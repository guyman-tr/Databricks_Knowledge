---
object: Dealing_CEPWeeklyAudit_Conditions
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_Conditions
Dealing_staging.External_Etoro_History_Conditions
    ↓ JOIN
Dealing_staging.External_Etoro_Dictionary_ConditionProperties  (PropertyID → name)
Dealing_staging.External_Etoro_Dictionary_ConditionOperators   (OperatorID → name)
    ↓
SP_W_CEPWeeklyAudit(@dd) — week window
    — SysStartTime in week → Property/Operator/Value change, New Condition
    — SysEndTime in week → Condition Deleted
    — LEFT JOIN #FromDateToDate
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions  ← DELETE + INSERT for week
```

| DWH Column | Source |
|-----------|--------|
| FromDate/ToDate | SP week parameters |
| ConditionID | External_Etoro_CEP_Conditions |
| Property | Dictionary_ConditionProperties (JOIN) |
| Operator | Dictionary_ConditionOperators (JOIN) |
| Value | External_Etoro_CEP_Conditions.Value |
| TypeOfChange | SP LAG logic |
| Comments | SP CONCAT previous values |
| LoginName | AppLoginName |
| RuleID/RuleName/HedgeServerID | #Dim_ConditionRule → #Dim_CPtoRule |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
