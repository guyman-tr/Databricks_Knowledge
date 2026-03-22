# Review Notes: Dealing_Best_Execution_Compensation_CBH

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 7.0

## Items Requiring Human Review

1. **⚠️ PIPELINE DECOMMISSION STATUS**: Max date is 2025-01-11. Confirm with Dealing team: (a) Was SP_Best_Execution officially decommissioned in January 2025? (b) Has compensation been handled by a different system since? (c) Were any client compensations outstanding at decommission? This is critical for compliance/audit trail purposes.

2. **Compensation formula**: The exact formula for `Compensation` was not fully read from the SP (SP is 3800+ lines). Confirm the compensation calculation logic — specifically: what is the `Compensation_Limit` value, under what conditions is `Compensation > 0`, and whether the formula changed in the 2024-09-03 update.

3. **CBH LP account identification**: How does the SP identify which positions are CBH vs HBC? Is it based on `HedgingType` from `Dealing_Daily_Latency_Compensation` or from `HedgingMode` in `Dealing_Daily_Slippage_Positions`? Confirm the classification logic.

4. **Percent_Diff formula**: Documented as `(CustomerChosenRate - LP_Rate) / LP_Rate` — confirm direction (positive = client paid more than LP market, negative = client got better than LP market?).

5. **PriceRateID = 0 rows**: The SP has special handling for `PriceRateID = 0` (rows where no price rate lookup is available). Confirm how these appear in the output — do they get LP_Rate = NULL?

6. **EU LP account selection**: EU instruments use specific LP account IDs (54, 127). Confirm these are still the correct EU LP accounts for CBH routing.

## Low-Confidence Fields

- **Compensation**: Exact formula not fully verified — only the overall structure was confirmed from partial SP read.
- **Compensation_Limit**: Value/formula for the cap not confirmed from SP analysis.
- **LP_Rate**: Bid vs Ask selection per IsBuy/IsOpen combination — general rule documented but exact implementation in SP not fully verified.
