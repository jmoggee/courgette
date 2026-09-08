defmodule Courgette.RendererTest do
  use ExUnit.Case

  alias Courgette.Element
  alias Courgette.Renderer

  defp start_renderer(opts \\ []) do
    defaults = [headless: true, width: 20, height: 5]
    merged = Keyword.merge(defaults, opts)
    {:ok, pid} = Renderer.start_link(merged)
    pid
  end

  defp start_terminal_renderer(opts \\ []) do
    {:ok, device} = StringIO.open("")
    term_name = :"term_#{:erlang.unique_integer([:positive])}"

    {:ok, _term} =
      Courgette.Terminal.start_link(
        skip_raw_mode: true,
        device: device,
        name: term_name
      )

    defaults = [headless: false, terminal: term_name, width: 20, height: 5]
    merged = Keyword.merge(defaults, opts)
    {:ok, pid} = Renderer.start_link(merged)

    %{pid: pid, device: device, terminal: term_name}
  end

  describe "start_link/1" do
    test "starts headless renderer" do
      pid = start_renderer()
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "push/2" do
    test "selects rendered text in either direction" do
      pid = start_renderer(width: 8, height: 3)

      tree =
        Element.new(:box, [flex_direction: :column], [
          Element.new(:text, [], ["alpha"]),
          Element.new(:text, [], ["beta"])
        ])

      Renderer.push(tree, pid)

      :ok = Renderer.begin_selection({4, 0}, pid)
      refute :sys.get_state(pid).front.cells[{4, 0}].style[:reverse]

      :ok = Renderer.extend_selection({1, 0}, pid)
      assert :sys.get_state(pid).front.cells[{1, 0}].style.reverse

      assert Renderer.finish_selection({1, 0}, pid) == "lpha"
    end

    test "a click leaves no highlighted cell or selected text" do
      pid = start_renderer()
      Renderer.push(Element.new(:text, [], ["hello"]), pid)

      :ok = Renderer.begin_selection({2, 0}, pid)

      assert Renderer.finish_selection({2, 0}, pid) == nil
      refute :sys.get_state(pid).front.cells[{2, 0}].style[:reverse]
    end

    test "renders a simple text element" do
      pid = start_renderer()

      tree = Element.new(:text, [], ["Hello"])
      assert :ok = Renderer.push(tree, pid)

      GenServer.stop(pid)
    end

    test "stores last tree" do
      pid = start_renderer()

      tree = Element.new(:text, [], ["Hello"])
      Renderer.push(tree, pid)

      assert Renderer.get_last_tree(pid) == tree

      GenServer.stop(pid)
    end

    test "updates front buffer on successive pushes" do
      pid = start_renderer()

      tree1 = Element.new(:text, [], ["First"])
      Renderer.push(tree1, pid)
      assert Renderer.get_last_tree(pid) == tree1

      tree2 = Element.new(:text, [], ["Second"])
      Renderer.push(tree2, pid)
      assert Renderer.get_last_tree(pid) == tree2

      GenServer.stop(pid)
    end

    test "handles box with border" do
      pid = start_renderer()

      tree =
        Element.new(:box, [border: :single], [
          Element.new(:text, [], ["Boxed"])
        ])

      assert :ok = Renderer.push(tree, pid)

      GenServer.stop(pid)
    end

    test "handles empty element" do
      pid = start_renderer()

      tree = Element.new(:box)
      assert :ok = Renderer.push(tree, pid)

      GenServer.stop(pid)
    end

    test "handles nested elements" do
      pid = start_renderer()

      tree =
        Element.new(:box, [flex_direction: :column], [
          Element.new(:text, [], ["Line 1"]),
          Element.new(:text, [], ["Line 2"]),
          Element.new(:text, [], ["Line 3"])
        ])

      assert :ok = Renderer.push(tree, pid)

      GenServer.stop(pid)
    end
  end

  describe "push/2 with terminal" do
    test "writes to terminal when not headless" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      tree = Element.new(:text, [], ["Hello"])
      Renderer.push(tree, pid)

      # In normal mode, push doesn't render immediately — need to flush
      Renderer.flush(pid)

      {_input, output} = StringIO.contents(device)
      # Should contain sync markers and rendered content
      assert output =~ "\e[?2026h"
      assert output =~ "\e[?2026l"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end
  end

  describe "resize/3" do
    test "resets front buffer dimensions" do
      pid = start_renderer(width: 20, height: 5)

      # Push something first
      tree = Element.new(:text, [], ["Before"])
      Renderer.push(tree, pid)

      # Resize
      Renderer.resize(40, 10, pid)

      # The current tree remains available for the resize repaint.
      assert Renderer.get_last_tree(pid) == tree

      # Push at new size works
      tree2 = Element.new(:text, [], ["After resize"])
      assert :ok = Renderer.push(tree2, pid)

      GenServer.stop(pid)
    end

    test "resize clears screen when not headless" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      Renderer.resize(40, 10, pid)

      {_input, output} = StringIO.contents(device)
      # Should have clear screen
      assert output =~ "\e[2J"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end
  end

  describe "get_last_tree/1" do
    test "returns nil before any push" do
      pid = start_renderer()
      assert Renderer.get_last_tree(pid) == nil
      GenServer.stop(pid)
    end

    test "returns the most recent tree" do
      pid = start_renderer()

      tree1 = Element.new(:text, [], ["One"])
      tree2 = Element.new(:text, [], ["Two"])

      Renderer.push(tree1, pid)
      Renderer.push(tree2, pid)

      assert Renderer.get_last_tree(pid) == tree2

      GenServer.stop(pid)
    end
  end

  describe "frame batching" do
    test "headless mode renders immediately on push" do
      pid = start_renderer()

      tree = Element.new(:text, [], ["Immediate"])
      Renderer.push(tree, pid)

      # In headless mode, the tree is rendered immediately — front buffer updated
      # We verify by pushing a second tree and checking it renders correctly
      tree2 = Element.new(:text, [], ["Second"])
      Renderer.push(tree2, pid)
      assert Renderer.get_last_tree(pid) == tree2

      GenServer.stop(pid)
    end

    test "normal mode does not render on push — renders on tick" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      tree = Element.new(:text, [], ["Deferred"])
      Renderer.push(tree, pid)

      # Immediately after push, nothing written yet (push only marks dirty)
      {_input, output_before} = StringIO.contents(device)
      refute output_before =~ "\e[?2026h"

      # Wait for tick to fire
      Process.sleep(25)

      {_input, output_after} = StringIO.contents(device)
      assert output_after =~ "\e[?2026h"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "multiple pushes between ticks collapse to one render" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      # Push 3 trees rapidly
      Renderer.push(Element.new(:text, [], ["One"]), pid)
      Renderer.push(Element.new(:text, [], ["Two"]), pid)
      Renderer.push(Element.new(:text, [], ["Three"]), pid)

      # Last tree stored
      assert Renderer.get_last_tree(pid) == Element.new(:text, [], ["Three"])

      # Wait for tick
      Process.sleep(25)

      {_input, output} = StringIO.contents(device)
      # Only one sync begin/end pair — one render, not three
      sync_begins = output |> String.split("\e[?2026h") |> length()
      # split produces N+1 parts for N occurrences
      assert sync_begins == 2

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "tick is no-op when clean" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      # No push — wait for two ticks
      Process.sleep(40)

      {_input, output} = StringIO.contents(device)
      # No sync markers written — tick saw clean state
      refute output =~ "\e[?2026h"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "tick continues after render" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      # First push + tick
      Renderer.push(Element.new(:text, [], ["First"]), pid)
      Process.sleep(25)

      # Second push + tick
      Renderer.push(Element.new(:text, [], ["Second"]), pid)
      Process.sleep(25)

      {_input, output} = StringIO.contents(device)
      # Two sync begin markers — two separate renders
      sync_begins = output |> String.split("\e[?2026h") |> length()
      assert sync_begins == 3

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "resize immediately repaints a pending tree" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      # Push to mark dirty
      Renderer.push(Element.new(:text, [], ["Before"]), pid)

      # Resize before tick fires — should clear dirty
      Renderer.resize(40, 10, pid)

      # Clear device contents so we only see what happens after resize
      {_in, _out} = StringIO.contents(device)

      # Wait for tick
      Process.sleep(25)

      {_input, output} = StringIO.contents(device)
      sync_count = output |> String.split("\e[?2026h") |> length()
      assert sync_count == 2

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end
  end

  describe "flush/1" do
    test "forces immediate render when dirty" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      Renderer.push(Element.new(:text, [], ["Flush me"]), pid)

      # Before flush — not rendered yet
      {_input, output_before} = StringIO.contents(device)
      refute output_before =~ "\e[?2026h"

      # Flush forces render
      assert :ok = Renderer.flush(pid)

      {_input, output_after} = StringIO.contents(device)
      assert output_after =~ "\e[?2026h"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "flush is no-op when clean" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      # No push — flush should be no-op
      assert :ok = Renderer.flush(pid)

      {_input, output} = StringIO.contents(device)
      refute output =~ "\e[?2026h"

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "flush clears dirty so tick does not re-render" do
      %{pid: pid, device: device, terminal: term_name} = start_terminal_renderer()

      Renderer.push(Element.new(:text, [], ["Once"]), pid)
      Renderer.flush(pid)

      # Wait for tick
      Process.sleep(25)

      {_input, output} = StringIO.contents(device)
      # Only one sync pair — from flush, not tick
      sync_count = output |> String.split("\e[?2026h") |> length()
      assert sync_count == 2

      GenServer.stop(pid)
      Courgette.Terminal.stop(term_name)
    end

    test "flush returns :ok for headless renderer" do
      pid = start_renderer()
      assert :ok = Renderer.flush(pid)
      GenServer.stop(pid)
    end
  end
end
