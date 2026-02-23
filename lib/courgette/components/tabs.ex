defmodule Courgette.Components.Tabs do
  @moduledoc """
  Horizontal tab bar for switching between content panes.

  Arrow keys move the active tab, Enter confirms. Notifies the parent
  via `send(assigns.parent_pid, {on_change, value})` when confirmed.

  ## Props

  - `tabs` — list of strings or `{id, label}` tuples (required)
  - `active` — initial active tab index (default 0)
  - `on_change` — message tag sent to parent on Enter (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    tabs = normalize_tabs(assigns[:tabs] || [])

    {:ok,
     assigns
     |> assign(:tabs, tabs)
     |> assign_new(:active, fn -> 0 end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    box border: :single, border_color: border_color do
      box flex_direction: :row do
        for {tab, idx} <- Enum.with_index(assigns.tabs) do
          {_value, label} = tab
          active? = idx == assigns.active

          if active? do
            text bold: true, fg: :cyan do
              "[ #{label} ]"
            end
          else
            text dim: true do
              "  #{label}  "
            end
          end
        end
      end
    end
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :tabs) do
        assign(new_assigns, :tabs, normalize_tabs(props.tabs))
      else
        new_assigns
      end

    {:ok, new_assigns}
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, :arrow_right}, assigns) do
    max_idx = length(assigns.tabs) - 1
    {:noreply, assign(assigns, :active, min(assigns.active + 1, max_idx))}
  end

  def handle_event({:key, :arrow_left}, assigns) do
    {:noreply, assign(assigns, :active, max(assigns.active - 1, 0))}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_change && assigns.parent_pid do
      {value, _label} = Enum.at(assigns.tabs, assigns.active)
      send(assigns.parent_pid, {assigns.on_change, value})
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp normalize_tabs(tabs) do
    Enum.map(tabs, fn
      {value, label} -> {value, label}
      str when is_binary(str) -> {str, str}
    end)
  end
end
