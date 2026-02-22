defmodule Courgette.FocusManagerTest do
  use ExUnit.Case

  alias Courgette.FocusManager

  # Dummy modules for keys
  defmodule Input, do: :ok
  defmodule Select, do: :ok
  defmodule Button, do: :ok

  describe "new/0" do
    test "creates empty struct" do
      fm = FocusManager.new()
      assert fm.focused == nil
      assert fm.order == []
    end
  end

  describe "update_order/2" do
    test "sets order" do
      fm = FocusManager.new()
      fm = FocusManager.update_order(fm, [{Input, "a"}, {Select, "b"}])
      assert fm.order == [{Input, "a"}, {Select, "b"}]
    end

    test "preserves focus when focused component is still in order" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}, {Select, "b"}]}
      fm = FocusManager.update_order(fm, [{Input, "a"}, {Button, "c"}])
      assert fm.focused == {Input, "a"}
    end

    test "auto-focuses first when focused component is removed from order" do
      fm = %FocusManager{focused: {Select, "b"}, order: [{Input, "a"}, {Select, "b"}]}
      fm = FocusManager.update_order(fm, [{Input, "a"}, {Button, "c"}])
      assert fm.focused == {Input, "a"}
    end

    test "handles empty order" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      fm = FocusManager.update_order(fm, [])
      assert fm.focused == nil
      assert fm.order == []
    end

    test "auto-focuses first child when focused is nil and order is non-empty" do
      fm = FocusManager.new()
      fm = FocusManager.update_order(fm, [{Input, "a"}])
      assert fm.focused == {Input, "a"}
      assert fm.order == [{Input, "a"}]
    end

    test "returns nil when order is empty and focused is nil" do
      fm = FocusManager.new()
      fm = FocusManager.update_order(fm, [])
      assert fm.focused == nil
      assert fm.order == []
    end
  end

  describe "focus_next/1" do
    test "empty order is no-op" do
      fm = FocusManager.new()
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == nil
      assert new_fm.focused == nil
    end

    test "nil focus advances to first" do
      fm = %FocusManager{focused: nil, order: [{Input, "a"}, {Select, "b"}]}
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == nil
      assert new_fm.focused == {Input, "a"}
    end

    test "advances to next" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}, {Select, "b"}, {Button, "c"}]}
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == {Input, "a"}
      assert new_fm.focused == {Select, "b"}
    end

    test "wraps from last to first" do
      fm = %FocusManager{focused: {Button, "c"}, order: [{Input, "a"}, {Select, "b"}, {Button, "c"}]}
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == {Button, "c"}
      assert new_fm.focused == {Input, "a"}
    end

    test "single item wraps to itself" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == {Input, "a"}
      assert new_fm.focused == {Input, "a"}
    end

    test "nil focus with single item focuses it" do
      fm = %FocusManager{focused: nil, order: [{Input, "a"}]}
      {old, new_fm} = FocusManager.focus_next(fm)
      assert old == nil
      assert new_fm.focused == {Input, "a"}
    end
  end

  describe "focus_prev/1" do
    test "empty order is no-op" do
      fm = FocusManager.new()
      {old, new_fm} = FocusManager.focus_prev(fm)
      assert old == nil
      assert new_fm.focused == nil
    end

    test "nil focus goes to last" do
      fm = %FocusManager{focused: nil, order: [{Input, "a"}, {Select, "b"}, {Button, "c"}]}
      {old, new_fm} = FocusManager.focus_prev(fm)
      assert old == nil
      assert new_fm.focused == {Button, "c"}
    end

    test "retreats to previous" do
      fm = %FocusManager{focused: {Select, "b"}, order: [{Input, "a"}, {Select, "b"}, {Button, "c"}]}
      {old, new_fm} = FocusManager.focus_prev(fm)
      assert old == {Select, "b"}
      assert new_fm.focused == {Input, "a"}
    end

    test "wraps from first to last" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}, {Select, "b"}, {Button, "c"}]}
      {old, new_fm} = FocusManager.focus_prev(fm)
      assert old == {Input, "a"}
      assert new_fm.focused == {Button, "c"}
    end

    test "single item wraps to itself" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      {old, new_fm} = FocusManager.focus_prev(fm)
      assert old == {Input, "a"}
      assert new_fm.focused == {Input, "a"}
    end
  end

  describe "set_focus/2" do
    test "sets focus directly" do
      fm = %FocusManager{focused: nil, order: [{Input, "a"}, {Select, "b"}]}
      {old, new_fm} = FocusManager.set_focus(fm, {Select, "b"})
      assert old == nil
      assert new_fm.focused == {Select, "b"}
    end

    test "returns old focused" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}, {Select, "b"}]}
      {old, new_fm} = FocusManager.set_focus(fm, {Select, "b"})
      assert old == {Input, "a"}
      assert new_fm.focused == {Select, "b"}
    end

    test "can set to nil" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      {old, new_fm} = FocusManager.set_focus(fm, nil)
      assert old == {Input, "a"}
      assert new_fm.focused == nil
    end
  end

  describe "current/1" do
    test "returns nil when nothing focused" do
      fm = FocusManager.new()
      assert FocusManager.current(fm) == nil
    end

    test "returns focused key" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      assert FocusManager.current(fm) == {Input, "a"}
    end
  end

  describe "focused?/2" do
    test "returns true for focused component" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}]}
      assert FocusManager.focused?(fm, {Input, "a"})
    end

    test "returns false for non-focused component" do
      fm = %FocusManager{focused: {Input, "a"}, order: [{Input, "a"}, {Select, "b"}]}
      refute FocusManager.focused?(fm, {Select, "b"})
    end

    test "returns false when nothing focused" do
      fm = FocusManager.new()
      refute FocusManager.focused?(fm, {Input, "a"})
    end
  end
end
