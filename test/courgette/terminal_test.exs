defmodule Courgette.TerminalTest do
  use ExUnit.Case

  alias Courgette.Terminal

  # We use a StringIO device to capture output instead of writing to the real terminal.
  # skip_raw_mode: true avoids calling :shell.start_interactive (which fails in mix test).

  defp start_terminal(opts \\ []) do
    {:ok, device} = StringIO.open("")

    defaults = [
      skip_raw_mode: true,
      device: device,
      name: :"terminal_#{:erlang.unique_integer([:positive])}"
    ]

    merged = Keyword.merge(defaults, opts)
    {:ok, pid} = Terminal.start_link(merged)
    {pid, device, merged[:name]}
  end

  defp get_output(device) do
    {_input, output} = StringIO.contents(device)
    output
  end

  describe "start_link/1 and stop/1" do
    test "starts and stops cleanly" do
      {_pid, _device, name} = start_terminal()
      assert Process.whereis(name) != nil
      Terminal.stop(name)
      Process.sleep(10)
      assert Process.whereis(name) == nil
    end
  end

  describe "screen_mode/1" do
    test "defaults to fullscreen" do
      {_pid, _device, name} = start_terminal()
      assert Terminal.screen_mode(name) == :fullscreen
      Terminal.stop(name)
    end

    test "can be set to inline" do
      {_pid, _device, name} = start_terminal(mode: :inline)
      assert Terminal.screen_mode(name) == :inline
      Terminal.stop(name)
    end
  end

  describe "write/2" do
    test "writes iodata to device" do
      {_pid, device, name} = start_terminal()

      Terminal.write("hello", name)
      Terminal.write([" ", "world"], name)

      assert get_output(device) =~ "hello world"

      Terminal.stop(name)
    end

    test "writes ANSI sequences" do
      {_pid, device, name} = start_terminal()

      Terminal.write(Courgette.ANSI.fg(:red), name)
      Terminal.write("red text", name)
      Terminal.write(Courgette.ANSI.reset(), name)

      output = get_output(device)
      assert output =~ "\e[31m"
      assert output =~ "red text"
      assert output =~ "\e[0m"

      Terminal.stop(name)
    end
  end

  describe "color_mode/1" do
    test "returns detected color mode" do
      {_pid, _device, name} = start_terminal()

      mode = Terminal.color_mode(name)
      assert mode in [:basic, :bit_8, :bit_24]

      Terminal.stop(name)
    end
  end

  describe "size/1" do
    test "returns {columns, rows} tuple" do
      {_pid, _device, name} = start_terminal()

      {cols, rows} = Terminal.size(name)
      assert is_integer(cols) and cols > 0
      assert is_integer(rows) and rows > 0

      Terminal.stop(name)
    end
  end

  describe "input forwarding" do
    test "forwards terminal input to target" do
      {_pid, _device, name} = start_terminal(input_target: self())

      send(Process.whereis(name), {:terminal_input, "hello"})

      assert_receive {:terminal_input, "hello"}, 100

      Terminal.stop(name)
    end

    test "does not crash when no input target" do
      {_pid, _device, name} = start_terminal(input_target: nil)

      send(Process.whereis(name), {:terminal_input, "hello"})

      Process.sleep(10)
      assert Process.alive?(Process.whereis(name))

      Terminal.stop(name)
    end
  end

  describe "resize" do
    test "forwards sigwinch as resize event to input target" do
      {_pid, _device, name} = start_terminal(input_target: self())

      send(Process.whereis(name), :sigwinch)

      assert_receive {:terminal_resize, cols, rows}, 100
      assert is_integer(cols) and cols > 0
      assert is_integer(rows) and rows > 0

      Terminal.stop(name)
    end

    test "does not crash on sigwinch with no input target" do
      {_pid, _device, name} = start_terminal(input_target: nil)

      send(Process.whereis(name), :sigwinch)

      Process.sleep(10)
      assert Process.alive?(Process.whereis(name))

      Terminal.stop(name)
    end
  end

  describe "input reader lifecycle" do
    test "does not spawn input reader when no input target" do
      {pid, _device, _name} = start_terminal(input_target: nil)

      # GenServer traps exits, so linked processes would show up
      # With no input target, no reader should be spawned
      state = :sys.get_state(pid)
      assert state.input_reader == nil

      Terminal.stop(pid)
    end
  end

  describe "skip_raw_mode" do
    test "does not write setup sequences when raw mode is skipped" do
      {_pid, device, name} = start_terminal()

      output = get_output(device)
      refute output =~ "\e[?1049h"

      Terminal.stop(name)
    end
  end

  describe "teardown" do
    test "does not write teardown sequences when raw mode was skipped" do
      {pid, device, _name} = start_terminal()

      ref = Process.monitor(pid)
      GenServer.stop(pid, :normal)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 100

      output = get_output(device)
      refute output =~ "\e[?1049l"
    end
  end
end
