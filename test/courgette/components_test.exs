defmodule Courgette.ComponentsTest do
  use ExUnit.Case, async: true

  import Courgette.Components
  alias Courgette.Theme

  describe "divider/1" do
    test "default is horizontal" do
      el = divider([])
      assert el.type == :text
      [content] = el.children
      assert String.contains?(content, "─")
    end

    test "vertical orientation" do
      el = divider(orientation: :vertical)
      assert el.type == :text
      [content] = el.children
      assert String.contains?(content, "│")
    end

    test "uses muted color by default" do
      el = divider([])
      assert el.props.color == :bright_black
    end

    test "custom color" do
      el = divider(color: :cyan)
      assert el.props.color == :cyan
    end

    test "themed color" do
      custom = %Theme{name: "custom", tokens: %{muted: :magenta}}
      el = divider(theme: custom)
      assert el.props.color == :magenta
    end
  end

  describe "badge/1" do
    test "renders label in rounded border box" do
      el = badge(label: "OK")
      assert el.type == :box
      assert el.props.border == :rounded
      [text_el] = el.children
      assert text_el.type == :text
      assert text_el.children == [" OK "]
    end

    test "uses primary color by default" do
      el = badge(label: "Test")
      assert el.props.border_color == :blue
      [text_el] = el.children
      assert text_el.props.color == :blue
    end

    test "custom color" do
      el = badge(label: "Error", color: :red)
      assert el.props.border_color == :red
      [text_el] = el.children
      assert text_el.props.color == :red
    end

    test "empty label" do
      el = badge([])
      [text_el] = el.children
      assert text_el.children == ["  "]
    end
  end

  describe "heading/1" do
    test "renders bold text with divider" do
      el = heading(text: "Dashboard")
      assert el.type == :box
      assert el.props.flex_direction == :column
      children = el.children
      assert length(children) == 2

      [text_el, divider_el] = children
      assert text_el.type == :text
      assert text_el.props.bold == true
      assert text_el.children == ["Dashboard"]
      assert divider_el.type == :text
    end

    test "without divider" do
      el = heading(text: "Title", divider: false)
      assert el.type == :box
      # Only the text child, no divider (nil filtered out)
      assert length(el.children) == 1
      [text_el] = el.children
      assert text_el.children == ["Title"]
    end

    test "uses primary color by default" do
      el = heading(text: "Test")
      [text_el, _] = el.children
      assert text_el.props.color == :blue
    end

    test "custom color" do
      el = heading(text: "Status", color: :cyan)
      [text_el, _] = el.children
      assert text_el.props.color == :cyan
    end

    test "themed heading" do
      custom = %Theme{name: "custom", tokens: %{primary: :magenta, muted: :white}}
      el = heading(text: "Themed", theme: custom)
      [text_el, _] = el.children
      assert text_el.props.color == :magenta
    end
  end

  describe "key_value/1" do
    test "renders label and value" do
      el = key_value(label: "Name", value: "Jeff")
      assert el.type == :box
      assert el.props.flex_direction == :row

      [label_el, value_el] = el.children
      assert label_el.type == :text
      assert label_el.children == ["Name: "]
      assert label_el.props.color == :bright_black

      assert value_el.type == :text
      assert value_el.children == ["Jeff"]
    end

    test "empty defaults" do
      el = key_value([])
      [label_el, value_el] = el.children
      assert label_el.children == [": "]
      assert value_el.children == [""]
    end

    test "uses muted color for label" do
      el = key_value(label: "Key", value: "Val")
      [label_el, _value_el] = el.children
      assert label_el.props.color == :bright_black
    end

    test "themed key_value" do
      custom = %Theme{name: "custom", tokens: %{muted: :cyan}}
      el = key_value(label: "Key", value: "Val", theme: custom)
      [label_el, _] = el.children
      assert label_el.props.color == :cyan
    end
  end

  describe "empty_state/1" do
    test "renders centered italic message" do
      el = empty_state(message: "No items")
      assert el.type == :box
      assert el.props.justify_content == :center
      assert el.props.align_items == :center

      [text_el] = el.children
      assert text_el.type == :text
      assert text_el.props.italic == true
      assert text_el.children == ["No items"]
    end

    test "default message" do
      el = empty_state([])
      [text_el] = el.children
      assert text_el.children == ["Nothing to show"]
    end

    test "uses muted color" do
      el = empty_state(message: "Empty")
      [text_el] = el.children
      assert text_el.props.color == :bright_black
    end

    test "themed empty_state" do
      custom = %Theme{name: "custom", tokens: %{muted: :yellow}}
      el = empty_state(message: "Empty", theme: custom)
      [text_el] = el.children
      assert text_el.props.color == :yellow
    end
  end

  describe "component introspection" do
    test "__components__/0 lists all 5 components" do
      components = Courgette.Components.__components__()
      names = Enum.map(components, fn {name, _} -> name end)
      assert :divider in names
      assert :badge in names
      assert :heading in names
      assert :key_value in names
      assert :empty_state in names
    end
  end
end
