# Review Sidecar — BI_DB_dbo.BI_DB_MarketingMonthlyRawData

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 50 columns in DDL, 50 in wiki |
| All columns have tier suffix | ✅ | T1=0, T2=39, T3=10, Propagation=1 |
| Writer SP confirmed | ✅ | SP_Marketing_Cube — OpsDB P0 Daily (second phase) |
| ETL pattern documented | ✅ | DELETE-INSERT from BI_DB_MarketingDailyRawData, ~5-year window |
| Sample data reviewed | ✅ | 2.37M rows, 64 months (202101→202604) |
| Sibling relationship documented | ✅ | Monthly = SUM aggregation of Daily |

## T1 Fidelity

No T1 upstream wiki available for any dimension tables (Dim_Affiliate, Dim_Country, Dim_Channel, Dim_Platform). All dimension columns are T3 inferred from SP code and DDL.

**T1 coverage**: 0 / 49 business columns = 0%

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Lead_Comm type mismatch | High | Daily table has Lead_Comm as float; Monthly has decimal(36,17). This is a DDL inconsistency that could cause precision issues in ETL or comparisons. Confirm whether this is intentional or a DDL drift. |
| 2 | IsRev/Redeposits/Rev10 in Monthly | Medium | In Daily, these columns are computed via a 3-month lookback UPDATE pass. In Monthly, they are SUM(daily IsRev) — meaning they correctly roll up the daily UPDATE-pass values. However, if the daily IsRev for a month was 0 at INSERT time and later updated, the Monthly row may not reflect the update. Confirm SP execution order ensures Daily is fully updated before Monthly INSERT runs. |
| 3 | Fake FTD exclusion (Aug 2025) | Medium | Propagated from Daily via SUM. Monthly YearMonthID=202508 rows should already exclude the fake FTDs. Confirm historical Monthly rows for 202508 were regenerated after the Daily fix was applied. |
| 4 | LTV_NoExtreme in Monthly | Low | Same as Daily — NOT in SP INSERT list. Populated by separate LTV SP. Confirm that the LTV SP also updates Monthly rows, not just Daily. |
| 5 | 5-year retention window start | Low | Monthly purge threshold = start of year 5 years ago (@StartOfYear5YearsBack = YYYY0101 of (current year - 5)). As of 2026: purges YearMonthID < '202101'. Confirm this retention policy is still appropriate for reporting needs. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | No upstream production DB wikis available |
| Tier 2 | 39 | All metric columns + grain ID columns |
| Tier 3 | 10 | CountryName, Region, Desk, DateCreated, Channel, SubChannel, Organic/Paid, Contact, ContractName, ContractType, AffiliatesGroupsName, AccountActivated, NewMarketingRegion |
| Propagation | 1 | UpdateDate |
