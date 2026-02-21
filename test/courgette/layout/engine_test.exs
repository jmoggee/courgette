defmodule Courgette.Layout.EngineTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.Painter

  # ── Basic compute ─────────────────────────────────────────────────

  describe "compute/2 basic" do
    test "returns layout tree with Bounds" do
      el = Element.new(:box, width: 80, height: 24)
      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      assert %Bounds{} = result.bounds
      assert result.bounds.x == 0
      assert result.bounds.y == 0
      assert result.bounds.width == 80
      assert result.bounds.height == 24
    end

    test "respects root bounds offset" do
      el = Element.new(:box, width: 40, height: 12)
      result = Engine.compute(el, Bounds.new(5, 3, 40, 12))

      assert result.bounds.x == 5
      assert result.bounds.y == 3
    end

    test "children have absolute coordinates" do
      el = Element.new(:box, [width: 80, height: 24, border: :single], [
        Element.new(:box, width: 10, height: 5)
      ])

      result = Engine.compute(el, Bounds.new(10, 5, 80, 24))
      child = hd(result.children)

      # Child should be offset by root_bounds origin + parent border
      assert child.bounds.x == 11
      assert child.bounds.y == 6
    end

    test "all values are non-negative integers" do
      el = Element.new(:box, [width: 80, height: 24], [
        Element.new(:box, flex: 1),
        Element.new(:box, flex: 1),
        Element.new(:box, flex: 1)
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      Enum.each(result.children, fn child ->
        assert is_integer(child.bounds.x)
        assert is_integer(child.bounds.y)
        assert is_integer(child.bounds.width)
        assert is_integer(child.bounds.height)
        assert child.bounds.x >= 0
        assert child.bounds.y >= 0
        assert child.bounds.width >= 0
        assert child.bounds.height >= 0
      end)
    end
  end

  # ── Flex grow with integers ───────────────────────────────────────

  describe "flex grow integer results" do
    test "two equal children in 80-wide container" do
      el = Element.new(:box, [width: 80, height: 24], [
        Element.new(:box, flex: 1),
        Element.new(:box, flex: 1)
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))
      [c0, c1] = result.children

      assert c0.bounds.width == 40
      assert c1.bounds.width == 40
      assert c0.bounds.x == 0
      assert c1.bounds.x == 40
    end

    test "three equal children in 100-wide container" do
      el = Element.new(:box, [width: 100, height: 10], [
        Element.new(:box, flex: 1),
        Element.new(:box, flex: 1),
        Element.new(:box, flex: 1)
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 100, 10))
      [c0, c1, c2] = result.children

      # 100/3 = 33.33..., cumulative rounding should make these adjacent
      assert c0.bounds.x + c0.bounds.width == c1.bounds.x
      assert c1.bounds.x + c1.bounds.width == c2.bounds.x
      total = c0.bounds.width + c1.bounds.width + c2.bounds.width
      # Should approximately fill container
      assert total >= 99
      assert total <= 100
    end
  end

  # ── Painter compatibility ─────────────────────────────────────────

  describe "Painter compatibility" do
    test "compute output works with Painter.paint" do
      el = Element.new(:box, [width: 40, height: 12, border: :single, bg: :blue], [
        Element.new(:text, [color: :green], ["Hello"])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 12))
      buffer = Buffer.new(40, 12)
      painted = Painter.paint(result, buffer)

      # Border corner should be painted
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "┌"

      # Background should be painted
      cell = Buffer.get_cell(painted, 2, 2)
      assert cell.bg == :blue
    end

    test "nested layout works with Painter" do
      el = Element.new(:box, [width: 40, height: 12, border: :single], [
        Element.new(:box, [width: 20, height: 5, border: :rounded, border_color: :cyan], [
          Element.new(:text, [color: :yellow], ["Nested"])
        ])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 12))
      buffer = Buffer.new(40, 12)
      painted = Painter.paint(result, buffer)

      # Outer border
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "┌"

      # Inner border (offset by outer border)
      cell = Buffer.get_cell(painted, 1, 1)
      assert cell.grapheme == "╭"
      assert cell.fg == :cyan

      # Text inside nested box
      cell = Buffer.get_cell(painted, 2, 2)
      assert cell.grapheme == "N"
      assert cell.fg == :yellow
    end

    test "column layout with text nodes" do
      el = Element.new(:box, [width: 40, height: 10, flex_direction: :column, align_items: :flex_start], [
        Element.new(:text, [], ["Line one"]),
        Element.new(:text, [], ["Line two"])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 10))
      buffer = Buffer.new(40, 10)
      painted = Painter.paint(result, buffer)

      # First line
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "L"

      # Second line
      cell = Buffer.get_cell(painted, 0, 1)
      assert cell.grapheme == "L"
    end

    test "dashboard layout with header, sidebar, content" do
      header = Element.new(:text, [color: :bright_white, bold: true, height: 1], ["Dashboard"])

      sidebar = Element.new(:box, [width: 12, border: :single, flex_direction: :column, align_items: :flex_start], [
        Element.new(:text, [color: :cyan], ["Menu"])
      ])

      content = Element.new(:box, [flex: 1, border: :rounded, bg: :black, align_items: :flex_start], [
        Element.new(:text, [], ["Welcome!"])
      ])

      el = Element.new(:box, [width: 40, height: 12, flex_direction: :column], [
        header,
        Element.new(:box, [flex: 1], [sidebar, content])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 12))
      buffer = Buffer.new(40, 12)
      painted = Painter.paint(result, buffer)

      # Header text should be at top
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "D"
      assert cell.fg == :bright_white
    end
  end

  # ── Edge cases ───────────────────────────────────────────────────

  describe "edge cases" do
    test "empty container" do
      el = Element.new(:box, width: 80, height: 24)
      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      assert result.children == []
    end

    test "single text element" do
      el = Element.new(:text, [], ["Hello"])
      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      assert result.bounds.width == 5
      assert result.bounds.height == 1
    end

    test "container with only text children" do
      el = Element.new(:box, [width: 80, height: 24, align_items: :flex_start], [
        Element.new(:text, [], ["A"]),
        Element.new(:text, [], ["B"]),
        Element.new(:text, [], ["C"])
      ])

      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      assert length(result.children) == 3
      [a, b, c] = result.children
      assert a.bounds.width == 1
      assert b.bounds.x == 1
      assert c.bounds.x == 2
    end
  end
end
