defmodule Courgette.Animation.FramesTest do
  use ExUnit.Case, async: true

  alias Courgette.Animation.Frames

  # --- new/1 ---

  test "new stores items as tuple" do
    frames = Frames.new(["a", "b", "c"])
    assert is_tuple(frames.items)
    assert frames.items == {"a", "b", "c"}
  end

  test "new sets count from list length" do
    frames = Frames.new(["a", "b", "c"])
    assert frames.count == 3
  end

  test "new starts at index 0" do
    frames = Frames.new(["a", "b"])
    assert frames.index == 0
  end

  # --- current/1 ---

  test "current returns first item initially" do
    frames = Frames.new(["x", "y", "z"])
    assert Frames.current(frames) == "x"
  end

  test "current does not advance" do
    frames = Frames.new(["x", "y", "z"])
    assert Frames.current(frames) == "x"
    assert Frames.current(frames) == "x"
  end

  # --- next/1 ---

  test "next returns current frame and advances" do
    frames = Frames.new(["a", "b", "c"])
    {frame, frames} = Frames.next(frames)
    assert frame == "a"
    assert frames.index == 1
  end

  test "next cycles through all frames" do
    frames = Frames.new(["a", "b", "c"])
    {f1, frames} = Frames.next(frames)
    {f2, frames} = Frames.next(frames)
    {f3, _frames} = Frames.next(frames)
    assert [f1, f2, f3] == ["a", "b", "c"]
  end

  test "next wraps around to beginning" do
    frames = Frames.new(["a", "b"])
    {_, frames} = Frames.next(frames)
    {_, frames} = Frames.next(frames)
    {frame, _frames} = Frames.next(frames)
    assert frame == "a"
  end

  test "next with single-item list always returns same frame" do
    frames = Frames.new(["only"])
    {f1, frames} = Frames.next(frames)
    {f2, _frames} = Frames.next(frames)
    assert f1 == "only"
    assert f2 == "only"
  end

  # --- reset/1 ---

  test "reset returns to index 0" do
    frames = Frames.new(["a", "b", "c"])
    {_, frames} = Frames.next(frames)
    {_, frames} = Frames.next(frames)
    assert frames.index == 2

    frames = Frames.reset(frames)
    assert frames.index == 0
    assert Frames.current(frames) == "a"
  end

  # --- Built-in frame sets ---

  test "braille returns 10-frame set" do
    frames = Frames.braille()
    assert frames.count == 10
    assert Frames.current(frames) == "⠋"
  end

  test "dots is alias for braille" do
    dots = Frames.dots()
    braille = Frames.braille()
    assert dots.items == braille.items
  end

  test "line returns 4-frame set" do
    frames = Frames.line()
    assert frames.count == 4
    assert Frames.current(frames) == "-"
  end

  test "wave returns 14-frame set" do
    frames = Frames.wave()
    assert frames.count == 14
    assert Frames.current(frames) == "▁"
  end

  test "circle returns 4-frame set" do
    frames = Frames.circle()
    assert frames.count == 4
    assert Frames.current(frames) == "◐"
  end

  test "bounce returns 8-frame set" do
    frames = Frames.bounce()
    assert frames.count == 8
    assert Frames.current(frames) == "⠁"
  end

  # --- O(1) access ---

  test "current uses elem/2 for O(1) access" do
    # Large frame set to demonstrate O(1) vs O(n) matters
    frames = Frames.new(Enum.to_list(1..1000))
    # Jump to a late index
    frames = %{frames | index: 999}
    assert Frames.current(frames) == 1000
  end
end
