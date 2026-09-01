---
name: new-feature
description: Use when adding a screen, feature or Gradle module to an Android app - "create a screen", "add a feature", "scaffold :feature:x", "new module", "build the profile page", "wire up a new flow". Not for changing a screen that already exists.
---

# new-feature

Its job is to stop a happy path shipping. A screen without every content state, a fake, and string
resources is not a feature — it is a demo.

## 0. Is this actually a scaffold?

```bash
./gradlew androidArchFind --q=<Name>
```

If the screen, route or endpoint already exists, **this is a change, not a scaffold.** Say so and
stop following this skill.

Then read `docs/DECISIONS.md`. A row there answers a §0 question — do not ask it again.

## 1. Ask the §0 questions — once, in one message

Presentation pattern · persistence engine · caching/offline policy · paging · any new dependency ·
`minSdk` · a new flavour · a new permission. Options + a recommendation + **Other** + **Skip**.
Wait. Record with `/decide`.

Asking these one at a time across three messages is the failure mode this step exists to prevent.

## 2. Create the module

One new module from the feature convention plugin. One line in `settings.gradle.kts`. **Zero edits
to any other feature** — if the change needs a sibling feature, it needs a `:core` interface
instead (§2.1).

Read the module's `build.gradle.kts` before adding any dependency edge. If it points sideways or
upward, stop and say so (§12).

## 3. Produce all of it, not the happy path

- **Interface first**, named for the capability, then the implementation.
- **A fake** in `:testing` for every interface introduced.
- **String keys** in `strings.xml` — every user-facing string, in every shipped locale (§2.3).
- **Every `ContentState`**: idle, loading, empty, offline, error, loaded, and paging footer states
  (§2.5). A sealed `UiState`, and a branch for each.
- **A screenshot test per state** — light, dark, RTL, 200% font. These are JVM tests; they need no
  device, which is why "every state" is affordable here and not on iOS.
- **One route class** (`@Serializable`), **one `NavHost` line**.
- State that must outlive process death goes through `SavedStateHandle` (§2.17).
- Dispatchers injected, never `Dispatchers.IO` inline (§2.18).

## 4. Write the row

`docs/modules/<Module>.md` — owns · may depend on · **must not** · public API · vendors wrapped ·
test doubles · gotchas. And its `MAP.tsv` row, in this same change.

## 5. Finish

Walk `docs/DONE.md`, or run `/verify`. Assemble to validate. **Do not run, install or test without
being asked** (§2.12), and do not commit or push (§2.11).
