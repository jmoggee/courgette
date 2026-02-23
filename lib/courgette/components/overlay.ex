defmodule Courgette.Components.Overlay do
  @moduledoc """
  A centered container for modal/popup content.

  Wraps child content in a bordered, centered box with optional title
  and padding. Useful for dialogs, confirmations, and popups.

  ## Props

  - `title` — optional title displayed at top of overlay (string)
  - `border` — border style (default `:rounded`)
  - `width` — width of overlay (integer, optional)
  - `height` — height of overlay (integer, optional)
  - `padding` — internal padding (integer, default 1)

  ## Examples

      overlay title: "Confirm" do
        text do: "Are you sure?"
      end

      overlay border: :single, width: 40, height: 10 do
        text do: "Dialog content"
      end
  """

  use Courgette.Component

  attr(:title, :string)
  attr(:border, :atom, default: :rounded)
  attr(:width, :integer)
  attr(:height, :integer)
  attr(:padding, :integer, default: 1)
  slot(:inner_block)

  @doc """
  Renders a centered overlay container with border and optional title.
  """
  @spec overlay(keyword()) :: Courgette.Element.t()
  def overlay(assigns) do
    assigns = assigns(assigns)

    title = Map.get(assigns, :title)
    border = Map.get(assigns, :border, :rounded)
    padding = Map.get(assigns, :padding, 1)
    width = Map.get(assigns, :width)
    height = Map.get(assigns, :height)
    children = render_slot(Map.get(assigns, :inner_block) || Map.get(assigns, :do))

    content_box_opts =
      [border: border, padding: padding, flex_direction: :column]
      |> maybe_add(:width, width)
      |> maybe_add(:height, height)

    box justify_content: :center, align_items: :center do
      box content_box_opts do
        if title do
          text bold: true do
            title
          end
        end

        for child <- children do
          child
        end
      end
    end
  end

  @spec maybe_add(keyword(), atom(), term()) :: keyword()
  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, key, val), do: Keyword.put(opts, key, val)
end
