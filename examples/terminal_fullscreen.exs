# examples/terminal_fullscreen.exs
#
# Test drive the Courgette.Terminal GenServer in fullscreen mode.
# All I/O goes through the server API — write/1, color_mode/0, size/0.
# Resize events arrive via SIGWINCH — no polling.
#
# Run with: mix run examples/terminal_fullscreen.exs

defmodule Example.TerminalFullscreen do
  alias Courgette.ANSI
  alias Courgette.Terminal

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self())

    mode = Terminal.color_mode()
    {cols, rows} = Terminal.size()

    draw_header(cols, rows, mode)

    try do
      loop(0, rows)
    after
      Terminal.stop()
    end
  end

  defp loop(line_count, rows) do
    receive do
      {:terminal_input, :eof} ->
        :ok

      {:terminal_input, <<3>>} ->
        :ok

      {:terminal_input, data} ->
        input_row = 10
        available = max(rows - input_row - 1, 1)
        row = input_row + rem(line_count, available)

        hex =
          data
          |> :binary.bin_to_list()
          |> Enum.map_join(" ", &("0x" <> String.pad_leading(Integer.to_string(&1, 16), 2, "0")))

        printable = String.replace(data, ~r/[^\x20-\x7E]/, ".")

        Terminal.write([
          ANSI.cursor_to(row, 3),
          ANSI.clear_line_right(),
          ANSI.fg(:bright_white),
          hex,
          ANSI.fg(:dark_gray),
          "  ",
          ANSI.fg(:bright_yellow),
          printable,
          ANSI.fg(:dark_gray),
          "  (#{byte_size(data)} bytes)",
          ANSI.reset()
        ])

        loop(line_count + 1, rows)

      {:terminal_resize, cols, new_rows} ->
        Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()])
        draw_header(cols, new_rows, Terminal.color_mode())
        loop(0, new_rows)
    end
  end

  defp draw_header(cols, rows, color_mode) do
    title = " Terminal Fullscreen Sketch "
    pad = max(div(cols - String.length(title), 2), 0)

    Terminal.write([
      ANSI.bold(),
      ANSI.fg(:bright_green),
      String.duplicate(" ", pad),
      title,
      "\r\n",
      ANSI.reset(),
      "\r\n",
      ANSI.fg(:bright_white),
      "  Color mode: ",
      ANSI.fg(:bright_green),
      inspect(color_mode),
      "\r\n",
      ANSI.fg(:bright_white),
      "  Terminal:   ",
      ANSI.fg(:bright_green),
      "#{cols}x#{rows}",
      "\r\n",
      ANSI.fg(:bright_white),
      "  Server:     ",
      ANSI.fg(:bright_green),
      inspect(Process.whereis(Courgette.Terminal)),
      "\r\n",
      ANSI.reset(),
      "\r\n",
      ANSI.dim(),
      "  Resize events via SIGWINCH. Input via {:terminal_input, bytes}.",
      "\r\n",
      "  Press keys to see raw bytes. Ctrl-C to quit.",
      ANSI.reset(),
      "\r\n"
    ])
  end
end

Example.TerminalFullscreen.run()
