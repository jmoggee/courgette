defmodule Courgette.Layout.Engine do
  @moduledoc """
  Public API for the flexbox layout engine.

  Takes an `%Element{}` tree and a root `%Bounds{}`, computes layout using
  the CSS flexbox algorithm, and returns a layout tree with absolute
  integer `%Bounds{}` coordinates suitable for the Painter.

  ## Usage

      element = Element.new(:box, [width: 80, height: 24, border: :single], [
        Element.new(:text, [color: :green, flex: 1], ["Hello"]),
        Element.new(:text, [color: :blue, flex: 1], ["World"])
      ])

      root_bounds = Bounds.new(0, 0, 80, 24)
      layout_tree = Engine.compute(element, root_bounds)

      # layout_tree is ready for Painter.paint/2
      buffer = Painter.paint(layout_tree, Buffer.new(80, 24))

  """

  alias Courgette.Element
  alias Courgette.Layout.Bounds
  alias Courgette.Layout.Engine.Flex
  alias Courgette.Layout.Engine.Round

  @doc """
  Computes layout for an element tree within the given bounds.

  Returns a layout tree of `%{element, bounds, children}` maps with
  absolute integer coordinates, ready for `Painter.paint/2`.
  """
  @spec compute(Element.t(), Bounds.t()) :: map()
  def compute(%Element{} = element, %Bounds{} = root_bounds) do
    available = %{width: root_bounds.width / 1, height: root_bounds.height / 1}

    # Step 1: Compute flexbox layout (float, parent-relative)
    float_tree = Flex.layout(element, available)

    # Step 2: Convert to absolute integer Bounds
    Round.to_bounds(float_tree, {root_bounds.x, root_bounds.y})
  end
end
