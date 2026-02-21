defmodule Courgette.BufferTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Buffer.Cell

  # ── Construction ──────────────────────────────────────────────────

  describe "new/2" do
    test "creates a buffer with the given dimensions" do
      buf = Buffer.new(80, 24)
      assert buf.width == 80
      assert buf.height == 24
    end

    test "fills all cells with empty cells" do
      buf = Buffer.new(3, 2)
      empty = Cell.empty()

      for y <- 0..1, x <- 0..2 do
        assert buf.cells[{x, y}] == empty
      end
    end

    test "has exactly width * height cells" do
      buf = Buffer.new(10, 5)
      assert map_size(buf.cells) == 50
    end

    test "1x1 buffer works" do
      buf = Buffer.new(1, 1)
      assert map_size(buf.cells) == 1
      assert Cell.empty?(buf.cells[{0, 0}])
    end
  end

  # ── size/1 ────────────────────────────────────────────────────────

  describe "size/1" do
    test "returns {width, height}" do
      assert Buffer.size(Buffer.new(80, 24)) == {80, 24}
      assert Buffer.size(Buffer.new(1, 1)) == {1, 1}
    end
  end

  # ── get_cell / put_cell ──────────────────────────────────────────

  describe "get_cell/3" do
    test "returns the cell at the given position" do
      buf = Buffer.new(5, 5)
      assert Cell.empty?(Buffer.get_cell(buf, 0, 0))
    end

    test "returns nil for out-of-bounds coordinates" do
      buf = Buffer.new(5, 5)

      assert Buffer.get_cell(buf, -1, 0) == nil
      assert Buffer.get_cell(buf, 0, -1) == nil
      assert Buffer.get_cell(buf, 5, 0) == nil
      assert Buffer.get_cell(buf, 0, 5) == nil
      assert Buffer.get_cell(buf, 100, 100) == nil
    end

    test "returns nil for negative coordinates" do
      buf = Buffer.new(5, 5)
      assert Buffer.get_cell(buf, -10, -10) == nil
    end
  end

  describe "put_cell/4" do
    test "writes and reads back a cell" do
      cell = Cell.new("X", fg: :red, bold: true)

      buf =
        Buffer.new(5, 5)
        |> Buffer.put_cell(2, 3, cell)

      assert Buffer.get_cell(buf, 2, 3) == cell
    end

    test "does not affect other cells" do
      cell = Cell.new("X")

      buf =
        Buffer.new(3, 3)
        |> Buffer.put_cell(1, 1, cell)

      assert Buffer.get_cell(buf, 1, 1) == cell
      assert Cell.empty?(Buffer.get_cell(buf, 0, 0))
      assert Cell.empty?(Buffer.get_cell(buf, 2, 2))
    end

    test "overwrites existing cell" do
      first = Cell.new("A")
      second = Cell.new("B")

      buf =
        Buffer.new(5, 5)
        |> Buffer.put_cell(0, 0, first)
        |> Buffer.put_cell(0, 0, second)

      assert Buffer.get_cell(buf, 0, 0) == second
    end

    test "silently ignores out-of-bounds writes" do
      buf = Buffer.new(5, 5)
      cell = Cell.new("X")

      assert Buffer.put_cell(buf, -1, 0, cell) == buf
      assert Buffer.put_cell(buf, 0, -1, cell) == buf
      assert Buffer.put_cell(buf, 5, 0, cell) == buf
      assert Buffer.put_cell(buf, 0, 5, cell) == buf
    end

    test "corner positions are valid" do
      buf = Buffer.new(3, 3)
      cell = Cell.new("X")

      # All four corners
      buf =
        buf
        |> Buffer.put_cell(0, 0, cell)
        |> Buffer.put_cell(2, 0, cell)
        |> Buffer.put_cell(0, 2, cell)
        |> Buffer.put_cell(2, 2, cell)

      assert Buffer.get_cell(buf, 0, 0) == cell
      assert Buffer.get_cell(buf, 2, 0) == cell
      assert Buffer.get_cell(buf, 0, 2) == cell
      assert Buffer.get_cell(buf, 2, 2) == cell
    end
  end

  # ── put_string ───────────────────────────────────────────────────

  describe "put_string/4" do
    test "places each grapheme in consecutive cells" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "hello")

      assert Buffer.get_cell(buf, 0, 0).grapheme == "h"
      assert Buffer.get_cell(buf, 1, 0).grapheme == "e"
      assert Buffer.get_cell(buf, 2, 0).grapheme == "l"
      assert Buffer.get_cell(buf, 3, 0).grapheme == "l"
      assert Buffer.get_cell(buf, 4, 0).grapheme == "o"
    end

    test "does not modify cells beyond the string" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "hi")

      assert Cell.empty?(Buffer.get_cell(buf, 2, 0))
    end

    test "truncates at the right edge" do
      buf =
        Buffer.new(5, 1)
        |> Buffer.put_string(3, 0, "abcdef")

      assert Buffer.get_cell(buf, 3, 0).grapheme == "a"
      assert Buffer.get_cell(buf, 4, 0).grapheme == "b"
      # "cdef" are beyond width=5 and silently clipped
    end

    test "ignores string entirely if y is out of bounds" do
      buf = Buffer.new(10, 5)
      assert Buffer.put_string(buf, 0, -1, "hello") == buf
      assert Buffer.put_string(buf, 0, 5, "hello") == buf
    end

    test "negative x clips the left portion" do
      buf =
        Buffer.new(5, 1)
        |> Buffer.put_string(-2, 0, "abcde")

      # x=-2 and x=-1 are clipped, "c" lands at 0, "d" at 1, "e" at 2
      assert Buffer.get_cell(buf, 0, 0).grapheme == "c"
      assert Buffer.get_cell(buf, 1, 0).grapheme == "d"
      assert Buffer.get_cell(buf, 2, 0).grapheme == "e"
    end

    test "empty string is a no-op" do
      buf = Buffer.new(5, 1)
      assert Buffer.put_string(buf, 0, 0, "") == buf
    end

    test "handles unicode graphemes" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "héllo")

      assert Buffer.get_cell(buf, 0, 0).grapheme == "h"
      assert Buffer.get_cell(buf, 1, 0).grapheme == "é"
      assert Buffer.get_cell(buf, 2, 0).grapheme == "l"
    end
  end

  describe "put_string/5 with options" do
    test "applies fg color to each cell" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "hi", fg: :red)

      assert Buffer.get_cell(buf, 0, 0).fg == :red
      assert Buffer.get_cell(buf, 1, 0).fg == :red
    end

    test "applies bg color to each cell" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "hi", bg: :blue)

      assert Buffer.get_cell(buf, 0, 0).bg == :blue
    end

    test "applies style attributes to each cell" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "hi", bold: true, italic: true)

      cell = Buffer.get_cell(buf, 0, 0)
      assert cell.style == %{bold: true, italic: true}
    end

    test "applies all options together" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(5, 0, "ab", fg: :red, bg: :blue, bold: true)

      cell = Buffer.get_cell(buf, 5, 0)
      assert cell.grapheme == "a"
      assert cell.fg == :red
      assert cell.bg == :blue
      assert cell.style == %{bold: true}
    end
  end

  # ── fill / clear ─────────────────────────────────────────────────

  describe "fill/2" do
    test "replaces every cell with the given cell" do
      cell = Cell.new("#", fg: :green)

      buf =
        Buffer.new(3, 2)
        |> Buffer.fill(cell)

      for y <- 0..1, x <- 0..2 do
        assert Buffer.get_cell(buf, x, y) == cell
      end
    end

    test "preserves buffer dimensions" do
      buf =
        Buffer.new(10, 5)
        |> Buffer.fill(Cell.new("X"))

      assert Buffer.size(buf) == {10, 5}
      assert map_size(buf.cells) == 50
    end
  end

  describe "clear/1" do
    test "resets all cells to empty" do
      buf =
        Buffer.new(3, 3)
        |> Buffer.put_string(0, 0, "abc", fg: :red)
        |> Buffer.put_string(0, 1, "def", fg: :blue)
        |> Buffer.clear()

      for y <- 0..2, x <- 0..2 do
        assert Cell.empty?(Buffer.get_cell(buf, x, y))
      end
    end

    test "preserves dimensions" do
      buf =
        Buffer.new(5, 3)
        |> Buffer.clear()

      assert Buffer.size(buf) == {5, 3}
    end
  end

  # ── Edge cases ───────────────────────────────────────────────────

  describe "edge cases" do
    test "put_string at last valid position" do
      buf =
        Buffer.new(5, 3)
        |> Buffer.put_string(4, 2, "X")

      assert Buffer.get_cell(buf, 4, 2).grapheme == "X"
    end

    test "put_cell at origin" do
      cell = Cell.new("@")

      buf =
        Buffer.new(1, 1)
        |> Buffer.put_cell(0, 0, cell)

      assert Buffer.get_cell(buf, 0, 0) == cell
    end

    test "multiple put_string calls compose" do
      buf =
        Buffer.new(10, 3)
        |> Buffer.put_string(0, 0, "line1")
        |> Buffer.put_string(0, 1, "line2")
        |> Buffer.put_string(0, 2, "line3")

      assert Buffer.get_cell(buf, 0, 0).grapheme == "l"
      assert Buffer.get_cell(buf, 0, 1).grapheme == "l"
      assert Buffer.get_cell(buf, 0, 2).grapheme == "l"
      assert Buffer.get_cell(buf, 4, 0).grapheme == "1"
      assert Buffer.get_cell(buf, 4, 1).grapheme == "2"
      assert Buffer.get_cell(buf, 4, 2).grapheme == "3"
    end

    test "put_string overwrites previous content" do
      buf =
        Buffer.new(10, 1)
        |> Buffer.put_string(0, 0, "aaaaa")
        |> Buffer.put_string(0, 0, "bb")

      assert Buffer.get_cell(buf, 0, 0).grapheme == "b"
      assert Buffer.get_cell(buf, 1, 0).grapheme == "b"
      # Original "a" remains beyond the overwrite
      assert Buffer.get_cell(buf, 2, 0).grapheme == "a"
    end

    test "large buffer creates correct number of cells" do
      buf = Buffer.new(200, 60)
      assert map_size(buf.cells) == 12_000
      assert Buffer.size(buf) == {200, 60}
    end
  end
end
