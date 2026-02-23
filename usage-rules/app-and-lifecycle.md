# App & Lifecycle

## Entry Point

```elixir
defmodule MyApp do
  use Courgette.App

  def mount(_assigns), do: {:ok, %{count: 0}}

  def render(assigns) do
    text(do: "Count: #{assigns.count}")
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, update(assigns, :count, &(&1 + 1))}
  end

  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop()
    {:noreply, %{}}
  end

  def handle_event(_event, assigns), do: {:noreply, assigns}
end

Courgette.run(MyApp)
```

## `Courgette.run/2`

Starts Terminal → Renderer → LiveComponent.Server, blocks until exit.

| Option | Default | Description |
|--------|---------|-------------|
| `:mode` | `:fullscreen` | `:fullscreen` or `:inline` |
| `:initial_assigns` | `%{}` | Map passed to `mount/1` |

## `Courgette.stop/0`

Call from `handle_event/2` to exit the app. Stops the root server, which unblocks `run/2`.

## `Courgette.send_update/2`

Push new props to a running child component by `{module, id}`:

```elixir
Courgette.send_update(Counter, id: "main", count: 42)
```

Returns `:ok` if found, `:error` if the component is not registered.

## Callback Signatures

### `mount/1` (required)

```elixir
@spec mount(assigns :: map()) :: {:ok, map()}
```

Called once at startup. Receives initial assigns (from `:initial_assigns` option or parent props). Must return `{:ok, assigns}`.

### `render/1` (required)

```elixir
@spec render(assigns :: map()) :: Element.t()
```

Called after mount and every state change. Returns an element tree built with DSL macros.

### `update/2` (optional)

```elixir
@spec update(new_props :: map(), assigns :: map()) :: {:ok, map()}
```

Called when a parent re-renders with new props. Default behavior merges props into assigns. Must return `{:ok, assigns}`.

### `handle_event/2` (optional)

```elixir
@spec handle_event(event :: term(), assigns :: map()) :: {:noreply, map()}
```

Called with parsed input events. Must return `{:noreply, assigns}`. Always include a catch-all clause.

### `handle_info/2` (optional)

```elixir
@spec handle_info(msg :: term(), assigns :: map()) :: {:noreply, map()}
```

Called with raw Erlang messages (e.g., from `send/2`, `Process.send_after/3`).

### `terminate/2` (optional)

Called on shutdown. No required return shape.

## State Helpers

Imported by `use Courgette.LiveComponent`:

- `assign(assigns, map_or_keyword)` — merge key-value pairs
- `assign(assigns, key, value)` — set one key
- `assign_new(assigns, key, fun)` — set only if absent
- `update(assigns, key, fun)` — apply function to existing key

## Common Mistakes

- **Wrong return shape from mount:** `mount/1` returns `{:ok, assigns}`, not bare assigns.
- **Wrong return shape from handle_event:** Must return `{:noreply, assigns}`, not `{:ok, assigns}`.
- **Missing catch-all in handle_event:** Unmatched events crash the component. Always add `def handle_event(_event, assigns), do: {:noreply, assigns}`.
