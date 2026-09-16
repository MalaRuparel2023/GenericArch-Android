#!/usr/bin/env bash
# install.sh — install GenericArch-Android into an existing Android project.
#
# Copies the rules, the Claude commands and skills, and the architecture docs into a target repo.
# Never writes without --apply. Never overwrites a file you have edited.
#
# The manifest is written LAST, so its presence is itself the proof that the install completed.
# uninstall.sh reads it and nothing else.
#
# Exit codes: 0 ok · 2 usage · 3 incompatible target
set -euo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$PWD"
APPLY=0
WITH_CI=0
WITH_CONVENTIONS=0

MANIFEST_REL=".claude/.genericarch-manifest"

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
    --target) [ $# -ge 2 ] || { echo "--target needs a directory" >&2; exit 2; }; TARGET="$2"; shift 2 ;;
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

GA_VERSION="${GA_VERSION:-}"
if [ -z "$GA_VERSION" ]; then
  GA_VERSION="$(git -C "$FRAMEWORK_ROOT" describe --tags --always 2>/dev/null || echo unknown)"
fi

# shasum is the BSD/macOS spelling, sha256sum the GNU one. uninstall.sh resolves it the same way.
if command -v shasum >/dev/null 2>&1; then
  ga_hash() { shasum -a 256 "$1" | cut -d' ' -f1; }
elif command -v sha256sum >/dev/null 2>&1; then
  ga_hash() { sha256sum "$1" | cut -d' ' -f1; }
else
  ga_hash() { echo -; }
fi

plan=()
add() { plan+=("$1|$2"); }   # source|destination-relative-to-target

add "$FRAMEWORK_ROOT/android/rules"                 "android/rules"
add "$FRAMEWORK_ROOT/android/architecture"          "docs/architecture"
add "$FRAMEWORK_ROOT/.claude/commands"              ".claude/commands"
add "$FRAMEWORK_ROOT/.claude/skills"                ".claude/skills"
# The commands and skills above address these by path. Shipping the commands without them left
# every /android-verify and /android-gaps run pointing at a file that was never installed.
add "$FRAMEWORK_ROOT/.claude/INDEX.md"              ".claude/INDEX.md"
add "$FRAMEWORK_ROOT/.claude/MAP.tsv"               ".claude/MAP.tsv"
add "$FRAMEWORK_ROOT/.claude/memory"                ".claude/memory"
add "$FRAMEWORK_ROOT/.claude/notes"                 ".claude/notes"
add "$FRAMEWORK_ROOT/docs/ADOPTION.md"              "docs/ADOPTION.md"
add "$FRAMEWORK_ROOT/docs/BUILD-PROCESS.md"         "docs/BUILD-PROCESS.md"
add "$FRAMEWORK_ROOT/docs/DECISIONS.md"             "docs/DECISIONS.md"
add "$FRAMEWORK_ROOT/docs/DELIVERY.md"              "docs/DELIVERY.md"
add "$FRAMEWORK_ROOT/docs/DONE.md"                  "docs/DONE.md"
add "$FRAMEWORK_ROOT/docs/GAPS.md"                  "docs/GAPS.md"
add "$FRAMEWORK_ROOT/docs/SEQUENCE.md"              "docs/SEQUENCE.md"
add "$FRAMEWORK_ROOT/docs/configuration.md"         "docs/configuration.md"
add "$FRAMEWORK_ROOT/scripts/androidArchDoctor.sh"  "scripts/androidArchDoctor.sh"
add "$FRAMEWORK_ROOT/scripts/androidArchCheck.sh"   "scripts/androidArchCheck.sh"
add "$FRAMEWORK_ROOT/scripts/androidArchTest.sh"    "scripts/androidArchTest.sh"
# The summary below names this command. Through bootstrap.sh the framework clone is a temp dir
# that is already gone by then, so the uninstall has to live in the target to be runnable at all.
add "$FRAMEWORK_ROOT/scripts/uninstall.sh"          "scripts/uninstall.sh"
[ "$WITH_CONVENTIONS" -eq 1 ] && add "$FRAMEWORK_ROOT/android/gradle/conventions" "build-logic/convention/src/main/kotlin"
[ "$WITH_CI" -eq 1 ] && add "$FRAMEWORK_ROOT/.github/workflows/architecture-check.yml" ".github/workflows/architecture-check.yml"

echo "GenericArch-Android $GA_VERSION → $TARGET"
[ "$APPLY" -eq 1 ] || echo "(dry run — nothing is written; pass --apply to write)"
echo

# A directory entry is expanded to its files before anything is compared. Testing the directory
# itself meant one unrelated file already in .claude/commands/ skipped all twenty commands and
# reported it as "left alone" — a target that looked installed and had nothing in it.
expand() {
  local src="$1" rel="$2"
  if [ -d "$src" ]; then
    ( cd "$src" && find . -type f -print ) | sed 's|^\./||' | sort \
      | while IFS= read -r f; do printf '%s/%s|%s/%s\n' "$src" "$f" "$rel" "$f"; done
  else
    printf '%s|%s\n' "$src" "$rel"
  fi
}

files=()
missing=()
for entry in "${plan[@]}"; do
  src="${entry%%|*}"; rel="${entry##*|}"
  if [ ! -e "$src" ]; then missing+=("$rel"); continue; fi
  while IFS= read -r line; do [ -n "$line" ] && files+=("$line"); done < <(expand "$src" "$rel")
done

written=0 skipped=0
installed=()
for entry in "${files[@]}"; do
  src="${entry%%|*}"; rel="${entry##*|}"; dst="$TARGET/$rel"
  if [ -e "$dst" ]; then
    printf '  %-52s  exists, left alone\n' "$rel"; skipped=$((skipped + 1)); continue
  fi
  printf '  %-52s  %s\n' "$rel" "$([ "$APPLY" -eq 1 ] && echo written || echo 'would write')"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    case "$rel" in *.sh) chmod +x "$dst" ;; esac
  fi
  installed+=("$rel	$(ga_hash "$src")")
  written=$((written + 1))
done

for rel in ${missing+"${missing[@]}"}; do
  printf '  %-52s  missing in framework, skipped\n' "$rel"; skipped=$((skipped + 1))
done

echo
echo "  $written to write, $skipped left alone"

# Written last: a manifest that exists is a manifest whose every line was copied. uninstall.sh
# removes exactly these paths and nothing else, so a file you added yourself is never a casualty.
if [ "$APPLY" -eq 1 ]; then
  mkdir -p "$TARGET/$(dirname "$MANIFEST_REL")"
  {
    echo "# GenericArch-Android manifest — do not edit"
    echo "version	$GA_VERSION"
    echo "installed	$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    for rec in ${installed+"${installed[@]}"}; do echo "file	$rec"; done
  } > "$TARGET/$MANIFEST_REL"
  echo
  echo "  manifest  $MANIFEST_REL ($written files)"
  echo "  Next:     ./scripts/androidArchDoctor.sh"
  echo "  Remove:   bash scripts/uninstall.sh --target \"$TARGET\" --apply"
fi
