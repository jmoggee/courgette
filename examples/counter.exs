# examples/counter.exs
#
# Interactive counter app using Courgette.App.
#
# An interactive counter:
# - Arrow up/down to increment/decrement
# - r to reset
# - q to quit
#
# Run with: mix run examples/counter.exs

defmodule Example.Counter do
  use Courgette.App

  @impl true
  def mount(_assigns) do
    {:ok, %{count: 0, last_event: nil}}
  end

  @impl true
  def render(assigns) do
    box border: :rounded, flex_direction: :column, padding: 1 do
      text bold: true, color: :cyan do
        "Courgette Counter"
      end

      text do
        ""
      end

      box flex_direction: :row do
        text color: :yellow do
          "Count: "
        end

        text bold: true, color: if(assigns.count >= 0, do: :green, else: :red) do
          "#{assigns.count}"
        end
      end

      text do
        ""
      end

      text color: :bright_black do
        "↑/↓ increment/decrement  r reset  q quit"
      end

      if assigns.last_event do
        text color: :bright_black do
          "Last event: #{inspect(assigns.last_event)}"
        end
      end
    end
  end

  @impl true
  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, %{assigns | count: assigns.count + 1, last_event: :arrow_up}}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    {:noreply, %{assigns | count: assigns.count - 1, last_event: :arrow_down}}
  end

  def handle_event({:key, {:char, "r"}}, assigns) do
    {:noreply, %{assigns | count: 0, last_event: :reset}}
  end

  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop()
    {:noreply, %{}}
  end

  def handle_event(event, assigns) do
    {:noreply, %{assigns | last_event: event}}
  end
end

Courgette.run(Example.Counter)
