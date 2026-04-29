---
object: Dealing_CEPDailyAudit_CP
schema: Dealing_dbo
lineage_type: cep-temporal-audit
generated: 2026-03-21
---

# Lineage — Dealing_CEPDailyAudit_CP

## Pipeline Status

**ACTIVE** — Last data 2026-03-09. Runs daily.

## ETL Chain

```
CEP (Client Execution Platform) — internal hedging rule engine
    → Dealing_staging.External_Etoro_CEP_CompoundProperties        (current state, temporal table)
    → Dealing_staging.External_Etoro_History_CompoundProperties     (history state, temporal table)
    → Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule     (CP-to-Rule current)
    → Dealing_staging.External_Etoro_History_CompoundPropertyToRule (CP-to-Rule history)
        → SP_CEPDailyAudit(@Date)
            → DELETE/INSERT Dealing_CEPDailyAudit_CP          (this table)
            → DELETE/INSERT Dealing_CEPDailyAudit_Rules
            → DELETE/INSERT Dealing_CEPDailyAudit_Conditions
            → DELETE/INSERT Dealing_CEPDailyAudit_ConditionToCP
            → DELETE/INSERT Dealing_CEPDailyAudit_CPToRule
            → DELETE/INSERT Dealing_CEPDailyAudit_NameLists
            → DELETE/INSERT Dealing_CEPDailyAudit_ListCIDMapping
```

## Production Source

| Attribute | Value |
|-----------|-------|
| Generic Pipeline mapping | Not found — CEP internal system, not a lake-ingested table |
| Source system | CEP (Client Execution Platform) — eToro's internal hedging rule engine |
| Upstream wiki | None |
| Refresh frequency | Daily |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP @Date parameter | @Date | passthrough |
| RuleID | #Dim_CPtoRule temp | RuleID | LEFT JOIN on CompoundPropertyID |
| RuleName | #Dim_CPtoRule temp | RuleName | LEFT JOIN on CompoundPropertyID |
| CompoundPropertyID | #CPChangesFinal temp | CompoundPropertyID | passthrough |
| CPName | #CPChangesFinal temp | Name | passthrough |
| HedgeServerID | #Dim_CPtoRule temp | HedgeServerID | LEFT JOIN |
| TypeOfChange | #CPChangesFinal temp | TypeOfChange | ETL-computed (CASE logic on NameChange, RN, RN_Desc) |
| Comments | #CPChangesFinal temp | Comments | conditional: `CONCAT('Previous Name: ', PreviousName)` for Name Change; NULL otherwise |
| LoginName | External_Etoro_* temporal | AppLoginName + PreviousAppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_* temporal | SysStartTime / SysEndTime | passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata |

## Change Detection Logic

SP_CEPDailyAudit uses SQL Server temporal table history (`SysStartTime`, `SysEndTime`, `ValidFrom`) with `LAG()` window functions to detect:
- **Creation**: `RN=1 AND ChangeDate=@Date AND DATEDIFF(MINUTE,ValidFrom,ChangeTime)<=60`
- **Name change**: `NameChange=1 AND ChangeDate=@Date`
- **Deletion**: `RN_Desc=1 AND CAST(SysEndTime AS DATE)=@Date`
