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

  @frames %{
    dots: ~w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏),
    line: ~w(- \\ | /),
    circle: ~w(◐ ◓ ◑ ◒),
    wave: ~w(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃ ▂),
    bounce: ~w(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈)
  }

  @impl true
  def mount(assigns) do
    assigns =
      assigns
      |> assign_new(:style, fn -> :dots end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:color, fn -> :cyan end)
      |> assign_new(:interval, fn -> 80 end)
      |> assign(:frame, 0)

    schedule_tick(assigns.interval)
    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    frames = Map.fetch!(@frames, assigns.style)
    char = Enum.at(frames, assigns.frame)

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
    frames = Map.fetch!(@frames, assigns.style)
    next_frame = rem(assigns.frame + 1, length(frames))
    schedule_tick(assigns.interval)
    {:noreply, assign(assigns, :frame, next_frame)}
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
end
