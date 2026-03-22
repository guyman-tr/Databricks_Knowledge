# Review: Dealing_dbo.Dealing_IndiciesIntraHour_Clients

## Unverified Claims
1. **Instruments 27, 28, 32**: Mapped to SPX500, DJ30, NSDQ100 — confirm these InstrumentIDs
2. **Forward-fill 5 days**: The 5-day lookback covers weekends but may be insufficient for long holidays

## Questions for Domain Expert
1. Are these the only indices monitored at minute resolution, or do other tables cover commodities/FX?
2. The VolumeBuy includes both new longs opened AND shorts closed — is this intentional?
3. How is this table consumed — by dealing desk dashboards or automated monitoring?

## Reviewer Corrections
_(none yet)_
