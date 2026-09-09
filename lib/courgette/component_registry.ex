defmodule Courgette.ComponentRegistry do
  @moduledoc """
  ETS-backed `{module, id} → pid` lookup table for live components.

  Used by `send_update/2` and `send_event/2` to locate a running component by
  its identity, and by the lifecycle reconciler to track child processes.
  """

  @table :courgette_components

  @doc "Create the ETS table if it doesn't already exist."
  @spec create_table() :: :ok
  def create_table do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, :set])
    end

    :ok
  end

  @doc "Delete the ETS table if it exists."
  @spec destroy_table() :: :ok
  def destroy_table do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table)
    end

    :ok
  end

  @doc "Register a component pid under `{module, id}`."
  @spec register(module(), term(), pid()) :: true
  def register(module, id, pid) do
    :ets.insert(@table, {{module, id}, pid})
  end

  @doc "Remove the registration for `{module, id}`. No-op if the table doesn't exist."
  @spec unregister(module(), term()) :: true
  def unregister(module, id) do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table, {module, id})
    else
      true
    end
  end

  @doc "Look up the pid for `{module, id}`. Returns `{:ok, pid}` or `:error`."
  @spec lookup(module(), term()) :: {:ok, pid()} | :error
  def lookup(module, id) do
    if :ets.whereis(@table) == :undefined do
      :error
    else
      case :ets.lookup(@table, {module, id}) do
        [{{^module, ^id}, pid}] -> {:ok, pid}
        [] -> :error
      end
    end
  end

  @doc "List all registered `{{module, id}, pid}` entries."
  @spec all() :: [{{module(), term()}, pid()}]
  def all do
    :ets.tab2list(@table)
  end
end
