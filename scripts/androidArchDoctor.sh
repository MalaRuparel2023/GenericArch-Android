#!/usr/bin/env bash
# androidArchDoctor.sh — architecture health diagnostics.
#
# Reports three states, never two:  ok / drift-or-opportunity / blocking.
# Exit 0 on ok-or-warnings, 1 on any blocking row — so CI can gate on it and a developer is never
# stopped by a warning.
set -uo pipefail

PROJECT="${1:-$PWD}"
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { echo "Usage: androidArchDoctor.sh [project-dir]"; exit 0; }
PROJECT="$(cd "$PROJECT" && pwd)"

blocking=0 warnings=0

ok()    { printf '  %-22s \033[32m✓\033[0m  %s\n' "$1" "${2:-}"; }
warn()  { printf '  %-22s \033[33m⚠\033[0m  %s\n' "$1" "${2:-}"; warnings=$((warnings + 1)); }
fail()  { printf '  %-22s \033[31m✗\033[0m  %s\n' "$1" "${2:-}"; blocking=$((blocking + 1)); }
have()  { command -v "$1" >/dev/null 2>&1; }

echo "================================="
echo "   GenericArch — Arch Doctor"
echo "================================="
echo
echo "Environment"

ok "OS" "$(uname -s) ($(uname -m))"

if have java; then
  jv="$(java -version 2>&1 | head -1 | sed -E 's/.*version "([^"]+)".*/\1/')"
  case "$jv" in
    17*|21*) ok "JDK" "$jv" ;;
    *)       warn "JDK" "$jv — the framework targets toolchain 17" ;;
  esac
else
  fail "JDK" "not on PATH"
fi

if [ -x "$PROJECT/gradlew" ]; then
  gv="$(sed -n 's/^distributionUrl=.*gradle-\([0-9.]*\)-.*/\1/p' "$PROJECT/gradle/wrapper/gradle-wrapper.properties" 2>/dev/null)"
  ok "Gradle" "${gv:-unknown} (wrapper)"
elif [ -f "$PROJECT/gradlew" ]; then
  fail "Gradle" "gradlew is not executable — git update-index --chmod=+x gradlew"
else
  fail "Gradle" "no wrapper in $PROJECT"
fi

if [ -n "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]; then
  ok "Android SDK" "${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
else
  warn "Android SDK" "ANDROID_HOME unset — fine for a docs-only repo, blocking for a build"
fi

have git && ok "git" "$(git --version | awk '{print $3}')" || warn "git" "not on PATH"

echo
echo "Project"

catalogue=""
for c in "$PROJECT/gradle/libs.versions.toml" "$PROJECT/android/gradle/libs.versions.toml"; do
  [ -f "$c" ] && catalogue="$c" && break
done
if [ -n "$catalogue" ]; then
  ok "Version catalogue" "${catalogue#$PROJECT/}"
  for key in agp kotlin compileSdk minSdk targetSdk; do
    v="$(sed -n "s/^${key}[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$catalogue" | head -1)"
    [ -n "$v" ] && ok "  $key" "$v" || warn "  $key" "not declared in the catalogue"
  done
else
  fail "Version catalogue" "no libs.versions.toml found"
fi

if [ -f "$PROJECT/settings.gradle.kts" ] || [ -f "$PROJECT/settings.gradle" ]; then
  s="$PROJECT/settings.gradle.kts"; [ -f "$s" ] || s="$PROJECT/settings.gradle"
  modules="$(grep -cE '^\s*include' "$s" 2>/dev/null || echo 0)"
  ok "Modules" "$modules declared"
else
  warn "Modules" "no settings.gradle[.kts] — not a Gradle project"
fi

if [ -d "$PROJECT/build-logic" ]; then
  ok "Convention plugins" "build-logic/"
else
  warn "Convention plugins" "build-logic/ absent — config will sprawl across module build files"
fi

if grep -rnE '["'\''][^"'\'']*([0-9]\.\+|latest\.release)["'\'']' --include='*.gradle.kts' --include='*.toml' "$PROJECT" 2>/dev/null | grep -v '/build/' | grep -qvE ':[0-9]+:[[:space:]]*#'; then
  fail "Dynamic versions" "found — the build is not reproducible across machines"
else
  ok "Dynamic versions" "none"
fi

echo
echo "Rules"
rules_dir=""
for d in "$PROJECT/android/rules" "$PROJECT/rules"; do [ -d "$d" ] && rules_dir="$d" && break; done
if [ -n "$rules_dir" ]; then
  for f in architecture-rules dependency-rules module-rules; do
    [ -f "$rules_dir/$f.yaml" ] && ok "$f" "loaded" || warn "$f" "absent"
  done
else
  fail "Rule set" "no android/rules/ — nothing to check against"
fi

echo
echo "================================="
if [ "$blocking" -gt 0 ]; then
  echo "  FAILED — $blocking blocking, $warnings warnings"
  echo "  Next:  fix the ✗ rows, then re-run"
  echo "================================="
  exit 1
fi
echo "  OK — 0 blocking, $warnings warnings"
echo "  Next:  ./scripts/androidArchCheck.sh"
echo "================================="
