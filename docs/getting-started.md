# Getting started

Five minutes to a signal, on Linux, Windows or macOS. JDK 17 and bash are the only requirements.

## 1. Get the framework

```bash
git clone https://github.com/MalaRuparel2023/GenericArch-Android.git
```

GenericArch is a **layer you install into a project that already builds** — not a template you start
from. If you have no Android project yet, create one with Android Studio first, then come back.

## 2. Check the ground before you build on it

```bash
./scripts/androidArchDoctor.sh /path/to/your/app
```

Three states, and only one of them stops you:

| | Means |
|---|---|
| `✓` | ok |
| `⚠` | drift or an opportunity — information |
| `✗` | blocking |

Exit is non-zero only on a `✗`. Fix those first: a quality gate on an unreliable build reports build
flakiness, not code quality, and the team learns to ignore it within a fortnight.

## 3. See what would be installed

```bash
cd /path/to/your/app
/path/to/GenericArch-Android/scripts/install.sh --dry-run
```

Nothing is written without `--apply`. An existing file is never overwritten.

## 4. Install

```bash
/path/to/GenericArch-Android/scripts/install.sh --apply --with-ci
```

That places `android/rules/`, the architecture docs, the Claude commands and skills, and the three
scripts into your repo. Add `--with-conventions` to take the Gradle convention plugins too.

## 5. Get your baseline

```bash
./scripts/androidArchCheck.sh
```

**On an existing codebase this is expected to fail.** That is the point — it is a baseline, not a
verdict. You now have a list of every place the code and the rules disagree, and two honest ways
forward:

1. **Baseline the debt** and gate only on *new* violations.
2. **Fix one category at a time**, gating each rule as its count reaches zero.

Never silence a rule by deleting it. A rule you cannot hold is a decision to record, not a line to
remove.

## 6. Run the tests

```bash
./scripts/androidArchTest.sh --all
```

Every device-free tier: architecture assertions, unit, screenshot, Robolectric. No emulator, no KVM.

## Where to go next

| You want to | Read |
|---|---|
| Understand the layers and why | [architecture.md](architecture.md) |
| Know what each command does | [commands.md](commands.md) |
| Change the rules for your project | [configuration.md](configuration.md) |
| Something is not working | [troubleshooting.md](troubleshooting.md) |
