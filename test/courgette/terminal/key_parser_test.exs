defmodule Courgette.Terminal.KeyParserTest do
  use ExUnit.Case, async: true

  alias Courgette.Terminal.KeyParser

  # Helper: parse with no buffer
  defp parse(bytes), do: KeyParser.parse(bytes)
  # Helper: parse with buffer
  defp parse(bytes, buffer), do: KeyParser.parse(bytes, buffer)

  # Helper: parse and return just the events (assert no remaining buffer)
  defp events(bytes) do
    {events, remaining} = parse(bytes)
    assert remaining == <<>>, "Expected no remaining bytes, got: #{inspect(remaining)}"
    events
  end

  describe "printable ASCII" do
    test "single characters" do
      assert events("a") == [{:key, {:char, "a"}}]
      assert events("z") == [{:key, {:char, "z"}}]
      assert events("A") == [{:key, {:char, "A"}}]
      assert events("Z") == [{:key, {:char, "Z"}}]
      assert events("0") == [{:key, {:char, "0"}}]
      assert events("9") == [{:key, {:char, "9"}}]
      assert events(" ") == [{:key, {:char, " "}}]
      assert events("!") == [{:key, {:char, "!"}}]
      assert events("~") == [{:key, {:char, "~"}}]
    end

    test "multiple characters produce multiple events" do
      assert events("abc") == [
               {:key, {:char, "a"}},
               {:key, {:char, "b"}},
               {:key, {:char, "c"}}
             ]
    end
  end

  describe "special keys" do
    test "enter" do
      assert events(<<0x0D>>) == [{:key, :enter}]
    end

    test "newline as enter" do
      assert events(<<0x0A>>) == [{:key, :enter}]
    end

    test "tab" do
      assert events(<<0x09>>) == [{:key, :tab}]
    end

    test "backspace" do
      assert events(<<0x7F>>) == [{:key, :backspace}]
    end
  end

  describe "ctrl+letter" do
    test "ctrl+a through ctrl+z" do
      assert events(<<0x01>>) == [{:key, {:ctrl, "a"}}]
      assert events(<<0x03>>) == [{:key, {:ctrl, "c"}}]
      assert events(<<0x04>>) == [{:key, {:ctrl, "d"}}]
      assert events(<<0x1A>>) == [{:key, {:ctrl, "z"}}]
    end

    test "ctrl+i is tab, not ctrl+i" do
      # 0x09 = ctrl+i = tab — we treat it as tab
      assert events(<<0x09>>) == [{:key, :tab}]
    end

    test "ctrl+m is enter, not ctrl+m" do
      # 0x0D = ctrl+m = enter — we treat it as enter
      assert events(<<0x0D>>) == [{:key, :enter}]
    end

    test "ctrl+j is enter, not ctrl+j" do
      # 0x0A = ctrl+j = newline — we treat it as enter
      assert events(<<0x0A>>) == [{:key, :enter}]
    end
  end

  describe "escape" do
    test "ESC at end of input buffers" do
      {events, remaining} = parse(<<0x1B>>)
      assert events == []
      assert remaining == <<0x1B>>
    end

    test "ESC followed by more data in next call" do
      {[], buffer} = parse(<<0x1B>>)
      {events, <<>>} = parse(<<"[A">>, buffer)
      assert events == [{:key, :arrow_up}]
    end

    test "ESC + ESC emits escape then buffers second ESC" do
      {events, remaining} = parse(<<0x1B, 0x1B>>)
      assert events == [{:key, :escape}]
      assert remaining == <<0x1B>>
    end
  end

  describe "alt+key" do
    test "alt+letter" do
      assert events(<<0x1B, ?x>>) == [{:key, {:alt, "x"}}]
      assert events(<<0x1B, ?a>>) == [{:key, {:alt, "a"}}]
    end

    test "alt+digit" do
      assert events(<<0x1B, ?1>>) == [{:key, {:alt, "1"}}]
    end

    test "alt+symbol" do
      assert events(<<0x1B, ?!>>) == [{:key, {:alt, "!"}}]
    end
  end

  describe "SS3 sequences (ESC O ...)" do
    test "F1-F4" do
      assert events(<<0x1B, ?O, ?P>>) == [{:key, :f1}]
      assert events(<<0x1B, ?O, ?Q>>) == [{:key, :f2}]
      assert events(<<0x1B, ?O, ?R>>) == [{:key, :f3}]
      assert events(<<0x1B, ?O, ?S>>) == [{:key, :f4}]
    end

    test "application-mode arrows" do
      assert events(<<0x1B, ?O, ?A>>) == [{:key, :arrow_up}]
      assert events(<<0x1B, ?O, ?B>>) == [{:key, :arrow_down}]
      assert events(<<0x1B, ?O, ?C>>) == [{:key, :arrow_right}]
      assert events(<<0x1B, ?O, ?D>>) == [{:key, :arrow_left}]
    end

    test "home and end" do
      assert events(<<0x1B, ?O, ?H>>) == [{:key, :home}]
      assert events(<<0x1B, ?O, ?F>>) == [{:key, :end}]
    end

    test "incomplete SS3 buffers" do
      {events, remaining} = parse(<<0x1B, ?O>>)
      assert events == []
      assert remaining == <<0x1B, ?O>>
    end
  end

  describe "CSI arrows" do
    test "unmodified arrows" do
      assert events("\e[A") == [{:key, :arrow_up}]
      assert events("\e[B") == [{:key, :arrow_down}]
      assert events("\e[C") == [{:key, :arrow_right}]
      assert events("\e[D") == [{:key, :arrow_left}]
    end

    test "shift+arrow" do
      assert events("\e[1;2A") == [{:key, :arrow_up, [:shift]}]
      assert events("\e[1;2B") == [{:key, :arrow_down, [:shift]}]
    end

    test "alt+arrow" do
      assert events("\e[1;3A") == [{:key, :arrow_up, [:alt]}]
    end

    test "ctrl+arrow" do
      assert events("\e[1;5C") == [{:key, :arrow_right, [:ctrl]}]
    end

    test "ctrl+shift+arrow" do
      assert events("\e[1;6A") == [{:key, :arrow_up, [:ctrl, :shift]}]
    end

    test "alt+ctrl+arrow" do
      # modifier 7: 7 - 1 = 6 = alt(2) + ctrl(4)
      assert events("\e[1;7A") == [{:key, :arrow_up, [:alt, :ctrl]}]
    end

    test "shift+alt+ctrl+arrow" do
      # modifier 8: 8 - 1 = 7 = shift(1) + alt(2) + ctrl(4)
      assert events("\e[1;8A") == [{:key, :arrow_up, [:alt, :ctrl, :shift]}]
    end
  end

  describe "CSI navigation keys" do
    test "home and end" do
      assert events("\e[H") == [{:key, :home}]
      assert events("\e[F") == [{:key, :end}]
    end

    test "modified home" do
      assert events("\e[1;5H") == [{:key, :home, [:ctrl]}]
    end

    test "shift+tab" do
      assert events("\e[Z") == [{:key, {:shift, :tab}}]
    end
  end

  describe "CSI tilde keys" do
    test "insert" do
      assert events("\e[2~") == [{:key, :insert}]
    end

    test "delete" do
      assert events("\e[3~") == [{:key, :delete}]
    end

    test "page up and page down" do
      assert events("\e[5~") == [{:key, :page_up}]
      assert events("\e[6~") == [{:key, :page_down}]
    end

    test "home and end (tilde variant)" do
      assert events("\e[1~") == [{:key, :home}]
      assert events("\e[4~") == [{:key, :end}]
    end

    test "F5-F12" do
      assert events("\e[15~") == [{:key, :f5}]
      assert events("\e[17~") == [{:key, :f6}]
      assert events("\e[18~") == [{:key, :f7}]
      assert events("\e[19~") == [{:key, :f8}]
      assert events("\e[20~") == [{:key, :f9}]
      assert events("\e[21~") == [{:key, :f10}]
      assert events("\e[23~") == [{:key, :f11}]
      assert events("\e[24~") == [{:key, :f12}]
    end

    test "modified delete" do
      assert events("\e[3;5~") == [{:key, :delete, [:ctrl]}]
    end

    test "modified F5" do
      assert events("\e[15;2~") == [{:key, :f5, [:shift]}]
    end
  end

  describe "focus events" do
    test "focus in" do
      assert events("\e[I") == [{:focus, :in}]
    end

    test "focus out" do
      assert events("\e[O") == [{:focus, :out}]
    end
  end

  describe "bracketed paste" do
    test "paste start" do
      assert events("\e[200~") == [{:paste, :start}]
    end

    test "paste end" do
      assert events("\e[201~") == [{:paste, :end}]
    end
  end

  describe "cursor position report" do
    test "standard CPR" do
      assert events("\e[24;80R") == [{:cursor_position, 24, 80}]
    end

    test "CPR at origin" do
      assert events("\e[1;1R") == [{:cursor_position, 1, 1}]
    end
  end

  describe "Kitty CSI u" do
    test "enter" do
      assert events("\e[13u") == [{:key, :enter}]
    end

    test "tab" do
      assert events("\e[9u") == [{:key, :tab}]
    end

    test "escape" do
      assert events("\e[27u") == [{:key, :escape}]
    end

    test "backspace" do
      assert events("\e[127u") == [{:key, :backspace}]
    end

    test "printable character" do
      assert events("\e[97u") == [{:key, {:char, "a"}}]
    end

    test "character with shift" do
      assert events("\e[97;2u") == [{:key, {:char, "a"}, [:shift]}]
    end

    test "character with ctrl" do
      assert events("\e[97;5u") == [{:key, {:char, "a"}, [:ctrl]}]
    end

    test "character with ctrl+shift" do
      assert events("\e[97;6u") == [{:key, {:char, "a"}, [:ctrl, :shift]}]
    end

    test "enter with shift" do
      assert events("\e[13;2u") == [{:key, :enter, [:shift]}]
    end
  end

  describe "SGR mouse" do
    test "left press" do
      assert events("\e[<0;10;20M") == [{:mouse, :press, :left, 10, 20}]
    end

    test "left release" do
      assert events("\e[<0;10;20m") == [{:mouse, :release, :left, 10, 20}]
    end

    test "middle press" do
      assert events("\e[<1;5;5M") == [{:mouse, :press, :middle, 5, 5}]
    end

    test "right press" do
      assert events("\e[<2;15;30M") == [{:mouse, :press, :right, 15, 30}]
    end

    test "scroll up" do
      assert events("\e[<64;10;20M") == [{:mouse, :scroll_up, 10, 20}]
    end

    test "scroll down" do
      assert events("\e[<65;10;20M") == [{:mouse, :scroll_down, 10, 20}]
    end

    test "ctrl+left press" do
      assert events("\e[<16;10;20M") == [{:mouse, :press, :left, 10, 20, [:ctrl]}]
    end

    test "shift+left press" do
      assert events("\e[<4;10;20M") == [{:mouse, :press, :left, 10, 20, [:shift]}]
    end

    test "alt+left press" do
      assert events("\e[<8;10;20M") == [{:mouse, :press, :left, 10, 20, [:alt]}]
    end
  end

  describe "UTF-8 multi-byte" do
    test "2-byte character (e.g. ñ)" do
      assert events("ñ") == [{:key, {:char, "ñ"}}]
    end

    test "3-byte character (e.g. €)" do
      assert events("€") == [{:key, {:char, "€"}}]
    end

    test "4-byte character (e.g. emoji 😀)" do
      assert events("😀") == [{:key, {:char, "😀"}}]
    end

    test "mixed ASCII and UTF-8" do
      assert events("añb") == [
               {:key, {:char, "a"}},
               {:key, {:char, "ñ"}},
               {:key, {:char, "b"}}
             ]
    end

    test "incomplete 2-byte sequence buffers" do
      # ñ is 0xC3 0xB1 — send just the first byte
      {events, remaining} = parse(<<0xC3>>)
      assert events == []
      assert remaining == <<0xC3>>
    end

    test "incomplete 3-byte sequence buffers" do
      # € is 0xE2 0x82 0xAC — send first two bytes
      {events, remaining} = parse(<<0xE2, 0x82>>)
      assert events == []
      assert remaining == <<0xE2, 0x82>>
    end

    test "incomplete 4-byte sequence buffers" do
      # 😀 is 0xF0 0x9F 0x98 0x80 — send first three bytes
      {events, remaining} = parse(<<0xF0, 0x9F, 0x98>>)
      assert events == []
      assert remaining == <<0xF0, 0x9F, 0x98>>
    end

    test "incomplete UTF-8 completed in next call" do
      {[], buffer} = parse(<<0xC3>>)
      {events, <<>>} = parse(<<0xB1>>, buffer)
      assert events == [{:key, {:char, "ñ"}}]
    end
  end

  describe "incremental buffer" do
    test "CSI sequence split across calls" do
      # ESC[1;5C split: first "\e[1;5" then "C"
      {[], buffer} = parse("\e[1;5")
      {events, <<>>} = parse("C", buffer)
      assert events == [{:key, :arrow_right, [:ctrl]}]
    end

    test "CSI sequence split at ESC" do
      {[], buffer} = parse(<<0x1B>>)
      {events, <<>>} = parse("[A", buffer)
      assert events == [{:key, :arrow_up}]
    end

    test "multiple events with trailing incomplete" do
      # "a" followed by start of ESC sequence
      {events, remaining} = parse(<<"a", 0x1B>>)
      assert events == [{:key, {:char, "a"}}]
      assert remaining == <<0x1B>>
    end

    test "tilde sequence split across calls" do
      {[], buffer} = parse("\e[15")
      {events, <<>>} = parse("~", buffer)
      assert events == [{:key, :f5}]
    end

    test "mouse sequence split across calls" do
      {[], buffer} = parse("\e[<0;10;")
      {events, <<>>} = parse("20M", buffer)
      assert events == [{:mouse, :press, :left, 10, 20}]
    end
  end

  describe "mixed input" do
    test "multiple different events in one chunk" do
      # "a" + Enter + Ctrl-C + ESC[A (arrow up)
      input = <<"a", 0x0D, 0x03, 0x1B, "[A">>

      assert events(input) == [
               {:key, {:char, "a"}},
               {:key, :enter},
               {:key, {:ctrl, "c"}},
               {:key, :arrow_up}
             ]
    end

    test "rapid key presses" do
      input = <<"hello">>

      assert events(input) == [
               {:key, {:char, "h"}},
               {:key, {:char, "e"}},
               {:key, {:char, "l"}},
               {:key, {:char, "l"}},
               {:key, {:char, "o"}}
             ]
    end

    test "empty input returns no events" do
      assert events(<<>>) == []
    end
  end

  describe "edge cases" do
    test "parse with explicit empty buffer" do
      {events, <<>>} = parse("a", <<>>)
      assert events == [{:key, {:char, "a"}}]
    end

    test "unknown CSI sequence is discarded" do
      # ESC[999z — unknown final byte 'z' outside recognized set
      {events, <<>>} = parse("\e[999`")
      assert events == [{:key, :escape}]
    end

    test "space is a printable character" do
      assert events(" ") == [{:key, {:char, " "}}]
    end

    test "DEL is backspace" do
      assert events(<<127>>) == [{:key, :backspace}]
    end
  end
end
