defmodule Courgette.Component.DSL do
  @moduledoc """
  Macros for building element trees declaratively.

  Each element type gets a macro that expands to `Element.new/3`:

      box padding: 2, border: :single do
        text color: :cyan do
          "Hello"
        end
      end

      # do: shorthand
      text color: :green, do: "Hello"

      # Props only, no children
      input placeholder: "Type..."

      # No args
      box()

  Children in `do` blocks are collected into a flat list with nils
  filtered out (supporting conditional `if` without `else`).
  """

  alias Courgette.Element

  @element_types [:box, :text, :grid, :col, :scrollable_area, :button, :input]

  for type <- @element_types do
    @doc "Creates a `#{inspect(type)}` element."
    defmacro unquote(type)() do
      type = unquote(type)
      quote do: Element.new(unquote(type))
    end

    defmacro unquote(type)(opts_or_body) do
      type = unquote(type)
      build_element(type, opts_or_body)
    end

    defmacro unquote(type)(opts, do_block) do
      type = unquote(type)
      build_element_with_do(type, opts, do_block)
    end
  end

  @doc """
  Declares a live (stateful) child component.

      live_component(Counter, id: "main", initial_count: 5)

      live_component(ScrollArea, id: "scroll", height: 10) do
        text do: "child content"
      end

  Creates a `:live_component` element with the module and options as props.
  The `:id` option is required and used for lifecycle reconciliation.

  When a `do` block is provided, its children are stored on the element's
  `children` field and passed to the component as `:inner_block` in props.
  """
  defmacro live_component(module, opts_or_body) do
    case extract_do(opts_or_body) do
      {props, body} ->
        children = wrap_children(body)

        quote do
          Element.new(
            :live_component,
            [{:module, unquote(module)} | unquote(props)],
            unquote(__MODULE__).__flatten_children__(unquote(children))
          )
        end

      :no_do ->
        quote do
          Element.new(
            :live_component,
            [{:module, unquote(module)} | unquote(opts_or_body)],
            []
          )
        end
    end
  end

  defmacro live_component(module, opts, do_block) do
    children = wrap_children(do_block[:do])

    quote do
      Element.new(
        :live_component,
        [{:module, unquote(module)} | unquote(opts)],
        unquote(__MODULE__).__flatten_children__(unquote(children))
      )
    end
  end

  @doc false
  def __flatten_children__(children) do
    children
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  # --- Private helpers ---

  # Called for single-argument form: either `box(do: ...)` or `box(props)`
  defp build_element(type, opts_or_body) do
    case extract_do(opts_or_body) do
      {props, body} ->
        children = wrap_children(body)

        quote do
          Element.new(
            unquote(type),
            unquote(props),
            unquote(__MODULE__).__flatten_children__(unquote(children))
          )
        end

      :no_do ->
        quote do
          Element.new(unquote(type), unquote(opts_or_body))
        end
    end
  end

  # Called for two-argument form: `box(props, do: body)`
  defp build_element_with_do(type, opts, [{:do, body}]) do
    children = wrap_children(body)

    quote do
      Element.new(
        unquote(type),
        unquote(opts),
        unquote(__MODULE__).__flatten_children__(unquote(children))
      )
    end
  end

  # Splits [props..., do: body] into {props, body} or returns :no_do
  defp extract_do(opts) when is_list(opts) do
    case Keyword.pop(opts, :do) do
      {nil, _} -> :no_do
      {body, props} -> {props, body}
    end
  end

  defp extract_do(_), do: :no_do

  # Wraps body AST expressions into a list for runtime flattening.
  # A __block__ means multiple expressions; otherwise it's a single expression.
  defp wrap_children({:__block__, _, exprs}), do: exprs
  defp wrap_children(single), do: [single]
end
