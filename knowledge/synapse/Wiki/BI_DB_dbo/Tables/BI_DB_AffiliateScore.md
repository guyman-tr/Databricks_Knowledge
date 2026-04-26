# BI_DB_dbo.BI_DB_AffiliateScore

**Schema**: BI_DB_dbo | **Batch**: 56 | **Generated**: 2026-04-23

## Purpose

Monthly affiliate quality scorecard. For each affiliate channel partner, scores the cohort of customers who made their first deposit (FTD) via that affiliate in a given calendar month, using LTV/CPA ratios, portfolio cluster distribution, and 30-day equity as inputs to a Red/Yellow/Green color score. Includes parallel lookback metrics (3M and 9M prior cohorts) and a lookback color score for trend analysis. Feeds affiliate performance reporting and partner strategy decisions.

## Shape

| Property | Value |
|----------|-------|
| Rows | ~23,079 |
| Columns | 54 |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Grain | One row per affiliate per YearMonth (YYYYMM) |

## Load Pattern

**Monthly window replace with 4-month rolling backfill** — `SP_M_AffiliateScore(@date)` runs a WHILE loop over the 4 most recent months, performing DELETE WHERE YearMonth=@YearMonth + INSERT for each period. This means every SP run refreshes the last 4 months to incorporate updated LTV, cluster, and cost data. History beyond 4 months is stable.

## Scoring Logic

**ColorScore** (Red/Yellow/Green) evaluates each affiliate's current-month FTD cohort quality using three signals:

| %ClusterEquitiesInvestors | AvgLTV/CPA < 1 | AvgLTV/CPA 1–1.5 | AvgLTV/CPA > 1.5 |
|--------------------------|----------------|-------------------|------------------|
| < 30% | Red | Yellow | Green |
| 30–50% | Red/Yellow (equity tiebreak) | Yellow/Green (equity tiebreak) | Green |
| > 50% | Red/Yellow (equity tiebreak) | Yellow/Green (equity tiebreak) | Green |

Equity tiebreak: AvgEquity_30d < 80% of monthly avg → lower score; ≥ 80% → higher score.

**ColorScore_3M_Before** applies the same matrix to the 3M/9M lookback cohorts.

## Columns

### Dimension & Identification

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | YearMonth | int | NOT NULL | Calendar month of the FTD cohort being scored, formatted as YYYYMM integer (e.g., 202601 = January 2026) | Propagation |
| 2 | AffiliateID | int | NOT NULL | Affiliate partner identifier — FK to DWH_dbo.Dim_Affiliate.AffiliateID | Tier 2 |
| 3 | AffiliateGroupName | varchar(100) | NULL | Marketing group the affiliate belongs to. | Tier 1 |
| 4 | AffiliateName | nvarchar(500) | NULL | Primary contact information for the affiliate partner. | Tier 1 |
| 5 | AffiliatePlan | nvarchar(500) | NULL | Free-text name of the affiliate's contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". | Tier 1 |
| 6 | ActiveMonths | int | NULL | Number of months the affiliate has been active as of the end of @YearMonth; minimum 1 even for affiliates created within the same month | Tier 2 |

### Current Month FTD Metrics

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 7 | FTDs | int | NULL | Count of customers who made their first deposit via this affiliate in @YearMonth (SubChannelID IN (20,31), IsValidCustomer=1) | Tier 2 |
| 8 | Cost_FTDs | int | NULL | Affiliate-reported count of FTDs from BI_DB_MarketingMonthlyRawData; may differ from FTDs due to attribution differences | Tier 2 |
| 9 | FTDA | money | NULL | Total first deposit amount in USD for all FTDs in the cohort | Tier 2 |
| 10 | TotalCost | numeric(38,6) | NULL | Total affiliate cost for the month in USD from BI_DB_MarketingMonthlyRawData (Channel='Affiliate') | Tier 2 |
| 11 | CPA | money | NULL | Cost per acquisition: TotalCost / Cost_FTDs | Tier 2 |

### First Action Distribution (Current Month Cohort)

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 12 | FirstActionStocks/ETF | numeric(38,6) | NULL | Fraction of FTD cohort whose first trading action was Stocks/ETFs (from BI_DB_First5Actions) | Tier 2 |
| 13 | FirstActionCrypto | numeric(38,6) | NULL | Fraction of FTD cohort whose first trading action was Crypto | Tier 2 |
| 14 | FirstActionFX | numeric(38,6) | NULL | Fraction of FTD cohort whose first trading action was FX/Commodities/Indices | Tier 2 |
| 15 | FirstActionCopy | numeric(38,6) | NULL | Fraction of FTD cohort whose first trading action was Copy trading | Tier 2 |
| 16 | FirstActionCopyFund | numeric(38,6) | NULL | Fraction of FTD cohort whose first trading action was Copy Fund | Tier 2 |

### Cluster Distribution (Current Month Cohort)

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 17 | ClusterEquitiesInvestors | numeric(38,6) | NULL | Fraction of FTD cohort classified as Equities Investors cluster (latest cluster, IsLastCluster=1) | Tier 2 |
| 18 | ClusterCrypto | numeric(38,6) | NULL | Fraction of FTD cohort classified as Crypto cluster | Tier 2 |
| 19 | ClusterLeveragedTraders | numeric(38,6) | NULL | Fraction of FTD cohort classified as Leveraged Traders cluster | Tier 2 |
| 20 | ClusterEquitiesTraders | numeric(38,6) | NULL | Fraction of FTD cohort classified as Equities Traders cluster | Tier 2 |
| 21 | ClusterEquitiesCrypto | numeric(38,6) | NULL | Fraction of FTD cohort classified as Equities Crypto cluster | Tier 2 |
| 22 | ClusterDiversifiedTraders | numeric(38,6) | NULL | Fraction of FTD cohort classified as Diversified Traders cluster | Tier 2 |
| 23 | ClusterEquitiesInvestors_Total | int | NULL | Absolute count of FTD cohort members classified as Equities Investors (numerator for ClusterEquitiesInvestors) | Tier 2 |
| 24 | AllClusters | int | NULL | Total count of FTD cohort members with any cluster classification (denominator for cluster fractions) | Tier 2 |

### LTV & Revenue Metrics (Current Month Cohort)

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 25 | LTV | numeric(38,6) | NULL | Total 8-year LTV estimate in USD for all FTD cohort members with positive LTV (BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New) | Tier 2 |
| 26 | LTV_No_Extreme | numeric(38,6) | NULL | Total 8-year LTV excluding extreme outliers (Revenue8Y_LTV_NoExtreme_New) | Tier 2 |
| 27 | AvgLTV | numeric(38,6) | NULL | Average LTV per cohort member: LTV / Users_LTV | Tier 2 |
| 28 | Users_LTV | int | NULL | Count of FTD cohort members with Revenue8Y_LTV_New > 0 (denominator for AvgLTV) | Tier 2 |
| 29 | AvgLTV_No_Ex | numeric(38,6) | NULL | Average no-extreme LTV per FTD: LTV_No_Extreme / FTDs | Tier 2 |
| 30 | Equity_30d | numeric(38,6) | NULL | Total 30-day equity in USD for the FTD cohort (BI_DB_First5Actions.Equity30days) | Tier 2 |
| 31 | AvgEquity_30d | numeric(38,6) | NULL | Average 30-day equity per cohort member: Equity_30d / UsersEqu30d | Tier 2 |
| 32 | UsersEqu30d | int | NULL | Count of FTD cohort members with non-null Equity30days (denominator for AvgEquity_30d) | Tier 2 |
| 33 | Revenue_30d | numeric(38,6) | NULL | Total 30-day revenue in USD for the FTD cohort (BI_DB_First5Actions.Revenue30days; source changed 2024-07-01) | Tier 2 |
| 34 | AvgRev_30d | numeric(38,6) | NULL | Average 30-day revenue per cohort member: Revenue_30d / UsersRev30d | Tier 2 |
| 35 | UsersRev30d | int | NULL | Count of FTD cohort members with non-null Revenue30days (denominator for AvgRev_30d) | Tier 2 |

### Color Score & Bucketing (Current Month)

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 36 | ColorScore | varchar(10) | NULL | Affiliate quality score for the current month cohort: 'Red' (low quality), 'Yellow' (medium), 'Green' (high); see scoring logic above; NULL when scoring inputs are unavailable | Tier 2 |
| 37 | EquityLevel | varchar(50) | NULL | AvgEquity_30d bucket relative to the monthly cohort average: 'Less 20% Avg', 'Between +-20% Avg', 'Above 20% Avg' | Tier 2 |
| 38 | LTV/CPA_Level | varchar(50) | NULL | AvgLTV/CPA ratio bucket: '0-1' (CPA exceeds LTV), '1-1.5' (breakeven to moderate), '+-1.5' (strong LTV return) | Tier 2 |
| 39 | ClusterEquityInvestorLevel | varchar(50) | NULL | %ClusterEquitiesInvestors bucket: 'Less 30%', 'Between 30%-50%', 'Above 50%' | Tier 2 |

### Lookback Metrics (3M and 9M Prior Cohorts)

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 40 | FTDs_3M_Before | int | NULL | Count of FTDs in the 3 months prior to @YearMonth for this affiliate | Tier 2 |
| 41 | LTV_Last9Months | numeric(38,6) | NULL | Total LTV for FTD cohort from the 9 months prior to @YearMonth | Tier 2 |
| 42 | LTV_No_Ex_Last9Months | numeric(38,6) | NULL | Total no-extreme LTV for the 9-month lookback cohort | Tier 2 |
| 43 | Users_LTV_Last9M | int | NULL | Count of customers with LTV>0 in the 9-month lookback cohort | Tier 2 |
| 44 | CPA_9M_Before | numeric(38,6) | NULL | Cost per acquisition for the 9 months prior to @YearMonth | Tier 2 |
| 45 | LTV/CPA_9M_Before | numeric(38,6) | NULL | AvgLTV to CPA ratio for the 9-month lookback: LTV_Last9M / Users_LTV_Last9M / CPA_9M_Before | Tier 2 |
| 46 | %Cluster_Equities_Investors_3M_Before | numeric(38,6) | NULL | Fraction of FTD cohort in 3-month lookback classified as Equities Investors | Tier 2 |
| 47 | ClusterEquitiesInvestors_Last3M_Total | int | NULL | Absolute count of Equities Investors in the 3-month lookback cohort | Tier 2 |
| 48 | AllClusters_Last3M | int | NULL | Total clustered FTDs in the 3-month lookback cohort (denominator for %Cluster_Equities_Investors_3M_Before) | Tier 2 |
| 49 | Equity_30d_3M_Before | numeric(38,6) | NULL | Total 30-day equity for the 3-month lookback cohort | Tier 2 |
| 50 | UsersEqu30d_Last3Months | int | NULL | Count of 3-month lookback cohort members with non-null Equity30days | Tier 2 |
| 51 | Rev_30d_Last3Months | numeric(38,6) | NULL | Total 30-day revenue for the 3-month lookback cohort | Tier 2 |
| 52 | UsersRev30d_Last3Months | int | NULL | Count of 3-month lookback cohort members with non-null Revenue30days | Tier 2 |
| 53 | ColorScore_3M_Before | varchar(10) | NULL | Affiliate quality score computed on the 3M/9M lookback cohorts using the same Red/Yellow/Green matrix | Tier 2 |

### ETL Metadata

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 54 | UpdateDate | datetime | NOT NULL | Timestamp when this row was inserted by the ETL pipeline (GETDATE() at INSERT time) | Propagation |

## Key Relationships

| Column | Joins To | Cardinality |
|--------|----------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate.AffiliateID | Many-to-one |
| YearMonth + AffiliateID | — | Composite natural key (one row per affiliate per month) |

## Data Observations

- YearMonth spans 202109 (Sept 2021) to 202602 (Feb 2026); 54 distinct months
- UpdateDate spans 2022-04-01 to 2026-04-01 — monthly cadence confirmed
- ColorScore distribution: Green predominates, followed by Red; Yellow minority; ~6% NULL (affiliates with insufficient scoring inputs)
- Approximately 427 affiliates scored per month on average (23,079 rows / 54 months); 2,875 distinct affiliates over history

## Quality Notes

| Dimension | Assessment |
|-----------|-----------|
| Tier Distribution | 3 Tier 1, 49 Tier 2, 2 Propagation |
| Completeness | All 54 columns documented |
| Tier 1 | 3 — AffiliateGroupName, AffiliateName, AffiliatePlan from Dim_Affiliate wiki |
| Known Gaps | No upstream wiki for BI_DB_First5Actions, BI_DB_LTV_BI_Actual, BI_DB_CID_DailyCluster, BI_DB_MarketingMonthlyRawData |

**Quality Score**: 8.4/10
