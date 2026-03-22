# Review Needed — Dealing_Staking_Summary_US

1. **IntroDays per instrument**: Confirm current values in Dealing_Staking_Parameters_US for ADA, ETH, SOL. The intro period changes the effective pool size significantly.

2. **EtoroYield formula**: `RewardsToDistribute × TotalStakingDays / MonthlyPool` — confirm this is the intended yield metric and that TotalStakingDays is the number of calendar days in the staking period.

3. **PercentUnutilized calculation**: Uses `UnutilizedUnits / EtoroUnits` (not / RewardsToDistribute). This is the same as the global Staking_Summary. Confirm this denominator is intentional (it means rounding residual as a fraction of eToro's share, not total rewards).

4. **Only 3 instruments**: US staking covers ADA, ETH, SOL as of Jan 2026. Confirm whether additional crypto assets are planned for the US program.
