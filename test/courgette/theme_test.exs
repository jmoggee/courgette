defmodule Courgette.ThemeTest do
  use ExUnit.Case, async: true

  alias Courgette.Theme

  describe "default/0" do
    test "returns a Theme struct" do
      theme = Theme.default()
      assert %Theme{name: "default"} = theme
    end

    test "has all standard tokens" do
      theme = Theme.default()
      expected = [:bg, :fg, :primary, :secondary, :success, :warning, :danger, :muted, :border, :surface]

      for token <- expected do
        assert Map.has_key?(theme.tokens, token), "missing token: #{token}"
      end
    end

    test "tokens are color values" do
      theme = Theme.default()
      assert theme.tokens.primary == :blue
      assert theme.tokens.danger == :red
      assert theme.tokens.success == :green
      assert theme.tokens.fg == :white
      assert theme.tokens.bg == :black
    end
  end

  describe "get/2" do
    test "returns token value" do
      theme = Theme.default()
      assert Theme.get(theme, :primary) == :blue
    end

    test "raises for unknown token" do
      theme = Theme.default()

      assert_raise ArgumentError, ~r/unknown theme token: :nonexistent/, fn ->
        Theme.get(theme, :nonexistent)
      end
    end
  end

  describe "get/3" do
    test "returns token value when present" do
      theme = Theme.default()
      assert Theme.get(theme, :primary, :fallback) == :blue
    end

    test "returns default when token missing" do
      theme = Theme.default()
      assert Theme.get(theme, :nonexistent, :white) == :white
    end
  end

  describe "custom themes" do
    test "can create custom theme" do
      theme = %Theme{name: "ocean", tokens: %{primary: :cyan, bg: {0, 20, 40}}}
      assert Theme.get(theme, :primary) == :cyan
      assert Theme.get(theme, :bg) == {0, 20, 40}
    end

    test "custom theme with 256-color values" do
      theme = %Theme{name: "retro", tokens: %{primary: 33, secondary: 208}}
      assert Theme.get(theme, :primary) == 33
      assert Theme.get(theme, :secondary) == 208
    end
  end
end
