defmodule Courgette.Layout.Bounds do
  @moduledoc """
  A rectangle in the buffer — position and size of a layout node.

  Bounds are absolute: `{x, y}` is the top-left corner in buffer
  coordinates, `width` and `height` define the extent. The layout
  engine assigns bounds; the Painter consumes them.

  All values are non-negative integers (cell coordinates).
  """

  @type t :: %__MODULE__{
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer()
        }

  defstruct x: 0, y: 0, width: 0, height: 0

  @doc """
  Creates a new bounds rectangle.

      Bounds.new(5, 3, 40, 12)
      #=> %Bounds{x: 5, y: 3, width: 40, height: 12}

  """
  @spec new(non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) :: t()
  def new(x, y, width, height)
      when is_integer(x) and x >= 0 and
             is_integer(y) and y >= 0 and
             is_integer(width) and width >= 0 and
             is_integer(height) and height >= 0 do
    %__MODULE__{x: x, y: y, width: width, height: height}
  end

  @doc """
  Returns `true` if the point `{px, py}` lies within the bounds.

      Bounds.new(5, 3, 10, 8) |> Bounds.contains?(5, 3)   #=> true
      Bounds.new(5, 3, 10, 8) |> Bounds.contains?(15, 3)  #=> false

  """
  @spec contains?(t(), integer(), integer()) :: boolean()
  def contains?(%__MODULE__{x: x, y: y, width: w, height: h}, px, py) do
    px >= x and px < x + w and py >= y and py < y + h
  end

  @doc """
  Returns the intersection of two bounds, or `nil` if they don't overlap.

  Used by the Painter to compute clip rectangles when descending into
  children — the child's painting area is the intersection of the
  parent's clip rect and the child's bounds.

      a = Bounds.new(0, 0, 20, 10)
      b = Bounds.new(5, 3, 30, 20)
      Bounds.intersect(a, b)
      #=> %Bounds{x: 5, y: 3, width: 15, height: 7}

  """
  @spec intersect(t(), t()) :: t() | nil
  def intersect(%__MODULE__{} = a, %__MODULE__{} = b) do
    x1 = max(a.x, b.x)
    y1 = max(a.y, b.y)
    x2 = min(a.x + a.width, b.x + b.width)
    y2 = min(a.y + a.height, b.y + b.height)

    if x2 > x1 and y2 > y1 do
      %__MODULE__{x: x1, y: y1, width: x2 - x1, height: y2 - y1}
    else
      nil
    end
  end
end
