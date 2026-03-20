# Column Lineage: DWH_dbo.Dim_Fund

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Fund` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund` |
| **Primary Source** | `etoro.Trade.Fund` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Trade.Fund (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Trade/Fund/]
    |
    v
DWH_staging.etoro_Trade_Fund (11 cols: adds CreateDate, LastUpdateDate, HasCrypto)
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 646)
  - Drops: CreateDate, LastUpdateDate, HasCrypto
  - Adds: UpdateDate = GETDATE()
    |
    v
DWH_dbo.Dim_Fund (REPLICATE / CLUSTERED INDEX)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **type-change** | Same value, different type in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **dropped** | Present in staging, not loaded to DWH. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| FundID | etoro.Trade.Fund | FundID | passthrough | int. Primary key. |
| FundName | etoro.Trade.Fund | FundName | passthrough | nvarchar(255) in DWH (max in staging). |
| FundAccountID | etoro.Trade.Fund | FundAccountID | passthrough | int. |
| FundOwnerID | etoro.Trade.Fund | FundOwnerID | passthrough | int. |
| IsPublic | etoro.Trade.Fund | IsPublic | passthrough | bit. |
| MinCopyAmount | etoro.Trade.Fund | MinCopyAmount | type-change | decimal(38,18) in staging -> money in DWH. |
| RefreshIntervalMonths | etoro.Trade.Fund | RefreshIntervalMonths | passthrough | int. |
| FundType | etoro.Trade.Fund | FundType | passthrough | int NULL. FK to Dim_FundType. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. NOT NULL. |
| (dropped) | etoro.Trade.Fund | CreateDate | dropped | datetime2 - not in DWH Dim_Fund |
| (dropped) | etoro.Trade.Fund | LastUpdateDate | dropped | datetime2 - not in DWH Dim_Fund |
| (dropped) | etoro.Trade.Fund | HasCrypto | dropped | bit - not in DWH Dim_Fund |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Type-change** | 1 |
| **ETL-computed** | 1 |
| **Dropped (staging only)** | 3 |
| **Total (DWH columns)** | 9 |
