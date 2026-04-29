# DWH_dbo.Dim_AccountType — Column Lineage

## Source Objects

| Source Object | Type | Relationship | Schema Location |
|--------------|------|-------------|-----------------|
| etoro.Dictionary.AccountType | Production Table | Primary source (via Generic Pipeline Bronze export) | `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md` |
| DWH_staging.etoro_Dictionary_AccountType | Staging Table | Intermediate staging (Bronze → Lake → Staging) | No wiki (staging relay) |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | Stored Procedure | Writer SP (TRUNCATE + INSERT + sentinel row) | `DataPlatform/.../Stored Procedures/DWH_dbo.SP_Dictionaries_DL_To_Synapse.sql` |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | AccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | Passthrough (staging renames column identically). Sentinel row 0=N/A added by SP. | Tier 1 |
| 2 | Name | etoro.Dictionary.AccountType | AccountTypeName | Rename: AccountTypeName → Name. Values unchanged. | Tier 1 |
| 3 | DWHAccountTypeID | SP_Dictionaries_DL_To_Synapse | AccountTypeID | ETL-computed: `[AccountTypeID] AS [DWHAccountTypeID]`. Always equals AccountTypeID. | Tier 2 |
| 4 | StatusID | SP_Dictionaries_DL_To_Synapse | (hardcoded) | ETL-computed: hardcoded `1 AS StatusID` for all rows. | Tier 2 |
| 5 | UpdateDate | SP_Dictionaries_DL_To_Synapse | (hardcoded) | ETL-computed: `GETDATE()` at load time. | Tier 2 |
| 6 | InsertDate | SP_Dictionaries_DL_To_Synapse | (hardcoded) | ETL-computed: `GETDATE()` at load time. | Tier 2 |
