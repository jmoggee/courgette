defmodule Courgette.Components.ProgressBar do
  @moduledoc """
  Determinate progress bar display.

  Renders a horizontal bar filled proportionally to a `value` prop (0.0–1.0).
  No keyboard interaction — the parent controls progress via props.

  ## Props

  - `value` — float 0.0 to 1.0 (default 0.0)
  - `width` — bar width in cells (default 20)
  - `color` — fill color (default `:cyan`)
  - `bg_color` — empty color (default `:white`)
  - `label` — `:percent` to show percentage, or nil (default nil)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:value, fn -> 0.0 end)
     |> assign_new(:width, fn -> 20 end)
     |> assign_new(:color, fn -> :cyan end)
     |> assign_new(:bg_color, fn -> :white end)
     |> assign_new(:label, fn -> nil end)}
  end

  @impl true
  def render(assigns) do
    value = assigns.value |> max(0.0) |> min(1.0)
    filled = round(value * assigns.width)
    empty = assigns.width - filled

    fill_str = String.duplicate("█", filled)
    empty_str = String.duplicate("░", empty)

    label_str =
      case assigns.label do
        :percent -> " #{round(value * 100)}%"
        _ -> ""
      end

    box flex_direction: :row do
      text fg: assigns.color do
        fill_str
      end

      text fg: assigns.bg_color do
        empty_str
      end

      if label_str != "" do
        text(do: label_str)
      end
    end
  end

  @impl true
  def update(props, assigns) do
    {:ok, Map.merge(assigns, props)}
  end
end
