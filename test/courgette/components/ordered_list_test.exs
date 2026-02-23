defmodule Courgette.Components.OrderedListTest do
  use ExUnit.Case, async: true

  import Courgette.Components.OrderedList

  describe "ordered_list/1" do
    test "renders all items with numbers" do
      el = ordered_list(items: ["Alpha", "Beta", "Gamma"])
      assert el.type == :box
      assert el.props.flex_direction == :column
      assert length(el.children) == 3

      texts =
        Enum.map(el.children, fn row ->
          row.children
          |> Enum.map(fn child -> hd(child.children) end)
          |> Enum.join()
        end)

      assert Enum.at(texts, 0) =~ "1. Alpha"
      assert Enum.at(texts, 1) =~ "2. Beta"
      assert Enum.at(texts, 2) =~ "3. Gamma"
    end

    test "numbers start at 1 by default" do
      el = ordered_list(items: ["First"])
      [row] = el.children
      [number_el | _] = row.children
      [content] = number_el.children
      assert content =~ "1."
    end

    test "custom start number works" do
      el = ordered_list(items: ["A", "B", "C"], start: 5)

      texts =
        Enum.map(el.children, fn row ->
          row.children
          |> Enum.map(fn child -> hd(child.children) end)
          |> Enum.join()
        end)

      assert Enum.at(texts, 0) =~ "5. A"
      assert Enum.at(texts, 1) =~ "6. B"
      assert Enum.at(texts, 2) =~ "7. C"
    end

    test "custom number color works" do
      el = ordered_list(items: ["Item"], color: :green)
      [row] = el.children
      [number_el | _] = row.children
      assert number_el.props.color == :green
    end

    test "empty list renders nothing" do
      el = ordered_list(items: [])
      assert el.type == :box
      assert el.children == []
    end

    test "right-aligns numbers when items exceed 9" do
      items = Enum.map(1..12, &"Item #{&1}")
      el = ordered_list(items: items)

      # First item should be padded: " 1. Item 1"
      first_row = hd(el.children)
      [number_el | _] = first_row.children
      [content] = number_el.children
      # " 1." — padded to width of "12."
      assert content == " 1. "

      # Last item should not be padded: "12. Item 12"
      last_row = List.last(el.children)
      [number_el_last | _] = last_row.children
      [content_last] = number_el_last.children
      assert content_last == "12. "
    end
  end
end
