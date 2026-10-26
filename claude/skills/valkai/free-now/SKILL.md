---
name: free-now
description: Check if a teammate is free to talk right now, from their Google Calendar, Slack status and last Slack message. Use for /free-now <name> or "is X free?".
argument-hint: "<name or email> [more names]"
---

# Free now

Read-only. Never create, edit or answer calendar events, and never send Slack messages.

## 1. Load the tools

One ToolSearch call:

`select:mcp__claude_ai_Google_Calendar__list_events,mcp__plugin_slack_slack__slack_search_users,mcp__plugin_slack_slack__slack_read_user_profile,mcp__plugin_slack_slack__slack_search_public_and_private`

If the Slack plugin tools are missing, load the same tools from `mcp__claude_ai_Slack__`. If a server is not connected, skip its signals and say so in the answer.

## 2. Collect, per person, in parallel

1. **Who:** `slack_search_users` with the name as `keywords`. This gives the Slack user ID and email. If several people match, ask which one.
2. **Calendar:** `list_events` with `calendarId: <email>`, `startTime` = now minus 2 hours, `endTime` = end of today, `orderBy: startTime`, `eventType: ["DEFAULT", "OUT_OF_OFFICE", "FOCUS_TIME"]`. Pass local times with no offset. Drop events where their `responseStatus` is `declined`, and all-day events that are not out of office.
3. **Slack profile:** `slack_read_user_profile` with their user ID and `response_format: detailed` (`concise` leaves out timezone), for status and timezone.
4. **Last Slack message:** `slack_search_public_and_private` with `filters: "from:<@ID>"`, `sort: timestamp`, `limit: 1`, `include_context: false`. Search sees only channels and DMs I am in, so an old result does not mean they are away.

## 3. Decide

* **Busy:** an event, out-of-office or focus-time block covers now, or their Slack status says they are away (meeting, OOO, lunch, commuting, sick).
* **Away:** their local time is outside 9:00–19:00, or it is their weekend.
* **Likely free:** none of the above. Say "free" with more confidence if their last message was under 15 minutes ago, and give how long until their next event.

## 4. Answer

Per person, at most 3 lines. Give times in 12-hour format (`1:45 pm ET`), in my timezone, and add theirs when it differs.

```
**Davis: busy** · Low-level Design interview until 4:45 pm ET (1:45 pm PT)
- next free: 5:15–5:45 pm ET, then "share the offline eval" 5:45 pm
- Slack: no status · last message 12m ago · 11:20 am PT local
```
