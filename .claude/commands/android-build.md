---
description: Assemble, check, test or bundle — and typing this IS the consent to run something
argument-hint: [check | test | debug | release]
---

# /android-build

Assembling is free and happens on initiative to validate a change. **Running, installing and testing
are not.** Typing this command is the consent, **for the run it names**, and it does not carry
forward to the next one.

## The commands

```bash
./scripts/androidArchDoctor.sh
```
```bash
./scripts/androidArchCheck.sh
```
```bash
./scripts/androidArchTest.sh --all
```
```bash
./gradlew assembleDebug
```
```bash
./gradlew bundleRelease
```

`assembleDebug` and `bundleRelease` are **AGP's own tasks and are never reimplemented** — this
framework gates and validates around them. The moment a wrapper starts *configuring* the build
instead of gating it, the configuration belongs in a convention plugin.

## What is reported back

The variant built, the artefact path and size, and for a check or test run the **per-rule tally** —
not a pointer to five report directories.

## Rules

- `check` (seconds) and `test` (minutes) stay separate. Merging them makes the fast signal wait on
  the slow one, which is how a pre-merge gate becomes a gate people skip.
- Run with `--continue` so one invocation reports every failure, not the first.
- A failing build is reported with its **actual output**. Never "should work now".
- Nothing is committed or pushed as part of a build.
