# Review Needed — Dealing_Staking_Parameters_US

## Open Questions

1. **WelcomeEmail_StartDate = 2026-08-19 for ADA/ETH/SOL**: This date is in the future (as of 2026-03-21), meaning welcome email notifications for the first three instruments have not activated. Confirm whether this date is intentional (a scheduled activation) or a placeholder not yet updated.

2. **SUI Distribution_StartDate = 2026-04-01**: SUI is the only instrument with a future distribution start date. Confirm whether SP_Staking_US will automatically begin producing SUI distribution rows once this date passes, or whether a manual configuration change is needed.

3. **IntroDays variance**: ETH IntroDays=60 is significantly stricter than ADA=9/SOL=7/SUI=7. Confirm whether this is a regulatory requirement (e.g., SEC/FINRA) or eToro's internal risk policy, and whether ETH IntroDays may be relaxed in the future.

4. **SOL LiquidityBuffer = 0.80**: SOL has the lowest buffer (80%), meaning eToro retains a 20% liquidity reserve. Confirm whether this reflects higher SOL unstaking risk/latency on the blockchain vs ADA/SUI (which use 90%).

5. **Add new instruments**: When a new instrument is added to US staking, confirm the process: is a new row inserted manually into this table first, then SP_Staking_DailyPool_US and SP_Staking_US pick it up automatically, or is there additional SP configuration required?
