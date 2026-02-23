defmodule Courgette.Components.Checkbox do
  @moduledoc """
  Toggleable boolean checkbox control.

  Renders as `[x]` when checked or `[ ]` when unchecked, with an optional
  label displayed beside the marker. Enter or Space toggles the state and
  notifies the parent via `send(assigns.parent_pid, {on_change, new_value})`.

  ## Props

  - `checked` — boolean, default false
  - `label` — string displayed next to the checkbox (optional)
  - `on_change` — message tag sent to parent on toggle (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:checked, fn -> false end)
     |> assign_new(:label, fn -> nil end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white
    marker = if assigns.checked, do: "[x]", else: "[ ]"

    box border: :single, border_color: border_color do
      box flex_direction: :row do
        text do
          marker
        end

        if assigns.label do
          text do
            " #{assigns.label}"
          end
        end
      end
    end
  end

  @impl true
  def update(props, assigns) do
    {:ok, Map.merge(assigns, props)}
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, :enter}, assigns) do
    toggle(assigns)
  end

  def handle_event({:key, {:char, " "}}, assigns) do
    toggle(assigns)
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp toggle(assigns) do
    new_checked = !assigns.checked

    if assigns.on_change && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_change, new_checked})
    end

    {:noreply, assign(assigns, :checked, new_checked)}
  end
end
