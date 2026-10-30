---
name: vscode
description: Open VS Code on a directory or onyx worktree (ENG ID, worktree name, path, or the current session's checkout). Use for /vscode or "open this in vscode".
argument-hint: "[ENG-1234 | worktree name | path]"
---

# Open in VS Code

## 1. Resolve the directory

Worktrees live in `~/Documents/valkai/onyx/.claude/worktrees/<name>`.

* **No argument or "this":** the current session's checkout, from `git rev-parse --show-toplevel`.
* **Ticket (`ENG-1234` or `1234`):** `worktrees/eng-1234`.
* **Path:** that path, with `~` expanded.
* **Other word:** the worktree whose name contains it. `ls` the worktrees folder to match. If several match, list them and ask which one.

If the directory does not exist, say so and list the closest worktree names. Do not create a worktree.

## 2. Open it

The `code` CLI is not on PATH. Run:

```bash
open -a "Visual Studio Code" /abs/path
```

Reply with one line: the path that opened.
