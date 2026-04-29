# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

## Source Objects

| # | Source Object | Type | Schema | Relationship |
|---|---------------|------|--------|--------------|
| 1 | `Dealing_staging.External_Etoro_CEP_Conditions` | External Table | Dealing_staging | Current-state condition definitions (ConditionID, PropertyID, OperatorID, Value, AppLoginName, SysStartTime, SysEndTime) |
| 2 | `Dealing_staging.External_Etoro_History_Conditions` | External Table | Dealing_staging | Temporal history of condition definitions |
| 3 | `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | External Table | Dealing_staging | Dictionary: PropertyID → Property name |
| 4 | `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | External Table | Dealing_staging | Dictionary: OperatorID → Operator name |
| 5 | `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | External Table | Dealing_staging | Condition-to-CP mapping (used to resolve rule context via CP→Rule chain) |
| 6 | `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | External Table | Dealing_staging | Temporal history of condition-to-CP mapping |
| 7 | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | External Table | Dealing_staging | CP-to-Rule mapping (used to resolve RuleID/RuleName/HedgeServerID) |
| 8 | `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | External Table | Dealing_staging | Temporal history of CP-to-Rule mapping |
| 9 | `Dealing_staging.External_Etoro_CEP_Rules` | External Table | Dealing_staging | Rule definitions (RuleID, Name, HedgeRuleActionTypeID) |
| 10 | `Dealing_staging.External_Etoro_History_Rules` | External Table | Dealing_staging | Temporal history of rule definitions |
| 11 | `Dealing_dbo.SP_W_CEPWeeklyAudit` | Stored Procedure | Dealing_dbo | Writer SP — weekly audit ETL |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|---------------|------------------|------------------|-----------|------|
| 1 | FromDate | SP_W_CEPWeeklyAudit | @weekStart parameter | Computed: `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` — Monday of the audit week | Tier 2 |
| 2 | ToDate | SP_W_CEPWeeklyAudit | @weekEnd parameter | Computed: `DATEADD(DAY,6,@weekStart)` — Sunday of the audit week | Tier 2 |
| 3 | RuleID | #Dim_ConditionRule → #Dim_CPtoRule → #CPToRule_Log → #RulesLog | External_Etoro_CEP_CompoundPropertyToRule.RuleID | Resolved via chain: Condition → ConditionToCP_Log (CompoundPropertyID) → Dim_CPtoRule → RulesLog; LEFT JOIN means NULL when condition has no CP/rule association | Tier 2 |
| 4 | RuleName | #Dim_ConditionRule → #Dim_CPtoRule → #RulesLog | External_Etoro_CEP_Rules.Name | Denormalized rule name from the same chain as RuleID; uses latest name (RN_Desc=1) | Tier 2 |
| 5 | HedgeServerID | #Dim_ConditionRule → #Dim_CPtoRule → #RulesLog | External_Etoro_CEP_Rules.HedgeRuleActionTypeID | Aliased as HedgeServerID in #RulesLog; resolved via same chain as RuleID | Tier 2 |
| 6 | ConditionID | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_CEP_Conditions.ConditionID | Passthrough from source conditions; NULL on no-change placeholder rows (LEFT JOIN to #FromDateToDate) | Tier 2 |
| 7 | Property | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_Dictionary_ConditionProperties.Name | Dictionary lookup: JOIN on PropertyID; resolved name of the condition property | Tier 2 |
| 8 | Operator | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_Dictionary_ConditionOperators.Name | Dictionary lookup: JOIN on OperatorID; resolved name of the comparison operator | Tier 2 |
| 9 | Value | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_CEP_Conditions.Value | Passthrough — the condition's threshold or match value; for Value Change events, holds the new value | Tier 2 |
| 10 | TypeOfChange | #Conditions_ChangesFinal | SP derivation | SP-derived classification: `Property Change` (Property!=PreviousProperty), `Operator Change`, `Value Change`, `New Condition` (RN=1 within week), `Condition Deleted` (SysEndTime in week AND RN_Desc=1); NULL for no-change placeholders | Tier 2 |
| 11 | Comments | #Conditions_ChangesFinal | SP derivation | CONCAT pattern: `Previous Property: {old}`, `Previous Operator: {old}`, `Previous Value: {old}`; NULL for New Condition, Condition Deleted, and placeholder rows | Tier 2 |
| 12 | LoginName | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_CEP_Conditions.AppLoginName | Passthrough of the application login from source conditions | Tier 2 |
| 13 | ChangeTime | #Conditions_ChangesFinal → #Conditions_Log | External_Etoro_CEP_Conditions.SysStartTime / SysEndTime | SysStartTime for change events (Property/Operator/Value/New); SysEndTime for Condition Deleted events | Tier 2 |
| 14 | UpdateDate | SP_W_CEPWeeklyAudit | GETDATE() | DWH row insert timestamp — not a business event time | Tier 4 |
