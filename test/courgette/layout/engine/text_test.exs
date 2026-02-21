defmodule Courgette.Layout.Engine.TextTest do
  use ExUnit.Case, async: true

  alias Courgette.Layout.Engine.Text

  # ── Basic measurement ─────────────────────────────────────────────

  describe "measure/3 unconstrained" do
    test "empty string" do
      assert Text.measure("", nil) == {0.0, 0.0}
    end

    test "single line" do
      assert Text.measure("Hello", nil) == {5.0, 1.0}
    end

    test "multiline text" do
      assert Text.measure("AB\nCDEF\nG", nil) == {4.0, 3.0}
    end

    test "unicode graphemes counted correctly" do
      # Each emoji is 1 grapheme
      assert Text.measure("café", nil) == {4.0, 1.0}
    end
  end

  # ── Word wrap ─────────────────────────────────────────────────────

  describe "measure/3 word_wrap" do
    test "text fits in constraint — no wrapping" do
      assert Text.measure("Hello", 10.0) == {5.0, 1.0}
    end

    test "wraps at word boundary" do
      assert Text.measure("Hello World", 6.0) == {5.0, 2.0}
    end

    test "multiple words wrapping" do
      # "one two three" with constraint 8
      # Line 1: "one two" (7)
      # Line 2: "three" (5)
      assert Text.measure("one two three", 8.0) == {7.0, 2.0}
    end

    test "long word exceeding constraint wraps at char boundary" do
      # "abcdefghij" with constraint 4
      # "abcd", "efgh", "ij"
      assert Text.measure("abcdefghij", 4.0, :word_wrap) == {4.0, 3.0}
    end

    test "words plus long word" do
      # "Hi abcdefgh" with constraint 5
      # "Hi" (2), then "abcde" (5), "fgh" (3)
      assert Text.measure("Hi abcdefgh", 5.0) == {5.0, 3.0}
    end

    test "exact fit" do
      assert Text.measure("12345", 5.0) == {5.0, 1.0}
    end

    test "newlines in source text create separate lines" do
      assert Text.measure("AB\nCD", 10.0) == {2.0, 2.0}
    end
  end

  # ── Char wrap ─────────────────────────────────────────────────────

  describe "measure/3 :wrap" do
    test "text fits — no wrapping" do
      assert Text.measure("Hello", 10.0, :wrap) == {5.0, 1.0}
    end

    test "wraps at character boundary" do
      assert Text.measure("ABCDEF", 4.0, :wrap) == {4.0, 2.0}
    end

    test "exact multiple" do
      assert Text.measure("ABCDEF", 3.0, :wrap) == {3.0, 2.0}
    end

    test "single char constraint" do
      assert Text.measure("ABC", 1.0, :wrap) == {1.0, 3.0}
    end
  end

  # ── Truncate ──────────────────────────────────────────────────────

  describe "measure/3 :truncate" do
    test "text fits — returns full width" do
      assert Text.measure("Hello", 10.0, :truncate) == {5.0, 1.0}
    end

    test "text exceeds — truncated width, height 1" do
      assert Text.measure("Hello World", 5.0, :truncate) == {5.0, 1.0}
    end

    test "multiline text — only first line" do
      assert Text.measure("AB\nCDEF", 10.0, :truncate) == {2.0, 1.0}
    end
  end

  # ── Visible ───────────────────────────────────────────────────────

  describe "measure/3 :visible" do
    test "ignores constraint" do
      assert Text.measure("Hello World", 5.0, :visible) == {11.0, 1.0}
    end
  end

  # ── Intrinsic sizing ──────────────────────────────────────────────

  describe "min_content_width/1" do
    test "empty string" do
      assert Text.min_content_width("") == 0.0
    end

    test "single word" do
      assert Text.min_content_width("Hello") == 5.0
    end

    test "multiple words — returns widest" do
      assert Text.min_content_width("Hi there everyone") == 8.0
    end

    test "newlines count as word boundaries" do
      assert Text.min_content_width("AB\nCDEF") == 4.0
    end
  end

  describe "max_content_width/1" do
    test "empty string" do
      assert Text.max_content_width("") == 0.0
    end

    test "single line" do
      assert Text.max_content_width("Hello World") == 11.0
    end

    test "multiline — returns widest line" do
      assert Text.max_content_width("AB\nCDEF\nG") == 4.0
    end
  end

  # ── grapheme_count ────────────────────────────────────────────────

  describe "grapheme_count/1" do
    test "ASCII" do
      assert Text.grapheme_count("Hello") == 5
    end

    test "empty" do
      assert Text.grapheme_count("") == 0
    end

    test "unicode" do
      assert Text.grapheme_count("café") == 4
    end
  end
end
