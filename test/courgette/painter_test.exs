defmodule Courgette.PainterTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Painter

  # ── Helpers ──────────────────────────────────────────────────────

  defp layout_node(type, props, bounds, children \\ []) do
    %{
      element: Element.new(type, props),
      bounds: bounds,
      children: children
    }
  end

  defp text_node(text, props, bounds) do
    %{
      element: Element.new(:text, props, List.wrap(text)),
      bounds: bounds,
      children: []
    }
  end

  defp grapheme_at(buffer, x, y) do
    cell = Buffer.get_cell(buffer, x, y)
    cell && cell.grapheme
  end

  defp fg_at(buffer, x, y) do
    cell = Buffer.get_cell(buffer, x, y)
    cell && cell.fg
  end

  defp bg_at(buffer, x, y) do
    cell = Buffer.get_cell(buffer, x, y)
    cell && cell.bg
  end

  defp style_at(buffer, x, y) do
    cell = Buffer.get_cell(buffer, x, y)
    cell && cell.style
  end

  # ── nil / empty ──────────────────────────────────────────────────

  describe "paint/2 with nil" do
    test "nil tree returns buffer unchanged" do
      buffer = Buffer.new(10, 5)
      assert Painter.paint(nil, buffer) == buffer
    end
  end

  describe "paint/2 with empty box" do
    test "empty box with no props leaves buffer unchanged" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [], Bounds.new(0, 0, 10, 5))
      assert Painter.paint(node, buffer) == buffer
    end
  end

  # ── Text painting ───────────────────────────────────────────────

  describe "text painting" do
    test "paints text at bounds position" do
      buffer = Buffer.new(20, 5)
      node = text_node("Hello", [], Bounds.new(3, 1, 10, 1))
      result = Painter.paint(node, buffer)

      assert grapheme_at(result, 3, 1) == "H"
      assert grapheme_at(result, 4, 1) == "e"
      assert grapheme_at(result, 5, 1) == "l"
      assert grapheme_at(result, 6, 1) == "l"
      assert grapheme_at(result, 7, 1) == "o"
      # After text ends, original empty cell
      assert grapheme_at(result, 8, 1) == " "
    end

    test "paints text with foreground color" do
      buffer = Buffer.new(20, 5)
      node = text_node("Hi", [color: :green], Bounds.new(0, 0, 10, 1))
      result = Painter.paint(node, buffer)

      assert fg_at(result, 0, 0) == :green
      assert fg_at(result, 1, 0) == :green
      # Unpainted cell has no color
      assert fg_at(result, 2, 0) == nil
    end

    test "paints text with background color" do
      buffer = Buffer.new(20, 5)
      node = text_node("AB", [bg: :red], Bounds.new(0, 0, 10, 1))
      result = Painter.paint(node, buffer)

      assert bg_at(result, 0, 0) == :red
      assert bg_at(result, 1, 0) == :red
    end

    test "paints text with styles" do
      buffer = Buffer.new(20, 5)
      node = text_node("X", [bold: true, italic: true], Bounds.new(0, 0, 10, 1))
      result = Painter.paint(node, buffer)

      assert style_at(result, 0, 0) == %{bold: true, italic: true}
    end

    test "paints text with 256-color" do
      buffer = Buffer.new(20, 5)
      node = text_node("Z", [color: 196], Bounds.new(0, 0, 10, 1))
      result = Painter.paint(node, buffer)

      assert fg_at(result, 0, 0) == 196
    end

    test "paints text with RGB color" do
      buffer = Buffer.new(20, 5)
      node = text_node("Z", [color: {255, 128, 0}], Bounds.new(0, 0, 10, 1))
      result = Painter.paint(node, buffer)

      assert fg_at(result, 0, 0) == {255, 128, 0}
    end

    test "concatenates multiple string children" do
      buffer = Buffer.new(20, 5)

      node = %{
        element: Element.new(:text, [], ["Hello", " ", "world"]),
        bounds: Bounds.new(0, 0, 20, 1),
        children: []
      }

      result = Painter.paint(node, buffer)

      assert grapheme_at(result, 0, 0) == "H"
      assert grapheme_at(result, 5, 0) == " "
      assert grapheme_at(result, 6, 0) == "w"
      assert grapheme_at(result, 10, 0) == "d"
    end

    test "empty text leaves buffer unchanged" do
      buffer = Buffer.new(10, 5)
      node = text_node("", [], Bounds.new(0, 0, 10, 1))
      assert Painter.paint(node, buffer) == buffer
    end
  end

  # ── Background fill ─────────────────────────────────────────────

  describe "background fill" do
    test "box with bg fills its bounds" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [bg: :blue], Bounds.new(2, 1, 4, 3))
      result = Painter.paint(node, buffer)

      # Inside the box
      for y <- 1..3, x <- 2..5 do
        assert bg_at(result, x, y) == :blue,
               "expected blue bg at (#{x}, #{y})"
      end

      # Outside the box
      assert bg_at(result, 0, 0) == nil
      assert bg_at(result, 6, 1) == nil
    end

    test "box without bg does not fill" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [], Bounds.new(0, 0, 10, 5))
      assert Painter.paint(node, buffer) == buffer
    end
  end

  # ── Border drawing ──────────────────────────────────────────────

  describe "single border" do
    setup do
      buffer = Buffer.new(20, 10)
      node = layout_node(:box, [border: :single], Bounds.new(2, 1, 8, 5))
      %{result: Painter.paint(node, buffer)}
    end

    test "corners", %{result: r} do
      assert grapheme_at(r, 2, 1) == "┌"
      assert grapheme_at(r, 9, 1) == "┐"
      assert grapheme_at(r, 2, 5) == "└"
      assert grapheme_at(r, 9, 5) == "┘"
    end

    test "horizontal edges", %{result: r} do
      for x <- 3..8 do
        assert grapheme_at(r, x, 1) == "─", "top edge at x=#{x}"
        assert grapheme_at(r, x, 5) == "─", "bottom edge at x=#{x}"
      end
    end

    test "vertical edges", %{result: r} do
      for y <- 2..4 do
        assert grapheme_at(r, 2, y) == "│", "left edge at y=#{y}"
        assert grapheme_at(r, 9, y) == "│", "right edge at y=#{y}"
      end
    end

    test "interior is not touched", %{result: r} do
      for y <- 2..4, x <- 3..8 do
        assert grapheme_at(r, x, y) == " ", "interior at (#{x}, #{y})"
      end
    end
  end

  describe "double border" do
    setup do
      buffer = Buffer.new(20, 10)
      node = layout_node(:box, [border: :double], Bounds.new(0, 0, 6, 4))
      %{result: Painter.paint(node, buffer)}
    end

    test "corners", %{result: r} do
      assert grapheme_at(r, 0, 0) == "╔"
      assert grapheme_at(r, 5, 0) == "╗"
      assert grapheme_at(r, 0, 3) == "╚"
      assert grapheme_at(r, 5, 3) == "╝"
    end

    test "horizontal edges", %{result: r} do
      for x <- 1..4 do
        assert grapheme_at(r, x, 0) == "═"
        assert grapheme_at(r, x, 3) == "═"
      end
    end

    test "vertical edges", %{result: r} do
      for y <- 1..2 do
        assert grapheme_at(r, 0, y) == "║"
        assert grapheme_at(r, 5, y) == "║"
      end
    end
  end

  describe "rounded border" do
    setup do
      buffer = Buffer.new(20, 10)
      node = layout_node(:box, [border: :rounded], Bounds.new(0, 0, 6, 4))
      %{result: Painter.paint(node, buffer)}
    end

    test "corners", %{result: r} do
      assert grapheme_at(r, 0, 0) == "╭"
      assert grapheme_at(r, 5, 0) == "╮"
      assert grapheme_at(r, 0, 3) == "╰"
      assert grapheme_at(r, 5, 3) == "╯"
    end

    test "horizontal edges use single-style lines", %{result: r} do
      for x <- 1..4 do
        assert grapheme_at(r, x, 0) == "─"
      end
    end

    test "vertical edges use single-style lines", %{result: r} do
      for y <- 1..2 do
        assert grapheme_at(r, 0, y) == "│"
      end
    end
  end

  describe "border color" do
    test "border cells have the specified color" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [border: :single, border_color: :cyan], Bounds.new(0, 0, 6, 4))
      result = Painter.paint(node, buffer)

      # Corners
      assert fg_at(result, 0, 0) == :cyan
      assert fg_at(result, 5, 0) == :cyan
      # Horizontal edge
      assert fg_at(result, 1, 0) == :cyan
      # Vertical edge
      assert fg_at(result, 0, 1) == :cyan
    end

    test "border without border_color uses default (nil)" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [border: :single], Bounds.new(0, 0, 6, 4))
      result = Painter.paint(node, buffer)

      assert fg_at(result, 0, 0) == nil
    end
  end

  describe "border edge cases" do
    test "2x2 box has only corners, no edges" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [border: :single], Bounds.new(0, 0, 2, 2))
      result = Painter.paint(node, buffer)

      assert grapheme_at(result, 0, 0) == "┌"
      assert grapheme_at(result, 1, 0) == "┐"
      assert grapheme_at(result, 0, 1) == "└"
      assert grapheme_at(result, 1, 1) == "┘"
    end

    test "1x1 box paints all four corners at same position" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [border: :single], Bounds.new(0, 0, 1, 1))
      result = Painter.paint(node, buffer)

      # The last corner written wins (bottom-right)
      cell = Buffer.get_cell(result, 0, 0)
      assert cell.grapheme == "┘"
    end
  end

  # ── Box with bg + border ─────────────────────────────────────────

  describe "box with bg and border" do
    test "border is drawn on top of background" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:box, [bg: :blue, border: :single, border_color: :white],
               Bounds.new(0, 0, 6, 4))
      result = Painter.paint(node, buffer)

      # Corners have border graphemes
      assert grapheme_at(result, 0, 0) == "┌"
      # Interior has background
      assert bg_at(result, 2, 1) == :blue
      # Border cells have border color, not background
      assert fg_at(result, 0, 0) == :white
    end
  end

  # ── Recursive children ─────────────────────────────────────────

  describe "recursive child painting" do
    test "children are painted after parent" do
      buffer = Buffer.new(20, 10)

      child = text_node("Hi", [color: :green], Bounds.new(3, 2, 10, 1))
      parent = layout_node(:box, [border: :single], Bounds.new(1, 0, 16, 6), [child])

      result = Painter.paint(parent, buffer)

      # Parent border
      assert grapheme_at(result, 1, 0) == "┌"
      # Child text
      assert grapheme_at(result, 3, 2) == "H"
      assert grapheme_at(result, 4, 2) == "i"
      assert fg_at(result, 3, 2) == :green
    end

    test "multiple children at different positions" do
      buffer = Buffer.new(30, 10)

      child1 = text_node("AAA", [], Bounds.new(0, 0, 10, 1))
      child2 = text_node("BBB", [], Bounds.new(0, 2, 10, 1))

      parent = layout_node(:box, [], Bounds.new(0, 0, 30, 10), [child1, child2])
      result = Painter.paint(parent, buffer)

      assert grapheme_at(result, 0, 0) == "A"
      assert grapheme_at(result, 0, 2) == "B"
    end

    test "nested boxes" do
      buffer = Buffer.new(30, 15)

      inner_text = text_node("OK", [color: :green], Bounds.new(5, 4, 10, 1))
      inner_box = layout_node(:box, [border: :rounded], Bounds.new(3, 2, 12, 6), [inner_text])
      outer_box = layout_node(:box, [border: :single], Bounds.new(1, 0, 20, 10), [inner_box])

      result = Painter.paint(outer_box, buffer)

      # Outer border
      assert grapheme_at(result, 1, 0) == "┌"
      # Inner border
      assert grapheme_at(result, 3, 2) == "╭"
      # Inner text
      assert grapheme_at(result, 5, 4) == "O"
      assert grapheme_at(result, 6, 4) == "K"
      assert fg_at(result, 5, 4) == :green
    end

    test "deeply nested (3 levels)" do
      buffer = Buffer.new(40, 20)

      text = text_node("Deep", [], Bounds.new(10, 5, 10, 1))
      level2 = layout_node(:box, [border: :double], Bounds.new(8, 3, 15, 8), [text])
      level1 = layout_node(:box, [border: :single], Bounds.new(5, 1, 25, 15), [level2])
      root = layout_node(:box, [], Bounds.new(0, 0, 40, 20), [level1])

      result = Painter.paint(root, buffer)

      assert grapheme_at(result, 5, 1) == "┌"
      assert grapheme_at(result, 8, 3) == "╔"
      assert grapheme_at(result, 10, 5) == "D"
    end
  end

  # ── Clipping ─────────────────────────────────────────────────────

  describe "clipping" do
    test "child text outside parent bounds is not painted" do
      buffer = Buffer.new(20, 10)

      # Child extends beyond parent's right edge
      child = text_node("Hello World", [], Bounds.new(3, 1, 20, 1))
      parent = layout_node(:box, [], Bounds.new(0, 0, 8, 5), [child])

      result = Painter.paint(parent, buffer)

      # Within parent bounds
      assert grapheme_at(result, 3, 1) == "H"
      assert grapheme_at(result, 7, 1) == "o"
      # Outside parent bounds — not painted
      assert grapheme_at(result, 8, 1) == " "
    end

    test "child completely outside parent bounds is not painted" do
      buffer = Buffer.new(30, 10)

      child = text_node("Hidden", [], Bounds.new(20, 0, 10, 1))
      parent = layout_node(:box, [], Bounds.new(0, 0, 10, 5), [child])

      result = Painter.paint(parent, buffer)

      # Text should not be painted anywhere
      assert grapheme_at(result, 20, 0) == " "
    end

    test "child partially below parent bounds is clipped vertically" do
      buffer = Buffer.new(20, 10)

      child = text_node("Y", [], Bounds.new(0, 5, 10, 1))
      parent = layout_node(:box, [], Bounds.new(0, 0, 20, 5), [child])

      result = Painter.paint(parent, buffer)

      # Row 5 is outside parent (height=5 means rows 0-4)
      assert grapheme_at(result, 0, 5) == " "
    end

    test "nested clipping — grandchild clipped by grandparent" do
      buffer = Buffer.new(30, 15)

      # Grandchild text that extends beyond mid's bounds
      text = text_node("ABCDEFGHIJ", [], Bounds.new(5, 3, 20, 1))
      # Mid box allows only x=3..12
      mid = layout_node(:box, [], Bounds.new(3, 1, 10, 8), [text])
      # Root allows x=0..29 (not a constraint here)
      root = layout_node(:box, [], Bounds.new(0, 0, 30, 15), [mid])

      result = Painter.paint(root, buffer)

      # Within mid's bounds: x=5..12
      assert grapheme_at(result, 5, 3) == "A"
      assert grapheme_at(result, 12, 3) == "H"
      # Outside mid's bounds: x=13 is past mid (x=3, w=10 → max x=12)
      assert grapheme_at(result, 13, 3) == " "
    end

    test "border drawing respects clipping" do
      buffer = Buffer.new(20, 10)

      # Box border at (5,2, 10x6) inside a parent that only covers (0,0, 12x10)
      child = layout_node(:box, [border: :single], Bounds.new(5, 2, 10, 6))
      parent = layout_node(:box, [], Bounds.new(0, 0, 12, 10), [child])

      result = Painter.paint(parent, buffer)

      # Left and top corners are within clip
      assert grapheme_at(result, 5, 2) == "┌"
      # Right side at x=14 is beyond parent width of 12
      assert grapheme_at(result, 14, 2) == " "
      # But x=11 (within clip) should have horizontal edge
      assert grapheme_at(result, 11, 2) == "─"
    end
  end

  # ── Other element types ─────────────────────────────────────────

  describe "unhandled element types" do
    test "grid element is a no-op (for now)" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:grid, [], Bounds.new(0, 0, 10, 5))
      assert Painter.paint(node, buffer) == buffer
    end

    test "button element is a no-op (for now)" do
      buffer = Buffer.new(10, 5)
      node = layout_node(:button, [], Bounds.new(0, 0, 10, 1))
      assert Painter.paint(node, buffer) == buffer
    end
  end

  # ── Overflow: scroll ────────────────────────────────────────────

  describe "overflow: :scroll on box" do
    test "scroll_offset=0 shows top content" do
      buffer = Buffer.new(20, 5)

      children = [
        text_node("Line 0", [], Bounds.new(0, 0, 6, 1)),
        text_node("Line 1", [], Bounds.new(0, 1, 6, 1)),
        text_node("Line 2", [], Bounds.new(0, 2, 6, 1)),
        text_node("Line 3", [], Bounds.new(0, 3, 6, 1)),
        text_node("Line 4", [], Bounds.new(0, 4, 6, 1)),
        text_node("Line 5", [], Bounds.new(0, 5, 6, 1)),
        text_node("Line 6", [], Bounds.new(0, 6, 6, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 0, overflow: :scroll], Bounds.new(0, 0, 20, 5), children)
      result = Painter.paint(sa, buffer)

      assert grapheme_at(result, 0, 0) == "L"
      assert grapheme_at(result, 5, 0) == "0"
      assert grapheme_at(result, 5, 4) == "4"
      # Line 5 and 6 are below viewport — not visible
    end

    test "scroll_offset shifts content up" do
      buffer = Buffer.new(20, 5)

      children = [
        text_node("AAA", [], Bounds.new(0, 0, 3, 1)),
        text_node("BBB", [], Bounds.new(0, 1, 3, 1)),
        text_node("CCC", [], Bounds.new(0, 2, 3, 1)),
        text_node("DDD", [], Bounds.new(0, 3, 3, 1)),
        text_node("EEE", [], Bounds.new(0, 4, 3, 1)),
        text_node("FFF", [], Bounds.new(0, 5, 3, 1)),
        text_node("GGG", [], Bounds.new(0, 6, 3, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 2, overflow: :scroll], Bounds.new(0, 0, 20, 5), children)
      result = Painter.paint(sa, buffer)

      # With offset=2, row 0 shows "CCC" (originally at y=2)
      assert grapheme_at(result, 0, 0) == "C"
      assert grapheme_at(result, 0, 1) == "D"
      assert grapheme_at(result, 0, 2) == "E"
      assert grapheme_at(result, 0, 3) == "F"
      assert grapheme_at(result, 0, 4) == "G"
    end

    test "content above viewport is clipped after shift" do
      buffer = Buffer.new(20, 3)

      children = [
        text_node("TOP", [], Bounds.new(0, 0, 3, 1)),
        text_node("MID", [], Bounds.new(0, 1, 3, 1)),
        text_node("BOT", [], Bounds.new(0, 2, 3, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 2, overflow: :scroll], Bounds.new(0, 0, 20, 3), children)
      result = Painter.paint(sa, buffer)

      # Only "BOT" is visible at row 0; TOP and MID shifted above viewport
      assert grapheme_at(result, 0, 0) == "B"
      assert grapheme_at(result, 1, 0) == "O"
      assert grapheme_at(result, 2, 0) == "T"
      # Rows 1 and 2 are empty
      assert grapheme_at(result, 0, 1) == " "
    end

    test "content below viewport is clipped" do
      buffer = Buffer.new(20, 3)

      children = [
        text_node("AAA", [], Bounds.new(0, 0, 3, 1)),
        text_node("BBB", [], Bounds.new(0, 1, 3, 1)),
        text_node("CCC", [], Bounds.new(0, 2, 3, 1)),
        text_node("DDD", [], Bounds.new(0, 3, 3, 1)),
        text_node("EEE", [], Bounds.new(0, 4, 3, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 0, overflow: :scroll], Bounds.new(0, 0, 20, 3), children)
      result = Painter.paint(sa, buffer)

      # Only first 3 lines visible
      assert grapheme_at(result, 0, 0) == "A"
      assert grapheme_at(result, 0, 1) == "B"
      assert grapheme_at(result, 0, 2) == "C"
    end

    test "large offset shows bottom content" do
      buffer = Buffer.new(20, 3)

      children = [
        text_node("AAA", [], Bounds.new(0, 0, 3, 1)),
        text_node("BBB", [], Bounds.new(0, 1, 3, 1)),
        text_node("CCC", [], Bounds.new(0, 2, 3, 1)),
        text_node("DDD", [], Bounds.new(0, 3, 3, 1)),
        text_node("EEE", [], Bounds.new(0, 4, 3, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 2, overflow: :scroll], Bounds.new(0, 0, 20, 3), children)
      result = Painter.paint(sa, buffer)

      assert grapheme_at(result, 0, 0) == "C"
      assert grapheme_at(result, 0, 1) == "D"
      assert grapheme_at(result, 0, 2) == "E"
    end

    test "offset beyond content shows empty viewport" do
      buffer = Buffer.new(20, 3)

      children = [
        text_node("AAA", [], Bounds.new(0, 0, 3, 1)),
        text_node("BBB", [], Bounds.new(0, 1, 3, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 10, overflow: :scroll], Bounds.new(0, 0, 20, 3), children)
      result = Painter.paint(sa, buffer)

      # All content shifted above viewport
      assert grapheme_at(result, 0, 0) == " "
      assert grapheme_at(result, 0, 1) == " "
      assert grapheme_at(result, 0, 2) == " "
    end

    test "border renders correctly with scrolled content" do
      buffer = Buffer.new(12, 5)

      children = [
        text_node("Hello", [], Bounds.new(1, 1, 5, 1)),
        text_node("World", [], Bounds.new(1, 2, 5, 1)),
        text_node("Foo!!", [], Bounds.new(1, 3, 5, 1))
      ]

      sa = layout_node(:box, [border: :single, scroll_offset: 1, overflow: :scroll],
             Bounds.new(0, 0, 12, 5), children)
      result = Painter.paint(sa, buffer)

      # Border is at viewport bounds (unshifted)
      assert grapheme_at(result, 0, 0) == "┌"
      assert grapheme_at(result, 11, 0) == "┐"
      assert grapheme_at(result, 0, 4) == "└"
      assert grapheme_at(result, 11, 4) == "┘"

      # Content shifted by -1: "World" (y=2 -> y=1) visible inside border
      assert grapheme_at(result, 1, 1) == "W"
      assert grapheme_at(result, 1, 2) == "F"
    end

    test "border not overwritten by shifted content" do
      buffer = Buffer.new(12, 4)

      # Content at y=0 shifted by -0 means it's at y=0 (top border row)
      children = [
        text_node("XXXXXXXX", [], Bounds.new(1, 0, 8, 1)),
        text_node("YYYYYYYY", [], Bounds.new(1, 1, 8, 1)),
        text_node("ZZZZZZZZ", [], Bounds.new(1, 2, 8, 1))
      ]

      sa = layout_node(:box, [border: :single, scroll_offset: 0, overflow: :scroll],
             Bounds.new(0, 0, 12, 4), children)
      result = Painter.paint(sa, buffer)

      # Top border row preserved
      assert grapheme_at(result, 0, 0) == "┌"
      assert grapheme_at(result, 11, 0) == "┐"
      # Content only shows in inner area (rows 1-2)
      assert grapheme_at(result, 1, 1) == "Y"
      assert grapheme_at(result, 1, 2) == "Z"
      # Bottom border
      assert grapheme_at(result, 0, 3) == "└"
    end

    test "background fills full viewport (not shifted)" do
      buffer = Buffer.new(10, 4)

      children = [
        text_node("Hi", [], Bounds.new(0, 0, 2, 1))
      ]

      sa = layout_node(:box, [bg: :blue, scroll_offset: 2, overflow: :scroll],
             Bounds.new(0, 0, 10, 4), children)
      result = Painter.paint(sa, buffer)

      # Background fills entire viewport
      assert bg_at(result, 0, 0) == :blue
      assert bg_at(result, 5, 2) == :blue
      assert bg_at(result, 9, 3) == :blue
    end

    test "background and border both render" do
      buffer = Buffer.new(10, 4)

      sa = layout_node(:box, [bg: :red, border: :single, overflow: :scroll],
             Bounds.new(0, 0, 10, 4), [])
      result = Painter.paint(sa, buffer)

      # Border corners
      assert grapheme_at(result, 0, 0) == "┌"
      assert grapheme_at(result, 9, 3) == "┘"
      # Background in interior
      assert bg_at(result, 3, 2) == :red
    end

    test "without scroll_offset defaults to 0" do
      buffer = Buffer.new(20, 3)

      children = [
        text_node("AAA", [], Bounds.new(0, 0, 3, 1)),
        text_node("BBB", [], Bounds.new(0, 1, 3, 1))
      ]

      sa = layout_node(:box, [overflow: :scroll], Bounds.new(0, 0, 20, 3), children)
      result = Painter.paint(sa, buffer)

      # Default offset=0, top content visible
      assert grapheme_at(result, 0, 0) == "A"
      assert grapheme_at(result, 0, 1) == "B"
    end

    test "nested scroll boxes clip independently" do
      buffer = Buffer.new(20, 6)

      inner_children = [
        text_node("AA", [], Bounds.new(2, 2, 2, 1)),
        text_node("BB", [], Bounds.new(2, 3, 2, 1)),
        text_node("CC", [], Bounds.new(2, 4, 2, 1)),
        text_node("DD", [], Bounds.new(2, 5, 2, 1))
      ]

      inner_sa = layout_node(:box, [scroll_offset: 1, overflow: :scroll],
                   Bounds.new(2, 2, 16, 3), inner_children)

      outer_children = [inner_sa]
      outer_sa = layout_node(:box, [scroll_offset: 0, overflow: :scroll],
                   Bounds.new(0, 0, 20, 6), outer_children)

      result = Painter.paint(outer_sa, buffer)

      # Inner SA is at (2,2) with height 3, scroll_offset=1
      # Inner children shifted by -1: BB at y=2, CC at y=3, DD at y=4
      # Inner viewport clips to y=2..4
      assert grapheme_at(result, 2, 2) == "B"
      assert grapheme_at(result, 2, 3) == "C"
      assert grapheme_at(result, 2, 4) == "D"
    end

    test "scroll box respects parent clip rect" do
      buffer = Buffer.new(20, 10)

      children = [
        text_node("Hello", [], Bounds.new(2, 2, 5, 1)),
        text_node("World", [], Bounds.new(2, 3, 5, 1))
      ]

      sa = layout_node(:box, [scroll_offset: 0, overflow: :scroll],
             Bounds.new(2, 2, 16, 6), children)

      # Parent is smaller — clips the scrollable area
      parent = layout_node(:box, [], Bounds.new(0, 0, 10, 5), [sa])
      result = Painter.paint(parent, buffer)

      # SA content at x=2..6 is within parent (x=0..9)
      assert grapheme_at(result, 2, 2) == "H"
      # Row 4 is at y=4, still within parent height=5 (rows 0-4)
      # But y=3 shifted by -0 → y=3 visible
      assert grapheme_at(result, 2, 3) == "W"
    end

    test "empty scroll box does not crash" do
      buffer = Buffer.new(20, 5)

      sa = layout_node(:box, [scroll_offset: 5, bg: :green, overflow: :scroll],
             Bounds.new(0, 0, 20, 5), [])
      result = Painter.paint(sa, buffer)

      # Background still painted
      assert bg_at(result, 0, 0) == :green
    end
  end

  # ── Overflow: hidden ───────────────────────────────────────────

  describe "overflow: :hidden on box" do
    test "clips children to inner bounds" do
      buffer = Buffer.new(20, 5)

      children = [
        text_node("Hello World 12345", [], Bounds.new(0, 0, 17, 1))
      ]

      # Box is 10 wide — children should be clipped at width 10
      node = layout_node(:box, [overflow: :hidden], Bounds.new(0, 0, 10, 5), children)
      result = Painter.paint(node, buffer)

      assert grapheme_at(result, 0, 0) == "H"
      assert grapheme_at(result, 9, 0) == "l"
      # Beyond the box width — not painted
      assert grapheme_at(result, 10, 0) == " "
    end

    test "clips children inside borders" do
      buffer = Buffer.new(20, 5)

      children = [
        text_node("ABCDEFGHIJ", [], Bounds.new(1, 1, 10, 1))
      ]

      # Bordered box: inner area is (1,1) to (8,3), so text clips at x=9
      node = layout_node(:box, [overflow: :hidden, border: :single],
               Bounds.new(0, 0, 10, 5), children)
      result = Painter.paint(node, buffer)

      # Border intact
      assert grapheme_at(result, 0, 0) == "┌"
      # Inner content
      assert grapheme_at(result, 1, 1) == "A"
      assert grapheme_at(result, 8, 1) == "H"
      # Border column — not overwritten
      assert grapheme_at(result, 9, 1) == "│"
    end
  end

  # ── Absolute positioning ────────────────────────────────────────

  describe "absolute positioning" do
    test "absolute child paints on top of normal content" do
      buffer = Buffer.new(20, 5)

      normal_text = text_node("AAAA", [], Bounds.new(0, 0, 4, 1))
      abs_text = text_node("BB", [], Bounds.new(0, 0, 2, 1))
      abs_box = layout_node(:box, [position: :absolute], Bounds.new(0, 0, 2, 1), [abs_text])

      parent = layout_node(:box, [], Bounds.new(0, 0, 20, 5), [normal_text, abs_box])
      result = Painter.paint(parent, buffer)

      # Phase 2 (absolute) overwrites phase 1 (normal)
      assert grapheme_at(result, 0, 0) == "B"
      assert grapheme_at(result, 1, 0) == "B"
      assert grapheme_at(result, 2, 0) == "A"
      assert grapheme_at(result, 3, 0) == "A"
    end

    test "absolute child escapes parent clip bounds" do
      buffer = Buffer.new(30, 5)

      # Absolute child placed outside parent's 10-wide bounds
      abs_text = text_node("HI", [], Bounds.new(15, 0, 2, 1))
      abs_box = layout_node(:box, [position: :absolute], Bounds.new(15, 0, 5, 1), [abs_text])

      # Parent is only 10 wide — normal clipping would prevent painting at x=15
      parent = layout_node(:box, [], Bounds.new(0, 0, 10, 5), [abs_box])
      result = Painter.paint(parent, buffer)

      # Absolute child escapes parent clip, uses screen clip instead
      assert grapheme_at(result, 15, 0) == "H"
      assert grapheme_at(result, 16, 0) == "I"
    end

    test "deeply nested absolute child extracted and painted at screen level" do
      buffer = Buffer.new(40, 10)

      abs_text = text_node("OVERLAY", [], Bounds.new(25, 0, 7, 1))
      abs_box = layout_node(:box, [position: :absolute], Bounds.new(25, 0, 10, 1), [abs_text])

      # Nest the absolute child deeply: root > mid > inner > abs
      inner = layout_node(:box, [], Bounds.new(2, 2, 8, 6), [abs_box])
      mid = layout_node(:box, [], Bounds.new(1, 1, 15, 8), [inner])
      root = layout_node(:box, [], Bounds.new(0, 0, 20, 10), [mid])

      result = Painter.paint(root, buffer)

      # Despite being nested in a 20-wide root, absolute child at x=25 paints on screen
      assert grapheme_at(result, 25, 0) == "O"
      assert grapheme_at(result, 26, 0) == "V"
    end

    test "absolute child with background covers normal content" do
      buffer = Buffer.new(20, 3)

      normal_text = text_node("XXXXX", [], Bounds.new(0, 0, 5, 1))
      abs_box = layout_node(:box, [position: :absolute, bg: :red], Bounds.new(0, 0, 5, 1))

      parent = layout_node(:box, [], Bounds.new(0, 0, 20, 3), [normal_text, abs_box])
      result = Painter.paint(parent, buffer)

      # Background from absolute box covers the normal text
      assert bg_at(result, 0, 0) == :red
      assert bg_at(result, 4, 0) == :red
    end
  end

  # ── Integration scenarios ───────────────────────────────────────

  describe "integration" do
    test "dashboard-like layout with header, sidebar, and content" do
      buffer = Buffer.new(40, 20)

      header = text_node("Dashboard", [color: :bright_white, bold: true], Bounds.new(1, 0, 38, 1))

      sidebar_title = text_node("Menu", [color: :cyan], Bounds.new(1, 2, 8, 1))
      sidebar = layout_node(:box, [border: :single], Bounds.new(0, 1, 10, 18), [sidebar_title])

      content_text = text_node("Welcome!", [], Bounds.new(12, 3, 26, 1))
      content = layout_node(:box, [border: :rounded, bg: :black], Bounds.new(10, 1, 30, 18), [content_text])

      root = layout_node(:box, [], Bounds.new(0, 0, 40, 20), [header, sidebar, content])
      result = Painter.paint(root, buffer)

      # Header
      assert grapheme_at(result, 1, 0) == "D"
      assert fg_at(result, 1, 0) == :bright_white
      assert style_at(result, 1, 0) == %{bold: true}

      # Sidebar border
      assert grapheme_at(result, 0, 1) == "┌"
      assert grapheme_at(result, 1, 2) == "M"
      assert fg_at(result, 1, 2) == :cyan

      # Content border (rounded)
      assert grapheme_at(result, 10, 1) == "╭"
      # Content background
      assert bg_at(result, 15, 5) == :black
      # Content text
      assert grapheme_at(result, 12, 3) == "W"
    end
  end
end
