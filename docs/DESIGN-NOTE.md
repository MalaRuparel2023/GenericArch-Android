> **Provenance.** This design note was written inside the app repo it analyses
> (`Talnetsure-android`) and is reproduced here unchanged as the source of truth for
> `GenericArch-Android`. Two consequences when reading it:
>
> - **"this repo" means that app repo**, not this one — most of all in §11 (*Findings in this repo
>   right now*) and §12 step 0, which describe that codebase's state at the time of writing.
> - **File paths like `app/build.gradle.kts` point into that app repo.** This repo ships no Kotlin
>   and no Gradle project, by the decision recorded in `DECISIONS.md`.
>
> What is actually built here versus specified: `../.claude/INDEX.md`. What is deliberately absent:
> `GAPS.md`.

---

# AndroidArch — design note

The Android counterpart to [GenericArch](https://github.com/kalpesh-jetani/GenericArch) (`iOS / iPadOS / macOS — Base Claude Setup`), rewritten
around the one thing Android has and Apple does not: **the toolchain runs on every operating
system**. Everything below is either a direct port, a deliberate divergence, or an addition that
only becomes possible on Android.

- **Audience:** whoever builds and owns the base repo, plus whoever adopts it into an app.
- **Status:** design note. Nothing here is installed yet.
- **Read with:** the section index below. Sections 1–2 are the analysis, 3–6 the architecture,
  7 the pipeline, 8–12 the plan.
- **Also merged in:** a second design — an *AndroidArch sequencing plan* built bottom-up from a
  working Gradle build. Its five-command surface, its "never reimplement an AGP task" rule and its
  ordering discipline are folded into §6 and §12; §8 records what each plan contributes, where the
  sequencing plan needs hardening, and the one place they genuinely disagree.

| § | Section | Read it when |
|---|---|---|
| 0 | [How to read this](#0-how-to-read-this) | First |
| 1 | [What GenericArch actually is](#1-what-genericarch-actually-is) | You have not read the iOS repo |
| 2 | [The port table](#2-the-port-table--every-ios-piece--its-android-answer) | Deciding what maps to what |
| 3 | [Repository shape for Android](#3-repository-shape-for-android) | Laying out modules |
| 4 | [CLAUDE.md for Android, section by section](#4-claudemd-for-android--section-by-section) | Writing the rules |
| 5 | [The `.claude/` layout](#5-the-claude-layout) | Wiring routing, notes, memory |
| 6 | [The tooling layer — Gradle, not bash](#6-the-tooling-layer--gradle-not-bash) | Building the scripts |
| 7 | [The pipeline — OS-independent by construction](#7-the-pipeline--os-independent-by-construction) | Setting up CI/CD |
| 8 | [Reconciling the two plans](#8-reconciling-the-two-plans) | You have also read the AndroidArch sequencing plan |
| 9 | [Enhancements over GenericArch](#9-enhancements-over-genericarch) | Deciding what to improve |
| 10 | [README idea for the new repo](#10-readme-idea-for-the-new-repo) | Writing the front door |
| 11 | [Findings in this repo right now](#11-findings-in-this-repo-right-now) | Today |
| 12 | [Build order](#12-build-order) | Planning the work |

---

## 0. How to read this

GenericArch is **not an app template**. It ships no Swift. It is a *governance layer* — rules, docs
and tooling — that installs into a repo which already has its project, and it uses Claude Code as
the enforcement mechanism. The Android version must be the same kind of thing: **no Kotlin app
code**, only rules, generated inventories, Gradle tasks and CI.

That distinction is the whole design. A template rots the day the app diverges from it. A
governance layer stays true because it reads the repo instead of prescribing it.

---

## 1. What GenericArch actually is

### 1.1 The seven ideas worth stealing

**1. A context budget, enforced.** `CLAUDE.md` is ~4,000 tokens, loaded every session, and holds
*only* what binds while writing code. Setup, build, ship, project settings — all pushed out to
`docs/`, fetched on demand. The rule is stated explicitly: *"a rule that isn't load-bearing is pure
overhead."* Most teams' `CLAUDE.md` is a 40 KB junk drawer; this one has a stated ceiling and a
`docs/STRUCTURE.md` that decides where new prose goes instead.

**2. A greppable router instead of a table of contents.** `.claude/MAP.tsv` is one tab-separated
row per doc, note, pattern, skill and command — `path`, `kind`, `topics`, `read it when`. You run
`grep -i navigation .claude/MAP.tsv` rather than re-reading an index every session. A `kind`
suffixed `:remote` means *not on disk, fetch it* — so a product does not carry docs for layers it
does not have.

**3. Scripts over skills, for context economics.** Stated outright: *"a skill costs context every
session through its description, a script costs nothing until called."* Two skills ship
(`new-feature`, `debug`). Everything else expressible as a script is a script. Skills fire on
inference; commands only when typed; anything that must never fire by inference (a full rescan, a
build) is a command by construction.

**4. A generated script registry with a declared contract.** `.claude/SCRIPTS.tsv` is generated
from each script's own `#@` header — `purpose`, `usage`, `in`, `out`, `exit`, `effects`, `when`,
plus a `claude` column with four values: `call`, `emit-only`, `needs-approval`,
`never:<reason>`. `register-scripts.sh --check` refuses a script with an incomplete header, so a
script cannot be added without stating its contract. And the rule *"never read a script's body to
learn what it does"* means the registry replaces reading, not supplements it.

**5. A lifecycle gate that returns exit 5.** `install → project-init → gaps → sync-app-notes →
ready`, enforced by `ga-step.sh` as the *first step of every command*. The reasoning is the good
part: out of order these commands *would not fail, they would succeed against the wrong input*.
`/gaps` before `/project-init` triages capabilities against rules nobody accepted yet. A step that
genuinely does not apply is recorded as skipped, **by the operator, with a reason** — Claude never
passes `--force`.

**6. A hash-recorded install manifest.** `install.sh` records every file it wrote, with a hash, in
`.androidarch/manifest-v<version>.json`. That is what makes the install *reversible* — `uninstall.sh`
reads the manifest and nothing else, and removes a file only while its hash still proves it is
GenericArch's. Hence `ga-reseal.sh` (re-hash after a legitimate edit) and `ga-remove.sh` (decline a
file: move to `safetodelete/`, tombstone it, prune its registry rows, record the reason in
`DECISIONS.md` under *Do not re-propose*). "Absent from disk" and "never installed" are the same
state to an installer — that is why a hand `rm` comes back on the next install, and why §2.15
forbids `rm`.

**7. An explicit consent model.** §2.12: *build freely to validate, ask before you run or test.*
§2.11: *never commit or push* — not to "save progress", not because the work looks finished. Typing
`/build` **is** the consent for that one run, and it does not carry forward. Three pipeline phases
are hard-gated and cannot be turned off: phase 5 refuses to write without `--approve`, phase 7
prints test commands and runs nothing, phase 9 emits a commit script and never runs git.

Two more worth noting: **`check-skill-triggers.py`** routes a 29-prompt corpus against skill
descriptions to catch trigger-vocabulary collisions (a skill that fires wrongly is a *description
bug*), and **`DECISIONS.md` / `GAPS.md`** separate *why it is this way* from *what is deliberately
absent* — so "we don't have that" never reads as "we forgot".

### 1.2 The five things that do not survive the port

| # | In GenericArch | Why it must change on Android |
|---|---|---|
| 1 | **macOS only.** `_common.sh` checks `uname` and exits `78` on anything else. bash 3.2, BSD `sed`/`awk`, `shasum` | Android's differentiator is that Linux, Windows and macOS are all first-class. A macOS-shaped tooling layer throws that away on day one |
| 2 | **~40 bash scripts** as the execution layer | bash is not a given on Windows, and BSD-vs-GNU `sed` differences bite even across Unixes. Android already ships a guaranteed, versioned, OS-agnostic runner in every repo: **the Gradle wrapper** |
| 3 | **`.xcconfig` as "build settings as reviewable text"** | Gradle *is* already reviewable text. The equivalent problem on Android is the opposite one: build logic sprawls across per-module `build.gradle.kts` files. The answer is **convention plugins**, not config files |
| 4 | **`Package.swift` as the dependency-direction enforcer** — "repo walls do not enforce it, the manifest does" | Correct, and Android can do strictly better: Gradle `implementation project(...)` edges are machine-readable, so the rule can be *asserted in a test* (Konsist, module-graph-assert) rather than reviewed |
| 5 | **`swift build` cannot check the iOS floor** — hence `check.sh` typechecks against the iOS 17 SDK, slowly | Android has no equivalent asymmetry. `minSdk`/`targetSdk`/`compileSdk` are declared once, lint's `NewApi` check is exhaustive and fast, and `lintVitalRelease` runs in seconds. **The single slowest, most fragile part of the iOS design disappears entirely** |

And one structural asymmetry in Android's favour: GenericArch cannot verify the iOS floor without
compiling, and cannot run UI tests without a simulator. On Android, **JVM screenshot tests**
(Paparazzi / Roborazzi / Compose Preview Screenshot Testing) render real Compose UI with no
emulator, no device, no KVM — so what costs iOS a signed simulator run costs Android a unit test.
That changes what the PR pipeline can afford to enforce.

---

## 2. The port table — every iOS piece → its Android answer

### 2.1 Modules

`docs/modules/` in GenericArch is one doc per SPM package. On Android each row becomes a Gradle
module, and the doc lives at `docs/modules/<Module>.md` exactly as before.

| GenericArch package | Android module | Implementation | Notes for the doc |
|---|---|---|---|
| `Core` (zero dependencies) | `:core:model`, `:core:common` | Pure Kotlin (`java-library`), no Android SDK | Holds `AppError`, `ContentState<T>`, `Paged<T>`, `Result` mapping. **Zero Android imports** is mechanically checkable — the module simply does not apply the Android plugin |
| `NetworkKit` (extracted) | `:core:network` | Retrofit + OkHttp, or Ktor | Single-flight token refresh via `Authenticator` + `Mutex` — the iOS doc's "signed out under load" bug is the same race here |
| `ImageCache` (extracted) | `:core:imageloader` | Coil 3 behind an interface | Same §7 wrapper rule: Coil types never cross the boundary |
| `StorageKit` | `:core:database`, `:core:datastore` | Room + DataStore(Proto/Prefs) | Secrets → `EncryptedSharedPreferences` or Keystore-wrapped, behind an interface. Room migrations are the "migration" half of the doc |
| `DIKit` (`liveValue`/`testValue`/`preview`) | `:core:di` | Hilt | `testValue` maps to `@TestInstallIn` replacing a production `@Module`. **Keep the rule that every binding must have a test double** — it is what enforces "no network in tests" |
| `DesignSystem` | `:core:designsystem` | Compose Material 3 + tokens | `ContentStateView` becomes a `ContentState<T>` composable. `#if os(...)` becomes `WindowSizeClass` branching — never a width constant, never `Build.MODEL` |
| `Navigation` | `:core:navigation` | Navigation-Compose type-safe routes (`@Serializable` route objects) | "Navigation state is data" ports verbatim, and the route classes are the machine-readable source for the generated `NAVIGATION.md` |
| `LocalizationKit` | `:core:localization` + per-module `res/values*` | `strings.xml`, plurals, `LocaleManager` | Android gives this for free *and* enforces it: lint `HardcodedText`, `MissingTranslation`, `StringFormatInvalid`, plus pseudolocales `en-XA`/`ar-XB` |
| `LoggingKit` | `:core:logging` | Timber behind an interface | The no-PII rule becomes a custom lint check, not a review item |
| `Messaging` (one presenter, never `.alert`) | `:core:messaging` | One `SnackbarHostState` + dialog host at the shell | Ports exactly. The Android violation to ban is a stray `AlertDialog` inside a feature composable |
| `NotificationKit` | `:core:notifications` | FCM behind an interface | Channels, permission (`POST_NOTIFICATIONS` on 33+), and the trailing-notification trap |
| `AppShell` (thin) | `:app` | `MainActivity`, `NavHost`, Hilt entry points, force-update gate | Stays thin: composition root only |
| `Packages/Features/Feature<Name>` | `:feature:<name>` | Compose + ViewModel + UseCase | **Never depends on another feature** — and here it is assertable, see §6 |
| — *(no iOS equivalent)* | `:build-logic` | Gradle convention plugins | The Android analogue of `Package.swift`-as-enforcement. New in this port |
| — *(no iOS equivalent)* | `:lint-checks` | Custom Android Lint rules | Turns §2 prose rules into compiler-level errors. New in this port |
| — *(no iOS equivalent)* | `:baselineprofile` | Macrobenchmark | Performance becomes a gate, not an aspiration. New in this port |

### 2.2 Tooling and enforcement

| GenericArch | Android answer | Why |
|---|---|---|
| `Scripts/*.sh` (bash 3.2, macOS-only) | **Gradle tasks** in `:build-logic`, plus Python 3 for pure text scanners | `./gradlew` is present, versioned and identical on all three OSes. `gradlew.bat` covers Windows |
| `.claude/SCRIPTS.tsv` generated from `#@` headers | `.claude/TASKS.tsv` generated from a `AndroidArchTask` annotation / task `group` + `description` + declared inputs/outputs | Same contract idea, but Gradle already models inputs, outputs and up-to-date checks — so the registry gets *verified* metadata, not commented metadata |
| `./Scripts/check.sh` (compiles the iOS floor, slow) | `./gradlew androidArchCheck` → `spotlessCheck detekt lintDebug konsistTest dependencyGuard` | Seconds instead of minutes, and no SDK-slice trickery |
| `detect-toolchain.sh` (Xcode, Swift, floors) | `./gradlew androidArchDoctor` → AGP, Gradle, Kotlin, KSP, JDK, compile/target/minSdk, Compose BOM, build-tools, installed SDK packages | Same precedence rule: **the project wins, the machine fills gaps, the rest is asked** |
| `swiftlint` + `swiftformat` | **Spotless** (ktlint/ktfmt) + **detekt** + **Android Lint** + `:lint-checks` | Three tiers: formatting, static analysis, and semantic rules you author |
| Manual review of §2 rules | **Konsist** (JVM arch tests) + **module-graph-assert** + **dependency-guard** + custom lint | The iOS repo's own `DELIVERY.md` says *"a rule only reviewed by humans decays"*. On Android most of §2 is genuinely automatable |
| `shasum` for the manifest | `sha256` via Gradle / Python `hashlib`, on **newline-normalised** bytes | Otherwise a Windows checkout with CRLF fails every hash and the manifest is useless |
| `xed -l <line> <file>` hints | `file:line` output (clickable in Studio, IntelliJ, VS Code and Claude Code) | Editor-agnostic |
| `.xcconfig` per stage | Build types × product flavours + `gradle.properties` + a `secrets` provider | Already text, already diffable |
| `Package.resolved` pinned to tags | `gradle/libs.versions.toml` + `gradle/verification-metadata.xml` | The version catalogue is the pin; dependency verification is the integrity check iOS has no equivalent for |

### 2.3 Configuration and delivery

| GenericArch | Android answer |
|---|---|
| Schemes `DEV / TEST / BETA / PROD` | Your existing flavours `envDev / envQa / envDemo / envProd` × build types `debug / release`. Keep the names you have — the base must read the repo, not rename it |
| `CFBundleShortVersionString` | `versionName` |
| `CFBundleVersion` (build number, CI-owned) | `versionCode` (CI-owned — see §7.7) |
| Package semver | Module API surface via `binary-compatibility-validator` (`apiDump` / `apiCheck`) if any module is ever published |
| App Store Connect API key `.p8` | Play Developer API service-account JSON |
| Manual signing + provisioning profiles | Upload keystore + **Play App Signing** (Google holds the app signing key) |
| Notarization (macOS) | No equivalent — but **AAB + Play Integrity + bundle badging check** is the analogous release gate |
| TestFlight internal / external | Play internal / closed / open tracks, or Firebase App Distribution for pre-Play builds |
| dSYM upload | `uploadCrashlyticsMappingFile<Variant>` (R8 mapping) + `uploadCrashlyticsSymbolFile<Variant>` (NDK) |
| Phased release | Play **staged rollout** (`userFraction`), plus halt-rollout as the panic button |
| Remote kill switch | Firebase Remote Config — you already depend on `firebase-config` |

---

## 3. Repository shape for Android

### 3.1 Target layout

```
build-logic/                    included build — the enforcement seam (§2.4 equivalent)
  convention/
    AndroidApplicationConventionPlugin.kt
    AndroidLibraryConventionPlugin.kt
    AndroidFeatureConventionPlugin.kt      applies: compose, hilt, testing, lint, detekt
    JvmLibraryConventionPlugin.kt
    AndroidArchToolingPlugin.kt                     registers every ga* task (§6)
gradle/
  libs.versions.toml            the single source of every version
  verification-metadata.xml     dependency integrity — generated, committed
app/                            composition root ONLY — thin
core/
  model/  common/  network/  database/  datastore/  designsystem/
  navigation/  di/  logging/  messaging/  notifications/  imageloader/
feature/
  auth/  profile/  jobs/  chat/  assessment/  …      never depend on each other
lint-checks/                    custom lint rules that make §2 mechanical
baselineprofile/                macrobenchmark + generated baseline profile
testing/                        shared fakes, fixtures, rules  ← you already have this
docs/                           hand-written reasoning
  modules/<Module>.md           one per module
  patterns/*.md                 procedures not yet promoted to skills
  CONVENTIONS.md  DECISIONS.md  GAPS.md  DONE.md
  BUILD-PROCESS.md  DEPLOYMENT-PROCESS.md  DELIVERY.md
  STRUCTURE.md  SEQUENCE.md  ADOPTION.md
.claude/
  MAP.tsv                       the router — grep, never read
  TASKS.tsv                     GENERATED from the Gradle task registry
  INDEX.md                      what THIS product has
  notes/                        nine generated inventories — grepped, never read
  memory/                       what earlier sessions learned — tracked
  skills/                       new-feature/  debug/
  commands/                     project-init, gaps, sync-app-notes, find, decide,
                                learn, verify, review, build, upgrade-stack, sync-with-base
.androidarch/                   install record: manifest, TOMBSTONES.tsv, STEPS.tsv
.github/workflows/              the pipeline (§7)
```

### 3.2 Migration path from your current four modules

Today: `:app` (263 Kotlin files), `:data` (99), `:domain` (193), `:testing` (4). That is a
layer-sliced Clean Architecture split — correct, but it means every feature's presentation code
sits in one 263-file `:app` module, so §2.1 ("no feature imports a sibling feature") is currently
unenforceable.

**Do not big-bang this.** GenericArch's own §12 says *"an existing repo's structure wins"* and
`docs/ADOPTION.md`'s answer to a hard conflict is *adopt for new code only*. Same here:

| Phase | Move | Gate that proves it landed |
|---|---|---|
| 0 | Nothing. Install the docs + rules + tooling layer only | `./gradlew androidArchDoctor` runs clean on Linux, Windows and macOS |
| 1 | `build-logic/` convention plugins; move duplicated config out of the three `build.gradle.kts` | Every module's build file is under ~30 lines |
| 2 | `:core:designsystem` extracted from `app/.../ui` and `presentation/component` | `HardcodedText` lint at error; theme has no `Color(0xFF…)` literals outside tokens |
| 3 | `:core:model` + `:core:common` split out of `:domain` | Module applies `java-library`, not the Android plugin |
| 4 | First **new** feature ships as `:feature:<name>`. Nothing existing moves | `module-graph-assert` rule: `:feature:.* -X> :feature:.*` |
| 5 | Existing screens migrate opportunistically, one per PR that already touches them | `:app` file count trends down; the graph rule stays green |

Phases 0–3 need no product decisions and no feature freeze. Phase 4 is where the architecture
starts paying.

---

## 4. CLAUDE.md for Android — section by section

GenericArch's `CLAUDE.md` runs §0–§12 in ~4,000 tokens. Keep the numbering scheme — the iOS repo
notes that *"roughly 450 `§N` citations repo-wide resolve against those headings, and no linter
checks them"*. We keep the headings **and** add the linter (§9.4).

Below: every section, what it holds on Android, and what changes from iOS.

### §0 — Decisions Claude must ASK about, never assume

Same mechanism: check `docs/DECISIONS.md` first; if a row answers it, follow it without re-asking.
Otherwise offer options + a recommendation + **Other** + **Skip**, wait, then record with `/decide`.

| Decision | When to ask | Android options |
|---|---|---|
| **Presentation pattern** | Before every new screen | MVVM + `StateFlow<UiState>` *(default)* · MVI with reducer · state hoisted into the composable (trivial screens only) |
| **Persistence engine** | Only if it stores data | Room · DataStore-Proto · DataStore-Prefs · in-memory only |
| **Caching / offline policy** | Any screen fetching remote data | Network-only · cache-then-network · offline-first (Room as SSOT + `NetworkBoundResource`) |
| **Paging** | Any list that can exceed ~50 items | Paging 3 · manual cursor · full-load |
| **New external dependency** | Always, before adding it | Plus: does it need a §7 wrapper, and what is its APK-size cost |
| **`minSdk` change** | Before any `minSdk` edit — never defaulted | Names the devices dropped and the APIs unlocked |
| **New `flavorDimension` or flavour** | Always | Each one multiplies variant count and CI time |
| **A new permission** | Always | Runtime rationale, Play Console declaration, and the graceful-denial path |

*Enhancement over iOS:* the last two have no Apple equivalent and are the two most common sources
of silent scope creep in an Android repo. A new flavour dimension doubles every build task; a new
permission can block a Play release outright.

### §1 — Stack

**Never quote a version from memory or from this file.** Every version is *acquired*:
`.claude/notes/PROJECT.md`, generated by `./gradlew androidArchDoctor`. Fixed by *choice*, not detection:

- **Jetpack Compose.** Views/XML only behind an `AndroidView`, only where Compose genuinely cannot.
- **Kotlin only.** No new Java.
- **Coroutines + Flow.** No RxJava, no `LiveData` in new code, no callback interfaces for async.
- **Hilt** for DI. No manual singletons, no service locator.
- **Gradle Kotlin DSL + version catalogue + convention plugins.** No Groovy, no hardcoded versions
  in a module build file.
- **`compileSdk` tracks the latest stable; `targetSdk` moves deliberately with a test pass;
  `minSdk` is a product decision (§0).**

#### §1.1 The asymmetric baseline — the Android version

iOS's asymmetry is *"the Mac floor sits many OS generations above the iPhone floor, and shared code
compiles against the lower one"*. Android's equivalent is **`minSdk` vs `compileSdk`**: you compile
against the newest SDK and must run on the oldest.

- A newer API is reached with `Build.VERSION.SDK_INT >= …` **plus a working fallback** — never by
  raising `minSdk`, never with `@SuppressLint("NewApi")`.
- The gate lives **inside a `:core:*` wrapper or a DesignSystem component**. A feature must not know
  which API level it is on.
- `lint` `NewApi` runs at **error**, and `lintVitalRelease` is a release gate. Unlike iOS, this is
  fully checkable without a second compile — see §1.2 of the iOS doc for the contrast.

Add the second Android-only asymmetry: **form factors.** Branch on `WindowSizeClass` and feature
availability (`PackageManager.hasSystemFeature`), never on `Build.MODEL`, screen width in dp
constants, or `isTablet` booleans.

### §2 — The rules that must never be broken

Fifteen rules, matching the iOS numbering where the rule is the same so `§2.N` citations stay
portable across the two bases.

| # | Rule | Mechanically enforced by |
|---|---|---|
| 1 | **No feature module imports a sibling feature.** Features talk through `:core` interfaces and navigate by route value | `module-graph-assert` + Konsist |
| 2 | **No third-party type crosses a module boundary.** Wrapper always (§7) | Konsist: no `io.coil`, `com.stream`, `okhttp3`, `com.smartlook` import outside its wrapper module |
| 3 | **No hardcoded user-facing string.** `strings.xml` key, always | lint `HardcodedText` = error; `MissingTranslation` = error |
| 4 | **No ad-hoc `AlertDialog` / `Toast` / `Snackbar` inside a feature.** One presenter | custom lint rule in `:lint-checks` |
| 5 | **Every data-driven screen handles every content state** — idle, loading, empty, offline, error, loaded, plus paging footer states | Screenshot test per state (see §7.2) — cheaper on Android than iOS |
| 6 | **Every dependency injected.** No `object` singletons holding state, no `EntryPoints.get()` inside a feature type | Konsist |
| 7 | **No swallowed exception**, no `!!`, no `runCatching {}` with an empty `onFailure`, no `TODO()` on a shipping path | detekt (`SwallowedException`, `UnsafeCallOnNullableType`) = error |
| 8 | **No `GlobalScope`, no un-scoped `CoroutineScope`.** Every scope is owned and cancelled | detekt `GlobalCoroutineUsage` = error |
| 9 | **No silent architectural choice.** If it is in §0, ask | — (review) |
| 10 | **No `BuildConfig.DEBUG` or flavour branching inside a feature.** Configuration is read once at the composition root and injected as `AppEnvironment` | Konsist: no `BuildConfig` import under `feature/` |
| 11 | **Never `commit` or `push`** unless explicitly told to. Leave it in the working tree and say what changed | — (behavioural) |
| 12 | **Assemble to validate on your own initiative; ask before you run, test or install.** `./gradlew assembleEnvDevDebug` is free; `installDebug`, `connectedAndroidTest`, launching an emulator, and `test` are consent-gated. Typing `/build` is that consent for the run it names | — (behavioural) |
| 13 | **Follow the matching skill and name it before starting** | `check-skill-triggers.py` equivalent |
| 14 | **Stop on a vague instruction.** Ask for a reference, a focused goal, or which reading — never ship a "safe subset" | — (behavioural) |
| 15 | **Never delete an installed file with `rm`.** Use `./gradlew androidArchRemove --path=… --reason=…` | manifest hash mismatch on the next `androidArchCheck` |

Three Android-specific additions worth their §2 slot, replacing iOS rules that have no analogue:

| # | Rule | Why it earns always-on context |
|---|---|---|
| 16 | **No `Context` held beyond its owner's lifetime.** No `Activity`/`View` reference in a ViewModel, singleton or companion object | The single most common Android memory leak, and it is invisible in review |
| 17 | **Every screen survives process death.** State that must outlive it goes through `SavedStateHandle`; never a `static`/`object` cache | Unreproducible on a dev machine, universal in the field |
| 18 | **No blocking call on the main dispatcher.** Every suspend function that touches IO declares its dispatcher via an injected `DispatcherProvider` | Makes the rule testable, which is the only way it holds |

*Cut from the iOS list:* `@unchecked Sendable`, typed throws, and `Package.swift` platform lines —
no Kotlin equivalent.

### §3 — Architecture principles

Ports almost verbatim; the vocabulary changes.

**Interface-oriented** — every capability is an interface first, implementation second. Defaults in
default methods or extension functions, never open base classes. Abstract on *capability*
(`ImageLoading`, `TokenRefreshing`), not on type.

**Modular** — one responsibility per module. Dependency direction strictly downward, and
**`build.gradle.kts` + the module graph enforce it, not repo walls**:

```
:app  →  :feature:*  →  :core:designsystem, :core:navigation
                     →  :core:network, :core:database, :core:datastore, :core:logging
                     →  :core:model, :core:common   (no Android SDK, zero deps)
```

**Inheritable** — a new feature gets standard behaviour free via **interface + extension +
composition**. No generic base `ViewModel` classes, no `BaseFragment`.

**Scalable** — adding a feature edits **zero** other features: one new module, one line in
`settings.gradle.kts`, one line in the `NavHost`, one route class.

### §4 — Repository

Single repo, Gradle modules, wired with `implementation(projects.core.model)` via type-safe project
accessors — **no version numbers on internal edges**. Extraction to its own repo requires all three
iOS tests to pass (**product-independent · actually reused · stable API**) and is a §0 question.
Add a fourth Android test: **it must not need a `:core:designsystem` theme to work**, or it is not
product-independent.

### §5 — Index

```bash
grep -i navigation .claude/MAP.tsv        # which doc, note or pattern covers a topic
grep -i lint .claude/TASKS.tsv            # which task does this, and its contract
./gradlew androidArchFind --q=SkillAssessment      # where is this screen/route/endpoint/string/colour?
./gradlew androidArchStep --show                   # which step is next, and why a command refused
```

Same rules: `MAP.tsv` is grepped never read; `.claude/notes/` is searched never read; a full rescan
is the user's `/sync-app-notes`, never started unprompted; `.claude/memory/` is in-repo and tracked
so it survives a clone.

### §6 — Concurrency

The iOS section is about Swift actors; the Android one is about dispatchers and scopes.

- ViewModels expose `StateFlow<UiState>`; UI collects with `collectAsStateWithLifecycle()`. Never
  `collectAsState()` for a lifecycle-sensitive stream.
- Every suspend function that touches IO takes its dispatcher from an injected provider —
  `withContext(dispatchers.io)`, never `Dispatchers.IO` inline.
- `viewModelScope` for UI-tied work; `WorkManager` for anything that must survive the process. No
  `GlobalScope`, ever.
- Every long-running operation is **cancellable** and cooperative.
- `Flow` for continuous data; `SharedFlow`/`Channel` for events. No `EventBus`, no
  `LocalBroadcastManager` for app-internal events.
- Cold flows stay cold until the UI collects. `stateIn(viewModelScope, WhileSubscribed(5_000), …)`
  is the default, and the 5-second timeout is deliberate — it survives a rotation without leaking.

### §7 — External library wrapper policy

Ports verbatim, and it is the section your current repo needs most. **No feature or core module
imports a third-party module directly — only its wrapper does, and swapping a vendor must touch
exactly one module.** Our types at the boundary; no vendor enum or exception crosses it.

From your version catalogue, the vendors that need a wrapper module today: Stream Chat, Smartlook,
Facebook SDK, AppAuth, Coil, Retrofit/OkHttp, Firebase (Crashlytics / Config / Messaging), Play
Services (Auth, Location), ZXing, Google Translation.

The rule that makes this checkable: **each wrapper module is the only Gradle module that declares
that dependency.** Not a convention — a `build.gradle.kts` fact, and Konsist can assert it.

### §8 — Multi-form-factor, accessibility, security

**Adaptivity** — branch on `WindowSizeClass` and feature availability, never device model or width
constants. Navigation state is data. `Build.VERSION` gates live inside `:core:*` wrappers or
DesignSystem components, never in a feature.

**Accessibility — a requirement, not polish.** Never encode meaning in colour alone. Every
interactive element ≥48 dp and carries a `contentDescription` or is explicitly
`clearAndSetSemantics`. Text scales to 200% without clipping. TalkBack traversal order is correct.
Mostly guaranteed inside DesignSystem components; what a screen must still prove is `docs/DONE.md`.

**Security & privacy** — two rules bind while writing code: **no PII, tokens or response bodies in
logs**, and **secrets to Keystore/EncryptedSharedPreferences only, behind an interface**. Everything
else is configuration: network security config, certificate pinning, `android:exported`, backup
rules, Play Data Safety declaration → `docs/PROJECT-SETTINGS.md`.

*Android-only additions:* `android:allowBackup` and the backup rules are a data-leak surface with no
iOS equivalent; every exported component needs a stated reason; deep links must be verified App
Links (`android:autoVerify`) or they are hijackable.

### §9 — Testing

**No network in tests** — enforced by requiring a test double for every Hilt binding. **Every module
builds and tests standalone**; that is what enforces the module boundaries.

Four tiers, in cost order — and the point of the Android version is that the first three need **no
device**:

| Tier | Runs on | Gate |
|---|---|---|
| Unit (JVM) | Every PR | ViewModels, mappers, use cases, repositories against fakes |
| **Screenshot (JVM)** | Every PR | Every `ContentState` of every screen, light + dark + RTL + 200% font |
| Robolectric | Every PR | Anything needing a shallow Android runtime |
| Instrumented | Merge / nightly | Gradle Managed Devices, or Firebase Test Lab for real hardware |

### §10 — Conventions

Naming, file layout, visibility, KDoc: `docs/CONVENTIONS.md`, enforced by Spotless + detekt. Three
that are rules, not conventions:

- **`internal` by default; `public` only what crosses a module boundary.**
- **Every public function or class carries a KDoc** stating what the signature cannot.
- **KDoc, not narration.** No `//` restating the code or describing the edit — that belongs in the
  commit message.

### §11 — Finishing a change

Read `docs/DONE.md` before saying a change is done, or run `/verify`. Never declare completion from
memory of the checklist. Say what could not be checked here (a physical device, TalkBack, a
foldable hinge, a Play upload).

### §12 — For Claude specifically

Ports verbatim, including the three that matter most: **never edit `CLAUDE.md` without explicit
approval**; **an existing repo's structure wins** — never propose this layout for a repo that has
one; **when asked for a feature, produce interface + fake + implementation + string resources +
every content state**, not just the happy path.

Add one Android-specific: **read the module's `build.gradle.kts` before adding a dependency edge.**
If it violates §3's direction, stop and say so rather than adding it.

---

## 5. The `.claude/` layout

### 5.1 `MAP.tsv` — the router

Identical format to iOS: `path`, `kind`, `topics`, `read it when`, tab-separated, with the same
`:remote` convention for rows not on disk. Keep the header comment block that teaches the grep — it
is the reason the file gets used instead of re-read.

### 5.2 `notes/` — nine generated inventories

GenericArch generates seven of nine offline in two tiers (three outright, four partial), and leaves
`FEATURES` and `STYLE-GUIDE` needing a human reviewer. Android's equivalents are **easier to
generate and more complete**, because Gradle, the manifest and the resource system are all
machine-readable:

| Note | Generated from | Tier |
|---|---|---|
| `PROJECT.md` | `androidArchDoctor` — AGP, Gradle, Kotlin, KSP, JDK, SDKs, Compose BOM, flavours, build types, signing configs present | outright |
| `MODULE-GRAPH.md` | Gradle's own project dependency model — plus a Mermaid diagram | outright *(no iOS equivalent — new)* |
| `NAVIGATION.md` | `@Serializable` route classes + `NavHost` composable destinations | outright *(richer than iOS)* |
| `API-MAP.md` | Retrofit interface annotations, or Ktor request builders | outright *(richer than iOS)* |
| `ASSETS-COLORS.md` | `res/values*/colors.xml` + Compose `Color(0x…)` literals, flagging any outside the theme | outright |
| `FONTS.md` | `res/font/`, `FontFamily` declarations | outright |
| `STRINGS.md` | Every `strings.xml` across locales, **with a parity matrix** — which keys are missing per locale | outright *(no iOS equivalent — new, and directly useful to you: you ship DE/TR)* |
| `PERMISSIONS.md` | Merged manifest — permissions, exported components, deep-link intent filters, `autoVerify` status | outright *(new)* |
| `VARIANTS.md` | Flavours × build types × signing configs × `buildConfigField`s × `manifestPlaceholders` | outright *(replaces `SCHEMES.md`)* |
| `FEATURES.md` | Module list + screens + states — **needs a reviewer** | partial |
| `STYLE-GUIDE.md` | DesignSystem tokens + components — **needs a reviewer** | partial |

That is eleven, two of them reviewer-gated. Keep the iOS discipline: **a generated block carries its
own caveat inside it, and `Last synced` line**; and **edit the affected rows in the same change as
the insertion or deletion** — a full rescan is `/sync-app-notes`, the user's call.

### 5.3 `memory/` and `INDEX.md`

Unchanged from iOS. `memory/` is in-repo and tracked so it survives a clone; never a machine-local
store. `INDEX.md` is *what this product has*, `MAP.tsv` is *what the base provides* — a thing in
neither is a thing nobody finds.

### 5.4 Skills — still exactly two

Resist adding more. `new-feature` and `debug`, with Android-shaped bodies:

**`new-feature`** — fires on "create a screen", "scaffold :feature:x", "new module". Its steps:
`androidArchFind` first (does the screen already exist? then this is a *change*, not a scaffold) → check
`DECISIONS.md` → ask the §0 questions in one message → create the module from the convention plugin
→ produce interface + fake + implementation + string keys + **every** `ContentState` + screenshot
tests per state → one route class, one `NavHost` line → the module's own `docs/modules/` row.

**`debug`** — fires on "it crashed", "blank screen", "works in dev not in prod", or a stack trace.
Its value is the **symptom index**, and Android's is different from iOS's:

| Symptom | Likely cause | Confirm in |
|---|---|---|
| String renders as its key / wrong language | Missing translation, or the locale is set per-Activity not app-wide | `notes/STRINGS.md` parity matrix |
| Blank screen, no error | A `ContentState` branch not handled — usually `empty` or `idle` | `:core:model` `ContentState` |
| Rows vanish when a page fails | Paging `LoadState.Error` collapsed into the whole-screen error state | Paging 3 doc |
| Works in debug, crashes in release | R8 stripped a reflectively-used type — Gson/Retrofit model, or a `Serializable` route | `proguard-rules.pro`, missing `@Keep` |
| Works on emulator, fails on device | ABI split, or a permission auto-granted in the test harness | merged manifest |
| Crash on rotation only | State not in `SavedStateHandle`; §2.17 | `notes/FEATURES.md` |
| Push works in dev, silent in prod | Wrong `google-services.json` per flavour, or notification channel missing | `notes/VARIANTS.md` |
| Deep link opens the browser | `autoVerify` failed — `assetlinks.json` not served, or wrong SHA-256 | `notes/PERMISSIONS.md` |
| Silent sign-out under load | Token refresh is not single-flight; concurrent 401s raced | `:core:network` doc |
| Leaks / OOM after navigation | `Context` or `View` held past its owner; §2.16 | LeakCanary trace |
| Recomposition storm / jank | Unstable parameter, lambda allocated per recomposition | Compose compiler metrics report |
| Fine locally, ANR in the field | Blocking call on the main dispatcher; §2.18 | StrictMode, Play Vitals |

### 5.5 Commands

Same split as iOS: **anything that must never fire by inference is a command.**

| Command | Does |
|---|---|
| `/project-init` | Adopt into an existing repo — reconciles conflicting rules, approval first |
| `/gaps` | Triage `docs/GAPS.md` |
| `/sync-app-notes` | Rebuild the eleven inventories — incremental, only what changed |
| `/find` | One lookup for a screen, route, endpoint, string key, colour, drawable or module |
| `/decide` | Record a settled decision in `docs/DECISIONS.md` |
| `/learn` | Record a resource or finished work; promote a pattern to a skill, or `--task` a repeated step |
| `/verify` | Walk `DONE.md` against the working diff — reports, never fixes |
| `/review` | Review someone else's diff or PR against the rules — reports, never edits |
| `/build` | Assemble, test or bundle a variant — **and this is the consent §2.12 requires** |
| `/upgrade-stack` | Reconcile AGP/Gradle/Kotlin/SDK with the machine — asks twice |
| `/release` | Prepare a release: version bump, changelog, checklist walked against the diff. **Emits commands, never runs them** *(new — iOS folds this into `/build` + docs)* |
| `/sync-with-base` | Take upstream base updates |

Note the fix to a real bug in the current repo: the directory must be `.claude/commands/`
(plural). `.claude/command/build.md` is never loaded by Claude Code — see §11.

---

## 6. The tooling layer — Gradle, not bash

**This is the single biggest divergence from GenericArch, and the reason the port is worth doing.**

GenericArch's `_common.sh` checks `uname` and exits `78` on anything that is not macOS. Roughly
forty scripts inherit that. For Apple platforms it costs nothing — you cannot build iOS off a Mac.
For Android it would throw away the platform's defining advantage.

### 6.1 Why Gradle is the right execution layer

| Requirement | bash | Python | **Gradle tasks** |
|---|---|---|---|
| Present on every dev machine and CI runner | no (Windows) | usually | **yes — the wrapper is committed** |
| Version-pinned and reproducible | no | no (3.8 vs 3.12) | **yes — `gradle-wrapper.properties`** |
| Identical invocation across OSes | no | mostly | **yes — `./gradlew` / `gradlew.bat`** |
| Knows the project model (modules, variants, deps) | no | no | **yes — natively** |
| Incremental / cacheable | no | no | **yes — inputs, outputs, up-to-date checks** |
| Good at text scanning | yes | **yes** | adequate |

So: **Gradle tasks for anything that needs the project model or must run in CI; Python 3 only for
pure text scanners**, invoked *through* a Gradle task so the entry point stays uniform. No bash
anywhere in the contract. (A `.sh` convenience wrapper is fine, as long as nothing depends on it.)

Every task lives in `build-logic/convention/AndroidArchToolingPlugin.kt` and is invoked the same way
everywhere:

```bash
./gradlew androidArchDoctor
```
```bash
gradlew.bat androidArchDoctor
```

### 6.2 The task registry — `.claude/TASKS.tsv`

Same idea as `SCRIPTS.tsv`, better mechanics. GenericArch parses `#@` comment headers; Gradle
already *has* typed inputs, outputs and a description, so the registry is generated from real
metadata plus one annotation for the fields Gradle lacks:

```kotlin
@AndroidArchTask(
  claude = Claude.CALL,                    // CALL | EMIT_ONLY | NEEDS_APPROVAL | NEVER
  purpose = "Resolve the actual stack: AGP, Gradle, Kotlin, JDK, SDKs, variants.",
  when_   = "what is the stack|which agp|min sdk|which jdk|toolchain|why won't it build",
  effects = "read-only",
  exits   = "0=ok; 2=usage; 3=no android plugin applied"
)
abstract class AndroidArchDoctorTask : DefaultTask() { … }
```

Columns: `task`, `kind`, `os`, `claude`, `purpose`, `usage`, `in`, `out`, `exit`, `effects`, `when`.

Keep the two rules that make the registry work:
- **`androidArchRegisterTasks --check` fails on any task missing its annotation** — a task cannot be added
  without stating its contract.
- **Never read a task's implementation to learn what it does.** Read the row. Read the source only
  when a call fails, then fix it in the same change.

And keep the `claude` column's four values verbatim. `EMIT_ONLY` is the important one: `androidArchRelease`
*prints* the upload commands and runs none of them.

### 6.3 The command surface — five public verbs, everything else internal

**The developer-facing API is five commands. Not fifteen.** A base repo whose value proposition is
"one conceptual command regardless of operating system" fails the moment the team has to remember
twenty task names.

| # | Command | Answers | Runs |
|---|---|---|---|
| 1 | `./gradlew androidArchDoctor` | *Is my environment and project ready to build?* | read-only, seconds |
| 2 | `./gradlew androidArchCheck` | *Is this code safe to merge?* | format + static analysis + lint + arch rules |
| 3 | `./gradlew androidArchTest` | *Do the tests pass?* | unit → screenshot → Robolectric → (opt) instrumented |
| 4 | `./gradlew assembleEnvDevDebug` | *Can I get an APK?* | **AGP's own task, unchanged** |
| 5 | `./gradlew bundleEnvProdRelease` | *Can I get the production AAB?* | **AGP's own task, unchanged** |

Every other task in §6.6 is *internal*: invoked by these five, by a command file, or by CI — never
something a developer is expected to remember. `androidArchFindTask` is how you rediscover one.

**Verbosity is a non-issue:** Gradle matches abbreviated camel-case task names, so
`./gradlew aAD` runs `androidArchDoctor` and `./gradlew aAC` runs `androidArchCheck`. Document the
long name, type the short one.

#### The rule that keeps commands 4 and 5 honest

> **Never reimplement an AGP task.** `assembleDebug` and `bundleRelease` are Google's, they are
> correct, and they will keep working across AGP upgrades. AndroidArch wraps and *validates* them —
> it never replaces them.

So `androidArchBuildDebug` (if it exists at all) is a thin wrapper:

```
androidArchBuildDebug
      → androidArchCheck          (gate)
      → assembleEnvDevDebug       (AGP does the work)
      → verify the APK exists, report path + size + variant
```

The same shape for release. The moment the wrapper starts configuring the build instead of gating
it, delete the wrapper and put the configuration in a convention plugin where it belongs.

### 6.4 `androidArchDoctor` — the output is the spec

`androidArchDoctor` is the first thing to build and the only command a new team member has to be
told about. Its contract is its output: three sections, one row per fact, and **three terminal
verdicts, not two**.

```
=================================
       AndroidArch Doctor
=================================

Environment
  OS                  ✓  Linux 7.0.0 (x86_64)
  JDK                 ✓  17.0.13 Temurin   (toolchain: 17)
  Gradle              ✓  8.14.3            (wrapper, validated)
  Android SDK         ✓  ANDROID_HOME set
  Platform 35         ✓  installed
  Build tools         ✓  35.0.0
  adb                 ✓  36.0.0
  git                 ✓  2.47.0

Project
  AGP                 ✓  8.12.3
  Kotlin / KSP        ✓  2.0.0 / 2.0.0-1.0.22
  compile / target    ✓  35 / 35
  minSdk              ✓  24
  Modules             ✓  4  (app, data, domain, testing)
  Version catalogue   ✓  gradle/libs.versions.toml
  Convention plugins  ✗  build-logic/ not present
  Config cache        ⚠  disabled — secret.properties read at configuration time

Release
  Signing (debug)     ✓  keystore/ss.keystore
  Signing (release)   ⚠  not resolvable on this machine (correct: CI-only)
  Play publishing     ✗  not configured

=================================
  FAILED — 2 blocking, 2 warnings
  Next:  ./gradlew androidArchStep --show
=================================
```

Four things this gets right that a boolean check does not:

- **Three states, not two.** `✓ ok` · `⚠ drift or opportunity` · `✗ blocking`. A warning is
  information; only a `✗` stops you. GenericArch's `detect-toolchain.sh --mismatches` uses the same
  three-way split (`BLOCKING` / `OPPORTUNITY` / `DRIFT`) and it is the right model.
- **The verdict names counts, and the next command.** Not "READY" — *"FAILED — 2 blocking, and here
  is what to run."*
- **It states where a value came from.** `toolchain: 17`, `wrapper, validated`, `CI-only`. A version
  with no provenance is a version someone will "fix" on their machine.
- **`⚠ not resolvable on this machine (correct: CI-only)`** — the doctor knows the difference between
  *missing* and *deliberately absent*. That distinction is what `docs/GAPS.md` exists for, and the
  doctor is where it becomes visible.

Exit code `0` on ok-or-warnings, non-zero only on a blocking row — so CI can gate on it and a
developer is not blocked by a warning.

### 6.5 `androidArchCheck` — an aggregator is not a gate

The obvious implementation is wrong:

```kotlin
// DON'T
tasks.register("androidArchCheck") { dependsOn("lint", "test") }
```

Three problems, all of which bite in a real multi-module build:

1. **`dependsOn` by name does not reach subprojects.** In the root project, `"lint"` resolves to the
   root project's `lint` task — which does not exist. You get `Task 'lint' not found`, or worse, a
   silent no-op if some plugin happens to register one.
2. **`dependsOn` gives no ordering and no useful failure report.** Gradle may run them in any order
   and stops at the first failure, so you learn about the lint error and never hear about the four
   test failures. The whole point of a merge gate is one run that reports *everything*.
3. **`lint` + `test` is not the rule set.** Nothing in it prevents a feature→feature import, a
   hardcoded string, a `!!`, or a missing content state — the rules §2 actually cares about.

The shape that works:

```kotlin
tasks.register("androidArchCheck") {
    group = "androidArch"
    description = "Is this code safe to merge?"
    dependsOn(
        subprojects.mapNotNull { it.tasks.findByName("spotlessCheck") },
        subprojects.mapNotNull { it.tasks.findByName("detekt") },
        subprojects.mapNotNull { it.tasks.findByName("lintEnvDevDebug") },
        project(":build-logic").tasks.named("konsistTest"),
        project(":app").tasks.named("dependencyGuard"),
    )
}
```

…plus `--continue` in CI so one run reports every violation, and a summary task that prints the
per-rule tally rather than leaving the developer to read five report directories:

```
androidArchCheck

  ✓ Formatting        spotless           0 files
  ✓ Static analysis   detekt             0 issues
  ✗ Lint              lintEnvDevDebug    3 errors   (HardcodedText ×3)
  ✗ Architecture      konsist            1 failure  (feature:jobs → feature:profile)
  ✓ Dependencies      dependency-guard   unchanged

  FAILED — 4 violations across 2 checks
  Reports: build/reports/androidarch/index.html
```

**`androidArchCheck` and `androidArchTest` stay separate** — and that separation is deliberate.
`check` answers *is it safe to merge*, `test` answers *do the tests pass*. Merging them makes the
fast signal (seconds) wait on the slow one (minutes), which is how a pre-merge gate becomes a gate
people skip.

### 6.6 The internal task set

| Task | Replaces | Does |
|---|---|---|
| `androidArchDoctor` | `detect-toolchain.sh` | Resolves the real stack; `--markdown` emits `PROJECT.md` rows; `--mismatches` emits `BLOCKING\|OPPORTUNITY\|DRIFT` rows |
| `androidArchCheck` | `check.sh` | §6.5. **Seconds, not minutes** |
| `androidArchTest` | — | Unit → screenshot → Robolectric. Instrumented only when asked (§9) |
| `androidArchSyncNotes` | `sync-notes.sh` + the `scan-*.py` set | Regenerates the eleven inventories. `--check` for CI staleness, `--evidence` for provenance |
| `androidArchFind` | `find.sh` | One lookup across screens, routes, endpoints, string keys, colours, drawables, modules |
| `androidArchFindTask` | `find-script.sh` | Scores an intent against the `when` column — *"is the memory store consistent"* reaches `androidArchVerifyMemory` without knowing its name |
| `androidArchStep` | `ga-step.sh` | The lifecycle gate. Exit 5 = an earlier step has not run |
| `androidArchInstall` / `androidArchUninstall` / `androidArchReseal` / `androidArchRemove` | the four installers | Manifest-driven, hash-verified, reversible |
| `androidArchAdoptReview` | `adopt-review.sh` | Diff an install against the base; exit 1 = decisions pending, so it doubles as a CI staleness gate |
| `androidArchVerifyMemory`, `androidArchCheckLinks`, `androidArchNotesStaleness`, `androidArchCheckSkillTriggers`, `androidArchCheckSections` | the offline checks | All read-only, all fast, all in the PR pipeline |
| `androidArchRelease` | — | **`EMIT_ONLY`.** Walks the release checklist against the diff and prints what to run |

### 6.7 The lifecycle gate

Ports directly, with the same five steps and the same exit 5. The reasoning is unchanged and worth
restating because it is the subtlest good idea in the whole repo: **out of order these commands do
not fail, they succeed against the wrong input.**

```
install → project-init → gaps → sync-app-notes → ready
```

Ledger at `.androidarch/STEPS.tsv`. Every command's first step is `./gradlew androidArchStep --after=install`.
A step that does not apply is **recorded as skipped by the operator with a reason** — Claude never
passes `--force`.

### 6.8 The install manifest — with the cross-OS fix

Keep the design: record every written file with its hash in
`.androidarch/manifest-v<version>.json`; remove a file only while its hash still proves it is the
base's; `androidArchReseal` after a legitimate edit; `androidArchRemove` to decline (move to `safetodelete/`,
tombstone, prune registry rows, record *Do not re-propose* in `DECISIONS.md`).

**One mandatory change:** hash **newline-normalised** bytes (`\r\n` → `\n`) and record the mode
separately. GenericArch can assume LF because it can assume macOS. A Windows checkout with
`core.autocrlf=true` would fail every single hash, and the manifest — the thing that makes the
install reversible — would be worthless on a third of the target machines.

Pair it with a committed `.gitattributes`:

```
* text=auto eol=lf
*.bat text eol=crlf
*.pro text eol=lf
gradlew text eol=lf
gradle/wrapper/gradle-wrapper.jar binary
*.keystore binary
*.jks binary
```

---

## 7. The pipeline — OS-independent by construction

The design goal: **the same command, producing the same artefact, on Linux, Windows, macOS, any CI
provider, and a developer's laptop.** Not "works on our runners" — *any* operating system.

The way you get there is not a clever YAML file. It is a **rule about where logic may live**:

> **All build logic lives in Gradle. CI files contain no logic — only checkout, toolchain
> provisioning, secret injection, and `./gradlew <task>`.**

If a step is more than one Gradle invocation, it belongs in a Gradle task, not in YAML. That single
constraint is what makes the pipeline portable, testable locally, and reviewable — and it means
migrating from GitHub Actions to GitLab, Bitrise or Jenkins is a half-day of YAML translation, not a
rewrite.

### 7.1 The five stages

| Stage | Trigger | Runner | Signs | Duration target |
|---|---|---|---|---|
| **0 · Local** | pre-commit hook (installed by `./gradlew androidArchInstallHooks`) | dev machine, any OS | no | < 20 s |
| **1 · PR** | every push to a PR | `ubuntu-latest` | no | < 12 min |
| **2 · Integration** | merge to `develop` | `ubuntu-latest` | debug key | < 25 min |
| **3 · Release candidate** | tag `v*` | `ubuntu-latest` | upload key | < 30 min |
| **4 · Promotion** | manual | `ubuntu-latest` | — | minutes |

Stage 0 runs a strict subset of stage 1 — formatting and the fastest static checks only. A
pre-commit hook that takes two minutes gets uninstalled by the team within a week.

### 7.2 What each stage runs

**Stage 0 — local pre-commit**
```bash
./gradlew spotlessApply androidArchCheckLinks --configuration-cache
```

**Stage 1 — PR (no signing, no emulator, no device)**
```bash
./gradlew androidArchCheck                       # spotless + detekt + lint + konsist + dependency-guard
./gradlew testEnvDevDebugUnitTest       # JVM unit tests, all modules
./gradlew verifyRoborazziEnvDevDebug    # JVM screenshot tests — every ContentState
./gradlew assembleEnvDevDebug           # it compiles
./gradlew androidArchSyncNotes --check           # the inventories are not stale
./gradlew androidArchAdoptReview                 # the base install is not stale
```

The screenshot tier is the part iOS cannot have cheaply. Every content state of every screen, in
light and dark, LTR and RTL, at 1.0× and 2.0× font scale — rendered on the JVM, no emulator, in the
same job. That is how §2.5 stops being a review item.

**Stage 2 — merge to `develop`**

Adds instrumented tests and distribution:
```bash
./gradlew pixel6api34EnvQaDebugAndroidTest     # Gradle Managed Device — provisions its own emulator
./gradlew bundleEnvQaRelease
./gradlew appDistributionUploadEnvQaRelease    # QA always has the latest develop
```

Gradle Managed Devices matter here: the emulator is declared in `build.gradle.kts`, downloaded by
Gradle, and identical on every runner — so "works on my machine" stops being a category of bug. It
needs KVM, which `ubuntu-latest` has; Windows and macOS runners do not, which is exactly why this
stage is pinned to Linux.

**Stage 3 — release candidate (tag `v1.11.0`)**
```bash
./gradlew bundleEnvProdRelease
./gradlew uploadCrashlyticsMappingFileEnvProdRelease
./gradlew :app:checkEnvProdReleaseBadging      # permissions/minSdk/versionCode vs the golden file
./gradlew publishEnvProdReleaseBundle          # → Play internal track
```

The badging check is worth calling out: it compares the built bundle's declared permissions,
`minSdk`, `targetSdk` and `versionCode` against a **committed golden file**. A transitive dependency
that quietly adds `READ_PHONE_STATE` fails the build instead of shipping. There is no iOS equivalent
and it catches a real class of incident.

**Stage 4 — promotion (manual, deliberate)**
```
internal → closed (soak) → open → production @ 5% → 20% → 50% → 100%
```

**The same rule iOS states, unchanged and just as often broken: production is promoted from the
same artefact that soaked — never rebuilt from a moved branch.** With AABs this is enforceable —
promote the *same version code* between tracks rather than uploading a new bundle.

### 7.3 GitHub Actions reference

Five files, and note how little is in each — that is the point.

```
.github/workflows/
├── pull-request.yml    stage 1 — every PR, fast, no signing
├── main.yml            stage 2 — merge to develop, GMD tests, QA distribution
├── nightly.yml         the slow tiers, so they never sit in the PR gate
├── release.yml         stage 3 — tag v*, signed, Play internal track
└── cross-os.yml        the weekly three-OS matrix
```

`.github/workflows/pull-request.yml`
```yaml
name: PR
on:
  pull_request:
  workflow_dispatch:

concurrency:
  group: pr-${{ github.head_ref }}
  cancel-in-progress: true

jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }        # androidArchSyncNotes and /verify need the merge base

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - uses: gradle/actions/wrapper-validation@v4
      - uses: gradle/actions/setup-gradle@v4
        with:
          cache-read-only: ${{ github.ref != 'refs/heads/develop' }}

      - name: Materialise secrets
        env:
          SECRET_PROPERTIES_B64: ${{ secrets.SECRET_PROPERTIES_B64 }}
          GOOGLE_SERVICES_JSON_B64: ${{ secrets.GOOGLE_SERVICES_JSON_B64 }}
        run: ./gradlew androidArchMaterialiseSecrets      # reads env, writes the gitignored files

      - run: ./gradlew androidArchCheck
      - run: ./gradlew testEnvDevDebugUnitTest
      - run: ./gradlew verifyRoborazziEnvDevDebug
      - run: ./gradlew assembleEnvDevDebug
      - run: ./gradlew androidArchSyncNotes --check
      - run: ./gradlew koverXmlReport

      - name: APK size delta
        run: ./gradlew androidArchSizeReport --base=origin/${{ github.base_ref }}

      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: reports
          path: |
            **/build/reports/**
            **/build/outputs/roborazzi/**
```

`.github/workflows/release.yml`
```yaml
name: Release
on:
  push:
    tags: ['v*']

jobs:
  candidate:
    runs-on: ubuntu-latest
    environment: production          # required reviewers live here, not in the YAML
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: gradle/actions/wrapper-validation@v4
      - uses: gradle/actions/setup-gradle@v4

      - name: Materialise secrets and keystore
        env:
          KEYSTORE_B64:        ${{ secrets.UPLOAD_KEYSTORE_B64 }}
          KEYSTORE_PASSWORD:   ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS:           ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD:        ${{ secrets.KEY_PASSWORD }}
          SECRET_PROPERTIES_B64: ${{ secrets.SECRET_PROPERTIES_B64 }}
          PLAY_SERVICE_ACCOUNT_JSON_B64: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON_B64 }}
        run: ./gradlew androidArchMaterialiseSecrets --with-keystore

      - run: ./gradlew androidArchCheck testEnvProdReleaseUnitTest lintVitalEnvProdRelease
      - run: ./gradlew bundleEnvProdRelease
      - run: ./gradlew :app:checkEnvProdReleaseBadging
      - run: ./gradlew uploadCrashlyticsMappingFileEnvProdRelease
      - run: ./gradlew publishEnvProdReleaseBundle      # internal track only

      - uses: actions/upload-artifact@v4
        with:
          name: mapping-and-bundle
          path: |
            app/build/outputs/bundle/envProdRelease/*.aab
            app/build/outputs/mapping/envProdRelease/mapping.txt
          retention-days: 90        # you cannot deobfuscate a crash without this file
```

`.github/workflows/nightly.yml` — **the pressure valve.** Everything genuinely slow lives here,
which is the only reason the PR gate can stay under twelve minutes:

```yaml
name: Nightly
on:
  schedule: [{ cron: '0 2 * * *' }]
  workflow_dispatch:

jobs:
  deep:
    runs-on: ubuntu-latest
    timeout-minutes: 120
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew androidArchMaterialiseSecrets

      - run: ./gradlew pixel6api34EnvQaDebugAndroidTest   # full instrumented suite
      - run: ./gradlew :baselineprofile:generateBaselineProfile
      - run: ./gradlew :app:macrobenchmark                # startup + scroll jank trend
      - run: ./gradlew androidArchSizeReport --trend      # AAB size over time
      - run: ./gradlew dependencyUpdates                  # what moved upstream
      - run: ./gradlew androidArchNotesStaleness androidArchAdoptReview
```

A nightly is not a weaker pipeline — it is where a check goes when it is **valuable but too slow to
block a human**. The failure mode to avoid is the opposite: a PR gate that grows until people start
merging around it.

Plus a **weekly cross-OS job** — the one that actually keeps the promise:

`.github/workflows/cross-os.yml`
```yaml
name: Cross-OS
on:
  schedule: [{ cron: '0 3 * * 1' }]
  workflow_dispatch:

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew androidArchDoctor androidArchCheck assembleEnvDevDebug
        shell: bash        # git-bash on Windows; the ONLY place a shell is named
```

Weekly, not per-PR: the failures it catches (path length, case sensitivity, line endings) appear
when someone adds a file, not when someone edits one. Weekly is enough, and it costs three jobs
instead of three per PR.

### 7.4 Other CI providers — the translation is mechanical

Because all logic is in Gradle, each provider needs the same five things. This is what the
"any operating system, any provider" claim actually reduces to:

| Need | GitHub Actions | GitLab CI | Bitrise | Jenkins |
|---|---|---|---|---|
| Checkout | `actions/checkout` | built-in | `git-clone` step | `checkout scm` |
| JDK 17 | `setup-java` | `image: eclipse-temurin:17` | `Set Java Version` | tool `jdk17` |
| Android SDK | preinstalled | `image: android-sdk:35` | preinstalled | agent image |
| Gradle cache | `setup-gradle` | `cache: .gradle/` | `cache-pull/push` | workspace or `setup-gradle` |
| Secrets | `secrets.*` → env | masked CI variables | Secrets + Generic File Storage | Credentials binding |
| Run | `./gradlew androidArchCheck` | `./gradlew androidArchCheck` | `./gradlew androidArchCheck` | `sh './gradlew androidArchCheck'` |

Prefer a **container image** (`eclipse-temurin:17` + `cmdline-tools` + SDK 35, or the official
`android-sdk` images) wherever the provider supports it. A pinned image is the only way "identical
on any OS" becomes literally true rather than approximately true — the host OS stops mattering
entirely. Commit the `Dockerfile` next to the pipeline and reuse it for a devcontainer, so a new
developer on Windows gets the exact CI environment without configuring anything.

### 7.5 Cross-OS traps, and the gate that forbids each one

Every one of these has cost a real team a real afternoon. Each gets a mechanical gate, not a wiki
page:

| Trap | Symptom | Gate |
|---|---|---|
| **Case sensitivity** | Builds on Windows/macOS (case-insensitive FS), fails on Linux CI | Linux is the *primary* runner, so it is caught first, always |
| **Line endings** | Manifest hashes fail; `.sh` files get CRLF and refuse to execute | `.gitattributes` (§6.5) + normalised hashing |
| **`gradlew` exec bit lost** | `Permission denied` on Linux after a Windows commit | `git update-index --chmod=+x gradlew`, checked by `androidArchCheck` |
| **Windows `MAX_PATH` (260)** | Cryptic KSP/R8 failures deep in `build/` | Short checkout dir + long-path support in the docs; the weekly matrix job catches regressions |
| **Hardcoded path separators** in build logic | Works on one OS only | detekt rule banning `"/"` string concatenation for paths; use `layout.projectDirectory.file(...)` |
| **`JAVA_HOME` drift** | Different bytecode per developer | **Gradle toolchains** — `kotlin { jvmToolchain(17) }` + the foojay resolver auto-provisions the JDK regardless of what is installed |
| **Locale-dependent string ops** | `toUpperCase()` differs under `tr-TR` (the Turkish dotless-i) — and **you ship Turkish** | detekt: require `Locale.ROOT` on every case conversion |
| **Timezone-dependent tests** | Green locally, red on a UTC runner | Inject a `Clock`; ban `System.currentTimeMillis()` in domain code |
| **Non-reproducible dependency resolution** | Different transitive versions per machine | `gradle/verification-metadata.xml` + no dynamic versions (`+`, `latest.release`) — assert this in `androidArchCheck` |
| **Gradle daemon file locks (Windows)** | Random `Could not delete` | `--no-daemon` in CI only; never locally, where it costs minutes |

### 7.6 Secrets and signing

Your `app/build.gradle.kts` currently does this at configuration time:

```kotlin
val secretFile = file("${project.projectDir}/src/main/secret.properties")
secretProperties.load(FileInputStream(secretFile))
```

It is gitignored, which is right. But it **throws if the file is absent**, so *no CI job can even
configure the project* until the file exists — and `Properties.load` at configuration time also
breaks the configuration cache. Fix both at once:

```kotlin
// build-logic: SecretsProvider — env first, then a local file, then a documented failure.
fun Project.secret(key: String): Provider<String> =
    providers.environmentVariable(key.uppercase().replace('.', '_'))
        .orElse(providers.gradleProperty(key))
        .orElse(providers.of(LocalSecretSource::class) { parameters.key.set(key) })
```

Then:

| Secret | Local | CI |
|---|---|---|
| API keys, Stream/Smartlook keys | `~/.gradle/gradle.properties` (outside the repo) | masked env vars |
| `secret.properties` | the gitignored file | `SECRET_PROPERTIES_B64` → `androidArchMaterialiseSecrets` |
| `google-services.json` (per flavour) | committed *only* for dev flavours, or gitignored | `GOOGLE_SERVICES_JSON_B64` per flavour |
| Upload keystore | never on a laptop for prod | `UPLOAD_KEYSTORE_B64` + 3 passwords |
| App signing key | — | **held by Google (Play App Signing)** |
| Play publishing | — | `PLAY_SERVICE_ACCOUNT_JSON_B64` |

Rules, matching the iOS `DELIVERY.md` reasoning:
- **Use a Play Developer API service account, never a personal Google account.** A pipeline tied to
  one engineer's login breaks the day they rotate their password, and 2FA cannot be automated.
- **Enable Play App Signing.** Then a leaked upload key is a key rotation, not a dead app.
- **`local` (debug) signing config may live in the repo. Production signing exists only in CI.** Your
  current `envProd` flavour points at `talentsure.keystore` — that should not be resolvable on a
  developer machine.
- Rotate the service-account key on a schedule and whenever someone with access leaves.

### 7.7 Versioning — three numbers, and only one is CI's

Same trap as iOS, different names:

| Number | Example | Owned by | Changes when |
|---|---|---|---|
| `versionName` | `1.10.8` | Product | A release ships |
| `versionCode` | `202636101` | **CI** | Every build |
| Module API version | `1.2.0` | The module | Only if published externally |

- **`versionCode` must be monotonic across every flavour and track, and must come from CI** — never
  a hand-edited constant. A committed counter guarantees merge conflicts and duplicate codes, and
  Play rejects a duplicate outright.
- Your current value (`202636101`) reads as a date-plus-counter scheme. Keep the scheme, move the
  *counter* to CI: `versionCode = baseFromDate * 100 + (CI_RUN_NUMBER % 100)`, or simply take Play's
  "highest uploaded + 1". Whichever — it must not be a literal in `build.gradle.kts`.
- **Never reset `versionCode` per flavour.** "Which build is newer" must stay answerable.
- **Hotfix:** branch from the release tag, not from `develop`. Bump patch, cherry-pick forward to
  `develop` in the same PR — never leave the fix only on the release branch.

### 7.8 Release, staged rollout, rollback

Ports the iOS ownership table with Android's mechanics:

| # | Step | Owned by | Gate before moving on |
|---|---|---|---|
| 1 | Merged to `develop` | the author | Stage 1 green |
| 2 | QA build to App Distribution | CI, on merge | QA has the latest `develop` and it launches |
| 3 | `versionName` bumped | a person, deliberately | Marketing version decided; `versionCode` is CI's |
| 4 | Tag `vX.Y.Z` | a person | The release checklist, walked against the diff |
| 5 | Internal → closed track soak | CI on tag, then a person | Crash-free rate acceptable, Vitals clean |
| 6 | Production, staged rollout from 5% | a person | **Same artefact, promoted — not rebuilt** |
| 7 | Rollback if needed | a person | See below |

**Rollback — decide the mechanism before you ship, not during the incident.** Same three-tier
reality as the App Store:

1. **Halt the staged rollout** — stops new installs. Does nothing for people who already have it.
2. **Remote Config flag off** — the only fix that reaches installed copies. Requires the flag to
   exist *before* the release, which is why it belongs on the pre-submit checklist. You already
   depend on `firebase-config`; make the kill-switch flag part of the feature template.
3. **Ship a hotfix** — hours, at best, and it still needs review. Assume it, do not rely on it.

Android's one genuine advantage over iOS here: `versionCode` monotonicity means you *can* halt and
re-promote an older bundle to a track. Google Play calls it deactivating a release. It is still not
an undo — installed copies keep the bad build.

**Release checklist** (`docs/DELIVERY.md`), the Android version:

- [ ] `versionName` bumped; `versionCode` from CI
- [ ] `gradle/verification-metadata.xml` current; no dynamic versions
- [ ] Every module green standalone
- [ ] Zero lint warnings; `lintVitalRelease` clean
- [ ] `androidArchDoctor` clean — no BLOCKING rows
- [ ] Translations complete for every shipping locale (`notes/STRINGS.md` parity matrix — you ship DE/TR)
- [ ] Screenshot tests regenerated and reviewed; store screenshots per locale
- [ ] Release notes localised
- [ ] Play Data Safety form current; permission list matches the badging golden file
- [ ] Force-update threshold set for the new `versionCode`
- [ ] `mapping.txt` uploaded to Crashlytics; retained as a CI artefact
- [ ] Staged rollout enabled, kill-switch flag created, rollback plan written down **before** submitting

### 7.9 What CI must enforce, not just report

The iOS `DELIVERY.md` line to keep on the wall: *"a rule only reviewed by humans decays."* Android's
version of that table is longer, because more of it is actually automatable:

| Rule | Check | Severity |
|---|---|---|
| §2.1 no feature→feature edge | `module-graph-assert` / Konsist | error |
| §2.2 no vendor type across a boundary | Konsist import assertions | error |
| §2.3 no hardcoded user-facing string | lint `HardcodedText`, `MissingTranslation`, `StringFormatInvalid` | error |
| §2.4 no ad-hoc dialog/toast in a feature | custom lint in `:lint-checks` | error |
| §2.5 every content state rendered | screenshot test count per screen | error |
| §2.6 everything injected | Konsist: no stateful `object`, no `EntryPoints` in `feature/` | error |
| §2.7 no `!!`, no swallowed exception | detekt | error |
| §2.8 no `GlobalScope` | detekt `GlobalCoroutineUsage` | error |
| §2.10 no `BuildConfig` in a feature | Konsist | error |
| §2.16 no leaked `Context` | LeakCanary in the instrumented tier + Konsist on ViewModel constructors | error |
| §2.18 no blocking main-thread call | detekt on `runBlocking` outside tests; StrictMode in debug | error |
| §1.1 `minSdk` floor respected | lint `NewApi` | error |
| Dependency surface did not change silently | `dependency-guard` baseline | error |
| Permissions / `minSdk` / `versionCode` did not change silently | `checkReleaseBadging` vs golden file | error |
| APK/AAB size did not regress | `androidArchSizeReport`, threshold on the PR | warn → error above 2% |
| Startup time did not regress | Macrobenchmark on the nightly | warn |
| Inventories are current | `androidArchSyncNotes --check` | error |
| The base install is not stale | `androidArchAdoptReview` exit 1 | warn |
| `CLAUDE.md` section citations resolve | `androidArchCheckSections` (§9.4) | error |

`-Werror` is on for release variants and **off for debug** deliberately — a warning mid-edit should
not block a local run.

---

## 8. Reconciling the two plans

A second design — an *AndroidArch sequencing plan* — exists alongside this one. It is a
Gradle-and-CI plan built bottom-up from a working build; this document is a governance-and-agent
plan built top-down from GenericArch. They disagree in useful ways, and the disagreements are worth
resolving explicitly rather than averaging.

### 8.1 What the sequencing plan gets right, and is now folded in

| Idea | Where it landed |
|---|---|
| **Five public commands, not fifteen tasks** — `doctor`, `check`, `test`, assemble, bundle | §6.3, rewritten around it. The other ~17 tasks are now explicitly *internal* |
| **Never reimplement an AGP task.** `assembleDebug` / `bundleRelease` are Google's; wrap and validate, never replace | §6.3, promoted to a stated rule with the wrapper shape |
| **`androidArchDoctor` first, and its output *is* its spec** — sectioned report, per-row status, a terminal verdict | §6.4, new. Extended to three states and a "next command" line |
| **`check` and `test` stay separate commands** | §6.5. `check` = *safe to merge*; `test` = *do the tests pass* |
| **A dedicated `nightly` workflow** | §7.3. The slow tiers (instrumented, macrobenchmark, size trend) have somewhere to live that is not the PR gate |
| **"Do not continue until `assembleDebug` works"** as a hard prerequisite | §12, now step 0 |
| **Its closing warning** — *the biggest mistake is starting with `check` or CI before a clean, reproducible Gradle build* | §12. This is the single most valuable line in that plan and it reorders this document's build order |

That last one deserves saying plainly: **my original build order started with repo hygiene and
convention plugins and treated build reproducibility as assumed.** It is not assumed — this repo
currently cannot configure without a gitignored file (§11 finding 4). Reproducibility is step 0, and
everything else is downstream of it.

### 8.2 Where the sequencing plan needs hardening

Each of these is a gap, not a disagreement — the plan simply stops before reaching them.

| Gap | Why it matters | Where this document answers it |
|---|---|---|
| **`androidArchCheck` as `dependsOn("lint","test")`** | Does not resolve in a multi-module build, gives no ordering, stops at the first failure, and enforces none of the §2 rules | §6.5 — including why the obvious implementation fails |
| **No architecture enforcement at all** | Nothing prevents a feature→feature import, a hardcoded string, a `!!`, a missing content state. Without Konsist / module-graph-assert / dependency-guard / custom lint, `check` is a formatter with ambitions | §4 §2, §7.9 |
| **`CLAUDE.md` / `AGENTS.md` deferred to the last sprint** | This is backwards for a repo whose stated purpose is being an agent base setup. The context budget, `MAP.tsv`, the notes, the skill-vs-command split and the consent model are the *product*, not a finishing touch | §4, §5 |
| **`manifest.json` named but not specified** | A manifest without hashes and a reseal path is a file list, not a reversible install. Reversibility is what makes the layer safe to adopt | §6.8 |
| **"Don't make it OS-dependent" with no mechanism** | Correct instinct, no teeth. Case sensitivity, CRLF, `MAX_PATH`, exec bits, `JAVA_HOME` drift and locale-dependent string ops each need a specific gate | §7.5 |
| **Secrets as "use CI secrets"** | Does not address the actual blocker: `Properties.load` at configuration time means no CI job can even *configure* this project | §7.6 |
| **No versioning, staged rollout or rollback model** | `versionCode` monotonicity and "promote the artefact that soaked, never rebuild" are where releases actually go wrong | §7.7, §7.8 |
| **Proposes `dev / qa / beta / prod` flavours** | This repo already has `envDev / envQa / envDemo / envProd`. A base that renames what it finds has stopped reading the repo — GenericArch §12: *an existing repo's structure wins* | §2.3 |

Two smaller corrections: the sample doctor output shows **Java 21 / Gradle 9**, while this repo is on
**JDK 17 / AGP 8.12.3 / Gradle 8.14.3** — illustrative, but the doctor must print what it *found*,
never a target. And `tasks.register("androidArchTest") { dependsOn("test") }` has the same
subproject-resolution problem as `check`.

### 8.3 The one real disagreement: reference app, or installable layer?

The sequencing plan says: **build a clean new Android project first**, get it right, then make
AndroidArch installable into existing projects. GenericArch says the opposite, in as many words:
*"There is no 'start from the template' path"* — because a copy no installer wrote has no manifest,
so it cannot be uninstalled, resealed or updated per file.

Both are right about different artefacts, and the resolution is to stop treating them as one thing:

| | Reference app | Installable layer |
|---|---|---|
| **Is** | A real, small, working Android app | Rules, docs, generated inventories, Gradle tasks, CI |
| **Contains Kotlin** | Yes — that is the point | **No** |
| **Answers** | "What does a conforming feature look like?" | "How do I make my repo conform?" |
| **Consumed by** | Reading it, and copying a pattern from it | `androidArchInstall` into a repo that already exists |
| **Lives in** | `androidarch-reference` | `androidarch` |
| **Verified by** | It builds, and `androidArchCheck` passes against it | It installs into the reference app *and* into TalentSure |

The rule that keeps them honest: **the installable layer must never depend on the reference app,
and the reference app gets the layer installed like any other consumer.** The reference app is then
also the layer's own integration test — if `androidArchCheck` cannot pass on the one repo you
control completely, it is not ready to inflict on a repo you do not.

For your situation specifically: **build the layer against TalentSure, not against a new project.**
A greenfield reference app will pass every check on day one and teach you nothing about adoption,
which is the hard part and the only part GenericArch spends its complexity budget on. Build the
reference app later, as documentation, once the rules have survived contact with 555 real Kotlin
files.

### 8.4 Where the two plans agree, and it is worth noticing

Independently arrived at, from different directions:

- **`build-logic/` convention plugins before anything else.** Both plans put it in the first phase.
- **Gradle is the engine; any CLI or CI file is a thin shell over it.**
- **A discovery phase before modification** — the sequencing plan's `docs/GAPS.md`-for-a-new-project
  is the same instinct as GenericArch's `/project-init` → `/gaps` gate.
- **`docs/DECISIONS.md` and `docs/GAPS.md` as separate files.** Why-it-is-this-way and
  what-is-deliberately-absent are different questions, and conflating them is how "we skipped that"
  decays into "we forgot that".
- **CI last.** Both plans refuse to write a pipeline before the thing it runs is reliable.

### 8.5 On the OS-abstraction CLI wrapper

The sequencing plan proposes hiding the wrapper difference behind `./androidarch check` on Unix and
`.\androidarch.ps1 check` on Windows, dispatching internally to `gradlew` / `gradlew.bat`.

The instinct — *one conceptual command* — is right. The implementation is worth pushing back on:
it adds **two OS-specific scripts that must be kept in sync** in order to hide a difference that is
already only cosmetic (`./gradlew` vs `gradlew.bat`, same task name, same behaviour). That is a new
drift surface bought for a saved keystroke, and it is exactly the shape of thing GenericArch's
generated-registry discipline exists to avoid.

Three options, in the order I would pick them:

1. **Document one canonical invocation and let the OS supply the prefix.** Every doc, every CI file
   and every command file writes `./gradlew androidArchCheck`, with a single note that Windows uses
   `gradlew.bat`. Zero new files. This is what §6.3 assumes.
2. **A single JVM launcher** — one `androidarch` script whose only job is to locate and exec the
   wrapper, with `androidarch.bat` generated by a Gradle task rather than hand-maintained. Acceptable
   if the team genuinely wants a shorter verb.
3. **Two hand-written scripts.** Not recommended — and if you do it anyway, `androidArchCheck` must
   remain fully functional without them, so the scripts are convenience and never contract.

Either way the important sentence from that plan holds: **`androidArchCheck` itself stays
OS-independent.** The abstraction is optional; the task's portability is not.

---

## 9. Enhancements over GenericArch

Nine changes worth making, roughly in order of payoff.

**9.1 Cross-platform by construction.** Gradle tasks instead of macOS bash; newline-normalised
hashing; `.gitattributes`; a weekly three-OS matrix; a committed container image. This is the whole
reason to build a separate base rather than translate the iOS one.

**9.2 Machine-checkable architecture rules.** GenericArch's §2 is largely enforced by review;
Konsist, `module-graph-assert`, `dependency-guard`, detekt and custom lint can enforce most of the
Android list. **Every rule you add to §2 should come with the check that enforces it, or an explicit
note that it is behavioural** — that is a discipline the iOS repo half-invented in its `DELIVERY.md`
table and never carried into `CLAUDE.md` itself. Make it structural: §2 gets a third column.

**9.3 Screenshot tests as the content-state gate.** iOS could not afford this; Android can. It turns
the most-violated rule (§2.5) from prose into a diff a reviewer can look at.

**9.4 A citation linter.** The iOS README admits: *"roughly 450 `§N` citations repo-wide resolve
against those headings, and no linter checks them."* That is a known-broken invariant in the most
load-bearing file in the repo. `androidArchCheckSections` should (a) resolve every `§N` and `§N.M` citation
against the actual headings, (b) fail on an orphan, and (c) **print `CLAUDE.md`'s token count and
fail above a declared ceiling** — the context budget is a rule, so measure it.

**9.5 `TASKS.tsv` from verified metadata.** Gradle already knows a task's inputs, outputs and
up-to-date-ness. A registry generated from real metadata cannot drift the way a comment header can.

**9.6 ADRs with a supersede chain.** `DECISIONS.md` as one flat table stops scaling around fifty
rows. Number the decisions (`ADR-0042`), give each a status (`accepted` / `superseded by ADR-0071` /
`declined`), and let `/decide` maintain the chain. Keeps the "why is it this way" answer honest
years later, which is the entire point of the file.

**9.7 One entry point: `androidArchDoctor`.** GenericArch's install flow is four scripts, eleven commands and
several `--flag` combinations documented across three files. Excellent for an operator who has read
the manual; hostile to a new team member on day one. `./gradlew androidArchDoctor` should print: what stack
was resolved, which lifecycle step is next, what is stale, what is failing, and **the exact next
command to run**. One command that tells you the truth about the repo.

**9.8 Cost and time budgets, stated.** Add to `DELIVERY.md`: PR pipeline target < 12 min, and a
declared limit on CI minutes per PR. A pipeline with no stated budget grows until someone starts
skipping it, which is worse than a slower pipeline everyone runs.

**9.9 A `/release` command that emits and never runs.** GenericArch gets this exactly right for its
commit phase (phase 9 *"emits a script and never runs git"*) but leaves release orchestration to
prose. Make it a first-class `EMIT_ONLY` command: it walks the checklist against the diff, then
prints the commands. Nothing about a Play upload should be one inferred tool call away.

**One thing to deliberately *not* change:** the two-skill limit. The temptation on a large Android
repo is a skill per layer. Resist it — the context arithmetic in GenericArch's §3 note is correct,
and a skill that fires on the wrong work is worse than a missing one.

---

## 10. README idea for the new repo

GenericArch's README is genuinely good — seven numbered sections, each with **Usage / Options /
Notes**, and a deliberate refusal to list the scripts by hand because the generated registry cannot
drift. Keep the skeleton. Fix three things: there is no 60-second path for a first-time reader, the
prose density assumes you already know the model, and nothing shows the shape of the thing.

Proposed structure — full skeleton in
`ANDROIDARCH-README.md` (folded into this repo's `README.md`):

```
AndroidArch
  one-line what-it-is  ·  badges (base version, min AGP, min JDK, OS support)
  ── 60-second start ─────────────────────────────────────────────
     3 commands, dry-run first, and what you will see
  ── What this is, and is not ────────────────────────────────────
     a governance layer, not a template. Ships no Kotlin.
  ── The shape ───────────────────────────────────────────────────
     one Mermaid diagram: modules + dependency direction + the gates
  1. Install            usage · options · what it adds and does not · notes
  2. Commands           the table, and why each is a command not a skill
  3. Skills             the two, what fires them, what they stop you doing
  4. CLAUDE.md          the context budget, and the six homes
  5. Upgrade & migrate  manifest, reseal, remove, adopt-review
  6. Tasks              how to FIND a task, never a list of them
  7. Pipeline           the five stages, and the one rule (no logic in CI files)
  8. Reference          "you want to… / read this" table · layout · status
```

The three additions that matter:

- **A 60-second start above everything else.** Dry run, apply, `androidArchDoctor`. A reader who cannot get a
  signal in a minute never reaches §1.
- **One diagram.** The module graph with the dependency arrows and the three gate points marked.
  GenericArch's layout is a code block of filenames; a picture of the *dependency direction* is what
  actually communicates the architecture.
- **An OS-support row in the badges.** It is the differentiator. Say it in the first screen.

And keep GenericArch's best README decision verbatim: **no table of tasks.** The registry is
generated; a hand-written list is the one place the README could drift. Teach the grep instead.

---

## 11. Findings in this repo right now

Independent of whether you build the base, these are real and cheap to fix.

| # | Finding | Where | Fix |
|---|---|---|---|
| 1 | **`.claude/command/` is singular — Claude Code never loads it.** The `build.md` you wrote is dead weight | `.claude/command/build.md` | Rename the directory to `.claude/commands/` |
| 2 | **Release AABs are sitting in the source tree** — `app/envDev/release/`, `app/envQa/release/` (multiple copies, `(2)`, `(3)`, `(4)`), `app/envDemo/release/` | `app/env*/release/` | Delete them; add `app/env*/` to `.gitignore`. `*.aab` is ignored but the surrounding `BundleConfig.pb`/metadata is not |
| 3 | **`.claude/worktrees/` contains three full checkouts** including `.gradle` caches | `.claude/worktrees/` | Add `.claude/worktrees/` to `.gitignore` |
| 4 | **The build throws at configuration time if `secret.properties` is missing** — no CI job can configure the project, and it breaks the configuration cache | `app/build.gradle.kts:16` | The `Provider`-based secrets source in §7.6 |
| 5 | **`secret.properties` lives under `src/main/`** — a source directory. It is not packaged today, but it is one `sourceSets` edit away from being in the APK | `app/src/main/secret.properties` | Move it to the module root or `~/.gradle/gradle.properties` |
| 6 | **No formatter, no static analysis.** No Spotless, ktlint, detekt or Konsist anywhere in the build | — | Add via a convention plugin — the cheapest single quality win available |
| 7 | **No CI at all.** No `.github/`, no `.gitlab-ci.yml`, no `fastlane/` | — | Stage 1 from §7.3 alone; a day's work |
| 8 | **`versionCode` is a literal** (`202636101`) | `app/build.gradle.kts:31` | §7.7 — move the counter to CI |
| 9 | **No `debug` build type block** — only `release` is configured, so debug takes defaults | `app/build.gradle.kts` | Declare it explicitly: `isMinifyEnabled = false`, `applicationIdSuffix`, `pseudoLocalesEnabled = true` |
| 10 | **`:app` holds 263 Kotlin files** — every feature's presentation code in one module, so §2.1 is unenforceable | `app/src/main/.../presentation/` | §3.2 phase 4 — new features as `:feature:*`, existing ones migrate opportunistically |
| 11 | **`:testing` exists but is nearly empty** (4 files) — the fake/fixture layer that makes "no network in tests" enforceable is not built yet | `testing/` | Grow it as phase 1; it is the prerequisite for the testing tiers in §4 |
| 12 | **No `.gitattributes`** — line endings are whatever each developer's git decides | — | §6.5 |

Items 1, 2, 3 and 12 are minutes. Items 6 and 7 are the ones that change how the repo behaves.

---

## 12. Build order

### Step 0 — the prerequisite, and it is not optional

> **Do not build any of this until `./gradlew assembleEnvDevDebug` and
> `./gradlew bundleEnvProdRelease` are reliable and reproducible on a clean checkout, on at least
> two different machines.**

This is the strongest point the AndroidArch sequencing plan makes, and it reorders everything below
it: *the biggest mistake is starting with `check` or CI before you have a clean, reproducible Gradle
build.* A quality gate on an unreliable build does not report code quality — it reports build
flakiness, and the team learns to ignore it within a fortnight.

Right now this repo fails step 0 for a specific, fixable reason: `app/build.gradle.kts:16`
loads `secret.properties` at configuration time and throws if it is absent, so a clean checkout
cannot configure at all (§11 finding 4). Fix that first. Then confirm:

```bash
git clone <repo> /tmp/clean && cd /tmp/clean && ./gradlew assembleEnvDevDebug
```

If that fails on a machine that has never built this project, nothing after this line is worth
starting.

### The order

Each step is independently useful — nothing here needs the next step to pay off.

| Step | Work | Done when | Sprint |
|---|---|---|---|
| 0 | **Reproducible build.** Findings 4, 5, 1, 2, 3, 12 from §11 | A clean clone builds debug and release with no hand-placed files | 1 |
| 1 | `build-logic/` with three convention plugins; Spotless + detekt wired in | Every module build file is under ~30 lines | 1 |
| 2 | `androidArchDoctor` (§6.4) | It prints the truth about the repo, including what is deliberately absent | 2 |
| 3 | `androidArchTest`, then `androidArchCheck` (§6.5) — **in that order** | One run reports every violation, not the first one | 2 |
| 4 | Secrets provider (§7.6) + `androidArchMaterialiseSecrets` | The project configures on a machine with no `secret.properties` | 2 |
| 5 | Stage 1 `pull-request.yml` (§7.3) | A PR gets a green check without a human running anything | 3 |
| 6 | `CLAUDE.md` §0–§18 (§4) + `docs/` skeleton + `MAP.tsv` | `grep -i navigation .claude/MAP.tsv` answers | 3 |
| 7 | `androidArchFind`, `androidArchStep`, `TASKS.tsv` (§6.6) | `androidArchDoctor` ends with the correct next command | 3 |
| 8 | `androidArchSyncNotes` + the eleven generators (§5.2) | `notes/STRINGS.md` shows the DE/TR parity gaps you have today | 4 |
| 9 | Konsist + module-graph-assert + dependency-guard | §2.1, §2.2, §2.6 and §2.10 fail the build instead of the review | 4 |
| 10 | Screenshot tests on `:core:designsystem`, then per feature | Every `ContentState` has a golden image | 4 |
| 11 | `main.yml` + `nightly.yml` + Firebase App Distribution | QA always has the latest `develop` and nobody uploads by hand | 5 |
| 12 | `release.yml`, Play publishing, badging golden file, staged rollout | A tag reaches the internal track with no manual step | 5 |
| 13 | Install/uninstall/reseal/remove + manifest (§6.8); extract the base to its own repo | A second Android repo can adopt it | 6 |
| 14 | The reference app (§8.3), and `.claude-plugin/` for multi-repo distribution | Tooling fixes reach every repo by updating one plugin | 6 |

### Two things to notice about this order

**`androidArchTest` before `androidArchCheck`** (step 3). The sequencing plan puts `check` first and
`test` second in one place and the reverse in another; the reverse is right. `test` is a thin,
honest wrapper over tasks that already exist, so it works on day one and gives you a real signal.
`check` is the one that needs Spotless, detekt, Konsist and a summary reporter behind it — build it
second, on top of a `test` you already trust.

**Steps 13–14 only matter once a *second* Android repo needs this.** The install manifest, the
uninstaller and the plugin are what make a layer adoptable by strangers; they are pure overhead
while there is exactly one consumer. GenericArch's own history — four installers, nine supported
uninstall versions, a tombstone ledger — is the argument for not building them earlier than you
have to.

Steps 0–5 are the ones with a payoff measured in days.
