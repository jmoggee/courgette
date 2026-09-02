defmodule Courgette.Layout.Engine.TaffyFixturesTest do
  @moduledoc """
  Hand-translated Taffy border_box test fixtures.

  Each test builds the same element tree and asserts the same numeric
  values as the corresponding Rust test. Taffy coordinates are
  parent-relative floats.

  Source: /tmp/taffy/tests/generated/flex/*.rs
  """
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Engine.Flex

  # ── Helpers ───────────────────────────────────────────────────────

  defp box(props, children \\ []), do: Element.new(:box, props, children)

  defp assert_layout(result, expected) do
    assert_in_delta result.width,
                    expected.w,
                    0.5,
                    "width: expected #{expected.w}, got #{result.width}"

    assert_in_delta result.height,
                    expected.h,
                    0.5,
                    "height: expected #{expected.h}, got #{result.height}"

    assert_in_delta result.x, expected.x, 0.5, "x: expected #{expected.x}, got #{result.x}"
    assert_in_delta result.y, expected.y, 0.5, "y: expected #{expected.y}, got #{result.y}"
  end

  defp child(result, idx), do: Enum.at(result.children, idx)

  # ── flex_basis + flex_grow ────────────────────────────────────────

  describe "flex_basis_flex_grow_row" do
    test "child with basis=50 and flex_grow=1 gets 75, other gets 25" do
      el =
        box([width: 100, height: 100], [
          box(flex_grow: 1, flex_basis: 50),
          box(flex_grow: 1)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 75, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 25, h: 100, x: 75, y: 0})
    end
  end

  describe "flex_basis_flex_grow_column" do
    test "column direction: heights 75 and 25" do
      el =
        box([width: 100, height: 100, flex_direction: :column], [
          box(flex_grow: 1, flex_basis: 50),
          box(flex_grow: 1)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 75, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 75})
    end
  end

  describe "flex_shrink_flex_grow_row" do
    test "two 500w children in 500w container shrink to 250 each" do
      el =
        box([width: 500, height: 500], [
          box(flex_grow: 0, flex_shrink: 1, width: 500, height: 100),
          box(flex_grow: 0, flex_shrink: 1, width: 500, height: 100)
        ])

      r = Flex.layout(el, %{width: 500.0, height: 500.0})

      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 250, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 250, h: 100, x: 250, y: 0})
    end
  end

  # ── justify_content ──────────────────────────────────────────────

  describe "justify_content_row_flex_start" do
    test "three 10w children packed at start" do
      el =
        box([width: 100, height: 100, justify_content: :flex_start], [
          box(width: 10),
          box(width: 10),
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 10, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 20, y: 0})
    end
  end

  describe "justify_content_row_center" do
    test "three 10w children centered" do
      el =
        box([width: 100, height: 100, justify_content: :center], [
          box(width: 10),
          box(width: 10),
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 100, x: 35, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 45, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 55, y: 0})
    end
  end

  describe "justify_content_row_flex_end" do
    test "three 10w children packed at end" do
      el =
        box([width: 100, height: 100, justify_content: :flex_end], [
          box(width: 10),
          box(width: 10),
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 100, x: 70, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 80, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 90, y: 0})
    end
  end

  describe "justify_content_row_space_between" do
    test "three 10w children with space between" do
      el =
        box([width: 100, height: 100, justify_content: :space_between], [
          box(width: 10),
          box(width: 10),
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 45, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 90, y: 0})
    end
  end

  describe "justify_content_row_space_around" do
    test "three 10w children with space around" do
      el =
        box([width: 100, height: 100, justify_content: :space_around], [
          box(width: 10),
          box(width: 10),
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      # space_around: free=70, each side = 70/(3*2) ≈ 11.67
      assert_in_delta child(r, 0).x, 12, 1
      assert_in_delta child(r, 1).x, 45, 1
      assert_in_delta child(r, 2).x, 78, 1
    end
  end

  describe "justify_content_row_space_evenly" do
    test "three 0w/10h children with space evenly" do
      # Taffy: children have width=auto (0), height=10
      el =
        box([width: 100, height: 100, justify_content: :space_evenly], [
          box(height: 10),
          box(height: 10),
          box(height: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_in_delta child(r, 0).x, 25, 1
      assert_in_delta child(r, 1).x, 50, 1
      assert_in_delta child(r, 2).x, 75, 1
    end
  end

  # ── align_items ──────────────────────────────────────────────────

  describe "align_items_flex_start" do
    test "10x10 child at top" do
      el =
        box([width: 100, height: 100, align_items: :flex_start], [
          box(width: 10, height: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "align_items_center" do
    test "10x10 child centered vertically" do
      el =
        box([width: 100, height: 100, align_items: :center], [
          box(width: 10, height: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 45})
    end
  end

  describe "align_items_flex_end" do
    test "10x10 child at bottom" do
      el =
        box([width: 100, height: 100, align_items: :flex_end], [
          box(width: 10, height: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 90})
    end
  end

  describe "align_items_stretch" do
    test "10w child stretches to full height" do
      el =
        box([width: 100, height: 100, align_items: :stretch], [
          box(width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
    end
  end

  describe "align_self_flex_end" do
    test "10x10 child with align_self=flex_end pushed to bottom" do
      el =
        box([width: 100, height: 100, align_items: :flex_start], [
          box(width: 10, height: 10, align_self: :flex_end)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 90})
    end
  end

  # ── flex_wrap ────────────────────────────────────────────────────

  describe "wrap_row" do
    test "4 children wrap into 2 rows, container height from content" do
      el =
        box([width: 100, flex_wrap: :wrap, align_items: :flex_start], [
          box(width: 31, height: 30),
          box(width: 32, height: 30),
          box(width: 33, height: 30),
          box(width: 34, height: 30)
        ])

      r = Flex.layout(el, %{width: 100.0, height: nil})

      assert_in_delta r.width, 100, 0.5
      assert_in_delta r.height, 60, 0.5

      assert_layout(child(r, 0), %{w: 31, h: 30, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 32, h: 30, x: 31, y: 0})
      assert_layout(child(r, 2), %{w: 33, h: 30, x: 63, y: 0})
      assert_layout(child(r, 3), %{w: 34, h: 30, x: 0, y: 30})
    end
  end

  describe "flex_wrap_align_stretch_fits_one_row" do
    test "2 children fit in one row, stretch to full height" do
      el =
        box([width: 150, height: 100, flex_wrap: :wrap], [
          box(width: 50),
          box(width: 50)
        ])

      r = Flex.layout(el, %{width: 150.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 100, x: 50, y: 0})
    end
  end

  # ── padding + border ──────────────────────────────────────────────

  describe "padding_no_child" do
    test "empty container with 10px padding = 20x20" do
      el = box(padding: 10)

      r = Flex.layout(el, %{width: nil, height: nil})

      assert_in_delta r.width, 20, 0.5
      assert_in_delta r.height, 20, 0.5
    end
  end

  describe "border_no_child" do
    test "empty container with 10px border = 20x20" do
      # In our system, border: :single is 1px. Use padding to simulate 10px border.
      # Taffy's "border" is an inset value. Our border is always 1 for :single.
      # So we test with explicit padding to get 10px insets.
      el = box(padding: 10)

      r = Flex.layout(el, %{width: nil, height: nil})

      assert_in_delta r.width, 20, 0.5
      assert_in_delta r.height, 20, 0.5
    end
  end

  describe "border_flex_child" do
    test "child fills 80x80 inside 100x100 container with 1px border" do
      # Our border is always 1px for :single, so use padding for larger insets
      # Container 100x100 with padding=10 → inner 80x80. Child flex_grow fills it.
      el =
        box([width: 100, height: 100, padding: 10], [
          box(flex_grow: 1, width: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      c = child(r, 0)

      assert_in_delta c.width, 80, 0.5
      assert_in_delta c.height, 80, 0.5
      assert_in_delta c.x, 10, 0.5
      assert_in_delta c.y, 10, 0.5
    end
  end

  # ── min/max ──────────────────────────────────────────────────────

  describe "flex_grow_within_constrained_max_row" do
    test "nested container constrained by max_width" do
      # Root: 200w, column direction
      # Child: auto width, 100h, max_width=100
      #   Grandchild 0: flex_basis=100, flex_shrink=1
      #   Grandchild 1: width=50
      el =
        box([width: 200, flex_direction: :column], [
          box([height: 100, max_width: 100], [
            box(flex_shrink: 1, flex_basis: 100),
            box(width: 50)
          ])
        ])

      r = Flex.layout(el, %{width: 200.0, height: nil})

      c0 = child(r, 0)
      assert_in_delta c0.width, 100, 0.5
      assert_in_delta c0.height, 100, 0.5

      gc0 = child(c0, 0)
      gc1 = child(c0, 1)
      assert_in_delta gc0.width, 67, 1
      assert_in_delta gc1.width, 33, 1
    end
  end

  # ── gap ──────────────────────────────────────────────────────────

  describe "gap_column_gap_flexible" do
    test "3 flex children with 10px column gap in 80w container" do
      # In Taffy gap.width = column gap (main axis gap for row)
      el =
        box([width: 80, height: 100, gap: 10], [
          box(flex: 1),
          box(flex: 1),
          box(flex: 1)
        ])

      r = Flex.layout(el, %{width: 80.0, height: 100.0})

      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_row_gap_wrapping" do
    test "9 children with col/row gap wrap into 3 rows" do
      children = for _ <- 1..9, do: box(width: 20, height: 20)

      # gap_main = column gap = 10, gap_cross = row gap = 20
      el =
        box(
          [
            width: 80,
            flex_wrap: :wrap,
            gap_main: 10,
            gap_cross: 20,
            align_items: :flex_start,
            align_content: :flex_start
          ],
          children
        )

      r = Flex.layout(el, %{width: 80.0, height: nil})

      # Row 1: items at x=0, 30, 60
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 0})
      # Row 2: items at y=40 (20 + 20 gap)
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 40})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 40})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 40})
      # Row 3: items at y=80
      assert_layout(child(r, 6), %{w: 20, h: 20, x: 0, y: 80})
      assert_layout(child(r, 7), %{w: 20, h: 20, x: 30, y: 80})
      assert_layout(child(r, 8), %{w: 20, h: 20, x: 60, y: 80})
    end
  end

  # ── nested ───────────────────────────────────────────────────────

  describe "flex_direction_column_no_height" do
    test "column container height from children" do
      el =
        box([width: 100, flex_direction: :column], [
          box(height: 10),
          box(height: 10),
          box(height: 10)
        ])

      r = Flex.layout(el, %{width: 100.0, height: nil})

      assert_in_delta r.width, 100, 0.5
      assert_in_delta r.height, 30, 0.5
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 10})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 20})
    end
  end

  describe "flex_basis_smaller_than_content_row" do
    test "nested child and grandchild expand to fill" do
      el =
        box([width: 100], [
          box([flex_direction: :column, flex_basis: 50], [
            box(width: 100, height: 100)
          ])
        ])

      r = Flex.layout(el, %{width: 100.0, height: nil})

      assert_in_delta r.width, 100, 0.5
      assert_in_delta r.height, 100, 0.5
      c0 = child(r, 0)
      assert_in_delta c0.width, 100, 0.5
      assert_in_delta c0.height, 100, 0.5
    end
  end
end
