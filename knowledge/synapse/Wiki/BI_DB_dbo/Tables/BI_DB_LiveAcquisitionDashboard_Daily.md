# BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily

> Rolling 90-day live acquisition dashboard tracking customer registrations and first-time deposits across affiliate, channel, country, and funnel dimensions (17 cols, ~1.47M rows, refreshed daily). Written by `SP_LiveAcquisitionDashboard_Daily` from `DWH_dbo.Dim_Customer` via UNION ALL of FTD and Registration events. Supports acquisition monitoring and affiliate performance reporting with two KPI types per customer event.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Dim_Customer` ← Customer.CustomerStatic + CustomerFinanceDB.FirstTimeDeposits via SP_LiveAcquisitionDashboard_Daily |
| **Refresh** | Daily SB_Daily (rolling 90-day DELETE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Amir Gurewitz (2021-03-17) |
| **Row Count** | ~1.47M (rolling 90 days — 2026-01-12 to 2026-04-11 as of 2026-04-22) |

---

## 1. Business Meaning

`BI_DB_LiveAcquisitionDashboard_Daily` is a rolling 90-day acquisition dashboard for the Marketing/Acquisition team. Each row represents a customer acquisition event — either a new account registration or a first-time deposit (FTD) — enriched with affiliate, channel, country, funnel, and regional dimensions.

The table maintains only the most recent 90 days of events: every daily run deletes all rows and reloads the latest 90-day window from `Dim_Customer`. As of 2026-04-22, it covers 2026-01-12 to 2026-04-11 (~1.47M rows).

**Two KPI row types** coexist in the same table, distinguished by the `KPI` column:
- **`KPI='Registration'`** (91.6% of rows, ~1.35M): customer registered a real account (`RegisteredReal`); `FTDA` is NULL
- **`KPI='FTDs'`** (8.4% of rows, ~124K): customer made their first deposit (`FirstDepositDate`); `FTDA` = amount

The same customer may have two rows (one Registration + one FTD) if both events fall within the 90-day window. Both rows share the same acquisition metadata (affiliate, channel, funnel) from `Dim_Customer`, but have different `Date` and `FTDA` values.

Only `IsValidCustomer=1` customers are included. Top FTD regions: UK (27K), Spain (13K), French (12K), Italian (11K), CEE (11K).

---

## 2. Business Logic

### 2.1 Rolling 90-Day Window

**What**: The table always contains the most recent 90 days of customer acquisition events — it is NOT a historical archive.

**Columns Involved**: Date, KPI, FTDA, CID

**Rules**:
- On each daily run with @date (today): `DELETE WHERE Date <= @date` — removes all existing rows
- Re-inserts all events where `FirstDepositDate >= @date - 90 days AND < @date` (FTDs) or `RegisteredReal >= @date - 90 days AND < @date` (Registrations)
- Window: `[@date - 90 days, @date)` — excludes @date itself (yesterday is max)
- Do NOT use this table for historical analysis beyond 90 days. Use `Dim_Customer` directly for long-term trends.

### 2.2 UNION ALL Two KPI Types

**What**: The SP combines FTD events and Registration events via UNION ALL, creating one unified stream with a `KPI` discriminator.

**Columns Involved**: KPI, Date, FTDA, CID

**Rules**:
- `KPI='FTDs'`: `Date = FirstDepositDate`, `FTDA = FirstDepositAmount` — real money deposited
- `KPI='Registration'`: `Date = RegisteredReal`, `FTDA = NULL` — account creation date
- A customer who registered and made their first deposit both within the 90-day window will have TWO rows with the same CID, different Date and KPI values
- Filter `KPI='FTDs'` to compute conversion rates; filter `KPI='Registration'` for registration-only analysis
- Both halves apply `IsValidCustomer=1` — customers who fail validity checks are excluded from both KPIs

### 2.3 Affiliate and Channel Attribution

**What**: Each row carries the customer's acquisition channel and affiliate attributes for marketing attribution reporting.

**Columns Involved**: AffiliatesGroupsName, Contact, Channel, SubChannel, SerialID, SubSerialID, DownloadID

**Rules**:
- `SerialID` = `Dim_Customer.AffiliateID` = `Customer.CustomerStatic.SerialID` — identifies the affiliate who drove the acquisition
- `SubSerialID` = sub-campaign tracking string within the affiliate (e.g., campaign name)
- `DownloadID` = app install / download attribution ID (mobile acquisition tracking)
- `AffiliatesGroupsName` and `Contact` come from `Dim_Affiliate` — the affiliate group name and contact/campaign tag from the AffWizz affiliate management system
- `Channel` / `SubChannel` from `Dim_Channel` — standardized channel taxonomy (e.g., SEM > Google Brand, Direct > Organic, Affiliate > Adtraction)
- Attribution is at the customer level — reflects the channel/affiliate set at registration in Dim_Customer (does not change if customer later makes FTD via different attribution)

### 2.4 Geographic Dimensions

**What**: Country, Region, and State provide geographic segmentation for acquisition analysis.

**Columns Involved**: Country, Region, State

**Rules**:
- `Country` = `Dim_Country.Name` — full country name from customer's `CountryID` at registration
- `Region` = `Dim_Country.MarketingRegionManualName` — manually curated marketing region (e.g., UK, Spain, French, Italian, CEE). Not a standardized dimension — values are managed by the Marketing team
- `State` = `Dim_State_and_Province.Name` — state/province derived from customer's IP at registration (`RegionID`); NULL when no IP match

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN. Clustered on CID — optimized for customer-level lookups but NOT for date-range scans. Since most dashboard queries filter on Date, expect full-table scans for date filters on a 1.47M-row table. For better performance, also filter on Channel or Region to reduce data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Daily FTDs by channel | `SELECT Date, Channel, COUNT(CID), SUM(FTDA) WHERE KPI='FTDs' GROUP BY Date, Channel ORDER BY Date DESC` |
| Registration-to-FTD conversion (same 90-day cohort) | `SELECT Channel, COUNT(CASE WHEN KPI='FTDs' THEN 1 END)*1.0 / COUNT(CASE WHEN KPI='Registration' THEN 1 END) WHERE KPI IN ('FTDs','Registration') GROUP BY Channel` |
| Affiliate performance by region | `SELECT AffiliatesGroupsName, Region, COUNT(CID) FTDs, SUM(FTDA) TotalDeposited WHERE KPI='FTDs' GROUP BY AffiliatesGroupsName, Region ORDER BY TotalDeposited DESC` |
| Check data freshness | `SELECT MAX(Date), MAX(UpdateDate) FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard_Daily]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile enrichment |
| DWH_dbo.Dim_Affiliate | SerialID = AffiliateID | Full affiliate contract/performance details |
| DWH_dbo.Dim_Channel | (via Dim_Customer SubChannelID) | Not directly joinable — Channel/SubChannel are already denormalized |

### 3.4 Gotchas

- **Rolling 90-day window — no history**: The table is completely replaced daily. Any row more than 90 days old is gone. Do NOT use for YTD or year-over-year analysis.
- **Two rows per customer possible**: If a customer both registered AND made their first deposit in the 90-day window, they have two rows (one per KPI type). Always include `KPI` in GROUP BY or WHERE to avoid double-counting.
- **CLUSTERED INDEX on CID, not Date**: Despite being a "daily" dashboard, the clustered index is on CID (customer). Date-range queries trigger full-table scans. Always add OPTION (LABEL = 'query hint') or partition results downstream.
- **Date is KPI-type-dependent**: For FTDs rows, Date = FirstDepositDate. For Registration rows, Date = RegisteredReal. These are different events — do not compare dates across KPI types naively.
- **Region is marketing-curated (MarketingRegionManualName)**: Not a standardized geographic dimension. Values are managed by the Marketing team and may change independently of country. UK ≠ United Kingdom in this column.
- **`@Days` declared but unused**: The SP declares `@Days = DATEADD(DAY,-1,@date)` but this variable is never used in the actual query logic. It appears to be a leftover from a prior logic version (per Change History). The actual cutoff is `< @date` (not `<= @Days`).
- **FunnelFromName is LEFT JOINed**: Customers without a FunnelFromID will have `FunnelFromName = NULL`. Do not filter on FunnelFromName without accounting for NULLs.
- **FTDA is NULL for Registrations**: Never use AVG(FTDA) without filtering `KPI='FTDs'` first — NULLs from Registration rows will be excluded from AVG but will inflate COUNT(*) if mixed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from production source wiki (Dictionary.Country) — passthrough |
| Tier 2 | From ETL SP code, DWH dimensions, or Dim_Customer column analysis |
| Tier 3 | ETL infrastructure (GETDATE(), system columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliatesGroupsName | nvarchar(1000) | YES | Affiliate group/network name from `DWH_dbo.Dim_Affiliate.AffiliatesGroupsName` (AffWizz affiliate management system). Groups individual affiliates into their parent network (e.g., "Adtraction", "Google"). (Tier 2 — Dim_Affiliate via SP_LiveAcquisitionDashboard_Daily) |
| 2 | Contact | nvarchar(1000) | YES | Affiliate contact/campaign identifier from `DWH_dbo.Dim_Affiliate.Contact`. Typically a campaign tag or affiliate contact string used for sub-campaign attribution. (Tier 2 — Dim_Affiliate via SP_LiveAcquisitionDashboard_Daily) |
| 3 | Channel | nvarchar(100) | YES | Marketing acquisition channel from `DWH_dbo.Dim_Channel.Channel` (e.g., SEM, Direct, Affiliate, Social). Standardized marketing taxonomy. (Tier 2 — Dim_Channel via SP_LiveAcquisitionDashboard_Daily) |
| 4 | SubChannel | nvarchar(100) | YES | Marketing sub-channel from `DWH_dbo.Dim_Channel.SubChannel` (e.g., Google Brand, FB, Taboola, Organic). More granular channel split. (Tier 2 — Dim_Channel via SP_LiveAcquisitionDashboard_Daily) |
| 5 | CID | bigint | YES | Customer identifier (RealCID from Dim_Customer). Platform-internal primary key assigned at registration. (Tier 2 — Dim_Customer.RealCID via SP_LiveAcquisitionDashboard_Daily) |
| 6 | Date | datetime | YES | Event date. Meaning depends on KPI: for KPI='FTDs' → FirstDepositDate; for KPI='Registration' → RegisteredReal. Range: rolling 90 days from load date. (Tier 2 — Dim_Customer.FirstDepositDate or Dim_Customer.RegisteredReal) |
| 7 | Region | varchar(100) | YES | Marketing region name from `DWH_dbo.Dim_Country.MarketingRegionManualName` — manually curated marketing-team region. Not a standard geographic boundary. Top values: UK, Spain, French, Italian, CEE. (Tier 2 — Dim_Country.MarketingRegionManualName) |
| 8 | Country | varchar(100) | YES | Full country name in English from `DWH_dbo.Dim_Country.Name` based on customer's registered CountryID. (Tier 1 — Dictionary.Country via Dim_Country) |
| 9 | KPI | nvarchar(100) | YES | Event type discriminator: 'FTDs' (first-time deposit event) or 'Registration' (real account registration event). Hardcoded in the SP's UNION ALL branches. (Tier 2 — SP_LiveAcquisitionDashboard_Daily hardcoded literal) |
| 10 | FTDA | money | YES | First deposit amount in USD. Populated only for KPI='FTDs' rows from `Dim_Customer.FirstDepositAmount`. NULL for KPI='Registration' rows. (Tier 2 — Dim_Customer.FirstDepositAmount via CustomerFinanceDB.Customer.FirstTimeDeposits) |
| 11 | SerialID | int | YES | Affiliate ID — acquisition affiliate/partner identifier. From `Dim_Customer.AffiliateID` (= Customer.CustomerStatic.SerialID). FK to `DWH_dbo.Dim_Affiliate`. (Tier 2 — Dim_Customer.AffiliateID) |
| 12 | SubSerialID | varchar(1024) | YES | Sub-affiliate campaign tracking string from `Dim_Customer.SubSerialID`. Allows affiliates to track sub-campaigns or sub-partners within their attribution. (Tier 2 — Dim_Customer.SubSerialID) |
| 13 | DownloadID | int | YES | App download/install attribution ID from `Dim_Customer.DownloadID`. Used for mobile app acquisition tracking. (Tier 2 — Dim_Customer.DownloadID) |
| 14 | FunnelName | varchar(100) | YES | Name of the acquisition funnel the customer entered, from `DWH_dbo.Dim_Funnel.Name` on `Dim_Customer.FunnelID`. NULL if no funnel. (Tier 2 — Dim_Funnel.Name via Dim_Customer.FunnelID) |
| 15 | FunnelFromName | varchar(100) | YES | Name of the source funnel (referral funnel), from `DWH_dbo.Dim_Funnel.Name` on `Dim_Customer.FunnelFromID`. LEFT JOIN — NULL when no source funnel. (Tier 2 — Dim_Funnel.Name via Dim_Customer.FunnelFromID) |
| 16 | State | varchar(100) | YES | State/province name from `DWH_dbo.Dim_State_and_Province.Name` on `Dim_Customer.RegionID`. Derived from customer's IP at registration. LEFT JOIN — NULL when no IP region match. (Tier 2 — Dim_State_and_Province.Name via Dim_Customer.RegionID) |
| 17 | UpdateDate | datetime | YES | Batch timestamp set to GETDATE() at INSERT time. Reflects when the SP last ran. (Tier 3 — GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Country | Dictionary.Country | Name | JOIN Dim_Country on CountryID |
| CID | Customer.CustomerStatic | CID | Via Dim_Customer.RealCID |
| Date (FTDs) | CustomerFinanceDB.Customer.FirstTimeDeposits | FirstDepositDate | Via Dim_Customer.FirstDepositDate |
| Date (Registration) | Customer.CustomerStatic | Registered | Via Dim_Customer.RegisteredReal |
| FTDA | CustomerFinanceDB.Customer.FirstTimeDeposits | FirstDepositAmount | Via Dim_Customer.FirstDepositAmount |
| SerialID | Customer.CustomerStatic | SerialID | Via Dim_Customer.AffiliateID |
| SubSerialID | Customer.CustomerStatic | SubSerialID | Via Dim_Customer.SubSerialID |
| DownloadID | Customer.CustomerStatic | DownloadID | Via Dim_Customer.DownloadID |
| Channel, SubChannel | fiktivo_dbo.tblaff_Affiliates (AffWizz) | Channel, SubChannel | Via Dim_Channel on SubChannelID |
| AffiliatesGroupsName, Contact | fiktivo_dbo.tblaff_Affiliates (AffWizz) | AffiliatesGroupsName, Contact | Via Dim_Affiliate on AffiliateID |
| Region | Dictionary.Country | MarketingRegionManualName | Via Dim_Country on CountryID |
| UpdateDate | ETL | GETDATE() | Batch timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1)
  UNION ALL:
    FTD events: FirstDepositDate in [t-90, t) → KPI='FTDs', FTDA=FirstDepositAmount
    Registration events: RegisteredReal in [t-90, t) → KPI='Registration', FTDA=NULL
  + JOIN Dim_Country (CountryID → Country, Region)
  + LEFT JOIN Dim_State_and_Province (RegionID → State)
  + JOIN Dim_Channel (SubChannelID → Channel, SubChannel)
  + LEFT JOIN Dim_Funnel (FunnelID → FunnelName; FunnelFromID → FunnelFromName)
  + JOIN Dim_Affiliate (AffiliateID → AffiliatesGroupsName, Contact)
         |-- SP_LiveAcquisitionDashboard_Daily @date ---|
         |   (DELETE WHERE Date <= @date, then INSERT 90-day window)
         v
BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily (~1.47M rows, rolling 90 days)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identity source |
| SerialID | DWH_dbo.Dim_Affiliate.AffiliateID | Affiliate partner attribution |
| Channel/SubChannel | DWH_dbo.Dim_Channel | Channel taxonomy (denormalized) |
| Country/Region | DWH_dbo.Dim_Country | Country/region lookup (denormalized) |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|--------|----------|
| BI_DB_LiveAcquisitionDashboard | Parent table — full historical; this Daily table is the rolling 90-day live layer |
| Acquisition / Marketing dashboards | Direct source for real-time acquisition monitoring |

---

## 7. Sample Queries

### 7.1 Daily FTD count and deposit volume by channel (last 30 days)
```sql
SELECT CAST(Date AS DATE) AS EventDate,
       Channel, SubChannel,
       COUNT(CID) AS FTDs,
       SUM(FTDA) AS TotalDeposited,
       AVG(FTDA) AS AvgFTDA
FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard_Daily]
WHERE KPI = 'FTDs'
  AND Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(Date AS DATE), Channel, SubChannel
ORDER BY EventDate DESC, TotalDeposited DESC;
```

### 7.2 Registration-to-FTD conversion rate by region
```sql
SELECT Region,
       SUM(CASE WHEN KPI = 'Registration' THEN 1 ELSE 0 END) AS Registrations,
       SUM(CASE WHEN KPI = 'FTDs' THEN 1 ELSE 0 END) AS FTDs,
       CAST(SUM(CASE WHEN KPI = 'FTDs' THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(SUM(CASE WHEN KPI = 'Registration' THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS ConversionPct
FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard_Daily]
GROUP BY Region
ORDER BY FTDs DESC;
```

### 7.3 Top affiliates by FTD volume (current window)
```sql
SELECT AffiliatesGroupsName, Contact, Channel,
       COUNT(CID) AS FTDs,
       SUM(FTDA) AS TotalDeposited
FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard_Daily]
WHERE KPI = 'FTDs'
GROUP BY AffiliatesGroupsName, Contact, Channel
ORDER BY TotalDeposited DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 1 T1, 15 T2, 1 T3, 0 T4 | Elements: 17/17, Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily | Type: Table | Production Source: DWH_dbo.Dim_Customer (rolling 90-day acquisition events)*
