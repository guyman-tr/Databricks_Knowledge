# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|--------------|------|--------|------|------|
| 1 | External_Etoro_CEP_ListCIDMappings | External Table | Dealing_staging | Current CID-to-Named-List membership state | — |
| 2 | External_Etoro_History_ListCIDMappings | External Table | Dealing_staging | Temporal history of CID-to-Named-List membership | — |
| 3 | External_Etoro_CEP_NamedLists | External Table | Dealing_staging | Current Named List definitions (joined for list name) | — |
| 4 | External_Etoro_History_NamedLists | External Table | Dealing_staging | Temporal history of Named List definitions | — |
| 5 | SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Writer SP — DELETE+INSERT for @Date | SP code in bundle |
| 6 | Dealing_CEPDailyAudit_NameLists | Table | Dealing_dbo | Sibling audit — list-level lifecycle events | `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_CEPDailyAudit_NameLists.md` |

## Column Lineage

| Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|--------------|-----------------|-----------------|-----------|------|
| Date | SP_CEPDailyAudit | @Date parameter | Direct assignment — business date for this audit run | Tier 2 |
| NameListID | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | NamedListID | Passthrough from #ListCIDMapping_Log (renamed from NamedListID) | Tier 2 |
| ListName | External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists | Name | Resolved via JOIN #NameLists_Log on NamedListID; uses latest name (RN_Desc=1) | Tier 2 |
| CID | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | CID | Passthrough from staging temporal tables | Tier 2 |
| TypeOfChange | SP_CEPDailyAudit | Derived | `CID Added` when SysStartDate=@Date; `CID Deleted` when SysEndTime<9999 AND SysEndDate=@Date | Tier 2 |
| LoginName | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) via LEAD() window — aliased as PreviousAppLoginName in INSERT | Tier 2 |
| ChangeTime | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | SysStartTime / SysEndTime | SysStartTime for CID Added; SysEndTime for CID Deleted | Tier 2 |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata timestamp at SP execution time | Tier 2 |
