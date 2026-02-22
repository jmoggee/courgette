defmodule Courgette.LiveComponent.ServerTest do
  use ExUnit.Case

  alias Courgette.LiveComponent.Server
  alias Courgette.Renderer
  alias Courgette.Element
  alias Courgette.ComponentRegistry

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

  # -- Child Component Test Modules --

  defmodule ChildCounter do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :count, fn -> 0 end)}
    end

    @impl true
    def render(assigns) do
      text(do: "child:#{assigns.count}")
    end

    @impl true
    def update(props, assigns) do
      {:ok, Map.merge(assigns, props)}
    end

    @impl true
    def handle_info({:increment}, assigns) do
      {:noreply, update(assigns, :count, &(&1 + 1))}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule ParentWithChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :show_child, fn -> true end)}
    end

    @impl true
    def render(assigns) do
      if assigns.show_child do
        box do
          text(do: "parent")
          live_component(ChildCounter, id: "c1", count: Map.get(assigns, :child_count, 0))
        end
      else
        box do
          text(do: "parent-only")
        end
      end
    end

    @impl true
    def handle_event({:key, {:char, "h"}}, assigns) do
      {:noreply, assign(assigns, :show_child, false)}
    end

    def handle_event({:key, {:char, "s"}}, assigns) do
      {:noreply, assign(assigns, :show_child, true)}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def handle_info({:set_child_count, n}, assigns) do
      {:noreply, assign(assigns, :child_count, n)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule ParentWithDynamicChildren do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :items, fn -> [] end)}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "items:#{length(assigns.items)}")

        for item <- assigns.items do
          live_component(ChildCounter, id: item, count: 0)
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

  defmodule GrandchildComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :value, fn -> "gc" end)}
    end

    @impl true
    def render(assigns) do
      text(do: "grandchild:#{assigns.value}")
    end
  end

  defmodule ChildWithChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :label, fn -> "mid" end)}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "child:#{assigns.label}")
        live_component(GrandchildComponent, id: "gc1", value: "deep")
      end
    end
  end

  defmodule ParentWithNesting do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns) do
      {:ok, %{}}
    end

    @impl true
    def render(_assigns) do
      box do
        text(do: "root")
        live_component(ChildWithChild, id: "mid1")
      end
    end
  end

  defmodule ParentPidChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      if assigns[:notify] do
        send(assigns.notify, {:parent_pid_received, assigns[:parent_pid]})
      end

      {:ok, assigns}
    end

    @impl true
    def render(_assigns) do
      text(do: "ppchild")
    end
  end

  defmodule ParentPidParent do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assigns}
    end

    @impl true
    def render(assigns) do
      box do
        live_component(ParentPidChild, id: "pp1", notify: assigns[:notify])
      end
    end
  end

  defmodule ChildMessagesParent do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assigns}
    end

    @impl true
    def render(_assigns) do
      text(do: "cmp")
    end

    @impl true
    def handle_info(:send_to_parent, assigns) do
      if assigns[:parent_pid] do
        send(assigns.parent_pid, {:from_child, "hello"})
      end

      {:noreply, assigns}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule ParentReceivesFromChild do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns) do
      {:ok, %{child_msg: nil}}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "parent:#{inspect(assigns.child_msg)}")
        live_component(ChildMessagesParent, id: "cmp1")
      end
    end

    @impl true
    def handle_info({:from_child, msg}, assigns) do
      {:noreply, assign(assigns, :child_msg, msg)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  # -- Focus Test Components --

  defmodule FocusableChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :focused, fn -> false end) |> assign_new(:last_event, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      label = assigns[:label] || "child"
      text(do: "#{label}:focused=#{assigns.focused}:event=#{inspect(assigns.last_event)}")
    end

    @impl true
    def handle_event(:focus, assigns) do
      {:noreply, assign(assigns, :focused, true)}
    end

    def handle_event(:blur, assigns) do
      {:noreply, assign(assigns, :focused, false)}
    end

    def handle_event(event, assigns) do
      {:noreply, assign(assigns, :last_event, event)}
    end
  end

  defmodule ParentWithFocusableChildren do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :child_count, fn -> 3 end)}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "parent")

        for i <- 1..assigns.child_count do
          live_component(FocusableChild, id: "f#{i}", focusable: true, label: "f#{i}")
        end
      end
    end

    @impl true
    def handle_event(event, assigns) do
      {:noreply, assign(assigns, :root_event, event)}
    end
  end

  defmodule ParentWithMixedChildren do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{}}

    @impl true
    def render(_assigns) do
      box do
        live_component(FocusableChild, id: "a", focusable: true, label: "a")
        live_component(ChildCounter, id: "nf", count: 0)
        live_component(FocusableChild, id: "b", focusable: true, label: "b")
      end
    end

    @impl true
    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  defmodule ParentNoFocusable do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{tab_count: 0}}

    @impl true
    def render(assigns) do
      box do
        text(do: "tabs:#{assigns.tab_count}")
        live_component(ChildCounter, id: "c1", count: 0)
      end
    end

    @impl true
    def handle_event({:key, :tab}, assigns) do
      {:noreply, update(assigns, :tab_count, &(&1 + 1))}
    end

    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  # -- Focus Tests --

  describe "focus management" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "Tab with no focusable children dispatches to root" do
      ctx = start_server(ParentNoFocusable)

      GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "tabs:1" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "Tab cycles focus to first focusable child" do
      ctx = start_server(ParentWithFocusableChildren)

      GenServer.call(ctx.server, {:test_event, {:key, :tab}})

      {:ok, child_pid} = ComponentRegistry.lookup(FocusableChild, "f1")
      :sys.get_state(child_pid)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "f1:focused=true"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "Tab twice focuses second child" do
      ctx = start_server(ParentWithFocusableChildren)

      GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})

      {:ok, child1} = ComponentRegistry.lookup(FocusableChild, "f1")
      {:ok, child2} = ComponentRegistry.lookup(FocusableChild, "f2")
      :sys.get_state(child1)
      :sys.get_state(child2)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "f1:focused=false"
      assert text =~ "f2:focused=true"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "Tab wraps from last to first" do
      ctx = start_server(ParentWithFocusableChildren)

      # Tab 3 times (focus f1, f2, f3), then one more wraps to f1
      for _ <- 1..4 do
        GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      end

      # Allow children to settle
      for i <- 1..3 do
        {:ok, pid} = ComponentRegistry.lookup(FocusableChild, "f#{i}")
        :sys.get_state(pid)
      end
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "f1:focused=true"
      assert text =~ "f3:focused=false"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "Shift-Tab cycles backward and wraps" do
      ctx = start_server(ParentWithFocusableChildren)

      # Shift-Tab from nil → last (f3)
      GenServer.call(ctx.server, {:test_event, {:key, {:shift, :tab}}})

      {:ok, child3} = ComponentRegistry.lookup(FocusableChild, "f3")
      :sys.get_state(child3)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "f3:focused=true"

      # Shift-Tab again → f2
      GenServer.call(ctx.server, {:test_event, {:key, {:shift, :tab}}})

      {:ok, child2} = ComponentRegistry.lookup(FocusableChild, "f2")
      :sys.get_state(child2)
      :sys.get_state(child3)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "f2:focused=true"
      assert text =~ "f3:focused=false"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "focusable: true not passed to child mount" do
      ctx = start_server(ParentWithFocusableChildren)

      {:ok, child_pid} = ComponentRegistry.lookup(FocusableChild, "f1")
      child_state = :sys.get_state(child_pid)
      refute Map.has_key?(child_state.assigns, :focusable)

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "non-focusable children skipped in focus order" do
      ctx = start_server(ParentWithMixedChildren)

      # Tab → a, Tab → b (skips nf which is not focusable)
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})

      {:ok, child_a} = ComponentRegistry.lookup(FocusableChild, "a")
      {:ok, child_b} = ComponentRegistry.lookup(FocusableChild, "b")
      :sys.get_state(child_a)
      :sys.get_state(child_b)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "a:focused=false"
      assert text =~ "b:focused=true"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "event routes to focused child's handle_event" do
      ctx = start_server(ParentWithFocusableChildren)

      # Focus f1
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      # Send a key event — should route to f1
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "x"}}})

      {:ok, child1} = ComponentRegistry.lookup(FocusableChild, "f1")
      :sys.get_state(child1)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ ~s(f1:focused=true:event={:key, {:char, "x"}})

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "root event (no focus set) dispatches locally" do
      ctx = start_server(ParentWithFocusableChildren)

      # No tab pressed yet — event goes to root
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "x"}}})

      state = :sys.get_state(ctx.server)
      assert state.assigns[:root_event] == {:key, {:char, "x"}}

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "routed event triggers child re-render and parent re-assembly" do
      ctx = start_server(ParentWithFocusableChildren)

      # Focus f1
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})
      # Verify initial state
      tree1 = last_tree(ctx)
      text1 = collect_all_text(tree1) |> Enum.join(" ")
      assert text1 =~ "f1:focused=true:event=nil"

      # Send event to focused child
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "z"}}})

      {:ok, child1} = ComponentRegistry.lookup(FocusableChild, "f1")
      :sys.get_state(child1)
      :sys.get_state(ctx.server)

      tree2 = last_tree(ctx)
      text2 = collect_all_text(tree2) |> Enum.join(" ")
      assert text2 =~ ~s(f1:focused=true:event={:key, {:char, "z"}})

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  # -- Child Component Tests --

  describe "child components" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "parent with child component: child mounts and renders" do
      ctx = start_server(ParentWithChild)
      tree = last_tree(ctx)

      # Tree should contain both parent text and child text
      text = collect_all_text(tree)
      assert "parent" in text
      assert "child:0" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent re-render starts new children" do
      ctx = start_server(ParentWithDynamicChildren)

      # Initially no items
      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "items:0" in text

      # Add items
      send(ctx.server, {:set_items, ["a", "b"]})
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "items:2" in text
      assert "child:0" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent re-render updates existing children with new props" do
      ctx = start_server(ParentWithChild)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "child:0" in text

      # Update child count via parent assigns
      send(ctx.server, {:set_child_count, 42})
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "child:42" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent re-render removes children that disappear" do
      ctx = start_server(ParentWithChild)

      # Child should be registered
      assert {:ok, _pid} = ComponentRegistry.lookup(ChildCounter, "c1")

      # Hide child
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "h"}}})

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "parent-only" in text
      refute Enum.any?(text, &String.starts_with?(&1, "child:"))

      # Child should be unregistered
      assert :error = ComponentRegistry.lookup(ChildCounter, "c1")

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "child re-render via handle_info triggers parent re-assembly" do
      ctx = start_server(ParentWithChild)

      # Find the child pid
      {:ok, child_pid} = ComponentRegistry.lookup(ChildCounter, "c1")

      # Send directly to child to trigger independent re-render
      send(child_pid, {:increment})
      :sys.get_state(child_pid)
      # Allow parent to process the child_tree message
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "child:1" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "send_update triggers child update" do
      ctx = start_server(ParentWithChild)

      # Use GenServer.call directly (send_update will be tested in integration)
      {:ok, child_pid} = ComponentRegistry.lookup(ChildCounter, "c1")
      GenServer.call(child_pid, {:update_props, %{count: 99}})
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "child:99" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "nested children (child of child) work" do
      ctx = start_server(ParentWithNesting)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "root" in text
      assert "child:mid" in text
      assert "grandchild:deep" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "child termination cleans up ComponentRegistry" do
      ctx = start_server(ParentWithChild)

      assert {:ok, _pid} = ComponentRegistry.lookup(ChildCounter, "c1")

      GenServer.stop(ctx.server)
      # Small wait for terminate to run
      Process.sleep(50)

      assert :error = ComponentRegistry.lookup(ChildCounter, "c1")

      GenServer.stop(ctx.renderer)
    end

    test "parent_pid is injected into child assigns" do
      ctx = start_server(ParentPidParent, initial_assigns: %{notify: self()})

      assert_receive {:parent_pid_received, parent_pid}, 200
      assert parent_pid == ctx.server

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "child sends message to parent via parent_pid" do
      ctx = start_server(ParentReceivesFromChild)

      # Find child and tell it to send to parent
      {:ok, child_pid} = ComponentRegistry.lookup(ChildMessagesParent, "cmp1")
      send(child_pid, :send_to_parent)
      :sys.get_state(child_pid)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert ~s(parent:"hello") in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent re-render does not re-mount existing children" do
      ctx = start_server(ParentWithChild)

      {:ok, child_pid_before} = ComponentRegistry.lookup(ChildCounter, "c1")

      # Trigger parent re-render with same child
      send(ctx.server, {:set_child_count, 5})
      :sys.get_state(ctx.server)

      {:ok, child_pid_after} = ComponentRegistry.lookup(ChildCounter, "c1")
      assert child_pid_before == child_pid_after

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  # -- Error Boundary Test Components --

  defmodule CrashableChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :label, fn -> "ok" end)}
    end

    @impl true
    def render(assigns) do
      text(do: "crashable:#{assigns.label}")
    end

    @impl true
    def handle_info(:crash, _assigns) do
      raise "deliberate crash"
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule FocusableCrashChild do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign_new(assigns, :label, fn -> "alive" end)}
    end

    @impl true
    def render(assigns) do
      text(do: "fc:#{assigns.label}")
    end

    @impl true
    def handle_event({:key, {:char, "x"}}, _assigns) do
      raise "crash via routed event"
    end

    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  defmodule FocusCrashParent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{crash_count: 0}}

    @impl true
    def render(assigns) do
      box do
        text(do: "crashes:#{assigns.crash_count}")
        live_component(FocusableCrashChild, id: "fc1", focusable: true, label: "target")
      end
    end

    @impl true
    def handle_info({:child_crashed, _key, _reason}, assigns) do
      {:noreply, update(assigns, :crash_count, &(&1 + 1))}
    end

    def handle_info(_msg, assigns), do: {:noreply, assigns}
    @impl true
    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  defmodule CrashHandlingParent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns) do
      {:ok, %{show_child: true, crash_log: []}}
    end

    @impl true
    def render(assigns) do
      if assigns.show_child do
        box do
          text(do: "parent:ok")
          live_component(CrashableChild, id: "cc1", label: "alive")
        end
      else
        box do
          text(do: "parent:fallback")
        end
      end
    end

    @impl true
    def handle_info({:child_crashed, {mod, id}, _reason}, assigns) do
      new_log = [{mod, id} | assigns.crash_log]
      {:noreply, assign(assigns, :crash_log, new_log)}
    end

    def handle_info({:hide_child}, assigns) do
      {:noreply, assign(assigns, :show_child, false)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule CrashRemoveParent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns) do
      {:ok, %{show_child: true}}
    end

    @impl true
    def render(assigns) do
      if assigns.show_child do
        box do
          text(do: "with-child")
          live_component(CrashableChild, id: "rm1")
        end
      else
        box do
          text(do: "without-child")
        end
      end
    end

    @impl true
    def handle_info({:child_crashed, _key, _reason}, assigns) do
      {:noreply, assign(assigns, :show_child, false)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  defmodule MultiChildParent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns) do
      {:ok, %{crash_count: 0}}
    end

    @impl true
    def render(assigns) do
      box do
        text(do: "crashes:#{assigns.crash_count}")
        live_component(CrashableChild, id: "m1", label: "first")
        live_component(CrashableChild, id: "m2", label: "second")
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

  # -- Error Boundary Tests --

  describe "error boundaries" do
    setup do
      ComponentRegistry.create_table()
      on_exit(fn -> ComponentRegistry.destroy_table() end)
    end

    test "child crash delivers {:child_crashed, {mod, id}, reason} to parent" do
      ctx = start_server(CrashHandlingParent)

      {:ok, child_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      send(child_pid, :crash)
      Process.sleep(50)
      :sys.get_state(ctx.server)

      state = :sys.get_state(ctx.server)
      assert [{CrashableChild, "cc1"}] = state.assigns.crash_log

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "crashed child's old pid is replaced after auto-restart" do
      ctx = start_server(CrashHandlingParent)

      {:ok, old_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      ref = Process.monitor(old_pid)
      send(old_pid, :crash)
      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(ctx.server)

      # Old pid is dead, but child was restarted (still in render tree)
      refute Process.alive?(old_pid)

      # New pid registered in ComponentRegistry
      {:ok, new_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      assert new_pid != old_pid
      assert Process.alive?(new_pid)

      # Parent's children map has the new pid
      state = :sys.get_state(ctx.server)
      {child_pid, _props} = state.children[{CrashableChild, "cc1"}]
      assert child_pid == new_pid

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent re-renders after crash, child auto-restarts" do
      ctx = start_server(CrashHandlingParent)

      {:ok, old_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      ref = Process.monitor(old_pid)
      send(old_pid, :crash)
      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(ctx.server)

      # Child still in render → auto-restarted with new pid
      {:ok, new_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      assert new_pid != old_pid

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "parent:ok"
      assert text =~ "crashable:alive"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "parent handles crash by removing child → fallback renders" do
      ctx = start_server(CrashRemoveParent)

      {:ok, child_pid} = ComponentRegistry.lookup(CrashableChild, "rm1")
      ref = Process.monitor(child_pid)
      send(child_pid, :crash)
      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(ctx.server)

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "without-child"

      # Child not re-registered
      assert :error = ComponentRegistry.lookup(CrashableChild, "rm1")

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "normal stop doesn't trigger child_crashed" do
      ctx = start_server(CrashHandlingParent)

      {:ok, child_pid} = ComponentRegistry.lookup(CrashableChild, "cc1")
      GenServer.stop(child_pid, :normal)
      Process.sleep(50)
      :sys.get_state(ctx.server)

      state = :sys.get_state(ctx.server)
      assert state.assigns.crash_log == []

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "multiple children: only crashed one affected" do
      ctx = start_server(MultiChildParent)

      {:ok, pid_m1} = ComponentRegistry.lookup(CrashableChild, "m1")
      {:ok, pid_m2} = ComponentRegistry.lookup(CrashableChild, "m2")

      ref = Process.monitor(pid_m1)
      send(pid_m1, :crash)
      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(ctx.server)

      # m2 still alive with same pid
      {:ok, pid_m2_after} = ComponentRegistry.lookup(CrashableChild, "m2")
      assert pid_m2 == pid_m2_after

      # m1 restarted with new pid
      {:ok, pid_m1_after} = ComponentRegistry.lookup(CrashableChild, "m1")
      assert pid_m1 != pid_m1_after

      tree = last_tree(ctx)
      text = collect_all_text(tree) |> Enum.join(" ")
      assert text =~ "crashable:first"
      assert text =~ "crashable:second"
      assert text =~ "crashes:1"

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "child crash during routed event doesn't kill parent" do
      ctx = start_server(FocusCrashParent)

      # Tab to focus the crashable child
      GenServer.call(ctx.server, {:test_event, {:key, :tab}})

      {:ok, old_pid} = ComponentRegistry.lookup(FocusableCrashChild, "fc1")
      ref = Process.monitor(old_pid)

      # Send 'x' which routes to focused child → child crashes
      GenServer.call(ctx.server, {:test_event, {:key, {:char, "x"}}})

      assert_receive {:DOWN, ^ref, :process, _, _}, 200
      Process.sleep(20)
      :sys.get_state(ctx.server)

      # Parent survived
      assert Process.alive?(ctx.server)

      # Child auto-restarted
      {:ok, new_pid} = ComponentRegistry.lookup(FocusableCrashChild, "fc1")
      assert new_pid != old_pid

      state = :sys.get_state(ctx.server)
      assert state.assigns.crash_count == 1

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end

    test "no handle_info for child_crashed → auto-restart (default)" do
      # ParentWithChild doesn't handle :child_crashed specifically
      # but has a catch-all handle_info that returns {:noreply, assigns}
      # The child should auto-restart via force_rerender
      ctx = start_server(ParentWithChild)

      {:ok, old_pid} = ComponentRegistry.lookup(ChildCounter, "c1")

      # We need a child that can crash — but ChildCounter can't.
      # Instead, directly kill it abnormally
      Process.exit(old_pid, :kill)
      Process.sleep(50)
      :sys.get_state(ctx.server)

      # The child should be restarted since it's still in the render tree
      {:ok, new_pid} = ComponentRegistry.lookup(ChildCounter, "c1")
      assert new_pid != old_pid

      tree = last_tree(ctx)
      text = collect_all_text(tree)
      assert "child:0" in text

      GenServer.stop(ctx.server)
      GenServer.stop(ctx.renderer)
    end
  end

  # -- Text extraction helper for child component tests --

  defp collect_all_text(nil), do: []
  defp collect_all_text(text) when is_binary(text), do: [text]

  defp collect_all_text(%Element{children: children}) do
    Enum.flat_map(children, &collect_all_text/1)
  end
end
