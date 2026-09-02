defmodule Courgette.Layout.Engine.FlexTest do
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Engine.Flex

  # Helper: shorthand for creating a box element with props and children
  defp box(props, children \\ []) do
    Element.new(:box, props, children)
  end

  defp text(content, props \\ []) do
    Element.new(:text, props, [content])
  end

  # Helper: extract child at index from layout result
  defp child(result, idx), do: Enum.at(result.children, idx)

  # ── Basic sizing ──────────────────────────────────────────────────

  describe "basic container sizing" do
    test "fixed-size empty container" do
      el = box(width: 80, height: 24)
      result = Flex.layout(el, %{width: 80.0, height: 24.0})

      assert result.width == 80.0
      assert result.height == 24.0
      assert result.children == []
    end

    test "container with border" do
      el = box(width: 20, height: 10, border: :single)
      result = Flex.layout(el, %{width: 80.0, height: 24.0})

      assert result.width == 20.0
      assert result.height == 10.0
    end

    test "container with padding" do
      el = box(width: 20, height: 10, padding: 2)
      result = Flex.layout(el, %{width: 80.0, height: 24.0})

      assert result.width == 20.0
      assert result.height == 10.0
    end

    test "container sizes from available when no explicit size" do
      el = box([])
      result = Flex.layout(el, %{width: 80.0, height: 24.0})

      assert result.width == 80.0
      assert result.height == 24.0
    end
  end

  # ── Fixed-size children (row) ─────────────────────────────────────

  describe "fixed-size children in row" do
    test "single fixed child" do
      el =
        box([width: 80, height: 24], [
          box(width: 20, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.x == 0.0
      assert c.y == 0.0
      assert c.width == 20.0
      assert c.height == 10.0
    end

    test "two fixed children laid out left to right" do
      el =
        box([width: 80, height: 24], [
          box(width: 20, height: 10),
          box(width: 30, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.x == 0.0
      assert c1.x == 20.0
      assert c0.width == 20.0
      assert c1.width == 30.0
    end

    test "children with gap" do
      el =
        box([width: 80, height: 24, gap: 2], [
          box(width: 20, height: 10),
          box(width: 20, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.x == 0.0
      assert c1.x == 22.0
    end
  end

  # ── Fixed-size children (column) ──────────────────────────────────

  describe "fixed-size children in column" do
    test "children laid out top to bottom" do
      el =
        box([width: 80, height: 24, flex_direction: :column], [
          box(width: 80, height: 5),
          box(width: 80, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.y == 0.0
      assert c1.y == 5.0
      assert c0.height == 5.0
      assert c1.height == 10.0
    end

    test "column with gap" do
      el =
        box([width: 80, height: 24, flex_direction: :column, gap: 1], [
          box(width: 80, height: 5),
          box(width: 80, height: 5)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c1 = child(result, 1)

      assert c1.y == 6.0
    end
  end

  # ── Flex grow ─────────────────────────────────────────────────────

  describe "flex_grow" do
    test "single child grows to fill container" do
      el =
        box([width: 100, height: 20], [
          box(flex: 1, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c = child(result, 0)

      assert c.width == 100.0
    end

    test "two children with equal flex_grow share space" do
      el =
        box([width: 100, height: 20], [
          box(flex: 1, height: 20),
          box(flex: 1, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.width == 50.0
      assert c1.width == 50.0
      assert c0.x == 0.0
      assert c1.x == 50.0
    end

    test "unequal flex_grow" do
      el =
        box([width: 100, height: 20], [
          box(flex_grow: 1, flex_basis: 0, height: 20),
          box(flex_grow: 2, flex_basis: 0, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      # After pixel rounding: 33 + 67 = 100 (exact pixel fit)
      assert_in_delta c0.width, 33, 0.5
      assert_in_delta c1.width, 67, 0.5
    end

    test "flex_grow with flex_basis" do
      # flex_basis gives initial size, grow distributes remaining
      el =
        box([width: 100, height: 20], [
          box(flex_grow: 1, flex_basis: 20, height: 20),
          box(flex_grow: 1, flex_basis: 20, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.width == 50.0
      assert c1.width == 50.0
    end

    test "flex_grow in column" do
      el =
        box([width: 80, height: 100, flex_direction: :column], [
          box(flex: 1, width: 80),
          box(flex: 1, width: 80)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 100.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.height == 50.0
      assert c1.height == 50.0
    end
  end

  # ── Flex shrink ───────────────────────────────────────────────────

  describe "flex_shrink" do
    test "children shrink when total exceeds container" do
      el =
        box([width: 100, height: 20], [
          box(width: 80, height: 20, flex_shrink: 1),
          box(width: 80, height: 20, flex_shrink: 1)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      # Total is 160, container is 100, so shrink 60 total
      # Both have same basis and factor, so equal shrink
      assert c0.width == 50.0
      assert c1.width == 50.0
    end

    test "flex_shrink: 0 prevents shrinking" do
      el =
        box([width: 100, height: 20], [
          box(width: 80, height: 20, flex_shrink: 0),
          box(width: 80, height: 20, flex_shrink: 1)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.width == 80.0
      assert c1.width == 20.0
    end
  end

  # ── Border + padding offsets ──────────────────────────────────────

  describe "border and padding offsets" do
    test "children offset by parent border" do
      el =
        box([width: 22, height: 12, border: :single], [
          box(width: 10, height: 5)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      # Border is 1 on each side
      assert c.x == 1.0
      assert c.y == 1.0
    end

    test "children offset by parent padding" do
      el =
        box([width: 30, height: 20, padding: 3], [
          box(width: 10, height: 5)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.x == 3.0
      assert c.y == 3.0
    end

    test "children offset by border + padding combined" do
      el =
        box([width: 30, height: 20, border: :single, padding: 2], [
          box(width: 10, height: 5)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.x == 3.0
      assert c.y == 3.0
    end
  end

  # ── Justify content ──────────────────────────────────────────────

  describe "justify_content" do
    setup do
      # 100-wide container, two 20-wide children = 60 free space
      make = fn jc ->
        el =
          box([width: 100, height: 20, justify_content: jc], [
            box(width: 20, height: 20),
            box(width: 20, height: 20)
          ])

        Flex.layout(el, %{width: 100.0, height: 20.0})
      end

      %{make: make}
    end

    test "flex_start (default)", %{make: make} do
      r = make.(:flex_start)
      assert child(r, 0).x == 0.0
      assert child(r, 1).x == 20.0
    end

    test "flex_end", %{make: make} do
      r = make.(:flex_end)
      assert child(r, 0).x == 60.0
      assert child(r, 1).x == 80.0
    end

    test "center", %{make: make} do
      r = make.(:center)
      assert child(r, 0).x == 30.0
      assert child(r, 1).x == 50.0
    end

    test "space_between", %{make: make} do
      r = make.(:space_between)
      assert child(r, 0).x == 0.0
      assert child(r, 1).x == 80.0
    end

    test "space_around", %{make: make} do
      r = make.(:space_around)
      # space_around: each item gets equal space around it
      # free=60, n=2 → each gets 60/(2*2)=15 on each side
      assert child(r, 0).x == 15.0
      assert child(r, 1).x == 65.0
    end

    test "space_evenly", %{make: make} do
      r = make.(:space_evenly)
      # free=60, n=2 → gaps=3, 60/3=20
      assert child(r, 0).x == 20.0
      assert child(r, 1).x == 60.0
    end
  end

  # ── Align items ──────────────────────────────────────────────────

  describe "align_items" do
    test "stretch (default) — children fill cross axis" do
      el =
        box([width: 80, height: 24], [
          box(flex: 1)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.height == 24.0
      assert c.y == 0.0
    end

    test "flex_start — children at top" do
      el =
        box([width: 80, height: 24, align_items: :flex_start], [
          box(width: 20, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.y == 0.0
      assert c.height == 10.0
    end

    test "flex_end — children at bottom" do
      el =
        box([width: 80, height: 24, align_items: :flex_end], [
          box(width: 20, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.y == 14.0
      assert c.height == 10.0
    end

    test "center — children centered on cross axis" do
      el =
        box([width: 80, height: 24, align_items: :center], [
          box(width: 20, height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.y == 7.0
    end
  end

  # ── Align self ────────────────────────────────────────────────────

  describe "align_self" do
    test "overrides align_items for individual child" do
      el =
        box([width: 80, height: 24, align_items: :flex_start], [
          box(width: 20, height: 10),
          box(width: 20, height: 10, align_self: :flex_end)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      assert c0.y == 0.0
      assert c1.y == 14.0
    end
  end

  # ── Flex wrap ─────────────────────────────────────────────────────

  describe "flex_wrap" do
    test "items wrap to next line when exceeding main size" do
      el =
        box([width: 50, height: 40, flex_wrap: :wrap, align_content: :flex_start], [
          box(width: 30, height: 10),
          box(width: 30, height: 10)
        ])

      result = Flex.layout(el, %{width: 50.0, height: 40.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      # First item on line 1
      assert c0.x == 0.0
      assert c0.y == 0.0
      # Second item wraps to line 2
      assert c1.x == 0.0
      assert c1.y == 10.0
    end

    test "no_wrap keeps all items on one line" do
      el =
        box([width: 50, height: 40, flex_wrap: :no_wrap], [
          box(width: 30, height: 10),
          box(width: 30, height: 10)
        ])

      result = Flex.layout(el, %{width: 50.0, height: 40.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      # Both on same row (will overflow)
      assert c0.y == 0.0
      assert c1.y == 0.0
    end
  end

  # ── Min/max constraints ───────────────────────────────────────────

  describe "min/max constraints" do
    test "min_width prevents shrinking below minimum" do
      el =
        box([width: 100, height: 20], [
          box(flex: 1, height: 20, min_width: 60),
          box(flex: 1, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)

      assert c0.width >= 60.0
    end

    test "max_width prevents growing above maximum" do
      el =
        box([width: 100, height: 20], [
          box(flex: 1, height: 20, max_width: 30),
          box(flex: 1, height: 20)
        ])

      result = Flex.layout(el, %{width: 100.0, height: 20.0})
      c0 = child(result, 0)

      assert c0.width <= 30.0
    end
  end

  # ── Text in flex ──────────────────────────────────────────────────

  describe "text in flex layout" do
    test "text leaf measures content" do
      el =
        box([width: 80, height: 24, align_items: :flex_start], [
          text("Hello")
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.width == 5.0
      assert c.height == 1.0
    end

    test "text with explicit size uses that size" do
      el =
        box([width: 80, height: 24], [
          text("Hello", width: 20, height: 3)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c = child(result, 0)

      assert c.width == 20.0
      assert c.height == 3.0
    end
  end

  # ── Nested containers ────────────────────────────────────────────

  describe "nested containers" do
    test "child container lays out its own children" do
      el =
        box([width: 80, height: 24], [
          box([width: 40, height: 24], [
            box(width: 20, height: 10),
            box(width: 20, height: 10)
          ])
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      outer_child = child(result, 0)

      assert outer_child.width == 40.0
      inner0 = Enum.at(outer_child.children, 0)
      inner1 = Enum.at(outer_child.children, 1)

      assert inner0.x == 0.0
      assert inner1.x == 20.0
    end

    test "nested container with border offsets grandchildren" do
      el =
        box([width: 80, height: 24], [
          box([width: 40, height: 24, border: :single], [
            box(width: 10, height: 5)
          ])
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      outer_child = child(result, 0)
      inner = Enum.at(outer_child.children, 0)

      # Grandchild should be offset by inner container's border
      assert inner.x == 1.0
      assert inner.y == 1.0
    end
  end

  # ── Column with stretch ──────────────────────────────────────────

  describe "column with stretch" do
    test "row children stretch in cross (height) when column" do
      el =
        box([width: 80, height: 24, flex_direction: :column], [
          box(height: 5),
          box(height: 10)
        ])

      result = Flex.layout(el, %{width: 80.0, height: 24.0})
      c0 = child(result, 0)
      c1 = child(result, 1)

      # In column direction with align_items: stretch (default),
      # children should stretch to full cross (width)
      assert c0.width == 80.0
      assert c1.width == 80.0
    end
  end
end
