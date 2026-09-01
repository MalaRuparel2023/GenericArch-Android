# Contributing

## The bar for a new rule

A rule earns its place in `android/rules/` only if all four hold:

1. **A machine can decide it.** If it needs judgment, it is guidance for a doc, not a rule for a
   build. A rule enforced by review decays; a rule enforced by the build does not.
2. **It has a written rationale.** A rule whose reason is not recorded is a rule that gets deleted by
   whoever it first inconveniences — and re-argued from scratch a year later.
3. **It has a remedy.** "Don't do that" is not actionable. Name the thing to do instead.
4. **It fails somewhere real.** Name the check: detekt, lint, Konsist, module-graph-assert, a
   screenshot test, or a line in `androidArchCheck.sh`.

```yaml
- id: TEAM-001
  name: No java.util.Date in domain code
  severity: error
  rationale: Timezone-dependent tests are green locally and red on a UTC runner.
  applies_to: "core/**"
  forbid_symbol: ["java.util.Date", "System.currentTimeMillis"]
  remedy: Inject a Clock.
  enforced_by: [detekt]
```

New rules land at `severity: warning`. They are promoted to `error` in the PR that removes the last
existing violation — a rule introduced at `error` against a codebase that breaks it just teaches the
team to skip the gate.

## Changing the scripts

The scripts are the framework's only working surface, so they carry the framework's own standards:

- `bash -n` clean, and they must run on Linux, macOS and Windows (Git Bash). The weekly three-OS CI
  matrix is what keeps that honest.
- **Every check reports, then continues.** Stopping at the first violation hides the rest, which is
  the failure mode `androidArchCheck` exists to avoid.
- Exit codes are part of the contract: `0` clean, `1` violations, `2` usage, `3` refused.
- A pattern must not match its own documentation. Test it against this repo before proposing it —
  prose in a comment that trips a rule is a false positive that costs trust immediately.

## Changing the convention plugins

- **No version is written in a plugin.** Every one is read from the catalogue.
- A plugin configures; it does not gate. Gating belongs in `androidArchCheck`.
- **Never reimplement an AGP task.** `assembleDebug` and `bundleRelease` are Google's, they are
  correct, and they keep working across upgrades. Wrap and validate; never replace.

## Documentation

- Reasoning goes in `android/architecture/`; usage goes in `docs/`. A change that alters behaviour
  updates both in the same commit.
- **No narration comments.** A comment states the *why* the code cannot; it never restates the code
  or describes the edit. That is what a commit message is for.

## Pull requests

1. `./scripts/androidArchCheck.sh` passes.
2. `bash -n scripts/*.sh` passes, and the rule YAML parses.
3. The commit message says what changed and why, and names what you could **not** verify — a
   physical device, a Windows runner, a real Play upload.
4. One concern per PR. A rule change and a script refactor in one diff cannot be reviewed, only
   approved.

## What will be declined

- A rule with no rationale, or no mechanical check behind it.
- A version pinned inside a plugin or a module build file.
- An app template, or Kotlin app code in this repo. Reference apps live in `examples/` and exist to
  demonstrate rules, not to be copied into production.
- A check that silences an existing violation instead of reporting it.
