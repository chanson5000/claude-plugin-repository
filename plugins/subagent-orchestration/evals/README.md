# subagent-orchestration evals

A `claude plugin eval` suite that compares plain Opus against Opus with this plugin loaded, on four small coding tasks. It asks two questions: does the plugin keep (or improve) task success, and what does it do to cost?

Each case scaffolds a self-contained Python 3 project (standard library and `unittest` only, no network) with `--scaffold`:

| Case | Task | Triage row | Expected routing |
|---|---|---|---|
| `mechanical-rename` | Rename `calc_total` to `compute_total` across 5 modules, tests, and a `getattr` string reference | decided, cheap to be wrong | haiku |
| `feature-following-pattern` | Add a `reverse` handler to a command registry, with tests | clear intent, existing pattern | sonnet or opus |
| `bug-unknown-cause` | Report test fails; real cause is an off-by-one in a pagination helper | undecided, investigate first | sonnet or opus |
| `trivial-fix` | One-word typo in an error message | trivial (control) | plugin expected not to help |

Graders:

- **Scored in both arms:** regex checks on the final file contents (`{source: file, path: ...}`), such as no `calc_total` left, the handler registered and imported, the off-by-one fixed in `reports/pagination.py` and not patched in `reports/sales.py`. Plus one `llm` grader per case that reads the trace and requires a visible final passing `unittest` run and a minimal, correct change.
- **Routing indicators (`arm: with-only`, not scored):** `tool_used` on `Agent` with `input_match` on the dispatched `model` (`"model"\s*:\s*"haiku"`, or `sonnet|opus`). They show whether the orchestrator picked the expected tier. They carry no score, so a failing indicator does not lower `WITH`. On `trivial-fix` a failing indicator is fine: doing a one-line fix directly is correct.

## Run it

From the plugin root:

```bash
cd plugins/subagent-orchestration
claude plugin eval . \
  --model opus \
  --scaffold \
  --allow-tools Write Edit "Bash(python3 -m unittest *)" \
  --max-cost-usd 40 \
  --json evals/results/latest.json \
  --no-publish
```

- `--model opus` pins the agent under test to Opus in both arms. Use a full model ID if you need an exact version. No case hardcodes a model.
- `--scaffold` is required: without it the workspaces are empty and every case fails. It runs the `fixture.sh` scripts in this directory as you, so read them first.
- `--allow-tools` is required: `Write`, `Edit` and `Bash` are not granted by a case's `allowed_tools`. Bash is limited to the unittest command and runs under the OS sandbox (Linux needs `bubblewrap` and `socat`).
- Add `--judge-model sonnet` if the haiku judge is noisy on the `llm` graders.
- Add `--runs 1 --ablation none --case <name>` to iterate on a single case cheaply.

## Cost

4 cases x 3 runs x 2 arms = **24 agent runs**, each up to 60 turns / 1200 s, plus 3 short judge calls for each of the 24 runs' `llm` grader (72 judge calls). The with-plugin arm spawns subagents, so its runs cost more than their turn count suggests. `--max-cost-usd` stops launching runs once the list-price estimate passes the ceiling (exit 2, partial results; started runs finish, so spend can overshoot). Tune the ceiling to your budget; 40 USD is a guess, not a measurement.

## Reading the result

```text
CASE  WITH  W/OUT  Δ  RUNS  COST  NOTES
```

- `WITH` / `W/OUT`: mean fraction of scored graders passed with and without the plugin. `Δ = WITH - W/OUT`. Near zero on a case both arms pass is the expected outcome: the plugin kept success. Negative means the orchestrated arm did worse (see `NOTES` and the report for the failing grader).
- `COST`: list-price estimate for the case's runs, both arms and judge calls together. Compare it with `Δ`: a flat `Δ` at lower cost, or a higher `Δ` at similar cost, favors the plugin. A flat `Δ` at higher cost does not.
- Routing indicators appear in the report as plugin-fired badges, not in `WITH`.
- With 3 runs per arm, one flaky run moves a case by 0.17 or more. Treat differences under about that size as noise.

## Known gaps

- **Cost is one total per case,** not split by model or by arm. You cannot see directly that the plugin shifted tokens from Opus to Haiku or Sonnet. Compare totals, or inspect `aggregate-result.json`.
- **Subagent tool calls may not appear in the trace.** This is undocumented. If they do not, the `llm` graders see only the orchestrator's own `Bash` runs, so the prompts ask for a visible `python3 -m unittest` run and the plugin's doctrine ("run them yourself") is what satisfies it. Whether the `--allow-tools` Bash grant reaches subagents is also undocumented; if implementers cannot run Bash, they should report back and the orchestrator should run the tests.
- **Effort cannot be pinned or observed.** The routing indicators check `model` only; `effort` is not graded (it may not be in the trace).
- **Short tasks favor the no-plugin arm.** `trivial-fix` is the honest control: delegation adds turns and tokens to a one-word change, so expect a flat or negative `Δ` and higher `COST` there. The same overhead likely shows on the other small projects. These tasks are small by design, so they underestimate the plugin's benefit on long sessions where context size matters.
- **File graders read final state only** and cannot run the code. Correctness beyond the regexes rests on the `llm` grader, which sees only the first 12 and last 12 trace messages.
- The plugin also ships older tier-named agents (`implement-mechanical`, `investigate-deep`, and so on). The routing indicators match any Agent dispatch with the right `model`, not a specific agent name.
- The baseline arm cannot dispatch the plugin's agents (`Agent type ... not found`) and will use built-in agents or work directly. That is the intended baseline.
