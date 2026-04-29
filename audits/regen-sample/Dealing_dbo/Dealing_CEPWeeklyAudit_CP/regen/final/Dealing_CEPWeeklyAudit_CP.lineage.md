# Lineage: Dealing_dbo.Dealing_CEPWeeklyAudit_CP

## Source Objects

| # | Source Object | Type | Schema | Role |
|---|--------------|------|--------|------|
| 1 | `Dealing_staging.External_Etoro_CEP_CompoundProperties` | External Table | Dealing_staging | Current-state CP definitions |
| 2 | `Dealing_staging.External_Etoro_History_CompoundProperties` | External Table | Dealing_staging | Temporal history of CP definitions |
| 3 | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | External Table | Dealing_staging | Current CP-to-rule mapping (rule context) |
| 4 | `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | External Table | Dealing_staging | Temporal history of CP-to-rule mapping |
| 5 | `Dealing_staging.External_Etoro_CEP_Rules` | External Table | Dealing_staging | Current rule definitions (RuleName, HedgeServerID) |
| 6 | `Dealing_staging.External_Etoro_History_Rules` | External Table | Dealing_staging | Temporal history of rule definitions |
| 7 | `Dealing_dbo.SP_W_CEPWeeklyAudit` | Stored Procedure | Dealing_dbo | Writer SP — weekly audit load |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | FromDate | SP_W_CEPWeeklyAudit | `@weekStart` parameter | `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` — Monday of the audit week | Tier 2 |
| 2 | ToDate | SP_W_CEPWeeklyAudit | `@weekEnd` parameter | `DATEADD(DAY,6,@weekStart)` — Sunday of the audit week | Tier 2 |
| 3 | RuleID | `#Dim_CPtoRule` ← `#CPToRule_Log` ← External_Etoro_CEP/History_CompoundPropertyToRule | `RuleID` | Passthrough via CP-to-rule dimension join on `CompoundPropertyID` | Tier 2 |
| 4 | RuleName | `#Dim_CPtoRule` ← `#RulesLog` ← External_Etoro_CEP/History_Rules | `Name` | Denormalized rule name from latest rule snapshot (`RN_Desc=1`) | Tier 2 |
| 5 | CompoundPropertyID | `#CPChangesFinal` ← `#CPLog` ← External_Etoro_CEP/History_CompoundProperties | `CompoundPropertyID` | Passthrough — identifies the CP that changed | Tier 2 |
| 6 | CPName | `#CPChangesFinal` ← `#CPLog` ← External_Etoro_CEP/History_CompoundProperties | `Name` | Passthrough aliased as `CPName` — CP display name at time of change | Tier 2 |
| 7 | HedgeServerID | `#Dim_CPtoRule` ← `#RulesLog` ← External_Etoro_CEP/History_Rules | `HedgeRuleActionTypeID` | Passthrough via rule dimension (aliased from `HedgeRuleActionTypeID`) | Tier 2 |
| 8 | TypeOfChange | SP_W_CEPWeeklyAudit | SP logic | Derived: `New Compound Property` (RN=1 + ValidFrom check), `Name Change` (NameChange flag), `Compound Property Deleted` (RN_Desc=1 + SysEndTime in week); NULL for no-change placeholder rows | Tier 2 |
| 9 | Comments | SP_W_CEPWeeklyAudit | SP logic | `CONCAT('Previous Name: ', PreviousName)` for name changes; NULL for new/deleted CPs | Tier 2 |
| 10 | LoginName | `#CPChangesFinal` ← `#CPLog` ← External_Etoro_CEP/History_CompoundProperties | `AppLoginName` | Passthrough — CEP application user | Tier 2 |
| 11 | ChangeTime | `#CPChangesFinal` ← `#CPLog` ← External_Etoro_CEP/History_CompoundProperties | `SysStartTime` / `SysEndTime` | `CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END` — event timestamp | Tier 2 |
| 12 | UpdateDate | SP_W_CEPWeeklyAudit | `GETDATE()` | DWH row insert timestamp — not business time | Tier 4 |
