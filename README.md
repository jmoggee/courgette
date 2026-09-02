> [!WARNING]
> This project is a work in progress. APIs may change without notice.

# Courgette

[![Hex.pm](https://img.shields.io/hexpm/v/courgette.svg)](https://hex.pm/packages/courgette)
[![Hexdocs](https://img.shields.io/badge/hexdocs-courgette-blue.svg)](https://hexdocs.pm/courgette)
[![License](https://img.shields.io/hexpm/l/courgette.svg)](https://github.com/LoamStudios/courgette/blob/main/LICENSE)

A declarative TUI framework for Elixir, built on OTP.

Courgette gives you a component model inspired by Phoenix LiveView — stateful
components with `mount`, `render`, and `handle_event` callbacks — but targeting
the terminal instead of the browser. Layout uses a CSS inspired Flexbox engine.
Rendering is incremental via double-buffered diffing.

## Quick Start

```elixir
defmodule HelloApp do
  use Courgette.App

  def mount(_assigns), do: {:ok, %{count: 0}}

  def render(assigns) do
    box border: :rounded, padding: 1 do
      text color: :cyan, bold: true do
        "Count: #{assigns.count}"
      end
    end
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

Courgette.run(HelloApp)
```

## Installation

> [!WARNING]
> v0.1.0 has not been released yet.

Add `courgette` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:courgette, "~> 0.1.0"}
  ]
end
```

Then `mix deps.get`.

## Features

- **Declarative DSL** — `box`, `text`, `input`, and friends compose into element
  trees, just like HEEx templates but for terminal output
- **Stateful components** — `use Courgette.LiveComponent` gives you `mount/1`,
  `render/1`, `handle_event/2`, and `handle_info/2` backed by a GenServer
- **Function components** — `use Courgette.Component` for stateless, reusable
  UI functions with declared attributes and slots
- **CSS Flexbox layout** — `flex_direction`, `flex_grow`, `justify_content`,
  `align_items`, `gap`, `min_width`/`max_width`, and more
- **Incremental rendering** — double-buffered diff produces minimal ANSI escape
  sequences at ~60 FPS
- **Input handling** — full keyboard (including Kitty protocol), mouse (SGR),
  bracketed paste, focus tracking, and resize events
- **Focus management** — Tab/Shift-Tab cycling with auto-focus, event bubbling
- **Theming** — semantic color tokens (`primary`, `danger`, `muted`, etc.)
  referenced by components instead of hard-coded colors
- **Animation** — tweens with easing functions and frame-based spinners
- **Built-in components** — `TextInput`, `Textarea`, `Select`, `Spinner`,
  `ProgressBar`, plus utility components (`badge`, `heading`, `divider`,
  `key_value`, `empty_state`)
- **Test helpers** — headless renderer for fast, deterministic component tests
- **Zero dependencies** — pure Elixir/OTP, no NIFs, no C bindings

## Components

### Live Components (Stateful)

Live components are process-backed and manage their own state:

```elixir
defmodule Counter do
  use Courgette.LiveComponent

  def mount(_assigns) do
    {:ok, %{count: 0}}
  end

  def render(assigns) do
    box border: :rounded do
      text do
        "Count: #{assigns.count}"
      end
    end
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, update(assigns, :count, &(&1 + 1))}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    {:noreply, update(assigns, :count, &(&1 - 1))}
  end

  def handle_event(_event, assigns), do: {:noreply, assigns}
end
```

Embed a live component inside another component's render:

```elixir
live_component(Counter, id: "main", initial_count: 5)
```

### Function Components (Stateless)

Function components are pure functions with declared attributes:

```elixir
defmodule MyComponents do
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

### Built-in Components

```elixir
import Courgette.Components

badge(label: "OK", color: :green)
heading(text: "Dashboard")
divider(orientation: :horizontal)
key_value(label: "Status", value: "Running")
empty_state(message: "No items found")
```

Interactive components are live components:

- `Courgette.Components.TextInput` — single-line text input with cursor and Ctrl shortcuts
- `Courgette.Components.Textarea` — multi-line text area with scrolling
- `Courgette.Components.Select` — dropdown-style selector with arrow navigation
- `Courgette.Components.Spinner` — animated loading indicator (20+ styles)
- `Courgette.Components.ProgressBar` — animated progress bar with labels

## Layout

Courgette uses a port of the [taffy engine](https://lib.rs/crates/taffy) for
layout. It's been adapted for terminal layouts.

Style props go directly on elements:

```elixir
box flex_direction: :row, gap: 1 do
  box flex_grow: 1, border: :single, padding: 1 do
    text do: "Sidebar"
  end

  box flex_grow: 3, border: :rounded, padding: 1 do
    text do: "Main content"
  end
end
```

Supported layout props include: `flex_direction`, `flex_wrap`, `flex_grow`,
`flex_shrink`, `flex_basis`, `justify_content`, `align_items`, `align_content`,
`align_self`, `gap`, `width`, `height`, `min_width`, `max_width`, `min_height`,
`max_height`, `padding`, `padding_h`, `padding_v`, `margin`, `margin_h`,
`margin_v`, `border`, `border_color`, `overflow`.

## Theming

Components reference semantic tokens rather than hard-coding colors:

```elixir
color = theme(assigns, :primary)   # :blue from default theme
muted = theme(assigns, :muted)     # :bright_black

text color: color, do: "Important"
```

Default tokens: `bg`, `fg`, `primary`, `secondary`, `success`, `warning`,
`danger`, `muted`, `border`, `surface`.

Custom themes are maps from token names to color values (named atoms, 0-255
integers, or `{r, g, b}` tuples).

## Animation

### Tweens

Interpolate values over time with easing:

```elixir
def mount(_assigns) do
  tween = Tween.new(0, 100, duration: 500, easing: :ease_out)
  {:ok, %{tween: tween} |> Tween.start_timer()}
end

def handle_info(:tween_tick, assigns) do
  case Tween.step(assigns.tween) do
    {:running, value, tween} ->
      {:noreply, assigns |> assign(tween: tween, progress: value) |> Tween.start_timer()}
    {:done, value} ->
      {:noreply, assigns |> assign(progress: value) |> Tween.stop_timer()}
  end
end
```

Easing functions: `linear`, `ease_in`, `ease_out`, `ease_in_out`,
`ease_in_cubic`, `ease_out_cubic`, `bounce_out`.

### Frame-based Animation

For spinners and cyclic animations:

```elixir
live_component(Courgette.Components.Spinner, id: "loading", style: :dots)
```

## Testing

Courgette includes headless test helpers that run the full component lifecycle
without a real terminal:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  use Courgette.ComponentTestHelpers

  test "renders initial state" do
    view = mount(MyApp)
    assert render_text(view) =~ "Count: 0"
  end

  test "handles keyboard events" do
    view = mount(MyApp)
    send_event(view, {:key, :arrow_up})
    assert render_text(view) =~ "Count: 1"
  end

  test "tab cycles focus" do
    view = mount(MyApp, width: 80, height: 24)
    send_tab(view)
    tree = render_tree(view)
    # assert on tree structure
  end
end
```

## Architecture

The rendering pipeline flows in one direction:

```
Element Tree → Layout (Flexbox) → Paint (Buffer) → Diff → ANSI → Terminal
```

1. Components return **element trees** — pure data describing what to render
2. The **layout engine** computes absolute positions and sizes using Flexbox
3. The **painter** fills a 2D cell buffer with styled graphemes
4. The **diff** compares front and back buffers to find changed cells
5. The **writer** emits minimal ANSI escape sequences for the changes
6. The **terminal** writes to stdout inside synchronized output markers

The renderer runs at ~60 FPS with frame batching — multiple state changes between
ticks are collapsed into a single render.

See the [Architecture Guide](guides/architecture.md) for a deep dive.

## Demos

18 runnable examples are included in `examples/`:

```bash
# Terminal + key parser demo
mix run examples/key_parser.exs

# Interactive counter (minimal live app)
mix run examples/counter.exs

# Full task tracker app exercising all components
mix run examples/task_tracker.exs
```

See the full list with `ls examples/`.

## License

MIT
