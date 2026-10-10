---
name: linear-recap
description: Recap what is going on in Valkai's Linear — my open tickets, inbox, active projects, and anything that needs attention. Use for /linear-recap, "what's going on in linear", or "catch me up on linear".
argument-hint: "[days, default 7]"
---

# Recap Linear

Read-only. Do not change any issue, project or comment. Offer changes at the end; make them only after the user says yes.

## 1. Load the tools

Load the Linear tools in one ToolSearch call:

`select:mcp__linear__list_issues,mcp__linear__list_projects,mcp__linear__get_notifications`

If the Linear MCP server is not connected, tell the user and stop.

## 2. Set the window

The window is the argument in days, or 7. Use it as an ISO-8601 duration (`-P7D`) for the `updatedAt` filters below.

## 3. Collect the data

Run these calls in parallel:

1. **My open tickets:** `list_issues` with `assignee: "me"`, `limit: 250`, fields `title, status, statusType, priority, project, parentId, dueDate, updatedAt, url`. Drop `completed`, `canceled` and `duplicate` statuses.
2. **My recently closed tickets:** the same call with `updatedAt: -P<days>D`. Keep only `completed`.
3. **Inbox:** `get_notifications` with `unreadOnly: true`, `limit: 50`.
4. **Active projects:** `list_projects` with `state: "started"`, `limit: 50`, fields `name, lead, targetDate, updatedAt, initiatives, url`.
5. **Team activity:** `list_issues` with `team: "Engineering"`, `updatedAt: -P<days>D`, `limit: 250`, fields `project, statusType, assignee`. Count issues per project to find which projects are active.

## 4. Write the recap

Keep it short. Use bullets and `label: value` lines, and link each ticket ID. Use these sections, and leave out any section that is empty:

1. **Needs attention**
   * Unread notifications, one line each.
   * My tickets that are past due, or due in the next 7 days.
   * My tickets that are In Progress but have had no update for more than 5 days.
2. **My tickets**
   * In Progress, then Todo, then Backlog. Show the count for each.
   * Put sub-issues under their parent. If there are more than 8 Backlog tickets, give the count and the 5 most recently updated.
   * Closed in the window: one line with the ticket IDs.
3. **Active projects**
   * Projects with issues updated in the window, sorted by that count. Give the lead and the target date for each.
   * Mark a project **overdue** if its target date has passed.
4. **Hygiene**
   * My open tickets with no project, and none on their parent either.
   * Possible duplicates among my open tickets (same or nearly the same title).
   * Projects that are In Progress but have no update in 30 days.

End with one line that offers the changes the hygiene section suggests, for example closing duplicates or moving tickets into a project.
