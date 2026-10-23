---
name: url
description: Show the URLs of what I am working on right now: the Linear ticket, its PR, and any local service this conversation is running. Use for /url, "give me the link", or "what's the PR url".
argument-hint: "[ticket-id]"
---

# Show the URLs of my current work

Read-only. Reply with the label line and one line per URL that exists. No preamble.

## 1. Pick the work

Use the first source that gives an item:

1. **Argument** (`ENG-1234`, any case): that ticket.
2. **This conversation:** the ticket or PR this conversation is working on.
3. **My most recently updated open PR:**
   ```bash
   gh pr list --repo valkai-tech/onyx --author @me --state open --limit 1 --json number,title,url
   ```

## 2. Collect the URLs

- **Ticket:** `https://linear.app/valkai/issue/<ID>`.
- **PR:** `gh pr list --repo valkai-tech/onyx --author @me --state all --search "<ID> in:title" --limit 1 --json number,title,url`. Omit the line when there is none.
- **Local service:** a server this conversation started for the work (for example `http://localhost:8795/deployments`). Link the page under test, not the bare port. Confirm it still answers with `curl -s -o /dev/null -w "%{http_code}" <url>`; omit the line when it does not. Say which branch it runs when that differs from the ticket's branch.

## 3. Report

```
ENG-11848 models page effort
ticket: https://linear.app/valkai/issue/ENG-11848
pr: https://github.com/valkai-tech/onyx/pull/11301
local: http://localhost:8795/models
```

The label is the ticket ID and 2–4 lowercase words from the title.
