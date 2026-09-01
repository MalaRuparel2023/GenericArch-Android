---
description: Take upstream updates from GenericArch-Android into this repo
---

# /sync-with-base

```bash
./gradlew androidArchAdoptReview
```

Diffs this install against the base at a given ref. **Exit 1 while decisions are pending**, so the
same command doubles as a CI staleness gate.

## What it does

1. Lists every upstream change since the installed ref: added, changed, removed.
2. For each, the three answers — take it · decline it · take it modified.
3. Declines go through `androidArchRemove`, which tombstones the file, prunes its registry rows, and
   records the reason under *Do not re-propose* in `docs/DECISIONS.md`.
4. A file legitimately edited locally is `androidArchReseal`ed so it stays removable.

## Rules

- **Never `rm` an installed file.** Absent from disk and never installed are the same state to an
  installer, so a hand `rm` comes back on the next install.
- A file is removed only while its hash still proves it is the base's — that contract is what stops
  the uninstaller deleting something you wrote.
- Hashes are computed on **newline-normalised** bytes, so a Windows checkout with
  `core.autocrlf=true` verifies identically to a Linux one.
- Your `CLAUDE.md`, your `.claude/settings.json`, your decisions and your notes are never taken.
