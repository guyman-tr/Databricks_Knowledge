---
object: Dealing_CEPDailyAudit_ListCIDMapping
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

## ETL Flow

```
[CEP System — ListCIDMappings temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (history)
    ↓ JOIN
#NameLists_Log (latest Name from #NameLists_Log WHERE RN_desc=1)
    ↓
SP_CEPDailyAudit(@Date)
    — SysStartDate = @Date → CID Added
    — SysEndDate = @Date AND SysEndTime < '9999-01-01' → CID Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping  ← DELETE + INSERT for @Date
```

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date | SP parameter |
| NameListID | NamedListID | External_Etoro_CEP_ListCIDMappings |
| ListName | Name | #NameLists_Log (latest state) |
| CID | CID | External_Etoro_CEP_ListCIDMappings |
| TypeOfChange | Derived | SysStartDate=@Date → 'CID Added'; SysEndDate=@Date → 'CID Deleted' |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_ListCIDMappings |
| ChangeTime | SysStartTime / SysEndTime | External_Etoro_CEP_ListCIDMappings |
| UpdateDate | GETDATE() | SP execution time |
