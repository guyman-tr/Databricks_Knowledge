# Lineage Map — Dealing_dbo.V_Dealing_DealingDashboard_Clients

**Generated**: 2026-03-21
**Type**: View — thin filter wrapper
**Pattern**: SELECT * FROM base table WHERE DateID > 20211231 (data from 2022 onwards)

## ETL Chain

```
Dealing_dbo.Dealing_DealingDashboard_Clients (NOLOCK)
  WHERE DateID > 20211231
        └── Dealing_dbo.V_Dealing_DealingDashboard_Clients
```

## Column Lineage

All columns pass through unchanged from `Dealing_dbo.Dealing_DealingDashboard_Clients`. No transformations. See [Dealing_DealingDashboard_Clients.md](Dealing_DealingDashboard_Clients.md) for full column definitions.

## Governance

- **No ETL / No writer**: This is a view — data is always read live from the base table
- **Fixed cutoff**: DateID > 20211231 — excludes all data from 2021 and earlier (static, not rolling)
- **NOLOCK hint**: View uses WITH(NOLOCK) — intended for high-frequency dashboard reads; may read uncommitted data
- **No OpsDB entry**: Views are not tracked in Service Broker orchestration
