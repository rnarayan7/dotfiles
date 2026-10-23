#!/usr/bin/env bash
# Async hook for /diagnose: appends one JSONL line per tool or permission event.
# Prints nothing, so it never changes the main thread's behaviour.
set -euo pipefail

LOG_DIR="${HOME}/.claude/diagnose/logs"
MAX_INPUT_CHARS=1500
MAX_RESULT_CHARS=2000

mkdir -p "$LOG_DIR"
payload="$(cat)"
session_id="$(jq -r '.session_id // "unknown"' <<<"$payload")"

jq -c \
  --argjson max_in "$MAX_INPUT_CHARS" \
  --argjson max_out "$MAX_RESULT_CHARS" \
  'def clip($n): if . == null then null
                 else (if type == "string" then . else tojson end) | .[0:$n] end;
   {
     ts: (now | todate),
     event: .hook_event_name,
     tool: .tool_name,
     tool_use_id: .tool_use_id,
     agent_id: .agent_id,
     agent_type: .agent_type,
     permission_mode: .permission_mode,
     transcript: .transcript_path,
     input: (.tool_input | clip($max_in)),
     result: (.tool_response | clip($max_out)),
     error: .error,
     is_interrupt: .is_interrupt,
     reason: .reason,
     permission_suggestions: (.permission_suggestions | clip($max_in)),
     duration_ms: .duration_ms
   } | with_entries(select(.value != null))' \
  <<<"$payload" >>"${LOG_DIR}/${session_id}.jsonl"
