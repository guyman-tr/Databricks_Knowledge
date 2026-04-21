# Column Lineage: eMoney_dbo.eMoney_Dictionary_CardStatus

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_CardStatus |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.CardStatuses |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus |
| **Row Count (live)** | 9 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | CardStatusID | int NULL | FiatDwhDB.Dictionary.CardStatuses | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | CardStatus | varchar(50) NULL | FiatDwhDB.Dictionary.CardStatuses | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.CardStatuses (source — 9 rows: 0=NotActivated through 8=Fraud)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/CardStatuses/)
  |-- External Table: External_FiatDwhDB_Dictionary_CardStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_CardStatus (9 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | CardStatusID, CardStatus |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
