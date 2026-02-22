# sketches/12_child_components.exs
#
# Phase 5c demo: dynamic child component lifecycle.
#
# A parent component manages a list of child Counter components.
# Each child ticks independently every 500ms. Press:
#   a — add a new child counter
#   d — remove the last child counter
#   q — quit
#
# Demonstrates:
# - live_component/2 in render
# - Lifecycle reconciliation (start/stop children dynamically)
# - Independent child state (each counter ticks on its own)
# - Parent tree assembly from child trees
#
# Run with: mix run sketches/12_child_components.exs

defmodule Sketch.ChildCounter do
  use Courgette.LiveComponent

  @tick_ms 500

  @impl true
  def mount(assigns) do
    schedule_tick()

    {:ok,
     %{
       label: assigns[:label] || "?",
       count: 0
     }}
  end

  @impl true
  def render(assigns) do
    box border: :single, padding_h: 1 do
      text do
        "#{assigns.label}: #{assigns.count}"
      end
    end
  end

  @impl true
  def handle_info(:tick, assigns) do
    schedule_tick()
    {:noreply, update(assigns, :count, &(&1 + 1))}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end
end

defmodule Sketch.ChildComponentsApp do
  use Courgette.App

  @impl true
  def mount(_assigns) do
    {:ok, %{next_id: 2, children: [%{id: "c1", label: "Alpha"}]}}
  end

  @impl true
  def render(assigns) do
    box border: :rounded, flex_direction: :column, padding: 1 do
      text bold: true, color: :cyan do
        "Child Components Demo"
      end

      text do
        ""
      end

      text color: :bright_black do
        "#{length(assigns.children)} child counters — each ticks independently"
      end

      text do
        ""
      end

      box flex_direction: :column do
        for child <- assigns.children do
          live_component(Sketch.ChildCounter, id: child.id, label: child.label)
        end
      end

      text do
        ""
      end

      text color: :bright_black do
        "a = add child  |  d = remove last  |  q = quit"
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "a"}}, assigns) do
    id = "c#{assigns.next_id}"
    label = Enum.at(~w(Alpha Beta Gamma Delta Epsilon Zeta Eta Theta), assigns.next_id - 1, "N#{assigns.next_id}")
    new_child = %{id: id, label: label}

    {:noreply,
     %{
       assigns
       | next_id: assigns.next_id + 1,
         children: assigns.children ++ [new_child]
     }}
  end

  def handle_event({:key, {:char, "d"}}, assigns) do
    case assigns.children do
      [] ->
        {:noreply, assigns}

      children ->
        {:noreply, %{assigns | children: Enum.drop(children, -1)}}
    end
  end

  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop()
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(Sketch.ChildComponentsApp)
