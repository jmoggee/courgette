# Animation

## Tween

`Courgette.Animation.Tween` — value interpolation over time with easing.

### Creating a Tween

```elixir
alias Courgette.Animation.Tween

tween = Tween.new(0, 100, duration: 500, easing: :ease_out)
```

Options:
- `:duration` (required) — milliseconds
- `:easing` — atom or function (default `:linear`)
- `:clock` — zero-arity function returning monotonic time in ms (injectable for testing)

### Stepping

```elixir
case Tween.step(tween) do
  {:running, value, updated_tween} -> # animation in progress
  {:done, final_value}              -> # animation complete
end
```

`step/1` records `started_at` on first call, then reads the clock on each subsequent call.

### Other Functions

- `Tween.value(tween)` — peek at current value without side effects
- `Tween.reset(tween)` — clear `started_at` for re-use

### Timer Helpers

Manage a one-shot `Process.send_after/3` timer (~60fps, 16ms interval):

```elixir
# Default timer (sends :tween_tick)
assigns = Tween.start_timer(assigns)
assigns = Tween.stop_timer(assigns)

# Named timer (sends :opacity_tick)
assigns = Tween.start_timer(assigns, :opacity)
assigns = Tween.stop_timer(assigns, :opacity)
```

### Complete Pattern

```elixir
def mount(_assigns) do
  if Courgette.animations_enabled?() do
    tween = Tween.new(0, 100, duration: 500, easing: :ease_out)
    {:ok, %{tween: tween, progress: 0} |> Tween.start_timer()}
  else
    {:ok, %{progress: 100}}
  end
end

def handle_info(:tween_tick, assigns) do
  case Tween.step(assigns.tween) do
    {:running, value, tween} ->
      {:noreply, assigns |> assign(tween: tween, progress: value) |> Tween.start_timer()}
    {:done, value} ->
      {:noreply, assigns |> assign(progress: value) |> Tween.stop_timer()}
  end
end
```

## Frames

`Courgette.Animation.Frames` — discrete frame cycling for spinners and looping animations.

```elixir
alias Courgette.Animation.Frames

frames = Frames.new(["a", "b", "c"])
Frames.current(frames)             # "a"
{frame, frames} = Frames.next(frames)  # {"a", updated}
frames = Frames.reset(frames)      # back to index 0
```

### Built-in Frame Sets

```elixir
Frames.dots()         # ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
Frames.circle()       # ◐ ◓ ◑ ◒
Frames.wave()         # ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃ ▂
Frames.line()         # - \ | /
Frames.ellipsis()     # . .. ... (space)
```

Many more: `dots_pulse`, `dots_orbit`, `sand`, `arc`, `triangle`, `pulse`, `meter`, `star`, `arrow`, `bounce`, etc.

## Easing Functions

`Courgette.Animation.Easing` — pure math functions mapping `0.0..1.0` to eased output.

Available easings:
- `:linear` — `t`
- `:ease_in` — quadratic `t²`
- `:ease_out` — quadratic `1-(1-t)²`
- `:ease_in_out` — piecewise quadratic
- `:ease_in_cubic` — `t³`
- `:ease_out_cubic` — `1-(1-t)³`
- `:bounce_out` — Penner bounce
- `:elastic_out` — elastic overshoot

Custom: pass any `(float -> float)` function to `Tween.new/3`.

## Disabling Animations in Tests

```elixir
# In test_helper.exs:
Application.put_env(:courgette, :animations_enabled, false)
```

Components should check `Courgette.animations_enabled?()` in `mount/1` to skip timers.

## Common Mistakes

- **Forgetting `Tween.stop_timer/1` on completion** — leaves a dangling timer reference in assigns.
- **Not checking `animations_enabled?()` in mount** — tests will have timers firing and may be flaky.
- **Using `Tween.step/1` without `start_timer`** — step reads the clock but doesn't schedule the next tick. You must call `start_timer` after each `:running` step.
