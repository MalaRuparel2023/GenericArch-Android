#!/usr/bin/env bash
# uninstall.sh — remove a GenericArch-Android install from a project.
#
# Reads .claude/.genericarch-manifest and removes exactly the paths it names. A file you added
# yourself is never touched, because it was never in the manifest. A file you edited since the
# install is reported and left alone unless --force is given.
#
# Exit codes: 0 ok · 2 usage · 5 no manifest
set -euo pipefail

TARGET="$PWD"
APPLY=0
FORCE=0
MANIFEST_REL=".claude/.genericarch-manifest"

usage() {
  cat <<'USAGE'
Usage: uninstall.sh [options]

  --target <dir>   Project to remove the layer from (default: current directory)
  --apply          Delete. Without it, this is a dry run and nothing is removed.
  --dry-run        Explicit dry run (the default)
  --force          Also remove files that changed since the install
  -h, --help       This message
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) [ $# -ge 2 ] || { echo "--target needs a directory" >&2; exit 2; }; TARGET="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -d "$TARGET" ] || { echo "target is not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

MANIFEST="$TARGET/$MANIFEST_REL"
[ -f "$MANIFEST" ] || {
  echo "no GenericArch-Android manifest in $TARGET" >&2
  echo "  nothing here was installed by install.sh, so nothing is removed." >&2
  exit 5
}

VERSION="$(awk -F'\t' '$1=="version" {print $2}' "$MANIFEST" | head -1)"
echo "GenericArch-Android ${VERSION:-unknown} ← $TARGET"
[ "$APPLY" -eq 1 ] || echo "(dry run — nothing is removed; pass --apply to delete)"
echo

if command -v shasum >/dev/null 2>&1; then
  ga_hash() { shasum -a 256 "$1" | cut -d' ' -f1; }
elif command -v sha256sum >/dev/null 2>&1; then
  ga_hash() { sha256sum "$1" | cut -d' ' -f1; }
else
  ga_hash() { echo -; }
fi

removed=0 kept=0
dirs=()
while IFS=$'\t' read -r kind rel want; do
  [ "$kind" = file ] || continue
  dst="$TARGET/$rel"
  if [ ! -e "$dst" ]; then
    printf '  %-52s  already gone\n' "$rel"; continue
  fi
  # An edited file is yours now. Deleting it would throw away work the install never authored,
  # so it is reported and kept unless --force says otherwise.
  if [ "$FORCE" -eq 0 ] && [ -n "${want:-}" ] && [ "$want" != - ] && [ "$(ga_hash "$dst")" != "$want" ]; then
    printf '  %-52s  changed since install, kept\n' "$rel"; kept=$((kept + 1)); continue
  fi
  printf '  %-52s  %s\n' "$rel" "$([ "$APPLY" -eq 1 ] && echo removed || echo 'would remove')"
  [ "$APPLY" -eq 1 ] && rm -f "$dst"
  dirs+=("$(dirname "$dst")")
  removed=$((removed + 1))
done < "$MANIFEST"

# The manifest outlives a partial removal: with files still kept, it is the only record of what
# this install owns, and deleting it would strand them.
if [ "$APPLY" -eq 1 ] && [ "$kept" -eq 0 ]; then
  rm -f "$MANIFEST"
  # Deepest first, and rmdir only — a directory that still holds one of your own files survives.
  printf '%s\n' ${dirs+"${dirs[@]}"} | sort -ru | while IFS= read -r d; do
    while [ "$d" != "$TARGET" ] && [ -d "$d" ]; do
      rmdir "$d" 2>/dev/null || break
      d="$(dirname "$d")"
    done
  done
fi

echo
echo "  $removed removed, $kept left alone"
if [ "$kept" -gt 0 ]; then
  echo "  ${MANIFEST_REL} kept — it still names the files above. Re-run with --force to remove them."
fi
