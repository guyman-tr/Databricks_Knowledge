# Review Needed: eMoney_Tribe.SettlementsTransactions_RiskActions-236807

## Tier 3 Items Requiring Human Review

All 11 source-passthrough columns are classified as Tier 3 because no upstream wiki exists for `FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807`. Descriptions are grounded in DDL column names, SP usage patterns (SP_eMoney_Reconciliation_ETLs), and live data distribution evidence.

### Columns to Verify

| # | Column | Concern | Suggested Action |
|---|--------|---------|-----------------|
| 1 | @Id | Assumed to be the primary record GUID based on data evidence and index usage. Confirm this is the unique identifier in the Tribe source. | Verify with eMoney/Tribe team |
| 2 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Contains identical values to @Id in all sampled rows. Confirm whether this is always the case or if there are scenarios where they diverge. | Verify FK semantics with eMoney/Tribe team |
| 3 | NotifyCardholderBySendingTAIsNotification | Zero '1' values observed. Confirm whether this flag is active in the source system or deprecated. | Check with card-processing / risk team |
| 4 | ChangeAccountStatusToSuspended | Zero '1' values observed. Same concern as above. | Check with card-processing / risk team |
| 5 | RejectTransaction | Zero '1' values observed. Same concern as above. | Check with card-processing / risk team |
| 6 | ChangeAccountStatusToReceiveOnly | 34% empty-string rate and zero '1' values. Appears to be a recently added, unused flag. | Confirm if active in production risk engine |
| 7 | ChangeAccountStatusToSpendOnly | Same pattern as ChangeAccountStatusToReceiveOnly. | Confirm if active in production risk engine |

## Structural Notes

- **Duplicate index**: `ClusteredIndex_ST_236807` and `idx_236807_Id` are both NCIs on `@Id`. One may be redundant and could be dropped to save storage/maintenance.
- **No upstream wiki**: The `_no_upstream_found.txt` marker was present. If an upstream wiki for `FiatDwhDB.Tribe` is created in the future, this object should be re-documented with Tier 1 inheritance.
- **String-typed booleans**: All flag columns are `varchar(max)` storing '0'/'1'/'' values. A schema optimization to `bit` or `tinyint` would be more efficient but would require coordination with the source system.

## Questions for Domain Expert

1. What risk engine or rules engine populates these flag columns in the source system?
2. Are `NotifyCardholderBySendingTAIsNotification`, `ChangeAccountStatusToSuspended`, and `RejectTransaction` actively used, or are they placeholder flags for future functionality?
3. Is the `@Id` = FK GUID identity pattern by design (sub-record shares parent ID), or does the FK column sometimes reference a different parent transaction?
