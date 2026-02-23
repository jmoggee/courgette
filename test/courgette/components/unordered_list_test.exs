defmodule Courgette.Components.UnorderedListTest do
  use ExUnit.Case, async: true

  import Courgette.Components.UnorderedList

  describe "unordered_list/1" do
    test "renders all items with bullet markers" do
      el = unordered_list(items: ["Alpha", "Beta", "Gamma"])
      assert el.type == :box
      assert el.props.flex_direction == :column
      assert length(el.children) == 3

      texts =
        Enum.map(el.children, fn row ->
          row.children
          |> Enum.map(fn child -> hd(child.children) end)
          |> Enum.join()
        end)

      assert Enum.at(texts, 0) =~ "\u2022 Alpha"
      assert Enum.at(texts, 1) =~ "\u2022 Beta"
      assert Enum.at(texts, 2) =~ "\u2022 Gamma"
    end

    test "custom marker character works" do
      el = unordered_list(items: ["One", "Two"], marker: "-")

      texts =
        Enum.map(el.children, fn row ->
          row.children
          |> Enum.map(fn child -> hd(child.children) end)
          |> Enum.join()
        end)

      assert Enum.at(texts, 0) =~ "- One"
      assert Enum.at(texts, 1) =~ "- Two"
    end

    test "custom marker color works" do
      el = unordered_list(items: ["Item"], color: :red)
      [row] = el.children
      # First child of row is the marker text element
      [marker_el | _] = row.children
      assert marker_el.props.color == :red
    end

    test "empty list renders nothing" do
      el = unordered_list(items: [])
      assert el.type == :box
      assert el.children == []
    end
  end
end
