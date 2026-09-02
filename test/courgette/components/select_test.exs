defmodule Courgette.Components.SelectTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.Select

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
       |> assign_new(:options, fn -> ["Red", "Green", "Blue"] end)
       |> assign_new(:selected, fn -> 0 end)
       |> assign_new(:on_select, fn -> nil end)
       |> assign_new(:prompt, fn -> nil end)
       |> assign_new(:last_selected, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Select,
        id: "sel",
        options: assigns.options,
        selected: assigns.selected,
        on_select: assigns.on_select,
        prompt: assigns.prompt,
        focusable: true
      )
    end

    @impl true
    def handle_info({:picked, value}, assigns) do
      {:noreply, assign(assigns, :last_selected, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  # -- Collapsed display --

  test "renders only selected option when collapsed" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Red"
    assert text =~ "▾"
    refute text =~ "Green"
    refute text =~ "Blue"
  end

  test "shows dropdown indicator when collapsed" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "▾"
  end

  test "initial selected prop respected" do
    view = mount(Host, initial_assigns: %{selected: 1})
    text = render_text(view)
    assert text =~ "Green"
    assert text =~ "▾"
    refute text =~ "Red"
    refute text =~ "Blue"
  end

  # -- Expanding --

  test "enter expands the dropdown" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :enter})
    text = render_text(view)
    # When expanded, all options should be visible
    assert text =~ "Red"
    assert text =~ "Green"
    assert text =~ "Blue"
  end

  test "space expands the dropdown" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, " "}})
    text = render_text(view)
    assert text =~ "Red"
    assert text =~ "Green"
    assert text =~ "Blue"
  end

  test "when expanded, all options visible with cursor on selected" do
    view = mount(Host, initial_assigns: %{selected: 1})
    send_tab(view)
    send_event(view, {:key, :enter})
    text = render_text(view)
    # Cursor should be on Green (the selected item)
    assert text =~ "▸ Green"
    # Other items should not have the cursor marker
    assert text =~ "Red"
    assert text =~ "Blue"
  end

  # -- Navigation while expanded --

  test "arrow down moves cursor while expanded" do
    view = mount(Host)
    send_tab(view)
    # Expand
    send_event(view, {:key, :enter})
    # Cursor starts at 0 (Red), move down
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ "▸ Green"
  end

  test "arrow up moves cursor while expanded" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :enter})
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Green"
  end

  test "clamps cursor at top while expanded" do
    view = mount(Host, initial_assigns: %{selected: 0})
    send_tab(view)
    send_event(view, {:key, :enter})
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Red"
  end

  test "clamps cursor at bottom while expanded" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :enter})
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ "▸ Blue"
  end

  # -- Selection --

  test "enter while expanded selects cursor item and collapses" do
    view = mount(Host, initial_assigns: %{on_select: :picked})
    send_tab(view)
    # Expand
    send_event(view, {:key, :enter})
    # Move to Green
    send_event(view, {:key, :arrow_down})
    # Select
    send_event(view, {:key, :enter})

    # Should be collapsed now showing only Green
    text = render_text(view)
    assert text =~ "Green"
    assert text =~ "▾"
    refute text =~ "Red"
    refute text =~ "Blue"

    # Parent should have received {:picked, "Green"}
    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "Green"
  end

  test "space while expanded selects cursor item and collapses" do
    view = mount(Host, initial_assigns: %{on_select: :picked})
    send_tab(view)
    send_event(view, {:key, {:char, " "}})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, {:char, " "}})

    text = render_text(view)
    assert text =~ "Green"
    assert text =~ "▾"
    refute text =~ "Red"

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "Green"
  end

  # -- Escape --

  test "escape collapses without changing selection" do
    view = mount(Host)
    send_tab(view)
    # Expand
    send_event(view, {:key, :enter})
    # Move cursor to Green
    send_event(view, {:key, :arrow_down})
    # Escape without selecting
    send_event(view, {:key, :escape})

    # Should be collapsed, still showing Red (original selection)
    text = render_text(view)
    assert text =~ "Red"
    assert text =~ "▾"
    refute text =~ "Green"
    refute text =~ "Blue"
  end

  # -- Arrow keys ignored when collapsed --

  test "arrow keys ignored when collapsed" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    # Should still show Red, not Green
    assert text =~ "Red"
    refute text =~ "Green"
  end

  # -- No notification without on_select --

  test "no notification without on_select prop" do
    view = mount(Host, initial_assigns: %{on_select: nil})
    send_tab(view)
    send_event(view, {:key, :enter})
    send_event(view, {:key, :enter})

    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == nil
  end

  # -- Focus/blur --

  test "focus/blur changes border" do
    view = mount(Host)
    tree = render_tree(view)
    # Initially unfocused — border_color should be :white
    assert find_border_color(tree) == :white

    send_tab(view)
    tree = render_tree(view)
    assert find_border_color(tree) == :cyan
  end

  # -- Prompt --

  test "prompt text renders" do
    view = mount(Host, initial_assigns: %{prompt: "Pick a color:"})
    text = render_text(view)
    assert text =~ "Pick a color:"
  end

  # -- Option formats --

  test "string options normalized to {value, label}" do
    view = mount(Host, initial_assigns: %{options: ["A", "B"]})
    text = render_text(view)
    assert text =~ "A"
  end

  test "tuple options send value not label" do
    view =
      mount(Host, initial_assigns: %{options: [{"r", "Red"}, {"g", "Green"}], on_select: :picked})

    send_tab(view)
    # Expand then select
    send_event(view, {:key, :enter})
    send_event(view, {:key, :enter})

    # Should send the value "r", not the label "Red"
    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "r"
  end

  # -- Update options --

  test "update options via props" do
    view = mount(Host, initial_assigns: %{options: ["X", "Y"]})
    text = render_text(view)
    assert text =~ "X"

    send_info(view, {:set, :options, ["A", "B", "C"]})
    text = render_text(view)
    assert text =~ "A"
    refute text =~ "X"
  end

  # -- Cursor starts at selected index when expanding --

  test "cursor starts at selected index when expanding" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :enter})
    text = render_text(view)
    assert text =~ "▸ Blue"
  end

  # -- Absolute positioned dropdown --

  test "expanded dropdown has position: :absolute box" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :enter})
    tree = render_tree(view)

    # Find a box with position: :absolute in the tree
    assert find_absolute_box(tree) != nil
  end

  # Helper to find position: :absolute box in tree
  defp find_absolute_box(nil), do: nil

  defp find_absolute_box(%Courgette.Element{type: :box, props: %{position: :absolute}} = el),
    do: el

  defp find_absolute_box(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_absolute_box(child)
      _ -> nil
    end)
  end

  # Helper to find border_color in tree
  defp find_border_color(nil), do: nil

  defp find_border_color(%Courgette.Element{type: :box, props: %{border_color: color}}), do: color

  defp find_border_color(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_border_color(child)
      _ -> nil
    end)
  end
end
