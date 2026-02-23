# DSL & Layout

## Element Macros

Available macros: `box`, `text`, `grid`, `col`, `scrollable_area`, `button`, `input`

### Syntax Forms

```elixir
# No args
box()

# Props only (no children)
input(placeholder: "Type...")

# Do-block with children
box padding: 2, border: :single do
  text color: :cyan do
    "Hello"
  end
end

# Inline do: shorthand
text color: :green, do: "Hello"
```

### Children

Children in `do` blocks are collected into a flat list. `nil` values are filtered out, enabling conditional rendering:

```elixir
box do
  if show_header do
    text(do: "Header")
  end

  for item <- items do
    text(do: item.name)
  end
end
```

### `live_component/2`

```elixir
live_component(Counter, id: "main", count: 5, focusable: true)
```

Creates a `:live_component` element. `:id` is required.

## Flexbox Layout Props

All elements support these layout props. The engine follows the CSS Flexbox spec.

### Direction & Wrapping

| Prop | Values | Default |
|------|--------|---------|
| `flex_direction` | `:row`, `:column` | `:row` |
| `flex_wrap` | `:no_wrap`, `:wrap` | `:no_wrap` |

### Flex Sizing

| Prop | Description | Default |
|------|-------------|---------|
| `flex` | Shorthand: sets `flex_grow: N, flex_shrink: 1, flex_basis: 0` | — |
| `flex_grow` | Growth factor | `0` |
| `flex_shrink` | Shrink factor | `1` |
| `flex_basis` | Base size (number or `:auto`) | `:auto` |

### Alignment

| Prop | Values | Default |
|------|--------|---------|
| `justify_content` | `:flex_start`, `:flex_end`, `:center`, `:space_between`, `:space_around`, `:space_evenly` | `:flex_start` |
| `align_items` | `:flex_start`, `:flex_end`, `:center`, `:stretch`, `:baseline` | `:stretch` |
| `align_self` | `:auto`, `:flex_start`, `:flex_end`, `:center`, `:stretch`, `:baseline` | `:auto` |
| `align_content` | `:flex_start`, `:flex_end`, `:center`, `:stretch`, `:space_between`, `:space_around` | `:stretch` |

### Sizing

| Prop | Type | Description |
|------|------|-------------|
| `width` / `height` | number | Fixed size in cells |
| `min_width` / `min_height` | number | Minimum size |
| `max_width` / `max_height` | number | Maximum size |

### Spacing

| Prop | Description |
|------|-------------|
| `padding` | All sides |
| `padding_h` | Left + right |
| `padding_v` | Top + bottom |
| `padding_left`, `padding_right`, `padding_top`, `padding_bottom` | Individual sides |
| `margin` | All sides |
| `margin_left`, `margin_right`, `margin_top`, `margin_bottom` | Individual sides |
| `gap` | Both main and cross axis |
| `gap_main`, `gap_cross` | Individual axes |

### Border

| Prop | Values |
|------|--------|
| `border` | `:single`, `:double`, `:rounded` |
| `border_color` | Any color value |

Borders consume 1 cell of inset on each side.

## Text Styling Props

These props apply to `text` elements:

| Prop | Type | Description |
|------|------|-------------|
| `color` or `fg` | color | Foreground color |
| `bg` | color | Background color |
| `bold` | boolean | Bold text |
| `italic` | boolean | Italic text |
| `dim` | boolean | Dim/faint text |
| `underline` | boolean | Underlined text |
| `strikethrough` | boolean | Strikethrough text |
| `reverse` | boolean | Swap fg/bg |

### Color Values

- Named atoms: `:black`, `:red`, `:green`, `:yellow`, `:blue`, `:magenta`, `:cyan`, `:white`
- Bright variants: `:bright_black`, `:bright_red`, etc.
- 256-color: integer `0..255`
- True color: `{r, g, b}` tuple

### Text Overflow

| Prop | Values | Default |
|------|--------|---------|
| `overflow` | `:visible`, `:hidden` | `:visible` |
| `white_space` | `:normal`, `:nowrap` | `:normal` |
| `overflow_wrap` | `:normal`, `:break_word` | `:normal` |
| `text_overflow` | `:clip`, `:ellipsis` | `:clip` |

## Theme Tokens

Use `theme(assigns, :token)` to look up semantic colors:

| Token | Default Color |
|-------|--------------|
| `:bg` | `:black` |
| `:fg` | `:white` |
| `:primary` | `:blue` |
| `:secondary` | `:cyan` |
| `:success` | `:green` |
| `:warning` | `:yellow` |
| `:danger` | `:red` |
| `:muted` | `:bright_black` |
| `:border` | `:white` |
| `:surface` | `:bright_black` |

## Common Mistakes

- **Text styling on `box`:** Props like `bold`, `italic`, `color` are only applied by `text` elements. To style text inside a box, wrap it in a `text` element.
- **`color` vs `border_color`:** `color`/`fg` set text foreground. Use `border_color` for border color, `bg` for background.
- **Children on `text`:** Text elements expect string children, not nested elements. Use `box` for nesting.
