defmodule Courgette.Renderer do
  @moduledoc """
  GenServer that owns the rendering pipeline.

  Receives element trees via `push/2`, runs them through the full pipeline
  (Engine → Painter → Diff → Writer → Terminal), and maintains the front
  buffer for incremental updates.

  ## Headless Mode

  In tests, start with `headless: true` to skip Terminal writes. The
  renderer still runs the full pipeline and stores the last tree and
  painted buffer for assertions.
  """

  use GenServer

  alias Courgette.Buffer
  alias Courgette.Buffer.Diff
  alias Courgette.Buffer.Writer
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine
  alias Courgette.ANSI
  alias Courgette.Painter
  alias Courgette.Terminal

  @type state :: %{
          front: Buffer.t(),
          terminal: pid() | atom() | nil,
          width: pos_integer(),
          height: pos_integer(),
          headless: boolean(),
          last_tree: Courgette.Element.t() | nil
        }

  # -- Public API --

  @doc """
  Start the Renderer.

  ## Options

  - `:terminal` — Terminal server pid or name. Required unless headless.
  - `:width` — buffer width in columns.
  - `:height` — buffer height in rows.
  - `:name` — GenServer name registration.
  - `:headless` — if `true`, skip Terminal.write calls. For tests.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @doc """
  Push an element tree through the render pipeline.

  Computes layout, paints into a back buffer, diffs against the front
  buffer, and writes the changes to the terminal.
  """
  def push(tree, server) do
    GenServer.call(server, {:push, tree})
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

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    width = Keyword.get(opts, :width, 80)
    height = Keyword.get(opts, :height, 24)
    terminal = Keyword.get(opts, :terminal)
    headless = Keyword.get(opts, :headless, false)

    state = %{
      front: Buffer.new(width, height),
      terminal: terminal,
      width: width,
      height: height,
      headless: headless,
      last_tree: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:push, tree}, _from, state) do
    %{front: front, width: w, height: h} = state

    # 1. Layout
    layout = Engine.compute(tree, Bounds.new(0, 0, w, h))

    # 2. Paint into back buffer
    back = Painter.paint(layout, Buffer.new(w, h))

    # 3. Diff
    runs = Diff.diff(front, back)

    # 4. Write to terminal (unless headless)
    unless state.headless do
      iodata = Writer.render(runs)
      Terminal.write([ANSI.sync_begin(), iodata, ANSI.sync_end()], state.terminal)
    end

    # 5. Swap front buffer
    {:reply, :ok, %{state | front: back, last_tree: tree}}
  end

  def handle_call({:resize, cols, rows}, _from, state) do
    unless state.headless do
      Terminal.write([ANSI.clear_screen(), ANSI.cursor_home()], state.terminal)
    end

    {:reply, :ok,
     %{state | front: Buffer.new(cols, rows), width: cols, height: rows, last_tree: nil}}
  end

  def handle_call(:get_last_tree, _from, state) do
    {:reply, state.last_tree, state}
  end
end
