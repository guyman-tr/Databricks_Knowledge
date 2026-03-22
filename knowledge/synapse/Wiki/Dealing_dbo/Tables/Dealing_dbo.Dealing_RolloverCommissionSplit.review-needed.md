# Review: Dealing_dbo.Dealing_RolloverCommissionSplit

## Unverified Claims
1. **5% annual rate**: Confirmed by SR-233814 but may have changed since — verify current rate
2. **Islamic detection via WeekendFeePrecentage=0**: Confirm this is still the canonical method
3. **Only InstrumentID 17 and 22**: Confirm no other instruments have been added

## Questions for Domain Expert
1. Why only NSDQ100 and SPX500? Are other instruments analyzed elsewhere?
2. Is the PureRO/PureEtoroFee split used for regulatory reporting or internal P&L attribution?
3. The SP has a `SELECT * FROM #UnitsCalculation` at the end — is this intentional debug output?

## Reviewer Corrections
_(none yet)_
