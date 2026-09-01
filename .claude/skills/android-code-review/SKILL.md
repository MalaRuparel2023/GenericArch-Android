---
name: android-code-review
description: Use when reviewing Android code against the architecture rules - "review this diff", "review this PR", "does this follow the rules", "check this before I merge", "is this Compose code correct", "any issues with this ViewModel", "critique this module". Reports findings; it does not edit the code.
---

# android-code-review

Reviews a change against `CLAUDE.md` §2, **citing the rule number** for every finding. An objection
that cites `§2.1` is checkable; one that cites taste is an argument.

## 1. Get the diff, and only the diff

The working diff, a branch against its base, or a PR. Review what changed — not the file it changed
in, and not the codebase's pre-existing debt. Debt found in passing is a `docs/GAPS.md` row, not a
review finding.

## 2. Walk the rules in this order

**Structural — a violation here is not fixable in review, it is a redesign:**

- §2.1 a feature importing a sibling feature
- §3 an edge pointing sideways or upward; check the target's `build.gradle.kts` and its
  `docs/modules/` row
- §7 a vendor type crossing a boundary, or a second module declaring a wrapped dependency
- §2.10 `BuildConfig` or flavour branching inside a feature
- §0 a decision made silently that should have been asked — presentation pattern, persistence,
  caching, paging, a new dependency, `minSdk`, a flavour, a permission

**Correctness — cheap to fix, expensive in the field:**

- §2.7 a swallowed exception, `!!`, an empty `onFailure`, a shipping `TODO()`
- §2.8 `GlobalScope` or an un-scoped `CoroutineScope`
- §2.16 an `Activity`, `View` or `Context` reachable from a ViewModel, singleton or companion
- §2.17 state that must survive process death and is not in `SavedStateHandle`
- §2.18 IO without an injected dispatcher; a blocking call reachable from main

**Completeness — where "it works" and "it is finished" diverge:**

- §2.5 a content state with no branch — usually `empty`, `idle`, or a paging footer
- §2.3 a user-facing string that is not a `strings.xml` key, or a key missing from a shipped locale
- A new interface with no fake; a new state with no screenshot test
- §10 new public API with no KDoc, or `public` where `internal` would do

**Compose specifics:**

- A composable taking a ViewModel instead of data and lambdas
- `Modifier` missing, not first-optional, or not applied to the root node
- `collectAsState()` where `collectAsStateWithLifecycle()` is required (§6)
- A side effect outside `LaunchedEffect`/`DisposableEffect`
- An unstable parameter or a lambda allocated per recomposition

**Accessibility (§8):** meaning carried by colour alone · a target under 48 dp · a missing
`contentDescription` · text that clips at 200%.

## 3. Report, never edit

Findings **most severe first**, each with file, line, the rule broken, and the concrete failure it
causes. Then say plainly what could not be reviewed here — rendering, device behaviour, TalkBack,
anything needing a run.

## 4. Close the loop

A rule broken **repeatedly** across reviews is a missing mechanical gate, not a people problem. Name
the lint, detekt or Konsist rule that would have caught it, and propose it — a rule enforced by
review decays; a rule enforced by the build does not.
