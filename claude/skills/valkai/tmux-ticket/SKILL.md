---
name: tmux-ticket
description: Rename the current tmux window after the Linear ticket in progress (e.g. "Claude ENG-10398 flaura eval"). Use for /tmux-ticket, "name my tmux window", or when starting work on a Linear ticket inside tmux.
argument-hint: "[ticket-id | linear-url]"
---

# Name the tmux window after a Linear ticket

## 1. Check for tmux

Run `echo "$TMUX_PANE"`. If it is empty, the session is not inside tmux: tell the user and stop.

## 2. Find the ticket ID

Use the first source that gives an ID:

1. The skill argument: a bare ID (`ENG-1234`, any case) or a Linear URL (take the ID from `/issue/<ID>/`).
2. The current branch: `git branch --show-current | grep -oiE '[a-z]+-[0-9]+' | head -1` (matches `codex/eng-10398-foo`, `roshan/ENG-1234-bar`).
3. A ticket that this conversation is already working on.

If no source gives an ID, ask the user for one. Uppercase the ID.

## 3. Get a short title

Load `mcp__linear__get_issue` with ToolSearch, then fetch the issue. Make a label of 2–4 lowercase words from the title that identify the work. Drop filler and bracket prefixes (e.g. "Filter Arena documents by custom attributes" → `arena attr filter`).

If the Linear call fails, name the window `Claude <ID>` with no title and say that the title lookup failed.

## 4. Rename the window

The name is `Claude <ID> <label>`.

Target `$TMUX_PANE`, not the active window. The user may have a different window focused.

```bash
tmux rename-window -t "$TMUX_PANE" "Claude ENG-1234 arena attr filter"
tmux set-option -w -t "$TMUX_PANE" allow-rename off
```

`rename-window` turns off `automatic-rename` for that window. `allow-rename off` stops programs from overwriting the name with terminal escape sequences.

## 5. Report

Reply with one line: the new window name.
