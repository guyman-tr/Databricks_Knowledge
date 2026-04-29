# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No direct upstream wiki inheritance — all columns are ETL-computed or SP-derived |
| Tier 2 | 11 | All columns traced to SP_CEPDailyAudit logic |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Items for Human Review

### 1. LoginName NULL Rate (~63%)

The high NULL rate for `LoginName` is unusual compared to sibling CEPDailyAudit tables. This may reflect:
- System-driven bulk mapping operations (no user attribution in temporal `AppLoginName`)
- A data quality issue in the CEP temporal tables for condition-to-CP mapping events

**Action**: Dealing team to confirm whether NULL `LoginName` on condition-to-CP mappings is expected or a data gap.

### 2. RuleID NULL Rate (~18%)

`RuleID`, `RuleName`, and `HedgeServerID` are NULL in ~1,216 of 6,604 rows. This is by design (LEFT JOIN to `#Dim_CPtoRule`), but it means ~18% of condition-to-CP changes cannot be attributed to a specific hedging rule.

**Action**: Confirm with Dealing team whether orphan CPs (not mapped to any rule) are expected in this volume.

### 3. Bursty Activity Pattern

2026-04-19 accounts for 5,052 of 6,604 total rows (76%) — a single bulk cleanup date dominates the dataset. This is not a data quality issue but should be noted for analysts interpreting aggregate statistics.

### 4. No Weekly Audit Counterpart Confirmed

The sibling tables (Rules, CP, CPToRule, Conditions, NameLists, ListCIDMapping) all have weekly counterparts. A `Dealing_CEPWeeklyAudit_ConditionToCP` table was not found in the SSDT repo. Confirm whether this weekly counterpart exists or is intentionally absent.

### 5. UpdateDate Tier Rationale

`UpdateDate` is assigned Tier 2 (not Tier 4) because the SP code explicitly shows `GETDATE()` in the INSERT statement. The column semantics are fully traceable from SP source.
