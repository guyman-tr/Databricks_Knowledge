# Review Needed: BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **Category column discarded**: The SP computes Category ('HighCompensationToDeposits Ratio' vs '>3DepositsLast24hrs') but does NOT insert it. Should this be added to the DDL for downstream consumers to distinguish qualification path?
2. **DepositAmount$24hrs is varchar(max)**: Stores numeric data (SUM of deposits) but DDL is varchar(max). Type mismatch — may cause issues for consumers expecting numeric type.
3. **Compensation$/Deposits$ is decimal(18,0)**: Rounded to integer, losing precision. A 75% ratio appears as 1 (same as 100%). Should be decimal(18,2) or float.
4. **No SP author or date**: Comment block is missing from the SP code. Who owns this?
5. **#ofCompensations computed but not inserted**: SP builds COUNT of compensations but does not store it.
6. **Atlassian search unavailable**: Could not verify business context for this monitoring table.
7. **UC Target not migrated**: This table has no generic pipeline mapping entry.

## Corrections Applied

- Column count corrected from batch assignment of 7 to actual DDL count of 12.
