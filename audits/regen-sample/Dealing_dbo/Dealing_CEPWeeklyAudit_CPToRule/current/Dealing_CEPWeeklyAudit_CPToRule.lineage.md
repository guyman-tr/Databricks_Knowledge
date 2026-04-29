---
object: Dealing_CEPWeeklyAudit_CPToRule
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule
Dealing_staging.External_Etoro_History_CompoundPropertyToRule
    ↓
SP_W_CEPWeeklyAudit(@dd) — @weekStart to @weekEnd window
    — SysStartTime BETWEEN @weekStart AND @weekEnd → Added/ValueChange
    — SysEndTime BETWEEN @weekStart AND @weekEnd AND RN_desc=1 → Removed
    — LEFT JOIN #FromDateToDate → always one row per week
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule  ← DELETE + INSERT for week
```

## Column Lineage

| DWH Column | Source |
|-----------|--------|
| FromDate | @weekStart |
| ToDate | @weekEnd |
| RuleID | #CPToRule_Log |
| RuleName | #CPLog (latest CP-to-Rule state) |
| HedgeServerID | #Dim_CPtoRule |
| CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule |
| CP_Name | #CPLog |
| IsTrue | Value (External_Etoro_CEP_CompoundPropertyToRule) |
| TypeOfChange | Derived SP logic |
| LoginName | AppLoginName |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
