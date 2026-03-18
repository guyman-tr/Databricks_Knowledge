# DWH_dbo.Dim_ActionType — Production Lineage Map

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
| 1 | ActionTypeID | DWH_Migration.Dim_ActionType | ActionTypeID | Type narrowing | varchar(10) → smallint |
| 2 | Name | DWH_Migration.Dim_ActionType | Name | None | Passthrough |
| 3 | UpdateDate | DWH_Migration.Dim_ActionType | Updatedate | Type conversion | varchar(50) → datetime. Historical values preserved. |
| 4 | InsertDate | DWH_Migration.Dim_ActionType | InsertDate | Type conversion | varchar(50) → datetime. Historical values preserved. |
| 5 | Category | DWH_Migration.Dim_ActionType | Category | None | Passthrough |
| 6 | CategoryID | DWH_Migration.Dim_ActionType | CategoryID | None | Passthrough |

## Added Columns (DWH-only, not in production)

All columns originated from the legacy DWH. No columns were added during migration.

## Lost Columns (in production, not in DWH)

Unknown — legacy DWH source schema not available for comparison.

## ETL Chain

```
Legacy DWH SQL Server (on-premises)
  → One-time migration (Sept 2024)
    → DWH_Migration.Dim_ActionType (varchar staging)
      → DWH_dbo.Dim_ActionType (typed, indexed)
```

## Important Notes

- **NOT from production Dictionary.ActionType**: The Generic Pipeline exports `etoro.Dictionary.ActionType` (16 rows, registration/game events). The DWH Dim_ActionType (45 rows, trading/financial events) is a completely separate table from the legacy DWH.
- **Migration scripts**: `NoDbObjectsScripts/2024_09_16_17_31_03_DWH_Migration.Dim_ActionType.sql` (main), `NoDbObjectsScripts/2024_09_22_17_11_42_DWH_Migration.JUNK_Dim_ActionType.sql` (staging variant).
- **Manual additions post-migration**: ActionTypeID 42 (Cashout Rollback, 2022), 43 (Reverse Deposit, 2022), 44 (InternalDeposit, 2024), 45 (InternalWithdraw, 2024) were added after the original 2013 data set.

## Upstream Wiki Reference

| Source | Path | Quality |
|--------|------|---------|
| N/A | No upstream wiki — DWH-specific table | — |
