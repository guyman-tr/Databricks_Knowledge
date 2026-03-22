# Lineage Map — Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days

**Generated**: 2026-03-21
**Type**: View — thin filter wrapper
**Pattern**: SELECT * FROM base table WHERE Date >= GETDATE()-180 (rolling 180-day window)

## ETL Chain

```
Dealing_dbo.Dealing_CEPDailyAudit_Rules
  WHERE Date >= GETDATE()-180
        └── Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days
```

## Column Lineage

All columns pass through unchanged from `Dealing_dbo.Dealing_CEPDailyAudit_Rules`. No transformations. See [Dealing_CEPDailyAudit_Rules.md](Dealing_CEPDailyAudit_Rules.md) for full column definitions.

## Governance

- **No ETL / No writer**: This is a view — data is always read live from the base table
- **Rolling window**: 180 days from query execution time (GETDATE()-180) — not a fixed date range
- **No OpsDB entry**: Views are not tracked in Service Broker orchestration
