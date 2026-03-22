# Review Needed — Dealing_dbo.Dealing_Staking_DailyPool

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 8.0/10

## Open Questions

1. **Avg_DailyTotalStakingPool recomputation**: The average is computed from `#DailyPool` (in-memory snapshot of current month). Does this mean historical rows get overwritten with an updated average if SP runs again? If so, which downstream consumers rely on the average being accurate?

2. **EUR pairs**: ADAEUR and SOLEUR and ETHEUR represent EUR-denominated positions. Are these aggregated with their base coin equivalents in SP_Staking, or handled separately for reward calculation?

3. **Opted-out pipeline**: The same SP writes Dealing_Staking_OptedOut and Dealing_Staking_OptedOut_PerCID. Are these used for monitoring/dashboards by the Staking PM team?
