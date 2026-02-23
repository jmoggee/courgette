defmodule Courgette.Components.TreeTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.Components.Tree
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
       |> assign_new(:data, fn -> ["Alpha", "Beta", "Gamma"] end)
       |> assign_new(:on_select, fn -> nil end)
       |> assign_new(:expanded, fn -> MapSet.new() end)
       |> assign_new(:last_selected, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Tree,
        id: "tree",
        data: assigns.data,
        on_select: assigns.on_select,
        expanded: assigns.expanded,
        focusable: true
      )
    end

    @impl true
    def handle_info({:selected, value}, assigns) do
      {:noreply, assign(assigns, :last_selected, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders flat list of leaf nodes" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Alpha"
    assert text =~ "Beta"
    assert text =~ "Gamma"
  end

  test "renders collapsed parent with triangle indicator" do
    view = mount(Host, initial_assigns: %{data: [{"Parent", ["Child1", "Child2"]}]})
    text = render_text(view)
    assert text =~ "▸ Parent"
    refute text =~ "Child1"
    refute text =~ "Child2"
  end

  test "arrow right expands a node, children become visible" do
    view =
      mount(Host,
        initial_assigns: %{data: [{"Parent", ["Child1", "Child2"]}]}
      )

    send_tab(view)
    send_event(view, {:key, :arrow_right})
    text = render_text(view)
    assert text =~ "▾ Parent"
    assert text =~ "Child1"
    assert text =~ "Child2"
  end

  test "arrow left collapses an expanded node" do
    view =
      mount(Host,
        initial_assigns: %{
          data: [{"Parent", ["Child1", "Child2"]}],
          expanded: MapSet.new([[0]])
        }
      )

    send_tab(view)
    # Cursor is on Parent (index 0), which is expanded
    send_event(view, {:key, :arrow_left})
    text = render_text(view)
    assert text =~ "▸ Parent"
    refute text =~ "Child1"
  end

  test "arrow down/up navigates through visible nodes" do
    view = mount(Host)
    send_tab(view)
    # Cursor starts on Alpha (bold cyan)
    assert has_bold_text?(render_tree(view), "Alpha")

    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Beta")

    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Gamma")

    send_event(view, {:key, :arrow_up})
    assert has_bold_text?(render_tree(view), "Beta")
  end

  test "clamps at top and bottom" do
    view = mount(Host)
    send_tab(view)

    # Already at top, arrow up should stay
    send_event(view, {:key, :arrow_up})
    assert has_bold_text?(render_tree(view), "Alpha")

    # Move to bottom
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Gamma")

    # Past bottom should clamp
    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Gamma")
  end

  test "nested expansion works" do
    view =
      mount(Host,
        initial_assigns: %{data: [{"A", [{"B", ["C"]}]}]}
      )

    send_tab(view)

    # Expand A
    send_event(view, {:key, :arrow_right})
    text = render_text(view)
    assert text =~ "▾ A"
    assert text =~ "▸ B"
    refute text =~ "C"

    # Move to B and expand
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_right})
    text = render_text(view)
    assert text =~ "▾ B"
    assert text =~ "C"
  end

  test "enter sends on_select with node label" do
    view = mount(Host, initial_assigns: %{on_select: :selected})
    send_tab(view)
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == "Alpha"
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

  test "cursor stays valid after collapse" do
    view =
      mount(Host,
        initial_assigns: %{
          data: [{"Parent", ["Child1", "Child2"]}, "After"],
          expanded: MapSet.new([[0]])
        }
      )

    send_tab(view)

    # Move cursor to Child2 (index 2)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Child2")

    # Go back to Parent and collapse
    send_event(view, {:key, :arrow_up})
    send_event(view, {:key, :arrow_up})
    send_event(view, {:key, :arrow_left})

    text = render_text(view)
    assert text =~ "▸ Parent"
    refute text =~ "Child1"
    refute text =~ "Child2"

    # Cursor should still be valid (on Parent at index 0)
    # and the flat list should only have Parent + After
    assert has_bold_text?(render_tree(view), "Parent")
  end

  test "deep nesting renders with proper indentation" do
    view =
      mount(Host,
        initial_assigns: %{
          data: [{"L0", [{"L1", [{"L2", ["L3"]}]}]}],
          expanded: MapSet.new([[0], [0, 0], [0, 0, 0]])
        }
      )

    text = render_text(view)
    assert text =~ "L0"
    assert text =~ "L1"
    assert text =~ "L2"
    assert text =~ "L3"

    # Verify indentation via tree inspection
    tree = render_tree(view)
    texts = collect_texts(tree)

    # Find the text nodes — should have increasing indentation
    l0_text = Enum.find(texts, &String.contains?(&1, "L0"))
    l1_text = Enum.find(texts, &String.contains?(&1, "L1"))
    l2_text = Enum.find(texts, &String.contains?(&1, "L2"))
    l3_text = Enum.find(texts, &String.contains?(&1, "L3"))

    # Each level should be indented 2 more spaces than the previous
    assert l0_text != nil
    assert l1_text != nil
    assert l2_text != nil
    assert l3_text != nil

    l0_indent = leading_spaces(l0_text)
    l1_indent = leading_spaces(l1_text)
    l2_indent = leading_spaces(l2_text)
    l3_indent = leading_spaces(l3_text)

    assert l1_indent == l0_indent + 2
    assert l2_indent == l1_indent + 2
    assert l3_indent == l2_indent + 2
  end

  test "arrow left on child moves cursor to parent" do
    view =
      mount(Host,
        initial_assigns: %{
          data: [{"Parent", ["Child1", "Child2"]}],
          expanded: MapSet.new([[0]])
        }
      )

    send_tab(view)
    # Move to Child1
    send_event(view, {:key, :arrow_down})
    assert has_bold_text?(render_tree(view), "Child1")

    # Arrow left on a leaf child should move to parent
    send_event(view, {:key, :arrow_left})
    assert has_bold_text?(render_tree(view), "Parent")
  end

  # -- Helpers --

  defp find_border_color(nil), do: nil

  defp find_border_color(%Courgette.Element{type: :box, props: %{border_color: color}}), do: color

  defp find_border_color(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_border_color(child)
      _ -> nil
    end)
  end

  defp has_bold_text?(nil, _text), do: false

  defp has_bold_text?(
         %Courgette.Element{type: :text, props: %{bold: true}, children: children},
         text
       ) do
    Enum.any?(children, fn
      str when is_binary(str) -> String.contains?(str, text)
      _ -> false
    end)
  end

  defp has_bold_text?(%Courgette.Element{children: children}, text) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> has_bold_text?(child, text)
      _ -> false
    end)
  end

  defp collect_texts(nil), do: []
  defp collect_texts(str) when is_binary(str), do: [str]

  defp collect_texts(%Courgette.Element{children: children}) do
    Enum.flat_map(children, &collect_texts/1)
  end

  defp leading_spaces(str) do
    str
    |> String.graphemes()
    |> Enum.take_while(&(&1 == " "))
    |> length()
  end
end
