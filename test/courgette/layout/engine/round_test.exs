defmodule Courgette.Layout.Engine.RoundTest do
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine.Round

  defp float_node(x, y, w, h, children \\ []) do
    %{
      element: Element.new(:box),
      x: x,
      y: y,
      width: w,
      height: h,
      children: children
    }
  end

  defp text_node(x, y, w, h) do
    %{
      element: Element.new(:text, [], ["test"]),
      x: x,
      y: y,
      width: w,
      height: h,
      children: []
    }
  end

  # ── Basic rounding ───────────────────────────────────────────────

  describe "to_bounds/2 basic" do
    test "integer values pass through" do
      node = float_node(0.0, 0.0, 80.0, 24.0)
      result = Round.to_bounds(node)

      assert result.bounds == Bounds.new(0, 0, 80, 24)
      assert result.children == []
    end

    test "rounds float coordinates" do
      node = float_node(1.6, 2.4, 33.5, 10.7)
      result = Round.to_bounds(node)

      assert result.bounds == Bounds.new(2, 2, 34, 11)
    end

    test "preserves element" do
      el = Element.new(:box, border: :single)
      node = %{element: el, x: 0.0, y: 0.0, width: 10.0, height: 5.0, children: []}
      result = Round.to_bounds(node)

      assert result.element == el
    end
  end

  # ── Absolute coordinates ──────────────────────────────────────────

  describe "absolute coordinates" do
    test "children get parent offset added" do
      child = float_node(5.0, 3.0, 10.0, 5.0)
      parent = float_node(10.0, 20.0, 80.0, 40.0, [child])

      result = Round.to_bounds(parent)
      c = hd(result.children)

      # Child absolute: parent(10,20) + child(5,3)
      assert c.bounds.x == 15
      assert c.bounds.y == 23
    end

    test "nested grandchildren accumulate offsets" do
      grandchild = float_node(2.0, 1.0, 5.0, 3.0)
      child = float_node(3.0, 2.0, 20.0, 10.0, [grandchild])
      root = float_node(0.0, 0.0, 80.0, 24.0, [child])

      result = Round.to_bounds(root)
      gc = hd(hd(result.children).children)

      # Grandchild absolute: root(0,0) + child(3,2) + gc(2,1)
      assert gc.bounds.x == 5
      assert gc.bounds.y == 3
    end
  end

  # ── Cumulative rounding ──────────────────────────────────────────

  describe "cumulative rounding" do
    test "three equal children fill container without gaps" do
      # 100 / 3 = 33.333...
      c0 = float_node(0.0, 0.0, 33.333, 10.0)
      c1 = float_node(33.333, 0.0, 33.333, 10.0)
      c2 = float_node(66.667, 0.0, 33.333, 10.0)

      parent = float_node(0.0, 0.0, 100.0, 10.0, [c0, c1, c2])
      result = Round.to_bounds(parent)

      [r0, r1, r2] = Enum.sort_by(result.children, & &1.bounds.x)

      # All should be adjacent with no gaps
      assert r0.bounds.x == 0
      assert r1.bounds.x == r0.bounds.x + r0.bounds.width
      assert r2.bounds.x == r1.bounds.x + r1.bounds.width
    end

    test "two equal children in column fill without gaps" do
      c0 = float_node(0.0, 0.0, 80.0, 12.0)
      c1 = float_node(0.0, 12.0, 80.0, 12.0)

      parent = float_node(0.0, 0.0, 80.0, 24.0, [c0, c1])
      result = Round.to_bounds(parent)

      [r0, r1] = Enum.sort_by(result.children, & &1.bounds.y)

      assert r0.bounds.y == 0
      assert r1.bounds.y == r0.bounds.y + r0.bounds.height
    end
  end

  # ── Edge cases ───────────────────────────────────────────────────

  describe "edge cases" do
    test "zero-size node" do
      node = float_node(0.0, 0.0, 0.0, 0.0)
      result = Round.to_bounds(node)

      assert result.bounds == Bounds.new(0, 0, 0, 0)
    end

    test "text element preserved" do
      node = text_node(5.0, 3.0, 10.0, 1.0)
      result = Round.to_bounds(node)

      assert result.element.type == :text
      assert result.bounds == Bounds.new(5, 3, 10, 1)
    end

    test "single child does not need gap correction" do
      child = float_node(1.0, 1.0, 10.0, 5.0)
      parent = float_node(0.0, 0.0, 20.0, 10.0, [child])
      result = Round.to_bounds(parent)

      c = hd(result.children)
      assert c.bounds == Bounds.new(1, 1, 10, 5)
    end
  end
end
