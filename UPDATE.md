# Fork maintenance guide

This fork (`jmoggee/courgette`) carries behavior needed by its applications on
top of `LoamStudios/courgette`. `origin` is upstream and `fork` is the writable
fork.

## Current upstream comparison

Last checked against `origin/main` at `d461c72` on 2026-09-11 after fetching
both `origin` and `fork`. Upstream remains at the fork's base, so it added no new
functionality since the previous sync. None of the behaviors below has an
upstream equivalent.

Recheck each behavior against the fetched upstream on every sync. This section
records the current result, not a permanent allowlist. If upstream implements a
behavior equivalently, drop that local change and record its disposition here.
If every behavior is upstream, do not rebase or push; notify that the fork can be
retired.

## Carried behaviors

### Opt-in renderer-owned text selection

- **What:** `Courgette.run/2` accepts `text_selection: true`. A root component
  then consumes left-button press/drag/release events, highlights the selected
  screen cells, extracts plain text in screen order for forward or reverse
  drags, and receives `{:selection, :completed, text}`. A click selects nothing;
  with the option disabled, mouse events retain their normal application routing.
- **Why:** Upstream has no terminal text-selection contract, so applications
  that need selectable rendered output otherwise have to duplicate renderer and
  input knowledge outside the framework.
- **How:** `Courgette.Selection` owns normalization, extraction, and reverse-video
  highlighting. `Courgette.Renderer` retains an unhighlighted base buffer and
  exposes begin/extend/finish calls. The root live-component server translates
  terminal coordinates and emits the completion event. The ANSI API includes
  button-motion mode sequences, and terminal teardown disables that mode.
- **Regression tests:** `test/courgette/selection_test.exs`, the selection cases
  in `test/courgette/renderer_test.exs`, and the opt-in/routing cases in
  `test/courgette/live_component/server_test.exs`.
- **Upstream equivalent:** No. `origin/main` has no selection module, run option,
  renderer selection state, or selection completion event.

### Resilient terminal input decoding

- **What:** SGR button-motion reports decode as `:drag`; both common xterm
  Shift+Enter tilde encodings decode consistently; Kitty CSI-u press and repeat
  events remain key events, release events are ignored, and invalid event-type
  parameters fail safely instead of raising.
- **Why:** Selection needs drag events, and real terminals emit multiple
  Shift+Enter/Kitty variants. Treating Kitty release as another key press causes
  duplicate actions, while unchecked numeric parsing can crash input handling.
- **How:** `Courgette.Terminal.KeyParser` classifies the SGR motion bit, recognizes
  the two tilde forms, parses Kitty modifier/event subparameters with tagged
  results, and supports a parser-level `:skip` result for releases.
- **Regression tests:** The added CSI tilde, Kitty CSI-u, and SGR mouse cases in
  `test/courgette/terminal/key_parser_test.exs`.
- **Upstream equivalent:** No. `origin/main` has neither `:drag` mouse actions nor
  Kitty event-type/release handling or the additional Shift+Enter encodings.

### Resize state is rendered at the new dimensions

- **What:** A terminal resize reaches the root component before the renderer is
  resized. The renderer preserves the latest element tree and immediately
  repaints it at the new dimensions, including repeated same-size resize events.
- **Why:** Upstream resized and discarded the renderer tree before the component
  handled `{:resize, cols, rows}`. That could leave an empty or stale frame until
  another state change, especially when duplicate resize notifications arrived.
- **How:** `Courgette.LiveComponent.Server` dispatches the component event first;
  `Courgette.Renderer.resize/3` replaces both buffers, clears transient selection
  state, retains `last_tree`, and repaints synchronously.
- **Regression tests:** The resize cases in
  `test/courgette/live_component/server_test.exs` and
  `test/courgette/renderer_test.exs`, including duplicate same-size resize and
  pending-tree repaint coverage.
- **Upstream equivalent:** No. `origin/main` still resizes before dispatch and
  clears `last_tree` during resize.

### Atomic resize frames

- **What:** When a rendered terminal is resized, clearing/homing and painting the
  replacement frame occur inside one synchronized-output transaction. This
  prevents stale cells and avoids exposing an intermediate blank frame.
- **Why:** Upstream writes clear/home separately from the next renderer frame, so
  terminals can display tearing or stale content around a resize.
- **How:** The renderer accepts clear/home as a prefix to `do_render/2`, placing
  it between `ANSI.sync_begin/0` and `ANSI.sync_end/0`. Before the first tree it
  retains the simple clear/home path; headless rendering performs no terminal I/O.
- **Regression tests:** The non-headless resize and immediate pending-tree repaint
  cases in `test/courgette/renderer_test.exs` assert the clear and synchronized
  frame sequences.
- **Upstream equivalent:** No. `origin/main` clears outside a synchronized render
  and does not atomically repaint the retained tree.

### Public child event delivery

- **What:** `Courgette.send_event/2` delivers an event to a registered live child
  selected by module and id, returning `:ok` when found and `:error` when absent.
  Delivery uses the child's ordinary event-routing path and triggers normal child
  rendering and parent tree reassembly.
- **Why:** `send_update/2` can change props but cannot express commands such as
  scrolling an existing child. Applications previously had to reach into the
  registry or call a GenServer protocol directly.
- **How:** The public function resolves the child through `ComponentRegistry` and
  calls the existing `{:routed_event, event}` server boundary.
- **Regression tests:** `accepts parent events through the public event boundary`
  in `test/courgette/components/scroll_area_test.exs`, backed by the routed-event
  rendering tests in `test/courgette/live_component/server_test.exs`.
- **Upstream equivalent:** No. `origin/main` only exposes the unrelated
  `ComponentTestHelpers.send_event/2` test helper; it has no public
  `Courgette.send_event/2` runtime API.

### Scroll-area follow mode

- **What:** `ScrollArea` accepts `follow: true`, initially shows the end of its
  content, and follows the end as content grows. Manual movement away from the
  end suspends following and preserves the viewport; returning to the end resumes
  it. Changing the follow prop updates that policy explicitly.
- **Why:** Streaming logs and transcripts need to follow new content without
  taking control away from a user who scrolls back to inspect earlier rows.
- **How:** The component tracks `follow_end?` separately from `scroll_offset`,
  compares old and new maximum offsets during prop updates, and makes all manual
  scroll paths update whether the viewport is at the end.
- **Regression tests:** `starts and stays at the bottom while content grows` and
  `preserves the viewport after scrolling away from the bottom` in
  `test/courgette/components/scroll_area_test.exs`.
- **Upstream equivalent:** No. `origin/main` has no `follow` prop or follow-state
  policy in `ScrollArea`.

## Verification

Run these checks from a clean checkout after rebasing and after any conflict
resolution or redundant-change removal:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test
```

`mise run precommit` is the project wrapper for the same checks and tests. Push
only a clean, tested rebase with:

```bash
git push --force-with-lease fork main
```

Never push to `origin`.
