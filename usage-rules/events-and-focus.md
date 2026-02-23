# Events & Focus

## Event Tuple Reference

All events are tuples. The first element identifies the category.

### Key Events

```elixir
{:key, {:char, "a"}}             # Printable character
{:key, :enter}                    # Enter key
{:key, :tab}                      # Tab
{:key, :escape}                   # Escape
{:key, :backspace}                # Backspace
{:key, :delete}                   # Delete
{:key, :arrow_up}                 # Arrow keys
{:key, :arrow_down}
{:key, :arrow_left}
{:key, :arrow_right}
{:key, :home}                     # Home
{:key, :end}                      # End
{:key, :page_up}                  # Page Up/Down
{:key, :page_down}
{:key, :insert}                   # Insert
{:key, :f1} .. {:key, :f12}      # Function keys
```

### Modifiers

```elixir
{:key, {:ctrl, "c"}}             # Ctrl + letter (lowercase string)
{:key, {:alt, "x"}}              # Alt + character
{:key, {:shift, :tab}}           # Shift + Tab

# Kitty/xterm extended modifiers (list form):
{:key, :arrow_up, [:shift]}      # Shift + Arrow
{:key, :arrow_up, [:ctrl]}       # Ctrl + Arrow
{:key, :arrow_up, [:alt, :shift]} # Alt + Shift + Arrow
```

### Mouse Events

```elixir
{:mouse, :press, :left, col, row}         # Click (1-indexed)
{:mouse, :release, :left, col, row}       # Release
{:mouse, :press, :left, col, row, [:ctrl]} # Modified click
{:mouse, :scroll_up, col, row}            # Scroll
{:mouse, :scroll_down, col, row}
```

### Focus Events

```elixir
{:focus, :in}                     # Terminal gained focus
{:focus, :out}                    # Terminal lost focus
```

### Paste Events

```elixir
{:paste, :start}                  # Bracketed paste begin
{:paste, :end}                    # Bracketed paste end
```

## `handle_event/2`

Pattern match on events. Always include a catch-all:

```elixir
def handle_event({:key, {:char, "q"}}, _assigns) do
  Courgette.stop()
  {:noreply, %{}}
end

def handle_event({:key, :arrow_up}, assigns) do
  {:noreply, update(assigns, :selected, &max(&1 - 1, 0))}
end

def handle_event(_event, assigns), do: {:noreply, assigns}
```

## Focus System

### Declaring Focusable Components

Set `focusable: true` when embedding a live component:

```elixir
live_component(TextInput, id: "name", focusable: true)
live_component(TextInput, id: "email", focusable: true)
```

### Focus Cycling

- **Tab** advances to the next focusable child (wraps around)
- **Shift-Tab** moves to the previous focusable child (wraps around)
- First focusable child is auto-focused on mount

### Focus/Blur Events

Focused components receive `:focus` and `:blur` atoms (not tuples) via `handle_event/2`:

```elixir
def handle_event(:focus, assigns) do
  {:noreply, assign(assigns, :focused, true)}
end

def handle_event(:blur, assigns) do
  {:noreply, assign(assigns, :focused, false)}
end
```

### Event Routing

1. If the root has focusable children, key events go to the **focused child** first
2. Tab/Shift-Tab are intercepted by the parent for focus cycling
3. Events not handled by children bubble up to the parent's `handle_event/2`

## Child-to-Parent Messaging

Children cannot return messages to parents through callbacks. Use `send/2`:

```elixir
# In child:
def handle_event({:key, :enter}, assigns) do
  send(assigns.parent_pid, {:submitted, assigns.value})
  {:noreply, assigns}
end

# In parent:
def handle_info({:submitted, value}, assigns) do
  {:noreply, assign(assigns, :result, value)}
end
```

## Common Mistakes

- **Matching `:focus`/`:blur` as key events:** Focus events are bare atoms, not `{:key, :focus}`.
- **Wrong Ctrl tuple nesting:** It's `{:key, {:ctrl, "c"}}` with a lowercase string, not `{:key, {:ctrl, :c}}`.
- **Forgetting catch-all:** Missing catch-all in `handle_event/2` crashes on any unmatched event.
- **Not setting `focusable: true`:** Without it, the child won't receive `:focus`/`:blur` or be included in Tab cycling.
