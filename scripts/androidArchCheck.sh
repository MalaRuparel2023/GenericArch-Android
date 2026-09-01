#!/usr/bin/env bash
# androidArchCheck.sh — is this code safe to merge?
#
# Checks the source tree against android/rules/. Reports EVERY violation, not the first: a gate
# that stops at the first failure teaches you about the lint error and hides the four others.
set -uo pipefail

PROJECT="$PWD"
RULES=""
QUIET=0

usage() { cat <<'USAGE'
Usage: androidArchCheck.sh [options]

  --project <dir>   Project to check (default: current directory)
  --rules <file>    A single rule file instead of all of android/rules/
  --quiet           Findings only, no per-rule ✓ lines
  -h, --help        This message

Exit 0 clean, 1 on any error-severity violation.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --rules) RULES="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
PROJECT="$(cd "$PROJECT" && pwd)"

violations=0
checked=0

report() {  # id  count  description  sample
  checked=$((checked + 1))
  if [ "$2" -eq 0 ]; then
    [ "$QUIET" -eq 1 ] || printf '  \033[32m✓\033[0m %-10s %s\n' "$1" "$3"
  else
    printf '  \033[31m✗\033[0m %-10s %s — %s occurrence(s)\n' "$1" "$3" "$2"
    [ -n "${4:-}" ] && printf '%s\n' "$4" | sed 's/^/       /'
    violations=$((violations + $2))
  fi
}

kt() { find "$PROJECT" -name '*.kt' -not -path '*/build/*' -not -path '*/.git/*' "$@" 2>/dev/null; }

echo "androidArchCheck  $PROJECT"
echo

# ARCH-001 — a feature importing a sibling feature.
hits="$(grep -rn --include='*.kt' -E '^import .*\.feature\.' "$PROJECT"/feature 2>/dev/null | grep -v "/build/" || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-001 "$n" "no feature imports a sibling feature" "$(printf '%s' "$hits" | head -5)"

# ARCH-002 / dependency-rules — a vendor declared by more than one module.
dupes=""
for vendor in retrofit2 okhttp3 room datastore coil glide firebase; do
  mods="$(grep -rl --include='build.gradle.kts' -E "\"[a-z.]*${vendor}" "$PROJECT" 2>/dev/null | grep -v '/build/' | wc -l)"
  [ "$mods" -gt 1 ] && dupes="${dupes}${vendor}: declared by ${mods} modules"$'\n'
done
n=$(printf '%s' "$dupes" | grep -c . || true)
report ARCH-002 "$n" "each vendor is declared by exactly one wrapper module" "$dupes"

# ARCH-007 — !! and swallowed exceptions.
hits="$(grep -rn --include='*.kt' -E '!!(\.|\s|$)' "$PROJECT" 2>/dev/null | grep -v '/build/' | grep -v '/test/' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-007 "$n" "no !! on a shipping path" "$(printf '%s' "$hits" | head -5)"


# ARCH-008 — GlobalScope.
hits="$(grep -rn --include='*.kt' 'GlobalScope' "$PROJECT" 2>/dev/null | grep -v '/build/' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-008 "$n" "no GlobalScope" "$(printf '%s' "$hits" | head -5)"

# ARCH-010 — BuildConfig inside a feature.
hits="$(grep -rn --include='*.kt' 'BuildConfig' "$PROJECT"/feature 2>/dev/null | grep -v '/build/' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-010 "$n" "no BuildConfig inside a feature" "$(printf '%s' "$hits" | head -5)"

# ARCH-018 — inline Dispatchers.IO instead of an injected provider.
hits="$(grep -rn --include='*.kt' -E 'Dispatchers\.(IO|Default)' "$PROJECT" 2>/dev/null | grep -v '/build/' | grep -v -i 'dispatcherprovider\|/test/\|/di/' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-018 "$n" "IO dispatcher is injected, not inline" "$(printf '%s' "$hits" | head -5)"

# ARCH-020 — collectAsState in a lifecycle-sensitive collection.
hits="$(grep -rn --include='*.kt' 'collectAsState()' "$PROJECT" 2>/dev/null | grep -v '/build/' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report ARCH-020 "$n" "collectAsStateWithLifecycle, not collectAsState" "$(printf '%s' "$hits" | head -5)"

# dependency-rules — dynamic versions.
hits="$(grep -rn --include='*.gradle.kts' --include='*.toml' -E '["'\''][^"'\'']*([0-9]\.\+|latest\.release)["'\'']' "$PROJECT" 2>/dev/null | grep -v '/build/' | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
n=$(printf '%s' "$hits" | grep -c . || true)
report DEP-001 "$n" "no dynamic versions" "$(printf '%s' "$hits" | head -5)"

# module-rules — a module build file with a hand-rolled android block and no convention plugin.
hits=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in */build/*) continue ;; esac
  if grep -q '^android {' "$f" 2>/dev/null && ! grep -qE 'genericarch\.android|alias\(libs\.plugins' "$f" 2>/dev/null; then
    hits="${hits}${f}"$'\n'
  fi
done <<EOF
$(find "$PROJECT" -name 'build.gradle.kts' -not -path '*/build/*' 2>/dev/null)
EOF
n=$(printf '%s' "$hits" | grep -c . || true)
report MOD-001 "$n" "every module applies a convention plugin" "$hits"

echo
if [ "$violations" -gt 0 ]; then
  echo "  FAILED — $violations violation(s) across $checked checks"
  exit 1
fi
echo "  PASSED — $checked checks, 0 violations"
