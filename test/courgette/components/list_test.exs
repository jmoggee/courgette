defmodule Courgette.Components.ListTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.List

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
       |> assign_new(:items, fn -> ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"] end)
       |> assign_new(:selected, fn -> 0 end)
       |> assign_new(:on_select, fn -> nil end)
       |> assign_new(:on_highlight, fn -> nil end)
       |> assign_new(:max_visible, fn -> 10 end)
       |> assign_new(:last_selected, fn -> nil end)
       |> assign_new(:last_highlighted, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(List,
        id: "list",
        items: assigns.items,
        selected: assigns.selected,
        on_select: assigns.on_select,
        on_highlight: assigns.on_highlight,
        max_visible: assigns.max_visible,
        focusable: true
      )
    end

    @impl true
    def handle_info({:selected, item}, assigns) do
      {:noreply, assign(assigns, :last_selected, item)}
    end

    def handle_info({:highlighted, item}, assigns) do
      {:noreply, assign(assigns, :last_highlighted, item)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders all items when fewer than max_visible" do
    view = mount(Host, initial_assigns: %{items: ["A", "B", "C"], max_visible: 10})
    text = render_text(view)
    assert text =~ "A"
    assert text =~ "B"
    assert text =~ "C"
  end

  test "renders only max_visible items when more exist" do
    items = Enum.map(1..20, &"Item #{&1}")
    view = mount(Host, initial_assigns: %{items: items, max_visible: 5})
    text = render_text(view)

    # Should show first 5 items
    assert text =~ "Item 1"
    assert text =~ "Item 5"
    # Should NOT show items beyond the window
    refute text =~ "Item 6"
  end

  test "arrow down moves selection" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "▸ Alpha"

    send_tab(view)
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ "▸ Beta"
  end

  test "arrow up moves selection" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Beta"
  end

  test "clamps at top" do
    view = mount(Host, initial_assigns: %{selected: 0})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Alpha"
  end

  test "clamps at bottom" do
    view = mount(Host)
    send_tab(view)

    # Move past the last item
    for _ <- 1..10 do
      send_event(view, {:key, :arrow_down})
    end

    text = render_text(view)
    assert text =~ "▸ Epsilon"
  end

  test "scrolls down when cursor passes visible window" do
    items = Enum.map(1..10, &"Item #{&1}")
    view = mount(Host, initial_assigns: %{items: items, max_visible: 3})
    send_tab(view)

    # Move down 3 times — cursor should be at index 3 (Item 4)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})

    text = render_text(view)
    # Item 4 should be selected and visible
    assert text =~ "▸ Item 4"
    # Item 1 should have scrolled out
    refute text =~ "Item 1"
  end

  test "scrolls up when cursor passes visible window" do
    items = Enum.map(1..10, &"Item #{&1}")
    view = mount(Host, initial_assigns: %{items: items, max_visible: 3, selected: 5})
    send_tab(view)

    # Move up — should scroll window up
    send_event(view, {:key, :arrow_up})
    send_event(view, {:key, :arrow_up})
    send_event(view, {:key, :arrow_up})

    text = render_text(view)
    assert text =~ "▸ Item 3"
    # Items far below should not be visible
    refute text =~ "Item 6"
  end

  test "home jumps to first item" do
    view = mount(Host, initial_assigns: %{selected: 3})
    send_tab(view)
    send_event(view, {:key, :home})
    text = render_text(view)
    assert text =~ "▸ Alpha"
  end

  test "end jumps to last item" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :end})
    text = render_text(view)
    assert text =~ "▸ Epsilon"
  end

  test "enter sends on_select to parent" do
    view = mount(Host, initial_assigns: %{on_select: :selected})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "Beta"
  end

  test "on_highlight fires when cursor moves" do
    view = mount(Host, initial_assigns: %{on_highlight: :highlighted})
    send_tab(view)
    send_event(view, {:key, :arrow_down})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_highlighted == "Beta"
  end

  test "no notification without on_select prop" do
    view = mount(Host, initial_assigns: %{on_select: nil})
    send_tab(view)
    send_event(view, {:key, :enter})

    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == nil
  end

  test "focus/blur changes border" do
    view = mount(Host)
    tree = render_tree(view)
    assert find_border_color(tree) == :white

    send_tab(view)
    tree = render_tree(view)
    assert find_border_color(tree) == :cyan
  end

  test "string items normalized to {id, label}" do
    view = mount(Host, initial_assigns: %{items: ["X", "Y"]})
    text = render_text(view)
    assert text =~ "X"
    assert text =~ "Y"
  end

  test "update items via parent props" do
    view = mount(Host, initial_assigns: %{items: ["X", "Y"]})
    text = render_text(view)
    assert text =~ "X"
    assert text =~ "Y"

    send_info(view, {:set, :items, ["A", "B", "C"]})
    text = render_text(view)
    assert text =~ "A"
    assert text =~ "B"
    assert text =~ "C"
    refute text =~ "X"
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
