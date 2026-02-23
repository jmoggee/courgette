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
       |> assign_new(:columns, fn -> ["name", "age"] end)
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
    assert text =~ "▸ Bob"
  end

  test "arrow up moves selection" do
    view = mount(Host, initial_assigns: %{selected: 1})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Alice"
  end

  test "clamps at top and bottom" do
    view = mount(Host, initial_assigns: %{selected: 0})
    send_tab(view)
    send_event(view, {:key, :arrow_up})
    text = render_text(view)
    assert text =~ "▸ Alice"

    view2 = mount(Host, initial_assigns: %{selected: 1})
    send_tab(view2)
    send_event(view2, {:key, :arrow_down})
    text2 = render_text(view2)
    assert text2 =~ "▸ Bob"
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
    assert text =~ "▸ Alice"
    # Bob should not have the indicator
    refute text =~ "▸ Bob"
  end

  test "string columns work (used as both key and header)" do
    view = mount(Host, initial_assigns: %{columns: ["name", "age"]})
    text = render_text(view)
    assert text =~ "name"
    assert text =~ "age"
    assert text =~ "Alice"
    assert text =~ "Bob"
  end

  test "tuple columns use key for data lookup and header for display" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: [{:name, "Full Name"}, {:age, "Years"}]
        }
      )

    text = render_text(view)
    assert text =~ "Full Name"
    assert text =~ "Years"
    assert text =~ "Alice"
    assert text =~ "30"
    # The atom key should not appear as display text
    refute text =~ "name" or text =~ "age"
  end

  test "column widths adjust to content" do
    view =
      mount(Host,
        initial_assigns: %{
          columns: ["x"],
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
