# sketches/09_dsl_components.exs
#
# Phase 4 demo: DSL macros, function components, and theming.
#
# Frame 1: DSL-built element tree rendered through the full pipeline
# Frame 2: Built-in components (badge, heading, key_value, divider, empty_state)
# Frame 3: Same components with a custom theme applied
#
# Run with: mix run sketches/09_dsl_components.exs

defmodule Sketch.DSLComponents do
  use Courgette.Component
  import Courgette.Components

  alias Courgette.ANSI
  alias Courgette.Buffer
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.Painter
  alias Courgette.Terminal
  alias Courgette.Theme

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

    # Frame 1: DSL-built element tree
    tree1 = build_dsl_demo(cols, rows)
    front = flush(front, tree1, cols, rows, cycle_num, 1, "DSL element tree")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 2: Built-in components with default theme
    tree2 = build_components_demo(cols, rows, Theme.default())
    front = flush(front, tree2, cols, rows, cycle_num, 2, "Built-in components (default theme)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 3: Same components with custom theme
    custom_theme = %Theme{
      name: "ocean",
      tokens: %{
        bg: :black, fg: :white,
        primary: :cyan, secondary: :blue,
        success: {0, 200, 100}, warning: {255, 180, 0}, danger: {255, 60, 60},
        muted: {100, 100, 120}, border: :cyan, surface: {20, 30, 50}
      }
    }
    tree3 = build_components_demo(cols, rows, custom_theme)
    front = flush(front, tree3, cols, rows, cycle_num, 3, "Built-in components (ocean theme)")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    cycle(front, cycle_num + 1, cols, rows)
  catch
    :quit -> :ok
  end

  # ── Frame 1: DSL-built tree ────────────────────────────────────────

  defp build_dsl_demo(cols, rows) do
    el =
      box width: cols, height: rows - 2, flex_direction: :column, border: :rounded, border_color: :bright_white do
        # Header
        box height: 3, bg: :blue, align_items: :center, padding_h: 2 do
          text color: :bright_white, bold: true do
            "Courgette DSL Demo"
          end
        end

        # Content area
        box flex: 1, flex_direction: :row do
          # Left panel
          box flex: 1, border: :single, border_color: :cyan, flex_direction: :column, padding: 1 do
            text color: :cyan, bold: true do
              "Left Panel"
            end
            text color: :white do
              "Built with DSL macros"
            end
            text color: :bright_black do
              "box, text, etc."
            end
          end

          # Right panel
          box flex: 2, border: :single, border_color: :green, flex_direction: :column, padding: 1 do
            text color: :green, bold: true do
              "Right Panel"
            end

            for item <- ["No more Element.new/3", "Clean do-block syntax", "Comprehensions work"] do
              text color: :white do
                "• #{item}"
              end
            end
          end
        end
      end

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Frames 2-3: Built-in components ────────────────────────────────

  defp build_components_demo(cols, rows, theme) do
    t = [theme: theme]

    el =
      box width: cols, height: rows - 2, flex_direction: :column, border: :rounded,
          border_color: Theme.get(theme, :border) do
        # Heading
        heading(text: "Component Showcase", theme: theme)

        # Badges row
        box flex_direction: :row, height: 3 do
          badge([{:label, "OK"}, {:color, Theme.get(theme, :success)} | t])
          badge([{:label, "WARN"}, {:color, Theme.get(theme, :warning)} | t])
          badge([{:label, "ERR"}, {:color, Theme.get(theme, :danger)} | t])
        end

        divider(t)

        # Key-value pairs
        box flex_direction: :column, flex: 1, padding_h: 1 do
          key_value([{:label, "Theme"}, {:value, theme.name} | t])
          key_value([{:label, "Primary"}, {:value, inspect(Theme.get(theme, :primary))} | t])
          key_value([{:label, "Components"}, {:value, "5 built-in"} | t])
        end

        divider(t)

        # Empty state
        empty_state([{:message, "More components coming in Phase 4b..."} | t])
      end

    Engine.compute(el, Bounds.new(0, 0, cols, rows - 2))
  end

  # ── Flush ──────────────────────────────────────────────────────────

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

  # ── Input ──────────────────────────────────────────────────────────

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

Sketch.DSLComponents.run()
