defmodule Courgette.Components.ScrollAreaTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.ScrollArea
  alias Courgette.Element

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
       |> assign_new(:items, fn -> Enum.map(1..20, &"Line #{&1}") end)
       |> assign_new(:height, fn -> 5 end)
       |> assign_new(:show_scrollbar, fn -> true end)
       |> assign_new(:on_scroll, fn -> nil end)
       |> assign_new(:border, fn -> nil end)
       |> assign_new(:content_height, fn -> nil end)
       |> assign_new(:last_scroll_offset, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(ScrollArea,
        id: "scroll",
        height: assigns.height,
        scrollbar: assigns.show_scrollbar,
        on_scroll: assigns.on_scroll,
        border: assigns.border,
        content_height: assigns.content_height,
        focusable: true,
        inner_block: build_children(assigns.items)
      )
    end

    defp build_children(items) do
      import Courgette.Component.DSL

      for item <- items do
        text(do: item)
      end
    end

    @impl true
    def handle_info({:scrolled, offset}, assigns) do
      {:noreply, assign(assigns, :last_scroll_offset, offset)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  # -- Rendering --

  test "renders slot content" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Line 1"
  end

  test "renders overflow: :scroll box in tree" do
    view = mount(Host)
    tree = render_tree(view)
    assert find_scroll_box(tree) != nil
  end

  # -- Arrow key scrolling --

  test "arrow down increments scroll offset" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_down})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 1
  end

  test "arrow up decrements scroll offset" do
    view = mount(Host)
    send_tab(view)
    # Scroll down first, then up
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_up})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 1
  end

  test "scroll offset clamped at 0" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_up})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 0
  end

  test "scroll offset clamped at max" do
    # 20 items, height 5 => max offset 15
    view = mount(Host)
    send_tab(view)

    for _ <- 1..25 do
      send_event(view, {:key, :arrow_down})
    end

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 15
  end

  # -- Page up/down --

  test "page down scrolls by viewport height" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :page_down})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 5
  end

  test "page up scrolls by viewport height" do
    view = mount(Host)
    send_tab(view)
    # Go to bottom first
    send_event(view, {:key, :end})
    send_event(view, {:key, :page_up})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    # max=15, page_up by 5 => 10
    assert sa.props.scroll_offset == 10
  end

  # -- Home/End --

  test "home jumps to top" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :home})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 0
  end

  test "end jumps to bottom" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :end})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    # 20 items, height 5 => max offset 15
    assert sa.props.scroll_offset == 15
  end

  # -- Mouse scroll --

  test "mouse scroll down" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:mouse, :scroll_down, 5, 5})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 1
  end

  test "mouse scroll up" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:mouse, :scroll_down, 5, 5})
    send_event(view, {:mouse, :scroll_down, 5, 5})
    send_event(view, {:mouse, :scroll_up, 5, 5})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 1
  end

  test "mouse scroll with modifiers" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:mouse, :scroll_down, 5, 5, []})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 1
  end

  # -- Scrollbar visibility --

  test "scrollbar renders when content overflows" do
    view = mount(Host)
    tree = render_tree(view)
    # Should have scrollbar children (vertical track cells)
    assert find_scrollbar_box(tree) != nil
  end

  test "scrollbar hidden when content fits" do
    view = mount(Host, initial_assigns: %{items: ["A", "B"], height: 5})
    tree = render_tree(view)
    # 2 items in height 5 — no scrollbar needed
    assert find_scrollbar_box(tree) == nil
  end

  test "scrollbar hidden when disabled" do
    view = mount(Host, initial_assigns: %{show_scrollbar: false})
    tree = render_tree(view)
    assert find_scrollbar_box(tree) == nil
  end

  # -- Focus/blur --

  test "border color changes on focus" do
    view = mount(Host)
    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.border_color == :white

    send_tab(view)
    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.border_color == :cyan
  end

  test "border color reverts on blur" do
    view = mount(Host)
    send_tab(view)

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.border_color == :cyan

    # Directly send blur to the scroll area child
    state = :sys.get_state(view.server)
    [{_key, {child_pid, _props}}] = Map.to_list(state.children)
    GenServer.call(child_pid, {:test_event, :blur})
    :sys.get_state(child_pid)

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.border_color == :white
  end

  # -- on_scroll callback --

  test "on_scroll notifies parent" do
    view = mount(Host, initial_assigns: %{on_scroll: :scrolled})
    send_tab(view)
    send_event(view, {:key, :arrow_down})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_scroll_offset == 1
  end

  test "no notification without on_scroll" do
    view = mount(Host, initial_assigns: %{on_scroll: nil})
    send_tab(view)
    send_event(view, {:key, :arrow_down})

    state = :sys.get_state(view.server)
    assert state.assigns.last_scroll_offset == nil
  end

  # -- content_height override --

  test "explicit content_height overrides child count" do
    # 20 items but content_height set to 10, so max = 10 - 5 = 5
    view = mount(Host, initial_assigns: %{content_height: 10})
    send_tab(view)
    send_event(view, {:key, :end})

    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.scroll_offset == 5
  end

  # -- Border pass-through --

  test "border prop passed to scroll box" do
    view = mount(Host, initial_assigns: %{border: :rounded})
    tree = render_tree(view)
    sa = find_scroll_box(tree)
    assert sa.props.border == :rounded
  end

  # -- Helpers --

  # Find the box with overflow: :scroll (the scroll container)
  defp find_scroll_box(nil), do: nil

  defp find_scroll_box(%Element{type: :box, props: %{overflow: :scroll}} = el), do: el

  defp find_scroll_box(%Element{children: children}) do
    Enum.find_value(children, fn
      %Element{} = child -> find_scroll_box(child)
      _ -> nil
    end)
  end

  # Find the scrollbar box (column of text cells with track/thumb chars)
  # The scrollbar is the second child of the outer row box, after the scroll box
  defp find_scrollbar_box(nil), do: nil

  defp find_scrollbar_box(%Element{
         type: :box,
         props: %{flex_direction: :row},
         children: children
       }) do
    case children do
      [%Element{type: :box, props: %{overflow: :scroll}}, %Element{type: :box} = scrollbar | _] ->
        scrollbar

      _ ->
        Enum.find_value(children, fn
          %Element{} = child -> find_scrollbar_box(child)
          _ -> nil
        end)
    end
  end

  defp find_scrollbar_box(%Element{children: children}) do
    Enum.find_value(children, fn
      %Element{} = child -> find_scrollbar_box(child)
      _ -> nil
    end)
  end
end
