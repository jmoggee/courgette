defmodule Courgette.Selection do
  @moduledoc """
  A renderer selection expressed in zero-based terminal cell coordinates.

  Selection is pure data. It normalizes forward and reverse drags in screen
  order, extracts plain text from a rendered buffer, and applies reverse-video
  styling without changing the underlying cells.
  """

  alias Courgette.Buffer
  alias Courgette.Buffer.Cell

  @type point :: {non_neg_integer(), non_neg_integer()}
  @type t :: %__MODULE__{anchor: point(), focus: point()}

  defstruct [:anchor, :focus]

  @spec new(point()) :: t()
  @doc "Start a selection at `point`."
  def new(point), do: %__MODULE__{anchor: point, focus: point}

  @spec extend(t(), point()) :: t()
  @doc "Move the selection focus to `point`."
  def extend(%__MODULE__{} = selection, point), do: %{selection | focus: point}

  @spec empty?(t()) :: boolean()
  @doc "Whether the selection has no span."
  def empty?(%__MODULE__{anchor: point, focus: point}), do: true
  def empty?(%__MODULE__{}), do: false

  @spec text(t(), Buffer.t()) :: String.t() | nil
  @doc "Extract selected screen cells as newline-separated plain text."
  def text(%__MODULE__{} = selection, %Buffer{} = buffer) do
    selection
    |> rows(buffer)
    |> Enum.map_join("\n", &row_text(buffer, &1, bounds(selection)))
    |> String.trim_trailing()
    |> present_text()
  end

  @spec highlight(t(), Buffer.t()) :: Buffer.t()
  @doc "Return a buffer with selected cells styled in reverse video."
  def highlight(%__MODULE__{} = selection, %Buffer{} = buffer)
      when selection.anchor == selection.focus,
      do: buffer

  def highlight(%__MODULE__{} = selection, %Buffer{} = buffer) do
    Enum.reduce(cells(selection, buffer), buffer, fn {column, row}, selected ->
      case Buffer.get_cell(selected, column, row) do
        %Cell{} = cell ->
          Buffer.put_cell(selected, column, row, Cell.merge_style(cell, reverse: true))

        nil ->
          selected
      end
    end)
  end

  defp present_text(""), do: nil
  defp present_text(text), do: text

  defp rows(selection, buffer) do
    {{_start_column, start_row}, {_end_column, end_row}} = bounds(selection)
    max(start_row, 0)..min(end_row, buffer.height - 1)
  end

  defp cells(selection, buffer) do
    Enum.flat_map(rows(selection, buffer), fn row ->
      {first, last} = row_columns(row, bounds(selection), buffer.width)
      if first <= last, do: Enum.map(first..last, &{&1, row}), else: []
    end)
  end

  defp row_text(buffer, row, selection_bounds) do
    {first, last} = row_columns(row, selection_bounds, buffer.width)

    first..last
    |> Enum.map_join(&cell_text(buffer, &1, row))
    |> String.trim_trailing()
  end

  defp cell_text(buffer, column, row) do
    case Buffer.get_cell(buffer, column, row) do
      %Cell{grapheme: grapheme} -> grapheme
      nil -> ""
    end
  end

  defp row_columns(row, {{start_column, start_row}, {end_column, end_row}}, width) do
    first = if row == start_row, do: start_column, else: 0
    last = if row == end_row, do: end_column, else: width - 1
    {max(first, 0), min(last, width - 1)}
  end

  defp bounds(%__MODULE__{
         anchor: {anchor_column, anchor_row} = anchor,
         focus: {focus_column, focus_row} = focus
       }) do
    if {anchor_row, anchor_column} <= {focus_row, focus_column},
      do: {anchor, focus},
      else: {focus, anchor}
  end
end
