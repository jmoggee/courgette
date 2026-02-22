defmodule Courgette.Animation.EasingTest do
  use ExUnit.Case, async: true

  alias Courgette.Animation.Easing

  # --- linear ---

  test "linear(0) == 0" do
    assert Easing.linear(0.0) == 0.0
  end

  test "linear(1) == 1" do
    assert Easing.linear(1.0) == 1.0
  end

  test "linear(0.5) == 0.5" do
    assert Easing.linear(0.5) == 0.5
  end

  # --- ease_in (quadratic) ---

  test "ease_in(0) == 0" do
    assert Easing.ease_in(0.0) == 0.0
  end

  test "ease_in(1) == 1" do
    assert Easing.ease_in(1.0) == 1.0
  end

  test "ease_in(0.5) == 0.25" do
    assert Easing.ease_in(0.5) == 0.25
  end

  # --- ease_out (quadratic) ---

  test "ease_out(0) == 0" do
    assert Easing.ease_out(0.0) == 0.0
  end

  test "ease_out(1) == 1" do
    assert Easing.ease_out(1.0) == 1.0
  end

  test "ease_out(0.5) == 0.75" do
    assert Easing.ease_out(0.5) == 0.75
  end

  # --- ease_in_out ---

  test "ease_in_out(0) == 0" do
    assert Easing.ease_in_out(0.0) == 0.0
  end

  test "ease_in_out(1) == 1" do
    assert Easing.ease_in_out(1.0) == 1.0
  end

  test "ease_in_out(0.5) == 0.5" do
    assert Easing.ease_in_out(0.5) == 0.5
  end

  test "ease_in_out first half accelerates" do
    assert Easing.ease_in_out(0.25) < 0.25
  end

  test "ease_in_out second half decelerates" do
    assert Easing.ease_in_out(0.75) > 0.75
  end

  # --- ease_in_cubic ---

  test "ease_in_cubic(0) == 0" do
    assert Easing.ease_in_cubic(0.0) == 0.0
  end

  test "ease_in_cubic(1) == 1" do
    assert Easing.ease_in_cubic(1.0) == 1.0
  end

  test "ease_in_cubic(0.5) == 0.125" do
    assert Easing.ease_in_cubic(0.5) == 0.125
  end

  # --- ease_out_cubic ---

  test "ease_out_cubic(0) == 0" do
    assert Easing.ease_out_cubic(0.0) == 0.0
  end

  test "ease_out_cubic(1) == 1" do
    assert Easing.ease_out_cubic(1.0) == 1.0
  end

  test "ease_out_cubic(0.5) == 0.875" do
    assert Easing.ease_out_cubic(0.5) == 0.875
  end

  # --- bounce_out ---

  test "bounce_out(0) == 0" do
    assert Easing.bounce_out(0.0) == 0.0
  end

  test "bounce_out(1) == 1" do
    assert Easing.bounce_out(1.0) == 1.0
  end

  test "bounce_out at midpoint is near 0.765" do
    result = Easing.bounce_out(0.5)
    assert_in_delta result, 0.765625, 0.001
  end

  # --- elastic_out ---

  test "elastic_out(0) == 0" do
    assert Easing.elastic_out(0.0) == 0.0
  end

  test "elastic_out(1) == 1" do
    assert Easing.elastic_out(1.0) == 1.0
  end

  test "elastic_out can overshoot past 1.0" do
    # Elastic functions typically overshoot around t=0.3-0.4
    values = for t <- [0.3, 0.35, 0.4, 0.45], do: Easing.elastic_out(t)
    assert Enum.any?(values, &(&1 > 1.0))
  end

  # --- clamping ---

  test "input below 0 is clamped" do
    assert Easing.linear(-0.5) == 0.0
    assert Easing.ease_in(-1.0) == 0.0
  end

  test "input above 1 is clamped" do
    assert Easing.linear(1.5) == 1.0
    assert Easing.ease_out(2.0) == 1.0
  end

  # --- apply/2 dispatch ---

  test "apply dispatches to named function" do
    assert Easing.apply(:ease_in, 0.5) == 0.25
  end

  test "apply accepts custom function" do
    cube = fn t -> t * t * t end
    assert Easing.apply(cube, 0.5) == 0.125
  end

  test "apply clamps before calling custom function" do
    identity = fn t -> t end
    assert Easing.apply(identity, -1.0) == 0.0
    assert Easing.apply(identity, 2.0) == 1.0
  end

  # --- monotonicity for non-bouncing easings ---

  test "ease_out is monotonically increasing" do
    values = for i <- 0..10, do: Easing.ease_out(i / 10)
    pairs = Enum.zip(values, tl(values))
    assert Enum.all?(pairs, fn {a, b} -> b >= a end)
  end

  test "ease_in is monotonically increasing" do
    values = for i <- 0..10, do: Easing.ease_in(i / 10)
    pairs = Enum.zip(values, tl(values))
    assert Enum.all?(pairs, fn {a, b} -> b >= a end)
  end
end
