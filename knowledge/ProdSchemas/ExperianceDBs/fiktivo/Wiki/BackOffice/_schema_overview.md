# BackOffice Schema Overview

> Database migration history tracking - a single table that records every SQL upgrade script executed against the fiktivo database since 2011.

## Purpose

The BackOffice schema contains the database migration history infrastructure. Its single table, UpgradeScript, records every SQL script executed against the database, providing a complete audit trail of schema changes and data migrations spanning 15+ years.

## Architecture

```
SQL Script Execution
    |
    +-- Manual (developer): TRAD\username from workstation
    |
    +-- CI/CD Pipeline: CICD_DB_EXPERIENCE from AKS runner
    v
BackOffice.UpgradeScript
    = Records: ScriptName, Version, Occurred, LoginName, HostName
    = Idempotency: check ScriptName before executing
    = 279 records (2011-03-01 to 2026-02-09)
```

## Object Summary

| Object | Type | Role |
|--------|------|------|
| UpgradeScript | Table | Migration history: records every executed SQL script with auto-captured context |

## Key Design Patterns

- **Auto-captured context**: Occurred (GETDATE), LoginName (ORIGINAL_LOGIN), HostName (HOST_NAME) defaults
- **Idempotency key**: ScriptName prevents duplicate execution
- **JIRA traceability**: Script naming convention {TICKET}_{Description}.sql links migrations to requirements
- **NOT FOR REPLICATION**: Each environment maintains its own identity sequence
- **Append-only**: FILLFACTOR 90 tuned for continuous inserts with minimal page splits
