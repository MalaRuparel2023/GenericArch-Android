---
description: Assemble, test or bundle a variant — and typing this IS the consent §2.12 requires
argument-hint: [debug | release | test | install] [variant]
---

# /build

Assembling is free and Claude does it on its own initiative to validate a change. **Running,
installing and testing are not** — `installDebug`, `connectedAndroidTest`, launching an emulator and
`test` are consent-gated. Typing `/build` is that consent, **for the run it names, and it does not
carry forward.**

## The commands

```bash
./gradlew assembleEnvDevDebug
```
```bash
./gradlew bundleEnvProdRelease
```
```bash
./gradlew androidArchTest
```
```bash
./gradlew androidArchCheck
```

The first two are **AGP's own tasks and are never reimplemented** — this layer gates and validates
around them.

## What it reports

The variant built, the artefact path, its size, and — for a check or test run — the per-rule tally,
not a pointer to five report directories.

## Rules

- `androidArchCheck` (seconds) and `androidArchTest` (minutes) stay separate. Merging them makes the
  fast signal wait on the slow one, which is how a pre-merge gate becomes a gate people skip.
- A failing build is reported with its actual output. Never "should work now".
- Nothing is committed or pushed as part of a build (§2.11).
