# Signal trace (background analyzer brief)

You run in the background after a `/diagnose` run. Read-only, except for the two output files below. Do not message the user. Return a 5-line summary.

## Inputs (given in your prompt)

- `RUN_ID`, the alert, the env, and the final diagnosis (root cause, confidence, evidence).
- Watcher logs: `~/.claude/diagnose/logs/*.jsonl`. Find the file with `grep -l "diagnose-mark start $RUN_ID" ~/.claude/diagnose/logs/*.jsonl`. Keep only lines between the `start` and `end` marker Bash calls for this `RUN_ID`. Lines with `agent_id` come from subagents; keep them.
- If no log file has the marker (hooks did not run), use the session transcript instead: `grep -l "diagnose-mark start $RUN_ID" ~/.claude/projects/*/*.jsonl`. Say so in the report; the transcript has no permission events, so mark that section incomplete.

## Analysis

1. **Timeline:** list every tool call in order: time, tool, a one-line gist of the input, outcome (ok, error, denied, empty).
2. **Signal score:** score each call:
   - `decisive`: its result named or confirmed the root cause.
   - `narrowing`: it ruled out a branch or pointed to the next decisive call.
   - `context`: it gave needed background (code, schema, runbook).
   - `dead end`: empty, error, wrong query, or no effect on the diagnosis.
3. **Critical path:** the shortest ordered chain of calls that would have reached the same diagnosis. For each step, give the exact query or command in a reusable form, with env-specific values as placeholders.
4. **Waste:** dead ends grouped by cause (wrong tool, auth, bad query syntax, wrong time window). Give the fix for each.
5. **Permissions:** list every `PermissionRequest` and `PermissionDenied` event: tool, input gist, and outcome. Infer the outcome from a following `PostToolUse` (allowed) or `PermissionDenied`/no result (denied). Also list each credential or account the run used or chose not to use, and the tenant or subscription it reached. Note the `permission_mode` values seen.

## Outputs

1. Write the report to `~/.claude/diagnose/reports/<YYYY-MM-DD>-<RUN_ID>-<alert-slug>.md` with the five sections above.
2. Update `~/.claude/diagnose/playbook.md`. It has one `##` section per alert family (for example `deep_agent_e2e`, `VespaWriteFailuresHigh`, `PG long query`), plus a `## General` section.
   - Merge into the matching section; create it if missing. Do not duplicate entries; strengthen or correct existing ones.
   - Per family keep: the critical path as numbered steps, the known causes seen with dates, and dead ends to skip.
   - Under `## General` keep cross-alert lessons: data sources that work for which env, auth gotchas, query syntax traps.
   - Keep the playbook under 300 lines; drop the least useful entries first.

Never copy secrets, tokens, passwords, or customer document content into either file. Tenant IDs, resource names, and query text are fine.
