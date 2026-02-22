defmodule CourgetteTest do
  use ExUnit.Case

  describe "animations_enabled?/0" do
    test "defaults to true" do
      Application.delete_env(:courgette, :animations_enabled)
      assert Courgette.animations_enabled?() == true
    end

    test "returns false when configured" do
      Application.put_env(:courgette, :animations_enabled, false)

      try do
        assert Courgette.animations_enabled?() == false
      after
        Application.delete_env(:courgette, :animations_enabled)
      end
    end
  end
end
