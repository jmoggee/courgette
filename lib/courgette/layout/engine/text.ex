defmodule Courgette.Layout.Engine.Text do
  @moduledoc """
  Text measurement for layout computation.

  Measures text dimensions under different overflow modes and width
  constraints. Used by the flexbox algorithm to determine the intrinsic
  sizes of text leaf nodes.
  """

  @typedoc "Result of text measurement: {width, height} in cells."
  @type measurement :: {float(), float()}

  @doc """
  Measures text given a width constraint and wrap mode.

  Returns `{width, height}` in cell units (as floats).

  ## Wrap modes

  - `:word_wrap` (default) — wraps at word boundaries. Words longer than
    the constraint wrap at character boundaries.
  - `:char_wrap` — wraps at character boundaries only.
  - `:no_wrap` — single line, width clamped to constraint.

  ## Width constraint

  - `nil` — unconstrained (returns natural text width)
  - `float` — maximum width in cells
  """
  @spec measure(String.t(), float() | nil, atom()) :: measurement()
  def measure(text, width_constraint \\ nil, wrap_mode \\ :word_wrap)

  def measure("", _constraint, _wrap_mode), do: {0.0, 0.0}

  def measure(text, nil, _wrap_mode) do
    lines = String.split(text, "\n")
    max_width = lines |> Enum.map(&grapheme_count/1) |> Enum.max()
    {max_width / 1, length(lines) / 1}
  end

  def measure(text, constraint, :no_wrap) when is_number(constraint) do
    lines = String.split(text, "\n")
    # No-wrap mode: only the first line matters, clamped to constraint
    first = hd(lines)
    w = min(grapheme_count(first), max(constraint, 0))
    {w / 1, 1.0}
  end

  def measure(text, constraint, :char_wrap) when is_number(constraint) do
    constraint = max(constraint, 1) / 1

    lines = String.split(text, "\n")

    wrapped =
      Enum.flat_map(lines, fn line ->
        wrap_chars(line, constraint)
      end)

    max_width = wrapped |> Enum.map(&grapheme_count/1) |> Enum.max(fn -> 0 end)
    {min(max_width / 1, constraint), length(wrapped) / 1}
  end

  def measure(text, constraint, _wrap_mode) when is_number(constraint) do
    # Default: word_wrap
    constraint = max(constraint, 1) / 1

    lines = String.split(text, "\n")

    wrapped =
      Enum.flat_map(lines, fn line ->
        wrap_words(line, constraint)
      end)

    max_width = wrapped |> Enum.map(&grapheme_count/1) |> Enum.max(fn -> 0 end)
    {min(max_width / 1, constraint), length(wrapped) / 1}
  end

  @doc """
  Returns the min-content width: the width of the widest word.

  For text with no spaces, this is the full text width.
  """
  @spec min_content_width(String.t()) :: float()
  def min_content_width(""), do: 0.0

  def min_content_width(text) do
    text
    |> String.split(~r/[\s\n]+/)
    |> Enum.map(&grapheme_count/1)
    |> Enum.max(fn -> 0 end)
    |> Kernel./(1)
  end

  @doc """
  Returns the max-content width: the width of the longest line if
  no wrapping were applied.
  """
  @spec max_content_width(String.t()) :: float()
  def max_content_width(""), do: 0.0

  def max_content_width(text) do
    text
    |> String.split("\n")
    |> Enum.map(&grapheme_count/1)
    |> Enum.max(fn -> 0 end)
    |> Kernel./(1)
  end

  @doc """
  Counts grapheme clusters in a string (visible character count).
  """
  @spec grapheme_count(String.t()) :: non_neg_integer()
  def grapheme_count(str), do: String.length(str)

  # ── Word wrapping ─────────────────────────────────────────────────

  defp wrap_words(line, constraint) do
    if grapheme_count(line) <= constraint do
      [line]
    else
      words = String.split(line, " ")
      do_wrap_words(words, constraint, "", [])
    end
  end

  defp do_wrap_words([], _constraint, current, lines) do
    Enum.reverse([current | lines])
  end

  defp do_wrap_words([word | rest], constraint, current, lines) do
    word_len = grapheme_count(word)
    current_len = grapheme_count(current)

    cond do
      # Empty current line — start with this word
      current == "" ->
        if word_len > constraint do
          # Word too long — force char-wrap it
          wrapped = force_wrap_word(word, constraint)
          {complete, [last]} = Enum.split(wrapped, -1)
          do_wrap_words(rest, constraint, last, Enum.reverse(complete) ++ lines)
        else
          do_wrap_words(rest, constraint, word, lines)
        end

      # Word fits on current line (with space)
      current_len + 1 + word_len <= constraint ->
        do_wrap_words(rest, constraint, current <> " " <> word, lines)

      # Word doesn't fit — start new line
      true ->
        if word_len > constraint do
          wrapped = force_wrap_word(word, constraint)
          {complete, [last]} = Enum.split(wrapped, -1)
          do_wrap_words(rest, constraint, last, Enum.reverse(complete) ++ [current | lines])
        else
          do_wrap_words(rest, constraint, word, [current | lines])
        end
    end
  end

  # Force-wrap a single word that exceeds the constraint
  defp force_wrap_word(word, constraint) do
    constraint = trunc(constraint)

    word
    |> String.graphemes()
    |> Enum.chunk_every(constraint)
    |> Enum.map(&Enum.join/1)
  end

  # ── Character wrapping ────────────────────────────────────────────

  defp wrap_chars(line, constraint) do
    if grapheme_count(line) <= constraint do
      [line]
    else
      constraint = trunc(constraint)

      line
      |> String.graphemes()
      |> Enum.chunk_every(constraint)
      |> Enum.map(&Enum.join/1)
    end
  end
end
