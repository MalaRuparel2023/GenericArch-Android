---
description: Architecture health diagnostics — resolve the real stack and module graph, and report what is drifting
---

# /android-arch-doctor

Answers one question: **is this project's architecture in the shape its rules claim?**

```bash
./gradlew androidArchDoctor
```

> **Not implemented yet** — `docs/GAPS.md` row 1. Until the task exists, this command performs the
> same walk by reading the project directly, and says so in its output. Every number it reports is
> acquired from the repo, **never quoted from memory** (§1).

## The contract is the output

Three sections, one row per fact, and **three states — not two**:

| State | Means |
|---|---|
| `✓` | ok |
| `⚠` | drift, or an opportunity — information, never a blocker |
| `✗` | blocking |

```
=================================
    GenericArch — Arch Doctor
=================================

Environment
  OS                  ✓  Linux (x86_64)
  JDK                 ✓  17.0.13 Temurin   (toolchain: 17)
  Gradle              ✓  wrapper, validated
  Android SDK         ✓  ANDROID_HOME set

Project
  AGP / Kotlin / KSP  ✓  read from gradle/libs.versions.toml
  compile / target    ✓
  minSdk              ✓  product decision — docs/DECISIONS.md
  Modules             ✓  n  (listed)
  Version catalogue   ✓  gradle/libs.versions.toml
  Convention plugins  ✗  build-logic/ not present

Architecture
  Feature→feature     ✓  no sibling imports            (§2.1)
  Vendor containment  ⚠  2 modules declare Retrofit    (§7)
  Dependency direction✓  no upward or sideways edges   (§3)
  Config in features  ✗  BuildConfig imported under feature/  (§2.10)

Release
  Signing (debug)     ✓
  Signing (release)   ⚠  not resolvable here (correct: CI-only)

=================================
  FAILED — 2 blocking, 2 warnings
  Next:  ./gradlew androidArchStep --show
=================================
```

## Rules

- **Exit 0 on ok-or-warnings; non-zero only on a `✗`.** CI can gate on it and a developer is never
  blocked by a warning.
- **State where a value came from** — `toolchain: 17`, `wrapper, validated`, `CI-only`. A version
  with no provenance is a version someone will "fix" on their machine.
- **A recorded gap prints `⚠`, an unrecorded one prints `✗`.** Knowing the difference between
  *missing* and *deliberately absent* is what `docs/GAPS.md` is for, and this is where it becomes
  visible.
- Read-only. It diagnoses; it never repairs.
