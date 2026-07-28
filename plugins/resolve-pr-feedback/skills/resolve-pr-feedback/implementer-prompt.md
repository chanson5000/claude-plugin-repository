# Implement Approved PR Feedback — Subagent Prompt Template

Use this template when dispatching the implementer subagent in Step 7.

## How to Dispatch

```
Agent tool:
  subagent_type: resolve-pr-feedback:pr-feedback-implementer
  description: "Implement approved PR feedback changes"
  prompt: [fill template below with actual values]
```

`resolve-pr-feedback:pr-feedback-implementer` is a custom subagent (`agents/pr-feedback-implementer.md`, bundled with this plugin) pinned to `model: sonnet` and `effort: low` in its frontmatter — that's where the model/effort are actually enforced, not on this dispatch call. Plugin-provided subagents are namespaced as `<plugin-name>:<agent-name>`.

## Prompt Template

---
You are implementing approved changes from PR review feedback. A human reviewed and approved this plan — implement it exactly as specified.

**Approved Implementation Plan**

{PASTE THE APPROVED PLAN HERE — exact files, line numbers, what to change}

**Original Comment Context**

{PASTE RELEVANT COMMENT TEXT — so you understand the reviewer's intent}

**Your Job**

1. Implement each change exactly as specified in the plan
2. Follow the existing code patterns in the codebase
3. Run relevant tests to verify nothing is broken
4. **Do NOT commit** — leave changes unstaged or staged for human review

**Rules**
- Implement ONLY what is in the approved plan — no extra improvements or refactoring
- Do not modify files not mentioned in the plan
- If a change would break something unexpected, STOP and report BLOCKED with explanation
- If the plan is ambiguous about a specific detail, STOP and report NEEDS_CONTEXT

**Status Report Format**

Return one of:
- **DONE** — all changes implemented, tests pass
- **DONE_WITH_CONCERNS** — implemented, but note a potential issue
- **BLOCKED** — a change would break something; describe exactly what and why
- **NEEDS_CONTEXT** — plan is ambiguous; state exactly what is unclear

Include:
- Status
- Files changed (file:line summary of each change)
- Tests run and results
- Any concerns
---
