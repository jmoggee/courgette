defmodule Courgette.Component.DSLTest do
  use ExUnit.Case, async: true

  import Courgette.Component.DSL
  alias Courgette.Element

  describe "box macro" do
    test "no args" do
      el = box()
      assert %Element{type: :box, props: %{}, children: []} = el
    end

    test "props only" do
      el = box(border: :single, bg: :blue)
      assert el.type == :box
      assert el.props == %{border: :single, bg: :blue}
      assert el.children == []
    end

    test "do block with children" do
      el =
        box border: :single do
          text(do: "Hello")
          text(do: "World")
        end

      assert el.type == :box
      assert el.props == %{border: :single}
      assert length(el.children) == 2
      assert Enum.all?(el.children, &(&1.type == :text))
    end

    test "do: shorthand" do
      el = box(do: text(do: "Hi"))
      assert el.type == :box
      assert [%Element{type: :text}] = el.children
    end

    test "empty do block" do
      el = box(do: nil)
      assert el.children == []
    end
  end

  describe "text macro" do
    test "no args" do
      el = text()
      assert %Element{type: :text, props: %{}, children: []} = el
    end

    test "with string child via do:" do
      el = text(color: :green, do: "Hello")
      assert el.type == :text
      assert el.props == %{color: :green}
      assert el.children == ["Hello"]
    end

    test "with do block string" do
      el =
        text color: :red do
          "Error!"
        end

      assert el.type == :text
      assert el.props == %{color: :red}
      assert el.children == ["Error!"]
    end
  end

  describe "all element types" do
    test "grid macro" do
      el = grid(gap: 1, do: col(do: text(do: "A")))
      assert el.type == :grid
      assert el.props == %{gap: 1}
      assert [%Element{type: :col}] = el.children
    end

    test "col macro" do
      el = col(span: 2)
      assert el.type == :col
      assert el.props == %{span: 2}
    end

    test "scrollable_area macro" do
      el = scrollable_area(scroll_offset: 5, do: text(do: "content"))
      assert el.type == :scrollable_area
      assert el.props == %{scroll_offset: 5}
      assert length(el.children) == 1
    end

    test "button macro" do
      el = button(label: "OK")
      assert el.type == :button
      assert el.props == %{label: "OK"}
    end

    test "input macro" do
      el = input(placeholder: "Type...")
      assert el.type == :input
      assert el.props == %{placeholder: "Type..."}
    end
  end

  describe "nesting" do
    test "deeply nested tree" do
      el =
        box border: :rounded do
          box padding: 1 do
            text color: :cyan do
              "Deep"
            end
          end
        end

      assert el.type == :box
      [inner] = el.children
      assert inner.type == :box
      [txt] = inner.children
      assert txt.type == :text
      assert txt.children == ["Deep"]
    end

    test "multiple children at same level" do
      el =
        box do
          text(do: "A")
          text(do: "B")
          text(do: "C")
        end

      assert length(el.children) == 3
    end
  end

  describe "conditionals and comprehensions" do
    test "if without else produces nil that gets filtered" do
      show = false

      el =
        box do
          if show do
            text(do: "shown")
          end

          text(do: "always")
        end

      assert length(el.children) == 1
      assert [%Element{children: ["always"]}] = el.children
    end

    test "if with else" do
      show = true

      el =
        box do
          if show do
            text(do: "yes")
          else
            text(do: "no")
          end
        end

      assert [%Element{children: ["yes"]}] = el.children
    end

    test "for comprehension" do
      items = ["a", "b", "c"]

      el =
        box do
          for item <- items do
            text(do: item)
          end
        end

      assert length(el.children) == 3
      assert Enum.map(el.children, & &1.children) == [["a"], ["b"], ["c"]]
    end

    test "mixed comprehension and static children" do
      items = [1, 2]

      el =
        box do
          text(do: "header")

          for i <- items do
            text(do: "item #{i}")
          end

          text(do: "footer")
        end

      assert length(el.children) == 4
      assert List.first(el.children).children == ["header"]
      assert List.last(el.children).children == ["footer"]
    end
  end

  describe "live_component macro" do
    defmodule FakeComponent, do: :ok

    test "props only, no do block" do
      el = live_component(FakeComponent, id: "a", count: 5)
      assert el.type == :live_component
      assert el.props.module == FakeComponent
      assert el.props.id == "a"
      assert el.props.count == 5
      assert el.children == []
    end

    test "with do block stores children" do
      el =
        live_component(FakeComponent, id: "b") do
          text(do: "child1")
          text(do: "child2")
        end

      assert el.type == :live_component
      assert el.props.module == FakeComponent
      assert el.props.id == "b"
      assert length(el.children) == 2
      assert Enum.all?(el.children, &(&1.type == :text))
    end

    test "with inline do: shorthand" do
      el = live_component(FakeComponent, id: "c", do: text(do: "inline"))
      assert el.type == :live_component
      assert el.props.module == FakeComponent
      assert el.props.id == "c"
      assert [%Element{type: :text}] = el.children
    end

    test "do block with conditional children" do
      show = false

      el =
        live_component(FakeComponent, id: "d") do
          if show do
            text(do: "hidden")
          end

          text(do: "visible")
        end

      assert length(el.children) == 1
      assert [%Element{children: ["visible"]}] = el.children
    end

    test "do block with comprehension" do
      items = ["x", "y"]

      el =
        live_component(FakeComponent, id: "e") do
          for item <- items do
            text(do: item)
          end
        end

      assert length(el.children) == 2
      assert Enum.map(el.children, & &1.children) == [["x"], ["y"]]
    end
  end

  describe "__flatten_children__/1" do
    test "flattens nested lists" do
      assert Courgette.Component.DSL.__flatten_children__([["a", "b"], "c"]) == ["a", "b", "c"]
    end

    test "removes nils" do
      assert Courgette.Component.DSL.__flatten_children__(["a", nil, "b"]) == ["a", "b"]
    end

    test "handles empty list" do
      assert Courgette.Component.DSL.__flatten_children__([]) == []
    end
  end
end
