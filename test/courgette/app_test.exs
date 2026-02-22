defmodule Courgette.AppTest do
  use ExUnit.Case
  use Courgette.ComponentTestHelpers

  # -- Test App --

  defmodule CounterApp do
    use Courgette.App

    @impl true
    def mount(_assigns) do
      {:ok, %{count: 0, label: "Counter"}}
    end

    @impl true
    def render(assigns) do
      box border: :rounded, flex_direction: :column do
        text bold: true do
          assigns.label
        end

        text do
          "Count: #{assigns.count}"
        end
      end
    end

    @impl true
    def handle_event({:key, :arrow_up}, assigns) do
      {:noreply, update(assigns, :count, &(&1 + 1))}
    end

    def handle_event({:key, :arrow_down}, assigns) do
      {:noreply, update(assigns, :count, &(max(&1 - 1, 0)))}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def handle_info({:set_label, label}, assigns) do
      {:noreply, assign(assigns, :label, label)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  describe "full mount→event→render cycle" do
    test "mounts and renders initial state" do
      view = mount(CounterApp)

      assert render_text(view) =~ "Counter"
      assert render_text(view) =~ "Count: 0"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "handles events and re-renders" do
      view = mount(CounterApp)

      send_event(view, {:key, :arrow_up})
      assert render_text(view) =~ "Count: 1"

      send_event(view, {:key, :arrow_up})
      assert render_text(view) =~ "Count: 2"

      send_event(view, {:key, :arrow_down})
      assert render_text(view) =~ "Count: 1"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "floor at zero" do
      view = mount(CounterApp)

      send_event(view, {:key, :arrow_down})
      assert render_text(view) =~ "Count: 0"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "handles info messages" do
      view = mount(CounterApp)

      send_info(view, {:set_label, "My Counter"})
      assert render_text(view) =~ "My Counter"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "render_tree returns element struct" do
      view = mount(CounterApp)

      tree = render_tree(view)
      assert %Courgette.Element{type: :box} = tree
      assert length(tree.children) == 2

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end
  end
end
