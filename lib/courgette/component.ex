defmodule Courgette.Component do
  @moduledoc """
  Defines function components for Courgette.

  A function component is a module that `use`s `Courgette.Component` and
  defines public functions that take a keyword list of assigns and return
  an element tree.

      defmodule MyApp.Components do
        use Courgette.Component

        attr :name, :string, default: "World"
        attr :color, :atom, default: :green

        def greeting(assigns) do
          assigns = assigns(assigns)

          text color: assigns.color do
            "Hello, \#{assigns.name}!"
          end
        end
      end

  ## Attributes and Slots

  `attr/3` declares an attribute with name, type, and options (`:default`,
  `:doc`). `slot/1,2` declares a slot for passing element children.

  Declarations are associated with the next public function defined via
  `@on_definition`. The `__components__/0` callback returns introspection
  data for all declared components.

  ## Assigns

  Components receive a keyword list and convert it to a map with
  `assigns/1`, which applies declared defaults.

  ## Themes

  `theme(assigns, :token)` looks up a semantic color token from the
  theme in assigns, falling back to `Theme.default()`.
  """

  alias Courgette.Theme

  @type attr_type :: :string | :atom | :integer | :float | :boolean | :list | :map | :any

  @doc """
  Converts a keyword list to an assigns map, applying declared defaults.

  Called at the top of each component function:

      def my_component(assigns) do
        assigns = assigns(assigns)
        # assigns is now a map with defaults applied
      end
  """
  @spec assigns(keyword()) :: map()
  def assigns(keyword) when is_list(keyword) do
    Map.new(keyword)
  end

  @doc """
  Looks up a theme token from the `:theme` key in assigns.

  Falls back to `Theme.default()` if no theme is in assigns.

      theme(assigns, :primary)   # => :blue (from default theme)
  """
  @spec theme(map(), atom()) :: Theme.color()
  def theme(assigns, token) when is_map(assigns) and is_atom(token) do
    theme = Map.get(assigns, :theme, Theme.default())
    Theme.get(theme, token)
  end

  @doc """
  Renders a slot's content.

  Slots are lists of elements or single elements passed via assigns.

      render_slot(assigns.header)
  """
  @spec render_slot(nil | Courgette.Element.t() | [Courgette.Element.t()]) ::
          [Courgette.Element.t()]
  def render_slot(nil), do: []
  def render_slot(elements) when is_list(elements), do: elements
  def render_slot(element), do: [element]

  @doc """
  Renders a slot with a mapping function applied to each element.

      render_slot(assigns.items, fn item -> text(do: item) end)
  """
  @spec render_slot(
          nil | Courgette.Element.t() | [Courgette.Element.t()],
          (Courgette.Element.t() -> Courgette.Element.t())
        ) :: [Courgette.Element.t()]
  def render_slot(nil, _fun), do: []
  def render_slot(elements, fun) when is_list(elements), do: Enum.map(elements, fun)
  def render_slot(element, fun), do: [fun.(element)]

  defmacro __using__(_opts) do
    quote do
      import Courgette.Component.DSL

      import Courgette.Component,
        only: [
          assigns: 1,
          theme: 2,
          render_slot: 1,
          render_slot: 2,
          attr: 2,
          attr: 3,
          slot: 1,
          slot: 2
        ]

      Module.register_attribute(__MODULE__, :courgette_attrs, accumulate: true)
      Module.register_attribute(__MODULE__, :courgette_slots, accumulate: true)
      Module.register_attribute(__MODULE__, :courgette_components, accumulate: true)
      Module.put_attribute(__MODULE__, :courgette_consumed, {0, 0})

      @on_definition Courgette.Component
      @before_compile Courgette.Component
    end
  end

  @doc false
  defmacro attr(name, type, opts \\ []) do
    quote do
      @courgette_attrs {unquote(name), unquote(type), unquote(opts)}
    end
  end

  @doc false
  defmacro slot(name, opts \\ []) do
    quote do
      @courgette_slots {unquote(name), unquote(opts)}
    end
  end

  # --- Callbacks ---

  @doc false
  def __on_definition__(env, :def, name, [_assigns], _guards, _body) do
    all_attrs = Module.get_attribute(env.module, :courgette_attrs) || []
    all_slots = Module.get_attribute(env.module, :courgette_slots) || []
    {consumed_attrs, consumed_slots} = Module.get_attribute(env.module, :courgette_consumed)

    # Accumulate attributes are stored most-recent-first.
    # New (unconsumed) attrs are the first (total - consumed) elements.
    new_attr_count = length(all_attrs) - consumed_attrs
    new_slot_count = length(all_slots) - consumed_slots

    if new_attr_count > 0 or new_slot_count > 0 do
      new_attrs = all_attrs |> Enum.take(new_attr_count) |> Enum.reverse()
      new_slots = all_slots |> Enum.take(new_slot_count) |> Enum.reverse()

      Module.put_attribute(env.module, :courgette_components, {name, new_attrs, new_slots})

      Module.put_attribute(
        env.module,
        :courgette_consumed,
        {length(all_attrs), length(all_slots)}
      )
    end
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body), do: :ok

  @doc false
  defmacro __before_compile__(env) do
    components =
      (Module.get_attribute(env.module, :courgette_components) || [])
      |> Enum.reverse()

    validate_components!(components, env)

    components_data =
      for {name, attrs, slots} <- components do
        attrs_data =
          for {attr_name, type, opts} <- attrs do
            {attr_name, Keyword.put(opts, :type, type)}
          end

        slots_data =
          for {slot_name, opts} <- slots do
            {slot_name, opts}
          end

        {name, %{attrs: attrs_data, slots: slots_data}}
      end

    quote do
      @doc false
      def __components__ do
        unquote(Macro.escape(components_data))
      end
    end
  end

  # --- Validation ---

  defp validate_components!(components, env) do
    for {name, attrs, slots} <- components do
      validate_no_duplicate_attrs!(name, attrs, env)
      validate_no_duplicate_slots!(name, slots, env)
      validate_attr_types!(name, attrs, env)
    end
  end

  @valid_types [:string, :atom, :integer, :float, :boolean, :list, :map, :any]

  defp validate_attr_types!(func_name, attrs, env) do
    for {attr_name, type, _opts} <- attrs, type not in @valid_types do
      IO.warn(
        "invalid attr type #{inspect(type)} for attr #{inspect(attr_name)} " <>
          "in #{inspect(func_name)}/1. Expected one of: #{inspect(@valid_types)}",
        Macro.Env.stacktrace(env)
      )
    end
  end

  defp validate_no_duplicate_attrs!(func_name, attrs, env) do
    names = for {name, _, _} <- attrs, do: name
    dupes = names -- Enum.uniq(names)

    for dupe <- Enum.uniq(dupes) do
      IO.warn(
        "duplicate attr #{inspect(dupe)} in #{inspect(func_name)}/1",
        Macro.Env.stacktrace(env)
      )
    end
  end

  defp validate_no_duplicate_slots!(func_name, slots, env) do
    names = for {name, _} <- slots, do: name
    dupes = names -- Enum.uniq(names)

    for dupe <- Enum.uniq(dupes) do
      IO.warn(
        "duplicate slot #{inspect(dupe)} in #{inspect(func_name)}/1",
        Macro.Env.stacktrace(env)
      )
    end
  end
end
