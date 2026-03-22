# Review Needed — Dealing_dbo.Dealing_Staking_Club_US

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 8.0/10

## Open Questions

1. **Why COLUMNSTORE vs CLUSTERED INDEX?** The non-US table uses a CLUSTERED INDEX on StakingMonthID while this US table uses COLUMNSTORE. Was this intentional (analytical workload difference) or an oversight?

2. **US currency roadmap**: Will additional cryptocurrencies (DOT, POL, ATOM, etc.) be added to the US staking program? The current 3-coin US scope (ADA, SOL, ETH) is much narrower than the 9-coin global program.

3. **US eligibility definition**: RegulationID 6, 7, 8 are used to identify US clients per SP_Staking_US — confirm these map to US regulations only (not other North American regulations).
