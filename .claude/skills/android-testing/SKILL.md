---
name: android-testing
description: Use when writing or fixing Android tests - "how do I test this ViewModel", "write a test for", "add a screenshot test", "I need a fake", "this test is flaky", "test needs a device", "mock the repository", "cover the error state", "Robolectric", "Paparazzi", "Roborazzi". Not for diagnosing a broken app, and not for running a build.
---

# android-testing

Picks the **cheapest tier that can actually prove the thing**, then writes the test at that tier.

## 1. Choose the tier — down, never up

| The thing under test | Tier | Device |
|---|---|---|
| ViewModel, mapper, use case, repository | Unit (JVM) | none |
| What a screen looks like in a given state | **Screenshot (JVM)** | none |
| Needs `Context`, resources, a shallow Android runtime | Robolectric | none |
| Real IPC, real hardware, a real permission dialog | Instrumented | yes — merge/nightly only |

**Reach for an instrumented test only when the first three genuinely cannot do it.** A test that
needs a device runs on merge, not on every push, so it protects nothing during review.

## 2. Fakes, not mocks

Every interface gets a **hand-written fake** in `:testing` — one that behaves, with state you can
drive:

```kotlin
class FakeJobRepository : JobRepository {
    var result: Result<List<Job>> = Result.success(emptyList())
    override suspend fun jobs(): Result<List<Job>> = result
}
```

- **No network in tests**, enforced by requiring a double for every Hilt binding — not by convention.
- A mocking framework verifying call order is testing the implementation, not the behaviour. It goes
  green after a refactor that broke the app, and red after one that did not.
- The fake ships **with** the interface, in the same change (§12).

## 3. Cover every state, not the happy path

For any data-driven screen, one screenshot test per `ContentState` — idle, loading, empty, offline,
error, loaded, and the paging footer states (§2.5) — each in **light, dark, RTL and 200% font**.
These are JVM tests, so the full matrix costs seconds. That is the whole reason the rule is
affordable here and not on iOS.

For a ViewModel, the states worth a unit test are the ones nobody demos: offline, empty, error,
and the transition back to loaded.

## 4. Name the test for the sentence it proves

`methodName_condition_expectedResult` — `load_offline_emitsOfflineState`. A failing test name should
tell you what broke without opening the file.

## 5. Make it deterministic, or it will be deleted

| Flake source | Fix |
|---|---|
| Wall-clock time | Inject a `Clock`. Never `System.currentTimeMillis()` in domain code |
| Timezone — green locally, red on a UTC runner | Fix the timezone in the test rule |
| Locale — `toUpperCase()` differs under `tr-TR` | `Locale.ROOT` on every case conversion |
| Dispatchers | Inject `DispatcherProvider`; a test dispatcher in tests, never `Dispatchers.IO` inline (§2.18) |
| Real delays | Virtual time via `runTest`, never a literal `delay` in a test |

A flaky test is worse than no test: it teaches the team to ignore red.

## 6. Running is consent-gated

Write tests freely; **assembling is free, running is not** (§2.12). `/android-arch-test` or `/build`
is the consent, for the run it names.
