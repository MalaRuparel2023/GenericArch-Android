---
name: debug
description: Use when an Android app is broken, blank or silently wrong - "it crashed", "blank screen", "works in dev but not prod", "works in debug not release", "the string shows the key", "it leaks", "ANR", "recomposition jank", "deep link opens the browser", or when a stack trace is pasted.
---

# debug

Its value is narrowing to a **layer** before opening a single file. Reading the wrong file first is
the expensive mistake, and it is the one this skill prevents.

## 1. Get the symptom exactly

What was seen, on which **variant**, which **flavour**, which **build type**, which **device or
emulator**, which **locale**, and whether it reproduces. "It crashed" is not a symptom until it names
a build.

## 2. Match the symptom index — confirm in the named place, not in the source

| Symptom | Likely cause | Confirm in |
|---|---|---|
| String renders as its key, or the wrong language | Missing translation, or locale set per-Activity not app-wide | `notes/STRINGS.md` parity matrix |
| Blank screen, no error | A `ContentState` branch not handled — usually `empty` or `idle` | the sealed `UiState` |
| Rows vanish when a page fails | Paging `LoadState.Error` collapsed into the whole-screen error state | the Paging source |
| Works in debug, crashes in release | R8 stripped a reflectively-used type — Gson/Retrofit model, or a `@Serializable` route | `proguard-rules.pro`, missing `@Keep` |
| Works on emulator, fails on device | ABI split, or a permission auto-granted in the test harness | merged manifest |
| Crash on rotation only | State not in `SavedStateHandle` (§2.17) | the ViewModel |
| Push works in dev, silent in prod | Wrong `google-services.json` per flavour, or a missing notification channel | `notes/VARIANTS.md` |
| Deep link opens the browser | `autoVerify` failed — `assetlinks.json` not served, or wrong SHA-256 | `notes/PERMISSIONS.md` |
| Silent sign-out under load | Token refresh is not single-flight; concurrent 401s raced | `:core:network` module row |
| Leaks / OOM after navigation | A `Context` or `View` held past its owner (§2.16) | LeakCanary trace |
| Recomposition storm / jank | Unstable parameter, or a lambda allocated per recomposition | Compose compiler metrics |
| Fine locally, ANR in the field | A blocking call on the main dispatcher (§2.18) | StrictMode, Play Vitals |

If nothing matches, say so rather than forcing a row. An unmatched symptom is worth a `/learn` entry
once it is solved.

## 3. Narrow before reading

```bash
./gradlew androidArchFind --q=<screen|route|endpoint|string key>
```
```bash
grep -i <topic> .claude/MAP.tsv
```

Search `.claude/notes/`. **Do not read a note in full**, and do not read a task's implementation to
learn what it does — read its `TASKS.tsv` row.

## 4. Reproduce, then change one thing

State the hypothesis and what would disprove it *before* editing. If a fix cannot be confirmed here
— a physical device, TalkBack, a real push, a Play upload — say it is unverified rather than
implying it works.

## 5. Close it

A fix that a rule would have prevented is a `/decide` row or a `docs/GAPS.md` row. A symptom that
cost real time and is not in the table above belongs in the table, via `/learn`.
