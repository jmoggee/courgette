defmodule Courgette.Components.Scrollbar do
  @moduledoc """
  A visual scroll indicator showing position within scrollable content.

  Renders a track with a proportionally sized and positioned thumb to
  indicate the current scroll position. The parent manages scroll state
  and passes it via props.

  ## Props

  - `content_length` — total number of items/lines (integer, required)
  - `viewport_length` — visible items/lines (integer, required)
  - `offset` — current scroll offset (integer, default 0)
  - `orientation` — `:vertical` (default) or `:horizontal`

  ## Examples

      scrollbar(content_length: 100, viewport_length: 20, offset: 10)
      scrollbar(content_length: 50, viewport_length: 10, offset: 5, orientation: :horizontal)
  """

  use Courgette.Component

  attr(:content_length, :integer)
  attr(:viewport_length, :integer)
  attr(:offset, :integer, default: 0)
  attr(:orientation, :atom, default: :vertical)

  @doc """
  Renders a scrollbar track with a proportionally sized thumb.

  When `content_length <= viewport_length`, the entire track is shown
  without a thumb (content fits in the viewport).
  """
  @spec scrollbar(keyword()) :: Courgette.Element.t()
  def scrollbar(assigns) do
    assigns = assigns(assigns)

    content_length = Map.get(assigns, :content_length, 0)
    viewport_length = Map.get(assigns, :viewport_length, 0)
    offset = Map.get(assigns, :offset, 0)
    orientation = Map.get(assigns, :orientation, :vertical)

    {track_char, thumb_char} =
      if orientation == :horizontal, do: {"\u2500", "\u2588"}, else: {"\u2502", "\u2588"}

    direction = if orientation == :horizontal, do: :row, else: :column

    cells = build_cells(content_length, viewport_length, offset, track_char, thumb_char)

    box flex_direction: direction do
      for char <- cells do
        text do
          char
        end
      end
    end
  end

  @spec build_cells(integer(), integer(), integer(), String.t(), String.t()) :: [String.t()]
  defp build_cells(content_length, viewport_length, offset, track_char, thumb_char) do
    if content_length <= viewport_length do
      List.duplicate(track_char, viewport_length)
    else
      thumb_size = max(1, round(viewport_length * viewport_length / content_length))

      thumb_pos =
        round(offset * (viewport_length - thumb_size) / (content_length - viewport_length))

      thumb_end = thumb_pos + thumb_size

      for i <- 0..(viewport_length - 1) do
        cell_char(i, thumb_pos, thumb_end, thumb_char, track_char)
      end
    end
  end

  @spec cell_char(integer(), integer(), integer(), String.t(), String.t()) :: String.t()
  defp cell_char(i, thumb_pos, thumb_end, thumb_char, track_char) do
    if i >= thumb_pos and i < thumb_end, do: thumb_char, else: track_char
  end
end
