defmodule Courgette.Terminal.KeyParser do
  @moduledoc """
  Pure function parser that converts raw terminal input bytes into structured
  event tuples.

  ## Usage

      {events, remaining} = KeyParser.parse(bytes, buffer)

  `buffer` holds incomplete bytes from the previous call. The caller manages
  buffer state between calls. Returns a list of parsed events and any
  trailing bytes that form an incomplete sequence.

  ## Event Formats

  See the module type specs for the full set of event tuples.
  """

  @type modifier :: :shift | :alt | :ctrl | :super | :hyper
  @type button :: :left | :middle | :right

  @type event ::
          {:key, key_value()}
          | {:key, key_value(), [modifier()]}
          | {:mouse, mouse_action(), button(), non_neg_integer(), non_neg_integer()}
          | {:mouse, mouse_action(), button(), non_neg_integer(), non_neg_integer(), [modifier()]}
          | {:mouse, :scroll_up | :scroll_down, non_neg_integer(), non_neg_integer()}
          | {:mouse, :scroll_up | :scroll_down, non_neg_integer(), non_neg_integer(),
             [modifier()]}
          | {:focus, :in | :out}
          | {:paste, :start | :end}
          | {:cursor_position, pos_integer(), pos_integer()}

  @type key_value ::
          :enter
          | :tab
          | :escape
          | :backspace
          | :delete
          | :insert
          | :home
          | :end
          | :page_up
          | :page_down
          | :arrow_up
          | :arrow_down
          | :arrow_left
          | :arrow_right
          | :f1
          | :f2
          | :f3
          | :f4
          | :f5
          | :f6
          | :f7
          | :f8
          | :f9
          | :f10
          | :f11
          | :f12
          | {:char, String.t()}
          | {:ctrl, String.t()}
          | {:alt, String.t()}
          | {:shift, :tab}

  @type mouse_action :: :press | :drag | :release | :scroll_up | :scroll_down

  @doc """
  Parse raw terminal bytes into structured events.

  Prepends any `buffer` (leftover bytes from a previous call) to `bytes`,
  then parses greedily. Returns `{events, remaining}` where `remaining`
  is any incomplete trailing sequence.
  """
  @spec parse(binary(), binary()) :: {[event()], binary()}
  def parse(bytes, buffer \\ <<>>) do
    input = buffer <> bytes
    parse_bytes(input, [])
  end

  # -- Top-level dispatch --

  defp parse_bytes(<<>>, acc), do: {Enum.reverse(acc), <<>>}

  # ESC
  defp parse_bytes(<<0x1B, rest::binary>>, acc) do
    case parse_escape(rest) do
      {:ok, event, rest2} -> parse_bytes(rest2, [event | acc])
      {:skip, rest2} -> parse_bytes(rest2, acc)
      {:ok_multi, events, rest2} -> parse_bytes(rest2, Enum.reverse(events) ++ acc)
      {:incomplete, remaining} -> {Enum.reverse(acc), remaining}
    end
  end

  # Tab (0x09)
  defp parse_bytes(<<0x09, rest::binary>>, acc) do
    parse_bytes(rest, [{:key, :tab} | acc])
  end

  # Enter (0x0D)
  defp parse_bytes(<<0x0D, rest::binary>>, acc) do
    parse_bytes(rest, [{:key, :enter} | acc])
  end

  # Newline (0x0A) - treat as enter
  defp parse_bytes(<<0x0A, rest::binary>>, acc) do
    parse_bytes(rest, [{:key, :enter} | acc])
  end

  # Ctrl+letter (0x01-0x1A, excluding tab=0x09, enter=0x0D, newline=0x0A)
  defp parse_bytes(<<byte, rest::binary>>, acc) when byte in 0x01..0x1A do
    letter = <<byte + 0x60>>
    parse_bytes(rest, [{:key, {:ctrl, letter}} | acc])
  end

  # Backspace (0x7F)
  defp parse_bytes(<<0x7F, rest::binary>>, acc) do
    parse_bytes(rest, [{:key, :backspace} | acc])
  end

  # Printable ASCII (0x20-0x7E)
  defp parse_bytes(<<byte, rest::binary>>, acc) when byte in 0x20..0x7E do
    parse_bytes(rest, [{:key, {:char, <<byte>>}} | acc])
  end

  # UTF-8 multi-byte sequences
  defp parse_bytes(<<byte, _::binary>> = input, acc) when byte >= 0xC0 do
    case parse_utf8(input) do
      {:ok, char, rest} -> parse_bytes(rest, [{:key, {:char, char}} | acc])
      {:incomplete, remaining} -> {Enum.reverse(acc), remaining}
    end
  end

  # Skip unknown bytes
  defp parse_bytes(<<_byte, rest::binary>>, acc) do
    parse_bytes(rest, acc)
  end

  # -- ESC dispatch --

  # ESC at end of input - might be start of sequence, buffer it
  defp parse_escape(<<>>) do
    {:incomplete, <<0x1B>>}
  end

  # CSI: ESC[
  defp parse_escape(<<?\[, rest::binary>>) do
    parse_csi(rest, <<>>)
  end

  # SS3: ESC O
  defp parse_escape(<<?O, rest::binary>>) do
    parse_ss3(rest)
  end

  # Alt + printable char
  defp parse_escape(<<byte, rest::binary>>) when byte in 0x20..0x7E do
    {:ok, {:key, {:alt, <<byte>>}}, rest}
  end

  # ESC + another ESC - emit escape, re-parse
  defp parse_escape(<<0x1B, _::binary>> = rest) do
    {:ok, {:key, :escape}, rest}
  end

  # ESC + unrecognized - emit escape, re-parse rest
  defp parse_escape(<<_byte, _::binary>> = rest) do
    {:ok, {:key, :escape}, rest}
  end

  # -- SS3 sequences (ESC O ...) --

  defp parse_ss3(<<>>), do: {:incomplete, <<0x1B, ?O>>}

  # Function keys
  defp parse_ss3(<<?P, rest::binary>>), do: {:ok, {:key, :f1}, rest}
  defp parse_ss3(<<?Q, rest::binary>>), do: {:ok, {:key, :f2}, rest}
  defp parse_ss3(<<?R, rest::binary>>), do: {:ok, {:key, :f3}, rest}
  defp parse_ss3(<<?S, rest::binary>>), do: {:ok, {:key, :f4}, rest}

  # Application mode arrows
  defp parse_ss3(<<?A, rest::binary>>), do: {:ok, {:key, :arrow_up}, rest}
  defp parse_ss3(<<?B, rest::binary>>), do: {:ok, {:key, :arrow_down}, rest}
  defp parse_ss3(<<?C, rest::binary>>), do: {:ok, {:key, :arrow_right}, rest}
  defp parse_ss3(<<?D, rest::binary>>), do: {:ok, {:key, :arrow_left}, rest}

  # Navigation
  defp parse_ss3(<<?H, rest::binary>>), do: {:ok, {:key, :home}, rest}
  defp parse_ss3(<<?F, rest::binary>>), do: {:ok, {:key, :end}, rest}

  # Unknown SS3 sequence
  defp parse_ss3(<<final, rest::binary>>), do: {:ok, {:key, :escape}, <<?O, final, rest::binary>>}

  # -- CSI sequences (ESC[ ...) --

  # Collect parameter bytes (0x30-0x3F: digits, ;, <, ?, >) and intermediate
  # bytes (0x20-0x2F), then dispatch on final byte (0x40-0x7E).
  defp parse_csi(<<>>, params), do: {:incomplete, <<0x1B, ?\[, params::binary>>}

  defp parse_csi(<<byte, rest::binary>>, params) when byte in 0x30..0x3F do
    parse_csi(rest, <<params::binary, byte>>)
  end

  # Intermediate bytes (space, !, ", etc.)
  defp parse_csi(<<byte, rest::binary>>, params) when byte in 0x20..0x2F do
    parse_csi(rest, <<params::binary, byte>>)
  end

  # Final byte
  defp parse_csi(<<final, rest::binary>>, params) when final in 0x40..0x7E do
    dispatch_csi(final, params, rest)
  end

  # Incomplete - buffer the whole sequence
  defp parse_csi(<<_byte, _::binary>>, params) do
    {:incomplete, <<0x1B, ?\[, params::binary>>}
  end

  # Parse modifier from CSI params like "1;5" (1=default, 5=modifier value)
  # Returns sorted modifier list or [] for no modifiers.
  defp parse_csi_modifier_params(<<>>), do: []

  defp parse_csi_modifier_params(params) do
    case String.split(params, ";") do
      [_] -> []
      [_, mod_s | _] -> decode_modifiers(String.to_integer(mod_s))
    end
  end

  # -- CSI final byte dispatch --

  # Arrows: A=up, B=down, C=right, D=left
  defp dispatch_csi(final, params, rest) when final in ~c"ABCD" do
    key =
      case final do
        ?A -> :arrow_up
        ?B -> :arrow_down
        ?C -> :arrow_right
        ?D -> :arrow_left
      end

    case parse_csi_modifier_params(params) do
      [] -> {:ok, {:key, key}, rest}
      mods -> {:ok, {:key, key, mods}, rest}
    end
  end

  # Home
  defp dispatch_csi(?H, params, rest) do
    case parse_csi_modifier_params(params) do
      [] -> {:ok, {:key, :home}, rest}
      mods -> {:ok, {:key, :home, mods}, rest}
    end
  end

  # End
  defp dispatch_csi(?F, params, rest) do
    case parse_csi_modifier_params(params) do
      [] -> {:ok, {:key, :end}, rest}
      mods -> {:ok, {:key, :end, mods}, rest}
    end
  end

  # Shift+Tab
  defp dispatch_csi(?Z, _params, rest) do
    {:ok, {:key, {:shift, :tab}}, rest}
  end

  # Focus in
  defp dispatch_csi(?I, _params, rest) do
    {:ok, {:focus, :in}, rest}
  end

  # Focus out (CSI O — note this is different from SS3 ESC O)
  defp dispatch_csi(?O, _params, rest) do
    {:ok, {:focus, :out}, rest}
  end

  # Cursor position report: ESC[row;colR
  defp dispatch_csi(?R, params, rest) do
    case String.split(params, ";") do
      [row_s, col_s] ->
        row = String.to_integer(row_s)
        col = String.to_integer(col_s)
        {:ok, {:cursor_position, row, col}, rest}

      _ ->
        {:ok, {:cursor_position, 1, 1}, rest}
    end
  end

  # Tilde keys: ESC[N~ or ESC[N;mod~
  # Shift+Enter has two common xterm encodings. `13;2~` is used by terminal
  # mappings, while modifyOtherKeys emits `27;2;13~`.
  defp dispatch_csi(?~, "13;2", rest), do: {:ok, {:key, :enter, [:shift]}, rest}

  defp dispatch_csi(?~, "27;2;13", rest), do: {:ok, {:key, :enter, [:shift]}, rest}

  defp dispatch_csi(?~, params, rest) do
    {key_num, mod_str} =
      case String.split(params, ";") do
        [n] -> {n, nil}
        [n, m] -> {n, m}
        _ -> {params, nil}
      end

    mods = if mod_str, do: decode_modifiers(String.to_integer(mod_str)), else: []

    case tilde_key(key_num) do
      nil ->
        {:ok, {:key, :escape}, rest}

      {:paste, _} = event ->
        {:ok, event, rest}

      {:key, key_name} when mods == [] ->
        {:ok, {:key, key_name}, rest}

      {:key, key_name} ->
        {:ok, {:key, key_name, mods}, rest}
    end
  end

  # Kitty CSI u: ESC[codepoint;modifiersu
  defp dispatch_csi(?u, params, rest) do
    case parse_kitty_key(params) do
      {:ok, _key, _mods, :release} ->
        {:skip, rest}

      {:ok, key, [], _event_type} ->
        {:ok, {:key, key}, rest}

      {:ok, key, mods, _event_type} ->
        {:ok, {:key, key, mods}, rest}

      :error ->
        {:ok, {:key, :escape}, rest}
    end
  end

  # SGR mouse: ESC[<button;x;yM or ESC[<button;x;ym
  defp dispatch_csi(final, params, rest) when final in ~c"Mm" do
    case params do
      <<?<, sgr_params::binary>> ->
        parse_sgr_mouse(final, sgr_params, rest)

      _ ->
        # Non-SGR mouse, skip
        {:ok, {:key, :escape}, rest}
    end
  end

  # Unknown CSI sequence — discard
  defp dispatch_csi(_final, _params, rest) do
    {:ok, {:key, :escape}, rest}
  end

  # -- Tilde key mapping --

  defp tilde_key("1"), do: {:key, :home}
  defp tilde_key("2"), do: {:key, :insert}
  defp tilde_key("3"), do: {:key, :delete}
  defp tilde_key("4"), do: {:key, :end}
  defp tilde_key("5"), do: {:key, :page_up}
  defp tilde_key("6"), do: {:key, :page_down}
  defp tilde_key("15"), do: {:key, :f5}
  defp tilde_key("17"), do: {:key, :f6}
  defp tilde_key("18"), do: {:key, :f7}
  defp tilde_key("19"), do: {:key, :f8}
  defp tilde_key("20"), do: {:key, :f9}
  defp tilde_key("21"), do: {:key, :f10}
  defp tilde_key("23"), do: {:key, :f11}
  defp tilde_key("24"), do: {:key, :f12}
  defp tilde_key("200"), do: {:paste, :start}
  defp tilde_key("201"), do: {:paste, :end}
  defp tilde_key(_), do: nil

  # -- CSI u codepoint mapping --

  defp csi_u_key(13), do: :enter
  defp csi_u_key(9), do: :tab
  defp csi_u_key(27), do: :escape
  defp csi_u_key(127), do: :backspace

  defp csi_u_key(cp) do
    {:char, <<cp::utf8>>}
  end

  defp parse_kitty_key(params) do
    case String.split(params, ";") do
      [codepoint] ->
        with {:ok, codepoint} <- parse_decimal(codepoint) do
          {:ok, csi_u_key(codepoint), [], :press}
        end

      [codepoint, modifier_and_event] ->
        with {:ok, codepoint} <- parse_decimal(codepoint),
             {:ok, modifiers, event_type} <- parse_kitty_modifiers(modifier_and_event) do
          {:ok, csi_u_key(codepoint), modifiers, event_type}
        end

      _ ->
        :error
    end
  end

  defp parse_kitty_modifiers(modifier_and_event) do
    case String.split(modifier_and_event, ":") do
      [modifier] ->
        with {:ok, modifier} <- parse_decimal(modifier) do
          {:ok, decode_modifiers(modifier), :press}
        end

      [modifier, event] ->
        with {:ok, modifier} <- parse_decimal(modifier),
             {:ok, event_type} <- parse_kitty_event_type(event) do
          {:ok, decode_modifiers(modifier), event_type}
        end

      _ ->
        :error
    end
  end

  defp parse_kitty_event_type("1"), do: {:ok, :press}
  defp parse_kitty_event_type("2"), do: {:ok, :repeat}
  defp parse_kitty_event_type("3"), do: {:ok, :release}
  defp parse_kitty_event_type(_event), do: :error

  defp parse_decimal(value) do
    case Integer.parse(value) do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  # -- Modifier decoding --

  # CSI modifier value: value - 1 = bitmask
  # shift=1, alt=2, ctrl=4, super=8, hyper=16
  defp decode_modifiers(value) when is_integer(value) do
    bits = value - 1

    []
    |> then(fn acc -> if Bitwise.band(bits, 2) != 0, do: [:alt | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(bits, 4) != 0, do: [:ctrl | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(bits, 16) != 0, do: [:hyper | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(bits, 1) != 0, do: [:shift | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(bits, 8) != 0, do: [:super | acc], else: acc end)
    |> Enum.sort()
  end

  # -- SGR mouse parsing --

  defp parse_sgr_mouse(final, params, rest) do
    case String.split(params, ";") do
      [button_s, x_s, y_s] ->
        button_code = String.to_integer(button_s)
        x = String.to_integer(x_s)
        y = String.to_integer(y_s)
        action = mouse_action(final, button_code)

        build_mouse_event(sgr_button(button_code), action, x, y, sgr_modifiers(button_code), rest)

      _ ->
        {:ok, {:key, :escape}, rest}
    end
  end

  defp mouse_action(?m, _button_code), do: :release
  defp mouse_action(?M, button_code) when Bitwise.band(button_code, 32) != 0, do: :drag
  defp mouse_action(?M, _button_code), do: :press

  defp build_mouse_event({:scroll, dir}, _action, x, y, [], rest) do
    {:ok, {:mouse, dir, x, y}, rest}
  end

  defp build_mouse_event({:scroll, dir}, _action, x, y, mods, rest) do
    {:ok, {:mouse, dir, x, y, mods}, rest}
  end

  defp build_mouse_event(button, action, x, y, [], rest) do
    {:ok, {:mouse, action, button, x, y}, rest}
  end

  defp build_mouse_event(button, action, x, y, mods, rest) do
    {:ok, {:mouse, action, button, x, y, mods}, rest}
  end

  # SGR button code: low 2 bits = button
  # bit 2 (4) = shift, bit 3 (8) = alt/meta, bit 4 (16) = ctrl
  # bits 6-7 (64, 128) = scroll
  defp sgr_button(code) do
    base = Bitwise.band(code, 0x43)

    case base do
      0 -> :left
      1 -> :middle
      2 -> :right
      64 -> {:scroll, :scroll_up}
      65 -> {:scroll, :scroll_down}
      _ -> :left
    end
  end

  defp sgr_modifiers(code) do
    []
    |> then(fn acc -> if Bitwise.band(code, 8) != 0, do: [:alt | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(code, 16) != 0, do: [:ctrl | acc], else: acc end)
    |> then(fn acc -> if Bitwise.band(code, 4) != 0, do: [:shift | acc], else: acc end)
    |> Enum.sort()
  end

  # -- UTF-8 multi-byte parsing --

  defp parse_utf8(<<byte, rest::binary>>) when byte in 0xC0..0xDF do
    # 2-byte sequence
    case rest do
      <<b2, rest2::binary>> when b2 in 0x80..0xBF ->
        {:ok, <<byte, b2>>, rest2}

      <<>> ->
        {:incomplete, <<byte>>}

      _ ->
        # Invalid continuation, skip lead byte
        {:ok, <<0xEF, 0xBF, 0xBD>>, rest}
    end
  end

  defp parse_utf8(<<byte, rest::binary>>) when byte in 0xE0..0xEF do
    # 3-byte sequence
    case rest do
      <<b2, b3, rest2::binary>> when b2 in 0x80..0xBF and b3 in 0x80..0xBF ->
        {:ok, <<byte, b2, b3>>, rest2}

      <<b2>> when b2 in 0x80..0xBF ->
        {:incomplete, <<byte, b2>>}

      <<>> ->
        {:incomplete, <<byte>>}

      _ ->
        {:ok, <<0xEF, 0xBF, 0xBD>>, rest}
    end
  end

  defp parse_utf8(<<byte, rest::binary>>) when byte in 0xF0..0xF7 do
    # 4-byte sequence
    case rest do
      <<b2, b3, b4, rest2::binary>>
      when b2 in 0x80..0xBF and b3 in 0x80..0xBF and b4 in 0x80..0xBF ->
        {:ok, <<byte, b2, b3, b4>>, rest2}

      <<b2, b3>> when b2 in 0x80..0xBF and b3 in 0x80..0xBF ->
        {:incomplete, <<byte, b2, b3>>}

      <<b2>> when b2 in 0x80..0xBF ->
        {:incomplete, <<byte, b2>>}

      <<>> ->
        {:incomplete, <<byte>>}

      _ ->
        {:ok, <<0xEF, 0xBF, 0xBD>>, rest}
    end
  end
end
