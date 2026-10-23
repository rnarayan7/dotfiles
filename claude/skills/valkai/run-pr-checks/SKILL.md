---
name: run-pr-checks
description: Trigger the Bugbot and Devin reviews on a GitHub PR by posting `bugbot run` and `/devin review` comments. Use for /run-pr-checks, "run bugbot and devin", or "run the review bots on my PR".
argument-hint: "[pr-number | pr-url | description of the PR]"
---

# Run the PR review bots

The user's invocation of this skill authorizes posting the two trigger comments. Post nothing else.

## 1. Find the PR

Use the first source that names a PR:

1. **Argument is a number or URL** (`11123`, `#11123`, `https://github.com/<owner>/<repo>/pull/11123`): use it.
2. **Argument is a description:** search `gh pr list --author @me --state open --limit 30 --json number,title` and pick the best title match. If two or more match equally well, list them and ask.
3. **No argument:** the PR this conversation is working on; else the PR for the current branch (`gh pr view --json number,title`); else ask.

## 2. Post the triggers

Run these as two separate plain commands. Both bots work on draft PRs.

```bash
gh pr comment <n> --body "bugbot run"
gh pr comment <n> --body "/devin review"
```

## 3. Report

Reply in one or two lines: the PR number and title, and that both reviews are triggered. Both bots take a few minutes; suggest `/check-comments <n>` to read their findings.
