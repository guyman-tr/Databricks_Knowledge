# Review Needed — Dealing_Staking_OptedOut_US

## Open Questions

1. **Breach threshold alerting**: The table documents `Units_AvailableForStaking = OptedInUnits × LiquidityBuffer`, but there is no visible alerting if this drops below a staking commitment threshold. Confirm whether Finance/Operations have a separate monitoring process or Power BI alert for this KPI.

2. **EligibleClients definition**: EligibleClients = OptedInClients + OptedOutClients. Confirm whether "eligible" means holding any position in the instrument (regardless of IntroDays), or only clients whose position already meets IntroDays. The SP_Staking_DailyPool_US scope is all position holders with FinCEN+FINRA regulation, not conditioned on IntroDays.

3. **SUI Distribution_StartDate = 2026-04-01**: SUI first appears in OptedOut_US from 2026-02-26. As of this writing (2026-03-21), SUI tracking is active but distributions have not started. Confirm the expected flow: will SUI rows appear in Results_US and Summary_US for the April 2026 distribution run?

4. **ETH LiquidityBuffer = 1.0**: ETH has a buffer of 1.0 (100% of opted-in units can be staked). This differs from ADA/SUI=0.9 and SOL=0.8. Confirm whether ETH's 1.0 buffer reflects a blockchain-level guarantee that ETH can always be unstaked without reserve, or another business decision.
