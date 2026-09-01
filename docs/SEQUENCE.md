# SEQUENCE — the lifecycle gate

```
install → project-init → gaps → sync-app-notes → ready
```

Every command's first step is `./gradlew androidArchStep --after=<step>`. The ledger lives at
`.androidarch/STEPS.tsv`.

## Why it is a gate and not a suggestion

Out of order these commands **do not fail — they succeed against the wrong input.** `/gaps` before
`/project-init` triages capabilities against rules nobody has accepted yet, and produces a
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
| `install` | `androidArchBootstrap --apply` | the manifest exists and verifies |
| `project-init` | `/project-init` | conflicting rules reconciled, approvals recorded |
| `gaps` | `/gaps` | `docs/GAPS.md` triaged against this repo |
| `sync-app-notes` | `/sync-app-notes` | the eleven inventories generated at least once |
| `ready` | — | the authoring surface is unlocked |

## Skipping

A step that genuinely does not apply is recorded as **skipped by the operator, with a reason**:

```bash
./gradlew androidArchStep --skip=gaps --reason="greenfield repo, nothing to triage"
```

**Claude never passes `--force` and never records a skip.** The whole value of the ledger is that a
human decided.
