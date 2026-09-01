---
description: Record a settled decision in docs/DECISIONS.md so it stops being asked
argument-hint: <the decision, in a sentence>
---

# /decide

A §0 question that has been answered must stop being asked. This is how.

## What it writes

```
## <YYYY-MM-DD> — <the decision, as a statement>
**Question** what was actually being decided
**Options** what was considered
**Chosen** the option, and the one sentence that decided it
**Consequences** what this makes easy, what it makes hard
**Revisit when** the concrete trigger, or "not expected"
```

## Rules

- **Consequences and Revisit-when are not optional.** A decision without them is a preference, and
  it will be relitigated.
- A decision that turns out to bind while writing code is a `CLAUDE.md` §2 rule instead — and
  `CLAUDE.md` is never edited without explicit approval.
- A declined file goes under *Do not re-propose*, written by `androidArchRemove` — not by hand.
