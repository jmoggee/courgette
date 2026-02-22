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

  # --- Built-in frame sets: Braille family ---

  test "dots returns 10-frame set" do
    frames = Frames.dots()
    assert frames.count == 10
    assert Frames.current(frames) == "⠋"
  end

  test "braille is alias for dots" do
    dots = Frames.dots()
    braille = Frames.braille()
    assert dots.items == braille.items
  end

  test "dots_pulse returns 16-frame set" do
    frames = Frames.dots_pulse()
    assert frames.count == 16
    assert Frames.current(frames) == "⠀"
  end

  test "dots_orbit returns 6-frame set" do
    frames = Frames.dots_orbit()
    assert frames.count == 6
    assert Frames.current(frames) == "⠈"
  end

  test "dots_scroll returns 8-frame set" do
    frames = Frames.dots_scroll()
    assert frames.count == 8
    assert Frames.current(frames) == "⣾"
  end

  test "dots_bounce returns 14-frame set" do
    frames = Frames.dots_bounce()
    assert frames.count == 14
    assert Frames.current(frames) == "⠄"
  end

  test "sand returns 35-frame set" do
    frames = Frames.sand()
    assert frames.count == 35
    assert Frames.current(frames) == "⠁"
  end

  test "braille_double returns 6-frame set" do
    frames = Frames.braille_double()
    assert frames.count == 6
    assert Frames.current(frames) == "⠘"
  end

  test "braille_six returns 6-frame set" do
    frames = Frames.braille_six()
    assert frames.count == 6
    assert Frames.current(frames) == "⠷"
  end

  test "braille_eight_double returns 8-frame set" do
    frames = Frames.braille_eight_double()
    assert frames.count == 8
    assert Frames.current(frames) == "⣧"
  end

  # --- Built-in frame sets: Geometric family ---

  test "circle returns 4-frame set" do
    frames = Frames.circle()
    assert frames.count == 4
    assert Frames.current(frames) == "◐"
  end

  test "arc returns 6-frame set" do
    frames = Frames.arc()
    assert frames.count == 6
    assert Frames.current(frames) == "◜"
  end

  test "triangle returns 4-frame set" do
    frames = Frames.triangle()
    assert frames.count == 4
    assert Frames.current(frames) == "◢"
  end

  test "quarter returns 4-frame set" do
    frames = Frames.quarter()
    assert frames.count == 4
    assert Frames.current(frames) == "◴"
  end

  test "box_bounce returns 4-frame set" do
    frames = Frames.box_bounce()
    assert frames.count == 4
    assert Frames.current(frames) == "▖"
  end

  test "pipe returns 8-frame set" do
    frames = Frames.pipe()
    assert frames.count == 8
    assert Frames.current(frames) == "┤"
  end

  test "box_invert returns 4-frame set" do
    frames = Frames.box_invert()
    assert frames.count == 4
    assert Frames.current(frames) == "▙"
  end

  test "square_corners returns 4-frame set" do
    frames = Frames.square_corners()
    assert frames.count == 4
    assert Frames.current(frames) == "◰"
  end

  # --- Built-in frame sets: Block family ---

  test "wave returns 14-frame set" do
    frames = Frames.wave()
    assert frames.count == 14
    assert Frames.current(frames) == "▁"
  end

  test "pulse returns 6-frame set" do
    frames = Frames.pulse()
    assert frames.count == 6
    assert Frames.current(frames) == "█"
  end

  test "meter returns 6-frame set" do
    frames = Frames.meter()
    assert frames.count == 6
    assert Frames.current(frames) == "▱▱▱"
  end

  test "grow_horizontal returns 12-frame set" do
    frames = Frames.grow_horizontal()
    assert frames.count == 12
    assert Frames.current(frames) == "▏"
  end

  test "noise returns 3-frame set" do
    frames = Frames.noise()
    assert frames.count == 3
    assert Frames.current(frames) == "▓"
  end

  test "layer returns 3-frame set" do
    frames = Frames.layer()
    assert frames.count == 3
    assert Frames.current(frames) == "-"
  end

  # --- Built-in frame sets: Classic ---

  test "line returns 4-frame set" do
    frames = Frames.line()
    assert frames.count == 4
    assert Frames.current(frames) == "-"
  end

  test "star returns 6-frame set" do
    frames = Frames.star()
    assert frames.count == 6
    assert Frames.current(frames) == "✶"
  end

  test "point returns 5-frame set" do
    frames = Frames.point()
    assert frames.count == 5
    assert Frames.current(frames) == "∙∙∙"
  end

  test "bounce returns 8-frame set" do
    frames = Frames.bounce()
    assert frames.count == 8
    assert Frames.current(frames) == "⠁"
  end

  test "arrow returns 8-frame set" do
    frames = Frames.arrow()
    assert frames.count == 8
    assert Frames.current(frames) == "←"
  end

  test "ellipsis returns 4-frame set" do
    frames = Frames.ellipsis()
    assert frames.count == 4
    assert Frames.current(frames) == "."
  end

  test "hamburger returns 3-frame set" do
    frames = Frames.hamburger()
    assert frames.count == 3
    assert Frames.current(frames) == "☱"
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
