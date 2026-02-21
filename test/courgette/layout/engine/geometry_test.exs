defmodule Courgette.Layout.Engine.GeometryTest do
  use ExUnit.Case, async: true

  alias Courgette.Layout.Engine.Geometry

  # ── Size ──────────────────────────────────────────────────────────

  describe "size/2" do
    test "creates a size with width and height" do
      s = Geometry.size(10.0, 20.0)
      assert s.width == 10.0
      assert s.height == 20.0
    end
  end

  describe "size_none/0" do
    test "creates a size with nil dimensions" do
      s = Geometry.size_none()
      assert s.width == nil
      assert s.height == nil
    end
  end

  # ── Rect ──────────────────────────────────────────────────────────

  describe "rect/4" do
    test "creates a rect with four sides" do
      r = Geometry.rect(1.0, 2.0, 3.0, 4.0)
      assert r.left == 1.0
      assert r.top == 2.0
      assert r.right == 3.0
      assert r.bottom == 4.0
    end
  end

  describe "rect_zero/0" do
    test "creates a zero rect" do
      r = Geometry.rect_zero()
      assert r.left == 0.0
      assert r.top == 0.0
      assert r.right == 0.0
      assert r.bottom == 0.0
    end
  end

  describe "rect_horizontal/1" do
    test "sums left and right" do
      r = Geometry.rect(3.0, 0.0, 7.0, 0.0)
      assert Geometry.rect_horizontal(r) == 10.0
    end
  end

  describe "rect_vertical/1" do
    test "sums top and bottom" do
      r = Geometry.rect(0.0, 4.0, 0.0, 6.0)
      assert Geometry.rect_vertical(r) == 10.0
    end
  end

  # ── AvailableSpace ────────────────────────────────────────────────

  describe "definite_or/2" do
    test "returns definite value" do
      assert Geometry.definite_or({:definite, 42.0}, 0.0) == 42.0
    end

    test "returns fallback for min_content" do
      assert Geometry.definite_or(:min_content, 99.0) == 99.0
    end

    test "returns fallback for max_content" do
      assert Geometry.definite_or(:max_content, 99.0) == 99.0
    end
  end

  describe "definite?/1" do
    test "true for definite" do
      assert Geometry.definite?({:definite, 1.0}) == true
    end

    test "false for min_content" do
      assert Geometry.definite?(:min_content) == false
    end

    test "false for max_content" do
      assert Geometry.definite?(:max_content) == false
    end
  end

  describe "map_definite/2" do
    test "maps over definite value" do
      assert Geometry.map_definite({:definite, 10.0}, &(&1 * 2)) == {:definite, 20.0}
    end

    test "passes through min_content" do
      assert Geometry.map_definite(:min_content, &(&1 * 2)) == :min_content
    end
  end

  describe "to_available/1" do
    test "nil becomes max_content" do
      assert Geometry.to_available(nil) == :max_content
    end

    test "number becomes definite" do
      assert Geometry.to_available(50.0) == {:definite, 50.0}
    end

    test "integer becomes definite float" do
      assert Geometry.to_available(50) == {:definite, 50.0}
    end
  end

  # ── Axis helpers ──────────────────────────────────────────────────

  describe "main/2 and cross/2" do
    test "row: main=width, cross=height" do
      s = Geometry.size(10.0, 20.0)
      assert Geometry.main(:row, s) == 10.0
      assert Geometry.cross(:row, s) == 20.0
    end

    test "column: main=height, cross=width" do
      s = Geometry.size(10.0, 20.0)
      assert Geometry.main(:column, s) == 20.0
      assert Geometry.cross(:column, s) == 10.0
    end

    test "works with nil values" do
      s = %{width: nil, height: 5.0}
      assert Geometry.main(:row, s) == nil
      assert Geometry.cross(:row, s) == 5.0
    end
  end

  describe "set_main/3 and set_cross/3" do
    test "row: set_main sets width, set_cross sets height" do
      s = Geometry.size(0.0, 0.0)
      assert Geometry.set_main(:row, s, 10.0) == %{width: 10.0, height: 0.0}
      assert Geometry.set_cross(:row, s, 20.0) == %{width: 0.0, height: 20.0}
    end

    test "column: set_main sets height, set_cross sets width" do
      s = Geometry.size(0.0, 0.0)
      assert Geometry.set_main(:column, s, 10.0) == %{width: 0.0, height: 10.0}
      assert Geometry.set_cross(:column, s, 20.0) == %{width: 20.0, height: 0.0}
    end
  end

  describe "from_main_cross/3" do
    test "row: main→width, cross→height" do
      assert Geometry.from_main_cross(:row, 10.0, 20.0) == %{width: 10.0, height: 20.0}
    end

    test "column: main→height, cross→width" do
      assert Geometry.from_main_cross(:column, 10.0, 20.0) == %{width: 20.0, height: 10.0}
    end
  end

  describe "main_inset/2 and cross_inset/2" do
    test "row: main_inset=horizontal, cross_inset=vertical" do
      r = Geometry.rect(3.0, 5.0, 7.0, 9.0)
      assert Geometry.main_inset(:row, r) == 10.0
      assert Geometry.cross_inset(:row, r) == 14.0
    end

    test "column: main_inset=vertical, cross_inset=horizontal" do
      r = Geometry.rect(3.0, 5.0, 7.0, 9.0)
      assert Geometry.main_inset(:column, r) == 14.0
      assert Geometry.cross_inset(:column, r) == 10.0
    end
  end

  describe "main_start/2 and cross_start/2" do
    test "row: main_start=left, cross_start=top" do
      r = Geometry.rect(3.0, 5.0, 7.0, 9.0)
      assert Geometry.main_start(:row, r) == 3.0
      assert Geometry.cross_start(:row, r) == 5.0
    end

    test "column: main_start=top, cross_start=left" do
      r = Geometry.rect(3.0, 5.0, 7.0, 9.0)
      assert Geometry.main_start(:column, r) == 5.0
      assert Geometry.cross_start(:column, r) == 3.0
    end
  end

  # ── maybe_* arithmetic ───────────────────────────────────────────

  describe "maybe_add/2" do
    test "adds two values" do
      assert Geometry.maybe_add(3.0, 4.0) == 7.0
    end

    test "nil + value = nil" do
      assert Geometry.maybe_add(nil, 4.0) == nil
    end

    test "value + nil = nil" do
      assert Geometry.maybe_add(3.0, nil) == nil
    end

    test "nil + nil = nil" do
      assert Geometry.maybe_add(nil, nil) == nil
    end
  end

  describe "maybe_sub/2" do
    test "subtracts two values" do
      assert Geometry.maybe_sub(10.0, 3.0) == 7.0
    end

    test "nil - value = nil" do
      assert Geometry.maybe_sub(nil, 3.0) == nil
    end

    test "value - nil = nil" do
      assert Geometry.maybe_sub(10.0, nil) == nil
    end
  end

  describe "maybe_min/2" do
    test "returns minimum of two values" do
      assert Geometry.maybe_min(3.0, 5.0) == 3.0
    end

    test "nil, b returns b" do
      assert Geometry.maybe_min(nil, 5.0) == 5.0
    end

    test "a, nil returns a" do
      assert Geometry.maybe_min(3.0, nil) == 3.0
    end

    test "nil, nil returns nil" do
      assert Geometry.maybe_min(nil, nil) == nil
    end
  end

  describe "maybe_max/2" do
    test "returns maximum of two values" do
      assert Geometry.maybe_max(3.0, 5.0) == 5.0
    end

    test "nil, b returns b" do
      assert Geometry.maybe_max(nil, 5.0) == 5.0
    end

    test "a, nil returns a" do
      assert Geometry.maybe_max(3.0, nil) == 3.0
    end
  end

  describe "maybe_clamp/3" do
    test "clamps between min and max" do
      assert Geometry.maybe_clamp(5.0, 2.0, 8.0) == 5.0
      assert Geometry.maybe_clamp(1.0, 2.0, 8.0) == 2.0
      assert Geometry.maybe_clamp(10.0, 2.0, 8.0) == 8.0
    end

    test "nil min — only max applies" do
      assert Geometry.maybe_clamp(10.0, nil, 8.0) == 8.0
      assert Geometry.maybe_clamp(5.0, nil, 8.0) == 5.0
    end

    test "nil max — only min applies" do
      assert Geometry.maybe_clamp(1.0, 3.0, nil) == 3.0
      assert Geometry.maybe_clamp(5.0, 3.0, nil) == 5.0
    end

    test "both nil — returns value unchanged" do
      assert Geometry.maybe_clamp(5.0, nil, nil) == 5.0
    end
  end

  describe "maybe_add_definite/2" do
    test "adds definite to value" do
      assert Geometry.maybe_add_definite(3.0, 4.0) == 7.0
    end

    test "nil base returns nil" do
      assert Geometry.maybe_add_definite(nil, 4.0) == nil
    end
  end

  describe "maybe_sub_definite/2" do
    test "subtracts definite from value" do
      assert Geometry.maybe_sub_definite(10.0, 3.0) == 7.0
    end

    test "nil base returns nil" do
      assert Geometry.maybe_sub_definite(nil, 3.0) == nil
    end
  end

  describe "or_else/2" do
    test "returns value when not nil" do
      assert Geometry.or_else(5.0, 0.0) == 5.0
    end

    test "returns default when nil" do
      assert Geometry.or_else(nil, 0.0) == 0.0
    end
  end
end
