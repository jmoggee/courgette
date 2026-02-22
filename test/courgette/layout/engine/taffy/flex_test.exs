defmodule Courgette.Layout.Engine.Taffy.FlexTest do
  @moduledoc "Auto-generated from Taffy border_box fixtures. DO NOT EDIT."
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Engine.Flex

  defp box(props, children \\ []), do: Element.new(:box, props, children)

  defp assert_layout(result, expected) do
    assert_in_delta result.width, expected.w, 0.5,
      "width: expected #{expected.w}, got #{result.width}"
    assert_in_delta result.height, expected.h, 0.5,
      "height: expected #{expected.h}, got #{result.height}"
    assert_in_delta result.x, expected.x, 0.5,
      "x: expected #{expected.x}, got #{result.x}"
    assert_in_delta result.y, expected.y, 0.5,
      "y: expected #{expected.y}, got #{result.y}"
  end

  defp child(result, idx), do: Enum.at(result.children, idx)

  describe "flex_basis_and_main_dimen_set_when_flexing" do
    test "border_box" do
      el = box([width: 100], [
        box([width: 50, height: 50, flex_grow: 1, flex_basis: 10]),
        box([width: 0, height: 50, flex_grow: 1, flex_basis: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 0})
    end
  end

  describe "flex_basis_flex_grow_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([flex_grow: 1, flex_basis: 50]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 75, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 75})
    end
  end

  describe "flex_basis_flex_grow_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([flex_grow: 1, flex_basis: 50]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 75, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 25, h: 100, x: 75, y: 0})
    end
  end

  describe "flex_basis_flex_shrink_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(flex_basis: 100),
        box(flex_basis: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 67, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 33, x: 0, y: 67})
    end
  end

  describe "flex_basis_flex_shrink_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_basis: 100),
        box(flex_basis: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 67, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 33, h: 100, x: 67, y: 0})
    end
  end

  describe "flex_basis_larger_than_content_column" do
    test "border_box" do
      el = box([height: 100, flex_direction: :column], [
        box([flex_direction: :column, flex_basis: 50], [
          box([width: 100, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 10, x: 0, y: 0})
    end
  end

  describe "flex_basis_larger_than_content_row" do
    test "border_box" do
      el = box([width: 100], [
        box([flex_direction: :column, flex_basis: 50], [
          box([width: 10, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_overrides_main_size" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 20, flex_grow: 1, flex_basis: 50]),
        box([width: 10, flex_grow: 1]),
        box([width: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 60, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 80, y: 0})
    end
  end

  describe "flex_basis_slightly_smaller_then_content_with_flex_grow_large_size" do
    test "border_box" do
      el = box([width: 100], [
        box([flex_direction: :column, flex_grow: 1, flex_basis: 60], [
          box([width: 70, height: 100])
        ]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 80, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_than_content_column" do
    test "border_box" do
      el = box([height: 100, flex_direction: :column], [
        box([flex_direction: :column, flex_basis: 50], [
          box([width: 100, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_than_content_row" do
    test "border_box" do
      el = box([width: 100], [
        box([flex_direction: :column, flex_basis: 50], [
          box([width: 100, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_than_main_dimen_column" do
    test "border_box" do
      el = box([height: 100, flex_direction: :column], [
        box([width: 50, height: 50, flex_basis: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_than_main_dimen_row" do
    test "border_box" do
      el = box([width: 100], [
        box([width: 50, height: 50, flex_basis: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 50, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_then_content_with_flex_grow_large_size" do
    test "border_box" do
      el = box([width: 100], [
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 70, height: 100])
        ]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 100, x: 70, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_then_content_with_flex_grow_small_size" do
    test "border_box" do
      el = box([width: 10], [
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 70, height: 100])
        ]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 10.0, height: nil})
      assert_layout(r, %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 70, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_then_content_with_flex_grow_unconstraint_size" do
    test "border_box" do
      el = box([], [
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 70, height: 100])
        ]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 90, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 70, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_smaller_then_content_with_flex_grow_very_large_size" do
    test "border_box" do
      el = box([width: 200], [
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 70, height: 100])
        ]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 100, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_unconstraint_column" do
    test "border_box" do
      el = box([flex_direction: :column], [
        box([width: 100, flex_basis: 50])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "flex_basis_unconstraint_row" do
    test "border_box" do
      el = box([], [
        box([height: 100, flex_basis: 50])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_basis_zero_undefined_main_size" do
    test "border_box" do
      el = box([], [
        box([flex_direction: :column, flex_basis: 0], [
          box([width: 100, height: 50])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "flex_column_relative_all_sides" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 0, x: 10, y: 10})
    end
  end

  describe "flex_direction_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 10})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 20})
    end
  end

  describe "flex_direction_column_no_height" do
    test "border_box" do
      el = box([width: 100, flex_direction: :column], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 10})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 20})
    end
  end

  describe "flex_direction_column_reverse" do
    # Unsupported: column_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 90})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 80})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 70})
    end
  end

  describe "flex_direction_column_reverse_no_height" do
    # Unsupported: column_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 20})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 10})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 0})
    end
  end

  describe "flex_direction_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
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

  describe "flex_direction_row_no_width" do
    test "border_box" do
      el = box([height: 100], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 30, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 10, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 20, y: 0})
    end
  end

  describe "flex_direction_row_reverse" do
    # Unsupported: row_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 90, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 80, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 70, y: 0})
    end
  end

  describe "flex_grow_0_min_size" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 100, border: :single], [
        box([flex_shrink: 0, flex_basis: 0]),
        box([flex_shrink: 0, flex_basis: 0]),
        box([flex_shrink: 0, flex_basis: 0]),
        box([flex_shrink: 0, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 100.0})
      assert_layout(r, %{w: 400, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 98, x: 1, y: 1})
      assert_layout(child(r, 1), %{w: 30, h: 98, x: 31, y: 1})
      assert_layout(child(r, 2), %{w: 50, h: 98, x: 61, y: 1})
      assert_layout(child(r, 3), %{w: 40, h: 98, x: 111, y: 1})
    end
  end

  describe "flex_grow_child" do
    test "border_box" do
      el = box([], [
        box([height: 100, flex_grow: 1, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_grow_flex_basis_percent_min_max" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 120], [
        box([height: 20, min_width: 60, flex_grow: 1, flex_shrink: 0, flex_basis: 0]),
        box([width: 20, height: 20, max_width: 20, flex_grow: 1, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 120.0, height: nil})
      assert_layout(r, %{w: 120, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 100, y: 0})
    end
  end

  describe "flex_grow_height_maximized" do
    test "border_box" do
      el = box([width: 100, height: 500, flex_direction: :column], [
        box([min_height: 100, max_height: 500, flex_direction: :column, flex_grow: 1], [
          box([flex_grow: 1, flex_basis: 200]),
          box(height: 100)
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 500.0})
      assert_layout(r, %{w: 100, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 500, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 400, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 100, h: 100, x: 0, y: 400})
    end
  end

  describe "flex_grow_in_at_most_container" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box([], [
          box([flex_grow: 1, flex_basis: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "flex_grow_less_than_factor_one" do
    test "border_box" do
      el = box([width: 500, height: 200], [
        box([flex_grow: 0.2, flex_shrink: 0, flex_basis: 40]),
        box([flex_grow: 0.2, flex_shrink: 0]),
        box([flex_grow: 0.4, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 200.0})
      assert_layout(r, %{w: 500, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 132, h: 200, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 92, h: 200, x: 132, y: 0})
      assert_layout(child(r, 2), %{w: 184, h: 200, x: 224, y: 0})
    end
  end

  describe "flex_grow_root_minimized" do
    test "border_box" do
      el = box([width: 100, min_height: 100, max_height: 500, flex_direction: :column], [
        box([min_height: 100, max_height: 500, flex_direction: :column, flex_grow: 1], [
          box([flex_grow: 1, flex_basis: 200]),
          box(height: 100)
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 300, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 100, h: 100, x: 0, y: 200})
    end
  end

  describe "flex_grow_shrink_at_most" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([], [
          box(flex_grow: 1)
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "flex_grow_to_min" do
    test "border_box" do
      el = box([width: 100, min_height: 100, max_height: 500, flex_direction: :column], [
        box(flex_grow: 1),
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 50, x: 0, y: 50})
    end
  end

  describe "flex_grow_within_constrained_max_column" do
    test "border_box" do
      el = box([width: 100, max_height: 100, flex_direction: :column], [
        box(flex_basis: 100),
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 67, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 33, x: 0, y: 67})
    end
  end

  describe "flex_grow_within_constrained_max_row" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([height: 100, max_width: 100], [
          box(flex_basis: 100),
          box(width: 50)
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 67, h: 100, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 33, h: 100, x: 67, y: 0})
    end
  end

  describe "flex_grow_within_constrained_max_width" do
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column], [
        box([max_width: 300], [
          box([height: 20, flex_grow: 1])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 20, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 200, h: 20, x: 0, y: 0})
    end
  end

  describe "flex_grow_within_constrained_min_column" do
    test "border_box" do
      el = box([min_height: 100, flex_direction: :column], [
        box(flex_grow: 1),
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 50, x: 0, y: 50})
    end
  end

  describe "flex_grow_within_constrained_min_max_column" do
    test "border_box" do
      el = box([min_height: 100, max_height: 200, flex_direction: :column], [
        box(flex_grow: 1),
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 50, x: 0, y: 50})
    end
  end

  describe "flex_grow_within_constrained_min_row" do
    test "border_box" do
      el = box([height: 100, min_width: 100], [
        box(flex_grow: 1),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 100, x: 50, y: 0})
    end
  end

  describe "flex_grow_within_max_width" do
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column], [
        box([max_width: 100], [
          box([height: 20, flex_grow: 1])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 20, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 20, x: 0, y: 0})
    end
  end

  describe "flex_root_ignored" do
    test "border_box" do
      el = box([width: 100, min_height: 100, max_height: 500, flex_direction: :column], [
        box([flex_grow: 1, flex_basis: 200]),
        box(height: 100)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 0, y: 200})
    end
  end

  describe "flex_row_relative_all_sides" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 100, x: 10, y: 10})
    end
  end

  describe "flex_shrink_by_outer_margin_with_max_size" do
    test "border_box" do
      el = box([height: 100, max_height: 80, flex_direction: :column], [
        box([width: 20, height: 20, margin_top: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 20, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 0, x: 0, y: 100})
    end
  end

  describe "flex_shrink_flex_grow_child_flex_shrink_other_child" do
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([width: 500, height: 100]),
        box([width: 500, height: 100, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 250, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 250, h: 100, x: 250, y: 0})
    end
  end

  describe "flex_shrink_flex_grow_row" do
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([width: 500, height: 100]),
        box([width: 500, height: 100])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 250, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 250, h: 100, x: 250, y: 0})
    end
  end

  describe "flex_shrink_to_zero" do
    test "border_box" do
      el = box([width: 75], [
        box([width: 50, height: 50, flex_shrink: 0]),
        box([width: 50, height: 50]),
        box([width: 50, height: 50, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 75.0, height: nil})
      assert_layout(r, %{w: 75, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 50, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 50, y: 0})
    end
  end
end
