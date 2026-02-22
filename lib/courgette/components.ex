defmodule Courgette.Components do
  @moduledoc """
  Built-in function components for common UI patterns.

  All components use the DSL and theme system. They accept a keyword
  list of assigns and return element trees.

      import Courgette.Components

      divider(orientation: :horizontal)
      badge(label: "OK", color: :green)
      heading(text: "Welcome")
      key_value(label: "Name", value: "Jeff")
      empty_state(message: "Nothing here yet")
  """

  use Courgette.Component

  @horizontal_rule String.duplicate("─", 500)
  @vertical_rule String.duplicate("│", 500)

  attr :orientation, :atom, default: :horizontal
  attr :color, :atom

  @doc """
  A horizontal or vertical divider line.

  The rule string is long and gets truncated by the container's width.

      divider(orientation: :horizontal)
      divider(orientation: :vertical, color: :cyan)
  """
  def divider(assigns) do
    assigns = assigns(assigns)
    orientation = Map.get(assigns, :orientation, :horizontal)
    color = Map.get(assigns, :color) || theme(assigns, :muted)

    char = if orientation == :vertical, do: @vertical_rule, else: @horizontal_rule

    text color: color, overflow: :truncate do
      char
    end
  end

  attr :label, :string
  attr :color, :atom

  @doc """
  A colored label badge with rounded border.

      badge(label: "OK", color: :green)
      badge(label: "Error", color: :red)
  """
  def badge(assigns) do
    assigns = assigns(assigns)
    label = Map.get(assigns, :label, "")
    color = Map.get(assigns, :color) || theme(assigns, :primary)

    box border: :rounded, border_color: color do
      text color: color do
        " #{label} "
      end
    end
  end

  attr :text, :string
  attr :color, :atom
  attr :divider, :boolean, default: true

  @doc """
  A themed heading with optional bottom divider.

      heading(text: "Dashboard")
      heading(text: "Status", color: :cyan, divider: false)
  """
  def heading(assigns) do
    assigns = assigns(assigns)
    heading_text = Map.get(assigns, :text, "")
    color = Map.get(assigns, :color) || theme(assigns, :primary)
    show_divider = Map.get(assigns, :divider, true)

    box flex_direction: :column do
      text color: color, bold: true do
        heading_text
      end

      if show_divider do
        divider(color: color, theme: Map.get(assigns, :theme))
      end
    end
  end

  attr :label, :string
  attr :value, :string

  @doc """
  A key-value pair row with muted label.

      key_value(label: "Name", value: "Jeff")
      key_value(label: "Status", value: "Active")
  """
  def key_value(assigns) do
    assigns = assigns(assigns)
    label = Map.get(assigns, :label, "")
    value = Map.get(assigns, :value, "")
    muted = theme(assigns, :muted)

    box flex_direction: :row do
      text color: muted do
        "#{label}: "
      end

      text do
        value
      end
    end
  end

  attr :message, :string

  @doc """
  A centered italic placeholder message for empty states.

      empty_state(message: "No items found")
  """
  def empty_state(assigns) do
    assigns = assigns(assigns)
    message = Map.get(assigns, :message, "Nothing to show")
    muted = theme(assigns, :muted)

    box justify_content: :center, align_items: :center do
      text color: muted, italic: true do
        message
      end
    end
  end
end
