# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_CP

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream wikis exist for staging sources (External_Etoro_*_CompoundProperties) |
| Tier 2 | 11 | All columns traced to SP_CEPDailyAudit logic and staging sources |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Items for Human Review

### 1. UpdateDate — Tier 2 vs Tier 4

**Status**: Assigned **Tier 2** based on SP code analysis (`GETDATE()` call in the INSERT statement). Sibling tables (Rules, Conditions, CPToRule, etc.) all mark `UpdateDate` as `Tier 4 — inferred`. However, the SP code clearly shows `GETDATE()` as the last column in the CP INSERT — this is verifiable from source, making Tier 2 appropriate. Reviewer may choose to align with sibling convention if desired.

### 2. LoginName trailing null bytes

**Observation**: Sampled data shows `LoginName` values with trailing `\u0000` null byte padding (e.g., `charilaosch` followed by ~117 null bytes). This is a source system artifact from the `varchar(max)` column in the CEP temporal tables. Downstream consumers should `RTRIM` or strip null characters when comparing or displaying login names.

### 3. NULL rule context (30% of rows)

**Observation**: 314 of 1,034 rows have NULL `RuleID`, `RuleName`, and `HedgeServerID`. This is by design — the SP uses a `LEFT JOIN` to `#Dim_CPtoRule`, and CPs that are not mapped to any rule at the time of the event will have NULL rule context. This is expected behavior, not a data quality issue.

### 4. No Tier 1 coverage — justified

All columns in this table are either SP-computed (TypeOfChange, Comments, Date) or sourced from `Dealing_staging.External_Etoro_*` tables that have no wiki documentation. The 6 upstream wikis in the bundle are **sibling** audit tables in the same CEPDailyAudit family, not column-level sources for Tier 1 inheritance. Zero Tier 1 is correct.

---

*Generated: 2026-04-28 | Regen harness attempt 1*
