---
name: android-architecture
description: Use when deciding where Android code belongs or whether a dependency is legal - "which module should this go in", "can :feature:jobs use this", "is this dependency allowed", "how do I wrap this SDK", "should this be in core or domain", "split this module", "why is this an interface". Not for scaffolding a new feature, and not for debugging.
---

# android-architecture

Answers *where does this belong, and what may it depend on* — before the code is written, when the
answer is still cheap.

## 1. Locate the question on the graph

```
:app  →  :feature:*  →  :core:designsystem, :core:navigation
                     →  :core:network, :core:database, :core:datastore, :core:logging
                     →  :core:model, :core:common   (no Android SDK, zero deps)
```

Direction is **strictly downward**. Three questions settle almost everything:

1. **Does it know about a screen?** Then it is a feature, not core.
2. **Would a second product want it unchanged?** Then it is core. If it needs a
   `:core:designsystem` theme to work, it is not product-independent — it is a feature (§4).
3. **Is it a vendor's type?** Then it lives behind a wrapper and never crosses a boundary (§7).

## 2. The four rules that decide most disputes

| Situation | Answer |
|---|---|
| Feature A needs something feature B has | **Neither imports the other** (§2.1). Extract the capability to a `:core` interface, or navigate by route value |
| Two features need the same UI | It belongs in `:core:designsystem`, as a token or a component |
| A vendor SDK is needed in two places | One wrapper module declares it; both depend on the wrapper (§7). **Swapping the vendor must touch exactly one module** |
| Something needs `Build.VERSION` or `WindowSizeClass` | The gate lives in `:core:*` or DesignSystem. A feature must not know which API level or form factor it is on (§1.1, §8) |

## 3. Interface first, on capability

Abstract on what a thing *does* (`ImageLoading`, `TokenRefreshing`), never on what it *is*. Defaults
go in default methods or extension functions — **never an open base class**, no generic base
`ViewModel`, no `BaseFragment` (§3). An interface with exactly one implementation and no fake is
usually ceremony; an interface with a fake is a seam.

## 4. Before adding any edge

Read the target module's `build.gradle.kts` first. If the edge points sideways or upward, **stop and
say so** rather than adding it (§12). Then check the module's row in `docs/modules/` — the
`Must not` line is what makes an objection citable rather than personal.

```bash
grep -i <topic> .claude/MAP.tsv
```

## 5. If it is a §0 decision, ask

Presentation pattern · persistence engine · caching/offline policy · paging · a new dependency ·
`minSdk` · a new flavour · a new permission. Check `docs/DECISIONS.md` first — a row there means do
not ask again. Otherwise: options + a recommendation + **Other** + **Skip**, then `/decide`.

## 6. Leave the reasoning behind

A module created or re-scoped gets its `docs/modules/<Module>.md` row and its `MAP.tsv` row **in the
same change**. An architecture decision that is not written down gets relitigated within a month.
