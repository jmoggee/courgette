defmodule Courgette.Layout.Engine.Taffy.WrapTest do
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

  describe "flex_wrap_align_stretch_fits_one_row" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap], [
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 100, x: 50, y: 0})
    end
  end

  describe "flex_wrap_children_with_min_main_overriding_flex_basis" do
    test "border_box" do
      el = box([width: 100, flex_wrap: :wrap], [
        box([height: 50, min_width: 55, flex_basis: 50]),
        box([height: 50, min_width: 55, flex_basis: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 55, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 55, h: 50, x: 0, y: 50})
    end
  end

  describe "flex_wrap_wrap_to_child_height" do
    test "border_box" do
      el = box([flex_direction: :column], [
        box([flex_wrap: :wrap, align_items: :flex_start], [
          box([width: 100, flex_direction: :column], [
            box([width: 100, height: 100])
          ])
        ]),
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 0, y: 100})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "wrap_child" do
    test "border_box" do
      el = box([flex_direction: :column], [
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "wrap_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap], [
        box([width: 30, height: 31]),
        box([width: 30, height: 32]),
        box([width: 30, height: 33]),
        box([width: 30, height: 34])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 31, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 32, x: 0, y: 31})
      assert_layout(child(r, 2), %{w: 30, h: 33, x: 0, y: 63})
      assert_layout(child(r, 3), %{w: 30, h: 34, x: 50, y: 0})
    end
  end

  describe "wrap_grandchild" do
    test "border_box" do
      el = box([], [
        box([], [
          box([width: 100, height: 100])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "wrap_nodes_with_content_sizing_margin_cross" do
    test "border_box" do
      el = box([width: 500, height: 500, flex_direction: :column], [
        box([width: 70, flex_wrap: :wrap], [
          box([flex_direction: :column], [
            box([width: 40, height: 40])
          ]),
          box([flex_direction: :column, margin_top: 10], [
            box([width: 40, height: 40])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 90, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 40, h: 40, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 40, h: 40, x: 0, y: 50})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 40, h: 40, x: 0, y: 0})
      c01 = child(c0, 1)
      assert_layout(child(c01, 0), %{w: 40, h: 40, x: 0, y: 0})
    end
  end

  describe "wrap_nodes_with_content_sizing_overflowing_margin" do
    test "border_box" do
      el = box([width: 500, height: 500, flex_direction: :column], [
        box([width: 85, flex_wrap: :wrap], [
          box([flex_direction: :column], [
            box([width: 40, height: 40])
          ]),
          box([flex_direction: :column, margin_right: 10], [
            box([width: 40, height: 40])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 85, h: 80, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 40, h: 40, x: 0, y: 0})
      assert_layout(child(c0, 1), %{w: 40, h: 40, x: 0, y: 40})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 40, h: 40, x: 0, y: 0})
      c01 = child(c0, 1)
      assert_layout(child(c01, 0), %{w: 40, h: 40, x: 0, y: 0})
    end
  end

  describe "wrap_reverse_column" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([width: 30, height: 31]),
        box([width: 30, height: 32]),
        box([width: 30, height: 33]),
        box([width: 30, height: 34])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 31, x: 70, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 32, x: 70, y: 31})
      assert_layout(child(r, 2), %{w: 30, h: 33, x: 70, y: 63})
      assert_layout(child(r, 3), %{w: 30, h: 34, x: 20, y: 0})
    end
  end

  describe "wrap_reverse_column_fixed_size" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 100, flex_direction: :column, align_items: :center], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 100.0})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 135, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 135, y: 10})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 135, y: 30})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 135, y: 60})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 35, y: 0})
    end
  end

  describe "wrap_reverse_row" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100], [
        box([width: 31, height: 30]),
        box([width: 32, height: 30]),
        box([width: 33, height: 30]),
        box([width: 34, height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 60, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 31, h: 30, x: 0, y: 30})
      assert_layout(child(r, 1), %{w: 32, h: 30, x: 31, y: 30})
      assert_layout(child(r, 2), %{w: 33, h: 30, x: 63, y: 30})
      assert_layout(child(r, 3), %{w: 34, h: 30, x: 0, y: 0})
    end
  end

  describe "wrap_reverse_row_align_content_center" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_content: :center], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 60})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 50})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 0, y: 10})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 30, y: 0})
    end
  end

  describe "wrap_reverse_row_align_content_flex_start" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_content: :flex_start], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 60})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 50})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 0, y: 10})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 30, y: 0})
    end
  end

  describe "wrap_reverse_row_align_content_space_around" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_content: :space_around], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 60})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 50})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 0, y: 10})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 30, y: 0})
    end
  end

  describe "wrap_reverse_row_align_content_stretch" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 100, align_content: :stretch], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 60})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 50})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 0, y: 10})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 30, y: 0})
    end
  end

  describe "wrap_reverse_row_single_line_different_size" do
    # Unsupported: wrap_reverse
    @tag :skip
    test "border_box" do
      el = box([width: 300, align_content: :flex_start], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 40]),
        box([width: 30, height: 50])
      ])
      r = Flex.layout(el, %{width: 300.0, height: nil})
      assert_layout(r, %{w: 300, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 40})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 30})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 20})
      assert_layout(child(r, 3), %{w: 30, h: 40, x: 90, y: 10})
      assert_layout(child(r, 4), %{w: 30, h: 50, x: 120, y: 0})
    end
  end

  describe "wrap_row" do
    test "border_box" do
      el = box([width: 100, flex_wrap: :wrap], [
        box([width: 31, height: 30]),
        box([width: 32, height: 30]),
        box([width: 33, height: 30]),
        box([width: 34, height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 60, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 31, h: 30, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 32, h: 30, x: 31, y: 0})
      assert_layout(child(r, 2), %{w: 33, h: 30, x: 63, y: 0})
      assert_layout(child(r, 3), %{w: 34, h: 30, x: 0, y: 30})
    end
  end

  describe "wrap_row_align_items_center" do
    test "border_box" do
      el = box([width: 100, flex_wrap: :wrap, align_items: :center], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 60, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 10})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 5})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 30, h: 30, x: 0, y: 30})
    end
  end

  describe "wrap_row_align_items_flex_end" do
    test "border_box" do
      el = box([width: 100, flex_wrap: :wrap, align_items: :flex_end], [
        box([width: 30, height: 10]),
        box([width: 30, height: 20]),
        box([width: 30, height: 30]),
        box([width: 30, height: 30])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 60, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 30, h: 10, x: 0, y: 20})
      assert_layout(child(r, 1), %{w: 30, h: 20, x: 30, y: 10})
      assert_layout(child(r, 2), %{w: 30, h: 30, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 30, h: 30, x: 0, y: 30})
    end
  end
end
