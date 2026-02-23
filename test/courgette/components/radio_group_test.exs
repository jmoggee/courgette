defmodule Courgette.Components.RadioGroupTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.RadioGroup

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
       |> assign_new(:selected, fn -> nil end)
       |> assign_new(:on_change, fn -> nil end)
       |> assign_new(:label, fn -> nil end)
       |> assign_new(:last_changed, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(RadioGroup,
        id: "radio",
        options: assigns.options,
        selected: assigns.selected,
        on_change: assigns.on_change,
        label: assigns.label,
        focusable: true
      )
    end

    @impl true
    def handle_info({:changed, value}, assigns) do
      {:noreply, assign(assigns, :last_changed, value)}
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

  test "renders selected option with filled radio indicator" do
    view = mount(Host, initial_assigns: %{selected: "Green"})
    text = render_text(view)
    assert text =~ "(●) Green"
    assert text =~ "( ) Red"
    assert text =~ "( ) Blue"
  end

  test "arrow down moves cursor highlight" do
    view = mount(Host)
    send_tab(view)
    # Cursor starts at 0 (Red)
    send_event(view, {:key, :arrow_down})
    tree = render_tree(view)
    # The highlighted option should be rendered with bold
    assert has_highlighted_option?(tree, "Green")
  end

  test "arrow up moves cursor highlight" do
    view = mount(Host)
    send_tab(view)
    # Move cursor to index 2 (Blue)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_up})
    tree = render_tree(view)
    assert has_highlighted_option?(tree, "Green")
  end

  test "clamps at top" do
    view = mount(Host)
    send_tab(view)
    # Cursor at 0, try going up
    send_event(view, {:key, :arrow_up})
    tree = render_tree(view)
    assert has_highlighted_option?(tree, "Red")
  end

  test "clamps at bottom" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    tree = render_tree(view)
    assert has_highlighted_option?(tree, "Blue")
  end

  test "enter selects the highlighted option" do
    view = mount(Host, initial_assigns: %{on_change: :changed})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :enter})
    text = render_text(view)
    assert text =~ "(●) Green"
  end

  test "space also selects" do
    view = mount(Host, initial_assigns: %{on_change: :changed})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, {:char, " "}})
    text = render_text(view)
    assert text =~ "(●) Green"
  end

  test "sends on_change to parent with selected value" do
    view = mount(Host, initial_assigns: %{on_change: :changed})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_changed == "Green"
  end

  test "no notification without on_change prop" do
    view = mount(Host, initial_assigns: %{on_change: nil})
    send_tab(view)
    send_event(view, {:key, :enter})

    state = :sys.get_state(view.server)
    assert state.assigns.last_changed == nil
  end

  test "focus/blur changes border" do
    view = mount(Host)
    tree = render_tree(view)
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

  test "tuple options preserve value vs label" do
    view =
      mount(Host,
        initial_assigns: %{options: [{"r", "Red"}, {"g", "Green"}], on_change: :changed}
      )

    send_tab(view)
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    # Should send the value "r", not the label "Red"
    assert state.assigns.last_changed == "r"
  end

  test "group label renders when provided" do
    view = mount(Host, initial_assigns: %{label: "Pick a color:"})
    text = render_text(view)
    assert text =~ "Pick a color:"
  end

  test "update options via parent props" do
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

  # Helper to check if an option is highlighted (rendered with bold: true)
  defp has_highlighted_option?(nil, _label), do: false

  defp has_highlighted_option?(
         %Courgette.Element{type: :text, props: props, children: children},
         label
       ) do
    is_bold = Map.get(props, :bold, false)

    has_label =
      Enum.any?(children, fn
        text when is_binary(text) -> String.contains?(text, label)
        _ -> false
      end)

    (is_bold and has_label) or
      Enum.any?(children, fn
        %Courgette.Element{} = child -> has_highlighted_option?(child, label)
        _ -> false
      end)
  end

  defp has_highlighted_option?(%Courgette.Element{children: children}, label) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> has_highlighted_option?(child, label)
      _ -> false
    end)
  end
end
