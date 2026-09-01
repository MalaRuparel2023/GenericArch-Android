---
description: Review a diff or PR against the architecture rules — reports findings, never edits the code
argument-hint: [PR number | branch | path]
---

# /android-review

Reviews a change against [`android/rules/`](../../android/rules/), citing the rule id for every
finding. An objection that cites `ARCH-001` is checkable; one that cites taste is an argument.

```bash
./scripts/androidArchCheck.sh --quiet
```

## What it reviews

The diff for `$ARGUMENTS` — a PR, a branch against its base, or a path. **What changed**, not the
file it changed in, and not the codebase's pre-existing debt. Debt noticed in passing is a gap to
record, not a review finding to block on.

## The order, worst first

**Structural — not fixable in review; this is a redesign:**

- `ARCH-001` a feature importing a sibling feature
- A dependency edge pointing sideways or upward
- `ARCH-002` a vendor type crossing a boundary, or a second module declaring a wrapped dependency
- `ARCH-010` `BuildConfig` or flavour branching inside a feature
- A product decision made silently — `minSdk`, persistence, caching, paging, a new permission

**Correctness — cheap now, expensive in the field:**

- `ARCH-007` a swallowed exception, `!!`, an empty `onFailure`, a shipping `TODO()`
- `ARCH-008` `GlobalScope` or an un-scoped `CoroutineScope`
- `ARCH-016` an `Activity`, `View` or `Context` reachable from a ViewModel or a singleton
- `ARCH-017` state that must survive process death and is not in `SavedStateHandle`
- `ARCH-018` IO without an injected dispatcher

**Completeness — where "it works" and "it is finished" diverge:**

- `ARCH-005` a content state with no branch — usually `empty`, `idle`, or a paging footer
- `ARCH-003` a user-facing string that is not a resource key, or a key missing from a locale
- A new interface with no fake; a new state with no screenshot test
- New public API with no KDoc, or `public` where `internal` would do

## Rules

- **Reports, never edits.** Someone else's change is not this session's to modify.
- Each finding carries file, line, rule id, and the concrete failure it causes.
- Say plainly what could not be reviewed here: rendering, device behaviour, TalkBack, anything
  needing a run.
- A rule broken **repeatedly** across reviews is a missing mechanical gate, not a people problem.
  Name the check that would have caught it.
