defmodule Courgette.Layout.Engine.Geometry do
  @moduledoc """
  Core geometry types and axis helpers for the layout engine.

  Provides `Size`, `Rect`, `AvailableSpace`, axis abstraction for
  flex-direction, and `maybe_*` arithmetic that propagates `nil`
  (representing unset/auto dimensions).
  """

  # ── Size ──────────────────────────────────────────────────────────

  @typedoc "A width/height pair. Values are floats or nil (unset)."
  @type size :: %{width: float() | nil, height: float() | nil}

  @doc "Creates a size with both dimensions."
  @spec size(float(), float()) :: size()
  def size(w, h), do: %{width: w, height: h}

  @doc "Creates a size with nil (unset) dimensions."
  @spec size_none() :: size()
  def size_none, do: %{width: nil, height: nil}

  # ── Rect (insets: padding, margin, border) ────────────────────────

  @typedoc "Four-sided inset values (all floats)."
  @type rect :: %{left: float(), top: float(), right: float(), bottom: float()}

  @doc "Creates a rect with explicit sides."
  @spec rect(float(), float(), float(), float()) :: rect()
  def rect(left, top, right, bottom) do
    %{left: left, top: top, right: right, bottom: bottom}
  end

  @doc "Creates a zero rect."
  @spec rect_zero() :: rect()
  def rect_zero, do: %{left: 0.0, top: 0.0, right: 0.0, bottom: 0.0}

  @doc "Sum of horizontal insets."
  @spec rect_horizontal(rect()) :: float()
  def rect_horizontal(%{left: l, right: r}), do: l + r

  @doc "Sum of vertical insets."
  @spec rect_vertical(rect()) :: float()
  def rect_vertical(%{top: t, bottom: b}), do: t + b

  # ── AvailableSpace ────────────────────────────────────────────────

  @typedoc """
  Available space along an axis.

  - `{:definite, float}` — a known pixel/cell value
  - `:min_content` — shrink to minimum content size
  - `:max_content` — expand to maximum content size
  """
  @type available_space :: {:definite, float()} | :min_content | :max_content

  @doc "Unwraps a definite value, or returns the fallback for content-based sizing."
  @spec definite_or(available_space(), float()) :: float()
  def definite_or({:definite, v}, _fallback), do: v
  def definite_or(_content, fallback), do: fallback

  @doc "Returns true if the space is definite."
  @spec definite?(available_space()) :: boolean()
  def definite?({:definite, _}), do: true
  def definite?(_), do: false

  @doc "Maps over a definite value, passes through content-based."
  @spec map_definite(available_space(), (float() -> float())) :: available_space()
  def map_definite({:definite, v}, fun), do: {:definite, fun.(v)}
  def map_definite(other, _fun), do: other

  @doc "Converts a maybe-nil float to AvailableSpace."
  @spec to_available(float() | nil) :: available_space()
  def to_available(nil), do: :max_content
  def to_available(v) when is_number(v), do: {:definite, v / 1}

  # ── Axis abstraction ──────────────────────────────────────────────

  @typedoc "Main axis of a flex container."
  @type axis :: :row | :column

  @doc "Returns the main-axis value from a size."
  @spec main(axis(), size()) :: float() | nil
  def main(:row, %{width: w}), do: w
  def main(:column, %{height: h}), do: h

  @doc "Returns the cross-axis value from a size."
  @spec cross(axis(), size()) :: float() | nil
  def cross(:row, %{height: h}), do: h
  def cross(:column, %{width: w}), do: w

  @doc "Sets the main-axis value on a size."
  @spec set_main(axis(), size(), float() | nil) :: size()
  def set_main(:row, size, v), do: %{size | width: v}
  def set_main(:column, size, v), do: %{size | height: v}

  @doc "Sets the cross-axis value on a size."
  @spec set_cross(axis(), size(), float() | nil) :: size()
  def set_cross(:row, size, v), do: %{size | height: v}
  def set_cross(:column, size, v), do: %{size | width: v}

  @doc "Builds a size from main and cross values."
  @spec from_main_cross(axis(), float() | nil, float() | nil) :: size()
  def from_main_cross(:row, main_val, cross_val), do: %{width: main_val, height: cross_val}
  def from_main_cross(:column, main_val, cross_val), do: %{width: cross_val, height: main_val}

  @doc "Returns the main-axis inset sum from a rect."
  @spec main_inset(axis(), rect()) :: float()
  def main_inset(:row, rect), do: rect_horizontal(rect)
  def main_inset(:column, rect), do: rect_vertical(rect)

  @doc "Returns the cross-axis inset sum from a rect."
  @spec cross_inset(axis(), rect()) :: float()
  def cross_inset(:row, rect), do: rect_vertical(rect)
  def cross_inset(:column, rect), do: rect_horizontal(rect)

  @doc "Returns the main-axis start inset from a rect."
  @spec main_start(axis(), rect()) :: float()
  def main_start(:row, %{left: v}), do: v
  def main_start(:column, %{top: v}), do: v

  @doc "Returns the cross-axis start inset from a rect."
  @spec cross_start(axis(), rect()) :: float()
  def cross_start(:row, %{top: v}), do: v
  def cross_start(:column, %{left: v}), do: v

  # ── maybe_* arithmetic ───────────────────────────────────────────

  @doc "Adds two values, treating nil as absent. Returns nil if either is nil."
  @spec maybe_add(float() | nil, float() | nil) :: float() | nil
  def maybe_add(nil, _), do: nil
  def maybe_add(_, nil), do: nil
  def maybe_add(a, b), do: a + b

  @doc "Subtracts b from a. Returns nil if either is nil."
  @spec maybe_sub(float() | nil, float() | nil) :: float() | nil
  def maybe_sub(nil, _), do: nil
  def maybe_sub(_, nil), do: nil
  def maybe_sub(a, b), do: a - b

  @doc "Returns the minimum of two values. nil is treated as absent (returns the other)."
  @spec maybe_min(float() | nil, float() | nil) :: float() | nil
  def maybe_min(nil, b), do: b
  def maybe_min(a, nil), do: a
  def maybe_min(a, b), do: min(a, b)

  @doc "Returns the maximum of two values. nil is treated as absent (returns the other)."
  @spec maybe_max(float() | nil, float() | nil) :: float() | nil
  def maybe_max(nil, b), do: b
  def maybe_max(a, nil), do: a
  def maybe_max(a, b), do: max(a, b)

  @doc "Clamps a value between min_val and max_val. nil bounds are ignored."
  @spec maybe_clamp(float(), float() | nil, float() | nil) :: float()
  def maybe_clamp(val, nil, nil), do: val
  def maybe_clamp(val, min_val, nil) when is_number(min_val), do: max(val, min_val)
  def maybe_clamp(val, nil, max_val) when is_number(max_val), do: min(val, max_val)

  def maybe_clamp(val, min_val, max_val) when is_number(min_val) and is_number(max_val) do
    val |> max(min_val) |> min(max_val)
  end

  @doc "Adds a definite value to a maybe-nil value. Returns nil if the base is nil."
  @spec maybe_add_definite(float() | nil, float()) :: float() | nil
  def maybe_add_definite(nil, _), do: nil
  def maybe_add_definite(a, b), do: a + b

  @doc "Subtracts a definite value from a maybe-nil value. Returns nil if the base is nil."
  @spec maybe_sub_definite(float() | nil, float()) :: float() | nil
  def maybe_sub_definite(nil, _), do: nil
  def maybe_sub_definite(a, b), do: a - b

  @doc "Returns the value or a default if nil."
  @spec or_else(float() | nil, float()) :: float()
  def or_else(nil, default), do: default
  def or_else(val, _default), do: val
end
