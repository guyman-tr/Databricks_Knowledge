# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_Conditions

## Open Items

### 1. LoginName NUL byte padding
- **Severity**: Low
- **Detail**: Sampled `LoginName` values contain trailing NUL (`\x00`) bytes, likely from fixed-width `nchar` source columns. Consumers should apply `REPLACE(LoginName, CHAR(0), '')` or `RTRIM` when using this column in filters or display. Consider whether a cleanup step should be added to the SP.

### 2. Condition Deleted logic — edge case
- **Severity**: Medium
- **Detail**: The SP's `Condition Deleted` classification requires `RN=1 AND RN_Desc=1 AND SysStartDate=@Date` — this only captures conditions whose entire temporal history is a single row created on `@Date`. Conditions that existed across multiple temporal versions and were then deleted (SysEndTime closes on `@Date`) may not be captured by this specific UNION branch. Only 8 deletion events exist in the full dataset. Domain team should confirm whether all deletions are being captured or if the SP logic misses multi-version deletions.

### 3. UpdateDate — Tier 4 candidate
- **Severity**: Low
- **Detail**: `UpdateDate` is assigned `GETDATE()` in the SP. This is confirmed from the SP source code (line in the INSERT statement). Assigned Tier 2 rather than Tier 4 because the SP code is explicit. Sibling tables (Rules, CP, CPToRule, ConditionToCP, NameLists, ListCIDMapping) all mark this as Tier 4 — inferred. For consistency across the family, reviewer may wish to standardize the tier. We assigned Tier 2 because the SP code is the direct source and is readable.

### 4. Rule context NULL values
- **Severity**: Low
- **Detail**: `RuleID`, `RuleName`, `HedgeServerID` can be NULL when a condition belongs to a CP that is not currently mapped to any rule. This is a valid LEFT JOIN result from `#Dim_ConditionRule`. Analysts should be aware that NULL rule context does not mean the condition is orphaned — it may be in a CP awaiting rule assignment.

### 5. No upstream wiki for staging sources
- **Severity**: Info
- **Detail**: `Dealing_staging.External_Etoro_CEP_Conditions`, `External_Etoro_History_Conditions`, `External_Etoro_Dictionary_ConditionProperties`, and `External_Etoro_Dictionary_ConditionOperators` have no wiki documentation. All column descriptions are derived from SP code analysis (Tier 2). No Tier 1 inheritance is possible for this object — all columns are ETL-derived or SP-computed.
