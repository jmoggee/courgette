defmodule Courgette.Components.OrderedList do
  @moduledoc """
  Auto-numbered list items.

  Renders a vertical list where each item is prefixed with its ordinal
  number. Numbers are right-aligned when the list exceeds 9 items.

  ## Props

  - `items` — list of strings (required)
  - `start` — starting number (integer, default 1)
  - `color` — number color (atom, optional)

  ## Examples

      ordered_list(items: ["First", "Second", "Third"])
      ordered_list(items: ["A", "B"], start: 5, color: :cyan)
  """

  use Courgette.Component

  alias Courgette.Element

  attr(:items, :list)
  attr(:start, :integer, default: 1)
  attr(:color, :atom)

  @doc """
  Renders a numbered list with one item per line.

  Numbers are right-aligned when the list has more than 9 items
  to keep item text aligned.
  """
  @spec ordered_list(keyword()) :: Courgette.Element.t()
  def ordered_list(assigns) do
    assigns = assigns(assigns)

    items = Map.get(assigns, :items, [])
    start = Map.get(assigns, :start, 1)
    color = Map.get(assigns, :color)

    max_number = start + length(items) - 1
    max_width = String.length(Integer.to_string(max_number))
    number_opts = if color, do: [color: color], else: []

    rows =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} ->
        number = start + idx
        padded = String.pad_leading(Integer.to_string(number), max_width)

        number_el = Element.new(:text, number_opts, ["#{padded}. "])
        item_el = Element.new(:text, [], [item])
        Element.new(:box, [flex_direction: :row], [number_el, item_el])
      end)

    Element.new(:box, [flex_direction: :column], rows)
  end
end
