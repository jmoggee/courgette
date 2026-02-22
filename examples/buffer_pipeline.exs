# sketches/05_buffer_pipeline.exs
#
# Full Buffer → Diff → Writer pipeline.
# Renders a box with styled text into a buffer, flushes to the terminal,
# then modifies one word and flushes again — only the changed cells update.
# Displays dirty-cell count for each flush. Cycles continuously.
#
# Run with: mix run sketches/05_buffer_pipeline.exs

defmodule Sketch.BufferPipeline do
  alias Courgette.ANSI
  alias Courgette.Buffer
  alias Courgette.Buffer.Cell
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Terminal

  @box_x 4
  @box_y 2
  @box_w 40
  @box_h 12

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self())
    {cols, rows} = Terminal.size()

    front = Buffer.new(cols, rows)
    cycle(front, 1)

    Terminal.stop()
  end

  defp cycle(front, cycle_num) do
    {cols, rows} = Terminal.size()

    # Re-create front if terminal was resized
    front =
      if {cols, rows} != Buffer.size(front) do
        Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()])
        Buffer.new(cols, rows)
      else
        front
      end

    # Frame 1: draw a box with text
    back = Buffer.new(cols, rows)
           |> draw_box(@box_x, @box_y, @box_w, @box_h)
           |> draw_title(" Buffer Pipeline ", @box_x, @box_y, @box_w)
           |> draw_body()

    front = flush(front, back, cycle_num, 1)
    if quit?("any key = next, q = quit"), do: throw(:quit)

    # Frame 2: change one word
    back2 = Buffer.put_string(back, @box_x + 3, @box_y + 3, "Howdy", fg: :bright_green, bold: true)
    front = flush(front, back2, cycle_num, 2)
    if quit?("any key = next, q = quit"), do: throw(:quit)

    # Frame 3: change colors on another line
    back3 = Buffer.put_string(back2, @box_x + 3, @box_y + 5,
              "pipeline works!", fg: :bright_yellow, bold: true)
    front = flush(front, back3, cycle_num, 3)
    if quit?("any key = next, q = quit"), do: throw(:quit)

    # Frame 4: clear the box content (keep borders)
    back4 = clear_body(back3)
    front = flush(front, back4, cycle_num, 4)
    if quit?("any key = next, q = quit"), do: throw(:quit)

    cycle(front, cycle_num + 1)
  catch
    :quit -> :ok
  end

  # -- Drawing helpers --

  defp draw_box(buf, x, y, w, h) do
    buf = Buffer.put_cell(buf, x, y, Cell.new("┌", fg: :bright_cyan))
    buf = Buffer.put_cell(buf, x + w - 1, y, Cell.new("┐", fg: :bright_cyan))
    buf = Buffer.put_cell(buf, x, y + h - 1, Cell.new("└", fg: :bright_cyan))
    buf = Buffer.put_cell(buf, x + w - 1, y + h - 1, Cell.new("┘", fg: :bright_cyan))

    bar = Cell.new("─", fg: :bright_cyan)
    buf = Enum.reduce((x + 1)..(x + w - 2), buf, fn col, b ->
      b = Buffer.put_cell(b, col, y, bar)
      Buffer.put_cell(b, col, y + h - 1, bar)
    end)

    pipe = Cell.new("│", fg: :bright_cyan)
    Enum.reduce((y + 1)..(y + h - 2), buf, fn row, b ->
      b = Buffer.put_cell(b, x, row, pipe)
      Buffer.put_cell(b, x + w - 1, row, pipe)
    end)
  end

  defp draw_title(buf, title, x, y, w) do
    offset = div(w - String.length(title), 2)
    Buffer.put_string(buf, x + offset, y, title, fg: :bright_white, bold: true)
  end

  defp draw_body(buf) do
    x = @box_x + 3
    y = @box_y

    buf
    |> Buffer.put_string(x, y + 2, "Buffer + Diff + Writer", fg: :bright_white)
    |> Buffer.put_string(x, y + 3, "Hello, world!", fg: :bright_green, bold: true)
    |> Buffer.put_string(x, y + 5, "pipeline works!", fg: :bright_cyan)
    |> Buffer.put_string(x, y + 7, "Style tracking skips", fg: :white)
    |> Buffer.put_string(x, y + 8, "redundant ANSI codes.", fg: :white, dim: true)
  end

  defp clear_body(buf) do
    x = @box_x + 1
    w = @box_w - 2
    blank = String.duplicate(" ", w)

    Enum.reduce((@box_y + 1)..(@box_y + @box_h - 2), buf, fn row, b ->
      Buffer.put_string(b, x, row, blank)
    end)
  end

  # -- Flush: diff, render, write, report --

  defp flush(front, back, cycle_num, frame) do
    runs = Diff.diff(front, back)
    dirty_cells = runs |> Enum.map(fn r -> length(r.cells) end) |> Enum.sum()
    iodata = Writer.render(runs)

    {cols, rows} = Terminal.size()

    Terminal.write([
      ANSI.sync_begin(),
      iodata,
      ANSI.reset(),
      status_line(cycle_num, frame, dirty_cells, length(runs), cols, rows),
      ANSI.sync_end()
    ])

    back
  end

  defp status_line(cycle_num, frame, dirty, run_count, cols, rows) do
    total = cols * rows
    pct = Float.round(dirty / total * 100, 1)

    [
      ANSI.cursor_to(rows - 1, 1),
      ANSI.clear_line(),
      ANSI.dim(),
      " Cycle #{cycle_num} Frame #{frame}: #{dirty} dirty cells in #{run_count} runs ",
      "(#{pct}% of #{total} total)",
      ANSI.reset()
    ]
  end

  # -- Input --

  defp quit?(prompt) do
    {_cols, rows} = Terminal.size()

    Terminal.write([
      ANSI.cursor_to(rows, 1),
      ANSI.clear_line(),
      ANSI.fg(:bright_black),
      " #{prompt}",
      ANSI.reset()
    ])

    receive do
      {:terminal_input, "q"} -> true
      {:terminal_input, "Q"} -> true
      {:terminal_input, <<3>>} -> true
      {:terminal_input, _} -> false
    end
  end
end

Sketch.BufferPipeline.run()
