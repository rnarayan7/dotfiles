#!/usr/bin/env bash
# Keep tmux windows in three groups: pinned names first, then windows used in the
# last few hours, then idle windows. tmux.conf runs this from status-right every
# status-interval, so it must print nothing.
#
# Options (set -g):
#   @autosort         on | off
#   @autosort-pinned  space-separated window names kept first (default: general todo)
#   @autosort-hours   hours since last use before a window counts as idle (default: 3)
#
# Window options it maintains:
#   @last_seen  time of the last keypress while the window was current, seeded
#               from the window's last output time
#   @idle       1 when the window is past @autosort-hours (formats dim it)
#   @bell       1 when a moved window had an unseen bell (move-window drops the flag)
set -u

DEFAULT_PINNED="general todo"
DEFAULT_HOURS=3
TEMP_INDEX_BASE=10000
LOCK="${TMPDIR:-/tmp}/tmux-autosort-$(id -u).lock"

mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK"' EXIT

enabled=$(tmux show -gqv @autosort)
pinned=$(tmux show -gqv @autosort-pinned)
pinned=${pinned:-$DEFAULT_PINNED}
hours=$(tmux show -gqv @autosort-hours)
hours=${hours:-$DEFAULT_HOURS}
cutoff=$(( $(date +%s) - hours * 3600 ))

# Stamp each client's current window with that client's last input time.
tmux list-clients -F '#{window_id}|#{client_activity}|#{@last_seen}' |
  while IFS='|' read -r wid activity seen; do
    if [[ -z "$seen" || "$activity" -gt "$seen" ]]; then
      tmux set -w -t "$wid" @last_seen "$activity"
    fi
    tmux set -wqu -t "$wid" @bell
  done

# A window never seen yet (new, restored, or from before autosort) starts from its
# last output time.
tmux list-windows -a -f '#{==:#{@last_seen},}' -F '#{window_id}|#{window_activity}' |
  while IFS='|' read -r wid activity; do
    tmux set -w -t "$wid" @last_seen "$activity"
  done

if [[ "$enabled" != "on" ]]; then
  tmux list-windows -a -F '#{window_id}|#{@idle}' | while IFS='|' read -r wid idle; do
    [[ -n "$idle" ]] && tmux set -wqu -t "$wid" @idle
  done
  exit 0
fi

base_index=$(tmux show -gv base-index)

for sid in $(tmux list-sessions -F '#{session_id}'); do
  ids=() names=() current_order=()
  pinned_ids=() active_ids=() idle_ids=()

  while IFS='|' read -r wid name seen idle bell; do
    ids+=("$wid")
    names+=("$name")
    current_order+=("$wid")
    is_pinned=0
    for p in $pinned; do [[ "$name" == "$p" ]] && is_pinned=1; done
    if (( is_pinned )); then
      want_idle=""
    elif [[ -n "$seen" && "$seen" -ge "$cutoff" ]]; then
      want_idle=""
      active_ids+=("$wid")
    else
      want_idle=1
      idle_ids+=("$wid")
    fi
    if [[ "$idle" != "$want_idle" ]]; then
      if [[ -n "$want_idle" ]]; then tmux set -w -t "$wid" @idle 1; else tmux set -wqu -t "$wid" @idle; fi
    fi
  done < <(tmux list-windows -t "$sid" -F '#{window_id}|#{window_name}|#{@last_seen}|#{@idle}|#{window_bell_flag}')

  # Pinned windows go in the order @autosort-pinned lists them.
  for p in $pinned; do
    for i in "${!names[@]}"; do
      [[ "${names[$i]}" == "$p" ]] && pinned_ids+=("${ids[$i]}")
    done
  done

  desired=("${pinned_ids[@]+"${pinned_ids[@]}"}" "${active_ids[@]+"${active_ids[@]}"}" "${idle_ids[@]+"${idle_ids[@]}"}")
  [[ "${desired[*]}" == "${current_order[*]}" ]] && continue

  # move-window drops the bell flag, so keep it in @bell for the formats.
  tmux list-windows -t "$sid" -f '#{window_bell_flag}' -F '#{window_id}' | while read -r wid; do
    tmux set -w -t "$wid" @bell 1
  done

  i=0
  for wid in "${desired[@]}"; do
    tmux move-window -d -s "$wid" -t "$sid:$(( TEMP_INDEX_BASE + i ))"
    i=$(( i + 1 ))
  done
  for (( j = 0; j < i; j++ )); do
    tmux move-window -d -s "$sid:$(( TEMP_INDEX_BASE + j ))" -t "$sid:$(( base_index + j ))"
  done
done
