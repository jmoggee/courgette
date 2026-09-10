# Fork maintenance guide

This fork (`jmoggee/courgette`) carries three local behavior changes on top of
`LoamStudios/courgette`. `origin` is upstream and `fork` is the writable fork.

## Carried changes

- `Add resilient resize and text selection` adds renderer-owned mouse text
  selection, optional `text_selection` support, motion tracking, selection
  highlighting, and copied plain text. It also routes resize events before the
  repaint and adds the selection API and tests.
- `Repaint resize frames atomically` clears and homes the terminal inside a
  synchronized resize frame, preventing stale cells after a resize. Renderer
  tests assert the clear sequence.
- `Make child event forwarding Courgette-native` adds `Courgette.send_event/2`
  through the component registry, and adds `ScrollArea.follow` so a viewport
  follows growing content while still allowing manual scrolling. Tests cover
  both behaviors.

Before each rebase, compare every behavior above with upstream. If upstream
implements one equivalently, remove only that redundant change and record the
disposition here. If all three are upstream, notify the user and stop; the fork
can be retired.

## Verification

Run the current Mix formatter, compiler, and test suite from a clean checkout.
Push only a clean, tested rebase with:

```bash
git push --force-with-lease fork main
```
