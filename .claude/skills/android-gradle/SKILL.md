---
name: android-gradle
description: Use for Android Gradle build work - "add a dependency", "the build fails", "write a convention plugin", "version catalogue", "libs.versions.toml", "build.gradle.kts", "upgrade AGP", "add a flavour", "configuration cache", "why is the build slow", "KSP", "ProGuard rules". Not for writing app code, tests or UI.
---

# android-gradle

Build logic is code, and it rots faster than app code because nobody tests it. Two habits prevent
most of that: **configuration lives in one convention plugin, versions live in one catalogue.**

## 1. Never edit a module build file to add configuration

If a `build.gradle.kts` is growing an `android { }` block, the configuration belongs in a convention
plugin — `android/gradle/conventions/`. A module build file should declare only what is unique to
that module: its plugins, its dependencies, and nothing else.

```kotlin
plugins {
    id("genericarch.android.library")
    id("genericarch.android.compose")
}

dependencies {
    implementation(projects.core.model)
    implementation(libs.retrofit.core)
}
```

Every module build file under ~30 lines is the target, and it is achievable.

## 2. Every version is an alias

```kotlin
implementation(libs.retrofit.core)        // yes
implementation("com.squareup.retrofit2:retrofit:2.11.0")   // no
```

- **No version in a module build file.** Ever.
- **No dynamic versions** (`+`, `latest.release`) — they make the build non-reproducible across
  machines, which quietly destroys the value of every check that runs on it.
- **Never quote a version from memory.** Read `libs.versions.toml`, or run
  `./scripts/androidArchDoctor.sh`.

## 3. Before adding a dependency

Four questions, in order:

1. **Which module declares it?** A vendor is declared by exactly one module — its wrapper. If two
   need it, the wrapper is what they share, not the vendor.
2. **Does it need a wrapper at all?** Anything whose types would otherwise cross a module boundary
   does.
3. **What does it cost?** APK size, method count, and a transitive tree you now own.
4. **Is this a decision someone should make?** A new dependency usually is.

Read the target module's build file before adding the edge. If it points sideways or upward, stop
and say so rather than adding it.

## 4. Configuration-time traps

| Trap | Why it hurts |
|---|---|
| Reading a file at configuration time | Breaks the configuration cache, and throws on any machine without the file — including every CI runner |
| `System.getenv()` directly | Not tracked as an input; use `providers.environmentVariable(...)` |
| Anything that throws when a secret is absent | The project cannot even configure. Read secrets through a `Provider` with a documented failure |
| Hardcoded path separators | Works on one OS. Use `layout.projectDirectory.file(...)` |

## 5. When the build fails

1. Read the **actual error**, not the summary line — Gradle's real cause is usually four frames down.
2. `./gradlew <task> --stacktrace` for a plugin failure, `--info` for a task that runs when it should
   not.
3. Reproduce on a clean checkout before blaming the code: a warm cache hides more build bugs than it
   causes.
4. `./scripts/androidArchDoctor.sh` — most "it built yesterday" reports are a toolchain drift the
   doctor names in one row.

## 6. Never reimplement an AGP task

`assembleDebug` and `bundleRelease` are Google's, they are correct, and they keep working across AGP
upgrades. Wrap and validate around them; never replace them.
