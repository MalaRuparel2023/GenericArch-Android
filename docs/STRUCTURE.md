# STRUCTURE — where a new document belongs

`CLAUDE.md` has a 4,500-token budget, so the default answer to "where does this prose go" is
**not `CLAUDE.md`**. Use this table before writing a word.

| The prose is… | It goes in | Loaded |
|---|---|---|
| A rule that binds *while writing code* | `CLAUDE.md`, under an existing §N | every session |
| Why a settled choice was made | `DECISIONS.md` | on lookup |
| What is deliberately absent, and the trigger to revisit | `GAPS.md` | on lookup |
| What "finished" means for a change | `DONE.md` | before `/verify` |
| Naming, layout, visibility, KDoc | `CONVENTIONS.md` | on lookup |
| How to build a variant on a machine | `BUILD-PROCESS.md` | when the task is that |
| How a build reaches users, and how to roll it back | `DEPLOYMENT-PROCESS.md` · `DELIVERY.md` | when the task is that |
| SDK levels, permissions, secrets, signing, Data Safety | `PROJECT-SETTINGS.md` | when the task is that |
| What one module owns and may depend on | `modules/<Module>.md` | on lookup |
| A repeatable procedure not yet worth a skill | `patterns/<name>.md` | on lookup |
| Generated from the code | `.claude/notes/` — never hand-written | searched |
| Something an earlier session learned | `.claude/memory/` | on lookup |

## Rules

- **Every new file gets a `MAP.tsv` row in the same change.** A doc nobody can grep to is a doc
  nobody reads.
- **A `CLAUDE.md` addition must displace something**, or it is not load-bearing enough to be there.
- **Reasoning here, inventory in `.claude/notes/`.** If you are hand-writing a list of the code's
  own contents, a generator should be writing it instead.
