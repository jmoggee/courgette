# examples/scrollable_area.exs
#
# Overflow: scroll viewport with scroll_offset shifting.
# 5 frames: basic scrolling, middle view, bottom view, bordered+colored, dashboard.
#
# Run with: mix run examples/scrollable_area.exs

defmodule Example.ScrollableArea do
  alias Courgette.ANSI
  alias Courgette.Buffer
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.Painter
  alias Courgette.Terminal

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self())
    {cols, rows} = Terminal.size()

    front = Buffer.new(cols, rows)
    cycle(front, 1, cols, rows)

    Terminal.stop()
  end

  defp cycle(front, cycle_num, cols, rows) do
    {new_cols, new_rows} = Terminal.size()

    {front, cols, rows} =
      if {new_cols, new_rows} != {cols, rows} do
        Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()])
        {Buffer.new(new_cols, new_rows), new_cols, new_rows}
      else
        {front, cols, rows}
      end

    viewport_h = rows - 3

    # Frame 1: 15 text lines in a 6-line viewport, offset=0
    tree1 = build_scrollable(cols, viewport_h, 0)
    front = flush(front, tree1, cols, rows, cycle_num, 1, "scroll_offset=0 (top)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 2: Same content, offset=4 (middle)
    tree2 = build_scrollable(cols, viewport_h, 4)
    front = flush(front, tree2, cols, rows, cycle_num, 2, "scroll_offset=4 (middle)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 3: Same content, offset=9 (bottom)
    tree3 = build_scrollable(cols, viewport_h, 9)
    front = flush(front, tree3, cols, rows, cycle_num, 3, "scroll_offset=9 (bottom)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 4: Bordered scrollable with colored content
    tree4 = build_bordered(cols, viewport_h)
    front = flush(front, tree4, cols, rows, cycle_num, 4, "Bordered + colored scroll")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 5: Dashboard with fixed header + scrollable content
    tree5 = build_dashboard(cols, viewport_h)
    front = flush(front, tree5, cols, rows, cycle_num, 5, "Dashboard with scroll panel")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    cycle(front, cycle_num + 1, cols, rows)
  catch
    :quit -> :ok
  end

  # ── Frame 1-3: Simple scrollable with 15 lines ─────────────────

  defp build_scrollable(cols, viewport_h, offset) do
    lines = for i <- 0..14 do
      color = Enum.at([:white, :cyan, :green, :yellow, :magenta], rem(i, 5))
      Element.new(:text, [color: color], ["  Line #{String.pad_leading("#{i}", 2, "0")}: #{String.duplicate("·", cols - 14)}"])
    end

    el = Element.new(:box, [width: cols, height: viewport_h, flex_direction: :column], [
      Element.new(:box, [flex: 1, scroll_offset: offset, overflow: :scroll, flex_direction: :column], lines)
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, viewport_h))
  end

  # ── Frame 4: Bordered + colored ────────────────────────────────

  defp build_bordered(cols, viewport_h) do
    lines = for i <- 0..19 do
      bg = if rem(i, 2) == 0, do: {30, 30, 50}, else: {20, 20, 35}
      color = Enum.at([:bright_white, :bright_cyan, :bright_green, :bright_yellow, :bright_magenta], rem(i, 5))
      Element.new(:text, [color: color, bg: bg], ["  Entry #{String.pad_leading("#{i}", 2, "0")}: This is a log message with details  "])
    end

    el = Element.new(:box, [width: cols, height: viewport_h, flex_direction: :column, bg: {20, 20, 35}], [
      Element.new(:box, [flex: 1, border: :rounded, border_color: :cyan, scroll_offset: 6, overflow: :scroll, flex_direction: :column], lines)
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, viewport_h))
  end

  # ── Frame 5: Dashboard layout ──────────────────────────────────

  defp build_dashboard(cols, viewport_h) do
    header = Element.new(:text, [color: :bright_white, bold: true, height: 1], [
      " Courgette Dashboard — Scrollable Areas"
    ])

    sidebar_items = [
      Element.new(:text, [color: :cyan, bold: true], ["  Navigation"]),
      Element.new(:text, [color: :white], ["  Home"]),
      Element.new(:text, [color: :white], ["  Logs"]),
      Element.new(:text, [color: :white], ["  Settings"]),
      Element.new(:text, [color: :bright_black], ["  Logout"])
    ]

    sidebar = Element.new(:box, [width: min(20, div(cols, 4)), border: :single,
                                  border_color: :bright_black, flex_direction: :column,
                                  align_items: :flex_start], sidebar_items)

    log_lines = for i <- 1..30 do
      ts = "12:#{String.pad_leading("#{rem(i + 14, 60)}", 2, "0")}:#{String.pad_leading("#{rem(i * 7, 60)}", 2, "0")}"
      level = Enum.at(["INFO", "WARN", "DEBUG", "ERROR"], rem(i, 4))
      color = Enum.at([:green, :yellow, :cyan, :red], rem(i, 4))
      Element.new(:text, [color: color], ["  [#{ts}] #{level}: Process #{i} completed task #{i * 3}"])
    end

    scroll_panel = Element.new(:box, [flex: 1, border: :rounded,
                                       border_color: :yellow, scroll_offset: 8,
                                       overflow: :scroll, flex_direction: :column], log_lines)

    el = Element.new(:box, [width: cols, height: viewport_h, flex_direction: :column], [
      header,
      Element.new(:box, [flex: 1], [sidebar, scroll_panel])
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, viewport_h))
  end

  # ── Flush ──────────────────────────────────────────────────────

  defp flush(front, tree, cols, rows, cycle_num, frame, label) do
    back = Buffer.new(cols, rows)
    back = Painter.paint(tree, back)

    runs = Diff.diff(front, back)
    dirty_cells = runs |> Enum.map(fn r -> length(r.cells) end) |> Enum.sum()
    iodata = Writer.render(runs)

    Terminal.write([
      ANSI.sync_begin(),
      iodata,
      ANSI.reset(),
      status_line(cycle_num, frame, label, dirty_cells, length(runs), cols, rows),
      ANSI.sync_end()
    ])

    back
  end

  defp status_line(cycle_num, frame, label, dirty, run_count, cols, rows) do
    total = cols * rows
    pct = Float.round(dirty / total * 100, 1)

    [
      ANSI.cursor_to(rows - 1, 1),
      ANSI.clear_line(),
      ANSI.dim(),
      " Cycle #{cycle_num} Frame #{frame} [#{label}]: #{dirty} dirty cells in #{run_count} runs ",
      "(#{pct}% of #{total} total)",
      ANSI.reset()
    ]
  end

  # ── Input ──────────────────────────────────────────────────────

  defp quit?(prompt, rows) do
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

Example.ScrollableArea.run()
