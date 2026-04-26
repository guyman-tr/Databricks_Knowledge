# BI_DB_dbo.BI_DB_MarketingDailyRawData

## 1. Overview

Daily marketing performance cube combining **affiliate commission costs**, **acquisition funnel metrics** (registrations, FTDs, FTDA), **revenue metrics** (NetRevenues, TotalDeposit, DBRev), and **LTV metrics** (GLTV, FTDfromLTV, Rev10) aggregated at the AffiliateID × CountryID × Date × Funnel grain. This is the primary marketing analytics table serving performance marketing, affiliate management, and revenue attribution reporting.

**Row grain**: One AffiliateID × CountryID × DateID × Funnel combination (sparse — most metric cells are NULL for a given combination)

---

## 2. Business Context

`BI_DB_MarketingDailyRawData` is the central marketing data cube built by `SP_Marketing_Cube` (P0 Daily). It draws from multiple source systems:
- **Fiktivo (AffWizz)**: Affiliate platform tracking commissions (CPA, CPL, RevShare, eCost, Lead) and affiliate-attributed registrations and FTDs
- **DWH dimension tables**: Affiliate metadata, country/region/desk, channel/sub-channel, funnel/platform
- **BI_DB LTV and revenue tables**: Lifetime value (GLTV), revenue metrics (IsRev, Redeposits, Rev10)
- **AppsFlyer**: Mobile app install counts

**Key design choices**:
- **CROSS JOIN grain scaffold**: #Affiliates is built as CROSS JOIN of all active AffiliateIDs × all 249 countries × all 4 Funnel values (Web, IOS, Android, Undefined). All metric temp tables are LEFT JOINed onto this scaffold — meaning rows exist for combinations without any metrics (NULL across all measures). The WHERE clause at the end of the INSERT filters to rows with at least one non-NULL metric source.
- **Affiliate-attributed FTDs only**: `FTD` and `FTDA` columns count only FTDs and deposit amounts processed through the Fiktivo affiliate platform (Tier-1 CPA credits). Direct/organic FTDs are NOT included here — see `BI_DB_LiveAcquisitionDashboard` for full FTD counts.
- **Rolling ~2-year window**: DELETE-INSERT deletes from last-month-start onwards + purges records older than 2 years, then re-inserts from last month to @Date. As of Apr 2026: covers 2024-03-01 to 2026-04-11 (772 distinct dates, 12M+ rows).
- **Channel/SubChannel retroactive update**: After INSERT, Channel/SubChannel/Organic-Paid are updated retroactively from 2019-01-01 based on current Dim_Channel — ensuring historical rows reflect channel reclassifications.
- **IsRev/Redeposits/Rev10 UPDATE pass**: These engagement quality metrics are applied via a second UPDATE pass within the same SP run, covering FTDs from the past 3 months (@DateM3).
- **Fake FTD exclusion (Aug 2025)**: Customers with FirstDepositAmount=1 between 2025-08-19 and 2025-08-22 are added to #NotValidCustomer and excluded from all metrics (fraudulent FTD batch identified by the BI team).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 50 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |
| **Row Count** | ~12.1M (rolling ~2 years) |
| **Date Range** | 2024-03-01 → 2026-04-11 (772 distinct dates, Apr 2026 sample) |
| **Distinct Affiliates** | ~49,307 |
| **Distinct Countries** | 249 |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | AffiliateID | int | NOT NULL | Affiliate (partner) ID from DWH_dbo.Dim_Affiliate. Part of the AffiliateID × CountryID × DateID × Funnel grain key. FK concept to Dim_Affiliate.AffiliateID. (Tier 2 — Dim_Affiliate.AffiliateID) |
| 2 | CountryID | int | NOT NULL | Country ID from DWH_dbo.Dim_Country. Part of the grain key. All 249 countries appear in the CROSS JOIN scaffold. FK concept to Dim_Country.CountryID. (Tier 2 — Dim_Country.CountryID) |
| 3 | DateID | varchar(8) | YES | Date as YYYYMMDD string from DWH_dbo.Dim_Date.DateKey. Leading clustered index column. Covers @StartOfLastMonth → @Date. (Tier 2 — Dim_Date.DateKey) |
| 4 | Date | date | YES | Calendar date from DWH_dbo.Dim_Date.FullDate. ISO date format of the same event date as DateID. (Tier 2 — Dim_Date.FullDate) |
| 5 | Funnel | nvarchar(20) | YES | Platform/funnel category from DWH_dbo.Dim_Platform.Platform. Part of grain key. Values: 'Web', 'IOS', 'Android', 'Undefined'. Derived from customer's FunnelFromID → Dim_Funnel.PlatformID. Customers without a valid platform/funnel assignment get 'Undefined'. (Tier 2 — Dim_Platform.Platform) |
| 6 | CountryName | varchar(50) | NOT NULL | Country display name from DWH_dbo.Dim_Country.Name. Denormalized from CountryID. (Tier 3 — Dim_Country.Name) |
| 7 | Region | varchar(50) | NOT NULL | Geographic region from DWH_dbo.Dim_Country.Region. Standard geographic grouping (not the marketing override — see NewMarketingRegion). (Tier 3 — Dim_Country.Region) |
| 8 | Desk | nvarchar(50) | YES | Country desk assignment from DWH_dbo.Dim_Country.Desk. Operational desk responsible for this country/region in the sales/support structure. (Tier 3 — Dim_Country.Desk) |
| 9 | DateCreated | datetime | NOT NULL | Affiliate account creation date from DWH_dbo.Dim_Affiliate.DateCreated. When the affiliate account was first registered in AffWizz/Fiktivo. (Tier 3 — Dim_Affiliate.DateCreated) |
| 10 | Channel | nvarchar(50) | NOT NULL | Top-level marketing channel from DWH_dbo.Dim_Channel.Channel. Retroactively corrected for DateID ≥ 2019-01-01 based on current Dim_Channel. Common values: Direct, SEM, SEO, Affiliate, Friend Referral, Media Performance, Mobile Acquisition. (Tier 3 — Dim_Channel.Channel) |
| 11 | SubChannel | varchar(100) | NOT NULL | Granular sub-channel name from DWH_dbo.Dim_Channel.SubChannel. Retroactively corrected alongside Channel. (Tier 3 — Dim_Channel.SubChannel) |
| 12 | Organic/Paid | varchar(7) | YES | Classification of whether acquisition is organic or paid from DWH_dbo.Dim_Channel.[Organic/Paid]. Values: 'Organic' or 'Paid'. Retroactively corrected. (Tier 3 — Dim_Channel.[Organic/Paid]) |
| 13 | Contact | nvarchar(255) | YES | Affiliate contact or campaign identifier from DWH_dbo.Dim_Affiliate.Contact. (Tier 3 — Dim_Affiliate.Contact) |
| 14 | ContractName | nvarchar(100) | YES | Affiliate contract name from DWH_dbo.Dim_Affiliate.ContractName. (Tier 3 — Dim_Affiliate.ContractName) |
| 15 | ContractType | varchar(20) | YES | Contract type description from DWH_dbo.Dim_ContractType.Name via Dim_Affiliate.ContractType. (Tier 3 — Dim_ContractType.Name) |
| 16 | AffiliatesGroupsName | nvarchar(50) | YES | Parent affiliate group/network name from DWH_dbo.Dim_Affiliate.AffiliatesGroupsName. Groups individual affiliate accounts into their parent network (e.g., "Adtraction"). (Tier 3 — Dim_Affiliate.AffiliatesGroupsName) |
| 17 | AccountActivated | bit | NOT NULL | Whether the affiliate account is activated (accepting commissions). From DWH_dbo.Dim_Affiliate.AccountActivated. (Tier 3 — Dim_Affiliate.AccountActivated) |
| 18 | TotalCost | float | YES | Total affiliate commission cost = sum of all commission types (RevShare + Chargebacks + CPA + CPL + eCost + Lead_Comm). Sourced from Fiktivo affiliate platform. NULL if no commissions for this combination. (Tier 2 — Fiktivo commission pipeline) |
| 19 | RevShare_Comm | float | YES | Revenue share commission paid to the affiliate for closed positions in the period. From Fiktivo AffiliateCommission_ClosedPosition. (Tier 2 — Fiktivo RevShare) |
| 20 | Chargebacks | float | YES | Chargeback and Refund commission credits (CreditTypeID IN 4,5) from Fiktivo. Negative impact to TotalCost. (Tier 2 — Fiktivo AffiliateCommission_Credit) |
| 21 | NumberOfChargebacks | int | YES | Count of chargeback/refund events in the period for this affiliate × country. (Tier 2 — Fiktivo AffiliateCommission_Credit COUNT) |
| 22 | CPA_Comm | float | YES | Cost Per Acquisition commission (CreditTypeID=1, Valid≠0) from Fiktivo. Paid when a Tier-1 qualifying FTD occurs. (Tier 2 — Fiktivo CPA credits) |
| 23 | CPL_Comm | float | YES | Cost Per Lead commission from Fiktivo tblaff_Leads. Paid when a qualified lead (registration) is delivered by the affiliate. (Tier 2 — Fiktivo CPL leads) |
| 24 | eCost | float | YES | eCost affiliate commission from Fiktivo tblaff_eCost. A performance-based variable cost type. (Tier 2 — Fiktivo eCost) |
| 25 | Tier2Commition | float | YES | Sub-affiliate Tier-2 commission amount. Paid to parent affiliates in multi-tier arrangements when their referred sub-affiliates generate activity. Note: column name has typo "Commition" (missing 's'). (Tier 2 — Fiktivo Tier=2 commissions) |
| 26 | Tier3Commition | float | YES | Sub-affiliate Tier-3 commission amount. Same as Tier2 but for third-level affiliate hierarchy. Note: typo "Commition". (Tier 2 — Fiktivo Tier=3 commissions) |
| 27 | Registration | int | YES | Count of customer registrations attributed to this affiliate under this country × date × funnel combination. Sourced from Fiktivo registration tracking joined with DWH_dbo.Dim_Customer. (Tier 2 — Fiktivo Registration + Dim_Customer) |
| 28 | SameDayFTD | int | YES | Count of First-Time Deposits where the deposit date equals the registration date (converted on same calendar day). Subset of FTD. (Tier 2 — Fiktivo FTD matching, SameDayFTD CASE) |
| 29 | FTD | int | YES | Count of affiliate-attributed First-Time Deposits from Fiktivo AffiliateCommission_Credit. **Scope note**: This is ONLY affiliate-attributed FTDs tracked by Fiktivo — does NOT include all platform FTDs (direct customers, non-affiliate-credited FTDs). (Tier 2 — Fiktivo AffiliateCommission_Credit) |
| 30 | EFTD | int | YES | Count of Eligible FTDs: Fiktivo Tier-1 CPA-eligible FTDs where IsFirstDeposit=1 and Valid=1. A subset of FTD representing qualifying conversions for CPA commission payment. (Tier 2 — Fiktivo AffiliateCommission_Credit Tier=1 Valid=1) |
| 31 | FTDA | float | YES | Sum of FTD amounts in USD for Tier-1 CPA-eligible affiliate credits (cpa.Amount). **Scope note**: This is NOT total first-deposit revenue — it is only the deposit amount for CPA-eligible Tier-1 affiliate FTDs. (Tier 2 — Fiktivo AffiliateCommission_Credit Tier=1 Amount) |
| 32 | NetRevenues | float | YES | Net revenue generated by customers acquired through this affiliate: SALE.Revenues + SALE.USED_BONUS_GRAND_TOTAL + CHARGEBACK.Revenues. Sources include closed position revenues and bonus credits from the Fiktivo ClosedPosition pipeline. (Tier 2 — Fiktivo ClosedPosition revenue) |
| 33 | VerificationLevelID2 | int | YES | Count of customers who achieved KYC verification level 2 (document verification) under this affiliate attribution. Used to measure document submission quality of acquired customers. (Tier 2 — Dim_Customer.VerificationLevelID=2) |
| 34 | VerificationLevelID3 | int | YES | Count of customers who achieved KYC verification level 3 (full verification) under this affiliate attribution. Higher quality signal than level 2. (Tier 2 — Dim_Customer.VerificationLevelID=3) |
| 35 | Installs | int | YES | Mobile app install events tracked via AppsFlyer, attributed to this affiliate × country × date × funnel combination. Source: BI_DB_AppFlyer_Reports. Column was disabled 2021-12 and restored/rewritten 2023-07. (Tier 2 — BI_DB_AppFlyer_Reports) |
| 36 | TotalDeposit | decimal(38,2) | YES | Total deposit amount (all deposits, not just FTD) in USD for customers attributed to this affiliate in the period. Includes repeat deposits. (Tier 2 — Billing/DWH deposit pipeline) |
| 37 | DBRev | decimal(38,2) | YES | Database Revenue — trading revenue (realized PnL + spreads + fees) generated by customers attributed to this affiliate in the period. (Tier 2 — DWH trading revenue pipeline) |
| 38 | RAF_Comm | decimal(38,2) | YES | Refer-A-Friend commission cost for the affiliate. Cost incurred when referred customers meet RAF eligibility criteria. (Tier 2 — Fiktivo RAF commission) |
| 39 | IsRev | int | YES | Count of FTD customers (from past 3 months) who became revenue-generating: opened their first trading position after depositing. Computed via UPDATE pass on BI_DB_CIDFirstDates.FirstPosOpenDate IS NOT NULL. Inserted as 0, then updated. (Tier 2 — BI_DB_CIDFirstDates.FirstPosOpenDate) |
| 40 | Redeposits | int | YES | Count of FTD customers who made at least one subsequent deposit (LastDepositDate ≠ FirstDepositDate on BI_DB_CIDFirstDates). Inserted as 0, then updated by UPDATE pass. (Tier 2 — BI_DB_CIDFirstDates.LastDepositDate) |
| 41 | PastGRevenue | float | YES | Legacy Optimove Gross Revenue field. Always set to 0 by current SP (removed from Optimove integration 2020-05). Default value (0) from DDL. (Tier 3 — legacy field, always 0) |
| 42 | GLTV | float | YES | Gross Lifetime Value: projected total lifetime revenue from FTD customers acquired through this affiliate × country × date × funnel. Sourced from BI_DB_LTV_BI_Actual since 2020-05 (replaced BI_DB_Real_LTV). Default 0. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 43 | FTDfromLTV | int | YES | Count of FTDs from the LTV model that are attributed to this combination. Used to normalize GLTV calculations. Default 0. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 44 | Rev10 | int | YES | Count of FTD customers who reached the "Rev10" revenue milestone (defined in BI_DB_FirstTimeRev10). Measures revenue quality of acquired customers beyond the initial deposit. Updated by UPDATE pass. (Tier 2 — BI_DB_FirstTimeRev10) |
| 45 | UpdateDate | datetime | NOT NULL | ETL metadata: SP execution timestamp. Set to GETDATE() at INSERT and updated at subsequent UPDATE passes for the same row. (Propagation — GETDATE()) |
| 46 | LTV_NoExtreme | numeric(38,6) | YES | LTV excluding extreme outlier customers — high-value outliers that distort the mean LTV. Populated by a separate LTV SP (not SP_Marketing_Cube). Added 2020-05. Default 0. (Tier 2 — BI_DB_LTV_BI_Actual, separate LTV SP) |
| 47 | NewMarketingRegion | varchar(100) | YES | Marketing team curated region override from DWH_dbo.Dim_Country.MarketingRegionManualName. Unlike Region (geographic), this is a manually maintained marketing taxonomy. Added 2021-02. (Tier 3 — Dim_Country.MarketingRegionManualName) |
| 48 | Lead_Comm | float | YES | Lead commission: CPL cost from Fiktivo AffiliateCommission Registration table, added 2023-05 as a separate column (also included in TotalCost). (Tier 2 — Fiktivo Registration commission) |
| 49 | totalGroupLTV | int | YES | Group-level total LTV component from BI_DB_LTV_BI_Actual — measures the combined LTV of the acquisition group. (Tier 2 — BI_DB_LTV_BI_Actual.totalGroupLTV) |
| 50 | totalExtLTV | int | YES | External/extreme component of total LTV from BI_DB_LTV_BI_Actual — the portion attributable to extreme-value customers. (Tier 2 — BI_DB_LTV_BI_Actual.totalExtLTV) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| DWH_dbo.Dim_Affiliate | DWH_dbo | Grain: AffiliateID scaffold; Channel/Contact/Contract metadata |
| DWH_dbo.Dim_Country | DWH_dbo | Grain: CountryID scaffold; CountryName/Region/Desk/NewMarketingRegion |
| DWH_dbo.Dim_Platform | DWH_dbo | Grain: Funnel values (Web/IOS/Android/Undefined) |
| DWH_dbo.Dim_Date | DWH_dbo | DateID/Date loop (@StartOfLastMonth → @Date) |
| DWH_dbo.Dim_Channel | DWH_dbo | Channel/SubChannel/Organic-Paid |
| DWH_dbo.Dim_Customer | DWH_dbo | Registration counts, FTD → funnel mapping |
| Fiktivo AffiliateCommission_* | BI_DB_dbo External tables | All cost metrics (TotalCost, RevShare, Chargebacks, CPA, CPL, eCost, Lead) |
| Fiktivo AffiliateCommission_Credit (Tier=1) | BI_DB_dbo External tables | FTD, EFTD, FTDA metrics |
| BI_DB_CIDFirstDates | BI_DB_dbo | IsRev, Redeposits (UPDATE pass) |
| BI_DB_FirstTimeRev10 | BI_DB_dbo | Rev10 (UPDATE pass) |
| BI_DB_LTV_BI_Actual | BI_DB_dbo | GLTV, totalGroupLTV, totalExtLTV, FTDfromLTV |
| BI_DB_AppFlyer_Reports | BI_DB_dbo | Installs |

### Sibling Tables

| Table | Relationship |
|-------|-------------|
| BI_DB_MarketingMonthlyRawData | Monthly aggregation of this table — same SP writes monthly from Daily SUM |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Marketing_Cube |
| **ETL Pattern** | DELETE-INSERT (rolling window refresh) |
| **Schedule** | Daily (P0 — OpsDB Daily) |
| **Delete scope** | DateID ≥ @StartOfLastMonthForLoop (refreshes last month onwards) AND DateID < @StartOfMonth2YearsBack (purges >2 years old) |
| **Insert scope** | DateID from @StartOfLastMonth to @Date (re-inserts last month through yesterday) |
| **Window kept** | ~2 years (first day of 2 years ago → yesterday) |
| **Post-INSERT UPDATE** | IsRev, Redeposits, Rev10 updated for last 3 months; Channel/SubChannel/Organic-Paid updated for DateID ≥ 2019-01-01 |
| **Fake FTD exclusion** | Aug 2025 fraudulent FTDs (Amount=1) excluded via #NotValidCustomer |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Sparse matrix** | Most AffiliateID×CountryID×DateID×Funnel combinations have NULL metrics. Always filter on specific metrics (WHERE FTD > 0 or WHERE TotalCost > 0) for analysis |
| **FTD scope** | FTD column = affiliate-attributed Fiktivo FTDs only. For platform-wide FTD counts, use BI_DB_LiveAcquisitionDashboard |
| **FTDA scope** | FTDA = Tier-1 CPA credit amounts, not total deposit revenue. For total deposits use TotalDeposit |
| **Channel retroactive** | Channel/SubChannel values for DateID ≥ 2019-01-01 reflect current Dim_Channel classifications (may differ from original channel at acquisition time) |
| **Funnel = 'Undefined'** | Customers without a valid Funnel mapping (no FunnelFromID or unresolved PlatformID) are grouped under 'Undefined' |
| **CLUSTERED INDEX on DateID** | Optimal filter is DateID range. Use varchar(8) comparison (e.g., WHERE DateID >= '20260101') |
| **LTV_NoExtreme** | Populated by a separate SP — may lag 1 day behind other metrics |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Marketing / Acquisition Performance |
| **Sub-domain** | Affiliate Marketing Cube (Daily Grain) |
| **Sensitivity** | No CID — no direct PII. AffiliateID is partner-level |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 52, Object #2*
*Phases: P1 ✓ P2 ✓ P3 ✓ P8 ✓ P9 ✓ P10A ✓ P10B ✓ P11 ✓*
*T1: 0 (dimension tables have no upstream wiki) | T2: 39 | T3: 10 | Propagation: 1*
