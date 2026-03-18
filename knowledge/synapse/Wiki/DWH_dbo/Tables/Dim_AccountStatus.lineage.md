# DWH_dbo.Dim_AccountStatus — Production Lineage Map

## Production Source

| Property | Value |
|----------|-------|
| **Production Table** | etoro.Dictionary.AccountStatus |
| **Server** | etoroDB-REAL |
| **Generic Pipeline ID** | 209 |
| **Copy Strategy** | Override (full reload) |
| **Frequency** | Daily (1440 min) |
| **Lake Path** | Bronze/etoro/Dictionary/AccountStatus/ |
| **File Type** | parquet |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Notes |
|---|-----------|-------------|---------------|-----------|-------|
| 1 | AccountStatusID | Dictionary.AccountStatus | AccountStatusID | None | Passthrough. Widened from tinyint to int in DWH. |
| 2 | AccountStatusName | Dictionary.AccountStatus | AccountStatusName | None | Passthrough. |
| 3 | StatusID | — | — | Hardcoded = 1 | ETL-generated. Not from production. |
| 4 | UpdateDate | — | — | GETDATE() | ETL-generated. Not from production. |
| 5 | InsertDate | — | — | GETDATE() | ETL-generated. Not from production. |

## Added Columns (DWH-only, not in production)

| Column | Origin | Purpose |
|--------|--------|---------|
| StatusID | SP_Dictionaries_DL_To_Synapse | Always 1. ETL active-record flag. |
| UpdateDate | SP_Dictionaries_DL_To_Synapse | ETL refresh timestamp. |
| InsertDate | SP_Dictionaries_DL_To_Synapse | ETL insert timestamp. |

## Lost Columns (in production, not in DWH)

No columns lost — production Dictionary.AccountStatus has only AccountStatusID and AccountStatusName.

## ETL Chain

```
etoro.Dictionary.AccountStatus (etoroDB-REAL)
  → Generic Pipeline (daily, parquet, Override)
    → Bronze/etoro/Dictionary/AccountStatus/
      → DWH_staging.etoro_Dictionary_AccountStatus
        → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
          → DWH_dbo.Dim_AccountStatus
```

## Upstream Wiki Reference

| Source | Path | Quality |
|--------|------|---------|
| Dictionary.AccountStatus | DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountStatus.md | 8.2/10 |
