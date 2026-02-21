defmodule Courgette.Buffer.DoubleBuffer do
  @moduledoc """
  Wraps two buffers in the classic double-buffer pattern.

  `back` is the draw target — new content goes here. `front` holds the last
  flushed frame (what's currently on screen). `swap/1` promotes back → front
  and clears back for the next frame. `diff/1` compares front to back so the
  caller knows what changed.

  The typical frame loop is:

      1. Draw into `db.back`
      2. Call `swap_and_diff/1` to get the change runs and advance the frame
      3. Pass runs to Writer
  """

  alias Courgette.Buffer
  alias Courgette.Buffer.Diff

  @type t :: %__MODULE__{
          front: Buffer.t(),
          back: Buffer.t(),
          width: pos_integer(),
          height: pos_integer()
        }

  defstruct [:front, :back, :width, :height]

  @doc """
  Creates a new double buffer with both buffers empty at the given size.
  """
  @spec new(pos_integer(), pos_integer()) :: t()
  def new(width, height) do
    %__MODULE__{
      front: Buffer.new(width, height),
      back: Buffer.new(width, height),
      width: width,
      height: height
    }
  end

  @doc """
  Returns the back buffer (the draw target).
  """
  @spec back(t()) :: Buffer.t()
  def back(%__MODULE__{back: back}), do: back

  @doc """
  Returns the front buffer (what's on screen).
  """
  @spec front(t()) :: Buffer.t()
  def front(%__MODULE__{front: front}), do: front

  @doc """
  Diffs front against back, returning runs of changed cells.

  Delegates to `Diff.diff/2`.
  """
  @spec diff(t()) :: [Diff.Run.t()]
  def diff(%__MODULE__{front: front, back: back}) do
    Diff.diff(front, back)
  end

  @doc """
  Promotes back → front and clears back for the next frame.
  """
  @spec swap(t()) :: t()
  def swap(%__MODULE__{back: back} = db) do
    %{db | front: back, back: Buffer.clear(back)}
  end

  @doc """
  Computes the diff, then swaps. Returns `{runs, new_db}`.

  This is the common frame-flush operation: you need the diff (to know what
  to write to the terminal) and then you advance the frame.
  """
  @spec swap_and_diff(t()) :: {[Diff.Run.t()], t()}
  def swap_and_diff(%__MODULE__{} = db) do
    runs = diff(db)
    {runs, swap(db)}
  end

  @doc """
  Resizes both buffers to new dimensions. Both are reset to empty.
  """
  @spec resize(t(), pos_integer(), pos_integer()) :: t()
  def resize(%__MODULE__{}, width, height) do
    new(width, height)
  end
end
