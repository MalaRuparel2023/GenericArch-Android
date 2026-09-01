# DEPENDENCIES

## The dependency rule

**Every edge points downward.** No sideways edges, no upward edges, no cycles — at any depth,
including transitively.

| Edge | Legal | Why |
|---|---|---|
| `:app → :feature:profile` | yes | The composition root wires features in |
| `:feature:jobs → :core:network` | yes | Downward |
| `:feature:jobs → :feature:profile` | **no** | Sideways — the change that makes both unshippable alone |
| `:core:network → :feature:jobs` | **no** | Upward — core would then know about a screen |
| `:core:model → androidx.*` | **no** | The floor stays pure Kotlin |

Wired with type-safe project accessors and **no version numbers on internal edges**:

```kotlin
implementation(projects.core.model)
```

## Why sideways is the one that matters

A sideways edge is the cheapest bad decision in an Android codebase and the most expensive to
reverse. Once `:feature:jobs` imports `:feature:profile`, neither module builds alone, neither tests
alone, and the two ship as one. Six months later they are one module in everything but name.

The three legal ways for one feature to reach another:

1. **A `:core` interface.** The capability moves down; both features depend on the abstraction.
2. **Navigation by route value.** Feature A emits a route; the `NavHost` in `:app` resolves it.
   No compile-time edge exists.
3. **A shared model in `:core:model`.** Data, not behaviour.

## Third-party dependencies

**A vendor SDK is declared in exactly one module — its wrapper.** Not "should be"; it is a
`build.gradle.kts` fact, and [`../rules/dependency-rules.yaml`](../rules/dependency-rules.yaml)
asserts it.

- Our types at the boundary. No vendor enum, model or exception crosses it.
- Swapping a vendor must touch **exactly one module**. If it touches two, the wrapper leaked.
- A new dependency is a decision, taken before it is added: does it need a wrapper, and what is its
  APK-size cost?

## Version management

- One version catalogue: [`../gradle/libs.versions.toml`](../gradle/libs.versions.toml).
- **No hardcoded version in a module build file.** Ever.
- **No dynamic versions** (`+`, `latest.release`) — they make the build non-reproducible across
  machines, which quietly destroys the value of every other check here.
- `gradle/verification-metadata.xml` is committed, so a changed artefact fails the build rather than
  silently entering it.

## Checking it

```bash
./scripts/androidArchCheck.sh --rules android/rules/dependency-rules.yaml
```
