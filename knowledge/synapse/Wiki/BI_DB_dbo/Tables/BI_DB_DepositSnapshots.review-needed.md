# BI_DB_DepositSnapshots — Review Notes

**Generated**: 2026-04-22 | **Batch**: 23 | **Priority**: 20

---

## Tier 4 Items (Low Confidence — Needs Verification)

None. All 4 columns have confirmed sourcing from SP code analysis.

---

## Open Questions for Reviewers

1. **ActionTypeID=7 only**: SP_User_Segment_Snapshot filters exclusively on ActionTypeID=7 (standard deposit). ActionTypeID=38 (Affiliate Deposit), 43 (Reverse Deposit), and 44 (InternalDeposit) are excluded. Is this intentional? Do these alternative deposit types count toward DepositGroup thresholds in the business definition?

2. **No cumulative column**: This table stores daily deposit amounts, not running totals. Downstream consumers must SUM across all rows per CID to compute a lifetime deposit value. Is there a separate table that materializes the cumulative total, or is this always recomputed on-demand?

3. **NULL TotalDeposit rows**: TotalDeposit is declared `decimal(38,2) NULL`. Can SUM(Amount) for ActionTypeID=7 ever produce NULL? This would only occur if Amount is NULL for deposit events. Data observation: min=$0.03 in YTD 2026, zero_deposits=0 — no nulls observed in recent data, but the nullable DDL is a design question.

4. **HASH(CID) vs CLUSTERED(DateID, CID)**: Distribution on CID optimizes CID-filtered lookups (co-located with Dim_Customer), but date-range scans (e.g., WHERE DateID BETWEEN x AND y) require touching all distributions. The clustered index on (DateID, CID) helps ordering within each distribution node, but does not prevent cross-distribution reads on date scans. Is there a specific query pattern that influenced this distribution choice?

---

## Data Quality Observations

- **No direct deposit from History.Credit**: Data flows through Fact_CustomerAction (ActionTypeID=7), not directly from History.Credit. This means the snapshot reflects DWH load timing, not real-time deposit processing.
- **max=$10,000,000**: Single-day deposit of $10M observed in YTD 2026. This is likely a high-net-worth client or institutional transfer — not a data error. No capping logic in SP.
- **Grain is (DateID, CID)**: Each customer appears at most once per date (grouped by DateID, RealCID). If a customer deposits multiple times on the same day, amounts are summed into one row.

---

## Cross-Object Consistency Checks

- **CID description**: Copied verbatim from DWH_dbo.Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) ✓
