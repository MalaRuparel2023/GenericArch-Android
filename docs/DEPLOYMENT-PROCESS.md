# DEPLOYMENT-PROCESS — the pipeline

One rule: **all build logic lives in Gradle. CI files contain no logic** — only checkout, toolchain,
secrets, and `./gradlew <task>`. That is what makes the pipeline portable across operating systems
and CI providers, and it is why translating to GitLab, Bitrise or Jenkins is mechanical.

## Stages

| Stage | Trigger | Runner | Target | Runs |
|---|---|---|---|---|
| 0 · local | pre-commit | any OS | < 20 s | `spotlessApply`, changed-module unit tests |
| 1 · PR | every push | ubuntu | < 12 min | `androidArchCheck --continue`, `androidArchTest`, `assembleEnvDevDebug` |
| 2 · integration | merge to `develop` | ubuntu + GMD | < 25 min | stage 1 + Robolectric + managed-device tests + App Distribution |
| 3 · candidate | tag `v*` | ubuntu, signed | < 30 min | `bundleEnvProdRelease`, `lintVitalRelease`, badging check, internal track |
| 4 · promotion | manual | — | minutes | promote the **same artefact** to a closed then production track |

Plus a **weekly three-OS matrix** (ubuntu · windows · macos) — the job that keeps the cross-platform
promise honest. It is the only place the Windows traps above get caught before a developer hits one.

## What CI enforces, not just reports

A check that only reports is a check the team learns to ignore. These fail the job:

- `androidArchCheck` violations — with `--continue`, so one run reports every violation
- Notes staleness (`androidArchSyncNotes --check`) — generated inventories may not drift from code
- Pending upstream decisions (`androidArchAdoptReview` exits 1)
- Dependency-guard diff, and any dynamic version
- `lintVitalRelease` on the release path
- Permission/badging diff against the golden file — a new permission cannot land silently

## Artefact promotion

**Stage 4 promotes; it never rebuilds.** The bundle that soaked on the internal track is the bundle
that reaches production. A rebuild — even from the same tag — is a different artefact and voids the
soak.

## Provider translation

Everything above is `./gradlew <task>` plus secrets. Porting to another provider is: checkout, set
up JDK 17, restore the Gradle cache, decode secrets, run the same task list. Nothing in a workflow
file may encode a decision that Gradle could encode instead.
