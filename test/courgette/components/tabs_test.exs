defmodule Courgette.Components.TabsTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.Components.Tabs
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
       |> assign_new(:tabs, fn -> ["Home", "Settings", "About"] end)
       |> assign_new(:active, fn -> 0 end)
       |> assign_new(:on_change, fn -> nil end)
       |> assign_new(:last_changed, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Tabs,
        id: "tabs",
        tabs: assigns.tabs,
        active: assigns.active,
        on_change: assigns.on_change,
        focusable: true
      )
    end

    @impl true
    def handle_info({:tab_changed, value}, assigns) do
      {:noreply, assign(assigns, :last_changed, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders all tab labels" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Home"
    assert text =~ "Settings"
    assert text =~ "About"
  end

  test "first tab is active by default" do
    view = mount(Host)
    tree = render_tree(view)
    # Active tab should have bold styling
    active_text = find_active_tab_text(tree)
    assert active_text =~ "Home"
  end

  test "arrow right moves to next tab" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_right})
    tree = render_tree(view)
    active_text = find_active_tab_text(tree)
    assert active_text =~ "Settings"
  end

  test "arrow left moves to previous tab" do
    view = mount(Host, initial_assigns: %{active: 2})
    send_tab(view)
    send_event(view, {:key, :arrow_left})
    tree = render_tree(view)
    active_text = find_active_tab_text(tree)
    assert active_text =~ "Settings"
  end

  test "clamps at first tab" do
    view = mount(Host, initial_assigns: %{active: 0})
    send_tab(view)
    send_event(view, {:key, :arrow_left})
    tree = render_tree(view)
    active_text = find_active_tab_text(tree)
    assert active_text =~ "Home"
  end

  test "clamps at last tab" do
    view = mount(Host, initial_assigns: %{active: 2})
    send_tab(view)
    send_event(view, {:key, :arrow_right})
    tree = render_tree(view)
    active_text = find_active_tab_text(tree)
    assert active_text =~ "About"
  end

  test "active tab has bold and cyan styling" do
    view = mount(Host)
    tree = render_tree(view)
    active_node = find_active_tab_node(tree)
    assert active_node != nil
    assert active_node.props[:bold] == true
    assert active_node.props[:fg] == :cyan
  end

  test "enter sends on_change with tab id to parent" do
    view = mount(Host, initial_assigns: %{on_change: :tab_changed})
    send_tab(view)
    # Move to Settings
    send_event(view, {:key, :arrow_right})
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_changed == "Settings"
  end

  test "no notification without on_change prop" do
    view = mount(Host, initial_assigns: %{on_change: nil})
    send_tab(view)
    send_event(view, {:key, :enter})

    state = :sys.get_state(view.server)
    assert state.assigns.last_changed == nil
  end

  test "focus/blur changes border color" do
    view = mount(Host)
    tree = render_tree(view)
    assert find_border_color(tree) == :white

    send_tab(view)
    tree = render_tree(view)
    assert find_border_color(tree) == :cyan
  end

  test "initial active prop respected" do
    view = mount(Host, initial_assigns: %{active: 1})
    tree = render_tree(view)
    active_text = find_active_tab_text(tree)
    assert active_text =~ "Settings"
  end

  test "string tabs normalized to {id, label}" do
    view = mount(Host, initial_assigns: %{tabs: ["A", "B"]})
    text = render_text(view)
    assert text =~ "A"
    assert text =~ "B"
  end

  test "tuple tabs send value on enter" do
    view =
      mount(Host,
        initial_assigns: %{
          tabs: [{"home", "Home"}, {"settings", "Settings"}],
          on_change: :tab_changed
        }
      )

    send_tab(view)
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_changed == "home"
  end

  test "update tabs via parent props" do
    view = mount(Host, initial_assigns: %{tabs: ["X", "Y"]})
    text = render_text(view)
    assert text =~ "X"
    assert text =~ "Y"

    send_info(view, {:set, :tabs, ["A", "B", "C"]})
    text = render_text(view)
    assert text =~ "A"
    assert text =~ "B"
    assert text =~ "C"
    refute text =~ "X"
  end

  # --- Helpers ---

  defp find_border_color(nil), do: nil

  defp find_border_color(%Courgette.Element{type: :box, props: %{border_color: color}}), do: color

  defp find_border_color(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_border_color(child)
      _ -> nil
    end)
  end

  # Find the text content of the active (bold) tab node
  defp find_active_tab_text(nil), do: nil

  defp find_active_tab_text(%Courgette.Element{type: :text, props: %{bold: true}} = el) do
    collect_text(el)
  end

  defp find_active_tab_text(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_active_tab_text(child)
      _ -> nil
    end)
  end

  defp find_active_tab_text(_), do: nil

  # Find the active tab Element node itself (for prop assertions)
  defp find_active_tab_node(nil), do: nil

  defp find_active_tab_node(%Courgette.Element{type: :text, props: %{bold: true}} = el), do: el

  defp find_active_tab_node(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_active_tab_node(child)
      _ -> nil
    end)
  end

  defp find_active_tab_node(_), do: nil

  defp collect_text(%Courgette.Element{children: children}) do
    Enum.map_join(children, fn
      text when is_binary(text) -> text
      %Courgette.Element{} = child -> collect_text(child)
      _ -> ""
    end)
  end
end
