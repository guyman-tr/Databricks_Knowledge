# Review: Dealing_dbo.Dealing_NOPDistribution

## Unverified Claims
1. **~200K rows/day**: Based on SR-224145 note — confirm current daily row count after MirrorID removal
2. **GuruStatusName values**: Assumed standard PI tiers — confirm complete list

## Questions for Domain Expert
1. Is this table used by the dealing desk for monitoring PI concentration risk?
2. Does the CopyFund bypass of IsValidCustomer=1 mean defunct CopyFunds still appear?
3. Are there downstream dashboards consuming this 382M-row table?

## Reviewer Corrections
_(none yet)_
