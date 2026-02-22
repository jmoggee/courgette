defmodule Courgette.Components.TextInputTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.Components.TextInput
  alias Courgette.ComponentRegistry

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
       |> assign_new(:input_value, fn -> "" end)
       |> assign_new(:placeholder, fn -> "" end)
       |> assign_new(:on_change, fn -> nil end)
       |> assign_new(:on_submit, fn -> nil end)
       |> assign_new(:submitted, fn -> nil end)
       |> assign_new(:last_change, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(TextInput,
        id: "inp",
        value: assigns.input_value,
        placeholder: assigns.placeholder,
        on_change: assigns.on_change,
        on_submit: assigns.on_submit,
        focusable: true
      )
    end

    @impl true
    def handle_info({:submitted, value}, assigns) do
      {:noreply, assign(assigns, :submitted, value)}
    end

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

  test "renders initial value" do
    view = mount(Host, initial_assigns: %{input_value: "Hello"})
    assert render_text(view) =~ "Hello"
  end

  test "empty renders placeholder when unfocused" do
    view = mount(Host, initial_assigns: %{placeholder: "Type here..."})
    text = render_text(view)
    assert text =~ "Type here..."
  end

  test "character insertion at cursor" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, "a"}})
    send_event(view, {:key, {:char, "b"}})
    send_event(view, {:key, {:char, "c"}})
    assert input_value(view) == "abc"
  end

  test "backspace deletes before cursor" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})
    send_tab(view)
    # Cursor starts at end (position 3)
    send_event(view, {:key, :backspace})
    assert input_value(view) == "ab"
  end

  test "delete removes at cursor" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})
    send_tab(view)
    # Move cursor to start
    send_event(view, {:key, :home})
    send_event(view, {:key, :delete})
    assert input_value(view) == "bc"
  end

  test "arrow left/right moves cursor" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})
    send_tab(view)
    # Cursor at end (3). Move left twice to position 1.
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, :arrow_left})
    # Insert 'X' at position 1
    send_event(view, {:key, {:char, "X"}})
    assert input_value(view) == "aXbc"
  end

  test "home jumps to start" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, {:char, "X"}})
    assert input_value(view) == "Xabc"
  end

  test "end jumps to end" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, :end})
    send_event(view, {:key, {:char, "X"}})
    assert input_value(view) == "abcX"
  end

  test "cursor doesn't go below 0" do
    view = mount(Host, initial_assigns: %{input_value: "a"})
    send_tab(view)
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, :arrow_left})
    # Backspace at position 0 should be no-op
    send_event(view, {:key, :backspace})
    assert input_value(view) == "a"
  end

  test "cursor doesn't go past length" do
    view = mount(Host, initial_assigns: %{input_value: "ab"})
    send_tab(view)
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    # Already at end (2), still at 2
    send_event(view, {:key, {:char, "X"}})
    assert input_value(view) == "abX"
  end

  test "enter sends on_submit with value" do
    view = mount(Host, initial_assigns: %{input_value: "hello", on_submit: :submitted})
    send_tab(view)
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.submitted == "hello"
  end

  test "on_change notifies on every edit" do
    view = mount(Host, initial_assigns: %{on_change: :changed})
    send_tab(view)
    send_event(view, {:key, {:char, "x"}})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_change == "x"
  end

  test "no notification without on_submit" do
    view = mount(Host, initial_assigns: %{input_value: "hello"})
    send_tab(view)
    send_event(view, {:key, :enter})

    state = :sys.get_state(view.server)
    assert state.assigns.submitted == nil
  end

  test "no notification without on_change" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, "x"}})

    state = :sys.get_state(view.server)
    assert state.assigns.last_change == nil
  end

  test "focus shows cursor, blur hides it" do
    view = mount(Host, initial_assigns: %{input_value: "abc"})

    # Unfocused — no reversed text
    tree = render_tree(view)
    refute has_reverse?(tree)

    # Focus — should have reversed text (cursor)
    send_tab(view)
    tree = render_tree(view)
    assert has_reverse?(tree)
  end

  test "ctrl+k kills to end of line" do
    view = mount(Host, initial_assigns: %{input_value: "abcdef"})
    send_tab(view)
    # Move cursor to position 3 (after 'c')
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, {:ctrl, "k"}})
    assert input_value(view) == "abc"
  end

  test "ctrl+u kills to start of line" do
    view = mount(Host, initial_assigns: %{input_value: "abcdef"})
    send_tab(view)
    # Move cursor to position 3
    send_event(view, {:key, :home})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, {:ctrl, "u"}})
    assert input_value(view) == "def"
  end

  test "insert in middle of text" do
    view = mount(Host, initial_assigns: %{input_value: "ac"})
    send_tab(view)
    # Cursor starts at end (2). Move left once to position 1.
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, {:char, "b"}})
    assert input_value(view) == "abc"
  end

  test "cursor at end shows trailing cursor" do
    view = mount(Host, initial_assigns: %{input_value: "ab"})
    send_tab(view)
    # Cursor is at end — should show reversed space
    tree = render_tree(view)
    reversed = find_reversed_text(tree)
    assert reversed == " "
  end

  test "placeholder hidden when focused" do
    view = mount(Host, initial_assigns: %{placeholder: "Type here..."})
    # Unfocused — placeholder visible
    assert render_text(view) =~ "Type here..."

    # Focus — placeholder should not appear (cursor shows instead)
    send_tab(view)
    refute render_text(view) =~ "Type here..."
  end

  test "update via props (controlled mode)" do
    view = mount(Host, initial_assigns: %{input_value: "old"})
    assert render_text(view) =~ "old"

    send_info(view, {:set, :input_value, "new"})
    assert render_text(view) =~ "new"
  end

  test "grapheme-safe cursor movement (multi-byte chars)" do
    view = mount(Host, initial_assigns: %{input_value: "héllo"})
    send_tab(view)
    # Cursor at end (5). Move left.
    send_event(view, {:key, :arrow_left})
    send_event(view, {:key, {:char, "X"}})
    assert input_value(view) == "héllXo"
  end

  # Helpers

  # Extract the text content from the rendered tree without space-joining.
  # This gives us the raw value by concatenating all text children directly,
  # which avoids the space artifacts from render_text when the cursor splits
  # text into multiple text nodes.
  defp input_value(view) do
    tree = render_tree(view)

    tree
    |> collect_all_text()
    |> Enum.join()
    |> String.trim()
  end

  defp collect_all_text(nil), do: []
  defp collect_all_text(text) when is_binary(text), do: [text]

  defp collect_all_text(%Courgette.Element{children: children}) do
    Enum.flat_map(children, &collect_all_text/1)
  end

  defp has_reverse?(nil), do: false
  defp has_reverse?(%Courgette.Element{type: :text, props: %{reverse: true}}), do: true

  defp has_reverse?(%Courgette.Element{children: children}) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> has_reverse?(child)
      _ -> false
    end)
  end

  defp find_reversed_text(nil), do: nil

  defp find_reversed_text(%Courgette.Element{type: :text, props: %{reverse: true}, children: [text]})
       when is_binary(text) do
    text
  end

  defp find_reversed_text(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_reversed_text(child)
      _ -> nil
    end)
  end
end
