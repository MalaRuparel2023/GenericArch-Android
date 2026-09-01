#!/usr/bin/env bash
# androidArchTest.sh — run the test tiers, cheapest first.
#
# The first three tiers need no device. Instrumented is opt-in, because a test that needs a device
# runs on merge, not on every push, and so protects nothing during review.
set -uo pipefail

PROJECT="$PWD"
TIERS="arch,unit,screenshot"
MODULE=""

usage() { cat <<'USAGE'
Usage: androidArchTest.sh [options]

  --project <dir>       Project to test (default: current directory)
  --module <path>       One Gradle module, e.g. :core:network
  --tiers <list>        Comma-separated: arch,unit,screenshot,robolectric,instrumented
                        Default: arch,unit,screenshot
  --all                 Every device-free tier (arch,unit,screenshot,robolectric)
  -h, --help            This message

Running tests is consent-gated. Invoking this script IS that consent, for this run only.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --module) MODULE="$2"; shift 2 ;;
    --tiers) TIERS="$2"; shift 2 ;;
    --all) TIERS="arch,unit,screenshot,robolectric"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
PROJECT="$(cd "$PROJECT" && pwd)"
[ -x "$PROJECT/gradlew" ] || { echo "no executable gradlew in $PROJECT" >&2; exit 3; }

has_tier() { printf '%s' ",$TIERS," | grep -q ",$1,"; }
prefix="${MODULE:+$MODULE:}"
tasks=()

has_tier arch        && tasks+=("${prefix}konsistTest")
has_tier unit        && tasks+=("${prefix}testDebugUnitTest")
has_tier screenshot  && tasks+=("${prefix}verifyPaparazziDebug")
has_tier robolectric && tasks+=("${prefix}testDebugUnitTest")
has_tier instrumented && {
  echo "instrumented tier requested — this needs a device or a managed device, and minutes."
  tasks+=("${prefix}connectedDebugAndroidTest")
}

[ "${#tasks[@]}" -gt 0 ] || { echo "no tiers selected" >&2; exit 2; }

# De-duplicate while keeping order (unit and robolectric share a task).
unique=(); for t in "${tasks[@]}"; do
  case " ${unique[*]-} " in *" $t "*) ;; *) unique+=("$t") ;; esac
done

echo "androidArchTest  $PROJECT"
echo "  tiers:  $TIERS"
echo "  tasks:  ${unique[*]}"
echo

# --continue so one run reports every failure, not just the first.
"$PROJECT/gradlew" --continue "${unique[@]}"
status=$?

echo
[ $status -eq 0 ] && echo "  PASSED" || echo "  FAILED — see the reports above"
exit $status
