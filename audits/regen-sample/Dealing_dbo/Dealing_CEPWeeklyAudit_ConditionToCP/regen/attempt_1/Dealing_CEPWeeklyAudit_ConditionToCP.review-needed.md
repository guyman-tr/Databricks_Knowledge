# Review Needed — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

## Tier 4 Items

| Column | Current Tier | Issue | Suggested Action |
|--------|-------------|-------|-----------------|
| UpdateDate | Tier 4 | `GETDATE()` — ETL metadata, no upstream source | Confirm this is acceptable as Tier 4 |

## Questions for Reviewer

1. **RuleID fan-out**: The SP joins `#Dim_CPtoRule` without dedup, so a single condition-to-CP event fans out across all rules sharing the CP. ~1,306 rows have NULL RuleID (CP not mapped to any rule). Is this the intended behavior, or should the wiki note a dedup recommendation?

2. **Asymmetry in event counts**: `Condition Removed from CP` (6,814) outnumbers `Condition Added To CP` (3,041) by ~2:1. This could indicate bulk condition reorganization events or rule engine cleanup. Reviewer should confirm this is expected business behavior.

3. **No daily counterpart wiki found**: `Dealing_CEPDailyAudit_ConditionToCP` is referenced as a daily sibling but no wiki was located in the bundle. When documented, cross-reference for consistency.

4. **Upstream sources unresolved**: All `Dealing_staging.External_Etoro_*` sources lack wikis. All 11 non-metadata columns are Tier 2 (SP code) rather than Tier 1. If staging table wikis are created in the future, re-evaluate tier assignments.

## Corrections Applied

- None — first attempt.
