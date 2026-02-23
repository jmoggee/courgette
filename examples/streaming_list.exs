# examples/streaming_list.exs
#
# Simulates streaming log data in a scrollable list.
# Items arrive on a timer and the list auto-scrolls to the bottom.
# Arrow keys and mouse wheel scroll; space pauses/resumes; q quits.
#
# Run with: mix run examples/streaming_list.exs

defmodule StreamingList do
  use Courgette.App

  alias Courgette.Components.ScrollArea

  @tick_ms 250
  @max_items 200

  @messages [
    "Connection established from 192.168.1.42",
    "Processing request POST /api/events",
    "Query completed in 12ms (3 rows)",
    "Cache miss for /api/users/831",
    "Worker pool scaled to 4 threads",
    "Health check passed (latency: 2ms)",
    "Metrics batch flushed (128 points)",
    "Session expired for user_7291",
    "Rate limit reset for client_api_3",
    "Backup snapshot saved (2.4 GB)",
    "TLS handshake completed",
    "Index rebuilt in 84ms",
    "Deployment v2.3.1 rolling out",
    "GC freed 128MB in gen1",
    "DNS TTL refresh for api.example.com",
    "WebSocket connection closed (code: 1000)",
    "Config reload triggered by SIGHUP",
    "Disk usage at 72% on /data",
    "New node joined cluster (node_5)",
    "Scheduled job completed: daily_report"
  ]

  def mount(_assigns) do
    schedule_tick()
    {:ok, %{items: [], counter: 0, streaming: true, scroll_offset: 0, pinned: true}}
  end

  def render(assigns) do
    {_cols, rows} = Courgette.Terminal.size()
    viewport_h = rows - 3
    status = if assigns.streaming, do: "● LIVE", else: "■ PAUSED"
    status_color = if assigns.streaming, do: :green, else: :yellow
    status_text = "#{status}  #{assigns.counter} events "

    box flex_direction: :column do
      box height: 1, padding_h: 1, flex_direction: :row do
        text bold: true, color: :cyan, do: "Streaming Data"

        box flex: 1, justify_content: :flex_end do
          text color: status_color, do: status_text
        end
      end

      live_component(ScrollArea,
        id: "log",
        height: viewport_h,
        scroll_offset: assigns.scroll_offset,
        on_scroll: :scroll_changed,
        border: :rounded,
        border_color: :bright_black,
        focusable: true
      ) do
        if assigns.items == [] do
          text color: :bright_black, do: "  Waiting for data..."
        end

        for item <- assigns.items do
          text color: item.color, do: "  #{item.text}"
        end
      end

      box height: 1, padding_h: 1 do
        text color: :bright_black,
            do: " [↑/↓] scroll  [space] pause/resume  [q] quit"
      end
    end
  end

  def handle_event({:resize, _cols, rows}, assigns) do
    viewport_h = rows - 3
    item_count = length(assigns.items)
    max_off = max(0, item_count - viewport_h)
    offset = if assigns.pinned, do: max_off, else: min(assigns.scroll_offset, max_off)
    {:noreply, assign(assigns, scroll_offset: offset)}
  end

  def handle_event({:key, {:char, " "}}, assigns) do
    streaming = !assigns.streaming
    if streaming, do: schedule_tick()
    {:noreply, assign(assigns, :streaming, streaming)}
  end

  def handle_event({:key, {:char, "q"}}, assigns) do
    Courgette.stop()
    {:noreply, assigns}
  end

  def handle_event({:key, {:ctrl, {:char, "c"}}}, assigns) do
    Courgette.stop()
    {:noreply, assigns}
  end

  def handle_event(_event, assigns), do: {:noreply, assigns}

  def handle_info(:tick, assigns) do
    if assigns.streaming do
      schedule_tick()
      counter = assigns.counter + 1
      item = generate_item()
      items = assigns.items ++ [item]
      items = if length(items) > @max_items, do: tl(items), else: items
      item_count = length(items)
      assigns = assign(assigns, items: items, counter: counter)

      assigns =
        if assigns.pinned do
          {_cols, rows} = Courgette.Terminal.size()
          viewport_h = rows - 3
          assign(assigns, :scroll_offset, max(0, item_count - viewport_h))
        else
          assigns
        end

      {:noreply, assigns}
    else
      {:noreply, assigns}
    end
  end

  def handle_info({:scroll_changed, offset}, assigns) do
    {_cols, rows} = Courgette.Terminal.size()
    viewport_h = rows - 3
    max_off = max(0, length(assigns.items) - viewport_h)
    {:noreply, assign(assigns, scroll_offset: offset, pinned: offset >= max_off)}
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @tick_ms)

  defp generate_item do
    {level, color} =
      Enum.random([
        {:info, :green},
        {:info, :green},
        {:info, :green},
        {:debug, :cyan},
        {:debug, :cyan},
        {:warn, :yellow},
        {:error, :red}
      ])

    tag = level |> Atom.to_string() |> String.upcase() |> String.pad_trailing(5)
    message = Enum.random(@messages)
    ts = Time.utc_now() |> Time.to_string() |> String.slice(0, 12)

    %{text: "[#{ts}] #{tag}  #{message}", color: color}
  end
end

Courgette.run(StreamingList)
