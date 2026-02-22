defmodule Courgette do
  @moduledoc """
  An Elixir TUI framework built on OTP.

  See the spec at rhyzo-architecture/spec/appendices/C-courgette-framework.md

  ## Quick Start

      defmodule MyApp do
        use Courgette.App

        def mount(_assigns), do: {:ok, %{count: 0}}

        def render(assigns) do
          text(do: "Count: \#{assigns.count}")
        end

        def handle_event({:key, :arrow_up}, assigns) do
          {:noreply, update(assigns, :count, &(&1 + 1))}
        end

        def handle_event({:key, {:char, "q"}}, _assigns) do
          Courgette.stop()
          {:noreply, %{}}
        end

        def handle_event(_event, assigns), do: {:noreply, assigns}
      end

      Courgette.run(MyApp)
  """

  alias Courgette.LiveComponent.Server
  alias Courgette.Renderer
  alias Courgette.Terminal

  @doc """
  Run a Courgette app, blocking until it exits.

  Starts Terminal → Renderer → LiveComponent.Server, wires up input,
  and blocks until the app server process terminates.

  ## Options

  - `:mode` — screen mode, `:fullscreen` (default) or `:inline`
  - `:initial_assigns` — map of initial assigns passed to `mount/1`
  """
  def run(module, opts \\ []) do
    screen_mode = Keyword.get(opts, :mode, :fullscreen)
    initial_assigns = Keyword.get(opts, :initial_assigns, %{})

    # 1. Start Terminal (no input target yet)
    {:ok, terminal} =
      Terminal.start_link(
        mode: screen_mode,
        input_target: nil
      )

    # 2. Query terminal size
    {cols, rows} = Terminal.size()

    # 3. Start Renderer
    {:ok, renderer} =
      Renderer.start_link(
        terminal: Terminal,
        width: cols,
        height: rows
      )

    # 4. Start LiveComponent.Server
    {:ok, app_server} =
      Server.start_link(
        module: module,
        renderer: renderer,
        initial_assigns: initial_assigns
      )

    # 5. Wire input to app server
    Terminal.set_input_target(app_server)

    # 6. Monitor and block until app exits
    ref = Process.monitor(app_server)

    receive do
      {:DOWN, ^ref, :process, ^app_server, _reason} -> :ok
    end

    # 7. Cleanup
    if Process.alive?(renderer), do: GenServer.stop(renderer)
    if Process.alive?(terminal), do: Terminal.stop()

    :ok
  end

  @doc """
  Stop the running app server.

  Call this from within `handle_event/2` to exit the app:

      def handle_event({:key, {:char, "q"}}, assigns) do
        Courgette.stop()
        {:noreply, assigns}
      end
  """
  def stop(server \\ nil) do
    pid =
      if server do
        server
      else
        # Find the app server by walking the process list.
        # In practice there's only one LiveComponent.Server.
        Process.list()
        |> Enum.find(fn pid ->
          case Process.info(pid, :dictionary) do
            {:dictionary, dict} ->
              Keyword.get(dict, :"$initial_call") ==
                {Courgette.LiveComponent.Server, :init, 1}

            _ ->
              false
          end
        end)
      end

    if pid && Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end
  end
end
