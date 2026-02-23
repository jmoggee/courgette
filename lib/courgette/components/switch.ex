defmodule Courgette.Components.Switch do
  @moduledoc """
  On/off toggle switch control.

  A visual alternative to a checkbox. Toggles between on and off states
  via Enter or Space. Notifies the parent via
  `send(assigns.parent_pid, {on_change, new_value})` when toggled.

  ## Props

  - `on` — boolean, default `false`
  - `label` — string displayed next to the switch (optional)
  - `on_change` — message tag sent to parent on toggle (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:on, fn -> false end)
     |> assign_new(:label, fn -> nil end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white
    indicator = if assigns.on, do: "◉ ━━", else: "━━ ○"
    indicator_color = if assigns.on, do: :cyan, else: :white

    box border: :single, border_color: border_color do
      if assigns.label do
        text fg: indicator_color do
          "#{indicator}  #{assigns.label}"
        end
      else
        text fg: indicator_color do
          indicator
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
    new_value = !assigns.on
    new_assigns = assign(assigns, :on, new_value)

    if assigns.on_change && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_change, new_value})
    end

    {:noreply, new_assigns}
  end
end
