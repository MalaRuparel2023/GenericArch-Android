# DONE — what "finished" means

Read this before saying a change is done, or run `/verify`. Never declare completion from memory of
this list. Anything that cannot be checked on this machine is **stated as unchecked**, not assumed.

## Every change

- [ ] `./gradlew androidArchCheck` passes — or its failures are listed and explained
- [ ] `./gradlew androidArchTest` passes for the modules touched
- [ ] No rule in `CLAUDE.md` §2 is broken; if one had to bend, it is a `/decide` row
- [ ] Public API added carries KDoc (§10); nothing is `public` that need not be
- [ ] No new dependency without a §0 decision, and none imported outside its wrapper (§7)
- [ ] Working tree only — nothing committed or pushed unless asked (§2.11)

## A screen or feature

- [ ] Every `ContentState` handled: idle, loading, empty, offline, error, loaded, paging footers
- [ ] A screenshot test per state — light, dark, RTL, 200% font
- [ ] Every user-facing string is a `strings.xml` key, present in **every** shipped locale
- [ ] Interface + fake + implementation, not just the implementation
- [ ] One route class, one `NavHost` line; no sibling-feature import
- [ ] Survives process death via `SavedStateHandle` (§2.17) and rotation
- [ ] Interactive targets ≥48 dp with `contentDescription`; TalkBack order verified or stated unchecked
- [ ] Adapts by `WindowSizeClass`, not by device model or width constant

## Data, network or persistence

- [ ] Dispatcher injected, never `Dispatchers.IO` inline (§2.18)
- [ ] Errors mapped to our types at the boundary; no vendor exception escapes the wrapper
- [ ] No PII, token or response body reaches a log
- [ ] Cache/offline behaviour matches the recorded §0 decision

## Cannot be checked here — say so explicitly

Physical device · TalkBack · a foldable hinge · a real push delivery · a Play upload · release
signing · an emulator-free instrumented run.
