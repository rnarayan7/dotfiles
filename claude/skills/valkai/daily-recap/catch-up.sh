#!/usr/bin/env bash
# SessionStart hook: archive any of the last few days that has no recap yet, in the background.
set -euo pipefail

LOOKBACK_DAYS=7
STALE_LOCK_MINUTES=180
ARCHIVE_ROOT="$HOME/Documents/valkai/journal/daily"
LOCK="$ARCHIVE_ROOT/.catch-up.lock"
NIGHTLY="$HOME/.claude/skills/daily-recap/nightly.sh"

# The archive run starts its own Claude session; do not recurse.
[ -n "${DAILY_RECAP_RUNNING:-}" ] && exit 0

mkdir -p "$ARCHIVE_ROOT"
find "$LOCK" -maxdepth 0 -mmin +"$STALE_LOCK_MINUTES" -exec rmdir {} \; 2>/dev/null || true
mkdir "$LOCK" 2>/dev/null || exit 0

missing=()
for i in $(seq "$LOOKBACK_DAYS" -1 1); do
  day="$(date -v-"${i}"d +%F)"
  [ -s "$ARCHIVE_ROOT/$day/recap.md" ] || missing+=("$day")
done

if [ ${#missing[@]} -eq 0 ]; then
  rmdir "$LOCK"
  exit 0
fi

nohup bash -c '
  for day in "$@"; do "'"$NIGHTLY"'" "$day" || true; done
  rmdir "'"$LOCK"'"
' _ "${missing[@]}" >/dev/null 2>&1 &
disown
echo "daily-recap: archiving ${missing[*]} in the background"
