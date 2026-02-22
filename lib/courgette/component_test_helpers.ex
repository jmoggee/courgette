defmodule Courgette.ComponentTestHelpers do
  @moduledoc """
  Test helpers for LiveComponent testing.

  `use Courgette.ComponentTestHelpers` imports helpers that start headless
  renderers and component servers, letting you test the full lifecycle
  without a real terminal.

  ## Example

      defmodule MyAppTest do
        use ExUnit.Case
        use Courgette.ComponentTestHelpers

        test "renders initial state" do
          view = mount(MyApp)
          assert render_text(view) =~ "Hello"
        end

        test "handles events" do
          view = mount(MyApp)
          send_event(view, {:key, :arrow_up})
          assert render_text(view) =~ "1"
        end
      end
  """

  alias Courgette.LiveComponent.Server
  alias Courgette.Renderer
  alias Courgette.Element

  @type view :: %{
          server: pid(),
          renderer: pid(),
          renderer_name: atom()
        }

  defmacro __using__(_opts) do
    quote do
      import Courgette.ComponentTestHelpers,
        only: [mount: 1, mount: 2, send_event: 2, send_info: 2, render_tree: 1, render_text: 1]
    end
  end

  @doc """
  Mount a LiveComponent in a headless test environment.

  Returns a view handle for use with other test helpers.

  ## Options

  - `:initial_assigns` — map of initial assigns (default `%{}`)
  - `:width` — buffer width (default 80)
  - `:height` — buffer height (default 24)
  """
  @spec mount(module(), keyword()) :: view()
  def mount(module, opts \\ []) do
    renderer_name = :"test_renderer_#{:erlang.unique_integer([:positive])}"

    {:ok, renderer} =
      Renderer.start_link(
        headless: true,
        width: Keyword.get(opts, :width, 80),
        height: Keyword.get(opts, :height, 24),
        name: renderer_name
      )

    {:ok, server} =
      Server.start_link(
        module: module,
        renderer: renderer_name,
        initial_assigns: Keyword.get(opts, :initial_assigns, %{})
      )

    %{server: server, renderer: renderer, renderer_name: renderer_name}
  end

  @doc """
  Send a parsed event directly to the component (bypasses KeyParser).
  Synchronous — returns after the event is processed.
  """
  @spec send_event(view(), term()) :: :ok
  def send_event(%{server: server}, event) do
    GenServer.call(server, {:test_event, event})
  end

  @doc """
  Send a raw message to the component's handle_info.
  Uses `:sys.get_state/1` to ensure the message is processed before returning.
  """
  @spec send_info(view(), term()) :: term()
  def send_info(%{server: server}, msg) do
    send(server, msg)
    :sys.get_state(server)
  end

  @doc """
  Get the last rendered element tree.
  """
  @spec render_tree(view()) :: Element.t() | nil
  def render_tree(%{renderer_name: name}) do
    Renderer.get_last_tree(name)
  end

  @doc """
  Extract all text content from the last rendered element tree.

  Walks the tree depth-first, collecting string children.
  Returns a single string with all text content joined by spaces.
  """
  @spec render_text(view()) :: String.t()
  def render_text(view) do
    tree = render_tree(view)

    tree
    |> collect_text()
    |> Enum.join(" ")
    |> String.trim()
  end

  defp collect_text(nil), do: []
  defp collect_text(text) when is_binary(text), do: [text]

  defp collect_text(%Element{children: children}) do
    Enum.flat_map(children, &collect_text/1)
  end
end
