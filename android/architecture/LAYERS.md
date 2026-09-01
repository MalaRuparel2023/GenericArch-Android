# LAYERS

Four layers. A layer may depend only on the ones below it.

```
┌─────────────────────────────────────────────────────────┐
│  :app                composition root — thin            │
│                      DI graph, NavHost, Application     │
├─────────────────────────────────────────────────────────┤
│  :feature:*          one user-facing capability each    │
│                      UI + ViewModel + feature DI        │
├─────────────────────────────────────────────────────────┤
│  :core:*             shared capability, no screens      │
│                      designsystem, navigation, network, │
│                      database, datastore, logging       │
├─────────────────────────────────────────────────────────┤
│  :core:model         pure Kotlin — no Android SDK       │
│  :core:common        no dependencies at all             │
└─────────────────────────────────────────────────────────┘
```

## `:app` — the composition root

Holds the `Application` class, the Hilt graph, the `NavHost`, and the theme wiring. **Nothing else.**
Every screen it shows lives in a feature module. If `:app` grows business logic, the architecture has
already failed — that is the symptom the layering exists to make visible.

Configuration — build type, flavour, environment — is read **here, once**, and injected downward as
an `AppEnvironment`. A feature must never read `BuildConfig`.

## `:feature:*` — one capability each

A feature owns its screens, its ViewModels, its UI state and its own DI bindings. Its public surface
is a route class and, where another part of the app must trigger it, a `:core` interface it
implements.

**A feature never imports a sibling feature.** When feature A needs something feature B has, the
capability moves down into `:core` as an interface — or A navigates to B by route *value*, which
carries no compile-time edge.

## `:core:*` — shared capability

Anything two features would otherwise duplicate: the design system, navigation primitives, network
transport, persistence, logging, and the wrappers around third-party SDKs.

A core module knows **nothing about any screen**. If it needs a `:core:designsystem` theme to
function, it is not a core capability — it is a feature.

## `:core:model` and `:core:common` — the floor

Pure Kotlin. `:core:model` declares no Android SDK dependency; `:core:common` declares no
dependencies at all. They are the only modules every other module may depend on, which is exactly
why nothing may be added to them casually.

## The test for which layer something belongs in

1. **Does it know about a screen?** → feature.
2. **Would a second product want it unchanged, with no theme?** → core.
3. **Is it a vendor's type?** → a wrapper module, and only that module declares the vendor.
