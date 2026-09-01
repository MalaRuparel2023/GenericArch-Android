---
description: Reconcile AGP, Gradle, Kotlin, KSP and SDK versions with what the machine has — asks twice
---

# /upgrade-stack

```bash
./gradlew androidArchDoctor --mismatches
```

Emits one row per drift, classified `BLOCKING` · `OPPORTUNITY` · `DRIFT`. A warning is information;
only a blocking row stops you.

## What it does

1. Resolves the real stack from the repo and the machine — never from memory, never from a doc.
2. Presents each available upgrade with what it unlocks and what it risks: AGP ↔ Gradle ↔ Kotlin ↔
   KSP compatibility is a lattice, not a list, and one of them moving alone is the usual failure.
3. **Asks once** for approval of the set.
4. **Asks again** before writing — naming every file it will touch.
5. Updates `gradle/libs.versions.toml` and the wrapper only. Never a hardcoded version in a module
   build file.
6. Refreshes `gradle/verification-metadata.xml`.

## Rules

- **`minSdk`, `targetSdk` and a new flavour are §0 questions**, not upgrades. This command will not
  move them.
- No dynamic versions (`+`, `latest.release`) — they make the build non-reproducible across machines
  and `androidArchCheck` asserts their absence.
- After an upgrade, `androidArchDoctor` and a clean-checkout build are the proof. An upgrade that has
  only been validated with a warm cache has not been validated.
