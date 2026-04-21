# Column Lineage: eMoney_dbo.eMoney_Dictionary_TransactionStatus

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_TransactionStatus |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.TransactionStatuses |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus |
| **Row Count (live)** | 6 (upstream FiatDwhDB has 8; IDs 6=Reserved and 7=Cancelled not yet loaded to Synapse) |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | TransactionStatusID | int NULL | FiatDwhDB.Dictionary.TransactionStatuses | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | TransactionStatus | varchar(50) NULL | FiatDwhDB.Dictionary.TransactionStatuses | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionStatuses (source — 8 rows incl. Reserved/Cancelled)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_TransactionStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_TransactionStatus (6 rows live, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | TransactionStatusID, TransactionStatus |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-20 | Phase 10B*
