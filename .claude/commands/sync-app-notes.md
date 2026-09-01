---
description: Rebuild the eleven generated inventories in .claude/notes/ — incremental, only what changed
---

# /sync-app-notes

Lifecycle step 4. First action:

```bash
./gradlew androidArchStep --after=gaps
```

Then:

```bash
./gradlew androidArchSyncNotes
```
```bash
./gradlew androidArchSyncNotes --check
```

`--check` reports staleness without writing; it is what CI runs.

## What it does

Regenerates `PROJECT`, `MODULE-GRAPH`, `NAVIGATION`, `API-MAP`, `ASSETS-COLORS`, `FONTS`, `STRINGS`,
`PERMISSIONS`, `VARIANTS` outright, and `FEATURES` + `STYLE-GUIDE` with a reviewer caveat inside the
generated block.

Each block carries its own caveat and a `Last synced` line.

## Rules

- **This is a command precisely because a full rescan must never fire by inference.** It is the
  user's call, always.
- Ordinary edits update the affected rows **in the same change** as the insertion or deletion. This
  command is for a full rebuild, not for keeping up.
- Nothing in `.claude/notes/` is ever hand-written. A row you want to write by hand is a generator
  gap — record it.
