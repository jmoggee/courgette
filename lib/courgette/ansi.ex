defmodule Courgette.ANSI do
  @moduledoc """
  Pure functions for generating ANSI escape sequences.

  All functions return iodata — either compile-time constant strings
  or iolists for parameterized sequences. Colors, styles, cursor
  movement, and screen control.

  ## Sequence Reference

  ### Colors (SGR)

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[30-37m` | `fg/1` | Foreground — 8 basic named colors |
  | `ESC[90-97m` | `fg/1` | Foreground — 8 bright named colors |
  | `ESC[38;5;{n}m` | `fg/1` | Foreground — 256-color palette (0-255) |
  | `ESC[38;2;{r};{g};{b}m` | `fg/1` | Foreground — truecolor RGB |
  | `ESC[39m` | `fg(:default)` | Foreground — reset to default |
  | `ESC[40-47m` | `bg/1` | Background — 8 basic named colors |
  | `ESC[100-107m` | `bg/1` | Background — 8 bright named colors |
  | `ESC[48;5;{n}m` | `bg/1` | Background — 256-color palette (0-255) |
  | `ESC[48;2;{r};{g};{b}m` | `bg/1` | Background — truecolor RGB |
  | `ESC[49m` | `bg(:default)` | Background — reset to default |

  ### Styles (SGR)

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[0m` | `reset/0` | Reset all attributes |
  | `ESC[1m` | `bold/0` | Bold / increased intensity |
  | `ESC[2m` | `dim/0` | Dim / faint |
  | `ESC[3m` | `italic/0` | Italic |
  | `ESC[4m` | `underline/0` | Underline (straight) |
  | `ESC[4:0m` | `underline_style/1` | No underline |
  | `ESC[4:1m` | `underline_style/1` | Straight underline |
  | `ESC[4:2m` | `underline_style/1` | Double underline |
  | `ESC[4:3m` | `underline_style/1` | Curly/wavy underline (errors, diagnostics) |
  | `ESC[4:4m` | `underline_style/1` | Dotted underline |
  | `ESC[4:5m` | `underline_style/1` | Dashed underline |
  | `ESC[58;5;{n}m` | `underline_color/1` | Underline color — 256-color |
  | `ESC[58;2;{r};{g};{b}m` | `underline_color/1` | Underline color — truecolor RGB |
  | `ESC[59m` | `underline_color_reset/0` | Reset underline color to foreground |
  | `ESC[5m` | `blink/0` | Blink |
  | `ESC[7m` | `reverse/0` | Reverse video (swap fg/bg) |
  | `ESC[8m` | `hidden/0` | Hidden / conceal |
  | `ESC[9m` | `strikethrough/0` | Strikethrough |
  | `ESC[53m` | `overline/0` | Overline |
  | `ESC[22m` | `no_bold/0` | Reset bold and dim |
  | `ESC[23m` | `no_italic/0` | Reset italic |
  | `ESC[24m` | `no_underline/0` | Reset underline |
  | `ESC[25m` | `no_blink/0` | Reset blink |
  | `ESC[27m` | `no_reverse/0` | Reset reverse |
  | `ESC[28m` | `no_hidden/0` | Reset hidden |
  | `ESC[29m` | `no_strikethrough/0` | Reset strikethrough |
  | `ESC[55m` | `no_overline/0` | Reset overline |

  ### Cursor

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[{n}A` | `cursor_up/1` | Move up N rows |
  | `ESC[{n}B` | `cursor_down/1` | Move down N rows |
  | `ESC[{n}C` | `cursor_right/1` | Move right N columns |
  | `ESC[{n}D` | `cursor_left/1` | Move left N columns |
  | `ESC[{n}E` | `cursor_next_line/1` | Move down N lines, to column 1 |
  | `ESC[{n}F` | `cursor_prev_line/1` | Move up N lines, to column 1 |
  | `ESC[{r};{c}H` | `cursor_to/2` | Move to absolute row, col (1-based) |
  | `ESC[{n}G` | `cursor_column/1` | Move to column N on current row |
  | `ESC[{n}d` | `cursor_row/1` | Move to row N on current column (1-based) |
  | `ESC[H` | `cursor_home/0` | Move to row 1, col 1 |
  | `ESC[s` | `cursor_save/0` | Save cursor position (SCO) |
  | `ESC[u` | `cursor_restore/0` | Restore cursor position (SCO) |
  | `ESC[?25l` | `cursor_hide/0` | Hide cursor |
  | `ESC[?25h` | `cursor_show/0` | Show cursor |
  | `ESC[{n} q` | `cursor_style/1` | Set cursor shape (block/underline/bar) |
  | `ESC[6n` | `cursor_position_request/0` | Request cursor position (terminal replies `ESC[{r};{c}R`) |

  ### Screen

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[2J` | `clear_screen/0` | Clear entire screen |
  | `ESC[0J` | `clear_below/0` | Clear from cursor to end of screen |
  | `ESC[1J` | `clear_above/0` | Clear from cursor to start of screen |
  | `ESC[2K` | `clear_line/0` | Clear entire line |
  | `ESC[0K` | `clear_line_right/0` | Clear from cursor to end of line |
  | `ESC[1K` | `clear_line_left/0` | Clear from cursor to start of line |
  | `ESC[?1049h` | `alternate_screen_enter/0` | Enter alternate screen buffer |
  | `ESC[?1049l` | `alternate_screen_exit/0` | Exit alternate screen buffer |
  | `ESC[?7l` | `line_wrap_disable/0` | Disable auto line wrap |
  | `ESC[?7h` | `line_wrap_enable/0` | Enable auto line wrap |
  | `ESC c` | `full_reset/0` | Full terminal reset (RIS) — restores all defaults |

  ### Focus Events

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[?1004h` | `focus_events_enable/0` | Enable focus in/out reporting |
  | `ESC[?1004l` | `focus_events_disable/0` | Disable focus reporting |

  Terminal sends `ESC[I` on focus in and `ESC[O` on focus out. Useful for
  pausing rendering or dimming UI when terminal loses focus.

  ### Scroll

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[{t};{b}r` | `scroll_region/2` | Set scroll region (top row, bottom row) |
  | `ESC[r` | `scroll_region_reset/0` | Reset scroll region to full screen |
  | `ESC[{n}S` | `scroll_up/1` | Scroll content up N lines |
  | `ESC[{n}T` | `scroll_down/1` | Scroll content down N lines |

  ### Synchronized Output

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[?2026h` | `sync_begin/0` | Begin synchronized update — terminal buffers output |
  | `ESC[?2026l` | `sync_end/0` | End synchronized update — terminal renders frame |

  ### Bracketed Paste

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[?2004h` | `bracketed_paste_enable/0` | Enable — pasted text wrapped in `ESC[200~` / `ESC[201~` |
  | `ESC[?2004l` | `bracketed_paste_disable/0` | Disable bracketed paste mode |

  ### Mouse

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[?1000h` | `mouse_enable/0` | Enable basic mouse tracking (press events) |
  | `ESC[?1000l` | `mouse_disable/0` | Disable basic mouse tracking |
  | `ESC[?1006h` | `mouse_sgr_enable/0` | Enable SGR extended mouse mode (large terminals) |
  | `ESC[?1006l` | `mouse_sgr_disable/0` | Disable SGR mouse mode |

  ### Kitty Keyboard Protocol

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[>{flags}u` | `kitty_keyboard_push/1` | Push keyboard mode with flags onto stack |
  | `ESC[<{n}u` | `kitty_keyboard_pop/1` | Pop N entries from keyboard mode stack |
  | `ESC[?u` | `kitty_keyboard_query/0` | Query current keyboard mode flags |

  Flags (bitmask): 1 = disambiguate, 2 = report event types, 4 = report alternate keys,
  8 = report all keys as escapes, 16 = report associated text. Both kitty and ghostty.

  ### Grapheme Cluster Mode

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC[?2027h` | `grapheme_cluster_enable/0` | Enable Unicode grapheme cluster mode |
  | `ESC[?2027l` | `grapheme_cluster_disable/0` | Disable grapheme cluster mode |

  Tells the terminal the application understands grapheme clustering for correct
  emoji and multi-codepoint character width. Both kitty and ghostty.

  ### Clipboard (OSC 52)

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC]52;c;{base64}ST` | `clipboard_write/1` | Write to system clipboard |
  | `ESC]52;c;?ST` | `clipboard_read/0` | Request clipboard contents |

  Both kitty and ghostty.

  ### OSC (Operating System Commands)

  | Code | Function | Purpose |
  |------|----------|---------|
  | `ESC]8;;{url}ST text ESC]8;;ST` | `hyperlink/2` | Clickable hyperlink |
  | `ESC]0;{title}BEL` | `window_title/1` | Set terminal window/tab title |

  Both kitty and ghostty.

  ### Not Adopted

  | Code | Purpose | Status |
  |------|---------|--------|
  | `ESC[21m` | Double underline (SGR 21) | Legacy — use `underline_style(:double)` (`ESC[4:2m`) instead. |
  | `ESC[?1002h` | Button-event mouse tracking | Reports motion while button held. Add if drag support needed. |
  | `ESC[?1003h` | All-motion mouse tracking | Too noisy — events on every mouse move. |
  | `ESC[?1005h` | UTF-8 mouse encoding | Deprecated — use SGR mode (`?1006h`) instead. |
  | `ESC[?1015h` | RXVT mouse encoding (urxvt) | Deprecated — use SGR mode (`?1006h`) instead. |
  | `ESC[{n}L/M` | Insert/delete lines | Cell-by-cell painting; layout engine handles positioning. |
  | `ESC[{n}@/P` | Insert/delete characters | Text input handles its own cursor/editing. |
  | `ESC[{n}X` | Erase N characters | `clear_line_right/0` covers the common case. |
  | `ESC[{n}b` | Repeat preceding character | Niche optimization; not needed for cell-by-cell rendering. |
  | `ESC 7` / `ESC 8` | Save/restore cursor (DEC) | Using SCO (`ESC[s` / `ESC[u`) instead — more widely supported. |
  | `ESC[?47h/l` | Legacy alternate screen | Using `?1049h/l` which also saves/restores cursor. |
  | `ESC[?12h/l` | Cursor blink toggle | Covered by `cursor_style/1`. |
  | `BEL` (`\\a`) | Audible bell | Notification component handles alerts visually. |
  | Tab stop sequences | Set/clear tab stops (`ESC H`, `ESC[g`) | Layout engine handles all spacing. |
  | `ESC]4;{n};{spec}ST` | Set palette color (OSC 4) | Modifies terminal palette — add with theming if needed. |
  | `ESC]10;{spec}ST` | Set default fg (OSC 10) | Modifies terminal defaults — add with theming if needed. |
  | `ESC]11;{spec}ST` | Set default bg (OSC 11) | Modifies terminal defaults — add with theming if needed. |
  | `ESC_G...` | Kitty graphics protocol | Inline images. Kitty + ghostty (partial). Future — not core to TUI components. |
  | `ESC]99;...` | Desktop notifications (OSC 99) | Kitty only (ghostty planned 1.3). Application concern, not framework. |
  | `ESC]22;...` | Mouse pointer shapes (OSC 22) | Kitty only. UX polish — add when mouse support is wired. |
  | `ESC]66;...` | Text sizing (OSC 66) | Kitty only. Headings at different sizes — watch for broader adoption. |
  | `ESC[>29;...q` | Multiple cursors | Kitty only. Only relevant for multi-cursor editor components. |
  | `ESC[{n}T+` | Unscrolling (SD+) | Kitty only. Not applicable — Courgette uses alternate screen. |
  | `CSI Pt;Pl;Pb;Pr;Pm $r` | DECCARA region styling | Kitty only. Niche optimization for diff renderer. |
  | `ESC]30001/30101` | Color stack push/pop | Kitty. Theme management — add when theming is implemented. |
  | `ESC]21;...` | Color control (OSC 21) | Both. Granular palette control — add with theming. |
  """

  @csi "\e["

  # -- Colors --

  # Named foreground color codes (SGR)
  @named_fg %{
    black: "30",
    red: "31",
    green: "32",
    yellow: "33",
    blue: "34",
    magenta: "35",
    cyan: "36",
    white: "37",
    default: "39",
    bright_black: "90",
    bright_red: "91",
    bright_green: "92",
    bright_yellow: "93",
    bright_blue: "94",
    bright_magenta: "95",
    bright_cyan: "96",
    bright_white: "97",
    # Aliases
    dark_gray: "90",
    light_gray: "37"
  }

  # Named background color codes (SGR)
  @named_bg %{
    black: "40",
    red: "41",
    green: "42",
    yellow: "43",
    blue: "44",
    magenta: "45",
    cyan: "46",
    white: "47",
    default: "49",
    bright_black: "100",
    bright_red: "101",
    bright_green: "102",
    bright_yellow: "103",
    bright_blue: "104",
    bright_magenta: "105",
    bright_cyan: "106",
    bright_white: "107",
    dark_gray: "100",
    light_gray: "47"
  }

  @doc """
  Foreground color. Accepts a named color atom, a 256-color integer (0-255),
  or an `{r, g, b}` truecolor tuple.
  """
  def fg(color) when is_atom(color) do
    [@csi, Map.fetch!(@named_fg, color), "m"]
  end

  def fg(n) when is_integer(n) and n in 0..255 do
    [@csi, "38;5;", Integer.to_string(n), "m"]
  end

  def fg({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    [
      @csi,
      "38;2;",
      Integer.to_string(r),
      ";",
      Integer.to_string(g),
      ";",
      Integer.to_string(b),
      "m"
    ]
  end

  @doc """
  Background color. Same argument forms as `fg/1`.
  """
  def bg(color) when is_atom(color) do
    [@csi, Map.fetch!(@named_bg, color), "m"]
  end

  def bg(n) when is_integer(n) and n in 0..255 do
    [@csi, "48;5;", Integer.to_string(n), "m"]
  end

  def bg({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    [
      @csi,
      "48;2;",
      Integer.to_string(r),
      ";",
      Integer.to_string(g),
      ";",
      Integer.to_string(b),
      "m"
    ]
  end

  # -- Styles --

  @doc "Bold (SGR 1)."
  def bold, do: "\e[1m"

  @doc "Dim/faint (SGR 2)."
  def dim, do: "\e[2m"

  @doc "Italic (SGR 3)."
  def italic, do: "\e[3m"

  @doc "Underline — straight (SGR 4). See also `underline_style/1` for styled variants."
  def underline, do: "\e[4m"

  @doc """
  Styled underline (SGR 4:x sub-parameter). Kitty + ghostty.

  Styles: `:none`, `:straight`, `:double`, `:curly`, `:dotted`, `:dashed`.
  """
  def underline_style(:none), do: "\e[4:0m"
  def underline_style(:straight), do: "\e[4:1m"
  def underline_style(:double), do: "\e[4:2m"
  def underline_style(:curly), do: "\e[4:3m"
  def underline_style(:dotted), do: "\e[4:4m"
  def underline_style(:dashed), do: "\e[4:5m"

  @doc """
  Underline color, independent of foreground. Kitty + ghostty.
  Same argument forms as `fg/1`: 256-color integer or `{r, g, b}` tuple.
  """
  def underline_color(n) when is_integer(n) and n in 0..255 do
    [@csi, "58;5;", Integer.to_string(n), "m"]
  end

  def underline_color({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    [
      @csi,
      "58;2;",
      Integer.to_string(r),
      ";",
      Integer.to_string(g),
      ";",
      Integer.to_string(b),
      "m"
    ]
  end

  @doc "Reset underline color to match foreground (SGR 59)."
  def underline_color_reset, do: "\e[59m"

  @doc "Blink (SGR 5)."
  def blink, do: "\e[5m"

  @doc "Reverse video (SGR 7)."
  def reverse, do: "\e[7m"

  @doc "Hidden/conceal (SGR 8)."
  def hidden, do: "\e[8m"

  @doc "Strikethrough (SGR 9)."
  def strikethrough, do: "\e[9m"

  @doc "Reset bold and dim (SGR 22)."
  def no_bold, do: "\e[22m"

  @doc "Reset italic (SGR 23)."
  def no_italic, do: "\e[23m"

  @doc "Reset underline (SGR 24)."
  def no_underline, do: "\e[24m"

  @doc "Reset blink (SGR 25)."
  def no_blink, do: "\e[25m"

  @doc "Reset reverse (SGR 27)."
  def no_reverse, do: "\e[27m"

  @doc "Reset hidden (SGR 28)."
  def no_hidden, do: "\e[28m"

  @doc "Reset strikethrough (SGR 29)."
  def no_strikethrough, do: "\e[29m"

  @doc "Overline (SGR 53). Kitty + ghostty."
  def overline, do: "\e[53m"

  @doc "Reset overline (SGR 55)."
  def no_overline, do: "\e[55m"

  @doc "Reset all attributes (SGR 0)."
  def reset, do: "\e[0m"

  # -- Cursor --

  @doc "Move cursor up by `n` rows."
  def cursor_up(n \\ 1), do: [@csi, Integer.to_string(n), "A"]

  @doc "Move cursor down by `n` rows."
  def cursor_down(n \\ 1), do: [@csi, Integer.to_string(n), "B"]

  @doc "Move cursor right by `n` columns."
  def cursor_right(n \\ 1), do: [@csi, Integer.to_string(n), "C"]

  @doc "Move cursor left by `n` columns."
  def cursor_left(n \\ 1), do: [@csi, Integer.to_string(n), "D"]

  @doc "Move cursor down `n` lines and to column 1."
  def cursor_next_line(n \\ 1), do: [@csi, Integer.to_string(n), "E"]

  @doc "Move cursor up `n` lines and to column 1."
  def cursor_prev_line(n \\ 1), do: [@csi, Integer.to_string(n), "F"]

  @doc "Move cursor to absolute `row`, `col` (1-based)."
  def cursor_to(row, col), do: [@csi, Integer.to_string(row), ";", Integer.to_string(col), "H"]

  @doc "Move cursor to column `n` on the current row (1-based)."
  def cursor_column(n), do: [@csi, Integer.to_string(n), "G"]

  @doc "Move cursor to row `n` on the current column (1-based)."
  def cursor_row(n), do: [@csi, Integer.to_string(n), "d"]

  @doc "Move cursor to row 1, col 1."
  def cursor_home, do: "\e[H"

  @doc "Save cursor position (SCO)."
  def cursor_save, do: "\e[s"

  @doc "Restore cursor position (SCO)."
  def cursor_restore, do: "\e[u"

  @doc "Hide cursor."
  def cursor_hide, do: "\e[?25l"

  @doc "Show cursor."
  def cursor_show, do: "\e[?25h"

  # -- Screen --

  @doc "Clear entire screen."
  def clear_screen, do: "\e[2J"

  @doc "Clear from cursor to end of screen."
  def clear_below, do: "\e[0J"

  @doc "Clear from cursor to beginning of screen."
  def clear_above, do: "\e[1J"

  @doc "Clear entire line."
  def clear_line, do: "\e[2K"

  @doc "Clear from cursor to end of line."
  def clear_line_right, do: "\e[0K"

  @doc "Clear from cursor to beginning of line."
  def clear_line_left, do: "\e[1K"

  @doc "Enter alternate screen buffer."
  def alternate_screen_enter, do: "\e[?1049h"

  @doc "Exit alternate screen buffer."
  def alternate_screen_exit, do: "\e[?1049l"

  @doc "Disable auto line wrap. Prevents terminal from wrapping at right edge."
  def line_wrap_disable, do: "\e[?7l"

  @doc "Enable auto line wrap (default terminal behavior)."
  def line_wrap_enable, do: "\e[?7h"

  @doc "Full terminal reset (RIS). Restores all defaults — clears screen, resets colors, styles, modes."
  def full_reset, do: "\ec"

  # -- Focus Events --

  @doc "Enable focus event reporting. Terminal sends `\\e[I` on focus in, `\\e[O` on focus out."
  def focus_events_enable, do: "\e[?1004h"

  @doc "Disable focus event reporting."
  def focus_events_disable, do: "\e[?1004l"

  # -- Synchronized Output --

  @doc "Begin synchronized update. Terminal buffers all output until `sync_end/0`."
  def sync_begin, do: "\e[?2026h"

  @doc "End synchronized update. Terminal renders buffered output as one atomic frame."
  def sync_end, do: "\e[?2026l"

  # -- Scroll Region --

  @doc "Set scroll region to rows `top` through `bottom` (1-based). Resets to full screen if called with no arguments."
  def scroll_region(top, bottom),
    do: [@csi, Integer.to_string(top), ";", Integer.to_string(bottom), "r"]

  @doc "Reset scroll region to full screen."
  def scroll_region_reset, do: "\e[r"

  @doc "Scroll content up by `n` lines within the scroll region."
  def scroll_up(n \\ 1), do: [@csi, Integer.to_string(n), "S"]

  @doc "Scroll content down by `n` lines within the scroll region."
  def scroll_down(n \\ 1), do: [@csi, Integer.to_string(n), "T"]

  # -- Cursor Position Report --

  @doc "Request cursor position. Terminal responds with `\\e[{row};{col}R`."
  def cursor_position_request, do: "\e[6n"

  # -- Bracketed Paste --

  @doc "Enable bracketed paste mode. Pasted text is wrapped in `\\e[200~` / `\\e[201~`."
  def bracketed_paste_enable, do: "\e[?2004h"

  @doc "Disable bracketed paste mode."
  def bracketed_paste_disable, do: "\e[?2004l"

  # -- Mouse --

  @doc "Enable basic mouse tracking (press events)."
  def mouse_enable, do: "\e[?1000h"

  @doc "Disable basic mouse tracking."
  def mouse_disable, do: "\e[?1000l"

  @doc "Enable SGR mouse mode (extended coordinates, supports large terminals)."
  def mouse_sgr_enable, do: "\e[?1006h"

  @doc "Disable SGR mouse mode."
  def mouse_sgr_disable, do: "\e[?1006l"

  # -- Hyperlinks (OSC 8) --

  @doc "Wrap `text` in an OSC 8 hyperlink to `url`."
  def hyperlink(url, text), do: ["\e]8;;", url, "\e\\", text, "\e]8;;\e\\"]

  # -- Window Title (OSC 0) --

  @doc "Set the terminal window/tab title."
  def window_title(title), do: ["\e]0;", title, "\a"]

  # -- Cursor Style --

  @doc """
  Set cursor style. Values:
  - `0` — default
  - `1` — blinking block
  - `2` — steady block
  - `3` — blinking underline
  - `4` — steady underline
  - `5` — blinking bar
  - `6` — steady bar
  """
  def cursor_style(n) when n in 0..6, do: [@csi, Integer.to_string(n), " q"]

  # -- Kitty Keyboard Protocol --

  @doc """
  Push keyboard mode with `flags` onto the stack. Kitty + ghostty.

  Flags (bitmask, combine with `Bitwise.bor/2`):
  - `1` — disambiguate escape codes
  - `2` — report event types (press/repeat/release)
  - `4` — report alternate keys
  - `8` — report all keys as escape codes
  - `16` — report associated text
  """
  def kitty_keyboard_push(flags) when is_integer(flags) do
    [@csi, ">", Integer.to_string(flags), "u"]
  end

  @doc "Pop `n` entries from the keyboard mode stack (default 1)."
  def kitty_keyboard_pop(n \\ 1), do: [@csi, "<", Integer.to_string(n), "u"]

  @doc "Query current keyboard mode flags. Terminal responds with `CSI ? {flags} u`."
  def kitty_keyboard_query, do: "\e[?u"

  # -- Grapheme Cluster Mode (Mode 2027) --

  @doc "Enable Unicode grapheme cluster mode. Kitty + ghostty."
  def grapheme_cluster_enable, do: "\e[?2027h"

  @doc "Disable Unicode grapheme cluster mode."
  def grapheme_cluster_disable, do: "\e[?2027l"

  # -- Clipboard (OSC 52) --

  @doc "Write `data` to the system clipboard. `data` is base64-encoded by this function."
  def clipboard_write(data) when is_binary(data) do
    ["\e]52;c;", Base.encode64(data), "\e\\"]
  end

  @doc "Request clipboard contents. Terminal responds with `ESC]52;c;{base64}ST`."
  def clipboard_read, do: "\e]52;c;?\e\\"
end
