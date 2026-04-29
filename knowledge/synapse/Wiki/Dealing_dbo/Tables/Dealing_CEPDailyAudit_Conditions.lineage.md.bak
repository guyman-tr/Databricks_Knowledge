---
object: Dealing_CEPDailyAudit_Conditions
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_Conditions

## ETL Flow

```
[CEP System — Conditions temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (history)
    ↓ JOIN
Dealing_staging.External_Etoro_Dictionary_ConditionProperties  (PropertyID → name)
Dealing_staging.External_Etoro_Dictionary_ConditionOperators   (OperatorID → name)
    ↓
SP_CEPDailyAudit(@Date)
    — LAG() detects Property/Operator/Value changes
    — Classifies: Property Change, Operator Change, Value Change, New Condition, Condition Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Conditions  ← DELETE + INSERT for @Date
```

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date | SP parameter |
| RuleID | RuleID | #Dim_ConditionRule (derived via ConditionToCP + CPToRule) |
| RuleName | RuleName | #Dim_ConditionRule |
| HedgeServerID | HedgeServerID | #Dim_ConditionRule |
| ConditionID | ConditionID | External_Etoro_CEP_Conditions |
| Property | Name | External_Etoro_Dictionary_ConditionProperties (via PropertyID JOIN) |
| Operator | Name | External_Etoro_Dictionary_ConditionOperators (via OperatorID JOIN) |
| Value | Value | External_Etoro_CEP_Conditions |
| TypeOfChange | Derived | SP LAG comparison logic |
| Comments | CONCAT('Previous X: ', old_value) | SP derived |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_Conditions |
| ChangeTime | SysStartTime | External_Etoro_CEP_Conditions |
| UpdateDate | GETDATE() | SP execution time |
