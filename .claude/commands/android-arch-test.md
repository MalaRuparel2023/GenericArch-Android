---
description: Run the architecture tests and the test tiers — and typing this IS the consent §2.12 requires
---

# /android-arch-test

Running tests is **consent-gated** (§2.12). Typing this command is that consent, for the run it
names, and it does not carry forward.

```bash
./gradlew androidArchTest
```

> **Not implemented yet** — `docs/GAPS.md` row 1.

## What runs, in cost order

| Tier | Device | Covers |
|---|---|---|
| **Architecture (JVM)** | none | The §2 rules as executable tests — Konsist, module-graph-assert |
| Unit (JVM) | none | ViewModels, mappers, use cases, repositories against fakes |
| Screenshot (JVM) | none | Every `ContentState`, light + dark + RTL + 200% font |
| Robolectric | none | Anything needing a shallow Android runtime |
| Instrumented | yes | **Only when asked** — Gradle Managed Devices, or Firebase Test Lab |

The first four need no device, no emulator and no KVM. That is what makes "every content state, in
every theme" affordable to enforce rather than merely recommend.

## Architecture tests — the rules as code

A rule enforced by review is a rule that decays. These are the §2 rules written as assertions that
fail the build:

- No `:feature:*` declares another `:feature:*` (§2.1) — asserted on the Gradle dependency model,
  not on imports, so it cannot be evaded by a transitive edge.
- A vendor package appears in exactly one module's `build.gradle.kts` (§7).
- Dependency direction is strictly downward (§3) — `:core:model` and `:core:common` declare no
  Android SDK dependency at all.
- No `BuildConfig` import under `feature/` (§2.10).
- Every `ViewModel` exposes `StateFlow`, holds no `Context`, and takes a `DispatcherProvider`
  (§2.16, §2.18).

## Rules

- **No network in tests** — enforced by requiring a test double for every Hilt binding, not by
  convention.
- **Every module builds and tests standalone.** That is what actually enforces the boundaries; a
  module that only compiles as part of `:app` has none.
- Instrumented tests are opt-in here and CI-scheduled elsewhere — merge and nightly, never on every
  push.
- Failures are reported with their actual output. Never "should pass now".
