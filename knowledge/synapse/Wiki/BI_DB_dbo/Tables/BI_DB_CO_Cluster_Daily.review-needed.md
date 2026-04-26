# BI_DB_CO_Cluster_Daily — Review Notes

## Items Requiring Human Verification

### HIGH — Functional Impact

1. **ActionTypeID=8 is cashout, not redeem/airdrop**: The SP filters specifically for ActionTypeID=8 and documents this as a cashout (not a redeem, not an airdrop). Confirm with the DWH team that ActionTypeID=8 has never been repurposed or reused across eToro's transaction taxonomy, and that no other ActionTypeIDs need to be included for a complete cashout picture (e.g., if partial redeems or platform-specific COs have separate ActionTypeIDs).

2. **RealizedEquity_CO at last CO date, not today**: The equity used for cluster classification is pulled from V_Liabilities where DateID = Last_Transaction_ID (the customer's last CO date), not today's equity. A customer with high equity today but low equity on their last CO date will be assigned Churn_CO. Confirm with the business that this is the intended design — using CO-date equity rather than current equity for cluster assignment.

3. **Current_Day_CO_Amount is INT, not MONEY**: The DDL defines `Current_Day_CO_Amount` as `INT`. For customers with large cashouts (e.g., $50,000+), this value will be truncated at the integer boundary. `ACC_CO_AmountUSD` (money) is not affected. Confirm whether this is a known defect or intentional (e.g., amount in cents, or expected values are always < 2^31). Consider fixing the DDL type to `MONEY` or `BIGINT` if truncation is possible.

4. **Report_Date_ID defined as BIGINT but computed as INT**: The DDL defines `Report_Date_ID` as `bigint` while the SP computes it as `CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)`. A YYYYMMDD integer fits comfortably in INT range (max ~21000101), so no overflow risk, but the type mismatch (BIGINT column, INT expression) is inconsistent. Confirm whether this is intentional or a DDL oversight.

### MEDIUM — Data Quality / Coverage

5. **Table starts 2024-01-01 — no historical pre-2024 data**: The SP uses `ISNULL(MAX(Report_Date), '2024-01-01')` as the fallback start date, meaning the table intentionally has no data before 2024. Customers who cashed out only before 2024 are absent. Confirm whether pre-2024 backfill was considered and rejected, or whether a separate historical table exists for prior cashout patterns.

6. **Cluster rules use absolute thresholds not calibrated to customer segments**: The cluster boundaries ($10 equity, 360-day gap, 3/5 cashout counts) are hardcoded in the SP CASE statement. Confirm with the CRM or Retention team whether these thresholds have been reviewed recently and remain calibrated to the current customer base distribution. If customer behavior has shifted, the cluster proportions may have drifted from their intended segmentation ratios.

7. **Null_Equity cluster may mask data pipeline gaps**: A customer with RealizedEquity IS NULL lands in Null_Equity. This can occur if V_Liabilities has no row for their last CO DateID — either because V_Liabilities doesn't cover that date, or because the join logic has a gap. Confirm what percentage of rows have Null_Equity and whether it spikes on certain dates (which would indicate a V_Liabilities availability issue rather than a genuine data condition).

8. **Fact_SnapshotCustomer join scope**: The SP uses Fact_SnapshotCustomer to filter IsValidCustomer and map GCID → RealCID. Confirm what `IsValidCustomer=1` excludes — if test accounts, internal accounts, or fraud-flagged customers are excluded at this stage, downstream consumers need to know. If the filter is not applied, duplicate rows under different GCIDs for the same RealCID may appear.

### LOW — Documentation Gaps

9. **Occasional_CO boundary completeness**: The Occasional_CO conditions cover: (ACC_Cashouts >= 5 AND gap > 360d), (Seniority > 360 AND cashouts 2-4), (Seniority <= 360 AND cashouts = 2). However, a customer with Seniority <= 360, ACC_Cashouts = 4, equity >= 10, and gap > 360d does not match Regular_CO (cashouts < 5, seniority <= 360 but cashouts = 4 ≥ 3 → Regular_CO 4b does match). Verify the CASE statement has no gaps or overlaps by testing edge-case combinations manually, especially around ACC_Cashouts=3 and Seniority=360.

10. **UC migration**: This table has `UC Target: _Not_Migrated`. Confirm if migration is planned.
