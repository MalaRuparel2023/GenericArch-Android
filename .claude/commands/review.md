---
description: Review someone else's diff or PR against the rules — reports, never edits
argument-hint: [PR number | branch | path]
---

# /review

## What it does

1. Gets the diff for $ARGUMENTS (a PR, a branch against its base, or a path).
2. Checks it against `CLAUDE.md` §2 — every rule, with the rule number cited.
3. Checks the §3 dependency direction against the module graph, and every new dependency edge
   against the module's `docs/modules/` row.
4. Flags anything that should have been a §0 question and was not.
5. Reports findings **most severe first**, each with file, line, and the rule it breaks.

## Rules

- **Reports, never edits.** Someone else's change is not this session's to modify.
- Cite the rule number. A review objection that cites `§2.1` is checkable; one that cites taste is
  an argument.
- A rule that is broken repeatedly across reviews is a missing mechanical gate — say so, and propose
  the lint, detekt or Konsist rule that would have caught it.
- Say what could not be reviewed here: rendering, device behaviour, anything needing a run.
