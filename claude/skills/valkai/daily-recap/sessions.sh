#!/usr/bin/env bash
# Print one block per Claude Code session with activity on a local date.
# Usage: sessions.sh [YYYY-MM-DD]   (default: today)
set -euo pipefail

DAY="${1:-$(date +%F)}"
PROMPT_CHARS=200
MAX_PROMPTS=15

for f in $(find "$HOME/.claude/projects" -name '*.jsonl' -newermt "$DAY 00:00" 2>/dev/null); do
  jq -rs --arg day "$DAY" --argjson n "$PROMPT_CHARS" --argjson max "$MAX_PROMPTS" '
    def localday: sub("\\.[0-9]+Z$"; "Z") | fromdate | strflocaltime("%Y-%m-%d");
    def localtime: sub("\\.[0-9]+Z$"; "Z") | fromdate | strflocaltime("%H:%M");
    select(any(.[]; .entrypoint? == "sdk-cli") | not)
    | (map(select(.type == "ai-title")) | last | .aiTitle // "untitled") as $title
    | map(select(.timestamp? and (.timestamp | localday) == $day)) as $today
    | ($today | map(select(.type == "user" and (.message.content | type) == "string"
                           and (.isMeta | not)
                           and (.message.content | test("^(<|Another Claude session)") | not)))) as $prompts
    | select($prompts | length > 0)
    | select(($prompts[0].message.content | startswith("You are")) | not)
    | ($today | map(.message.content? // empty | if type == "array" then map(.text? // .content? // "" | tostring) | join(" ") else tostring end)
        | join(" ") | [scan("https://github\\.com/valkai-tech/[^/ ]+/pull/[0-9]+")] | unique) as $prs
    | "## \($title)",
      "cwd: \($today[0].cwd // "?")  branch: \($today[0].gitBranch // "?")  time: \($today[0].timestamp | localtime)-\($today[-1].timestamp | localtime)",
      (if ($prs | length) > 0 then "PRs: \($prs | join(" "))" else empty end),
      "prompts:",
      ($prompts[:$max][] | "- " + (.message.content | gsub("\\s+"; " ") | .[:$n])),
      ""
  ' "$f"
done
