---
description: Is this code safe to merge? Run the architecture rule set and report every violation, not the first
---

# /android-arch-check

```bash
./gradlew androidArchCheck
```

> **Not implemented yet** — `docs/GAPS.md` row 1. Until then this command walks the working diff
> against `CLAUDE.md` §2 by hand and reports with the same shape.

## What it checks

Every §2 rule that a machine can decide:

| Rule | Gate |
|---|---|
| §2.1 no feature imports a sibling feature | module-graph-assert + Konsist |
| §2.2 no third-party type crosses a module boundary | Konsist — a vendor import outside its wrapper |
| §2.3 no hardcoded user-facing string | lint `HardcodedText`, `MissingTranslation` at error |
| §2.4 no ad-hoc `AlertDialog`/`Toast`/`Snackbar` in a feature | custom lint rule |
| §2.6 every dependency injected | Konsist — stateful `object`, `EntryPoints.get()` in a feature |
| §2.7 no swallowed exception, `!!`, empty `onFailure`, shipping `TODO()` | detekt at error |
| §2.8 no `GlobalScope` or un-scoped `CoroutineScope` | detekt |
| §2.10 no `BuildConfig`/flavour branching in a feature | Konsist |
| §2.18 no blocking call on the main dispatcher | detekt + injected `DispatcherProvider` |
| §7 each wrapper is the only module declaring its vendor | a `build.gradle.kts` fact Konsist asserts |
| — no dynamic versions (`+`, `latest.release`) | reproducibility across machines |
| — `gradlew` keeps its exec bit | cross-OS trap, `docs/BUILD-PROCESS.md` |

## The report

```
androidArchCheck

  ✓ Formatting        spotless           0 files
  ✓ Static analysis   detekt             0 issues
  ✗ Lint              lintEnvDevDebug    3 errors   (HardcodedText ×3)
  ✗ Architecture      konsist            1 failure  (feature:jobs → feature:profile)
  ✓ Dependencies      dependency-guard   unchanged

  FAILED — 4 violations across 2 checks
  Reports: build/reports/androidarch/index.html
```

## Rules

- **An aggregator is not a gate.** `dependsOn("lint", "test")` in the root project resolves against
  the root, reaches no subproject, and stops at the first failure — so you learn about the lint error
  and never hear about the four test failures. Depend on the resolved subproject tasks, and run with
  `--continue` in CI so one run reports **everything**.
- **`check` and `test` stay separate.** `check` answers *is it safe to merge* in seconds; `test`
  answers *do the tests pass* in minutes. Merging them makes the fast signal wait on the slow one,
  which is how a pre-merge gate becomes a gate people skip.
- **Expected to fail on an existing codebase.** That is the point — it is a baseline, not a verdict.
  Baseline the debt or fix a category at a time, but never silence a rule by deleting it
  (`docs/ADOPTION.md`).
- A rule broken repeatedly across reviews is a **missing mechanical gate**. Say so, and name the
  lint, detekt or Konsist rule that would have caught it.
