defmodule Courgette.LiveComponent do
  @moduledoc """
  Behaviour for live (stateful, process-backed) components.

  A live component defines callbacks that the runtime calls to manage
  state and rendering:

      defmodule MyApp.Counter do
        use Courgette.LiveComponent

        def mount(_assigns) do
          {:ok, %{count: 0}}
        end

        def render(assigns) do
          box border: :rounded do
            text do
              "Count: \#{assigns.count}"
            end
          end
        end

        def handle_event({:key, :arrow_up}, assigns) do
          {:noreply, update(assigns, :count, &(&1 + 1))}
        end

        def handle_event(_event, assigns) do
          {:noreply, assigns}
        end
      end

  ## Callbacks

  - `mount/1` — called once on startup with initial assigns. Must return `{:ok, assigns}`.
  - `render/1` — called after mount and after every state change. Returns an element tree.
  - `handle_event/2` — called with parsed key/mouse events and current assigns. Optional.
  - `handle_info/2` — called with raw Erlang messages. Optional.
  - `terminate/2` — called on shutdown. Optional.

  ## State Helpers

  `use Courgette.LiveComponent` imports pure map helpers for working with assigns:

  - `assign(assigns, map)` — merge a map of key-value pairs
  - `assign(assigns, key, value)` — set a single key
  - `assign_new(assigns, key, fun)` — set key only if absent
  - `update(assigns, key, fun)` — apply a function to an existing key
  """

  @doc "Called once on startup. Returns `{:ok, assigns}`."
  @callback mount(assigns :: map()) :: {:ok, map()}

  @doc "Called to produce the element tree. Must return an `Element.t()`."
  @callback render(assigns :: map()) :: Courgette.Element.t()

  @doc "Called with a parsed input event. Returns `{:noreply, assigns}`."
  @callback handle_event(event :: term(), assigns :: map()) :: {:noreply, map()}

  @doc "Called with a raw Erlang message. Returns `{:noreply, assigns}`."
  @callback handle_info(msg :: term(), assigns :: map()) :: {:noreply, map()}

  @doc "Called on shutdown."
  @callback terminate(reason :: term(), assigns :: map()) :: term()

  @optional_callbacks handle_event: 2, handle_info: 2, terminate: 2

  defmacro __using__(_opts) do
    quote do
      @behaviour Courgette.LiveComponent

      import Courgette.Component.DSL
      import Courgette.Component, only: [theme: 2, render_slot: 1, render_slot: 2]

      import Courgette.LiveComponent,
        only: [assign: 2, assign: 3, assign_new: 3, update: 3]
    end
  end

  # -- State helpers (pure map operations) --

  @doc "Merge a map of key-value pairs into assigns."
  @spec assign(map(), map() | keyword()) :: map()
  def assign(assigns, kv) when is_map(assigns) and is_map(kv) do
    Map.merge(assigns, kv)
  end

  def assign(assigns, kv) when is_map(assigns) and is_list(kv) do
    Map.merge(assigns, Map.new(kv))
  end

  @doc "Set a single key in assigns."
  @spec assign(map(), atom(), term()) :: map()
  def assign(assigns, key, value) when is_map(assigns) and is_atom(key) do
    Map.put(assigns, key, value)
  end

  @doc "Set key only if it is not already present in assigns."
  @spec assign_new(map(), atom(), (-> term())) :: map()
  def assign_new(assigns, key, fun) when is_map(assigns) and is_atom(key) and is_function(fun, 0) do
    case assigns do
      %{^key => _} -> assigns
      _ -> Map.put(assigns, key, fun.())
    end
  end

  @doc "Apply a function to the value of an existing key."
  @spec update(map(), atom(), (term() -> term())) :: map()
  def update(assigns, key, fun) when is_map(assigns) and is_atom(key) and is_function(fun, 1) do
    Map.update!(assigns, key, fun)
  end
end
