defmodule Courgette.ANSI.ColorModeTest do
  use ExUnit.Case, async: true

  alias Courgette.ANSI.ColorMode

  # -- Detection --

  describe "detect_from_env/0" do
    test "COLORTERM=truecolor → :bit_24" do
      System.put_env("COLORTERM", "truecolor")
      assert ColorMode.detect_from_env() == :bit_24
    after
      System.delete_env("COLORTERM")
    end

    test "COLORTERM=24bit → :bit_24" do
      System.put_env("COLORTERM", "24bit")
      assert ColorMode.detect_from_env() == :bit_24
    after
      System.delete_env("COLORTERM")
    end

    test "COLORTERM is case-insensitive" do
      System.put_env("COLORTERM", "TrueColor")
      assert ColorMode.detect_from_env() == :bit_24
    after
      System.delete_env("COLORTERM")
    end

    test "TERM=xterm-256color → :bit_8" do
      System.delete_env("COLORTERM")
      System.put_env("TERM", "xterm-256color")
      assert ColorMode.detect_from_env() == :bit_8
    after
      System.delete_env("TERM")
    end

    test "TERM=screen-256color → :bit_8" do
      System.delete_env("COLORTERM")
      System.put_env("TERM", "screen-256color")
      assert ColorMode.detect_from_env() == :bit_8
    after
      System.delete_env("TERM")
    end

    test "COLORTERM takes precedence over TERM" do
      System.put_env("COLORTERM", "truecolor")
      System.put_env("TERM", "xterm-256color")
      assert ColorMode.detect_from_env() == :bit_24
    after
      System.delete_env("COLORTERM")
      System.delete_env("TERM")
    end

    test "neither set → :basic" do
      System.delete_env("COLORTERM")
      System.delete_env("TERM")
      assert ColorMode.detect_from_env() == :basic
    end

    test "TERM=xterm without 256color → :basic" do
      System.delete_env("COLORTERM")
      System.put_env("TERM", "xterm")
      assert ColorMode.detect_from_env() == :basic
    after
      System.delete_env("TERM")
    end
  end

  describe "detect/0 with config override" do
    test "respects explicit config" do
      Application.put_env(:courgette, :color_mode, :bit_8)
      assert ColorMode.detect() == :bit_8
    after
      Application.delete_env(:courgette, :color_mode)
    end

    test ":auto falls through to env detection" do
      Application.put_env(:courgette, :color_mode, :auto)
      System.put_env("COLORTERM", "truecolor")
      assert ColorMode.detect() == :bit_24
    after
      Application.delete_env(:courgette, :color_mode)
      System.delete_env("COLORTERM")
    end
  end

  # -- Downgrading --

  describe "downgrade/2 in :bit_24 mode" do
    test "all values pass through" do
      assert ColorMode.downgrade(:red, :bit_24) == :red
      assert ColorMode.downgrade(196, :bit_24) == 196
      assert ColorMode.downgrade({255, 128, 0}, :bit_24) == {255, 128, 0}
    end
  end

  describe "downgrade/2 atoms" do
    test "atoms pass through in all modes" do
      assert ColorMode.downgrade(:red, :basic) == :red
      assert ColorMode.downgrade(:bright_cyan, :bit_8) == :bright_cyan
    end
  end

  describe "downgrade/2 in :bit_8 mode" do
    test "256-color index passes through" do
      assert ColorMode.downgrade(196, :bit_8) == 196
    end

    test "truecolor maps to 256-color index" do
      result = ColorMode.downgrade({255, 0, 0}, :bit_8)
      assert is_integer(result)
      assert result in 0..255
    end

    test "pure red maps to red region" do
      result = ColorMode.downgrade({255, 0, 0}, :bit_8)
      # Should map to 196 (bright red in the cube) or 9 (bright red basic)
      assert result in [9, 196]
    end

    test "pure white maps correctly" do
      result = ColorMode.downgrade({255, 255, 255}, :bit_8)
      # 231 is the brightest cube white, 15 is bright white basic
      assert result in [15, 231]
    end

    test "gray maps to grayscale ramp" do
      result = ColorMode.downgrade({128, 128, 128}, :bit_8)
      # Should land in the grayscale ramp (232-255) or a neutral cube entry
      assert is_integer(result) and result in 0..255
    end
  end

  describe "downgrade/2 in :basic mode" do
    test "truecolor red maps to basic red" do
      result = ColorMode.downgrade({255, 0, 0}, :basic)
      # Should be 9 (bright red) or 1 (red)
      assert result in [1, 9]
    end

    test "truecolor green maps to basic green" do
      result = ColorMode.downgrade({0, 255, 0}, :basic)
      assert result in [2, 10]
    end

    test "truecolor blue maps to basic blue" do
      result = ColorMode.downgrade({0, 0, 255}, :basic)
      assert result in [4, 12]
    end

    test "truecolor white maps to basic white" do
      result = ColorMode.downgrade({255, 255, 255}, :basic)
      assert result == 15
    end

    test "truecolor black maps to basic black" do
      result = ColorMode.downgrade({0, 0, 0}, :basic)
      assert result == 0
    end

    test "256-color index downgrades to basic" do
      result = ColorMode.downgrade(196, :basic)
      assert result in 0..15
    end

    test "basic indices (0-15) map to themselves via nearest match" do
      # Index 0 is black {0,0,0} — should map back to 0
      assert ColorMode.downgrade(0, :basic) == 0
      # Index 15 is bright white {255,255,255} — should map back to 15
      assert ColorMode.downgrade(15, :basic) == 15
    end
  end

  # -- RGB mapping helpers --

  describe "rgb_to_256/3" do
    test "pure black" do
      assert ColorMode.rgb_to_256(0, 0, 0) == 16
    end

    test "pure white" do
      # Cube white (231) = {255,255,255}, grayscale 255 would be index 255 = {238,238,238}
      assert ColorMode.rgb_to_256(255, 255, 255) == 231
    end

    test "midrange gray uses grayscale ramp" do
      # {128, 128, 128} is close to grayscale index 244 = level 128
      result = ColorMode.rgb_to_256(128, 128, 128)
      assert result in 232..255
    end

    test "saturated color uses cube" do
      result = ColorMode.rgb_to_256(0, 135, 0)
      # Should be in the cube range
      assert result in 16..231
    end
  end

  describe "rgb_to_basic/3" do
    test "exact matches" do
      assert ColorMode.rgb_to_basic(0, 0, 0) == 0
      assert ColorMode.rgb_to_basic(255, 255, 255) == 15
      assert ColorMode.rgb_to_basic(128, 0, 0) == 1
    end

    test "near matches map to closest" do
      # Slightly off-red should still map to red (1) or bright red (9)
      result = ColorMode.rgb_to_basic(140, 10, 10)
      assert result in [1, 9]
    end
  end
end
