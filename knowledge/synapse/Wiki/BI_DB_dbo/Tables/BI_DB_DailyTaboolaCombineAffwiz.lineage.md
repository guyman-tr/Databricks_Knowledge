# BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz |
| **Writer SP** | BI_DB_dbo.SP_Taboola |
| **Author** | Eti Rozolio (2021-01-07) |
| **Primary Sources** | BI_DB_python.BI_DB_TaboolaCampaignsByCountry (Taboola API), DWH_dbo.Dim_Customer (Affwiz registrations/FTD), BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints (Ver2) |
| **Load Pattern** | Daily DELETE last 10 days + INSERT |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Date | Taboola API / Dim_Customer | Date / RegisteredReal / FirstDepositDate | COALESCE across sources | Tier 2 |
| 2 | DateID | SP computation | Date | YYYYMMDD INT conversion | Tier 2 |
| 3 | CampaignName | Taboola API / Dim_Customer.SubSerialID | campaign_name / SubSerialID | Complex string parsing to extract campaign name (remove "_Taboola" suffix + trailing segment) | Tier 2 |
| 4 | AffiliateID | Hardcoded / Dim_Customer | 45729 / AffiliateID | Hardcoded to 45729 (Taboola affiliate) | Tier 2 |
| 5 | Desk | Taboola API / Dim_Country | Desk | From Dim_Country via country JOIN | Tier 2 |
| 6 | Region | Taboola API / Dim_Country | MarketingRegionManualName | Renamed to Region | Tier 2 |
| 7 | Country | Taboola API / Dim_Country | Name / Abbreviation → Name | Resolved from country JOIN | Tier 2 |
| 8 | EU | Taboola API / Dim_Country | EU | EU membership flag | Tier 2 |
| 9 | Platform | Taboola API / campaign name keywords | campaign_name / SubSerialID | CASE LIKE Desktop/Desk/Mobile/Mob/Both keywords | Tier 2 |
| 10 | Cost | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | spent | Renamed to Cost | Tier 2 |
| 11 | Impressions | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | impressions | Passthrough | Tier 2 |
| 12 | VisibleImpressions | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | visible_impressions | Passthrough | Tier 2 |
| 13 | Clicks | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | clicks | Passthrough | Tier 2 |
| 14 | Tb_Registrations | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | Registration_NewConversions | Renamed | Tier 2 |
| 15 | AW_Registrations | DWH_dbo.Dim_Customer | COUNT(*) WHERE AffiliateID=45729 | Registration count by campaign/date/country | Tier 2 |
| 16 | Tb_FTD | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | FTD_NewConversions | Renamed | Tier 2 |
| 17 | AW_FTD | DWH_dbo.Dim_Customer | COUNT(*) WHERE AffiliateID=45729 by FirstDepositDate | FTD count by campaign/date/country | Tier 2 |
| 18 | Tb_Verification2 | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | Verification_Level_2_NEWConversions | Renamed | Tier 2 |
| 19 | AW_Verification2 | BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints | COUNT(*) WHERE VerificationLevel2=1 | Level 2 verified count by campaign/date/country | Tier 2 |
| 20 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |
| 21 | Taboola_Account | BI_DB_python.BI_DB_TaboolaCampaignsByCountry | account_name | Renamed to Taboola_Account | Tier 2 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| BI_DB_python.BI_DB_TaboolaCampaignsByCountry | External (Python/API) | Taboola advertising API metrics (cost, impressions, clicks, conversions) |
| DWH_dbo.Dim_Customer | Dimension | Affwiz registration and FTD counts (SubSerialID campaign parsing, AffiliateID=45729) |
| DWH_dbo.Dim_Country | Dimension | Country name, desk, region, EU flag |
| BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints | Table | Verification Level 2 counts (SubAffiliateID campaign parsing) |
