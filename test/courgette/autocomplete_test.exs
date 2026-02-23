defmodule Courgette.AutocompleteTest do
  use ExUnit.Case, async: true

  alias Courgette.Autocomplete

  describe "new/1" do
    test "creates empty state with no triggers" do
      ac = Autocomplete.new()
      assert ac.triggers == []
      assert ac.active == nil
      assert ac.suggestions == []
      assert ac.cursor == 0
    end

    test "creates state with triggers" do
      triggers = [%{char: "@", tag: :mention}, %{char: "#", tag: :tag}]
      ac = Autocomplete.new(triggers)
      assert ac.triggers == triggers
    end
  end

  describe "check_trigger/5" do
    setup do
      ac = Autocomplete.new([%{char: "@", tag: :mention}])
      %{ac: ac}
    end

    test "activates on matching trigger at start of line", %{ac: ac} do
      # "@" typed at col 0, cursor is now at col 1
      lines = [["@"]]
      result = Autocomplete.check_trigger(ac, "@", 0, 1, lines)
      assert result.active != nil
      assert result.active.trigger.tag == :mention
      assert result.active.start_line == 0
      assert result.active.start_col == 0
    end

    test "activates after whitespace", %{ac: ac} do
      # "hello @" — trigger at col 6, cursor at col 7
      lines = [["h", "e", "l", "l", "o", " ", "@"]]
      result = Autocomplete.check_trigger(ac, "@", 0, 7, lines)
      assert result.active != nil
      assert result.active.start_col == 6
    end

    test "does not activate mid-word", %{ac: ac} do
      # "foo@" — @ at col 3, preceded by "o" (not whitespace)
      lines = [["f", "o", "o", "@"]]
      result = Autocomplete.check_trigger(ac, "@", 0, 4, lines)
      assert result.active == nil
    end

    test "does not activate for non-trigger character", %{ac: ac} do
      lines = [["#"]]
      result = Autocomplete.check_trigger(ac, "#", 0, 1, lines)
      assert result.active == nil
    end

    test "activates on second line", %{ac: ac} do
      lines = [["h", "i"], ["@"]]
      result = Autocomplete.check_trigger(ac, "@", 1, 1, lines)
      assert result.active != nil
      assert result.active.start_line == 1
      assert result.active.start_col == 0
    end

    test "activates after tab character", %{ac: ac} do
      lines = [["\t", "@"]]
      result = Autocomplete.check_trigger(ac, "@", 0, 2, lines)
      assert result.active != nil
    end
  end

  describe "extract_query/4" do
    test "returns nil when inactive" do
      ac = Autocomplete.new()
      assert Autocomplete.extract_query(ac, [[]], 0, 0) == nil
    end

    test "returns empty string immediately after trigger" do
      ac = %Autocomplete{
        triggers: [%{char: "@", tag: :mention}],
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0}
      }

      lines = [["@"]]
      assert Autocomplete.extract_query(ac, lines, 0, 1) == ""
    end

    test "returns query text after trigger" do
      ac = %Autocomplete{
        triggers: [%{char: "@", tag: :mention}],
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0}
      }

      lines = [["@", "f", "i", "l", "e"]]
      assert Autocomplete.extract_query(ac, lines, 0, 5) == "file"
    end

    test "returns partial query" do
      ac = %Autocomplete{
        triggers: [%{char: "@", tag: :mention}],
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3}
      }

      lines = [["h", "i", " ", "@", "f", "i"]]
      assert Autocomplete.extract_query(ac, lines, 0, 6) == "fi"
    end

    test "returns nil when cursor on different line" do
      ac = %Autocomplete{
        triggers: [%{char: "@", tag: :mention}],
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0}
      }

      lines = [["@", "f"], []]
      assert Autocomplete.extract_query(ac, lines, 1, 0) == nil
    end
  end

  describe "set_suggestions/2" do
    test "sets string suggestions, normalizing to maps" do
      ac = Autocomplete.new()
      result = Autocomplete.set_suggestions(ac, ["foo.ex", "bar.ex"])
      assert length(result.suggestions) == 2
      assert hd(result.suggestions) == %{label: "foo.ex", value: "foo.ex"}
    end

    test "preserves map suggestions" do
      ac = Autocomplete.new()
      suggestions = [%{label: "Foo", value: "foo.ex"}]
      result = Autocomplete.set_suggestions(ac, suggestions)
      assert result.suggestions == suggestions
    end

    test "resets cursor to 0" do
      ac = %Autocomplete{cursor: 3}
      result = Autocomplete.set_suggestions(ac, ["a", "b", "c"])
      assert result.cursor == 0
    end

    test "handles empty list" do
      ac = Autocomplete.new()
      result = Autocomplete.set_suggestions(ac, [])
      assert result.suggestions == []
    end
  end

  describe "navigate/2" do
    test "moves cursor down" do
      ac = Autocomplete.set_suggestions(Autocomplete.new(), ["a", "b", "c"])
      result = Autocomplete.navigate(ac, :down)
      assert result.cursor == 1
    end

    test "moves cursor up" do
      ac = %{Autocomplete.set_suggestions(Autocomplete.new(), ["a", "b", "c"]) | cursor: 2}
      result = Autocomplete.navigate(ac, :up)
      assert result.cursor == 1
    end

    test "clamps at bottom" do
      ac = %{Autocomplete.set_suggestions(Autocomplete.new(), ["a", "b"]) | cursor: 1}
      result = Autocomplete.navigate(ac, :down)
      assert result.cursor == 1
    end

    test "clamps at top" do
      ac = Autocomplete.set_suggestions(Autocomplete.new(), ["a", "b"])
      result = Autocomplete.navigate(ac, :up)
      assert result.cursor == 0
    end

    test "no-ops with empty suggestions" do
      ac = Autocomplete.new()
      assert Autocomplete.navigate(ac, :down) == ac
      assert Autocomplete.navigate(ac, :up) == ac
    end
  end

  describe "accept/1" do
    test "returns acceptance and dismissed state" do
      ac = %Autocomplete{
        triggers: [%{char: "@", tag: :mention}],
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3},
        suggestions: [%{label: "foo.ex", value: "foo.ex"}, %{label: "bar.ex", value: "bar.ex"}],
        cursor: 1
      }

      {acceptance, dismissed} = Autocomplete.accept(ac)

      assert acceptance.tag == :mention
      assert acceptance.value == "bar.ex"
      assert acceptance.label == "bar.ex"
      assert acceptance.start_line == 0
      assert acceptance.start_col == 3

      assert dismissed.active == nil
      assert dismissed.suggestions == []
      assert dismissed.cursor == 0
    end

    test "returns nil when inactive" do
      ac = Autocomplete.new()
      {acceptance, state} = Autocomplete.accept(ac)
      assert acceptance == nil
      assert state == ac
    end

    test "returns nil when no suggestions" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0},
        suggestions: []
      }

      {acceptance, _state} = Autocomplete.accept(ac)
      assert acceptance == nil
    end
  end

  describe "dismiss/1" do
    test "clears active state, suggestions, and cursor" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0},
        suggestions: [%{label: "foo", value: "foo"}],
        cursor: 2
      }

      result = Autocomplete.dismiss(ac)
      assert result.active == nil
      assert result.suggestions == []
      assert result.cursor == 0
      # triggers preserved
      assert result.triggers == ac.triggers
    end
  end

  describe "active?/1" do
    test "false when inactive" do
      assert Autocomplete.active?(Autocomplete.new()) == false
    end

    test "true when active" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 0}
      }

      assert Autocomplete.active?(ac) == true
    end
  end

  describe "should_dismiss?/4" do
    test "false when inactive" do
      ac = Autocomplete.new()
      assert Autocomplete.should_dismiss?(ac, 0, 0, [[]]) == false
    end

    test "true when cursor on different line" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3}
      }

      assert Autocomplete.should_dismiss?(ac, 1, 0, [[], []]) == true
    end

    test "true when cursor at trigger position" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3}
      }

      assert Autocomplete.should_dismiss?(ac, 0, 3, [["h", "i", " ", "@"]]) == true
    end

    test "true when cursor before trigger position" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3}
      }

      assert Autocomplete.should_dismiss?(ac, 0, 1, [["h", "i", " ", "@"]]) == true
    end

    test "false when cursor after trigger on same line" do
      ac = %Autocomplete{
        active: %{trigger: %{char: "@", tag: :mention}, start_line: 0, start_col: 3}
      }

      assert Autocomplete.should_dismiss?(ac, 0, 5, [["h", "i", " ", "@", "f"]]) == false
    end
  end

  describe "query_char?/1" do
    test "letters" do
      assert Autocomplete.query_char?("a")
      assert Autocomplete.query_char?("Z")
    end

    test "digits" do
      assert Autocomplete.query_char?("0")
      assert Autocomplete.query_char?("9")
    end

    test "underscore, hyphen, dot, slash" do
      assert Autocomplete.query_char?("_")
      assert Autocomplete.query_char?("-")
      assert Autocomplete.query_char?(".")
      assert Autocomplete.query_char?("/")
    end

    test "space is not a query char" do
      refute Autocomplete.query_char?(" ")
    end

    test "special characters are not query chars" do
      refute Autocomplete.query_char?("@")
      refute Autocomplete.query_char?("#")
      refute Autocomplete.query_char?("!")
    end
  end
end
