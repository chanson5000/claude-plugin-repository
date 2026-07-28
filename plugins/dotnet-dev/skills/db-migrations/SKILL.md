---
name: db-migrations
description: Use when adding or changing database schema — creating a migration script, adding or dropping a column, altering a type, adding an index, or backfilling existing rows. Covers DbUp, EF Core Migrations, and FluentMigrator. Load before writing the script, because the first rule (never edit an applied migration) is unrecoverable once broken.
---

# Database Migrations

Schema changes are the least reversible thing in the codebase. A bad migration that reaches production can lose data permanently, and no code review catches it after the fact.

## The rule that matters most

**Never modify a migration that has already been applied anywhere.** Not to fix a typo, not to add a forgotten column. Migration runners record which scripts they have run, usually by filename and often by content hash — editing an applied script either does nothing on already-migrated databases (leaving them permanently divergent) or hard-fails the runner on a checksum mismatch. Always add a new script.

The only exception: a script you authored in the current uncommitted working tree that has never been applied to any database including your own local one.

## Identify the tool first

Check the project's CLAUDE.md, then look for the database project's script directory:

| Tool | Applied in | Rollback | Script form |
|---|---|---|---|
| **DbUp** | Filename order | None — write a compensating script | `.sql` or `.cs` |
| **EF Core Migrations** | Timestamp order | `Down()`, if you wrote it correctly | Generated `.cs` + designer file |
| **FluentMigrator** | Version attribute order | `Down()` | `.cs` |

Match the existing naming convention exactly — read the directory before naming a new file. DbUp projects commonly use `s_YYYYMMDD_##_DescriptiveName.sql`; EF Core generates its own timestamp prefix via `dotnet ef migrations add`.

For DbUp and any tool without real rollback, write the compensating script *at the same time* as the forward migration for anything non-trivial, even if you never commit it. If you cannot describe how to undo the change, you do not yet understand it well enough to ship it.

## Adding a column

1. New migration script in the project's scripts directory.
2. Update the corresponding entity class, and the EF configuration or `DbContext` mapping if the project uses explicit configuration.
3. Decide nullability deliberately. `NOT NULL` on a table with existing rows **requires** a default or a backfill in the same script — otherwise the migration fails on any non-empty table, which usually means it passes locally and fails in staging.
4. Add an index if the column will appear in a `WHERE`, `JOIN`, or `ORDER BY`. Index creation on a large table locks it — check whether the target database supports a concurrent/online build.
5. Update affected queries, projections, and repository methods.

## Changing existing schema

Assume a deploy where old and new application code run simultaneously. That makes destructive one-step changes unsafe:

* **Renaming a column** is drop + add to the database. Do it in three deploys — add new, backfill and dual-write, drop old — or accept downtime.
* **Narrowing a type** (shortening a `varchar`, `int` → `smallint`) can truncate silently depending on server settings. Verify no existing row would be affected before altering.
* **Adding a `FOREIGN KEY` or `CHECK` constraint** fails if any existing row violates it. Query for violations first, then decide whether to clean or to add the constraint as `NOT ENFORCED`/untrusted.
* **Dropping anything** — column, table, index — needs confirmation that no deployed code version still references it.

## Script hygiene

* One logical change per migration. A script that adds two tables and backfills a third cannot be partially diagnosed when it fails.
* Wrap multi-statement scripts in an explicit transaction so a mid-script failure doesn't leave the schema half-changed. Note that some DDL — and some tools' own batching on `GO` boundaries — won't participate; check rather than assume.
* Make scripts idempotent where the tool doesn't guarantee once-only execution: `IF NOT EXISTS`, `IF OBJECT_ID(...) IS NULL`.
* Comment the *why* for anything non-obvious, especially a backfill's data assumptions.
* Test against a database with realistic row counts. A migration that takes 200ms on 50 local rows can take 40 minutes and hold a lock on 50 million production rows.
