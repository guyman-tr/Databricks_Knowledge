# Review Needed — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

## Tier 4 Items

| Column | Current Tier | Question |
|--------|-------------|----------|
| UpdateDate | Tier 4 | Standard `GETDATE()` ETL metadata — no action needed unless SP changes. |

## Data Quality Notes

### LoginName Null-Byte Padding

Live data sampling revealed that `LoginName` values contain **trailing null bytes** (e.g. `jasonha\0\0\0...` with ~121 trailing `\0` characters). This appears to be a fixed-width field artifact from the upstream `External_Etoro_CEP_Conditions.AppLoginName` column. Consumers should apply `RTRIM` or `REPLACE(LoginName, CHAR(0), '')` when displaying or comparing.

### Condition Deleted Detection Logic

The SP uses `WHERE RN = 1 AND SysEndTime BETWEEN @weekStart AND @weekEnd AND RN_Desc = 1` for deletion classification. The conjunction of `RN = 1` (first record) **AND** `RN_Desc = 1` (last record) means only **single-record conditions** — those with exactly one temporal history row — are captured as deletions. Conditions with multiple history rows whose final row ends in the week may not be classified as deleted. **Verify**: Is this intentional, or should the deletion path use only `RN_Desc = 1` (consistent with the Rules deletion path which uses `RN_Desc = 1` alone)?

### NULL RuleID on Non-Placeholder Rows

535 rows with non-null `TypeOfChange` have NULL `RuleID` / `RuleName` / `HedgeServerID`. This occurs when the condition's CP association or the CP's rule association cannot be resolved in the weekly snapshot (e.g. orphaned conditions, or CPs not mapped to any rule). This is a structural consequence of the LEFT JOIN chain and may be expected behavior.

## Upstream Source Notes

- All upstream sources (`Dealing_staging.External_Etoro_*`) are external/staging tables with **no wiki documentation**. Tier 1 inheritance is not applicable for this object.
- Dictionary tables (`External_Etoro_Dictionary_ConditionProperties`, `External_Etoro_Dictionary_ConditionOperators`) provide human-readable names but have no semantic wikis.

## No Further Review Items

All 14 columns are grounded in SP code analysis (Tier 2) or ETL metadata (Tier 4). No Tier 4-inferred columns exist.
