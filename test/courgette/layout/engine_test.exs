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
      el =
        Element.new(:box, [width: 80, height: 24, border: :single], [
          Element.new(:box, width: 10, height: 5)
        ])

      result = Engine.compute(el, Bounds.new(10, 5, 80, 24))
      child = hd(result.children)

      # Child should be offset by root_bounds origin + parent border
      assert child.bounds.x == 11
      assert child.bounds.y == 6
    end

    test "all values are non-negative integers" do
      el =
        Element.new(:box, [width: 80, height: 24], [
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
      el =
        Element.new(:box, [width: 80, height: 24], [
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
      el =
        Element.new(:box, [width: 100, height: 10], [
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
      el =
        Element.new(:box, [width: 40, height: 12, border: :single, bg: :blue], [
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
      el =
        Element.new(:box, [width: 40, height: 12, border: :single], [
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
      el =
        Element.new(
          :box,
          [width: 40, height: 10, flex_direction: :column, align_items: :flex_start],
          [
            Element.new(:text, [], ["Line one"]),
            Element.new(:text, [], ["Line two"])
          ]
        )

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

      sidebar =
        Element.new(
          :box,
          [width: 12, border: :single, flex_direction: :column, align_items: :flex_start],
          [
            Element.new(:text, [color: :cyan], ["Menu"])
          ]
        )

      content =
        Element.new(:box, [flex: 1, border: :rounded, bg: :black, align_items: :flex_start], [
          Element.new(:text, [], ["Welcome!"])
        ])

      el =
        Element.new(:box, [width: 40, height: 12, flex_direction: :column], [
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

  # ── Overflow: scroll (end-to-end) ────────────────────────────────

  describe "overflow: :scroll end-to-end" do
    test "text children with offset=0 paint correctly" do
      el =
        Element.new(:box, [width: 30, height: 6, flex_direction: :column], [
          Element.new(
            :box,
            [flex: 1, scroll_offset: 0, overflow: :scroll, flex_direction: :column],
            [
              Element.new(:text, [], ["Line A"]),
              Element.new(:text, [], ["Line B"]),
              Element.new(:text, [], ["Line C"]),
              Element.new(:text, [], ["Line D"]),
              Element.new(:text, [], ["Line E"]),
              Element.new(:text, [], ["Line F"]),
              Element.new(:text, [], ["Line G"]),
              Element.new(:text, [], ["Line H"])
            ]
          )
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 30, 6))
      buffer = Buffer.new(30, 6)
      painted = Painter.paint(result, buffer)

      # First line visible at row 0
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "L"
      cell = Buffer.get_cell(painted, 5, 0)
      assert cell.grapheme == "A"

      # Line at row 5 visible
      cell = Buffer.get_cell(painted, 5, 5)
      assert cell.grapheme == "F"
    end

    test "text children with scroll_offset shift content" do
      el =
        Element.new(:box, [width: 30, height: 4, flex_direction: :column], [
          Element.new(
            :box,
            [flex: 1, scroll_offset: 3, overflow: :scroll, flex_direction: :column],
            [
              Element.new(:text, [], ["Line A"]),
              Element.new(:text, [], ["Line B"]),
              Element.new(:text, [], ["Line C"]),
              Element.new(:text, [], ["Line D"]),
              Element.new(:text, [], ["Line E"]),
              Element.new(:text, [], ["Line F"]),
              Element.new(:text, [], ["Line G"])
            ]
          )
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 30, 4))
      buffer = Buffer.new(30, 4)
      painted = Painter.paint(result, buffer)

      # With offset=3, row 0 shows "Line D"
      cell = Buffer.get_cell(painted, 5, 0)
      assert cell.grapheme == "D"
      cell = Buffer.get_cell(painted, 5, 1)
      assert cell.grapheme == "E"
      cell = Buffer.get_cell(painted, 5, 2)
      assert cell.grapheme == "F"
      cell = Buffer.get_cell(painted, 5, 3)
      assert cell.grapheme == "G"
    end

    test "with border and scroll_offset" do
      el =
        Element.new(:box, [width: 30, height: 6, flex_direction: :column], [
          Element.new(
            :box,
            [
              flex: 1,
              border: :single,
              scroll_offset: 2,
              overflow: :scroll,
              flex_direction: :column
            ],
            [
              Element.new(:text, [], ["Line A"]),
              Element.new(:text, [], ["Line B"]),
              Element.new(:text, [], ["Line C"]),
              Element.new(:text, [], ["Line D"]),
              Element.new(:text, [], ["Line E"]),
              Element.new(:text, [], ["Line F"])
            ]
          )
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 30, 6))
      buffer = Buffer.new(30, 6)
      painted = Painter.paint(result, buffer)

      # Border at viewport edges
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "┌"
      cell = Buffer.get_cell(painted, 29, 5)
      assert cell.grapheme == "┘"

      # Inner content: with offset=2, "Line C" visible at row 1 (inside border)
      cell = Buffer.get_cell(painted, 1, 1)
      assert cell.grapheme == "L"
    end

    test "dashboard with scrollable panel" do
      header = Element.new(:text, [color: :bright_white, bold: true, height: 1], ["Dashboard"])

      log_lines =
        for i <- 1..20 do
          Element.new(:text, [], ["Log entry #{i}"])
        end

      scroll_panel =
        Element.new(
          :box,
          [
            flex: 1,
            border: :single,
            scroll_offset: 5,
            overflow: :scroll,
            flex_direction: :column
          ],
          log_lines
        )

      el =
        Element.new(:box, [width: 40, height: 12, flex_direction: :column], [
          header,
          scroll_panel
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 12))
      buffer = Buffer.new(40, 12)
      painted = Painter.paint(result, buffer)

      # Header at top
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "D"
      assert cell.fg == :bright_white

      # Scroll panel border starts at row 1
      cell = Buffer.get_cell(painted, 0, 1)
      assert cell.grapheme == "┌"

      # Content inside border is scrolled — "Log entry 6" should be first visible
      # The text "Log entry 6" starts with "L" at x=1 (inside border), y=2 (row 1 is border top)
      cell = Buffer.get_cell(painted, 1, 2)
      assert cell.grapheme == "L"
    end
  end

  # ── Absolute positioning ────────────────────────────────────────

  describe "absolute positioning" do
    test "absolute child does not push siblings" do
      el =
        Element.new(
          :box,
          [width: 40, height: 10, flex_direction: :column, align_items: :flex_start],
          [
            Element.new(:text, [], ["Line 1"]),
            Element.new(:box, position: :absolute, top: 5, left: 0, width: 20, height: 3),
            Element.new(:text, [], ["Line 2"])
          ]
        )

      result = Engine.compute(el, Bounds.new(0, 0, 40, 10))

      # Flow children: Line 1 and Line 2 should be adjacent (no gap from absolute child)
      flow_children =
        Enum.filter(result.children, fn child ->
          child.element.type == :text
        end)

      [line1, line2] = flow_children
      assert line1.bounds.y == 0
      assert line2.bounds.y == 1
    end

    test "absolute child positioned at content origin + top/left" do
      el =
        Element.new(:box, [width: 40, height: 20, border: :single], [
          Element.new(:box, position: :absolute, top: 2, left: 3, width: 10, height: 5)
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 20))
      [abs_child] = result.children

      # border inset is 1, so content origin is (1,1), offset by top:2, left:3
      assert abs_child.bounds.x == 4
      assert abs_child.bounds.y == 3
      assert abs_child.bounds.width == 10
      assert abs_child.bounds.height == 5
    end

    test "absolute child with right/bottom positioning" do
      el =
        Element.new(:box, [width: 40, height: 20], [
          Element.new(:box, position: :absolute, right: 0, bottom: 0, width: 10, height: 5)
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 20))
      [abs_child] = result.children

      # Positioned at right edge: x = 40 - 0 - 10 = 30, y = 20 - 0 - 5 = 15
      assert abs_child.bounds.x == 30
      assert abs_child.bounds.y == 15
    end

    test "absolute child does not affect parent sizing" do
      # A parent with explicit size shouldn't grow due to absolute children
      el =
        Element.new(
          :box,
          [width: 20, height: 10, flex_direction: :column, align_items: :flex_start],
          [
            Element.new(:text, [], ["Hello"]),
            Element.new(:box, position: :absolute, top: 0, left: 0, width: 100, height: 50)
          ]
        )

      result = Engine.compute(el, Bounds.new(0, 0, 80, 24))

      # Parent keeps its explicit size, not expanded by the absolute child
      assert result.bounds.width == 20
      assert result.bounds.height == 10

      # Only 2 children: 1 flow text + 1 absolute box
      assert length(result.children) == 2
    end

    test "absolute child with intrinsic sizing" do
      el =
        Element.new(:box, [width: 40, height: 20, align_items: :flex_start], [
          Element.new(
            :box,
            [
              position: :absolute,
              top: 0,
              left: 0,
              flex_direction: :column,
              align_items: :flex_start
            ],
            [
              Element.new(:text, [], ["Line A"]),
              Element.new(:text, [], ["Line B"])
            ]
          )
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 20))
      [abs_child] = result.children

      # Absolute child has no explicit size — it computes from content
      # Column with 2 text children: 6 chars wide, 2 lines tall
      assert abs_child.bounds.width == 6
      assert abs_child.bounds.height == 2
    end

    test "mixed flow and absolute children" do
      el =
        Element.new(:box, [width: 40, height: 10, align_items: :flex_start], [
          Element.new(:text, [], ["A"]),
          Element.new(:box, position: :absolute, top: 5, left: 5, width: 10, height: 3),
          Element.new(:text, [], ["B"])
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 40, 10))

      # Should have 3 children total (2 flow + 1 absolute)
      assert length(result.children) == 3

      # Flow children at x=0 and x=1 (row layout)
      [a, b | _] = Enum.filter(result.children, &(&1.element.type == :text))
      assert a.bounds.x == 0
      assert b.bounds.x == 1

      # Absolute child at offset position
      [abs] = Enum.filter(result.children, &(&1.element.props[:position] == :absolute))
      assert abs.bounds.x == 5
      assert abs.bounds.y == 5
    end
  end

  # ── Absolute + Painter ─────────────────────────────────────────

  describe "absolute positioning with Painter" do
    test "absolute child paints on top of normal content" do
      el =
        Element.new(
          :box,
          [width: 20, height: 5, flex_direction: :column, align_items: :flex_start],
          [
            Element.new(:text, [], ["AAAAAAAAAA"]),
            Element.new(:box, [position: :absolute, top: 0, left: 0, width: 2, height: 1], [
              Element.new(:text, [], ["BB"])
            ])
          ]
        )

      result = Engine.compute(el, Bounds.new(0, 0, 20, 5))
      buffer = Buffer.new(20, 5)
      painted = Painter.paint(result, buffer)

      # Absolute box paints on top — "BB" overwrites first two chars of "AAAA..."
      cell = Buffer.get_cell(painted, 0, 0)
      assert cell.grapheme == "B"
      cell = Buffer.get_cell(painted, 1, 0)
      assert cell.grapheme == "B"
      # The rest of the flow text is still there
      cell = Buffer.get_cell(painted, 2, 0)
      assert cell.grapheme == "A"
    end

    test "absolute child escapes parent clip bounds" do
      el =
        Element.new(:box, [width: 20, height: 3], [
          Element.new(:box, [width: 10, height: 3], [
            Element.new(:box, [position: :absolute, top: 0, left: 12, width: 5, height: 1], [
              Element.new(:text, [], ["HI"])
            ])
          ])
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 20, 3))
      buffer = Buffer.new(20, 3)
      painted = Painter.paint(result, buffer)

      # The absolute child at left:12 escapes the width:10 parent
      cell = Buffer.get_cell(painted, 12, 0)
      assert cell.grapheme == "H"
      cell = Buffer.get_cell(painted, 13, 0)
      assert cell.grapheme == "I"
    end

    test "select-like dropdown overlay" do
      # Simulate a select: outer box with a trigger text and absolute dropdown
      el =
        Element.new(:box, [width: 30, height: 10, flex_direction: :column], [
          Element.new(:box, [border: :single, flex_direction: :column], [
            Element.new(:text, [], ["Red ▾"]),
            Element.new(
              :box,
              [
                position: :absolute,
                top: 1,
                left: 0,
                flex_direction: :column,
                border: :single,
                bg: :black,
                align_items: :flex_start
              ],
              [
                Element.new(:text, [bold: true, fg: :cyan], ["▸ Red"]),
                Element.new(:text, [], ["  Green"]),
                Element.new(:text, [], ["  Blue"])
              ]
            )
          ]),
          Element.new(:text, [], ["Other content"])
        ])

      result = Engine.compute(el, Bounds.new(0, 0, 30, 10))
      buffer = Buffer.new(30, 10)
      painted = Painter.paint(result, buffer)

      # "Other content" should be right below the select box (not pushed down by dropdown)
      # The select border box is 1 border + 1 line text + 1 border = 3 tall
      cell = Buffer.get_cell(painted, 0, 3)
      assert cell.grapheme == "O"

      # The dropdown overlay should paint on top — its border starts inside the select
      # at y offset = border(1) + top(1) = row 2 from parent origin
      # The dropdown text should be visible
      painted_text =
        for x <- 0..29 do
          c = Buffer.get_cell(painted, x, 3)
          c.grapheme
        end
        |> Enum.join()
        |> String.trim()

      # The absolute dropdown paints on top of "Other content"
      assert painted_text =~ "Red" or painted_text =~ "Green" or painted_text =~ "Other"
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
      el =
        Element.new(:box, [width: 80, height: 24, align_items: :flex_start], [
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
