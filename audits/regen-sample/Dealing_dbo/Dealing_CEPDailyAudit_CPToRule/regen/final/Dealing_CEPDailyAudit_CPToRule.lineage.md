# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

## Source Objects

| # | Source Object | Type | Role | Wiki |
|---|--------------|------|------|------|
| 1 | Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule | External table | Current CP-to-Rule mappings | — |
| 2 | Dealing_staging.External_Etoro_History_CompoundPropertyToRule | External table | Temporal history of CP-to-Rule mappings | — |
| 3 | Dealing_staging.External_Etoro_CEP_CompoundProperties | External table | CP names (via #CPLog) | — |
| 4 | Dealing_staging.External_Etoro_History_CompoundProperties | External table | CP history (via #CPLog) | — |
| 5 | Dealing_staging.External_Etoro_CEP_Rules | External table | Rule names / HedgeServerID (via #RulesLog → #Dim_CPtoRule) | — |
| 6 | Dealing_staging.External_Etoro_History_Rules | External table | Rule history (via #RulesLog) | — |
| 7 | Dealing_dbo.SP_CEPDailyAudit | Stored Procedure | Writer SP — DELETE+INSERT for @Date | SSDT |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | Date | SP parameter | @Date | Direct assignment | Tier 2 — SP_CEPDailyAudit |
| 2 | RuleID | External_Etoro_CEP_CompoundPropertyToRule | RuleID | Passthrough via #CPToRule_Log | Tier 2 — SP_CEPDailyAudit |
| 3 | RuleName | External_Etoro_CEP_Rules / History_Rules | Name | Resolved via #RulesLog → #Dim_CPtoRule (latest state by RN_Desc=1) | Tier 2 — SP_CEPDailyAudit |
| 4 | HedgeServerID | External_Etoro_CEP_Rules / History_Rules | HedgeRuleActionTypeID | Resolved via #RulesLog → #Dim_CPtoRule (latest state by RN_Desc=1) | Tier 2 — SP_CEPDailyAudit |
| 5 | CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule | CompoundPropertyID | Passthrough via #CPToRule_Log | Tier 2 — SP_CEPDailyAudit |
| 6 | CP_Name | External_Etoro_CEP_CompoundProperties / History | Name | Resolved via #CPLog (latest state by RN_Desc=1) | Tier 2 — SP_CEPDailyAudit |
| 7 | IsTrue | External_Etoro_CEP_CompoundPropertyToRule | Value | Passthrough via #CPToRule_Log.Value → #CPToRule_ChangesFinal.IsTrue | Tier 2 — SP_CEPDailyAudit |
| 8 | TypeOfChange | SP logic | — | CASE: RN=1+SysStartDate=@Date → 'CP Added to Rule'; RN>1+Value≠PreviousValue → 'Mapping Changed from [Not] True to [Not] True'; SysEndDate=@Date → 'CP Removed from Rule' | Tier 2 — SP_CEPDailyAudit |
| 9 | LoginName | External_Etoro_CEP_CompoundPropertyToRule / History | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) via LEAD() | Tier 2 — SP_CEPDailyAudit |
| 10 | ChangeTime | External_Etoro_CEP_CompoundPropertyToRule / History | SysStartTime / SysEndTime | SysStartTime for adds/value changes; SysEndTime for removals | Tier 2 — SP_CEPDailyAudit |
| 11 | UpdateDate | SP logic | GETDATE() | ETL metadata timestamp | Tier 2 — SP_CEPDailyAudit |
