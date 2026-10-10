---
name: close-ticket
description: Close out a Linear ticket: confirm its PRs merged, its scope shipped, and its status is Done, then remove its worktree. Use for /close-ticket or "wrap up ENG-1234".
argument-hint: "[ticket-id | linear-url]"
---

# Close out a Linear ticket

Run the checks in order. Report every result, then act only as each step allows. Run git and tmux commands as plain, separate commands with literal values; worktree-isolated sessions refuse compound commands and runtime variables.

## 1. Find the ticket ID

Use the first source that gives an ID:

1. The skill argument: a bare ID (`ENG-1234`, any case) or a Linear URL (take the ID from `/issue/<ID>/`).
2. The current branch: `git branch --show-current`, matching `eng-<number>`.
3. A ticket that this conversation already worked on.

If no source gives an ID, ask the user. Uppercase the ID. If this conversation worked on more tickets in the same worktree, run steps 2–6 for each of them.

## 2. Find the ticket's PRs

1. Load `mcp__linear__get_issue` with ToolSearch. Fetch the issue with `title`, `description`, `status`, and `attachments`. Take PR URLs from the attachments.
2. Also run `gh pr list -R valkai-tech/onyx --state all --search "<ID> in:title" --json number,title,state,headRefName,url`.
3. Use the union of both lists. If there are no PRs, report that and stop.

## 3. Check that every PR merged

For each PR, run `gh pr view <number> -R valkai-tech/onyx --json state,mergedAt,headRefName,headRefOid`.

- `MERGED`: pass.
- `OPEN`: fail. Name the PR and stop after the report.
- `CLOSED` without a merge: ignore it if a merged PR covers the same work, else fail.

## 4. Check that the ticket's scope shipped

1. List each change the ticket description asks for.
2. Read the merged diffs: `gh pr diff <number> -R valkai-tech/onyx`.
3. Mark each item shipped, partly shipped, or missing, with the file that shows it.

If an item is partly shipped or missing, report it and stop. Do not change the ticket or the worktree.

## 5. Check the ticket status

- `Done`: pass.
- Any other status: set it to `Done` with `mcp__linear__save_issue`, then fetch it again to confirm.

## 6. Remove the ticket's worktree

Run `git fetch origin` first. A branch has shipped when every commit it has that `origin/main` lacks was folded into a merged squash commit:

1. List the branch's commits: `git rev-list origin/main..<branch>`.
2. List the ticket's merged PR commits: `gh pr view <number> -R valkai-tech/onyx --json commits -q '.commits[].oid'` for each merged PR.
3. The branch has shipped when list 2 contains every SHA in list 1. An empty list 1 also counts as shipped.

Then:

1. Run `git worktree list --porcelain`. Select the worktrees whose checked-out branch contains the ticket ID (case-insensitive). Never select the main checkout.
2. Skip a selected worktree, and report the reason, when any of these is true:
   - `git -C <path> status --porcelain` shows changes.
   - Its branch has not shipped. Name the SHAs that are missing from the PRs.
   - The porcelain output marks it `locked`, and this session is not inside it.
3. Remove each worktree that passed. Never pass `--force`.
   - If this session is inside it, call `ExitWorktree` with `action: "remove"` and `discard_changes: true`. The shipped check covers the commits it would discard. Only this session can call it; do not delegate it to a subagent.
   - Else run `git worktree remove <path>`.
4. Run `git branch --list`. Delete each local branch that contains the ticket ID, has shipped, and no remaining worktree has checked out: `git branch -D <branch>`. `ExitWorktree` deletes only the branch name it created, so check again after it.

## 7. Report

Use one line for each check, as `label: result`:

- PRs: each number with its state and merge time.
- Scope: shipped, or the items that are not shipped.
- Linear: the status, and whether this run changed it.
- Worktrees: each path, removed or skipped with its reason.
- Branches: each local branch deleted or kept.
