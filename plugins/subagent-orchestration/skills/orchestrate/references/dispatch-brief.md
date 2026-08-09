# The Dispatch Brief

A subagent starts cold. It has no session history, has not seen what the user asked for, does not know what the last dispatch found, and cannot ask you a question mid-flight. Every dispatch is a self-contained work order, and the quality of the brief is the single biggest lever on whether a cheap tier succeeds.

Most tier escalations are really brief failures. Before promoting a stalled task to a bigger model, check whether the brief actually contained what the worker needed.

## Template

```
GOAL
One sentence, stated as an outcome. Not "look at the auth middleware" —
"make expired sessions return 401 instead of 500 on the refresh endpoint."

CONTEXT
What you already know that saves the worker a search: the diagnosis a prior
dispatch produced, the decision the user made, the pattern to follow and where
an example of it lives. Keep it to facts the worker will use.

FILES
Every path you already know, with why each matters. If the file set is unknown,
that is a signal you should have dispatched an investigator first.

CONSTRAINTS
What must not change: public signatures, behavior other code depends on,
scope boundaries. Name the project conventions that apply and the CLAUDE.md
or convention skill to load — do not restate them from memory.

DONE WHEN
Verifiable conditions. "The new test in FooTests fails before and passes after,
and `dotnet test` is green."

VERIFY WITH
The exact build and test command for this repo.

REPORT
What you need back: files changed, judgment calls, test output verbatim,
anything left undone.

If anything above is ambiguous or the change turns out to be larger than this
brief describes, stop and report it rather than guessing.
```

Not every dispatch needs all eight sections — a mechanical rename may only need GOAL, FILES, VERIFY WITH, and the stop-and-report line. Drop sections that would be empty; never drop the stop-and-report line.

## Worked example — mechanical

```
GOAL
Rename ICustomerRepo to ICustomerRepository across the solution, including
the implementation, all injection sites, and tests.

FILES
src/Domain/Abstractions/ICustomerRepo.cs   — the interface (rename the file too)
src/Infrastructure/CustomerRepo.cs         — the implementation
Everywhere else: grep for both ICustomerRepo and "CustomerRepo" as a string;
the DI registration in src/Api/Program.cs uses the string form in one place.

CONSTRAINTS
Rename only. Do not reorder members, change signatures, or reformat files.
Leave CustomerRepo (the class) named as it is — interface only.

DONE WHEN
`rg ICustomerRepo` returns no hits, the solution builds, `dotnet test` is green.

VERIFY WITH
dotnet build && dotnet test

REPORT
Files changed with per-file site counts; anything you left alone and why.

If a call site does not match the expected shape, stop and report rather than
adapting it.
```

## Worked example — standard, following a diagnosis

```
GOAL
Fix the 500 on POST /api/orders/{id}/refund when the order has already been
refunded; it must return 409 with the existing ProblemDetails shape.

CONTEXT
Diagnosed by a prior investigation: RefundService.RefundAsync assumes
order.RefundId is null and dereferences it at RefundService.cs:88. The
already-refunded case is never checked. The 409 + ProblemDetails pattern to
follow is in OrderService.CancelAsync (OrderService.cs:140-158).

FILES
src/Application/Services/RefundService.cs   — the fix, around line 88
src/Application/Services/OrderService.cs    — the pattern to mirror, do not edit
tests/Application.Tests/RefundServiceTests.cs — new test goes here

CONSTRAINTS
Do not change the public shape of RefundAsync's success path. Follow the
project's test conventions — load the dotnet-dev:test-conventions skill.

DONE WHEN
A new test covering the already-refunded case fails before the fix and passes
after; the full suite is green.

VERIFY WITH
dotnet test

REPORT
The change, the test you added, test output, and any other call path you found
that makes the same null assumption.

Stop and report if the correct status code is genuinely unclear rather than
picking one.
```

## What makes briefs fail

| Brief says | Worker does |
|---|---|
| "Continue where we left off" | Guesses, or asks a question nobody will answer |
| "Fix the auth bug" | Fixes a different bug it happened to find |
| "Follow our conventions" (unnamed) | Infers style from whichever file it opened first |
| "Make sure it works" | Declares success without running anything |
| "Refactor this while you're in there" | Returns a diff nobody can review |
| No stop-and-report clause | Improvises through the ambiguity, confidently |

## After the report comes back

Compare the report against the brief before doing anything else — specifically the file list and the definition of done. Scope drift in either direction is the finding: work that was asked for and is missing, and work that appeared and was not asked for.

Then verify rather than trust: run the build and test command yourself, and `git diff --stat` to confirm the changeset matches the files the brief named. If the report claims a green suite and the suite is red, that is the whole result — re-dispatch or escalate, and do not carry the claim forward into a commit message.
