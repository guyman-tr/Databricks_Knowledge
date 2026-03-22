# Review Notes: Dealing_Daily_Slippage_Positions

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 7.0

## Items Requiring Human Review

1. **⚠️ PIPELINE DECOMMISSION STATUS**: Max date is 2025-01-11. Confirm with Dealing team: (a) Was SP_Slippage_Report officially decommissioned? (b) Was it replaced by a different system? (c) Are the ~498M historical rows still consumed by any active process?

2. **OverThreshold 0.5% threshold**: The threshold is `ABS(slippage%) >= 0.005` (0.5%). Confirm this threshold has not been changed — SR-266910 (2024-08-13) made significant changes to the slippage population logic.

3. **SR-266910 impact (2024-08-13)**: "Remove the Trigger columns, Adjust the population to match the approach used in the latency" — this last major change before the pipeline stopped may have significantly altered the row population. Confirm what changed and whether the historical rows before vs after this change are comparable.

4. **ClientViewRate NULL handling**: When `ClientViewRate IS NULL` (no EMS record), the SP uses price history from `PriceLog_History_CurrencyPrice`. Confirm this fallback is still valid after the switch to EMSOrders source.

5. **OpenOpen action type**: Added 2023-04-13. Confirm what OpenOpen represents (partial close and reopen? reopen after close?) and whether it should be treated differently from a regular Open for slippage analysis.

6. **slippage % vs SlippageInPips vs SlippageInDollar**: Three slippage measures with different semantics. Confirm which is the canonical measure for compensation decisions and whether all three are maintained consistently.

## Low-Confidence Fields

- **RequestID**: Mapped from `ClientRequestID` in EMS Orders — confirm the mapping is 1:1 and no truncation occurs given the bigint type.
- **OrigIsBuy vs IsBuy**: The SP has specific logic for when RequestID and ClientViewRate are both NULL to use OrigIsBuy instead of IsBuy. Confirm this edge case impacts row count significantly.
