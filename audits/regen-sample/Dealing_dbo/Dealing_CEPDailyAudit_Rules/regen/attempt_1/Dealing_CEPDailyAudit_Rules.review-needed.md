# Review Needed: Dealing_dbo.Dealing_CEPDailyAudit_Rules

## Summary

All 11 columns documented at Tier 2 (SP code). No Tier 1 inheritance possible — the upstream sources (`Dealing_staging.External_Etoro_CEP_Rules` and `External_Etoro_History_Rules`) have no wiki documentation. All column descriptions grounded in SP_CEPDailyAudit source code analysis.

## Items for Human Review

### 1. LoginName NULL byte padding
Sampled `LoginName` values contain trailing `\0` (NULL byte) characters, likely from a fixed-length field in the CEP source system. Confirm whether downstream consumers handle this or if a REPLACE/RTRIM should be applied at query time.

### 2. HedgeServerID semantics
The source column is `HedgeRuleActionTypeID` but is renamed to `HedgeServerID` in the SP. Confirm with Dealing team that this is indeed a hedge server identifier and not an action type ID with different semantics.

### 3. New Rule detection window
The SP uses `DATEDIFF(MINUTE, ValidFrom, ChangeTime) <= 60` to classify a rule as "New Rule" (vs a pre-existing rule with a first temporal record). Confirm this 60-minute window is intentional and sufficient.

### 4. No sentinel rows
Unlike sibling tables (e.g., `Dealing_CEPDailyAudit_CP`), this table has zero NULL `TypeOfChange` rows in production (0 out of 1,052). Confirm whether the SP intentionally omits sentinel rows for Rules, or if this is a difference in behavior.

### 5. Priority value semantics
Sampled data shows `Priority = -1` for some rules (e.g., RuleID 223). Confirm whether -1 has special meaning (disabled, lowest priority, etc.) or is a valid priority value.

## Tier Coverage

| Tier | Count | Percentage |
|------|-------|------------|
| Tier 1 | 0 | 0% |
| Tier 2 | 11 | 100% |
| Tier 3 | 0 | 0% |
| Tier 4 | 0 | 0% |

**Justification for 0 Tier 1**: The upstream staging tables (`External_Etoro_CEP_Rules`, `External_Etoro_History_Rules`) have no wiki documentation. The 6 upstream wikis in the bundle are sibling CEPDailyAudit tables (CP, Conditions, ConditionToCP, CPToRule, NameLists, ListCIDMapping) — peer objects in the same audit family, not upstream sources for this table's columns. All columns are either passthrough-with-rename from undocumented staging tables or ETL-computed by the SP, making Tier 2 the correct assignment.
