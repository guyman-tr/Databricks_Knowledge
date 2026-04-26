# Review Sidecar — BI_DB_dbo.BI_DB_MarketingDailyRawData

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 50 columns in DDL, 50 in wiki |
| All columns have tier suffix | ✅ | T1=0, T2=39, T3=10, Propagation=1 |
| Writer SP confirmed | ✅ | SP_Marketing_Cube — OpsDB P0 Daily |
| ETL pattern documented | ✅ | DELETE-INSERT rolling 2-year window |
| Sample data reviewed | ✅ | 12.1M rows, 772 dates, 49K affiliates, 249 countries |
| Grain documented | ✅ | AffiliateID × CountryID × DateID × Funnel (CROSS JOIN scaffold) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | FTD scope | High | The FTD column counts only Fiktivo affiliate-attributed FTDs (through the AffWizz commission platform). Direct/organic FTDs are NOT in this table. Confirm this scope is correctly understood by all consumers — there's a risk of confusion with BI_DB_LiveAcquisitionDashboard FTD counts which cover all platform FTDs. |
| 2 | FTDA scope | High | FTDA = SUM(cpa.Amount) for Tier-1 CPA credits only. This is NOT total first deposit revenue. Confirm column description is clear enough for analysts who may confuse this with total FTD amounts. |
| 3 | LTV_NoExtreme population | Medium | DDL has LTV_NoExtreme column but it is NOT in the SP_Marketing_Cube INSERT list. The 2020-05 changelog mentions it was added along with GLTV. Confirm which SP populates this column and whether it is current or stale. |
| 4 | Fake FTD exclusion (Aug 2025) | Medium | SP_Marketing_Cube has #fakeftd block that excludes customers with FirstDepositDate 2025-08-19 to 2025-08-22 and FirstDepositAmount=1. Confirm this exclusion is still intentional and known to the business stakeholders. |
| 5 | IsRev/Redeposits coverage | Medium | IsRev and Redeposits are computed from BI_DB_CIDFirstDates for FTDs within the last 3 months (@DateM3). FTDs older than 3 months will have IsRev=0 even if they later became revenue-generating. Confirm this 3-month lookback window is the intended design. |
| 6 | Installs availability | Low | Installs from BI_DB_AppFlyer_Reports was disabled in 2021-12 and restored in 2023-07. Confirm data is continuously available post-2023-07 and whether pre-2023 Installs data is NULL or 0. |
| 7 | PastGRevenue | Low | Always 0 from SP. Was previously from Optimove BI_DB_Real_LTV (removed 2020-05). Confirm whether this column is still being consumed by any reports or can be deprecated. |
| 8 | Channel retroactive update | Low | Channel/SubChannel are retroactively updated for DateID ≥ 2019-01-01. This means historical channel attribution is rewritten when Dim_Channel changes. Confirm whether reports that use historical channel data are aware of this retroactive behavior. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | No upstream production DB wikis exist for dimension tables (Dim_Affiliate, Dim_Country, Dim_Channel) |
| Tier 2 | 39 | All SP-computed metrics and dimension-derived columns where SP code is authoritative |
| Tier 3 | 10 | CountryName, Region, Desk, DateCreated, Channel, SubChannel, Organic/Paid, Contact, ContractName, ContractType, AffiliatesGroupsName, AccountActivated, NewMarketingRegion (no Dim wiki) |
| Propagation | 1 | UpdateDate |
