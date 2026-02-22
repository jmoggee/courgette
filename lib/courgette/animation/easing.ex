defmodule Courgette.Animation.Easing do
  @moduledoc """
  Pure math easing functions for animation.

  Each function maps a progress value `t` in `0.0..1.0` to an eased output.
  Input is clamped to `[0.0, 1.0]`. Output may overshoot for elastic/bounce.

  Use `apply/2` to dispatch by atom name or pass a custom function.
  """

  @doc """
  Apply an easing function to a progress value.

  Accepts an atom naming a built-in easing or a 1-arity function.

      iex> Easing.apply(:linear, 0.5)
      0.5

      iex> Easing.apply(fn t -> t * t * t end, 0.5)
      0.125
  """
  @spec apply(atom() | (float() -> float()), float()) :: float()
  def apply(easing, t) when is_function(easing, 1) do
    easing.(clamp(t))
  end

  def apply(name, t) when is_atom(name) do
    Kernel.apply(__MODULE__, name, [clamp(t)])
  end

  @doc "Linear: `t`"
  @spec linear(float()) :: float()
  def linear(t), do: clamp(t)

  @doc "Quadratic ease-in: `t²`"
  @spec ease_in(float()) :: float()
  def ease_in(t) do
    t = clamp(t)
    t * t
  end

  @doc "Quadratic ease-out: `1 - (1-t)²`"
  @spec ease_out(float()) :: float()
  def ease_out(t) do
    t = clamp(t)
    1.0 - (1.0 - t) * (1.0 - t)
  end

  @doc "Quadratic ease-in-out: piecewise quadratic"
  @spec ease_in_out(float()) :: float()
  def ease_in_out(t) do
    t = clamp(t)

    if t < 0.5 do
      2.0 * t * t
    else
      1.0 - (-2.0 * t + 2.0) * (-2.0 * t + 2.0) / 2.0
    end
  end

  @doc "Cubic ease-in: `t³`"
  @spec ease_in_cubic(float()) :: float()
  def ease_in_cubic(t) do
    t = clamp(t)
    t * t * t
  end

  @doc "Cubic ease-out: `1 - (1-t)³`"
  @spec ease_out_cubic(float()) :: float()
  def ease_out_cubic(t) do
    t = clamp(t)
    inv = 1.0 - t
    1.0 - inv * inv * inv
  end

  @doc "Bounce out: 4-segment Penner formula"
  @spec bounce_out(float()) :: float()
  def bounce_out(t) do
    t = clamp(t)
    n1 = 7.5625
    d1 = 2.75

    cond do
      t < 1.0 / d1 ->
        n1 * t * t

      t < 2.0 / d1 ->
        t = t - 1.5 / d1
        n1 * t * t + 0.75

      t < 2.5 / d1 ->
        t = t - 2.25 / d1
        n1 * t * t + 0.9375

      true ->
        t = t - 2.625 / d1
        n1 * t * t + 0.984375
    end
  end

  @doc "Elastic out: `2^(-10t) * sin(...) + 1`"
  @spec elastic_out(float()) :: float()
  def elastic_out(t) do
    t = clamp(t)

    cond do
      t == 0.0 -> 0.0
      t == 1.0 -> 1.0
      true ->
        c4 = 2.0 * :math.pi() / 3.0
        :math.pow(2.0, -10.0 * t) * :math.sin((t * 10.0 - 0.75) * c4) + 1.0
    end
  end

  defp clamp(t) when t < 0.0, do: 0.0
  defp clamp(t) when t > 1.0, do: 1.0
  defp clamp(t), do: t + 0.0
end
