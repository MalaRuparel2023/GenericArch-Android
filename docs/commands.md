# Commands

## The three you will type

| Command | Answers | Cost |
|---|---|---|
| `./scripts/androidArchDoctor.sh` | Is my environment and project ready? | seconds, read-only |
| `./scripts/androidArchCheck.sh` | Is this code safe to merge? | seconds |
| `./scripts/androidArchTest.sh` | Do the tests pass? | minutes |

Plus `./scripts/install.sh` once, per repo.

**`check` and `test` stay separate.** `check` answers *safe to merge* in seconds; `test` answers *do
the tests pass* in minutes. Merging them makes the fast signal wait on the slow one, which is how a
pre-merge gate becomes a gate people skip.

## androidArchDoctor.sh

```bash
./scripts/androidArchDoctor.sh [project-dir]
```

Three sections — Environment, Project, Rules — and three states: `✓` ok, `⚠` drift or opportunity,
`✗` blocking. **Exit is non-zero only on a `✗`**, so CI can gate on it and a developer is never
stopped by a warning.

## androidArchCheck.sh

```bash
./scripts/androidArchCheck.sh --project . --rules android/rules/dependency-rules.yaml --quiet
```

| Flag | Effect |
|---|---|
| `--project <dir>` | what to check (default: cwd) |
| `--rules <file>` | one rule file instead of all of them |
| `--quiet` | findings only, no per-rule `✓` lines |

Reports **every** violation with file and line, then exits 1 if any was error-severity.

## androidArchTest.sh

```bash
./scripts/androidArchTest.sh --all
./scripts/androidArchTest.sh --module :core:network --tiers unit,screenshot
```

| Flag | Effect |
|---|---|
| `--module <path>` | one Gradle module |
| `--tiers <list>` | `arch,unit,screenshot,robolectric,instrumented` |
| `--all` | every device-free tier |

Instrumented is opt-in: a test that needs a device runs on merge, not on every push, so it protects
nothing during review.

## install.sh

```bash
./scripts/install.sh --target /path/to/app            # dry run
./scripts/install.sh --target /path/to/app --apply --with-ci --with-conventions
```

Refuses a directory with no `settings.gradle[.kts]`, never overwrites an existing file, and writes
nothing at all without `--apply`.

## The Claude commands

Typed in Claude Code, in `.claude/commands/`. Anything that must never fire by inference is a
command rather than a skill.

| Command | Does |
|---|---|
| `/android-project-init` | Adopt the framework into an existing repo — reconciles conflicting rules, approval first |
| `/android-gaps` | Triage what is deliberately absent, each with a revisit trigger |
| `/android-review` | Review a diff or PR against the rules — reports, never edits |
| `/android-verify` | Walk the completion checklist against the working diff |
| `/android-build` | Assemble, check, test or bundle — and typing it **is** the consent to run |

## The Claude skills

Never typed; they activate from their description.

| Skill | Fires when |
|---|---|
| `android-architecture` | deciding where code belongs, or whether an edge is legal |
| `android-gradle` | build files, convention plugins, the version catalogue, build failures |
| `android-testing` | writing or fixing tests, fakes, screenshot coverage, flakes |
| `android-compose` | writing UI, state hoisting, recomposition, accessibility |
