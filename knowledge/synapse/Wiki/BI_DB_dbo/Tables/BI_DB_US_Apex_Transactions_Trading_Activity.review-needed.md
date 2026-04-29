# BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity — Review Needed

## Questions for Reviewer

1. **"ProccessDate" typo**: Triple 'c' in column name. DDL issue — should this be corrected via ALTER?
2. **Missing in Apex (5%)**: 131K rows exist in eToro but not in Apex SOD 872. Is this expected (e.g., trades not yet reported by Apex) or a reconciliation issue?
3. **ClosePositionReasonID != 10 exclusion**: Close-side excludes reason 10 (system close). These are handled separately in the Stocks_Activity reconciliation — confirm this is intentional.
4. **AmountEtoro for closes**: Calculated as Amount + NetProfit — confirm this represents the net settlement value, not the original investment amount.
5. **Club enrichment**: The INNER JOIN to Fact_SnapshotCustomer means "Missing in eToro" rows with no CIDEtoro are excluded from the final insert. Is this intentional?
