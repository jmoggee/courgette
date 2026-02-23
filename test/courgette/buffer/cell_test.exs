defmodule Courgette.Buffer.CellTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer.Cell

  # -- Construction --

  describe "new/0" do
    test "returns an empty cell with space grapheme" do
      cell = Cell.new()
      assert cell.grapheme == " "
      assert cell.fg == nil
      assert cell.bg == nil
      assert cell.style == %{}
    end
  end

  describe "new/1" do
    test "sets grapheme" do
      assert Cell.new("a").grapheme == "a"
    end

    test "leaves colors and style at defaults" do
      cell = Cell.new("x")
      assert cell.fg == nil
      assert cell.bg == nil
      assert cell.style == %{}
    end

    test "accepts multi-byte UTF-8" do
      assert Cell.new("é").grapheme == "é"
    end

    test "accepts emoji" do
      assert Cell.new("🎉").grapheme == "🎉"
    end

    test "accepts grapheme cluster" do
      # family emoji ZWJ sequence
      family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"
      assert Cell.new(family).grapheme == family
    end
  end

  describe "new/2" do
    test "sets fg color" do
      cell = Cell.new("a", fg: :red)
      assert cell.fg == :red
      assert cell.bg == nil
      assert cell.style == %{}
    end

    test "sets bg color" do
      cell = Cell.new("a", bg: :blue)
      assert cell.fg == nil
      assert cell.bg == :blue
    end

    test "sets both fg and bg" do
      cell = Cell.new("a", fg: :red, bg: :blue)
      assert cell.fg == :red
      assert cell.bg == :blue
    end

    test "256-color integer" do
      cell = Cell.new("a", fg: 196, bg: 0)
      assert cell.fg == 196
      assert cell.bg == 0
    end

    test "RGB tuple" do
      cell = Cell.new("█", fg: {255, 100, 0}, bg: {0, 0, 0})
      assert cell.fg == {255, 100, 0}
      assert cell.bg == {0, 0, 0}
    end

    test "boolean style flags" do
      cell = Cell.new("a", bold: true, italic: true)
      assert cell.style == %{bold: true, italic: true}
      assert cell.fg == nil
    end

    test "parameterized underline_style" do
      cell = Cell.new("a", underline_style: :curly)
      assert cell.style == %{underline_style: :curly}
    end

    test "parameterized underline_color" do
      cell = Cell.new("a", underline_color: {255, 0, 0})
      assert cell.style == %{underline_color: {255, 0, 0}}
    end

    test "mixed colors and styles" do
      cell = Cell.new("x", fg: :red, bg: {0, 0, 0}, bold: true, underline_style: :curly)
      assert cell.grapheme == "x"
      assert cell.fg == :red
      assert cell.bg == {0, 0, 0}
      assert cell.style == %{bold: true, underline_style: :curly}
    end

    test "empty options" do
      cell = Cell.new("a", [])
      assert cell == Cell.new("a")
    end

    test "sets url" do
      cell = Cell.new("x", url: "https://example.com")
      assert cell.url == "https://example.com"
      assert cell.fg == nil
      assert cell.style == %{}
    end

    test "url with colors and styles" do
      cell = Cell.new("x", fg: :blue, url: "https://example.com", underline: true)
      assert cell.url == "https://example.com"
      assert cell.fg == :blue
      assert cell.style == %{underline: true}
    end
  end

  # -- Empty --

  describe "empty/0" do
    test "returns a cell with space and no attributes" do
      cell = Cell.empty()
      assert cell.grapheme == " "
      assert cell.fg == nil
      assert cell.bg == nil
      assert cell.style == %{}
    end

    test "is the same value as new/0" do
      assert Cell.empty() == Cell.new()
    end
  end

  describe "empty?/1" do
    test "true for empty cell" do
      assert Cell.empty?(Cell.empty())
      assert Cell.empty?(Cell.new())
    end

    test "false when grapheme differs" do
      refute Cell.empty?(Cell.new("a"))
    end

    test "false when fg is set" do
      refute Cell.empty?(Cell.new(" ", fg: :red))
    end

    test "false when bg is set" do
      refute Cell.empty?(Cell.new(" ", bg: :blue))
    end

    test "false when style is set" do
      refute Cell.empty?(Cell.new(" ", bold: true))
    end

    test "false when url is set" do
      refute Cell.empty?(Cell.new(" ", url: "https://example.com"))
    end
  end

  # -- Equality --

  describe "equality" do
    test "identical cells are equal" do
      a = Cell.new("a", fg: :red, bold: true)
      b = Cell.new("a", fg: :red, bold: true)
      assert a == b
    end

    test "different graphemes are not equal" do
      refute Cell.new("a") == Cell.new("b")
    end

    test "different fg are not equal" do
      refute Cell.new("a", fg: :red) == Cell.new("a", fg: :blue)
    end

    test "different bg are not equal" do
      refute Cell.new("a", bg: :red) == Cell.new("a", bg: :blue)
    end

    test "different styles are not equal" do
      refute Cell.new("a", bold: true) == Cell.new("a", italic: true)
    end

    test "nil fg != named fg" do
      refute Cell.new("a") == Cell.new("a", fg: :default)
    end
  end

  # -- Style Merging --

  describe "merge_style/2 with map" do
    test "adds styles to empty style map" do
      cell = Cell.new("a") |> Cell.merge_style(%{bold: true})
      assert cell.style == %{bold: true}
    end

    test "merges into existing styles" do
      cell =
        Cell.new("a", bold: true)
        |> Cell.merge_style(%{italic: true})

      assert cell.style == %{bold: true, italic: true}
    end

    test "overrides existing keys" do
      cell =
        Cell.new("a", underline_style: :straight)
        |> Cell.merge_style(%{underline_style: :curly})

      assert cell.style == %{underline_style: :curly}
    end

    test "preserves grapheme and colors" do
      cell =
        Cell.new("x", fg: :red, bg: :blue)
        |> Cell.merge_style(%{bold: true})

      assert cell.grapheme == "x"
      assert cell.fg == :red
      assert cell.bg == :blue
    end
  end

  describe "merge_style/2 with keyword list" do
    test "works like map form" do
      cell = Cell.new("a") |> Cell.merge_style(bold: true, italic: true)
      assert cell.style == %{bold: true, italic: true}
    end

    test "overrides existing keys" do
      cell =
        Cell.new("a", underline_style: :straight)
        |> Cell.merge_style(underline_style: :double)

      assert cell.style == %{underline_style: :double}
    end
  end

  # -- Edge Cases --

  describe "edge cases" do
    test "all style flags at once" do
      cell =
        Cell.new("a",
          bold: true,
          dim: true,
          italic: true,
          underline: true,
          blink: true,
          reverse: true,
          hidden: true,
          strikethrough: true,
          overline: true
        )

      assert map_size(cell.style) == 9
      assert cell.style[:bold] == true
      assert cell.style[:overline] == true
    end

    test "underline_style implies underline without explicit flag" do
      cell = Cell.new("a", underline_style: :curly)
      # underline_style is set, underline key is absent
      assert cell.style[:underline_style] == :curly
      refute Map.has_key?(cell.style, :underline)
    end

    test "struct has correct module" do
      assert %Courgette.Buffer.Cell{} = Cell.new()
    end

    test "merge_style with empty map is a no-op" do
      cell = Cell.new("a", bold: true)
      assert Cell.merge_style(cell, %{}) == cell
    end

    test "merge_style with empty keyword list is a no-op" do
      cell = Cell.new("a", bold: true)
      assert Cell.merge_style(cell, []) == cell
    end
  end
end
