# Review Needed — Dealing_dbo.Dealing_Staking_Club

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 8.0/10

## Open Questions

1. **Dashboard usage**: Is this table consumed directly by Tableau, or is it intermediated through a BI_DB view/table? The SP_Staking comments mention Tableau but no consumer view/SP referencing Dealing_Staking_Club was found in the SSDT repo.

2. **OpsDB gap**: SP_Staking → Dealing_Staking_Club is NOT tracked in OpsDB (only Staking_Results, Staking_Summary, Staking_Position appear). Is this intentional? If OpsDB monitoring is missing for this table, failures would not be auto-detected.

3. **Boundary interpolation accuracy**: The $1 USD threshold is computed from a pair of real clients straddling the boundary — it is an empirical measurement, not a derived formula. This means the threshold can vary slightly month-to-month even for the same currency/tier purely due to which client happens to be at the boundary. Is this expected behavior?

4. **SUI added recently**: SUI only has 2 months of data (since ~Jan 2026). The Dealing_Staking_Parameters table should have SUI configured — confirm IntroDays and LiquidityBuffer are correctly set.
