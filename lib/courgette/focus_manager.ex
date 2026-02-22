defmodule Courgette.FocusManager do
  @moduledoc """
  Pure data structure for tracking focus among child components.

  Manages a focus order (list of `{module, id}` tuples) and which one
  is currently focused. All functions are pure — no processes, no side effects.
  The root Server holds a `%FocusManager{}` in its state and calls these
  functions in response to Tab/Shift-Tab events.
  """

  defstruct focused: nil, order: []

  @type component_key :: {module(), term()}
  @type t :: %__MODULE__{
          focused: component_key() | nil,
          order: [component_key()]
        }

  @doc """
  Create a new empty FocusManager.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Update the focusable order. Preserves focus if the focused component
  is still in the new order; clears focus otherwise.
  """
  @spec update_order(t(), [component_key()]) :: t()
  def update_order(%__MODULE__{} = fm, ids) when is_list(ids) do
    new_focused =
      if fm.focused && fm.focused in ids do
        fm.focused
      else
        nil
      end

    %{fm | order: ids, focused: new_focused}
  end

  @doc """
  Advance focus to the next component in order.

  Returns `{old_focused, new_fm}`. If order is empty, returns `{nil, fm}`.
  If nothing is focused, focuses the first item. Wraps from last to first.
  """
  @spec focus_next(t()) :: {component_key() | nil, t()}
  def focus_next(%__MODULE__{order: []} = fm), do: {nil, fm}

  def focus_next(%__MODULE__{focused: nil, order: [first | _]} = fm) do
    {nil, %{fm | focused: first}}
  end

  def focus_next(%__MODULE__{focused: current, order: order} = fm) do
    idx = Enum.find_index(order, &(&1 == current))

    next =
      if idx == length(order) - 1 do
        List.first(order)
      else
        Enum.at(order, idx + 1)
      end

    {current, %{fm | focused: next}}
  end

  @doc """
  Move focus to the previous component in order.

  Returns `{old_focused, new_fm}`. If order is empty, returns `{nil, fm}`.
  If nothing is focused, focuses the last item. Wraps from first to last.
  """
  @spec focus_prev(t()) :: {component_key() | nil, t()}
  def focus_prev(%__MODULE__{order: []} = fm), do: {nil, fm}

  def focus_prev(%__MODULE__{focused: nil, order: order} = fm) do
    {nil, %{fm | focused: List.last(order)}}
  end

  def focus_prev(%__MODULE__{focused: current, order: order} = fm) do
    idx = Enum.find_index(order, &(&1 == current))

    prev =
      if idx == 0 do
        List.last(order)
      else
        Enum.at(order, idx - 1)
      end

    {current, %{fm | focused: prev}}
  end

  @doc """
  Set focus to a specific component. Returns `{old_focused, new_fm}`.
  """
  @spec set_focus(t(), component_key() | nil) :: {component_key() | nil, t()}
  def set_focus(%__MODULE__{focused: old} = fm, id) do
    {old, %{fm | focused: id}}
  end

  @doc """
  Returns the currently focused component key, or nil.
  """
  @spec current(t()) :: component_key() | nil
  def current(%__MODULE__{focused: focused}), do: focused

  @doc """
  Returns true if the given component key is currently focused.
  """
  @spec focused?(t(), component_key()) :: boolean()
  def focused?(%__MODULE__{focused: focused}, id), do: focused == id
end
