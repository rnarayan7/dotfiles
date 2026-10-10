---
name: tmux-recap
description: Review my open tmux windows and say which are ready to close, which to keep, and what to check first. Use for /tmux-recap, "which tmux windows can I close", or "review my tmux windows".
---

# Recap tmux windows

Read-only. Do not close windows, send keys, answer prompts in other panes, or remove worktrees. Offer cleanup at the end; do it only after the user says yes.

## 1. Check for tmux

Run `echo "$TMUX_PANE"`. If it is empty, tell the user the session is not inside tmux and stop. Note this session's own window (`tmux display -p -t "$TMUX_PANE" '#{session_name}:#{window_index}'`) so you leave it out of the review.

## 2. Collect the data

Run in one Bash call:

```bash
tmux list-windows -a -F '#{session_name}:#{window_index}|#{window_name}|#{window_activity}'
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_command}|#{pane_current_path}'
```

For each window, read the last screen of its first pane:

```bash
tmux capture-pane -p -t <session>:<window>.0 -S -40 | grep -v '^\s*$' | tail -8
```

A Claude pane usually ends with a `※ recap:` line that states the goal and the next step. Note any pane that waits on a question (a numbered option list), and any prompt line (`❯`) that holds typed text, which may be unsent.

Then, in parallel:

* **PRs:** for each PR number in the recaps or prompt footers (`PR #123`), run `gh pr view <n> --repo valkai-tech/onyx --json number,state,isDraft,mergedAt`.
* **Worktrees:** for each pane path under `.claude/worktrees/` or a sibling `onyx-*` checkout, run `git -C <path> status --porcelain | wc -l` and `git -C <path> log --oneline @{u}..HEAD | wc -l`.
* **Tickets:** if a window name has a ticket ID (`ENG-1234`) and the state is not clear from the recap, get its status from Linear with `mcp__linear__get_issue` (load it with ToolSearch).

## 3. Classify each window

* **Ready to close:** its PRs are merged or closed, its ticket is done, and its worktree has no uncommitted or unpushed changes. Also a pane that waits on a question about work already finished elsewhere. Say not to answer that question.
* **Probably ready:** the conversation reached an end ("ok got it", no next step), or the only open item is a small decision. Say what is lost on close, for example research results that live only in that session.
* **Keep:** an open or draft PR with a next step, a ticket still in progress, or recent activity.

Never mark a window ready to close if its worktree has uncommitted or unpushed changes. Name the window and the count instead.

## 4. Write the recap

Fit one screen. One line per window: `<session>:<index> <short name>: <reason>`. Use these sections and leave out any that is empty:

1. **Ready to close**
2. **Probably ready**
3. **Keep**
4. **Check first:** unsent prompts and windows with unsaved work.

End with one line that offers to remove the worktrees of the windows that are ready to close, after the user closes them.
