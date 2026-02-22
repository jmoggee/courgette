defmodule Courgette.Animation.Tween do
  @moduledoc """
  Value interpolation with wall clock for smooth animation.

  A tween interpolates a numeric value from `from` to `to` over `duration`
  milliseconds using an easing function. The clock is injectable for testing.

  ## Usage

      tween = Tween.new(0, 100, duration: 500, easing: :ease_out)
      assigns = assigns |> assign(:tween, tween) |> Tween.start_timer()

      # In handle_info:
      case Tween.step(assigns.tween) do
        {:running, value, tween} ->
          assigns |> assign(tween: tween, progress: value) |> Tween.start_timer()
        {:done, value} ->
          assigns |> assign(progress: value) |> Tween.stop_timer()
      end

  ## Timer Helpers

  `start_timer/1` and `stop_timer/1` manage a one-shot `Process.send_after/3`
  timer that sends `:tween_tick` in 16ms (~60fps). Named variants
  `start_timer/2` and `stop_timer/2` use `{name}_tick` atoms for multiple
  concurrent tweens.
  """

  alias Courgette.Animation.Easing

  defstruct [:from, :to, :duration, :easing, :started_at, :clock]

  @type t :: %__MODULE__{
          from: number(),
          to: number(),
          duration: pos_integer(),
          easing: atom() | (float() -> float()),
          started_at: integer() | nil,
          clock: (-> integer())
        }

  @tick_interval 16

  @doc """
  Create a new tween.

  ## Options

  - `:duration` (required) — duration in milliseconds
  - `:easing` — easing function atom or function (default `:linear`)
  - `:clock` — zero-arity function returning monotonic time in ms (default `System.monotonic_time(:millisecond)`)
  """
  @spec new(number(), number(), keyword()) :: t()
  def new(from, to, opts) do
    duration = Keyword.fetch!(opts, :duration)
    easing = Keyword.get(opts, :easing, :linear)
    clock = Keyword.get(opts, :clock, fn -> System.monotonic_time(:millisecond) end)

    %__MODULE__{
      from: from,
      to: to,
      duration: duration,
      easing: easing,
      started_at: nil,
      clock: clock
    }
  end

  @doc """
  Advance the tween by reading the clock.

  On first call, records `started_at`. Returns `{:running, value, tween}`
  while in progress, or `{:done, to_value}` when complete.
  """
  @spec step(t()) :: {:running, number(), t()} | {:done, number()}
  def step(%__MODULE__{} = tween) do
    now = tween.clock.()
    tween = if tween.started_at == nil, do: %{tween | started_at: now}, else: tween
    elapsed = now - tween.started_at

    if elapsed >= tween.duration do
      {:done, tween.to}
    else
      progress = elapsed / tween.duration
      eased = Easing.apply(tween.easing, progress)
      value = tween.from + (tween.to - tween.from) * eased
      {:running, value, tween}
    end
  end

  @doc """
  Peek at the current value without side effects.

  Does not set `started_at` if it hasn't been set yet (returns `from` in that case).
  """
  @spec value(t()) :: number()
  def value(%__MODULE__{started_at: nil} = tween), do: tween.from

  def value(%__MODULE__{} = tween) do
    now = tween.clock.()
    elapsed = now - tween.started_at

    if elapsed >= tween.duration do
      tween.to
    else
      progress = elapsed / tween.duration
      eased = Easing.apply(tween.easing, progress)
      tween.from + (tween.to - tween.from) * eased
    end
  end

  @doc """
  Reset the tween for re-use. Clears `started_at`.
  """
  @spec reset(t()) :: t()
  def reset(%__MODULE__{} = tween) do
    %{tween | started_at: nil}
  end

  # --- Timer helpers ---

  @doc """
  Schedule a `:tween_tick` message in #{@tick_interval}ms.

  Stores the timer reference in `assigns.__tween_timer__` so it can be
  cancelled later with `stop_timer/1`.
  """
  @spec start_timer(map()) :: map()
  def start_timer(assigns) do
    ref = Process.send_after(self(), :tween_tick, @tick_interval)
    Map.put(assigns, :__tween_timer__, ref)
  end

  @doc """
  Schedule a named tick message in #{@tick_interval}ms.

  For a name of `:opacity`, sends `:opacity_tick` and stores the ref
  in `assigns.__opacity_timer__`.
  """
  @spec start_timer(map(), atom()) :: map()
  def start_timer(assigns, name) do
    tick_msg = :"#{name}_tick"
    timer_key = :"__#{name}_timer__"
    ref = Process.send_after(self(), tick_msg, @tick_interval)
    Map.put(assigns, timer_key, ref)
  end

  @doc """
  Cancel the default tween timer.
  """
  @spec stop_timer(map()) :: map()
  def stop_timer(assigns) do
    case Map.get(assigns, :__tween_timer__) do
      nil -> assigns
      ref ->
        Process.cancel_timer(ref)
        Map.delete(assigns, :__tween_timer__)
    end
  end

  @doc """
  Cancel a named tween timer.
  """
  @spec stop_timer(map(), atom()) :: map()
  def stop_timer(assigns, name) do
    timer_key = :"__#{name}_timer__"

    case Map.get(assigns, timer_key) do
      nil -> assigns
      ref ->
        Process.cancel_timer(ref)
        Map.delete(assigns, timer_key)
    end
  end
end
