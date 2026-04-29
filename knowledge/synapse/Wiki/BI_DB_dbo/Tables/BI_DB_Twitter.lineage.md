# BI_DB_dbo.BI_DB_Twitter — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| BI_DB_dbo.External_Fivetran_twitter_campaign_locations_report | External Table | Primary — Twitter campaign metrics by country (impressions, clicks, conversions, cost) |
| BI_DB_dbo.External_Fivetran_twitter_ads_account_history | External Table | Account name resolution (latest name via ROW_NUMBER) |
| BI_DB_dbo.External_Fivetran_twitter_campaign_history | External Table | Campaign name resolution (latest name via ROW_NUMBER) |
| DWH_dbo.Dim_Country | Table | Geographic dimension — Region, Desk, IsEuropeanCountry via country name JOIN |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | AffiliateWizard registration/FTD counts for affiliates 52350/52351 |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | External_Fivetran_twitter_campaign_locations_report / BI_DB_CIDFirstDates | date / @date | CAST(DATEADD(HOUR,1,date) AS DATE), ISNULL merge with AW |
| AccountID | External_Fivetran_twitter_campaign_locations_report / BI_DB_CIDFirstDates | account_id / AccountID | ISNULL merge TW/AW |
| AccountName | External_Fivetran_twitter_ads_account_history / BI_DB_CIDFirstDates | name / AccountName | Latest via ROW_NUMBER, ISNULL merge |
| CampaignID | External_Fivetran_twitter_campaign_locations_report / BI_DB_CIDFirstDates | campaign_id / CampaignID | ISNULL merge TW/AW |
| CampaignName | External_Fivetran_twitter_campaign_history / BI_DB_CIDFirstDates | name / SubAffiliateID | Latest via ROW_NUMBER, ISNULL merge |
| AffiliateID | External_Fivetran_twitter_campaign_history / BI_DB_CIDFirstDates | name / SerialID | TW: SUBSTRING(name, CHARINDEX('AFFID')+6, 5). AW: SerialID direct |
| Country | External_Fivetran_twitter_campaign_locations_report / BI_DB_CIDFirstDates | segment / Country | ISNULL merge |
| Region | DWH_dbo.Dim_Country | Region | Passthrough via JOIN on country name |
| Desk | DWH_dbo.Dim_Country | Desk | Passthrough via JOIN on country name |
| EU | DWH_dbo.Dim_Country | IsEuropeanCountry | Passthrough via JOIN on country name |
| Platform | Derived | CampaignName | CASE WHEN LOWER(CampaignName) LIKE '%ios%' THEN 'iOS' WHEN '%android%' THEN 'Android' ELSE NULL |
| Cost | External_Fivetran_twitter_campaign_locations_report | billed_charge_local_micro | SUM(billed_charge_local_micro) * 1.00 / 1000000 |
| Impressions | External_Fivetran_twitter_campaign_locations_report | impressions | SUM aggregation |
| App_Clicks | External_Fivetran_twitter_campaign_locations_report | app_clicks | SUM aggregation |
| Clicks | External_Fivetran_twitter_campaign_locations_report | clicks | SUM aggregation |
| TW_Reg | External_Fivetran_twitter_campaign_locations_report | conversion_sign_ups_post_engagement + conversion_sign_ups_post_view | SUM(post_engagement) + SUM(post_view) |
| TW_FTD | External_Fivetran_twitter_campaign_locations_report | conversion_purchases_post_engagement + conversion_purchases_post_view | SUM(post_engagement) + SUM(post_view) |
| AW_Reg | BI_DB_dbo.BI_DB_CIDFirstDates | registered | SUM(CASE WHEN CAST(registered AS DATE)=@date THEN 1 ELSE 0) for affiliates 52350/52351 |
| AW_FTD | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | SUM(CASE WHEN CAST(FirstDepositDate AS DATE)=@date THEN 1 ELSE 0) for affiliates 52350/52351 |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

## Lineage Notes

- **Dual-source merge**: Twitter's own conversion tracking (TW_Reg/TW_FTD) is merged with AffiliateWizard's independent tracking (AW_Reg/AW_FTD) via FULL OUTER JOIN on Date+CampaignName+Country. This allows reconciliation between Twitter-reported conversions and internally-tracked registrations/deposits.
- **AffiliateID extraction**: For TW data, affiliate ID is parsed from the campaign name convention `AFFID_XXXXX`. For AW data, it's the SerialID from CIDFirstDates (hardcoded to affiliates 52350/52351).
- **Rolling 30-day window**: SP deletes and reinserts 30 days back to capture late Twitter conversions (post-engagement/post-view attribution).
