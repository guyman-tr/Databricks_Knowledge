---
object: Dealing_CEPWeeklyAudit_Rules
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_Rules

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_Rules  (current)
Dealing_staging.External_Etoro_History_Rules  (history)
    ↓
SP_W_CEPWeeklyAudit(@dd)
    — @weekStart = Monday, @weekEnd = Sunday
    — ChangeTime BETWEEN @weekStart AND @weekEnd (or SysEndTime for deletions)
    — LEFT JOIN #FromDateToDate → one row per week
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_Rules  ← DELETE + INSERT for (@weekStart, @weekEnd)
```

## Column Lineage

| DWH Column | Source |
|-----------|--------|
| FromDate | @weekStart |
| ToDate | @weekEnd |
| RuleID | External_Etoro_CEP_Rules.RuleID |
| RuleName | External_Etoro_CEP_Rules.Name |
| Description | External_Etoro_CEP_Rules.Description |
| HedgeServerID | External_Etoro_CEP_Rules.HedgeRuleActionTypeID |
| Priority | External_Etoro_CEP_Rules.Priority |
| TypeOfChange | SP LAG logic (Name/Description/IsActive/HedgeServerID/Priority changes) |
| Comments | CONCAT('Previous X: ', previous_value) |
| LoginName | AppLoginName (no COALESCE fallback in Weekly SP) |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
