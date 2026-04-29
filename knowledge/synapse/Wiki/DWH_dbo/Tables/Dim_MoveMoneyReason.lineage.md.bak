# Column Lineage: DWH_dbo.Dim_MoveMoneyReason

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_MoveMoneyReason` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason` (expected) |
| **Primary Source** | `etoro.Dictionary.MoveMoneyReason` (partial, 4 of 9 IDs via legacy DWH migration) |
| **ETL SP** | None (frozen migration + manual DBA inserts) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.MoveMoneyReason (production, 9 rows)
  -> Generic Pipeline -> Bronze/etoro/Dictionary/MoveMoneyReason/ [not confirmed in DWH]
  -> Legacy DWH SQL Server (partial snapshot)
       -> DWH_Migration.Dim_MoveMoneyReason (NoDbObjectsScripts, 2024-09-16)
            -> DWH_dbo.Dim_MoveMoneyReason (4 rows, no active ETL refresh)

NOTE: Production has IDs 1-3, 5-9. DWH has IDs 1-4 only.
      ID=4 "Airdrop" in DWH diverges from production (marked deprecated).
      ID=5 (InternalTransfer Trade) is used by SP_Fact_CustomerAction
      to derive ActionTypeID 44/45 but is MISSING from DWH dim.
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived by ETL, not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| MoveMoneyReasonID | etoro.Dictionary.MoveMoneyReason | MoveMoneyReasonID | passthrough | int in both; DWH has 4 of 9 production IDs |
| MoveMoneyReason | etoro.Dictionary.MoveMoneyReason | MoveMoneyReason | passthrough | varchar(30) in both; ID=4 label "Airdrop" diverges from production |
| UpdateDate | DWH ETL / manual | - | ETL-computed | Not in production Dictionary.MoveMoneyReason; DWH-specific audit field |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 (MoveMoneyReasonID, MoveMoneyReason) |
| **ETL-computed** | 1 (UpdateDate) |
| **Total** | 3 |
