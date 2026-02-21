defmodule Courgette.Buffer do
  @moduledoc """
  A 2D grid of cells — the surface that everything renders into.

  Buffer is a dense, flat map from `{col, row}` coordinates to `Cell` structs.
  Every position from `{0, 0}` to `{width - 1, height - 1}` is pre-filled with
  `Cell.empty()` on creation. Out-of-bounds writes are silently clipped;
  out-of-bounds reads return `nil`.

  Coordinates are 0-based: `x` is column (0 = left), `y` is row (0 = top).
  """

  alias Courgette.Buffer.Cell

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          cells: %{{non_neg_integer(), non_neg_integer()} => Cell.t()}
        }

  defstruct width: 0, height: 0, cells: %{}

  @doc """
  Creates a new buffer of the given dimensions, filled with empty cells.
  """
  @spec new(pos_integer(), pos_integer()) :: t()
  def new(width, height) when is_integer(width) and width > 0 and is_integer(height) and height > 0 do
    cells =
      for y <- 0..(height - 1), x <- 0..(width - 1), into: %{} do
        {{x, y}, Cell.empty()}
      end

    %__MODULE__{width: width, height: height, cells: cells}
  end

  @doc """
  Returns the cell at `{x, y}`, or `nil` if out of bounds.
  """
  @spec get_cell(t(), integer(), integer()) :: Cell.t() | nil
  def get_cell(%__MODULE__{cells: cells}, x, y) do
    Map.get(cells, {x, y})
  end

  @doc """
  Writes `cell` at `{x, y}`. Returns the buffer unchanged if out of bounds.
  """
  @spec put_cell(t(), integer(), integer(), Cell.t()) :: t()
  def put_cell(%__MODULE__{} = buf, x, y, %Cell{} = cell) do
    if in_bounds?(buf, x, y) do
      %{buf | cells: Map.put(buf.cells, {x, y}, cell)}
    else
      buf
    end
  end

  @doc """
  Writes a string starting at `{x, y}`, one grapheme per cell.

  Graphemes beyond the right edge are truncated. No line wrapping.
  Optional keyword list sets colors and styles (same format as `Cell.new/2`).
  """
  @spec put_string(t(), integer(), integer(), String.t(), keyword()) :: t()
  def put_string(buf, x, y, string, opts \\ [])

  def put_string(%__MODULE__{} = buf, _x, y, _string, _opts)
      when y < 0 or y >= buf.height do
    buf
  end

  def put_string(%__MODULE__{} = buf, x, y, string, opts) do
    string
    |> String.graphemes()
    |> Enum.with_index(x)
    |> Enum.reduce(buf, fn {grapheme, col}, acc ->
      put_cell(acc, col, y, Cell.new(grapheme, opts))
    end)
  end

  @doc """
  Replaces every cell in the buffer with `cell`.
  """
  @spec fill(t(), Cell.t()) :: t()
  def fill(%__MODULE__{} = buf, %Cell{} = cell) do
    cells =
      for y <- 0..(buf.height - 1), x <- 0..(buf.width - 1), into: %{} do
        {{x, y}, cell}
      end

    %{buf | cells: cells}
  end

  @doc """
  Resets every cell to `Cell.empty()`.
  """
  @spec clear(t()) :: t()
  def clear(%__MODULE__{} = buf) do
    fill(buf, Cell.empty())
  end

  @doc """
  Returns `{width, height}`.
  """
  @spec size(t()) :: {pos_integer(), pos_integer()}
  def size(%__MODULE__{width: width, height: height}), do: {width, height}

  defp in_bounds?(%__MODULE__{width: w, height: h}, x, y) do
    x >= 0 and x < w and y >= 0 and y < h
  end
end
