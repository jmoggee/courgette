defmodule Courgette.Renderer do
  @moduledoc """
  GenServer that owns the rendering pipeline.

  Receives element trees via `push/2`, runs them through the full pipeline
  (Engine → Painter → Diff → Writer → Terminal), and maintains the front
  buffer for incremental updates.

  ## Frame Batching

  In normal mode (real terminal), pushes mark the renderer dirty and rendering
  happens on a ~16ms tick loop (≈60 FPS). Multiple pushes between ticks are
  collapsed — only the last tree is rendered. Use `flush/1` to force an
  immediate render.

  ## Headless Mode

  In tests, start with `headless: true` to skip Terminal writes and disable
  the tick loop. Pushes render immediately (synchronous behavior), so existing
  tests work unchanged.
  """

  use GenServer

  alias Courgette.ANSI
  alias Courgette.Buffer
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.Painter
  alias Courgette.Selection
  alias Courgette.Terminal

  @frame_ms 16

  @type state :: %{
          front: Buffer.t(),
          base: Buffer.t(),
          terminal: pid() | atom() | nil,
          width: pos_integer(),
          height: pos_integer(),
          headless: boolean(),
          last_tree: Courgette.Element.t() | nil,
          dirty: boolean(),
          selection: Selection.t() | nil
        }

  # -- Public API --

  @doc """
  Start the Renderer.

  ## Options

  - `:terminal` — Terminal server pid or name. Required unless headless.
  - `:width` — buffer width in columns.
  - `:height` — buffer height in rows.
  - `:name` — GenServer name registration.
  - `:headless` — if `true`, skip Terminal.write calls and tick loop. For tests.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @doc """
  Push an element tree through the render pipeline.

  In headless mode, renders immediately. In normal mode, stores the tree and
  marks dirty — actual rendering happens on the next tick.
  """
  def push(tree, server) do
    GenServer.call(server, {:push, tree})
  end

  @doc """
  Force an immediate render if dirty.

  In normal mode, this bypasses the tick loop and renders right away.
  Returns `:ok` regardless of whether a render was needed.
  """
  def flush(server) do
    GenServer.call(server, :flush)
  end

  @doc """
  Handle a terminal resize.

  Clears the screen and resets the front buffer to the new dimensions.
  """
  def resize(cols, rows, server) do
    GenServer.call(server, {:resize, cols, rows})
  end

  @doc "Get the last element tree that was pushed (for test assertions)."
  def get_last_tree(server) do
    GenServer.call(server, :get_last_tree)
  end

  @doc "Start a screen-cell selection at a zero-based point."
  def begin_selection(point, server), do: GenServer.call(server, {:begin_selection, point})

  @doc "Extend the active screen-cell selection to a zero-based point."
  def extend_selection(point, server), do: GenServer.call(server, {:extend_selection, point})

  @doc "Finish the active selection and return its plain text, if non-empty."
  def finish_selection(point, server), do: GenServer.call(server, {:finish_selection, point})

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    width = Keyword.get(opts, :width, 80)
    height = Keyword.get(opts, :height, 24)
    terminal = Keyword.get(opts, :terminal)
    headless = Keyword.get(opts, :headless, false)

    state = %{
      front: Buffer.new(width, height),
      base: Buffer.new(width, height),
      terminal: terminal,
      width: width,
      height: height,
      headless: headless,
      last_tree: nil,
      dirty: false,
      selection: nil
    }

    unless headless do
      schedule_tick()
    end

    {:ok, state}
  end

  @impl true
  def handle_call({:push, tree}, _from, state) do
    state = %{state | last_tree: tree}

    if state.headless do
      # Headless: render immediately (synchronous, test-friendly)
      {:reply, :ok, do_render(state)}
    else
      # Normal: mark dirty, render on next tick
      {:reply, :ok, %{state | dirty: true}}
    end
  end

  def handle_call(:flush, _from, state) do
    if state.dirty do
      {:reply, :ok, do_render(%{state | dirty: false})}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:resize, cols, rows}, _from, state) do
    resized = %{
      state
      | front: Buffer.new(cols, rows),
        base: Buffer.new(cols, rows),
        width: cols,
        height: rows,
        dirty: false,
        selection: nil
    }

    {:reply, :ok, resize_frame(resized)}
  end

  def handle_call(:get_last_tree, _from, state) do
    {:reply, state.last_tree, state}
  end

  def handle_call({:begin_selection, point}, _from, state) do
    state = repaint(%{state | selection: Selection.new(point)})
    {:reply, :ok, state}
  end

  def handle_call(
        {:extend_selection, point},
        _from,
        %{selection: %Selection{} = selection} = state
      ) do
    state = repaint(%{state | selection: Selection.extend(selection, point)})
    {:reply, :ok, state}
  end

  def handle_call({:extend_selection, _point}, _from, state), do: {:reply, :ok, state}

  def handle_call(
        {:finish_selection, point},
        _from,
        %{selection: %Selection{} = selection} = state
      ) do
    selection = Selection.extend(selection, point)

    if Selection.empty?(selection) do
      {:reply, nil, repaint(%{state | selection: nil})}
    else
      state = repaint(%{state | selection: selection})
      {:reply, Selection.text(selection, state.base), state}
    end
  end

  def handle_call({:finish_selection, _point}, _from, state), do: {:reply, nil, state}

  @impl true
  def handle_info(:tick, state) do
    state =
      if state.dirty do
        do_render(%{state | dirty: false})
      else
        state
      end

    schedule_tick()
    {:noreply, state}
  end

  # -- Private --

  defp do_render(state) do
    %{front: front, width: w, height: h, last_tree: tree} = state

    # 1. Layout
    layout = Engine.compute(tree, Bounds.new(0, 0, w, h))

    # 2. Paint into back buffer
    base = Painter.paint(layout, Buffer.new(w, h))
    back = selected_buffer(base, state.selection)

    # 3. Diff
    runs = Diff.diff(front, back)

    # 4. Write to terminal (unless headless)
    unless state.headless do
      iodata = Writer.render(runs)
      Terminal.write([ANSI.sync_begin(), iodata, ANSI.sync_end()], state.terminal)
    end

    # 5. Swap front buffer
    %{state | front: back, base: base}
  end

  defp repaint(%{last_tree: nil} = state), do: state
  defp repaint(state), do: do_render(state)

  defp resize_frame(%{last_tree: nil, headless: false} = state) do
    Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()], state.terminal)
    state
  end

  defp resize_frame(state), do: repaint(state)

  defp selected_buffer(buffer, nil), do: buffer
  defp selected_buffer(buffer, selection), do: Selection.highlight(selection, buffer)

  defp schedule_tick do
    Process.send_after(self(), :tick, @frame_ms)
  end
end
