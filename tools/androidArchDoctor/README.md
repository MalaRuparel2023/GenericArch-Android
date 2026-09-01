# androidArchDoctor

**Answers:** *is my environment and project ready?*

| | |
|---|---|
| Shell entry point | [`scripts/androidArchDoctor.sh`](../../scripts/androidArchDoctor.sh) — **working** |
| Gradle task | `./gradlew androidArchDoctor` — **not implemented yet** |
| Effects | read-only |
| Exit | `0` ok or warnings · `1` any blocking row · `2` usage |

## Contract

Three sections — Environment, Project, Rules — and **three states, never two**:

| | Means |
|---|---|
| `✓` | ok |
| `⚠` | drift or opportunity — information, never a blocker |
| `✗` | blocking |

Two properties the shell version already keeps, and the Gradle task must keep:

- **Exit non-zero only on `✗`.** CI can gate on it; a developer is never stopped by a warning.
- **Every value states its provenance** — `wrapper`, `toolchain: 17`, `CI-only`. A version with no
  provenance is a version someone will "fix" on their machine.

## Why a Gradle task, eventually

The shell script reads files. A Gradle task reads the **configured model** — resolved variants, the
real module graph, actual dependency resolution — which is the difference between "there is a
`libs.versions.toml`" and "AGP resolved to 8.12.3 for this build". Everything in `Project` and every
graph assertion gets more truthful, and it runs identically on Linux, Windows and macOS with no bash.
