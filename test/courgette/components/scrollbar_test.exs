defmodule Courgette.Components.ScrollbarTest do
  use ExUnit.Case, async: true

  import Courgette.Components.Scrollbar

  describe "scrollbar/1 vertical" do
    test "renders vertical track with correct height" do
      el = scrollbar(content_length: 20, viewport_length: 10, offset: 0)
      assert el.type == :box
      assert el.props.flex_direction == :column
      children = el.children
      assert length(children) == 10
    end

    test "thumb at top when offset is 0" do
      el = scrollbar(content_length: 20, viewport_length: 10, offset: 0)
      children = el.children
      # Thumb size: max(1, round(10 * 10 / 20)) = 5
      # Thumb position: round(0 * (10 - 5) / (20 - 10)) = 0
      thumb_children = Enum.slice(children, 0, 5)
      track_children = Enum.slice(children, 5, 5)

      for child <- thumb_children do
        [content] = child.children
        assert content == "\u2588"
      end

      for child <- track_children do
        [content] = child.children
        assert content == "\u2502"
      end
    end

    test "thumb at bottom when offset is at max" do
      # offset = content_length - viewport_length = 10
      el = scrollbar(content_length: 20, viewport_length: 10, offset: 10)
      children = el.children
      # Thumb size: 5, Thumb position: round(10 * 5 / 10) = 5
      track_children = Enum.slice(children, 0, 5)
      thumb_children = Enum.slice(children, 5, 5)

      for child <- track_children do
        [content] = child.children
        assert content == "\u2502"
      end

      for child <- thumb_children do
        [content] = child.children
        assert content == "\u2588"
      end
    end

    test "thumb in middle for middle offset" do
      # offset = 5 (half of max 10)
      el = scrollbar(content_length: 20, viewport_length: 10, offset: 5)
      children = el.children
      # Thumb size: 5
      # Thumb position: round(5 * (10 - 5) / (20 - 10)) = round(5 * 5 / 10) = round(2.5) = 3
      # So: 3 track, 5 thumb, 2 track

      texts = Enum.map(children, fn child -> hd(child.children) end)
      track_before = Enum.count(Enum.take(texts, 3), &(&1 == "\u2502"))
      assert track_before == 3

      thumb = Enum.count(Enum.slice(texts, 3, 5), &(&1 == "\u2588"))
      assert thumb == 5
    end

    test "no thumb when content fits in viewport" do
      el = scrollbar(content_length: 5, viewport_length: 10, offset: 0)
      children = el.children
      # All should be track characters (or empty)
      assert length(children) == 10

      for child <- children do
        [content] = child.children
        assert content == "\u2502"
      end
    end

    test "thumb size proportional to viewport/content ratio" do
      # Small viewport relative to content
      el = scrollbar(content_length: 100, viewport_length: 10, offset: 0)
      children = el.children
      # Thumb size: max(1, round(10 * 10 / 100)) = max(1, 1) = 1
      thumb_count = Enum.count(children, fn child -> hd(child.children) == "\u2588" end)
      assert thumb_count == 1

      # Large viewport relative to content
      el2 = scrollbar(content_length: 12, viewport_length: 10, offset: 0)
      children2 = el2.children
      # Thumb size: max(1, round(10 * 10 / 12)) = max(1, 8) = 8
      thumb_count2 = Enum.count(children2, fn child -> hd(child.children) == "\u2588" end)
      assert thumb_count2 == 8
    end
  end

  describe "scrollbar/1 horizontal" do
    test "renders horizontal track" do
      el = scrollbar(content_length: 20, viewport_length: 10, offset: 0, orientation: :horizontal)
      assert el.type == :box
      assert el.props.flex_direction == :row
      children = el.children
      assert length(children) == 10
    end

    test "horizontal uses correct track character" do
      el = scrollbar(content_length: 5, viewport_length: 10, offset: 0, orientation: :horizontal)
      children = el.children

      for child <- children do
        [content] = child.children
        assert content == "\u2500"
      end
    end
  end

  describe "scrollbar/1 defaults" do
    test "offset defaults to 0" do
      el = scrollbar(content_length: 20, viewport_length: 10)
      children = el.children
      # Should be same as offset: 0 — thumb at top
      [first | _] = children
      [content] = first.children
      assert content == "\u2588"
    end

    test "orientation defaults to vertical" do
      el = scrollbar(content_length: 20, viewport_length: 10)
      assert el.props.flex_direction == :column
    end
  end
end
