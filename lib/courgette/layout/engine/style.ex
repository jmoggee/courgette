defmodule Courgette.Layout.Engine.Style do
  @moduledoc """
  Resolves `Element` props into a layout-ready style struct.

  Normalizes border insets, padding, margin, and flex properties from
  the keyword-style props map on an Element into consistent float values
  that the flexbox algorithm can consume directly.
  """

  alias Courgette.Layout.Engine.Geometry

  @typedoc "Resolved layout style for one element."
  @type t :: %__MODULE__{
          position: :static | :absolute,
          top: float() | nil,
          left: float() | nil,
          right: float() | nil,
          bottom: float() | nil,
          flex_direction: :row | :column,
          flex_wrap: :no_wrap | :wrap,
          flex_grow: float(),
          flex_shrink: float(),
          flex_basis: :auto | float(),
          justify_content:
            :flex_start | :flex_end | :center | :space_between | :space_around | :space_evenly,
          align_items: :flex_start | :flex_end | :center | :stretch | :baseline,
          align_self: :auto | :flex_start | :flex_end | :center | :stretch | :baseline,
          align_content:
            :flex_start | :flex_end | :center | :stretch | :space_between | :space_around,
          width: float() | nil,
          height: float() | nil,
          min_width: float() | nil,
          min_height: float() | nil,
          max_width: float() | nil,
          max_height: float() | nil,
          padding: Geometry.rect(),
          margin: Geometry.rect(),
          border: Geometry.rect(),
          gap_main: float(),
          gap_cross: float(),
          overflow: :visible | :hidden | :scroll,
          white_space: :normal | :nowrap,
          overflow_wrap: :normal | :break_word,
          text_overflow: :clip | :ellipsis
        }

  defstruct position: :static,
            top: nil,
            left: nil,
            right: nil,
            bottom: nil,
            flex_direction: :row,
            flex_wrap: :no_wrap,
            flex_grow: 0.0,
            flex_shrink: 1.0,
            flex_basis: :auto,
            justify_content: :flex_start,
            align_items: :stretch,
            align_self: :auto,
            align_content: :stretch,
            width: nil,
            height: nil,
            min_width: nil,
            min_height: nil,
            max_width: nil,
            max_height: nil,
            padding: %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0},
            margin: %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0},
            border: %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0},
            gap_main: 0.0,
            gap_cross: 0.0,
            overflow: :visible,
            white_space: :normal,
            overflow_wrap: :normal,
            text_overflow: :clip

  @doc """
  Resolves an Element's props map into a `%Style{}`.

  Handles shorthand expansions:
  - `border: :single/:double/:rounded` → 1-cell insets on all sides
  - `padding: N` → all sides; `padding_h: N` → left+right; `padding_v: N` → top+bottom
  - `margin: N` → all sides; individual sides override
  - `flex: N` shorthand → `flex_grow: N, flex_shrink: 1, flex_basis: 0`
  - `gap: N` → both main and cross gap
  """
  @spec from_element(Courgette.Element.t()) :: t()
  def from_element(%{props: props}) do
    %__MODULE__{}
    |> resolve_position(props)
    |> resolve_border(props)
    |> resolve_padding(props)
    |> resolve_margin(props)
    |> resolve_size(props)
    |> resolve_flex(props)
    |> resolve_alignment(props)
    |> resolve_gap(props)
    |> resolve_text_props(props)
  end

  # ── Position ─────────────────────────────────────────────────────

  defp resolve_position(style, props) do
    %{
      style
      | position: Map.get(props, :position, :static),
        top: to_maybe_float(Map.get(props, :top)),
        left: to_maybe_float(Map.get(props, :left)),
        right: to_maybe_float(Map.get(props, :right)),
        bottom: to_maybe_float(Map.get(props, :bottom))
    }
  end

  # ── Border ────────────────────────────────────────────────────────

  defp resolve_border(style, props) do
    case Map.get(props, :border) do
      s when s in [:single, :double, :rounded] ->
        %{style | border: Geometry.rect(1.0, 1.0, 1.0, 1.0)}

      _ ->
        style
    end
  end

  # ── Padding ───────────────────────────────────────────────────────

  defp resolve_padding(style, props) do
    base = to_float(Map.get(props, :padding, 0))
    h = to_float(Map.get(props, :padding_h, base))
    v = to_float(Map.get(props, :padding_v, base))

    left = to_float(Map.get(props, :padding_left, h))
    right = to_float(Map.get(props, :padding_right, h))
    top = to_float(Map.get(props, :padding_top, v))
    bottom = to_float(Map.get(props, :padding_bottom, v))

    %{style | padding: Geometry.rect(left, top, right, bottom)}
  end

  # ── Margin ────────────────────────────────────────────────────────

  defp resolve_margin(style, props) do
    base = to_float(Map.get(props, :margin, 0))

    left = to_float(Map.get(props, :margin_left, base))
    right = to_float(Map.get(props, :margin_right, base))
    top = to_float(Map.get(props, :margin_top, base))
    bottom = to_float(Map.get(props, :margin_bottom, base))

    %{style | margin: Geometry.rect(left, top, right, bottom)}
  end

  # ── Size ──────────────────────────────────────────────────────────

  defp resolve_size(style, props) do
    %{
      style
      | width: to_maybe_float(Map.get(props, :width)),
        height: to_maybe_float(Map.get(props, :height)),
        min_width: to_maybe_float(Map.get(props, :min_width)),
        min_height: to_maybe_float(Map.get(props, :min_height)),
        max_width: to_maybe_float(Map.get(props, :max_width)),
        max_height: to_maybe_float(Map.get(props, :max_height))
    }
  end

  # ── Flex ──────────────────────────────────────────────────────────

  defp resolve_flex(style, props) do
    # `flex: N` shorthand → grow=N, shrink=1, basis=0
    case Map.get(props, :flex) do
      n when is_number(n) and n >= 0 ->
        %{
          style
          | flex_grow: to_float(n),
            flex_shrink: 1.0,
            flex_basis: 0.0
        }
        |> override_flex_props(props)

      _ ->
        %{
          style
          | flex_direction: Map.get(props, :flex_direction, :row),
            flex_wrap: Map.get(props, :flex_wrap, :no_wrap),
            flex_grow: to_float(Map.get(props, :flex_grow, 0)),
            flex_shrink: to_float(Map.get(props, :flex_shrink, 1)),
            flex_basis: resolve_flex_basis(Map.get(props, :flex_basis))
        }
    end
  end

  defp override_flex_props(style, props) do
    style = %{style | flex_direction: Map.get(props, :flex_direction, style.flex_direction)}
    style = %{style | flex_wrap: Map.get(props, :flex_wrap, style.flex_wrap)}

    style =
      if Map.has_key?(props, :flex_grow),
        do: %{style | flex_grow: to_float(props.flex_grow)},
        else: style

    style =
      if Map.has_key?(props, :flex_shrink),
        do: %{style | flex_shrink: to_float(props.flex_shrink)},
        else: style

    style =
      if Map.has_key?(props, :flex_basis),
        do: %{style | flex_basis: resolve_flex_basis(props.flex_basis)},
        else: style

    style
  end

  defp resolve_flex_basis(nil), do: :auto
  defp resolve_flex_basis(:auto), do: :auto
  defp resolve_flex_basis(n) when is_number(n), do: to_float(n)

  # ── Alignment ─────────────────────────────────────────────────────

  defp resolve_alignment(style, props) do
    %{
      style
      | justify_content: Map.get(props, :justify_content, :flex_start),
        align_items: Map.get(props, :align_items, :stretch),
        align_self: Map.get(props, :align_self, :auto),
        align_content: Map.get(props, :align_content, :stretch)
    }
  end

  # ── Gap ───────────────────────────────────────────────────────────

  defp resolve_gap(style, props) do
    base = to_float(Map.get(props, :gap, 0))

    %{
      style
      | gap_main: to_float(Map.get(props, :gap_main, base)),
        gap_cross: to_float(Map.get(props, :gap_cross, base))
    }
  end

  # ── Text / Overflow ─────────────────────────────────────────────

  defp resolve_text_props(style, props) do
    %{
      style
      | overflow: Map.get(props, :overflow, :visible),
        white_space: Map.get(props, :white_space, :normal),
        overflow_wrap: Map.get(props, :overflow_wrap, :normal),
        text_overflow: Map.get(props, :text_overflow, :clip)
    }
  end

  # ── Helpers ───────────────────────────────────────────────────────

  defp to_float(n) when is_integer(n), do: n / 1
  defp to_float(n) when is_float(n), do: n
  defp to_float(_), do: 0.0

  defp to_maybe_float(nil), do: nil
  defp to_maybe_float(n) when is_number(n), do: n / 1
  defp to_maybe_float(_), do: nil
end
