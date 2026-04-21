# Column Lineage: eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.CurrencyBalanceStatuses |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus |
| **Row Count (live)** | 5 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | CurrencyBalanceStatusID | int NULL | FiatDwhDB.Dictionary.CurrencyBalanceStatuses | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | CurrencyBalanceStatus | varchar(50) NULL | FiatDwhDB.Dictionary.CurrencyBalanceStatuses | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.CurrencyBalanceStatuses (source — 5 rows: 0=Active through 4=Blocked)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/CurrencyBalanceStatuses/)
  |-- External Table: External_FiatDwhDB_Dictionary_CurrencyBalanceStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus (5 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | CurrencyBalanceStatusID, CurrencyBalanceStatus |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
