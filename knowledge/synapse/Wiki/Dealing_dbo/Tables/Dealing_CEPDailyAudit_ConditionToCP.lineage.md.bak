---
object: Dealing_CEPDailyAudit_ConditionToCP
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

## Source Classification

**No Generic Pipeline mapping** — sourced from the CEP (Client Execution Platform) internal system.

## ETL Flow

```
[CEP System — ConditionToCompoundProperty temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — JOIN to #CPLog for CP names, #Dim_CPtoRule for rule context
    — SysStartDate = @Date → Condition Added; SysEndDate = @Date → Condition Removed
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP  ← DELETE + INSERT for @Date
```

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date parameter | SP parameter |
| RuleID | RuleID | #Dim_CPtoRule (derived from CPToRule_Log + RulesLog) |
| RuleName | RuleName | #Dim_CPtoRule |
| HedgeServerID | HedgeServerID | #Dim_CPtoRule |
| CompoundPropertyID | CompoundPropertyID | External_Etoro_CEP_ConditionToCompoundProperty |
| CP_Name | Name | #CPLog (latest state) |
| ConditionID | ConditionID | External_Etoro_CEP_ConditionToCompoundProperty |
| TypeOfChange | Derived | SP: SysStartDate=@Date → 'Condition Added To CP'; SysEndDate=@Date → 'Condition Removed from CP' |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_ConditionToCompoundProperty |
| ChangeTime | SysStartTime / SysEndTime | External_Etoro_CEP_ConditionToCompoundProperty |
| UpdateDate | GETDATE() | SP execution time |
