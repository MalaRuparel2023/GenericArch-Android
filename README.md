# GenericArch-Android

A **reusable Android architecture framework**: the layer rules, the module contracts, the Gradle
conventions that make them the default, and the checks that fail a build when they are broken.

![status](https://img.shields.io/badge/status-early-orange)
![jdk](https://img.shields.io/badge/JDK-17-green)
![os](https://img.shields.io/badge/OS-Linux%20%7C%20Windows%20%7C%20macOS-brightgreen)
![license](https://img.shields.io/badge/license-MIT-blue)

It is a layer you **install into a project that already builds** — not a template you start from. A
template rots the day your app diverges from it; a layer that reads your repo instead of prescribing
it stays true.

---

## Quick start

```bash
git clone https://github.com/MalaRuparel2023/GenericArch-Android.git
```
```bash
./scripts/androidArchDoctor.sh /path/to/your/app
```
```bash
/path/to/GenericArch-Android/scripts/install.sh --target /path/to/your/app --apply --with-ci
```
```bash
./scripts/androidArchCheck.sh
```

The doctor tells you whether the ground is solid. The install writes nothing without `--apply` and
never overwrites a file you have edited. **The first check is expected to fail** on an existing
codebase — that is a baseline, not a verdict.

Full walkthrough: [docs/getting-started.md](docs/getting-started.md).

---

## The three commands

| Command | Answers | Cost |
|---|---|---|
| `./scripts/androidArchDoctor.sh` | Is my environment and project ready? | seconds, read-only |
| `./scripts/androidArchCheck.sh` | Is this code safe to merge? | seconds |
| `./scripts/androidArchTest.sh` | Do the tests pass? | minutes |

`check` and `test` stay separate on purpose. Merging them makes the fast signal wait on the slow
one, which is how a pre-merge gate becomes a gate people skip.

---

## The architecture it enforces

```
:app  →  :feature:*  →  :core:designsystem, :core:navigation
                     →  :core:network, :core:database, :core:datastore, :core:logging
                     →  :core:model, :core:common   (no Android SDK, zero deps)
```

Every edge points **downward**. The rule that carries the most weight is the one about the edges
that do not exist: **no feature module imports a sibling feature.** It is the cheapest bad decision
in an Android codebase and the most expensive to reverse.

Detail: [android/architecture/](android/architecture/).

---

## Repository layout

```
GenericArch-Android/
│
├── android/
│   ├── architecture/
│   │   ├── ARCHITECTURE.md
│   │   ├── LAYERS.md
│   │   ├── DEPENDENCIES.md
│   │   └── MODULES.md
│   │
│   ├── gradle/
│   │   ├── conventions/
│   │   │   ├── AndroidApplicationConventionPlugin.kt
│   │   │   ├── AndroidLibraryConventionPlugin.kt
│   │   │   ├── AndroidComposeConventionPlugin.kt
│   │   │   └── AndroidTestConventionPlugin.kt
│   │   │
│   │   └── libs.versions.toml
│   │
│   └── rules/
│       ├── architecture-rules.yaml
│       ├── dependency-rules.yaml
│       └── module-rules.yaml
│
├── tools/
│   ├── androidArchDoctor/
│   ├── androidArchCheck/
│   └── androidArchTest/
│
├── scripts/
│   ├── install.sh
│   ├── androidArchDoctor.sh
│   ├── androidArchCheck.sh
│   └── androidArchTest.sh
│
├── docs/
│   ├── getting-started.md
│   ├── architecture.md
│   ├── commands.md
│   ├── configuration.md
│   └── troubleshooting.md
│
├── .claude/
│   ├── commands/
│   │   ├── android-project-init.md
│   │   ├── android-gaps.md
│   │   ├── android-review.md
│   │   ├── android-verify.md
│   │   └── android-build.md
│   │
│   └── skills/
│       ├── android-architecture/
│       ├── android-gradle/
│       ├── android-testing/
│       └── android-compose/
│
├── examples/
│   ├── simple-app/
│   └── multi-module-app/
│
├── .github/
│   └── workflows/
│       └── architecture-check.yml
│
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

| Directory | Holds |
|---|---|
| `android/architecture/` | The reasoning — layers, dependency direction, module contracts |
| `android/gradle/` | Convention plugins and the starting version catalogue |
| `android/rules/` | **The rules as data.** One source, read by the scripts, the build and CI |
| `tools/` | The Gradle task implementations — contract documented, not yet built |
| `scripts/` | The working cross-platform entry points |
| `docs/` | How to use it |
| `.claude/` | Commands you type, and skills that fire on their own |
| `examples/` | Specifications for a single-module and a multi-module reference app |

---

## Rules as data

Everything enforced lives in [`android/rules/`](android/rules/) as YAML:

```yaml
- id: ARCH-001
  name: No feature module imports a sibling feature
  severity: error
  rationale: >
    A sideways edge is the cheapest bad decision in an Android codebase and the most expensive to
    reverse. Once it exists, neither module builds alone, tests alone, or ships alone.
  remedy: Extract the capability to a :core interface, or navigate by route value.
```

The local script, the Gradle check and the CI workflow read the **same** file. Three enforcement
points with three copies of the rules would be three drifting approximations of a rule nobody can
state. Adding or changing one: [docs/configuration.md](docs/configuration.md).

---

## Claude Code integration

Commands you type — anything that must never fire by inference:

| Command | Does |
|---|---|
| `/android-project-init` | Adopt into an existing repo; reconciles conflicting rules, approval first |
| `/android-gaps` | Triage what is deliberately absent, each with a revisit trigger |
| `/android-review` | Review a diff or PR against the rules — reports, never edits |
| `/android-verify` | Walk the completion checklist against the working diff |
| `/android-build` | Assemble, check, test or bundle — and typing it is the consent to run |

Skills that activate from their own description:

| Skill | Fires when |
|---|---|
| `android-architecture` | deciding where code belongs, or whether a dependency edge is legal |
| `android-gradle` | build files, convention plugins, the catalogue, a build failure |
| `android-testing` | writing or fixing tests, fakes, screenshot coverage, a flake |
| `android-compose` | UI, state hoisting, recomposition, accessibility, adaptivity |

---

## What it does not decide for you

`minSdk`, presentation pattern, persistence engine, caching policy, paging strategy, flavours,
permissions. These are product decisions with real trade-offs, and a framework that picks one for
you is a framework you will fight. Its job is to make sure they are decided **deliberately and
written down**.

---

## Status

| | |
|---|---|
| Architecture docs, rules, conventions | **written** |
| `install.sh`, `androidArchDoctor.sh`, `androidArchCheck.sh`, `androidArchTest.sh` | **working** |
| Claude commands and skills | **written** |
| CI workflow | **written** |
| Gradle tasks in `tools/` | contract documented, **not implemented** |
| `examples/` | specified, **not built** |

Early. The scripts run today; the Gradle task layer is the next step, and it earns its keep by
reading the configured build model rather than the files.

---

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md). The short version: a rule needs a rationale, a remedy and a way
to check it mechanically — a rule enforced by review decays, a rule enforced by the build does not.

## Licence

[MIT](LICENSE).
