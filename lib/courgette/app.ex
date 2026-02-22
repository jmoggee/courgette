defmodule Courgette.App do
  @moduledoc """
  Entry point for root application components.

  `use Courgette.App` is the idiomatic way to define a root TUI component:

      defmodule MyApp do
        use Courgette.App

        def mount(_assigns), do: {:ok, %{}}
        def render(_assigns), do: text(do: "Hello!")
      end

  Currently identical to `use Courgette.LiveComponent`. Will diverge in
  Phase 5b when apps gain supervision and lifecycle features that child
  components don't have.
  """

  defmacro __using__(_opts) do
    quote do
      use Courgette.LiveComponent
    end
  end
end
