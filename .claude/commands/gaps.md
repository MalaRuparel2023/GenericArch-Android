---
description: Triage docs/GAPS.md — decide what is deliberately absent in this repo, and the trigger to revisit
---

# /gaps

Lifecycle step 3. First action:

```bash
./gradlew androidArchStep --after=project-init
```

Run before `/project-init` this triages capabilities against rules nobody has accepted yet — and it
will produce a confident, useless answer rather than an error. That is why the gate exists.

## What it does

1. Walks each capability the base assumes: lint, static analysis, screenshot tests, module graph
   rules, CI stages, signing, notes generation.
2. For each: **present · absent by choice · absent by oversight**.
3. For every *absent by choice*, records a `docs/GAPS.md` row with a **concrete revisit trigger**.
4. For every *absent by oversight*, proposes the smallest change that closes it — and proposes only.

## Rules

- A gap without a trigger is a wish. "Someday" is not a trigger.
- `androidArchDoctor` prints `⚠` for a recorded gap and `✗` for one that is not — which is the whole
  reason to record them.
- Never fills a gap silently as part of another task.
