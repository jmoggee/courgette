defmodule TestComponents do
  use Courgette.Component

  attr :name, :string, default: "stranger"

  def greeting(assigns) do
    assigns = assigns(assigns)
    name = Map.get(assigns, :name, "stranger")

    text do
      "Hello, #{name}!"
    end
  end

  attr :color, :atom

  def themed_text(assigns) do
    assigns = assigns(assigns)
    color = theme(assigns, :primary)
    text(color: color, do: "themed")
  end

  attr :title, :string, default: "Untitled"
  slot :header
  slot :body

  def card(assigns) do
    assigns = assigns(assigns)

    box border: :single do
      render_slot(assigns[:header])
      render_slot(assigns[:body])
    end
  end
end

defmodule Courgette.ComponentTest do
  use ExUnit.Case, async: true

  alias Courgette.{Component, Element, Theme}

  describe "assigns/1" do
    test "converts keyword list to map" do
      assert Component.assigns(name: "Jeff", color: :blue) == %{name: "Jeff", color: :blue}
    end

    test "empty keyword list" do
      assert Component.assigns([]) == %{}
    end
  end

  describe "theme/2" do
    test "looks up token from default theme" do
      assigns = %{}
      assert Component.theme(assigns, :primary) == :blue
    end

    test "looks up token from custom theme" do
      custom = %Theme{name: "custom", tokens: %{primary: :magenta}}
      assigns = %{theme: custom}
      assert Component.theme(assigns, :primary) == :magenta
    end

    test "raises for unknown token" do
      assert_raise ArgumentError, ~r/unknown theme token/, fn ->
        Component.theme(%{}, :nonexistent)
      end
    end
  end

  describe "render_slot/1" do
    test "nil returns empty list" do
      assert Component.render_slot(nil) == []
    end

    test "list passes through" do
      elements = [Element.new(:text, [], ["a"]), Element.new(:text, [], ["b"])]
      assert Component.render_slot(elements) == elements
    end

    test "single element wrapped in list" do
      el = Element.new(:text, [], ["solo"])
      assert Component.render_slot(el) == [el]
    end
  end

  describe "render_slot/2" do
    test "nil returns empty list" do
      assert Component.render_slot(nil, fn _ -> :ignored end) == []
    end

    test "maps function over list" do
      elements = [Element.new(:text, [], ["a"]), Element.new(:text, [], ["b"])]

      result =
        Component.render_slot(elements, fn el ->
          Element.new(:box, [], [el])
        end)

      assert length(result) == 2
      assert Enum.all?(result, &(&1.type == :box))
    end

    test "maps function over single element" do
      el = Element.new(:text, [], ["solo"])
      [result] = Component.render_slot(el, fn e -> Element.new(:box, [], [e]) end)
      assert result.type == :box
      assert [^el] = result.children
    end
  end

  describe "use Courgette.Component" do
    test "imports DSL macros" do
      el = TestComponents.greeting(name: "World")
      assert el.type == :text
      assert el.children == ["Hello, World!"]
    end

    test "imports assigns/1" do
      el = TestComponents.greeting([])
      assert el.children == ["Hello, stranger!"]
    end

    test "imports theme/2" do
      el = TestComponents.themed_text([])
      assert el.props.color == :blue
    end

    test "theme/2 with custom theme" do
      custom = %Theme{name: "custom", tokens: %{primary: :magenta}}
      el = TestComponents.themed_text(theme: custom)
      assert el.props.color == :magenta
    end
  end

  describe "attr declarations" do
    test "__components__/0 returns component info" do
      components = TestComponents.__components__()
      assert is_list(components)
    end

    test "component attrs are captured" do
      components = TestComponents.__components__()
      {_name, info} = Enum.find(components, fn {name, _} -> name == :greeting end)
      assert is_list(info.attrs)

      name_attr = Enum.find(info.attrs, fn {n, _} -> n == :name end)
      assert {_n, opts} = name_attr
      assert opts[:type] == :string
      assert opts[:default] == "stranger"
    end

    test "component slots are captured" do
      components = TestComponents.__components__()
      {_name, info} = Enum.find(components, fn {name, _} -> name == :card end)
      assert is_list(info.slots)

      header_slot = Enum.find(info.slots, fn {n, _} -> n == :header end)
      assert {_n, _opts} = header_slot
    end
  end

  describe "multiple components in one module" do
    test "each function gets its own attrs" do
      components = TestComponents.__components__()

      {_, greeting_info} = Enum.find(components, fn {n, _} -> n == :greeting end)
      {_, card_info} = Enum.find(components, fn {n, _} -> n == :card end)

      greeting_attr_names = Enum.map(greeting_info.attrs, fn {n, _} -> n end)
      card_attr_names = Enum.map(card_info.attrs, fn {n, _} -> n end)

      assert :name in greeting_attr_names
      refute :title in greeting_attr_names
      assert :title in card_attr_names
      refute :name in card_attr_names
    end
  end

  describe "validation" do
    test "duplicate attrs produce warnings" do
      warnings =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          defmodule DuplicateAttrComponent do
            use Courgette.Component

            attr :name, :string
            attr :name, :string

            def my_func(assigns) do
              assigns = assigns(assigns)
              text(do: assigns[:name])
            end
          end
        end)

      assert warnings =~ "duplicate attr"
    end

    test "invalid attr types produce warnings" do
      warnings =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          defmodule InvalidTypeComponent do
            use Courgette.Component

            attr :name, :nonsense

            def my_func(assigns) do
              assigns = assigns(assigns)
              text(do: assigns[:name])
            end
          end
        end)

      assert warnings =~ "invalid attr type"
    end

    test "duplicate slots produce warnings" do
      warnings =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          defmodule DuplicateSlotComponent do
            use Courgette.Component

            slot :header
            slot :header

            def my_func(assigns) do
              assigns = assigns(assigns)
              box(do: render_slot(assigns[:header]))
            end
          end
        end)

      assert warnings =~ "duplicate slot"
    end
  end
end
