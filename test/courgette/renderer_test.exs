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

  describe "start_link/1" do
    test "starts headless renderer" do
      pid = start_renderer()
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "push/2" do
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
      {:ok, device} = StringIO.open("")
      term_name = :"term_renderer_#{:erlang.unique_integer([:positive])}"

      {:ok, _term} =
        Courgette.Terminal.start_link(
          skip_raw_mode: true,
          device: device,
          name: term_name
        )

      pid = start_renderer(headless: false, terminal: term_name)

      tree = Element.new(:text, [], ["Hello"])
      Renderer.push(tree, pid)

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

      # Last tree is cleared on resize
      assert Renderer.get_last_tree(pid) == nil

      # Push at new size works
      tree2 = Element.new(:text, [], ["After resize"])
      assert :ok = Renderer.push(tree2, pid)

      GenServer.stop(pid)
    end

    test "resize clears screen when not headless" do
      {:ok, device} = StringIO.open("")
      term_name = :"term_resize_#{:erlang.unique_integer([:positive])}"

      {:ok, _term} =
        Courgette.Terminal.start_link(
          skip_raw_mode: true,
          device: device,
          name: term_name
        )

      pid = start_renderer(headless: false, terminal: term_name, width: 20, height: 5)

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
end
