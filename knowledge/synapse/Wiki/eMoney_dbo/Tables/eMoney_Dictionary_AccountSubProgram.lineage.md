# Column Lineage: eMoney_dbo.eMoney_Dictionary_AccountSubProgram

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_AccountSubProgram |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.dbo.SubPrograms (NOT Dictionary schema — note different schema) |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram |
| **Row Count (live)** | 10 (FiatDwhDB source has 16; IDs 11-16 — AUS and DK sub-programs — not yet in Synapse) |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | AccountSubProgramID | int NULL | FiatDwhDB.dbo.SubPrograms | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | AccountSubProgram | varchar(50) NULL | FiatDwhDB.dbo.SubPrograms | Name (nvarchar(128)) | Rename + type narrow (nvarchar(128)→varchar(50)); passthrough value | Tier 1 |
| 3 | AccountProgramID | int NULL | FiatDwhDB.dbo.SubPrograms | AccountProgramId (tinyint) | Rename + type widen; passthrough value | Tier 1 |
| 4 | CUGAccountSubProgram | varchar(50) NULL | FiatDwhDB.dbo.SubPrograms | CugProgramName (nvarchar(128)) | Rename + type narrow; passthrough value | Tier 1 |
| 5 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.dbo.SubPrograms (source — 16 rows, product sub-program config)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_dbo_SubPrograms ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountSubProgram (10 rows live, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 4 | AccountSubProgramID, AccountSubProgram, AccountProgramID, CUGAccountSubProgram |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 5 | |

*Generated: 2026-04-20 | Phase 10B*
