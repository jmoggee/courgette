defmodule Courgette.ANSITest do
  use ExUnit.Case, async: true

  alias Courgette.ANSI

  # Helper: flatten iodata to a string for assertion
  defp to_str(iodata), do: IO.iodata_to_binary(iodata)

  # -- Foreground colors --

  describe "fg/1 named colors" do
    test "basic colors" do
      assert to_str(ANSI.fg(:red)) == "\e[31m"
      assert to_str(ANSI.fg(:green)) == "\e[32m"
      assert to_str(ANSI.fg(:blue)) == "\e[34m"
      assert to_str(ANSI.fg(:black)) == "\e[30m"
      assert to_str(ANSI.fg(:white)) == "\e[37m"
      assert to_str(ANSI.fg(:default)) == "\e[39m"
    end

    test "bright colors" do
      assert to_str(ANSI.fg(:bright_red)) == "\e[91m"
      assert to_str(ANSI.fg(:bright_green)) == "\e[92m"
      assert to_str(ANSI.fg(:bright_white)) == "\e[97m"
    end

    test "aliases" do
      assert to_str(ANSI.fg(:dark_gray)) == "\e[90m"
      assert to_str(ANSI.fg(:light_gray)) == "\e[37m"
    end

    test "unknown color raises" do
      assert_raise KeyError, fn -> ANSI.fg(:purple) end
    end
  end

  describe "fg/1 256-color" do
    test "valid indices" do
      assert to_str(ANSI.fg(0)) == "\e[38;5;0m"
      assert to_str(ANSI.fg(196)) == "\e[38;5;196m"
      assert to_str(ANSI.fg(255)) == "\e[38;5;255m"
    end

    test "out of range raises" do
      assert_raise FunctionClauseError, fn -> ANSI.fg(256) end
      assert_raise FunctionClauseError, fn -> ANSI.fg(-1) end
    end
  end

  describe "fg/1 truecolor" do
    test "rgb tuple" do
      assert to_str(ANSI.fg({255, 128, 0})) == "\e[38;2;255;128;0m"
      assert to_str(ANSI.fg({0, 0, 0})) == "\e[38;2;0;0;0m"
    end
  end

  # -- Background colors --

  describe "bg/1 named colors" do
    test "basic colors" do
      assert to_str(ANSI.bg(:red)) == "\e[41m"
      assert to_str(ANSI.bg(:blue)) == "\e[44m"
      assert to_str(ANSI.bg(:default)) == "\e[49m"
    end

    test "bright colors" do
      assert to_str(ANSI.bg(:bright_black)) == "\e[100m"
    end
  end

  describe "bg/1 256-color" do
    test "valid index" do
      assert to_str(ANSI.bg(42)) == "\e[48;5;42m"
    end
  end

  describe "bg/1 truecolor" do
    test "rgb tuple" do
      assert to_str(ANSI.bg({10, 20, 30})) == "\e[48;2;10;20;30m"
    end
  end

  # -- Styles --

  describe "styles" do
    test "enable" do
      assert ANSI.bold() == "\e[1m"
      assert ANSI.dim() == "\e[2m"
      assert ANSI.italic() == "\e[3m"
      assert ANSI.underline() == "\e[4m"
      assert ANSI.blink() == "\e[5m"
      assert ANSI.reverse() == "\e[7m"
      assert ANSI.hidden() == "\e[8m"
      assert ANSI.strikethrough() == "\e[9m"
    end

    test "disable" do
      assert ANSI.no_bold() == "\e[22m"
      assert ANSI.no_italic() == "\e[23m"
      assert ANSI.no_underline() == "\e[24m"
      assert ANSI.no_blink() == "\e[25m"
      assert ANSI.no_reverse() == "\e[27m"
      assert ANSI.no_hidden() == "\e[28m"
      assert ANSI.no_strikethrough() == "\e[29m"
    end

    test "overline" do
      assert ANSI.overline() == "\e[53m"
      assert ANSI.no_overline() == "\e[55m"
    end

    test "reset" do
      assert ANSI.reset() == "\e[0m"
    end
  end

  # -- Cursor --

  describe "cursor movement" do
    test "directional defaults to 1" do
      assert to_str(ANSI.cursor_up()) == "\e[1A"
      assert to_str(ANSI.cursor_down()) == "\e[1B"
      assert to_str(ANSI.cursor_right()) == "\e[1C"
      assert to_str(ANSI.cursor_left()) == "\e[1D"
    end

    test "directional with count" do
      assert to_str(ANSI.cursor_up(5)) == "\e[5A"
      assert to_str(ANSI.cursor_down(10)) == "\e[10B"
      assert to_str(ANSI.cursor_right(3)) == "\e[3C"
      assert to_str(ANSI.cursor_left(8)) == "\e[8D"
    end

    test "next/prev line defaults to 1" do
      assert to_str(ANSI.cursor_next_line()) == "\e[1E"
      assert to_str(ANSI.cursor_prev_line()) == "\e[1F"
    end

    test "next/prev line with count" do
      assert to_str(ANSI.cursor_next_line(5)) == "\e[5E"
      assert to_str(ANSI.cursor_prev_line(3)) == "\e[3F"
    end

    test "absolute positioning" do
      assert to_str(ANSI.cursor_to(1, 1)) == "\e[1;1H"
      assert to_str(ANSI.cursor_to(24, 80)) == "\e[24;80H"
    end

    test "column positioning" do
      assert to_str(ANSI.cursor_column(1)) == "\e[1G"
      assert to_str(ANSI.cursor_column(42)) == "\e[42G"
    end

    test "row positioning" do
      assert to_str(ANSI.cursor_row(1)) == "\e[1d"
      assert to_str(ANSI.cursor_row(24)) == "\e[24d"
    end

    test "home" do
      assert ANSI.cursor_home() == "\e[H"
    end

    test "save and restore" do
      assert ANSI.cursor_save() == "\e[s"
      assert ANSI.cursor_restore() == "\e[u"
    end

    test "hide and show" do
      assert ANSI.cursor_hide() == "\e[?25l"
      assert ANSI.cursor_show() == "\e[?25h"
    end
  end

  # -- Screen --

  describe "screen control" do
    test "clear screen variants" do
      assert ANSI.clear_screen() == "\e[2J"
      assert ANSI.clear_below() == "\e[0J"
      assert ANSI.clear_above() == "\e[1J"
    end

    test "clear line variants" do
      assert ANSI.clear_line() == "\e[2K"
      assert ANSI.clear_line_right() == "\e[0K"
      assert ANSI.clear_line_left() == "\e[1K"
    end

    test "alternate screen buffer" do
      assert ANSI.alternate_screen_enter() == "\e[?1049h"
      assert ANSI.alternate_screen_exit() == "\e[?1049l"
    end

    test "line wrap" do
      assert ANSI.line_wrap_disable() == "\e[?7l"
      assert ANSI.line_wrap_enable() == "\e[?7h"
    end

    test "full reset" do
      assert ANSI.full_reset() == "\ec"
    end
  end

  # -- Focus Events --

  describe "focus events" do
    test "enable and disable" do
      assert ANSI.focus_events_enable() == "\e[?1004h"
      assert ANSI.focus_events_disable() == "\e[?1004l"
    end
  end

  # -- Synchronized Output --

  describe "synchronized output" do
    test "begin and end" do
      assert ANSI.sync_begin() == "\e[?2026h"
      assert ANSI.sync_end() == "\e[?2026l"
    end
  end

  # -- Scroll Region --

  describe "scroll region" do
    test "set region" do
      assert to_str(ANSI.scroll_region(5, 20)) == "\e[5;20r"
    end

    test "reset region" do
      assert ANSI.scroll_region_reset() == "\e[r"
    end

    test "scroll up and down" do
      assert to_str(ANSI.scroll_up()) == "\e[1S"
      assert to_str(ANSI.scroll_up(3)) == "\e[3S"
      assert to_str(ANSI.scroll_down()) == "\e[1T"
      assert to_str(ANSI.scroll_down(5)) == "\e[5T"
    end
  end

  # -- Cursor Position Report --

  describe "cursor position report" do
    test "request" do
      assert ANSI.cursor_position_request() == "\e[6n"
    end
  end

  # -- Bracketed Paste --

  describe "bracketed paste" do
    test "enable and disable" do
      assert ANSI.bracketed_paste_enable() == "\e[?2004h"
      assert ANSI.bracketed_paste_disable() == "\e[?2004l"
    end
  end

  # -- Mouse --

  describe "mouse" do
    test "basic tracking" do
      assert ANSI.mouse_enable() == "\e[?1000h"
      assert ANSI.mouse_disable() == "\e[?1000l"
    end

    test "SGR mode" do
      assert ANSI.mouse_sgr_enable() == "\e[?1006h"
      assert ANSI.mouse_sgr_disable() == "\e[?1006l"
    end
  end

  # -- Hyperlinks --

  describe "hyperlinks" do
    test "wraps text in OSC 8" do
      result = to_str(ANSI.hyperlink("https://example.com", "click here"))
      assert result == "\e]8;;https://example.com\e\\click here\e]8;;\e\\"
    end
  end

  # -- Cursor Style --

  describe "cursor style" do
    test "valid styles" do
      assert to_str(ANSI.cursor_style(0)) == "\e[0 q"
      assert to_str(ANSI.cursor_style(1)) == "\e[1 q"
      assert to_str(ANSI.cursor_style(6)) == "\e[6 q"
    end

    test "out of range raises" do
      assert_raise FunctionClauseError, fn -> ANSI.cursor_style(7) end
    end
  end

  # -- Styled Underlines --

  describe "styled underlines" do
    test "all styles" do
      assert ANSI.underline_style(:none) == "\e[4:0m"
      assert ANSI.underline_style(:straight) == "\e[4:1m"
      assert ANSI.underline_style(:double) == "\e[4:2m"
      assert ANSI.underline_style(:curly) == "\e[4:3m"
      assert ANSI.underline_style(:dotted) == "\e[4:4m"
      assert ANSI.underline_style(:dashed) == "\e[4:5m"
    end
  end

  # -- Underline Color --

  describe "underline color" do
    test "256-color" do
      assert to_str(ANSI.underline_color(196)) == "\e[58;5;196m"
    end

    test "truecolor" do
      assert to_str(ANSI.underline_color({255, 0, 0})) == "\e[58;2;255;0;0m"
    end

    test "reset" do
      assert ANSI.underline_color_reset() == "\e[59m"
    end
  end

  # -- Kitty Keyboard Protocol --

  describe "kitty keyboard" do
    test "push with flags" do
      assert to_str(ANSI.kitty_keyboard_push(1)) == "\e[>1u"
      assert to_str(ANSI.kitty_keyboard_push(3)) == "\e[>3u"
      assert to_str(ANSI.kitty_keyboard_push(31)) == "\e[>31u"
    end

    test "pop" do
      assert to_str(ANSI.kitty_keyboard_pop()) == "\e[<1u"
      assert to_str(ANSI.kitty_keyboard_pop(2)) == "\e[<2u"
    end

    test "query" do
      assert ANSI.kitty_keyboard_query() == "\e[?u"
    end
  end

  # -- Grapheme Cluster Mode --

  describe "grapheme cluster mode" do
    test "enable and disable" do
      assert ANSI.grapheme_cluster_enable() == "\e[?2027h"
      assert ANSI.grapheme_cluster_disable() == "\e[?2027l"
    end
  end

  # -- Clipboard --

  describe "clipboard" do
    test "write encodes as base64" do
      result = to_str(ANSI.clipboard_write("hello"))
      assert result == "\e]52;c;#{Base.encode64("hello")}\e\\"
    end

    test "read request" do
      assert ANSI.clipboard_read() == "\e]52;c;?\e\\"
    end
  end

  # -- Window Title --

  describe "window title" do
    test "sets title" do
      assert to_str(ANSI.window_title("My App")) == "\e]0;My App\a"
    end
  end

  # -- Iodata composability --

  describe "composability" do
    test "sequences compose as iodata" do
      styled = [ANSI.fg(:red), ANSI.bold(), "hello", ANSI.reset()]
      result = IO.iodata_to_binary(styled)
      assert result == "\e[31m\e[1mhello\e[0m"
    end
  end
end
