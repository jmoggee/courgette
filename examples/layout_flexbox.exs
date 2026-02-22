# examples/layout_flexbox.exs
#
# Element → Engine.compute → Painter → Buffer → Diff → Writer pipeline.
# Builds element trees with flex properties, computes layout automatically,
# and renders to the terminal. No hand-positioned bounds!
#
# Run with: mix run examples/layout_flexbox.exs

defmodule Example.LayoutFlexbox do
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

    # Frame 1: Equal flex children in a row
    tree1 = build_flex_row(cols, rows)
    front = flush(front, tree1, cols, rows, cycle_num, 1, "Flex row (equal grow)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 2: Column layout with varied sizes
    tree2 = build_flex_column(cols, rows)
    front = flush(front, tree2, cols, rows, cycle_num, 2, "Flex column")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 3: Dashboard layout (header + sidebar + content)
    tree3 = build_dashboard(cols, rows)
    front = flush(front, tree3, cols, rows, cycle_num, 3, "Dashboard layout")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 4: Nested flex with borders
    tree4 = build_nested(cols, rows)
    front = flush(front, tree4, cols, rows, cycle_num, 4, "Nested flex containers")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 5: Justify content showcase
    tree5 = build_justify(cols, rows)
    front = flush(front, tree5, cols, rows, cycle_num, 5, "Justify content modes")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    cycle(front, cycle_num + 1, cols, rows)
  catch
    :quit -> :ok
  end

  # ── Frame 1: Flex row with equal grow ─────────────────────────────

  defp build_flex_row(cols, rows) do
    el = Element.new(:box, [width: cols, height: rows - 2, border: :rounded, border_color: :bright_white], [
      Element.new(:box, [flex: 1, bg: :blue, border: :single, border_color: :bright_blue,
                         align_items: :flex_start], [
        Element.new(:text, [color: :bright_white, bold: true], ["Panel A"])
      ]),
      Element.new(:box, [flex: 1, bg: :red, border: :single, border_color: :bright_red,
                         align_items: :flex_start], [
        Element.new(:text, [color: :bright_white, bold: true], ["Panel B"])
      ]),
      Element.new(:box, [flex: 1, bg: :green, border: :single, border_color: :bright_green,
                         align_items: :flex_start], [
        Element.new(:text, [color: :black, bold: true], ["Panel C"])
      ])
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Frame 2: Column layout ───────────────────────────────────────

  defp build_flex_column(cols, rows) do
    el = Element.new(:box, [width: cols, height: rows - 2, flex_direction: :column,
                            border: :single, border_color: :cyan], [
      Element.new(:box, [height: 3, bg: :blue, align_items: :center, justify_content: :center], [
        Element.new(:text, [color: :bright_white, bold: true], ["Header"])
      ]),
      Element.new(:box, [flex: 3, bg: :black, padding: 1, align_items: :flex_start,
                         flex_direction: :column], [
        Element.new(:text, [color: :green], ["Content area"]),
        Element.new(:text, [color: :white], ["flex: 3 — takes most of the space"]),
        Element.new(:text, [color: :bright_black], ["Grows to fill available height"])
      ]),
      Element.new(:box, [height: 3, bg: {40, 40, 40}, align_items: :center,
                         justify_content: :center], [
        Element.new(:text, [color: :bright_black], ["Footer — fixed height"])
      ])
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Frame 3: Dashboard ───────────────────────────────────────────

  defp build_dashboard(cols, rows) do
    sidebar_width = min(20, div(cols, 4))

    sidebar = Element.new(:box, [width: sidebar_width, border: :single, border_color: :cyan,
                                  flex_direction: :column, align_items: :flex_start,
                                  padding: 1], [
      Element.new(:text, [color: :cyan, bold: true], ["Navigation"]),
      Element.new(:text, [color: :white], ["Home"]),
      Element.new(:text, [color: :white], ["Settings"]),
      Element.new(:text, [color: :white], ["Profile"]),
      Element.new(:text, [color: :bright_black], ["Logout"])
    ])

    content = Element.new(:box, [flex: 1, border: :rounded, border_color: :yellow,
                                  flex_direction: :column, padding: 1, align_items: :flex_start], [
      Element.new(:text, [color: :yellow, bold: true], ["Dashboard"]),
      Element.new(:text, [], [""]),
      Element.new(:text, [color: :white], ["Welcome to the Courgette TUI framework."]),
      Element.new(:text, [color: :white], ["This layout is computed by the flexbox engine."]),
      Element.new(:text, [], [""]),
      Element.new(:box, [border: :single, border_color: :green, padding_h: 2, align_items: :flex_start,
                          flex_direction: :column], [
        Element.new(:text, [color: :green, bold: true], ["Activity"]),
        Element.new(:text, [color: :white], ["Last login: just now"]),
        Element.new(:text, [color: :white], ["Status: online"])
      ])
    ])

    header = Element.new(:text, [color: :bright_white, bold: true, height: 1], [
      "Courgette Dashboard — Flexbox Layout"
    ])

    el = Element.new(:box, [width: cols, height: rows - 2, flex_direction: :column], [
      header,
      Element.new(:box, [flex: 1], [sidebar, content])
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Frame 4: Nested flex ─────────────────────────────────────────

  defp build_nested(cols, rows) do
    el = Element.new(:box, [width: cols, height: rows - 2, gap: 1,
                            border: :double, border_color: :bright_white], [
      Element.new(:box, [flex: 1, border: :single, border_color: :magenta,
                         flex_direction: :column, gap: 1, padding: 1], [
        Element.new(:box, [flex: 1, bg: :magenta, align_items: :center, justify_content: :center], [
          Element.new(:text, [color: :bright_white], ["A1"])
        ]),
        Element.new(:box, [flex: 1, bg: {100, 0, 100}, align_items: :center,
                           justify_content: :center], [
          Element.new(:text, [color: :bright_white], ["A2"])
        ])
      ]),
      Element.new(:box, [flex: 2, border: :rounded, border_color: :cyan,
                         flex_direction: :column, gap: 1, padding: 1], [
        Element.new(:box, [flex: 1, bg: :cyan, align_items: :center, justify_content: :center], [
          Element.new(:text, [color: :black, bold: true], ["B1 (flex: 2 outer)"])
        ]),
        Element.new(:box, [flex: 2, bg: {0, 100, 100}, align_items: :center,
                           justify_content: :center], [
          Element.new(:text, [color: :bright_white], ["B2"])
        ])
      ]),
      Element.new(:box, [flex: 1, border: :single, border_color: :yellow,
                         flex_direction: :column, padding: 1, align_items: :flex_start], [
        Element.new(:text, [color: :yellow, bold: true], ["C"]),
        Element.new(:text, [color: :white], ["Fixed"]),
        Element.new(:text, [color: :white], ["panel"])
      ])
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Frame 5: Justify content showcase ────────────────────────────

  defp build_justify(cols, rows) do
    box_w = 6
    box_h = 3

    modes = [:flex_start, :flex_end, :center, :space_between, :space_around, :space_evenly]

    children = Enum.map(modes, fn mode ->
      label = mode |> Atom.to_string() |> String.replace("_", " ")

      Element.new(:box, [height: box_h + 2, flex_direction: :column, align_items: :flex_start], [
        Element.new(:text, [color: :bright_black], ["  #{label}"]),
        Element.new(:box, [height: box_h, justify_content: mode, align_items: :center,
                           border: :single, border_color: :bright_black], [
          Element.new(:box, [width: box_w, bg: :blue, align_items: :center,
                             justify_content: :center], [
            Element.new(:text, [color: :bright_white], ["1"])
          ]),
          Element.new(:box, [width: box_w, bg: :red, align_items: :center,
                             justify_content: :center], [
            Element.new(:text, [color: :bright_white], ["2"])
          ]),
          Element.new(:box, [width: box_w, bg: :green, align_items: :center,
                             justify_content: :center], [
            Element.new(:text, [color: :black], ["3"])
          ])
        ])
      ])
    end)

    el = Element.new(:box, [width: cols, height: rows - 2, flex_direction: :column,
                            padding: 1, align_items: :flex_start], [
      Element.new(:text, [color: :bright_white, bold: true], ["justify_content modes"]),
      Element.new(:text, [], [""]) |
      children
    ])

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Flush ────────────────────────────────────────────────────────

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

  # ── Input ────────────────────────────────────────────────────────

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

Example.LayoutFlexbox.run()
