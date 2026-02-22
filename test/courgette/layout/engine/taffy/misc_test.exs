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

  describe "taffy_issue_696" do
    test "border_box" do
      el = box([width: 200, flex_direction: :column], [
        box([min_height: 100, flex_direction: :column, flex_basis: 0, padding: 20, overflow: :hidden], [
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
        box([min_height: 100, flex_direction: :column, flex_basis: 20, padding: 20, overflow: :hidden], [
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
        box([min_height: 100, flex_direction: :column, padding: 20, overflow: :hidden], [
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
        box([flex_direction: :column, flex_basis: 0, padding: 20, overflow: :hidden], [
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
