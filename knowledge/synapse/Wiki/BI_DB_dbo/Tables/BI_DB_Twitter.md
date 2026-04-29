# BI_DB_dbo.BI_DB_Twitter

> 408K-row Twitter (X) advertising campaign performance table tracking daily impressions, clicks, conversions, and cost by campaign and country from January 2020 to present. Merges Fivetran-ingested Twitter Ads data with AffiliateWizard registration/FTD attribution for eToro Twitter affiliates (52350/52351). Refreshed daily via SP_Twitter with a 30-day rolling DELETE+INSERT to capture late Twitter conversion attribution.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Twitter Ads (3 external tables: campaign_locations_report, account_history, campaign_history) + BI_DB_CIDFirstDates (AffWiz) + DWH_dbo.Dim_Country (geography) |
| **Refresh** | Daily (SP_Twitter, DELETE+INSERT rolling 30 days, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Twitter` is a 408K-row marketing analytics table that consolidates Twitter (X) advertising campaign performance data at daily × campaign × country granularity from January 2020 to present. Each row represents one day's performance metrics for a specific Twitter campaign in a specific country, including ad spend, impressions, clicks, and two independent conversion tracking sources.

The table merges two data streams via FULL OUTER JOIN:

1. **Twitter-reported metrics (TW)**: Impressions, clicks, app clicks, cost, and Twitter's own conversion tracking (registrations and first-time deposits via post-engagement + post-view attribution) — sourced from Fivetran-ingested Twitter Ads API data through three external tables.

2. **AffiliateWizard-tracked conversions (AW)**: Independently counted registrations and FTDs for customers attributed to Twitter affiliate IDs 52350 and 52351 — sourced from BI_DB_CIDFirstDates where SerialID matches these specific affiliates.

The SP deletes and reinserts a rolling 30-day window on each run to capture Twitter's late conversion attribution (conversions can be attributed days after the ad interaction). The date loops back from @date to @date-30 (minimum 2020-01-01), processing one day per iteration.

Geographic enrichment (Region, Desk, EU flag) is resolved from DWH_dbo.Dim_Country by matching the Twitter-reported country segment name. Platform (iOS/Android) is derived from campaign naming conventions.

---

## 2. Business Logic

### 2.1 Dual-Source Conversion Tracking

**What**: Two independent conversion counts allow reconciliation between Twitter's pixel-based attribution and eToro's internal AffiliateWizard tracking.
**Columns Involved**: `TW_Reg`, `TW_FTD`, `AW_Reg`, `AW_FTD`
**Rules**:
- TW_Reg = SUM(conversion_sign_ups_post_engagement + conversion_sign_ups_post_view) from Twitter Ads API
- TW_FTD = SUM(conversion_purchases_post_engagement + conversion_purchases_post_view) from Twitter Ads API
- AW_Reg = COUNT of customers registered on that date with SerialID IN (52350, 52351) from BI_DB_CIDFirstDates
- AW_FTD = COUNT of customers with FirstDepositDate on that date with same affiliate filter
- Discrepancies between TW and AW counts indicate attribution model differences (Twitter pixel vs internal server-side tracking)

### 2.2 AffiliateID Extraction from Campaign Name

**What**: Affiliate ID is embedded in Twitter campaign naming convention and extracted via string parsing.
**Columns Involved**: `AffiliateID`, `CampaignName`
**Rules**:
- For TW data: `SUBSTRING(CampaignName, CHARINDEX('AFFID', CampaignName) + 6, 5)` — extracts 5 characters after "AFFID_"
- For AW data: `SerialID` directly from CIDFirstDates (always 52350 or 52351)
- Campaign naming convention: `{CC}_{Type}_{Date}_TW_AFFID_{ID}_{Platform}_{Targeting}`
- Example: `UK_HF_Purchase_2026-01-01_TW_AFFID_52350_iOS` → AffiliateID = "52350"
- 7 distinct affiliate IDs in the data

### 2.3 Platform Detection from Campaign Name

**What**: Mobile platform is inferred from the campaign name, not from a dedicated field.
**Columns Involved**: `Platform`
**Rules**:
- `CASE WHEN LOWER(CampaignName) LIKE '%ios%' THEN 'iOS'`
- `WHEN LOWER(CampaignName) LIKE '%android%' THEN 'Android'`
- `ELSE NULL` — 62% of rows have NULL platform (desktop or untagged campaigns)

### 2.4 Rolling 30-Day Reload

**What**: The SP re-processes 30 days of data on each run to capture late Twitter conversion attribution.
**Columns Involved**: `Date`
**Rules**:
- DELETE WHERE Date >= @date-30 AND Date <= @date
- Re-insert day by day in a WHILE loop from @date back to @30_days_back
- Minimum date boundary: 2020-01-01
- Late conversions can arrive days after the ad interaction (post-view window)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no distribution key affinity. CLUSTERED INDEX on Date ASC provides efficient date-range scans. For date-filtered queries, use `WHERE [Date] BETWEEN @start AND @end` to leverage the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily Twitter ad spend by region | `SELECT [Date], Region, SUM(Cost) FROM BI_DB_Twitter GROUP BY [Date], Region` |
| Compare TW vs AW conversion counts | `SELECT [Date], SUM(TW_Reg) TW, SUM(AW_Reg) AW FROM BI_DB_Twitter GROUP BY [Date]` |
| Campaign performance breakdown | `SELECT CampaignName, SUM(Impressions), SUM(Clicks), SUM(Cost) GROUP BY CampaignName` |
| EU vs non-EU performance | `SELECT EU, SUM(Cost), SUM(TW_FTD) FROM BI_DB_Twitter GROUP BY EU` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | BI_DB_Twitter.Country = Dim_Country.Name | Additional geographic attributes (already embedded: Region, Desk, EU) |
| BI_DB_dbo.BI_DB_CIDFirstDates | CIDFirstDates.SerialID IN (52350,52351) AND Date filters | Drill to individual customer registrations/deposits for Twitter affiliates |

### 3.4 Gotchas

- **Platform NULL**: 62% of rows have NULL Platform — these are desktop campaigns or campaigns without iOS/Android in the name. Do NOT filter on Platform without accounting for NULLs
- **AW columns only for affiliates 52350/52351**: AW_Reg and AW_FTD are ONLY populated from CIDFirstDates for these two specific affiliate IDs. Other Twitter affiliates have AW_Reg=0 and AW_FTD=0
- **Country collation**: JOINs between Twitter segment names and Dim_Country use `COLLATE Latin1_General_100_BIN` — case-sensitive matching. Minor naming mismatches may cause NULL Region/Desk/EU
- **Cost precision**: Cost is `numeric(31,10)` from micro-units (divided by 1M). Very small fractional values (e.g., `0E-10`) appear for zero-spend rows
- **AccountID/Name empty**: AW-only rows (no Twitter impression data) have empty AccountID and AccountName strings, not NULL

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data + context |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for the campaign metrics. Derived from Twitter campaign_locations_report.date with +1 hour UTC adjustment (DATEADD(HOUR,1,date) cast to DATE). ISNULL merge: falls back to AW @date when TW data absent. Range: 2020-01-01 to present. (Tier 2 — SP_Twitter) |
| 2 | AccountID | nvarchar(256) | YES | Twitter Ads account identifier. From campaign_locations_report.account_id. ISNULL merge with AW side. Empty string (not NULL) for AW-only rows. 25 distinct accounts. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 3 | AccountName | nvarchar(256) | YES | Twitter Ads account display name. Latest version resolved from account_history via ROW_NUMBER PARTITION BY id ORDER BY updated_at DESC. Empty string for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_ads_account_history) |
| 4 | CampaignID | nvarchar(256) | YES | Twitter Ads campaign identifier. From campaign_locations_report.campaign_id. ISNULL merge with AW side. 1,620 distinct campaigns. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 5 | CampaignName | nvarchar(256) | YES | Twitter Ads campaign display name. Latest version resolved from campaign_history via ROW_NUMBER. Encodes metadata in naming convention: `{CC}_{Type}_{Date}_TW_AFFID_{ID}_{Platform}_{Targeting}`. Used to derive AffiliateID and Platform. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_history) |
| 6 | AffiliateID | nvarchar(5) | YES | eToro affiliate partner ID. For TW rows: extracted from CampaignName via SUBSTRING(CHARINDEX('AFFID')+6, 5). For AW rows: SerialID from CIDFirstDates (52350 or 52351). 7 distinct values. NULL when campaign name lacks AFFID tag. (Tier 2 — SP_Twitter) |
| 7 | Country | nvarchar(256) | YES | Country name. For TW rows: campaign_locations_report.segment (Twitter's geographic targeting). For AW rows: CIDFirstDates.Country (customer registration country). ISNULL merge. 237 distinct countries. (Tier 2 — SP_Twitter) |
| 8 | Region | nvarchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. Passthrough from Dim_Country. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country_Region_Desk via SP) |
| 10 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join — NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country live data) |
| 11 | Platform | varchar(7) | YES | Mobile platform derived from campaign name pattern matching. CASE WHEN LOWER(CampaignName) LIKE '%ios%' THEN 'iOS', LIKE '%android%' THEN 'Android', ELSE NULL. NULL=desktop or untagged (62% of rows). (Tier 2 — SP_Twitter) |
| 12 | Cost | numeric(31,10) | YES | Total advertising spend for this campaign-day-country in the campaign's local currency. Calculated as SUM(billed_charge_local_micro) / 1,000,000 (Twitter reports cost in micro-units). 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 13 | Impressions | bigint | YES | Total ad impressions served for this campaign-day-country. SUM aggregation from campaign_locations_report.impressions. 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 14 | App_Clicks | bigint | YES | Total app install button clicks for this campaign-day-country. SUM from campaign_locations_report.app_clicks. 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 15 | Clicks | bigint | YES | Total link clicks for this campaign-day-country. SUM from campaign_locations_report.clicks. 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 16 | TW_Reg | bigint | YES | Twitter-attributed registration count. SUM(conversion_sign_ups_post_engagement + conversion_sign_ups_post_view) — combines post-click and post-view attribution windows. 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 17 | TW_FTD | bigint | YES | Twitter-attributed first-time deposit count. SUM(conversion_purchases_post_engagement + conversion_purchases_post_view) — combines post-click and post-view attribution windows. 0 for AW-only rows. (Tier 2 — SP_Twitter, External_Fivetran_twitter_campaign_locations_report) |
| 18 | AW_Reg | int | YES | AffiliateWizard-tracked registration count. COUNT of customers registered on this date from BI_DB_CIDFirstDates WHERE SerialID IN (52350, 52351). Independent of Twitter's pixel tracking. 0 for TW-only rows or non-52350/52351 affiliates. (Tier 2 — SP_Twitter, BI_DB_CIDFirstDates) |
| 19 | AW_FTD | int | YES | AffiliateWizard-tracked first-time deposit count. COUNT of customers with FirstDepositDate on this date from BI_DB_CIDFirstDates WHERE SerialID IN (52350, 52351). Independent of Twitter's pixel tracking. 0 for TW-only rows or non-52350/52351 affiliates. (Tier 2 — SP_Twitter, BI_DB_CIDFirstDates) |
| 20 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last inserted by SP_Twitter (GETDATE()). (Tier 5 — SP_Twitter) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | Fivetran twitter_campaign_locations_report | date | DATEADD(HOUR,1,date) cast to DATE |
| AccountID | Fivetran twitter_campaign_locations_report | account_id | Passthrough |
| AccountName | Fivetran twitter_ads_account_history | name | Latest via ROW_NUMBER(PARTITION BY id ORDER BY updated_at DESC) |
| CampaignID | Fivetran twitter_campaign_locations_report | campaign_id | Passthrough |
| CampaignName | Fivetran twitter_campaign_history | name | Latest via ROW_NUMBER |
| AffiliateID | CampaignName (derived) / CIDFirstDates.SerialID | — | SUBSTRING extraction / direct |
| Country | Fivetran twitter_campaign_locations_report / CIDFirstDates | segment / Country | ISNULL merge |
| Region | DWH_dbo.Dim_Country | Region | JOIN on country name |
| Desk | DWH_dbo.Dim_Country | Desk | JOIN on country name |
| EU | DWH_dbo.Dim_Country | IsEuropeanCountry | JOIN on country name |
| Platform | CampaignName (derived) | — | CASE LIKE pattern match |
| Cost | Fivetran twitter_campaign_locations_report | billed_charge_local_micro | SUM / 1,000,000 |
| Impressions | Fivetran twitter_campaign_locations_report | impressions | SUM |
| App_Clicks | Fivetran twitter_campaign_locations_report | app_clicks | SUM |
| Clicks | Fivetran twitter_campaign_locations_report | clicks | SUM |
| TW_Reg | Fivetran twitter_campaign_locations_report | conversion_sign_ups_post_engagement + post_view | SUM(both) |
| TW_FTD | Fivetran twitter_campaign_locations_report | conversion_purchases_post_engagement + post_view | SUM(both) |
| AW_Reg | BI_DB_CIDFirstDates | registered | SUM CASE for date match, affiliates 52350/52351 |
| AW_FTD | BI_DB_CIDFirstDates | FirstDepositDate | SUM CASE for date match, affiliates 52350/52351 |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Twitter Ads API
  |-- Fivetran connector ---|
  v
Bronze/Fivetran/twitter_ads/ (Data Lake)
  |-- External Tables ---|
  v
BI_DB_dbo.External_Fivetran_twitter_campaign_locations_report (metrics)
BI_DB_dbo.External_Fivetran_twitter_ads_account_history (account names)
BI_DB_dbo.External_Fivetran_twitter_campaign_history (campaign names)
  |                                                              |
  |  + DWH_dbo.Dim_Country (Region/Desk/EU)                     |
  |  + BI_DB_dbo.BI_DB_CIDFirstDates (AW Reg/FTD)               |
  |                                                              |
  |-- SP_Twitter @date (daily, DELETE+INSERT 30-day rolling) ----|
  v
BI_DB_dbo.BI_DB_Twitter (408K rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country / Region / Desk / EU | DWH_dbo.Dim_Country | Geographic enrichment via country name JOIN |
| AW_Reg, AW_FTD | BI_DB_dbo.BI_DB_CIDFirstDates | AffiliateWizard conversion counts for affiliates 52350/52351 |
| AccountID, AccountName | BI_DB_dbo.External_Fivetran_twitter_ads_account_history | Twitter account dimension |
| CampaignID, CampaignName | BI_DB_dbo.External_Fivetran_twitter_campaign_history | Twitter campaign dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo or DWH_dbo SPs.

---

## 7. Sample Queries

### 7.1 Daily Twitter Ad Spend and Registrations by Region

```sql
SELECT
    [Date],
    Region,
    SUM(Cost) AS TotalCost,
    SUM(TW_Reg) AS TwitterRegistrations,
    SUM(AW_Reg) AS AffWizRegistrations,
    CASE WHEN SUM(Impressions) > 0
         THEN CAST(SUM(Clicks) AS FLOAT) / SUM(Impressions)
         ELSE 0 END AS CTR
FROM BI_DB_dbo.BI_DB_Twitter
WHERE [Date] >= '2026-01-01'
GROUP BY [Date], Region
ORDER BY [Date] DESC, TotalCost DESC
```

### 7.2 Twitter vs AffWiz Conversion Discrepancy

```sql
SELECT
    [Date],
    SUM(TW_Reg) AS TW_Registrations,
    SUM(AW_Reg) AS AW_Registrations,
    SUM(TW_Reg) - SUM(AW_Reg) AS Reg_Discrepancy,
    SUM(TW_FTD) AS TW_Deposits,
    SUM(AW_FTD) AS AW_Deposits,
    SUM(TW_FTD) - SUM(AW_FTD) AS FTD_Discrepancy
FROM BI_DB_dbo.BI_DB_Twitter
WHERE [Date] >= DATEADD(MONTH, -3, GETDATE())
GROUP BY [Date]
ORDER BY [Date] DESC
```

### 7.3 Campaign Performance Top 10 by Cost

```sql
SELECT TOP 10
    CampaignName,
    AffiliateID,
    SUM(Cost) AS TotalSpend,
    SUM(Impressions) AS TotalImpressions,
    SUM(Clicks) AS TotalClicks,
    SUM(TW_Reg) AS TotalRegistrations,
    CASE WHEN SUM(TW_Reg) > 0
         THEN SUM(Cost) / SUM(TW_Reg)
         ELSE NULL END AS CostPerRegistration
FROM BI_DB_dbo.BI_DB_Twitter
WHERE [Date] >= '2026-01-01'
GROUP BY CampaignName, AffiliateID
ORDER BY TotalSpend DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 17 T2, 2 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Twitter | Type: Table | Production Source: Fivetran Twitter Ads + CIDFirstDates + Dim_Country*
