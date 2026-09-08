defmodule Courgette.SelectionTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Selection

  test "extracts forward and reverse multiline selections in screen order" do
    buffer =
      Buffer.new(8, 3)
      |> Buffer.put_string(0, 0, "first")
      |> Buffer.put_string(0, 1, "second")
      |> Buffer.put_string(0, 2, "third")

    forward = Selection.new({1, 0}) |> Selection.extend({2, 2})
    reverse = Selection.new({2, 2}) |> Selection.extend({1, 0})

    assert Selection.text(forward, buffer) == "irst\nsecond\nthi"
    assert Selection.text(reverse, buffer) == "irst\nsecond\nthi"
  end

  test "a click has no selected text" do
    selection = Selection.new({2, 0})
    assert Selection.empty?(selection)
  end
end
