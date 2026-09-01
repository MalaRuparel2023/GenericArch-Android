# DELIVERY — secrets, versioning, release and rollback

## Secrets

| Secret | Local | CI |
|---|---|---|
| API and vendor keys | `~/.gradle/gradle.properties`, outside the repo | masked env vars |
| `secret.properties` | the gitignored file | `SECRET_PROPERTIES_B64` → `androidArchMaterialiseSecrets` |
| `google-services.json` per flavour | committed only for dev flavours, or gitignored | `GOOGLE_SERVICES_JSON_B64` per flavour |
| Upload keystore | never on a laptop for prod | `UPLOAD_KEYSTORE_B64` + three passwords |
| App signing key | — | held by Google (**Play App Signing**) |
| Play publishing | — | `PLAY_SERVICE_ACCOUNT_JSON_B64` |

Rules:

- **A Play Developer API service account, never a personal Google account.** A pipeline tied to one
  engineer's login breaks the day they rotate a password, and 2FA cannot be automated.
- **Enable Play App Signing.** Then a leaked upload key is a key rotation, not a dead app.
- **Debug signing may live in the repo; production signing exists only in CI** — a production
  keystore that resolves on a laptop is a finding, not a convenience.
- Rotate the service-account key on a schedule, and whenever someone with access leaves.

## Versioning — three numbers, one of them CI's

| Number | Owned by | Changes when |
|---|---|---|
| `versionName` (`1.10.8`) | Product | A release ships |
| `versionCode` (`202636101`) | **CI** | Every build |
| Module API version | The module | Only if published externally |

- **`versionCode` is monotonic across every flavour and track, and comes from CI** — never a
  hand-edited literal. A committed counter guarantees merge conflicts and duplicate codes, and Play
  rejects a duplicate outright.
- A date-plus-counter scheme is fine; move the *counter* to CI
  (`base * 100 + CI_RUN_NUMBER % 100`, or Play's highest-uploaded + 1).
- **Never reset `versionCode` per flavour.** "Which build is newer" must stay answerable.
- **Hotfix:** branch from the release tag, not `develop`. Bump patch, cherry-pick forward to
  `develop` in the same PR — never leave the fix only on the release branch.

## Release ownership

| # | Step | Owned by | Gate before moving on |
|---|---|---|---|
| 1 | Merged to `develop` | the author | Stage 1 green |
| 2 | QA build to App Distribution | CI, on merge | QA has the latest `develop` and it launches |
| 3 | `versionName` bumped | a person, deliberately | Marketing version decided |
| 4 | Tag `vX.Y.Z` | a person | The checklist below, walked against the diff |
| 5 | Internal → closed track soak | CI on tag, then a person | Crash-free rate acceptable, Vitals clean |
| 6 | Production, staged rollout from 5% | a person | **Same artefact, promoted — not rebuilt** |
| 7 | Rollback if needed | a person | See below |

## Rollback — decide the mechanism before you ship

1. **Halt the staged rollout.** Stops new installs. Does nothing for people who already have it.
2. **Remote Config flag off.** The only fix that reaches installed copies — and it requires the flag
   to exist *before* the release, which is why creating it is on the checklist, not the incident.
3. **Ship a hotfix.** Hours at best, and it still needs review. Assume it; do not rely on it.

`versionCode` monotonicity means an older bundle *can* be re-promoted (Play calls it deactivating a
release). It is still not an undo — installed copies keep the bad build.

## Release checklist

- [ ] `versionName` bumped; `versionCode` from CI
- [ ] `gradle/verification-metadata.xml` current; no dynamic versions
- [ ] Every module green standalone
- [ ] Zero lint warnings; `lintVitalRelease` clean
- [ ] `androidArchDoctor` clean — no blocking rows
- [ ] Translations complete for every shipping locale (`notes/STRINGS.md` parity matrix)
- [ ] Screenshot tests regenerated and reviewed; store screenshots per locale
- [ ] Release notes localised
- [ ] Play Data Safety form current; permission list matches the badging golden file
- [ ] Force-update threshold set for the new `versionCode`
- [ ] `mapping.txt` uploaded to Crashlytics and retained as a CI artefact
- [ ] Staged rollout enabled, kill-switch flag created, rollback plan written down **before** submitting

`/release` walks this list against the diff and **prints** the commands. It runs none of them.
