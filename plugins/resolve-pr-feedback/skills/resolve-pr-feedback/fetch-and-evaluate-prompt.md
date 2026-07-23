# Fetch and Evaluate PR Comments — Subagent Prompt Template

Use this template when dispatching the fetch-and-evaluate subagent in Step 2.

## How to Dispatch

```
Agent tool:
  subagent_type: resolve-pr-feedback:pr-feedback-evaluator
  description: "Fetch and evaluate PR #{PR_NUMBER} comments"
  prompt: [fill template below with actual values]
```

`resolve-pr-feedback:pr-feedback-evaluator` is a custom subagent (`agents/pr-feedback-evaluator.md`, bundled with this plugin) pinned to `model: sonnet` and `effort: high` in its frontmatter — that's where the model/effort are actually enforced, not on this dispatch call. Plugin-provided subagents are namespaced as `<plugin-name>:<agent-name>` — verified with a local `--plugin-dir` load with no home-directory copy present.

## Prompt Template

---
You are evaluating PR review comments for technical correctness. Do NOT implement any changes.

**PR Details**
- Owner: {OWNER}
- Repo: {REPO}
- PR Number: {PR_NUMBER}
- Selective mode (if set): evaluate only comment IDs: {COMMENT_IDS or "all"}

**Your Job**

1. **Fetch comments** using `mcp__plugin_github_github__pull_request_read`:
   - Call with `method: "get_review_comments"` for inline code comments
   - Call with `method: "get_comments"` for general PR comments
   - Filter to unresolved threads only. Note any marked `isOutdated: true`.

2. **For each unresolved comment:**
   a. Read the referenced file and surrounding context
   b. Verify against the actual codebase:
      - Is this technically correct for THIS codebase?
      - Does the current code actually have the problem described?
      - Would implementing it break existing functionality?
      - Is there a reason the code is written the current way?
      - Is this YAGNI? (grep for actual usage before accepting "add X" suggestions)
      - Does the reviewer have full context, or are they missing something?
   c. Assign verdict:
      - **ACCEPT** — technically sound, should implement
      - **PARTLY_ACCEPT** — partially correct; specify accepted_part and rejected_part
      - **PUSHBACK** — technically incorrect, breaks things, YAGNI, or reviewer lacks context
      - **OUTDATED** — code has changed since this comment was written (`isOutdated: true` or verified by inspection)

3. **Group related comments** (same file/area, or same theme across files)

4. **Detect conflicts** — different reviewers making contradictory suggestions on the same code

5. **Return structured report:**

```
GROUPS:
- group_name: "[descriptive name] ([file or area])"
  comments:
    - id: [comment_id]
      reviewer: [login]
      file: [path]
      line: [line number, if inline]
      summary: [1-sentence summary of what reviewer is asking]
      verdict: ACCEPT | PARTLY_ACCEPT | PUSHBACK | OUTDATED
      reasoning: [1-2 sentences of technical justification, cite file:line or grep results]
      accepted_part: [PARTLY_ACCEPT only]
      rejected_part: [PARTLY_ACCEPT only]

CONFLICTS:
- comment_ids: [id1, id2]
  description: [what contradicts what]

SUMMARY:
  accept_count: N
  partly_accept_count: N
  pushback_count: N
  outdated_count: N
  conflict_count: N
```

**Critical Rules**
- VERIFY before categorizing. Read the actual code.
- If the code described in the comment doesn't match what's in the file, say so in reasoning.
- YAGNI check: grep for usage before accepting suggestions to add new abstractions or features.
- Be specific — reference file:line, grep result counts, interface names.
- If you can't verify something, say so explicitly rather than guessing.
- Do NOT implement anything. Return the report only.
---