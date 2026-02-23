# Built-in Components

## Live Components (Stateful)

### TextInput

Single-line text input with cursor. `use Courgette.Components.TextInput`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `value` | string | `""` | Initial text |
| `placeholder` | string | `""` | Shown when empty and unfocused |
| `on_change` | atom | nil | Message tag sent on every edit |
| `on_submit` | atom | nil | Message tag sent on Enter |

Sends to parent: `{on_change, value}` and `{on_submit, value}`.

### Textarea

Multi-line text editor with cursor, scrolling, and readline shortcuts.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `value` | string | `""` | Initial text (may contain `\n`) |
| `placeholder` | string | `""` | Shown when empty and unfocused |
| `on_change` | atom | nil | Message tag sent on every edit |
| `height` | integer | `10` | Total height including border |

Sends to parent: `{on_change, value}`.

### Select

Navigable option picker. Arrow keys move selection, Enter confirms.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `options` | list | `[]` | Strings or `{value, label}` tuples |
| `selected` | integer | `0` | Initial selected index |
| `on_select` | atom | nil | Message tag sent on Enter |
| `prompt` | string | nil | Text shown above options |

Sends to parent: `{on_select, value}`.

### Spinner

Animated activity indicator. Self-ticking, no keyboard interaction.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `style` | atom | `:dots` | Frame set (see below) |
| `frames` | Frames.t() | nil | Custom frames (overrides style) |
| `label` | string | nil | Text after spinner |
| `color` | atom | `:cyan` | Spinner color |
| `interval` | integer | `80` | Tick interval in ms |

Styles: `:dots`, `:dots_pulse`, `:dots_orbit`, `:dots_scroll`, `:dots_bounce`, `:sand`, `:circle`, `:arc`, `:triangle`, `:wave`, `:pulse`, `:meter`, `:line`, `:star`, `:point`, `:bounce`, `:arrow`, `:ellipsis`, and more.

### ProgressBar

Determinate progress bar. Parent controls progress via props.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `value` | float | `0.0` | Progress 0.0–1.0 |
| `width` | integer | `20` | Bar width in cells |
| `color` | atom | `:cyan` | Fill color |
| `bg_color` | atom | `:white` | Empty color |
| `label` | atom | nil | `:percent` to show percentage |

## Function Components (Stateless)

Import with `import Courgette.Components`.

### badge

```elixir
badge(label: "OK", color: :green)
```

Props: `label` (string), `color` (atom, defaults to theme `:primary`).

### heading

```elixir
heading(text: "Dashboard", color: :cyan, divider: false)
```

Props: `text` (string), `color` (atom, defaults to theme `:primary`), `divider` (boolean, default `true`).

### divider

```elixir
divider(orientation: :horizontal, color: :cyan)
```

Props: `orientation` (`:horizontal` or `:vertical`, default `:horizontal`), `color` (atom, defaults to theme `:muted`).

### key_value

```elixir
key_value(label: "Name", value: "Jeff")
```

Props: `label` (string), `value` (string).

### empty_state

```elixir
empty_state(message: "No items found")
```

Props: `message` (string, default `"Nothing to show"`).

## Usage Example

```elixir
defmodule MyApp do
  use Courgette.App

  def mount(_assigns) do
    {:ok, %{name: "", status: :idle}}
  end

  def render(assigns) do
    import Courgette.Components

    box flex_direction: :column, padding: 1 do
      heading(text: "Form")

      live_component(Courgette.Components.TextInput,
        id: "name",
        placeholder: "Enter name",
        on_change: :name_changed,
        focusable: true
      )

      badge(label: to_string(assigns.status), color: :cyan)
    end
  end

  def handle_info({:name_changed, value}, assigns) do
    {:noreply, assign(assigns, :name, value)}
  end

  def handle_event(_event, assigns), do: {:noreply, assigns}
end
```

## Common Mistakes

- **Forgetting `focusable: true`** on TextInput/Textarea/Select — without it the component won't receive focus or keyboard events.
- **Not handling messages from children** — TextInput with `on_change: :name_changed` sends `{:name_changed, value}` to the parent's `handle_info/2`, not `handle_event/2`.
- **Using `:color` for Spinner** — Spinner uses `:fg` internally, but the prop is `:color`.
