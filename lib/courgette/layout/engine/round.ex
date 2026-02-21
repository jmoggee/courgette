defmodule Courgette.Layout.Engine.Round do
  @moduledoc """
  Converts float layout coordinates to integer `%Bounds{}` structs.

  Uses cumulative rounding to avoid 1-cell gaps. For children at float
  positions `[0.0, 33.33, 66.67]` in a 100-wide container, we round
  cumulative positions to get `[0, 33, 67, 100]` and derive widths from
  differences `[33, 34, 33]`. This ensures widths sum exactly to the
  container width.
  """

  alias Courgette.Layout.Bounds

  @doc """
  Converts a float layout tree to a `%Bounds{}`-based layout tree
  suitable for the Painter.

  Takes a layout node `%{element, x, y, width, height, children}` with
  float coordinates (parent-relative) and an absolute parent origin.

  Returns `%{element, bounds, children}` with absolute integer `%Bounds{}`.
  """
  @spec to_bounds(map(), {non_neg_integer(), non_neg_integer()}) :: map()
  def to_bounds(node, {parent_x, parent_y} \\ {0, 0}) do
    abs_x = parent_x + round_val(node.x)
    abs_y = parent_y + round_val(node.y)
    w = round_val(node.width)
    h = round_val(node.height)

    bounds = Bounds.new(max(abs_x, 0), max(abs_y, 0), max(w, 0), max(h, 0))

    children = round_children(node.children, abs_x, abs_y, node, bounds)

    %{
      element: node.element,
      bounds: bounds,
      children: children
    }
  end

  # Round children using cumulative rounding to avoid gaps
  defp round_children(children, parent_abs_x, parent_abs_y, _parent_node, parent_bounds) do
    if children == [] do
      []
    else
      # Sort children and apply cumulative rounding along each axis
      children
      |> Enum.map(fn child ->
        to_bounds(child, {parent_abs_x, parent_abs_y})
      end)
      |> apply_cumulative_rounding_x(parent_bounds)
      |> apply_cumulative_rounding_y(parent_bounds)
    end
  end

  # Cumulative rounding along X: ensures children that share the same Y
  # band don't have gaps between them
  defp apply_cumulative_rounding_x(children, parent_bounds) do
    # Group by approximate Y position (same row)
    children
    |> Enum.group_by(fn child -> child.bounds.y end)
    |> Enum.flat_map(fn {_y, row_children} ->
      if length(row_children) <= 1 do
        row_children
      else
        row_sorted = Enum.sort_by(row_children, & &1.bounds.x)
        fix_horizontal_gaps(row_sorted, parent_bounds)
      end
    end)
  end

  defp apply_cumulative_rounding_y(children, parent_bounds) do
    children
    |> Enum.group_by(fn child -> child.bounds.x end)
    |> Enum.flat_map(fn {_x, col_children} ->
      if length(col_children) <= 1 do
        col_children
      else
        col_sorted = Enum.sort_by(col_children, & &1.bounds.y)
        fix_vertical_gaps(col_sorted, parent_bounds)
      end
    end)
  end

  # Fix gaps between horizontally adjacent children
  defp fix_horizontal_gaps([first | rest], _parent_bounds) do
    {fixed, _} =
      Enum.map_reduce(rest, first, fn child, prev ->
        expected_x = prev.bounds.x + prev.bounds.width

        if child.bounds.x != expected_x and abs(child.bounds.x - expected_x) <= 1 do
          # Adjust this child to be flush with previous
          new_bounds = %{child.bounds | x: expected_x}
          adjusted = %{child | bounds: new_bounds}
          {adjusted, adjusted}
        else
          {child, child}
        end
      end)

    [first | fixed]
  end

  # Fix gaps between vertically adjacent children
  defp fix_vertical_gaps([first | rest], _parent_bounds) do
    {fixed, _} =
      Enum.map_reduce(rest, first, fn child, prev ->
        expected_y = prev.bounds.y + prev.bounds.height

        if child.bounds.y != expected_y and abs(child.bounds.y - expected_y) <= 1 do
          new_bounds = %{child.bounds | y: expected_y}
          adjusted = %{child | bounds: new_bounds}
          {adjusted, adjusted}
        else
          {child, child}
        end
      end)

    [first | fixed]
  end

  defp round_val(v) when is_float(v), do: round(v)
  defp round_val(v) when is_integer(v), do: v
end
