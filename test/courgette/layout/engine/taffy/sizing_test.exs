defmodule Courgette.Layout.Engine.Taffy.SizingTest do
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

  describe "border_center_child" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center, justify_content: :center, padding_top: 10, padding_bottom: 20], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 45, y: 40})
    end
  end

  describe "border_container_match_child" do
    test "border_box" do
      el = box([flex_direction: :column, padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 30, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "border_flex_child" do
    test "border_box" do
      el = box([width: 100, height: 100, padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10], [
        box([width: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 80, x: 10, y: 10})
    end
  end

  describe "border_no_child" do
    test "border_box" do
      el = box([padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "border_no_size" do
    test "border_box" do
      el = box([flex_direction: :column, padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "border_stretch_child" do
    test "border_box" do
      el = box([width: 100, height: 100, padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10], [
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 80, x: 10, y: 10})
    end
  end

  describe "margin_and_flex_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([flex_grow: 1, margin_top: 10, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 80, x: 0, y: 10})
    end
  end

  describe "margin_and_flex_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([flex_grow: 1, margin_left: 10, margin_right: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 100, x: 10, y: 0})
    end
  end

  describe "margin_and_stretch_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([flex_grow: 1, margin_left: 10, margin_right: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 100, x: 10, y: 0})
    end
  end

  describe "margin_and_stretch_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([flex_grow: 1, margin_top: 10, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 80, x: 0, y: 10})
    end
  end

  describe "margin_auto_bottom" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 75})
    end
  end

  describe "margin_auto_bottom_and_top" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 75})
    end
  end

  describe "margin_auto_bottom_and_top_justify_center" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, justify_content: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 50, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 100, y: 0})
    end
  end

  describe "margin_auto_left" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 100, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_left_and_right" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 0})
    end
  end

  describe "margin_auto_left_and_right_column" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 50, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_left_and_right_column_and_center" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 50, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_left_and_right_stretch" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :stretch], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 50, y: 0})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 0})
    end
  end

  describe "margin_auto_left_child_bigger_than_parent" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 52, height: 52, justify_content: :center], [
        box([width: 72, height: 72])
      ])
      r = Flex.layout(el, %{width: 52.0, height: 52.0})
      assert_layout(r, %{w: 52, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 52, h: 72, x: 0, y: 0})
    end
  end

  describe "margin_auto_left_fix_right_child_bigger_than_parent" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 52, height: 52, justify_content: :center], [
        box([width: 72, height: 72, margin_right: 10])
      ])
      r = Flex.layout(el, %{width: 52.0, height: 52.0})
      assert_layout(r, %{w: 52, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 42, h: 72, x: 0, y: 0})
    end
  end

  describe "margin_auto_left_right_child_bigger_than_parent" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 52, height: 52, justify_content: :center], [
        box([width: 72, height: 72])
      ])
      r = Flex.layout(el, %{width: 52.0, height: 52.0})
      assert_layout(r, %{w: 52, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 52, h: 72, x: 0, y: 0})
    end
  end

  describe "margin_auto_left_stretching_child" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([flex_grow: 1, flex_basis: 0]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 150, h: 0, x: 0, y: 100})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_multiple_children_column" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 75, y: 25})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 75, y: 100})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 75, y: 150})
    end
  end

  describe "margin_auto_multiple_children_row" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 75, y: 75})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_right" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 75})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_auto_top" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 150})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 50, y: 75})
    end
  end

  describe "margin_auto_top_and_bottom_stretch" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, flex_direction: :column, align_items: :stretch], [
        box([width: 50, height: 50]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: 50})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 0, y: 150})
    end
  end

  describe "margin_auto_top_stretching_child" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :center], [
        box([flex_grow: 1, flex_basis: 0]),
        box([width: 50, height: 50])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 150, h: 0, x: 0, y: 200})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 150, y: 75})
    end
  end

  describe "margin_bottom" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_end], [
        box([height: 10, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 80})
    end
  end

  describe "margin_fix_left_auto_right_child_bigger_than_parent" do
    # Unsupported: auto margins
    @tag :skip
    test "border_box" do
      el = box([width: 52, height: 52, justify_content: :center], [
        box([width: 72, height: 72, margin_left: 10])
      ])
      r = Flex.layout(el, %{width: 52.0, height: 52.0})
      assert_layout(r, %{w: 52, h: 52, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 42, h: 72, x: 10, y: 0})
    end
  end

  describe "margin_left" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, margin_left: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 10, y: 0})
    end
  end

  describe "margin_right" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_end], [
        box([width: 10, margin_right: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 80, y: 0})
    end
  end

  describe "margin_should_not_be_part_of_max_height" do
    test "border_box" do
      el = box([width: 250, height: 250], [
        box([width: 100, height: 100, max_height: 100, margin_top: 20])
      ])
      r = Flex.layout(el, %{width: 250.0, height: 250.0})
      assert_layout(r, %{w: 250, h: 250, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 20})
    end
  end

  describe "margin_should_not_be_part_of_max_width" do
    test "border_box" do
      el = box([width: 250, height: 250], [
        box([width: 100, height: 100, max_width: 100, margin_left: 20])
      ])
      r = Flex.layout(el, %{width: 250.0, height: 250.0})
      assert_layout(r, %{w: 250, h: 250, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 20, y: 0})
    end
  end

  describe "margin_top" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([height: 10, margin_top: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 10})
    end
  end

  describe "margin_with_sibling_column" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([flex_grow: 1, margin_bottom: 10]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 45, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 45, x: 0, y: 55})
    end
  end

  describe "margin_with_sibling_row" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([flex_grow: 1, margin_right: 10]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 45, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 45, h: 100, x: 55, y: 0})
    end
  end

  describe "max_height" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([width: 10, max_height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 50, x: 0, y: 0})
    end
  end

  describe "max_height_overrides_height" do
    test "border_box" do
      el = box([], [
        box([height: 200, max_height: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "max_height_overrides_height_on_root" do
    test "border_box" do
      el = box([height: 200, max_height: 100])
      r = Flex.layout(el, %{width: nil, height: 200.0})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "max_width" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([height: 10, max_width: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 10, x: 0, y: 0})
    end
  end

  describe "max_width_overrides_width" do
    test "border_box" do
      el = box([], [
        box([width: 200, max_width: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 0, x: 0, y: 0})
    end
  end

  describe "max_width_overrides_width_on_root" do
    test "border_box" do
      el = box([width: 200, max_width: 100])
      r = Flex.layout(el, %{width: 200.0, height: nil})
      assert_layout(r, %{w: 100, h: 0, x: 0, y: 0})
    end
  end

  describe "min_height" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([min_height: 60, flex_grow: 1]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 60, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 40, x: 0, y: 60})
    end
  end

  describe "min_height_larger_than_height" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([height: 25, min_height: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 50, x: 0, y: 0})
    end
  end

  describe "min_height_overrides_height" do
    test "border_box" do
      el = box([], [
        box([height: 50, min_height: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "min_height_overrides_height_on_root" do
    test "border_box" do
      el = box([height: 50, min_height: 100])
      r = Flex.layout(el, %{width: nil, height: 50.0})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "min_height_overrides_max_height" do
    test "border_box" do
      el = box([], [
        box([min_height: 100, max_height: 50])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
    end
  end

  describe "min_height_with_nested_fixed_height" do
    test "border_box" do
      el = box([width: 320, min_height: 44, padding_left: 16, padding_right: 16], [
        box([min_height: 28, flex_direction: :column, flex_shrink: 0, align_self: :flex_start, margin_top: 8, margin_bottom: 9], [
          box([width: 40, height: 40])
        ])
      ])
      r = Flex.layout(el, %{width: 320.0, height: nil})
      assert_layout(r, %{w: 320, h: 57, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 40, h: 40, x: 16, y: 8})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 40, h: 40, x: 0, y: 0})
    end
  end

  describe "min_max_percent_different_width_height" do
    # Unsupported: percentage dimensions, measure function, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 200, flex_direction: :column, align_items: :flex_start], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 20, x: 0, y: 0})
    end
  end

  describe "min_max_percent_no_width_height" do
    # Unsupported: percentage dimensions, percentage values
    @tag :skip
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, align_items: :flex_start], [
        box([])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 0, y: 0})
    end
  end

  describe "min_width" do
    test "border_box" do
      el = box([width: 100, height: 100], [
        box([min_width: 60, flex_grow: 1]),
        box(flex_grow: 1)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 40, h: 100, x: 60, y: 0})
    end
  end

  describe "min_width_larger_than_width" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column], [
        box([width: 25, min_width: 50])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 0, x: 0, y: 0})
    end
  end

  describe "min_width_overrides_max_width" do
    test "border_box" do
      el = box([], [
        box([min_width: 100, max_width: 50])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 0, x: 0, y: 0})
    end
  end

  describe "min_width_overrides_width" do
    test "border_box" do
      el = box([], [
        box([width: 50, min_width: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 0, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 0, x: 0, y: 0})
    end
  end

  describe "min_width_overrides_width_on_root" do
    test "border_box" do
      el = box([width: 50, min_width: 100])
      r = Flex.layout(el, %{width: 50.0, height: nil})
      assert_layout(r, %{w: 100, h: 0, x: 0, y: 0})
    end
  end

  describe "padding_align_end_child" do
    test "border_box" do
      el = box([width: 200, height: 200, align_items: :flex_end, justify_content: :flex_end], [
        box([width: 100, height: 100, padding: 20])
      ])
      r = Flex.layout(el, %{width: 200.0, height: 200.0})
      assert_layout(r, %{w: 200, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 100, y: 100})
    end
  end

  describe "padding_border_overrides_max_size" do
    test "border_box" do
      el = box([], [
        box([max_width: 12, max_height: 12, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 22, h: 14, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 22, h: 14, x: 0, y: 0})
    end
  end

  describe "padding_border_overrides_min_size" do
    test "border_box" do
      el = box([], [
        box([min_width: 0, min_height: 0, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 22, h: 14, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 22, h: 14, x: 0, y: 0})
    end
  end

  describe "padding_border_overrides_size" do
    test "border_box" do
      el = box([], [
        box([width: 12, height: 12, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 22, h: 14, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 22, h: 14, x: 0, y: 0})
    end
  end

  describe "padding_border_overrides_size_flex_basis_0_growable" do
    test "border_box" do
      el = box([], [
        box([width: 12, height: 12, flex_grow: 1, flex_basis: 0, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11]),
        box([width: 12, height: 12, flex_grow: 1, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 34, h: 14, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 28, h: 14, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 6, h: 12, x: 28, y: 0})
    end
  end

  describe "padding_border_overrides_size_root" do
    test "border_box" do
      el = box([width: 12, height: 12, padding_left: 15, padding_right: 7, padding_top: 3, padding_bottom: 11], [
        box([])
      ])
      r = Flex.layout(el, %{width: 12.0, height: 12.0})
      assert_layout(r, %{w: 22, h: 14, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 0, x: 15, y: 3})
    end
  end

  describe "padding_center_child" do
    test "border_box" do
      el = box([width: 100, height: 100, align_items: :center, justify_content: :center, padding_left: 10, padding_right: 20, padding_top: 10, padding_bottom: 20], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 40, y: 40})
    end
  end

  describe "padding_container_match_child" do
    test "border_box" do
      el = box([flex_direction: :column, padding: 10], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 30, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "padding_flex_child" do
    test "border_box" do
      el = box([width: 100, height: 100, padding: 10], [
        box([width: 10, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 80, h: 80, x: 10, y: 10})
    end
  end

  describe "padding_no_child" do
    test "border_box" do
      el = box(padding: 10)
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "padding_no_size" do
    test "border_box" do
      el = box(padding: 10)
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 20, x: 0, y: 0})
    end
  end

  describe "padding_stretch_child" do
    test "border_box" do
      el = box([width: 100, height: 100, padding: 10], [
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 10, x: 10, y: 10})
    end
  end

  describe "size_defined_by_child" do
    test "border_box" do
      el = box([], [
        box([width: 100, height: 100])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 100, x: 0, y: 0})
    end
  end

  describe "size_defined_by_child_with_border" do
    test "border_box" do
      el = box([padding_left: 10, padding_right: 10, padding_top: 10, padding_bottom: 10], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 30, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "size_defined_by_child_with_padding" do
    test "border_box" do
      el = box([padding: 10], [
        box([width: 10, height: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 30, h: 30, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 10, x: 10, y: 10})
    end
  end

  describe "size_defined_by_grand_child" do
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
end
