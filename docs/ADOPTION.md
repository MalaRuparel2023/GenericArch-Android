# ADOPTION — installing into a repo that already exists

The governing rule: **an existing repo's structure wins.** This layer is installed into a project
that already works, and it never proposes a layout for a repo that has one.

## The three answers to a conflict

| Conflict | Answer |
|---|---|
| The repo has no opinion | Adopt the base's rule |
| The repo has a different rule that works | Keep the repo's rule; record it in `DECISIONS.md` so the base stops proposing it |
| The repo's rule is wrong but the migration is large | **Adopt for new code only** — the rule binds new modules and new screens, existing code migrates opportunistically |

*Adopt for new code only* is the usual answer for the hard ones: XML views vs Compose, Groovy vs
KTS, a layer-sliced module split vs feature modules.

## `androidArchCheck` is expected to fail on day one

On an existing codebase the first run reports every violation that was already there. That is the
point — it is a baseline, not a verdict. Two honest ways to hold it:

1. **Baseline the debt** (lint baseline, detekt baseline) and gate only on *new* violations.
2. **Fail loudly and fix a category at a time**, gating one rule as each category reaches zero.

Choose one with `/decide`. Never silence a rule by deleting it.

## What is never touched

Your `CLAUDE.md` (unless `--with-claude-md`), your `.claude/settings.json`, your decisions, your
notes. If the base's `CLAUDE.md` is taken, yours is preserved at `CLAUDE-BK.md` and reconciling the
two is `/project-init`'s job, with approval, section by section.

## Phased module migration

A layer-sliced repo (`:app`, `:data`, `:domain`) does not big-bang into feature modules. The order
that pays, with the gate that proves each phase landed, is in `DESIGN-NOTE.md` §3.2. Phases 0–3 need
no product decisions and no feature freeze; phase 4 — *the first **new** feature ships as
`:feature:<name>`, nothing existing moves* — is where the architecture starts paying.
