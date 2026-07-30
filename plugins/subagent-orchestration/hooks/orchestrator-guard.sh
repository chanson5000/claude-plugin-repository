#!/bin/sh
# subagent-orchestration — strict-mode guard.
#
# Two jobs, selected by $1:
#   session-start   Print a short orchestrator-mode reminder. SessionStart stdout
#                   is added to the session's context.
#   pre-tool-use    On a main-session Edit/Write/NotebookEdit, return an "ask"
#                   permission decision naming the tier to dispatch instead.
#                   Tool calls made *inside* a subagent pass through untouched —
#                   the workers are the ones supposed to be editing.
#
# Inert unless SUBAGENT_ORCHESTRATION_STRICT is set to 1/true/on, so installing the
# plugin never changes behavior on its own. Set it in settings.json's "env" block
# or the shell environment; see this plugin's README.
#
# Always exits 0. A hook failure must never block session startup or a tool call.

set -u

mode="${1:-}"

case "${SUBAGENT_ORCHESTRATION_STRICT:-}" in
  1 | true | on | yes) ;;
  *) exit 0 ;;
esac

case "$mode" in
  session-start)
    cat <<'EOF'
Orchestrator mode is active (subagent-orchestration, strict). Triage and dispatch;
do not read broadly or edit files in this session. Load the `orchestrate` skill for
the triage rubric and dispatch-brief contract. Lanes: plan-standard, investigate-standard,
investigate-deep, implement-mechanical, implement-standard, implement-complex, review-critical.
Main-session edits will prompt for confirmation.
EOF
    ;;

  pre-tool-use)
    # `agent_id` is present in the hook payload only for tool calls made inside a
    # subagent, and absent entirely in the main session. That is the whole gate:
    # without it, this hook would also block the workers doing the actual work.
    if grep -q '"agent_id"[[:space:]]*:[[:space:]]*"' 2>/dev/null; then
      exit 0
    fi

    cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Orchestrator mode: the main session's edit budget is zero. Dispatch subagent-orchestration:implement-mechanical for a fully decided change, implement-standard for ordinary work, or implement-complex when it is consequence-heavy or unsettled. Approve to edit here anyway."}}
EOF
    ;;
esac

exit 0
