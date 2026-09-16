# GAPS — what is deliberately absent

*Missing* and *deliberately absent* are different states. `androidArchDoctor` prints `⚠` for a gap
recorded here and `✗` for one that is not. Triage with `/android-gaps`.

| # | Gap | Why it is absent today | Revisit when |
|---|---|---|---|
| 1 | No `androidArch*` Gradle tasks implemented — every command that calls one says so inline, and names the `./scripts/*.sh` equivalent where one exists | Design note §12 step 0: nothing is worth building until a target repo has a reproducible clean-checkout build. The rules and docs pay off without them | Talnetsure passes `git clone && ./gradlew assembleEnvDevDebug` on a clean machine |
| 2 | No reseal or in-place upgrade | The manifest and `uninstall.sh` landed (§12 step 13); resealing an edited install and upgrading over an older one are the remainder of step 14 | A target repo needs to move between two installed versions without removing first |
| 3 | No CI workflows committed | Stage 1 needs `androidArchCheck` and `androidArchTest` to exist first, or the pipeline gates on nothing | Steps 2–3 of the build order land |
| 4 | No `.claude/notes/` inventories | They are generated from a target repo's code; this repo has no Kotlin to scan | `androidArchSyncNotes` exists (§12 step 8) |
| 5 | No `TASKS.tsv` | Generated from task metadata; there are no tasks yet | Step 7 |
| 6 | No `.claude-plugin/` for multi-repo distribution | Same argument as gap 2 — one consumer | Step 14 |
| 7 | No reference app | Recorded as a decision, not an oversight — see `DECISIONS.md` | Two adopters need the same Compose scaffolding |
| 8 | No `docs/modules/` rows | A module row describes a *target repo's* module. The base ships the format, not the content | `/android-project-init` runs in an adopting repo |

## Rules

- A gap is a row with a **trigger**, not a wish. "Someday" is not a trigger.
- Closing a gap deletes the row in the same change that closes it.
- A gap Claude discovers is proposed here, never silently filled.
