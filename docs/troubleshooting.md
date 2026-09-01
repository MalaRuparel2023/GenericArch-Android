# Troubleshooting

## The scripts

| Symptom | Cause | Fix |
|---|---|---|
| `Permission denied` running a script | The exec bit was lost, usually via a Windows commit | `git update-index --chmod=+x scripts/*.sh` |
| `refused: … has no settings.gradle[.kts]` | `install.sh` was pointed at a directory that is not a Gradle project | This is a layer, not a template. Create the project first |
| Doctor reports `✗ no wrapper` in the framework repo itself | Correct — GenericArch ships no Gradle project | Run the doctor against your **app**, not against the framework |
| `androidArchCheck` finds violations on a fresh install | Expected. It is a baseline, not a verdict | Baseline the debt, or fix one category at a time |
| Check passes locally, fails in CI | Case sensitivity — macOS and Windows filesystems are case-insensitive, Linux is not | Linux is the primary runner precisely so this is caught first |
| A rule matches its own documentation | The pattern is too loose — it hit prose in a comment | Tighten the pattern, and exclude comment lines |

## The build

| Symptom | Likely cause | Confirm in |
|---|---|---|
| Configuration fails on a machine with no secrets file | A `Properties.load` at configuration time that throws when absent | The build file — read secrets through a `Provider` instead, with a documented failure |
| Different transitive versions per machine | A dynamic version, or no `verification-metadata.xml` | `./scripts/androidArchCheck.sh` — `DEP-001` |
| Different bytecode per developer | `JAVA_HOME` drift | Gradle toolchains — `jvmToolchain(17)` plus the foojay resolver |
| Cryptic KSP or R8 failure deep in `build/` on Windows | `MAX_PATH` (260 characters) | Shorter checkout directory, or enable long-path support |
| Random `Could not delete` on Windows | Gradle daemon file locks | `--no-daemon` in CI only — never locally, where it costs minutes |

## The app

| Symptom | Likely cause | Confirm in |
|---|---|---|
| Blank screen, no error | A content state with no branch — usually `empty` or `idle` | The sealed `UiState` |
| String renders as its key | Missing translation, or the locale is set per-Activity rather than app-wide | The locale parity of your `strings.xml` files |
| Works in debug, crashes in release | R8 stripped a reflectively-used type — a Retrofit model or a `@Serializable` route | `proguard-rules.pro`; add `@Keep` |
| Crash on rotation only | State that is not in `SavedStateHandle` | The ViewModel |
| Deep link opens the browser | `autoVerify` failed — `assetlinks.json` not served, or the wrong SHA-256 | The merged manifest |
| Leaks after navigation | A `Context` or `View` held past its owner | A LeakCanary trace |
| Fine locally, ANR in the field | A blocking call reachable from the main dispatcher | StrictMode, Play Vitals |
| Recomposition jank | An unstable parameter, or a lambda allocated per recomposition | `build/compose-metrics/` — written by the Compose convention plugin |

## Tests

| Symptom | Cause | Fix |
|---|---|---|
| Green locally, red on CI | Timezone or locale | The test convention plugin fixes both to UTC / en-US. Check it is applied |
| `toUpperCase()` behaves oddly | The Turkish dotless i, under a `tr` locale | `Locale.ROOT` on every case conversion |
| Screenshot tests fail after a token change | Expected — the goldens are stale | Regenerate, then **review the diff**. Regenerating without looking defeats the tier |
| A test needs a device for something trivial | The wrong tier was chosen | Unit, screenshot and Robolectric cover far more than most teams assume |

## Still stuck

Run the doctor and read every row, including the `⚠` ones:

```bash
./scripts/androidArchDoctor.sh
```

A warning is information, not noise. Most "it works on my machine" reports resolve to a `⚠` that was
scrolled past.
