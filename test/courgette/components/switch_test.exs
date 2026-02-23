defmodule Courgette.Components.SwitchTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.Components.Switch
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
       |> assign_new(:on, fn -> false end)
       |> assign_new(:label, fn -> nil end)
       |> assign_new(:on_change, fn -> nil end)
       |> assign_new(:last_value, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Switch,
        id: "sw",
        on: assigns.on,
        label: assigns.label,
        on_change: assigns.on_change,
        focusable: true
      )
    end

    @impl true
    def handle_info({:toggled, value}, assigns) do
      {:noreply, assign(assigns, :last_value, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders off state by default" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "○"
    refute text =~ "◉"
  end

  test "renders on state when on: true" do
    view = mount(Host, initial_assigns: %{on: true})
    text = render_text(view)
    assert text =~ "◉"
  end

  test "renders label text alongside switch" do
    view = mount(Host, initial_assigns: %{label: "Dark mode"})
    text = render_text(view)
    assert text =~ "Dark mode"
  end

  test "space toggles from off to on" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, {:char, " "}})
    text = render_text(view)
    assert text =~ "◉"
  end

  test "enter toggles from on to off" do
    view = mount(Host, initial_assigns: %{on: true})
    send_tab(view)
    send_event(view, {:key, :enter})
    text = render_text(view)
    assert text =~ "○"
    refute text =~ "◉"
  end

  test "sends on_change message to parent with new boolean value" do
    view = mount(Host, initial_assigns: %{on_change: :toggled})
    send_tab(view)
    send_event(view, {:key, {:char, " "}})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_value == true
  end

  test "no notification without on_change prop" do
    view = mount(Host, initial_assigns: %{on_change: nil})
    send_tab(view)
    send_event(view, {:key, {:char, " "}})

    state = :sys.get_state(view.server)
    assert state.assigns.last_value == nil
  end

  test "focus/blur changes border color" do
    view = mount(Host)
    tree = render_tree(view)
    assert find_border_color(tree) == :white

    send_tab(view)
    tree = render_tree(view)
    assert find_border_color(tree) == :cyan
  end

  test "update on state via parent props" do
    view = mount(Host, initial_assigns: %{on: false})
    text = render_text(view)
    assert text =~ "○"

    send_info(view, {:set, :on, true})
    text = render_text(view)
    assert text =~ "◉"
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
