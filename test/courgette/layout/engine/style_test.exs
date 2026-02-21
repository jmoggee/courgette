defmodule Courgette.Layout.Engine.StyleTest do
  use ExUnit.Case, async: true

  alias Courgette.Element
  alias Courgette.Layout.Engine.Style

  defp style_for(props) do
    Element.new(:box, props) |> Style.from_element()
  end

  # ── Defaults ──────────────────────────────────────────────────────

  describe "defaults" do
    test "empty props produce default style" do
      s = style_for([])
      assert s.flex_direction == :row
      assert s.flex_wrap == :no_wrap
      assert s.flex_grow == 0.0
      assert s.flex_shrink == 1.0
      assert s.flex_basis == :auto
      assert s.justify_content == :flex_start
      assert s.align_items == :stretch
      assert s.align_self == :auto
      assert s.width == nil
      assert s.height == nil
      assert s.padding == %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0}
      assert s.margin == %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0}
      assert s.border == %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0}
      assert s.gap_main == 0.0
      assert s.gap_cross == 0.0
    end
  end

  # ── Border ────────────────────────────────────────────────────────

  describe "border resolution" do
    test "single border → 1-cell insets" do
      s = style_for(border: :single)
      assert s.border == %{left: 1.0, top: 1.0, right: 1.0, bottom: 1.0}
    end

    test "double border → 1-cell insets" do
      s = style_for(border: :double)
      assert s.border == %{left: 1.0, top: 1.0, right: 1.0, bottom: 1.0}
    end

    test "rounded border → 1-cell insets" do
      s = style_for(border: :rounded)
      assert s.border == %{left: 1.0, top: 1.0, right: 1.0, bottom: 1.0}
    end

    test "no border → zero insets" do
      s = style_for([])
      assert s.border == %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0}
    end
  end

  # ── Padding ───────────────────────────────────────────────────────

  describe "padding resolution" do
    test "uniform padding" do
      s = style_for(padding: 2)
      assert s.padding == %{left: 2.0, top: 2.0, right: 2.0, bottom: 2.0}
    end

    test "padding_h and padding_v" do
      s = style_for(padding_h: 3, padding_v: 1)
      assert s.padding == %{left: 3.0, top: 1.0, right: 3.0, bottom: 1.0}
    end

    test "individual sides override base" do
      s = style_for(padding: 1, padding_left: 5)
      assert s.padding.left == 5.0
      assert s.padding.right == 1.0
      assert s.padding.top == 1.0
    end

    test "individual sides override padding_h/v" do
      s = style_for(padding_h: 2, padding_left: 0)
      assert s.padding.left == 0.0
      assert s.padding.right == 2.0
    end

    test "float padding preserved" do
      s = style_for(padding: 1.5)
      assert s.padding.left == 1.5
    end
  end

  # ── Margin ────────────────────────────────────────────────────────

  describe "margin resolution" do
    test "uniform margin" do
      s = style_for(margin: 3)
      assert s.margin == %{left: 3.0, top: 3.0, right: 3.0, bottom: 3.0}
    end

    test "individual margin sides" do
      s = style_for(margin_left: 1, margin_top: 2)
      assert s.margin.left == 1.0
      assert s.margin.top == 2.0
      assert s.margin.right == 0.0
      assert s.margin.bottom == 0.0
    end
  end

  # ── Size ──────────────────────────────────────────────────────────

  describe "size resolution" do
    test "explicit width and height" do
      s = style_for(width: 40, height: 12)
      assert s.width == 40.0
      assert s.height == 12.0
    end

    test "nil dimensions remain nil" do
      s = style_for([])
      assert s.width == nil
      assert s.height == nil
    end

    test "min/max constraints" do
      s = style_for(min_width: 10, max_width: 50, min_height: 5, max_height: 20)
      assert s.min_width == 10.0
      assert s.max_width == 50.0
      assert s.min_height == 5.0
      assert s.max_height == 20.0
    end
  end

  # ── Flex ──────────────────────────────────────────────────────────

  describe "flex resolution" do
    test "flex shorthand" do
      s = style_for(flex: 1)
      assert s.flex_grow == 1.0
      assert s.flex_shrink == 1.0
      assert s.flex_basis == 0.0
    end

    test "flex: 2 sets grow to 2" do
      s = style_for(flex: 2)
      assert s.flex_grow == 2.0
    end

    test "explicit flex_grow/shrink/basis" do
      s = style_for(flex_grow: 3, flex_shrink: 0, flex_basis: 50)
      assert s.flex_grow == 3.0
      assert s.flex_shrink == 0.0
      assert s.flex_basis == 50.0
    end

    test "flex_basis: auto is default" do
      s = style_for([])
      assert s.flex_basis == :auto
    end

    test "flex shorthand can be overridden by explicit props" do
      s = style_for(flex: 1, flex_grow: 3)
      assert s.flex_grow == 3.0
      assert s.flex_basis == 0.0
    end

    test "flex_direction" do
      s = style_for(flex_direction: :column)
      assert s.flex_direction == :column
    end

    test "flex_wrap" do
      s = style_for(flex_wrap: :wrap)
      assert s.flex_wrap == :wrap
    end
  end

  # ── Alignment ─────────────────────────────────────────────────────

  describe "alignment" do
    test "justify_content" do
      s = style_for(justify_content: :center)
      assert s.justify_content == :center
    end

    test "align_items" do
      s = style_for(align_items: :flex_end)
      assert s.align_items == :flex_end
    end

    test "align_self" do
      s = style_for(align_self: :center)
      assert s.align_self == :center
    end

    test "align_content" do
      s = style_for(align_content: :space_between)
      assert s.align_content == :space_between
    end
  end

  # ── Gap ───────────────────────────────────────────────────────────

  describe "gap" do
    test "uniform gap" do
      s = style_for(gap: 2)
      assert s.gap_main == 2.0
      assert s.gap_cross == 2.0
    end

    test "individual gap axes" do
      s = style_for(gap_main: 3, gap_cross: 1)
      assert s.gap_main == 3.0
      assert s.gap_cross == 1.0
    end

    test "gap_main overrides base gap" do
      s = style_for(gap: 2, gap_main: 5)
      assert s.gap_main == 5.0
      assert s.gap_cross == 2.0
    end
  end

  # ── Overflow ──────────────────────────────────────────────────────

  describe "overflow" do
    test "default is :visible" do
      s = style_for([])
      assert s.overflow == :visible
    end

    test "word_wrap" do
      s = style_for(overflow: :word_wrap)
      assert s.overflow == :word_wrap
    end
  end
end
