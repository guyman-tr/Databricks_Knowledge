# BI_DB_dbo.BI_DB_MarketingMonthlyRawData

## 1. Overview

Monthly marketing performance cube — the **month-level aggregation** of `BI_DB_MarketingDailyRawData`. Each row is a SUM of all daily metrics for one AffiliateID × CountryID × YearMonth × Funnel combination. Replaces DateID/Date with YearMonthID (YYYYMM) and YearMonth (YYYY-MM). Extends the rolling window to ~5 years (vs. ~2 years for the daily table). See `BI_DB_MarketingDailyRawData.md` for full column descriptions — this document covers Monthly-specific details only.

**Row grain**: One AffiliateID × CountryID × YearMonthID × Funnel combination

---

## 2. Business Context

`BI_DB_MarketingMonthlyRawData` serves the same marketing performance analytics use case as the Daily table but at monthly granularity. It is populated by the same `SP_Marketing_Cube` in a second phase:

1. SP first writes/refreshes `BI_DB_MarketingDailyRawData` (daily grain, ~2-year window)
2. SP then DELETEs from `BI_DB_MarketingMonthlyRawData` where YearMonthID ≥ last month and rebuilds by `SELECT SUM(...) GROUP BY` from `BI_DB_MarketingDailyRawData`

**Key differences from Daily table**:
- **Date dimension**: YearMonthID (YYYYMM varchar(6)) + YearMonth (YYYY-MM varchar(7)) instead of DateID/Date
- **Window**: ~5 years retained (purge threshold = start of year 5 years ago). Monthly data: 202101 → 202604 (64 months as of Apr 2026)
- **All metrics are SUM aggregations**: All float/int/decimal metric columns are SUM(daily), not per-day values
- **LTV_NoExtreme not in SP INSERT**: Same behavior as Daily — populated by separate LTV SP
- **Channel retroactive UPDATE**: Same post-INSERT UPDATE pass correcting Channel/SubChannel/Organic-Paid

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 50 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | YearMonthID ASC |
| **Row Count** | ~2.37M (rolling ~5 years) |
| **Month Range** | 202101 → 202604 (64 months, Apr 2026 sample) |

---

## 4. Elements

**Note**: Columns 6-50 have identical business meaning to `BI_DB_MarketingDailyRawData` but represent monthly SUM aggregations. See that table's wiki for detailed per-column descriptions. Key differences for Monthly-specific columns are documented here.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | AffiliateID | int | NOT NULL | Affiliate (partner) ID. Part of grain key. From BI_DB_MarketingDailyRawData (same source). (Tier 2 — Dim_Affiliate.AffiliateID) |
| 2 | CountryID | int | NOT NULL | Country ID. Part of grain key. From BI_DB_MarketingDailyRawData. (Tier 2 — Dim_Country.CountryID) |
| 3 | YearMonthID | varchar(6) | YES | Month as YYYYMM string. Leading clustered index column. Derived from BI_DB_MarketingDailyRawData.DateID via CONVERT(VARCHAR(6), DateID, 112). Example: '202604'. (Tier 2 — Dim_Date.DateKey → YYYYMM) |
| 4 | YearMonth | varchar(7) | YES | Month as YYYY-MM string. Human-readable month label. Derived from BI_DB_MarketingDailyRawData.Date via CONVERT(VARCHAR(7), Date, 126). Example: '2026-04'. (Tier 2 — Dim_Date.FullDate → YYYY-MM) |
| 5 | Funnel | nvarchar(20) | YES | Platform/funnel category. Part of grain key. Values: 'Web', 'IOS', 'Android', 'Undefined'. Same as Daily. (Tier 2 — Dim_Platform.Platform) |
| 6 | CountryName | varchar(50) | NOT NULL | Country display name. GROUP BY passthrough from Daily. (Tier 3 — Dim_Country.Name) |
| 7 | Region | varchar(50) | NOT NULL | Geographic region. GROUP BY passthrough. (Tier 3 — Dim_Country.Region) |
| 8 | Desk | nvarchar(50) | YES | Country desk assignment. GROUP BY passthrough. (Tier 3 — Dim_Country.Desk) |
| 9 | DateCreated | datetime | NOT NULL | Affiliate account creation date. GROUP BY passthrough. (Tier 3 — Dim_Affiliate.DateCreated) |
| 10 | Channel | nvarchar(50) | NOT NULL | Marketing channel. GROUP BY passthrough + retroactive UPDATE pass. (Tier 3 — Dim_Channel.Channel) |
| 11 | SubChannel | varchar(100) | NOT NULL | Sub-channel. GROUP BY passthrough + retroactive UPDATE pass. (Tier 3 — Dim_Channel.SubChannel) |
| 12 | Organic/Paid | varchar(7) | YES | Organic/Paid classification. GROUP BY passthrough + retroactive UPDATE. (Tier 3 — Dim_Channel.[Organic/Paid]) |
| 13 | Contact | nvarchar(255) | YES | Affiliate contact identifier. GROUP BY passthrough. (Tier 3 — Dim_Affiliate.Contact) |
| 14 | ContractName | nvarchar(100) | YES | Affiliate contract name. GROUP BY passthrough. (Tier 3 — Dim_Affiliate.ContractName) |
| 15 | ContractType | varchar(20) | YES | Contract type description. GROUP BY passthrough. (Tier 3 — Dim_ContractType.Name) |
| 16 | AffiliatesGroupsName | nvarchar(50) | YES | Parent affiliate group name. GROUP BY passthrough. (Tier 3 — Dim_Affiliate.AffiliatesGroupsName) |
| 17 | AccountActivated | bit | NOT NULL | Affiliate account activated flag. GROUP BY passthrough. (Tier 3 — Dim_Affiliate.AccountActivated) |
| 18 | TotalCost | float | YES | Monthly total affiliate commission cost. SUM of daily TotalCost. (Tier 2 — Fiktivo commission pipeline) |
| 19 | RevShare_Comm | float | YES | Monthly revenue share commissions. SUM of daily. (Tier 2 — Fiktivo RevShare) |
| 20 | Chargebacks | float | YES | Monthly chargeback/refund commission credits. SUM of daily. (Tier 2 — Fiktivo chargebacks) |
| 21 | NumberOfChargebacks | int | YES | Monthly count of chargeback events. SUM of daily. (Tier 2 — Fiktivo) |
| 22 | CPA_Comm | float | YES | Monthly CPA commissions. SUM of daily. (Tier 2 — Fiktivo CPA credits) |
| 23 | CPL_Comm | float | YES | Monthly CPL commissions. SUM of daily. (Tier 2 — Fiktivo CPL leads) |
| 24 | eCost | float | YES | Monthly eCost. SUM of daily. (Tier 2 — Fiktivo eCost) |
| 25 | Tier2Commition | float | YES | Monthly Tier-2 sub-affiliate commissions. SUM of daily. Note: typo in column name. (Tier 2 — Fiktivo) |
| 26 | Tier3Commition | float | YES | Monthly Tier-3 sub-affiliate commissions. SUM of daily. Note: typo in column name. (Tier 2 — Fiktivo) |
| 27 | Registration | int | YES | Monthly registration count. SUM of daily. (Tier 2 — Fiktivo + Dim_Customer) |
| 28 | SameDayFTD | int | YES | Monthly same-day FTD count. SUM of daily. (Tier 2 — Fiktivo) |
| 29 | FTD | int | YES | Monthly affiliate-attributed FTD count. SUM of daily. (Tier 2 — Fiktivo AffiliateCommission_Credit) |
| 30 | EFTD | int | YES | Monthly eligible FTD count (Tier-1 CPA). SUM of daily. (Tier 2 — Fiktivo Tier=1) |
| 31 | FTDA | float | YES | Monthly FTD amount (Tier-1 CPA credits). SUM of daily. (Tier 2 — Fiktivo Tier=1 Amount) |
| 32 | NetRevenues | float | YES | Monthly net revenue. SUM of daily. (Tier 2 — Fiktivo ClosedPosition revenue) |
| 33 | VerificationLevelID2 | int | YES | Monthly count of customers reaching KYC level 2. SUM of daily. (Tier 2 — Dim_Customer) |
| 34 | VerificationLevelID3 | int | YES | Monthly count of customers reaching KYC level 3. SUM of daily. (Tier 2 — Dim_Customer) |
| 35 | Installs | int | YES | Monthly app installs. SUM of daily. (Tier 2 — BI_DB_AppFlyer_Reports) |
| 36 | TotalDeposit | decimal(38,2) | YES | Monthly total deposit amount. SUM of daily. (Tier 2 — Billing pipeline) |
| 37 | DBRev | decimal(38,2) | YES | Monthly DB Revenue. SUM of daily. (Tier 2 — DWH revenue pipeline) |
| 38 | RAF_Comm | decimal(38,2) | YES | Monthly RAF commission cost. SUM of daily. (Tier 2 — Fiktivo RAF) |
| 39 | IsRev | int | YES | Monthly count of FTDs who became revenue-generating. SUM of daily. (Tier 2 — BI_DB_CIDFirstDates) |
| 40 | Redeposits | int | YES | Monthly count of FTDs who redeposited. SUM of daily. (Tier 2 — BI_DB_CIDFirstDates) |
| 41 | PastGRevenue | float | YES | Legacy Optimove field. Always 0 (hardcoded in Monthly INSERT). (Tier 3 — legacy field) |
| 42 | GLTV | float | NOT NULL | Monthly Gross LTV. SUM of daily. Default 0. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 43 | FTDfromLTV | int | NOT NULL | Monthly FTD count from LTV model. SUM of daily. Default 0. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 44 | Rev10 | int | YES | Monthly Rev10 milestone count. SUM of daily. (Tier 2 — BI_DB_FirstTimeRev10) |
| 45 | UpdateDate | datetime | NOT NULL | ETL metadata: SP execution timestamp (GETDATE()). (Propagation — GETDATE()) |
| 46 | LTV_NoExtreme | numeric(38,6) | YES | LTV excluding outliers. Not in SP INSERT list — populated by separate LTV SP. (Tier 2 — BI_DB_LTV_BI_Actual, separate LTV SP) |
| 47 | NewMarketingRegion | varchar(100) | YES | Marketing team curated region. GROUP BY passthrough from Daily. (Tier 3 — Dim_Country.MarketingRegionManualName) |
| 48 | Lead_Comm | decimal(36,17) | YES | Monthly Lead commission. SUM of daily. Note: different type from Daily (decimal vs float). (Tier 2 — Fiktivo) |
| 49 | totalGroupLTV | int | YES | Monthly group LTV component. SUM of daily. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 50 | totalExtLTV | int | YES | Monthly extreme LTV component. SUM of daily. (Tier 2 — BI_DB_LTV_BI_Actual) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_MarketingDailyRawData | BI_DB_dbo | Primary and only source — SUM aggregation by month |
| DWH_dbo.Dim_Affiliate | DWH_dbo | Retroactive Channel/SubChannel UPDATE pass (same as Daily) |
| DWH_dbo.Dim_Channel | DWH_dbo | Retroactive UPDATE pass |

### Sibling Tables

| Table | Relationship |
|-------|-------------|
| BI_DB_MarketingDailyRawData | Daily sibling — this table is a monthly rollup of Daily |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Marketing_Cube (same SP as Daily, second phase) |
| **ETL Pattern** | DELETE-INSERT (reads from Daily table, writes Monthly) |
| **Schedule** | Daily (P0 — runs after Daily insert completes) |
| **Delete scope** | YearMonthID ≥ @StartOfLastMonthIDForMonthly (last month YYYYMM) AND YearMonthID < @StartOfYear5YearsBack |
| **Insert scope** | Aggregates from BI_DB_MarketingDailyRawData WHERE DateID >= @StartOfLastMonth |
| **Window kept** | ~5 years (start of year 5 years ago → current month) |
| **Post-INSERT UPDATE** | Channel/SubChannel/Organic-Paid updated from current Dim_Channel |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **All metrics are monthly sums** | Never divide metrics by 30 to get daily averages — use Daily table for daily analysis |
| **FTD scope** | Same as Daily: Fiktivo affiliate-attributed FTDs only |
| **CLUSTERED INDEX on YearMonthID** | Filter on YearMonthID (varchar(6)) for optimal performance. Use >= '202601' style comparisons |
| **Lead_Comm type difference** | Daily is float, Monthly is decimal(36,17) — this is a DDL inconsistency. Handle appropriately in joins/comparisons |
| **5-year window** | Monthly table extends further back than Daily — useful for multi-year trend analysis |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Marketing / Acquisition Performance |
| **Sub-domain** | Affiliate Marketing Cube (Monthly Grain) |
| **Sensitivity** | No CID — no direct PII |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 52, Object #3*
*Phases: P1 ✓ P2 ✓ P3 ✓ P8 ✓ P9 ✓ P10A ✓ P10B ✓ P11 ✓*
*T1: 0 | T2: 39 | T3: 10 | Propagation: 1 | Sibling wiki: BI_DB_MarketingDailyRawData.md*
