# Review Notes — BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap

**Batch**: 60 | **Date**: 2026-04-23 | **Status**: Ready for SME review

## Items for SME Review

1. **SP naming inconsistency**: This table is written by `SP_CMR_Automation_Phase2_FinraGap` (includes 'Automation'), while all other CMR Phase 2 SPs follow the pattern `SP_CMR_Phase2_*`. Confirm this is deliberate and whether the 'Automation' designation has any operational significance.

2. **Regulation filter scope**: The SP filters `WHERE Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')` in the outer WHERE clause, but the effective target audience is FINRA-regulated US customers. Confirm whether eToroUS and FinCEN rows (without FINRA) are intentionally included, and whether they hold real stock positions via Apex.

3. **FinraGapBreakdownTotal formula**: Metric 7 contains a complex formula with a commented-out alternative. Confirm the current active formula is correct and the commented-out version is obsolete.

4. **DividendsPaid (metric 8) in gap calculation**: The formula for FinraGapBreakdownTotal has `+ 0 -- dividends adjusted in finra`. Confirm: does this mean DividendsPaid is intentionally excluded from the gap calculation (hence `+ 0`), and is metric 8 provided for informational context only?

5. **Row count expectation**: With a single regulation scope (FinCEN+FINRA), the table should have ~11 rows per date. Confirm whether the current ~17K rows (≈11 × ~1,560 days) is consistent with expectations.
