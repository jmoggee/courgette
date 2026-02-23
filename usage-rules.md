# Courgette Usage Rules

Courgette is a declarative TUI framework for Elixir built on OTP. Zero runtime dependencies.

**Pipeline:** `Component render/1 → Element Tree → Layout (Flexbox) → Paint (Buffer) → Diff → ANSI → Terminal`

## Core Conventions

- Root apps use `use Courgette.App`; children use `use Courgette.LiveComponent`
- Assigns are maps internally. Public APIs accept keyword lists.
- DSL macros (`box`, `text`, `input`, etc.) build pure-data element trees
- `live_component(Module, id: "unique")` — the `:id` is required
- Events are tuples: `{:key, {:char, "a"}}`, `{:key, :enter}`, `{:key, {:ctrl, "c"}}`
- Focus: set `focusable: true` on `live_component`; Tab/Shift-Tab cycles focus
- Children notify parents via `send(assigns.parent_pid, {tag, value})`

## Sub-rules

- [App & Lifecycle](usage-rules/app-and-lifecycle.md) — run/stop, callbacks, return shapes
- [Components](usage-rules/components.md) — LiveComponent vs Component, reconciliation
- [DSL & Layout](usage-rules/dsl-and-layout.md) — element macros, flexbox props, styling
- [Events & Focus](usage-rules/events-and-focus.md) — event tuples, focus routing
- [Built-in Components](usage-rules/built-in-components.md) — TextInput, Select, Spinner, etc.
- [Animation](usage-rules/animation.md) — Tween, Frames, Easing, timer patterns
- [Testing](usage-rules/testing.md) — ComponentTestHelpers, headless testing
