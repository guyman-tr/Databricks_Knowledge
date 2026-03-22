---
object: Dealing_CEPDailyAudit_Rules
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_Rules

## ETL Flow

```
[CEP System — Rules temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Rules  (current)
Dealing_staging.External_Etoro_History_Rules  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — LAG() detects Name/Description/IsActive/HedgeServerID/Priority changes
    — RN=1 + created within 60 min of ValidFrom → New Rule
    — RN_Desc=1 + SysEndDate=@Date → Rule Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Rules  ← DELETE + INSERT for @Date
```

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date | SP parameter |
| RuleID | RuleID | External_Etoro_CEP_Rules |
| RuleName | Name | External_Etoro_CEP_Rules |
| Description | Description | External_Etoro_CEP_Rules |
| HedgeServerID | HedgeRuleActionTypeID | External_Etoro_CEP_Rules |
| Priority | Priority | External_Etoro_CEP_Rules |
| TypeOfChange | Derived | SP LAG comparison + RN/RN_Desc logic |
| Comments | CONCAT('Previous X: ', previous_value) | SP derived |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_Rules |
| ChangeTime | SysStartTime / SysEndTime | External_Etoro_CEP_Rules |
| UpdateDate | GETDATE() | SP execution time |
