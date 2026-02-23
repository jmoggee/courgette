defmodule Courgette.Autocomplete do
  @moduledoc """
  Pure-function state machine for trigger-based autocomplete.

  Manages the lifecycle of autocomplete popups triggered by special characters
  (like `@` for mentions, `#` for tags, `/` for commands). All functions are
  pure — no processes, no side effects. The component holding the text editor
  state calls these functions in response to user input and renders the
  suggestions accordingly.

  ## Trigger format

  Each trigger is a map with:

  - `:char` — the single character that activates autocomplete (e.g. `"@"`)
  - `:tag` — an atom identifying this trigger type (e.g. `:mention`, `:file_ref`)

  ## Suggestion format

  Suggestions can be plain strings or maps with `:label` and `:value` keys.
  Plain strings are normalized to `%{label: str, value: str}` internally.
  """

  defstruct triggers: [],
            active: nil,
            suggestions: [],
            cursor: 0

  @type trigger :: %{char: String.t(), tag: atom()}

  @type suggestion :: %{label: String.t(), value: String.t()}

  @type active_state :: %{
          trigger: trigger(),
          start_line: non_neg_integer(),
          start_col: non_neg_integer()
        }

  @type t :: %__MODULE__{
          triggers: [trigger()],
          active: active_state() | nil,
          suggestions: [suggestion()],
          cursor: non_neg_integer()
        }

  @doc """
  Create a new autocomplete state with the given trigger definitions.
  """
  @spec new([trigger()]) :: t()
  def new(triggers \\ []) do
    %__MODULE__{triggers: triggers}
  end

  @doc """
  Check if a character activates a trigger.

  A trigger activates when the character matches a registered trigger's `:char`
  and appears at a word boundary (start of line or preceded by whitespace).
  Returns the updated state with `:active` set if triggered, unchanged otherwise.
  """
  @spec check_trigger(t(), String.t(), non_neg_integer(), non_neg_integer(), list()) :: t()
  def check_trigger(%__MODULE__{} = state, char, cursor_line, cursor_col, lines) do
    case find_trigger(state.triggers, char) do
      nil ->
        state

      trigger ->
        # The trigger char was just inserted at cursor_col - 1
        # (cursor_col is the position AFTER insertion)
        trigger_col = cursor_col - 1

        if at_word_boundary?(lines, cursor_line, trigger_col) do
          %{
            state
            | active: %{
                trigger: trigger,
                start_line: cursor_line,
                start_col: trigger_col
              }
          }
        else
          state
        end
    end
  end

  @doc """
  Extract the query text between the trigger character and the current cursor position.

  Returns the query string, or `nil` if autocomplete is not active.
  """
  @spec extract_query(t(), list(), non_neg_integer(), non_neg_integer()) :: String.t() | nil
  def extract_query(%__MODULE__{active: nil}, _lines, _cursor_line, _cursor_col), do: nil

  def extract_query(%__MODULE__{active: active}, lines, cursor_line, cursor_col) do
    if cursor_line != active.start_line do
      nil
    else
      line = Enum.at(lines, cursor_line, [])
      # Query starts after the trigger character
      query_start = active.start_col + 1

      if cursor_col > query_start do
        line
        |> Enum.slice(query_start, cursor_col - query_start)
        |> Enum.join()
      else
        ""
      end
    end
  end

  @doc """
  Update the suggestion list and reset the cursor to 0.
  """
  @spec set_suggestions(t(), [String.t() | suggestion()]) :: t()
  def set_suggestions(%__MODULE__{} = state, suggestions) do
    %{state | suggestions: normalize_suggestions(suggestions), cursor: 0}
  end

  @doc """
  Navigate the suggestion cursor up or down, clamped to valid range.
  """
  @spec navigate(t(), :up | :down) :: t()
  def navigate(%__MODULE__{suggestions: []} = state, _direction), do: state

  def navigate(%__MODULE__{} = state, :up) do
    %{state | cursor: max(state.cursor - 1, 0)}
  end

  def navigate(%__MODULE__{} = state, :down) do
    max_idx = length(state.suggestions) - 1
    %{state | cursor: min(state.cursor + 1, max_idx)}
  end

  @doc """
  Accept the currently selected suggestion.

  Returns `{acceptance, dismissed_state}` where `acceptance` is a map containing
  `:tag`, `:value`, `:label`, `:start_line`, and `:start_col`, and `dismissed_state`
  is the autocomplete state reset to inactive.

  Returns `{nil, state}` if no suggestion is selected or autocomplete is inactive.
  """
  @spec accept(t()) :: {map() | nil, t()}
  def accept(%__MODULE__{active: nil} = state), do: {nil, state}
  def accept(%__MODULE__{suggestions: []} = state), do: {nil, state}

  def accept(%__MODULE__{} = state) do
    suggestion = Enum.at(state.suggestions, state.cursor)

    acceptance = %{
      tag: state.active.trigger.tag,
      value: suggestion.value,
      label: suggestion.label,
      start_line: state.active.start_line,
      start_col: state.active.start_col
    }

    {acceptance, dismiss(state)}
  end

  @doc """
  Dismiss autocomplete, clearing active state, suggestions, and cursor.
  """
  @spec dismiss(t()) :: t()
  def dismiss(%__MODULE__{} = state) do
    %{state | active: nil, suggestions: [], cursor: 0}
  end

  @doc """
  Returns true if autocomplete is currently active (a trigger has been detected).
  """
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{active: nil}), do: false
  def active?(%__MODULE__{}), do: true

  @doc """
  Check if autocomplete should be dismissed based on cursor position.

  Returns true if the cursor has moved to a different line than the trigger,
  or has moved before or to the trigger position.
  """
  @spec should_dismiss?(t(), non_neg_integer(), non_neg_integer(), list()) :: boolean()
  def should_dismiss?(%__MODULE__{active: nil}, _cursor_line, _cursor_col, _lines), do: false

  def should_dismiss?(%__MODULE__{active: active}, cursor_line, cursor_col, _lines) do
    cursor_line != active.start_line or cursor_col <= active.start_col
  end

  @doc """
  Returns true if the character is valid within an autocomplete query.

  Valid query characters are alphanumeric, underscore, hyphen, dot, and forward slash.
  """
  @spec query_char?(String.t()) :: boolean()
  def query_char?(ch) when is_binary(ch) do
    ch =~ ~r/^[a-zA-Z0-9_\-\.\/]$/
  end

  # --- Private helpers ---

  defp find_trigger(triggers, char) do
    Enum.find(triggers, fn t -> t.char == char end)
  end

  defp at_word_boundary?(lines, line_idx, col) do
    if col == 0 do
      true
    else
      line = Enum.at(lines, line_idx, [])
      prev_char = Enum.at(line, col - 1)
      prev_char == nil or prev_char == " " or prev_char == "\t"
    end
  end

  defp normalize_suggestions(suggestions) do
    Enum.map(suggestions, fn
      %{label: _, value: _} = s -> s
      str when is_binary(str) -> %{label: str, value: str}
    end)
  end
end
