# DWH_dbo.Dim_AccountType — Production Lineage Map

## Production Source

| Property | Value |
|----------|-------|
| **Production Table** | etoro.Dictionary.AccountType |
| **Server** | etoroDB-REAL |
| **Generic Pipeline ID** | 211 |
| **Copy Strategy** | Override (full reload) |
| **Frequency** | Daily (1440 min) |
| **Lake Path** | Bronze/etoro/Dictionary/AccountType/ |
| **File Type** | parquet |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Notes |
|---|-----------|-------------|---------------|-----------|-------|
| 1 | AccountTypeID | Dictionary.AccountType | AccountTypeID | None | Passthrough. Widened from tinyint to int. PK (NOT ENFORCED). |
| 2 | Name | Dictionary.AccountType | AccountTypeName | Renamed | Column renamed from AccountTypeName → Name in SP_Dictionaries. |
| 3 | DWHAccountTypeID | Dictionary.AccountType | AccountTypeID | Copy | `[AccountTypeID] as [DWHAccountTypeID]` — redundant surrogate. |
| 4 | StatusID | — | — | Hardcoded = 1 | ETL-generated. Not from production. |
| 5 | UpdateDate | — | — | GETDATE() | ETL-generated. Not from production. |
| 6 | InsertDate | — | — | GETDATE() | ETL-generated. Not from production. |

## Added Columns (DWH-only, not in production)

| Column | Origin | Purpose |
|--------|--------|---------|
| DWHAccountTypeID | SP_Dictionaries_DL_To_Synapse | Redundant copy of AccountTypeID. DWH surrogate. |
| StatusID | SP_Dictionaries_DL_To_Synapse | Always 1. ETL active-record flag. |
| UpdateDate | SP_Dictionaries_DL_To_Synapse | ETL refresh timestamp. |
| InsertDate | SP_Dictionaries_DL_To_Synapse | ETL insert timestamp. |

## Lost Columns (in production, not in DWH)

No columns lost — production columns are AccountTypeID and AccountTypeName (renamed to Name).

## ETL Chain

```
etoro.Dictionary.AccountType (etoroDB-REAL)
  → Generic Pipeline (daily, parquet, Override)
    → Bronze/etoro/Dictionary/AccountType/
      → DWH_staging.etoro_Dictionary_AccountType
        → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
          → DWH_dbo.Dim_AccountType
```

## Upstream Wiki Reference

| Source | Path | Quality |
|--------|------|---------|
| Dictionary.AccountType | DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md | 8.4/10 |
