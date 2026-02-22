defmodule Courgette.AppTest do
  use ExUnit.Case
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry

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

  # -- Child Component Integration Test Modules --

  defmodule ChildItem do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :ticks, fn -> 0 end)}
    end

    @impl true
    def render(assigns) do
      text(do: "item:#{assigns[:name]}:#{assigns.ticks}")
    end

    @impl true
    def update(props, assigns) do
      {:ok, Map.merge(assigns, props)}
    end

    @impl true
    def handle_info(:tick, assigns) do
      {:noreply, update(assigns, :ticks, &(&1 + 1))}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule DynamicListApp do
    use Courgette.App

    @impl true
    def mount(_assigns) do
      {:ok, %{items: ["a", "b"]}}
    end

    @impl true
    def render(assigns) do
      box border: :single do
        text(do: "count:#{length(assigns.items)}")

        for name <- assigns.items do
          live_component(ChildItem, id: name, name: name)
        end
      end
    end

    @impl true
    def handle_info({:set_items, items}, assigns) do
      {:noreply, assign(assigns, :items, items)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  describe "child component integration" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "dynamic child list: add and remove items" do
      view = mount(DynamicListApp)

      assert render_text(view) =~ "count:2"
      assert render_text(view) =~ "item:a:0"
      assert render_text(view) =~ "item:b:0"

      # Add a third item
      send_info(view, {:set_items, ["a", "b", "c"]})
      assert render_text(view) =~ "count:3"
      assert render_text(view) =~ "item:c:0"

      # Remove first item
      send_info(view, {:set_items, ["b", "c"]})
      assert render_text(view) =~ "count:2"
      refute render_text(view) =~ "item:a"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "child with independent state updates" do
      view = mount(DynamicListApp)

      # Find child "a" and tick it
      {:ok, child_a} = ComponentRegistry.lookup(ChildItem, "a")
      send(child_a, :tick)
      :sys.get_state(child_a)
      :sys.get_state(view.server)

      assert render_text(view) =~ "item:a:1"
      # Child b is unaffected
      assert render_text(view) =~ "item:b:0"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "send_update from parent to specific child" do
      view = mount(DynamicListApp)

      Courgette.send_update(ChildItem, id: "b", ticks: 99)
      :sys.get_state(view.server)

      assert render_text(view) =~ "item:b:99"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "parent re-render does not re-mount existing children" do
      view = mount(DynamicListApp)

      {:ok, pid_a_before} = ComponentRegistry.lookup(ChildItem, "a")

      # Re-render parent with same children
      send_info(view, {:set_items, ["a", "b"]})

      {:ok, pid_a_after} = ComponentRegistry.lookup(ChildItem, "a")
      assert pid_a_before == pid_a_after

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end
  end
end
