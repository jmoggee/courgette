defmodule Courgette.LiveComponent.LifecycleTest do
  use ExUnit.Case

  alias Courgette.LiveComponent.Lifecycle
  alias Courgette.Element

  # Dummy modules for specs
  defmodule Counter, do: :ok
  defmodule AgentCard, do: :ok

  describe "extract_components/1" do
    test "returns [] for tree with no live_components" do
      tree = Element.new(:box, [], [
        Element.new(:text, [], ["Hello"])
      ])

      assert Lifecycle.extract_components(tree) == []
    end

    test "returns [] for nil" do
      assert Lifecycle.extract_components(nil) == []
    end

    test "finds direct live_component children" do
      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "a", initial: 1], []),
        Element.new(:live_component, [module: AgentCard, id: "b"], [])
      ])

      specs = Lifecycle.extract_components(tree)

      assert specs == [
               {Counter, "a", %{initial: 1}},
               {AgentCard, "b", %{}}
             ]
    end

    test "does NOT recurse into :live_component elements" do
      # A live_component that itself has children in the tree (shouldn't happen,
      # but verifies we don't look inside)
      inner = Element.new(:live_component, [module: AgentCard, id: "inner"], [])

      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "outer"],
          [inner])
      ])

      specs = Lifecycle.extract_components(tree)

      # Should only find the outer one — stops recursion at :live_component
      assert specs == [{Counter, "outer", %{}}]
    end

    test "finds live_components nested inside boxes" do
      tree = Element.new(:box, [], [
        Element.new(:box, [border: :single], [
          Element.new(:live_component, [module: Counter, id: "deep"], [])
        ]),
        Element.new(:text, [], ["Label"])
      ])

      specs = Lifecycle.extract_components(tree)
      assert specs == [{Counter, "deep", %{}}]
    end

    test "handles multiple levels of nesting" do
      tree = Element.new(:box, [], [
        Element.new(:box, [], [
          Element.new(:box, [], [
            Element.new(:live_component, [module: Counter, id: "1"], []),
            Element.new(:live_component, [module: Counter, id: "2"], [])
          ])
        ]),
        Element.new(:live_component, [module: AgentCard, id: "3"], [])
      ])

      specs = Lifecycle.extract_components(tree)

      assert specs == [
               {Counter, "1", %{}},
               {Counter, "2", %{}},
               {AgentCard, "3", %{}}
             ]
    end
  end

  describe "extract_components strips :focusable" do
    test "focusable prop is not included in returned props" do
      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "a", focusable: true, label: "hi"], [])
      ])

      [{Counter, "a", props}] = Lifecycle.extract_components(tree)
      refute Map.has_key?(props, :focusable)
      assert props == %{label: "hi"}
    end
  end

  describe "extract_focusable_order/1" do
    test "returns [] for nil" do
      assert Lifecycle.extract_focusable_order(nil) == []
    end

    test "returns [] when no components are focusable" do
      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "a"], []),
        Element.new(:live_component, [module: AgentCard, id: "b"], [])
      ])

      assert Lifecycle.extract_focusable_order(tree) == []
    end

    test "finds focusable components in document order" do
      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "a", focusable: true], []),
        Element.new(:live_component, [module: AgentCard, id: "b", focusable: true], [])
      ])

      assert Lifecycle.extract_focusable_order(tree) == [{Counter, "a"}, {AgentCard, "b"}]
    end

    test "skips non-focusable components" do
      tree = Element.new(:box, [], [
        Element.new(:live_component, [module: Counter, id: "a", focusable: true], []),
        Element.new(:live_component, [module: AgentCard, id: "b"], []),
        Element.new(:live_component, [module: Counter, id: "c", focusable: true], [])
      ])

      assert Lifecycle.extract_focusable_order(tree) == [{Counter, "a"}, {Counter, "c"}]
    end

    test "finds focusable components nested inside boxes" do
      tree = Element.new(:box, [], [
        Element.new(:box, [border: :single], [
          Element.new(:live_component, [module: Counter, id: "deep", focusable: true], [])
        ]),
        Element.new(:text, [], ["Label"])
      ])

      assert Lifecycle.extract_focusable_order(tree) == [{Counter, "deep"}]
    end

    test "tree with only non-element children returns []" do
      tree = Element.new(:box, [], ["just text"])
      assert Lifecycle.extract_focusable_order(tree) == []
    end
  end

  describe "reconcile/2" do
    test "all new specs → to_start" do
      old = %{}

      new_specs = [
        {Counter, "a", %{count: 0}},
        {AgentCard, "b", %{}}
      ]

      result = Lifecycle.reconcile(old, new_specs)

      assert result.to_start == [{Counter, "a", %{count: 0}}, {AgentCard, "b", %{}}]
      assert result.to_update == []
      assert result.to_stop == []
    end

    test "same id with changed props → to_update" do
      pid = self()
      old = %{{Counter, "a"} => {pid, %{count: 0}}}
      new_specs = [{Counter, "a", %{count: 5}}]

      result = Lifecycle.reconcile(old, new_specs)

      assert result.to_start == []
      assert result.to_update == [{pid, Counter, "a", %{count: 5}}]
      assert result.to_stop == []
    end

    test "same id with same props → skip (no action)" do
      pid = self()
      old = %{{Counter, "a"} => {pid, %{count: 0}}}
      new_specs = [{Counter, "a", %{count: 0}}]

      result = Lifecycle.reconcile(old, new_specs)

      assert result.to_start == []
      assert result.to_update == []
      assert result.to_stop == []
    end

    test "missing from new specs → to_stop" do
      pid = self()
      old = %{{Counter, "a"} => {pid, %{count: 0}}}
      new_specs = []

      result = Lifecycle.reconcile(old, new_specs)

      assert result.to_start == []
      assert result.to_update == []
      assert result.to_stop == [{pid, Counter, "a"}]
    end

    test "mixed: start, update, and stop" do
      pid_a = spawn(fn -> Process.sleep(:infinity) end)
      pid_b = spawn(fn -> Process.sleep(:infinity) end)

      old = %{
        {Counter, "a"} => {pid_a, %{count: 0}},
        {Counter, "b"} => {pid_b, %{count: 10}}
      }

      new_specs = [
        {Counter, "a", %{count: 5}},
        {AgentCard, "c", %{name: "new"}}
      ]

      result = Lifecycle.reconcile(old, new_specs)

      assert result.to_start == [{AgentCard, "c", %{name: "new"}}]
      assert result.to_update == [{pid_a, Counter, "a", %{count: 5}}]
      assert [{^pid_b, Counter, "b"}] = result.to_stop
    end
  end
end
