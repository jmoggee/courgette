# examples/textarea.exs
#
# Multi-line text editor component with readline shortcuts.
#
# Tab to focus the textarea. Type to edit. Arrow keys to navigate.
# Enter to insert newline. Ctrl+A/E for home/end. Ctrl+K/U to kill.
# Alt+F/B for word movement. Page Up/Down for scrolling.
# Press 'q' when textarea is not focused to quit.
#
# Run: mix run examples/textarea.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Components.Textarea

defmodule TextareaDemo do
  use Courgette.App

  @initial_text """
  Welcome to the Textarea demo!

  This is a multi-line text editor with full
  readline shortcuts. Try these:

    Ctrl+A/E  - beginning/end of line
    Ctrl+K    - kill to end of line
    Ctrl+U    - kill to start of line
    Ctrl+W    - kill word backward
    Alt+F/B   - word forward/backward
    Ctrl+P/N  - previous/next line
    Page Up/Down - scroll by page

  Edit freely and watch the status bar update.\
  """

  @impl true
  def mount(_assigns) do
    {:ok, %{text: @initial_text}}
  end

  @impl true
  def render(assigns) do
    lines = String.split(assigns.text, "\n")
    line_count = length(lines)

    box flex_direction: :column do
      text bold: true, fg: :yellow do
        "Textarea Demo"
      end

      text fg: :white, dim: true do
        "Tab: focus | q: quit (when unfocused)"
      end

      box padding_v: 1 do
        live_component(Textarea,
          id: "editor",
          value: assigns.text,
          placeholder: "Start typing...",
          on_change: :text_changed,
          height: 16,
          focusable: true
        )
      end

      text fg: :cyan do
        "Lines: #{line_count} | Chars: #{String.length(assigns.text)}"
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop(self())
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info({:text_changed, text}, assigns) do
    {:noreply, assign(assigns, :text, text)}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(TextareaDemo)
