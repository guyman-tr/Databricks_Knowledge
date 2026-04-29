# Lineage: Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

## Source Objects

| # | Source Object | Type | Relationship |
|---|--------------|------|-------------|
| 1 | Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule | External Table | Current CP-to-rule mappings (primary source for CPToRule events) |
| 2 | Dealing_staging.External_Etoro_History_CompoundPropertyToRule | External Table | Temporal history of CP-to-rule mappings |
| 3 | Dealing_staging.External_Etoro_History_CompoundProperties | External Table | CP history for name resolution via `#CPLog` |
| 4 | Dealing_staging.External_Etoro_CEP_CompoundProperties | External Table | Current CP state for name resolution via `#CPLog` |
| 5 | Dealing_staging.External_Etoro_CEP_Rules | External Table | Current rules for `#RulesLog` → `#Dim_CPtoRule` (RuleName, HedgeServerID) |
| 6 | Dealing_staging.External_Etoro_History_Rules | External Table | Rule history for `#RulesLog` → `#Dim_CPtoRule` |
| 7 | Dealing_dbo.SP_W_CEPWeeklyAudit | Stored Procedure | Writer SP — weekly DELETE+INSERT for the `(@weekStart, @weekEnd)` window |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform |
|---|--------------|-----------------|-----------------|-----------|
| 1 | FromDate | SP_W_CEPWeeklyAudit | `@weekStart` parameter | Computed: `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` — Monday of the audit week |
| 2 | ToDate | SP_W_CEPWeeklyAudit | `@weekEnd` parameter | Computed: `DATEADD(DAY,6,@weekStart)` — Sunday (Friday+1 day after Monday) |
| 3 | RuleID | External_Etoro_CEP_CompoundPropertyToRule / History | RuleID | Passthrough from `#CPToRule_Log` via `#CPToRule_ChangesFinal` |
| 4 | RuleName | External_Etoro_CEP_Rules / History (via `#RulesLog` → `#Dim_CPtoRule`) | Name | Denormalized: latest rule Name resolved via `#Dim_CPtoRule` JOIN on CompoundPropertyID |
| 5 | HedgeServerID | External_Etoro_CEP_Rules / History (via `#RulesLog` → `#Dim_CPtoRule`) | HedgeRuleActionTypeID | Denormalized: aliased from `HedgeRuleActionTypeID` in `#RulesLog`, resolved via `#Dim_CPtoRule` |
| 6 | CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule / History | CompoundPropertyID | Passthrough from `#CPToRule_Log` via `#CPToRule_ChangesFinal` |
| 7 | CP_Name | External_Etoro_History_CompoundProperties / CEP_CompoundProperties (via `#CPLog`) | Name | Denormalized: latest CP Name from `#CPLog` (RN_Desc=1), joined in `#CPToRule_Log` |
| 8 | IsTrue | External_Etoro_CEP_CompoundPropertyToRule / History | Value | Passthrough from `#CPToRule_Log.Value` aliased as `IsTrue` in `#CPToRule_ChangesFinal` |
| 9 | TypeOfChange | SP_W_CEPWeeklyAudit | — | SP-derived literal: `'CP Added to Rule'` (RN=1 + SysStartTime in week), `'Mapping Changed from Not True to True'` / `'Mapping Changed from True to Not True'` (Value changed, RN>1), `'CP Removed from Rule'` (RN_desc=1 + SysEndTime in week) |
| 10 | LoginName | External_Etoro_CEP_CompoundPropertyToRule / History | AppLoginName | Passthrough from `#CPToRule_Log.AppLoginName` via `#CPToRule_ChangesFinal` |
| 11 | ChangeTime | External_Etoro_CEP_CompoundPropertyToRule / History | SysStartTime / SysEndTime | `SysStartTime` for add and value-change events; `SysEndTime` for removal events |
| 12 | UpdateDate | SP_W_CEPWeeklyAudit | `GETDATE()` | ETL metadata — row insert timestamp at SP execution time |
