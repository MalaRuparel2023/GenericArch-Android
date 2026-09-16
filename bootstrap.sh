#!/usr/bin/env bash
# Fetch GenericArch-Android from GitHub, then hand over to its install.sh.
#
#   Recommended — read it before you run it:
#     curl -fsSLO https://raw.githubusercontent.com/MalaRuparel2023/GenericArch-Android/HEAD/bootstrap.sh
#     less bootstrap.sh && bash bootstrap.sh --apply
#
#   One-liner, if you already trust the source:
#     curl -fsSL https://raw.githubusercontent.com/MalaRuparel2023/GenericArch-Android/HEAD/bootstrap.sh | bash -s -- --apply
#
# Run it from the root of the Android project you want the layer installed into.
# Dry run unless --apply is given.
#
# Overrides:
#   GA_REPO=<git url|path>   where to fetch from  (default: the MalaRuparel2023 remote)
#   GA_REF=<tag|branch>      which version to pin (default: the newest semver tag, else the
#                            default branch)
#   --ref <tag>              same, as a flag — usable through `curl ... | bash -s -- --ref <tag>`
#   --with-ci ·              install.sh's own flags, forwarded verbatim
#   --with-conventions
#
# To remove a layer this installed, run the uninstall from the target project:
#   bash scripts/uninstall.sh --apply
# It reads .claude/.genericarch-manifest and removes exactly what the install wrote.
#
# This is the ONLY script in the lifecycle that touches the network, and all it does is fetch.
# Every decision about what lands in your repo belongs to install.sh, which runs offline against
# the clone this leaves behind.
set -uo pipefail

RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; DIM=$'\033[2m'; BLD=$'\033[1m'; OFF=$'\033[0m'

GA_REPO="${GA_REPO:-https://github.com/MalaRuparel2023/GenericArch-Android.git}"
GA_REF="${GA_REF:-}"
RESOLVED_LATEST=0
APPLY=0
PASS_THROUGH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --ref) [ $# -ge 2 ] || { echo "--ref needs a tag" >&2; exit 2; }; GA_REF="$2"; shift 2 ;;
    --help|-h) sed -n '2,29p' "$0" 2>/dev/null || echo "see the header of bootstrap.sh"; exit 0 ;;
    # install.sh's own flags, forwarded verbatim.
    --with-ci|--with-conventions) PASS_THROUGH="$PASS_THROUGH $1"; shift ;;
    # A trailing `# comment` pasted from the README arrives as arguments in zsh, whose
    # interactive_comments is off by default. Say that, rather than reporting `#` as a typo.
    '#') echo "${YEL}⚠${OFF} a '#' comment reached this script as an argument — your shell did not" >&2
         echo "  strip it (zsh does not, by default). Paste the command without its trailing" >&2
         echo "  comment, or run:  setopt interactive_comments" >&2
         exit 2 ;;
    *) echo "unknown argument: $1" >&2
       echo "  bootstrap flags: --apply --ref <tag> --help" >&2
       echo "  forwarded to install.sh: --with-ci --with-conventions" >&2
       exit 2 ;;
  esac
done

TARGET="$PWD"

command -v git >/dev/null 2>&1 || { echo "${RED}git is required${OFF}" >&2; exit 1; }

# Refuse before the fetch, not after — a machine that cannot use the layer never clones it.
# install.sh repeats both of these checks offline; duplicating them here only moves the refusal
# earlier, it does not own the decision.

# The usual copy/paste accident: running this inside the framework base itself. Identified by the
# base's own layout, not by a CLAUDE.md mention — an app that documents its adoption of the layer
# names it too, and refusing those made a re-run of the install impossible.
if [ -f "$TARGET/scripts/install.sh" ] && [ -d "$TARGET/android/rules" ] && [ -d "$TARGET/.claude/skills" ]; then
  echo "${RED}this looks like the GenericArch-Android base itself — nothing to install${OFF}" >&2
  echo "  ${DIM}run this from the root of the app you want the layer installed into${OFF}" >&2
  exit 1
fi

# Same refusal and same exit code as install.sh: a layer installs into a project that builds.
if [ ! -f "$TARGET/settings.gradle.kts" ] && [ ! -f "$TARGET/settings.gradle" ]; then
  echo "${RED}refused: $TARGET has no settings.gradle[.kts].${OFF}" >&2
  echo "  GenericArch installs into a project that already builds, not an empty directory." >&2
  echo "  ${DIM}Nothing was fetched and nothing was written.${OFF}" >&2
  exit 3
fi

# A piped script cannot see the URL it was fetched from, so a hardcoded default silently installs
# the wrong version. Resolve the newest semver tag from the remote instead, and let --ref override.
# Tag names are matched with an optional leading `v` because either spelling is plausible.
semver_tags() {
  git ls-remote --tags --refs "$GA_REPO" 2>/dev/null \
    | awk -F'refs/tags/' 'NF>1 {print $2}' \
    | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
    | awk '{o=$0; v=$0; sub(/^v/,"",v); print v"\t"o}' \
    | sort -t. -k1,1n -k2,2n -k3,3n
}

# `0.2.0` and `v0.2.0` are the SAME version under two names, and nothing stops them pointing at
# different commits. A collision is reported and the choice named rather than left to whichever
# way `sort` happened to break the tie.
resolve_latest_ref() {
  local tags newest dupes
  tags="$(semver_tags)"
  [ -n "$tags" ] || return 0
  newest="$(printf '%s\n' "$tags" | tail -1 | cut -f1)"
  dupes="$(printf '%s\n' "$tags" | awk -F'\t' -v n="$newest" '$1==n {print $2}')"
  if [ "$(printf '%s\n' "$dupes" | grep -c .)" -gt 1 ]; then
    echo "${YEL}two tags both claim version $newest and may point at different commits:${OFF}" >&2
    printf '%s\n' "$dupes" | sed "s|^|    |" >&2
    echo "  ${DIM}picking the last by name; pass --ref <tag> to choose, or delete the duplicate tag${OFF}" >&2
  fi
  printf '%s\n' "$dupes" | tail -1
}

if [ -z "$GA_REF" ]; then
  GA_REF="$(resolve_latest_ref)"
  if [ -n "$GA_REF" ]; then
    RESOLVED_LATEST=1
  else
    echo "${YEL}no semver tag on $GA_REPO — using the default branch${OFF}" >&2
    echo "  ${DIM}pass --ref <tag> to pin a version you can reproduce${OFF}" >&2
    GA_REF=""
  fi
fi

echo
echo "${BLD}GenericArch-Android bootstrap${OFF}"
echo "  into    $TARGET"
echo "  from    $GA_REPO"
if [ "$RESOLVED_LATEST" -eq 1 ]; then
  echo "  version ${BLD}$GA_REF${OFF} ${DIM}(newest tag on the remote; pass --ref to pin another)${OFF}"
elif [ -n "$GA_REF" ]; then
  echo "  version ${BLD}$GA_REF${OFF} ${DIM}(pinned)${OFF}"
else
  echo "  version ${BLD}default branch${OFF} ${DIM}(untagged — not reproducible)${OFF}"
fi
[ "$APPLY" -eq 1 ] && echo "  mode    ${GRN}APPLY${OFF}" || echo "  mode    ${YEL}dry run${OFF} (add --apply to write)"
echo

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "${DIM}fetching ${GA_REF:-default branch}...${OFF}"
if [ -n "$GA_REF" ]; then
  if ! git clone --quiet --depth 1 --branch "$GA_REF" "$GA_REPO" "$TMP/base" 2>/dev/null; then
    # A tag that does not exist, or a local path clone — retry without --branch.
    git clone --quiet --depth 1 "$GA_REPO" "$TMP/base" 2>/dev/null || {
      echo "${RED}could not fetch $GA_REPO${OFF}" >&2
      echo "  ${DIM}set GA_REPO to a reachable URL or a local checkout path${OFF}" >&2
      exit 1
    }
    echo "${YEL}⚠ ref '$GA_REF' not found — installed from the default branch instead${OFF}" >&2
    echo "  ${DIM}Pin a tag for anything you intend to reproduce.${OFF}" >&2
  fi
else
  git clone --quiet --depth 1 "$GA_REPO" "$TMP/base" 2>/dev/null || {
    echo "${RED}could not fetch $GA_REPO${OFF}" >&2
    echo "  ${DIM}set GA_REPO to a reachable URL or a local checkout path${OFF}" >&2
    exit 1
  }
fi
echo "${DIM}fetched $(git -C "$TMP/base" describe --tags --always 2>/dev/null || echo unknown)${OFF}"

[ -f "$TMP/base/scripts/install.sh" ] || {
  echo "${RED}the fetched base has no scripts/install.sh${OFF}" >&2; exit 1
}
chmod +x "$TMP/base/scripts/install.sh" 2>/dev/null || true

# Everything from here is offline and belongs to install.sh: the plan, the never-overwrite rule,
# the summary. Duplicating any of it here is how the two would disagree.
# shellcheck disable=SC2086
if [ "$APPLY" -eq 1 ]; then
  "$TMP/base/scripts/install.sh" --target "$TARGET" --apply $PASS_THROUGH
else
  "$TMP/base/scripts/install.sh" --target "$TARGET" --dry-run $PASS_THROUGH
fi
rc=$?

if [ "$APPLY" -eq 0 ] && [ "$rc" -eq 0 ]; then
  echo
  echo "Dry run only. Re-run with ${BLD}--apply${OFF} to write."
fi
exit "$rc"
