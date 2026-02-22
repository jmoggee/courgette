# examples/painter.exs
#
# Element → Painter → Buffer → Diff → Writer pipeline.
# Builds a layout tree by hand (no layout engine yet), paints it into
# a buffer, and renders to the terminal. Cycles through different
# layouts to show text, borders, backgrounds, and nesting.
#
# Run with: mix run examples/painter.exs

defmodule Example.Painter do
  alias Courgette.ANSI
  alias Courgette.Buffer
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Element
  alias Courgette.Layout.Bounds
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

    # Frame 1: Simple text elements
    tree1 = build_text_frame(cols, rows)
    front = flush(front, tree1, cols, rows, cycle_num, 1, "Text elements")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 2: Bordered boxes
    tree2 = build_border_frame(cols, rows)
    front = flush(front, tree2, cols, rows, cycle_num, 2, "Bordered boxes")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 3: Nested layout (dashboard-like)
    tree3 = build_dashboard_frame(cols, rows)
    front = flush(front, tree3, cols, rows, cycle_num, 3, "Dashboard layout")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    # Frame 4: Background fills
    tree4 = build_bg_frame(cols, rows)
    front = flush(front, tree4, cols, rows, cycle_num, 4, "Background fills")
    if quit?("any key = next, q = quit", rows), do: throw(:quit)

    cycle(front, cycle_num + 1, cols, rows)
  catch
    :quit -> :ok
  end

  # ── Frame builders ──────────────────────────────────────────────

  defp build_text_frame(cols, rows) do
    %{
      element: Element.new(:box),
      bounds: Bounds.new(0, 0, cols, rows),
      children: [
        text_node("Courgette Painter Pipeline", [color: :bright_white, bold: true], 2, 1),
        text_node("Plain text", [], 4, 3),
        text_node("Green text", [color: :green], 4, 4),
        text_node("Red bold", [color: :red, bold: true], 4, 5),
        text_node("Cyan italic", [color: :cyan, italic: true], 4, 6),
        text_node("Yellow on blue", [color: :yellow, bg: :blue], 4, 7),
        text_node("Dim + strikethrough", [color: :white, dim: true, strikethrough: true], 4, 8)
      ]
    }
  end

  defp build_border_frame(cols, rows) do
    %{
      element: Element.new(:box),
      bounds: Bounds.new(0, 0, cols, rows),
      children: [
        text_node("Border Styles", [color: :bright_white, bold: true], 2, 1),
        box_node(:single, :cyan, 2, 3, 20, 6, [
          text_node("Single border", [color: :white], 4, 5)
        ]),
        box_node(:double, :yellow, 24, 3, 20, 6, [
          text_node("Double border", [color: :white], 26, 5)
        ]),
        box_node(:rounded, :green, 46, 3, 20, 6, [
          text_node("Rounded border", [color: :white], 48, 5)
        ])
      ]
    }
  end

  defp build_dashboard_frame(cols, rows) do
    sidebar_w = min(16, div(cols, 4))
    content_x = sidebar_w + 1
    content_w = cols - sidebar_w - 2

    %{
      element: Element.new(:box),
      bounds: Bounds.new(0, 0, cols, rows),
      children: [
        # Header
        text_node("Dashboard", [color: :bright_white, bold: true], 2, 0),
        # Sidebar
        %{
          element: Element.new(:box, border: :single, border_color: :bright_black),
          bounds: Bounds.new(0, 1, sidebar_w, rows - 3),
          children: [
            text_node("Navigation", [color: :cyan, bold: true], 2, 2),
            text_node("> Overview", [color: :bright_white], 2, 4),
            text_node("  Agents", [color: :white], 2, 5),
            text_node("  Logs", [color: :white], 2, 6),
            text_node("  Settings", [color: :white], 2, 7)
          ]
        },
        # Content
        %{
          element: Element.new(:box, border: :rounded, border_color: :bright_black),
          bounds: Bounds.new(content_x, 1, content_w, rows - 3),
          children: [
            text_node("Overview", [color: :bright_cyan, bold: true], content_x + 2, 2),
            text_node("Agents: 8 running, 2 idle", [color: :green], content_x + 2, 4),
            text_node("Tasks: 42 completed, 3 in progress", [color: :yellow], content_x + 2, 5),
            text_node("Errors: 0", [color: :bright_green], content_x + 2, 6),
            # Nested panel
            %{
              element: Element.new(:box, border: :single, border_color: :blue),
              bounds: Bounds.new(content_x + 1, 8, content_w - 2, 6),
              children: [
                text_node("Recent Activity", [color: :blue, bold: true], content_x + 3, 9),
                text_node("Agent-3 completed file_edit task", [color: :white], content_x + 3, 11),
                text_node("Agent-1 started bash command", [color: :white, dim: true], content_x + 3, 12)
              ]
            }
          ]
        }
      ]
    }
  end

  defp build_bg_frame(cols, rows) do
    %{
      element: Element.new(:box),
      bounds: Bounds.new(0, 0, cols, rows),
      children: [
        text_node("Background Fills", [color: :bright_white, bold: true], 2, 1),
        # Blue bg box
        %{
          element: Element.new(:box, bg: :blue, border: :single, border_color: :bright_blue),
          bounds: Bounds.new(2, 3, 18, 5),
          children: [
            text_node("Blue bg", [color: :bright_white], 4, 5)
          ]
        },
        # Red bg box
        %{
          element: Element.new(:box, bg: :red, border: :rounded, border_color: :bright_red),
          bounds: Bounds.new(22, 3, 18, 5),
          children: [
            text_node("Red bg", [color: :bright_white, bold: true], 24, 5)
          ]
        },
        # Green bg box
        %{
          element: Element.new(:box, bg: :green, border: :double, border_color: :bright_green),
          bounds: Bounds.new(42, 3, 18, 5),
          children: [
            text_node("Green bg", [color: :black, bold: true], 44, 5)
          ]
        }
      ]
    }
  end

  # ── Node builders ───────────────────────────────────────────────

  defp text_node(text, props, x, y) do
    %{
      element: Element.new(:text, props, [text]),
      bounds: Bounds.new(x, y, String.length(text), 1),
      children: []
    }
  end

  defp box_node(border_style, border_color, x, y, w, h, children) do
    %{
      element: Element.new(:box, border: border_style, border_color: border_color),
      bounds: Bounds.new(x, y, w, h),
      children: children
    }
  end

  # ── Flush ───────────────────────────────────────────────────────

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

  # ── Input ───────────────────────────────────────────────────────

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

Example.Painter.run()
