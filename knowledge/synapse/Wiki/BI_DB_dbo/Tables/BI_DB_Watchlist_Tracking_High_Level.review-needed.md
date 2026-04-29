# BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Row count**: Placeholder — run `SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level` to populate the property table.
2. **LTV extreme outlier threshold**: The `Sum_8Y_LTV_NoExtreme` / `Count_8Y_LTV_NoExtreme` columns exclude extreme outliers. Confirm the threshold is defined in BI_DB_LTV_BI_Actual (percentile cutoff? absolute value?) and not re-applied in SP_Watchlist_Tracking.
3. **Revenue/Deposit 30-day source**: Are Sum_Revenue30days and Sum_Deposit30days sourced from BI_DB_CIDFirstDates directly, or from a separate revenue/deposit table joined via CID? The SP logic should clarify.
4. **Reg/FTD independence from Item Level**: Confirm that Reg and FTD counts are computed independently (direct cohort counts) and NOT derived from the Item Level table's Users_Traded columns.
5. **Aggregation correctness**: The FirstActions total is SUM(Users_TradedAsFirstAction) across items. Since a user's first action is exactly ONE item, this should equal the distinct count of users with a first action. Verify no double-counting occurs when users appear in both Instrument and User item types.
6. **Desk mapping consistency**: Confirm Desk is inherited from the Item Level table (same SP, same Dim_Country join) and not re-derived.
