defmodule Courgette.Element do
  @moduledoc """
  A node in the element tree — the output of `render/1`.

  Elements are pure data. They describe *what* to render, not *where*.
  Layout computation and painting happen downstream. The DSL macros
  (Phase 4) construct these at compile time; until then, use `new/2,3`.

  ## Types

  - `:box` — flexbox container. Props: `border`, `border_color`, `bg`,
    `padding`, `padding_h`, `padding_v`, `flex_direction`, etc.
  - `:text` — styled text. Props: `color`, `bg`, `bold`, `italic`, etc.
    Children are plain strings.
  - `:grid` — CSS grid container.
  - `:col` — grid column child.
  - `:button` — clickable action element.
  - `:input` — raw input field.

  ## Children

  Children are nested `%Element{}` structs or plain strings (for text
  content). A `:text` element's children are typically `["Hello"]`.
  """

  @type element_type :: :box | :text | :grid | :col | :button | :input | :live_component

  @type t :: %__MODULE__{
          type: element_type(),
          props: map(),
          children: [t() | String.t()]
        }

  defstruct type: :box, props: %{}, children: []

  @valid_types [:box, :text, :grid, :col, :button, :input, :live_component]

  @doc """
  Creates a new element with the given type and options.

  Props are passed as a keyword list and converted to a map.
  Children default to `[]`.

      Element.new(:box, border: :single, bg: :blue)
      Element.new(:text, color: :green)

  """
  @spec new(element_type(), keyword()) :: t()
  def new(type, opts \\ []) when type in @valid_types and is_list(opts) do
    {children, props} = Keyword.pop(opts, :children, [])
    %__MODULE__{type: type, props: Map.new(props), children: List.wrap(children)}
  end

  @doc """
  Creates a new element with the given type, options, and children.

      Element.new(:box, [border: :single], [
        Element.new(:text, [], ["Hello"])
      ])

      Element.new(:text, [color: :red], ["Error!"])

  """
  @spec new(element_type(), keyword(), [t() | String.t()]) :: t()
  def new(type, opts, children)
      when type in @valid_types and is_list(opts) and is_list(children) do
    %__MODULE__{type: type, props: Map.new(opts), children: children}
  end
end
