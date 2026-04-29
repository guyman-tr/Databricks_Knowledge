# Column Lineage: DWH_dbo.Dim_CardType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CardType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype` (expected) |
| **Primary Source** | `etoro.Dictionary.CardType` (via Legacy DWH SQL Server, 2019 snapshot) |
| **ETL SP** | None (frozen migration) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.CardType (production, etoroDB-REAL)
  [Generic Pipeline ID 229 -> Bronze/etoro/Dictionary/CardType/ - NOT consumed by DWH]
  |
  -> Legacy DWH SQL Server (2019 snapshot of Dim_CardType)
       -> DWH_Migration.Dim_CardType (migration staging, NoDbObjectsScripts 2024-09-16)
            -> DWH_dbo.Dim_CardType (Synapse, REPLICATE, 18 rows, frozen)
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
| CardTypeID | etoro.Dictionary.CardType | CardTypeID | passthrough | int in both |
| CarTypeName | etoro.Dictionary.CardType | Name | rename | Name -> CarTypeName (includes DDL typo "Car" instead of "Card") |
| IsActive | etoro.Dictionary.CardType | IsActive | cast/convert | bit in production -> int in DWH |
| UpdateDate | — | — | ETL-computed | Migration load timestamp (2019-06-30); not from source |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 (CardTypeID) |
| **Rename** | 1 (CarTypeName <- Name) |
| **Cast/Convert** | 1 (IsActive) |
| **ETL-computed** | 1 (UpdateDate) |
| **Total** | 4 |
