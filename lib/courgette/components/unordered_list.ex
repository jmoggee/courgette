defmodule Courgette.Components.UnorderedList do
  @moduledoc """
  Auto-bulleted list items.

  Renders a vertical list where each item is prefixed with a bullet
  marker character.

  ## Props

  - `items` — list of strings (required)
  - `marker` — bullet character (string, default `"\\u2022"`)
  - `color` — marker color (atom, optional)

  ## Examples

      unordered_list(items: ["First", "Second", "Third"])
      unordered_list(items: ["A", "B"], marker: "-", color: :cyan)
  """

  use Courgette.Component

  alias Courgette.Element

  attr(:items, :list)
  attr(:marker, :string, default: "\u2022")
  attr(:color, :atom)

  @doc """
  Renders a bulleted list with one item per line.
  """
  @spec unordered_list(keyword()) :: Courgette.Element.t()
  def unordered_list(assigns) do
    assigns = assigns(assigns)

    items = Map.get(assigns, :items, [])
    marker = Map.get(assigns, :marker, "\u2022")
    color = Map.get(assigns, :color)

    marker_opts = if color, do: [color: color], else: []

    rows =
      Enum.map(items, fn item ->
        marker_el = Element.new(:text, marker_opts, ["#{marker} "])
        item_el = Element.new(:text, [], [item])
        Element.new(:box, [flex_direction: :row], [marker_el, item_el])
      end)

    Element.new(:box, [flex_direction: :column], rows)
  end
end
