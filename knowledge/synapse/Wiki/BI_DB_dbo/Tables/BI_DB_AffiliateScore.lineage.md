# Lineage: BI_DB_dbo.BI_DB_AffiliateScore

**Generated**: 2026-04-23
**Writer SP**: `SP_M_AffiliateScore(@date)`
**Load Pattern**: DELETE WHERE YearMonth=@YearMonth + INSERT (monthly window replace; WHILE loop over 4 months per run)
**UC Target**: `_Not_Migrated`

## ETL Pipeline

```
── Current Month Cohort (FTD in @YearMonth, SubChannelID IN 20/31) ──────────────────────

DWH_dbo.Dim_Customer (FirstDepositDate = @YearMonth, SubChannelID IN (20,31), IsValidCustomer=1)
  + DWH_dbo.Dim_Affiliate (JOIN on AffiliateID → group, name, plan, DateCreated)
  + BI_DB_dbo.BI_DB_First5Actions (JOIN on CID → FirstAction type, Equity30days, Revenue30days)
  + BI_DB_dbo.BI_DB_LTV_BI_Actual (JOIN on CID, Revenue8Y_LTV_New>0)
  + BI_DB_dbo.BI_DB_CID_DailyCluster (JOIN on CID, IsLastCluster=1 → ClusterDetail)
  + BI_DB_dbo.BI_DB_MarketingMonthlyRawData (YearMonthID=@YearMonth, Channel='Affiliate' → Cost, FTD cost count)
        |
        v [aggregate by AffiliateID: counts, sums, ratios, color scoring]
        ColorScore (Red/Yellow/Green)

── 3-Month Lookback Cohort (FTD between @start3monthbefore and @end3monthsbefore) ────────

DWH_dbo.Dim_Customer (FTD in 3M lookback window, IsValidCustomer=1)
  + BI_DB_dbo.BI_DB_First5Actions (Equity30days, Revenue30days)
  + BI_DB_dbo.BI_DB_CID_DailyCluster (IsLastCluster=1)

── 9-Month Lookback Cohort (FTD between @start9monthbefore and @end9monthsbefore) ────────

DWH_dbo.Dim_Customer (FTD in 9M lookback window, IsValidCustomer=1)
  + BI_DB_dbo.BI_DB_LTV_BI_Actual (Revenue8Y_LTV_New>0)
  + BI_DB_dbo.BI_DB_MarketingMonthlyRawData (YearMonthID between 9M window, Channel='Affiliate')
        |
        v [aggregate by AffiliateID: lookback metrics + color scoring]
        ColorScore_3M_Before (Red/Yellow/Green on lookback cohorts)

        |
        v
SP_M_AffiliateScore(@date) [DELETE WHERE YearMonth=@YearMonth + INSERT; WHILE loop over last 4 months]
        |
        v
BI_DB_dbo.BI_DB_AffiliateScore (23,079 rows, 54 months, Sept 2021–Feb 2026)
```

## Column Lineage

### Dimension & Identification

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | YearMonth | ETL pipeline | — | YYYYMM integer derived from @date parameter (period being scored) | Propagation |
| 2 | AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | passthrough (also in Dim_Affiliate) | Tier 2 |
| 3 | AffiliateGroupName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | passthrough | Tier 1 |
| 4 | AffiliateName | DWH_dbo.Dim_Affiliate | Contact | passthrough | Tier 1 |
| 5 | AffiliatePlan | DWH_dbo.Dim_Affiliate | ContractName | passthrough | Tier 1 |
| 6 | ActiveMonths | DWH_dbo.Dim_Affiliate | DateCreated | computed: CASE WHEN DATEDIFF(MONTH, DateCreated, month_end) <= 0 THEN 1 ELSE DATEDIFF(MONTH, ...) END | Tier 2 |

### Current Month FTD Metrics

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 7 | FTDs | DWH_dbo.Dim_Customer | RealCID | COUNT of FTDs in @YearMonth cohort | Tier 2 |
| 8 | Cost_FTDs | BI_DB_dbo.BI_DB_MarketingMonthlyRawData | FTD | SUM(FTD) for Channel='Affiliate', @YearMonth | Tier 2 |
| 9 | FTDA | DWH_dbo.Dim_Customer | FirstDepositAmount | SUM(FirstDepositAmount) for @YearMonth cohort | Tier 2 |
| 10 | TotalCost | BI_DB_dbo.BI_DB_MarketingMonthlyRawData | TotalCost | SUM(TotalCost) for Channel='Affiliate', @YearMonth | Tier 2 |
| 11 | CPA | BI_DB_dbo.BI_DB_MarketingMonthlyRawData | TotalCost, FTD | SUM(TotalCost)/SUM(FTD) | Tier 2 |

### First Action Distribution (Current Month Cohort)

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 12 | FirstActionStocks/ETF | BI_DB_dbo.BI_DB_First5Actions | FirstAction | fraction: count(FirstAction='Stocks/ETFs') / total first actions | Tier 2 |
| 13 | FirstActionCrypto | BI_DB_dbo.BI_DB_First5Actions | FirstAction | fraction: count(FirstAction='Crypto') / total | Tier 2 |
| 14 | FirstActionFX | BI_DB_dbo.BI_DB_First5Actions | FirstAction | fraction: count(FirstAction='FX/Commodities/Indices') / total | Tier 2 |
| 15 | FirstActionCopy | BI_DB_dbo.BI_DB_First5Actions | FirstAction | fraction: count(FirstAction='Copy') / total | Tier 2 |
| 16 | FirstActionCopyFund | BI_DB_dbo.BI_DB_First5Actions | FirstAction | fraction: count(FirstAction='Copy Fund') / total | Tier 2 |

### Cluster Distribution (Current Month Cohort)

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 17 | ClusterEquitiesInvestors | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Equities Investors') / AllClusters | Tier 2 |
| 18 | ClusterCrypto | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Crypto') / AllClusters | Tier 2 |
| 19 | ClusterLeveragedTraders | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Leveraged Traders') / AllClusters | Tier 2 |
| 20 | ClusterEquitiesTraders | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Equities Traders') / AllClusters | Tier 2 |
| 21 | ClusterEquitiesCrypto | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Equities Crypto') / AllClusters | Tier 2 |
| 22 | ClusterDiversifiedTraders | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(ClusterDetail='Diversified Traders') / AllClusters | Tier 2 |
| 23 | ClusterEquitiesInvestors_Total | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | absolute count: count(ClusterDetail='Equities Investors') | Tier 2 |
| 24 | AllClusters | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | total count of FTDs with any cluster (denominator for fractions) | Tier 2 |

### LTV & Revenue Metrics (Current Month Cohort)

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 25 | LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | SUM(Revenue8Y_LTV_New) for cohort where LTV>0 | Tier 2 |
| 26 | LTV_No_Extreme | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_NoExtreme_New | SUM(Revenue8Y_LTV_NoExtreme_New) | Tier 2 |
| 27 | AvgLTV | derived | LTV, Users_LTV | LTV / Users_LTV | Tier 2 |
| 28 | Users_LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | CID | COUNT customers with Revenue8Y_LTV_New > 0 | Tier 2 |
| 29 | AvgLTV_No_Ex | derived | LTV_No_Extreme, FTDs | LTV_No_Extreme / FTDs | Tier 2 |
| 30 | Equity_30d | BI_DB_dbo.BI_DB_First5Actions | Equity30days | SUM(Equity30days) for cohort | Tier 2 |
| 31 | AvgEquity_30d | derived | Equity_30d, UsersEqu30d | Equity_30d / UsersEqu30d | Tier 2 |
| 32 | UsersEqu30d | BI_DB_dbo.BI_DB_First5Actions | Equity30days | COUNT customers with non-null Equity30days | Tier 2 |
| 33 | Revenue_30d | BI_DB_dbo.BI_DB_First5Actions | Revenue30days | SUM(Revenue30days) for cohort (changed from BI_LTV_Actual 2024-07-01) | Tier 2 |
| 34 | AvgRev_30d | derived | Revenue_30d, UsersRev30d | Revenue_30d / UsersRev30d | Tier 2 |
| 35 | UsersRev30d | BI_DB_dbo.BI_DB_First5Actions | Revenue30days | COUNT customers with non-null Revenue30days | Tier 2 |

### Color Scoring (Current Month)

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 36 | ColorScore | derived | ClusterEquitiesInvestors, AvgLTV, CPA, AvgEquity_30d | CASE scoring: Red/Yellow/Green based on %EI, AvgLTV/CPA ratio, AvgEquity vs 80% benchmark | Tier 2 |
| 37 | EquityLevel | derived | AvgEquity_30d | CASE: 'Less 20% Avg' / 'Between +-20% Avg' / 'Above 20% Avg' vs @AvgEqu30d | Tier 2 |
| 38 | LTV/CPA_Level | derived | AvgLTV, CPA | CASE: '0-1' / '1-1.5' / '+-1.5' | Tier 2 |
| 39 | ClusterEquityInvestorLevel | derived | ClusterEquitiesInvestors | CASE: 'Less 30%' / 'Between 30%-50%' / 'Above 50%' | Tier 2 |

### Lookback Metrics (3M and 9M Prior Cohorts)

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 40 | FTDs_3M_Before | DWH_dbo.Dim_Customer | RealCID | COUNT FTDs in 3M lookback window for this affiliate | Tier 2 |
| 41 | LTV_Last9Months | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | SUM LTV for 9M lookback cohort | Tier 2 |
| 42 | LTV_No_Ex_Last9Months | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_NoExtreme_New | SUM LTV_NoExtreme for 9M lookback | Tier 2 |
| 43 | Users_LTV_Last9M | BI_DB_dbo.BI_DB_LTV_BI_Actual | CID | COUNT customers with LTV>0 in 9M lookback | Tier 2 |
| 44 | CPA_9M_Before | BI_DB_dbo.BI_DB_MarketingMonthlyRawData | TotalCost, FTD | SUM(TotalCost)/SUM(FTD) for 9M prior period | Tier 2 |
| 45 | LTV/CPA_9M_Before | derived | LTV_Last9Months, Users_LTV_Last9M, CPA_9M_Before | AvgLTV_Last9M / CPA_9M_Before | Tier 2 |
| 46 | %Cluster_Equities_Investors_3M_Before | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | fraction: count(EI) / AllClusters in 3M lookback | Tier 2 |
| 47 | ClusterEquitiesInvestors_Last3M_Total | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | absolute count Equities Investors in 3M lookback | Tier 2 |
| 48 | AllClusters_Last3M | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | total clustered FTDs in 3M lookback (denominator) | Tier 2 |
| 49 | Equity_30d_3M_Before | BI_DB_dbo.BI_DB_First5Actions | Equity30days | SUM(Equity30days) for 3M lookback cohort | Tier 2 |
| 50 | UsersEqu30d_Last3Months | BI_DB_dbo.BI_DB_First5Actions | Equity30days | COUNT customers with non-null Equity30days in 3M lookback | Tier 2 |
| 51 | Rev_30d_Last3Months | BI_DB_dbo.BI_DB_First5Actions | Revenue30days | SUM(Revenue30days) for 3M lookback cohort | Tier 2 |
| 52 | UsersRev30d_Last3Months | BI_DB_dbo.BI_DB_First5Actions | Revenue30days | COUNT customers with non-null Revenue30days in 3M lookback | Tier 2 |
| 53 | ColorScore_3M_Before | derived | Lookback metrics | CASE scoring Red/Yellow/Green on 3M cohort %EI, LTV/CPA 9M ratio, AvgEquity 3M | Tier 2 |

### ETL Metadata

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 54 | UpdateDate | ETL pipeline | — | GETDATE() at INSERT time | Propagation |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| DWH_dbo.Dim_Customer | Table | FTD cohort base (SubChannelID IN (20,31), IsValidCustomer=1, FTD month filter) |
| DWH_dbo.Dim_Affiliate | Table | Affiliate metadata: group, name, plan, DateCreated |
| BI_DB_dbo.BI_DB_First5Actions | Table | First action type and 30-day equity/revenue per customer |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | Table | 8-year LTV estimates per customer (Revenue8Y_LTV_New, Revenue8Y_LTV_NoExtreme_New) |
| BI_DB_dbo.BI_DB_CID_DailyCluster | Table | Latest customer cluster classification (IsLastCluster=1) |
| BI_DB_dbo.BI_DB_MarketingMonthlyRawData | Table | Monthly affiliate cost and FTD counts (Channel='Affiliate') |

## Notes

- SP runs a WHILE loop over the last 4 months relative to @date, refreshing each YearMonth separately (DELETE+INSERT per period)
- Only affiliates with matching cost data in BI_DB_MarketingMonthlyRawData (HAVING SUM(TotalCost)>0) are included; affiliates with zero cost are excluded
- SubChannelID filter IN (20, 31) limits the FTD population to specific affiliate acquisition channels
- ColorScore uses a 3×3 decision matrix: %ClusterEquitiesInvestors (buckets: <30%, 30-50%, >50%) × AvgLTV/CPA (buckets: <1, 1-1.5, >1.5), with AvgEquity_30d vs 80% of monthly average as a tiebreaker
- Revenue_30d source changed 2024-07-01 from BI_DB_LTV_Actual to BI_DB_First5Actions (Or Filizer)
- No upstream wiki for BI_DB_First5Actions, BI_DB_LTV_BI_Actual, BI_DB_CID_DailyCluster, or BI_DB_MarketingMonthlyRawData
