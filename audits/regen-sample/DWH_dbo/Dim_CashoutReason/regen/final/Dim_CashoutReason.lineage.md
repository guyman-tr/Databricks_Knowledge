# Lineage: DWH_dbo.Dim_CashoutReason

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | Dictionary.CashoutReason | Table | Dictionary | etoro | Production origin — 19-row lookup of withdrawal reasons |
| 2 | DWH_staging.etoro_Dictionary_CashoutReason | Table | DWH_staging | Synapse | Staging replica of Dictionary.CashoutReason (Generic Pipeline Bronze) |
| 3 | DWH_dbo.SP_Dictionaries_DL_To_Synapse | Stored Procedure | DWH_dbo | Synapse | Writer SP — TRUNCATE + INSERT from staging, UpdateDate = GETDATE() |

## Column Lineage

| DWH Column | Source Object | Source Column | Transform | Tier |
|-----------|--------------|---------------|-----------|------|
| CashoutReasonID | Dictionary.CashoutReason | CashoutReasonID | Passthrough (staging relay) | Tier 1 |
| Name | Dictionary.CashoutReason | Name | Passthrough (staging relay) | Tier 1 |
| UpdateDate | SP_Dictionaries_DL_To_Synapse | GETDATE() | ETL-computed: set to current timestamp on each TRUNCATE+INSERT cycle | Tier 2 |
