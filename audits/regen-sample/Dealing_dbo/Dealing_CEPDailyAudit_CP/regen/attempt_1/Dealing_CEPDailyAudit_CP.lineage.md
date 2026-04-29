# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_CP

## Source Objects

| # | Source Object | Type | Schema | Relationship |
|---|--------------|------|--------|--------------|
| 1 | Dealing_staging.External_Etoro_CEP_CompoundProperties | External Table | Dealing_staging | Current CP state (UNION into #CPLog) |
| 2 | Dealing_staging.External_Etoro_History_CompoundProperties | External Table | Dealing_staging | Temporal CP history (UNION into #CPLog) |
| 3 | Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule | External Table | Dealing_staging | Current CP-to-Rule mappings (feeds #Dim_CPtoRule) |
| 4 | Dealing_staging.External_Etoro_History_CompoundPropertyToRule | External Table | Dealing_staging | Temporal CP-to-Rule history (feeds #Dim_CPtoRule) |
| 5 | Dealing_staging.External_Etoro_CEP_Rules | External Table | Dealing_staging | Current rule definitions (feeds #RulesLog for rule name/server) |
| 6 | Dealing_staging.External_Etoro_History_Rules | External Table | Dealing_staging | Temporal rule history (feeds #RulesLog) |
| 7 | Dealing_dbo.SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Writer SP — DELETE + INSERT for @Date |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | Date | SP_CEPDailyAudit | @Date parameter | Direct assignment — business date for the SP run | Tier 2 |
| 2 | RuleID | #Dim_CPtoRule (← #CPToRule_Log + #RulesLog) | RuleID | LEFT JOIN on CompoundPropertyID; NULL when CP has no active rule mapping | Tier 2 |
| 3 | RuleName | #Dim_CPtoRule (← #RulesLog) | Name | LEFT JOIN; denormalized rule name from latest RulesLog state (RN_Desc=1) | Tier 2 |
| 4 | CompoundPropertyID | #CPChangesFinal (← #CPLog ← External_Etoro_*_CompoundProperties) | CompoundPropertyID | Passthrough from CP external/history tables | Tier 2 |
| 5 | CPName | #CPChangesFinal (← #CPLog) | Name | CP display name from compound properties source; aliased as CPName | Tier 2 |
| 6 | HedgeServerID | #Dim_CPtoRule (← #RulesLog) | HedgeServerID | LEFT JOIN via CP-to-rule dimension; originally HedgeRuleActionTypeID in rules | Tier 2 |
| 7 | TypeOfChange | SP_CEPDailyAudit | Derived | SP logic: 'New Compound Property' (RN=1, created within 60 min of ValidFrom), 'Name Change' (NameChange=1), 'Compound Property Deleted' (RN_Desc=1, SysEndTime cast to @Date) | Tier 2 |
| 8 | Comments | SP_CEPDailyAudit | Derived | NULL for New/Deleted; CONCAT('Previous Name: ', PreviousName) for Name Change | Tier 2 |
| 9 | LoginName | #CPChangesFinal (← #CPLog) | COALESCE(AppLoginName, PreviousAppLoginName) | CEP application user; COALESCE ensures attribution even on deletions | Tier 2 |
| 10 | ChangeTime | #CPChangesFinal (← #CPLog) | CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END | Source event timestamp — SysStartTime for active rows, SysEndTime for deleted rows | Tier 2 |
| 11 | UpdateDate | SP_CEPDailyAudit | GETDATE() | DWH load timestamp — ETL metadata, not business event time | Tier 2 |
