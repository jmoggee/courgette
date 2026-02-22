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

  # --- Built-in frame sets: Braille family ---

  @doc "Classic braille rotation (cli-spinners \"dots\")"
  @spec dots() :: t()
  def dots, do: new(~w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏))

  @doc "Alias for `dots/0`"
  @spec braille() :: t()
  def braille, do: dots()

  @doc "Braille fills up then empties — breathing effect"
  @spec dots_pulse() :: t()
  def dots_pulse, do: new(~w(⠀ ⠁ ⠃ ⠇ ⡇ ⣇ ⣧ ⣷ ⣿ ⣷ ⣧ ⣇ ⡇ ⠇ ⠃ ⠁))

  @doc "Single dot tracing the 6 braille positions"
  @spec dots_orbit() :: t()
  def dots_orbit, do: new(~w(⠈ ⠐ ⠠ ⠄ ⠂ ⠁))

  @doc "Dense braille rotation, one gap sweeps around (cli-spinners \"dots2\")"
  @spec dots_scroll() :: t()
  def dots_scroll, do: new(~w(⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷))

  @doc "Braille wave that swells and recedes (cli-spinners \"dots4\")"
  @spec dots_bounce() :: t()
  def dots_bounce, do: new(~w(⠄ ⠆ ⠇ ⠋ ⠙ ⠸ ⠰ ⠠ ⠰ ⠸ ⠙ ⠋ ⠇ ⠆))

  @doc "Hourglass: fills from top, empties from bottom (cli-spinners \"sand\")"
  @spec sand() :: t()
  def sand do
    new(~w(⠁ ⠂ ⠄ ⡀ ⡈ ⡐ ⡠ ⣀ ⣁ ⣂ ⣄ ⣌ ⣔ ⣤ ⣥ ⣦ ⣮ ⣶ ⣷ ⣿ ⡿ ⠿ ⢟ ⠟ ⡛ ⠛ ⠫ ⢋ ⠋ ⠍ ⡉ ⠉ ⠑ ⠡ ⢁))
  end

  @doc "Two dots orbiting together (throbber-widgets-tui BRAILLE_DOUBLE)"
  @spec braille_double() :: t()
  def braille_double, do: new(~w(⠘ ⠰ ⠤ ⠆ ⠃ ⠉))

  @doc "Inverse: one missing dot sweeps around (throbber-widgets-tui BRAILLE_SIX)"
  @spec braille_six() :: t()
  def braille_six, do: new(~w(⠷ ⠯ ⠟ ⠻ ⠽ ⠾))

  @doc "Full 8-dot with two gaps sweeping (throbber-widgets-tui BRAILLE_EIGHT_DOUBLE)"
  @spec braille_eight_double() :: t()
  def braille_eight_double, do: new(~w(⣧ ⣏ ⡟ ⠿ ⢻ ⣹ ⣼ ⣶))

  # --- Built-in frame sets: Geometric family ---

  @doc "Half-circle rotation"
  @spec circle() :: t()
  def circle, do: new(~w(◐ ◓ ◑ ◒))

  @doc "Smooth arc sweeping around"
  @spec arc() :: t()
  def arc, do: new(~w(◜ ◠ ◝ ◞ ◡ ◟))

  @doc "Rotating filled corner"
  @spec triangle() :: t()
  def triangle, do: new(~w(◢ ◣ ◤ ◥))

  @doc "Quarter-circle rotation"
  @spec quarter() :: t()
  def quarter, do: new(~w(◴ ◷ ◶ ◵))

  @doc "Quadrant block bouncing around corners"
  @spec box_bounce() :: t()
  def box_bounce, do: new(~w(▖ ▘ ▝ ▗))

  @doc "Box-drawing corner rotation"
  @spec pipe() :: t()
  def pipe, do: new(~w(┤ ┘ ┴ └ ├ ┌ ┬ ┐))

  @doc "Inverse of box_bounce: three quadrants filled"
  @spec box_invert() :: t()
  def box_invert, do: new(~w(▙ ▛ ▜ ▟))

  @doc "Quarter-filled squares rotating"
  @spec square_corners() :: t()
  def square_corners, do: new(~w(◰ ◳ ◲ ◱))

  # --- Built-in frame sets: Block family ---

  @doc "Vertical block elements pulse up and down"
  @spec wave() :: t()
  def wave, do: new(~w(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃ ▂))

  @doc "Block density fade: solid to light and back"
  @spec pulse() :: t()
  def pulse, do: new(~w(█ ▓ ▒ ░ ▒ ▓))

  @doc "Three-segment bar that fills and empties"
  @spec meter() :: t()
  def meter, do: new(~w(▱▱▱ ▰▱▱ ▰▰▱ ▰▰▰ ▰▰▱ ▰▱▱))

  @doc "Horizontal block element grows and shrinks"
  @spec grow_horizontal() :: t()
  def grow_horizontal, do: new(~w(▏ ▎ ▍ ▌ ▋ ▊ ▉ ▊ ▋ ▌ ▍ ▎))

  @doc "Static/interference flicker"
  @spec noise() :: t()
  def noise, do: new(~w(▓ ▒ ░))

  @doc "Accumulating horizontal lines"
  @spec layer() :: t()
  def layer, do: new(~w(- = ≡))

  # --- Built-in frame sets: Classic ---

  @doc "ASCII line rotation: - \\ | /"
  @spec line() :: t()
  def line, do: new(~w(- \\ | /))

  @doc "Twinkling star"
  @spec star() :: t()
  def star, do: new(~w(✶ ✸ ✹ ✺ ✹ ✷))

  @doc "Dot traveling across three positions"
  @spec point() :: t()
  def point, do: new(~w(∙∙∙ ●∙∙ ∙●∙ ∙∙● ∙∙∙))

  @doc "Single braille dot orbiting 8 positions"
  @spec bounce() :: t()
  def bounce, do: new(~w(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈))

  @doc "Arrow rotating through 8 compass directions"
  @spec arrow() :: t()
  def arrow, do: new(~w(← ↖ ↑ ↗ → ↘ ↓ ↙))

  @doc "The universal thinking indicator"
  @spec ellipsis() :: t()
  def ellipsis, do: new([".", "..", "...", " "])

  @doc "Trigram lines"
  @spec hamburger() :: t()
  def hamburger, do: new(~w(☱ ☲ ☴))
end
