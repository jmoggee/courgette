# CSS Flexbox Compliance

Courgette implements CSS Flexbox layout following the [CSS Flexible Box Layout Module Level 1](https://www.w3.org/TR/css-flexbox-1/) spec. Correctness is verified against [Taffy](https://github.com/DioxusLabs/taffy), a Rust flexbox engine with browser-generated test fixtures.

**Score: 262/262 active Taffy tests passing (275 skipped, 537 total)**

## Reference pipeline

Taffy ships 537 test fixtures generated from browser rendering. Each fixture defines an element tree with specific flex properties and asserts exact pixel positions/sizes. Our `mix taffy.generate` task parses the Rust fixture files and emits ExUnit tests. Tests using unsupported CSS features are tagged `@tag :skip` with the reason.

## Feature table

| CSS Property | Values | Status | Taffy tests skipped | Notes |
|---|---|---|---|---|
| **display** | `flex` | Supported | — | Only layout mode |
| | `inline-flex` | Not supported | — | Not relevant for TUI (no inline flow context) |
| | `none` | Not supported | 8 | Would hide element and children from layout |
| | `block` | Not supported | 2 | Taffy supports it; not needed for TUI (flex covers all cases) |
| | `grid` | Not supported | 4 | CSS Grid is a separate layout algorithm |
| **flex-direction** | `row` | Supported | — | Default |
| | `column` | Supported | — | |
| | `row-reverse` | Not supported | 1 | Reverses main-axis direction. Low priority — can be simulated by reversing children |
| | `column-reverse` | Not supported | 5 | Same as row-reverse but vertical |
| **flex-wrap** | `nowrap` | Supported | — | Default |
| | `wrap` | Supported | — | |
| | `wrap-reverse` | Not supported | 12 | Reverses cross-axis stacking. Rarely used |
| **flex-grow** | `<number>` | Supported | — | |
| **flex-shrink** | `<number>` | Supported | — | |
| **flex-basis** | `auto` | Supported | — | Default |
| | `<length>` | Supported | — | |
| | `<percentage>` | Not supported | (counted in % totals) | Would need container-size resolution |
| **justify-content** | `flex-start` | Supported | — | Default |
| | `flex-end` | Supported | — | |
| | `center` | Supported | — | |
| | `space-between` | Supported | — | |
| | `space-around` | Supported | — | |
| | `space-evenly` | Supported | — | CSS Box Alignment extension, widely used |
| **align-items** | `stretch` | Supported | — | Default |
| | `flex-start` | Supported | — | |
| | `flex-end` | Supported | — | |
| | `center` | Supported | — | |
| | `baseline` | Not supported | 21 | Requires font/glyph baseline metrics. Irrelevant in TUI — all cells are uniform height |
| **align-self** | `auto` | Supported | — | Default (inherits align-items) |
| | `flex-start` | Supported | — | |
| | `flex-end` | Supported | — | |
| | `center` | Supported | — | |
| | `stretch` | Supported | — | |
| | `baseline` | Not supported | (counted above) | Same reason as align-items baseline |
| **align-content** | `stretch` | Supported | — | Default |
| | `flex-start` | Supported | — | |
| | `flex-end` | Supported | — | |
| | `center` | Supported | — | |
| | `space-between` | Supported | — | |
| | `space-around` | Supported | — | |
| **gap** | `<length>` | Supported | — | Both row-gap and column-gap |
| | `<percentage>` | Not supported | (counted in % totals) | |
| **width / height** | `auto` | Supported | — | Default |
| | `<length>` | Supported | — | Fixed cell dimensions |
| | `<percentage>` | Not supported | (counted in % totals) | Would need container-size resolution |
| **min-width / min-height** | `<length>` | Supported | — | |
| | `<percentage>` | Not supported | (counted in % totals) | |
| **max-width / max-height** | `<length>` | Supported | — | |
| | `<percentage>` | Not supported | (counted in % totals) | |
| **padding** | `<length>` (all sides) | Supported | — | Shorthand + individual sides |
| | `<percentage>` | Not supported | (counted in % totals) | |
| **margin** | `<length>` (all sides) | Supported | — | Shorthand + individual sides |
| | `auto` | Not supported | 21 | Auto margins for centering/pushing. Could implement — useful pattern |
| | `<percentage>` | Not supported | (counted in % totals) | |
| **border** | `<length>` (insets) | Supported | — | Always 1 cell for `:single`/`:double`/`:rounded` |
| **box-sizing** | `border-box` | Supported | — | Only mode — all sizing includes padding + border |
| | `content-box` | Not supported | 5 | width/height would exclude padding + border. border-box is standard for TUI |
| **overflow** | `visible` | Supported | — | Default |
| | `hidden` | Supported | — | Suppresses automatic minimum sizing |
| | `scroll` | Not supported | 10 | Would need scrollbar space reservation. We handle scrolling at component level (ScrollableArea) |
| | `auto` | Not supported | — | Like scroll but only when content overflows |
| **white-space** | `normal` | Supported | — | Default — text wraps at word boundaries |
| | `nowrap` | Supported | — | Single line, no wrapping |
| **overflow-wrap** | `normal` | Supported | — | Default — only wraps at word boundaries |
| | `break-word` | Supported | — | Allows breaking within words at character boundaries |
| **text-overflow** | `clip` | Supported | — | Default — overflowing text is clipped |
| | `ellipsis` | Not supported | — | Future: append ellipsis to clipped text (Painter work) |
| **position** | `static` | Supported | — | Only mode — normal flex flow |
| | `relative` | Not supported | — | Offset from normal position. Could be useful but rare in TUI |
| | `absolute` | Not supported | 58 | Removes from flow, positions relative to containing block. Root portal pattern is simpler for TUI overlays |
| | `fixed` / `sticky` | Not supported | — | Browser-specific concepts |
| **insets** (top/right/bottom/left) | `<length>` | Not supported | 45 | Only meaningful with position: relative/absolute |
| **aspect-ratio** | `<ratio>` | Not supported | 29 | Terminal cells aren't square pixels — ratio doesn't translate meaningfully |
| **order** | `<integer>` | Not supported | — | Reorders flex items visually. Not in Taffy test suite. Low priority |
| **Percentage values** | on any property | Not supported | 102 | `<percentage>` on padding, margin, gap, flex-basis. Needs container-size resolution pass |
| **Percentage dimensions** | on size props | Not supported | 87 | `<percentage>` on width, height, min/max variants |

### Taffy-specific (not CSS)

| Feature | Status | Tests skipped | Notes |
|---|---|---|---|
| **Measure functions** | Not supported | 49 | Taffy's mechanism for custom intrinsic sizing (e.g., text measurement). Courgette handles text measurement directly in the flex engine via the Text module |
| **Content-box test variant** | Not used | — | Taffy generates both border-box and content-box variants of each test. We only use border-box |

## Skip reason totals

Many tests are skipped for multiple reasons (e.g., a test using both percentages and absolute positioning). Individual feature mention counts across all 275 skipped tests:

| Reason | Mentions |
|---|---|
| Percentage values | 102 |
| Percentage dimensions | 87 |
| Absolute positioning | 58 |
| Measure functions | 49 |
| Insets | 45 |
| Aspect ratio | 29 |
| Baseline alignment | 21 |
| Auto margins | 21 |
| Wrap reverse | 12 |
| Overflow scroll | 10 |
| Display none | 8 |
| Column reverse | 5 |
| Content-box sizing | 5 |
| Display grid | 4 |
| Display block | 2 |
| Row reverse | 1 |

## TUI-specific extensions

These are Courgette additions that go beyond CSS:

| Feature | What it does |
|---|---|
| `border: :single / :double / :rounded` | Semantic border styles (always 1-cell inset). CSS uses pixel widths; TUI cells are the atomic unit |
| `padding_h` / `padding_v` | Horizontal/vertical padding shorthand (not in CSS) |
| Cumulative rounding | Float→cell rounding uses cumulative absolute coordinates to prevent 1-cell gaps between siblings |

## What would be worth adding

Ranked by usefulness for TUI applications:

1. **Percentage dimensions** (87+102 skipped tests) — "sidebar is 30% width" is a natural pattern. Can be approximated with `flex: 1`/`flex: 2` ratios but percentages are more direct.
2. **Auto margins** (21 skipped tests) — `margin: auto` for centering or pushing items to edges. Common CSS pattern, directly useful.
3. **Display none** (8 skipped tests) — Conditionally hiding elements. Currently requires removing from the tree; `display: none` would be simpler.
4. **Row/column reverse** (6 skipped tests) — Minor convenience. Can simulate by reversing children list.
5. **Wrap reverse** (12 skipped tests) — Niche. Rarely needed.
6. **Overflow scroll** (10 skipped tests) — Handled at component level by ScrollableArea instead of in layout.
7. **Absolute positioning** (58 skipped tests) — Root portal pattern covers the main use case (modals). Not worth the complexity.
8. **Baseline alignment** (21 skipped tests) — Meaningless in a cell grid where all cells have uniform height.
9. **Aspect ratio** (29 skipped tests) — Meaningless when cells aren't square pixels.
10. **Content-box sizing** (5 skipped tests) — border-box is the modern standard. No reason to support both.

## Algorithm coverage

The flex engine implements all 15 steps of the CSS Flexbox algorithm (spec sections 9.1–9.6):

1. Generate anonymous flex items
2. Determine available main and cross space
3. Determine flex base size and hypothetical main size
4. Determine main size of flex container
5. Collect flex items into flex lines
6. Resolve flexible lengths (grow/shrink distribution)
7. Determine hypothetical cross size of each item
8. Calculate cross size of each flex line
9. Handle `align-content: stretch`
10. Collapse `visibility: collapse` items (no-op — not applicable to TUI)
11. Determine used cross size of each flex item
12. Distribute remaining space per `justify-content`
13. Resolve cross-axis auto margins (partial — length margins only)
14. Align items with `align-self`
15. Determine flex container used cross size and align lines with `align-content`
