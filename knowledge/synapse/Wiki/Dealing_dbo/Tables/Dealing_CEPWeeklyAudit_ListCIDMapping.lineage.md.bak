---
object: Dealing_CEPWeeklyAudit_ListCIDMapping
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_ListCIDMappings
Dealing_staging.External_Etoro_History_ListCIDMappings
    ↓ JOIN #NameLists_Log (for Name)
SP_W_CEPWeeklyAudit(@dd) — week window
    — SysStartTime in week → CID Added
    — SysEndTime < '9999-01-01' AND in week → CID Deleted
    — LEFT JOIN #FromDateToDate
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping  ← DELETE + INSERT for week
```

| DWH Column | Source |
|-----------|--------|
| FromDate/ToDate | SP week parameters |
| NameListID | External_Etoro_CEP_ListCIDMappings.NamedListID |
| Name | #NameLists_Log latest Name |
| CID | External_Etoro_CEP_ListCIDMappings.CID |
| TypeOfChange | SysStartTime in week → Added; SysEndTime in week → Deleted |
| LoginName | AppLoginName |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
