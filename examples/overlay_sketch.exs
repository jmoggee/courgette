# examples/overlay_sketch.exs
#
# Overlay component sketch — iterating toward a command palette.
#
# Starting simple, adding complexity incrementally:
# 1. Static text in overlay (baseline)
# 2. Live component inside overlay
# 3. Full command palette (TextInput + List)
#
# Run with: mix run examples/overlay_sketch.exs

defmodule Example.OverlaySketch do
  use Courgette.App
  import Courgette.Components
  import Courgette.Components.Overlay

  alias Courgette.Components.TextInput
  @items [
    "Checkbox",
    "Switch",
    "RadioGroup",
    "Select",
    "TextInput",
    "Textarea",
    "Table",
    "List",
    "Tree",
    "Tabs",
    "Spinner",
    "ProgressBar"
  ]

  @visible_height 12

  @impl true
  def mount(_assigns) do
    {:ok, %{filter: "", selected: 0, open: false}}
  end

  @impl true
  def render(assigns) do
    filtered = filter_items(assigns.filter)
    count = length(filtered)
    selected = min(assigns.selected, max(count - 1, 0))
    scroll_offset = scroll_offset_for(selected, count, @visible_height)

    box flex_direction: :column, flex: 1 do
      # Background wall of text
      box flex: 1, flex_direction: :column, padding: 1 do
        text bold: true, fg: :yellow do
          "Background Content"
        end

        for i <- 1..30 do
          text dim: true do
            "#{String.pad_leading("#{i}", 2, "0")}  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
          end
        end
      end

      box padding_h: 1 do
        text dim: true do
          "Ctrl+P: open palette  |  q: quit"
        end
      end

      # Overlay centered on screen
      if assigns.open do
        box position: :absolute, top: 0, left: 0, right: 0, bottom: 0,
            justify_content: :center, align_items: :center do
          box border: :rounded, bg: :black, width: 50, height: 20,
              flex_direction: :column, padding: 1, overflow: :hidden do
            text bold: true do
              "Command Palette"
            end

            live_component(TextInput,
              id: "filter",
              focusable: true,
              value: assigns.filter,
              placeholder: "Type to filter...",
              on_change: :filter_changed
            )

            box height: @visible_height, overflow: :scroll, scroll_offset: scroll_offset,
                flex_direction: :column do
              for {label, idx} <- Enum.with_index(filtered) do
                if idx == selected do
                  text(bold: true, fg: :cyan, do: "▸ #{label}")
                else
                  text(do: "  #{label}")
                end
              end
            end
          end
        end
      end
    end
  end

  defp scroll_offset_for(idx, count, visible_height) do
    min(max(0, idx - visible_height + 1), max(0, count - visible_height))
  end

  defp filter_items(""), do: @items

  defp filter_items(filter) do
    q = String.downcase(filter)
    Enum.filter(@items, fn label -> String.downcase(label) |> String.contains?(q) end)
  end

  @impl true
  def handle_event({:key, {:ctrl, "p"}}, assigns) do
    {:noreply, %{assigns | open: true, filter: "", selected: 0}}
  end

  def handle_event({:key, :escape}, assigns) do
    {:noreply, %{assigns | open: false}}
  end

  def handle_event({:key, :arrow_down}, %{open: true} = assigns) do
    count = length(filter_items(assigns.filter))
    {:noreply, %{assigns | selected: min(assigns.selected + 1, count - 1)}}
  end

  def handle_event({:key, :arrow_up}, %{open: true} = assigns) do
    {:noreply, %{assigns | selected: max(assigns.selected - 1, 0)}}
  end

  def handle_event({:key, :enter}, %{open: true} = assigns) do
    items = filter_items(assigns.filter)
    selected = min(assigns.selected, length(items) - 1)

    if selected >= 0 do
      label = Enum.at(items, selected)
      {:noreply, %{assigns | filter: label, selected: 0, open: false}}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop()
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info({:filter_changed, value}, assigns) do
    {:noreply, %{assigns | filter: value, selected: 0}}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(Example.OverlaySketch)
