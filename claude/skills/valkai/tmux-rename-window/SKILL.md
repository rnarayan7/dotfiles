---
name: tmux-rename-window
description: Rename the current tmux window to the exact text the user gives. Use for /tmux-rename-window <name> or "rename my tmux window to X".
argument-hint: "<window name>"
---

# Rename the tmux window

## 1. Get the name

Use the skill argument exactly as typed, with surrounding whitespace trimmed. Do not reword, shorten, or add a prefix. If the argument is empty, ask the user for a name.

## 2. Check for tmux

Run `echo "$TMUX_PANE"` as its own command. If it is empty, the session is not inside tmux: tell the user and stop. Otherwise keep the pane ID it prints (e.g. `%88`).

## 3. Rename the window

Target the pane ID from step 2, not the active window. The user may have a different window focused.

Pass the literal pane ID, not `$TMUX_PANE`, and run each command on its own. In a worktree-isolated session, the worktree guard refuses tmux commands that use a runtime variable. Quote the name in single quotes; escape any single quote in it as `'\''`.

```bash
tmux rename-window -t %88 'my window name'
```

```bash
tmux set-option -w -t %88 allow-rename off
```

`rename-window` turns off `automatic-rename` for that window. `allow-rename off` stops programs from overwriting the name with terminal escape sequences.

## 4. Report

Reply with one line: the new window name.
