---
name: check-comments
description: Find a GitHub PR and summarize its latest review comments, threads, and bot findings (Devin, Bugbot) with a suggested action for each. Use for /check-comments, "check the comments on my PR", "what did <reviewer> say", or "any new comments on #1234".
argument-hint: "[pr-number | pr-url | description of the PR]"
---

# Check the latest comments on a PR

Never resolve threads, here or later: the user resolves every conversation. When you fix a comment after this skill, reply on its thread once the fix is pushed, in the user's voice, without asking first. Comments that need only a reply (no code change): draft and ask first.

## 1. Find the PR

Use the first source that names a PR:

1. **Argument is a number or URL** (`11123`, `#11123`, `https://github.com/<owner>/<repo>/pull/11123`): use it.
2. **Argument is a description** ("the control plane deploy PR", "Nav's comments on the role PR"): search the user's PRs and pick the best title match.
   ```bash
   gh pr list --author @me --state all --limit 30 --json number,title,state,updatedAt
   ```
   If two or more match equally well, list them and ask.
3. **No argument**:
   - The PR this conversation is working on, if there is one.
   - Else the PR for the current branch: `gh pr view --json number,title`.
   - Else the user's most recently updated open PR: `gh pr list --author @me --state open --limit 5 --json number,title,updatedAt`.

State which PR you picked (number and title) in the first line of the report.

## 2. Fetch everything

Run these as separate plain commands. Worktree-isolated sessions reject long pipelines, loops, and `git -C`.

```bash
gh pr view <n> --json title,state,isDraft,reviewDecision,mergeStateStatus,headRefOid,updatedAt
```

Review threads with resolution state (inline comments live here):
```bash
gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){reviewThreads(first:50){nodes{id isResolved isOutdated path line comments(first:20){nodes{author{login} createdAt body}}}}}}}'
```

Top-level reviews and conversation comments:
```bash
gh pr view <n> --json reviews,comments
```

If a bot body is long or HTML-heavy, fetch that one comment and strip tags:
```bash
gh api repos/<owner>/<repo>/pulls/comments/<id> --jq '.body | gsub("<[^>]*>";"")'
```

Checks that failed or are still running:
```bash
gh pr checks <n> --json name,state,link -q '.[] | select(.state!="SUCCESS" and .state!="SKIPPED") | "\(.state) \(.name) \(.link)"'
```

For each failed check, find the cause. Take the `job=` ID from its depot.dev link and run `depot ci diagnose --job <id>`. For a link that is not depot.dev, run `gh run view <run-id> --log-failed`.

## 3. Decide what is new

- **Needs attention:** an unresolved thread whose last comment is not from the user, and any review or conversation comment newer than the user's last reply or push.
- **Answered:** an unresolved thread where the user replied last. The user resolves it; it needs no action.
- **Outdated:** a thread on code that changed or no longer exists (`isOutdated`).
- Skip `bugbot run` comments, the Linear linkback comment, and review-badge summaries with no findings.

## 4. Check each item before reporting it

- **Questions from humans:** answer from the code. Read the lines in question at the PR head, not from memory.
- **Bot findings (Devin, Bugbot):** verify the claim against the code and say whether it is real, a known trade-off, or a false positive. Check whether the same behavior already exists elsewhere in the repo; if so, say so.
- Devin can hold flags it did not post on GitHub ("1 flag not posted"). Mention them with the Devin Review link; you cannot see their content.

## 5. Report

Lead with the answer: the PR, the review state (approved, changes requested, review required), and how many items need attention.

Then one block per item, newest first:

- **Who, where:** author and `file:line` (or "conversation").
- **What they said:** quote the comment, short.
- **Status:** needs attention, answered, or outdated.
- **Assessment:** for a question, the answer. For a finding, real / trade-off / false positive, with the evidence.
- **Suggested action:** a code change (what and where) or a reply.
- **Draft reply:** in the user's voice: casual, short, lowercase start, no AI phrasing.

Then one block per failed check:

- **Check:** its name.
- **Cause:** the error from the diagnosis, short.
- **Fix:** the code change, label, or re-run that clears it.

List running checks by name on one line.

End with what blocks merge (unresolved threads, missing approval, failed checks), and offer to post the replies or make the changes.
