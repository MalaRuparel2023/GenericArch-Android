---
description: Prepare a release — version bump, changelog, checklist walked against the diff. EMIT_ONLY, it prints commands and runs none
argument-hint: <version, e.g. 1.10.8>
---

# /release

**`EMIT_ONLY`.** This command walks the release checklist and **prints** the commands. It runs none
of them. Nothing about a Play upload is one inferred tool call away.

## What it does

1. Walks `docs/DELIVERY.md`'s checklist against the actual diff since the last tag.
2. Reports each item met · not met · cannot be checked here.
3. Drafts the changelog from the diff, and the localised release notes stub.
4. Confirms `versionName` is bumped and that `versionCode` comes from CI — **a literal
   `versionCode` in a build file is a blocking finding**, not a warning.
5. Prints the tag, build and upload commands for a person to run.

## The items that are most often missed

- Translations complete for every shipping locale — `notes/STRINGS.md` parity matrix.
- The **kill-switch flag created before submitting.** Remote Config is the only rollback that
  reaches installed copies, and it must exist before the release, not during the incident.
- Force-update threshold set for the new `versionCode`.
- `mapping.txt` uploaded to Crashlytics and retained as a CI artefact.
- Data Safety form current; permission list matches the badging golden file.

## Rules

- **Promote, never rebuild.** The bundle that soaked on the internal track is the bundle that reaches
  production; a rebuild from the same tag is a different artefact and voids the soak.
- Never commits, never tags, never uploads (§2.11).
