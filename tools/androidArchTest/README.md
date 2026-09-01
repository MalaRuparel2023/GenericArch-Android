# androidArchTest

**Answers:** *do the tests pass?*

| | |
|---|---|
| Shell entry point | [`scripts/androidArchTest.sh`](../../scripts/androidArchTest.sh) — **working** |
| Gradle task | `./gradlew androidArchTest` — **not implemented yet** |
| Effects | runs tests — **consent-gated**; invoking it is the consent, for that run only |
| Exit | `0` pass · non-zero on any failing tier |

## The tiers, cheapest first

| Tier | Device | Task | Covers |
|---|---|---|---|
| Architecture | none | `konsistTest` | The rules in `android/rules/`, as executable assertions |
| Unit | none | `testDebugUnitTest` | ViewModels, mappers, use cases, repositories against fakes |
| Screenshot | none | `verifyPaparazziDebug` | Every content state — light, dark, RTL, 200% font |
| Robolectric | none | `testDebugUnitTest` | Anything needing a shallow Android runtime |
| Instrumented | **yes** | `connectedDebugAndroidTest` | Opt-in only — merge and nightly, never every push |

The first four need no device, no emulator and no KVM. That is what makes "every content state, in
every theme, on every PR" affordable to *enforce* rather than merely recommend — and it is the
single biggest structural advantage Android has over iOS for a framework like this one.

## Two rules

- **No network in tests**, enforced by requiring a test double for every binding — not by convention.
- **Every module tests standalone.** That property, not the folder layout, is what enforces the
  module boundaries.

Run with `--continue` so one invocation reports every failing tier.
