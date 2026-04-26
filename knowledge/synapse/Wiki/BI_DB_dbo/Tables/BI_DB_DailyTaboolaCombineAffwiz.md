# BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz

> 917K-row daily marketing analytics table combining Taboola advertising platform metrics (cost, impressions, clicks, conversion events) with Affwiz internal attribution data (registrations, first-time deposits, Level 2 verifications) for AffiliateID 45729 (Taboola) from December 2020 to present — grain is (Date, CampaignName, Country, Platform), refreshed daily via SP_Taboola with rolling 10-day backfill (author: Eti Rozolio, 2021-01-07).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_python.BI_DB_TaboolaCampaignsByCountry (Taboola API) + DWH_dbo.Dim_Customer (Affwiz registrations/FTD) + BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints (Ver2) via SP_Taboola |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE last 10 days + INSERT for rolling backfill |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Date] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DailyTaboolaCombineAffwiz is a marketing performance reconciliation table that merges Taboola advertising API metrics with eToro's internal Affwiz attribution system. The purpose is to compare what Taboola reports (Tb_* columns: registrations, FTDs, verifications reported by Taboola's pixel tracking) against what eToro actually observes (AW_* columns: real registrations, deposits, and verifications from Dim_Customer).

The table contains 917K rows spanning December 2020 to April 2026 across 1,934 distinct dates. The grain is (Date, CampaignName, Country, Platform). All data is for AffiliateID 45729 (the Taboola affiliate partner).

The ETL uses a 10-day rolling window: every run deletes the last 10 days and re-inserts from both sources. This backfill pattern accounts for late-arriving Taboola conversion data and delayed Dim_Customer registration records. The SP does a FULL OUTER JOIN between Taboola API data and Affwiz data, so campaigns that exist in one source but not the other are still captured.

Campaign names are parsed from the `_Taboola` suffix format using complex string manipulation — the SP extracts the campaign base name by removing the trailing "_Taboola" segment and the last underscore-delimited token. Platform (Desktop/Mobile) is inferred from keywords in the campaign name.

---

## 2. Business Logic

### 2.1 Dual-Source Reconciliation

**What**: Each conversion metric has a Taboola-reported value (Tb_*) and an Affwiz-internal value (AW_*).
**Columns Involved**: Tb_Registrations/AW_Registrations, Tb_FTD/AW_FTD, Tb_Verification2/AW_Verification2
**Rules**:
- Tb_* values come from Taboola's pixel-based conversion tracking (may double-count, fractional due to attribution models)
- AW_* values come from eToro's internal records (Dim_Customer for Reg/FTD, BI_DB_DepositUsersFirstTouchPoints for Ver2)
- Discrepancies between Tb_* and AW_* indicate tracking pixel accuracy, attribution model differences, or late-arriving data
- Tb_* values are decimal (fractional attribution), AW_* values are integer (actual counts)

### 2.2 Campaign Name Parsing

**What**: Complex string extraction to normalize campaign names from Taboola's naming convention.
**Columns Involved**: CampaignName
**Rules**:
- If campaign_name contains "_Taboola": extract everything before "_Taboola", then strip the last underscore-delimited segment
- If no "_Taboola" suffix: strip only the last underscore-delimited segment
- Same parsing logic applied to Dim_Customer.SubSerialID for Affwiz registration matching
- Different parsing for Ver2: uses Dim_Customer.SubAffiliateID instead of SubSerialID

### 2.3 Platform Detection

**What**: Infers device platform from campaign name keywords.
**Columns Involved**: Platform
**Rules**:
- Desktop: campaign name contains "Desktop" or "Desk" (case-insensitive)
- Mobile: campaign name contains "Mobile" or "Mob" (case-insensitive)
- Desktop+Mobile: campaign name contains "Both" (case-insensitive)
- NULL: no matching keyword found

### 2.4 FULL OUTER JOIN Merge

**What**: Ensures complete coverage of both Taboola API data and Affwiz attribution data.
**Columns Involved**: All dimension columns (Date, Campaign, Country, Platform)
**Rules**:
- FULL OUTER JOIN between Taboola and combined Affwiz data on Date + CampaignName + Country
- COALESCE on dimension columns ensures non-null values from whichever source has data
- Cost/Impressions/Clicks only from Taboola; AW_* only from Affwiz side

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no single high-cardinality join key
- **Clustered Index**: Date ASC — always filter by Date for efficient scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign performance this month | `WHERE Date >= '2026-04-01' GROUP BY CampaignName` |
| Taboola vs Affwiz registration discrepancy | `SELECT SUM(Tb_Registrations) AS tb, SUM(AW_Registrations) AS aw WHERE Date = @date` |
| Cost per registration by country | `SELECT Country, SUM(Cost)/NULLIF(SUM(AW_Registrations),0) WHERE Date >= @date` |
| Platform performance comparison | `GROUP BY Platform; compare Cost, Clicks, AW_FTD` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON Country = Name | Full country details |
| BI_DB_python.BI_DB_TaboolaCampaignsByCountry | ON CampaignName + Date + Country | Raw Taboola API data |

### 3.4 Gotchas

- **AffiliateID is always 45729** — hardcoded in the SP. This table is Taboola-only
- **Tb_* values are decimal** (fractional attribution), **AW_* values are integer** (actual counts). Do not compare them directly without understanding the attribution model
- **Rolling 10-day backfill** means the last 10 days may change on each run. For finalized numbers, use data older than 10 days
- **Platform NULL** means the campaign name didn't contain Desktop/Mobile/Both keywords
- **Cost/Impressions/Clicks are NULL** for rows that only exist in the Affwiz source (no Taboola API match)
- **AW_Registrations/AW_FTD/AW_Verification2 are NULL** for rows that only exist in the Taboola source (no Affwiz match)
- **DDL column name**: Taboola_Account appears last in DDL but is logically a dimension column

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified by source system owner |
| Tier 2 | SP code / ETL logic analysis | High — derived from version-controlled code |
| Tier 3 | Live data observation + schema inference | Medium — empirically verified but no code/wiki confirmation |
| Tier 4 | Inferred from naming / context | Lower — best-effort, needs reviewer validation |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard — canonical description for known ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Reporting date for the campaign metrics. Range: 2020-12-23 to present, 1,934 distinct dates. Part of the natural grain (Date, CampaignName, Country, Platform). (Tier 2 — SP_Taboola) |
| 2 | DateID | int | NO | Integer representation of Date in YYYYMMDD format. Computed from Date via CONCAT(YEAR, MM, DD) cast to INT. (Tier 2 — SP_Taboola) |
| 3 | CampaignName | varchar(500) | NO | Normalized campaign name extracted from Taboola API campaign_name or Dim_Customer.SubSerialID. Complex string parsing removes "_Taboola" suffix and trailing underscore-delimited segment. Format: "{Country}_{HF}_{Platform}_{Type}_{Topic}" (e.g., "FR_HF_Desk_Blog_CFD_TopAssets2026"). (Tier 2 — SP_Taboola) |
| 4 | AffiliateID | int | YES | Affiliate partner identifier. Always 45729 (Taboola affiliate) — hardcoded in SP for both Taboola API and Affwiz sources. (Tier 2 — SP_Taboola) |
| 5 | Desk | varchar(50) | YES | Marketing desk/team responsible for the region. From Dim_Country.Desk (e.g., "French", "German", "UK", "Spain", "Australia"). (Tier 2 — SP_Taboola via Dim_Country) |
| 6 | Region | varchar(50) | YES | Marketing region from Dim_Country.MarketingRegionManualName. Renamed to Region in SP. (Tier 2 — SP_Taboola via Dim_Country) |
| 7 | Country | varchar(50) | YES | Country name from Dim_Country.Name. Resolved via country code JOIN for Taboola data, direct match for Affwiz data. (Tier 2 — SP_Taboola via Dim_Country) |
| 8 | EU | int | YES | EU membership flag from Dim_Country.EU. 1=EU member, 0=non-EU. (Tier 2 — SP_Taboola via Dim_Country) |
| 9 | Platform | varchar(50) | YES | Device platform inferred from campaign name keywords. "Desktop" (Desk/Desktop), "Mobile" (Mob/Mobile), "Desktop+Mobile" (Both). NULL when no keyword match. (Tier 2 — SP_Taboola) |
| 10 | Cost | decimal(16,8) | YES | Advertising spend reported by Taboola API (spent column). In campaign currency. NULL for rows from Affwiz source only (no Taboola match). (Tier 2 — SP_Taboola) |
| 11 | Impressions | int | YES | Total impressions reported by Taboola API. NULL for Affwiz-only rows. (Tier 2 — SP_Taboola) |
| 12 | VisibleImpressions | int | YES | Viewable impressions (MRC standard) reported by Taboola API. Subset of Impressions. NULL for Affwiz-only rows. (Tier 2 — SP_Taboola) |
| 13 | Clicks | int | YES | Click count reported by Taboola API. NULL for Affwiz-only rows. (Tier 2 — SP_Taboola) |
| 14 | Tb_Registrations | decimal(16,8) | YES | Registration conversions as reported by Taboola's pixel tracking. Decimal due to fractional attribution models. NULL for Affwiz-only rows. Compare with AW_Registrations for reconciliation. (Tier 2 — SP_Taboola) |
| 15 | AW_Registrations | int | YES | Actual registration count from Dim_Customer WHERE AffiliateID=45729 AND RegisteredReal in date range. Integer count. NULL for Taboola-only rows. Compare with Tb_Registrations for reconciliation. (Tier 2 — SP_Taboola) |
| 16 | Tb_FTD | decimal(16,8) | YES | First-time deposit conversions as reported by Taboola's pixel tracking. Decimal due to fractional attribution. NULL for Affwiz-only rows. Compare with AW_FTD for reconciliation. (Tier 2 — SP_Taboola) |
| 17 | AW_FTD | int | YES | Actual first-time deposit count from Dim_Customer WHERE AffiliateID=45729 AND FirstDepositDate in date range. Integer count. NULL for Taboola-only rows. Compare with Tb_FTD for reconciliation. (Tier 2 — SP_Taboola) |
| 18 | Tb_Verification2 | decimal(16,8) | YES | Level 2 verification conversions as reported by Taboola's pixel tracking. Decimal due to fractional attribution. NULL for Affwiz-only rows. (Tier 2 — SP_Taboola) |
| 19 | AW_Verification2 | int | YES | Actual Level 2 verification count from BI_DB_DepositUsersFirstTouchPoints WHERE AffiliateID=45729 AND VerificationLevel2=1. Integer count. NULL for Taboola-only rows. (Tier 2 — SP_Taboola) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |
| 21 | Taboola_Account | varchar(50) | YES | Taboola advertising account name (e.g., "etoronew-sc", "etoro-brandactivity-sc"). From BI_DB_TaboolaCampaignsByCountry.account_name. NULL for Affwiz-only rows. (Tier 2 — SP_Taboola) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | Taboola API / Dim_Customer | Date / RegisteredReal / FirstDepositDate | COALESCE |
| CampaignName | Taboola API / Dim_Customer | campaign_name / SubSerialID | Complex string parsing |
| Cost | Taboola API | spent | Renamed |
| Impressions | Taboola API | impressions | Passthrough |
| Tb_* columns | Taboola API | Various conversion metrics | Renamed |
| AW_* columns | Dim_Customer / DepositUsersFirstTouchPoints | COUNT(*) | Aggregation |

### 5.2 ETL Pipeline

```
BI_DB_python.BI_DB_TaboolaCampaignsByCountry (Taboola API data, loaded by Python)
  + DWH_dbo.Dim_Country (ON country=Abbreviation)
  |-- Campaign name parsing + dimension enrichment ---|
  v
#Taboola (temp: Taboola metrics by campaign/date/country)
  |
  |-- FULL OUTER JOIN on Date + CampaignName + Country ---|
  |                                                        |
DWH_dbo.Dim_Customer (AffiliateID=45729, IsValidCustomer=1)
  + DWH_dbo.Dim_Country (ON CountryID)
  |-- COUNT(*) registrations by campaign/date/country ---|
  v
#AW_Reg → #AW_FTD → #AW_RegFTD (temp: Affwiz metrics)
  + BI_DB_DepositUsersFirstTouchPoints (Ver2 counts)
  |-- FULL OUTER JOIN Reg + FTD + Ver2 ---|
  v
#AW_WithAccount (temp: Affwiz with account name lookup)
  |
  v
#FinalTaboola (temp: merged Taboola + Affwiz)
  |-- DELETE last 10 days + INSERT ---|
  v
BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz (917K rows, ROUND_ROBIN, CI(Date))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country.Name | Country dimension |
| AffiliateID | DWH_dbo.Dim_Affiliate.AffiliateID | Always 45729 (Taboola) |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Marketing performance dashboards (consumed directly by BI tools) |

---

## 7. Sample Queries

### 7.1 Daily Cost and Conversion Summary

```sql
SELECT Date, SUM(Cost) AS total_cost,
       SUM(AW_Registrations) AS registrations,
       SUM(AW_FTD) AS ftd,
       SUM(Cost) / NULLIF(SUM(AW_FTD), 0) AS cost_per_ftd
FROM [BI_DB_dbo].[BI_DB_DailyTaboolaCombineAffwiz]
WHERE Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date;
```

### 7.2 Taboola vs Affwiz Registration Reconciliation

```sql
SELECT Date,
       SUM(Tb_Registrations) AS taboola_reg,
       SUM(AW_Registrations) AS affwiz_reg,
       SUM(AW_Registrations) - SUM(Tb_Registrations) AS delta
FROM [BI_DB_dbo].[BI_DB_DailyTaboolaCombineAffwiz]
WHERE Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date;
```

### 7.3 Campaign Performance by Country

```sql
SELECT Country, CampaignName,
       SUM(Cost) AS spend, SUM(Clicks) AS clicks,
       SUM(AW_FTD) AS ftd,
       SUM(Cost) / NULLIF(SUM(Clicks), 0) AS cpc
FROM [BI_DB_dbo].[BI_DB_DailyTaboolaCombineAffwiz]
WHERE Date >= '2026-04-01'
GROUP BY Country, CampaignName
ORDER BY SUM(Cost) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 0 T1, 20 T2, 0 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz | Type: Table | Production Source: Taboola API + Affwiz attribution via SP_Taboola*
