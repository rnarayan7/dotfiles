---
name: daily-recap
description: Recap what I accomplished on a day and how I spent my time, from Claude sessions, Slack, Notion, GitHub, Linear and meetings. Use for /daily-recap or "what did I do today".
argument-hint: "[today | yesterday | YYYY-MM-DD] [--archive DIR]"
---

# Daily recap

Read-only. Do not post, comment, edit pages or change tickets. Offer follow-ups at the end; do them only after the user says yes. The only allowed writes are archive files (section 6).

## 1. Resolve the day

Default `today`. Convert the argument to a local date `DAY` (`YYYY-MM-DD`) with `date`. Slack wants `on:DAY`. GitHub wants `DAY..NEXT_DAY`, where `NEXT_DAY` is the day after. Notion and Linear want a range from `DAY` to the next day.

## 2. Load the tools

One ToolSearch call:

`select:mcp__plugin_slack_slack__slack_search_public_and_private,mcp__plugin_slack_slack__slack_read_thread,mcp__notionApi__notion-search,mcp__notionApi__notion-fetch,mcp__notionApi__notion-query-meeting-notes,mcp__linear__list_issues,mcp__claude_ai_Granola__list_meetings`

If the Slack plugin tools are missing, load the same tools from the `mcp__claude_ai_Slack__` server. If a server is not connected, skip that source and name it in the recap footer.

Run each Bash command on its own, with the literal date and no shell variables.

## 3. Collect the data

Run every source in parallel.

1. **Claude sessions:** `~/.claude/skills/daily-recap/sessions.sh DAY`. It prints one block per session: title, worktree, branch, time span, PR links, and my prompts. The worktree path and branch name the ticket (`eng-<id>`).
2. **Slack, my messages:** `slack_search_public_and_private` with `filters: "from:<@MY_ID> on:DAY"`, `sort: timestamp`, `limit: 20`, `include_context: false`. `MY_ID` is the user ID in the tool description. Follow `cursor` until there are no more pages.
3. **Slack, mentions of me:** the same call with `keywords: ["<@MY_ID>"]` and `filters: "on:DAY"`. Read a thread with `slack_read_thread` only when a message alone does not show the outcome (decision, answer, handoff).
4. **Notion, pages I edited:** `notion-search` with `query: ""`, `filters: {edited_by_user_ids: ["me"], last_edited_date_range: {start_date: DAY, end_date: DAY+1}}`, `sort: last_edited`, `page_size: 25`. If the result says the filters were dropped, retry with `created_by_user_ids` and `created_date_range`, and add one plain search for `DAY` work titles taken from steps 1 and 2.
5. **Notion, meetings:** `notion-query-meeting-notes` for `DAY`. Keep the meetings I attended, with the decisions and my action items.
6. **GitHub:** three Bash calls:
   ```bash
   gh search prs --author @me --closed DAY..NEXT_DAY --json number,title,url,repository,state,closedAt --limit 50
   gh search prs --author @me --created DAY..NEXT_DAY --json number,title,url,state,isDraft,createdAt --limit 50
   gh search prs --reviewed-by @me --updated DAY..NEXT_DAY --json number,title,url,author --limit 50
   ```
   From the first call keep PRs with `state: merged` and `closedAt` on `DAY` in local time (`--merged` returns wrong dates), and a created PR only if `createdAt` is. Drop review results where the author is me.
7. **Meetings with times:** Granola `list_meetings` with `time_range: "custom"`, `custom_start: DAY`, `custom_end: DAY`, `involvement: {captured_by_me: true, listed_as_participant: true}`. Each meeting's `meeting_at` is its start and `updated_at` its end.
8. **Linear:** `list_issues` with `assignee: "me"`, `updatedAt: "DAY"` (updated on or after), `limit: 250`, follow `cursor` until done, fields `title, status, statusType, completedAt, project, url`. Keep tickets with `completedAt` on `DAY`, and tickets whose status changed in item 1 or item 6 work.

Then profile time. Write an events file (TSV, no header, one row per event: `START_ISO<TAB>END_ISO<TAB>SOURCE<TAB>LABEL`):

* each item 2 Slack message: start = sent time, end empty, source `slack`, label `#channel` or `DM <name>`
* each item 7 meeting: start = `meeting_at`, end = `updated_at`, source `meeting`, label = title

Save it as `DIR/raw/timeline-extra.tsv` when archiving, else in the scratchpad. Run `~/.claude/skills/daily-recap/timeline.py DAY <events file>`. It adds Claude prompts, git commits and screen-off periods, and prints a summary (active floor, ceiling, midpoint and unadjusted hours, screen-on time), hours per label, active blocks and every event.

## 4. Merge into accomplishments

* Group by piece of work, not by source. One ticket, PR, doc or incident is one item. Join items by ticket ID, PR number, branch, or a doc link that appears in Slack or a session.
* Write each item as an outcome: "Merged #11380: control plane writes behind the audit log", not "worked on control plane".
* A PR that is only mentioned in a session is not shipped. Use section 3 item 6 for merged, opened and reviewed.
* Leave out sessions that ended with no result (a question with no answer, an aborted try), small talk, bot alerts I did not act on, and subagent or debate sessions. Their parent session's result covers them.
* Put sensitive content (customer data, secrets, HR topics) at title level only.
* Time: map each `timeline.py` label to a work item. A `session: <title>` label or a Slack channel joins the item whose work it covered; the rest is "Slack and on-call" or "Other". Add the hours of merged labels, using the ceiling column. Use only `timeline.py` numbers; never estimate.

## 5. Write the recap

Fit one screen. Terse bullets in `label: value` form, links on IDs. Leave out any empty section.

```
**Recap: <weekday> DAY**

**Time:** 8:57–21:12 · 8.7–10.3h active (mid 9.5h, unadjusted 10.5h) · screen on 11.0h · meetings 0.2h · longest block 5h07
- ENG-12081 dev outage: 1.6h
- Slack and on-call: 2.4h
**Shipped**
- ENG-11860 control plane writes: merged #11380, #11397
**Progressed**
- ENG-11637 control plane auth: opened draft #11401, JWT check left
**Decisions and comms**
- #pod-infra-security: agreed X with <person>
**Docs and meetings**
- Customer environment risks and priorities: added super admin endpoint link
**Helped others**
- Reviewed #11399 (Davis)

Sources: 9 sessions · 24 Slack messages · 3 Notion pages · 2 meetings · 5 PRs · 2 tickets. Skipped: <source> (not connected)
```

End with one line that offers a follow-up: post the recap as a draft standup, or move finished tickets to Done.

## 6. Archive (only with `--archive DIR`)

The run is unattended: ask nothing, offer nothing, skip the follow-up line. Write these files with the Write tool, then stop:

* `DIR/recap.md`: the section 5 recap.
* `DIR/raw/claude-sessions.md`: the full `sessions.sh` output.
* `DIR/raw/slack.md`: every message from section 3 items 2 and 3, and every thread read, in time order. One entry per message: time, channel, author, permalink, and the full text as returned. Do not summarize.
* `DIR/raw/notion.md`: for each page from section 3 item 4, its title, URL and last edit time, then its full content from `notion-fetch`. Then the item 5 meeting notes in full.
* `DIR/raw/github.json`, `DIR/raw/linear.json` and `DIR/raw/meetings.md`: the item 6, 8 and 7 results as returned.
* `DIR/raw/timeline.md`: the full `timeline.py` output.

Save raw results unfiltered: section 4 filtering applies to `recap.md` only. If a source failed, write its file with the error.
