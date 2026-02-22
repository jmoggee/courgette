defmodule Courgette.Components.Select do
  @moduledoc """
  Navigable option picker.

  Arrow keys move the selection, Enter confirms. Notifies the parent
  via `send(assigns.parent_pid, {on_select, value})` when confirmed.

  ## Props

  - `options` — list of strings or `{value, label}` tuples (required)
  - `selected` — initial selected index (default 0)
  - `on_select` — message tag sent to parent on Enter (optional)
  - `prompt` — text shown above options (optional)
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
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    box border: :single, border_color: border_color do
      if assigns.prompt do
        text(do: assigns.prompt)
      end

      for {opt, idx} <- Enum.with_index(assigns.options) do
        {_value, label} = opt
        selected? = idx == assigns.selected

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
    {:noreply, assign(assigns, :selected, min(assigns.selected + 1, max_idx))}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, assign(assigns, :selected, max(assigns.selected - 1, 0))}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_select && assigns.parent_pid do
      {value, _label} = Enum.at(assigns.options, assigns.selected)
      send(assigns.parent_pid, {assigns.on_select, value})
    end

    {:noreply, assigns}
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
