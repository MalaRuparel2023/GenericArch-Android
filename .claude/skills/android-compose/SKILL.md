---
name: android-compose
description: Use when writing or fixing Jetpack Compose UI - "build this screen", "make this composable", "hoist state", "why does it recompose", "the list janks", "preview", "theme this", "make it accessible", "adapt for tablet", "LaunchedEffect", "remember", "Modifier order". Not for Gradle work and not for architecture placement questions.
---

# android-compose

## 1. Two composables per screen, always

```kotlin
@Composable
fun ProfileRoute(viewModel: ProfileViewModel = hiltViewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    ProfileScreen(state = state, onRetry = viewModel::retry)
}

@Composable
fun ProfileScreen(state: ProfileUiState, onRetry: () -> Unit, modifier: Modifier = Modifier) { … }
```

The route holds the ViewModel; the screen takes **data and lambdas only**. That split is what makes
the screen previewable, screenshot-testable, and reusable in a different navigation host — and it
costs nothing.

`collectAsStateWithLifecycle()`, never `collectAsState()`, for anything lifecycle-sensitive.

## 2. Every state, not the happy path

A sealed `UiState` with a branch for each: idle, loading, empty, offline, error, loaded, and the
paging footer states. **The states nobody demos are the states users hit first** — an empty list on
day one, an error on a train.

One `@Preview` per state, and the preview is what the screenshot test renders. Write the previews as
you write the branches, not afterwards.

## 3. Modifier discipline

- `modifier: Modifier = Modifier` is the **first optional parameter**, and it is applied to the root
  node — not to an inner child, which silently drops half of what callers pass.
- Order matters: `padding` before `background` paints a smaller box than after it.
- Never store a `Modifier` in a field or a state holder.

## 4. Side effects

| Need | Use |
|---|---|
| Run on first composition, or when a key changes | `LaunchedEffect(key)` |
| Clean something up | `DisposableEffect` |
| React to a click | `rememberCoroutineScope()` |
| Read state without recomposing | `rememberUpdatedState` / `derivedStateOf` |

Nothing that touches the outside world happens in a composable body directly. If it is not in an
effect, it runs on every recomposition — which is not a schedule you control.

## 5. Recomposition

When a screen janks, the metrics are already written — `build/compose-metrics/`, produced by the
Compose convention plugin. The usual three causes:

1. **An unstable parameter** — a `List` instead of an `ImmutableList`, a class from a module the
   compiler cannot see.
2. **A lambda allocated per recomposition** — pass a method reference, or `remember` it.
3. **Reading state too high** — a value read in a parent recomposes the whole subtree. Read it where
   it is used, or defer with a lambda.

Measure before optimising. A `key` added on a hunch usually moves the problem rather than fixing it.

## 6. Accessibility is a requirement, not polish

- Every interactive element ≥48 dp, with a `contentDescription` or an explicit `clearAndSetSemantics`.
- **Never encode meaning in colour alone** — pair it with an icon, text or shape.
- Text scales to 200% without clipping. Test it; `fontScale` is a preview parameter.
- Check the TalkBack traversal order, and say so plainly when you could not check it here.

## 7. Adaptivity

Branch on `WindowSizeClass` and on feature availability — **never** `Build.MODEL`, a width-in-dp
constant, or an `isTablet` boolean. Navigation state is data, so a size change re-renders rather
than re-navigating.

## 8. Theme

Colours, type and spacing come from the design system's tokens. A `Color(0xFF…)` literal inside a
feature is a finding — it is invisible in dark mode review and it drifts the moment the palette
changes.
