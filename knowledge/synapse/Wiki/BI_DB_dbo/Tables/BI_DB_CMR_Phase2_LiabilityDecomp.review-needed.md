# Review Notes — BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp

**Batch**: 60 | **Date**: 2026-04-23 | **Status**: Ready for SME review

## Items for SME Review

1. **'Closing Balace' typo**: ExcelOrder=3 metric is named 'Closing Balace' (missing 'n') — same typo as in ClientBalance table. Confirm this matches the downstream Excel column heading.

2. **Commented-out PlayerStatus filter**: The SP contains `-- AND PlayerStatus in ('Blocked', 'Blocked Upon Request', 'Pending Verification', 'Block Deposit & Trading')`. This was presumably the original intent (restricted to non-normal statuses), but is now commented out, resulting in all 9 PlayerStatus values being included. Confirm the current behavior (all statuses) is intentional for the CMR liability section.

3. **Regulation scope excludes FCA**: FCA, FinCEN, eToroUS, and other regulations are excluded from this table. Confirm whether EU liability under FCA is captured elsewhere in the CMR Phase 2 framework, or intentionally omitted.

4. **Metrics 2, 5, 7, 9 sign**: The "Negative*" metrics (NegativeTotalLiability, NegativeWithdrawableLiability, NegativeLiabilityInUsedMargin, NegativeInProcessCashout) represent deficit or negative balance components. Confirm whether these are stored as negative values (matching the sign from source) or as positive values representing the absolute negative amount.

5. **Row count vs theoretical max**: Live data shows 423,009 rows across 1,218 distinct dates (2022-01-01 to 2026-04-12). Theoretical max is 9 × 6 × 9 × 1,218 ≈ 591K. The shortfall (~28%) indicates sparse Regulation × PlayerStatus combinations (zero-balance segments are omitted). Confirm whether the ISNULL(SUM(col), 0) = 0 rows are intentionally dropped from the INSERT or filtered by the outer WHERE clause.

6. **NegativeLiabilityInUsedMargin sign**: Live data shows ExcelOrder=7 (NegativeLiabilityInUsedMargin) has positive MetricValues (e.g., $26.9K total on 2026-04-12), unlike metrics 2 and 5 which are stored as negative values. Confirm whether this column is stored as a positive absolute value in the CBCAN source, and whether it should be negated before use in calculations.
