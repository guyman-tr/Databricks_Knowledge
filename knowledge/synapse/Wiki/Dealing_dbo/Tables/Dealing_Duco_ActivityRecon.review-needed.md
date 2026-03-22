# Review Notes: Dealing_Duco_ActivityRecon

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 8.5

## Items Requiring Human Review

1. **CUSIP source**: Same ambiguity as EODRecon — CUSIP source in the ActivityRecon context is unclear. It may come from the execution log or from a separate reference. Confirm.

2. **eToro_AvgRate formula**: Documented as "weighted average execution rate" but the exact weighting (units vs value) is not confirmed from SP inspection. Verify the rate aggregation formula in SP_DataForDuco for the activity path.

3. **Client_AvgRate formula**: Same uncertainty — is this the open/close rate from `Dim_Position`, or from `BI_DB_PositionPnL`? Confirm what rate is used for client-side averaging.

4. **DST handling**: SP_DataForDuco processes both ActivityRecon and EODRecon. Confirm whether Daylight Savings boundary adjustments (documented for SP_Apex_Recon) also apply here for the execution log date filtering.

5. **LiquidityAccountID for activity**: The activity recon uses `etoro_Hedge_ExecutionLog` which may have a different LP mapping than the netting table. Confirm the LP account mapping path for activity vs EOD.

6. **Atlassian context unavailable**: Any Jira tickets for the 2025-08-07 SP update should be reviewed to understand what changed — particularly if new instrument types or LP routing changes were introduced.

## Low-Confidence Fields

- **eToro_AvgRate and Client_AvgRate**: Aggregation formula inferred; exact SP logic not fully read.
- **CUSIP**: Same uncertainty as EODRecon.
