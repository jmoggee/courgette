# Testing

## Setup

```elixir
# test/test_helper.exs
Application.put_env(:courgette, :animations_enabled, false)
ExUnit.start()
```

In each test module:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  use Courgette.ComponentTestHelpers

  # ...
end
```

## Test Helpers

### `mount/1,2`

Start a component in a headless environment (no real terminal).

```elixir
view = mount(MyApp)
view = mount(MyApp, width: 120, height: 40, initial_assigns: %{items: []})
```

Options:
- `:width` — buffer width (default 80)
- `:height` — buffer height (default 24)
- `:initial_assigns` — map passed to `mount/1` (default `%{}`)

Returns a view handle used by all other helpers.

### `send_event/2`

Send a parsed event directly to the component. Synchronous — returns after the event is fully processed.

```elixir
send_event(view, {:key, {:char, "a"}})
send_event(view, {:key, :enter})
send_event(view, {:key, {:ctrl, "c"}})
```

### `send_tab/1` / `send_shift_tab/1`

Convenience for focus cycling:

```elixir
send_tab(view)        # sends {:key, :tab}
send_shift_tab(view)  # sends {:key, {:shift, :tab}}
```

### `send_info/2`

Send a raw Erlang message to the component's `handle_info/2`. Synchronous.

```elixir
send_info(view, {:name_changed, "Alice"})
```

### `render_text/1`

Extract all visible text from the last rendered tree. Walks depth-first, joins with spaces.

```elixir
assert render_text(view) =~ "Hello"
assert render_text(view) =~ "Count: 5"
```

### `render_tree/1`

Get the raw `Element.t()` tree for structural assertions.

```elixir
tree = render_tree(view)
assert tree.type == :box
assert length(tree.children) == 3
```

## Complete Test Example

```elixir
defmodule CounterTest do
  use ExUnit.Case
  use Courgette.ComponentTestHelpers

  defmodule Counter do
    use Courgette.App

    def mount(_assigns), do: {:ok, %{count: 0}}

    def render(assigns) do
      text(do: "Count: #{assigns.count}")
    end

    def handle_event({:key, :arrow_up}, assigns) do
      {:noreply, update(assigns, :count, &(&1 + 1))}
    end

    def handle_event(_event, assigns), do: {:noreply, assigns}
  end

  test "renders initial state" do
    view = mount(Counter)
    assert render_text(view) =~ "Count: 0"
  end

  test "increments on arrow up" do
    view = mount(Counter)
    send_event(view, {:key, :arrow_up})
    assert render_text(view) =~ "Count: 1"
  end

  test "ignores unknown keys" do
    view = mount(Counter)
    send_event(view, {:key, {:char, "x"}})
    assert render_text(view) =~ "Count: 0"
  end
end
```

## Key Notes

- **All helpers are synchronous.** After `send_event` or `send_info` returns, the component has finished processing and re-rendering.
- **`render_text/1` joins depth-first.** It collects all string children from the element tree, so nested text elements are flattened.
- **No real terminal is involved.** Tests use a headless renderer — no raw mode, no ANSI output.
- **Animations should be disabled** in `test_helper.exs` to avoid timers and flaky tests.
