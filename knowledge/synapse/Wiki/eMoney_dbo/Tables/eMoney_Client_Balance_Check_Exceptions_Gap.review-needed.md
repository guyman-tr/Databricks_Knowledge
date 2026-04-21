# Review Needed — eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

Generated: 2026-04-21 | Reviewer: Data Engineering / eTM Finance Team

## Tier 4 Items (Requires Verification)

None — all 3 columns are Tier 2 sourced directly from SP_eMoney_Client_Balance_Check_Exceptions_Gap code.

## Open Questions

1. **Is the SP still being called?** SP_eMoney_ClientBalance calls this SP at the end of its run (lines 1002-1003). However, since Execute_Group_One had all SPs commented out in 2023-10-30, confirm whether SP_eMoney_ClientBalance is still scheduled independently or if this check has also been suspended.

2. **Table currently empty**: The table has 0 rows as of 2026-04-21. Is this because:
   - (a) The balance check has been passing consistently (no exceptions), OR
   - (b) The SP is no longer being called (suspended)?
   Verification needed: check if SP_eMoney_ClientBalance runs in any ADF/Synapse pipeline.

3. **Intended frequency**: The SP accepts a `@Date` parameter — is it run daily as part of SP_eMoney_ClientBalance, or is it an ad-hoc on-demand check? The comment in SP_eMoney_ClientBalance suggests it runs as the "eMoney CB Alerts" step.

4. **Historical data**: Since the table is TRUNCATE+INSERT, no history of past exceptions is retained. Was historical data ever needed? If so, a separate history/log table should be considered.

## Reviewer Corrections

*[To be filled by reviewer]*

## Flagged Risks

- `CheckCalc` formula documentation is inferred from SP_eMoney_ClientBalance code; the exact meaning of each component (ClosingPositiveBalanceCalc, ClosingNegativeBalanceBO, ClosingBalanceBO) should be verified with the eTM finance/data team.
