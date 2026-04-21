# Column Lineage: eMoney_dbo.eMoney_Dictionary_TribeScriptStatus

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_TribeScriptStatus |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.TribeScriptStatus |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus |
| **Row Count (live)** | 3 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | TribeScriptStatusID | int NULL | FiatDwhDB.Dictionary.TribeScriptStatus | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | TribeScriptStatus | varchar(50) NULL | FiatDwhDB.Dictionary.TribeScriptStatus | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.TribeScriptStatus (source — 3 rows: 0=Unapproved, 1=Approved, 2=Executed)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/TribeScriptStatus/)
  |-- External Table: External_FiatDwhDB_Dictionary_TribeScriptStatus ---|
  v
eMoney_dbo.eMoney_Dictionary_TribeScriptStatus (3 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | TribeScriptStatusID, TribeScriptStatus |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
