---
description: Adopt this layer into an existing repo — reconcile conflicting rules, with approval first
---

# /project-init

Lifecycle step 2. First action:

```bash
./gradlew androidArchStep --after=install
```

Exit 5 means the install has not run — stop and say so (`docs/SEQUENCE.md`).

## What it does

1. Reads the repo as it is: modules, flavours, build types, source sets, existing conventions.
2. Diffs the repo's actual practice against `CLAUDE.md` §1–§10.
3. For **every** conflict, presents: the repo's rule, the base's rule, a recommendation, and the
   three answers from `docs/ADOPTION.md` — adopt · keep and record · adopt for new code only.
4. **Waits for approval on each.** Nothing is reconciled silently.
5. Records the outcome: `docs/DECISIONS.md` for a kept rule, `docs/GAPS.md` for a deferred one.
6. Writes `.claude/INDEX.md` — what this product has.

## Rules

- **An existing repo's structure wins.** This command never proposes the base's layout for a repo
  that already has one.
- `androidArchCheck` is expected to fail after this. It is a baseline, not a verdict.
- Never touches `CLAUDE.md` without explicit approval; if the base's is taken, the repo's is kept at
  `CLAUDE-BK.md`.
