defmodule Courgette.LiveComponent.ServerTest do
  use ExUnit.Case

  alias Courgette.LiveComponent.Server
  alias Courgette.Renderer
  alias Courgette.Element

  # -- Test Components --

  defmodule CounterComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :count, fn -> 0 end)}
    end

    @impl true
    def render(assigns) do
      text do
        "count: #{assigns.count}"
      end
    end

    @impl true
    def handle_event({:key, :arrow_up}, assigns) do
      {:noreply, update(assigns, :count, &(&1 + 1))}
    end

    def handle_event({:key, :arrow_down}, assigns) do
      {:noreply, update(assigns, :count, &(&1 - 1))}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def handle_info({:set_count, n}, assigns) do
      {:noreply, assign(assigns, :count, n)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def terminate(_reason, assigns) do
      if pid = assigns[:notify_on_terminate] do
        send(pid, :terminated)
      end

      :ok
    end
  end

  defmodule MinimalComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{value: "hello"}}

    @impl true
    def render(assigns) do
      text(do: assigns.value)
    end
  end

  defmodule ResizeComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{size: nil}}

    @impl true
    def render(assigns) do
      text(do: "size: #{inspect(assigns.size)}")
    end

    @impl true
    def handle_event({:resize, cols, rows}, assigns) do
      {:noreply, assign(assigns, :size, {cols, rows})}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end
  end

  # -- Helpers --

  defp start_server(module, opts \\ []) do
    renderer_name = :"renderer_#{:erlang.unique_integer([:positive])}"

    {:ok, renderer} =
      Renderer.start_link(
        headless: true,
        width: Keyword.get(opts, :width, 40),
        height: Keyword.get(opts, :height, 10),
        name: renderer_name
      )

    initial_assigns = Keyword.get(opts, :initial_assigns, %{})

    {:ok, server} =
      Server.start_link(
        module: module,
        renderer: renderer_name,
        initial_assigns: initial_assigns
      )

    %{server: server, renderer: renderer, renderer_name: renderer_name}
  end

  defp last_tree(%{renderer_name: name}) do
    Renderer.get_last_tree(name)
  end

  defp extract_text(%Element{type: :text, children: [text]}) when is_binary(text), do: text
  defp extract_text(%Element{children: children}), do: extract_text(List.first(children))

  # -- Tests --

  describe "mount and initial render" do
    test "mounts with default assigns and renders" do
      ctx = start_server(CounterComponent)
      tree = last_tree(ctx)

      assert %Element{type: :text} = tree
      assert extract_text(tree) == "count: 0"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "mounts with initial assigns" do
      ctx = start_server(CounterComponent, initial_assigns: %{count: 42})
      tree = last_tree(ctx)

      assert extract_text(tree) == "count: 42"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "minimal component mounts" do
      ctx = start_server(MinimalComponent)
      tree = last_tree(ctx)

      assert extract_text(tree) == "hello"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  describe "handle_event via test_event" do
    test "arrow_up increments counter" do
      ctx = start_server(CounterComponent)

      GenServer.call(ctx.server, {:test_event, {:key, :arrow_up}})
      assert extract_text(last_tree(ctx)) == "count: 1"

      GenServer.call(ctx.server, {:test_event, {:key, :arrow_up}})
      assert extract_text(last_tree(ctx)) == "count: 2"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "arrow_down decrements counter" do
      ctx = start_server(CounterComponent, initial_assigns: %{count: 5})

      GenServer.call(ctx.server, {:test_event, {:key, :arrow_down}})
      assert extract_text(last_tree(ctx)) == "count: 4"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "unhandled event does not change state" do
      ctx = start_server(CounterComponent)

      GenServer.call(ctx.server, {:test_event, {:key, {:char, "x"}}})
      assert extract_text(last_tree(ctx)) == "count: 0"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "no re-render when assigns unchanged" do
      ctx = start_server(CounterComponent)

      # Get initial tree ref
      tree1 = last_tree(ctx)

      # Event that doesn't change assigns
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "x"}}})

      # Tree should still be the same object (no re-render)
      tree2 = last_tree(ctx)
      assert tree1 == tree2

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "component without handle_event ignores events" do
      ctx = start_server(MinimalComponent)

      GenServer.call(ctx.server, {:test_event, {:key, :arrow_up}})
      assert extract_text(last_tree(ctx)) == "hello"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  describe "handle_info" do
    test "handles custom messages" do
      ctx = start_server(CounterComponent)

      send(ctx.server, {:set_count, 99})
      # Give the message time to be processed
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "count: 99"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "component without handle_info ignores messages" do
      ctx = start_server(MinimalComponent)

      send(ctx.server, {:custom, :message})
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "hello"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  describe "terminal_input (key parsing)" do
    test "parses raw bytes and dispatches events" do
      ctx = start_server(CounterComponent)

      # Send raw escape sequence for arrow up: ESC [ A
      send(ctx.server, {:terminal_input, "\e[A"})
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "count: 1"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "handles multiple events in one input" do
      ctx = start_server(CounterComponent)

      # Two arrow ups in one input
      send(ctx.server, {:terminal_input, "\e[A\e[A"})
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "count: 2"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "buffers incomplete escape sequences" do
      ctx = start_server(CounterComponent)

      # Send partial ESC sequence
      send(ctx.server, {:terminal_input, "\e"})
      :sys.get_state(ctx.server)

      # Count should still be 0 (buffered, not dispatched)
      assert extract_text(last_tree(ctx)) == "count: 0"

      # Complete the sequence
      send(ctx.server, {:terminal_input, "[A"})
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "count: 1"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  describe "terminal_resize" do
    test "dispatches resize event to component" do
      ctx = start_server(ResizeComponent)

      send(ctx.server, {:terminal_resize, 120, 40})
      :sys.get_state(ctx.server)

      assert extract_text(last_tree(ctx)) == "size: {120, 40}"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  describe "terminate" do
    test "calls module terminate callback" do
      ctx = start_server(CounterComponent, initial_assigns: %{notify_on_terminate: self()})

      GenServer.stop(ctx.server, :normal)
      assert_receive :terminated, 100

      GenServer.stop(ctx.renderer)
    end

    test "component without terminate callback stops cleanly" do
      ctx = start_server(MinimalComponent)

      ref = Process.monitor(ctx.server)
      GenServer.stop(ctx.server, :normal)
      assert_receive {:DOWN, ^ref, :process, _, :normal}, 100

      GenServer.stop(ctx.renderer)
    end
  end
end
