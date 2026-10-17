#!/bin/sh
# subagent-orchestration — orchestrator guard.
#
# ACTIVE BY DEFAULT. Enabling the plugin is the consent: orchestrator mode is the
# behavior you asked for by installing it, not a flag you then have to remember.
# It never takes a tool away from the main session: delegation is a strong
# default the orchestrator applies with judgment, not a rule enforced here.
#
# Two jobs, selected by $1:
#   session-start   Print the orchestrator doctrine. SessionStart stdout is added
#                   to the session's context, so the essentials hold whether or
#                   not the `orchestrate` skill gets loaded.
#   pre-dispatch    On an Agent or Workflow call that asks for `xhigh` or `max`
#                   effort, deny it. Subagent effort tops out at high: past that,
#                   a bigger model is the better lever. Applies wherever the
#                   call comes from, including a nested dispatch.
#
# SUBAGENT_ORCHESTRATION=off (or 0, false, no) makes it fully inert: nothing is
# injected and no dispatch is denied.
#
# Always exits 0. A hook failure must never block session startup or a tool call.

set -u

mode="${1:-}"

case "${SUBAGENT_ORCHESTRATION:-on}" in
  off | 0 | false | no) exit 0 ;;
esac

case "$mode" in
  session-start)
    cat <<'EOF'
=== Orchestrator mode is active (subagent-orchestration) ===
This session is a control plane by default. Delegate reading, searching, and
writing to subagents so this context holds decisions and short reports, and so
each piece of work runs on the model it needs. Doing work here directly is your
call when delegating would plainly cost more — but broad reads and searches
belong in a subagent. Load the `orchestrate` skill for the full model/effort
table, escalation protocol, and dispatch-brief contract.

Dispatch as subagent-orchestration:<name>, and pass `model` and `effort` every time:
  planner       sequence multi-step work into dispatch briefs
  investigator  how/why code behaves, scope a change, root-cause diagnosis
  implementer   any decided change; state MODE mechanical|standard|complex
  reviewer      a changeset you are about to accept
  Explore       built-in; plain "where is X" lookups, always with model haiku

Default haiku/low for mechanical work, sonnet/medium for ordinary work, opus/high
for consequence-heavy or stalled work. Effort is low, medium, or high — never
xhigh or max (the guard denies them). Never use fork; don't pass `name`.

Tier on two questions: is the work decided, or does it still have to be figured
out? And what does being wrong cost? Continue a worker with SendMessage for a small
gap; go up a model for a wall. Workers never commit — they report, you review.
EOF
    ;;

  pre-dispatch)
    input=$(cat 2>/dev/null || true)

    # Agent: a top-level "effort":"xhigh"/"max" key in tool_input. Quotes inside
    # the prompt text are JSON-escaped, so a brief that mentions effort can't
    # match. Workflow: the script is one JSON string, so look for
    # effort: 'max' or effort: \"max\" (and xhigh) inside it.
    if printf '%s' "$input" | grep -Eq '"effort"[[:space:]]*:[[:space:]]*"(xhigh|max)"' ||
       printf '%s' "$input" | grep -Eq "effort[[:space:]]*:[[:space:]]*(\\\\\"|')(xhigh|max)(\\\\\"|')"; then
      # JSON-escape the reason before interpolating it: an edit introducing a
      # quote or backslash would otherwise emit invalid JSON, and an unparseable
      # decision is ignored silently.
      reason=$(
        printf '%s' "Orchestrator mode: subagent effort tops out at high. Use low, medium, or high. If a dispatch stalled, raise the model instead; if opus/high stalled, fix the brief, investigate, or take the decision to the user." |
          sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
      )
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
    fi
    ;;
esac

exit 0
