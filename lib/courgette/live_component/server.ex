defmodule Courgette.LiveComponent.Server do
  @moduledoc """
  GenServer that wraps a user's LiveComponent module.

  Manages the component lifecycle: mount → render → event loop → terminate.
  Holds the user's assigns and a key buffer for incremental key parsing.

  ## Child Components

  When a component's `render/1` returns `:live_component` elements, the
  server manages child processes automatically — starting new ones, updating
  existing ones with changed props, and stopping removed ones.

  ## Dual Role: Root and Child

  A server acts as a root when started without `:parent` (receives keyboard
  input, pushes to Renderer). It acts as a child when started with `:parent`
  (sends rendered trees to parent instead of pushing to Renderer directly).

  ## Input Flow

  Raw terminal bytes arrive as `{:terminal_input, bytes}` messages.
  The server parses them through `KeyParser.parse/2` (maintaining a buffer
  for incomplete sequences), then calls `handle_event/2` for each parsed
  event. If assigns change, the server re-renders and pushes to the Renderer.

  ## Testing

  Use `{:test_event, event}` via GenServer.call to bypass KeyParser and
  inject parsed events directly.
  """

  use GenServer

  alias Courgette.ComponentRegistry
  alias Courgette.FocusManager
  alias Courgette.LiveComponent.Lifecycle
  alias Courgette.Renderer
  alias Courgette.Terminal.KeyParser

  @type state :: %{
          module: module(),
          assigns: map(),
          renderer: pid() | atom(),
          key_buffer: binary(),
          escape_timer: reference() | nil,
          parent: pid() | nil,
          component_id: {module(), term()} | nil,
          children: %{{module(), term()} => {pid(), map()}},
          child_trees: %{{module(), term()} => Courgette.Element.t()},
          raw_tree: Courgette.Element.t() | nil,
          focus: FocusManager.t()
        }

  # -- Public API --

  @doc """
  Start a LiveComponent server.

  ## Options

  - `:module` — the LiveComponent module (required)
  - `:initial_assigns` — map of initial assigns passed to mount (default `%{}`)
  - `:renderer` — Renderer server pid or name (required)
  - `:name` — GenServer name registration
  - `:parent` — parent server pid (for child components)
  - `:component_id` — `{module, id}` tuple (for child components)
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @doc """
  Returns the current assembled tree from the server.
  Used by parents to fetch a child's initial rendered tree.
  """
  def get_rendered_tree(server) do
    GenServer.call(server, :get_rendered_tree)
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    module = Keyword.fetch!(opts, :module)
    initial_assigns = Keyword.get(opts, :initial_assigns, %{})
    renderer = Keyword.fetch!(opts, :renderer)
    parent = Keyword.get(opts, :parent)
    component_id = Keyword.get(opts, :component_id)

    Process.flag(:trap_exit, true)

    # Register in ComponentRegistry if this is a child component
    if component_id do
      {mod, id} = component_id
      ComponentRegistry.register(mod, id, self())
    end

    # Inject parent_pid into assigns for child components
    mount_assigns =
      if parent do
        Map.put(initial_assigns, :parent_pid, parent)
      else
        initial_assigns
      end

    # Call mount
    {:ok, assigns} = module.mount(mount_assigns)

    # Initial render
    raw_tree = module.render(assigns)

    state = %{
      module: module,
      assigns: assigns,
      renderer: renderer,
      key_buffer: <<>>,
      escape_timer: nil,
      parent: parent,
      component_id: component_id,
      children: %{},
      child_trees: %{},
      raw_tree: raw_tree,
      focus: FocusManager.new()
    }

    # Reconcile any initial children from the raw tree
    state = reconcile_children(state)

    # Assemble and deliver the tree
    assembled = assemble_tree(state.raw_tree, state.child_trees)

    if parent do
      # Child: send tree to parent for assembly
      send(parent, {:child_tree, component_id, assembled})
    else
      # Root: push to renderer
      Renderer.push(assembled, renderer)
    end

    {:ok, state}
  end

  @impl true
  def handle_call({:test_event, event}, _from, state) do
    new_state = dispatch_event(event, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:routed_event, event}, _from, state) do
    new_state = dispatch_event(event, state)
    handled = event_handled?(event, state, new_state)
    {:reply, {:ok, handled}, new_state}
  end

  def handle_call(:get_rendered_tree, _from, state) do
    assembled = assemble_tree(state.raw_tree, state.child_trees)
    {:reply, assembled, state}
  end

  def handle_call({:update_props, props}, _from, state) do
    new_state = apply_update_props(state, props)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:terminal_input, bytes}, state) when is_binary(bytes) do
    state = cancel_escape_timer(state)
    {events, new_buffer} = KeyParser.parse(bytes, state.key_buffer)

    new_state =
      Enum.reduce(events, %{state | key_buffer: new_buffer}, fn event, acc ->
        dispatch_event(event, acc)
      end)

    new_state = maybe_start_escape_timer(new_state)
    {:noreply, new_state}
  end

  def handle_info(:escape_timeout, %{key_buffer: <<0x1B>>} = state) do
    new_state = dispatch_event({:key, :escape}, %{state | key_buffer: <<>>, escape_timer: nil})
    {:noreply, new_state}
  end

  def handle_info(:escape_timeout, state) do
    {:noreply, %{state | escape_timer: nil}}
  end

  def handle_info({:terminal_resize, cols, rows}, state) do
    Renderer.resize(cols, rows, state.renderer)

    new_state = dispatch_event({:resize, cols, rows}, state)
    {:noreply, new_state}
  end

  def handle_info({:child_tree, component_id, tree}, state) do
    new_child_trees = Map.put(state.child_trees, component_id, tree)
    state = %{state | child_trees: new_child_trees}

    # Re-assemble and deliver
    assembled = assemble_tree(state.raw_tree, state.child_trees)
    deliver_tree(state, assembled)

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, state) do
    case find_child_by_pid(state, pid) do
      nil ->
        # Not a child — ignore (e.g., input reader)
        {:noreply, state}

      {mod, id} ->
        state = cleanup_crashed_child(state, {mod, id})
        handle_child_exit(state, {mod, id}, reason)
    end
  end

  def handle_info(msg, state) do
    if function_exported?(state.module, :handle_info, 2) do
      {:noreply, new_assigns} = state.module.handle_info(msg, state.assigns)
      maybe_rerender(state, new_assigns)
    else
      {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    # Stop all children
    for {_key, {pid, _props}} <- state.children do
      if Process.alive?(pid), do: GenServer.stop(pid, :normal)
    end

    # Unregister from ComponentRegistry
    if state.component_id do
      {mod, id} = state.component_id
      ComponentRegistry.unregister(mod, id)
    end

    if function_exported?(state.module, :terminate, 2) do
      state.module.terminate(reason, state.assigns)
    end

    :ok
  end

  # -- Private helpers --

  defp handle_child_exit(state, _child_key, reason)
       when reason in [:normal, :shutdown] do
    # Normal/shutdown — quiet cleanup, no notification
    {:noreply, state}
  end

  defp handle_child_exit(state, _child_key, {:shutdown, _}) do
    {:noreply, state}
  end

  defp handle_child_exit(state, {mod, id}, reason) do
    # Abnormal crash — notify parent module and force re-render
    state = notify_parent_of_crash(state, {mod, id}, reason)
    state = force_rerender(state)
    {:noreply, state}
  end

  defp notify_parent_of_crash(state, {mod, id}, reason) do
    if function_exported?(state.module, :handle_info, 2) do
      {:noreply, new_assigns} =
        state.module.handle_info({:child_crashed, {mod, id}, reason}, state.assigns)

      %{state | assigns: new_assigns}
    else
      state
    end
  end

  defp dispatch_event(event, state) do
    if state.focus.order != [] do
      dispatch_event_root(event, state)
    else
      dispatch_event_local(event, state)
    end
  end

  # Hierarchical Tab/Shift-Tab: route to focused child first so inner
  # controls cycle before advancing focus at this level.
  defp dispatch_event_root({:key, :tab}, state) do
    handle_tab({:key, :tab}, state, :next)
  end

  defp dispatch_event_root({:key, {:shift, :tab}}, state) do
    handle_tab({:key, {:shift, :tab}}, state, :prev)
  end

  # Other events: route to focused child or dispatch locally.
  defp dispatch_event_root(event, state) do
    case FocusManager.current(state.focus) do
      nil ->
        dispatch_event_local(event, state)

      focused_key ->
        route_to_focused_child(event, state, focused_key)
    end
  end

  defp handle_tab(tab_event, state, direction) do
    # First, try routing Tab to the focused child
    if try_route_to_child(state, tab_event) do
      state
    else
      advance_focus_or_fallback(state, direction, tab_event)
    end
  end

  defp try_route_to_child(state, event) do
    with focused_key when not is_nil(focused_key) <- FocusManager.current(state.focus),
         {pid, _props} <- Map.get(state.children, focused_key),
         {:ok, true} <- route_to_child(pid, event) do
      true
    else
      _ -> false
    end
  end

  defp advance_focus_or_fallback(state, direction, tab_event) do
    # Child servers don't wrap — they let the parent cycle instead
    if state.parent != nil and would_focus_wrap?(state.focus, direction) do
      dispatch_event_local(tab_event, state)
    else
      {old_focused, new_focus} =
        case direction do
          :next -> FocusManager.focus_next(state.focus)
          :prev -> FocusManager.focus_prev(state.focus)
        end

      state = %{state | focus: new_focus}

      if old_focused == new_focus.focused and old_focused == nil do
        dispatch_event_local(tab_event, state)
      else
        handle_focus_change(state, old_focused, new_focus.focused)
      end
    end
  end

  defp would_focus_wrap?(%{order: []}, _direction), do: false
  defp would_focus_wrap?(%{focused: nil}, _direction), do: false

  defp would_focus_wrap?(%{focused: focused, order: order}, :next) do
    focused == List.last(order)
  end

  defp would_focus_wrap?(%{focused: focused, order: order}, :prev) do
    focused == hd(order)
  end

  defp route_to_focused_child(event, state, focused_key) do
    case Map.get(state.children, focused_key) do
      {pid, _props} ->
        case route_to_child(pid, event) do
          {:ok, true} -> state
          _ -> dispatch_event_local(event, state)
        end

      nil ->
        dispatch_event_local(event, state)
    end
  end

  # For Tab/Shift-Tab, only focus changes count as "handled" — prevents
  # leaf children from accidentally consuming Tab via catch-all handle_event.
  defp event_handled?({:key, :tab}, old, new), do: new.focus != old.focus
  defp event_handled?({:key, {:shift, :tab}}, old, new), do: new.focus != old.focus
  defp event_handled?(_event, old, new), do: new.assigns != old.assigns or new.focus != old.focus

  # Local dispatch — calls module's handle_event directly.
  defp dispatch_event_local(event, state) do
    if function_exported?(state.module, :handle_event, 2) do
      {:noreply, new_assigns} = state.module.handle_event(event, state.assigns)
      {_noreply, new_state} = maybe_rerender(state, new_assigns)
      new_state
    else
      state
    end
  end

  defp cancel_escape_timer(%{escape_timer: nil} = state), do: state

  defp cancel_escape_timer(%{escape_timer: ref} = state) do
    Process.cancel_timer(ref)
    %{state | escape_timer: nil}
  end

  defp maybe_start_escape_timer(%{key_buffer: <<0x1B>>} = state) do
    ref = Process.send_after(self(), :escape_timeout, 50)
    %{state | escape_timer: ref}
  end

  defp maybe_start_escape_timer(state), do: state

  defp handle_focus_change(state, old_focused, new_focused) do
    # Send :blur to old focused child
    if old_focused do
      case Map.get(state.children, old_focused) do
        {pid, _props} -> route_to_child(pid, :blur)
        nil -> :ok
      end
    end

    # Send :focus to new focused child
    if new_focused do
      case Map.get(state.children, new_focused) do
        {pid, _props} -> route_to_child(pid, :focus)
        nil -> :ok
      end
    end

    state
  end

  # Route an event to a child, catching exits if the child crashes
  # during the call. Returns {:ok, handled} on success, :error on crash.
  # The {:EXIT, pid, reason} message will arrive separately and trigger
  # error boundary cleanup.
  defp route_to_child(pid, event) do
    GenServer.call(pid, {:routed_event, event})
  catch
    :exit, _ -> :error
  end

  defp maybe_rerender(state, new_assigns) do
    if new_assigns != state.assigns do
      raw_tree = state.module.render(new_assigns)
      state = %{state | assigns: new_assigns, raw_tree: raw_tree}

      # Reconcile children from new raw tree
      state = reconcile_children(state)

      # Assemble and deliver
      assembled = assemble_tree(state.raw_tree, state.child_trees)
      deliver_tree(state, assembled)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  defp deliver_tree(state, assembled) do
    if state.parent do
      send(state.parent, {:child_tree, state.component_id, assembled})
    else
      Renderer.push(assembled, state.renderer)
    end
  end

  defp apply_update_props(state, props) do
    new_assigns =
      if function_exported?(state.module, :update, 2) do
        {:ok, assigns} = state.module.update(props, state.assigns)
        assigns
      else
        Map.merge(state.assigns, props)
      end

    {_noreply, new_state} = maybe_rerender(state, new_assigns)
    new_state
  end

  # -- Error boundary helpers --

  defp find_child_by_pid(state, pid) do
    Enum.find_value(state.children, fn
      {{mod, id}, {^pid, _props}} -> {mod, id}
      _ -> nil
    end)
  end

  defp cleanup_crashed_child(state, {mod, id}) do
    ComponentRegistry.unregister(mod, id)

    %{
      state
      | children: Map.delete(state.children, {mod, id}),
        child_trees: Map.delete(state.child_trees, {mod, id})
    }
  end

  defp force_rerender(state) do
    raw_tree = state.module.render(state.assigns)
    state = %{state | raw_tree: raw_tree}

    state = reconcile_children(state)

    assembled = assemble_tree(state.raw_tree, state.child_trees)
    deliver_tree(state, assembled)

    state
  end

  # -- Child reconciliation --

  defp reconcile_children(state) do
    new_specs = Lifecycle.extract_components(state.raw_tree)
    actions = Lifecycle.reconcile(state.children, new_specs)

    state = start_children(state, actions.to_start)
    state = update_children(state, actions.to_update)
    state = stop_children(state, actions.to_stop)

    # Update focus order for any server with focusable children
    focusable_order = Lifecycle.extract_focusable_order(state.raw_tree)
    old_focused = state.focus.focused
    new_focus = FocusManager.update_order(state.focus, focusable_order)
    state = %{state | focus: new_focus}

    if new_focus.focused != old_focused do
      handle_focus_change(state, old_focused, new_focus.focused)
    else
      state
    end
  end

  defp start_children(state, to_start) do
    Enum.reduce(to_start, state, fn {mod, id, props}, acc ->
      {:ok, pid} =
        start_link(
          module: mod,
          renderer: acc.renderer,
          initial_assigns: props,
          parent: self(),
          component_id: {mod, id}
        )

      # Fetch the child's initial rendered tree
      child_tree = get_rendered_tree(pid)

      new_children = Map.put(acc.children, {mod, id}, {pid, props})
      new_child_trees = Map.put(acc.child_trees, {mod, id}, child_tree)
      %{acc | children: new_children, child_trees: new_child_trees}
    end)
  end

  defp update_children(state, to_update) do
    Enum.reduce(to_update, state, fn {pid, mod, id, new_props}, acc ->
      GenServer.call(pid, {:update_props, new_props})
      # Fetch updated tree after props change
      child_tree = get_rendered_tree(pid)

      new_children = Map.put(acc.children, {mod, id}, {pid, new_props})
      new_child_trees = Map.put(acc.child_trees, {mod, id}, child_tree)
      %{acc | children: new_children, child_trees: new_child_trees}
    end)
  end

  defp stop_children(state, to_stop) do
    Enum.reduce(to_stop, state, fn {pid, mod, id}, acc ->
      if Process.alive?(pid), do: GenServer.stop(pid, :normal)

      new_children = Map.delete(acc.children, {mod, id})
      new_child_trees = Map.delete(acc.child_trees, {mod, id})
      %{acc | children: new_children, child_trees: new_child_trees}
    end)
  end

  # -- Tree assembly --

  defp assemble_tree(nil, _child_trees), do: nil

  defp assemble_tree(%Courgette.Element{type: :live_component, props: props} = _el, child_trees) do
    module = Map.fetch!(props, :module)
    id = Map.fetch!(props, :id)
    key = {module, id}

    case Map.get(child_trees, key) do
      nil -> Courgette.Element.new(:box, [], [])
      tree -> tree
    end
  end

  defp assemble_tree(%Courgette.Element{} = el, child_trees) do
    new_children =
      Enum.map(el.children, fn
        %Courgette.Element{} = child -> assemble_tree(child, child_trees)
        other -> other
      end)

    %{el | children: new_children}
  end
end
