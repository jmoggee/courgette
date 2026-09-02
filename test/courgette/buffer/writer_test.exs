defmodule Courgette.Buffer.WriterTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer.Cell
  alias Courgette.Buffer.Diff.Run
  alias Courgette.Buffer.Writer

  defp to_binary(iodata), do: IO.iodata_to_binary(iodata)

  defp count(string, pattern) do
    string |> String.split(pattern) |> length() |> Kernel.-(1)
  end

  describe "empty input" do
    test "empty list returns empty iodata" do
      assert Writer.render([]) == []
    end
  end

  describe "cursor positioning" do
    test "0-based coords map to 1-based ANSI" do
      run = %Run{x: 3, y: 5, cells: [Cell.new("A")]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[6;4H"
    end

    test "origin {0,0} maps to row 1, col 1" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A")]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[1;1H"
    end

    test "multiple runs each get cursor positioning" do
      runs = [
        %Run{x: 0, y: 0, cells: [Cell.new("A")]},
        %Run{x: 5, y: 3, cells: [Cell.new("B")]}
      ]

      result = to_binary(Writer.render(runs))
      assert result =~ "\e[1;1H"
      assert result =~ "\e[4;6H"
    end

    test "consecutive cells in a run share one cursor position" do
      cells = [Cell.new("A"), Cell.new("B"), Cell.new("C")]
      run = %Run{x: 2, y: 1, cells: cells}
      result = to_binary(Writer.render([run]))
      # Only one cursor_to, not three
      assert count(result, "\e[") >= 1
      assert result =~ "\e[2;3H"
      assert result =~ "ABC"
    end
  end

  describe "grapheme output" do
    test "single cell emits its grapheme" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("X")]}
      result = to_binary(Writer.render([run]))
      assert result =~ "X"
    end

    test "multiple cells emit graphemes in order" do
      cells = [Cell.new("H"), Cell.new("i"), Cell.new("!")]
      run = %Run{x: 0, y: 0, cells: cells}
      result = to_binary(Writer.render([run]))
      assert result =~ "Hi!"
    end

    test "unicode graphemes" do
      cells = [Cell.new("日"), Cell.new("本"), Cell.new("語")]
      run = %Run{x: 0, y: 0, cells: cells}
      result = to_binary(Writer.render([run]))
      assert result =~ "日本語"
    end

    test "emoji grapheme" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("🚀")]}
      result = to_binary(Writer.render([run]))
      assert result =~ "🚀"
    end
  end

  describe "initial reset" do
    test "first cell emits reset to establish known state" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A")]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[0m"
    end

    test "unstyled cell produces cursor + reset + grapheme only" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A")]}
      assert to_binary(Writer.render([run])) == "\e[1;1H\e[0mA"
    end
  end

  describe "foreground color" do
    test "named color" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", fg: :red)]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[31m"
    end

    test "256-color" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", fg: 196)]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[38;5;196m"
    end

    test "truecolor RGB" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", fg: {255, 128, 0})]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[38;2;255;128;0m"
    end

    test "change to nil emits default fg" do
      cell1 = Cell.new("A", fg: :red)
      cell2 = Cell.new("B")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[39m"
    end
  end

  describe "background color" do
    test "named color" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", bg: :blue)]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[44m"
    end

    test "256-color" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", bg: 42)]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[48;5;42m"
    end

    test "truecolor RGB" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", bg: {0, 100, 200})]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[48;2;0;100;200m"
    end

    test "change to nil emits default bg" do
      cell1 = Cell.new("A", bg: :green)
      cell2 = Cell.new("B")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[49m"
    end
  end

  describe "style attributes" do
    test "bold" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", bold: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[1m"
    end

    test "dim" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", dim: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[2m"
    end

    test "italic" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", italic: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[3m"
    end

    test "underline" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[4m"
    end

    test "blink" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", blink: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[5m"
    end

    test "reverse" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", reverse: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[7m"
    end

    test "hidden" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", hidden: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[8m"
    end

    test "strikethrough" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", strikethrough: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[9m"
    end

    test "overline" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", overline: true)]}
      assert to_binary(Writer.render([run])) =~ "\e[53m"
    end

    test "underline_style :curly" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_style: :curly)]}
      assert to_binary(Writer.render([run])) =~ "\e[4:3m"
    end

    test "underline_style :double" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_style: :double)]}
      assert to_binary(Writer.render([run])) =~ "\e[4:2m"
    end

    test "underline_style :dotted" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_style: :dotted)]}
      assert to_binary(Writer.render([run])) =~ "\e[4:4m"
    end

    test "underline_style :dashed" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_style: :dashed)]}
      assert to_binary(Writer.render([run])) =~ "\e[4:5m"
    end

    test "underline_color 256" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_color: 160)]}
      assert to_binary(Writer.render([run])) =~ "\e[58;5;160m"
    end

    test "underline_color RGB" do
      run = %Run{x: 0, y: 0, cells: [Cell.new("A", underline_color: {255, 0, 0})]}
      assert to_binary(Writer.render([run])) =~ "\e[58;2;255;0;0m"
    end

    test "multiple styles on one cell" do
      cell = Cell.new("A", fg: :red, bold: true, italic: true)
      run = %Run{x: 0, y: 0, cells: [cell]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[31m"
      assert result =~ "\e[1m"
      assert result =~ "\e[3m"
    end
  end

  describe "style deduplication" do
    test "identical adjacent cells share style codes" do
      cell = Cell.new("A", fg: :red, bold: true)
      run = %Run{x: 0, y: 0, cells: [cell, cell, cell]}
      result = to_binary(Writer.render([run]))
      assert count(result, "\e[1m") == 1
      assert count(result, "A") == 3
    end

    test "identical style tracked across runs" do
      cell = Cell.new("A", fg: :red)

      runs = [
        %Run{x: 0, y: 0, cells: [cell]},
        %Run{x: 5, y: 0, cells: [cell]}
      ]

      result = to_binary(Writer.render(runs))
      # fg(:red) emitted once (first run), not re-emitted for second
      assert count(result, "\e[31m") == 1
    end

    test "only changed attributes emitted" do
      cell1 = Cell.new("A", fg: :red, bold: true)
      cell2 = Cell.new("B", fg: :blue, bold: true)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # bold emitted once (first cell), fg changes from red to blue
      assert count(result, "\e[1m") == 1
      assert result =~ "\e[31m"
      assert result =~ "\e[34m"
    end
  end

  describe "style removal (reset strategy)" do
    test "removing a style attribute triggers reset" do
      cell1 = Cell.new("A", fg: :red, bold: true)
      cell2 = Cell.new("B", fg: :red)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # Two resets: initial + bold removal
      assert count(result, "\e[0m") == 2
    end

    test "after removal reset, remaining attributes are re-emitted" do
      cell1 = Cell.new("A", fg: :red, bold: true, italic: true)
      cell2 = Cell.new("B", fg: :red, italic: true)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # fg(:red) emitted twice (initial + re-emit after removal reset)
      assert count(result, "\e[31m") == 2
      # italic emitted twice (initial + re-emit)
      assert count(result, "\e[3m") == 2
    end

    test "removing all styles leaves just reset" do
      cell1 = Cell.new("A", bold: true, italic: true)
      cell2 = Cell.new("B")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # Second cell: reset + no additional codes + grapheme
      assert count(result, "\e[0m") == 2
    end

    test "fg going to nil after removal uses reset (not separate default)" do
      cell1 = Cell.new("A", fg: :red, bold: true)
      cell2 = Cell.new("B")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # Reset handles clearing fg — no need for separate fg(:default)
      assert count(result, "\e[0m") == 2
      refute result =~ "\e[39m"
    end
  end

  describe "targeted color changes (no removal)" do
    test "fg change emits only new fg" do
      cell1 = Cell.new("A", fg: :red)
      cell2 = Cell.new("B", fg: :blue)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # One reset (initial), then targeted fg change
      assert count(result, "\e[0m") == 1
      assert result =~ "\e[34m"
    end

    test "bg change emits only new bg" do
      cell1 = Cell.new("A", bg: :red)
      cell2 = Cell.new("B", bg: :blue)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      assert count(result, "\e[0m") == 1
      assert result =~ "\e[44m"
    end

    test "adding a style attribute is targeted (no reset)" do
      cell1 = Cell.new("A", fg: :red)
      cell2 = Cell.new("B", fg: :red, bold: true)
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # One reset (initial only), bold added without reset
      assert count(result, "\e[0m") == 1
      assert result =~ "\e[1m"
    end

    test "fg to nil without style removal emits default" do
      cell1 = Cell.new("A", fg: :red)
      cell2 = Cell.new("B")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # No style keys removed (both have empty style maps)
      # fg change: red → nil, emits fg(:default)
      assert count(result, "\e[0m") == 1
      assert result =~ "\e[39m"
    end
  end

  describe "hyperlinks (OSC 8)" do
    test "cell with url emits OSC 8 open sequence" do
      cell = Cell.new("L", fg: :blue, url: "https://example.com", underline: true)
      run = %Run{x: 0, y: 0, cells: [cell]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e]8;;https://example.com\e\\"
    end

    test "transition from url cell to non-url cell emits close sequence" do
      cell1 = Cell.new("L", url: "https://example.com")
      cell2 = Cell.new("X")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # Open for cell1
      assert result =~ "\e]8;;https://example.com\e\\"
      # Close before cell2
      assert result =~ "\e]8;;\e\\"
    end

    test "adjacent cells with same url share one open sequence" do
      cell = Cell.new("A", url: "https://example.com")
      run = %Run{x: 0, y: 0, cells: [cell, cell, cell]}
      result = to_binary(Writer.render([run]))
      assert count(result, "\e]8;;https://example.com\e\\") == 1
      assert result =~ "AAA"
    end

    test "transition between different urls emits close then open" do
      cell1 = Cell.new("A", url: "https://one.com")
      cell2 = Cell.new("B", url: "https://two.com")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e]8;;https://one.com\e\\"
      assert result =~ "\e]8;;https://two.com\e\\"
      # Close sequence between the two
      assert result =~ "\e]8;;\e\\"
    end

    test "url re-emitted after reset" do
      cell1 = Cell.new("A", url: "https://example.com", bold: true)
      cell2 = Cell.new("B", url: "https://example.com")
      run = %Run{x: 0, y: 0, cells: [cell1, cell2]}
      result = to_binary(Writer.render([run]))
      # Bold removed triggers reset, url should be re-emitted
      assert count(result, "\e]8;;https://example.com\e\\") == 2
    end

    test "url tracked across runs" do
      cell = Cell.new("A", url: "https://example.com")

      runs = [
        %Run{x: 0, y: 0, cells: [cell]},
        %Run{x: 5, y: 0, cells: [cell]}
      ]

      result = to_binary(Writer.render(runs))
      # URL emitted once, not re-emitted for second run with same state
      assert count(result, "\e]8;;https://example.com\e\\") == 1
    end
  end

  describe "complex scenarios" do
    test "multiple runs, mixed styles" do
      runs = [
        %Run{x: 0, y: 0, cells: [Cell.new("H", fg: :red), Cell.new("i", fg: :red)]},
        %Run{x: 5, y: 0, cells: [Cell.new("!", fg: :blue, bold: true)]},
        %Run{x: 0, y: 1, cells: [Cell.new("W"), Cell.new("o"), Cell.new("w")]}
      ]

      result = to_binary(Writer.render(runs))
      assert result =~ "\e[1;1H"
      assert result =~ "\e[1;6H"
      assert result =~ "\e[2;1H"
      assert result =~ "Hi"
      assert result =~ "!"
      assert result =~ "Wow"
    end

    test "clearing a region (run of spaces)" do
      cells = [Cell.new(" "), Cell.new(" "), Cell.new(" ")]
      run = %Run{x: 5, y: 3, cells: cells}
      result = to_binary(Writer.render([run]))
      assert result =~ "\e[4;6H"
      assert result =~ "   "
    end

    test "style changes mid-run then back" do
      # plain → bold → plain
      cell_plain = Cell.new("A")
      cell_bold = Cell.new("B", bold: true)
      run = %Run{x: 0, y: 0, cells: [cell_plain, cell_bold, cell_plain]}
      result = to_binary(Writer.render([run]))
      # reset (initial) + bold (second cell) + reset (bold removed for third)
      assert count(result, "\e[0m") == 2
      assert result =~ "\e[1m"
      # Graphemes present (separated by escape codes)
      assert count(result, "A") == 2
      assert count(result, "B") == 1
    end

    test "render returns valid iodata" do
      runs = [
        %Run{x: 0, y: 0, cells: [Cell.new("X", fg: :red, bold: true)]},
        %Run{x: 10, y: 5, cells: [Cell.new("Y", bg: {0, 255, 0})]}
      ]

      # Should not raise — valid iodata
      result = Writer.render(runs)
      assert is_list(result)
      assert IO.iodata_to_binary(result) |> is_binary()
    end
  end
end
