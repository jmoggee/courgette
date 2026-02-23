defmodule Courgette.Components.ScrollArea do
  @moduledoc """
  A scrollable viewport with automatic scrollbar.

  Wraps arbitrary child content in a scrollable area that handles keyboard
  and mouse scroll events. Renders a visual scrollbar when content overflows
  the viewport.

  ## Props

  - `inner_block` — slot content from `do` block (elements)
  - `height` — viewport height in rows (integer, required)
  - `scrollbar` — show scrollbar when content overflows (boolean, default `true`)
  - `on_scroll` — optional message tag sent to parent on scroll offset change
  - `border` — border style passed to the scrollable area (atom, optional)
  - `border_color` — border color override (atom, optional)
  - `content_height` — explicit content height override; defaults to counting children

  ## Examples

      live_component(ScrollArea, id: "log", height: 10) do
        for line <- assigns.log_lines do
          text do: line
        end
      end

      live_component(ScrollArea, id: "items", height: 20, scrollbar: false) do
        text do: "No scrollbar shown"
      end
  """

  use Courgette.LiveComponent

  import Courgette.Components.Scrollbar, only: [scrollbar: 1]

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:inner_block, fn -> [] end)
     |> assign_new(:scrollbar, fn -> true end)
     |> assign_new(:on_scroll, fn -> nil end)
     |> assign_new(:border, fn -> nil end)
     |> assign_new(:border_color, fn -> nil end)
     |> assign_new(:content_height, fn -> nil end)
     |> assign_new(:scroll_offset, fn -> 0 end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def update(props, assigns) do
    {:ok, Map.merge(assigns, props)}
  end

  @impl true
  def render(assigns) do
    height = assigns.height
    content_h = assigns.content_height || length(assigns.inner_block)
    max_offset = max(0, content_h - height)
    offset = clamp(assigns.scroll_offset, 0, max_offset)
    show_scrollbar = assigns.scrollbar && content_h > height
    children = render_slot(assigns.inner_block)

    border_color =
      assigns.border_color || if(assigns.focused, do: :cyan, else: :white)

    scroll_opts =
      [flex: 1, height: height, scroll_offset: offset, overflow: :scroll, flex_direction: :column]
      |> maybe_add(:border, assigns.border)
      |> Keyword.put(:border_color, border_color)

    box flex_direction: :row do
      box scroll_opts do
        for child <- children do
          child
        end
      end

      if show_scrollbar do
        scrollbar(
          content_length: content_h,
          viewport_length: height,
          offset: offset
        )
      end
    end
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    scroll_by(assigns, -1)
  end

  def handle_event({:key, :arrow_down}, assigns) do
    scroll_by(assigns, 1)
  end

  def handle_event({:key, :page_up}, assigns) do
    scroll_by(assigns, -assigns.height)
  end

  def handle_event({:key, :page_down}, assigns) do
    scroll_by(assigns, assigns.height)
  end

  def handle_event({:key, :home}, assigns) do
    scroll_to(assigns, 0)
  end

  def handle_event({:key, :end}, assigns) do
    scroll_to(assigns, max_offset(assigns))
  end

  def handle_event({:mouse, :scroll_up, _col, _row}, assigns) do
    scroll_by(assigns, -1)
  end

  def handle_event({:mouse, :scroll_down, _col, _row}, assigns) do
    scroll_by(assigns, 1)
  end

  def handle_event({:mouse, :scroll_up, _col, _row, _mods}, assigns) do
    scroll_by(assigns, -1)
  end

  def handle_event({:mouse, :scroll_down, _col, _row, _mods}, assigns) do
    scroll_by(assigns, 1)
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # -- Private helpers --

  defp scroll_by(assigns, delta) do
    scroll_to(assigns, assigns.scroll_offset + delta)
  end

  defp scroll_to(assigns, target) do
    max = max_offset(assigns)
    new_offset = clamp(target, 0, max)

    if new_offset != assigns.scroll_offset do
      new_assigns = assign(assigns, :scroll_offset, new_offset)
      notify_parent(new_assigns, new_offset)
      {:noreply, new_assigns}
    else
      {:noreply, assigns}
    end
  end

  defp max_offset(assigns) do
    content_h = assigns.content_height || length(assigns.inner_block)
    max(0, content_h - assigns.height)
  end

  defp clamp(value, min_val, max_val) do
    value |> max(min_val) |> min(max_val)
  end

  defp notify_parent(assigns, offset) do
    if assigns.on_scroll && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_scroll, offset})
    end
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, key, val), do: Keyword.put(opts, key, val)
end
