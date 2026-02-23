defmodule Courgette.Buffer.Cell do
  @moduledoc """
  A single terminal cell — the atom of the rendering pipeline.

  Each cell holds a grapheme, optional foreground/background colors, and
  a sparse style map. Cell is a pure data structure: it stores the same
  color and style types that `Courgette.ANSI` accepts but has no
  dependency on it and emits no escape sequences.

  ## Colors

  `fg` and `bg` accept:
  - Named atoms: `:red`, `:bright_cyan`, etc.
  - 256-color integers: `0..255`
  - RGB tuples: `{r, g, b}`
  - `nil` — terminal default (Writer emits nothing)

  ## Style Map

  The `:style` field is a map of attribute names to values. Empty `%{}`
  means no styling.

  Boolean flags (value is `true`):
  `:bold`, `:dim`, `:italic`, `:underline`, `:blink`, `:reverse`,
  `:hidden`, `:strikethrough`, `:overline`

  Parameterized:
  - `:underline_style` — `:straight | :double | :curly | :dotted | :dashed`
  - `:underline_color` — same color types as `fg`/`bg`

  When `:underline_style` is set, it implies underline is active.
  Plain `underline: true` means `:straight`.
  """

  @type color :: atom() | 0..255 | {byte(), byte(), byte()}

  @type t :: %__MODULE__{
          grapheme: String.t(),
          fg: color() | nil,
          bg: color() | nil,
          url: String.t() | nil,
          style: %{atom() => true | atom() | color()}
        }

  defstruct grapheme: " ", fg: nil, bg: nil, url: nil, style: %{}

  @extract_keys [:fg, :bg, :url]

  @doc """
  Returns the canonical empty cell (space, no colors, no style).
  """
  @spec empty() :: t()
  def empty, do: %__MODULE__{}

  @doc """
  Returns `true` if `cell` is equal to the empty cell.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{grapheme: " ", fg: nil, bg: nil, url: nil, style: style}),
    do: style == %{}

  def empty?(%__MODULE__{}), do: false

  @doc """
  Creates a new cell with default values (space, no colors, no style).
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new cell with the given grapheme and default colors/style.
  """
  @spec new(String.t()) :: t()
  def new(grapheme) when is_binary(grapheme) do
    %__MODULE__{grapheme: grapheme}
  end

  @doc """
  Creates a new cell with the given grapheme and options.

  Options `:fg` and `:bg` set colors. All other keys become style entries.

      Cell.new("x", fg: :red, bold: true, underline_style: :curly)
      #=> %Cell{grapheme: "x", fg: :red, bg: nil, style: %{bold: true, underline_style: :curly}}

  """
  @spec new(String.t(), keyword()) :: t()
  def new(grapheme, opts) when is_binary(grapheme) and is_list(opts) do
    {extracted, style_pairs} = Keyword.split(opts, @extract_keys)

    %__MODULE__{
      grapheme: grapheme,
      fg: Keyword.get(extracted, :fg),
      bg: Keyword.get(extracted, :bg),
      url: Keyword.get(extracted, :url),
      style: Map.new(style_pairs)
    }
  end

  @doc """
  Merges style attributes into the cell's existing style map.

  Accepts a map or keyword list. New keys override existing ones.

      cell |> Cell.merge_style(%{bold: true, italic: true})
      cell |> Cell.merge_style(bold: true, italic: true)

  """
  @spec merge_style(t(), map() | keyword()) :: t()
  def merge_style(%__MODULE__{} = cell, styles) when is_map(styles) do
    %{cell | style: Map.merge(cell.style, styles)}
  end

  def merge_style(%__MODULE__{} = cell, styles) when is_list(styles) do
    merge_style(cell, Map.new(styles))
  end
end
