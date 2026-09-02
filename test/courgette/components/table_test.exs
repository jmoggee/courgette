defmodule Courgette.Components.TableTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.Table

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
       |> assign_new(:columns, fn ->
         [[key: :name, header: "name"], [key: :age, header: "age"]]
       end)
       |> assign_new(:rows, fn ->
         [%{name: "Alice", age: 30}, %{name: "Bob", age: 25}]
       end)
       |> assign_new(:selected, fn -> 0 end)
       |> assign_new(:on_select, fn -> nil end)
       |> assign_new(:last_selected, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(Table,
        id: "tbl",
        columns: assigns.columns,
        rows: assigns.rows,
        selected: assigns.selected,
        on_select: assigns.on_select,
        focusable: true
      )
    end

    @impl true
    def handle_info({:row_picked, value}, assigns) do
      {:noreply, assign(assigns, :last_selected, value)}
    end

    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders column headers" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "name"
    assert text =~ "age"
  end

  test "renders all row data" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Alice"
    assert text =~ "30"
    assert text =~ "Bob"
    assert text =~ "25"
  end

  test "arrow down moves selection" do
    view = mount(Host)
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    text = render_text(view)
    assert text =~ ~r/▸.*Bob/
  end

  test "arrow up moves selection" do
    view = mount(Host, initial_assigns: %{selected: 1})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ ~r/▸.*Alice/
  end

  test "clamps at top and bottom" do
    view = mount(Host, initial_assigns: %{selected: 0})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ ~r/▸.*Alice/

    view2 = mount(Host, initial_assigns: %{selected: 1})
    send_tab(view2)
    send_event(view2, {:key, :arrow_down})
    text2 = render_text(view2)
    assert text2 =~ ~r/▸.*Bob/
  end

  test "enter sends on_select with full row map" do
    view = mount(Host, initial_assigns: %{on_select: :row_picked})
    send_tab(view)
    send_event(view, {:key, :arrow_down})
    send_event(view, {:key, :enter})

    :sys.get_state(view.server)
    state = :sys.get_state(view.server)
    assert state.assigns.last_selected == %{name: "Bob", age: 25}
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

  test "selected row has visual indicator" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "▸"
    assert text =~ "Alice"
    # Only one row should have the selection indicator
    assert length(Regex.scan(~r/▸/, text)) == 1
  end

  test "keyword list columns with key and header" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [[key: :name, header: "Full Name"], [key: :age, header: "Years"]]
        }
      )

    text = render_text(view)
    assert text =~ "Full Name"
    assert text =~ "Years"
    assert text =~ "Alice"
    assert text =~ "30"
  end

  test "column widths adjust to content" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [[key: :x, header: "x"]],
          rows: [%{x: "short"}, %{x: "much longer value"}]
        }
      )

    text = render_text(view)
    # Both values should be present, the longer one determines width
    assert text =~ "short"
    assert text =~ "much longer value"
  end

  test "update rows via parent props" do
    view = mount(Host)
    text = render_text(view)
    assert text =~ "Alice"

    send_info(view, {:set, :rows, [%{name: "Charlie", age: 40}]})
    text = render_text(view)
    assert text =~ "Charlie"
    assert text =~ "40"
    refute text =~ "Alice"
  end

  test "empty rows renders just headers" do
    view = mount(Host, initial_assigns: %{rows: []})
    text = render_text(view)
    assert text =~ "name"
    assert text =~ "age"
    refute text =~ "Alice"
  end

  test "right-aligned column" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [
            [key: :id, header: "ID", align: :right],
            [key: :name, header: "Name"]
          ],
          rows: [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]
        }
      )

    tree = render_tree(view)
    # Find a cell box with justify_content: :flex_end
    assert find_justify_content(tree, :flex_end),
           "Expected a cell with justify_content: :flex_end for right alignment"
  end

  test "center-aligned column" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [
            [key: :name, header: "Name"],
            [key: :role, header: "Role", align: :center]
          ],
          rows: [%{name: "Alice", role: "Engineer"}]
        }
      )

    tree = render_tree(view)

    assert find_justify_content(tree, :center),
           "Expected a cell with justify_content: :center for center alignment"
  end

  test "explicit column width" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [
            [key: :name, header: "Name", width: 20]
          ],
          rows: [%{name: "Al"}]
        }
      )

    tree = render_tree(view)
    # Find a box with width: 20
    assert find_box_width(tree, 20),
           "Expected a cell box with explicit width: 20"
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

  # Helper to find justify_content value in tree
  defp find_justify_content(nil, _target), do: false

  defp find_justify_content(
         %Courgette.Element{type: :box, props: props, children: children},
         target
       ) do
    if Map.get(props, :justify_content) == target do
      true
    else
      Enum.any?(children, fn
        %Courgette.Element{} = child -> find_justify_content(child, target)
        _ -> false
      end)
    end
  end

  defp find_justify_content(%Courgette.Element{children: children}, target) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> find_justify_content(child, target)
      _ -> false
    end)
  end

  # Helper to find a box with specific width
  defp find_box_width(nil, _target), do: false

  defp find_box_width(%Courgette.Element{type: :box, props: props, children: children}, target) do
    if Map.get(props, :width) == target do
      true
    else
      Enum.any?(children, fn
        %Courgette.Element{} = child -> find_box_width(child, target)
        _ -> false
      end)
    end
  end

  defp find_box_width(%Courgette.Element{children: children}, target) do
    Enum.any?(children, fn
      %Courgette.Element{} = child -> find_box_width(child, target)
      _ -> false
    end)
  end
end
