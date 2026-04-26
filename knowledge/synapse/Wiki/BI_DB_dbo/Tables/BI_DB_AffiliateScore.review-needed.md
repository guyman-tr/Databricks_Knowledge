# Review Needed: BI_DB_dbo.BI_DB_AffiliateScore

**Generated**: 2026-04-23 | **Batch**: 56 | **Reviewer**: Pending

## Tier 4 Items (Low Confidence — Needs Confirmation)

None — all columns are Tier 1 (Dim_Affiliate wiki), Tier 2 (SP code), or Propagation.

## Open Questions

1. **SubChannelID IN (20, 31) semantics**: The FTD population is filtered to customers with SubChannelID in these two values. Confirm what these sub-channels represent (e.g., 20=Affiliate Partners, 31=Sub-Affiliate?). This filter defines which customers count as "affiliate-sourced FTDs" for scoring purposes.

2. **FTDs vs Cost_FTDs discrepancy**: `FTDs` counts customers from Dim_Customer with SubChannelID filter; `Cost_FTDs` is SUM(FTD) from BI_DB_MarketingMonthlyRawData. These may differ due to attribution methodology differences. Confirm whether the CPA denominator (Cost_FTDs) is the intended definition, and document when these two counts diverge.

3. **NULL ColorScore (1,296 rows, ~6%)**: These rows have ColorScore=NULL. The CASE expression returns NULL when none of the scoring conditions are met. Likely caused by division-by-zero protection (NULL CPA, zero AllClusters, or zero UsersEqu30d). Confirm the expected behavior and whether NULL should be treated as "unscored" or "insufficient data" in downstream reports.

4. **4-month backfill window**: The SP refreshes the last 4 months on every run. Confirm whether this window is intentional (to absorb late-arriving LTV, cluster, and cost updates) or a performance concern. Data for months 5+ in the past should be considered immutable.

5. **Revenue_30d source change (2024-07-01)**: Revenue_30d was switched from BI_DB_LTV_Actual to BI_DB_First5Actions (Revenue30days). Confirm whether historical rows (pre-July 2024) were backfilled with the new source or if there is a data discontinuity at that boundary.

6. **Lookback cohort alignment**: The 3M lookback uses `FTD BETWEEN @start3monthbefore AND @end3monthsbefore`, and the 9M LTV lookback uses `@start9monthbefore AND @end9monthsbefore`. Confirm whether "3 months before" means the 3-month window ending at the start of @YearMonth (i.e., months N-3 to N-1) or a different window.

## Known Issues / Notes

- Affiliates with SUM(TotalCost)=0 in BI_DB_MarketingMonthlyRawData are excluded from scoring (HAVING clause). These affiliates may have FTDs but no recorded cost — they will not appear in this table for that YearMonth.
- The table uses column names with special characters: `FirstActionStocks/ETF`, `LTV/CPA_Level`, `%Cluster_Equities_Investors_3M_Before`. These require bracket escaping in SQL queries.
- Fraction columns (ClusterEquitiesInvestors, FirstAction*) represent fractions (0.0–1.0), not percentages (0–100). Downstream reports should multiply by 100 for display.
- No upstream wiki available for BI_DB_First5Actions, BI_DB_LTV_BI_Actual, BI_DB_CID_DailyCluster, or BI_DB_MarketingMonthlyRawData; column semantics for those sources are inferred from SP code.

## Cross-Object Consistency Checks

| Column | Canonical Source | Check Status |
|--------|-----------------|-------------|
| AffiliateGroupName | DWH_dbo.Dim_Affiliate.AffiliatesGroupsName | ✓ Tier 1 description copied verbatim from Dim_Affiliate wiki |
| AffiliateName | DWH_dbo.Dim_Affiliate.Contact | ✓ Tier 1 description copied verbatim from Dim_Affiliate wiki |
| AffiliatePlan | DWH_dbo.Dim_Affiliate.ContractName | ✓ Tier 1 description copied verbatim from Dim_Affiliate wiki |
