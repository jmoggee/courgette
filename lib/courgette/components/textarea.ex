defmodule Courgette.Components.Textarea do
  @moduledoc """
  Multi-line text editor with cursor and readline shortcuts.

  Stores text as a list of grapheme lists (one per line). Supports character
  insertion, line splitting/joining, cursor navigation with desired_col
  stickiness, word movement, readline kill operations, and scrolling.

  ## Props

  - `value` — initial text, may contain `\\n` (default "")
  - `placeholder` — shown when empty and unfocused (default "")
  - `on_change` — message tag sent on every edit (optional)
  - `height` — total height in rows including border (default 10)
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    value = assigns[:value] || ""
    lines = string_to_lines(value)
    last_line = length(lines) - 1
    last_col = length(Enum.at(lines, last_line))

    {:ok,
     assigns
     |> assign(:value, value)
     |> assign(:lines, lines)
     |> assign(:cursor_line, last_line)
     |> assign(:cursor_col, last_col)
     |> assign(:desired_col, last_col)
     |> assign(:scroll_offset, 0)
     |> assign_new(:placeholder, fn -> "" end)
     |> assign_new(:on_change, fn -> nil end)
     |> assign_new(:height, fn -> 10 end)
     |> assign_new(:focused, fn -> false end)
     |> ensure_cursor_visible()}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    cond do
      assigns.focused -> render_focused(assigns, border_color)
      assigns.value == "" -> render_placeholder(assigns, border_color)
      true -> render_readonly(assigns, border_color)
    end
  end

  defp render_focused(assigns, border_color) do
    visible_height = max(assigns.height - 2, 1)
    offset = assigns.scroll_offset
    visible_lines = Enum.slice(assigns.lines, offset, visible_height)

    box border: :single, border_color: border_color, flex_direction: :column, height: assigns.height do
      for {line_graphemes, idx} <- Enum.with_index(visible_lines) do
        render_visible_line(line_graphemes, idx + offset, assigns.cursor_line, assigns.cursor_col)
      end
    end
  end

  defp render_placeholder(assigns, border_color) do
    box border: :single, border_color: border_color, height: assigns.height do
      text dim: true do
        assigns.placeholder
      end
    end
  end

  defp render_readonly(assigns, border_color) do
    box border: :single, border_color: border_color, flex_direction: :column, height: assigns.height do
      for line_graphemes <- assigns.lines do
        render_plain_line(line_graphemes)
      end
    end
  end

  defp render_visible_line(line_graphemes, actual_line, cursor_line, cursor_col) do
    if actual_line == cursor_line do
      render_cursor_line(line_graphemes, cursor_col)
    else
      render_plain_line(line_graphemes)
    end
  end

  defp render_plain_line(line_graphemes) do
    content = if line_graphemes == [], do: " ", else: Enum.join(line_graphemes)

    box flex_direction: :row do
      text(do: content)
    end
  end

  defp render_cursor_line(graphemes, col) do
    before = Enum.slice(graphemes, 0, col) |> Enum.join()
    cursor_char = Enum.at(graphemes, col)
    after_cursor = Enum.slice(graphemes, (col + 1)..-1//1) |> Enum.join()

    box flex_direction: :row do
      if before != "" do
        text(do: before)
      end

      if cursor_char do
        text reverse: true do
          cursor_char
        end
      else
        text reverse: true do
          " "
        end
      end

      if after_cursor != "" do
        text(do: after_cursor)
      end
    end
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :value) && props.value != assigns.value do
        lines = string_to_lines(props.value)
        last_line = length(lines) - 1
        last_col = length(Enum.at(lines, last_line))

        new_assigns
        |> assign(:lines, lines)
        |> assign(:cursor_line, last_line)
        |> assign(:cursor_col, last_col)
        |> assign(:desired_col, last_col)
        |> assign(:scroll_offset, 0)
      else
        new_assigns
      end

    {:ok, new_assigns}
  end

  # --- Focus ---

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  # --- Character insertion ---

  def handle_event({:key, {:char, ch}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    new_line = List.insert_at(line, assigns.cursor_col, ch)
    new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)
    new_col = assigns.cursor_col + 1

    assigns
    |> assign(:lines, new_lines)
    |> set_cursor(assigns.cursor_line, new_col)
    |> sync_value()
    |> notify_change()
    |> noreply()
  end

  # --- Enter (line split) ---

  def handle_event({:key, :enter}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    before = Enum.slice(line, 0, assigns.cursor_col)
    after_cursor = Enum.slice(line, assigns.cursor_col..-1//1)

    new_lines =
      assigns.lines
      |> List.replace_at(assigns.cursor_line, before)
      |> List.insert_at(assigns.cursor_line + 1, after_cursor)

    assigns
    |> assign(:lines, new_lines)
    |> set_cursor(assigns.cursor_line + 1, 0)
    |> ensure_cursor_visible()
    |> sync_value()
    |> notify_change()
    |> noreply()
  end

  # --- Backspace ---

  def handle_event({:key, :backspace}, assigns) do
    cond do
      assigns.cursor_col > 0 ->
        line = Enum.at(assigns.lines, assigns.cursor_line)
        new_line = List.delete_at(line, assigns.cursor_col - 1)
        new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

        assigns
        |> assign(:lines, new_lines)
        |> set_cursor(assigns.cursor_line, assigns.cursor_col - 1)
        |> sync_value()
        |> notify_change()
        |> noreply()

      assigns.cursor_line > 0 ->
        prev_line = Enum.at(assigns.lines, assigns.cursor_line - 1)
        curr_line = Enum.at(assigns.lines, assigns.cursor_line)
        joined = prev_line ++ curr_line
        new_col = length(prev_line)

        new_lines =
          assigns.lines
          |> List.replace_at(assigns.cursor_line - 1, joined)
          |> List.delete_at(assigns.cursor_line)

        assigns
        |> assign(:lines, new_lines)
        |> set_cursor(assigns.cursor_line - 1, new_col)
        |> ensure_cursor_visible()
        |> sync_value()
        |> notify_change()
        |> noreply()

      true ->
        {:noreply, assigns}
    end
  end

  # --- Delete ---

  def handle_event({:key, :delete}, assigns) do
    handle_delete(assigns)
  end

  # --- Arrow navigation ---

  def handle_event({:key, :arrow_left}, assigns) do
    cond do
      assigns.cursor_col > 0 ->
        assigns
        |> set_cursor(assigns.cursor_line, assigns.cursor_col - 1)
        |> noreply()

      assigns.cursor_line > 0 ->
        prev_len = length(Enum.at(assigns.lines, assigns.cursor_line - 1))

        assigns
        |> set_cursor(assigns.cursor_line - 1, prev_len)
        |> ensure_cursor_visible()
        |> noreply()

      true ->
        {:noreply, assigns}
    end
  end

  def handle_event({:key, :arrow_right}, assigns) do
    line_len = length(Enum.at(assigns.lines, assigns.cursor_line))
    last_line = length(assigns.lines) - 1

    cond do
      assigns.cursor_col < line_len ->
        assigns
        |> set_cursor(assigns.cursor_line, assigns.cursor_col + 1)
        |> noreply()

      assigns.cursor_line < last_line ->
        assigns
        |> set_cursor(assigns.cursor_line + 1, 0)
        |> ensure_cursor_visible()
        |> noreply()

      true ->
        {:noreply, assigns}
    end
  end

  def handle_event({:key, :arrow_up}, assigns) do
    move_vertical(assigns, -1) |> noreply()
  end

  def handle_event({:key, :arrow_down}, assigns) do
    move_vertical(assigns, 1) |> noreply()
  end

  # --- Home / End ---

  def handle_event({:key, :home}, assigns) do
    assigns |> set_cursor(assigns.cursor_line, 0) |> noreply()
  end

  def handle_event({:key, :end}, assigns) do
    line_len = length(Enum.at(assigns.lines, assigns.cursor_line))
    assigns |> set_cursor(assigns.cursor_line, line_len) |> noreply()
  end

  # --- Page Up / Page Down ---

  def handle_event({:key, :page_up}, assigns) do
    visible = visible_height(assigns)
    new_line = max(assigns.cursor_line - (visible - 1), 0)
    move_to_line(assigns, new_line) |> noreply()
  end

  def handle_event({:key, :page_down}, assigns) do
    visible = visible_height(assigns)
    last = length(assigns.lines) - 1
    new_line = min(assigns.cursor_line + (visible - 1), last)
    move_to_line(assigns, new_line) |> noreply()
  end

  # --- Readline Navigation ---

  def handle_event({:key, {:ctrl, "a"}}, assigns) do
    assigns |> set_cursor(assigns.cursor_line, 0) |> noreply()
  end

  def handle_event({:key, {:ctrl, "e"}}, assigns) do
    line_len = length(Enum.at(assigns.lines, assigns.cursor_line))
    assigns |> set_cursor(assigns.cursor_line, line_len) |> noreply()
  end

  def handle_event({:key, {:ctrl, "p"}}, assigns) do
    move_vertical(assigns, -1) |> noreply()
  end

  def handle_event({:key, {:ctrl, "n"}}, assigns) do
    move_vertical(assigns, 1) |> noreply()
  end

  def handle_event({:key, {:ctrl, "f"}}, assigns) do
    handle_event({:key, :arrow_right}, assigns)
  end

  def handle_event({:key, {:ctrl, "b"}}, assigns) do
    handle_event({:key, :arrow_left}, assigns)
  end

  # --- Readline Kill/Delete ---

  # Ctrl+D — forward delete
  def handle_event({:key, {:ctrl, "d"}}, assigns) do
    handle_delete(assigns)
  end

  # Ctrl+K — kill to end of line
  def handle_event({:key, {:ctrl, "k"}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    line_len = length(line)

    if assigns.cursor_col >= line_len do
      # At end of line — join next line (delete the newline)
      last_line = length(assigns.lines) - 1

      if assigns.cursor_line < last_line do
        next_line = Enum.at(assigns.lines, assigns.cursor_line + 1)
        joined = line ++ next_line

        new_lines =
          assigns.lines
          |> List.replace_at(assigns.cursor_line, joined)
          |> List.delete_at(assigns.cursor_line + 1)

        assigns
        |> assign(:lines, new_lines)
        |> sync_value()
        |> notify_change()
        |> noreply()
      else
        {:noreply, assigns}
      end
    else
      new_line = Enum.slice(line, 0, assigns.cursor_col)
      new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

      assigns
      |> assign(:lines, new_lines)
      |> sync_value()
      |> notify_change()
      |> noreply()
    end
  end

  # Ctrl+U — kill to start of line
  def handle_event({:key, {:ctrl, "u"}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    new_line = Enum.slice(line, assigns.cursor_col..-1//1)
    new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

    assigns
    |> assign(:lines, new_lines)
    |> set_cursor(assigns.cursor_line, 0)
    |> sync_value()
    |> notify_change()
    |> noreply()
  end

  # Ctrl+W — kill word backward (no cross-line)
  def handle_event({:key, {:ctrl, "w"}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    {new_col, _} = backward_word_in_line(line, assigns.cursor_col)

    # Delete from new_col to cursor_col
    new_line = Enum.slice(line, 0, new_col) ++ Enum.slice(line, assigns.cursor_col..-1//1)
    new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

    assigns
    |> assign(:lines, new_lines)
    |> set_cursor(assigns.cursor_line, new_col)
    |> sync_value()
    |> notify_change()
    |> noreply()
  end

  # Ctrl+T — transpose chars
  def handle_event({:key, {:ctrl, "t"}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    line_len = length(line)

    cond do
      line_len < 2 ->
        {:noreply, assigns}

      assigns.cursor_col == 0 ->
        {:noreply, assigns}

      assigns.cursor_col >= line_len ->
        # At end: swap col-2 and col-1
        a = Enum.at(line, line_len - 2)
        b = Enum.at(line, line_len - 1)

        new_line =
          line
          |> List.replace_at(line_len - 2, b)
          |> List.replace_at(line_len - 1, a)

        new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

        assigns
        |> assign(:lines, new_lines)
        |> sync_value()
        |> notify_change()
        |> noreply()

      true ->
        # Normal: swap col-1 and col, advance cursor
        a = Enum.at(line, assigns.cursor_col - 1)
        b = Enum.at(line, assigns.cursor_col)

        new_line =
          line
          |> List.replace_at(assigns.cursor_col - 1, b)
          |> List.replace_at(assigns.cursor_col, a)

        new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

        assigns
        |> assign(:lines, new_lines)
        |> set_cursor(assigns.cursor_line, assigns.cursor_col + 1)
        |> sync_value()
        |> notify_change()
        |> noreply()
    end
  end

  # --- Word movement ---

  # Alt+F — forward word
  def handle_event({:key, {:alt, "f"}}, assigns) do
    {new_line, new_col} = forward_word(assigns.lines, assigns.cursor_line, assigns.cursor_col)

    assigns
    |> set_cursor(new_line, new_col)
    |> ensure_cursor_visible()
    |> noreply()
  end

  # Alt+B — backward word
  def handle_event({:key, {:alt, "b"}}, assigns) do
    {new_line, new_col} = backward_word(assigns.lines, assigns.cursor_line, assigns.cursor_col)

    assigns
    |> set_cursor(new_line, new_col)
    |> ensure_cursor_visible()
    |> noreply()
  end

  # Alt+D — kill word forward (no cross-line)
  def handle_event({:key, {:alt, "d"}}, assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    {new_col, _} = forward_word_in_line(line, assigns.cursor_col)

    new_line = Enum.slice(line, 0, assigns.cursor_col) ++ Enum.slice(line, new_col..-1//1)
    new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

    assigns
    |> assign(:lines, new_lines)
    |> sync_value()
    |> notify_change()
    |> noreply()
  end

  # Catch-all
  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # --- Private Helpers ---

  defp handle_delete(assigns) do
    line = Enum.at(assigns.lines, assigns.cursor_line)
    line_len = length(line)
    last_line = length(assigns.lines) - 1

    cond do
      assigns.cursor_col < line_len ->
        new_line = List.delete_at(line, assigns.cursor_col)
        new_lines = List.replace_at(assigns.lines, assigns.cursor_line, new_line)

        assigns
        |> assign(:lines, new_lines)
        |> sync_value()
        |> notify_change()
        |> noreply()

      assigns.cursor_line < last_line ->
        next_line = Enum.at(assigns.lines, assigns.cursor_line + 1)
        joined = line ++ next_line

        new_lines =
          assigns.lines
          |> List.replace_at(assigns.cursor_line, joined)
          |> List.delete_at(assigns.cursor_line + 1)

        assigns
        |> assign(:lines, new_lines)
        |> sync_value()
        |> notify_change()
        |> noreply()

      true ->
        {:noreply, assigns}
    end
  end

  defp set_cursor(assigns, line, col) do
    assigns
    |> assign(:cursor_line, line)
    |> assign(:cursor_col, col)
    |> assign(:desired_col, col)
  end

  defp move_vertical(assigns, delta) do
    new_line = assigns.cursor_line + delta
    last_line = length(assigns.lines) - 1

    if new_line < 0 or new_line > last_line do
      assigns
    else
      target_len = length(Enum.at(assigns.lines, new_line))
      new_col = min(assigns.desired_col, target_len)

      assigns
      |> assign(:cursor_line, new_line)
      |> assign(:cursor_col, new_col)
      # NOTE: do NOT update desired_col for vertical movement
      |> ensure_cursor_visible()
    end
  end

  defp move_to_line(assigns, new_line) do
    target_len = length(Enum.at(assigns.lines, new_line))
    new_col = min(assigns.desired_col, target_len)

    assigns
    |> assign(:cursor_line, new_line)
    |> assign(:cursor_col, new_col)
    |> ensure_cursor_visible()
  end

  defp visible_height(assigns) do
    max(assigns.height - 2, 1)
  end

  defp ensure_cursor_visible(assigns) do
    visible = visible_height(assigns)
    offset = assigns.scroll_offset

    cond do
      assigns.cursor_line < offset ->
        assign(assigns, :scroll_offset, assigns.cursor_line)

      assigns.cursor_line >= offset + visible ->
        assign(assigns, :scroll_offset, assigns.cursor_line - visible + 1)

      true ->
        assigns
    end
  end

  defp sync_value(assigns) do
    assign(assigns, :value, lines_to_string(assigns.lines))
  end

  defp notify_change(assigns) do
    if assigns.on_change && assigns[:parent_pid] do
      send(assigns.parent_pid, {assigns.on_change, assigns.value})
    end

    assigns
  end

  defp noreply(assigns), do: {:noreply, assigns}

  # --- Conversion ---

  defp string_to_lines(""), do: [[]]

  defp string_to_lines(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.graphemes/1)
  end

  defp lines_to_string(lines) do
    Enum.map_join(lines, "\n", &Enum.join/1)
  end

  # --- Word helpers ---

  defp word_char?(ch) do
    ch =~ ~r/^[a-zA-Z0-9_]$/
  end

  # Forward word within a single line: skip non-word, then word chars
  defp forward_word_in_line(line, col) do
    line_len = length(line)

    if col >= line_len do
      {line_len, :at_end}
    else
      # Skip non-word chars
      col = skip_while(line, col, line_len, &(not word_char?(&1)))
      # Skip word chars
      col = skip_while(line, col, line_len, &word_char?/1)
      {col, :ok}
    end
  end

  # Backward word within a single line: skip non-word backward, then word chars backward
  defp backward_word_in_line(line, col) do
    if col <= 0 do
      {0, :at_start}
    else
      # Skip non-word chars backward
      col = skip_while_back(line, col, &(not word_char?(&1)))
      # Skip word chars backward
      col = skip_while_back(line, col, &word_char?/1)
      {col, :ok}
    end
  end

  # Forward word across lines
  defp forward_word(lines, line_idx, col) do
    line = Enum.at(lines, line_idx)

    case forward_word_in_line(line, col) do
      {new_col, :at_end} ->
        if line_idx < length(lines) - 1 do
          forward_word(lines, line_idx + 1, 0)
        else
          {line_idx, new_col}
        end

      {new_col, :ok} ->
        {line_idx, new_col}
    end
  end

  # Backward word across lines
  defp backward_word(lines, line_idx, col) do
    line = Enum.at(lines, line_idx)

    case backward_word_in_line(line, col) do
      {_new_col, :at_start} ->
        if line_idx > 0 do
          prev_line = Enum.at(lines, line_idx - 1)
          backward_word(lines, line_idx - 1, length(prev_line))
        else
          {line_idx, 0}
        end

      {new_col, :ok} ->
        {line_idx, new_col}
    end
  end

  defp skip_while(_line, col, max, _pred) when col >= max, do: col

  defp skip_while(line, col, max, pred) do
    ch = Enum.at(line, col)

    if pred.(ch) do
      skip_while(line, col + 1, max, pred)
    else
      col
    end
  end

  defp skip_while_back(_line, col, _pred) when col <= 0, do: 0

  defp skip_while_back(line, col, pred) do
    ch = Enum.at(line, col - 1)

    if pred.(ch) do
      skip_while_back(line, col - 1, pred)
    else
      col
    end
  end
end
