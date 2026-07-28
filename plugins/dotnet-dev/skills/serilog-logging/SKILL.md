---
name: serilog-logging
description: Use when adding or changing log statements in a .NET project using Serilog or ILogger<T> — covers message templates, level selection, scopes, and what must never be logged. Load before writing the log line. For sweeping an existing codebase to find logging gaps, dispatch the dotnet-dev:logging-auditor agent instead.
---

# Structured Logging (Serilog / ILogger&lt;T&gt;)

Logs are queried, not read. Every rule here follows from that: a log line's value is how well it can be filtered, aggregated, and correlated months later by someone who wasn't there.

Check the project's CLAUDE.md or startup configuration for where logging is wired up, which sinks are active, and per-namespace minimum levels.

## Message templates, never interpolation

```csharp
// ✗ one opaque string per call — unqueryable, and defeats template-based grouping
logger.LogInformation($"User {userId} accessed account {accountId}");

// ✓ named properties, stored as structured fields
logger.LogInformation("User {UserId} accessed account {AccountId}", userId, accountId);
```

This is the single highest-value rule in this file. An interpolated log line cannot be searched by `UserId` and cannot be grouped by event shape — it produces one distinct message per invocation.

Property names are PascalCase and consistent application-wide: `UserId`, `OrderId`, `TransactionId`, `CorrelationId`. Two spellings of the same concept means two columns and no correlation.

## Choosing a level

| Level | For | Example |
|---|---|---|
| **Critical** | Unrecoverable — app cannot continue, data corrupted, security breach | Startup failure on a required dependency |
| **Error** | An operation failed. Something is broken and someone should look | Caught exception, external service failure |
| **Warning** | Degraded but handled — retry, fallback taken, limit approaching | Rate limit at 90%, config fell back to default |
| **Information** | Significant business or lifecycle events | Order placed, service started, workflow completed |
| **Debug** | Diagnostic flow detail for troubleshooting | Item counts, branch taken, elapsed timings |
| **Trace** | Very fine-grained, temporary | Rarely appropriate in committed code |

The recurring mistake is level inflation in both directions: routine per-request chatter at Information (drowning the real events), and genuine failures at Warning (so nothing alerts). If a human should act on it, it is at least Error.

## Always pass the exception object

```csharp
// ✗ discards stack trace, inner exceptions, and exception type
logger.LogError(ex.Message);
logger.LogError("Failed to save: " + ex.Message);

// ✓ full exception as the first argument, plus identifying context
logger.LogError(ex, "Failed to save order {OrderId} for customer {CustomerId}", orderId, customerId);
```

Context means the IDs needed to find the affected record. `logger.LogError(ex, "Failed to save")` is nearly useless in production — it tells you something broke but not what.

## Scopes for correlation

Wrap multi-step operations so every nested log line carries the operation's identity:

```csharp
using (logger.BeginScope("Processing batch {BatchId}", batchId))
{
    logger.LogInformation("Started processing {ItemCount} items", items.Count);
    // ...
    logger.LogInformation("Completed {SuccessCount} succeeded, {FailureCount} failed",
        successCount, failureCount);
}
```

## Never log

Passwords, secrets, API keys, tokens, connection strings, full card or bank account numbers, SSNs, health information, or raw request bodies that may contain any of the above.

Safe: entity IDs, last-four digits, masked or hashed values, transaction IDs, counts and durations. Prefer a `UserId` over a username, since usernames are frequently email addresses and therefore PII.

Serializing a whole entity — `logger.LogDebug("Saving {@Order}", order)` — is the usual way sensitive fields leak into logs by accident. Log the fields you need.

## Canonical service-method shape

```csharp
public async Task<Result> ProcessOrderAsync(int orderId, CancellationToken cancellationToken)
{
    logger.LogInformation("Starting order processing for order {OrderId}", orderId);

    try
    {
        var order = await _repository.GetOrderAsync(orderId, cancellationToken);
        if (order is null)
        {
            logger.LogWarning("Order {OrderId} not found", orderId);
            return Result.NotFound();
        }

        await _processor.ProcessAsync(order, cancellationToken);
        logger.LogInformation("Order {OrderId} processed successfully", orderId);
        return Result.Success();
    }
    catch (ValidationException ex)
    {
        logger.LogWarning(ex, "Validation failed for order {OrderId}", orderId);
        return Result.ValidationError(ex.Message);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to process order {OrderId}", orderId);
        return Result.Error();
    }
}
```

Variations on the same structure:

* **Controllers** — log the entity ID on entry and the created/updated ID on success. Map to an HTTP status; do not re-throw.
* **Outbound HTTP calls** — Debug on entry and exit, include `{ElapsedMs}` from a `Stopwatch`, log non-success status codes at Warning before re-throwing.
* **Background jobs** — log job name at start and finish; record per-item failures inside the loop *without* aborting the batch; emit `{ProcessedCount}` and `{FailedCount}` summary counts at the end.

## Performance

Serilog and `Microsoft.Extensions.Logging` both short-circuit disabled levels cheaply, so `if (logger.IsEnabled(...))` guards are usually noise. They earn their place only when building the arguments is itself expensive — serialization, a database read, a `ToList()` purely for logging. Do watch for logging inside tight loops and hot paths, where even cheap calls add up.

## Regulated domains

For financial, healthcare, or legal data, additionally:

* Log authentication attempts, permission denials, and privilege escalations at Warning or above — always.
* Route audit trails (who did what, to which resource, when) to a separate tamper-resistant sink, not the general application log.
* Emit volume metrics on bulk export and bulk read operations so anomalous access patterns are detectable.
* Confirm whether SOX, HIPAA, or GDPR impose retention limits or access controls on the log data itself.
