# Lineage: Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

## Source Objects

| # | Source Object | Type | Schema | Role |
|---|--------------|------|--------|------|
| 1 | `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | External Table | Dealing_staging | Current CID-to-NamedList membership |
| 2 | `Dealing_staging.External_Etoro_History_ListCIDMappings` | External Table | Dealing_staging | Temporal history of CID-to-NamedList membership |
| 3 | `Dealing_staging.External_Etoro_CEP_NamedLists` | External Table | Dealing_staging | Current Named List definitions (for Name resolution) |
| 4 | `Dealing_staging.External_Etoro_History_NamedLists` | External Table | Dealing_staging | Temporal history of Named List definitions |
| 5 | `Dealing_dbo.SP_W_CEPWeeklyAudit` | Stored Procedure | Dealing_dbo | Writer SP — weekly DELETE + INSERT |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | FromDate | SP_W_CEPWeeklyAudit | `@weekStart` | Computed: `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` — Monday of the audit week | Tier 2 |
| 2 | ToDate | SP_W_CEPWeeklyAudit | `@weekEnd` | Computed: `DATEADD(DAY,6,@weekStart)` — Sunday of the audit week | Tier 2 |
| 3 | NameListID | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | NamedListID | Passthrough (positional rename in INSERT) | Tier 2 |
| 4 | ListName | #NameLists_Log (from External_Etoro_CEP_NamedLists / External_Etoro_History_NamedLists) | Name | Passthrough via JOIN on NamedListID; positional map to ListName column | Tier 2 |
| 5 | CID | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | CID | Passthrough | Tier 2 |
| 6 | TypeOfChange | SP_W_CEPWeeklyAudit | — | SP-derived: `'CID Added'` when SysStartTime in week, `'CID Deleted'` when SysEndTime in week; NULL for placeholder rows from LEFT JOIN | Tier 2 |
| 7 | LoginName | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | AppLoginName | Passthrough (positional rename in INSERT) | Tier 2 |
| 8 | ChangeTime | External_Etoro_CEP_ListCIDMappings / External_Etoro_History_ListCIDMappings | SysStartTime / SysEndTime | SysStartTime for CID Added events; SysEndTime for CID Deleted events | Tier 2 |
| 9 | UpdateDate | SP_W_CEPWeeklyAudit | `GETDATE()` | ETL load timestamp | Tier 4 |
