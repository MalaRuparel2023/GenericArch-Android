---
description: Triage what is deliberately absent in this repo, each with a concrete revisit trigger
---

# /android-gaps

*Missing* and *deliberately absent* are different states, and a project that cannot tell them apart
re-litigates the same omission every quarter.

## What it does

1. Walks each capability the framework assumes: convention plugins, formatter, static analysis,
   architecture tests, screenshot tests, module-graph assertions, CI, signing, dependency
   verification.
2. Classifies each: **present · absent by choice · absent by oversight**.
3. For every *absent by choice*, records a row with a **concrete revisit trigger**.
4. For every *absent by oversight*, proposes the smallest change that closes it — and proposes only.

## The row format

| Gap | Why it is absent | Revisit when |
|---|---|---|
| No screenshot tests | The design system is still moving weekly; goldens would be churn | The token set has been stable for a full sprint |

**A gap without a trigger is a wish.** "Someday", "when we have time" and "post-launch" are not
triggers. A trigger is an observable event someone will actually notice.

## Why this is a command and not automatic

Triage against rules nobody has accepted yet produces a confident, useless answer — not an error,
which is worse. Run `/android-project-init` first.

## Effect on the doctor

Once recorded, a gap prints `⚠` instead of `✗`. That is the whole point: the diagnostics stop
nagging about a decision you have already made, and keep nagging about the ones you have not.
