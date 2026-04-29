# Lineage — Dealing_dbo.Dealing_CEPDailyAudit_Conditions

## Source Objects

| # | Source Object | Type | Schema | Role |
|---|--------------|------|--------|------|
| 1 | Dealing_staging.External_Etoro_CEP_Conditions | External Table | Dealing_staging | Current condition definitions |
| 2 | Dealing_staging.External_Etoro_History_Conditions | External Table | Dealing_staging | Temporal history of condition definitions |
| 3 | Dealing_staging.External_Etoro_Dictionary_ConditionProperties | External Table | Dealing_staging | Property name dictionary (PropertyID → Name) |
| 4 | Dealing_staging.External_Etoro_Dictionary_ConditionOperators | External Table | Dealing_staging | Operator name dictionary (OperatorID → Name) |
| 5 | Dealing_dbo.SP_CEPDailyAudit | Stored Procedure | Dealing_dbo | Writer SP — DELETE + INSERT for @Date |
| 6 | #Dim_ConditionRule | Temp Table (SP) | — | Condition → CP → Rule resolution (RuleID, RuleName, HedgeServerID) |
| 7 | #Conditions_Log | Temp Table (SP) | — | LAG()-based change detection over conditions temporal union |
| 8 | #Conditions_ChangesFinal | Temp Table (SP) | — | Classified change events for @Date |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform |
|---|--------------|---------------|---------------|-----------|
| 1 | Date | SP_CEPDailyAudit | @Date parameter | Direct assignment — SP parameter value |
| 2 | RuleID | #Dim_ConditionRule | RuleID | LEFT JOIN on ConditionID — rule context for the condition |
| 3 | RuleName | #Dim_ConditionRule | RuleName | LEFT JOIN on ConditionID — denormalized rule name |
| 4 | HedgeServerID | #Dim_ConditionRule | HedgeServerID | LEFT JOIN on ConditionID — hedge server from rule |
| 5 | ConditionID | External_Etoro_CEP_Conditions + History | ConditionID | Passthrough from conditions temporal union |
| 6 | Property | External_Etoro_Dictionary_ConditionProperties | Name | JOIN on PropertyID — human-readable property name |
| 7 | Operator | External_Etoro_Dictionary_ConditionOperators | Name | JOIN on OperatorID — human-readable operator name |
| 8 | Value | External_Etoro_CEP_Conditions + History | Value | Passthrough — the condition's comparison value |
| 9 | TypeOfChange | SP_CEPDailyAudit | Derived | SP logic: Property Change, Operator Change, Value Change, New Condition, Condition Deleted |
| 10 | Comments | SP_CEPDailyAudit | Derived | CONCAT('Previous {X}: ', Previous{X}) for change events; NULL for new/deleted |
| 11 | LoginName | External_Etoro_CEP_Conditions + History | COALESCE(AppLoginName, PreviousAppLoginName) | COALESCE across temporal columns for user attribution |
| 12 | ChangeTime | External_Etoro_CEP_Conditions + History | SysStartTime / SysEndTime | SysStartTime for changes/new; SysEndTime for deletions |
| 13 | UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata timestamp |
