defmodule Courgette.Components.Spinner do
  @moduledoc """
  Animated activity indicator.

  Self-ticking component that cycles through animation frames using
  `Process.send_after/3`. No keyboard interaction.

  ## Props

  - `style` — `:dots`, `:line`, `:circle`, `:wave`, `:bounce` (default `:dots`)
  - `label` — optional text after the spinner character
  - `color` — spinner color (default `:cyan`)
  - `interval` — tick interval in ms (default 80)
  """

  use Courgette.LiveComponent

  alias Courgette.Animation.Frames

  @impl true
  def mount(assigns) do
    assigns =
      assigns
      |> assign_new(:style, fn -> :dots end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:color, fn -> :cyan end)
      |> assign_new(:interval, fn -> 80 end)

    frames = frames_for_style(assigns.style)
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

  defp frames_for_style(:dots), do: Frames.dots()
  defp frames_for_style(:line), do: Frames.line()
  defp frames_for_style(:circle), do: Frames.circle()
  defp frames_for_style(:wave), do: Frames.wave()
  defp frames_for_style(:bounce), do: Frames.bounce()
end
