defmodule Courgette.Layout.Engine.Taffy.MiscTest do
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

  describe "absolute_aspect_ratio_aspect_ratio_overrides_height_of_full_inset" do
    # Unsupported: absolute positioning, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 360, h: 120, x: 20, y: 15})
    end
  end

  describe "absolute_aspect_ratio_fill_height" do
    # Unsupported: absolute positioning, percentage dimensions, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 67, x: 20, y: 15})
    end
  end

  describe "absolute_aspect_ratio_fill_height_from_inset" do
    # Unsupported: absolute positioning, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 320, h: 107, x: 40, y: 15})
    end
  end

  describe "absolute_aspect_ratio_fill_max_height" do
    # Unsupported: absolute positioning, aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box(max_width: 50)
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 17, x: 0, y: 0})
    end
  end

  describe "absolute_aspect_ratio_fill_max_width" do
    # Unsupported: absolute positioning, aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box(max_height: 50)
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 25, h: 50, x: 0, y: 0})
    end
  end

  describe "absolute_aspect_ratio_fill_min_height" do
    # Unsupported: absolute positioning, aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box(min_width: 50)
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 17, x: 0, y: 0})
    end
  end

  describe "absolute_aspect_ratio_fill_min_width" do
    # Unsupported: absolute positioning, aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box(min_height: 50)
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 25, h: 50, x: 0, y: 0})
    end
  end

  describe "absolute_aspect_ratio_fill_width" do
    # Unsupported: absolute positioning, percentage dimensions, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 180, h: 60, x: 20, y: 15})
    end
  end

  describe "absolute_aspect_ratio_fill_width_from_inset" do
    # Unsupported: absolute positioning, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 180, h: 60, x: 0, y: 90})
    end
  end

  describe "absolute_aspect_ratio_height_overrides_inset" do
    # Unsupported: absolute positioning, percentage dimensions, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 90, h: 30, x: 0, y: 90})
    end
  end

  describe "absolute_aspect_ratio_width_overrides_inset" do
    # Unsupported: absolute positioning, percentage dimensions, aspect_ratio, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 300], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 300.0})
      assert_layout(r, %{w: 400, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 160, h: 53, x: 40, y: 15})
    end
  end

  describe "absolute_child_with_cross_margin" do
    # Unsupported: absolute positioning, percentage dimensions, measure function, percentage values
    @tag :skip
    test "border_box" do
      el = box([min_width: 311, min_height: 0, max_width: 311, max_height: 36893500000000000000, justify_content: :space_between], [
        box([width: 28, height: 27, align_content: :stretch]),
        box([height: 15, align_content: :stretch, margin_top: 4]),
        box([width: 25, height: 27, align_content: :stretch])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 311, h: 27, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 28, h: 27, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 311, h: 15, x: 0, y: 4})
      assert_layout(child(r, 2), %{w: 25, h: 27, x: 286, y: 0})
    end
  end

  describe "absolute_child_with_main_margin" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 20, height: 37], [
        box([width: 9, height: 9, margin_left: 7])
      ])
      r = Flex.layout(el, %{width: 20.0, height: 37.0})
      assert_layout(r, %{w: 20, h: 37, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 9, h: 9, x: 7, y: 0})
    end
  end

  describe "absolute_child_with_max_height" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 200, flex_direction: :column], [
        box([max_height: 100, flex_direction: :column], [
          box([width: 100, height: 30])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 30, x: 0, y: 150})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 30, x: 0, y: 0})
    end
  end

  describe "absolute_child_with_max_height_larger_shrinkable_grandchild" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 200, flex_direction: :column], [
        box([max_height: 100, flex_direction: :column], [
          box([width: 100, flex_basis: 150])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 80})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "absolute_correct_cross_child_size_with_percentage" do
    # Unsupported: absolute positioning, percentage dimensions, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 300, height: 110], [
        box([flex_direction: :column], [
          box([width: 200, height: 10]),
          box(height: 10),
          box([height: 10], [
            box([width: 10, height: 10])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 300.0, height: 110.0})
      assert_layout(r, %{w: 300, h: 110, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 30, x: 50, y: 40})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 200, h: 10, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 200, h: 10, x: 0, y: 10})
      assert_layout(child(c0, 2), %{w: 200, h: 10, x: 0, y: 20})
      c02 = child(c0, 2)
      assert_layout(child(c02, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_center" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 25, y: 30})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_center_and_bottom_position" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 25, y: 50})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_center_and_left_position" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 5, y: 30})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_center_and_right_position" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 45, y: 30})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_center_and_top_position" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 25, y: 10})
    end
  end

  describe "absolute_layout_align_items_and_justify_content_flex_end" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :flex_end, justify_content: :flex_end], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 50, y: 60})
    end
  end

  describe "absolute_layout_align_items_center" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 0, y: 30})
    end
  end

  describe "absolute_layout_align_items_center_on_child_only" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100], [
        box([width: 60, height: 40, align_self: :center])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 0, y: 30})
    end
  end

  describe "absolute_layout_child_order" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, align_items: :center, justify_content: :center], [
        box([width: 60, height: 40]),
        box([width: 60, height: 40]),
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 55, h: 40, x: 0, y: 30})
      assert_layout(child(r, 1), %{w: 60, h: 40, x: 25, y: 30})
      assert_layout(child(r, 2), %{w: 55, h: 40, x: 55, y: 30})
    end
  end

  describe "absolute_layout_in_wrap_reverse_column_container" do
    # Unsupported: absolute positioning, wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 80, y: 0})
    end
  end

  describe "absolute_layout_in_wrap_reverse_column_container_flex_end" do
    # Unsupported: absolute positioning, wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([width: 20, height: 20, align_self: :flex_end])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "absolute_layout_in_wrap_reverse_row_container" do
    # Unsupported: absolute positioning, wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 80})
    end
  end

  describe "absolute_layout_in_wrap_reverse_row_container_flex_end" do
    # Unsupported: absolute positioning, wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 20, height: 20, align_self: :flex_end])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "absolute_layout_justify_content_center" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 110, height: 100, justify_content: :center], [
        box([width: 60, height: 40])
      ])
      r = Flex.layout(el, %{width: 110.0, height: 100.0})
      assert_layout(r, %{w: 110, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 40, x: 25, y: 0})
    end
  end

  describe "absolute_layout_no_size" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "absolute_layout_percentage_bottom_based_on_parent_height" do
    # Unsupported: absolute positioning, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 200], [
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 100})
      assert_layout(child(r, 1), %{w: 10, h: 10, x: 0, y: 90})
      assert_layout(child(r, 2), %{w: 10, h: 160, x: 0, y: 20})
    end
  end

  describe "absolute_layout_percentage_height" do
    # Unsupported: absolute positioning, percentage dimensions, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 100], [
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 50, x: 10, y: 10})
    end
  end

  describe "absolute_layout_row_width_height_end_bottom" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 80, y: 80})
    end
  end

  describe "absolute_layout_start_top_end_bottom" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 80, x: 10, y: 10})
    end
  end

  describe "absolute_layout_width_height_end_bottom" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 80, y: 80})
    end
  end

  describe "absolute_layout_width_height_start_top" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "absolute_layout_width_height_start_top_end_bottom" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "absolute_layout_within_border" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, padding: 20], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50]),
        box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
        box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 10, y: 10})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 40, y: 40})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 20, y: 20})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 30, y: 30})
    end
  end

  describe "absolute_margin_bottom_left" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_end], [
        box([width: 10, height: 10, margin_left: 10, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 80})
    end
  end

  describe "absolute_minmax_bottom_right_max" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 100, max_width: 40, max_height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 30, x: 50, y: 60})
    end
  end

  describe "absolute_minmax_bottom_right_min_max" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([min_width: 50, min_height: 60, max_width: 40, max_height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 40, y: 30})
    end
  end

  describe "absolute_minmax_bottom_right_min_max_preferred" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 200, height: 200, min_width: 50, min_height: 60, max_width: 40, max_height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 40, y: 30})
    end
  end

  describe "absolute_minmax_top_left_bottom_right_max" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([max_width: 40, max_height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 30, x: 10, y: 10})
    end
  end

  describe "absolute_minmax_top_left_bottom_right_min_max" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([min_width: 50, min_height: 60, max_width: 40, max_height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 10, y: 10})
    end
  end

  describe "absolute_padding_border_overrides_max_size" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([], [
        box([max_width: 12, max_height: 12, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 22, h: 14, x: 0, y: 0})
    end
  end

  describe "absolute_padding_border_overrides_size" do
    # Unsupported: absolute positioning
    @tag :skip
    test "border_box" do
      el = box([], [
        box([width: 12, height: 12, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 22, h: 14, x: 0, y: 0})
    end
  end

  describe "absolute_resolved_insets" do
    # Unsupported: absolute positioning, percentage dimensions, overflow_scroll, auto margins, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([], [
        box([width: 200, height: 200, padding: 35], [
          box([]),
          box([]),
          box([]),
          box([]),
          box([]),
          box([])
        ]),
        box([width: 200, height: 200, padding: 35], [
          box([]),
          box([]),
          box([]),
          box([]),
          box([]),
          box([])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 400, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 200, x: 200, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 35, y: 35})
      assert_layout(child(c0, 1), %{w: 0, h: 0, x: 20, y: 20})
      assert_layout(child(c0, 2), %{w: 0, h: 0, x: 180, y: 180})
      assert_layout(child(c0, 3), %{w: 0, h: 0, x: 20, y: 20})
      assert_layout(child(c0, 4), %{w: 0, h: 0, x: 50, y: 50})
      assert_layout(child(c0, 5), %{w: 160, h: 160, x: 20, y: 20})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 0, h: 0, x: 35, y: 35})
      assert_layout(child(c1, 1), %{w: 0, h: 0, x: 20, y: 20})
      assert_layout(child(c1, 2), %{w: 0, h: 0, x: 165, y: 165})
      assert_layout(child(c1, 3), %{w: 0, h: 0, x: 20, y: 20})
      assert_layout(child(c1, 4), %{w: 0, h: 0, x: 50, y: 50})
      assert_layout(child(c1, 5), %{w: 145, h: 145, x: 20, y: 20})
    end
  end

  describe "android_news_feed" do
    test "border_box" do
      el = box([width: 1080, flex_direction: :column, flex_shrink: 0, align_content: :stretch], [
        box([flex_direction: :column, flex_shrink: 0], [
          box([flex_direction: :column, align_content: :stretch], [
            box([flex_direction: :column, align_content: :stretch], [
              box([align_items: :flex_start, align_content: :stretch, margin_left: 36, margin_top: 24], [
                box([flex_shrink: 0, align_content: :stretch], [
                  box([width: 120, height: 120, flex_shrink: 0, align_content: :stretch])
                ]),
                box([flex_direction: :column, align_content: :stretch, padding_left: 36, padding_right: 36, padding_top: 21, padding_bottom: 18, margin_right: 36], [
                  box(align_content: :stretch),
                  box(align_content: :stretch)
                ])
              ])
            ]),
            box([flex_direction: :column, align_content: :stretch], [
              box([align_items: :flex_start, align_content: :stretch, margin_left: 174, margin_top: 24], [
                box([flex_shrink: 0, align_content: :stretch], [
                  box([width: 72, height: 72, flex_shrink: 0, align_content: :stretch])
                ]),
                box([flex_direction: :column, align_content: :stretch, padding_left: 36, padding_right: 36, padding_top: 21, padding_bottom: 18, margin_right: 36], [
                  box(align_content: :stretch),
                  box(align_content: :stretch)
                ])
              ])
            ])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 1080.0, height: nil})
      assert_layout(r, %{w: 1080, h: 240, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 1080, h: 240, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 1080, h: 240, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 1080, h: 144, x: 0, y: 0})
      assert_layout(child(c00, 1), %{w: 1080, h: 96, x: 0, y: 144})
      c000 = child(c00, 0)
      assert_layout(child(c000, 0), %{w: 1044, h: 120, x: 36, y: 24})
      c001 = child(c00, 1)
      assert_layout(child(c001, 0), %{w: 906, h: 72, x: 174, y: 24})
      c0000 = child(c000, 0)
      assert_layout(child(c0000, 0), %{w: 120, h: 120, x: 0, y: 0})
      assert_layout(child(c0000, 1), %{w: 72, h: 39, x: 120, y: 0})
      c0010 = child(c001, 0)
      assert_layout(child(c0010, 0), %{w: 72, h: 72, x: 0, y: 0})
      assert_layout(child(c0010, 1), %{w: 72, h: 39, x: 72, y: 0})
      c00000 = child(c0000, 0)
      assert_layout(child(c00000, 0), %{w: 120, h: 120, x: 0, y: 0})
      c00001 = child(c0000, 1)
      assert_layout(child(c00001, 0), %{w: 0, h: 0, x: 36, y: 21})
      assert_layout(child(c00001, 1), %{w: 0, h: 0, x: 36, y: 21})
      c00100 = child(c0010, 0)
      assert_layout(child(c00100, 0), %{w: 72, h: 72, x: 0, y: 0})
      c00101 = child(c0010, 1)
      assert_layout(child(c00101, 0), %{w: 0, h: 0, x: 36, y: 21})
      assert_layout(child(c00101, 1), %{w: 0, h: 0, x: 36, y: 21})
    end
  end

  describe "aspect_ratio_flex_column_fill_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_max_height" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_max_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box(max_height: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_min_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box(min_width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_min_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box(min_height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 40, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_width" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box(height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 40, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_fill_width_flex" do
    # Unsupported: aspect_ratio, display_grid
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_stretch_fill_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_stretch_fill_max_height" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([width: 100, height: 100, flex_direction: :column])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_stretch_fill_max_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(max_height: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_column_stretch_fill_width" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 40, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_max_height" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box([width: 100, height: 100, align_items: :flex_start])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_max_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(max_height: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_min_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(min_width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_min_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(min_height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 40, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_width" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 40, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_fill_width_flex" do
    # Unsupported: aspect_ratio, display_grid
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_stretch_fill_height" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 100, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_stretch_fill_max_height" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 100, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_stretch_fill_max_width" do
    # Unsupported: aspect_ratio, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(max_height: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "aspect_ratio_flex_row_stretch_fill_width" do
    # Unsupported: aspect_ratio
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(height: 40)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 40, x: 0, y: 0})
    end
  end

  describe "bevy_issue_10343_block" do
    # Unsupported: display_block
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_around], [
        box([], [
          box([width: 200, height: 200, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
            box([])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 210, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 90, h: 200, x: 5, y: 5})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 90, h: 0, x: 0, y: 0})
    end
  end

  describe "bevy_issue_10343_flex" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_around], [
        box([], [
          box([width: 200, height: 200, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
            box([])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 210, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 90, h: 200, x: 5, y: 5})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 0, h: 200, x: 0, y: 0})
    end
  end

  describe "bevy_issue_10343_grid" do
    # Unsupported: display_grid
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_around], [
        box([], [
          box([width: 200, height: 200, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
            box([])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 210, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 90, h: 200, x: 5, y: 5})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 90, h: 200, x: 0, y: 0})
    end
  end

  describe "bevy_issue_16304" do
    test "border_box" do
      el = box([], [
        box([width: 50, flex_direction: :column], [
          box([min_width: 50, flex_wrap: :wrap, gap: 10], [
            box([width: 20, height: 40]),
            box([width: 20, height: 40])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 50, h: 40, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 40, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 40, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 20, h: 40, x: 0, y: 0})
      assert_layout(child(c00, 1), %{w: 20, h: 40, x: 30, y: 0})
    end
  end

  describe "bevy_issue_21240" do
    # Unsupported: display_grid
    @tag :skip
    test "border_box" do
      el = box([gap: 8, padding: 8], [
        box([]),
        box([]),
        box([]),
        box([]),
        box([]),
        box([])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 200, h: 152, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 40, x: 8, y: 8})
      assert_layout(child(r, 1), %{w: 40, h: 40, x: 56, y: 8})
      assert_layout(child(r, 2), %{w: 40, h: 40, x: 104, y: 8})
      assert_layout(child(r, 3), %{w: 40, h: 40, x: 152, y: 8})
      assert_layout(child(r, 4), %{w: 184, h: 40, x: 8, y: 56})
      assert_layout(child(r, 5), %{w: 184, h: 40, x: 8, y: 104})
    end
  end

  describe "bevy_issue_7976_3_level" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_content: :flex_start], [
        box([min_width: 40, min_height: 40, padding: 5, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
          box(padding: 5)
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 190, x: 5, y: 5})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 30, h: 180, x: 5, y: 5})
    end
  end

  describe "bevy_issue_7976_4_level" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_content: :flex_start], [
        box([min_width: 40, min_height: 40, padding: 5, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
          box([padding: 5], [
            box([])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 190, x: 5, y: 5})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 30, h: 180, x: 5, y: 5})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 0, h: 170, x: 5, y: 5})
    end
  end

  describe "bevy_issue_7976_reduced" do
    test "border_box" do
      el = box([height: 200, align_content: :flex_start], [
        box(width: 40)
      ])
      r = Flex.layout(el, %{width: nil, height: 200.0})
      assert_layout(r, %{w: 40, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 200, x: 0, y: 0})
    end
  end

  describe "bevy_issue_8017" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 400, flex_direction: :column, gap: 8, padding: 8], [
        box([gap: 8], [
          box([]),
          box([])
        ]),
        box([gap: 8], [
          box([]),
          box([])
        ])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 400.0})
      assert_layout(r, %{w: 400, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 384, h: 188, x: 8, y: 8})
      assert_layout(child(r, 1), %{w: 384, h: 188, x: 8, y: 204})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 188, h: 188, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 188, h: 188, x: 196, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 188, h: 188, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 188, h: 188, x: 196, y: 0})
    end
  end

  describe "bevy_issue_8017_reduced" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column, gap: 8], [
        box([], [
          box([])
        ]),
        box([], [
          box([])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 196, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 196, x: 0, y: 204})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 196, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 0, h: 196, x: 0, y: 0})
    end
  end

  describe "bevy_issue_8082" do
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column, align_items: :stretch, align_content: :center, justify_content: :flex_start], [
        box([flex_wrap: :wrap, align_items: :flex_start, align_content: :center, justify_content: :center], [
          box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
          box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
          box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
          box([width: 50, height: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 140, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 40, y: 10})
      assert_layout(child(c0, 1), %{w: 50, h: 50, x: 110, y: 10})
      assert_layout(child(c0, 2), %{w: 50, h: 50, x: 40, y: 80})
      assert_layout(child(c0, 3), %{w: 50, h: 50, x: 110, y: 80})
    end
  end

  describe "bevy_issue_8082_percent" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column, align_items: :stretch, align_content: :center, justify_content: :flex_start], [
        box([flex_wrap: :wrap, align_items: :flex_start, align_content: :center, justify_content: :center], [
          box([width: 50, height: 50]),
          box([width: 50, height: 50]),
          box([width: 50, height: 50]),
          box([width: 50, height: 50])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(c0, 2), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(c0, 3), %{w: 50, h: 50, x: 50, y: 50})
    end
  end

  describe "bevy_issue_9530" do
    # Unsupported: percentage dimensions, measure function, auto margins, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 300, height: 300, flex_direction: :column, align_items: :center, align_content: :center], [
        box([height: 20, flex_direction: :column]),
        box([flex_direction: :column, flex_grow: 1, padding: 20, margin_left: 20, margin_right: 20, margin_top: 20, margin_bottom: 20], [
          box(height: 50),
          box(height: 50),
          box(height: 50)
        ])
      ])
      r = Flex.layout(el, %{width: 300.0, height: 300.0})
      assert_layout(r, %{w: 300, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 0, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 300, h: 420, x: 0, y: 20})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 260, h: 50, x: 20, y: 20})
      assert_layout(child(c1, 1), %{w: 220, h: 240, x: 40, y: 90})
      assert_layout(child(c1, 2), %{w: 260, h: 50, x: 20, y: 350})
    end
  end

  describe "bevy_issue_9530_reduced" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 40, flex_direction: :column], [
        box([flex_direction: :column, flex_grow: 1], [
          box(flex_grow: 1)
        ])
      ])
      r = Flex.layout(el, %{width: 40.0, height: nil})
      assert_layout(r, %{w: 40, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 40, h: 20, x: 0, y: 0})
    end
  end

  describe "bevy_issue_9530_reduced2" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([flex_direction: :column], [
        box([width: 80, flex_direction: :column, flex_grow: 1, margin_left: 20, margin_right: 20], [
          box(flex_grow: 1)
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 120, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 20, x: 20, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 80, h: 20, x: 0, y: 0})
    end
  end

  describe "bevy_issue_9530_reduced3" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 80, flex_direction: :column], [
        box([flex_grow: 1, margin_left: 20, margin_right: 20])
      ])
      r = Flex.layout(el, %{width: 80.0, height: nil})
      assert_layout(r, %{w: 80, h: 40, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 40, x: 20, y: 0})
    end
  end

  describe "bevy_issue_9530_reduced4" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 80, flex_direction: :column], [
        box([margin_left: 20, margin_right: 20, margin_top: 20, margin_bottom: 20])
      ])
      r = Flex.layout(el, %{width: 80.0, height: nil})
      assert_layout(r, %{w: 80, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 40, x: 20, y: 20})
    end
  end

  describe "blitz_issue_88" do
    # Unsupported: measure function, display_block
    @tag :skip
    test "border_box" do
      el = box([width: 600], [
        box([flex_direction: :column, justify_content: :flex_start], [
          box([flex_grow: 1], [
            box([flex_grow: 1, flex_basis: 0])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 600.0, height: nil})
      assert_layout(r, %{w: 600, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 600, h: 10, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 600, h: 10, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 600, h: 10, x: 0, y: 0})
    end
  end

  describe "child_min_max_width_flexing" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 120, height: 50, align_items: :stretch], [
        box([min_width: 60, flex_grow: 1, flex_shrink: 0, flex_basis: 0]),
        box([max_width: 20, flex_grow: 1, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 120.0, height: 50.0})
      assert_layout(r, %{w: 120, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 50, x: 100, y: 0})
    end
  end

  describe "child_with_padding_align_end" do
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :flex_end, justify_content: :flex_end], [
        box([width: 100, height: 100, padding: 20])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 100, y: 100})
    end
  end

  describe "container_with_unsized_child" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "content_size" do
    # Unsupported: absolute positioning, percentage dimensions, measure function, overflow_scroll, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([height: 30], [
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 85, h: 30, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 85, h: 20, x: 0, y: -10})
    end
  end

  describe "display_none" do
    # Unsupported: display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_absolute_child" do
    # Unsupported: absolute positioning, display_none, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_grow: 1),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_fixed_size" do
    # Unsupported: display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_grow: 1),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_only_node" do
    # Unsupported: display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_with_child" do
    # Unsupported: display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([flex_grow: 1, flex_basis: 0]),
        box([flex_direction: :column, flex_grow: 1, flex_basis: 0], [
          box([width: 20, flex_grow: 1, flex_basis: 0])
        ]),
        box([flex_grow: 1, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 100, x: 50, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_with_margin" do
    # Unsupported: display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 20, height: 20, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "display_none_with_position" do
    # Unsupported: display_none, insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "display_none_with_position_absolute" do
    # Unsupported: absolute positioning, display_none
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "do_not_clamp_height_of_absolute_node_to_height_of_its_overflow_hidden_parent" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box([flex_direction: :column], [
          box([width: 100, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_cross_size_column" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box(flex_direction: :column)
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 40, h: 10, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_main_size_column" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box(flex_direction: :column)
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 10, h: 40, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_main_size_column_nested" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([flex_direction: :column], [
        box(flex_direction: :column)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 10, h: 40, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 40, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_main_size_column_wrap" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([flex_direction: :column, flex_wrap: :wrap], [
        box(flex_direction: :column),
        box(flex_direction: :column)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 10, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 40, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 40, x: 0, y: 40})
    end
  end

  describe "intrinsic_sizing_main_size_min_size" do
    # Unsupported: absolute positioning, insets
    @tag :skip
    test "border_box" do
      el = box([width: 300, height: 200], [
        box([max_width: 100, max_height: 100, align_items: :center, justify_content: :center, padding: 10], [
          box([min_width: 50, min_height: 50, padding: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 300.0, height: 200.0})
      assert_layout(r, %{w: 300, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 70, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 10, y: 10})
    end
  end

  describe "intrinsic_sizing_main_size_row" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 40, h: 10, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_main_size_row_nested" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([], [
        box([])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 40, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 10, x: 0, y: 0})
    end
  end

  describe "intrinsic_sizing_main_size_row_wrap" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([flex_wrap: :wrap], [
        box([]),
        box([])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 80, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 10, x: 40, y: 0})
    end
  end

  describe "measure_child" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([], [
        box([])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 60, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 10, x: 0, y: 0})
    end
  end

  describe "measure_child_absolute" do
    # Unsupported: absolute positioning, measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 10, x: 0, y: 0})
    end
  end

  describe "measure_child_constraint" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 50], [
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 50.0, height: nil})
      assert_layout(r, %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "measure_child_constraint_padding_parent" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 50, padding: 10], [
        box([width: 50, padding: 10])
      ])
      r = Flex.layout(el, %{width: 50.0, height: nil})
      assert_layout(r, %{w: 50, h: 120, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 10, y: 10})
    end
  end

  describe "measure_child_with_flex_grow" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box([width: 50, height: 50]),
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 0})
    end
  end

  describe "measure_child_with_flex_shrink" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box([width: 50, height: 50]),
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "measure_child_with_flex_shrink_hidden" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box([width: 50, height: 50]),
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 9, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 91, h: 50, x: 9, y: 0})
    end
  end

  describe "measure_child_with_min_size_greater_than_available_space" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, flex_direction: :column], [
        box(min_width: 200)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 0, y: 0})
    end
  end

  describe "measure_flex_basis_overrides_measure" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box([])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 50, x: 0, y: 0})
    end
  end

  describe "measure_height_overrides_measure" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([], [
        box(height: 5)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 10, h: 5, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 5, x: 0, y: 0})
    end
  end

  describe "measure_remeasure_child_after_growing" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_items: :flex_start], [
        box([width: 50, height: 50]),
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 10, x: 50, y: 0})
    end
  end

  describe "measure_remeasure_child_after_shrinking" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_items: :flex_start], [
        box([width: 50, height: 50, flex_shrink: 0]),
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 10, x: 50, y: 0})
    end
  end

  describe "measure_remeasure_child_after_stretching" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "measure_root" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 60, h: 10, x: 0, y: 0})
    end
  end

  describe "measure_stretch_overrides_measure" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 20, height: 10], [
        box([flex_grow: 1, flex_basis: 5]),
        box([flex_grow: 1, flex_basis: 5])
      ])
      r = Flex.layout(el, %{width: 20.0, height: 10.0})
      assert_layout(r, %{w: 20, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 10, x: 10, y: 0})
    end
  end

  describe "measure_width_overrides_measure" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([], [
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "multiline_column_max_height" do
    test "border_box" do
      el = box([max_height: 200, flex_direction: :column, flex_wrap: :wrap], [
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0]),
        box([width: 40, height: 20, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 80, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 20, x: 0, y: 20})
      assert_layout(child(r, 2), %{w: 40, h: 20, x: 0, y: 40})
      assert_layout(child(r, 3), %{w: 40, h: 20, x: 0, y: 60})
      assert_layout(child(r, 4), %{w: 40, h: 20, x: 0, y: 80})
      assert_layout(child(r, 5), %{w: 40, h: 20, x: 0, y: 100})
      assert_layout(child(r, 6), %{w: 40, h: 20, x: 0, y: 120})
      assert_layout(child(r, 7), %{w: 40, h: 20, x: 0, y: 140})
      assert_layout(child(r, 8), %{w: 40, h: 20, x: 0, y: 160})
      assert_layout(child(r, 9), %{w: 40, h: 20, x: 0, y: 180})
      assert_layout(child(r, 10), %{w: 40, h: 20, x: 40, y: 0})
      assert_layout(child(r, 11), %{w: 40, h: 20, x: 40, y: 20})
      assert_layout(child(r, 12), %{w: 40, h: 20, x: 40, y: 40})
      assert_layout(child(r, 13), %{w: 40, h: 20, x: 40, y: 60})
      assert_layout(child(r, 14), %{w: 40, h: 20, x: 40, y: 80})
      assert_layout(child(r, 15), %{w: 40, h: 20, x: 40, y: 100})
      assert_layout(child(r, 16), %{w: 40, h: 20, x: 40, y: 120})
      assert_layout(child(r, 17), %{w: 40, h: 20, x: 40, y: 140})
      assert_layout(child(r, 18), %{w: 40, h: 20, x: 40, y: 160})
      assert_layout(child(r, 19), %{w: 40, h: 20, x: 40, y: 180})
    end
  end

  describe "multiline_min_max_12" do
    test "border_box" do
      el = box([width: 600, height: 20, flex_wrap: :wrap, padding_left: 5, padding_right: 5, padding_top: 5, padding_bottom: 5], [
        box([height: 10, max_width: 300, flex_grow: 1, flex_basis: 600, padding_left: 10]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 600.0, height: 20.0})
      assert_layout(r, %{w: 610, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 10, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 305, y: 5})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 405, y: 5})
      assert_layout(child(r, 3), %{w: 100, h: 10, x: 505, y: 5})
    end
  end

  describe "multiline_min_max_13" do
    test "border_box" do
      el = box([width: 600, height: 20, flex_wrap: :wrap, padding_left: 5, padding_right: 5, padding_top: 5, padding_bottom: 5], [
        box([height: 10, max_width: 300, flex_grow: 1, flex_basis: 600, padding_left: 10]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 600.0, height: 20.0})
      assert_layout(r, %{w: 610, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 10, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 305, y: 5})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 405, y: 5})
      assert_layout(child(r, 3), %{w: 100, h: 10, x: 505, y: 5})
    end
  end

  describe "multiline_min_max_14" do
    test "border_box" do
      el = box([width: 600, height: 20, flex_wrap: :wrap, padding_left: 5, padding_right: 5, padding_top: 5, padding_bottom: 5], [
        box([height: 10, max_width: 300, flex_grow: 1, flex_basis: 600, margin_left: 10]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 600.0, height: 20.0})
      assert_layout(r, %{w: 610, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 10, x: 15, y: 5})
      assert_layout(child(r, 1), %{w: 145, h: 10, x: 315, y: 5})
      assert_layout(child(r, 2), %{w: 145, h: 10, x: 460, y: 5})
      assert_layout(child(r, 3), %{w: 600, h: 10, x: 5, y: 15})
    end
  end

  describe "multiline_min_max_5" do
    test "border_box" do
      el = box([width: 600, height: 20, flex_wrap: :wrap, padding_left: 5, padding_right: 5, padding_top: 5, padding_bottom: 5], [
        box([height: 10, max_width: 300, flex_grow: 1, flex_basis: 600]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 600.0, height: 20.0})
      assert_layout(r, %{w: 610, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 10, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 305, y: 5})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 405, y: 5})
      assert_layout(child(r, 3), %{w: 100, h: 10, x: 505, y: 5})
    end
  end

  describe "multiline_min_max_8" do
    test "border_box" do
      el = box([width: 600, height: 20, flex_wrap: :wrap, padding_left: 5, padding_right: 5, padding_top: 5, padding_bottom: 5], [
        box([height: 10, max_width: 300, flex_grow: 1, flex_basis: 600, margin_left: 10]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1]),
        box([width: 100, height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 600.0, height: 20.0})
      assert_layout(r, %{w: 610, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 300, h: 10, x: 15, y: 5})
      assert_layout(child(r, 1), %{w: 145, h: 10, x: 315, y: 5})
      assert_layout(child(r, 2), %{w: 145, h: 10, x: 460, y: 5})
      assert_layout(child(r, 3), %{w: 600, h: 10, x: 5, y: 15})
    end
  end

  describe "nested_overflowing_child" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([], [
          box([width: 200, height: 200])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 200, h: 200, x: 0, y: 0})
    end
  end

  describe "nested_overflowing_child_in_constraint_parent" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 100], [
          box([width: 200, height: 200])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 200, x: 0, y: 0})
    end
  end

  describe "only_shrinkable_item_with_flex_basis_zero" do
    test "border_box" do
      el = box([width: 480, max_height: 764, flex_direction: :column], [
        box(flex_basis: 0),
        box([flex_shrink: 0, flex_basis: 93, margin_bottom: 6]),
        box([flex_shrink: 0, flex_basis: 764])
      ])
      r = Flex.layout(el, %{width: 480.0, height: nil})
      assert_layout(r, %{w: 480, h: 764, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 480, h: 0, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 480, h: 93, x: 0, y: 0})
      assert_layout(child(r, 2), %{w: 480, h: 764, x: 0, y: 99})
    end
  end

  describe "overflow_cross_axis" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 200])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 200, x: 0, y: 0})
    end
  end

  describe "overflow_main_axis" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 200, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
    end
  end

  describe "overflow_main_axis_shrink_hidden" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box([])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
    end
  end

  describe "overflow_main_axis_shrink_scroll" do
    # Unsupported: measure function, overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box([])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
    end
  end

  describe "overflow_main_axis_shrink_visible" do
    # Unsupported: measure function
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box([])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
    end
  end

  describe "overflow_scroll_main_axis_justify_content_end" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_end], [
        box([width: 200, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: -100, y: 0})
    end
  end

  describe "overflow_scrollbars_overridden_by_available_space" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 2, height: 4], [
        box([flex_grow: 1], [
          box(flex_grow: 1)
        ])
      ])
      r = Flex.layout(el, %{width: 2.0, height: 4.0})
      assert_layout(r, %{w: 2, h: 4, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 2, h: 4, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "overflow_scrollbars_overridden_by_max_size" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([max_width: 2, max_height: 4], [
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 2, h: 4, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "overflow_scrollbars_overridden_by_size" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 2, height: 4], [
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 2.0, height: 4.0})
      assert_layout(r, %{w: 2, h: 4, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "overflow_scrollbars_take_up_space_both_axis" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 35, h: 35, x: 0, y: 0})
    end
  end

  describe "overflow_scrollbars_take_up_space_cross_axis" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 35, h: 50, x: 0, y: 0})
    end
  end

  describe "overflow_scrollbars_take_up_space_main_axis" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50], [
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 35, x: 0, y: 0})
    end
  end

  describe "parent_wrap_child_size_overflowing_parent" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100], [
          box([width: 100, height: 200])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 200, x: 0, y: 0})
    end
  end

  describe "percent_absolute_position" do
    # Unsupported: absolute positioning, percentage dimensions, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 60, height: 50, flex_direction: :column], [
        box([height: 50], [
          box([]),
          box([])
        ])
      ])
      r = Flex.layout(el, %{width: 60.0, height: 50.0})
      assert_layout(r, %{w: 60, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 50, x: 30, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 30, h: 50, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 30, h: 50, x: 30, y: 0})
    end
  end

  describe "percent_within_flex_grow" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 350, height: 100], [
        box(width: 100),
        box([flex_direction: :column, flex_grow: 1], [
          box([])
        ]),
        box(width: 100)
      ])
      r = Flex.layout(el, %{width: 350.0, height: 100.0})
      assert_layout(r, %{w: 350, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 150, h: 100, x: 100, y: 0})
      assert_layout(child(r, 2), %{w: 100, h: 100, x: 250, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 150, h: 0, x: 0, y: 0})
    end
  end

  describe "percentage_absolute_position" do
    # Unsupported: absolute positioning, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 60, y: 10})
    end
  end

  describe "percentage_container_in_wrapping_container" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :center, justify_content: :center], [
        box([flex_direction: :column], [
          box([justify_content: :center], [
            box([width: 50, height: 50]),
            box([width: 50, height: 50])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 50, y: 75})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 50, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(c00, 1), %{w: 50, h: 50, x: 50, y: 0})
    end
  end

  describe "percentage_different_width_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 300], [
        box(flex_grow: 1),
        box([])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 300.0})
      assert_layout(r, %{w: 200, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 90, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 90, x: 200, y: 0})
    end
  end

  describe "percentage_different_width_height_column" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 300, flex_direction: :column], [
        box(flex_grow: 1),
        box([])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 300.0})
      assert_layout(r, %{w: 200, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 210, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 90, x: 0, y: 210})
    end
  end

  describe "percentage_flex_basis" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200], [
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 125, h: 200, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 75, h: 200, x: 125, y: 0})
    end
  end

  describe "percentage_flex_basis_cross" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column], [
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 250, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 150, x: 0, y: 250})
    end
  end

  describe "percentage_flex_basis_cross_max_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 240, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 80, x: 0, y: 240})
    end
  end

  describe "percentage_flex_basis_cross_max_width" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 120, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 300, x: 0, y: 100})
    end
  end

  describe "percentage_flex_basis_cross_min_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column], [
        box(flex_grow: 1),
        box(flex_grow: 2)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 240, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 160, x: 0, y: 240})
    end
  end

  describe "percentage_flex_basis_cross_min_width" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 300, x: 0, y: 100})
    end
  end

  describe "percentage_flex_basis_main_max_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 52, h: 240, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 148, h: 80, x: 52, y: 0})
    end
  end

  describe "percentage_flex_basis_main_max_width" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 120, h: 400, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 400, x: 120, y: 0})
    end
  end

  describe "percentage_flex_basis_main_min_width" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400], [
        box(flex_grow: 1),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 120, h: 400, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 80, h: 400, x: 120, y: 0})
    end
  end

  describe "percentage_main_max_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 71, flex_direction: :column], [
        box([height: 151, flex_direction: :column, align_items: :flex_start], [
          box(flex_basis: 15),
          box(flex_basis: 48)
        ])
      ])
      r = Flex.layout(el, %{width: 71.0, height: nil})
      assert_layout(r, %{w: 71, h: 151, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 71, h: 151, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 15, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 0, h: 48, x: 0, y: 15})
    end
  end

  describe "percentage_margin_should_calculate_based_only_on_width" do
    # Unsupported: percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column], [
        box([flex_direction: :column, flex_grow: 1], [
          box([width: 10, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 160, h: 60, x: 20, y: 20})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "percentage_moderate_complexity" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, flex_direction: :column, padding: 3], [
        box([flex_direction: :column, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
          box(padding: 3)
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "percentage_moderate_complexity2" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column], [
        box([flex_direction: :column], [
          box([width: 20, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 60, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 20, h: 20, x: 20, y: 20})
    end
  end

  describe "percentage_multiple_nested_with_padding_margin_and_percentage_values" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column], [
        box([flex_direction: :column, flex_grow: 1, padding: 3, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
          box([flex_direction: :column, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5], [
            box(padding: 3)
          ])
        ]),
        box(flex_grow: 4)
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 190, h: 48, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 200, h: 142, x: 0, y: 58})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 92, h: 25, x: 8, y: 8})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 36, h: 6, x: 10, y: 10})
    end
  end

  describe "percentage_padding_should_calculate_based_only_on_width" do
    # Unsupported: percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column], [
        box([flex_direction: :column, flex_grow: 1], [
          box([width: 10, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 20, y: 20})
    end
  end

  describe "percentage_position_bottom_right" do
    # Unsupported: percentage dimensions, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 275, h: 75, x: -100, y: -50})
    end
  end

  describe "percentage_position_left_top" do
    # Unsupported: percentage dimensions, insets, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 400, height: 400], [
        box([])
      ])
      r = Flex.layout(el, %{width: 400.0, height: 400.0})
      assert_layout(r, %{w: 400, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 180, h: 220, x: 40, y: 80})
    end
  end

  describe "percentage_size_based_on_parent_inner_size" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400, flex_direction: :column, padding: 20], [
        box([])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 180, x: 20, y: 20})
    end
  end

  describe "percentage_size_of_flex_basis" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box([flex_basis: 50], [
          box(height: 100)
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 100, x: 0, y: 0})
    end
  end

  describe "percentage_sizes_should_not_prevent_flex_shrinking" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200], [
        box([], [
          box([])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 200, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 200, x: 0, y: 0})
    end
  end

  describe "percentage_width_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 400], [
        box([])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 400.0})
      assert_layout(r, %{w: 200, h: 400, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 120, x: 0, y: 0})
    end
  end

  describe "percentage_width_height_undefined_parent_size" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([flex_direction: :column], [
        box([])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "position_root_with_rtl_should_position_withoutdirection" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([], [
        box([width: 52, height: 52])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 52, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 52, h: 52, x: 72, y: 0})
    end
  end

  describe "relative_position_should_not_nudge_siblings" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 15})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 25})
    end
  end

  describe "rounding_flex_basis_flex_grow_row_prime_number_width" do
    test "border_box" do
      el = box([width: 113, height: 100], [
        box(flex_grow: 1),
        box(flex_grow: 1),
        box(flex_grow: 1),
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 113.0, height: 100.0})
      assert_layout(r, %{w: 113, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 23, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 22, h: 100, x: 23, y: 0})
      assert_layout(child(r, 2), %{w: 23, h: 100, x: 45, y: 0})
      assert_layout(child(r, 3), %{w: 22, h: 100, x: 68, y: 0})
      assert_layout(child(r, 4), %{w: 23, h: 100, x: 90, y: 0})
    end
  end

  describe "rounding_flex_basis_flex_grow_row_width_of_100" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(flex_grow: 1),
        box(flex_grow: 1),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 33, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 34, h: 100, x: 33, y: 0})
      assert_layout(child(r, 2), %{w: 33, h: 100, x: 67, y: 0})
    end
  end

  describe "rounding_flex_basis_flex_shrink_row" do
    test "border_box" do
      el = box([width: 101, height: 100], [
        box(flex_basis: 100),
        box(flex_basis: 25),
        box(flex_basis: 25)
      ])
      r = Flex.layout(el, %{width: 101.0, height: 100.0})
      assert_layout(r, %{w: 101, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 67, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 17, h: 100, x: 67, y: 0})
      assert_layout(child(r, 2), %{w: 17, h: 100, x: 84, y: 0})
    end
  end

  describe "rounding_flex_basis_overrides_main_size" do
    test "border_box" do
      el = box([width: 100, height: 113, flex_direction: :column], [
        box([height: 20, flex_grow: 1, flex_basis: 50]),
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 113.0})
      assert_layout(r, %{w: 100, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 64, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 64})
      assert_layout(child(r, 2), %{w: 100, h: 24, x: 0, y: 89})
    end
  end

  describe "rounding_fractial_input_1" do
    test "border_box" do
      el = box([width: 100, height: 113.4, flex_direction: :column], [
        box([height: 20, flex_grow: 1, flex_basis: 50]),
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 113.4})
      assert_layout(r, %{w: 100, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 64, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 64})
      assert_layout(child(r, 2), %{w: 100, h: 24, x: 0, y: 89})
    end
  end

  describe "rounding_fractial_input_2" do
    test "border_box" do
      el = box([width: 100, height: 113.6, flex_direction: :column], [
        box([height: 20, flex_grow: 1, flex_basis: 50]),
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 113.6})
      assert_layout(r, %{w: 100, h: 114, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 65, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 24, x: 0, y: 65})
      assert_layout(child(r, 2), %{w: 100, h: 25, x: 0, y: 89})
    end
  end

  describe "rounding_fractial_input_3" do
    test "border_box" do
      el = box([width: 100, height: 113.4, flex_direction: :column], [
        box([height: 20, flex_grow: 1, flex_basis: 50]),
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 113.4})
      assert_layout(r, %{w: 100, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 64, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 64})
      assert_layout(child(r, 2), %{w: 100, h: 24, x: 0, y: 89})
    end
  end

  describe "rounding_fractial_input_4" do
    test "border_box" do
      el = box([width: 100, height: 113.4, flex_direction: :column], [
        box([height: 20, flex_grow: 1, flex_basis: 50]),
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 113.4})
      assert_layout(r, %{w: 100, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 64, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 25, x: 0, y: 64})
      assert_layout(child(r, 2), %{w: 100, h: 24, x: 0, y: 89})
    end
  end

  describe "rounding_fractial_input_5" do
    test "border_box" do
      el = box([width: 963.333, height: 100, justify_content: :center], [
        box([width: 100.3, height: 100.3]),
        box([width: 100.3, height: 100.3])
      ])
      r = Flex.layout(el, %{width: 963.333, height: 100.0})
      assert_layout(r, %{w: 963, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 101, h: 100, x: 381, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 482, y: 0})
    end
  end

  describe "rounding_fractial_input_6" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 7], [
        box([flex_wrap: :wrap], [
          box([width: 2, height: 10]),
          box([width: 2, height: 10])
        ]),
        box([flex_wrap: :wrap], [
          box([width: 2, height: 10]),
          box([width: 2, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 7.0, height: nil})
      assert_layout(r, %{w: 7, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 4, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 3, h: 20, x: 4, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 2, h: 10, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 2, h: 10, x: 0, y: 10})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 2, h: 10, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 2, h: 10, x: 0, y: 10})
    end
  end

  describe "rounding_fractial_input_7" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 7], [
        box([flex_wrap: :wrap], [
          box([width: 1, height: 10]),
          box([width: 1, height: 10])
        ]),
        box([flex_wrap: :wrap], [
          box([width: 1, height: 10]),
          box([width: 1, height: 10])
        ]),
        box([flex_wrap: :wrap], [
          box([width: 1, height: 10]),
          box([width: 1, height: 10])
        ]),
        box([flex_wrap: :wrap], [
          box([width: 1, height: 10]),
          box([width: 1, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 7.0, height: nil})
      assert_layout(r, %{w: 7, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 2, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 2, h: 20, x: 2, y: 0})
      assert_layout(child(r, 2), %{w: 1, h: 20, x: 4, y: 0})
      assert_layout(child(r, 3), %{w: 2, h: 20, x: 5, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 1, h: 10, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 1, h: 10, x: 0, y: 10})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 1, h: 10, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 1, h: 10, x: 0, y: 10})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 1, h: 10, x: 0, y: 0})
      assert_layout(child(c2, 1), %{w: 1, h: 10, x: 0, y: 10})
      c3 = child(r, 3)
      assert_layout(child(c3, 0), %{w: 1, h: 10, x: 0, y: 0})
      assert_layout(child(c3, 1), %{w: 1, h: 10, x: 0, y: 10})
    end
  end

  describe "rounding_inner_node_controversy_combined" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 640, height: 320], [
        box(flex_grow: 1),
        box([flex_direction: :column, flex_grow: 1], [
          box(flex_grow: 1),
          box([flex_direction: :column, flex_grow: 1], [
            box(flex_grow: 1)
          ]),
          box(flex_grow: 1)
        ]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 640.0, height: 320.0})
      assert_layout(r, %{w: 640, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 213, h: 320, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 214, h: 320, x: 213, y: 0})
      assert_layout(child(r, 2), %{w: 213, h: 320, x: 427, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 214, h: 107, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 214, h: 106, x: 0, y: 107})
      assert_layout(child(c1, 2), %{w: 214, h: 107, x: 0, y: 213})
      c11 = child(c1, 1)
      assert_layout(child(c11, 0), %{w: 214, h: 106, x: 0, y: 0})
    end
  end

  describe "rounding_inner_node_controversy_horizontal" do
    test "border_box" do
      el = box([width: 320], [
        box([height: 10, flex_grow: 1]),
        box([height: 10, flex_direction: :column, flex_grow: 1], [
          box([height: 10, flex_grow: 1])
        ]),
        box([height: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 320.0, height: nil})
      assert_layout(r, %{w: 320, h: 10, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 107, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 106, h: 10, x: 107, y: 0})
      assert_layout(child(r, 2), %{w: 107, h: 10, x: 213, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 106, h: 10, x: 0, y: 0})
    end
  end

  describe "rounding_inner_node_controversy_vertical" do
    test "border_box" do
      el = box([height: 320, flex_direction: :column], [
        box([width: 10, flex_grow: 1]),
        box([width: 10, flex_direction: :column, flex_grow: 1], [
          box([width: 10, flex_grow: 1])
        ]),
        box([width: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: nil, height: 320.0})
      assert_layout(r, %{w: 10, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 107, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 106, x: 0, y: 107})
      assert_layout(child(r, 2), %{w: 10, h: 107, x: 0, y: 213})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 10, h: 106, x: 0, y: 0})
    end
  end

  describe "rounding_total_fractial" do
    test "border_box" do
      el = box([width: 87.4, height: 113.4, flex_direction: :column], [
        box([height: 20.3, flex_grow: 0.7, flex_basis: 50.3]),
        box([height: 10, flex_grow: 1.6]),
        box([height: 10.7, flex_grow: 1.1])
      ])
      r = Flex.layout(el, %{width: 87.4, height: 113.4})
      assert_layout(r, %{w: 87, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 87, h: 59, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 87, h: 30, x: 0, y: 59})
      assert_layout(child(r, 2), %{w: 87, h: 24, x: 0, y: 89})
    end
  end

  describe "rounding_total_fractial_nested" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 87.4, height: 113.4, flex_direction: :column], [
        box([height: 20.3, flex_direction: :column, flex_grow: 0.7, flex_basis: 50.3], [
          box([height: 9.9, flex_grow: 1, flex_basis: 0.3]),
          box([height: 1.1, flex_grow: 4, flex_basis: 0.3])
        ]),
        box([height: 10, flex_grow: 1.6]),
        box([height: 10.7, flex_grow: 1.1])
      ])
      r = Flex.layout(el, %{width: 87.4, height: 113.4})
      assert_layout(r, %{w: 87, h: 113, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 87, h: 59, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 87, h: 30, x: 0, y: 59})
      assert_layout(child(r, 2), %{w: 87, h: 24, x: 0, y: 89})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 87, h: 12, x: 0, y: -13})
      assert_layout(child(c0, 1), %{w: 87, h: 47, x: 0, y: 25})
    end
  end

  describe "scroll_size" do
    # Unsupported: overflow_scroll
    @tag :skip
    test "border_box" do
      el = box([width: 50, height: 50, align_items: :flex_start, justify_content: :flex_start], [
        box([width: 100, height: 100, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "simple_child" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([], [
          box([width: 10, height: 10], [
            box([width: 10, height: 10])
          ]),
          box([], [
            box([width: 10, height: 10, align_self: :center]),
            box([width: 10, height: 10, align_self: :center])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 20, h: 100, x: 10, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 10, h: 10, x: 0, y: 0})
      c01 = child(c0, 1)
      assert_layout(child(c01, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c01, 1), %{w: 10, h: 10, x: 10, y: 45})
    end
  end

  describe "single_flex_child_after_absolute_child" do
    # Unsupported: absolute positioning, percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 428, height: 845, flex_direction: :column], [
        box([]),
        box(flex_grow: 1),
        box([flex_shrink: 0, flex_basis: 174])
      ])
      r = Flex.layout(el, %{width: 428.0, height: 845.0})
      assert_layout(r, %{w: 428, h: 845, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 428, h: 845, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 428, h: 671, x: 0, y: 0})
      assert_layout(child(r, 2), %{w: 428, h: 174, x: 0, y: 671})
    end
  end

  describe "taffy_issue_696" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([min_height: 100, flex_direction: :column, flex_basis: 0, padding: 20], [
          box([height: 200, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 200, x: 20, y: 20})
    end
  end

  describe "taffy_issue_696_flex_basis_20" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([min_height: 100, flex_direction: :column, flex_basis: 20, padding: 20], [
          box([height: 200, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 200, x: 20, y: 20})
    end
  end

  describe "taffy_issue_696_min_height" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([min_height: 100, flex_direction: :column, flex_basis: 0, padding: 20], [
          box([height: 200, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 200, x: 20, y: 20})
    end
  end

  describe "taffy_issue_696_no_flex_basis" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([min_height: 100, flex_direction: :column, padding: 20], [
          box([height: 200, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 240, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 240, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 200, x: 20, y: 20})
    end
  end

  describe "taffy_issue_696_overflow_hidden" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([flex_direction: :column, flex_basis: 0, padding: 20], [
          box([height: 200, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 200, h: 40, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 40, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 200, x: 20, y: 20})
    end
  end

  describe "undefined_height_with_min_max" do
    test "border_box" do
      el = box([width: 320, min_height: 0, flex_direction: :column], [
        box([min_height: 0, max_height: 100])
      ])
      r = Flex.layout(el, %{width: 320.0, height: nil})
      assert_layout(r, %{w: 320, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 320, h: 0, x: 0, y: 0})
    end
  end

  describe "undefined_width_with_min_max" do
    test "border_box" do
      el = box([height: 50, flex_direction: :column], [
        box([min_width: 0, max_width: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: 50.0})
      assert_layout(r, %{w: 0, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "undefined_width_with_min_max_row" do
    test "border_box" do
      el = box([height: 50], [
        box([min_width: 60, max_width: 300], [
          box([width: 30, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: 50.0})
      assert_layout(r, %{w: 60, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 50, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 30, h: 20, x: 0, y: 0})
    end
  end

  describe "width_smaller_then_content_with_flex_grow_large_size" do
    test "border_box" do
      el = box([width: 100], [
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 70, height: 100])
        ]),
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 100, x: 50, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "width_smaller_then_content_with_flex_grow_small_size" do
    test "border_box" do
      el = box([width: 10], [
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 70, height: 100])
        ]),
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: 10.0, height: nil})
      assert_layout(r, %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 5, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 5, h: 100, x: 5, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "width_smaller_then_content_with_flex_grow_unconstraint_size" do
    test "border_box" do
      el = box([], [
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 70, height: 100])
        ]),
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 20, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 100, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 100, x: 0, y: 0})
    end
  end

  describe "width_smaller_then_content_with_flex_grow_very_large_size" do
    test "border_box" do
      el = box([width: 200], [
        box([width: 0, flex_direction: :column, flex_grow: 1], [
          box([width: 70, height: 100])
        ]),
        box([width: 0, flex_direction: :column, flex_grow: 1], [
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

  describe "wrapped_column_max_height" do
    test "border_box" do
      el = box([width: 700, height: 500, flex_direction: :column, flex_wrap: :wrap, align_items: :center, align_content: :center, justify_content: :center], [
        box([width: 100, height: 500, max_height: 200]),
        box([width: 200, height: 200, margin_left: 20, margin_right: 20, margin_top: 20, margin_bottom: 20]),
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: 700.0, height: 500.0})
      assert_layout(r, %{w: 700, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 200, x: 250, y: 30})
      assert_layout(child(r, 1), %{w: 200, h: 200, x: 200, y: 250})
      assert_layout(child(r, 2), %{w: 100, h: 100, x: 420, y: 200})
    end
  end

  describe "wrapped_column_max_height_flex" do
    test "border_box" do
      el = box([width: 700, height: 500, flex_direction: :column, flex_wrap: :wrap, align_items: :center, align_content: :center, justify_content: :center], [
        box([width: 100, height: 500, max_height: 200, flex_grow: 1, flex_basis: 0]),
        box([width: 200, height: 200, flex_grow: 1, flex_basis: 0, margin_left: 20, margin_right: 20, margin_top: 20, margin_bottom: 20]),
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: 700.0, height: 500.0})
      assert_layout(r, %{w: 700, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 180, x: 300, y: 0})
      assert_layout(child(r, 1), %{w: 200, h: 180, x: 250, y: 200})
      assert_layout(child(r, 2), %{w: 100, h: 100, x: 300, y: 400})
    end
  end

  describe "wrapped_row_within_align_items_center" do
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :center], [
        box([flex_wrap: :wrap], [
          box([width: 150, height: 80]),
          box([width: 80, height: 80])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 160, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 150, h: 80, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 80, h: 80, x: 0, y: 80})
    end
  end

  describe "wrapped_row_within_align_items_flex_end" do
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :flex_end], [
        box([flex_wrap: :wrap], [
          box([width: 150, height: 80]),
          box([width: 80, height: 80])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 160, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 150, h: 80, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 80, h: 80, x: 0, y: 80})
    end
  end

  describe "wrapped_row_within_align_items_flex_start" do
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :flex_start], [
        box([flex_wrap: :wrap], [
          box([width: 150, height: 80]),
          box([width: 80, height: 80])
        ])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 160, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 150, h: 80, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 80, h: 80, x: 0, y: 80})
    end
  end
end
