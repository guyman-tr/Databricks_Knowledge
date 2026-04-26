# BI_DB_dbo.BI_DB_FB_Report — Column Lineage

## Summary

Facebook Ads (Smartly account only) daily performance report combining FB API metrics (spend, impressions, clicks, conversions) with actual platform registration/FTD data from BI_DB_CIDFirstDates. Campaign name parsed for Country/Funnel. Region mapped via CASE. 7-day rolling window.

## Source Objects

| # | Source Object | Schema | Role |
|---|--------------|--------|------|
| 1 | BI_DB_dbo.BI_DB_FB_Performance | BI_DB_dbo | Facebook Ads performance (spend, clicks, impressions) — Smartly account only. INACTIVE since 2026-01-07 |
| 2 | BI_DB_dbo.BI_DB_FB_Conversion | BI_DB_dbo | Facebook Ads conversions (Registration, V2, FTD via 7d click attribution). INACTIVE since 2026-01-07 |
| 3 | BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | Platform registration and FTD dates (SubChannel='FB') — still active |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | BI_DB_FB_Performance / CIDFirstDates | date / FirstDepositDate / registered | ISNULL(FB date, DB date) |
| CampaignID | BI_DB_FB_Performance | campaign_id | ISNULL(campaign_id, 0) |
| CampaignName | BI_DB_FB_Performance / CIDFirstDates | campaign_name / SubAffiliateID | ISNULL(FB name, DB name) |
| Funnel | BI_DB_FB_Performance | campaign_name | Parsed — second underscore-delimited segment |
| Country | BI_DB_FB_Performance | campaign_name | Parsed — first underscore-delimited segment |
| AccountName | BI_DB_FB_Performance | account_name | Passthrough — always 'eToro ALL 2 (Smartly)' for FB rows |
| Cost | BI_DB_FB_Performance | spend | SUM(spend) — ISNULL to 0 |
| Impressions | BI_DB_FB_Performance | impressions | SUM(impressions) — ISNULL to 0 |
| Clicks | BI_DB_FB_Performance | clicks | SUM(clicks) — ISNULL to 0 |
| FB_Reg | BI_DB_FB_Conversion | Registration | SUM(Registration) — from FB 7d click attribution |
| FB_V2 | BI_DB_FB_Conversion | V2 | SUM(V2) — FB attributed L2 KYC completions |
| FB_FTD | BI_DB_FB_Conversion | FTD | SUM(FTD) — FB attributed first-time deposits |
| DB_Reg | BI_DB_CIDFirstDates | CID COUNT | COUNT per (date, SubAffiliateID) WHERE SubChannel='FB' |
| DB_FTD | BI_DB_CIDFirstDates | CID COUNT | COUNT per (FirstDepositDate, SubAffiliateID) WHERE SubChannel='FB' |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |
| Region | Derived from Country | — | CASE mapping: DE→German, FR→French, IT→Italian, US→USA, AU→Australia, etc. Unmapped→'Not valid region' |
