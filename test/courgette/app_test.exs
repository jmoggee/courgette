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
      {:noreply, update(assigns, :count, &max(&1 - 1, 0))}
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

  # -- Focus + Error Integration Test Components --

  defmodule FocusableItem do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :focused, fn -> false end)}
    end

    @impl true
    def render(assigns) do
      name = assigns[:name] || "item"
      text(do: "#{name}:f=#{assigns.focused}")
    end

    @impl true
    def update(props, assigns) do
      {:ok, Map.merge(assigns, props)}
    end

    @impl true
    def handle_event(:focus, assigns) do
      {:noreply, assign(assigns, :focused, true)}
    end

    def handle_event(:blur, assigns) do
      {:noreply, assign(assigns, :focused, false)}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule FocusApp do
    use Courgette.App

    @impl true
    def mount(_assigns) do
      {:ok, %{}}
    end

    @impl true
    def render(_assigns) do
      box do
        live_component(FocusableItem, id: "x", focusable: true, name: "x")
        live_component(FocusableItem, id: "y", focusable: true, name: "y")
        live_component(FocusableItem, id: "z", focusable: true, name: "z")
      end
    end

    @impl true
    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  defmodule CrashableItem do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :status, fn -> "ok" end)}
    end

    @impl true
    def render(assigns) do
      text(do: "crash_item:#{assigns[:name]}:#{assigns.status}")
    end

    @impl true
    def handle_info(:crash, _assigns) do
      raise "boom"
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule CrashApp do
    use Courgette.App

    @impl true
    def mount(_assigns) do
      {:ok, %{crash_count: 0}}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "crashes:#{assigns.crash_count}")
        live_component(CrashableItem, id: "ci1", name: "ci1")
      end
    end

    @impl true
    def handle_info({:child_crashed, _key, _reason}, assigns) do
      {:noreply, update(assigns, :crash_count, &(&1 + 1))}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  describe "focus integration" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "auto-focuses first child on mount" do
      view = mount(FocusApp)

      # Allow auto-focus child tree updates to propagate
      {:ok, pid} = ComponentRegistry.lookup(FocusableItem, "x")
      :sys.get_state(pid)
      :sys.get_state(view.server)

      assert render_text(view) =~ "x:f=true"
      assert render_text(view) =~ "y:f=false"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "Tab cycles through all children" do
      view = mount(FocusApp)

      # Auto-focused x, one Tab moves to y
      send_tab(view)

      for id <- ["x", "y", "z"] do
        {:ok, pid} = ComponentRegistry.lookup(FocusableItem, id)
        :sys.get_state(pid)
      end

      :sys.get_state(view.server)

      assert render_text(view) =~ "x:f=false"
      assert render_text(view) =~ "y:f=true"
      assert render_text(view) =~ "z:f=false"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "event routes to focused child" do
      view = mount(FocusApp)

      # x is auto-focused, send an event directly
      send_event(view, {:key, {:char, "a"}})

      {:ok, pid_x} = ComponentRegistry.lookup(FocusableItem, "x")
      :sys.get_state(pid_x)
      :sys.get_state(view.server)

      # x should still be focused (event handled by catch-all)
      assert render_text(view) =~ "x:f=true"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "focus + event routing end-to-end with Shift-Tab" do
      view = mount(FocusApp)

      # Shift-Tab from auto-focused x wraps to last child (z)
      send_shift_tab(view)

      for id <- ["x", "y", "z"] do
        {:ok, pid} = ComponentRegistry.lookup(FocusableItem, id)
        :sys.get_state(pid)
      end

      :sys.get_state(view.server)

      assert render_text(view) =~ "z:f=true"
      assert render_text(view) =~ "x:f=false"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end
  end

  describe "error boundary integration" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "child crash and auto-restart in app" do
      view = mount(CrashApp)

      assert render_text(view) =~ "crash_item:ci1:ok"

      {:ok, old_pid} = ComponentRegistry.lookup(CrashableItem, "ci1")
      ref = Process.monitor(old_pid)
      send(old_pid, :crash)
      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(view.server)

      # Auto-restarted
      {:ok, new_pid} = ComponentRegistry.lookup(CrashableItem, "ci1")
      assert new_pid != old_pid

      assert render_text(view) =~ "crash_item:ci1:ok"
      assert render_text(view) =~ "crashes:1"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
    end

    test "crash count tracks across multiple crashes" do
      view = mount(CrashApp)

      for _i <- 1..3 do
        {:ok, pid} = ComponentRegistry.lookup(CrashableItem, "ci1")
        ref = Process.monitor(pid)
        send(pid, :crash)
        assert_receive {:DOWN, ^ref, :process, _, _}, 200
        Process.sleep(20)
        :sys.get_state(view.server)
      end

      assert render_text(view) =~ "crashes:3"

      GenServer.stop(view.server)
      GenServer.stop(view.renderer)
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
