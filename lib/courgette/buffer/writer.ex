defmodule Courgette.Buffer.Writer do
  @moduledoc """
  Converts diff runs into ANSI escape sequences.

  Final step in the rendering pipeline: takes the list of `Diff.Run`
  structs from `Diff.diff/2` and produces an iolist that, when written
  to the terminal, updates only the changed cells.

  Optimizes output by tracking style state across cells and skipping
  redundant color/attribute sequences. When a style attribute is removed
  between cells, Writer emits a reset followed by the new cell's active
  attributes. When attributes are only added or changed, it emits
  targeted SGR codes.
  """

  alias Courgette.ANSI
  alias Courgette.Buffer.Cell
  alias Courgette.Buffer.Diff.Run

  @doc """
  Renders diff runs as an iolist of ANSI escape sequences.

  Each run produces a cursor movement to its starting position,
  followed by style codes and graphemes for its cells. Adjacent
  cells with identical styling share codes — no redundant emission.

  Returns `[]` for an empty run list.
  """
  @spec render([Run.t()]) :: iodata()
  def render([]), do: []

  def render(runs) when is_list(runs) do
    {parts, _state} = Enum.map_reduce(runs, nil, &render_run/2)
    parts
  end

  defp render_run(%Run{x: x, y: y, cells: cells}, state) do
    cursor = ANSI.cursor_to(y + 1, x + 1)
    {cell_parts, new_state} = Enum.map_reduce(cells, state, &render_cell/2)
    {[cursor | cell_parts], new_state}
  end

  defp render_cell(%Cell{} = cell, state) do
    new_state = {cell.fg, cell.bg, cell.style}
    codes = style_diff(state, new_state)
    {[codes, cell.grapheme], new_state}
  end

  # First cell — unknown terminal state, reset to establish baseline
  defp style_diff(nil, new_state) do
    [ANSI.reset() | emit_from_reset(new_state)]
  end

  # Same state — nothing to emit
  defp style_diff(state, state), do: []

  # Different state
  defp style_diff({prev_fg, prev_bg, prev_style}, {new_fg, new_bg, new_style} = new_state) do
    removed_keys = Map.keys(prev_style) -- Map.keys(new_style)

    if removed_keys != [] do
      # Style attributes were removed — reset and re-emit all active attrs
      [ANSI.reset() | emit_from_reset(new_state)]
    else
      # No removals — emit only targeted changes
      emit_changes(prev_fg, prev_bg, prev_style, new_fg, new_bg, new_style)
    end
  end

  # After a reset, emit only non-default attributes
  defp emit_from_reset({fg, bg, style}) do
    io = []
    io = if fg != nil, do: [ANSI.fg(fg) | io], else: io
    io = if bg != nil, do: [ANSI.bg(bg) | io], else: io

    Enum.reduce(style, io, fn {key, val}, acc ->
      [emit_style_attr(key, val) | acc]
    end)
  end

  # Emit only changed attributes (no removals — only additions/modifications)
  defp emit_changes(prev_fg, prev_bg, prev_style, new_fg, new_bg, new_style) do
    io = []
    io = if new_fg != prev_fg, do: [emit_color_change(:fg, new_fg) | io], else: io
    io = if new_bg != prev_bg, do: [emit_color_change(:bg, new_bg) | io], else: io

    Enum.reduce(new_style, io, fn {key, val}, acc ->
      if Map.get(prev_style, key) != val do
        [emit_style_attr(key, val) | acc]
      else
        acc
      end
    end)
  end

  defp emit_color_change(:fg, nil), do: ANSI.fg(:default)
  defp emit_color_change(:fg, color), do: ANSI.fg(color)
  defp emit_color_change(:bg, nil), do: ANSI.bg(:default)
  defp emit_color_change(:bg, color), do: ANSI.bg(color)

  # Boolean style attributes
  defp emit_style_attr(:bold, true), do: ANSI.bold()
  defp emit_style_attr(:dim, true), do: ANSI.dim()
  defp emit_style_attr(:italic, true), do: ANSI.italic()
  defp emit_style_attr(:underline, true), do: ANSI.underline()
  defp emit_style_attr(:blink, true), do: ANSI.blink()
  defp emit_style_attr(:reverse, true), do: ANSI.reverse()
  defp emit_style_attr(:hidden, true), do: ANSI.hidden()
  defp emit_style_attr(:strikethrough, true), do: ANSI.strikethrough()
  defp emit_style_attr(:overline, true), do: ANSI.overline()

  # Parameterized style attributes
  defp emit_style_attr(:underline_style, style), do: ANSI.underline_style(style)
  defp emit_style_attr(:underline_color, color), do: ANSI.underline_color(color)
end
