#!/bin/sh
# subagent-orchestration — orchestrator guard.
#
# ACTIVE BY DEFAULT. Enabling the plugin is the consent: orchestrator mode is the
# behavior you asked for by installing it, not a flag you then have to remember.
#
# Two jobs, selected by $1:
#   session-start   Print the orchestrator doctrine. SessionStart stdout is added
#                   to the session's context, so the essentials hold whether or
#                   not the `orchestrate` skill gets loaded.
#   pre-tool-use    On a main-session Edit/Write/NotebookEdit, deny the call and
#                   tell Claude which tier to dispatch instead. Tool calls made
#                   *inside* a subagent pass through untouched — the workers are
#                   the ones supposed to be editing.
#
# Tuning, via SUBAGENT_ORCHESTRATION_STRICT:
#   unset / on / 1   deny main-session edits, so Claude re-routes to a worker
#                    without interrupting the user. The default.
#   ask              prompt the user instead of denying; approving edits in place.
#   off / 0          fully inert. Nothing is injected, nothing is blocked.
#
# Always exits 0. A hook failure must never block session startup or a tool call.

set -u

mode="${1:-}"
setting="${SUBAGENT_ORCHESTRATION_STRICT:-on}"

case "$setting" in
  off | 0 | false | no) exit 0 ;;
esac

case "$mode" in
  session-start)
    cat <<'EOF'
=== Orchestrator mode is active (subagent-orchestration) ===
This session is a control plane. Triage and dispatch; do not read broadly or edit
files here. Editing tools are blocked in the main session by design — that is not a
malfunction, it is the routing signal. Load the `orchestrate` skill for the full
triage rubric, escalation protocol, and dispatch-brief contract.

Dispatch as subagent-orchestration:<name>
  plan-standard         sonnet/medium  sequence multi-step work into tier-scoped briefs
  investigate-standard  sonnet/medium  how/why code behaves; scope a change
  investigate-deep      opus/high      diagnosis a cheaper pass could not settle
  implement-mechanical  haiku/low      fully decided changes, no judgment left
  implement-standard    sonnet/medium  ordinary work with a pattern to follow
  implement-complex     opus/high      consequence-heavy or unsettled work
  review-critical       opus/high      a changeset you are about to commit
Prefer plan-standard over the built-in Plan, and pass model:haiku to Explore —
both built-ins inherit the session model and otherwise escape the ladder.

Tier on two questions: is the work decided, or does it still have to be figured out?
And what does being wrong cost? Escalate on consequence; never re-dispatch the same
tier on the same failure. Workers never commit — they report, you review the diff.
EOF
    ;;

  pre-tool-use)
    input=$(cat 2>/dev/null || true)

    # `agent_id` is present in the payload only for tool calls made inside a
    # subagent, and absent entirely in the main session. That is the whole gate:
    # without it this would also block the workers doing the actual work.
    case "$input" in
      *'"agent_id"'*) exit 0 ;;
    esac

    # Scratch space is not project code. Let the orchestrator keep notes.
    path=$(printf '%s' "$input" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p')
    case "$path" in
      /tmp/* | /var/folders/*) exit 0 ;;
    esac

    reason="Orchestrator mode: the main session does not edit files. Dispatch subagent-orchestration:implement-mechanical for a fully decided change, implement-standard for ordinary work with a pattern to follow, or implement-complex when it is consequence-heavy or unsettled. Give the worker the full brief — it has none of this session's context. To edit here anyway, the user can set SUBAGENT_ORCHESTRATION_STRICT=off."

    case "$setting" in
      ask) decision="ask" ;;
      *) decision="deny" ;;
    esac

    # JSON-escape the reason before interpolating it. The string above is a
    # literal that needs none of this today, but an edit introducing a quote or
    # a backslash would emit invalid JSON — and an unparseable decision is
    # ignored, so the guard would silently stop enforcing with no signal at all.
    # Escapes backslashes and double quotes, and folds embedded newlines to \n.
    reason=$(
      printf '%s' "$reason" |
        sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
        awk '{ if (NR > 1) printf "\\n"; printf "%s", $0 }'
    )

    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' \
      "$decision" "$reason"
    ;;
esac

exit 0
