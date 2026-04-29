---
object: Dealing_CEPWeeklyAudit_ConditionToCP
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty
    ↓
SP_W_CEPWeeklyAudit(@dd) — week window filter
    — SysStartTime in week → Condition Added
    — SysEndTime in week → Condition Removed
    — LEFT JOIN #FromDateToDate → nullable no-change rows
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP  ← DELETE + INSERT for week
```

| DWH Column | Source |
|-----------|--------|
| FromDate/ToDate | SP week parameters |
| CompoundPropertyID | External_Etoro_CEP_ConditionToCompoundProperty |
| CP_Name | #CPLog latest state |
| ConditionID | External_Etoro_CEP_ConditionToCompoundProperty |
| RuleID/RuleName/HedgeServerID | #Dim_CPtoRule |
| TypeOfChange | Derived SP logic |
| LoginName | AppLoginName |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
