---
object: Dealing_CEPDailyAudit_CPToRule
schema: Dealing_dbo
lineage_type: internal_cep
documented: 2026-03-21
---

# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

## Source Classification

**No Generic Pipeline mapping** — this table is sourced from the CEP (Client Execution Platform) internal system, not the eToro production trading database lake pipeline.

## ETL Flow

```
[CEP System — CompoundPropertyToRule temporal table]
    ↓ (SQL Server temporal / system-time versioning)
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule  (current state external table)
Dealing_staging.External_Etoro_History_CompoundPropertyToRule  (history external table)
    ↓
SP_CEPDailyAudit(@Date)
    — LAG() window function detects state transitions
    — classifies events: Added, Removed, IsTrue toggle
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_CPToRule  ← DELETE + INSERT for @Date
```

## Key Lineage Facts

| Attribute | Value |
|-----------|-------|
| **Production source** | CEP internal system (CompoundPropertyToRule temporal table) |
| **Staging layer** | `Dealing_staging.External_Etoro_CEP_*` + `External_Etoro_History_*` |
| **Writer SP** | `Dealing_dbo.SP_CEPDailyAudit` |
| **Load pattern** | DELETE+INSERT per day — idempotent daily refresh |
| **Generic Pipeline** | Not applicable |
| **Upstream DWH wiki** | None |

## Column Lineage

| DWH Column | Source Column | Source Table |
|-----------|--------------|-------------|
| Date | @Date parameter | SP parameter |
| RuleID | RuleID | External_Etoro_CEP_CompoundPropertyToRule |
| RuleName | Name | #RulesLog (from CEP_Rules / History_Rules) |
| HedgeServerID | HedgeRuleActionTypeID | #RulesLog |
| CompoundPropertyID | CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule |
| CP_Name | Name | #CPLog (from CEP_CompoundProperties / History_CompoundProperties) |
| IsTrue | Value | External_Etoro_CEP_CompoundPropertyToRule |
| TypeOfChange | Derived | SP logic (RN=1 → Added; RN_Desc=1 + SysEndTime → Removed; Value change → toggle) |
| LoginName | COALESCE(AppLoginName, PreviousAppLoginName) | External_Etoro_CEP_CompoundPropertyToRule |
| ChangeTime | SysStartTime / SysEndTime | External_Etoro_CEP_CompoundPropertyToRule |
| UpdateDate | GETDATE() | SP execution time |
