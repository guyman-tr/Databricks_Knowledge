# Column Lineage: eMoney_dbo.eMoney_Dictionary_AuthorizationType

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_AuthorizationType |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.AuthorizationTypes |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype |
| **Row Count (live)** | 15 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | AuthorizationTypeID | int NULL | FiatDwhDB.Dictionary.AuthorizationTypes | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | AuthorizationType | varchar(50) NULL | FiatDwhDB.Dictionary.AuthorizationTypes | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.AuthorizationTypes (source — 15 rows: 0=Unknown through 14=AccountFunding)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/AuthorizationTypes/)
  |-- External Table: External_FiatDwhDB_Dictionary_AuthorizationTypes ---|
  v
eMoney_dbo.eMoney_Dictionary_AuthorizationType (15 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | AuthorizationTypeID, AuthorizationType |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
