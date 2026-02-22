defmodule Courgette.ComponentRegistryTest do
  use ExUnit.Case

  alias Courgette.ComponentRegistry

  setup do
    ComponentRegistry.create_table()
    on_exit(fn -> ComponentRegistry.destroy_table() end)
  end

  describe "create_table/0" do
    test "is idempotent" do
      assert :ok = ComponentRegistry.create_table()
      assert :ok = ComponentRegistry.create_table()
    end
  end

  describe "register and lookup" do
    test "register then lookup returns pid" do
      ComponentRegistry.register(MyMod, "abc", self())
      assert {:ok, pid} = ComponentRegistry.lookup(MyMod, "abc")
      assert pid == self()
    end

    test "lookup missing returns :error" do
      assert :error = ComponentRegistry.lookup(NoSuchMod, "nope")
    end

    test "register overwrites existing entry" do
      other = spawn(fn -> Process.sleep(:infinity) end)
      ComponentRegistry.register(MyMod, "x", self())
      ComponentRegistry.register(MyMod, "x", other)

      assert {:ok, ^other} = ComponentRegistry.lookup(MyMod, "x")
    end
  end

  describe "unregister/2" do
    test "removes entry" do
      ComponentRegistry.register(MyMod, "del", self())
      assert {:ok, _} = ComponentRegistry.lookup(MyMod, "del")

      ComponentRegistry.unregister(MyMod, "del")
      assert :error = ComponentRegistry.lookup(MyMod, "del")
    end
  end

  describe "all/0" do
    test "lists all entries" do
      ComponentRegistry.register(ModA, "1", self())
      ComponentRegistry.register(ModB, "2", self())

      entries = ComponentRegistry.all()
      assert length(entries) >= 2
      assert {{ModA, "1"}, _} = Enum.find(entries, fn {{m, _}, _} -> m == ModA end)
      assert {{ModB, "2"}, _} = Enum.find(entries, fn {{m, _}, _} -> m == ModB end)
    end
  end
end
