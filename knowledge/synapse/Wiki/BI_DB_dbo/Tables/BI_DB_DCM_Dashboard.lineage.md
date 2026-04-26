# BI_DB_dbo.BI_DB_DCM_Dashboard — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_DCM_Dashboard |
| **Writer SP** | BI_DB_dbo.SP_DCM_Dashboard |
| **Author** | Jan Iablunovskey (2021-10-18) |
| **Primary Sources** | External_Fivetran_double_click_campaign_manager_media_campaign (DCM/Fivetran), BI_DB_CIDFirstDates (reg/FTD), BI_DB_First5Actions (first action breakdown) |
| **Load Pattern** | Daily DELETE last 90 days + INSERT (3 UNION levels: High Level, DCM Level, First Action) |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Date | DCM Fivetran / BI_DB_CIDFirstDates | date / RegisteredReal / FirstDepositDate | ISNULL across sources | Tier 2 |
| 2 | Country | DCM Fivetran + BI_DB_CountryDCM / BI_DB_CIDFirstDates | country → Country_Affwiz | Mapped via BI_DB_CountryDCM lookup | Tier 2 |
| 3 | AffiliateID | DCM campaign name / BI_DB_CIDFirstDates | campaign (parsed) / SerialID | Extracted from campaign name reverse-parsing | Tier 2 |
| 4 | Impressions | DCM Fivetran | impressions | SUM | Tier 2 |
| 5 | Clicks | DCM Fivetran | clicks | SUM | Tier 2 |
| 6 | FTDs | BI_DB_CIDFirstDates | COUNT(*) by FirstDepositDate | Internal FTD count (High Level only) | Tier 2 |
| 7 | Regs | BI_DB_CIDFirstDates | COUNT(*) by registered | Internal registration count (High Level only) | Tier 2 |
| 8 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |
| 9 | Campaign | DCM Fivetran | campaign | Passthrough (DCM Level only, NULL for High Level/First Action) | Tier 2 |
| 10 | CampaignId | DCM Fivetran | campaign_id | Passthrough (DCM Level only) | Tier 2 |
| 11 | Placement | DCM Fivetran | placement | Passthrough (DCM Level only) | Tier 2 |
| 12 | PlacementId | DCM Fivetran | placement_id | Passthrough (DCM Level only) | Tier 2 |
| 13 | MediaCost | DCM Fivetran | media_cost | SUM | Tier 2 |
| 14 | ViewFTD | DCM Fivetran | view_through_conversions WHERE activity='FTD' | SUM CASE | Tier 2 |
| 15 | ClickFTD | DCM Fivetran | click_through_conversions WHERE activity='FTD' | SUM CASE | Tier 2 |
| 16 | ViewAndroidFTD | DCM Fivetran | view_through_conversions WHERE activity='FTD_Android' | SUM CASE | Tier 2 |
| 17 | ClickAndroidFTD | DCM Fivetran | click_through_conversions WHERE activity='FTD_Android' | SUM CASE | Tier 2 |
| 18 | ViewRegistration | DCM Fivetran | view_through_conversions WHERE activity='Registration' | SUM CASE | Tier 2 |
| 19 | ClickRegistration | DCM Fivetran | click_through_conversions WHERE activity='Registration' | SUM CASE | Tier 2 |
| 20 | ViewAndroidRegistration | DCM Fivetran | view_through_conversions WHERE activity='Registration_Android' | SUM CASE | Tier 2 |
| 21 | ClickAndroidRegistration | DCM Fivetran | click_through_conversions WHERE activity='Registration_Android' | SUM CASE | Tier 2 |
| 22 | LOD | SP computation | Hardcoded | 'High Level', 'DCM Level', or 'First Action' | Tier 2 |
| 23 | CampaignName | DCM Fivetran | campaign | LEFT(campaign, CHARINDEX('_', campaign)-1) (DCM Level only) | Tier 2 |
| 24 | FTDs1 | BI_DB_CIDFirstDates | FTDs | Same as FTDs (High Level only, 0 for others) | Tier 2 |
| 25 | Regs1 | BI_DB_CIDFirstDates | REG | Same as Regs (High Level only, 0 for others) | Tier 2 |
| 26 | Stocks | BI_DB_First5Actions | FirstAction='Stocks/ETFs' | COUNT CASE (First Action only) | Tier 2 |
| 27 | CFDs | BI_DB_First5Actions | FirstAction='FX/Commodities/Indices' | COUNT CASE (First Action only) | Tier 2 |
| 28 | Crypto | BI_DB_First5Actions | FirstAction='Crypto' | COUNT CASE (First Action only) | Tier 2 |
| 29 | Copy | BI_DB_First5Actions | FirstAction='Copy' | COUNT CASE (First Action only) | Tier 2 |
| 30 | SmartPortfolio | BI_DB_First5Actions | FirstAction='Copy Fund' | COUNT CASE (First Action only) | Tier 2 |
| 31 | FirstActionNULL | BI_DB_First5Actions | FirstAction IS NULL | COUNT CASE (First Action only) | Tier 2 |
| 32 | ViewIOSFTD | DCM Fivetran | view_through_conversions WHERE activity='FTD_IOS' | SUM CASE | Tier 2 |
| 33 | ClickIOSFTD | DCM Fivetran | click_through_conversions WHERE activity='FTD_IOS' | SUM CASE | Tier 2 |
| 34 | ViewIOSRegistration | DCM Fivetran | view_through_conversions WHERE activity='Registration_IOS' | SUM CASE | Tier 2 |
| 35 | ClickIOSRegistration | DCM Fivetran | click_through_conversions WHERE activity='Registration_IOS' | SUM CASE | Tier 2 |
| 36 | Creative | DCM Fivetran | creative | Passthrough (DCM Level only) | Tier 2 |
| 37 | NewMarketingRegion | DWH_dbo.Dim_Country | MarketingRegionManualName | Renamed | Tier 2 |
| 38 | Contact | DWH_dbo.Dim_Affiliate | Contact | Passthrough | Tier 2 |
| 39 | Channel | DWH_dbo.Dim_Affiliate | Channel | Passthrough | Tier 2 |
| 40 | SubChannel | DWH_dbo.Dim_Affiliate | SubChannel | Passthrough | Tier 2 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| External_Fivetran_double_click_campaign_manager_media_campaign | External (Fivetran) | DCM/Google Campaign Manager impression/click/conversion data |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | Internal registration and FTD counts |
| BI_DB_dbo.BI_DB_First5Actions | Table | First action breakdown by product type |
| BI_DB_dbo.BI_DB_CountryDCM | Table | DCM country name → Affwiz country name mapping |
| DWH_dbo.Dim_Country | Dimension | Country, marketing region |
| DWH_dbo.Dim_Affiliate | Dimension | Channel, SubChannel, Contact |
