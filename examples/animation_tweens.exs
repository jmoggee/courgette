# examples/animation_tweens.exs
#
# Demonstrates the Animation module trio:
# - Tween: smooth value interpolation with easing
# - Frames: discrete frame cycling (refactored Spinner)
# - Easing: various easing curves
#
# Shows a progress bar animated from 0→100% using Tween,
# with multiple easing styles cycling on each completion.
#
# Press 'q' to quit, 'r' to restart animation.
#
# Run: mix run examples/animation_tweens.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Animation.{Tween, Frames, Easing}
alias Courgette.Components.{ProgressBar, Spinner}

defmodule AnimationDemo do
  use Courgette.App

  @easings [:linear, :ease_in, :ease_out, :ease_in_out, :ease_in_cubic, :ease_out_cubic, :bounce_out, :elastic_out]

  @impl true
  def mount(_assigns) do
    easing_frames = Frames.new(@easings)
    easing = Frames.current(easing_frames)

    tween = Tween.new(0.0, 1.0, duration: 2000, easing: easing)
    assigns = %{
      tween: tween,
      progress: 0.0,
      easing_frames: easing_frames,
      easing_name: easing,
      cycle_count: 0
    }

    assigns = Tween.start_timer(assigns)
    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    bar_width = 40

    box flex_direction: :column do
      text bold: true, fg: :yellow do
        "Animation System Demo"
      end

      text fg: :white, dim: true do
        "q: quit | r: restart current | Cycles through easings automatically"
      end

      # Current easing label
      box padding_v: 1 do
        text fg: :cyan, bold: true do
          "Easing: #{assigns.easing_name}"
        end

        text fg: :white, dim: true do
          "  (cycle #{assigns.cycle_count + 1}/#{length(@easings)})"
        end
      end

      # Animated progress bar
      live_component(ProgressBar,
        id: "anim_bar",
        value: assigns.progress,
        width: bar_width,
        color: :green,
        label: :percent
      )

      # Value display
      box padding_v: 1 do
        text fg: :white do
          "Value: #{Float.round(assigns.progress * 100, 1)}%"
        end
      end

      # Spinner still works with Frames internally
      box flex_direction: :row do
        text fg: :white do
          "Spinner (using Frames): "
        end

        live_component(Spinner,
          id: "spin",
          style: :dots,
          label: "working...",
          color: :magenta
        )
      end

      # Easing function table
      box padding_v: 1 do
        text bold: true, fg: :white do
          "Easing samples at t=0.5:"
        end

        for name <- @easings do
          val = Easing.apply(name, 0.5)
          marker = if name == assigns.easing_name, do: "▸ ", else: "  "
          color = if name == assigns.easing_name, do: :cyan, else: :white

          text fg: color do
            "#{marker}#{name}: #{Float.round(val, 3)}"
          end
        end
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop(self())
    {:noreply, %{}}
  end

  def handle_event({:key, {:char, "r"}}, assigns) do
    tween = Tween.new(0.0, 1.0, duration: 2000, easing: assigns.easing_name)
    assigns = assign(assigns, tween: tween, progress: 0.0)
    assigns = Tween.start_timer(assigns)
    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info(:tween_tick, assigns) do
    case Tween.step(assigns.tween) do
      {:running, value, tween} ->
        assigns = assign(assigns, tween: tween, progress: value)
        assigns = Tween.start_timer(assigns)
        {:noreply, assigns}

      {:done, value} ->
        assigns = Tween.stop_timer(assigns)

        # Advance to next easing
        {_current, easing_frames} = Frames.next(assigns.easing_frames)
        next_easing = Frames.current(easing_frames)

        # Start new tween with next easing after brief pause
        tween = Tween.new(0.0, 1.0, duration: 2000, easing: next_easing)

        assigns = assign(assigns,
          progress: value,
          easing_frames: easing_frames,
          easing_name: next_easing,
          tween: tween,
          cycle_count: assigns.cycle_count + 1
        )

        # Brief pause then restart
        Process.send_after(self(), :restart_tween, 500)
        {:noreply, assigns}
    end
  end

  def handle_info(:restart_tween, assigns) do
    assigns = assign(assigns, progress: 0.0)
    tween = Tween.reset(assigns.tween)
    assigns = assign(assigns, tween: tween)
    assigns = Tween.start_timer(assigns)
    {:noreply, assigns}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(AnimationDemo)
