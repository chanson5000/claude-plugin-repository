#!/bin/sh
# subagent-orchestration — orchestrator guard.
#
# ACTIVE BY DEFAULT. Enabling the plugin is the consent: orchestrator mode is the
# behavior you asked for by installing it, not a flag you then have to remember.
#
# Three jobs, selected by $1:
#   session-start   Print the orchestrator doctrine. SessionStart stdout is added
#                   to the session's context, so the essentials hold whether or
#                   not the `orchestrate` skill gets loaded.
#   pre-tool-use    On a main-session Edit/Write/NotebookEdit, deny the call and
#                   tell Claude to dispatch the implementer instead. Tool calls
#                   made *inside* a subagent pass through untouched — the workers
#                   are the ones supposed to be editing.
#   pre-dispatch    On an Agent or Workflow call that asks for `xhigh` or `max`
#                   effort, deny it. Subagent effort tops out at high: past that,
#                   a bigger model is the better lever. Applies wherever the
#                   call comes from, including a nested dispatch.
#
# Tuning, via SUBAGENT_ORCHESTRATION_STRICT:
#   unset / on / 1   deny main-session edits, so Claude re-routes to a worker
#                    without interrupting the user. The default.
#   ask              prompt the user instead of denying edits. xhigh/max are
#                    still denied.
#   off / 0          fully inert. Nothing is injected, nothing is blocked.
#
# Always exits 0. A hook failure must never block session startup or a tool call.

set -u

mode="${1:-}"
setting="${SUBAGENT_ORCHESTRATION_STRICT:-on}"

case "$setting" in
  off | 0 | false | no) exit 0 ;;
esac

# Print a PreToolUse decision. JSON-escape the reason before interpolating it:
# the strings below need none of this today, but an edit introducing a quote or
# a backslash would emit invalid JSON — and an unparseable decision is ignored,
# so the guard would silently stop enforcing with no signal at all.
# Escapes backslashes and double quotes, and folds embedded newlines to \n.
decide() {
  reason=$(
    printf '%s' "$2" |
      sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
      awk '{ if (NR > 1) printf "\\n"; printf "%s", $0 }'
  )
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' \
    "$1" "$reason"
}

case "$mode" in
  session-start)
    cat <<'EOF'
=== Orchestrator mode is active (subagent-orchestration) ===
This session is a control plane. Triage and dispatch; do not read broadly or edit
files here. Editing tools are blocked in the main session by design — that is the
routing signal, not a malfunction. Load the `orchestrate` skill for the full
model/effort table, escalation protocol, and dispatch-brief contract.

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

  pre-tool-use)
    input=$(cat 2>/dev/null || true)

    # `agent_id` is a top-level key only for tool calls made inside a subagent.
    # Match the key itself, followed by a colon: a bare "agent_id" inside file
    # content is JSON-escaped (\"agent_id\") or unquoted, so it can't match.
    if printf '%s' "$input" | grep -q '"agent_id"[[:space:]]*:'; then
      exit 0
    fi

    # Scratch space is not project code. Let the orchestrator keep notes —
    # but not via a `..` that walks back out of it.
    path=$(printf '%s' "$input" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p')
    case "$path" in
      *..*) ;;
      /tmp/* | /var/folders/*) exit 0 ;;
    esac

    case "$setting" in
      ask) decision="ask" ;;
      *) decision="deny" ;;
    esac

    decide "$decision" "Orchestrator mode: the main session does not edit files. Dispatch subagent-orchestration:implementer with model and effort chosen for the work — MODE mechanical at haiku/low for a fully decided change, standard at sonnet/medium for ordinary work, complex at opus/high when it is consequence-heavy or unsettled. Give it the full brief; it has none of this session's context. To edit here anyway, the user can set SUBAGENT_ORCHESTRATION_STRICT=ask or off."
    ;;

  pre-dispatch)
    input=$(cat 2>/dev/null || true)

    # Agent: a top-level "effort":"xhigh"/"max" key in tool_input. Quotes inside
    # the prompt text are JSON-escaped, so a brief that mentions effort can't
    # match. Workflow: the script is one JSON string, so look for
    # effort: 'max' or effort: \"max\" (and xhigh) inside it.
    if printf '%s' "$input" | grep -Eq '"effort"[[:space:]]*:[[:space:]]*"(xhigh|max)"' ||
       printf '%s' "$input" | grep -Eq "effort[[:space:]]*:[[:space:]]*(\\\\\"|')(xhigh|max)(\\\\\"|')"; then
      decide deny "Orchestrator mode: subagent effort tops out at high. Use low, medium, or high. If a dispatch stalled, raise the model instead; if opus/high stalled, fix the brief, investigate, or take the decision to the user."
    fi
    ;;
esac

exit 0
