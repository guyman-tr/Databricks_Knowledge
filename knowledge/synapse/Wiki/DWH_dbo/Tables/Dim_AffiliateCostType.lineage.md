# DWH_dbo.Dim_AffiliateCostType — Production Lineage Map

## Production Source

| Property | Value |
|----------|-------|
| **Production Table** | Legacy DWH SQL Server (on-premises) |
| **Server** | Unknown (legacy, decommissioned) |
| **Generic Pipeline ID** | N/A — not in Generic Pipeline |
| **Copy Strategy** | One-time migration (Sept 2024) |
| **Frequency** | None — frozen since migration |
| **Lake Path** | N/A |
| **File Type** | N/A |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Notes |
|---|-----------|-------------|---------------|-----------|-------|
| 1 | AffiliateCostTypeID | DWH_Migration.Dim_AffiliateCostType | AffiliateCostTypeID | None | Passthrough |
| 2 | Name | DWH_Migration.Dim_AffiliateCostType | Name | None | Passthrough |
| 3 | InsertDate | DWH_Migration.Dim_AffiliateCostType | InsertDate | None | NULL for all rows |
| 4 | UpdateDate | DWH_Migration.Dim_AffiliateCostType | UpdateDate | None | NULL for all rows |

## ETL Chain

```
Legacy DWH SQL Server (on-premises)
  → One-time migration (Sept 2024)
    → DWH_Migration.Dim_AffiliateCostType
      → DWH_dbo.Dim_AffiliateCostType (frozen)
```

## Migration Scripts

- `NoDbObjectsScripts/2024_09_16_17_31_03_DWH_Migration.Dim_AffiliateCostType.sql`
- `NoDbObjectsScripts/2024_09_22_17_11_42_DWH_Migration.JUNK_Dim_AffiliateCostType.sql`

## Upstream Wiki Reference

| Source | Path | Quality |
|--------|------|---------|
| N/A | No upstream wiki — DWH-specific table | — |
