defmodule Courgette.Components.List do
  @moduledoc """
  Scrollable, keyboard-navigable list for browsing data.

  Arrow keys move the highlight, Enter confirms. Supports scrolling when
  items exceed `max_visible`. Notifies the parent via
  `send(assigns.parent_pid, {on_select, item})` on Enter and
  `send(assigns.parent_pid, {on_highlight, item})` on cursor movement.

  ## Props

  - `items` — list of strings or `{id, label}` tuples (required)
  - `selected` — initial selected index (default 0)
  - `on_select` — message tag sent to parent on Enter (optional)
  - `on_highlight` — message tag sent to parent when cursor moves (optional)
  - `max_visible` — max number of visible items before scrolling (default 10)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    items = normalize_items(assigns[:items] || [])
    selected = assigns[:selected] || 0
    max_visible = assigns[:max_visible] || 10

    {:ok,
     assigns
     |> assign(:items, items)
     |> assign(:selected, selected)
     |> assign(:scroll_offset, compute_scroll_offset(selected, 0, max_visible, length(items)))
     |> assign_new(:on_select, fn -> nil end)
     |> assign_new(:on_highlight, fn -> nil end)
     |> assign(:max_visible, max_visible)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white
    visible_items = visible_items(assigns)

    box border: :single, border_color: border_color do
      for {{_id, label}, actual_idx} <- visible_items do
        selected? = actual_idx == assigns.selected

        if selected? do
          text bold: true, fg: :cyan do
            "▸ #{label}"
          end
        else
          text do
            "  #{label}"
          end
        end
      end
    end
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :items) do
        assign(new_assigns, :items, normalize_items(props.items))
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

  def handle_event({:key, :arrow_down}, assigns) do
    max_idx = length(assigns.items) - 1
    new_selected = min(assigns.selected + 1, max_idx)
    assigns = move_to(assigns, new_selected)
    {:noreply, assigns}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    new_selected = max(assigns.selected - 1, 0)
    assigns = move_to(assigns, new_selected)
    {:noreply, assigns}
  end

  def handle_event({:key, :home}, assigns) do
    assigns = move_to(assigns, 0)
    {:noreply, assigns}
  end

  def handle_event({:key, :end}, assigns) do
    max_idx = length(assigns.items) - 1
    assigns = move_to(assigns, max_idx)
    {:noreply, assigns}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_select && assigns.parent_pid do
      {id, _label} = Enum.at(assigns.items, assigns.selected)
      send(assigns.parent_pid, {assigns.on_select, id})
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp move_to(assigns, new_selected) do
    old_selected = assigns.selected

    new_offset =
      compute_scroll_offset(
        new_selected,
        assigns.scroll_offset,
        assigns.max_visible,
        length(assigns.items)
      )

    assigns = assign(assigns, :selected, new_selected)
    assigns = assign(assigns, :scroll_offset, new_offset)

    if new_selected != old_selected && assigns.on_highlight && assigns.parent_pid do
      {id, _label} = Enum.at(assigns.items, new_selected)
      send(assigns.parent_pid, {assigns.on_highlight, id})
    end

    assigns
  end

  defp compute_scroll_offset(selected, current_offset, max_visible, item_count) do
    max_offset = max(item_count - max_visible, 0)

    cond do
      selected < current_offset ->
        selected

      selected >= current_offset + max_visible ->
        min(selected - max_visible + 1, max_offset)

      true ->
        min(current_offset, max_offset)
    end
  end

  defp visible_items(assigns) do
    offset = assigns.scroll_offset
    count = assigns.max_visible

    assigns.items
    |> Enum.with_index()
    |> Enum.slice(offset, count)
  end

  defp normalize_items(items) do
    Enum.map(items, fn
      {id, label} -> {id, label}
      str when is_binary(str) -> {str, str}
    end)
  end
end
