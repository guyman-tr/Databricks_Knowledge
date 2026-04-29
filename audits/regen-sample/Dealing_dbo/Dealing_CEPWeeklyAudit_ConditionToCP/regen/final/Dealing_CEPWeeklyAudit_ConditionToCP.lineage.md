# Lineage — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

## Source Objects

| # | Source Object | Type | Schema | Relationship |
|---|--------------|------|--------|--------------|
| 1 | `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | External Table | Dealing_staging | Current condition-to-CP mappings |
| 2 | `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | External Table | Dealing_staging | Temporal history of condition-to-CP mappings |
| 3 | `Dealing_staging.External_Etoro_History_CompoundProperties` | External Table | Dealing_staging | CP history (for CP_Name resolution) |
| 4 | `Dealing_staging.External_Etoro_CEP_CompoundProperties` | External Table | Dealing_staging | Current CPs (for CP_Name resolution) |
| 5 | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | External Table | Dealing_staging | CP-to-rule mappings (for rule context) |
| 6 | `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | External Table | Dealing_staging | CP-to-rule history (for rule context) |
| 7 | `Dealing_staging.External_Etoro_CEP_Rules` | External Table | Dealing_staging | Rule definitions (for RuleName, HedgeServerID) |
| 8 | `Dealing_staging.External_Etoro_History_Rules` | External Table | Dealing_staging | Rule history (for RuleName, HedgeServerID) |
| 9 | `Dealing_dbo.SP_W_CEPWeeklyAudit` | Stored Procedure | Dealing_dbo | Writer SP — weekly audit load |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | FromDate | SP_W_CEPWeeklyAudit | @weekStart parameter | `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` — Monday of the audit week | Tier 2 |
| 2 | ToDate | SP_W_CEPWeeklyAudit | @weekEnd parameter | `DATEADD(DAY,6,@weekStart)` — Sunday of the audit week | Tier 2 |
| 3 | RuleID | #Dim_CPtoRule ← #CPToRule_Log ← External_Etoro_CEP/History_CompoundPropertyToRule | RuleID | Passthrough via CP→Rule dimension join on CompoundPropertyID; NULL when CP has no rule mapping | Tier 2 |
| 4 | RuleName | #Dim_CPtoRule ← #RulesLog ← External_Etoro_CEP/History_Rules | Name | Denormalized rule name from latest rule record (RN_Desc=1) | Tier 2 |
| 5 | HedgeServerID | #Dim_CPtoRule ← #RulesLog ← External_Etoro_CEP/History_Rules | HedgeRuleActionTypeID | Passthrough via CP→Rule dimension join | Tier 2 |
| 6 | CompoundPropertyID | #ConditionToCP_Log ← External_Etoro_CEP/History_ConditionToCompoundProperty | CompoundPropertyID | Direct passthrough from source | Tier 2 |
| 7 | CP_Name | #ConditionToCP_Log ← #CPLog ← External_Etoro_CEP/History_CompoundProperties | Name | CP display name resolved via JOIN on CompoundPropertyID (latest record, RN_Desc=1) | Tier 2 |
| 8 | ConditionID | #ConditionToCP_Log ← External_Etoro_CEP/History_ConditionToCompoundProperty | ConditionID | Direct passthrough from source | Tier 2 |
| 9 | TypeOfChange | SP_W_CEPWeeklyAudit | — | SP-derived: `'Condition Added To CP'` when SysStartTime in week; `'Condition Removed from CP'` when SysEndTime in week; NULL for placeholder rows | Tier 2 |
| 10 | LoginName | #ConditionToCP_Log ← External_Etoro_CEP/History_ConditionToCompoundProperty | AppLoginName | Direct passthrough (column rename only) | Tier 2 |
| 11 | ChangeTime | #ConditionToCP_Log ← External_Etoro_CEP/History_ConditionToCompoundProperty | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for removes | Tier 2 |
| 12 | UpdateDate | SP_W_CEPWeeklyAudit | GETDATE() | Row load timestamp — ETL metadata | Tier 4 |
