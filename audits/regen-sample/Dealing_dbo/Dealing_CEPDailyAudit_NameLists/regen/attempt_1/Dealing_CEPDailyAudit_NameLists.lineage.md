# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_NameLists

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---------------|------|--------|----------|--------------|
| 1 | External_Etoro_CEP_NamedLists | Table | Dealing_staging | Synapse | Current named list state |
| 2 | External_Etoro_History_NamedLists | Table | Dealing_staging | Synapse | Temporal history of named lists |
| 3 | SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Synapse | Writer SP — DELETE + INSERT per @Date |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|---------------|---------------|---------------|-----------|------|
| 1 | Date | SP_CEPDailyAudit | @Date parameter | Set to the SP input parameter @Date | Tier 2 |
| 2 | NameListID | External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists | NamedListID | Passthrough via #NameLists_Log → #NameLists_ChangesFinal | Tier 2 |
| 3 | Name | External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists | Name | Passthrough via #NameLists_Log → #NameLists_ChangesFinal | Tier 2 |
| 4 | TypeOfChange | SP_CEPDailyAudit | Derived | CASE: RN=1 → 'New Name List'; RN_desc=1 + SysEndDate=@Date → 'Name List Deleted'; else → 'Change In CIDs' | Tier 2 |
| 5 | LoginName | External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) via LEAD() window; aliased as PreviousAppLoginName in INSERT | Tier 2 |
| 6 | ChangeTime | External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists | SysStartTime / SysEndTime | SysStartTime for additions (SysStartDate = @Date); SysEndTime for deletions/end events (SysEndDate = @Date) | Tier 2 |
| 7 | UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL load timestamp — GETDATE() at SP execution time | Tier 2 |
