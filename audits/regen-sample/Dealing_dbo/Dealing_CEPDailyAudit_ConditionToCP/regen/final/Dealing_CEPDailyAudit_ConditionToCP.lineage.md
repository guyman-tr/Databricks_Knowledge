# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|--------------|
| 1 | External_Etoro_CEP_ConditionToCompoundProperty | External Table | Dealing_staging | CEP (internal) | Current condition-to-CP mappings |
| 2 | External_Etoro_History_ConditionToCompoundProperty | External Table | Dealing_staging | CEP (internal) | Temporal history of condition-to-CP mappings |
| 3 | External_Etoro_History_CompoundProperties | External Table | Dealing_staging | CEP (internal) | Temporal history of CPs (for CP name resolution) |
| 4 | External_Etoro_CEP_CompoundProperties | External Table | Dealing_staging | CEP (internal) | Current CP state (for CP name resolution) |
| 5 | External_Etoro_CEP_CompoundPropertyToRule | External Table | Dealing_staging | CEP (internal) | Current CP-to-Rule mappings (for Rule resolution) |
| 6 | External_Etoro_History_CompoundPropertyToRule | External Table | Dealing_staging | CEP (internal) | Temporal history of CP-to-Rule mappings |
| 7 | External_Etoro_CEP_Rules | External Table | Dealing_staging | CEP (internal) | Current rule state (for RuleName, HedgeServerID) |
| 8 | External_Etoro_History_Rules | External Table | Dealing_staging | CEP (internal) | Temporal history of rules |
| 9 | SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Synapse | Writer SP — DELETE + INSERT for @Date |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform |
|---|--------------|-----------------|-----------------|-----------|
| 1 | Date | SP_CEPDailyAudit | @Date parameter | Direct assignment — SP parameter equals the business date |
| 2 | RuleID | #Dim_CPtoRule (via CPToRule_Log → RulesLog) | RuleID | LEFT JOIN on CompoundPropertyID; NULL when CP has no rule mapping |
| 3 | RuleName | #Dim_CPtoRule (via RulesLog) | Name | Denormalized from latest rule state; NULL when RuleID is NULL |
| 4 | HedgeServerID | #Dim_CPtoRule (via RulesLog) | HedgeRuleActionTypeID | Aliased as HedgeServerID; NULL when RuleID is NULL |
| 5 | CompoundPropertyID | External_Etoro_CEP_ConditionToCompoundProperty / History | CompoundPropertyID | Passthrough from staging temporal tables |
| 6 | CP_Name | #CPLog (latest by CompoundPropertyID) | Name | Latest CP name from UNION of current + history CPs |
| 7 | ConditionID | External_Etoro_CEP_ConditionToCompoundProperty / History | ConditionID | Passthrough from staging temporal tables |
| 8 | TypeOfChange | SP_CEPDailyAudit | — | SP-derived: 'Condition Added To CP' (SysStartDate = @Date) or 'Condition Removed from CP' (SysEndDate = @Date) |
| 9 | LoginName | External_Etoro_CEP_ConditionToCompoundProperty / History | AppLoginName, PreviousAppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) — captures actor even for removals |
| 10 | ChangeTime | External_Etoro_CEP_ConditionToCompoundProperty / History | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for removals |
| 11 | UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata timestamp at SP execution |
