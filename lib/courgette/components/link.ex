defmodule Courgette.Components.Link do
  @moduledoc """
  A styled text element representing a navigable link.

  Renders underlined text in a configurable color (default cyan).
  When a URL is provided, the text is wrapped in OSC 8 hyperlink
  sequences, making it clickable in supported terminals (iTerm2,
  kitty, ghostty, WezTerm).

  ## Props

  - `label` — display text (string, required)
  - `url` — target URL (string, optional)
  - `color` — link color (atom, default `:cyan`)

  ## Examples

      link(label: "Documentation", url: "https://hexdocs.pm/courgette")
      link(label: "Home", color: :blue)
  """

  use Courgette.Component

  attr(:label, :string)
  attr(:url, :string)
  attr(:color, :atom, default: :cyan)

  @doc """
  Renders an underlined text element styled as a link.
  """
  @spec link(keyword()) :: Courgette.Element.t()
  def link(assigns) do
    assigns = assigns(assigns)

    label = Map.get(assigns, :label, "")
    color = Map.get(assigns, :color, :cyan)
    url = Map.get(assigns, :url)

    opts = [color: color, underline: true]
    opts = if url, do: Keyword.put(opts, :url, url), else: opts

    text opts do
      label
    end
  end
end
