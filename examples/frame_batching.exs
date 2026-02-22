# examples/frame_batching.exs
#
# Frame batching with rapid self-ticking updates.
#
# A counter that increments every 50ms (20 updates/sec) via
# Process.send_after. The Renderer batches these at ~60 FPS,
# so many updates collapse into a single render per frame.
#
# Press q to quit.
#
# Run with: mix run examples/frame_batching.exs

defmodule Example.FrameBatching do
  use Courgette.App

  @tick_ms 50

  @impl true
  def mount(_assigns) do
    schedule_tick()
    {:ok, %{count: 0, renders: 0, started_at: System.monotonic_time(:millisecond)}}
  end

  @impl true
  def render(assigns) do
    elapsed_s = max(1, System.monotonic_time(:millisecond) - assigns.started_at) / 1000
    ups = Float.round(assigns.count / elapsed_s, 1)

    box border: :rounded, flex_direction: :column, padding: 1 do
      text bold: true, color: :cyan do
        "Frame Batching Demo"
      end

      text do
        ""
      end

      box flex_direction: :row do
        text color: :yellow do
          "Counter: "
        end

        text bold: true, color: :green do
          "#{assigns.count}"
        end
      end

      box flex_direction: :row do
        text color: :yellow do
          "Updates/sec: "
        end

        text color: :white do
          "#{ups}"
        end
      end

      text do
        ""
      end

      text color: :bright_black do
        "Counter ticks every #{@tick_ms}ms — renderer batches at 60 FPS"
      end

      text color: :bright_black do
        "q to quit"
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop()
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info(:tick, assigns) do
    schedule_tick()
    {:noreply, %{assigns | count: assigns.count + 1}}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end
end

Courgette.run(Example.FrameBatching)
