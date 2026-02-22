defmodule Courgette.Animation.Frames do
  @moduledoc """
  Discrete frame cycling for animation.

  Wraps a list of frames into a tuple for O(1) indexing. Supports advancing
  with wrap-around and provides built-in frame sets for common patterns.

  ## Usage

      frames = Frames.new(["a", "b", "c"])
      {frame, frames} = Frames.next(frames)  # {"a", updated}
      {frame, frames} = Frames.next(frames)  # {"b", updated}
  """

  defstruct [:items, :count, :index]

  @type t :: %__MODULE__{
          items: tuple(),
          count: non_neg_integer(),
          index: non_neg_integer()
        }

  @doc """
  Create a new Frames from a list.

  The list is stored as a tuple for O(1) access via `elem/2`.
  """
  @spec new(list()) :: t()
  def new(list) when is_list(list) and list != [] do
    %__MODULE__{
      items: List.to_tuple(list),
      count: length(list),
      index: 0
    }
  end

  @doc """
  Return the current frame without advancing.
  """
  @spec current(t()) :: term()
  def current(%__MODULE__{items: items, index: index}) do
    elem(items, index)
  end

  @doc """
  Return the current frame and advance to the next (wrapping around).
  """
  @spec next(t()) :: {term(), t()}
  def next(%__MODULE__{items: items, count: count, index: index} = frames) do
    frame = elem(items, index)
    next_index = rem(index + 1, count)
    {frame, %{frames | index: next_index}}
  end

  @doc """
  Reset to the first frame.
  """
  @spec reset(t()) :: t()
  def reset(%__MODULE__{} = frames) do
    %{frames | index: 0}
  end

  # --- Built-in frame sets ---

  @doc "Braille spinner frames (alias: `dots/0`)"
  @spec braille() :: t()
  def braille, do: new(~w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏))

  @doc "Alias for `braille/0`"
  @spec dots() :: t()
  def dots, do: braille()

  @doc "Line spinner: - \\ | /"
  @spec line() :: t()
  def line, do: new(~w(- \\ | /))

  @doc "Wave animation frames"
  @spec wave() :: t()
  def wave, do: new(~w(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃ ▂))

  @doc "Circle spinner frames"
  @spec circle() :: t()
  def circle, do: new(~w(◐ ◓ ◑ ◒))

  @doc "Bounce animation frames"
  @spec bounce() :: t()
  def bounce, do: new(~w(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈))
end
