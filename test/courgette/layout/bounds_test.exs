defmodule Courgette.Layout.BoundsTest do
  use ExUnit.Case, async: true

  alias Courgette.Layout.Bounds

  # ── Construction ──────────────────────────────────────────────────

  describe "struct defaults" do
    test "all fields default to 0" do
      b = %Bounds{}
      assert b.x == 0
      assert b.y == 0
      assert b.width == 0
      assert b.height == 0
    end
  end

  describe "new/4" do
    test "creates bounds with given values" do
      b = Bounds.new(5, 3, 40, 12)
      assert b.x == 5
      assert b.y == 3
      assert b.width == 40
      assert b.height == 12
    end

    test "zero-size bounds" do
      b = Bounds.new(0, 0, 0, 0)
      assert b.width == 0
      assert b.height == 0
    end

    test "origin bounds" do
      b = Bounds.new(0, 0, 80, 24)
      assert b.x == 0
      assert b.y == 0
    end

    test "rejects negative values" do
      assert_raise FunctionClauseError, fn -> Bounds.new(-1, 0, 10, 10) end
      assert_raise FunctionClauseError, fn -> Bounds.new(0, -1, 10, 10) end
      assert_raise FunctionClauseError, fn -> Bounds.new(0, 0, -1, 10) end
      assert_raise FunctionClauseError, fn -> Bounds.new(0, 0, 10, -1) end
    end
  end

  # ── contains?/3 ──────────────────────────────────────────────────

  describe "contains?/3" do
    setup do
      %{bounds: Bounds.new(5, 3, 10, 8)}
    end

    test "top-left corner is inside", %{bounds: b} do
      assert Bounds.contains?(b, 5, 3)
    end

    test "top-right edge is outside (exclusive)", %{bounds: b} do
      refute Bounds.contains?(b, 15, 3)
    end

    test "bottom-left edge is outside (exclusive)", %{bounds: b} do
      refute Bounds.contains?(b, 5, 11)
    end

    test "bottom-right is outside", %{bounds: b} do
      refute Bounds.contains?(b, 15, 11)
    end

    test "interior point is inside", %{bounds: b} do
      assert Bounds.contains?(b, 10, 7)
    end

    test "last valid column", %{bounds: b} do
      assert Bounds.contains?(b, 14, 3)
    end

    test "last valid row", %{bounds: b} do
      assert Bounds.contains?(b, 5, 10)
    end

    test "point left of bounds", %{bounds: b} do
      refute Bounds.contains?(b, 4, 5)
    end

    test "point above bounds", %{bounds: b} do
      refute Bounds.contains?(b, 7, 2)
    end

    test "zero-size bounds contains nothing" do
      b = Bounds.new(5, 5, 0, 0)
      refute Bounds.contains?(b, 5, 5)
    end
  end

  # ── intersect/2 ──────────────────────────────────────────────────

  describe "intersect/2" do
    test "overlapping bounds" do
      a = Bounds.new(0, 0, 20, 10)
      b = Bounds.new(5, 3, 30, 20)
      result = Bounds.intersect(a, b)

      assert result == %Bounds{x: 5, y: 3, width: 15, height: 7}
    end

    test "identical bounds" do
      a = Bounds.new(5, 5, 10, 10)
      assert Bounds.intersect(a, a) == a
    end

    test "one inside the other" do
      outer = Bounds.new(0, 0, 100, 100)
      inner = Bounds.new(10, 10, 20, 20)
      assert Bounds.intersect(outer, inner) == inner
      assert Bounds.intersect(inner, outer) == inner
    end

    test "no overlap returns nil" do
      a = Bounds.new(0, 0, 10, 10)
      b = Bounds.new(20, 20, 10, 10)
      assert Bounds.intersect(a, b) == nil
    end

    test "adjacent bounds (touching edges) returns nil" do
      a = Bounds.new(0, 0, 10, 10)
      b = Bounds.new(10, 0, 10, 10)
      assert Bounds.intersect(a, b) == nil
    end

    test "partial overlap on one axis" do
      a = Bounds.new(0, 0, 10, 10)
      b = Bounds.new(5, 0, 10, 10)
      result = Bounds.intersect(a, b)

      assert result == %Bounds{x: 5, y: 0, width: 5, height: 10}
    end

    test "zero-size bounds returns nil" do
      a = Bounds.new(5, 5, 0, 0)
      b = Bounds.new(0, 0, 10, 10)
      assert Bounds.intersect(a, b) == nil
    end

    test "commutative" do
      a = Bounds.new(0, 0, 15, 15)
      b = Bounds.new(10, 5, 20, 20)
      assert Bounds.intersect(a, b) == Bounds.intersect(b, a)
    end
  end
end
