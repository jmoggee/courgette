defmodule Courgette.Painter do
  @moduledoc """
  Traverses a layout tree and paints into a Buffer.

  The Painter receives pre-resolved layout — a tree of `LayoutNode` maps
  where each node has an `element`, `bounds`, and `children`. It doesn't
  compute layout; it only paints.

  ## Layout Node

  A layout node is a map (not a struct, to keep it simple until the
  layout engine solidifies):

      %{
        element: %Element{type: :box, props: %{border: :single}, ...},
        bounds: %Bounds{x: 0, y: 0, width: 40, height: 12},
        children: [%{element: ..., bounds: ..., children: ...}]
      }

  ## What Painter Handles

  - **Text painting** — `:text` elements with string children. Applies
    fg, bg, bold/italic/etc from props via `Buffer.put_string/5`.
  - **Box background** — fills the bounds area with the `bg` color.
  - **Borders** — `:single`, `:double`, `:rounded` border styles with
    `border_color`.
  - **Recursive children** — depth-first traversal.
  - **Clipping** — children outside their parent's bounds are not painted.

  ## What Painter Does NOT Handle

  - Text wrapping/truncation (needs layout engine)
  - Padding offset computation (layout's job)
  """

  alias Courgette.Buffer
  alias Courgette.Buffer.Cell
  alias Courgette.Element
  alias Courgette.Layout.Bounds

  @border_chars %{
    single: %{tl: "┌", tr: "┐", bl: "└", br: "┘", h: "─", v: "│"},
    double: %{tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║"},
    rounded: %{tl: "╭", tr: "╮", bl: "╰", br: "╯", h: "─", v: "│"}
  }

  @doc """
  Paints a layout tree into a buffer.

  Takes a layout node (or `nil`) and a `%Buffer{}`. Returns the buffer
  with all elements painted.

      buffer = Buffer.new(80, 24)
      painted = Painter.paint(layout_tree, buffer)

  """
  @spec paint(map() | nil, Buffer.t()) :: Buffer.t()
  def paint(nil, buffer), do: buffer

  def paint(%{element: %Element{}, bounds: %Bounds{}} = node, %Buffer{} = buffer) do
    {cleaned_tree, absolute_nodes} = extract_absolute_nodes(node)

    # Phase 1: paint normal content with hierarchical clipping
    buffer = paint_node(cleaned_tree, buffer, nil)

    # Phase 2: paint absolute nodes on top, clipped only to screen
    screen_clip = Bounds.new(0, 0, buffer.width, buffer.height)

    Enum.reduce(absolute_nodes, buffer, fn abs_node, buf ->
      paint_node(abs_node, buf, screen_clip)
    end)
  end

  # ── Internal ──────────────────────────────────────────────────────

  defp paint_node(%{element: element, bounds: bounds, children: children}, buffer, clip) do
    effective_clip = compute_clip(bounds, clip)

    case effective_clip do
      nil ->
        buffer

      clip_rect ->
        buffer
        |> paint_element(element, bounds, clip_rect)
        |> paint_overflow(element, bounds, children, clip_rect)
    end
  end

  # Paints a node's children according to its overflow mode. :hidden and
  # :scroll both clip to the inner content box; :scroll also shifts the
  # subtree up by the current scroll offset.
  defp paint_overflow(buffer, element, bounds, children, clip) do
    case Map.get(element.props, :overflow, :visible) do
      :visible ->
        paint_children(buffer, children, clip)

      :hidden ->
        paint_clipped_children(buffer, element, bounds, children, clip)

      :scroll ->
        offset = Map.get(element.props, :scroll_offset, 0)
        paint_clipped_children(buffer, element, bounds, shift_tree(children, 0, -offset), clip)
    end
  end

  defp paint_clipped_children(buffer, element, bounds, children, clip) do
    case compute_clip(inner_content_bounds(bounds, element.props), clip) do
      nil -> buffer
      inner -> paint_children(buffer, children, inner)
    end
  end

  defp compute_clip(bounds, nil), do: bounds

  defp compute_clip(bounds, clip) do
    Bounds.intersect(bounds, clip)
  end

  # ── Element painting ──────────────────────────────────────────────

  defp paint_element(buffer, %Element{type: :box} = element, bounds, clip) do
    buffer
    |> paint_background(element.props, bounds, clip)
    |> paint_border(element.props, bounds, clip)
  end

  defp paint_element(buffer, %Element{type: :text} = element, bounds, clip) do
    paint_text(buffer, element, bounds, clip)
  end

  defp paint_element(buffer, _element, _bounds, _clip) do
    # Other element types are not yet handled
    buffer
  end

  # ── Background fill ──────────────────────────────────────────────

  defp paint_background(buffer, %{bg: bg}, bounds, clip) when not is_nil(bg) do
    fill_rect(buffer, bounds, clip, Cell.new(" ", bg: bg))
  end

  defp paint_background(buffer, _props, _bounds, _clip), do: buffer

  defp fill_rect(buffer, bounds, clip, cell) do
    for y <- bounds.y..(bounds.y + bounds.height - 1),
        x <- bounds.x..(bounds.x + bounds.width - 1),
        Bounds.contains?(clip, x, y),
        reduce: buffer do
      buf -> Buffer.put_cell(buf, x, y, cell)
    end
  end

  # ── Border drawing ───────────────────────────────────────────────

  defp paint_border(buffer, %{border: style} = props, bounds, clip)
       when is_map_key(@border_chars, style) do
    chars = @border_chars[style]
    opts = border_opts(props)

    buffer
    |> paint_corners(chars, bounds, clip, opts)
    |> paint_horizontal_edges(chars, bounds, clip, opts)
    |> paint_vertical_edges(chars, bounds, clip, opts)
  end

  defp paint_border(buffer, _props, _bounds, _clip), do: buffer

  defp border_opts(%{border_color: color}), do: [fg: color]
  defp border_opts(_props), do: []

  defp paint_corners(buffer, chars, bounds, clip, opts) do
    %{x: x, y: y, width: w, height: h} = bounds

    buffer
    |> put_if_clipped(x, y, chars.tl, clip, opts)
    |> put_if_clipped(x + w - 1, y, chars.tr, clip, opts)
    |> put_if_clipped(x, y + h - 1, chars.bl, clip, opts)
    |> put_if_clipped(x + w - 1, y + h - 1, chars.br, clip, opts)
  end

  defp paint_horizontal_edges(buffer, chars, bounds, clip, opts) do
    %{x: x, y: y, width: w, height: h} = bounds

    if w <= 2 do
      buffer
    else
      cell = Cell.new(chars.h, opts)

      Enum.reduce((x + 1)..(x + w - 2), buffer, fn col, buf ->
        buf
        |> put_cell_if_clipped(col, y, cell, clip)
        |> put_cell_if_clipped(col, y + h - 1, cell, clip)
      end)
    end
  end

  defp paint_vertical_edges(buffer, chars, bounds, clip, opts) do
    %{x: x, y: y, width: w, height: h} = bounds

    if h <= 2 do
      buffer
    else
      cell = Cell.new(chars.v, opts)

      Enum.reduce((y + 1)..(y + h - 2), buffer, fn row, buf ->
        buf
        |> put_cell_if_clipped(x, row, cell, clip)
        |> put_cell_if_clipped(x + w - 1, row, cell, clip)
      end)
    end
  end

  defp put_if_clipped(buffer, x, y, grapheme, clip, opts) do
    if Bounds.contains?(clip, x, y) do
      Buffer.put_cell(buffer, x, y, Cell.new(grapheme, opts))
    else
      buffer
    end
  end

  defp put_cell_if_clipped(buffer, x, y, cell, clip) do
    if Bounds.contains?(clip, x, y) do
      Buffer.put_cell(buffer, x, y, cell)
    else
      buffer
    end
  end

  # ── Text painting ────────────────────────────────────────────────

  defp paint_text(buffer, %Element{children: children, props: props}, bounds, clip) do
    text = children |> Enum.filter(&is_binary/1) |> Enum.join()
    opts = text_opts(props)

    # Paint text starting at bounds origin, one grapheme per cell
    text
    |> String.graphemes()
    |> Enum.with_index(bounds.x)
    |> Enum.reduce(buffer, fn {grapheme, col}, buf ->
      if Bounds.contains?(clip, col, bounds.y) do
        Buffer.put_cell(buf, col, bounds.y, Cell.new(grapheme, opts))
      else
        buf
      end
    end)
  end

  @text_prop_keys [
    :color,
    :bg,
    :bold,
    :dim,
    :italic,
    :underline,
    :strikethrough,
    :reverse,
    :blink,
    :hidden,
    :overline,
    :underline_style,
    :underline_color,
    :url
  ]

  defp text_opts(props) do
    Enum.reduce(@text_prop_keys, [], fn key, opts ->
      case Map.get(props, key) do
        nil -> opts
        value when key == :color -> [{:fg, value} | opts]
        value -> [{key, value} | opts]
      end
    end)
  end

  # ── Overflow helpers ────────────────────────────────────────────

  defp inner_content_bounds(bounds, props) do
    has_border = Map.get(props, :border) in [:single, :double, :rounded]
    inset = if has_border, do: 1, else: 0

    %Bounds{
      x: bounds.x + inset,
      y: bounds.y + inset,
      width: max(bounds.width - inset * 2, 0),
      height: max(bounds.height - inset * 2, 0)
    }
  end

  defp shift_tree(children, dx, dy) do
    Enum.map(children, fn %{bounds: %Bounds{} = bounds} = node ->
      shifted_bounds = %{bounds | x: bounds.x + dx, y: bounds.y + dy}
      shifted_children = shift_tree(node.children, dx, dy)
      %{node | bounds: shifted_bounds, children: shifted_children}
    end)
  end

  # ── Absolute node extraction ────────────────────────────────────

  defp extract_absolute_nodes(%{children: children} = node) do
    {normal, absolutes} =
      Enum.reduce(children, {[], []}, fn child, {normals, abs_acc} ->
        if child.element.props[:position] == :absolute do
          {normals, [child | abs_acc]}
        else
          {cleaned_child, nested_abs} = extract_absolute_nodes(child)
          {[cleaned_child | normals], nested_abs ++ abs_acc}
        end
      end)

    {%{node | children: Enum.reverse(normal)}, Enum.reverse(absolutes)}
  end

  # ── Children ─────────────────────────────────────────────────────

  defp paint_children(buffer, children, clip) when is_list(children) do
    Enum.reduce(children, buffer, fn child, buf ->
      paint_node(child, buf, clip)
    end)
  end

  defp paint_children(buffer, _children, _clip), do: buffer
end
