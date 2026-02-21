defmodule Courgette.Buffer.Diff do
  @moduledoc """
  Compares two buffers and produces a list of change runs.

  Sits between `Buffer` and `Writer` in the rendering pipeline. Given a
  front buffer (what's on screen) and a back buffer (what we want), `diff/2`
  returns a list of `Run` structs representing consecutive changed cells on
  each row. Writer consumes these to emit minimal ANSI sequences.

  Runs are ordered top-to-bottom, left-to-right (row-major).
  """

  alias Courgette.Buffer
  alias Courgette.Buffer.Cell

  defmodule Run do
    @moduledoc """
    A group of adjacent changed cells on a single row.
    """

    @type t :: %__MODULE__{
            x: non_neg_integer(),
            y: non_neg_integer(),
            cells: [Cell.t()]
          }

    defstruct [:x, :y, :cells]
  end

  @doc """
  Diffs two same-sized buffers, returning runs of changed cells from `new`.

  Raises `ArgumentError` if the buffers have different dimensions.
  Returns `[]` when the buffers are identical.
  """
  @spec diff(Buffer.t(), Buffer.t()) :: [Run.t()]
  def diff(%Buffer{width: w, height: h} = old, %Buffer{width: w, height: h} = new) do
    old_cells = old.cells
    new_cells = new.cells

    for y <- 0..(h - 1), reduce: [] do
      runs -> scan_row(old_cells, new_cells, w, y, runs)
    end
    |> :lists.reverse()
  end

  def diff(%Buffer{}, %Buffer{}) do
    raise ArgumentError, "buffers must have the same dimensions"
  end

  defp scan_row(old_cells, new_cells, width, y, runs) do
    scan_row(old_cells, new_cells, width, y, 0, nil, runs)
  end

  # End of row — flush any open run
  defp scan_row(_old, _new, width, _y, x, acc, runs) when x >= width do
    flush(acc, runs)
  end

  # Cells differ — accumulate
  defp scan_row(old, new, width, y, x, acc, runs) do
    old_cell = Map.fetch!(old, {x, y})
    new_cell = Map.fetch!(new, {x, y})

    if old_cell == new_cell do
      # Match — flush any open run, continue
      scan_row(old, new, width, y, x + 1, nil, flush(acc, runs))
    else
      # Difference — start or extend a run
      acc =
        case acc do
          nil -> {x, y, [new_cell]}
          {start_x, ^y, cells} -> {start_x, y, [new_cell | cells]}
        end

      scan_row(old, new, width, y, x + 1, acc, runs)
    end
  end

  defp flush(nil, runs), do: runs

  defp flush({x, y, cells}, runs) do
    [%Run{x: x, y: y, cells: :lists.reverse(cells)} | runs]
  end
end
