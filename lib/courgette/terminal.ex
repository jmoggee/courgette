defmodule Courgette.Terminal do
  @moduledoc """
  Terminal lifecycle management.

  A GenServer that owns the terminal: enables raw mode, detects capabilities,
  and ensures cleanup on exit.

  ## Screen Modes

  - `:fullscreen` (default) — enters the alternate screen buffer. Courgette
    owns every cell. Original terminal content is restored on exit.
  - `:inline` — renders at the current cursor position. Output stays in
    the terminal's native scrollback after exit.

  ## Startup

  On init, the Terminal:

  1. Enables raw mode via `:shell.start_interactive({:noshell, :raw})`
  2. Detects color capability via `Courgette.ANSI.ColorMode`
  3. Enters the alternate screen buffer (fullscreen mode only)
  4. Hides the cursor
  5. Enables focus events and bracketed paste
  6. Registers for SIGWINCH to detect terminal resize
  7. Spawns an input reader process (only if `input_target` is set)

  ## Shutdown

  On terminate (or crash), the Terminal restores all terminal state:
  shows the cursor, exits the alternate screen (if fullscreen), resets
  colors/styles. This is guaranteed by `GenServer.terminate/2`.

  ## Writing

  All terminal output goes through `write/1`, which writes iodata directly
  to `:standard_io`. This is a synchronous call — the data hits the terminal
  immediately. The future `OutputBuffer` will batch writes for efficiency,
  but the Terminal provides the raw write path.

  ## Input

  When `input_target` is set, the Terminal spawns a linked input reader
  process that blocks on `IO.getn("", 1024)`. When bytes arrive, they are
  forwarded to the target as `{:terminal_input, bytes}` messages. If no
  target is set, no input is consumed from stdin.

  ## Resize

  The Terminal registers a SIGWINCH handler via `:os.set_signal/2`. When the
  terminal is resized, the new dimensions are queried via `:io.columns/0` and
  `:io.rows/0` (which call `ioctl(TIOCGWINSZ)` via a NIF — always fresh,
  no caching) and forwarded to the input target as `{:terminal_resize, cols, rows}`.
  """

  use GenServer

  alias Courgette.ANSI
  alias Courgette.ANSI.ColorMode

  @type screen_mode :: :fullscreen | :inline
  @type state :: %{
          color_mode: ColorMode.mode(),
          screen_mode: screen_mode(),
          input_reader: pid() | nil,
          input_target: pid() | nil,
          device: atom() | pid(),
          raw: boolean()
        }

  # -- Public API --

  @doc """
  Start the Terminal server.

  ## Options

  - `:mode` — screen mode, `:fullscreen` (default) or `:inline`.
  - `:input_target` — pid to receive `{:terminal_input, bytes}` and
    `{:terminal_resize, cols, rows}` messages. If nil, no input is consumed.
  - `:device` — IO device for output. Defaults to `:standard_io`.
  - `:skip_raw_mode` — if `true`, skip `:shell.start_interactive`.
    Used for testing when the shell is already started.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Write iodata to the terminal."
  def write(data, server \\ __MODULE__) do
    GenServer.call(server, {:write, data})
  end

  @doc "Get the detected color mode."
  def color_mode(server \\ __MODULE__) do
    GenServer.call(server, :color_mode)
  end

  @doc "Get the screen mode (`:fullscreen` or `:inline`)."
  def screen_mode(server \\ __MODULE__) do
    GenServer.call(server, :screen_mode)
  end

  @doc "Get terminal dimensions as `{columns, rows}`."
  def size(server \\ __MODULE__) do
    GenServer.call(server, :size)
  end

  @doc """
  Change the input target at runtime.

  Kills the old input reader (if any), updates the target, and spawns
  a new reader if `target` is non-nil and raw mode is active.
  Pass `nil` to stop consuming input.
  """
  def set_input_target(target, server \\ __MODULE__) do
    GenServer.call(server, {:set_input_target, target})
  end

  @doc "Stop the terminal server, restoring terminal state."
  def stop(server \\ __MODULE__) do
    GenServer.stop(server, :normal)
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    device = Keyword.get(opts, :device, :standard_io)
    input_target = Keyword.get(opts, :input_target, nil)
    skip_raw = Keyword.get(opts, :skip_raw_mode, false)
    screen_mode = Keyword.get(opts, :mode, :fullscreen)

    raw =
      if skip_raw do
        false
      else
        case :shell.start_interactive({:noshell, :raw}) do
          :ok -> true
          {:error, _} -> false
        end
      end

    color_mode = ColorMode.detect()

    if raw do
      setup_terminal(device, screen_mode)
      setup_signal_handler()
    end

    # Only consume input when someone is listening
    input_reader =
      if raw && input_target do
        me = self()
        spawn_link(fn -> input_loop(me) end)
      end

    state = %{
      color_mode: color_mode,
      screen_mode: screen_mode,
      input_reader: input_reader,
      input_target: input_target,
      device: device,
      raw: raw
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:write, data}, _from, state) do
    IO.write(state.device, data)
    {:reply, :ok, state}
  end

  def handle_call(:color_mode, _from, state) do
    {:reply, state.color_mode, state}
  end

  def handle_call(:screen_mode, _from, state) do
    {:reply, state.screen_mode, state}
  end

  def handle_call(:size, _from, state) do
    {:reply, get_size(), state}
  end

  def handle_call({:set_input_target, target}, _from, state) do
    # Kill old reader if present
    if state.input_reader do
      Process.unlink(state.input_reader)
      Process.exit(state.input_reader, :kill)
    end

    # Spawn new reader if target given and in raw mode
    new_reader =
      if state.raw && target do
        me = self()
        spawn_link(fn -> input_loop(me) end)
      end

    {:reply, :ok, %{state | input_target: target, input_reader: new_reader}}
  end

  @impl true
  def handle_info({:terminal_input, bytes}, state) do
    if state.input_target do
      send(state.input_target, {:terminal_input, bytes})
    end

    {:noreply, state}
  end

  def handle_info(:sigwinch, state) do
    if state.input_target do
      {cols, rows} = get_size()
      send(state.input_target, {:terminal_resize, cols, rows})
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, %{input_reader: pid} = state) do
    # Input reader died — restart it if we still have a target
    new_reader =
      if state.input_target do
        me = self()
        spawn_link(fn -> input_loop(me) end)
      end

    {:noreply, %{state | input_reader: new_reader}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.raw do
      remove_signal_handler()
      teardown_terminal(state.device, state.screen_mode)
    end

    :ok
  end

  # -- Terminal setup/teardown --

  defp setup_terminal(device, :fullscreen) do
    IO.write(device, [
      ANSI.alternate_screen_enter(),
      ANSI.cursor_hide(),
      ANSI.clear_screen(),
      ANSI.cursor_home(),
      ANSI.focus_events_enable(),
      ANSI.bracketed_paste_enable()
    ])
  end

  defp setup_terminal(device, :inline) do
    IO.write(device, [
      ANSI.cursor_hide(),
      ANSI.focus_events_enable(),
      ANSI.bracketed_paste_enable()
    ])
  end

  defp teardown_terminal(device, :fullscreen) do
    IO.write(device, [
      ANSI.bracketed_paste_disable(),
      ANSI.focus_events_disable(),
      ANSI.mouse_disable(),
      ANSI.mouse_sgr_disable(),
      ANSI.cursor_show(),
      ANSI.reset(),
      ANSI.alternate_screen_exit()
    ])
  end

  defp teardown_terminal(device, :inline) do
    IO.write(device, [
      ANSI.bracketed_paste_disable(),
      ANSI.focus_events_disable(),
      ANSI.mouse_disable(),
      ANSI.mouse_sgr_disable(),
      ANSI.cursor_show(),
      ANSI.reset(),
      "\r\n"
    ])
  end

  # -- SIGWINCH handler --

  defp setup_signal_handler do
    :os.set_signal(:sigwinch, :handle)
    :gen_event.add_handler(:erl_signal_server, __MODULE__.SignalHandler, self())
  end

  defp remove_signal_handler do
    :gen_event.delete_handler(:erl_signal_server, __MODULE__.SignalHandler, :remove)
  rescue
    # erl_signal_server may not be running in test
    _ -> :ok
  end

  # -- Input reader --

  defp input_loop(terminal_pid) do
    case IO.getn("", 1024) do
      :eof ->
        send(terminal_pid, {:terminal_input, :eof})

      {:error, _reason} ->
        :ok

      data when is_binary(data) ->
        send(terminal_pid, {:terminal_input, data})
        input_loop(terminal_pid)
    end
  end

  # -- Terminal size --

  defp get_size do
    cols = try_io_columns()
    rows = try_io_rows()
    {cols, rows}
  end

  defp try_io_columns do
    case :io.columns() do
      {:ok, cols} -> cols
      {:error, _} -> try_tput("cols", 80)
    end
  end

  defp try_io_rows do
    case :io.rows() do
      {:ok, rows} -> rows
      {:error, _} -> try_tput("lines", 24)
    end
  end

  defp try_tput(attr, default) do
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
