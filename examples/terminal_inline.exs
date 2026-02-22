# examples/terminal_inline.exs
#
# Test drive the Terminal GenServer in inline mode. Output renders at
# the cursor position and stays in terminal scrollback after exit.
#
# Run with: mix run examples/terminal_inline.exs

defmodule Example.TerminalInline do
  alias Courgette.ANSI
  alias Courgette.Terminal

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self(), mode: :inline)

    mode = Terminal.color_mode()
    {cols, _rows} = Terminal.size()

    Terminal.write([
      "\r\n",
      ANSI.bold(),
      ANSI.fg(:bright_green),
      "  Courgette Inline Mode",
      ANSI.reset(),
      "\r\n",
      ANSI.dim(),
      "  Output stays in scrollback after exit.",
      ANSI.reset(),
      "\r\n\r\n",
      ANSI.fg(:bright_white),
      "  Color mode: ",
      ANSI.fg(:bright_green),
      inspect(mode),
      ANSI.reset(),
      "\r\n",
      ANSI.fg(:bright_white),
      "  Terminal:   ",
      ANSI.fg(:bright_green),
      "#{cols} cols",
      ANSI.reset(),
      "\r\n\r\n"
    ])

    # Color swatches
    Terminal.write(["  ", ANSI.bold(), "Basic:    ", ANSI.reset(), " "])

    for color <- [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white] do
      Terminal.write([ANSI.bg(color), "  ", ANSI.reset()])
    end

    Terminal.write("\r\n")

    Terminal.write(["  ", ANSI.bold(), "Bright:   ", ANSI.reset(), " "])

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
      Terminal.write([ANSI.bg(color), "  ", ANSI.reset()])
    end

    Terminal.write("\r\n")

    if mode in [:bit_8, :bit_24] do
      Terminal.write(["  ", ANSI.bold(), "256:      ", ANSI.reset(), " "])

      for i <- Enum.take_every(0..255, 8) do
        Terminal.write([ANSI.bg(i), " ", ANSI.reset()])
      end

      Terminal.write("\r\n")
    end

    if mode == :bit_24 do
      Terminal.write(["  ", ANSI.bold(), "Truecolor:", ANSI.reset(), " "])

      for i <- Enum.take_every(0..255, 4) do
        Terminal.write([ANSI.bg({i, 50, 255 - i}), " ", ANSI.reset()])
      end

      Terminal.write("\r\n")
    end

    Terminal.write([
      "\r\n",
      ANSI.dim(),
      "  Type to see bytes. Ctrl-C to quit.",
      ANSI.reset(),
      "\r\n\r\n"
    ])

    loop(0)
  after
    Terminal.stop()
  end

  defp loop(count) do
    receive do
      {:terminal_input, :eof} ->
        :ok

      {:terminal_input, <<3>>} ->
        :ok

      {:terminal_input, data} ->
        hex =
          data
          |> :binary.bin_to_list()
          |> Enum.map_join(" ", &("0x" <> String.pad_leading(Integer.to_string(&1, 16), 2, "0")))

        printable = String.replace(data, ~r/[^\x20-\x7E]/, ".")

        Terminal.write([
          "  ",
          ANSI.fg(:dark_gray),
          "#{String.pad_leading(Integer.to_string(count), 3)}  ",
          ANSI.fg(:bright_white),
          hex,
          ANSI.fg(:dark_gray),
          "  ",
          ANSI.fg(:bright_yellow),
          printable,
          ANSI.fg(:dark_gray),
          "  (#{byte_size(data)})",
          ANSI.reset(),
          "\r\n"
        ])

        loop(count + 1)

      {:terminal_resize, cols, _rows} ->
        Terminal.write([
          "  ",
          ANSI.fg(:bright_cyan),
          "--- resized to #{cols} cols ---",
          ANSI.reset(),
          "\r\n"
        ])

        loop(count)
    end
  end
end

Example.TerminalInline.run()
