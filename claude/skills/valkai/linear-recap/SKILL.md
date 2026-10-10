---
name: linear-recap
description: Recap what is going on in Valkai's Linear in one screen — what needs attention, my active tickets, the busiest projects, and cleanup to do. Use for /linear-recap, "what's going on in linear", or "catch me up on linear".
argument-hint: "[days] [mine | projects | hygiene]"
---

# Recap Linear

Read-only. Do not change any issue, project or comment. Offer changes at the end; make them only after the user says yes.

## 1. Read the arguments

* **Days:** a number sets the window. The default is 7. Use it as an ISO-8601 duration (`-P7D`).
* **Section:** `mine`, `projects` or `hygiene` gives the full detail for that one section (step 5). With no section, give the one-screen summary (step 4).

## 2. Load the tools

One ToolSearch call:

`select:mcp__linear__list_issues,mcp__linear__list_projects,mcp__linear__get_notifications,mcp__linear__get_issue`

If the Linear MCP server is not connected, tell the user and stop.

## 3. Collect the data

Run these calls in parallel:

1. **My tickets:** `list_issues` with `assignee: "me"`, `limit: 250`, fields `title, status, statusType, priority, project, parentId, dueDate, updatedAt, completedAt, url`. This one call gives both open tickets and tickets closed in the window (`completedAt` inside the window).
2. **Inbox:** `get_notifications` with `unreadOnly: true`, `limit: 50`.
3. **Projects:** `list_projects` with `state: "started"`, `limit: 50`, fields `name, lead, targetDate, url`.
4. **Team activity:** `list_issues` with `team: "Engineering"`, `updatedAt: -P<days>D`, `limit: 250`, fields `project, statusType`. If the result has `hasNextPage: true`, call again with `cursor` until it is false. Count issues per project.

Then, for each of my tickets completed in the window, call `get_issue` in parallel and read `stateHistory`. Flag a ticket if a Canceled or Duplicate state came before Done. This happens when a PR that names a canceled ticket merges.

### Rules for the data

* A project's `updatedAt` does not change when its issues move. Judge project activity only from the team activity counts.
* A project is **stale** if it is In Progress and has no issue in the team activity.
* A project is **overdue** if its target date has passed.

## 4. One-screen summary (default)

The whole reply must fit on one screen: about 20 lines, with no tables. Link each ticket ID. Leave out a line that has nothing to show. Use this shape:

```
**Linear: last 7 days**

**Attention**
- <unread notifications, due-soon or past-due tickets, tickets moved from Canceled to Done; max 3 lines, else "Nothing">

**Mine:** 7 in progress · 5 todo · 20 backlog · 20 closed this week
- ENG-1 <short title> (In Review)
- … in-progress tickets only, max 6; group sub-issues as "ENG-11105 + 4 sub-issues"

**Team:** busiest projects this week
- <project> (<issue count>) <lead>, **overdue** if so
- … top 5 only

**Cleanup:** <n> tickets with no project · <n> possible duplicates · <n> stale projects

More: `/linear-recap mine` · `projects` · `hygiene`
```

## 5. Section detail (when a section is given)

Keep each to one screen when possible.

* **mine:** open tickets by status (In Progress, Todo, Backlog), sub-issues under their parent, then the IDs closed in the window.
* **projects:** every project with activity, sorted by issue count, with lead, target date and overdue mark. Then upcoming target dates in the next 14 days.
* **hygiene:**
  * My open tickets with no project, where the parent has none either.
  * Possible duplicates among my open tickets (same or nearly the same title).
  * Stale and overdue projects.
  * Tickets moved from Canceled or Duplicate to Done.

  End with one line that offers the fixes, for example closing duplicates or moving tickets into a project.
