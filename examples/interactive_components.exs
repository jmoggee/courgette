# Sketch 14: Interactive Components
#
# Demo of all four built-in interactive components:
# - Spinner: animated loading indicator
# - ProgressBar: determinate progress display
# - Select: navigable option picker
# - TextInput: single-line text editor with cursor
#
# Tab between components. Arrow keys to navigate Select.
# Type in the TextInput. Press Enter to submit.
# Press 'q' to quit.
#
# Run: mix run sketches/14_interactive_components.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Components.{ProgressBar, Spinner, Select, TextInput}

defmodule InteractiveDemo do
  use Courgette.App

  @tick_ms 100

  @impl true
  def mount(_assigns) do
    schedule_tick()

    {:ok,
     %{
       progress: 0.0,
       selected_color: nil,
       submitted_name: nil
     }}
  end

  @impl true
  def render(assigns) do
    box flex_direction: :column do
      text bold: true, fg: :yellow do
        "Interactive Components Demo"
      end

      text fg: :white, dim: true do
        "Tab: cycle focus | Arrows: navigate | Enter: submit | q: quit"
      end

      # Spinner
      box flex_direction: :row, padding_v: 1 do
        text fg: :white do
          "Status: "
        end

        live_component(Spinner,
          id: "spinner",
          style: :dots,
          label: "Loading...",
          color: :cyan
        )
      end

      # Progress bar
      box padding_v: 1 do
        text fg: :white do
          "Download progress:"
        end

        live_component(ProgressBar,
          id: "progress",
          value: assigns.progress,
          width: 30,
          color: :green,
          label: :percent
        )
      end

      # Select
      live_component(Select,
        id: "colors",
        focusable: true,
        options: [
          {"red", "Red"},
          {"green", "Green"},
          {"blue", "Blue"},
          {"yellow", "Yellow"}
        ],
        prompt: "Pick a color:",
        on_select: :color_picked
      )

      # TextInput
      box padding_v: 1 do
        text fg: :white do
          "Your name:"
        end

        live_component(TextInput,
          id: "name",
          focusable: true,
          placeholder: "Type your name...",
          on_submit: :name_submitted
        )
      end

      # Results display
      if assigns.selected_color do
        text fg: :green do
          "Selected color: #{assigns.selected_color}"
        end
      end

      if assigns.submitted_name do
        text fg: :green do
          "Hello, #{assigns.submitted_name}!"
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
  def handle_info(:tick, assigns) do
    new_progress = min(assigns.progress + 0.01, 1.0)
    schedule_tick()
    {:noreply, assign(assigns, :progress, new_progress)}
  end

  def handle_info({:color_picked, color}, assigns) do
    {:noreply, assign(assigns, :selected_color, color)}
  end

  def handle_info({:name_submitted, name}, assigns) do
    {:noreply, assign(assigns, :submitted_name, name)}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end
end

Courgette.run(InteractiveDemo)
