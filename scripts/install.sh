#!/usr/bin/env bash
# install.sh — install GenericArch-Android into an existing Android project.
#
# Copies the rules, the Claude commands and skills, and the architecture docs into a target repo.
# Never writes without --apply. Never overwrites a file you have edited.
set -euo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$PWD"
APPLY=0
WITH_CI=0
WITH_CONVENTIONS=0

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

  --target <dir>       Project to install into (default: current directory)
  --apply              Write. Without it, this is a dry run and nothing is written.
  --dry-run            Explicit dry run (the default)
  --with-ci            Also install .github/workflows/architecture-check.yml
  --with-conventions   Also copy the Gradle convention plugins into build-logic/
  -h, --help           This message

The target must already be a Gradle project with a wrapper. An empty directory is refused:
this is a layer you install into a project, not a template you start from.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --with-ci) WITH_CI=1; shift ;;
    --with-conventions) WITH_CONVENTIONS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -d "$TARGET" ] || { echo "target is not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

if [ ! -f "$TARGET/settings.gradle.kts" ] && [ ! -f "$TARGET/settings.gradle" ]; then
  echo "refused: $TARGET has no settings.gradle[.kts]." >&2
  echo "GenericArch installs into a project that already builds." >&2
  exit 3
fi
[ -x "$TARGET/gradlew" ] || echo "warning: no executable gradlew in $TARGET"

plan=()
add() { plan+=("$1|$2"); }   # source|destination-relative-to-target

add "$FRAMEWORK_ROOT/android/rules"                 "android/rules"
add "$FRAMEWORK_ROOT/android/architecture"          "docs/architecture"
add "$FRAMEWORK_ROOT/.claude/commands"              ".claude/commands"
add "$FRAMEWORK_ROOT/.claude/skills"                ".claude/skills"
add "$FRAMEWORK_ROOT/scripts/androidArchDoctor.sh"  "scripts/androidArchDoctor.sh"
add "$FRAMEWORK_ROOT/scripts/androidArchCheck.sh"   "scripts/androidArchCheck.sh"
add "$FRAMEWORK_ROOT/scripts/androidArchTest.sh"    "scripts/androidArchTest.sh"
[ "$WITH_CONVENTIONS" -eq 1 ] && add "$FRAMEWORK_ROOT/android/gradle/conventions" "build-logic/convention/src/main/kotlin"
[ "$WITH_CI" -eq 1 ] && add "$FRAMEWORK_ROOT/.github/workflows/architecture-check.yml" ".github/workflows/architecture-check.yml"

echo "GenericArch-Android → $TARGET"
[ "$APPLY" -eq 1 ] || echo "(dry run — nothing is written; pass --apply to write)"
echo

written=0 skipped=0
for entry in "${plan[@]}"; do
  src="${entry%%|*}"; rel="${entry##*|}"; dst="$TARGET/$rel"
  if [ ! -e "$src" ]; then
    printf '  %-52s  missing in framework, skipped\n' "$rel"; skipped=$((skipped + 1)); continue
  fi
  if [ -e "$dst" ]; then
    printf '  %-52s  exists, left alone\n' "$rel"; skipped=$((skipped + 1)); continue
  fi
  printf '  %-52s  %s\n' "$rel" "$([ "$APPLY" -eq 1 ] && echo written || echo would write)"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
  fi
  written=$((written + 1))
done

echo
echo "  $written to write, $skipped left alone"
if [ "$APPLY" -eq 1 ]; then
  echo
  echo "  Next:  ./scripts/androidArchDoctor.sh"
fi
