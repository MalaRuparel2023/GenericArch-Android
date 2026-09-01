---
description: Walk the completion checklist against the working diff — reports what is done, undone, and uncheckable here
---

# /android-verify

Never declare a change finished from memory of the checklist. This walks the **actual diff**.

```bash
./scripts/androidArchCheck.sh
```

## Every change

- [ ] `androidArchCheck.sh` passes, or every failure is listed and explained
- [ ] The tests for the modules touched pass
- [ ] No rule in `android/rules/` is broken; if one had to bend, the reason is recorded
- [ ] New public API carries KDoc; nothing is `public` that need not be
- [ ] No new dependency without a decision, and none imported outside its wrapper
- [ ] Working tree only — nothing committed or pushed unless asked

## A screen or feature

- [ ] Every content state handled: idle, loading, empty, offline, error, loaded, paging footers
- [ ] A screenshot test per state — light, dark, RTL, 200% font
- [ ] Every user-facing string is a resource key, present in **every** shipped locale
- [ ] Interface + fake + implementation, not just the implementation
- [ ] One route class, one `NavHost` line, no sibling-feature import
- [ ] Survives process death via `SavedStateHandle`, and rotation
- [ ] Interactive targets ≥48 dp with a `contentDescription`; TalkBack order verified or stated unchecked
- [ ] Adapts by `WindowSizeClass`, not by device model or a width constant

## Data, network or persistence

- [ ] Dispatcher injected, never `Dispatchers.IO` inline
- [ ] Errors mapped to our types at the boundary; no vendor exception escapes the wrapper
- [ ] No PII, token or response body reaches a log
- [ ] Cache and offline behaviour match the recorded decision

## Three rules

- **Reports, never fixes.** A verify that quietly repairs what it finds cannot be trusted to report.
- **"Cannot be checked here" is a first-class result** — a physical device, TalkBack, a foldable
  hinge, a real push, a Play upload. Say it rather than implying coverage you do not have.
- It does not run tests. `/android-build` does, and running is consent-gated.
