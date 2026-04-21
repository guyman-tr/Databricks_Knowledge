# Column Lineage: eMoney_dbo.eMoney_Dictionary_AccountStatus

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_AccountStatus |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.AccountStatuses |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus |
| **Row Count (live)** | 3 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | AccountStatusID | int NULL | FiatDwhDB.Dictionary.AccountStatuses | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | AccountStatus | varchar(50) NULL | FiatDwhDB.Dictionary.AccountStatuses | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.AccountStatuses (source — 3 rows: 0=Active, 1=Suspended, 2=Deleted)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_AccountStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountStatus (3 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | AccountStatusID, AccountStatus |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-20 | Phase 10B*
