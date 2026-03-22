# Review: Dealing_dbo.Dealing_Max_NOP

## Unverified Claims
1. **Inactive since June 2024**: Last data is 2024-06-02 — confirm if the SP has been decommissioned or is just failing
2. **GBP pence (CurrencyID=666)**: Hardcoded `/100` conversion — confirm this special handling is still correct

## Questions for Domain Expert
1. Is this table deprecated? Should it be marked as inactive in documentation?
2. Was the hourly WHILE loop replaced by a more efficient approach elsewhere?
3. Does MAX_NOP_USD represent the max across ALL hours or a specific window?

## Reviewer Corrections
_(none yet)_
