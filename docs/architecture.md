# Architecture

The full reference lives in [`android/architecture/`](../android/architecture/). This is the
orientation.

## One paragraph

An app is a thin composition root (`:app`) over independent features (`:feature:*`) that never speak
to each other, standing on shared capabilities (`:core:*`) that know nothing about any screen. Every
dependency points **downward**. Everything else follows from that sentence.

```
:app  →  :feature:*  →  :core:designsystem, :core:navigation
                     →  :core:network, :core:database, :core:datastore, :core:logging
                     →  :core:model, :core:common   (no Android SDK, zero deps)
```

## The four documents

| Document | Answers |
|---|---|
| [ARCHITECTURE.md](../android/architecture/ARCHITECTURE.md) | What the framework believes, and how each belief is enforced |
| [LAYERS.md](../android/architecture/LAYERS.md) | What each layer owns, and the test for which layer something belongs in |
| [DEPENDENCIES.md](../android/architecture/DEPENDENCIES.md) | Which edges are legal, why sideways is the one that matters, and vendor containment |
| [MODULES.md](../android/architecture/MODULES.md) | Naming, the module contract, and what "standalone" actually requires |

## The rule that carries the most weight

**No feature module imports a sibling feature.**

It is the cheapest bad decision in an Android codebase and the most expensive to reverse. Once
`:feature:jobs` imports `:feature:profile`, neither builds alone, neither tests alone, and the two
ship as one. Six months later they are one module in everything but name.

Three legal ways for one feature to reach another:

1. **A `:core` interface** — the capability moves down; both features depend on the abstraction.
2. **Navigation by route value** — feature A emits a route, `:app` resolves it. No compile-time edge.
3. **A shared model in `:core:model`** — data, not behaviour.

## What the framework refuses to decide

Presentation pattern, persistence engine, caching policy, paging strategy, `minSdk`, flavours,
permissions. These are product decisions with real trade-offs, and a framework that picks one for
you is a framework you will fight. Its job is to make sure they are decided **deliberately and
written down** — see [configuration.md](configuration.md).

## How enforcement actually happens

| Where | What | When |
|---|---|---|
| Locally | `scripts/androidArchCheck.sh` | before a push |
| In the build | Konsist, module-graph-assert, lint, detekt | `androidArchCheck` |
| In CI | `.github/workflows/architecture-check.yml` | every PR, plus a weekly three-OS matrix |

All three read the **same** `android/rules/*.yaml`. That is deliberate: three enforcement points
with three copies of the rules is three drifting approximations of a rule nobody can state.
