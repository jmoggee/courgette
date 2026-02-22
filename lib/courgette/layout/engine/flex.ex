defmodule Courgette.Layout.Engine.Flex do
  @moduledoc """
  CSS Flexbox layout algorithm.

  Implements the 15-step flexbox layout algorithm following CSS Flexbox
  spec sections 9.1–9.6, using Taffy (Rust) as the correctness reference.

  All computation uses floats internally. The caller (Engine) converts to
  integer Bounds at the boundary via the Round module.

  Coordinates are parent-relative — the Engine converts to absolute.
  """

  alias Courgette.Layout.Engine.Geometry
  alias Courgette.Layout.Engine.Style
  alias Courgette.Layout.Engine.Text

  @doc """
  Computes flexbox layout for an element tree.

  Returns a layout tree of `%{element, x, y, width, height, children}` maps
  with parent-relative float coordinates.

  `available` is a `%{width: float | nil, height: float | nil}` representing
  the space available to the root container.
  """
  @spec layout(Courgette.Element.t(), Geometry.size()) :: map()
  def layout(element, available) do
    style = Style.from_element(element)
    compute_node(element, style, available)
  end

  # ── Node dispatch ─────────────────────────────────────────────────

  defp compute_node(element, style, available) do
    case element.type do
      :text ->
        compute_text_leaf(element, style, available)

      _ ->
        compute_flex_container(element, style, available)
    end
  end

  # ── Text leaf ─────────────────────────────────────────────────────

  defp compute_text_leaf(element, style, available) do
    text = element.children |> Enum.filter(&is_binary/1) |> Enum.join()

    border_h = Geometry.rect_horizontal(style.border)
    border_v = Geometry.rect_vertical(style.border)
    padding_h = Geometry.rect_horizontal(style.padding)
    padding_v = Geometry.rect_vertical(style.padding)

    inset_h = border_h + padding_h
    inset_v = border_v + padding_v

    # Determine width constraint for text measurement
    width_constraint =
      cond do
        style.width != nil -> style.width - inset_h
        available.width != nil -> available.width - inset_h
        true -> nil
      end

    width_constraint = if width_constraint != nil, do: max(width_constraint, 0.0), else: nil

    overflow =
      case style.overflow do
        :visible -> :word_wrap
        other -> other
      end

    {text_w, text_h} = Text.measure(text, width_constraint, overflow)

    inner_w = if style.width != nil, do: style.width - inset_h, else: text_w
    inner_h = if style.height != nil, do: style.height - inset_v, else: text_h

    w = max(inner_w + inset_h, 0.0)
    h = max(inner_h + inset_v, 0.0)

    # Apply min/max
    w = Geometry.maybe_clamp(w, style.min_width, style.max_width)
    h = Geometry.maybe_clamp(h, style.min_height, style.max_height)

    %{
      element: element,
      x: 0.0,
      y: 0.0,
      width: w,
      height: h,
      children: []
    }
  end

  # ── Flex container ────────────────────────────────────────────────

  defp compute_flex_container(element, style, available) do
    axis = style.flex_direction

    border = style.border
    padding = style.padding
    margin = style.margin

    # Total insets per axis
    inset_main = Geometry.main_inset(axis, border) + Geometry.main_inset(axis, padding)
    inset_cross = Geometry.cross_inset(axis, border) + Geometry.cross_inset(axis, padding)

    # Resolve outer container size (from style or available)
    container_width = style.width || available.width
    container_height = style.height || available.height
    container_size = %{width: container_width, height: container_height}

    outer_main = Geometry.main(axis, container_size)
    outer_cross = Geometry.cross(axis, container_size)

    # Inner space = outer - insets
    inner_main = Geometry.maybe_sub_definite(outer_main, inset_main)
    inner_cross = Geometry.maybe_sub_definite(outer_cross, inset_cross)

    inner_available = Geometry.from_main_cross(axis, inner_main, inner_cross)

    # Step 1: Generate flex items
    items = generate_flex_items(element.children, axis, inner_available)

    # Step 2-3: Determine flex base sizes
    items = determine_flex_base_sizes(items, axis, inner_available)

    # Step 4: Collect flex lines
    lines = collect_flex_lines(items, style, axis, inner_main)

    # Step 5: Determine container main size
    {container_main_inner, lines} = determine_container_main_size(lines, style, axis, inner_main)

    # Step 6: Resolve flexible lengths
    lines = resolve_flexible_lengths(lines, axis, container_main_inner, style.gap_main)

    # Step 7: Determine hypothetical cross sizes
    lines = determine_hypothetical_cross_sizes(lines, axis, inner_available)

    # Step 8: Calculate line cross sizes
    lines = calculate_line_cross_sizes(lines, axis)

    # Step 9: Handle align-content: stretch
    container_cross_inner = Geometry.or_else(inner_cross, 0.0)
    lines = handle_align_content_stretch(lines, style, container_cross_inner)

    # Step 10: Determine used cross sizes (align-self: stretch)
    lines = determine_used_cross_sizes(lines, axis, style)

    # Step 11: Distribute remaining free space (justify-content)
    lines = distribute_remaining_free_space(lines, style, axis, container_main_inner)

    # Step 12: Resolve cross-axis alignment (align-items/self)
    lines = resolve_cross_axis_alignment(lines, axis, style)

    # Step 13: Determine final container cross size
    container_cross_inner =
      if inner_cross != nil do
        inner_cross
      else
        total_line_cross = lines |> Enum.map(& &1.cross_size) |> Enum.sum()
        gap_cross_total = max(length(lines) - 1, 0) * style.gap_cross
        total_line_cross + gap_cross_total
      end

    # Step 14: Align flex lines (align-content)
    lines = align_flex_lines(lines, style, container_cross_inner)

    # Step 15: Final layout — compute x/y from main/cross offsets
    children = final_layout_pass(lines, axis, style)

    # Compute final container outer size
    final_main = container_main_inner + inset_main
    final_cross = container_cross_inner + inset_cross

    # Apply min/max to container
    final_size = Geometry.from_main_cross(axis, final_main, final_cross)
    final_w = Geometry.maybe_clamp(final_size.width, style.min_width, style.max_width)
    final_h = Geometry.maybe_clamp(final_size.height, style.min_height, style.max_height)

    # Apply margin to position
    margin_left = margin.left
    margin_top = margin.top

    %{
      element: element,
      x: margin_left,
      y: margin_top,
      width: final_w,
      height: final_h,
      children: children
    }
  end

  # ── Step 1: Generate flex items ───────────────────────────────────

  defp generate_flex_items(children, axis, _available) do
    children
    |> Enum.filter(fn
      child when is_binary(child) -> false
      _ -> true
    end)
    |> Enum.map(fn child ->
      style = Style.from_element(child)

      margin_main = Geometry.main_inset(axis, style.margin)
      margin_cross = Geometry.cross_inset(axis, style.margin)

      %{
        element: child,
        style: style,
        flex_basis: 0.0,
        inner_flex_basis: 0.0,
        hypothetical_inner_size: Geometry.size_none(),
        hypothetical_outer_size: Geometry.size_none(),
        target_size: Geometry.size(0.0, 0.0),
        outer_target_size: Geometry.size(0.0, 0.0),
        min_size: %{
          width: style.min_width,
          height: style.min_height
        },
        max_size: %{
          width: style.max_width,
          height: style.max_height
        },
        margin_main: margin_main,
        margin_cross: margin_cross,
        violation: 0.0,
        frozen: false,
        offset_main: 0.0,
        offset_cross: 0.0
      }
    end)
  end

  # ── Steps 2-3: Flex base sizes ────────────────────────────────────

  defp determine_flex_base_sizes(items, axis, available) do
    Enum.map(items, fn item ->
      style = item.style

      border_main = Geometry.main_inset(axis, style.border)
      padding_main = Geometry.main_inset(axis, style.padding)
      content_box_inset = border_main + padding_main

      border_cross = Geometry.cross_inset(axis, style.border)
      padding_cross = Geometry.cross_inset(axis, style.padding)
      content_box_inset_cross = border_cross + padding_cross

      # Determine flex basis
      flex_basis =
        case style.flex_basis do
          :auto ->
            # Use the main-axis size if set, otherwise compute from content
            main_size = Geometry.main(axis, %{width: style.width, height: style.height})

            if main_size != nil do
              main_size
            else
              # Compute intrinsic size
              intrinsic = compute_intrinsic_main(item.element, style, axis, available)
              intrinsic
            end

          value when is_number(value) ->
            # Explicit flex-basis — this is a content-box value, add insets
            value + content_box_inset
        end

      inner_flex_basis = max(flex_basis - content_box_inset, 0.0)

      # Hypothetical main size = flex_basis clamped to min/max
      # CSS automatic minimum size: if no explicit min is set, use content min size
      explicit_min_main = Geometry.main(axis, item.min_size)
      max_main = Geometry.main(axis, item.max_size)

      min_main =
        if explicit_min_main != nil do
          explicit_min_main
        else
          # CSS automatic minimum size:
          # - If item has specified main size: min(specified, content_min)
          # - Otherwise: content_min
          content_min = compute_content_min_main(item.element, style, axis, available)
          specified_main = Geometry.main(axis, %{width: style.width, height: style.height})

          if specified_main != nil do
            min(specified_main, content_min)
          else
            content_min
          end
        end

      hyp_inner_main = Geometry.maybe_clamp(inner_flex_basis, min_main, max_main)
      hyp_outer_main = hyp_inner_main + content_box_inset + item.margin_main

      # Cross size — use explicit if set, otherwise will be computed later
      cross_size = Geometry.cross(axis, %{width: style.width, height: style.height})

      hyp_inner_cross =
        if cross_size != nil do
          max(cross_size - content_box_inset_cross, 0.0)
        else
          nil
        end

      hyp_outer_cross =
        Geometry.maybe_add_definite(
          Geometry.maybe_add_definite(hyp_inner_cross, content_box_inset_cross),
          item.margin_cross
        )

      item
      |> Map.put(:flex_basis, flex_basis)
      |> Map.put(:inner_flex_basis, inner_flex_basis)
      |> Map.put(:resolved_min_main, min_main)
      |> Map.put(
        :hypothetical_inner_size,
        Geometry.set_main(
          axis,
          Geometry.set_cross(axis, item.hypothetical_inner_size, hyp_inner_cross),
          hyp_inner_main
        )
      )
      |> Map.put(
        :hypothetical_outer_size,
        Geometry.set_main(
          axis,
          Geometry.set_cross(axis, item.hypothetical_outer_size, hyp_outer_cross),
          hyp_outer_main
        )
      )
    end)
  end

  defp compute_intrinsic_main(element, style, axis, available) do
    border_main = Geometry.main_inset(axis, style.border)
    padding_main = Geometry.main_inset(axis, style.padding)
    content_box_inset = border_main + padding_main

    case element.type do
      :text ->
        text = element.children |> Enum.filter(&is_binary/1) |> Enum.join()

        _cross_size = Geometry.cross(axis, %{width: style.width, height: style.height})
        main_constraint = Geometry.main(axis, available)

        constraint =
          if main_constraint != nil do
            max(main_constraint - content_box_inset, 0.0)
          else
            nil
          end

        overflow =
          case style.overflow do
            :visible -> :word_wrap
            other -> other
          end

        {text_w, text_h} = Text.measure(text, constraint, overflow)

        case axis do
          :row -> text_w + content_box_inset
          :column -> text_h + content_box_inset
        end

      _ ->
        # For container children, compute max-content size (unconstrained main axis)
        max_content_available =
          case axis do
            :row -> %{width: nil, height: available.height}
            :column -> %{width: available.width, height: nil}
          end

        child_result = compute_node(element, style, max_content_available)

        case axis do
          :row -> child_result.width
          :column -> child_result.height
        end
    end
  end

  # Compute automatic minimum main size (CSS "implied minimum main size")
  # This computes the minimum size based on CONTENT only, ignoring explicit main size.
  #
  # For text: uses min-content width (longest word) or 0 for truncated text.
  # For containers: recursively computes min-content sizes of children and
  # aggregates based on flex direction (sum for main axis, max for cross axis).
  defp compute_content_min_main(element, style, axis, _available) do
    border_main = Geometry.main_inset(axis, style.border)
    padding_main = Geometry.main_inset(axis, style.padding)
    content_box_inset = border_main + padding_main

    case element.type do
      :text ->
        text = element.children |> Enum.filter(&is_binary/1) |> Enum.join()

        min_w =
          case style.overflow do
            :truncate -> 0.0
            _ -> Text.min_content_width(text)
          end

        case axis do
          :row -> min_w + content_box_inset
          :column -> if text == "", do: 0.0, else: 1.0 + content_box_inset
        end

      _ ->
        children =
          element.children
          |> Enum.filter(fn
            child when is_binary(child) -> false
            _ -> true
          end)

        if children == [] do
          # Empty container — content minimum is just border + padding
          content_box_inset
        else
          # Recursively compute each child's min-content size in the requested axis.
          # If a child has an explicit size in the measured axis, use that directly
          # (its specified size IS its min-content contribution).
          child_mins =
            Enum.map(children, fn child ->
              child_style = Style.from_element(child)

              margin_in_axis =
                case axis do
                  :row -> Geometry.rect_horizontal(child_style.margin)
                  :column -> Geometry.rect_vertical(child_style.margin)
                end

              explicit_size =
                case axis do
                  :row -> child_style.width
                  :column -> child_style.height
                end

              child_min =
                if explicit_size != nil do
                  explicit_size
                else
                  compute_content_min_main(child, child_style, axis, %{width: nil, height: nil})
                end

              child_min + margin_in_axis
            end)

          # Aggregate based on whether the container's flex direction aligns with
          # the axis we're measuring:
          #   Same axis (main) → children stack along it → sum (no-wrap) or max (wrap)
          #   Cross axis       → children stack perpendicular → max
          same_axis = axis == style.flex_direction

          children_contribution =
            if same_axis do
              gap_total = max(length(child_mins) - 1, 0) * style.gap_main

              if style.flex_wrap == :wrap do
                Enum.max(child_mins)
              else
                Enum.sum(child_mins) + gap_total
              end
            else
              Enum.max(child_mins)
            end

          children_contribution + content_box_inset
        end
    end
  end

  # ── Step 4: Collect flex lines ────────────────────────────────────

  defp collect_flex_lines(items, style, axis, inner_main) do
    case style.flex_wrap do
      :no_wrap ->
        [%{items: items, cross_size: 0.0, offset_cross: 0.0}]

      :wrap ->
        if inner_main == nil or items == [] do
          [%{items: items, cross_size: 0.0, offset_cross: 0.0}]
        else
          do_collect_lines(items, axis, inner_main, style.gap_main)
        end
    end
  end

  defp do_collect_lines(items, axis, max_main, gap) do
    {lines, current_items, _current_main} =
      Enum.reduce(items, {[], [], 0.0}, fn item, {lines, current, current_main} ->
        hyp_main = Geometry.main(axis, item.hypothetical_outer_size) || 0.0

        item_with_gap =
          if current == [] do
            hyp_main
          else
            hyp_main + gap
          end

        if current != [] and current_main + item_with_gap > max_main do
          # Start new line
          {[%{items: Enum.reverse(current), cross_size: 0.0, offset_cross: 0.0} | lines],
           [item], hyp_main}
        else
          {lines, [item | current], current_main + item_with_gap}
        end
      end)

    lines =
      if current_items != [] do
        [%{items: Enum.reverse(current_items), cross_size: 0.0, offset_cross: 0.0} | lines]
      else
        lines
      end

    Enum.reverse(lines)
  end

  # ── Step 5: Determine container main size ─────────────────────────

  defp determine_container_main_size(lines, style, axis, inner_main) do
    if inner_main != nil do
      {inner_main, lines}
    else
      # Sum hypothetical main sizes + gaps
      container_main =
        lines
        |> Enum.map(fn line ->
          item_sum =
            line.items
            |> Enum.map(fn item -> Geometry.main(axis, item.hypothetical_outer_size) || 0.0 end)
            |> Enum.sum()

          gap_sum = max(length(line.items) - 1, 0) * style.gap_main
          item_sum + gap_sum
        end)
        |> Enum.max(fn -> 0.0 end)

      # Clamp to min/max
      min_main = Geometry.main(axis, %{width: style.min_width, height: style.min_height})
      max_main = Geometry.main(axis, %{width: style.max_width, height: style.max_height})

      inset_main =
        Geometry.main_inset(axis, style.border) + Geometry.main_inset(axis, style.padding)

      container_main =
        Geometry.maybe_clamp(
          container_main,
          Geometry.maybe_sub_definite(min_main, inset_main),
          Geometry.maybe_sub_definite(max_main, inset_main)
        )

      {container_main, lines}
    end
  end

  # ── Step 6: Resolve flexible lengths ──────────────────────────────

  defp resolve_flexible_lengths(lines, axis, container_main, gap_main) do
    Enum.map(lines, fn line ->
      items = resolve_line_flex(line.items, axis, container_main, gap_main)
      %{line | items: items}
    end)
  end

  defp resolve_line_flex(items, axis, container_main, gap_main) do
    if items == [] do
      items
    else
      # Calculate initial free space (subtract gaps)
      used =
        Enum.reduce(items, 0.0, fn item, acc ->
          acc + (Geometry.main(axis, item.hypothetical_outer_size) || 0.0)
        end)

      total_gap = max(length(items) - 1, 0) * gap_main
      initial_free = container_main - used - total_gap
      growing = initial_free >= 0

      # Initialize: set target to hypothetical, freeze inflexible items
      items =
        Enum.map(items, fn item ->
          style = item.style
          hyp_inner = Geometry.main(axis, item.hypothetical_inner_size) || 0.0

          border_main = Geometry.main_inset(axis, style.border)
          padding_main = Geometry.main_inset(axis, style.padding)
          content_box_inset = border_main + padding_main

          freeze =
            cond do
              growing and style.flex_grow == 0.0 -> true
              not growing and style.flex_shrink == 0.0 -> true
              true -> false
            end

          target = if freeze, do: hyp_inner, else: item.inner_flex_basis

          item
          |> Map.put(:frozen, freeze)
          |> Map.put(:target_size, Geometry.set_main(axis, item.target_size, target))
          |> Map.put(
            :outer_target_size,
            Geometry.set_main(axis, item.outer_target_size, target + content_box_inset + item.margin_main)
          )
          |> Map.put(:content_box_inset, content_box_inset)
        end)

      # Iterative resolution
      do_resolve_flex(items, axis, container_main, growing, total_gap, 10)
    end
  end

  defp do_resolve_flex(items, axis, container_main, growing, total_gap, iterations_left) do
    all_frozen = Enum.all?(items, & &1.frozen)

    if all_frozen or iterations_left <= 0 do
      finalize_flex_items(items, axis)
    else
      # Calculate free space among unfrozen items
      {frozen_space, unfrozen_flex_factor, unfrozen_items} =
        Enum.reduce(items, {0.0, 0.0, []}, fn item, {fs, ff, ui} ->
          if item.frozen do
            outer = Geometry.main(axis, item.outer_target_size) || 0.0
            {fs + outer, ff, ui}
          else
            factor = if growing, do: item.style.flex_grow, else: item.style.flex_shrink
            {fs, ff + factor, [item | ui]}
          end
        end)

      unfrozen_items = Enum.reverse(unfrozen_items)
      free_space = container_main - frozen_space - total_gap

      # Distribute free space to unfrozen items
      items =
        Enum.map(items, fn item ->
          if item.frozen do
            item
          else
            factor = if growing, do: item.style.flex_grow, else: item.style.flex_shrink

            new_target =
              if unfrozen_flex_factor == 0.0 do
                item.inner_flex_basis
              else
                if growing do
                  ratio = factor / unfrozen_flex_factor

                  # Free space relative to unfrozen bases
                  unfrozen_bases =
                    Enum.reduce(unfrozen_items, 0.0, fn ui, acc ->
                      acc + ui.inner_flex_basis + ui.content_box_inset + ui.margin_main
                    end)

                  item.inner_flex_basis + (free_space - unfrozen_bases) * ratio
                else
                  # Shrink
                  scaled_factor = item.inner_flex_basis * factor

                  total_scaled =
                    Enum.reduce(unfrozen_items, 0.0, fn ui, acc ->
                      acc + ui.inner_flex_basis * ui.style.flex_shrink
                    end)

                  if total_scaled == 0.0 do
                    item.inner_flex_basis
                  else
                    ratio = scaled_factor / total_scaled

                    unfrozen_bases =
                      Enum.reduce(unfrozen_items, 0.0, fn ui, acc ->
                        acc + ui.inner_flex_basis + ui.content_box_inset + ui.margin_main
                      end)

                    item.inner_flex_basis + (free_space - unfrozen_bases) * ratio
                  end
                end
              end

            new_target = max(new_target, 0.0)
            Map.put(item, :target_size, Geometry.set_main(axis, item.target_size, new_target))
          end
        end)

      # Clamp and check violations
      items =
        Enum.map(items, fn item ->
          if item.frozen do
            item
          else
            target = Geometry.main(axis, item.target_size) || 0.0
            # Use resolved min (includes automatic minimum from content)
            min_main = Map.get(item, :resolved_min_main) || Geometry.main(axis, item.min_size)
            max_main = Geometry.main(axis, item.max_size)
            min_inner = Geometry.maybe_sub_definite(min_main, item.content_box_inset)
            max_inner = Geometry.maybe_sub_definite(max_main, item.content_box_inset)

            clamped = Geometry.maybe_clamp(target, min_inner, max_inner)
            violation = clamped - target

            item
            |> Map.put(:target_size, Geometry.set_main(axis, item.target_size, clamped))
            |> Map.put(:violation, violation)
          end
        end)

      # Freeze items based on violations
      total_violation =
        items
        |> Enum.reject(& &1.frozen)
        |> Enum.map(& &1.violation)
        |> Enum.sum()

      items =
        Enum.map(items, fn item ->
          if item.frozen do
            item
          else
            should_freeze =
              cond do
                total_violation > 0.0 -> item.violation > 0.0
                total_violation < 0.0 -> item.violation < 0.0
                true -> true
              end

            if should_freeze do
              target = Geometry.main(axis, item.target_size) || 0.0

              item
              |> Map.put(:frozen, true)
              |> Map.put(
                :outer_target_size,
                Geometry.set_main(axis, item.outer_target_size, target + item.content_box_inset + item.margin_main)
              )
            else
              item
            end
          end
        end)

      do_resolve_flex(items, axis, container_main, growing, total_gap, iterations_left - 1)
    end
  end

  defp finalize_flex_items(items, axis) do
    Enum.map(items, fn item ->
      target = Geometry.main(axis, item.target_size) || 0.0

      content_box_inset = Map.get(item, :content_box_inset, 0.0)

      item
      |> Map.put(
        :outer_target_size,
        Geometry.set_main(axis, item.outer_target_size, target + content_box_inset + item.margin_main)
      )
      |> Map.delete(:content_box_inset)
    end)
  end

  # ── Step 7: Hypothetical cross sizes ──────────────────────────────

  defp determine_hypothetical_cross_sizes(lines, axis, available) do
    Enum.map(lines, fn line ->
      items =
        Enum.map(line.items, fn item ->
          cross_size = Geometry.cross(axis, item.hypothetical_inner_size)

          if cross_size != nil do
            # Already has explicit cross size
            item
          else
            # Compute cross size by laying out at resolved main size
            resolved_main = Geometry.main(axis, item.target_size) || 0.0
            cross = compute_item_cross_size(item, axis, resolved_main, available)

            style = item.style
            border_cross = Geometry.cross_inset(axis, style.border)
            padding_cross = Geometry.cross_inset(axis, style.padding)
            content_box_inset_cross = border_cross + padding_cross

            # Clamp cross to min/max
            min_cross = Geometry.cross(axis, item.min_size)
            max_cross = Geometry.cross(axis, item.max_size)
            min_inner = Geometry.maybe_sub_definite(min_cross, content_box_inset_cross)
            max_inner = Geometry.maybe_sub_definite(max_cross, content_box_inset_cross)
            cross = Geometry.maybe_clamp(cross, min_inner, max_inner)

            outer_cross = cross + content_box_inset_cross + item.margin_cross

            item
            |> Map.put(
              :hypothetical_inner_size,
              Geometry.set_cross(axis, item.hypothetical_inner_size, cross)
            )
            |> Map.put(
              :hypothetical_outer_size,
              Geometry.set_cross(axis, item.hypothetical_outer_size, outer_cross)
            )
          end
        end)

      %{line | items: items}
    end)
  end

  defp compute_item_cross_size(item, axis, resolved_main, available) do
    style = item.style

    border_main = Geometry.main_inset(axis, style.border)
    padding_main = Geometry.main_inset(axis, style.padding)
    border_cross = Geometry.cross_inset(axis, style.border)
    padding_cross = Geometry.cross_inset(axis, style.padding)

    inner_main = max(resolved_main - border_main - padding_main, 0.0)

    case item.element.type do
      :text ->
        text = item.element.children |> Enum.filter(&is_binary/1) |> Enum.join()

        overflow =
          case style.overflow do
            :visible -> :word_wrap
            other -> other
          end

        constraint =
          case axis do
            :row -> inner_main
            :column -> if available.width != nil, do: max(available.width - border_cross - padding_cross, 0.0), else: nil
          end

        {text_w, text_h} = Text.measure(text, constraint, overflow)

        case axis do
          :row -> text_h
          :column -> text_w
        end

      _ ->
        # For container children, lay out recursively
        child_available =
          case axis do
            :row -> %{width: resolved_main, height: available.height}
            :column -> %{width: available.width, height: resolved_main}
          end

        child_result = compute_node(item.element, style, child_available)

        case axis do
          :row -> child_result.height - border_cross - padding_cross
          :column -> child_result.width - border_cross - padding_cross
        end
    end
  end

  # ── Step 8: Calculate line cross sizes ────────────────────────────

  defp calculate_line_cross_sizes(lines, axis) do
    Enum.map(lines, fn line ->
      if line.items == [] do
        line
      else
        max_cross =
          line.items
          |> Enum.map(fn item ->
            Geometry.cross(axis, item.hypothetical_outer_size) || 0.0
          end)
          |> Enum.max(fn -> 0.0 end)

        %{line | cross_size: max_cross}
      end
    end)
  end

  # ── Step 9: align-content: stretch ────────────────────────────────

  defp handle_align_content_stretch(lines, style, container_cross) do
    if style.align_content == :stretch and length(lines) > 0 do
      total_line_cross = lines |> Enum.map(& &1.cross_size) |> Enum.sum()
      gap_total = max(length(lines) - 1, 0) * style.gap_cross
      free = container_cross - total_line_cross - gap_total

      if free > 0 do
        extra_per_line = free / length(lines)

        Enum.map(lines, fn line ->
          %{line | cross_size: line.cross_size + extra_per_line}
        end)
      else
        lines
      end
    else
      lines
    end
  end

  # ── Step 10: Used cross sizes (align-self: stretch) ───────────────

  defp determine_used_cross_sizes(lines, axis, container_style) do
    Enum.map(lines, fn line ->
      items =
        Enum.map(line.items, fn item ->
          align = resolve_align_self(item.style, container_style)

          if align == :stretch do
            style = item.style
            border_cross = Geometry.cross_inset(axis, style.border)
            padding_cross = Geometry.cross_inset(axis, style.padding)
            cross_inset = border_cross + padding_cross

            # Stretch to fill line cross size minus margins
            target_cross = max(line.cross_size - item.margin_cross - cross_inset, 0.0)

            # Clamp to min/max
            min_cross = Geometry.cross(axis, item.min_size)
            max_cross = Geometry.cross(axis, item.max_size)
            min_inner = Geometry.maybe_sub_definite(min_cross, cross_inset)
            max_inner = Geometry.maybe_sub_definite(max_cross, cross_inset)
            target_cross = Geometry.maybe_clamp(target_cross, min_inner, max_inner)

            # Only stretch if no explicit cross size is set
            explicit_cross = Geometry.cross(axis, %{width: item.style.width, height: item.style.height})

            if explicit_cross == nil do
              item
              |> Map.put(:target_size, Geometry.set_cross(axis, item.target_size, target_cross))
              |> Map.put(
                :outer_target_size,
                Geometry.set_cross(axis, item.outer_target_size, target_cross + cross_inset + item.margin_cross)
              )
            else
              # Use explicit cross size
              inner = max(explicit_cross - cross_inset, 0.0)

              item
              |> Map.put(:target_size, Geometry.set_cross(axis, item.target_size, inner))
              |> Map.put(
                :outer_target_size,
                Geometry.set_cross(axis, item.outer_target_size, inner + cross_inset + item.margin_cross)
              )
            end
          else
            # Non-stretch: use hypothetical cross size
            hyp_cross = Geometry.cross(axis, item.hypothetical_inner_size) || 0.0

            style = item.style
            border_cross = Geometry.cross_inset(axis, style.border)
            padding_cross = Geometry.cross_inset(axis, style.padding)
            cross_inset = border_cross + padding_cross

            item
            |> Map.put(:target_size, Geometry.set_cross(axis, item.target_size, hyp_cross))
            |> Map.put(
              :outer_target_size,
              Geometry.set_cross(
                axis,
                item.outer_target_size,
                hyp_cross + cross_inset + item.margin_cross
              )
            )
          end
        end)

      %{line | items: items}
    end)
  end

  defp resolve_align_self(item_style, container_style) do
    case item_style.align_self do
      :auto -> container_style.align_items
      other -> other
    end
  end

  # ── Step 11: Justify content ──────────────────────────────────────

  defp distribute_remaining_free_space(lines, style, axis, container_main) do
    Enum.map(lines, fn line ->
      items = line.items
      n = length(items)

      if n == 0 do
        line
      else
        used =
          Enum.reduce(items, 0.0, fn item, acc ->
            acc + (Geometry.main(axis, item.outer_target_size) || 0.0)
          end)

        gap_total = max(n - 1, 0) * style.gap_main
        free = container_main - used - gap_total

        {initial_offset, between_offset} =
          case style.justify_content do
            :flex_start -> {0.0, 0.0}
            :flex_end -> {max(free, 0.0), 0.0}
            :center -> {max(free / 2, 0.0), 0.0}
            :space_between ->
              if n <= 1, do: {0.0, 0.0}, else: {0.0, max(free, 0.0) / (n - 1)}
            :space_around ->
              if n == 0, do: {0.0, 0.0}, else: {max(free, 0.0) / (n * 2), max(free, 0.0) / n}
            :space_evenly ->
              if n == 0, do: {0.0, 0.0}, else: {max(free, 0.0) / (n + 1), max(free, 0.0) / (n + 1)}
          end

        {items, _} =
          Enum.map_reduce(items, initial_offset, fn item, offset ->
            item = Map.put(item, :offset_main, offset)
            next = offset + (Geometry.main(axis, item.outer_target_size) || 0.0) + between_offset + style.gap_main
            {item, next}
          end)

        %{line | items: items}
      end
    end)
  end

  # ── Step 12: Cross-axis alignment ─────────────────────────────────

  defp resolve_cross_axis_alignment(lines, axis, container_style) do
    Enum.map(lines, fn line ->
      items =
        Enum.map(line.items, fn item ->
          align = resolve_align_self(item.style, container_style)
          outer_cross = Geometry.cross(axis, item.outer_target_size) || 0.0
          line_cross = line.cross_size

          offset =
            case align do
              :flex_start -> 0.0
              :flex_end -> max(line_cross - outer_cross, 0.0)
              :center -> max((line_cross - outer_cross) / 2, 0.0)
              :stretch -> 0.0
              :baseline -> 0.0
            end

          # Add margin start to cross offset
          margin_cross_start = Geometry.cross_start(axis, item.style.margin)
          Map.put(item, :offset_cross, offset + margin_cross_start)
        end)

      %{line | items: items}
    end)
  end

  # ── Step 14: Align flex lines ─────────────────────────────────────

  defp align_flex_lines(lines, style, container_cross) do
    n = length(lines)
    total_cross = lines |> Enum.map(& &1.cross_size) |> Enum.sum()
    gap_total = max(n - 1, 0) * style.gap_cross
    free = container_cross - total_cross - gap_total

    {initial_offset, between_offset} =
      case style.align_content do
        :flex_start -> {0.0, 0.0}
        :flex_end -> {max(free, 0.0), 0.0}
        :center -> {max(free / 2, 0.0), 0.0}
        :stretch -> {0.0, 0.0}
        :space_between ->
          if n <= 1, do: {0.0, 0.0}, else: {0.0, max(free, 0.0) / (n - 1)}
        :space_around ->
          if n == 0, do: {0.0, 0.0}, else: {max(free, 0.0) / (n * 2), max(free, 0.0) / n}
      end

    {lines, _} =
      Enum.map_reduce(lines, initial_offset, fn line, offset ->
        line = %{line | offset_cross: offset}
        next = offset + line.cross_size + between_offset + style.gap_cross
        {line, next}
      end)

    lines
  end

  # ── Step 15: Final layout pass ────────────────────────────────────

  defp final_layout_pass(lines, axis, style) do
    border = style.border
    padding = style.padding

    # Content area starts after border + padding
    content_start_main = Geometry.main_start(axis, border) + Geometry.main_start(axis, padding)
    content_start_cross = Geometry.cross_start(axis, border) + Geometry.cross_start(axis, padding)

    Enum.flat_map(lines, fn line ->
      Enum.map(line.items, fn item ->
        # Main/cross offsets → x/y
        main_pos = content_start_main + item.offset_main +
          Geometry.main_start(axis, item.style.margin)
        cross_pos = content_start_cross + line.offset_cross + item.offset_cross

        {x, y} =
          case axis do
            :row -> {main_pos, cross_pos}
            :column -> {cross_pos, main_pos}
          end

        target_main = Geometry.main(axis, item.target_size) || 0.0
        target_cross = Geometry.cross(axis, item.target_size) || 0.0

        item_style = item.style
        border_main = Geometry.main_inset(axis, item_style.border)
        padding_main = Geometry.main_inset(axis, item_style.padding)
        border_cross = Geometry.cross_inset(axis, item_style.border)
        padding_cross = Geometry.cross_inset(axis, item_style.padding)

        outer_main = target_main + border_main + padding_main
        outer_cross = target_cross + border_cross + padding_cross

        {w, h} =
          case axis do
            :row -> {outer_main, outer_cross}
            :column -> {outer_cross, outer_main}
          end

        # Recurse into children
        child_available = %{width: w, height: h}
        children = layout_children(item.element, item_style, child_available)

        %{
          element: item.element,
          x: x,
          y: y,
          width: w,
          height: h,
          children: children
        }
      end)
    end)
  end

  defp layout_children(element, _style, _available) when element.type == :text do
    []
  end

  defp layout_children(element, style, available) when element.type == :scrollable_area do
    if element.children == [] do
      []
    else
      # Children flow in a column with unlimited height
      scroll_style = %{style | flex_direction: :column, height: nil, min_height: nil, max_height: nil}
      content_available = %{width: available.width, height: nil}
      result = compute_flex_container(element, scroll_style, content_available)
      result.children
    end
  end

  defp layout_children(element, style, available) do
    if element.children == [] do
      []
    else
      # Lay out children as a nested flex container
      _child_axis = style.flex_direction

      result = compute_flex_container(element, style, available)
      result.children
    end
  end
end
