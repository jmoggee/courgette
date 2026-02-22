defmodule Courgette.Components.SelectTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.Components.Select
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

  test "renders all options" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Red"
    assert text =~ "Green"
    assert text =~ "Blue"
  end

  test "arrow down moves selection" do
    view = mount(Host)
    text = render_text(view)
    # Initially "Red" is selected (has ▸ marker)
    assert text =~ "▸ Red"

    # Focus the select, then press down
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ "▸ Green"
  end

  test "arrow up moves selection" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Green"
  end

  test "clamps at top (no wrap)" do
    view = mount(Host, initial_assigns: %{selected: 0})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Red"
  end

  test "clamps at bottom (no wrap)" do
    view = mount(Host, initial_assigns: %{selected: 2})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ "▸ Blue"
  end

  test "enter sends on_select to parent" do
    view = mount(Host, initial_assigns: %{on_select: :picked})
    send_tab(view)
    # Move to Green
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :enter})

    # Parent should have received {:picked, "Green"}
    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "Green"
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
    # Initially unfocused — border_color should be :white
    assert find_border_color(tree) == :white

    send_tab(view)
    tree = render_tree(view)
    assert find_border_color(tree) == :cyan
  end

  test "string options normalized to {value, label}" do
    view = mount(Host, initial_assigns: %{options: ["A", "B"]})
    text = render_text(view)
    assert text =~ "A"
    assert text =~ "B"
  end

  test "tuple options work" do
    view = mount(Host, initial_assigns: %{options: [{"r", "Red"}, {"g", "Green"}], on_select: :picked})
    send_tab(view)
    send_event(view, {:key, :enter})

    # Should send the value "r", not the label "Red"
    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "r"
  end

  test "prompt text renders above options" do
    view = mount(Host, initial_assigns: %{prompt: "Pick a color:"})
    text = render_text(view)
    assert text =~ "Pick a color:"
  end

  test "initial selected prop respected" do
    view = mount(Host, initial_assigns: %{selected: 1})
    text = render_text(view)
    assert text =~ "▸ Green"
  end

  test "update options via props" do
    view = mount(Host, initial_assigns: %{options: ["X", "Y"]})
    text = render_text(view)
    assert text =~ "X"
    assert text =~ "Y"

    send_info(view, {:set, :options, ["A", "B", "C"]})
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
