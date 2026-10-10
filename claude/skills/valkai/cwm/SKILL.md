---
name: cwm
description: Confirm with me. Ask the user before taking any action that changes something, even in auto mode. Use only when the user types /cwm.
argument-hint: "[task]"
disable-model-invocation: true
---

# Confirm with me

The user turned this on because auto mode lets you act without permission prompts, and you
have been doing things they didn't want. For the message that invoked /cwm, nothing changes
without their explicit yes.

If the user passed a task as an argument, do that task under these rules. If not, apply these
rules to the request in that same message.

## What needs a yes first

Any action that changes state or reaches outside this machine:

- Creating, editing, moving or deleting files
- Shell commands that change things: installs, builds that write files, migrations, `rm`, `mv`
- Git: commit, branch, checkout, reset, rebase, merge, push, tag, stash
- PRs, issues, comments, messages, or any other post to an external service
- Starting or stopping processes, servers, containers or deploys
- Spawning subagents or workflows that will do any of the above

Reading, searching, listing files and read-only commands (`git status`, `git diff`, `ls`, `cat`)
need no confirmation. Investigate as much as you need before proposing.

## How to ask

1. Investigate first, then propose a short plan: the concrete steps, which files or commands
   each touches, and anything destructive or hard to undo called out on its own line.
2. Ask with AskUserQuestion: options "Proceed", "Change the plan" and "Stop". Wait for the
   answer. Do not start the work in the same turn as the proposal.
3. Do exactly the approved steps. Approval covers only those steps, not anything that comes up
   while doing them.
4. If something requires a step outside the plan (a fix you didn't foresee, an extra file, a
   follow-up command, a "while I'm here" cleanup), stop and ask again before doing it.
5. If a step fails, report what happened and ask how to proceed. Don't try alternative
   approaches on your own.

Never broaden scope on your own. If you notice something else worth doing, mention it in one
line and leave it.

## When it ends

These rules cover only the message that invoked /cwm, including the approvals and follow-up
questions needed to finish that task. When the task is done, go back to normal behavior. A
later message gets these rules only if it invokes /cwm again.

Acknowledge with one line saying confirm mode is on, then continue with the task if one was given.
