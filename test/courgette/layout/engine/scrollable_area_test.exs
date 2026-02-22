defmodule Courgette.Layout.Engine.ScrollableAreaTest do
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.Layout.Engine.Flex

  defp scrollable(props, children \\ []) do
    Element.new(:scrollable_area, props, children)
  end

  defp box(props, children \\ []) do
    Element.new(:box, props, children)
  end

  defp text(content, props \\ []) do
    Element.new(:text, props, [content])
  end

  defp child(result, idx), do: Enum.at(result.children, idx)

  # ── Flex.layout level ──────────────────────────────────────────────

  describe "Flex.layout with scrollable_area" do
    test "empty scrollable area has no children" do
      el = box([width: 40, height: 10], [
        scrollable([flex: 1])
      ])

      result = Flex.layout(el, %{width: 40.0, height: 10.0})
      sa = child(result, 0)

      assert sa.children == []
    end

    test "children can exceed viewport height" do
      # Viewport is 5 rows, but children total 10 rows
      el = box([width: 20, height: 5], [
        scrollable([flex: 1], [
          box([height: 4]),
          box([height: 3]),
          box([height: 3])
        ])
      ])

      result = Flex.layout(el, %{width: 20.0, height: 5.0})
      sa = child(result, 0)

      # All three children present, not compressed
      assert length(sa.children) == 3

      # Total child height exceeds viewport
      total_h = Enum.reduce(sa.children, 0, fn c, acc -> acc + c.height end)
      assert total_h == 10.0
    end

    test "children laid out in column regardless of parent direction" do
      # Parent is row, scrollable_area should still use column internally
      el = box([width: 40, height: 10, flex_direction: :row], [
        scrollable([flex: 1], [
          text("Line 1"),
          text("Line 2"),
          text("Line 3")
        ])
      ])

      result = Flex.layout(el, %{width: 40.0, height: 10.0})
      sa = child(result, 0)

      # Children stacked vertically (sequential y positions)
      c0 = Enum.at(sa.children, 0)
      c1 = Enum.at(sa.children, 1)
      c2 = Enum.at(sa.children, 2)

      assert c0.y < c1.y
      assert c1.y < c2.y
      # All at x=0 (column layout)
      assert c0.x == 0.0
      assert c1.x == 0.0
    end

    test "children have correct sequential y positions" do
      el = box([width: 20, height: 10], [
        scrollable([flex: 1], [
          box([height: 3]),
          box([height: 2]),
          box([height: 4])
        ])
      ])

      result = Flex.layout(el, %{width: 20.0, height: 10.0})
      sa = child(result, 0)

      c0 = Enum.at(sa.children, 0)
      c1 = Enum.at(sa.children, 1)
      c2 = Enum.at(sa.children, 2)

      assert c0.y == 0.0
      assert c0.height == 3.0
      assert c1.y == 3.0
      assert c1.height == 2.0
      assert c2.y == 5.0
      assert c2.height == 4.0
    end

    test "scrollable area own bounds equal viewport dimensions" do
      el = box([width: 40, height: 10], [
        scrollable([flex: 1], [
          box([height: 30])
        ])
      ])

      result = Flex.layout(el, %{width: 40.0, height: 10.0})
      sa = child(result, 0)

      # The scrollable area itself keeps its viewport size
      assert sa.width == 40.0
      assert sa.height == 10.0
    end

    test "works with borders — children get inner width" do
      el = box([width: 22, height: 10], [
        scrollable([flex: 1, border: :single], [
          box([height: 3]),
          box([height: 3])
        ])
      ])

      result = Flex.layout(el, %{width: 22.0, height: 10.0})
      sa = child(result, 0)

      # Scrollable area is 22 wide, 10 tall
      assert sa.width == 22.0
      assert sa.height == 10.0

      # Children should be inside borders (22 - 2 = 20 wide)
      c0 = Enum.at(sa.children, 0)
      assert c0.width == 20.0
    end

    test "mixed children: text and box" do
      el = box([width: 30, height: 8], [
        scrollable([flex: 1], [
          text("Header line"),
          box([height: 5, bg: :blue]),
          text("Footer line")
        ])
      ])

      result = Flex.layout(el, %{width: 30.0, height: 8.0})
      sa = child(result, 0)

      assert length(sa.children) == 3
      # Text children have height 1, box has height 5
      c0 = Enum.at(sa.children, 0)
      c1 = Enum.at(sa.children, 1)
      c2 = Enum.at(sa.children, 2)

      assert c0.height == 1.0
      assert c1.height == 5.0
      assert c2.height == 1.0
    end

    test "single child taller than viewport" do
      el = box([width: 20, height: 5], [
        scrollable([flex: 1], [
          box([height: 50])
        ])
      ])

      result = Flex.layout(el, %{width: 20.0, height: 5.0})
      sa = child(result, 0)

      c0 = Enum.at(sa.children, 0)
      assert c0.height == 50.0
      # Scrollable area itself is viewport-sized
      assert sa.height == 5.0
    end
  end

  # ── Engine.compute level ───────────────────────────────────────────

  describe "Engine.compute with scrollable_area" do
    test "produces integer Bounds for scrollable area and children" do
      el = box([width: 40, height: 10], [
        scrollable([flex: 1], [
          box([height: 3]),
          box([height: 4]),
          box([height: 5])
        ])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 10))
      sa = hd(result.children)

      assert %Bounds{} = sa.bounds
      assert sa.bounds.width == 40
      assert sa.bounds.height == 10

      # Children have integer bounds
      Enum.each(sa.children, fn child ->
        assert %Bounds{} = child.bounds
        assert is_integer(child.bounds.x)
        assert is_integer(child.bounds.y)
        assert is_integer(child.bounds.width)
        assert is_integer(child.bounds.height)
      end)
    end

    test "children y-positions are absolute coordinates" do
      el = box([width: 40, height: 10], [
        scrollable([flex: 1], [
          box([height: 3]),
          box([height: 4])
        ])
      ])

      result = Engine.compute(el, Bounds.new(5, 2, 40, 10))
      sa = hd(result.children)

      c0 = Enum.at(sa.children, 0)
      c1 = Enum.at(sa.children, 1)

      # Children offset by parent origin
      assert c0.bounds.x == 5
      assert c0.bounds.y == 2
      assert c1.bounds.y == 5  # 2 + 3
    end

    test "children overflow viewport height (not clamped)" do
      el = box([width: 20, height: 5], [
        scrollable([flex: 1], [
          box([height: 10]),
          box([height: 10])
        ])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 20, 5))
      sa = hd(result.children)

      total_h = Enum.reduce(sa.children, 0, fn c, acc -> acc + c.bounds.height end)
      assert total_h == 20
      assert sa.bounds.height == 5
    end
  end
end
