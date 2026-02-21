# sketches/04_key_parser.exs
#
# Live terminal key parser demo. Shows parsed event tuples for every
# keypress, mouse action, focus change, etc.
#
# Run with: mix run sketches/04_key_parser.exs

defmodule Sketch.KeyParser do
  alias Courgette.ANSI
  alias Courgette.Terminal
  alias Courgette.Terminal.KeyParser

  def run do
    {:ok, _pid} = Terminal.start_link(input_target: self(), mode: :inline)

    Terminal.write([
      "\r\n",
      ANSI.bold(),
      ANSI.fg(:bright_green),
      "  Courgette KeyParser Demo",
      ANSI.reset(),
      "\r\n",
      ANSI.dim(),
      "  Press keys to see parsed events. Ctrl-C to quit.",
      ANSI.reset(),
      "\r\n\r\n"
    ])

    loop(<<>>, 0)
  after
    Terminal.stop()
  end

  defp loop(buffer, count) do
    receive do
      {:terminal_input, :eof} ->
        :ok

      {:terminal_input, bytes} ->
        {events, new_buffer} = KeyParser.parse(bytes, buffer)

        hex =
          bytes
          |> :binary.bin_to_list()
          |> Enum.map_join(" ", &("0x" <> String.pad_leading(Integer.to_string(&1, 16), 2, "0")))

        for event <- events do
          # Check for Ctrl-C to quit
          if event == {:key, {:ctrl, "c"}} do
            Terminal.write([
              "\r\n",
              ANSI.dim(),
              "  Bye!",
              ANSI.reset(),
              "\r\n\r\n"
            ])

            Terminal.stop()
            System.halt(0)
          end

          Terminal.write([
            "  ",
            ANSI.fg(:dark_gray),
            String.pad_leading(Integer.to_string(count), 3),
            "  ",
            ANSI.fg(:bright_white),
            String.pad_trailing(inspect(event), 45),
            ANSI.fg(:dark_gray),
            hex,
            ANSI.reset(),
            "\r\n"
          ])
        end

        if new_buffer != <<>> do
          Terminal.write([
            "  ",
            ANSI.fg(:bright_yellow),
            "    (buffered #{byte_size(new_buffer)} bytes)",
            ANSI.reset(),
            "\r\n"
          ])
        end

        loop(new_buffer, count + length(events))

      {:terminal_resize, cols, rows} ->
        Terminal.write([
          "  ",
          ANSI.fg(:bright_cyan),
          "--- resized to #{cols}x#{rows} ---",
          ANSI.reset(),
          "\r\n"
        ])

        loop(buffer, count)
    end
  end
end

Sketch.KeyParser.run()
