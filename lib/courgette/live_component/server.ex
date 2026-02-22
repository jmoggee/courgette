defmodule Courgette.LiveComponent.Server do
  @moduledoc """
  GenServer that wraps a user's LiveComponent module.

  Manages the component lifecycle: mount → render → event loop → terminate.
  Holds the user's assigns and a key buffer for incremental key parsing.

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

  alias Courgette.Terminal.KeyParser
  alias Courgette.Renderer

  @type state :: %{
          module: module(),
          assigns: map(),
          renderer: pid() | atom(),
          key_buffer: binary()
        }

  # -- Public API --

  @doc """
  Start a LiveComponent server.

  ## Options

  - `:module` — the LiveComponent module (required)
  - `:initial_assigns` — map of initial assigns passed to mount (default `%{}`)
  - `:renderer` — Renderer server pid or name (required)
  - `:name` — GenServer name registration
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    module = Keyword.fetch!(opts, :module)
    initial_assigns = Keyword.get(opts, :initial_assigns, %{})
    renderer = Keyword.fetch!(opts, :renderer)

    Process.flag(:trap_exit, true)

    # Call mount
    {:ok, assigns} = module.mount(initial_assigns)

    # Initial render
    tree = module.render(assigns)
    Renderer.push(tree, renderer)

    state = %{
      module: module,
      assigns: assigns,
      renderer: renderer,
      key_buffer: <<>>
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:test_event, event}, _from, state) do
    new_state = dispatch_event(event, state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:terminal_input, bytes}, state) when is_binary(bytes) do
    {events, new_buffer} = KeyParser.parse(bytes, state.key_buffer)

    new_state =
      Enum.reduce(events, %{state | key_buffer: new_buffer}, fn event, acc ->
        dispatch_event(event, acc)
      end)

    {:noreply, new_state}
  end

  def handle_info({:terminal_resize, cols, rows}, state) do
    Renderer.resize(cols, rows, state.renderer)

    new_state = dispatch_event({:resize, cols, rows}, state)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:noreply, state}
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
    if function_exported?(state.module, :terminate, 2) do
      state.module.terminate(reason, state.assigns)
    end

    :ok
  end

  # -- Private helpers --

  defp dispatch_event(event, state) do
    if function_exported?(state.module, :handle_event, 2) do
      {:noreply, new_assigns} = state.module.handle_event(event, state.assigns)
      {_noreply, new_state} = maybe_rerender(state, new_assigns)
      new_state
    else
      state
    end
  end

  defp maybe_rerender(state, new_assigns) do
    if new_assigns != state.assigns do
      tree = state.module.render(new_assigns)
      Renderer.push(tree, state.renderer)
      {:noreply, %{state | assigns: new_assigns}}
    else
      {:noreply, state}
    end
  end
end
