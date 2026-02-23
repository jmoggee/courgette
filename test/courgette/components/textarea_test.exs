defmodule Courgette.Components.TextareaTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.Textarea

  setup do
    ComponentRegistry.create_table()
    on_exit(fn -> ComponentRegistry.destroy_table() end)
  end

  defmodule Host do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok,
       assigns
       |> assign_new(:textarea_value, fn -> "" end)
       |> assign_new(:placeholder, fn -> "" end)
       |> assign_new(:on_change, fn -> nil end)
       |> assign_new(:height, fn -> 10 end)
       |> assign_new(:last_change, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Textarea,
        id: "ta",
        value: assigns.textarea_value,
        placeholder: assigns.placeholder,
        on_change: assigns.on_change,
        height: assigns.height,
        focusable: true
      )
    end

    @impl true
    def handle_info({:changed, value}, assigns) do
      {:noreply, assign(assigns, :last_change, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  # --- Rendering ---

  test "renders initial multi-line value" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    text = render_text(view)
    assert text =~ "hello"
    assert text =~ "world"
  end

  test "empty shows placeholder when unfocused" do
    view = mount(Host, initial_assigns: %{placeholder: "Enter text..."})
    text = render_text(view)
    assert text =~ "Enter text..."
  end

  test "focus shows cursor, blur hides" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})

    # Unfocused — no reversed text
    tree = render_tree(view)
    refute has_reverse?(tree)

    # Focus — should have reversed text (cursor)
    send_tab(view)
    tree = render_tree(view)
    assert has_reverse?(tree)
  end

  test "placeholder hidden when focused" do
    view = mount(Host, initial_assigns: %{placeholder: "Enter text..."})
    assert render_text(view) =~ "Enter text..."

    send_tab(view)
    refute render_text(view) =~ "Enter text..."
  end

  # --- Basic editing ---

  test "character insertion" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, "a"}})
    send_event(view, {:key, {:char, "b"}})
    send_event(view, {:key, {:char, "c"}})
    assert textarea_value(view) == "abc"
  end

  test "enter splits line" do
    view = mount(Host, initial_assigns: %{textarea_value: "abcd"})
    send_tab(view)
    # Move to position 2
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :enter})
    assert textarea_value(view) == "ab\ncd"
  end

  test "backspace within line" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})
    send_tab(view)
    send_event(view, {:key, :backspace})
    assert textarea_value(view) == "ab"
  end

  test "backspace at start joins lines" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # Move to start of line 1 (the "world" line)
    send_event(view, {:key, :home})
    # cursor is at end of "world" after mount, home goes to col 0 of line 1
    # Actually cursor starts at end of last line (line 1, col 5)
    send_event(view, {:key, :home})
    send_event(view, {:key, :backspace})
    assert textarea_value(view) == "helloworld"
  end

  test "delete within line" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, :delete})
    assert textarea_value(view) == "bc"
  end

  test "delete at end joins lines" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # Go to line 0, end
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, :end})
    send_event(view, {:key, :delete})
    assert textarea_value(view) == "helloworld"
  end

  # --- Navigation ---

  test "arrow left/right within line" do
    view = mount(Host, initial_assigns: %{textarea_value: "abcd"})
    send_tab(view)
    # At end (col 4), move left twice to col 2
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "abXcd"
  end

  test "arrow left wraps to previous line end" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # Cursor at line 1, col 5. Go to start of line 1.
    send_event(view, {:key, :home})
    # Now at line 1, col 0. Arrow left wraps to end of line 0.
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "helloX\nworld"
  end

  test "arrow right wraps to next line start" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # Go to line 0
    send_event(view, {:key, {:ctrl, "p"}})
    # Go to end of line 0
    send_event(view, {:key, :end})
    # Arrow right wraps to start of line 1
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "hello\nXworld"
  end

  test "arrow up/down between lines" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc\ndef\nghi"})
    send_tab(view)
    # Cursor at line 2, col 3. Move up.
    send_event(view, {:key, :arrow_up})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "abc\ndefX\nghi"
  end

  test "up/down with desired_col through short lines" do
    view = mount(Host, initial_assigns: %{textarea_value: "abcde\nab\nabcde"})
    send_tab(view)
    # Go to line 0, col 4
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, :end})
    send_event(view, {:key, :arrow_left})
    # Now at line 0, col 4. desired_col = 4
    # Move down to line 1 (len=2), col should be min(4,2)=2
    send_event(view, {:key, :arrow_down})
    # Move down to line 2 (len=5), col should be restored to min(4,5)=4
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "abcde\nab\nabcdXe"
  end

  test "home/end within line" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # At line 1, col 5. Home goes to col 0.
    send_event(view, {:key, :home})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "hello\nXworld"
  end

  test "page up/down" do
    # 5 lines, height=4 (visible=2)
    view = mount(Host, initial_assigns: %{textarea_value: "a\nb\nc\nd\ne", height: 4})
    send_tab(view)
    # Cursor at line 4. Page up moves up by (2-1)=1 lines.
    send_event(view, {:key, :page_up})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "a\nb\nc\ndX\ne"
  end

  # --- Readline navigation ---

  test "ctrl+a/e beginning/end of line" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello"})
    send_tab(view)
    send_event(view, {:key, {:ctrl, "a"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "Xhello"

    send_event(view, {:key, {:ctrl, "e"}})
    send_event(view, {:key, {:char, "Y"}})
    assert textarea_value(view) == "XhelloY"
  end

  test "ctrl+p/n previous/next line" do
    view = mount(Host, initial_assigns: %{textarea_value: "aaa\nbbb\nccc"})
    send_tab(view)
    # At line 2. Ctrl+P goes up.
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "aaa\nbbbX\nccc"
  end

  test "ctrl+f/b forward/backward char" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})
    send_tab(view)
    send_event(view, {:key, {:ctrl, "a"}})
    send_event(view, {:key, {:ctrl, "f"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "aXbc"

    # Cursor is now at col 2 (after X). Ctrl+B once to col 1.
    send_event(view, {:key, {:ctrl, "b"}})
    send_event(view, {:key, {:char, "Y"}})
    assert textarea_value(view) == "aYXbc"
  end

  test "alt+f forward word" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello world"})
    send_tab(view)
    send_event(view, {:key, {:ctrl, "a"}})
    send_event(view, {:key, {:alt, "f"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "helloX world"
  end

  test "alt+b backward word" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello world"})
    send_tab(view)
    # At end (col 11)
    send_event(view, {:key, {:alt, "b"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "hello Xworld"
  end

  test "alt+f/b wrapping across lines" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # At line 1, col 5. Alt+F should stay (at end of last line).
    # Actually forward word at end of last line can't go further.
    # Let's test backward: go to start of "world", alt+b wraps to "hello"
    send_event(view, {:key, :home})
    send_event(view, {:key, {:alt, "b"}})
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "Xhello\nworld"
  end

  # --- Readline kill/delete ---

  test "ctrl+d forward delete" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, {:ctrl, "d"}})
    assert textarea_value(view) == "bc"
  end

  test "ctrl+k kill to end of line" do
    view = mount(Host, initial_assigns: %{textarea_value: "abcdef"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, {:ctrl, "k"}})
    assert textarea_value(view) == "abc"
  end

  test "ctrl+k at end of line joins next" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello\nworld"})
    send_tab(view)
    # Go to line 0, end
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, :end})
    send_event(view, {:key, {:ctrl, "k"}})
    assert textarea_value(view) == "helloworld"
  end

  test "ctrl+u kill to start" do
    view = mount(Host, initial_assigns: %{textarea_value: "abcdef"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, {:ctrl, "u"}})
    assert textarea_value(view) == "def"
  end

  test "ctrl+w kill word backward" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello world"})
    send_tab(view)
    # At end (col 11)
    send_event(view, {:key, {:ctrl, "w"}})
    assert textarea_value(view) == "hello "
  end

  test "alt+d kill word forward" do
    view = mount(Host, initial_assigns: %{textarea_value: "hello world"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, {:alt, "d"}})
    assert textarea_value(view) == " world"
  end

  test "ctrl+t transpose" do
    view = mount(Host, initial_assigns: %{textarea_value: "abc"})
    send_tab(view)
    # At end (col 3). Transpose swaps col-2/col-1 -> "acb"... wait
    # At end: swap b and c -> "acb"
    assert textarea_value(view) == "abc"
    send_event(view, {:key, {:ctrl, "t"}})
    assert textarea_value(view) == "acb"
  end

  # --- Scrolling ---

  test "scroll follows cursor down" do
    # 5 lines, height=4 (visible=2)
    view = mount(Host, initial_assigns: %{textarea_value: "a\nb\nc\nd\ne", height: 4})
    send_tab(view)
    # Cursor at line 4. Scroll should have followed.
    state = get_textarea_state(view)
    assert state.scroll_offset > 0
    assert state.cursor_line == 4
  end

  test "scroll follows cursor up" do
    view = mount(Host, initial_assigns: %{textarea_value: "a\nb\nc\nd\ne", height: 4})
    send_tab(view)
    # Go to top
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, {:ctrl, "p"}})
    send_event(view, {:key, {:ctrl, "p"}})
    state = get_textarea_state(view)
    assert state.scroll_offset == 0
    assert state.cursor_line == 0
  end

  test "page up/down adjusts scroll" do
    view = mount(Host, initial_assigns: %{textarea_value: "a\nb\nc\nd\ne\nf\ng\nh", height: 4})
    send_tab(view)
    # Cursor at line 7. Page up by (2-1)=1
    send_event(view, {:key, :page_up})
    state = get_textarea_state(view)
    assert state.cursor_line == 6
  end

  # --- Integration ---

  test "on_change fires on edits" do
    view = mount(Host, initial_assigns: %{on_change: :changed})
    send_tab(view)
    send_event(view, {:key, {:char, "x"}})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_change == "x"
  end

  test "no notification without on_change" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, "x"}})

    state = :sys.get_state(view.server)
    assert state.assigns.last_change == nil
  end

  test "update via props (controlled mode)" do
    view = mount(Host, initial_assigns: %{textarea_value: "old"})
    assert render_text(view) =~ "old"

    send_info(view, {:set, :textarea_value, "new\nvalue"})
    text = render_text(view)
    assert text =~ "new"
    assert text =~ "value"
  end

  test "grapheme-safe with multi-byte chars" do
    view = mount(Host, initial_assigns: %{textarea_value: "héllo\nwörld"})
    send_tab(view)
    # At end of line 1 (col 5). Insert char.
    send_event(view, {:key, {:char, "X"}})
    assert textarea_value(view) == "héllo\nwörldX"
  end

  # --- Helpers ---

  defp textarea_value(view) do
    state = get_textarea_state(view)
    state.value
  end

  defp get_textarea_state(view) do
    # Get the host's server state, then look up the textarea component state
    :sys.get_state(view.server)

    # The textarea is a child live_component — get its state from the registry
    case Courgette.ComponentRegistry.lookup(Textarea, "ta") do
      {:ok, pid} -> :sys.get_state(pid).assigns
      _ -> raise "textarea component not found in registry"
    end
  end

  defp has_reverse?(nil), do: false
  defp has_reverse?(%Courgette.Element{type: :text, props: %{reverse: true}}), do: true

  defp has_reverse?(%Courgette.Element{children: children}) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> has_reverse?(child)
      _ -> false
    end)
  end

  # ===== Autocomplete Integration Tests =====

  defmodule AutocompleteHost do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok,
       assigns
       |> assign_new(:textarea_value, fn -> "" end)
       |> assign_new(:height, fn -> 10 end)
       |> assign_new(:files, fn -> ["foo.ex", "bar.ex", "baz.ex", "lib/app.ex"] end)
       |> assign_new(:suggestions, fn -> [] end)
       |> assign_new(:last_trigger_event, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Textarea,
        id: "ta",
        value: assigns.textarea_value,
        triggers: [%{char: "@", tag: :file_ref}],
        on_trigger: :autocomplete,
        trigger_suggestions: assigns.suggestions,
        height: assigns.height,
        focusable: true
      )
    end

    @impl true
    def handle_info({:autocomplete, %{accepted: true} = event}, assigns) do
      {:noreply,
       assigns
       |> assign(:suggestions, [])
       |> assign(:last_trigger_event, event)}
    end

    def handle_info({:autocomplete, %{tag: :file_ref, query: q} = event}, assigns) do
      matches =
        assigns.files
        |> Enum.filter(&String.contains?(&1, q))
        |> Enum.take(10)

      Courgette.send_update(Textarea, id: "ta", trigger_suggestions: matches)

      {:noreply, assign(assigns, :last_trigger_event, event)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  describe "autocomplete" do
    test "typing trigger char activates autocomplete and notifies parent" do
      view = mount(AutocompleteHost)
      send_tab(view)

      # Type "@" — should trigger autocomplete
      send_event(view, {:key, {:char, "@"}})

      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil
      assert state.autocomplete.active.trigger.tag == :file_ref

      # Parent should have been notified with empty query
      host_state = :sys.get_state(view.server).assigns
      assert host_state.last_trigger_event == %{tag: :file_ref, query: ""}
    end

    test "trigger provides suggestions from parent" do
      view = mount(AutocompleteHost)
      send_tab(view)

      # Type "@" — triggers, parent filters all files (empty query matches all)
      send_event(view, {:key, {:char, "@"}})

      state = get_autocomplete_textarea_state(view)
      assert length(state.autocomplete.suggestions) == 4
    end

    test "typing query chars narrows suggestions" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      send_event(view, {:key, {:char, "b"}})

      state = get_autocomplete_textarea_state(view)
      # "b" matches "bar.ex", "baz.ex", "lib/app.ex"
      labels = Enum.map(state.autocomplete.suggestions, & &1.label)
      assert "bar.ex" in labels
      assert "baz.ex" in labels
      refute "foo.ex" in labels
    end

    test "arrow keys navigate suggestions when popup is showing" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.cursor == 0

      send_event(view, {:key, :arrow_down})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.cursor == 1

      send_event(view, {:key, :arrow_up})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.cursor == 0
    end

    test "ctrl+p/n navigate suggestions when popup is showing" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})

      send_event(view, {:key, {:ctrl, "n"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.cursor == 1

      send_event(view, {:key, {:ctrl, "p"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.cursor == 0
    end

    test "enter accepts selected suggestion" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      # Navigate to second suggestion
      send_event(view, {:key, :arrow_down})
      # Accept
      send_event(view, {:key, :enter})

      state = get_autocomplete_textarea_state(view)
      # Autocomplete should be dismissed
      assert state.autocomplete.active == nil
      assert state.autocomplete.suggestions == []

      # Value should contain the accepted suggestion with trailing space
      # The suggestions were ["bar.ex", "baz.ex", "foo.ex", "lib/app.ex"] sorted by filter
      # Actually they come in order: ["foo.ex", "bar.ex", "baz.ex", "lib/app.ex"]
      # cursor=1 means second item: "bar.ex"
      assert state.value =~ "@bar.ex "

      # Parent should have received acceptance event
      host_state = :sys.get_state(view.server).assigns
      assert host_state.last_trigger_event.accepted == true
      assert host_state.last_trigger_event.value == "bar.ex"
    end

    test "escape dismisses autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil

      send_event(view, {:key, :escape})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
      assert state.autocomplete.suggestions == []
    end

    test "backspace past trigger dismisses autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil

      # Backspace removes the "@" — cursor is now at or before trigger col
      send_event(view, {:key, :backspace})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
    end

    test "moving cursor before trigger dismisses autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      send_event(view, {:key, {:char, "f"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil

      # Move left past the trigger
      send_event(view, {:key, :arrow_left})
      send_event(view, {:key, :arrow_left})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
    end

    test "trigger does not activate mid-word" do
      view = mount(AutocompleteHost)
      send_tab(view)

      # Type "foo@" — @ is not at a word boundary
      send_event(view, {:key, {:char, "f"}})
      send_event(view, {:key, {:char, "o"}})
      send_event(view, {:key, {:char, "o"}})
      send_event(view, {:key, {:char, "@"}})

      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
    end

    test "trigger activates after space" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "h"}})
      send_event(view, {:key, {:char, "i"}})
      send_event(view, {:key, {:char, " "}})
      send_event(view, {:key, {:char, "@"}})

      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil
      assert state.autocomplete.active.start_col == 3
    end

    test "non-query char dismisses active autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil

      # Space is not a query char — should dismiss
      send_event(view, {:key, {:char, " "}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
    end

    test "enter does normal line split when no autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "a"}})
      send_event(view, {:key, {:char, "b"}})
      send_event(view, {:key, :enter})
      send_event(view, {:key, {:char, "c"}})

      state = get_autocomplete_textarea_state(view)
      assert state.value == "ab\nc"
    end

    test "arrow keys do normal movement when no autocomplete" do
      view = mount(AutocompleteHost, initial_assigns: %{textarea_value: "abc\ndef"})
      send_tab(view)

      send_event(view, {:key, :arrow_up})
      state = get_autocomplete_textarea_state(view)
      assert state.cursor_line == 0
    end

    test "popup renders with suggestions" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})

      text = render_text(view)
      assert text =~ "foo.ex"
      assert text =~ "bar.ex"
    end

    test "accepted value replaces trigger and query in text" do
      view = mount(AutocompleteHost)
      send_tab(view)

      # Type "hello @fo" then accept first suggestion
      send_event(view, {:key, {:char, "h"}})
      send_event(view, {:key, {:char, "e"}})
      send_event(view, {:key, {:char, "l"}})
      send_event(view, {:key, {:char, "l"}})
      send_event(view, {:key, {:char, "o"}})
      send_event(view, {:key, {:char, " "}})
      send_event(view, {:key, {:char, "@"}})
      send_event(view, {:key, {:char, "f"}})
      send_event(view, {:key, {:char, "o"}})

      state = get_autocomplete_textarea_state(view)
      # "fo" matches "foo.ex"
      assert state.autocomplete.suggestions != []

      # Accept first suggestion
      send_event(view, {:key, :enter})

      state = get_autocomplete_textarea_state(view)
      assert state.value == "hello @foo.ex "
    end

    test "blur dismisses autocomplete" do
      view = mount(AutocompleteHost)
      send_tab(view)

      send_event(view, {:key, {:char, "@"}})
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active != nil

      # Blur (e.g., by focusing away)
      send_event(view, :blur)
      state = get_autocomplete_textarea_state(view)
      assert state.autocomplete.active == nil
    end
  end

  defp get_autocomplete_textarea_state(view) do
    :sys.get_state(view.server)

    case Courgette.ComponentRegistry.lookup(Textarea, "ta") do
      {:ok, pid} -> :sys.get_state(pid).assigns
      _ -> raise "textarea component not found in registry"
    end
  end
end
