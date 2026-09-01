# BUILD-PROCESS — getting a build on a machine

Loaded only when the task is building. The daily surface is five commands (`README.md`); this file
is what you read when one of them does not work.

## Requirements

JDK 17 and the committed Gradle wrapper. Nothing else — no bash, no `sed`, no `shasum`. The JDK is
provisioned by Gradle toolchains (`jvmToolchain(17)` + the foojay resolver), so a mismatched
`JAVA_HOME` is not a build input.

```bash
./gradlew androidArchDoctor
```

Read its output as the spec: three sections, three states — `✓ ok` · `⚠ drift or opportunity` ·
`✗ blocking`. Exit is non-zero only on a `✗`, so a warning never blocks a developer, and CI can
still gate on it.

## Building

```bash
./gradlew assembleEnvDevDebug
```
```bash
./gradlew bundleEnvProdRelease
```

**These are AGP's tasks and they are never reimplemented.** This layer gates and validates around
them. If a wrapper task starts *configuring* the build rather than gating it, delete the wrapper and
move the configuration into a convention plugin.

## Consent

Assembling is free — do it on your own initiative to validate a change. `installDebug`,
`connectedAndroidTest`, launching an emulator and `test` are consent-gated (`CLAUDE.md` §2.12).
Typing `/build` is that consent, for the run it names only.

## Cross-OS traps

Each has a mechanical gate, not a wiki page:

| Trap | Symptom | Gate |
|---|---|---|
| Case sensitivity | Builds on Windows/macOS, fails on Linux CI | Linux is the *primary* runner, so it is caught first, always |
| Line endings | Manifest hashes fail; scripts get CRLF | `.gitattributes` + newline-normalised hashing |
| `gradlew` exec bit lost | `Permission denied` on Linux after a Windows commit | `git update-index --chmod=+x gradlew`, checked by `androidArchCheck` |
| Windows `MAX_PATH` (260) | Cryptic KSP/R8 failures deep in `build/` | Short checkout dir + long-path support; the weekly matrix job catches regressions |
| Hardcoded path separators | Works on one OS only | detekt rule; use `layout.projectDirectory.file(...)` |
| `JAVA_HOME` drift | Different bytecode per developer | Gradle toolchains |
| Locale-dependent string ops | `toUpperCase()` differs under `tr-TR` | detekt: `Locale.ROOT` required on every case conversion |
| Timezone-dependent tests | Green locally, red on a UTC runner | Inject a `Clock`; ban `System.currentTimeMillis()` in domain code |
| Non-reproducible resolution | Different transitive versions per machine | `gradle/verification-metadata.xml`; no dynamic versions |
| Daemon file locks (Windows) | Random `Could not delete` | `--no-daemon` in CI only — never locally, where it costs minutes |

## Secrets at configuration time

The project **must configure on a machine with no secrets file.** A `Properties.load` at
configuration time that throws when the file is missing means no CI job can configure the project,
and it breaks the configuration cache. Secrets are read through a `Provider` — environment variable,
then Gradle property, then a local file, then a documented failure. See `DELIVERY.md`.
