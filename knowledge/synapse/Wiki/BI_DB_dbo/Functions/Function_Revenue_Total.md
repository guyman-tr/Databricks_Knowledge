# Function_Revenue_Total

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 31 (T1: 10, T2: 21) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns collectible revenue at customer-by-date grain aligned with DDR (daily revenue-generating actions), joined to snapshot customer attributes for segmentation. Staking is unioned separately from `Function_Revenue_StakingFee` (with one-month lag vs DDR) and excluded metric rows named `StakingLagOneMonth` from the main fact.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DDR_Fact_Revenue_Generating_Actions | BI_DB_dbo |
| Dim_Revenue_Metrics | BI_DB_dbo |
| Function_Revenue_StakingFee | BI_DB_dbo |
| Dim_Range | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RealCID; Function_Revenue_StakingFee.CID | Direct (UNION) | T1 |
| 2 | DateID | BI_DB_DDR_Fact_Revenue_Generating_Actions.DateID; Function_Revenue_StakingFee.DateID | Direct (UNION) | T1 |
| 3 | Date | BI_DB_DDR_Fact_Revenue_Generating_Actions.DateID; Function_Revenue_StakingFee.DateID | CONVERT(DATE, CONVERT(VARCHAR(8), DateID), 112) | T2 |
| 4 | Metric | BI_DB_DDR_Fact_Revenue_Generating_Actions.Metric | DDR: direct; Staking branch: 'Staking' | T2 |
| 5 | InstrumentTypeID | BI_DB_DDR_Fact_Revenue_Generating_Actions.InstrumentTypeID | DDR: direct; Staking: 10 | T2 |
| 6 | IsSettled | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsSettled | DDR: direct; Staking: 1 | T2 |
| 7 | IsCopy | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsCopy | DDR: direct; Staking: NULL | T2 |
| 8 | CountTransactions | BI_DB_DDR_Fact_Revenue_Generating_Actions.CountTransactions | DDR: direct; Staking: NULL | T2 |
| 9 | IncludedInTotalRevenue | BI_DB_DDR_Fact_Revenue_Generating_Actions.IncludedInTotalRevenue | DDR: direct; Staking: 1 | T2 |
| 10 | CountAsActiveTrade | BI_DB_DDR_Fact_Revenue_Generating_Actions.CountAsActiveTrade | DDR: direct; Staking: 0 | T2 |
| 11 | IsBuy | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsBuy | DDR: direct; Staking: 1 | T2 |
| 12 | IsLeveraged | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsLeveraged | DDR: direct; Staking: 0 | T2 |
| 13 | IsFuture | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsFuture | DDR: direct; Staking: 0 | T2 |
| 14 | IsCopyFund | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsCopyFund | DDR: direct; Staking: 0 | T2 |
| 15 | IsOpenedFromIBAN | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsOpenedFromIBAN | DDR: direct; Staking: NULL | T2 |
| 16 | IsClosedToIBAN | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsClosedToIBAN | DDR: direct; Staking: NULL | T2 |
| 17 | IsRecurring | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsRecurring | DDR: direct; Staking: NULL | T2 |
| 18 | IsAirDrop | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsAirDrop | DDR: direct; Staking: NULL | T2 |
| 19 | IsSQF | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsSQF | DDR: direct; Staking: 0 | T2 |
| 20 | RevenueMetricID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RevenueMetricID | DDR: direct; Staking: 12 | T2 |
| 21 | RevenueMetricCategoryID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RevenueMetricCategoryID | DDR: direct; Staking: 4 | T2 |
| 22 | RevenueMetricCategory | Dim_Revenue_Metrics.RevenueMetricCategory | JOIN on Metric; Staking branch: 'RevShare' | T2 |
| 23 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer; Function_Revenue_StakingFee.IsValidCustomer | Direct (UNION) | T1 |
| 24 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB; Function_Revenue_StakingFee.IsCreditReportValidCB | Direct (UNION) | T1 |
| 25 | CountryID | Fact_SnapshotCustomer.CountryID; Function_Revenue_StakingFee.CountryID | Direct (UNION) | T1 |
| 26 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID; Function_Revenue_StakingFee.PlayerLevelID | Direct (UNION) | T1 |
| 27 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID; Function_Revenue_StakingFee.PlayerStatusID | Direct (UNION) | T1 |
| 28 | RegulationID | Fact_SnapshotCustomer.RegulationID; Function_Revenue_StakingFee.RegulationID | Direct (UNION) | T1 |
| 29 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID; Function_Revenue_StakingFee.AccountTypeID | Direct (UNION) | T1 |
| 30 | AffiliateID | Fact_SnapshotCustomer.AffiliateID; Function_Revenue_StakingFee.AffiliateID | Direct (UNION) | T1 |
| 31 | Amount | BI_DB_DDR_Fact_Revenue_Generating_Actions.Amount; Function_Revenue_StakingFee.TotalUSDDistributed | **DDR branch:** `SUM(ga.Amount)` grouped after `WHERE ga.DateID BETWEEN @sdateInt AND @edateInt` AND `ga.Metric <> 'StakingLagOneMonth'` (staking lag rows excluded from this union part). **Staking branch:** `SUM(frsf.TotalUSDDistributed)` from `Function_Revenue_StakingFee(@sdateInt,@edateInt)` with `@OnlyValidCustomers` filter on `frsf.IsValidCustomer` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-02-12 | Guy M | Added staking |
| 2025-05-06 | Guy M | Added ticket fee by percent (and before that C2F, share lending) |
| 2025-06-23 | Guy M | Added IsSQF and IsFuture |
| 2025-10-17 | Guy M | Replaced calls with DDR revenue table for performance; staking still calls its function (DDR has 1-month lag) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
