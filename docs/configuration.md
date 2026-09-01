# Configuration

Everything the framework enforces is data in [`android/rules/`](../android/rules/). Changing what is
enforced means editing YAML, not patching a script.

## The three rule files

| File | Holds |
|---|---|
| `architecture-rules.yaml` | The rules a machine can decide — imports, symbols, states, severities |
| `dependency-rules.yaml` | Layers, legal edges, vendor containment, version policy |
| `module-rules.yaml` | Naming, what a module must declare, what a feature must contain |

All three are read by the local script, the Gradle check and the CI workflow. **One source, three
enforcement points** — three copies would be three drifting approximations of a rule nobody can
state.

## Severity

```yaml
- id: ARCH-017
  name: Every screen survives process death
  severity: warning      # error | warning | info
```

| Severity | Effect |
|---|---|
| `error` | fails the build |
| `warning` | reported, does not fail |
| `info` | counted only |

**Downgrading a rule is a decision, not a config tweak.** Record why, next to the change — a
severity that drops with no reasoning attached goes back up in six months, and the argument is had
again from scratch.

## Adopting into a codebase that already breaks the rules

`androidArchCheck` is *expected* to fail on day one. Two honest strategies:

**Baseline the debt.** Gate only on new violations. Fast to adopt; the existing debt becomes
invisible unless you track the count.

**Fix a category at a time.** Set the rule to `warning`, drive the count to zero, then flip it to
`error` in the same PR that removes the last violation. Slower; the ratchet never slips.

Never delete a rule to make a build green. A rule you cannot hold today is a `warning` with a note,
not an absence.

## Adding your own rule

```yaml
- id: TEAM-001
  name: No java.util.Date in domain code
  severity: error
  rationale: Timezone-dependent tests are green locally and red on a UTC runner.
  applies_to: "core/**"
  forbid_symbol: ["java.util.Date", "System.currentTimeMillis"]
  remedy: Inject a Clock.
  enforced_by: [detekt]
```

Every field except `enforced_by` is required. **`rationale` most of all** — a rule whose reason is
not written down is a rule that gets deleted by whoever it first inconveniences.

## Versions

[`android/gradle/libs.versions.toml`](../android/gradle/libs.versions.toml) is a **starting point,
not an assertion**. Reconcile it with your machine before relying on it:

```bash
./scripts/androidArchDoctor.sh
```

Two rules bind regardless of which versions you land on:

1. **No version in a module build file.** Every one is an alias from the catalogue.
2. **No dynamic versions** (`+`, `latest.release`). They make the build non-reproducible across
   machines, which silently destroys the value of every other check here.

## Product decisions the framework will not make

`minSdk`, presentation pattern, persistence engine, caching policy, paging, flavours, permissions.
Record each one where your team will find it — with the options considered, the reason, and the
trigger that would justify revisiting it.
