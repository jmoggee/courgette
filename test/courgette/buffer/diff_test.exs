defmodule Courgette.Buffer.DiffTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Buffer.Cell
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Diff.Run

  describe "dimension validation" do
    test "raises ArgumentError when widths differ" do
      assert_raise ArgumentError, "buffers must have the same dimensions", fn ->
        Diff.diff(Buffer.new(3, 2), Buffer.new(4, 2))
      end
    end

    test "raises ArgumentError when heights differ" do
      assert_raise ArgumentError, "buffers must have the same dimensions", fn ->
        Diff.diff(Buffer.new(3, 2), Buffer.new(3, 3))
      end
    end

    test "raises ArgumentError when both dimensions differ" do
      assert_raise ArgumentError, "buffers must have the same dimensions", fn ->
        Diff.diff(Buffer.new(3, 2), Buffer.new(5, 7))
      end
    end
  end

  describe "identical buffers" do
    test "two empty buffers of same size produce no runs" do
      buf = Buffer.new(5, 3)
      assert Diff.diff(buf, buf) == []
    end

    test "same reference returns no runs" do
      buf = Buffer.new(10, 10)
      assert Diff.diff(buf, buf) == []
    end

    test "two independently constructed identical buffers produce no runs" do
      a = Buffer.new(4, 4) |> Buffer.put_string(0, 0, "test")
      b = Buffer.new(4, 4) |> Buffer.put_string(0, 0, "test")
      assert Diff.diff(a, b) == []
    end

    test "buffers with identical styled cells produce no runs" do
      cell = Cell.new("x", fg: :red, bold: true)
      a = Buffer.new(3, 3) |> Buffer.put_cell(1, 1, cell)
      b = Buffer.new(3, 3) |> Buffer.put_cell(1, 1, cell)
      assert Diff.diff(a, b) == []
    end
  end

  describe "single cell changes" do
    test "one cell changed produces one run with one cell" do
      old = Buffer.new(5, 3)
      new = Buffer.new(5, 3) |> Buffer.put_cell(2, 1, Cell.new("X"))

      assert Diff.diff(old, new) == [
               %Run{x: 2, y: 1, cells: [Cell.new("X")]}
             ]
    end

    test "change at origin {0, 0}" do
      old = Buffer.new(3, 3)
      new = Buffer.new(3, 3) |> Buffer.put_cell(0, 0, Cell.new("A"))

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 0, cells: [Cell.new("A")]}
             ]
    end

    test "change at last cell {width-1, height-1}" do
      old = Buffer.new(4, 3)
      new = Buffer.new(4, 3) |> Buffer.put_cell(3, 2, Cell.new("Z"))

      assert Diff.diff(old, new) == [
               %Run{x: 3, y: 2, cells: [Cell.new("Z")]}
             ]
    end

    test "change at first column" do
      old = Buffer.new(5, 3)
      new = Buffer.new(5, 3) |> Buffer.put_cell(0, 1, Cell.new("L"))

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 1, cells: [Cell.new("L")]}
             ]
    end

    test "change at last column" do
      old = Buffer.new(5, 3)
      new = Buffer.new(5, 3) |> Buffer.put_cell(4, 1, Cell.new("R"))

      assert Diff.diff(old, new) == [
               %Run{x: 4, y: 1, cells: [Cell.new("R")]}
             ]
    end
  end

  describe "adjacent changes (runs)" do
    test "consecutive cells on one row form a single run" do
      old = Buffer.new(10, 1)
      new = Buffer.new(10, 1) |> Buffer.put_string(3, 0, "abc")

      assert Diff.diff(old, new) == [
               %Run{x: 3, y: 0, cells: [Cell.new("a"), Cell.new("b"), Cell.new("c")]}
             ]
    end

    test "entire row changed forms one run" do
      old = Buffer.new(5, 1)
      new = Buffer.new(5, 1) |> Buffer.put_string(0, 0, "hello")

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 0, cells: Enum.map(~w(h e l l o), &Cell.new/1)}
             ]
    end

    test "run starting at column 0" do
      old = Buffer.new(5, 1)
      new = Buffer.new(5, 1) |> Buffer.put_string(0, 0, "ab")

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 0, cells: [Cell.new("a"), Cell.new("b")]}
             ]
    end

    test "run ending at last column" do
      old = Buffer.new(5, 1)
      new = Buffer.new(5, 1) |> Buffer.put_string(3, 0, "xy")

      assert Diff.diff(old, new) == [
               %Run{x: 3, y: 0, cells: [Cell.new("x"), Cell.new("y")]}
             ]
    end
  end

  describe "non-adjacent changes (separate runs)" do
    test "two gaps on same row produce two runs" do
      old = Buffer.new(10, 1)

      new =
        Buffer.new(10, 1)
        |> Buffer.put_cell(1, 0, Cell.new("A"))
        |> Buffer.put_cell(5, 0, Cell.new("B"))

      assert Diff.diff(old, new) == [
               %Run{x: 1, y: 0, cells: [Cell.new("A")]},
               %Run{x: 5, y: 0, cells: [Cell.new("B")]}
             ]
    end

    test "three separate changes on same row" do
      old = Buffer.new(10, 1)

      new =
        Buffer.new(10, 1)
        |> Buffer.put_cell(0, 0, Cell.new("X"))
        |> Buffer.put_cell(4, 0, Cell.new("Y"))
        |> Buffer.put_cell(9, 0, Cell.new("Z"))

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 0, cells: [Cell.new("X")]},
               %Run{x: 4, y: 0, cells: [Cell.new("Y")]},
               %Run{x: 9, y: 0, cells: [Cell.new("Z")]}
             ]
    end

    test "adjacent group then gap then single" do
      old = Buffer.new(10, 1)

      new =
        Buffer.new(10, 1)
        |> Buffer.put_string(2, 0, "ab")
        |> Buffer.put_cell(7, 0, Cell.new("Z"))

      assert Diff.diff(old, new) == [
               %Run{x: 2, y: 0, cells: [Cell.new("a"), Cell.new("b")]},
               %Run{x: 7, y: 0, cells: [Cell.new("Z")]}
             ]
    end
  end

  describe "multiple rows" do
    test "changes on different rows produce separate runs in row order" do
      old = Buffer.new(5, 3)

      new =
        Buffer.new(5, 3)
        |> Buffer.put_cell(2, 0, Cell.new("A"))
        |> Buffer.put_cell(3, 2, Cell.new("B"))

      assert Diff.diff(old, new) == [
               %Run{x: 2, y: 0, cells: [Cell.new("A")]},
               %Run{x: 3, y: 2, cells: [Cell.new("B")]}
             ]
    end

    test "runs are ordered top-to-bottom, left-to-right" do
      old = Buffer.new(10, 3)

      new =
        Buffer.new(10, 3)
        |> Buffer.put_cell(5, 2, Cell.new("C"))
        |> Buffer.put_cell(1, 0, Cell.new("A"))
        |> Buffer.put_cell(3, 1, Cell.new("B"))

      runs = Diff.diff(old, new)
      assert length(runs) == 3
      assert Enum.at(runs, 0).y == 0
      assert Enum.at(runs, 1).y == 1
      assert Enum.at(runs, 2).y == 2
    end

    test "mixed runs across multiple rows" do
      old = Buffer.new(8, 3)

      new =
        Buffer.new(8, 3)
        |> Buffer.put_string(0, 0, "hi")
        |> Buffer.put_cell(5, 0, Cell.new("!"))
        |> Buffer.put_string(2, 2, "xyz")

      runs = Diff.diff(old, new)
      assert length(runs) == 3
      assert Enum.at(runs, 0) == %Run{x: 0, y: 0, cells: [Cell.new("h"), Cell.new("i")]}
      assert Enum.at(runs, 1) == %Run{x: 5, y: 0, cells: [Cell.new("!")]}

      assert Enum.at(runs, 2) == %Run{
               x: 2,
               y: 2,
               cells: [Cell.new("x"), Cell.new("y"), Cell.new("z")]
             }
    end
  end

  describe "every cell different" do
    test "completely different 3x2 buffers" do
      old = Buffer.new(3, 2)
      new = Buffer.new(3, 2) |> Buffer.fill(Cell.new("X"))

      runs = Diff.diff(old, new)
      # One run per row since all cells are adjacent
      assert length(runs) == 2

      assert Enum.at(runs, 0) == %Run{
               x: 0,
               y: 0,
               cells: [Cell.new("X"), Cell.new("X"), Cell.new("X")]
             }

      assert Enum.at(runs, 1) == %Run{
               x: 0,
               y: 1,
               cells: [Cell.new("X"), Cell.new("X"), Cell.new("X")]
             }
    end
  end

  describe "1x1 buffer" do
    test "identical 1x1 buffers" do
      buf = Buffer.new(1, 1)
      assert Diff.diff(buf, buf) == []
    end

    test "different 1x1 buffers" do
      old = Buffer.new(1, 1)
      new = Buffer.new(1, 1) |> Buffer.put_cell(0, 0, Cell.new("X"))

      assert Diff.diff(old, new) == [
               %Run{x: 0, y: 0, cells: [Cell.new("X")]}
             ]
    end
  end

  describe "style-only changes" do
    test "same grapheme but different fg color produces a run" do
      old = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", fg: :red))
      new = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", fg: :blue))

      assert Diff.diff(old, new) == [
               %Run{x: 1, y: 0, cells: [Cell.new("A", fg: :blue)]}
             ]
    end

    test "same grapheme but different bg color produces a run" do
      old = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", bg: :red))
      new = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", bg: :green))

      assert Diff.diff(old, new) == [
               %Run{x: 1, y: 0, cells: [Cell.new("A", bg: :green)]}
             ]
    end

    test "same grapheme and color but different style produces a run" do
      old = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", bold: true))
      new = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", italic: true))

      assert Diff.diff(old, new) == [
               %Run{x: 1, y: 0, cells: [Cell.new("A", italic: true)]}
             ]
    end

    test "adding style to unstyled cell produces a run" do
      old = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A"))
      new = Buffer.new(3, 1) |> Buffer.put_cell(1, 0, Cell.new("A", bold: true))

      assert Diff.diff(old, new) == [
               %Run{x: 1, y: 0, cells: [Cell.new("A", bold: true)]}
             ]
    end
  end

  describe "Run struct" do
    test "has expected fields" do
      run = %Run{x: 3, y: 5, cells: [Cell.new("A")]}
      assert run.x == 3
      assert run.y == 5
      assert run.cells == [Cell.new("A")]
    end

    test "defaults to nil fields" do
      run = %Run{}
      assert run.x == nil
      assert run.y == nil
      assert run.cells == nil
    end
  end

  describe "reverse diff" do
    test "diffing new against old gives runs from old buffer" do
      old = Buffer.new(5, 1) |> Buffer.put_cell(2, 0, Cell.new("A"))
      new = Buffer.new(5, 1) |> Buffer.put_cell(2, 0, Cell.new("B"))

      forward = Diff.diff(old, new)
      reverse = Diff.diff(new, old)

      assert forward == [%Run{x: 2, y: 0, cells: [Cell.new("B")]}]
      assert reverse == [%Run{x: 2, y: 0, cells: [Cell.new("A")]}]
    end
  end
end
