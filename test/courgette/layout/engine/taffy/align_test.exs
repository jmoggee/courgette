defmodule Courgette.Layout.Engine.Taffy.AlignTest do
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

  describe "align_baseline" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 30})
    end
  end

  describe "align_baseline_child" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_child_margin" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10, margin_left: 5, margin_right: 5, margin_top: 5, margin_bottom: 5])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 50, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 5, y: 5})
    end
  end

  describe "align_baseline_child_margin_percent" do
    # Unsupported: percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 50, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 45})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 1, y: 1})
    end
  end

  describe "align_baseline_child_multiline" do
    test "border_box" do
      el = box([width: 100, align_items: :baseline], [
        box([width: 50, height: 60]),
        box([width: 50, flex_wrap: :wrap], [
          box([width: 25, height: 20]),
          box([width: 25, height: 10]),
          box([width: 25, height: 20]),
          box([width: 25, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 40, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 25, h: 20, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 25, h: 10, x: 25, y: 0})
      assert_layout(child(c1, 2), %{w: 25, h: 20, x: 0, y: 20})
      assert_layout(child(c1, 3), %{w: 25, h: 10, x: 25, y: 20})
    end
  end

  describe "align_baseline_child_multiline_no_override_on_secondline" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 60]),
        box([width: 50, height: 25, flex_wrap: :wrap], [
          box([width: 25, height: 20]),
          box([width: 25, height: 10]),
          box([width: 25, height: 20]),
          box([width: 25, height: 10, align_self: :baseline])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 25, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 25, h: 20, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 25, h: 10, x: 25, y: 0})
      assert_layout(child(c1, 2), %{w: 25, h: 20, x: 0, y: 20})
      assert_layout(child(c1, 3), %{w: 25, h: 10, x: 25, y: 20})
    end
  end

  describe "align_baseline_child_multiline_override" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 60]),
        box([width: 50, height: 25, flex_wrap: :wrap], [
          box([width: 25, height: 20]),
          box([width: 25, height: 10, align_self: :baseline]),
          box([width: 25, height: 20]),
          box([width: 25, height: 10, align_self: :baseline])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 25, x: 50, y: 50})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 25, h: 20, x: 0, y: 0})
      assert_layout(child(c1, 1), %{w: 25, h: 10, x: 25, y: 0})
      assert_layout(child(c1, 2), %{w: 25, h: 20, x: 0, y: 20})
      assert_layout(child(c1, 3), %{w: 25, h: 10, x: 25, y: 20})
    end
  end

  describe "align_baseline_child_padding" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline, padding: 5], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column, padding: 5], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 50, x: 5, y: 5})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 45, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 5, y: 5})
    end
  end

  describe "align_baseline_child_top" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 10})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_child_top2" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 45})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 0, y: 50})
    end
  end

  describe "align_baseline_double_nested_child" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50], [
          box([width: 50, height: 20])
        ]),
        box([width: 50, height: 20], [
          box([width: 50, height: 15])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 5})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 20, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 15, x: 0, y: 0})
    end
  end

  describe "align_baseline_multiline" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      assert_layout(child(r, 2), %{w: 50, h: 20, x: 0, y: 100})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 50, y: 60})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_multiline_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 30, height: 50, flex_direction: :column], [
          box([width: 20, height: 20])
        ]),
        box([width: 40, height: 70, flex_direction: :column], [
          box([width: 10, height: 10])
        ]),
        box([width: 50, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 50, x: 0, y: 50})
      assert_layout(child(r, 2), %{w: 40, h: 70, x: 50, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 20, x: 50, y: 70})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 20, x: 0, y: 0})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_multiline_column2" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap, align_items: :baseline], [
        box([width: 50, height: 50, flex_direction: :column]),
        box([width: 30, height: 50, flex_direction: :column], [
          box([width: 20, height: 20, flex_direction: :column])
        ]),
        box([width: 40, height: 70, flex_direction: :column], [
          box([width: 10, height: 10, flex_direction: :column])
        ]),
        box([width: 50, height: 20, flex_direction: :column])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 30, h: 50, x: 0, y: 50})
      assert_layout(child(r, 2), %{w: 40, h: 70, x: 50, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 20, x: 50, y: 70})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 20, h: 20, x: 0, y: 0})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_multiline_row_and_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50, flex_direction: :column], [
          box([width: 50, height: 10])
        ]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ]),
        box([width: 50, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 40})
      assert_layout(child(r, 2), %{w: 50, h: 20, x: 0, y: 100})
      assert_layout(child(r, 3), %{w: 50, h: 20, x: 50, y: 90})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_nested_child" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 50]),
        box([width: 50, height: 20, flex_direction: :column], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_baseline_nested_column" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :baseline], [
        box([width: 50, height: 60]),
        box([flex_direction: :column], [
          box([width: 50, height: 80, flex_direction: :column], [
            box([width: 50, height: 30, flex_direction: :column]),
            box([width: 50, height: 40, flex_direction: :column])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 60, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 80, x: 50, y: 30})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 80, x: 0, y: 0})
      c10 = child(c1, 0)
      assert_layout(child(c10, 0), %{w: 50, h: 30, x: 0, y: 0})
      assert_layout(child(c10, 1), %{w: 50, h: 40, x: 0, y: 30})
    end
  end

  describe "align_center_should_size_based_on_content" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center], [
        box([justify_content: :center], [
          box([flex_grow: 1], [
            box([width: 20, height: 20])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 40})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 20, h: 20, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "align_content_center_single_line" do
    test "border_box" do
      el = box([width: 120, height: 100, align_content: :center], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 120.0, height: 100.0})
      assert_layout(r, %{w: 120, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 10, x: 20, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 10, x: 40, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 10, x: 60, y: 0})
      assert_layout(child(r, 4), %{w: 20, h: 10, x: 80, y: 0})
      assert_layout(child(r, 5), %{w: 20, h: 10, x: 100, y: 0})
    end
  end

  describe "align_content_center_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :center, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_center_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :center, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_center_wrapped" do
    test "border_box" do
      el = box([width: 120, height: 100, flex_wrap: :wrap, align_content: :center], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 120.0, height: 100.0})
      assert_layout(r, %{w: 120, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 35})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 35})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 45})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 45})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 55})
      assert_layout(child(r, 5), %{w: 50, h: 10, x: 50, y: 55})
    end
  end

  describe "align_content_center_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :center, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: -25})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: -5})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 15})
    end
  end

  describe "align_content_center_wrapped_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :center, justify_content: :center, gap: 10], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: -35})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: -5})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 25})
    end
  end

  describe "align_content_end" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap, align_content: :flex_end], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 10})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 50, y: 20})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 30})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 50, y: 40})
    end
  end

  describe "align_content_end_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :flex_end, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_end_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :flex_end, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_end_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :flex_end, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: -50})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: -30})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: -10})
    end
  end

  describe "align_content_end_wrapped_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :flex_end, justify_content: :center, gap: 10], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: -70})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: -40})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: -10})
    end
  end

  describe "align_content_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap, align_content: :flex_end], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 10})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 50, y: 20})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 30})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 50, y: 40})
    end
  end

  describe "align_content_flex_start" do
    test "border_box" do
      el = box([width: 130, height: 100, flex_wrap: :wrap, align_content: :flex_start], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 130.0, height: 100.0})
      assert_layout(r, %{w: 130, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 10})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 10})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 20})
    end
  end

  describe "align_content_flex_start_with_flex" do
    test "border_box" do
      el = box([width: 100, height: 120, flex_direction: :column, flex_wrap: :wrap, align_content: :flex_start], [
        box([width: 50, flex_grow: 1, flex_shrink: 0, flex_basis: 0]),
        box([width: 50, height: 10, flex_grow: 1, flex_shrink: 0, flex_basis: 0]),
        box(width: 50),
        box([width: 50, flex_grow: 1, flex_basis: 0]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 120.0})
      assert_layout(r, %{w: 100, h: 120, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 40, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 40, x: 0, y: 40})
      assert_layout(child(r, 2), %{w: 50, h: 0, x: 0, y: 80})
      assert_layout(child(r, 3), %{w: 50, h: 40, x: 0, y: 80})
      assert_layout(child(r, 4), %{w: 50, h: 0, x: 0, y: 120})
    end
  end

  describe "align_content_flex_start_without_height_on_children" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, flex_wrap: :wrap, align_content: :flex_start], [
        box(width: 50),
        box([width: 50, height: 10]),
        box(width: 50),
        box([width: 50, height: 10]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 0, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 0, x: 0, y: 10})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 0, y: 10})
      assert_layout(child(r, 4), %{w: 50, h: 0, x: 0, y: 20})
    end
  end

  describe "align_content_not_stretch_with_align_items_stretch" do
    test "border_box" do
      el = box([width: 328, height: 52, flex_wrap: :wrap, align_content: :flex_start], [
        box([flex_direction: :column], [
          box([width: 272, height: 44])
        ]),
        box([flex_direction: :column], [
          box([width: 56, height: 44])
        ])
      ])
      r = Flex.layout(el, %{width: 328.0, height: 52.0})
      assert_layout(r, %{w: 328, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 272, h: 44, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 56, h: 44, x: 272, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 272, h: 44, x: 0, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 56, h: 44, x: 0, y: 0})
    end
  end

  describe "align_content_space_around_single_line" do
    test "border_box" do
      el = box([width: 100, height: 100, align_content: :space_around], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 17, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 16, h: 10, x: 17, y: 0})
      assert_layout(child(r, 2), %{w: 17, h: 10, x: 33, y: 0})
      assert_layout(child(r, 3), %{w: 17, h: 10, x: 50, y: 0})
      assert_layout(child(r, 4), %{w: 16, h: 10, x: 67, y: 0})
      assert_layout(child(r, 5), %{w: 17, h: 10, x: 83, y: 0})
    end
  end

  describe "align_content_space_around_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_around, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_around_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_around, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_around_wrapped" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_around], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 12})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 12})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 45})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 45})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 78})
      assert_layout(child(r, 5), %{w: 50, h: 10, x: 50, y: 78})
    end
  end

  describe "align_content_space_around_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_around, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 20})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 40})
    end
  end

  describe "align_content_space_around_wrapped_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_around, justify_content: :center, gap: 10], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 30})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 60})
    end
  end

  describe "align_content_space_around_wrapped_single" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_around], [
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 45})
    end
  end

  describe "align_content_space_between_single_line" do
    test "border_box" do
      el = box([width: 100, height: 100, align_content: :space_between], [
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 10, x: 10, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 10, x: 20, y: 0})
      assert_layout(child(r, 3), %{w: 10, h: 10, x: 30, y: 0})
      assert_layout(child(r, 4), %{w: 10, h: 10, x: 40, y: 0})
      assert_layout(child(r, 5), %{w: 10, h: 10, x: 50, y: 0})
    end
  end

  describe "align_content_space_between_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_between, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_between_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_between, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_between_wrapped" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_between], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 45})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 45})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 90})
      assert_layout(child(r, 5), %{w: 50, h: 10, x: 50, y: 90})
    end
  end

  describe "align_content_space_between_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_between, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 20})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 40})
    end
  end

  describe "align_content_space_between_wrapped_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_between, justify_content: :center, gap: 10], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 30})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 60})
    end
  end

  describe "align_content_space_between_wrapped_single" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_between], [
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_content_space_evenly_single_line" do
    test "border_box" do
      el = box([width: 100, height: 100, align_content: :space_evenly], [
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10]),
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 10, x: 10, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 10, x: 20, y: 0})
      assert_layout(child(r, 3), %{w: 10, h: 10, x: 30, y: 0})
      assert_layout(child(r, 4), %{w: 10, h: 10, x: 40, y: 0})
      assert_layout(child(r, 5), %{w: 10, h: 10, x: 50, y: 0})
    end
  end

  describe "align_content_space_evenly_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_evenly, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_evenly_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :space_evenly, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_space_evenly_wrapped" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_evenly], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 18})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 18})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 45})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 45})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 73})
      assert_layout(child(r, 5), %{w: 50, h: 10, x: 50, y: 73})
    end
  end

  describe "align_content_space_evenly_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_evenly, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 20})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 40})
    end
  end

  describe "align_content_space_evenly_wrapped_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :space_evenly, justify_content: :center, gap: 10], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 30})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 60})
    end
  end

  describe "align_content_space_evenly_wrapped_single" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_between], [
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_content_spacearound" do
    test "border_box" do
      el = box([width: 140, height: 120, flex_wrap: :wrap, align_content: :space_around], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 140.0, height: 120.0})
      assert_layout(r, %{w: 140, h: 120, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 15})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 15})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 55})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 55})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 95})
    end
  end

  describe "align_content_spacebetween" do
    test "border_box" do
      el = box([width: 130, height: 100, flex_wrap: :wrap, align_content: :space_between], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 130.0, height: 100.0})
      assert_layout(r, %{w: 130, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 45})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 45})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 90})
    end
  end

  describe "align_content_start" do
    test "border_box" do
      el = box([width: 130, height: 100, flex_wrap: :wrap, align_content: :flex_start], [
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10]),
        box([width: 50, height: 10])
      ])
      r = Flex.layout(el, %{width: 130.0, height: 100.0})
      assert_layout(r, %{w: 130, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 10, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 10, x: 0, y: 10})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 50, y: 10})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 0, y: 20})
    end
  end

  describe "align_content_start_single_line_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :flex_start, justify_content: :center], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_start_single_line_negative_space_gap" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, align_content: :flex_start, justify_content: :center, gap: 10], [
          box([height: 60, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 60, x: 20, y: 0})
    end
  end

  describe "align_content_start_wrapped_negative_space" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 320, height: 320, flex_direction: :column, padding_left: 60, padding_right: 60, padding_top: 60, padding_bottom: 60], [
        box([height: 10, flex_wrap: :wrap, align_content: :flex_start, justify_content: :center], [
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0]),
          box([height: 20, flex_shrink: 0])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: 320.0})
      assert_layout(r, %{w: 320, h: 320, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 200, h: 10, x: 60, y: 60})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 160, h: 20, x: 20, y: 0})
      assert_layout(child(c0, 1), %{w: 160, h: 20, x: 20, y: 20})
      assert_layout(child(c0, 2), %{w: 160, h: 20, x: 20, y: 40})
    end
  end

  describe "align_content_stretch" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_direction: :column, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box(width: 50),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 0, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 0, x: 0, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 0, x: 0, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 0, x: 0, y: 0})
      assert_layout(child(r, 4), %{w: 50, h: 0, x: 0, y: 0})
    end
  end

  describe "align_content_stretch_column" do
    test "border_box" do
      el = box([width: 100, height: 150, flex_direction: :column, flex_wrap: :wrap, align_content: :stretch], [
        box([height: 50, flex_direction: :column], [
          box([flex_grow: 1, flex_basis: 0])
        ]),
        box([height: 50, flex_grow: 1, flex_basis: 0]),
        box(height: 50),
        box(height: 50),
        box(height: 50)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 150.0})
      assert_layout(r, %{w: 100, h: 150, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 0, x: 0, y: 50})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 0, y: 100})
      assert_layout(child(r, 4), %{w: 50, h: 50, x: 50, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 0, y: 0})
    end
  end

  describe "align_content_stretch_is_not_overriding_align_items" do
    test "border_box" do
      el = box([align_content: :stretch], [
        box([width: 100, height: 100, align_items: :center, align_content: :stretch], [
          box([width: 10, height: 10, align_content: :stretch])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 45})
    end
  end

  describe "align_content_stretch_row" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box(width: 50),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 4), %{w: 50, h: 50, x: 50, y: 50})
    end
  end

  describe "align_content_stretch_row_with_children" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box([width: 50, flex_direction: :column], [
          box([flex_grow: 1, flex_basis: 0])
        ]),
        box(width: 50),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 4), %{w: 50, h: 50, x: 50, y: 50})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 0, y: 0})
    end
  end

  describe "align_content_stretch_row_with_fixed_height" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, height: 60]),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 80, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 60, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 80, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 20, x: 0, y: 80})
      assert_layout(child(r, 4), %{w: 50, h: 20, x: 50, y: 80})
    end
  end

  describe "align_content_stretch_row_with_flex" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, flex_grow: 1, flex_basis: 0]),
        box(width: 50),
        box([width: 50, flex_grow: 1, flex_basis: 0]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 100, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 100, x: 50, y: 0})
      assert_layout(child(r, 3), %{w: 0, h: 100, x: 100, y: 0})
      assert_layout(child(r, 4), %{w: 50, h: 100, x: 100, y: 0})
    end
  end

  describe "align_content_stretch_row_with_flex_no_shrink" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, flex_grow: 1, flex_basis: 0]),
        box(width: 50),
        box([width: 50, flex_grow: 1, flex_shrink: 0, flex_basis: 0]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 100, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 100, x: 50, y: 0})
      assert_layout(child(r, 3), %{w: 0, h: 100, x: 100, y: 0})
      assert_layout(child(r, 4), %{w: 50, h: 100, x: 100, y: 0})
    end
  end

  describe "align_content_stretch_row_with_margin" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
        box(width: 50),
        box([width: 50, margin_left: 10, margin_right: 10, margin_top: 10, margin_bottom: 10]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 40, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 60, y: 10})
      assert_layout(child(r, 2), %{w: 50, h: 40, x: 0, y: 40})
      assert_layout(child(r, 3), %{w: 50, h: 20, x: 60, y: 50})
      assert_layout(child(r, 4), %{w: 50, h: 20, x: 0, y: 80})
    end
  end

  describe "align_content_stretch_row_with_max_height" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, max_height: 20]),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 4), %{w: 50, h: 50, x: 50, y: 50})
    end
  end

  describe "align_content_stretch_row_with_min_height" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, min_height: 80]),
        box(width: 50),
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 90, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 90, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 90, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 10, x: 0, y: 90})
      assert_layout(child(r, 4), %{w: 50, h: 10, x: 50, y: 90})
    end
  end

  describe "align_content_stretch_row_with_padding" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box([width: 50, padding: 10]),
        box(width: 50),
        box([width: 50, padding: 10]),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 100, y: 0})
      assert_layout(child(r, 3), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 4), %{w: 50, h: 50, x: 50, y: 50})
    end
  end

  describe "align_content_stretch_row_with_single_row" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box(width: 50),
        box(width: 50)
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 100, x: 50, y: 0})
    end
  end

  describe "align_content_stretch_row_wrap" do
    test "border_box" do
      el = box([width: 150, height: 100, flex_wrap: :wrap, align_content: :stretch], [
        box([width: 100], [
          box([width: 50, height: 150])
        ])
      ])
      r = Flex.layout(el, %{width: 150.0, height: 100.0})
      assert_layout(r, %{w: 150, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 150, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 150, x: 0, y: 0})
    end
  end

  describe "align_flex_start_with_shrinking_children" do
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([align_items: :flex_start], [
          box([flex_grow: 1], [
            box(flex_grow: 1)
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 500, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "align_flex_start_with_shrinking_children_with_stretch" do
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([align_items: :flex_start], [
          box([flex_grow: 1, align_items: :stretch], [
            box(flex_grow: 1)
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 500, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 0, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 0, h: 0, x: 0, y: 0})
    end
  end

  describe "align_flex_start_with_stretching_children" do
    test "border_box" do
      el = box([width: 500, height: 500], [
        box([align_items: :stretch], [
          box([flex_grow: 1], [
            box(flex_grow: 1)
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 500, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 0, h: 500, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 0, h: 500, x: 0, y: 0})
    end
  end

  describe "align_items_center" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 45})
    end
  end

  describe "align_items_center_child_with_margin_bigger_than_parent" do
    test "border_box" do
      el = box([width: 50, height: 50, align_items: :center, justify_content: :center], [
        box([align_items: :center], [
          box([width: 50, height: 50, margin_left: 10, margin_right: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 50, x: -10, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 10, y: 0})
    end
  end

  describe "align_items_center_child_without_margin_bigger_than_parent" do
    test "border_box" do
      el = box([width: 50, height: 50, align_items: :center, justify_content: :center], [
        box([align_items: :center], [
          box([width: 70, height: 70])
        ])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 70, x: -10, y: -10})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 70, x: 0, y: 0})
    end
  end

  describe "align_items_center_justify_content_center" do
    # Unsupported: percentage dimensions, measure function, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 500, height: 500, flex_direction: :column], [
        box([height: 50, flex_direction: :column, align_items: :center, justify_content: :center], [
          box([flex_direction: :column, align_items: :center, justify_content: :center, margin_left: 10, margin_right: 10], [
            box([width: 10, height: 10])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 500.0, height: 500.0})
      assert_layout(r, %{w: 500, h: 500, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 500, h: 50, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 50, x: 245, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 10, h: 10, x: 0, y: 20})
    end
  end

  describe "align_items_center_min_max_with_padding" do
    test "border_box" do
      el = box([min_width: 320, min_height: 72, max_width: 320, max_height: 504, align_items: :center, padding_top: 8, padding_bottom: 8], [
        box([width: 62, height: 62])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 320, h: 78, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 62, h: 62, x: 0, y: 8})
    end
  end

  describe "align_items_center_with_child_margin" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center], [
        box([width: 10, height: 10, margin_top: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 50})
    end
  end

  describe "align_items_center_with_child_top" do
    # Unsupported: insets
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 55})
    end
  end

  describe "align_items_center_with_height_with_padding_border_with_wrap" do
    test "border_box" do
      el = box([], [
        box([width: 100, height: 100, flex_wrap: :wrap, align_items: :center, align_content: :flex_start], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ]),
        box([width: 100, height: 100, flex_wrap: :wrap, align_items: :center], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 100, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 5})
      assert_layout(child(c0, 1), %{w: 10, h: 20, x: 10, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c1, 1), %{w: 10, h: 20, x: 10, y: 40})
    end
  end

  describe "align_items_center_with_max_height_percentage_with_align_content_flex_start" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, height: 100, align_items: :center, align_content: :flex_start], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 50, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 20})
      assert_layout(child(c0, 1), %{w: 10, h: 20, x: 10, y: 15})
    end
  end

  describe "align_items_center_with_max_height_with_align_content_flex_start" do
    test "border_box" do
      el = box([width: 100, max_height: 100, align_items: :center, align_content: :flex_start], [
        box([width: 10, height: 50]),
        box([width: 10, height: 150])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 50, x: 0, y: 25})
      assert_layout(child(r, 1), %{w: 10, h: 150, x: 10, y: -25})
    end
  end

  describe "align_items_center_with_max_height_with_padding_border" do
    test "border_box" do
      el = box([flex_direction: :column], [
        box([width: 100, max_height: 100, align_items: :center, align_content: :flex_start, padding: 20], [
          box([width: 10, height: 10]),
          box([width: 10, height: 150])
        ]),
        box([width: 100, max_height: 100, flex_wrap: :wrap, align_items: :center, align_content: :flex_start, padding: 20], [
          box([width: 10, height: 10]),
          box([width: 10, height: 150])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 0, y: 100})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 20, y: 45})
      assert_layout(child(c0, 1), %{w: 10, h: 150, x: 30, y: -25})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 10, h: 10, x: 20, y: 90})
      assert_layout(child(c1, 1), %{w: 10, h: 150, x: 30, y: 20})
    end
  end

  describe "align_items_center_with_min_height_percentage_with_align_content_flex_start" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 100, align_items: :center, align_content: :flex_start], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c0, 1), %{w: 10, h: 20, x: 10, y: 40})
    end
  end

  describe "align_items_center_with_min_height_with_align_content_flex_start" do
    test "border_box" do
      el = box([width: 100, min_height: 100, align_items: :center, align_content: :flex_start], [
        box([width: 10, height: 10]),
        box([width: 10, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(r, 1), %{w: 10, h: 20, x: 10, y: 40})
    end
  end

  describe "align_items_center_with_min_height_with_align_content_flex_start_with_wrap" do
    test "border_box" do
      el = box([], [
        box([width: 100, min_height: 100, flex_wrap: :wrap, align_items: :center, align_content: :flex_start], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ]),
        box([width: 100, min_height: 100, flex_wrap: :wrap, align_items: :center], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ]),
        box([width: 100, min_height: 100, align_items: :center], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ]),
        box([width: 100, min_height: 100, align_items: :center, align_content: :flex_start], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 400, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 100, y: 0})
      assert_layout(child(r, 2), %{w: 100, h: 100, x: 200, y: 0})
      assert_layout(child(r, 3), %{w: 100, h: 100, x: 300, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 0, y: 5})
      assert_layout(child(c0, 1), %{w: 10, h: 20, x: 10, y: 0})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c1, 1), %{w: 10, h: 20, x: 10, y: 40})
      c2 = child(r, 2)
      assert_layout(child(c2, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c2, 1), %{w: 10, h: 20, x: 10, y: 40})
      c3 = child(r, 3)
      assert_layout(child(c3, 0), %{w: 10, h: 10, x: 0, y: 45})
      assert_layout(child(c3, 1), %{w: 10, h: 20, x: 10, y: 40})
    end
  end

  describe "align_items_center_with_min_height_with_padding_border" do
    test "border_box" do
      el = box([], [
        box([width: 100, min_height: 100, align_items: :center, align_content: :flex_start, padding: 15], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ]),
        box([width: 100, min_height: 100, flex_wrap: :wrap, align_items: :center, align_content: :flex_start, padding: 15], [
          box([width: 10, height: 10]),
          box([width: 10, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 200, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 100, x: 100, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 10, h: 10, x: 15, y: 45})
      assert_layout(child(c0, 1), %{w: 10, h: 20, x: 25, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 10, h: 10, x: 15, y: 20})
      assert_layout(child(c1, 1), %{w: 10, h: 20, x: 25, y: 15})
    end
  end

  describe "align_items_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_end], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 90})
    end
  end

  describe "align_items_flex_end_child_with_margin_bigger_than_parent" do
    test "border_box" do
      el = box([width: 50, height: 50, align_items: :center, justify_content: :center], [
        box([align_items: :flex_end], [
          box([width: 50, height: 50, margin_left: 10, margin_right: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 50, x: -10, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 50, h: 50, x: 10, y: 0})
    end
  end

  describe "align_items_flex_end_child_without_margin_bigger_than_parent" do
    test "border_box" do
      el = box([width: 50, height: 50, align_items: :center, justify_content: :center], [
        box([align_items: :flex_end], [
          box([width: 70, height: 70])
        ])
      ])
      r = Flex.layout(el, %{width: 50.0, height: 50.0})
      assert_layout(r, %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 70, h: 70, x: -10, y: -10})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 70, h: 70, x: 0, y: 0})
    end
  end

  describe "align_items_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "align_items_min_max" do
    test "border_box" do
      el = box([height: 100, min_width: 100, max_width: 200, flex_direction: :column, align_items: :center], [
        box([width: 60, height: 60])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 60, x: 20, y: 0})
    end
  end

  describe "align_items_stretch" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
    end
  end

  describe "align_items_stretch_min_cross" do
    test "border_box" do
      el = box([min_width: 400, min_height: 50, flex_direction: :column], [
        box([height: 36, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 400, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 400, h: 36, x: 0, y: 0})
    end
  end

  describe "align_self_baseline" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 50, height: 50, align_self: :baseline]),
        box([width: 50, height: 20, align_self: :baseline], [
          box([width: 50, height: 10])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 20, x: 50, y: 40})
      c1 = child(r, 1)
      assert_layout(child(c1, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "align_self_center" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10, align_self: :center])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 45})
    end
  end

  describe "align_self_center_undefined_max_height" do
    test "border_box" do
      el = box([width: 280, min_height: 52], [
        box([width: 240, height: 44]),
        box([width: 40, height: 56, align_self: :center])
      ])
      r = Flex.layout(el, %{width: 280.0, height: nil})
      assert_layout(r, %{w: 280, h: 56, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 240, h: 44, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 56, x: 240, y: 0})
    end
  end

  describe "align_self_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10, align_self: :flex_end])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 90})
    end
  end

  describe "align_self_flex_end_override_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :flex_start], [
        box([width: 10, height: 10, align_self: :flex_end])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 90})
    end
  end

  describe "align_self_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, height: 10, align_self: :flex_start])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "align_stretch_should_size_based_on_parent" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([justify_content: :center], [
          box([flex_grow: 1], [
            box([width: 20, height: 20])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 20, h: 100, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 20, h: 20, x: 0, y: 0})
    end
  end
end
