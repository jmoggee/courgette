# Architecture

This guide walks through Courgette's internals — how element trees become
terminal output, how components manage state, and how the pieces fit together.

## Process Topology

A running Courgette app has three long-lived processes:

```
Terminal (GenServer)
  ├── input reader (linked Task)
  └── signal handler (SIGWINCH)

Renderer (GenServer)
  └── tick timer (~16ms)

Server (GenServer)
  └── child component servers (one per live_component)
```

`Courgette.run/2` starts them in order (Terminal → Renderer → Server), wires
input from Terminal to Server, then blocks on a monitor until the Server exits.

## The Render Cycle

Every render follows the same five-stage pipeline:

```
Element Tree → Layout → Paint → Diff → Write
```

### 1. Element Tree

Components produce element trees — nested `%Element{}` structs describing
*what* to render, not *where*. Trees are pure data with no position or size
information.

```elixir
%Element{
  type: :box,
  props: %{border: :rounded, padding: 1},
  children: [
    %Element{type: :text, props: %{color: :cyan}, children: ["Hello"]}
  ]
}
```

Element types: `:box`, `:text`, `:grid`, `:col`, `:scrollable_area`,
`:button`, `:input`, `:live_component`.

### 2. Layout (Flexbox)

`Engine.compute/2` takes an element tree and a bounding rectangle, then runs
a CSS Flexbox algorithm to assign every node absolute `{x, y, width, height}`
coordinates. The implementation follows the CSS spec's 15-step algorithm and
uses [Taffy](https://github.com/DioxusLabs/taffy) as a correctness reference
(with `mix taffy.generate` to auto-translate test fixtures).

Key capabilities:

- **Flex direction** — `:row` (default) and `:column`
- **Flex wrapping** — `:wrap` and `:nowrap`
- **Flex sizing** — `flex_grow`, `flex_shrink`, `flex_basis`
- **Alignment** — `justify_content`, `align_items`, `align_content`, `align_self`
- **Gaps** — `gap` for spacing between flex items
- **Constraints** — `min_width`, `max_width`, `min_height`, `max_height`
- **Content sizing** — automatic minimum sizes based on text content
- **Overflow** — `:visible`, `:hidden`
- **Text wrapping** — `white_space` (`:normal`, `:nowrap`), `overflow_wrap` (`:normal`, `:break_word`)
- **Scrollable areas** — unlimited height with content-driven width

The output is a layout tree where each node is `{element, bounds, children}`.

### 3. Paint

`Painter.paint/2` traverses the layout tree and writes into a `Buffer` — a
dense 2D grid of `Cell` structs. Each cell holds a grapheme plus optional
foreground/background colors and style flags.

Painting handles:
- **Backgrounds** — fill the element's bounds with its `bg` color
- **Borders** — draw box-drawing characters (`:single`, `:double`, `:rounded`)
- **Text** — place one grapheme per cell, applying colors and styles
- **Clipping** — children that extend beyond their parent's bounds are not painted
- **Scroll offset** — scrollable areas apply a Y offset before painting children

### 4. Diff

`Diff.diff/2` compares the front buffer (what's on screen) with the back
buffer (what we just painted). It produces a list of `Run` structs —
consecutive sequences of changed cells at known positions.

Only cells that actually changed get emitted. If the user just moved cursor
focus and one cell changed from `>` to ` `, only that cell is in the diff.

### 5. Write

`Writer.render/1` converts runs into ANSI escape sequences. It tracks SGR
state across cells to skip redundant color/style codes. The output is wrapped
in synchronized output markers (`\e[?2026h` / `\e[?2026l`) to prevent tearing
on terminals that support it.

## Frame Batching

The Renderer runs a tick loop at ~60 FPS (16ms intervals). When a component's
state changes:

1. Server calls `Renderer.push(tree, renderer)` with the new element tree
2. Renderer marks itself dirty but doesn't render yet
3. On the next tick, if dirty, the full pipeline runs
4. Multiple pushes between ticks are collapsed — only the last tree renders

This means rapid state changes (like typing) don't cause redundant renders.

In headless mode (tests), the tick loop is disabled and pushes render
immediately for deterministic test behavior.

## Component Lifecycle

### Function Components

Stateless. A module that `use`s `Courgette.Component` defines public functions
that take a keyword list and return element trees. Attributes are declared
with `attr/3` and validated at compile time.

```
attr declarations → compile-time validation → function call → element tree
```

### Live Components

Stateful, process-backed. Each live component instance runs in a GenServer.

```
mount/1 → render/1 → [handle_event/2 | handle_info/2 → render/1]*
```

**Lifecycle:**

1. **`mount/1`** — called once with initial assigns. Returns `{:ok, assigns}`.
2. **`render/1`** — called after mount and after every state change. Returns
   an element tree.
3. **`handle_event/2`** — called with parsed input events (keyboard, mouse,
   focus). Returns `{:noreply, assigns}`.
4. **`handle_info/2`** — called with raw Erlang messages (timers, external
   processes). Returns `{:noreply, assigns}`.
5. **`update/2`** — called when a parent re-renders with new props. Receives
   the new props and current assigns. Optional (default merges props).
6. **`terminate/2`** — called on shutdown. Optional.

### Child Components and Reconciliation

When a parent's `render/1` includes `live_component(Module, id: "x")`, the
Server reconciles children:

- **New children** are started (mount → render)
- **Existing children** receive updated props (update → render)
- **Removed children** are stopped (terminate)

The `id` prop is required and used for stable identity across re-renders.

## Focus Management

`FocusManager` is a pure data structure (no processes) that tracks which child
component has focus. The root Server holds one in its state.

- Tab → `focus_next/1` (wraps around)
- Shift-Tab → `focus_prev/1` (wraps around)
- First child is auto-focused on mount

Focus determines which child receives keyboard events. Events bubble up —
if the focused child doesn't handle an event, the parent gets it.

## Input Pipeline

```
stdin → Terminal reader process → KeyParser.parse/2 → Server → Component
```

1. A linked process blocks on `IO.getn/2` reading raw bytes
2. `KeyParser.parse/2` is a pure function that converts byte sequences to
   structured events: `{:key, value}`, `{:mouse, ...}`, `{:focus, ...}`,
   `{:paste, ...}`
3. The parser handles UTF-8 multi-byte sequences, CSI sequences, SS3
   sequences, Kitty keyboard protocol, SGR mouse protocol, and bracketed paste
4. An escape key timeout (50ms) distinguishes a lone ESC press from the
   start of an escape sequence

## Terminal Management

The Terminal GenServer manages the raw terminal lifecycle:

**Startup:**
- Enable raw mode (no echo, no line buffering)
- Detect color capability (truecolor, 256-color, basic, or none)
- Enter alternate screen buffer (fullscreen mode)
- Hide cursor
- Enable focus event reporting
- Enable bracketed paste mode
- Register SIGWINCH handler for resize detection

**Shutdown (guaranteed via `ensure` pattern):**
- Show cursor
- Exit alternate screen
- Reset all colors and styles
- Restore terminal mode

The terminal is always restored cleanly, even on crash.

## Buffer System

`Buffer` is a map from `{col, row}` coordinates to `Cell` structs.

A `Cell` contains:
- `grapheme` — a single visible character (or `nil` for empty)
- `fg` — foreground color (named atom, 0-255 integer, or `{r, g, b}` tuple)
- `bg` — background color (same types)
- `style` — sparse map of style flags (`:bold`, `:italic`, `:underline`,
  `:strikethrough`, `:dim`, `:inverse`, `:underline_style`, `:underline_color`)

Colors support three modes, auto-detected from the terminal:
- **Truecolor** — `{r, g, b}` tuples, 16 million colors
- **256-color** — integers 0-255
- **Basic** — named atoms (`:red`, `:bright_cyan`, etc.)

## Theming

`Theme` maps semantic token names to color values:

```elixir
%Theme{
  name: "default",
  tokens: %{
    bg: :black, fg: :white,
    primary: :blue, secondary: :cyan,
    success: :green, warning: :yellow, danger: :red,
    muted: :bright_black, border: :white, surface: :bright_black
  }
}
```

Components call `theme(assigns, :primary)` instead of hard-coding `:blue`.
The theme flows through assigns — a parent can set `:theme` to propagate
a custom palette to all children.

## Animation System

Two animation primitives:

**Tweens** (`Animation.Tween`) — interpolate a numeric value from A to B over
a duration with an easing function. Uses wall clock time (injectable for
tests). Timer helpers manage `Process.send_after` for 16ms tick messages.

**Frames** (`Animation.Frames`) — cycle through a list of strings at a fixed
interval. Used by the Spinner component. Includes 20+ built-in frame sets
from cli-spinners.

Both integrate with `handle_info/2` for the animation loop.
