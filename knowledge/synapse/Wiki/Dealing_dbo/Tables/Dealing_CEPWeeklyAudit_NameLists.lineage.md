---
object: Dealing_CEPWeeklyAudit_NameLists
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_NamedLists
Dealing_staging.External_Etoro_History_NamedLists
    ↓
SP_W_CEPWeeklyAudit(@dd)
    — #NameLists_ChangesFinal built from week-window filter
    — INSERT: LEFT JOIN #FromDateToDate ON fdtd.FromDate=rcf.FromDate AND fdtd.ToDate=fdtd.ToDate [⚠️ self-join bug — second condition always true]
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists  ← DELETE + INSERT for week
```

⚠️ **SP join bug on line 878**: The NameLists INSERT uses `fdtd.ToDate=fdtd.ToDate` (self-reference) instead of `fdtd.ToDate=rcf.ToDate`. This may cause incorrect data population.

| DWH Column | Source |
|-----------|--------|
| FromDate/ToDate | SP week parameters |
| NameListID | External_Etoro_CEP_NamedLists.NamedListID |
| Name | External_Etoro_CEP_NamedLists.Name |
| TypeOfChange | #NameLists_ChangesFinal (potentially nulled by SP bug) |
| LoginName | AppLoginName |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
