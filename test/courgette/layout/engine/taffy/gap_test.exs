# credo:disable-for-this-file Credo.Check.Readability.MaxLineLength
defmodule Courgette.Layout.Engine.Taffy.GapTest do
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

  describe "gap_column_gap_child_margins" do
    test "border_box" do
      el = box([width: 80, height: 100, gap_main: 10], [
        box([flex_grow: 1, flex_basis: 0, margin_left: 2, margin_right: 2]),
        box([flex_grow: 1, flex_basis: 0, margin_left: 10, margin_right: 10]),
        box([flex_grow: 1, flex_basis: 0, margin_left: 15, margin_right: 15])
      ])
      r = Flex.layout(el, %{width: 80.0, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 2, h: 100, x: 2, y: 0})
      assert_layout(child(r, 1), %{w: 2, h: 100, x: 26, y: 0})
      assert_layout(child(r, 2), %{w: 2, h: 100, x: 63, y: 0})
    end
  end

  describe "gap_column_gap_determines_parent_width" do
    test "border_box" do
      el = box([height: 100, align_items: :stretch, gap_main: 10], [
        box(width: 10),
        box(width: 20),
        box(width: 30)
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 10, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 20, y: 0})
      assert_layout(child(r, 2), %{w: 30, h: 100, x: 50, y: 0})
    end
  end

  describe "gap_column_gap_flexible" do
    test "border_box" do
      el = box([width: 80, height: 100, gap_main: 10, gap_cross: 20], [
        box([flex_grow: 1, flex_basis: 0]),
        box([flex_grow: 1, flex_basis: 0]),
        box([flex_grow: 1, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: 80.0, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_flexible_undefined_parent" do
    test "border_box" do
      el = box([height: 100, gap_main: 10, gap_cross: 20], [
        box([flex_grow: 1, flex_basis: 0]),
        box([flex_grow: 1, flex_basis: 0]),
        box([flex_grow: 1, flex_basis: 0])
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 0, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 0, h: 100, x: 10, y: 0})
      assert_layout(child(r, 2), %{w: 0, h: 100, x: 20, y: 0})
    end
  end

  describe "gap_column_gap_inflexible" do
    test "border_box" do
      el = box([width: 80, height: 100, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 80.0, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_inflexible_undefined_parent" do
    test "border_box" do
      el = box([height: 100, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: nil, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_justify_center" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :center, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 10, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 40, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 70, y: 0})
    end
  end

  describe "gap_column_gap_justify_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_end, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 20, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 50, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 80, y: 0})
    end
  end

  describe "gap_column_gap_justify_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :flex_start, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_justify_space_around" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_around, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 3, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 40, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 77, y: 0})
    end
  end

  describe "gap_column_gap_justify_space_between" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_between, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 40, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 80, y: 0})
    end
  end

  describe "gap_column_gap_justify_space_evenly" do
    test "border_box" do
      el = box([width: 100, height: 100, justify_content: :space_evenly, gap_main: 10], [
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 5, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 40, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 75, y: 0})
    end
  end

  describe "gap_column_gap_mixed_flexible" do
    test "border_box" do
      el = box([width: 80, height: 100, gap_main: 10], [
        box(width: 20),
        box([flex_grow: 1, flex_basis: 0]),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 80.0, height: 100.0})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 100, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 100, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 100, x: 60, y: 0})
    end
  end

  describe "gap_column_gap_row_gap_wrapping" do
    test "border_box" do
      el = box([width: 80, flex_wrap: :wrap, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 80.0, height: nil})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 40})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 40})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 40})
      assert_layout(child(r, 6), %{w: 20, h: 20, x: 0, y: 80})
      assert_layout(child(r, 7), %{w: 20, h: 20, x: 30, y: 80})
      assert_layout(child(r, 8), %{w: 20, h: 20, x: 60, y: 80})
    end
  end

  describe "gap_column_gap_wrap_align_center" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :center, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 20})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 20})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 20})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 60})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 60})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 60})
    end
  end

  describe "gap_column_gap_wrap_align_flex_end" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :flex_end, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 40})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 40})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 40})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 80})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 80})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 80})
    end
  end

  describe "gap_column_gap_wrap_align_flex_start" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :flex_start, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 40})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 40})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 40})
    end
  end

  describe "gap_column_gap_wrap_align_space_around" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_around, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 10})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 10})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 10})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 70})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 70})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 70})
    end
  end

  describe "gap_column_gap_wrap_align_space_between" do
    test "border_box" do
      el = box([width: 100, height: 100, flex_wrap: :wrap, align_content: :space_between, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 100.0})
      assert_layout(r, %{w: 100, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 80})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 80})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 80})
    end
  end

  describe "gap_column_gap_wrap_align_stretch" do
    test "border_box" do
      el = box([width: 300, height: 300, flex_wrap: :wrap, align_content: :stretch, gap_main: 5], [
        box([min_width: 60, flex_grow: 1]),
        box([min_width: 60, flex_grow: 1]),
        box([min_width: 60, flex_grow: 1]),
        box([min_width: 60, flex_grow: 1]),
        box([min_width: 60, flex_grow: 1])
      ])
      r = Flex.layout(el, %{width: 300.0, height: 300.0})
      assert_layout(r, %{w: 300, h: 300, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 71, h: 150, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 72, h: 150, x: 76, y: 0})
      assert_layout(child(r, 2), %{w: 71, h: 150, x: 153, y: 0})
      assert_layout(child(r, 3), %{w: 71, h: 150, x: 229, y: 0})
      assert_layout(child(r, 4), %{w: 300, h: 150, x: 0, y: 150})
    end
  end

  describe "gap_column_row_gap_wrapping" do
    test "border_box" do
      el = box([width: 80, flex_wrap: :wrap, gap_main: 10, gap_cross: 20], [
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20]),
        box([width: 20, height: 20])
      ])
      r = Flex.layout(el, %{width: 80.0, height: nil})
      assert_layout(r, %{w: 80, h: 100, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 20, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 20, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 20, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 20, x: 0, y: 40})
      assert_layout(child(r, 4), %{w: 20, h: 20, x: 30, y: 40})
      assert_layout(child(r, 5), %{w: 20, h: 20, x: 60, y: 40})
      assert_layout(child(r, 6), %{w: 20, h: 20, x: 0, y: 80})
      assert_layout(child(r, 7), %{w: 20, h: 20, x: 30, y: 80})
      assert_layout(child(r, 8), %{w: 20, h: 20, x: 60, y: 80})
    end
  end

  describe "gap_row_gap_align_items_end" do
    test "border_box" do
      el = box([width: 100, height: 200, flex_wrap: :wrap, align_items: :flex_end, gap_main: 10, gap_cross: 20], [
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 0, x: 0, y: 90})
      assert_layout(child(r, 1), %{w: 20, h: 0, x: 30, y: 90})
      assert_layout(child(r, 2), %{w: 20, h: 0, x: 60, y: 90})
      assert_layout(child(r, 3), %{w: 20, h: 0, x: 0, y: 200})
      assert_layout(child(r, 4), %{w: 20, h: 0, x: 30, y: 200})
      assert_layout(child(r, 5), %{w: 20, h: 0, x: 60, y: 200})
    end
  end

  describe "gap_row_gap_align_items_stretch" do
    test "border_box" do
      el = box([width: 100, height: 200, flex_wrap: :wrap, align_items: :stretch, align_content: :stretch, gap_main: 10, gap_cross: 20], [
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20),
        box(width: 20)
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 20, h: 90, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 20, h: 90, x: 30, y: 0})
      assert_layout(child(r, 2), %{w: 20, h: 90, x: 60, y: 0})
      assert_layout(child(r, 3), %{w: 20, h: 90, x: 0, y: 110})
      assert_layout(child(r, 4), %{w: 20, h: 90, x: 30, y: 110})
      assert_layout(child(r, 5), %{w: 20, h: 90, x: 60, y: 110})
    end
  end

  describe "gap_row_gap_column_child_margins" do
    test "border_box" do
      el = box([width: 100, height: 200, flex_direction: :column, gap_main: 10], [
        box([flex_grow: 1, flex_basis: 0, margin_top: 2, margin_bottom: 2]),
        box([flex_grow: 1, flex_basis: 0, margin_top: 10, margin_bottom: 10]),
        box([flex_grow: 1, flex_basis: 0, margin_top: 15, margin_bottom: 15])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 42, x: 0, y: 2})
      assert_layout(child(r, 1), %{w: 100, h: 42, x: 0, y: 66})
      assert_layout(child(r, 2), %{w: 100, h: 42, x: 0, y: 143})
    end
  end

  describe "gap_row_gap_determines_parent_height" do
    test "border_box" do
      el = box([width: 100, flex_direction: :column, align_items: :stretch, gap_main: 10], [
        box(height: 10),
        box(height: 20),
        box(height: 30)
      ])
      r = Flex.layout(el, %{width: 100.0, height: nil})
      assert_layout(r, %{w: 100, h: 80, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 100, h: 10, x: 0, y: 0})
      assert_layout(child(r, 1), %{w: 100, h: 20, x: 0, y: 20})
      assert_layout(child(r, 2), %{w: 100, h: 30, x: 0, y: 50})
    end
  end

  describe "gap_row_gap_row_wrap_child_margins" do
    test "border_box" do
      el = box([width: 100, height: 200, flex_wrap: :wrap, gap_cross: 10], [
        box([width: 60, margin_top: 2, margin_bottom: 2]),
        box([width: 60, margin_top: 10, margin_bottom: 10]),
        box([width: 60, margin_top: 15, margin_bottom: 15])
      ])
      r = Flex.layout(el, %{width: 100.0, height: 200.0})
      assert_layout(r, %{w: 100, h: 200, x: 0, y: 0})
      assert_layout(child(r, 0), %{w: 60, h: 42, x: 0, y: 2})
      assert_layout(child(r, 1), %{w: 60, h: 42, x: 0, y: 66})
      assert_layout(child(r, 2), %{w: 60, h: 42, x: 0, y: 143})
    end
  end
end
