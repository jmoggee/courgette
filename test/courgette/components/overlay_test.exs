defmodule Courgette.Components.OverlayTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

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
       |> assign_new(:title, fn -> nil end)
       |> assign_new(:border, fn -> :rounded end)
       |> assign_new(:overlay_width, fn -> nil end)
       |> assign_new(:overlay_height, fn -> nil end)
       |> assign_new(:padding, fn -> 1 end)
       |> assign_new(:body_text, fn -> "Overlay content" end)}
    end

    @impl true
    def render(assigns) do
      import Courgette.Component.DSL
      import Courgette.Components.Overlay

      opts =
        [title: assigns.title, border: assigns.border, padding: assigns.padding]
        |> maybe_add(:width, assigns.overlay_width)
        |> maybe_add(:height, assigns.overlay_height)

      overlay(opts ++ [do: text(do: assigns.body_text)])
    end

    defp maybe_add(opts, _key, nil), do: opts
    defp maybe_add(opts, key, val), do: Keyword.put(opts, key, val)

    @impl true
    def handle_info({:set, key, val}, assigns) do
      {:noreply, assign(assigns, key, val)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end
  end

  test "renders with rounded border by default" do
    view = mount(Host)
    tree = render_tree(view)
    assert find_border(tree) == :rounded
  end

  test "renders title when provided" do
    view = mount(Host, initial_assigns: %{title: "My Dialog"})
    text = render_text(view)
    assert text =~ "My Dialog"
  end

  test "custom border style works" do
    view = mount(Host, initial_assigns: %{border: :single})
    tree = render_tree(view)
    assert find_border(tree) == :single
  end

  test "padding applied" do
    view = mount(Host, initial_assigns: %{padding: 2})
    tree = render_tree(view)
    assert find_padding(tree) == 2
  end

  test "renders body content" do
    view = mount(Host, initial_assigns: %{body_text: "Hello overlay"})
    text = render_text(view)
    assert text =~ "Hello overlay"
  end

  # Helper to find border in the element tree
  defp find_border(nil), do: nil

  defp find_border(%Courgette.Element{type: :box, props: %{border: border}}), do: border

  defp find_border(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_border(child)
      _ -> nil
    end)
  end

  # Helper to find padding in the content box
  defp find_padding(nil), do: nil

  defp find_padding(%Courgette.Element{type: :box, props: %{border: _, padding: padding}}),
    do: padding

  defp find_padding(%Courgette.Element{children: children}) do
    Enum.find_value(children, fn
      %Courgette.Element{} = child -> find_padding(child)
      _ -> nil
    end)
  end
end
