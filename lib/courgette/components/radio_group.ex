defmodule Courgette.Components.RadioGroup do
  @moduledoc """
  Single-selection radio button group.

  Arrow keys move the cursor highlight, Enter or Space confirms the selection.
  Notifies the parent via `send(assigns.parent_pid, {on_change, value})` when
  a selection is made.

  ## Props

  - `options` — list of strings or `{value, label}` tuples (required)
  - `selected` — the currently selected value (default nil)
  - `on_change` — message tag sent to parent when selection changes (optional)
  - `label` — group label text displayed above options (optional)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    options = normalize_options(assigns[:options] || [])

    {:ok,
     assigns
     |> assign(:options, options)
     |> assign_new(:selected, fn -> nil end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:label, fn -> nil end)
     |> assign_new(:cursor, fn -> 0 end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    box border: :single, border_color: border_color do
      if assigns.label do
        text(do: assigns.label)
      end

      for {opt, idx} <- Enum.with_index(assigns.options) do
        render_option(opt, idx, assigns)
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
    max_idx = length(assigns.options) - 1
    {:noreply, assign(assigns, :cursor, min(assigns.cursor + 1, max_idx))}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, assign(assigns, :cursor, max(assigns.cursor - 1, 0))}
  end

  def handle_event({:key, key}, assigns) when key in [:enter, {:char, " "}] do
    {value, _label} = Enum.at(assigns.options, assigns.cursor)
    new_assigns = assign(assigns, :selected, value)

    if assigns.on_change && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_change, value})
    end

    {:noreply, new_assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  defp render_option({value, label}, idx, assigns) do
    selected? = value == assigns.selected
    cursor? = idx == assigns.cursor
    indicator = if selected?, do: "(●)", else: "( )"
    content = "#{indicator} #{label}"

    if cursor? or selected? do
      text bold: true, fg: :cyan do
        content
      end
    else
      text do
        content
      end
    end
  end

  defp normalize_options(options) do
    Enum.map(options, fn
      {value, label} -> {value, label}
      str when is_binary(str) -> {str, str}
    end)
  end
end
