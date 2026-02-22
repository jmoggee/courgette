defmodule Courgette.Theme do
  @moduledoc """
  Semantic color tokens for theming Courgette components.

  A theme maps semantic names (`:primary`, `:danger`, `:surface`, etc.)
  to terminal color values. Components look up tokens via `get/2,3`
  rather than hard-coding colors.

      theme = Theme.default()
      Theme.get(theme, :primary)   # => :blue
      Theme.get(theme, :custom, :white)  # => :white (fallback)
  """

  @type color :: atom() | 0..255 | {byte(), byte(), byte()}

  @type t :: %__MODULE__{
          name: String.t(),
          tokens: %{atom() => color()}
        }

  defstruct name: "default", tokens: %{}

  @default_tokens %{
    bg: :black,
    fg: :white,
    primary: :blue,
    secondary: :cyan,
    success: :green,
    warning: :yellow,
    danger: :red,
    muted: :bright_black,
    border: :white,
    surface: :bright_black
  }

  @doc "Returns the default theme."
  @spec default() :: t()
  def default do
    %__MODULE__{name: "default", tokens: @default_tokens}
  end

  @doc """
  Looks up a token in the theme. Raises if not found.

      Theme.get(theme, :primary)  # => :blue
  """
  @spec get(t(), atom()) :: color()
  def get(%__MODULE__{tokens: tokens}, token) do
    case Map.fetch(tokens, token) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "unknown theme token: #{inspect(token)}"
    end
  end

  @doc """
  Looks up a token in the theme with a default fallback.

      Theme.get(theme, :custom, :white)  # => :white
  """
  @spec get(t(), atom(), color()) :: color()
  def get(%__MODULE__{tokens: tokens}, token, default) do
    Map.get(tokens, token, default)
  end
end
