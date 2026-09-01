---
description: Walk docs/DONE.md against the working diff — reports, never fixes
---

# /verify

Never declare a change finished from memory of the checklist. This walks the actual diff against
`docs/DONE.md` and reports.

## What it does

1. Reads the working diff — not the branch, not the last commit. What is uncommitted is what ships.
2. Walks every applicable `DONE.md` section: every change · a screen or feature · data, network or
   persistence.
3. Reports each item as **met · not met · cannot be checked here**.
4. Lists what could not be checked and why — a physical device, TalkBack, a foldable hinge, a real
   push, a Play upload, release signing.

## Rules

- **Reports, never fixes.** A verify that quietly repairs what it finds cannot be trusted to report.
- "Cannot be checked here" is a first-class result, not a failure to be worked around.
- It does not run tests. `androidArchTest` does, and running it is consent-gated (§2.12).
