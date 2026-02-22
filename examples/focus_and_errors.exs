# examples/focus_and_errors.exs
#
# Three focusable child components in a column.
# Tab/Shift-Tab cycles focus (visible border highlight).
# Press 'x' on focused child to crash it — brief fallback, auto-restart.
# Press 'q' to quit.
#
# Run: mix run examples/focus_and_errors.exs

# Suppress GenServer crash logs from polluting the TUI
:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

defmodule FocusChild do
  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:focused, fn -> false end)
     |> assign_new(:count, fn -> 0 end)}
  end

  @impl true
  def render(assigns) do
    name = assigns[:name] || "child"
    border = if assigns.focused, do: :rounded, else: :single
    fg = if assigns.focused, do: :cyan, else: :white

    box border: border, border_color: fg, width: 30 do
      text fg: fg do
        "#{name} [count: #{assigns.count}]#{if assigns.focused, do: " *", else: ""}"
      end
    end
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, {:char, "x"}}, _assigns) do
    raise "crash on purpose!"
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, update(assigns, :count, &(&1 + 1))}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    {:noreply, update(assigns, :count, &(max(&1 - 1, 0)))}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end
end

defmodule FocusApp do
  use Courgette.App

  @impl true
  def mount(_assigns) do
    {:ok, %{crashes: 0, last_crash: nil}}
  end

  @impl true
  def render(assigns) do
    box flex_direction: :column do
      text bold: true, fg: :yellow do
        "Focus & Error Boundaries Demo"
      end

      text fg: :white, dim: true do
        "Tab/Shift-Tab: cycle focus | Up/Down: count | x: crash | q: quit"
      end

      live_component(FocusChild, id: "alpha", focusable: true, name: "Alpha")
      live_component(FocusChild, id: "beta", focusable: true, name: "Beta")
      live_component(FocusChild, id: "gamma", focusable: true, name: "Gamma")

      if assigns.crashes > 0 do
        text fg: :red do
          "Crashes: #{assigns.crashes} | Last: #{inspect(assigns.last_crash)}"
        end
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop(self())
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info({:child_crashed, {_mod, id}, _reason}, assigns) do
    {:noreply,
     assigns
     |> assign(:crashes, assigns.crashes + 1)
     |> assign(:last_crash, id)}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(FocusApp)
