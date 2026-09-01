# docs/modules/ — one row per module

Written per adopting repo, not shipped by the base. One file per module, named for it
(`Core-Network.md`, `Feature-Profile.md`).

## Template

```markdown
# :core:network

**Owns** HTTP transport, auth token refresh, error mapping to our types.
**May depend on** :core:model, :core:common.
**Must not** know about a feature, a screen, or the design system.
**Public API** the interfaces that cross the boundary — everything else is `internal`.
**Vendors wrapped** Retrofit, OkHttp. This is the only module declaring them (§7).
**Test doubles** FakeApiClient, FakeTokenRefreshing — in :testing.
**Exported components / permissions** none.
**Gotchas** token refresh is single-flight; concurrent 401s must not each trigger a refresh.
```

## Rules

- A module without a row is a module nobody can reason about — add the row in the change that
  creates the module.
- `Must not` is the load-bearing line. It is what makes a review objection citable rather than
  personal.
- Dependency edges here must match the module graph. `androidArchCheckLinks` compares them.
