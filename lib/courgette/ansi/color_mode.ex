defmodule Courgette.ANSI.ColorMode do
  @moduledoc """
  Detects terminal color capability and downgrades colors to fit.

  ## Modes

  - `:bit_24` — truecolor (16M colors). `{r, g, b}` tuples pass through.
  - `:bit_8` — 256-color palette. Truecolor values are mapped to nearest palette entry.
  - `:basic` — 16 ANSI colors. Values are mapped to nearest basic color.

  ## Detection

  On startup, `detect/0` checks `$COLORTERM` and `$TERM` to determine capability.
  The user can override with `config :courgette, color_mode: :bit_24`.

  ## Downgrading

  `downgrade/2` takes a color value and a mode, returning an equivalent value
  that the terminal can render. Higher-fidelity colors are mapped to the
  nearest available representation.
  """

  @type mode :: :basic | :bit_8 | :bit_24
  @type color :: atom() | 0..255 | {0..255, 0..255, 0..255}

  # The 16 basic ANSI colors as approximate RGB values for distance calculations.
  # Indices 0-7 are normal, 8-15 are bright.
  @basic_rgb [
    # 0  black
    {0, 0, 0},
    # 1  red
    {128, 0, 0},
    # 2  green
    {0, 128, 0},
    # 3  yellow
    {128, 128, 0},
    # 4  blue
    {0, 0, 128},
    # 5  magenta
    {128, 0, 128},
    # 6  cyan
    {0, 128, 128},
    # 7  white
    {192, 192, 192},
    # 8  bright black
    {128, 128, 128},
    # 9  bright red
    {255, 0, 0},
    # 10 bright green
    {0, 255, 0},
    # 11 bright yellow
    {255, 255, 0},
    # 12 bright blue
    {0, 0, 255},
    # 13 bright magenta
    {255, 0, 255},
    # 14 bright cyan
    {0, 255, 255},
    # 15 bright white
    {255, 255, 255}
  ]

  # -- Detection --

  @doc """
  Detect terminal color capability from environment variables.

  Returns the configured mode if set (not `:auto`), otherwise checks
  `$COLORTERM` and `$TERM` in order:

  1. `$COLORTERM` is `"truecolor"` or `"24bit"` → `:bit_24`
  2. `$TERM` ends with `"-256color"` → `:bit_8`
  3. Otherwise → `:basic`
  """
  @spec detect() :: mode()
  def detect do
    case Application.get_env(:courgette, :color_mode, :auto) do
      :auto -> detect_from_env()
      mode when mode in [:basic, :bit_8, :bit_24] -> mode
    end
  end

  @doc """
  Detect color capability from environment variables only, ignoring config.
  """
  @spec detect_from_env() :: mode()
  def detect_from_env do
    colorterm = System.get_env("COLORTERM", "") |> String.downcase()
    term = System.get_env("TERM", "") |> String.downcase()

    cond do
      colorterm in ["truecolor", "24bit"] -> :bit_24
      String.ends_with?(term, "-256color") -> :bit_8
      true -> :basic
    end
  end

  # -- Downgrading --

  @doc """
  Downgrade a color value to fit within the given mode.

  - In `:bit_24` mode, all values pass through unchanged.
  - In `:bit_8` mode, `{r, g, b}` tuples are mapped to nearest 256-color index.
  - In `:basic` mode, both tuples and 256-color indices are mapped to 0-15.

  Named color atoms always pass through unchanged — they're already basic colors.
  """
  @spec downgrade(color(), mode()) :: color()
  def downgrade(color, :bit_24), do: color
  def downgrade(color, _mode) when is_atom(color), do: color

  def downgrade({r, g, b}, :bit_8) do
    rgb_to_256(r, g, b)
  end

  def downgrade({r, g, b}, :basic) do
    rgb_to_basic(r, g, b)
  end

  def downgrade(n, :bit_8) when is_integer(n) and n in 0..255, do: n

  def downgrade(n, :basic) when is_integer(n) and n in 0..255 do
    {r, g, b} = index_to_rgb(n)
    rgb_to_basic(r, g, b)
  end

  # -- 256-color mapping --

  @doc false
  @spec rgb_to_256(0..255, 0..255, 0..255) :: 0..255
  def rgb_to_256(r, g, b) do
    # Check if it's close to a grayscale ramp entry (indices 232-255)
    gray_index = rgb_to_gray_index(r, g, b)
    # Map to the 6x6x6 color cube (indices 16-231)
    cube_index = rgb_to_cube_index(r, g, b)

    gray_rgb = gray_index_to_rgb(gray_index)
    cube_rgb = cube_index_to_rgb(cube_index)

    gray_dist = color_distance({r, g, b}, gray_rgb)
    cube_dist = color_distance({r, g, b}, cube_rgb)

    if gray_dist <= cube_dist, do: gray_index, else: cube_index
  end

  # -- Basic color mapping --

  @doc false
  @spec rgb_to_basic(0..255, 0..255, 0..255) :: 0..15
  def rgb_to_basic(r, g, b) do
    @basic_rgb
    |> Enum.with_index()
    |> Enum.min_by(fn {{br, bg, bb}, _idx} -> color_distance({r, g, b}, {br, bg, bb}) end)
    |> elem(1)
  end

  # -- Internal helpers --

  # Squared Euclidean distance in RGB space. No need for sqrt — we only compare.
  defp color_distance({r1, g1, b1}, {r2, g2, b2}) do
    dr = r1 - r2
    dg = g1 - g2
    db = b1 - b2
    dr * dr + dg * dg + db * db
  end

  # 6x6x6 color cube: indices 16-231.
  # Each channel maps to 0, 95, 135, 175, 215, 255.
  @cube_values [0, 95, 135, 175, 215, 255]

  defp rgb_to_cube_index(r, g, b) do
    ri = nearest_cube_channel(r)
    gi = nearest_cube_channel(g)
    bi = nearest_cube_channel(b)
    16 + 36 * ri + 6 * gi + bi
  end

  defp nearest_cube_channel(v) do
    @cube_values
    |> Enum.with_index()
    |> Enum.min_by(fn {cv, _} -> abs(v - cv) end)
    |> elem(1)
  end

  defp cube_index_to_rgb(index) when index in 16..231 do
    n = index - 16
    ri = div(n, 36)
    gi = div(rem(n, 36), 6)
    bi = rem(n, 6)
    {Enum.at(@cube_values, ri), Enum.at(@cube_values, gi), Enum.at(@cube_values, bi)}
  end

  # Grayscale ramp: indices 232-255 map to levels 8, 18, 28, ..., 238.
  defp rgb_to_gray_index(r, g, b) do
    avg = div(r + g + b, 3)
    # Clamp to 232-255 range
    idx = round((avg - 8) / 10)
    min(max(idx + 232, 232), 255)
  end

  defp gray_index_to_rgb(index) when index in 232..255 do
    level = 8 + 10 * (index - 232)
    {level, level, level}
  end

  # Convert a 256-color index to approximate RGB.
  defp index_to_rgb(n) when n in 0..15, do: Enum.at(@basic_rgb, n)
  defp index_to_rgb(n) when n in 16..231, do: cube_index_to_rgb(n)
  defp index_to_rgb(n) when n in 232..255, do: gray_index_to_rgb(n)
end
