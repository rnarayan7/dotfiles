#!/usr/bin/env bash
# Archive one day's raw activity and a recap under ~/Documents/valkai/journal/daily/DAY.
# Usage: nightly.sh [YYYY-MM-DD]   (default: yesterday)
set -euo pipefail

export DAILY_RECAP_RUNNING=1
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

DAY="${1:-$(date -v-1d +%F)}"
ARCHIVE_ROOT="$HOME/Documents/valkai/journal/daily"
REPO="$HOME/Documents/valkai/onyx"
SKILL_DIR="$HOME/.claude/skills/daily-recap"
DIR="$ARCHIVE_ROOT/$DAY"
TRANSCRIPTS="$DIR/raw/claude-transcripts"

mkdir -p "$TRANSCRIPTS"
exec >>"$DIR/run.log" 2>&1
echo "=== $(date '+%F %T') nightly recap for $DAY"

# Claude Code deletes old transcripts, so keep a compressed copy of every session active that day.
NEXT_DAY="$(date -j -v+1d -f %F "$DAY" +%F)"
find "$HOME/.claude/projects" -name '*.jsonl' -newermt "$DAY 00:00" -print0 |
  while IFS= read -r -d '' f; do
    if grep -q "\"timestamp\":\"$DAY" "$f" || grep -q "\"timestamp\":\"$NEXT_DAY" "$f"; then
      project="$(basename "$(dirname "$f")")"
      gzip -c "$f" >"$TRANSCRIPTS/${project}__$(basename "$f").gz"
    fi
  done

cd "$REPO"
claude -p "/daily-recap $DAY --archive $DIR" \
  --add-dir "$DIR" \
  --permission-mode dontAsk \
  --allowedTools \
    "Skill" "ToolSearch" "Read" \
    "Edit(/$DIR/**)" \
    "Bash($SKILL_DIR/sessions.sh:*)" "Bash(~/.claude/skills/daily-recap/sessions.sh:*)" "Bash($SKILL_DIR/timeline.py:*)" "Bash(~/.claude/skills/daily-recap/timeline.py:*)" "Bash(gh search prs:*)" "Bash(gh pr view:*)" "Bash(date:*)" \
    "mcp__plugin_slack_slack__slack_search_public_and_private" "mcp__plugin_slack_slack__slack_read_thread" \
    "mcp__claude_ai_Slack__slack_search_public_and_private" "mcp__claude_ai_Slack__slack_read_thread" \
    "mcp__notionApi__notion-search" "mcp__notionApi__notion-fetch" "mcp__notionApi__notion-query-meeting-notes" \
    "mcp__linear__list_issues" "mcp__claude_ai_Granola__list_meetings"

test -s "$DIR/recap.md" && echo "=== done: $DIR/recap.md" || { echo "=== FAILED: no recap.md"; exit 1; }
