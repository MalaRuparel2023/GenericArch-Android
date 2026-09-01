# androidArchCheck

**Answers:** *is this code safe to merge?*

| | |
|---|---|
| Shell entry point | [`scripts/androidArchCheck.sh`](../../scripts/androidArchCheck.sh) — **working**, 9 checks |
| Gradle task | `./gradlew androidArchCheck` — **not implemented yet** |
| Rule source | [`android/rules/`](../../android/rules/) |
| Exit | `0` clean · `1` any error-severity violation · `2` usage |

## Contract

**Report every violation, not the first.** A gate that stops at the first failure teaches you about
the lint error and hides the four test failures behind it, and a team learns to distrust it within a
fortnight.

```
androidArchCheck

  ✓ Formatting        spotless           0 files
  ✓ Static analysis   detekt             0 issues
  ✗ Lint              lintEnvDevDebug    3 errors   (HardcodedText ×3)
  ✗ Architecture      konsist            1 failure  (feature:jobs → feature:profile)
  ✓ Dependencies      dependency-guard   unchanged

  FAILED — 4 violations across 2 checks
```

## The implementation trap

```kotlin
// DON'T
tasks.register("androidArchCheck") { dependsOn("lint", "test") }
```

In the root project `"lint"` resolves against the **root**, reaches no subproject, and gives no
ordering and no aggregate report. Depend on the resolved subproject tasks instead, and run CI with
`--continue`:

```kotlin
dependsOn(
    subprojects.mapNotNull { it.tasks.findByName("spotlessCheck") },
    subprojects.mapNotNull { it.tasks.findByName("detekt") },
    subprojects.mapNotNull { it.tasks.findByName("lintDebug") },
)
```

## Two rules

- **`check` and `test` stay separate.** `check` answers *safe to merge* in seconds; `test` answers
  *do the tests pass* in minutes. Merging them makes the fast signal wait on the slow one.
- **Expected to fail on an existing codebase.** It is a baseline, not a verdict. Baseline the debt or
  fix one category at a time — never silence a rule by deleting it.
