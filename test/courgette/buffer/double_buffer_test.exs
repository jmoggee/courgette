defmodule Courgette.Buffer.DoubleBufferTest do
  use ExUnit.Case, async: true

  alias Courgette.Buffer
  alias Courgette.Buffer.Diff.Run
  alias Courgette.Buffer.DoubleBuffer

  describe "new/2" do
    test "creates two empty buffers of the given size" do
      db = DoubleBuffer.new(10, 5)

      assert db.width == 10
      assert db.height == 5
      assert Buffer.size(db.front) == {10, 5}
      assert Buffer.size(db.back) == {10, 5}
    end

    test "both buffers start identical (all empty cells)" do
      db = DoubleBuffer.new(3, 2)

      assert db.front == db.back
    end
  end

  describe "back/1 and front/1" do
    test "return the respective buffers" do
      db = DoubleBuffer.new(4, 3)

      assert DoubleBuffer.back(db) == db.back
      assert DoubleBuffer.front(db) == db.front
    end
  end

  describe "diff/1" do
    test "returns empty list when both buffers are identical" do
      db = DoubleBuffer.new(5, 3)

      assert DoubleBuffer.diff(db) == []
    end

    test "returns runs for cells that differ" do
      db = DoubleBuffer.new(5, 3)
      back = Buffer.put_string(db.back, 0, 0, "Hi")
      db = %{db | back: back}

      runs = DoubleBuffer.diff(db)

      assert [%Run{x: 0, y: 0, cells: [_, _]}] = runs
    end
  end

  describe "swap/1" do
    test "promotes back to front" do
      db = DoubleBuffer.new(5, 3)
      back = Buffer.put_string(db.back, 0, 0, "Hey")
      db = %{db | back: back}

      swapped = DoubleBuffer.swap(db)

      assert swapped.front == back
    end

    test "clears back after swap" do
      db = DoubleBuffer.new(5, 3)
      back = Buffer.put_string(db.back, 0, 0, "Hey")
      db = %{db | back: back}

      swapped = DoubleBuffer.swap(db)
      empty = Buffer.new(5, 3)

      assert swapped.back == empty
    end

    test "preserves width and height" do
      db = DoubleBuffer.new(8, 4)
      swapped = DoubleBuffer.swap(db)

      assert swapped.width == 8
      assert swapped.height == 4
    end
  end

  describe "swap_and_diff/1" do
    test "returns diff runs and swapped state" do
      db = DoubleBuffer.new(5, 3)
      back = Buffer.put_string(db.back, 1, 1, "AB")
      db = %{db | back: back}

      {runs, new_db} = DoubleBuffer.swap_and_diff(db)

      # Should have detected the changes
      assert [%Run{x: 1, y: 1, cells: cells}] = runs
      assert length(cells) == 2

      # Front should now be what back was
      assert new_db.front == back

      # Back should be cleared
      assert new_db.back == Buffer.new(5, 3)
    end

    test "returns empty runs when buffers match" do
      db = DoubleBuffer.new(3, 3)

      {runs, _new_db} = DoubleBuffer.swap_and_diff(db)

      assert runs == []
    end

    test "sequential frames work correctly" do
      db = DoubleBuffer.new(5, 1)

      # Frame 1: draw "A" at 0,0
      db = %{db | back: Buffer.put_string(db.back, 0, 0, "A")}
      {runs1, db} = DoubleBuffer.swap_and_diff(db)
      assert [%Run{x: 0, y: 0}] = runs1

      # Frame 2: draw "A" at 0,0 again — same content, no diff
      db = %{db | back: Buffer.put_string(db.back, 0, 0, "A")}
      {runs2, db} = DoubleBuffer.swap_and_diff(db)
      assert runs2 == []

      # Frame 3: draw "B" at 0,0 — different content, has diff
      db = %{db | back: Buffer.put_string(db.back, 0, 0, "B")}
      {runs3, _db} = DoubleBuffer.swap_and_diff(db)
      assert [%Run{x: 0, y: 0}] = runs3
    end
  end

  describe "resize/2" do
    test "returns fresh double buffer at new dimensions" do
      db = DoubleBuffer.new(10, 5)
      db = %{db | back: Buffer.put_string(db.back, 0, 0, "old")}

      resized = DoubleBuffer.resize(db, 20, 10)

      assert resized.width == 20
      assert resized.height == 10
      assert Buffer.size(resized.front) == {20, 10}
      assert Buffer.size(resized.back) == {20, 10}
      # Both should be empty
      assert resized.front == resized.back
    end
  end
end
