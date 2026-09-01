---
description: Adopt GenericArch into an existing Android repo — reconcile conflicting rules, with approval on each
---

# /android-project-init

Run once per repo, before anything else.

```bash
./scripts/androidArchDoctor.sh
```

## What it does

1. **Reads the repo as it is** — modules, flavours, build types, source sets, existing conventions.
   Nothing is assumed from the framework's own layout.
2. **Diffs actual practice against `android/rules/`.**
3. For **every** conflict, presents four things: what the repo does, what the rule says, a
   recommendation, and the three possible answers —

   | Answer | When |
   |---|---|
   | Adopt the rule | The repo has no opinion, or the migration is small |
   | Keep the repo's rule | It works; record it so the framework stops proposing the alternative |
   | **Adopt for new code only** | The rule is right but the migration is large — this is the usual answer for the hard ones |

4. **Waits for approval on each.** Nothing is reconciled silently.
5. Writes the outcome down: kept rules and their reasons, deferred rules and their revisit triggers.

## The rule that governs everything here

**An existing repo's structure wins.** This command never proposes the framework's layout for a repo
that already has one. XML views instead of Compose, Groovy instead of KTS, layer-sliced modules
instead of feature modules — for each, the default answer is *adopt for new code only*.

## What it never touches

Your `CLAUDE.md`, your `.claude/settings.json`, your existing decisions. Your rules are yours.

## Expect the first check to fail

`./scripts/androidArchCheck.sh` on an existing codebase reports every violation that was already
there. That is a baseline, not a verdict — see [configuration.md](../../docs/configuration.md) for
the two honest ways to hold it.
