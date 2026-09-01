# examples/multi-module-app

The full shape: a thin composition root, two features that never speak to each other, and the core
layer they both stand on.

**Status: not built yet.** This directory holds the specification.

## What it will demonstrate

```
:app                    composition root — DI graph, NavHost, theme. Nothing else
:feature:catalog        a paged list
:feature:profile        a form and a detail screen
:core:designsystem      tokens and components
:core:navigation        route contracts
:core:network           the Retrofit wrapper — the only module declaring it
:core:model             pure Kotlin, no Android SDK
:testing                the fakes both features test against
```

## The three things it proves

1. **`:feature:catalog` and `:feature:profile` never import each other**, yet one navigates to the
   other — by route value, resolved in `:app`. This is the rule that is easiest to state and hardest
   to hold, so the example exists mainly to show it holding.
2. **Every module builds and tests standalone** — `./gradlew :core:network:test` with no `:app`.
3. **Swapping a vendor touches exactly one module.** The example includes the diff for replacing
   Retrofit with Ktor: `:core:network` only, no feature changed, no test changed.

## What it deliberately does not demonstrate

A real backend, authentication, or a design language worth copying. An example that tries to be a
product stops being readable, and nobody learns the architecture from it.
