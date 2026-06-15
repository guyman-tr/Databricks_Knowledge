---
name: domain-marketing-and-acquisition
description: "Affiliate platform (Fiktivo) + paid media vendors (Google / Facebook / Twitter / TikTok / Apple Search / Snapchat / Taboola / DV360) + live acquisition dashboard. Covers main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked (114k affiliates, 99 cols with pre-aggregated trailing-window FTD / FTDe counters), Fiktivo OLTP bronzes for affiliate master / groups / channels / banners / leads / country-config / commission VWs, the 1.02B-row bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation, the 58k-row affiliate-payments settlement report with the 5-tier commission structure, the pre-aggregated v_marketing_campaigns_social (Twitter/FB/Taboola/TikTok cost+attribution) and v_marketing_campaigns_google (Google UAC/Brand/Search/YT/pMAX cost+Firebase attribution) views, the 1.79M-row bi_output_marketing_liveacquisitiondashboard (live registrationג†’FTD watcher with FunnelName/FunnelFromName/Fast24H), the Fivetran vendor-feed bronzes that feed it, and the SubChannel taxonomy. Use for affiliate ranking, paid-media cost-per-FTD, channel ֳ— region ֳ— date attribution, live acquisition funnel state, and affiliate-tier commission settlement."
triggers:
  - dim_affiliate_masked
  - dim_affiliate
  - AffiliateID
  - AffiliatesGroupsName
  - AffiliatesGroupsID
  - MasterAffiliateID
  - SubChannelID
  - SubChannel
  - Channel
  - newmarketingregion
  - marketingregion
  - fiktivo
  - bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation
  - ClicksCount
  - ImpressionsCount
  - BannerID
  - bronze_fiktivo_affiliatecommission_registrationvw
  - bronze_fiktivo_affiliatecommission_registrationcommissionvw
  - bronze_fiktivo_affiliatecommission_closedpositionvw
  - bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
  - bronze_fiktivo_affiliatecommission_creditvw
  - bronze_fiktivo_affiliatecommission_creditcommissionvw
  - bronze_fiktivo_dbo_tblaff_affiliates_masked
  - bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked
  - bronze_fiktivo_dbo_tblaff_country
  - bronze_fiktivo_dbo_tblaff_leads
  - bronze_fiktivo_dbo_tblaff_banners
  - bronze_fiktivo_dbo_tblaff_paymenthistory
  - bronze_fiktivo_dbo_tblaff_marketingexpense
  - bronze_fiktivo_dbo_channels
  - bi_output_marketing_affiliate_payments_report_closed_position
  - affiliate_payments_report
  - Tier
  - v_marketing_campaigns_social
  - v_marketing_campaigns_google
  - Google UAC
  - Google Brand
  - Google Search
  - pMAX
  - YouTube
  - "YT"
  - Taboola
  - FTD_S2S
  - FTD_Android_Firebase
  - FTD_IOS_Firebase
  - FTD_Web_Pilot
  - Registration_Android_Firebase
  - Registration_IOS_Firebase
  - Registration_Web
  - AppsFlyer_Registrations
  - FTDs_Channel
  - Registrations_Channel
  - bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report
  - bronze_fivetran_adwords_new_api_v_campaign_performance_report
  - bronze_fivetran_bingads_campaign_history
  - bronze_fivetran_twitter_ads_campaign_history
  - bronze_fivetran_twitter_ads_campaign_locations_report
  - bronze_fivetran_double_click_campaign_manager_dv_360_daily
  - bronze_fivetran_double_click_campaign_manager_dv_360_daily_conversions
  - bronze_fivetran_double_click_campaign_manager_v_media_campaign
  - bronze_fivetran_google_new_agg_v_google_campaign_perf
  - bronze_fivetran_google_new_agg_v_google_campaign_conv
  - bronze_rivery_google_ad_google_campaign_perf
  - bronze_rivery_google_ad_google_campaign_conv
  - bronze_fivetran_apple_search_ads_campaign_history
  - bronze_fivetran_apple_search_ads_campaign_report
  - bronze_fivetran_tiktok_ads_campaign_history
  - bronze_fivetran_tiktok_ads_campaign_report_daily
  - bronze_fivetran_snapchat_ads_campaign_daily_report
  - bronze_fivetran_snapchat_ads_campaign_history
  - bi_output_marketing_liveacquisitiondashboard
  - liveacquisitiondashboard
  - FunnelName
  - FunnelFromName
  - RegToFTDBuckets
  - RegToFTD
  - Fast24H
  - vg_acquisitionfunnel
  - vg_acquisitionfunnel_em1
  - vg_marketingacquisitionfunnel
  - bi_output_marketing_acquisition_anomaly
  - bi_output_marketing_acquisition_liveacquisition
  - silver_sharepoint_marketing_region_mapping
  - silver_sharepoint_marketing_subchannel_level_data
  - bronze_fivetran_google_sheets_marketing_subchannel_level_data  # historical name (Google-Sheets-via-Fivetran), superseded by the silver_sharepoint sibling
  - silver_sharepoint_multiregulationaffiliatecompliance
  - silver_sharepoint_sedric_affiliates_sedric_regulationdomain
  - sedric_additionalaffiliatesurl
sample_questions:
  - "Top 10 affiliates by FTDs this quarter?"
  - "Cost-per-FTD on Google UAC vs Facebook last 30 days?"
  - "How many clicks did Banner X drive in Italy yesterday?"
  - "Per-tier total commission paid in May 2026?"
  - "Live acquisition funnel for today by Channel ֳ— Country"
  - "Which affiliate group has the highest LifetimeValue per FTD?"
  - "Time-series of registrations from TikTok by region last quarter"
  - "Show all SEM-channel affiliates with > 1000 FTDs this year"
  - "What does the FunnelFromName distribution look like for the eToro Homepage funnel?"
  - "Master-affiliate roll-up: total commission for affiliate-network X"
required_tables:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked
  - main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates_masked
  - main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked
  - main.bi_db.bronze_fiktivo_dbo_channels
  - main.bi_db.bronze_fiktivo_dbo_tblaff_country
  - main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation
  - main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw
  - main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw
  - main.bi_db.bronze_fiktivo_affiliatecommission_creditvw
  - main.bi_output.bi_output_marketing_affiliate_payments_report_closed_position
  - main.etoro_kpi_stg.v_marketing_campaigns_social
  - main.etoro_kpi_stg.v_marketing_campaigns_google
  - main.bi_output.bi_output_marketing_liveacquisitiondashboard
  - main.bi_db.bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report
  - main.bi_db.bronze_fivetran_twitter_ads_campaign_history
  - main.general.bronze_fivetran_apple_search_ads_campaign_report
  - main.general.bronze_fivetran_tiktok_ads_campaign_report_daily
  - main.marketing.bronze_fivetran_snapchat_ads_campaign_daily_report
  - main.sharepoint.silver_sharepoint_marketing_region_mapping
  - main.sharepoint.silver_sharepoint_marketing_subchannel_level_data
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Affiliate platform + Paid Media + Live Acquisition

External sources of new eToro customers, all paid (per-click, per-registration, per-FTD, or per-impression), all attributed back to a `Channel ֳ— SubChannel ֳ— Region` cube. Three layers: the AFFILIATE network (Fiktivo platform), the PAID MEDIA vendors (Google / Facebook / etc.), and the LIVE ACQUISITION DASHBOARD that watches the funnel state in near-real-time.

## What it covers

`Channel ֳ— SubChannel` is the canonical attribution cube. From `dim_affiliate_masked` (sample distribution): `Affiliate` channel dominates (109k of 114k affiliates ג‰ˆ 95%, split into the `Affiliate` SubChannel 102k and `IBs` Introducing-Brokers 6.7k). Then `Media Performance` (2.1k affiliates), `Direct` (778), `SEM` (split into SEM Other 519 + Google Search 235 + Google Brand 73 + YT 67 + FB 83 ג€” yes, SEM and the paid-media views overlap here), `Productions` (331), `Mobile Acquisition / Mobile CPA` (242), `SEO` (182), `Events` (173), `Content Partnerships` (96), `Sponsorships` (84), `Media Programmatic` (56), `Club` (53 ג€” internal club-loyalty traffic counts as a channel), `OOH` (out-of-home 41), `Social Organic` (36). The lowercase `systems` (54) is a placeholder bucket ג€” treat as un-attributed.

`dim_affiliate_masked` itself is the affiliate-grain DIMENSION (1 row per affiliate, 99 columns). Each affiliate carries baked-in lifecycle counters: `RegistrationLifeTime / Yesterday / ThisMonth / LastMonth / ThisQuarter / LastQuarter / ThisYear / LastYear` and the parallel set for `FTD*` (real-money FTD) and `FTDe*` (eMoney FTD). These are PRE-AGGREGATED and refresh nightly ג€” they are NOT additive across rows; use them for ranking ("top affiliates THIS month") not time-series.

For TIME-SERIES of affiliate-sourced traffic, the source-of-truth bronzes are:

- `bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation` (1.02B rows) ג€” clicks + impressions per `AffiliateID ֳ— BannerID ֳ— Campaign ֳ— CountryID ֳ— etr_ymd`. Partition-filter mandatory.
- `bronze_fiktivo_affiliatecommission_registrationvw` ג€” per-registration commission events keyed by `RegistrationID`, with `AffiliateID`, `CID`, `RegistrationDate`, `BannerID`, `FunnelID`, `LabelID`, `PlayerLevelID`, `Valid` (boolean ג€” did the registration validate), `IsProcessed` (boolean ג€” did commission process).
- `bronze_fiktivo_affiliatecommission_closedpositionvw` ג€” per-position commission events (revenue-share on actual trading).
- `bronze_fiktivo_affiliatecommission_creditvw` ג€” per-deposit credit commission events.
- Each commission VW has a `*commissionvw` sibling carrying the actual dollar amount per event (separated to keep PII-light tables).

Settlement happens monthly into `bi_output_marketing_affiliate_payments_report_closed_position` (58k rows total). 5-tier structure: Tier 1 (51.8k payments, ~$3.75M cumulative, ג‰ˆ72 USD avg/payment), Tier 2 (6.2k payments, ~$3.52M, ג‰ˆ566 USD avg ג€” Tier 2 affiliates have ~8x the per-payment value of Tier 1), Tier 3 (273 payments, ~$10k), Tiers 4-5 are residual edge cases. The `month` column is STRING-formatted (e.g. `'2026-05'`) ג€” partition-friendly for trailing-window queries.

Paid-media (NON-affiliate) performance is the pre-aggregated `etoro_kpi_stg` view family:

- `v_marketing_campaigns_social` (25.9k rows, 12 cols): `Date ֳ— Region ֳ— Channel` where Channel is one of `Twitter` (5.99k rows = ~6 channels ֳ— ~100 weeks of US/EU/etc. regions), `FB` (5.84k), `Taboola` (4.73k), `TikTok` (4.56k), `''` (4.76k ג€” un-mapped). Metrics: `Cost`, `Clicks`, `Impressions`, `FTD_S2S` (server-to-server post-back), `FTDs_Channel`, `Registrations_Channel`, `AppsFlyer_Registrations` (per-vendor attribution overlay), `FTD_Count`, `Registration_Count` (cross-attribution unified).

- `v_marketing_campaigns_google` (22.1k rows, 14 cols): `perf_date ֳ— Region ֳ— Channel` where Channel is `Google UAC` (5.67k rows ג€” Universal App Campaigns), `Google Brand` (5.57k), `Google Search` (5.07k), `YT` YouTube (4.57k), `pMAX` (919), `YTE` (153 ג€” YouTube Engagement), `NBR` (138 ג€” Non-Brand Region?). Metrics: `Cost`, `Clicks`, `Impressions`, `FTD_Android_Firebase`, `FTD_IOS_Firebase`, `FTD_Web_Pilot`, `Registration_Android_Firebase`, `Registration_IOS_Firebase`, `Registration_Web`, `FTD_Count`, `Registration_Count`.

The raw vendor-feed bronzes (Fivetran or Rivery ingestion) live one layer below:

- Google Ads / SEM family: `bi_db.bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report`, `bi_db.bronze_fivetran_adwords_new_api_v_campaign_performance_report`, `bi_db.bronze_fivetran_google_new_agg_v_google_campaign_perf` / `_campaign_conv`, `bi_db.bronze_rivery_google_ad_google_campaign_perf` / `_campaign_conv` (Rivery is the alternate ETL ג€” both sources present, prefer Fivetran for current).
- Bing Ads: `bi_db.bronze_fivetran_bingads_campaign_history`.
- Twitter Ads: `bi_db.bronze_fivetran_twitter_ads_campaign_history`, `bi_db.bronze_fivetran_twitter_ads_campaign_locations_report`.
- DV360 / Display: `bi_db.bronze_fivetran_double_click_campaign_manager_dv_360_daily`, `_daily_conversions`, `_v_media_campaign`.
- Apple Search Ads: `general.bronze_fivetran_apple_search_ads_campaign_history`, `general.bronze_fivetran_apple_search_ads_campaign_report`.
- TikTok: `general.bronze_fivetran_tiktok_ads_campaign_history`, `general.bronze_fivetran_tiktok_ads_campaign_report_daily`.
- Snapchat: `marketing.bronze_fivetran_snapchat_ads_campaign_history`, `marketing.bronze_fivetran_snapchat_ads_campaign_daily_report`.

The Live Acquisition Dashboard is `bi_output.bi_output_marketing_liveacquisitiondashboard` (1.79M rows, 22 cols) ג€” per-CID ֳ— Date with `AffiliatesGroupsName / Channel / SubChannel / CountryID / Region / Country / Funnel / FTDA / RegToFTDBuckets / RegToFTD / State / Fast / Fast24H / SerialID / SubSerialID / DownloadID / KPI / UpdateDate`. `FunnelName` lists the marketing-funnel grouping (`Retoro` is the canonical re-targeting funnel, dominant at 1.27M of 1.79M; `reToroiOS` and `reToroAndroid` are platform splits; `OpenBook` family is legacy; `Web Trader / Mobile / Sit & Play / Web Registration` are direct), and `FunnelFromName` is the entry-point page (~120 distinct values, top: `Retoro` 1.13M, `reToroiOS` 252k, `reToroAndroid` 236k, `Interest on balance` 117k, `Web Registration Form LP` 25k, `Stocks Offering` 8.5k, `Copy Traders Offering` 6.1k, `Academy` 4.6k, `Crypto Offering` 4.1k, `eToro Homepage` 2.8k, `ETFs` 1.1k, `Aspects of Trading Course` 997, `eToroPartners Website` 953, `Landing Page` 840, `Affiliates General LP` 584, `Stock Cashback Affiliates` 469).

Reference dimension tables you'll need for joins:

- `bronze_fiktivo_dbo_tblaff_country` (251 rows ג€” country-config including per-country commission rules for the affiliate platform).
- `bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked` (243 groups with `AccountManagerName / Email / ImagePath / ManagerUserID`).
- `bronze_fiktivo_dbo_channels` (25k channel rows mapping `AffiliateID ג†’ AffiliatesGroupsID ג†’ MarketingExpenseID + MarketingExpenseName`).
- `bronze_fiktivo_dictionary_marketingregion` / `experience.bronze_fiktivo_dictionary_marketingregion` (`MarketingRegionID ג†’ Name` lookup).
- `bronze_fiktivo_dbo_tblaff_banners`, `_bannertypes`, `_languages`, `_ecost` (banner inventory + per-banner cost-config).
- `bronze_fiktivo_dbo_tblaff_leads`, `_leads_commissions`, `_firstpositions`, `_firstpositions_commissions` (per-lead / per-first-position commission detail).
- `sharepoint.silver_sharepoint_marketing_region_mapping`, `_marketing_subchannel_level_data` (manually-maintained mapping of region / sub-channel ג€” sourced from a Google Sheets / SharePoint admin workbook).
- `sharepoint.silver_sharepoint_multiregulationaffiliatecompliance`, `regtech_stg.silver_sharepoint_sedric_affiliates_sedric_regulationdomain` (regulation ֳ— affiliate compliance reference data ג€” used by compliance to flag non-compliant affiliate sources).

## Critical Warnings

1. **Tier 1 ג€” `dim_affiliate_masked` lifecycle counters are PRE-AGGREGATED and refresh nightly. Do not SUM across rows for time-series.** Columns `Registration*`, `FTD*`, `FTDe*` Yesterday / ThisMonth / ThisQuarter / ThisYear / LastMonth / LastQuarter / LastYear / LifeTime are baked-in counters PER AFFILIATE NOW. They give you "rank top affiliates by FTDs this month" but NOT "FTDs by week" ג€” for time-series, query the bronze `bronze_fiktivo_affiliatecommission_registrationvw` per-event table.

2. **Tier 1 ג€” `Channel ֳ— SubChannel` is the canonical attribution cube but `SEM` channel overlaps with paid-media vendor tables.** SEM affiliates exist in `dim_affiliate_masked` (Google Search / Google Brand / FB / YT SubChannel rows = 458 affiliates) AND those campaigns also report cost-and-FTDs in `v_marketing_campaigns_google` / `_social`. Don't double-count when summing total acquisition cost. The convention is: `dim_affiliate_masked` is for AFFILIATE network performance (per-partner ranking); `v_marketing_campaigns_*` is for PAID MEDIA spend (per-channel cost-per-FTD). A single FTD may appear once in each lens.

3. **Tier 1 ג€” `v_marketing_campaigns_social` and `_google` have NO CID column.** They are pre-aggregated to `Date ֳ— Region ֳ— Channel`. For per-CID attribution you have to drive off `bi_output_marketing_liveacquisitiondashboard` (which IS per-CID and carries `Channel / SubChannel`) or trace through `dim_customer_masked.AffiliateID ג†’ dim_affiliate_masked.SubChannel`.

4. **Tier 1 ג€” Attribution columns on `v_marketing_campaigns_social` carry both vendor-attributed and total counts; do not sum them together.** `FTD_S2S` = server-to-server post-back from vendor; `FTDs_Channel` = channel-attributed FTDs; `AppsFlyer_Registrations` = per-vendor attribution overlay; `FTD_Count` = unified-attribution total. Summing `FTD_S2S + FTDs_Channel + AppsFlyer_Registrations` triple-counts the same FTD across attribution lenses. For "how many FTDs from FB last week", use `FTD_Count`.

5. **Tier 1 ג€” Google view's attribution is platform-split: `FTD_Android_Firebase`, `FTD_IOS_Firebase`, `FTD_Web_Pilot`.** Three columns covering the three install platforms. Total = `FTD_Count`. `Firebase` is the Google-Play / iOS install attribution provider; `Web_Pilot` is the web-side attribution overlay. Per-platform CPA = `Cost / (FTD_<platform>_Firebase or FTD_Web_Pilot)`.

6. **Tier 2 ג€” `bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation` (1.02B rows) uses dashed-string partitions.** Filter pattern: `WHERE etr_y='2026' AND etr_ymd BETWEEN '2026-05-01' AND '2026-05-31'`. Ignore the upstream-sharding `PartitionCol100` column. `Campaign` is FREE-TEXT (affiliate-side), `AdditionalData` is a STRING payload blob ג€” both are not pre-cleaned.

7. **Tier 2 ג€” `bi_output_marketing_affiliate_payments_report_closed_position` is settlement-grain (monthly), not event-grain.** 5-tier commission structure with most volume at Tier 1 (51.8k payments / ~$3.75M cumulative / avg $72) and most VALUE at Tier 2 (6.2k payments / ~$3.52M / avg $566). Tier 3 has 273 payments. The `month` column is STRING (`'2026-05'` format). For the per-event commission you need the bronze `*commissionvw` tables joined on the appropriate key.

8. **Tier 2 ג€” `bi_output_marketing_liveacquisitiondashboard` is per-CID with TWO update mechanisms.** A nightly job populates the canonical row; a "Fast24H" snapshot adds a same-day row with `Fast24H = 1` for today-vs-yesterday delta. `Fast = 1` flags very-recent records that may still be enriching. For "stable historical" funnel use `Fast = 0 AND Fast24H = 0`; for "live today" use the latest `UpdateDate`.

9. **Tier 2 ג€” `MasterAffiliateID` is the parent-affiliate hierarchy.** Affiliates with `MasterAffiliateID > 0` are sub-affiliates; master gets a cut of sub commission. 3-level hierarchy is common, deeper exists but rare. For "total network performance under affiliate X" join transitively until `MasterAffiliateID = 0`. Distinct from `AffiliatesGroupsName` (account-manager-level grouping).

10. **Tier 3 ג€” Multiple parallel paid-media bronze feeds exist (Fivetran vs Rivery for Google; `bronze_fivetran_adwords_*` and `_adwords_new_api_*` for legacy-vs-new).** When directly hitting the vendor bronzes (rare, usually you use the curated views), check which feed the dashboard owner actually queries. The `v_marketing_campaigns_*` views aggregate the canonical feeds.

11. **Tier 3 ג€” The `silver_sharepoint_marketing_region_mapping` and `_marketing_subchannel_level_data` are manually-maintained reference data sourced from a Google Sheets / SharePoint admin workbook.** They can lag the production taxonomy. Mismatched / un-mapped regions appear as NULL in joined queries. For "production current taxonomy" prefer `dim_affiliate_masked.Region` / `.Channel` / `.SubChannel`.

12. **Tier 3 ג€” `bi_output_marketing_acquisition_anomaly` flags anomalous acquisition patterns (sudden spike / drop / fraud-like).** Used by Live Acquisition Dashboard owners as an early-warning. Not a transactional table ג€” it's a derived alert table. For "is this affiliate spike a fraud signal" cross-check `acquisition_anomaly` and the compliance fraud-rules in `domain-compliance-and-aml`.

## Canonical query patterns

### Pattern A ג€” Top 10 affiliates by FTDs this month (ranking)

```sql
SELECT
  a.AffiliateID,
  a.AffiliatesGroupsName,
  a.Channel,
  a.SubChannel,
  a.FTDThisMonth,
  a.FTDeThisMonth,
  a.RegistrationThisMonth
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked a
WHERE a.AccountActivated = TRUE
ORDER BY a.FTDThisMonth DESC
LIMIT 10
```

### Pattern B ג€” FTDs per week from Google UAC last quarter (time-series of paid media)

```sql
SELECT
  DATE_TRUNC('week', perf_date) AS week,
  Region,
  SUM(Cost)             AS cost_usd,
  SUM(FTD_Count)        AS ftd_count,
  ROUND(SUM(Cost) / NULLIF(SUM(FTD_Count),0), 2) AS cost_per_ftd
FROM main.etoro_kpi_stg.v_marketing_campaigns_google
WHERE perf_date >= DATE_TRUNC('quarter', current_date) - INTERVAL 1 QUARTER
  AND perf_date <  DATE_TRUNC('quarter', current_date)
  AND Channel = 'Google UAC'
GROUP BY 1, 2
ORDER BY 1, 2
```

### Pattern C ג€” Per-affiliate clicks + commissions joined (time-series of affiliate performance)

```sql
SELECT
  c.AffiliateID,
  a.AffiliatesGroupsName,
  a.Channel,
  a.SubChannel,
  c.etr_ymd,
  SUM(c.ClicksCount)      AS clicks,
  SUM(c.ImpressionsCount) AS impressions,
  COUNT(DISTINCT r.RegistrationID) AS registrations,
  SUM(CASE WHEN r.Valid THEN 1 ELSE 0 END) AS valid_registrations
FROM main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation c
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked a
  ON a.AffiliateID = c.AffiliateID
LEFT JOIN main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw r
  ON r.AffiliateID = c.AffiliateID
 AND DATE(r.RegistrationDate) = TO_DATE(c.etr_ymd)
 AND r.etr_y = c.etr_y
WHERE c.etr_y = '2026'
  AND c.etr_ymd BETWEEN '2026-05-01' AND '2026-05-27'
GROUP BY 1, 2, 3, 4, 5
ORDER BY clicks DESC
LIMIT 50
```

### Pattern D ג€” Live acquisition funnel snapshot for today

```sql
SELECT
  Channel,
  SubChannel,
  Region,
  COUNT(DISTINCT CID) AS new_customers,
  SUM(FTDA)          AS ftd_amount_usd,
  AVG(RegToFTD)      AS avg_minutes_to_ftd
FROM main.bi_output.bi_output_marketing_liveacquisitiondashboard
WHERE DATE(Date) = current_date
  AND Fast24H = 1
GROUP BY 1, 2, 3
ORDER BY new_customers DESC
LIMIT 50
```

### Pattern E ג€” Total commission paid by tier last month

```sql
SELECT
  month,
  Tier,
  COUNT(*)           AS n_payments,
  SUM(Commission)    AS total_commission_usd,
  AVG(Commission)    AS avg_payment_usd
FROM main.bi_output.bi_output_marketing_affiliate_payments_report_closed_position
WHERE month >= DATE_FORMAT(current_date - INTERVAL 1 MONTH, 'yyyy-MM')
GROUP BY 1, 2
ORDER BY 1, 2
```

## Federation hooks

- `dim_customer_masked.AffiliateID` joins back to `dim_affiliate_masked.AffiliateID` ג€” the customer-master record carries the originating affiliate. For "who acquired this customer" lookup, use this join. The `newmarketingregion` / `marketingregion` column on `dim_customer_masked` is sourced from `experience.bronze_fiktivo_dictionary_marketingregion`. See `../domain-customer-and-identity/customer-master-record.md`.
- `bi_output_marketing_liveacquisitiondashboard.CID` joins to `dim_customer_masked` for full-customer enrichment, and to `domain-payments/deposits-and-withdrawals.md` for the actual deposit-amount-by-day rollup on `FTDA`.
- For VL3 / verification timing of these acquired customers, the link is via `CID` to `domain-ops-and-onboarding/electronic-verification-and-registration-funnel.md` (`registrationfunnel.VerificationLevel3_DateTime` paired with `dim_affiliate_masked.FTDFirstDate` gives the verification-to-FTD gap per affiliate).
- For the paid-media spend P&L allocation, the future `domain-finance-and-treasury` hub will own the cost-line reconciliation; this sub-skill owns the operational measurement.

## Last verified

2026-05-28 ג€” anchor row counts probed; `Channel`/`SubChannel` distribution from `dim_affiliate_masked`; commission Tier distribution from `bi_output_marketing_affiliate_payments_report_closed_position` (5 tiers, Tier 1 dominant by count, Tier 2 dominant by avg-payment-value); paid-media Channel taxonomy from both Google and Social campaigns views; `FunnelName` / `FunnelFromName` distribution from Live Acquisition Dashboard; partition format dashed-string confirmed on `bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation`.
