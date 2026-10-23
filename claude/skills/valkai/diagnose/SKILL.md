---
name: diagnose
description: Diagnose what caused an alert or incident, while a background watcher logs tool calls and permissions to learn which steps found the cause. Use for /diagnose <alert or link>.
hooks:
  PostToolUse:
    - matcher: "*"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/diagnose/watch.sh"
          async: true
  PostToolUseFailure:
    - matcher: "*"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/diagnose/watch.sh"
          async: true
  PermissionRequest:
    - matcher: "*"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/diagnose/watch.sh"
          async: true
  PermissionDenied:
    - matcher: "*"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/diagnose/watch.sh"
          async: true
---

# Diagnose an alert

Find the root cause of the alert the user names (a Rootly alert ID, a Slack thread link, or a description). Read-only: never mutate a live system; follow the repo's live-system guardrail.

The frontmatter hooks run `watch.sh` asynchronously on every tool and permission event and append to `~/.claude/diagnose/logs/<session_id>.jsonl`. Never read, wait on, or mention these logs during the diagnosis.

## 1. Start

1. Set a run ID and mark the start, in one Bash call:
   ```bash
   echo "diagnose-mark start $(date +%Y%m%d-%H%M%S)"
   ```
   The printed value is `RUN_ID`; keep it for step 6.
2. Read `~/.claude/diagnose/playbook.md` if it exists. If it has a section for this alert family, run its critical path first and skip its listed dead ends.

## 2. Pin down the alert

Get the alert's exact name, environment, severity, and the fire and resolve times in UTC. Read the Slack thread and any bot investigation in it. Note the window: start 30 minutes before the first fire.

## 3. Find what the alert measures

Grep the repo for the check or rule name (health checks, Grafana rules, Azure alert Terraform). State what it measures, its threshold, and where its results and logs go. Use the on-call references in `AGENTS.md` for env names, tenants, and access paths; do not guess them.

## 4. Gather evidence

- Start with the data source that covers the env with the user's current login. Prefer aggregate queries (counts by type per hour) over raw rows.
- Scope it: compare the alert window with a baseline window, and the affected env with sibling envs. A signal that appears only in the window and only in the affected env is the lead.
- Follow the lead to the failing dependency: exception chain, dependency target, latency, error class.
- Run independent queries in parallel.
- Access:
  - Use only the user's own credentials. Never use another person's cached account or token, even when one is logged in.
  - If access is blocked, stop that branch. Say which login or role would unblock it, and continue with other sources.

## 5. Report

Lead with the cause in one sentence and a confidence level (confirmed, likely, unknown). Then:

- **Evidence:** the decisive numbers and links (Sentry issue, query, thread).
- **Scope and impact:** envs, time window, user-facing effect.
- **Status:** recovered or ongoing; whether anyone acted.
- **Needs a fix:** yes or no, what fix, and who likely owns it.
- **Open questions:** what you could not verify and what access would close it.

## 6. Signal trace (background)

After the report, in one response:

1. Mark the end: `echo "diagnose-mark end <RUN_ID>"`, with the literal value.
2. Launch a background `general-purpose` agent with `run_in_background: true`. Prompt: "Follow `~/.claude/skills/diagnose/references/signal-trace.md`." plus `RUN_ID`, the alert, the env, and the step 5 report.

Do not wait for it. When it finishes, give the user its report path in one line.
