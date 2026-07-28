---
name: api-conventions
description: Use when writing or modifying ASP.NET Core API endpoints, controllers, or the service layer behind them — covers error shape, where validation belongs, authorization attributes, and pagination. Load before adding an endpoint, not after. For auditing an existing endpoint's error handling, use pr-review-toolkit:silent-failure-hunter instead.
---

# ASP.NET Core API Conventions

House rules for endpoints in this codebase. Standard REST semantics — plural resource nouns, verb-to-status-code mapping, `/api/users/{id}` shapes, `?page=&pageSize=` filtering — are assumed and not restated here.

## Controllers stay thin

A controller action does four things and nothing else: bind, authorize, delegate to a service, map the result to a status code. Business logic in a controller is the single most common defect in this layer.

* Return `ActionResult<T>` so the type is visible to clients and to OpenAPI generation.
* `async`/`await` for every I/O path — no `.Result`, no `.GetAwaiter().GetResult()`.
* Constructor-inject services; never resolve from `IServiceProvider` inside an action.
* `[Authorize]` on every protected action. Verify the *authenticated user's* permission against the *specific resource* being touched — a role check alone lets any authenticated user pass an ID that isn't theirs.

## Error shape

Return `ProblemDetails` (or `ValidationProblemDetails`) for every non-success response, so clients get one parseable shape.

**Do not wrap action bodies in `try`/`catch` to convert exceptions into 500s.** Let unhandled exceptions reach the global exception handler, which produces `ProblemDetails` centrally. Catch only when you can do something specific and useful with that exception type — mapping a `NotFoundException` to a 404, say. A `catch (Exception)` that logs and rethrows adds nothing; a `catch` that swallows hides real failures.

Never let a stack trace, inner-exception message, connection string, or SQL fragment reach a response body.

## Validation belongs at the boundary

* Data annotations on the request DTO handle shape: required, length, range, format.
* For rules that need more than one field or a database lookup, extend the validation pattern the codebase already uses — a custom `ValidationAttribute` or a dedicated validator class. Check the project first; do not introduce a second validation mechanism alongside an existing one.
* Reject invalid input at the boundary and return 400 with `ValidationProblemDetails`. Services should be able to assume their inputs are shape-valid; re-validating deep in the call stack means the boundary isn't doing its job.
* Client-side validation is a UX affordance, never a trust boundary.

## Data access

* Every list endpoint is paginated. An unbounded list endpoint is a latent outage.
* Watch for N+1: projecting a collection whose items each lazy-load a navigation property. Use explicit `Include`/`ThenInclude`, or project straight into a DTO with `Select`.
* Parameterized queries only. String-concatenated SQL is a defect even when the input "can't" be user-controlled.
* Consider `IAsyncEnumerable<T>` streaming for responses large enough that buffering the whole payload matters.

## Documentation

XML doc comments on public actions, covering the response types and status codes the action can actually produce. Document required headers and the auth scheme. Skip commentary that restates the method name.
