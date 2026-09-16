# SEQUENCE — the lifecycle gate

> **NOT BUILT — this page is a specification, not instructions.** `androidArchStep` does not
> exist, and neither does the `.androidarch/STEPS.tsv` ledger; nothing writes it. Every step
> below except `install` is unenforced today. Recorded as `docs/GAPS.md` row 1 and gated on the
> `androidArch*` Gradle tasks landing. What *does* run after an install is
> `./scripts/androidArchDoctor.sh`, then `./scripts/androidArchCheck.sh` — see
> [getting-started.md](getting-started.md).

```
install → project-init → gaps → sync-app-notes → ready
```

Once the tasks exist, every command's first step is `./gradlew androidArchStep --after=<step>`,
and the ledger lives at `.androidarch/STEPS.tsv`.

## Why it is a gate and not a suggestion

Out of order these commands **do not fail — they succeed against the wrong input.** `/android-gaps` before
`/android-project-init` triages capabilities against rules nobody has accepted yet, and produces a
confident, useless answer. That is the failure mode a gate exists to prevent.

## Exit codes

| Exit | Means |
|---|---|
| 0 | the step is satisfied; continue |
| 5 | **an earlier step has not run** — `./gradlew androidArchStep --show` names it |
| 2 | usage error |

## Steps

| Step | Satisfied by | Records |
|---|---|---|
| `install` | `bash bootstrap.sh --apply` — **works today** | `.claude/.genericarch-manifest` exists and verifies |
| `project-init` | `/android-project-init` | conflicting rules reconciled, approvals recorded |
| `gaps` | `/android-gaps` | `docs/GAPS.md` triaged against this repo |
| `sync-app-notes` | `/android-sync-app-notes` | the eleven inventories generated at least once |
| `ready` | — | the authoring surface is unlocked |

## Skipping

A step that genuinely does not apply is recorded as **skipped by the operator, with a reason**:

```bash
./gradlew androidArchStep --skip=gaps --reason="greenfield repo, nothing to triage"
```

**Claude never passes `--force` and never records a skip.** The whole value of the ledger is that a
human decided.
