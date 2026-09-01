# CONVENTIONS

Enforced by Spotless + detekt where a machine can. The three that are **rules** rather than
conventions live in `CLAUDE.md` §10 — `internal` by default, KDoc on public API, no narration
comments.

## Naming

| Thing | Form | Example |
|---|---|---|
| Module | `:core:<noun>` · `:feature:<noun>` | `:core:network`, `:feature:profile` |
| Composable screen | `<Feature>Screen` | `ProfileScreen` |
| Stateful/stateless pair | `<Name>Route` / `<Name>Screen` | `ProfileRoute` / `ProfileScreen` |
| ViewModel | `<Feature>ViewModel` | `ProfileViewModel` |
| UI state | `<Feature>UiState` | `ProfileUiState` |
| Route class | `<Feature>Route`, `@Serializable` | `ProfileRoute(val userId: String)` |
| Interface / impl | capability noun · `<Impl>` | `TokenRefreshing` / `RetrofitTokenRefresher` |
| Fake | `Fake<Interface>` | `FakeTokenRefreshing` |
| String key | `<feature>_<context>_<meaning>` | `profile_header_title` |
| Test | `methodName_condition_expectedResult` | `load_offline_emitsOfflineState` |

## File layout

One public type per file, named for it. Inside a feature module:

```
feature/<name>/src/main/kotlin/<pkg>/
  <Name>Route.kt      navigation entry + hoisted state
  <Name>Screen.kt     stateless composables
  <Name>ViewModel.kt  StateFlow<UiState>, no Android types beyond SavedStateHandle
  <Name>UiState.kt    every content state, sealed
  di/                 the module's Hilt bindings
```

## Kotlin

- Expression bodies for single-expression functions; no `return` block for one line.
- Data classes for state, sealed interfaces for closed sets, value classes for typed ids.
- Trailing commas on multi-line argument lists.
- Named arguments once a call has more than two parameters, or any boolean.
- Extension functions over util objects. No `*Utils` class.

## Compose

- Stateless composables take data and lambdas — never a ViewModel.
- `Modifier` is the first optional parameter, defaulted, and is passed to the root node.
- No side effect outside `LaunchedEffect` / `DisposableEffect` / `rememberCoroutineScope`.
- Preview per content state, and the preview is what the screenshot test renders.

## KDoc

State what the signature cannot: units, ownership, cancellation, whether it touches IO, what an
empty result means. Never restate the parameter list.
