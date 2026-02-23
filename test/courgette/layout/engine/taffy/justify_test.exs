# credo:disable-for-this-file Credo.Check.Readability.MaxLineLength
defmodule Courgette.Layout.Engine.Taffy.JustifyTest do
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

  describe "justify_content_column_center" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :center], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 35})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 45})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 55})
    end
  end

  describe "justify_content_column_end" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_end], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 80})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 90})
    end
  end

  describe "justify_content_column_end_reverse" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_end], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 80})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 90})
    end
  end

  describe "justify_content_column_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_end], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 70})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 80})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 90})
    end
  end

  describe "justify_content_column_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_start], [
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

  describe "justify_content_column_max_height_and_margin" do
    test "border_box" do
      el = box([], [
        box([height: 100, max_height: 80, flex_direction: :column, justify_content: :center, margin_top: 100], [
          box([width: 20, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 180, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 80, x: 0, y: 100})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 20, h: 20, x: 0, y: 30})
    end
  end

  describe "justify_content_column_min_height_and_margin" do
    test "border_box" do
      el = box([], [
        box([min_height: 50, flex_direction: :column, justify_content: :center, margin_top: 100], [
          box([width: 20, height: 20])
        ])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 150, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 50, x: 0, y: 100})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 20, h: 20, x: 0, y: 15})
    end
  end

  describe "justify_content_column_min_height_and_margin_bottom" do
    test "border_box" do
      el = box([min_height: 50, flex_direction: :column, justify_content: :center], [
        box([width: 20, height: 20, margin_bottom: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 10})
    end
  end

  describe "justify_content_column_min_height_and_margin_top" do
    test "border_box" do
      el = box([min_height: 50, flex_direction: :column, justify_content: :center], [
        box([width: 20, height: 20, margin_top: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 20, h: 50, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 20})
    end
  end

  describe "justify_content_column_space_around" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_around], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 12})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 45})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 78})
    end
  end

  describe "justify_content_column_space_between" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_between], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 45})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 90})
    end
  end

  describe "justify_content_column_space_evenly" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :space_evenly], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 18})
      assert_layout(child(r, 1), %{w: 100, h: 10, x: 0, y: 45})
      assert_layout(child(r, 2), %{w: 100, h: 10, x: 0, y: 73})
    end
  end

  describe "justify_content_column_start" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_direction: :column, justify_content: :flex_start], [
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

  describe "justify_content_min_max" do
    test "border_box" do
      el = box([width: 100, min_height: 100, max_height: 200, flex_direction: :column, justify_content: :center], [
        box([width: 60, height: 60])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 60, x: 0, y: 20})
    end
  end

  describe "justify_content_min_width_with_padding_child_width_greater_than_parent" do
    test "border_box" do
      el = box([width: 1000, height: 1584, flex_direction: :column, align_content: :stretch], [
        box([align_content: :stretch], [
          box([min_width: 400, align_content: :stretch, justify_content: :center, padding_left: 100, padding_right: 100], [
            box([width: 300, height: 100, align_content: :stretch])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 1000.0, height: 1584.0})
      assert_layout(r, %{w: 1000, h: 1584, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 1000, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 500, h: 100, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 300, h: 100, x: 100, y: 0})
    end
  end

  describe "justify_content_min_width_with_padding_child_width_lower_than_parent" do
    test "border_box" do
      el = box([width: 1080, height: 1584, flex_direction: :column, align_content: :stretch], [
        box([align_content: :stretch], [
          box([min_width: 400, align_content: :stretch, justify_content: :center, padding_left: 100, padding_right: 100], [
            box([width: 199, height: 100, align_content: :stretch])
          ])
        ])
      ])
      r = Flex.layout(el, %{width: 1080.0, height: 1584.0})
      assert_layout(r, %{w: 1080, h: 1584, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 1080, h: 100, x: 0, y: 0})
      c0 = child(r, 0)
      assert_layout(child(c0, 0), %{w: 400, h: 100, x: 0, y: 0})
      c00 = child(c0, 0)
      assert_layout(child(c00, 0), %{w: 199, h: 100, x: 101, y: 0})
    end
  end

  describe "justify_content_overflow_min_max" do
    test "border_box" do
      el = box([min_height: 100, max_height: 110, flex_direction: :column, justify_content: :center], [
        box([width: 50, height: 50, flex_shrink: 0]),
        box([width: 50, height: 50, flex_shrink: 0]),
        box([width: 50, height: 50, flex_shrink: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 50, h: 110, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 50, h: 50, x: 0, y: -20})
      assert_layout(child(r, 1), %{w: 50, h: 50, x: 0, y: 30})
      assert_layout(child(r, 2), %{w: 50, h: 50, x: 0, y: 80})
    end
  end

  describe "justify_content_row_center" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :center], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 35, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 45, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 55, y: 0})
    end
  end

  describe "justify_content_row_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_end], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 70, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 80, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 90, y: 0})
    end
  end

  describe "justify_content_row_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_start], [
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

  describe "justify_content_row_max_width_and_margin" do
    test "border_box" do
      el = box([width: 100, max_width: 80, justify_content: :center], [
        box([width: 20, height: 20, margin_left: 100])
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 80, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 20, x: 90, y: 0})
    end
  end

  describe "justify_content_row_min_width_and_margin" do
    test "border_box" do
      el = box([min_width: 50, justify_content: :center], [
        box([width: 20, height: 20, margin_left: 10])
      ])
      r = Flex.layout(el, %{width: nil, height: nil})
      assert_layout(r, %{w: 50, h: 20, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 20, y: 0})
    end
  end

  describe "justify_content_row_space_around" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_around], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 12, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 45, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 78, y: 0})
    end
  end

  describe "justify_content_row_space_between" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_between], [
        box(width: 10),
        box(width: 10),
        box(width: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 10, h: 100, x: 45, y: 0})
      assert_layout(child(r, 2), %{w: 10, h: 100, x: 90, y: 0})
    end
  end

  describe "justify_content_row_space_evenly" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_evenly], [
        box(height: 10),
        box(height: 10),
        box(height: 10)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 10, x: 25, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 10, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 0, h: 10, x: 75, y: 0})
    end
  end
end
