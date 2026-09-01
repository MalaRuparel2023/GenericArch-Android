# MODULES

## Naming and placement

| Kind | Path | Gradle path |
|---|---|---|
| Composition root | `app/` | `:app` |
| Feature | `feature/<name>/` | `:feature:<name>` |
| Shared capability | `core/<name>/` | `:core:<name>` |
| Vendor wrapper | `core/<vendor-capability>/` | `:core:imageloader`, `:core:analytics` |
| Test doubles | `testing/` | `:testing` |
| Custom lint rules | `lint-checks/` | `:lint-checks` |

Names are **nouns describing a capability**, not a layer or a pattern: `:core:network`, not
`:core:data`; `:feature:profile`, not `:feature:profilePresentation`.

## Every module declares its contract

One row per module in `docs/modules/<Module>.md`:

```markdown
# :core:network

**Owns** HTTP transport, auth token refresh, error mapping to our types.
**May depend on** :core:model, :core:common.
**Must not** know about a feature, a screen, or the design system.
**Public API** the interfaces that cross the boundary — everything else is `internal`.
**Vendors wrapped** Retrofit, OkHttp. The only module declaring them.
**Test doubles** FakeApiClient, FakeTokenRefreshing — in :testing.
**Gotchas** token refresh is single-flight; concurrent 401s must not each trigger one.
```

**`Must not` is the load-bearing line.** It is what turns a review objection from a matter of taste
into a citable fact.

## Adding a module

1. Create the directory and its `build.gradle.kts`, applying **one convention plugin** — never a
   hand-rolled android block.
2. One line in `settings.gradle.kts`.
3. Its `docs/modules/` row, in the same change.
4. **Zero edits to any other feature.** If a sibling has to change, the design is wrong, not the
   sibling.

## Every module builds and tests standalone

This is the property that actually enforces the boundaries — not the folder layout, not the review.
A module that only compiles as part of `:app` has no boundary at all.

```bash
./gradlew :core:network:assemble :core:network:test
```

## Visibility

`internal` by default. `public` only for what genuinely crosses the module boundary, and everything
public carries KDoc stating what the signature cannot — units, ownership, cancellation, whether it
touches IO, what an empty result means.

## Extracting a module to its own repository

All four must hold, and it is a decision, not a refactor:

1. Product-independent · 2. actually reused · 3. stable API · 4. **works with no
`:core:designsystem` theme.**
