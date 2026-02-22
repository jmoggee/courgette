defmodule Courgette.LiveComponent.Lifecycle do
  @moduledoc """
  Pure function module for child component lifecycle reconciliation.

  Provides two operations:

  - `extract_components/1` — walks an element tree and collects all
    `:live_component` specs (stopping recursion at those nodes).
  - `reconcile/2` — compares old children against new specs to produce
    start/update/stop action lists.
  """

  alias Courgette.Element

  @type component_spec :: {module(), term(), map()}

  @doc """
  Walk the element tree depth-first, collecting `:live_component` elements.

  Returns a list of `{module, id, props}` tuples. Does NOT recurse into
  `:live_component` nodes — those children are managed by the child's own Server.
  """
  @spec extract_components(Element.t() | nil) :: [component_spec()]
  def extract_components(nil), do: []

  def extract_components(%Element{type: :live_component, props: props}) do
    module = Map.fetch!(props, :module)
    id = Map.fetch!(props, :id)
    extra_props = Map.drop(props, [:module, :id])
    [{module, id, extra_props}]
  end

  def extract_components(%Element{children: children}) do
    Enum.flat_map(children, fn
      %Element{} = child -> extract_components(child)
      _string -> []
    end)
  end

  @doc """
  Compare old children map against new specs to produce reconciliation actions.

  ## Parameters

  - `old_children` — `%{{module, id} => {pid, old_props}}`
  - `new_specs` — `[{module, id, new_props}]` from `extract_components/1`

  ## Returns

  A map with three keys:
  - `:to_start` — `[{module, id, props}]`
  - `:to_update` — `[{pid, module, id, new_props}]`
  - `:to_stop` — `[{pid, module, id}]`
  """
  @spec reconcile(map(), [component_spec()]) :: %{
          to_start: [component_spec()],
          to_update: [{pid(), module(), term(), map()}],
          to_stop: [{pid(), module(), term()}]
        }
  def reconcile(old_children, new_specs) do
    new_keys = MapSet.new(new_specs, fn {mod, id, _props} -> {mod, id} end)

    # Determine starts and updates
    {to_start, to_update} =
      Enum.reduce(new_specs, {[], []}, fn {mod, id, props}, {starts, updates} ->
        key = {mod, id}

        case Map.get(old_children, key) do
          nil ->
            {[{mod, id, props} | starts], updates}

          {pid, old_props} ->
            if props != old_props do
              {starts, [{pid, mod, id, props} | updates]}
            else
              {starts, updates}
            end
        end
      end)

    # Determine stops: old keys not in new specs
    to_stop =
      old_children
      |> Enum.reject(fn {key, _val} -> MapSet.member?(new_keys, key) end)
      |> Enum.map(fn {{mod, id}, {pid, _props}} -> {pid, mod, id} end)

    %{
      to_start: Enum.reverse(to_start),
      to_update: Enum.reverse(to_update),
      to_stop: to_stop
    }
  end
end
