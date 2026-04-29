# Lineage: Dealing_dbo.Dealing_CEPDailyAudit_Rules

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|------------|--------|----------|-------------|
| 1 | External_Etoro_CEP_Rules | Table | Dealing_staging | Synapse | Current state of CEP rules |
| 2 | External_Etoro_History_Rules | Table | Dealing_staging | Synapse | Temporal history of CEP rules |
| 3 | SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Synapse | Writer SP — DELETE+INSERT per @Date |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|--------------|-----------|------|
| 1 | Date | SP_CEPDailyAudit | @Date parameter | Direct assignment from SP parameter | Tier 2 |
| 2 | RuleID | External_Etoro_CEP_Rules / History_Rules | RuleID | Passthrough via #RulesLog → #RulesAudit1 → #RuleChangesFinal | Tier 2 |
| 3 | RuleName | External_Etoro_CEP_Rules / History_Rules | Name | Column rename: Name → RuleName. Filtered WHERE Name <> ' ' | Tier 2 |
| 4 | Description | External_Etoro_CEP_Rules / History_Rules | Description | Passthrough via #RulesLog; change detection via LAG() | Tier 2 |
| 5 | HedgeServerID | External_Etoro_CEP_Rules / History_Rules | HedgeRuleActionTypeID | Column rename: HedgeRuleActionTypeID → HedgeServerID | Tier 2 |
| 6 | Priority | External_Etoro_CEP_Rules / History_Rules | Priority | Passthrough via #RulesLog; change detection via LAG() | Tier 2 |
| 7 | TypeOfChange | SP_CEPDailyAudit | — (computed) | UNION ALL of change detection branches: 'Name Change', 'Description Change', 'Activated', 'Deactivated', 'HedgeServerID Change', 'Priority Change', 'New Rule', 'Rule Deleted' | Tier 2 |
| 8 | Comments | SP_CEPDailyAudit | — (computed) | CONCAT('Previous {attr}: ', previous_value) for change events; NULL for New Rule, Rule Deleted, Activated, Deactivated | Tier 2 |
| 9 | LoginName | External_Etoro_CEP_Rules / History_Rules | AppLoginName, PreviousAppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) — captures identity even for deletion events | Tier 2 |
| 10 | ChangeTime | External_Etoro_CEP_Rules / History_Rules | SysStartTime / SysEndTime | SysStartTime for changes/creations; SysEndTime for Rule Deleted events | Tier 2 |
| 11 | UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL load timestamp — not business event time | Tier 2 |
