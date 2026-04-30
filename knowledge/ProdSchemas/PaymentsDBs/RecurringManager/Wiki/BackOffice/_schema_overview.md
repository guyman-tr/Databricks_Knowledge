# BackOffice Schema - RecurringManager

## Purpose

The BackOffice schema in RecurringManager contains infrastructure-level objects used for database administration and deployment management. It is not part of the core recurring payments business logic.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| [BackOffice.UpgradeScript](Tables/BackOffice.UpgradeScript.md) | Table | Tracks which database migration scripts have been executed, enabling idempotent deployments |

## Characteristics

- **Size**: 1 object (1 table)
- **Business Role**: Infrastructure/deployment support - not involved in the recurring payments data flow
- **Consumers**: External deployment tooling only - no stored procedures, views, or functions reference objects in this schema
- **Relationships**: No cross-schema dependencies - fully self-contained

## Data Flow

```
Deployment Pipeline -> BackOffice.UpgradeScript (write-once log)
```

---

*Generated: 2026-04-16*
