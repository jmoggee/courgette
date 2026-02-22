defmodule Courgette.Components.TextInput do
  @moduledoc """
  Single-line text input with cursor.

  Supports character insertion, deletion, cursor movement, and line-editing
  shortcuts. Notifies the parent via `send(assigns.parent_pid, {tag, value})`.

  ## Props

  - `value` — initial text (default "")
  - `placeholder` — shown when empty and unfocused (default "")
  - `on_change` — message tag sent on every edit (optional)
  - `on_submit` — message tag sent on Enter (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    value = assigns[:value] || ""
    cursor = String.length(value)

    {:ok,
     assigns
     |> assign(:value, value)
     |> assign(:cursor, cursor)
     |> assign_new(:placeholder, fn -> "" end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:on_submit, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    cond do
      assigns.focused ->
        # Show cursor
        graphemes = String.graphemes(assigns.value)
        pos = assigns.cursor

        before = Enum.slice(graphemes, 0, pos) |> Enum.join()
        cursor_char = Enum.at(graphemes, pos)
        after_cursor = Enum.slice(graphemes, (pos + 1)..-1//1) |> Enum.join()

        box border: :single, border_color: border_color, flex_direction: :row do
          if before != "" do
            text(do: before)
          end

          if cursor_char do
            text reverse: true do
              cursor_char
            end
          else
            # Cursor at end — show reversed space
            text reverse: true do
              " "
            end
          end

          if after_cursor != "" do
            text(do: after_cursor)
          end
        end

      assigns.value == "" ->
        # Unfocused, empty — show placeholder
        box border: :single, border_color: border_color do
          text dim: true do
            assigns.placeholder
          end
        end

      true ->
        # Unfocused with value — show plain text
        box border: :single, border_color: border_color do
          text(do: assigns.value)
        end
    end
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    # If value was updated externally, reset cursor to end
    new_assigns =
      if Map.has_key?(props, :value) && props.value != assigns.value do
        assign(new_assigns, :cursor, String.length(props.value))
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

  def handle_event({:key, {:char, ch}}, assigns) do
    graphemes = String.graphemes(assigns.value)
    new_graphemes = List.insert_at(graphemes, assigns.cursor, ch)
    new_value = Enum.join(new_graphemes)
    assigns = assigns |> assign(:value, new_value) |> assign(:cursor, assigns.cursor + 1)
    {:noreply, notify_change(assigns)}
  end

  def handle_event({:key, :backspace}, assigns) do
    if assigns.cursor > 0 do
      graphemes = String.graphemes(assigns.value)
      new_graphemes = List.delete_at(graphemes, assigns.cursor - 1)
      new_value = Enum.join(new_graphemes)
      assigns = assigns |> assign(:value, new_value) |> assign(:cursor, assigns.cursor - 1)
      {:noreply, notify_change(assigns)}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, :delete}, assigns) do
    graphemes = String.graphemes(assigns.value)

    if assigns.cursor < length(graphemes) do
      new_graphemes = List.delete_at(graphemes, assigns.cursor)
      new_value = Enum.join(new_graphemes)
      assigns = assign(assigns, :value, new_value)
      {:noreply, notify_change(assigns)}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, :arrow_left}, assigns) do
    {:noreply, assign(assigns, :cursor, max(assigns.cursor - 1, 0))}
  end

  def handle_event({:key, :arrow_right}, assigns) do
    max_pos = String.length(assigns.value)
    {:noreply, assign(assigns, :cursor, min(assigns.cursor + 1, max_pos))}
  end

  def handle_event({:key, :home}, assigns) do
    {:noreply, assign(assigns, :cursor, 0)}
  end

  def handle_event({:key, :end}, assigns) do
    {:noreply, assign(assigns, :cursor, String.length(assigns.value))}
  end

  def handle_event({:key, {:ctrl, "k"}}, assigns) do
    # Kill to end of line
    graphemes = String.graphemes(assigns.value)
    new_value = Enum.slice(graphemes, 0, assigns.cursor) |> Enum.join()
    assigns = assign(assigns, :value, new_value)
    {:noreply, notify_change(assigns)}
  end

  def handle_event({:key, {:ctrl, "u"}}, assigns) do
    # Kill to start of line
    graphemes = String.graphemes(assigns.value)
    new_value = Enum.slice(graphemes, assigns.cursor..-1//1) |> Enum.join()
    assigns = assigns |> assign(:value, new_value) |> assign(:cursor, 0)
    {:noreply, notify_change(assigns)}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_submit && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_submit, assigns.value})
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp notify_change(assigns) do
    if assigns.on_change && assigns[:parent_pid] do
      send(assigns.parent_pid, {assigns.on_change, assigns.value})
    end

    assigns
  end
end
