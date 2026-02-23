defmodule Courgette.Components.Select do
  @moduledoc """
  Dropdown select component.

  Displays a single-line trigger showing the selected value when collapsed.
  Expands to show all options on Enter or Space, with arrow key navigation.
  Collapses after selection or Escape.

  Notifies the parent via `send(assigns.parent_pid, {on_select, value})` when
  an option is confirmed.

  ## Props

  - `options` — list of strings or `{value, label}` tuples (required)
  - `selected` — initial selected index (default 0)
  - `on_select` — message tag sent to parent on selection (optional)
  - `prompt` — text shown above the dropdown (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    options = normalize_options(assigns[:options] || [])

    {:ok,
     assigns
     |> assign(:options, options)
     |> assign_new(:selected, fn -> 0 end)
     |> assign_new(:on_select, fn -> nil end)
     |> assign_new(:prompt, fn -> nil end)
     |> assign_new(:focused, fn -> false end)
     |> assign_new(:expanded, fn -> false end)
     |> assign_new(:cursor, fn -> 0 end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    box border: :single, border_color: border_color, flex_direction: :column do
      if assigns.prompt do
        text(do: assigns.prompt)
      end

      if assigns.expanded do
        render_expanded(assigns)
      else
        render_collapsed(assigns)
      end
    end
  end

  defp render_collapsed(assigns) do
    {_value, label} = Enum.at(assigns.options, assigns.selected, {nil, ""})

    text do
      "#{label} ▾"
    end
  end

  defp render_expanded(assigns) do
    # Trigger line
    {_value, selected_label} = Enum.at(assigns.options, assigns.selected, {nil, ""})

    text do
      "#{selected_label} ▾"
    end

    for {opt, idx} <- Enum.with_index(assigns.options) do
      {_value, label} = opt
      cursor? = idx == assigns.cursor

      if cursor? do
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

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :options) do
        assign(new_assigns, :options, normalize_options(props.options))
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
    if assigns.expanded do
      max_idx = length(assigns.options) - 1
      {:noreply, assign(assigns, :cursor, min(assigns.cursor + 1, max_idx))}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, :arrow_up}, assigns) do
    if assigns.expanded do
      {:noreply, assign(assigns, :cursor, max(assigns.cursor - 1, 0))}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, key}, assigns) when key in [:enter, {:char, " "}] do
    if assigns.expanded do
      # Select the cursor item and collapse
      new_assigns =
        assigns
        |> assign(:selected, assigns.cursor)
        |> assign(:expanded, false)

      if assigns.on_select && assigns.parent_pid do
        {value, _label} = Enum.at(assigns.options, assigns.cursor)
        send(assigns.parent_pid, {assigns.on_select, value})
      end

      {:noreply, new_assigns}
    else
      # Expand and set cursor to current selection
      {:noreply,
       assigns
       |> assign(:expanded, true)
       |> assign(:cursor, assigns.selected)}
    end
  end

  def handle_event({:key, :escape}, assigns) do
    if assigns.expanded do
      {:noreply, assign(assigns, :expanded, false)}
    else
      {:noreply, assigns}
    end
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp normalize_options(options) do
    Enum.map(options, fn
      {value, label} -> {value, label}
      str when is_binary(str) -> {str, str}
    end)
  end
end
