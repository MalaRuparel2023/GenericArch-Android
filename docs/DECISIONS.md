# DECISIONS

Settled choices, with the reasoning that settled them. Claude reads this **before** asking a §0
question — a row here means do not ask again. Written by `/decide`, never by hand in a hurry.

Format: one `##` block per decision, newest first.

## Template

```
## <YYYY-MM-DD> — <the decision, as a statement>
**Question** what was actually being decided
**Options** what was considered
**Chosen** the option, and the one sentence that decided it
**Consequences** what this makes easy, what it makes hard
**Revisit when** the concrete trigger, or "not expected"
```

---

## 2026-08-31 — This repo is a governance layer, not an app template

**Question** Does the base ship a working reference app, or only rules, docs and tooling?
**Options** Reference app · governance layer installed into an existing repo · both.
**Chosen** Governance layer. A template rots the day the app diverges from it; a layer that reads
the repo instead of prescribing it stays true. See `DESIGN-NOTE.md` §0 and §8.3.
**Consequences** No Kotlin ships here, so nothing can be copy-pasted into an app — every capability
has to be expressed as a rule, a generated inventory, or a Gradle task. Adoption needs an installer
and a manifest; a `git clone` is not a supported start.
**Revisit when** a second Android repo has adopted the layer and both need the same starting
Compose scaffolding — then §8.3's reference app becomes worth its maintenance.

## 2026-08-31 — The execution layer is Gradle, not bash

**Question** GenericArch (iOS) uses ~40 bash scripts. What runs the equivalent logic here?
**Options** Port the bash · Gradle tasks in an included build · a cross-platform CLI binary.
**Chosen** Gradle tasks. Every Android repo already ships a guaranteed, versioned, OS-agnostic
runner in the wrapper. bash is not a given on Windows and BSD-vs-GNU `sed` bites across Unixes.
**Consequences** Linux, Windows and macOS are first-class with no abstraction layer. The cost is
that every task must be configuration-cache-safe, and task metadata has to be declared for
`TASKS.tsv` rather than parsed from a comment header.
**Revisit when** never expected — this is the reason the port is worth doing.

## Do not re-propose

Files declined via `androidArchRemove`, with the reason. Empty until the first decline.

| Path | Declined | Reason |
|---|---|---|
| — | — | — |
