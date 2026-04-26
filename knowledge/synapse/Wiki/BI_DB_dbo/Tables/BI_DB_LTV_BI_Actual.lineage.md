# BI_DB_dbo.BI_DB_LTV_BI_Actual — Column Lineage

**Generated**: 2026-04-23 | **Pipeline**: SP_LTV_BI_Actual (Daily, SB_Daily, Priority 0 — SP code not accessible)

## ETL Chain

```
BI_DB_dbo.BI_DB_LTV_Predictions (multiplier model: LTV_1Y/3Y/8Y/VolFix/GroupLevel)
  |-- BI_DB_dbo.BI_DB_CIDFirstDates (FirstDepositDate, Seniority, FirstFundedMonth)
  |-- BI_DB_dbo.BI_DB_CID_DailyCluster (ClusterDetail, behavioral segment)
  |-- Fact_SnapshotEquity (RealizedEquity → EquityTier: <$100=1, $100-$500=2, ≥$500=3)
  |-- Revenue8Y prediction model (new methodology 2023+) → Revenue8Y_LTV_New variants
  |-- SP_LTV_BI_Actual (Daily, SB_Daily, Priority 0 — consolidation SP) ---|
  v
BI_DB_dbo.BI_DB_LTV_BI_Actual (5.84M rows, ~1 row per CID, HEAP, HASH(CID))
  |-- SP_D_LTV_BI_Actual_Snapshot (P20) → BI_DB_LTV_BI_Actual_Daily_Snapshot
  |-- SP_LTV_FromDB_ToBigQuery → LTV_FromDB_ToBigQuery (BigQuery export)
  |-- (13 known downstream dependents in BI_DB_dbo)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Customer.CustomerStatic | CID | Passthrough — platform customer ID | Tier 1 — Customer.CustomerStatic |
| 2 | GCID | Customer.CustomerStatic | GCID | Passthrough — cross-product identity key | Tier 1 — Customer.CustomerStatic |
| 3 | NewMarketingRegion | DWH_dbo.Dim_Country / Dictionary.MarketingRegion | Region | Marketing region label (UK, German, French, Italian, etc.) | Tier 2 — BI_DB_LTV_Predictions wiki (Region column) |
| 4 | FirstDepositDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | Passthrough — date of first deposit | Tier 2 — BI_DB_CIDFirstDates context |
| 5 | FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | FirstNewFundedDate | EOMONTH(FirstNewFundedDate) — cohort anchor | Tier 2 — BI_DB_LTV_Predictions wiki |
| 6 | Seniority | BI_DB_dbo.BI_DB_CIDFirstDates | FirstFundedMonth | Months from FirstFundedMonth to today | Tier 2 — BI_DB_LTV_Predictions wiki |
| 7 | ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | Behavioral cluster at run date | Tier 2 — BI_DB_LTV_Predictions wiki |
| 8 | EquityTier | DWH_dbo.Fact_SnapshotEquity | RealizedEquity | 1=<$100, 2=$100-$500, 3=≥$500 RealizedEquity | Tier 2 — BI_DB_LTV_Predictions wiki |
| 9 | MonthsSinceLastPosOpen | DWH positions data | last open position date | Months elapsed since CID last opened a position | Tier 2 — naming + data evidence |
| 10 | Current_ACC_Revenue | Revenue source (DWH/BI_DB) | accumulated revenue | Cumulative revenue this CID has generated for eToro to date | Tier 2 — BI_DB_LTV_Predictions wiki |
| 11 | DaysFromFTD | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | Days from FTD to SP run date | Tier 2 — naming + data evidence |
| 12 | LTV_1Y | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_1Y | Passthrough or recalculated; hybrid predicted/actual at Seniority≥12 | Tier 2 — BI_DB_LTV_Predictions wiki |
| 13 | LTV_3Y | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_3Y | Passthrough or recalculated; hybrid predicted/actual at Seniority≥36 | Tier 2 — BI_DB_LTV_Predictions wiki |
| 14 | LTV_8Y | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_8Y | Passthrough or recalculated; hybrid predicted/actual at Seniority≥96 | Tier 2 — BI_DB_LTV_Predictions wiki |
| 15 | LTV_1Y_VolFix | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_1Y_VolFix | 1Y LTV with 12-month rolling group average volatility smoothing | Tier 2 — BI_DB_LTV_Predictions wiki |
| 16 | LTV_3Y_VolFix | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_3Y_VolFix | 3Y LTV with volatility smoothing | Tier 2 — BI_DB_LTV_Predictions wiki |
| 17 | LTV_8Y_VolFix | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_8Y_VolFix | 8Y LTV with volatility smoothing. Preferred variant. | Tier 2 — BI_DB_LTV_Predictions wiki |
| 18 | LTV_8Y_GroupLevel | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_8Y_GroupLevel | Post-INSERT UPDATE: AVG(LTV_8Y_VolFix) per (FirstFundedMonth × Region × ClusterDetail × EquityTier) | Tier 2 — BI_DB_LTV_Predictions wiki |
| 19 | Revenue8Y_LTV_New | Revenue8Y model (new methodology 2023+) | — | Predicted 8Y cumulative broker revenue; individual prediction only | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 20 | Revenue8Y_LTV_NoExtreme_New | Revenue8Y model | — | 8Y LTV (new methodology) with statistical outliers excluded | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 21 | UpdateDate | ETL pipeline | — | ETL write timestamp (SP_LTV_BI_Actual run time) | Propagation |
| 22 | Revenue8Y_LTV_New_WO_Group_LTV | Revenue8Y model | — | Individual 8Y LTV without group supplement; 0 where group LTV applied | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 23 | Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | Revenue8Y model | — | Outlier-trimmed individual 8Y LTV without group supplement | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 24 | First_Month_Equity_Tier | Fact_SnapshotEquity (at first funded month) | EquityTier | Customer's equity tier during first funded month; frozen | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 25 | First_Month_Cluster | BI_DB_CID_DailyCluster (at first funded month) | ClusterDetail | Customer's behavioral cluster in first funded month; frozen | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 26 | Currency | Customer account currency | — | Binary: 'USD' (~32%) or 'Non_USD' (~67%). Not the actual currency code. | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 27 | Revenue_Change_Percentage_Fixed | LTV calibration model | — | Fixed calibration multiplier applied to base LTV prediction; adjusts for projection bias | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 28 | Revenue8Y_LTV_New_Group_LTV | Revenue8Y model + group assignment | — | Blended 8Y LTV: individual where available, group supplement where not. **Recommended for most use cases.** | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 29 | Revenue8Y_LTV_NoExtreme_New_Group_LTV | Revenue8Y model + group (no extremes) | — | Blended 8Y LTV without outliers. Conservative version of Revenue8Y_LTV_New_Group_LTV. | Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki |
| 30 | Revenue8Y_LTV_All_Conv_Old | Legacy LTV model | — | Legacy 8Y LTV from pre-2023 methodology; retained for historical comparison | Tier 2 — naming + data evidence |

## Notes

- **SP code unavailable**: SP_LTV_BI_Actual has empty sys.sql_modules definition. Logic inferred from sibling wikis (BI_DB_LTV_Predictions, BI_DB_LTV_BI_Actual_Daily_Snapshot).
- **Preferred LTV variants**: VolFix variants (LTV_1Y_VolFix, LTV_3Y_VolFix, LTV_8Y_VolFix) are preferred for revenue modelling. Revenue8Y_LTV_New_Group_LTV is recommended for holistic 8Y prediction.
- **Hybrid predicted/actual**: LTV_1Y becomes actual at Seniority≥12; LTV_3Y at Seniority≥36; LTV_8Y at Seniority≥96 months.
- **WO_Group_LTV = 0**: Where group-level LTV was applied, WO_Group_LTV variants are set to 0, not NULL. Sum-aggregations undercount unless using blended Group_LTV variants.
- **Snapshot downstream**: SP_D_LTV_BI_Actual_Snapshot (P20) reads this table daily and appends to BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B row archive).
