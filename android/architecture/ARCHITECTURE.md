# ARCHITECTURE

GenericArch-Android is a **reusable Android architecture framework**: the layer rules, the module
contracts, the Gradle conventions that make them the default, and the checks that fail a build when
they are broken.

## The one-paragraph version

An app is a thin composition root (`:app`) over independent features (`:feature:*`) that never speak
to each other, standing on shared capabilities (`:core:*`) that know nothing about any screen. Every
dependency points **downward**. Everything else here is a consequence of that sentence.

## The four principles

| Principle | What it means in practice |
|---|---|
| **Interface-oriented** | Every capability is an interface first, implementation second. Abstract on capability (`ImageLoading`, `TokenRefreshing`), never on type. Defaults live in default methods or extension functions — never an open base class |
| **Modular** | One responsibility per module. The direction is enforced by the module graph, not by convention or review |
| **Inheritable** | A new feature gets standard behaviour free through interface + extension + composition. No base `ViewModel`, no `BaseFragment` |
| **Scalable** | Adding a feature edits **zero** other features: one new module, one line in `settings.gradle.kts`, one line in the `NavHost`, one route class |

## The shape

```
:app  →  :feature:*  →  :core:designsystem, :core:navigation
                     →  :core:network, :core:database, :core:datastore, :core:logging
                     →  :core:model, :core:common   (no Android SDK, zero deps)
```

Detail: [LAYERS.md](LAYERS.md) · [DEPENDENCIES.md](DEPENDENCIES.md) · [MODULES.md](MODULES.md).

## How it is enforced

A rule enforced by review decays; a rule enforced by the build does not. Each rule in
[`../rules/`](../rules/) is machine-readable and is checked three ways:

| Where | What runs | When |
|---|---|---|
| Locally | `scripts/androidArchCheck.sh` | before a push |
| In the build | Konsist + module-graph-assert + lint + detekt | `androidArchCheck` |
| In CI | `.github/workflows/architecture-check.yml` | every PR |

## What this framework does not decide for you

Presentation pattern, persistence engine, caching policy, paging strategy, `minSdk`, flavours and
permissions are **product decisions**. The framework's job is to make sure they are decided
deliberately and written down — not to pick one.
