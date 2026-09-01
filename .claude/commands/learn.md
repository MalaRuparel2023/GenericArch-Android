---
description: Record what a session learned — a resource, a finished piece of work, a pattern worth promoting, or a repeated step worth a task
argument-hint: [--task | --pattern] <what was learned>
---

# /learn

Memory is in-repo and tracked, so what one session learned survives a clone and reaches the team.

## Where it lands

| What it is | Goes to |
|---|---|
| Something learned that changes how work is done | `.claude/memory/<topic>.md` + a row in `memory/INDEX.md` |
| A repeatable procedure | `docs/patterns/<name>.md` + a `MAP.tsv` row |
| A procedure invoked often enough to earn always-on context | promote to a skill — and say what its trigger phrases are |
| A step repeated by hand more than twice | `--task`: propose a Gradle task, with its full metadata |
| A settled choice | `/decide` instead |
| A rule that binds while writing code | `CLAUDE.md`, with explicit approval |

## Rules

- A memory row states **what was learned and what it changes**, not what was done.
- Promotion to a skill is not free: a skill costs context every session through its description, a
  doc costs nothing until read. Promote only on evidence of repeated use.
- A new task cannot be added without its contract — `androidArchRegisterTasks --check` refuses it.
