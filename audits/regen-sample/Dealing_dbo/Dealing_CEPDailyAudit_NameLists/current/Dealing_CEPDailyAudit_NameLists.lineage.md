---
object: Dealing_CEPDailyAudit_NameLists
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_NameLists

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_NamedLists  (current)
Dealing_staging.External_Etoro_History_NamedLists  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — SysStartDate = @Date AND RN=1 → New Name List
    — SysStartDate = @Date AND RN>1 → Change In CIDs
    — SysEndDate = @Date AND RN_desc=1 → Name List Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_NameLists  ← DELETE + INSERT for @Date
```

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date | SP parameter |
| NameListID | NamedListID | External_Etoro_CEP_NamedLists |
| Name | Name | External_Etoro_CEP_NamedLists |
| TypeOfChange | Derived | RN/RN_desc SP logic |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_NamedLists |
| ChangeTime | SysStartTime / SysEndTime | External_Etoro_CEP_NamedLists |
| UpdateDate | GETDATE() | SP execution time |
