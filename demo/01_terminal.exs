# demo/01_terminal.exs
#
# End-to-end Phase 1 demo: Terminal + KeyParser working together.
# Enters raw mode, shows detected color mode and terminal size,
# displays every keypress as a parsed event tuple, updates on resize.
#
# Run with: mix run demo/01_terminal.exs

defmodule Demo.Terminal do
  alias Courgette.ANSI
  alias Courgette.Terminal
  alias Courgette.Terminal.KeyParser

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self(), mode: :fullscreen)

    color_mode = Terminal.color_mode()
    {cols, rows} = Terminal.size()

    draw_header(color_mode, cols, rows)
    draw_footer(cols, rows)

    loop(<<>>, 0, cols, rows)
  after
    Terminal.stop()
  end

  defp draw_header(color_mode, cols, rows) do
    Terminal.write([
      ANSI.cursor_to(1, 1),
      ANSI.bg(:bright_black),
      ANSI.fg(:bright_white),
      ANSI.bold(),
      " Courgette Phase 1 ",
      ANSI.reset(),
      ANSI.fg(:dark_gray),
      "  color=",
      ANSI.fg(:bright_green),
      inspect(color_mode),
      ANSI.fg(:dark_gray),
      "  size=",
      ANSI.fg(:bright_green),
      "#{cols}x#{rows}",
      ANSI.reset(),
      String.duplicate(" ", max(0, cols - 60)),
      "\r\n"
    ])
  end

  defp draw_footer(cols, rows) do
    footer = " Ctrl-C to quit "
    padding = max(0, cols - String.length(footer))

    Terminal.write([
      ANSI.cursor_to(rows, 1),
      ANSI.bg(:bright_black),
      ANSI.fg(:dark_gray),
      footer,
      String.duplicate(" ", padding),
      ANSI.reset()
    ])

    # Position cursor for event output
    Terminal.write(ANSI.cursor_to(3, 1))
  end

  defp loop(buffer, count, cols, rows) do
    receive do
      {:terminal_input, :eof} ->
        :ok

      {:terminal_input, bytes} ->
        {events, new_buffer} = KeyParser.parse(bytes, buffer)

        for event <- events do
          if event == {:key, {:ctrl, "c"}} do
            throw(:quit)
          end

          hex =
            bytes
            |> :binary.bin_to_list()
            |> Enum.map_join(" ", &("0x" <> String.pad_leading(Integer.to_string(&1, 16), 2, "0")))

          line_y = rem(count, max(1, rows - 4)) + 3

          Terminal.write([
            ANSI.cursor_to(line_y, 1),
            ANSI.clear_line(),
            "  ",
            ANSI.fg(:dark_gray),
            String.pad_leading(Integer.to_string(count), 4),
            "  ",
            ANSI.fg(:bright_white),
            String.pad_trailing(inspect(event), 45),
            ANSI.fg(:dark_gray),
            hex,
            ANSI.reset()
          ])

          count = count + 1
          # Wrap cursor within event area
          next_y = rem(count, max(1, rows - 4)) + 3

          if next_y == 3 do
            # Clear the event area when wrapping
            for y <- 3..(rows - 2) do
              Terminal.write([ANSI.cursor_to(y, 1), ANSI.clear_line()])
            end
          end

          loop(new_buffer, count, cols, rows)
        end

        loop(new_buffer, count, cols, rows)

      {:terminal_resize, new_cols, new_rows} ->
        Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()])
        color_mode = Terminal.color_mode()
        draw_header(color_mode, new_cols, new_rows)
        draw_footer(new_cols, new_rows)
        loop(buffer, 0, new_cols, new_rows)
    end
  catch
    :quit -> :ok
  end
end

Demo.Terminal.run()
