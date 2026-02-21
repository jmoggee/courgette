defmodule Courgette.ElementTest do
  use ExUnit.Case, async: true

  alias Courgette.Element

  # ── Construction ──────────────────────────────────────────────────

  describe "struct defaults" do
    test "default type is :box" do
      assert %Element{}.type == :box
    end

    test "default props is empty map" do
      assert %Element{}.props == %{}
    end

    test "default children is empty list" do
      assert %Element{}.children == []
    end
  end

  # ── new/2 ────────────────────────────────────────────────────────

  describe "new/2" do
    test "creates element with type and default children" do
      el = Element.new(:text)
      assert el.type == :text
      assert el.props == %{}
      assert el.children == []
    end

    test "creates box with props" do
      el = Element.new(:box, border: :single, bg: :blue)
      assert el.type == :box
      assert el.props == %{border: :single, bg: :blue}
      assert el.children == []
    end

    test "creates text with color" do
      el = Element.new(:text, color: :green, bold: true)
      assert el.type == :text
      assert el.props == %{color: :green, bold: true}
    end

    test "accepts children via opts" do
      child = Element.new(:text, color: :red, children: ["Hello"])
      assert child.children == ["Hello"]
    end

    test "all valid types are accepted" do
      for type <- [:box, :text, :grid, :col, :scrollable_area, :button, :input] do
        el = Element.new(type)
        assert el.type == type
      end
    end

    test "invalid type raises" do
      assert_raise FunctionClauseError, fn ->
        Element.new(:invalid)
      end
    end
  end

  # ── new/3 ────────────────────────────────────────────────────────

  describe "new/3" do
    test "creates element with type, props, and children" do
      el = Element.new(:box, [border: :single], [
        Element.new(:text, [], ["Hello"])
      ])

      assert el.type == :box
      assert el.props == %{border: :single}
      assert length(el.children) == 1
    end

    test "text element with string children" do
      el = Element.new(:text, [color: :red], ["Error!"])
      assert el.type == :text
      assert el.props == %{color: :red}
      assert el.children == ["Error!"]
    end

    test "empty props and children" do
      el = Element.new(:box, [], [])
      assert el.type == :box
      assert el.props == %{}
      assert el.children == []
    end

    test "nested element tree" do
      tree = Element.new(:box, [border: :single], [
        Element.new(:text, [color: :green], ["Line 1"]),
        Element.new(:text, [color: :red], ["Line 2"]),
        Element.new(:box, [border: :rounded], [
          Element.new(:text, [], ["Nested"])
        ])
      ])

      assert tree.type == :box
      assert length(tree.children) == 3
      assert Enum.at(tree.children, 2).type == :box
      assert Enum.at(tree.children, 2).children |> hd() |> Map.get(:children) == ["Nested"]
    end

    test "mixed string and element children" do
      el = Element.new(:text, [color: :cyan], ["Hello ", "world"])
      assert el.children == ["Hello ", "world"]
    end
  end
end
