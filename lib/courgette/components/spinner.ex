defmodule Courgette.Components.Spinner do
  @moduledoc """
  Animated activity indicator.

  Self-ticking component that cycles through animation frames using
  `Process.send_after/3`. No keyboard interaction.

  ## Props

  - `style` — spinner style atom (default `:dots`). See styles below.
  - `frames` — a `Frames` struct for custom frame sequences. Overrides `style`.
  - `label` — optional text after the spinner character
  - `color` — spinner color (default `:cyan`)
  - `interval` — tick interval in ms (default 80)

  ## Styles

  Braille family:
  - `:dots` — classic braille rotation
  - `:dots_pulse` — braille fills up then empties, breathing effect
  - `:dots_orbit` — single dot tracing the 6 braille positions
  - `:dots_scroll` — dense braille rotation, one gap sweeps around
  - `:dots_bounce` — braille wave that swells and recedes
  - `:sand` — hourglass: fills from top, empties from bottom
  - `:braille_double` — two dots orbiting together
  - `:braille_six` — inverse: one missing dot sweeps around
  - `:braille_eight_double` — full 8-dot with two gaps sweeping

  Geometric family:
  - `:circle` — half-circle rotation
  - `:arc` — smooth arc sweeping around
  - `:triangle` — rotating filled corner
  - `:quarter` — quarter-circle rotation
  - `:box_bounce` — quadrant block bouncing around corners
  - `:pipe` — box-drawing corner rotation
  - `:box_invert` — inverse of box_bounce, three quadrants filled
  - `:square_corners` — quarter-filled squares rotating

  Block family:
  - `:wave` — vertical block elements pulse up and down
  - `:pulse` — block density fade: solid to light and back
  - `:meter` — three-segment bar that fills and empties
  - `:grow_horizontal` — horizontal block element grows and shrinks
  - `:noise` — static/interference flicker
  - `:layer` — accumulating horizontal lines

  Classic:
  - `:line` — ASCII line rotation
  - `:star` — twinkling star
  - `:point` — dot traveling across three positions
  - `:bounce` — single braille dot orbiting
  - `:arrow` — arrow rotating through 8 compass directions
  - `:ellipsis` — the universal thinking indicator
  - `:hamburger` — trigram lines
  """

  use Courgette.LiveComponent

  alias Courgette.Animation.Frames

  @impl true
  def mount(assigns) do
    assigns =
      assigns
      |> assign_new(:style, fn -> :dots end)
      |> assign_new(:frames, fn -> nil end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:color, fn -> :cyan end)
      |> assign_new(:interval, fn -> 80 end)

    frames = assigns.frames || frames_for_style(assigns.style)
    assigns = assign(assigns, :frames, frames)

    schedule_tick(assigns.interval)
    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    char = Frames.current(assigns.frames)

    box flex_direction: :row do
      text fg: assigns.color do
        char
      end

      if assigns.label do
        text(do: " #{assigns.label}")
      end
    end
  end

  @impl true
  def handle_info(:tick, assigns) do
    {_frame, frames} = Frames.next(assigns.frames)
    schedule_tick(assigns.interval)
    {:noreply, assign(assigns, :frames, frames)}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def update(props, assigns) do
    {:ok, Map.merge(assigns, props)}
  end

  defp schedule_tick(interval) do
    Process.send_after(self(), :tick, interval)
  end

  # Braille family
  defp frames_for_style(:dots), do: Frames.dots()
  defp frames_for_style(:dots_pulse), do: Frames.dots_pulse()
  defp frames_for_style(:dots_orbit), do: Frames.dots_orbit()
  defp frames_for_style(:dots_scroll), do: Frames.dots_scroll()
  defp frames_for_style(:dots_bounce), do: Frames.dots_bounce()
  defp frames_for_style(:sand), do: Frames.sand()
  defp frames_for_style(:braille_double), do: Frames.braille_double()
  defp frames_for_style(:braille_six), do: Frames.braille_six()
  defp frames_for_style(:braille_eight_double), do: Frames.braille_eight_double()
  # Geometric family
  defp frames_for_style(:circle), do: Frames.circle()
  defp frames_for_style(:arc), do: Frames.arc()
  defp frames_for_style(:triangle), do: Frames.triangle()
  defp frames_for_style(:quarter), do: Frames.quarter()
  defp frames_for_style(:box_bounce), do: Frames.box_bounce()
  defp frames_for_style(:pipe), do: Frames.pipe()
  defp frames_for_style(:box_invert), do: Frames.box_invert()
  defp frames_for_style(:square_corners), do: Frames.square_corners()
  # Block family
  defp frames_for_style(:wave), do: Frames.wave()
  defp frames_for_style(:pulse), do: Frames.pulse()
  defp frames_for_style(:meter), do: Frames.meter()
  defp frames_for_style(:grow_horizontal), do: Frames.grow_horizontal()
  defp frames_for_style(:noise), do: Frames.noise()
  defp frames_for_style(:layer), do: Frames.layer()
  # Classic
  defp frames_for_style(:line), do: Frames.line()
  defp frames_for_style(:star), do: Frames.star()
  defp frames_for_style(:point), do: Frames.point()
  defp frames_for_style(:bounce), do: Frames.bounce()
  defp frames_for_style(:arrow), do: Frames.arrow()
  defp frames_for_style(:ellipsis), do: Frames.ellipsis()
  defp frames_for_style(:hamburger), do: Frames.hamburger()
end
