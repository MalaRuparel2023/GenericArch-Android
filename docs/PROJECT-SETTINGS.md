# PROJECT-SETTINGS — the configuration surface

Loaded only when the task is configuration. Everything here is a *product* fact, so in an adopting
repo these tables are filled from that repo and re-generated into `.claude/notes/` — never quoted
from memory.

## SDK levels

| Setting | Value | Owned by | Changing it |
|---|---|---|---|
| `compileSdk` | latest stable | the toolchain | Routine, with a build pass |
| `targetSdk` | — | Product + engineering | Deliberate, with a behaviour-change test pass |
| `minSdk` | — | **Product (§0)** | Never defaulted; name the devices dropped and the APIs unlocked |

Resolved values: `.claude/notes/PROJECT.md`, from `./gradlew androidArchDoctor`.

## Permissions

Every permission needs three things before it lands: a **runtime rationale** shown to the user, a
**Play Console declaration** where required, and a **graceful-denial path** that keeps the app
usable. New permissions are a §0 question and are diffed against a badging golden file in CI, so one
cannot arrive silently.

Inventory: `.claude/notes/PERMISSIONS.md` — merged manifest, exported components, deep-link intent
filters, `autoVerify` status.

## Exported components and deep links

- Every `android:exported="true"` carries a stated reason in the module's `docs/modules/` row.
- Deep links are verified App Links (`android:autoVerify="true"`) with `assetlinks.json` served, or
  they are hijackable. A deep link that opens the browser is a verification failure, not a routing
  bug.

## Backup and data safety

`android:allowBackup` and the backup rules are a data-leak surface with no iOS equivalent. State
explicitly what is excluded from backup, and keep the Play Data Safety declaration in step with what
the app actually collects.

## Network security

Network security config, certificate pinning and cleartext policy are declared here, per flavour.
Pinning without a documented rotation plan is an outage waiting for a certificate renewal.

## Variants

Flavours × build types × signing configs × `buildConfigField`s × `manifestPlaceholders`:
`.claude/notes/VARIANTS.md`. A new flavour dimension multiplies every build task and CI minute — it
is a §0 question.
