defmodule Courgette.Components.SpinnerTest do
  use ExUnit.Case, async: false
  use Courgette.ComponentTestHelpers

  alias Courgette.ComponentRegistry
  alias Courgette.Components.Spinner

  setup do
    ComponentRegistry.create_table()
    on_exit(fn -> ComponentRegistry.destroy_table() end)
    :ok
  end

  # Wrapper that renders a Spinner as a child
  defmodule Host do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok,
       assigns
       |> assign_new(:spinner_style, fn -> :dots end)
       |> assign_new(:spinner_label, fn -> nil end)
       |> assign_new(:spinner_color, fn -> :cyan end)
       |> assign_new(:spinner_interval, fn -> 80 end)}
    end

    @impl true
    def render(assigns) do
      live_component(Spinner,
        id: "spin",
        style: assigns.spinner_style,
        label: assigns.spinner_label,
        color: assigns.spinner_color,
        interval: assigns.spinner_interval
      )
    end
  end

  test "renders initial frame" do
    view = mount(Host)
    text = render_text(view)
    # First frame of :dots is ⠋
    assert text =~ "⠋"
  end

  test "advances frame on tick" do
    view = mount(Host)
    assert render_text(view) =~ "⠋"

    # Manually send tick to the child
    child_pid = await_child(Spinner, "spin")
    send(child_pid, :tick)
    :sys.get_state(child_pid)
    # Wait for child tree to propagate to parent
    :sys.get_state(view.server)

    assert render_text(view) =~ "⠙"
  end

  test "wraps around to first frame" do
    view = mount(Host)
    child_pid = await_child(Spinner, "spin")

    # Dots has 10 frames — send 10 ticks to wrap around
    for _ <- 1..10 do
      send(child_pid, :tick)
      :sys.get_state(child_pid)
    end

    :sys.get_state(view.server)
    assert render_text(view) =~ "⠋"
  end

  test "different styles render different characters" do
    view = mount(Host, initial_assigns: %{spinner_style: :line})
    text = render_text(view)
    # First frame of :line is "-"
    assert text =~ "-"
  end

  test "label prop appends text" do
    view = mount(Host, initial_assigns: %{spinner_label: "Loading..."})
    text = render_text(view)
    assert text =~ "Loading..."
  end

  test "color prop applied" do
    view = mount(Host, initial_assigns: %{spinner_color: :green})
    tree = render_tree(view)
    texts = collect_texts(tree)
    assert Enum.any?(texts, fn t -> t.props[:fg] == :green end)
  end

  test "circle style renders correct first frame" do
    view = mount(Host, initial_assigns: %{spinner_style: :circle})
    assert render_text(view) =~ "◐"
  end

  test "all styles render without error" do
    styles = [
      :dots, :dots_pulse, :dots_orbit, :dots_scroll, :dots_bounce, :sand,
      :braille_double, :braille_six, :braille_eight_double,
      :circle, :arc, :triangle, :quarter, :box_bounce,
      :pipe, :box_invert, :square_corners,
      :wave, :pulse, :meter, :grow_horizontal, :noise, :layer,
      :line, :star, :point, :bounce, :arrow, :ellipsis, :hamburger
    ]

    for style <- styles do
      view = mount(Host, initial_assigns: %{spinner_style: style})
      text = render_text(view)
      assert is_binary(text), "style #{style} should render text"
      assert text != "", "style #{style} should render non-empty text"
    end
  end

  test "no label renders just the spinner character" do
    view = mount(Host, initial_assigns: %{spinner_label: nil})
    text = render_text(view)
    assert text == "⠋"
  end

  # Helper to collect text elements from tree
  defp collect_texts(nil), do: []
  defp collect_texts(%Courgette.Element{type: :text} = el), do: [el]

  defp collect_texts(%Courgette.Element{children: children}) do
    Enum.flat_map(children, &collect_texts/1)
  end

  # Wait for a child component to register in the ComponentRegistry.
  # Child processes start asynchronously so they may not be registered
  # by the time the parent's mount returns.
  defp await_child(module, id, attempts \\ 50) do
    case ComponentRegistry.lookup(module, id) do
      {:ok, pid} ->
        pid

      :error when attempts > 0 ->
        Process.sleep(1)
        await_child(module, id, attempts - 1)

      :error ->
        raise "Child #{inspect(module)} #{inspect(id)} did not register in time"
    end
  end
end
