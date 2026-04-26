# BI_DB_dbo.BI_DB_LiveAcquisitionDashboard

## 1. Overview

Live intraday acquisition dashboard combining **same-day hourly customer events** with a **rolling ~90-day historical archive**. Each row represents one customer acquisition event — a Registration or First-Time Deposit (FTD) — enriched with full marketing attribution: affiliate group, channel, funnel, country, and conversion-speed metrics. Rebuilt from scratch on every hourly run (TRUNCATE + INSERT). History is in the sibling table `BI_DB_LiveAcquisitionDashboard_Daily`.

**Row grain**: One CID × Date × KPI event (Registration or FTDs)

---

## 2. Business Context

`BI_DB_LiveAcquisitionDashboard` is the primary real-time acquisition dashboard for the Marketing and Acquisition teams. It is refreshed hourly by `SP_H_LiveAcquisitionDashboard` (P0 Hourly), which stitches together:

1. **Live intraday data** (≥ @MinDate+1 day): sourced from `External_etoro_DWH_V_CustomerCustomerHourly`, an external table backed by the hourly lake copy of `etoro.Customer.Customer`. FTDs additionally join `LiveAcquisition_Billing_Deposit_Hourly_Range` (created fresh each run by `SP_Create_External_etoro_billing_deposit_hourly_Range`) to confirm IsFTD=1 and PaymentStatusID=2 (Approved).
2. **Historical data** (≤ @MinDate+1): sourced from `BI_DB_LiveAcquisitionDashboard_Daily` (daily frozen snapshot), enriched with `DWH_dbo.Dim_Customer` for FunnelID/CountryID that may be missing from the daily archive.

The table always reflects a rolling window (as of April 2026: 2026-01-12 → 2026-04-13, 1,483,806 rows across 92 distinct dates).

**Key business rules**:
- **KPI types**: `'Registration'` (91.6%, ~1.36M rows) — customer completes sign-up; `'FTDs'` (8.4%, ~125K rows) — first successful deposit (IsFTD=1, PaymentStatusID=2).
- **Exclusion filter**: Popular Investors (PlayerLevelID=4), LabelID=30, and CountryID=250 are excluded from all rows.
- **Fast FTD**: `Fast=1` means FTD placed exactly 1 calendar day after registration (midnight boundary). `Fast24H=1` means within 24 hours of registration time.
- **RegToFTDBuckets**: Segments FTD customers by time to first deposit. Observed distribution: SameDay 41%, OldReg 28%, Same Month 10%, 1 Day 9%, Same Week 8%, 2Days 4%.
- **NULL semantics**: FTD-only columns (FTDA, Fast, Fast24H, RegToFTDBuckets, RegToFTD) are NULL for Registration rows.
- **CID is not unique**: A customer in the rolling window may have both a Registration and FTD row. Always include KPI in GROUP BY.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 22 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | CID ASC |
| **Row Count** | ~1.48M (rolling ~90 days) |
| **Date Range** | 2026-01-12 → 2026-04-13 (92 distinct dates, Apr 2026 sample) |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | AffiliatesGroupsName | nvarchar(100) | YES | Affiliate group name the customer was acquired through. Resolved from `DWH_dbo.Dim_Affiliate.AffiliatesGroupsName` via SerialID = AffiliateID JOIN. Groups individual affiliate partners into their parent network (e.g., "Adtraction", "Google"). NULL for direct/organic registrations without affiliate attribution. (Tier 2 — Dim_Affiliate.AffiliatesGroupsName) |
| 2 | Contact | nvarchar(1000) | YES | Primary contact or campaign identifier for the affiliate partner. Resolved from `DWH_dbo.Dim_Affiliate.Contact`. Used for sub-campaign attribution within the affiliate group. NULL when SerialID is unmatched or NULL. (Tier 2 — Dim_Affiliate.Contact) |
| 3 | Channel | nvarchar(100) | YES | Top-level marketing channel category resolved from `DWH_dbo.Dim_Channel.Channel` via Dim_Affiliate.SubChannelID. Observed values: Direct (60%), SEM (17%), SEO (10%), Affiliate (6%), Friend Referral (3.5%), Media Performance, Mobile Acquisition, Content Partnerships, Sponsorships, TV. (Tier 2 — Dim_Channel.Channel) |
| 4 | SubChannel | nvarchar(100) | YES | Granular sub-channel name within the parent Channel, from `DWH_dbo.Dim_Channel.SubChannel`. Human-readable label (e.g., 'Google Brand', 'Google Search', 'FB', 'Taboola', 'SEO', 'Affiliate'). (Tier 2 — Dim_Channel.SubChannel) |
| 5 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. From `etoro.Customer.CustomerStatic.CID` via `External_etoro_DWH_V_CustomerCustomerHourly`. NOT unique in this table — a customer can have two rows (one Registration, one FTD row) within the rolling window. (Tier 1 — etoro.Customer.Customer.CID) |
| 6 | Date | datetime | YES | Event datetime. For `KPI='FTDs'`: FTD timestamp (Billing.Deposit.ModificationDate — the deposit approval datetime). For `KPI='Registration'`: registration datetime (Customer.CustomerStatic.Registered). Historical rows carry the original event timestamp from `BI_DB_LiveAcquisitionDashboard_Daily`. (Tier 1 — etoro.Customer.Customer.Registered / etoro.Billing.Deposit.ModificationDate) |
| 7 | CountryID | int | YES | Country of residence. FK concept to Dictionary.Country. From `etoro.Customer.CustomerStatic.CountryID` via External (live) or `DWH_dbo.Dim_Customer.CountryID` (historical). Determines regulatory framework, available instruments, and leverage limits. Customers with CountryID=250 are excluded by population filter. (Tier 1 — etoro.Customer.Customer.CountryID) |
| 8 | Region | varchar(100) | YES | Marketing region name — manually curated override maintained by the Marketing team (`DWH_dbo.Dim_Country.MarketingRegionManualName`). May differ from standard geographic regions. Not suitable for regulatory analysis. (Tier 3 — Dim_Country.MarketingRegionManualName) |
| 9 | Country | varchar(100) | YES | Full country name in English from `DWH_dbo.Dim_Country.Name`. Top values: United Kingdom, France, Germany, Italy, Spain, United States, Argentina, UAE, Australia, Colombia. (Tier 1 — Dictionary.Country) |
| 10 | Fast | int | YES | FTD speed flag: 1 if the FTD was placed exactly 1 calendar day after registration (DATEDIFF(DAY, Registered, Date) = 1), else 0. Uses midnight-to-midnight boundary — NOT equivalent to "within 24 hours" (see Fast24H). Always 0 for `KPI='Registration'` rows. NULL in historical path if not populated. (Tier 2 — SP_H_LiveAcquisitionDashboard, DATEDIFF(DAY)=1) |
| 11 | Fast24H | int | YES | FTD speed flag: 1 if the FTD occurred within 0–24 hours of registration (DATEDIFF(HOUR, Registered, Date) BETWEEN 0 AND 24), else 0. More time-accurate than Fast: captures same-day deposits that Fast misses. ~51K FTDs qualify (41% of all FTDs). Always 0 for `KPI='Registration'` rows. (Tier 2 — SP_H_LiveAcquisitionDashboard, DATEDIFF(HOUR) BETWEEN 0 AND 24) |
| 12 | KPI | nvarchar(100) | YES | Event type discriminator. Values: 'Registration' (91.6%, 1,358,954 rows) or 'FTDs' (8.4%, 124,852 rows). Hardcoded literal injected by SP at temp table construction. Controls NULL semantics for FTD-specific columns (FTDA, Fast, Fast24H, RegToFTDBuckets, RegToFTD). Always include in GROUP BY or WHERE to avoid mixing event types. (Tier 2 — SP_H_LiveAcquisitionDashboard literal) |
| 13 | FTDA | money | YES | First deposit amount in USD. Computed as `Billing.Deposit.Amount × ExchangeRate` for live intraday data. Carried from `BI_DB_LiveAcquisitionDashboard_Daily.FTDA` for historical rows. NULL for all `KPI='Registration'` rows. (Tier 1 — etoro.Billing.Deposit.Amount × ExchangeRate) |
| 14 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired. FK concept to `DWH_dbo.Dim_Affiliate.AffiliateID`. From `etoro.Customer.CustomerStatic.SerialID`. NULL for direct/organic registrations. (Tier 1 — etoro.Customer.Customer.SerialID) |
| 15 | SubSerialID | varchar(1024) | YES | Sub-affiliate identifier string for complex tracking paths within an affiliate network (up to 1024 chars). From `etoro.Customer.CustomerStatic.SubSerialID`. NULL for direct/organic. (Tier 1 — etoro.Customer.Customer.SubSerialID) |
| 16 | DownloadID | int | YES | Platform download source ID. Legacy tracking for which platform installer or app download the customer used at registration. From `etoro.Customer.CustomerStatic.DownloadID`. NULL when no download attribution. (Tier 1 — etoro.Customer.Customer.DownloadID) |
| 17 | FunnelName | varchar(100) | YES | Human-readable name for the acquisition funnel the customer entered at registration. Resolved from `DWH_dbo.Dim_Funnel.Name` on FunnelID (from Customer record). NULL if no funnel was assigned. (Tier 1 — etoro.Customer.Customer.FunnelID → Dim_Funnel.Name) |
| 18 | FunnelFromName | varchar(100) | YES | Human-readable name for the source funnel (the funnel from which the customer was referred into the registration funnel). LEFT JOIN on `DWH_dbo.Dim_Funnel.Name` via FunnelFromID. NULL when no source funnel recorded. (Tier 1 — etoro.Customer.Customer.FunnelFromID → Dim_Funnel.Name) |
| 19 | RegToFTDBuckets | varchar(100) | YES | CASE-bucketed categorization of days from registration to FTD. FTDs only — NULL for `KPI='Registration'` rows. Observed values and distribution: SameDay (41%), OldReg (28%), Same Month (10%), 1 Day (9%), Same Week (8%), 2Days (4%). Based on DATEDIFF(DAY, Registered, Date). (Tier 2 — SP_H_LiveAcquisitionDashboard CASE expression) |
| 20 | RegToFTD | varchar(100) | YES | Raw integer days from registration to FTD stored as VARCHAR (DATEDIFF(DAY, Registered, Date)). FTDs only — NULL for `KPI='Registration'` rows. Use CAST to INT for numeric comparisons. (Tier 2 — SP_H_LiveAcquisitionDashboard) |
| 21 | State | varchar(100) | YES | State, province, or territory name from `DWH_dbo.Dim_State_and_Province.Name`, resolved via customer's IP-derived RegionID. LEFT JOIN — NULL for ~91.7% of rows (countries without state-level IP mapping). Non-NULL top values: Lombardia, New South Wales, Victoria, Lazio, California. (Tier 3 — Dim_State_and_Province.Name) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded by the ETL pipeline. Set to GETDATE() at each hourly INSERT. Not a business timestamp — reflects last SP_H_LiveAcquisitionDashboard run time. (Propagation — GETDATE()) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| External_etoro_DWH_V_CustomerCustomerHourly | BI_DB_dbo | Primary live source — hourly lake copy of etoro.Customer.Customer |
| BI_DB_LiveAcquisitionDashboard_Daily | BI_DB_dbo | Historical source — daily frozen snapshot; anchor for @MinDate |
| LiveAcquisition_Billing_Deposit_Hourly_Range | BI_DB_dbo | Intraday billing deposits staging (created fresh each run by SP_Create_External_etoro_billing_deposit_hourly_Range) |
| DWH_dbo.Dim_Customer | DWH_dbo | Historical path only: enriches daily rows with RegisteredReal, FunnelID, FunnelFromID, CountryID, RegionID |
| DWH_dbo.Dim_Country | DWH_dbo | Region, Country name resolution (final INSERT) |
| DWH_dbo.Dim_Affiliate | DWH_dbo | AffiliatesGroupsName, Contact (via SerialID = AffiliateID) |
| DWH_dbo.Dim_Channel | DWH_dbo | Channel, SubChannel (via Dim_Affiliate.SubChannelID) |
| DWH_dbo.Dim_Funnel | DWH_dbo | FunnelName (FunnelID) and FunnelFromName (FunnelFromID) — two separate JOINs |
| DWH_dbo.Dim_State_and_Province | DWH_dbo | State name (via RegionID = RegionByIP_ID) |

### Sibling Tables

| Table | Relationship |
|-------|-------------|
| BI_DB_LiveAcquisitionDashboard_Daily | Daily frozen snapshot; this table extends it intraday. Also used as Leg 3 historical input into this table each hour |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_H_LiveAcquisitionDashboard |
| **ETL Pattern** | TRUNCATE + INSERT (full refresh) |
| **Schedule** | Hourly (P0 — OpsDB Hourly) |
| **Anchor** | @MinDate = MAX(CAST(Date AS DATE)) FROM BI_DB_LiveAcquisitionDashboard_Daily |
| **Live data** | ≥ @MinDate+1 day — from External_etoro_DWH_V_CustomerCustomerHourly |
| **Historical data** | ≤ @MinDate+1 — from BI_DB_LiveAcquisitionDashboard_Daily + Dim_Customer |
| **Billing staging** | SP_Create_External_etoro_billing_deposit_hourly_Range creates LiveAcquisition_Billing_Deposit_Hourly_Range each run |
| **SP_H_LiveAcquisitionDashboard_New** | Dead stub (PRINT 'Hello World' only) — not the active writer |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Always filter on KPI** | `WHERE KPI='FTDs'` or `WHERE KPI='Registration'` — mixing row types produces misleading aggregates |
| **FTD-only columns are NULL for Registration** | Fast, Fast24H, FTDA, RegToFTDBuckets, RegToFTD are NULL for all Registration rows |
| **CID not unique** | A customer may have both Registration and FTD rows; GROUP BY must include KPI |
| **Fast ≠ Fast24H** | Fast uses calendar-day midnight boundary; Fast24H uses 0–24 hour elapsed time |
| **ROUND_ROBIN** | No distribution colocation benefit; add WHERE Date filter first |
| **Intraday freshness** | Table may be empty momentarily during hourly TRUNCATE+INSERT |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Acquisition / Marketing |
| **Sub-domain** | Live Intraday Acquisition Dashboard |
| **Sensitivity** | Contains CID — PII-adjacent |
| **Quality Score** | 8.6 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 52, Object #1*
*Phases: P1 ✓ P2 ✓ P3 ✓ P8 ✓ P9 ✓ P10A ✓ P10B ✓ P11 ✓*
*T1 columns: 9 (CID, Date, CountryID, Country, FTDA, SerialID, SubSerialID, DownloadID, FunnelName/FunnelFromName) | T2: 7 | T3: 4 | Propagation: 1*
