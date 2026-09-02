defmodule Courgette.Components.ProgressBarTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.ProgressBar

  setup do
    ComponentRegistry.create_table()
    on_exit(fn -> ComponentRegistry.destroy_table() end)
  end

  # Wrapper that renders a ProgressBar as a child
  defmodule Host do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok,
       assigns
       |> assign_new(:bar_value, fn -> 0.0 end)
       |> assign_new(:bar_width, fn -> 20 end)
       |> assign_new(:bar_color, fn -> :cyan end)
       |> assign_new(:bar_bg_color, fn -> :white end)
       |> assign_new(:bar_label, fn -> nil end)}
    end

    @impl true
    def render(assigns) do
      live_component(ProgressBar,
        id: "bar",
        value: assigns.bar_value,
        width: assigns.bar_width,
        color: assigns.bar_color,
        bg_color: assigns.bar_bg_color,
        label: assigns.bar_label
      )
    end

    @impl true
    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end
  end

  test "renders empty bar (value 0.0)" do
    view = mount(Host, initial_assigns: %{bar_value: 0.0, bar_width: 10})
    text = render_text(view)
    assert text =~ String.duplicate("░", 10)
    refute text =~ "█"
  end

  test "renders full bar (value 1.0)" do
    view = mount(Host, initial_assigns: %{bar_value: 1.0, bar_width: 10})
    text = render_text(view)
    assert text =~ String.duplicate("█", 10)
    refute text =~ "░"
  end

  test "renders partial bar" do
    view = mount(Host, initial_assigns: %{bar_value: 0.5, bar_width: 10})
    text = render_text(view)
    assert text =~ String.duplicate("█", 5)
    assert text =~ String.duplicate("░", 5)
  end

  test "custom width" do
    view = mount(Host, initial_assigns: %{bar_value: 1.0, bar_width: 30})
    text = render_text(view)
    assert text =~ String.duplicate("█", 30)
  end

  test "custom colors applied" do
    view =
      mount(Host,
        initial_assigns: %{bar_value: 0.5, bar_width: 10, bar_color: :green, bar_bg_color: :red}
      )

    tree = render_tree(view)
    # Tree should contain text nodes with the custom colors
    texts = collect_texts(tree)
    assert Enum.any?(texts, fn t -> t.props[:fg] == :green end)
    assert Enum.any?(texts, fn t -> t.props[:fg] == :red end)
  end

  test "percent label" do
    view = mount(Host, initial_assigns: %{bar_value: 0.45, bar_width: 20, bar_label: :percent})
    text = render_text(view)
    assert text =~ "45%"
  end

  test "update via props changes value" do
    view = mount(Host, initial_assigns: %{bar_value: 0.0, bar_width: 10})
    text = render_text(view)
    refute text =~ "█"

    send_info(view, {:set, :bar_value, 0.8})
    text = render_text(view)
    assert text =~ String.duplicate("█", 8)
  end

  test "clamps value to 0.0-1.0" do
    # Value > 1.0 clamps to full
    view = mount(Host, initial_assigns: %{bar_value: 2.0, bar_width: 10})
    text = render_text(view)
    assert text =~ String.duplicate("█", 10)
    refute text =~ "░"

    # Value < 0.0 clamps to empty
    view2 = mount(Host, initial_assigns: %{bar_value: -0.5, bar_width: 10})
    text2 = render_text(view2)
    assert text2 =~ String.duplicate("░", 10)
    refute text2 =~ "█"
  end

  # Helper to collect text elements from tree
  defp collect_texts(nil), do: []
  defp collect_texts(%Courgette.Element{type: :text} = el), do: [el]

  defp collect_texts(%Courgette.Element{children: children}) do
    Enum.flat_map(children, &collect_texts/1)
  end
end
