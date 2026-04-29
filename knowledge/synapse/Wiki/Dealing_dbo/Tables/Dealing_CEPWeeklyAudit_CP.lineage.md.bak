---
object: Dealing_CEPWeeklyAudit_CP
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_CP

## ETL Flow

```
Dealing_staging.External_Etoro_CEP_CompoundProperties  (current)
Dealing_staging.External_Etoro_History_CompoundProperties  (history)
    ↓
SP_W_CEPWeeklyAudit(@dd)
    — @weekStart = Monday, @weekEnd = Sunday
    — ChangeTime BETWEEN @weekStart AND @weekEnd
    — LEFT JOIN #FromDateToDate guarantees one row per week (nullable if no changes)
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CP  ← DELETE + INSERT for (@weekStart, @weekEnd)
```

## Column Lineage

| DWH Column | Source |
|-----------|--------|
| FromDate | @weekStart (SP derived: DATEADD(DAY,1,DATEADD(WW,-1,@dd))) |
| ToDate | @weekEnd (SP derived: DATEADD(DAY,6,@weekStart)) |
| RuleID | #Dim_CPtoRule via CPToRule_Log |
| RuleName | #Dim_CPtoRule |
| CompoundPropertyID | #CPChangesFinal ← #CPLog |
| CPName | Name from #CPLog |
| HedgeServerID | #Dim_CPtoRule |
| TypeOfChange | Derived: New CP / Name Change / CP Deleted |
| Comments | CONCAT('Previous Name: ', PreviousName) |
| LoginName | AppLoginName |
| ChangeTime | SysStartTime / SysEndTime |
| UpdateDate | GETDATE() |
