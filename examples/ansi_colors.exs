# examples/ansi_colors.exs
#
# Test drive ANSI output. Enters raw mode, shows detected color
# capabilities with swatches, and echoes raw input bytes until Ctrl-C.
#
# Run with: mix run examples/ansi_colors.exs

defmodule Example.AnsiColors do
  alias Courgette.ANSI
  alias Courgette.ANSI.ColorMode

  def run do
    :ok = :shell.start_interactive({:noshell, :raw})

    color_mode = ColorMode.detect_from_env()
    {cols, rows} = get_size()

    IO.write([
      ANSI.alternate_screen_enter(),
      ANSI.cursor_hide(),
      ANSI.clear_screen(),
      ANSI.cursor_home()
    ])

    draw_header(cols, rows, color_mode)

    parent = self()
    spawn_link(fn -> input_loop(parent) end)

    try do
      loop(0, {cols, rows}, color_mode, rows)
    after
      IO.write([
        ANSI.cursor_show(),
        ANSI.reset(),
        ANSI.alternate_screen_exit()
      ])
    end
  end

  defp input_loop(parent) do
    case IO.getn("", 1024) do
      :eof ->
        send(parent, :quit)

      data when is_binary(data) ->
        send(parent, {:input, data})
        input_loop(parent)
    end
  end

  defp loop(line_count, last_size, color_mode, rows) do
    current_size = get_size()

    {line_count, last_size, rows} =
      if current_size != last_size do
        {new_cols, new_rows} = current_size
        IO.write([ANSI.clear_screen(), ANSI.cursor_home()])
        draw_header(new_cols, new_rows, color_mode)
        {0, current_size, new_rows}
      else
        {line_count, last_size, rows}
      end

    receive do
      :quit ->
        :ok

      {:input, <<3>>} ->
        :ok

      {:input, data} ->
        input_row = 16
        available = max(rows - input_row - 1, 1)
        row = input_row + rem(line_count, available)

        IO.write(ANSI.cursor_to(row, 3))
        IO.write(ANSI.clear_line_right())

        hex =
          data
          |> :binary.bin_to_list()
          |> Enum.map_join(" ", &("0x" <> String.pad_leading(Integer.to_string(&1, 16), 2, "0")))

        printable = String.replace(data, ~r/[^\x20-\x7E]/, ".")

        IO.write([
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

        loop(line_count + 1, last_size, color_mode, rows)
    after
      100 ->
        loop(line_count, last_size, color_mode, rows)
    end
  end

  defp draw_header(cols, rows, color_mode) do
    title = " Courgette Terminal Sketch "
    pad = max(div(cols - String.length(title), 2), 0)

    IO.write([
      ANSI.bold(),
      ANSI.fg(:bright_cyan),
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
      "  $COLORTERM: ",
      ANSI.fg(:yellow),
      System.get_env("COLORTERM") || "(not set)",
      "\r\n",
      ANSI.fg(:bright_white),
      "  $TERM:      ",
      ANSI.fg(:yellow),
      System.get_env("TERM") || "(not set)",
      "\r\n",
      ANSI.reset(),
      "\r\n"
    ])

    IO.write(["  ", ANSI.bold(), "Basic:    ", ANSI.reset(), " "])

    for color <- [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white] do
      IO.write([ANSI.bg(color), "  ", ANSI.reset()])
    end

    IO.write("\r\n")

    IO.write(["  ", ANSI.bold(), "Bright:   ", ANSI.reset(), " "])

    for color <- [
          :bright_black,
          :bright_red,
          :bright_green,
          :bright_yellow,
          :bright_blue,
          :bright_magenta,
          :bright_cyan,
          :bright_white
        ] do
      IO.write([ANSI.bg(color), "  ", ANSI.reset()])
    end

    IO.write("\r\n")

    if color_mode in [:bit_8, :bit_24] do
      IO.write(["  ", ANSI.bold(), "256:      ", ANSI.reset(), " "])

      for i <- Enum.take_every(0..255, 8) do
        IO.write([ANSI.bg(i), " ", ANSI.reset()])
      end

      IO.write("\r\n")
    end

    if color_mode == :bit_24 do
      IO.write(["  ", ANSI.bold(), "Truecolor:", ANSI.reset(), " "])

      for i <- Enum.take_every(0..255, 4) do
        IO.write([ANSI.bg({i, 50, 255 - i}), " ", ANSI.reset()])
      end

      IO.write("\r\n")
    end

    IO.write([
      "\r\n",
      ANSI.dim(),
      "  Press keys to see raw bytes. Ctrl-C to quit.",
      ANSI.reset(),
      "\r\n"
    ])
  end

  def get_size do
    cols =
      case :io.columns() do
        {:ok, c} -> c
        _ -> tput("cols", 80)
      end

    rows =
      case :io.rows() do
        {:ok, r} -> r
        _ -> tput("lines", 24)
      end

    {cols, rows}
  end

  defp tput(attr, default) do
    case System.cmd("tput", [attr], stderr_to_stdout: true) do
      {output, 0} ->
        case Integer.parse(String.trim(output)) do
          {n, _} -> n
          :error -> default
        end

      _ ->
        default
    end
  end
end

Example.AnsiColors.run()
