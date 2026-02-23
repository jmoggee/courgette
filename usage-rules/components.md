# Components

## LiveComponent (Stateful)

Process-backed components with their own state and lifecycle.

```elixir
defmodule MyApp.Counter do
  use Courgette.LiveComponent

  def mount(_assigns), do: {:ok, %{count: 0}}

  def render(assigns) do
    box border: :rounded do
      text(do: "Count: #{assigns.count}")
    end
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, update(assigns, :count, &(&1 + 1))}
  end

  def handle_event(_event, assigns), do: {:noreply, assigns}
end
```

### Callbacks

| Callback | Required | Returns |
|----------|----------|---------|
| `mount/1` | yes | `{:ok, assigns}` |
| `render/1` | yes | `Element.t()` |
| `update/2` | no | `{:ok, assigns}` |
| `handle_event/2` | no | `{:noreply, assigns}` |
| `handle_info/2` | no | `{:noreply, assigns}` |
| `terminate/2` | no | any |

### State Helpers

```elixir
assign(assigns, %{key: value})    # merge map
assign(assigns, key: value)       # merge keyword
assign(assigns, :key, value)      # set one key
assign_new(assigns, :key, fn -> default end)
update(assigns, :key, &(&1 + 1))
```

## Function Component (Stateless)

No process, no state. Pure function from assigns to element tree.

```elixir
defmodule MyApp.UI do
  use Courgette.Component

  attr :name, :string, default: "World"
  attr :color, :atom, default: :green

  def greeting(assigns) do
    assigns = assigns(assigns)

    text color: assigns.color do
      "Hello, #{assigns.name}!"
    end
  end
end
```

### Key Functions

- `assigns(keyword)` — converts keyword list to map with defaults applied. Call at the top of every function component.
- `theme(assigns, :token)` — looks up a semantic color from the theme in assigns. Falls back to `Theme.default()`.
- `render_slot(assigns.slot_name)` — renders a slot's content as a list of elements.
- `attr/3` — declares an attribute: `attr :name, :type, opts`. Types: `:string`, `:atom`, `:integer`, `:float`, `:boolean`, `:list`, `:map`, `:any`.
- `slot/1,2` — declares a slot for passing child elements.

## Using `live_component/2`

Embed a stateful child inside a parent's `render/1`:

```elixir
def render(assigns) do
  box do
    live_component(Counter, id: "main", initial_count: 5)
    live_component(Counter, id: "other", focusable: true)
  end
end
```

- `:id` is **required** — used for lifecycle reconciliation as `{module, id}`.
- `:focusable` — set to `true` to include in Tab-cycling focus order.
- All other options are passed as props to `mount/1` (first render) or `update/2` (re-render).

## Child-to-Parent Communication

Children notify parents via `send/2`:

```elixir
# In child's handle_event:
send(assigns.parent_pid, {:counter_changed, assigns.count})

# In parent's handle_info:
def handle_info({:counter_changed, count}, assigns) do
  {:noreply, assign(assigns, :child_count, count)}
end
```

`assigns.parent_pid` is automatically set by the runtime for child components.

## Reconciliation

The runtime matches children by `{module, id}` key:

- **Same key, new props** → calls `update/2` on the existing child
- **New key** → starts a new child process via `mount/1`
- **Removed key** → stops the child process

This means:
- IDs must be unique per module within a parent
- Changing the `:id` prop destroys and recreates the component
- The order of `live_component` calls determines focus order

## Common Mistakes

- **Forgetting `:id`** on `live_component/2` — will raise at runtime.
- **Non-unique IDs** within the same module — causes child conflicts.
- **Returning `{:noreply, assigns}` from `mount/1`** — mount must return `{:ok, assigns}`.
- **Calling `assigns/1` in a LiveComponent** — `assigns/1` is for function components only. LiveComponents receive assigns as a map directly.
