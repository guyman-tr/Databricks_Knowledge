---
name: domain-marketing-and-acquisition
description: "Salesforce Marketing Cloud (SFMC) emails + Marketing Cloud user-behavior + push / in-app notifications + CRM campaigns. Anchors: main.bi_output.bi_output_marketing_sfmc_sfmc_report (2.28B rows / 46 cols ג€” the aggregated email-by-email engagement layer with 20 CampaignGroups Daily / MarketCampaigns / USDaily / ProductUpdates / IncentivePromotions / Transact / eToroCrypto / Smartportfolio / LeadWelcomeJourney / Automation / AdHocCampaignMarketing / LocalCurrency / WebinarPromotion / ClubRecurring / ColdLeadJourney / VerificationJourney / AdHocCampaignOperational / USWelcomeJourney / PopularInvestors / RAFAutomation; CountOpen / UniqueOpen / CountClicks / UniqueClicks / CountBounce are STRING-typed because the ESP API returns nulls as empty strings; partition-format dashed-string), the raw events main.sfmc.silver_sfmc_sent (2.9B) / silver_sfmc_opens (1.67B) / silver_sfmc_clicks (33.6M) / silver_sfmc_bounces (42.2M with BounceCategory + SMTPCode + BounceReason) / silver_sfmc_unsubs (4.4M) / silver_sfmc_complaints (397k) ג€” all columns STRING-typed including EventDate and SubscriberID, all carrying SendID + SubscriberKey + ClientID + BatchID for join-back to the silver_sfmc_sendjobs campaign-job dimension (444k campaign jobs with Subject + FromName + FromEmail + JobStatus + PreviewURL + IsMultipart), the targeting filter main.bi_output.bi_output_marketing_sfmc_sfmc_filter (52.5M RealCID + GCID + ShouldSynced filter targeting), the aggregated stats view main.api_delta.v_backoffice_sfmc_email_stats (4.13B aggregated email-event records keyed by GCID + SendDateID + EmailName), the Marketing Cloud user-behavior personalisation signals main.bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument (per-CID ֳ— InstrumentID with LastVisit / LastMonthAmountInvest / TotalAmountInvest / AssetAmount / OpenActiveInstruments) + _instrument_v + _pi (per-CID ֳ— CIDViewed for Popular-Investor exposure with UserPI flag) + _pi_v, the push/in-app notification platform main.experience.bronze_notificationdb_notifications_marketingtemplate{metadata,content} (with TemplateId + Name + ImageUrl + ChannelType referencing the 3-state ChannelType dictionary 1=InApp 2=Push 3=InApp & Push, plus NotificationMustSend and TtlSeconds for delivery semantics), and the CRM-side campaign object main.crm.silver_crm_campaign (Salesforce-grain) + silver_crm_campaignmember + silver_crm_campaign_eligability__c. Use for email engagement analysis, deliverability, campaign performance, journey orchestration, push-notification campaign tracking, and Marketing Cloud personalisation."
triggers:
  - bi_output_marketing_sfmc_sfmc_report
  - sfmc_report
  - SFMC
  - sfmc
  - silver_sfmc_sent
  - silver_sfmc_opens
  - silver_sfmc_clicks
  - silver_sfmc_bounces
  - silver_sfmc_unsubs
  - silver_sfmc_complaints
  - silver_sfmc_sendjobs
  - silver_sfmc_accountjourneylogtracking
  - silver_sfmc_sendautologgingtracking
  - archive_bi_db_sfmc_sent
  - archive_bi_db_sfmc_opens
  - archive_bi_db_sfmc_clicks
  - archive_bi_db_sfmc_bounces
  - archive_bi_db_sfmc_unsubs
  - archive_bi_db_sfmc_sendjobs
  - archive_bi_db_sfmc_accountjourneylogtracking
  - archive_bi_db_sfmc_sendautologgingtracking
  - bi_output_marketing_sfmc_sfmc_filter
  - sfmc_filter
  - v_backoffice_sfmc_email_stats
  - sfmc_email_stats
  - SubscriberID
  - SubscriberKey
  - ClientID
  - SendID
  - BatchID
  - TriggeredSendExternalKey
  - CampaignGroup
  - CampaignSubGroup
  - CampaignName
  - CampaignNumber
  - EmailName
  - Subject
  - SendDateID
  - SentTime
  - LSD
  - CountOpen
  - UniqueOpen
  - CountClicks
  - UniqueClicks
  - CountBounce
  - CountSend
  - Delivered
  - OpenDate
  - ClickDate
  - BounceCategory
  - BounceReason
  - SMTPCode
  - SendURLID
  - URLID
  - EventType
  - JobStatus
  - FromName
  - FromEmail
  - SchedTime
  - Daily
  - USDaily
  - MarketCampaigns
  - ProductUpdates
  - IncentivePromotions
  - Transact
  - eToroCrypto
  - Smartportfolio
  - LeadWelcomeJourney
  - Automation
  - AdHocCampaignMarketing
  - AdHocCampaignOperational
  - LocalCurrency
  - WebinarPromotion
  - ClubRecurring
  - ColdLeadJourney
  - VerificationJourney
  - USWelcomeJourney
  - PopularInvestors
  - RAFAutomation
  - bi_output_marketing_marketingcloud_user_behavior_instrument
  - bi_output_marketing_marketingcloud_user_behavior_instrument_v
  - bi_output_marketing_marketingcloud_user_behavior_pi
  - bi_output_marketing_marketingcloud_user_behavior_pi_v
  - marketingcloud_user_behavior
  - "Marketing Cloud"
  - UserPI
  - CIDViewed
  - LastMonthAmountInvest
  - TotalAmountInvest
  - AssetAmount
  - OpenActiveInstruments
  - bronze_notificationdb_notifications_marketingtemplatecontent
  - bronze_notificationdb_notifications_marketingtemplatemetadata
  - bronze_notificationdb_notifications_configlabellanguagenamescampaignids
  - marketingtemplatecontent
  - marketingtemplatemetadata
  - bronze_notificationdb_dictionary_marketingchanneltype
  - bronze_notificationdb_dictionary_marketingcontenttype
  - marketingchanneltype
  - marketingcontenttype
  - ChannelType
  - "InApp"
  - "Push"
  - "InApp & Push"
  - silver_crm_campaign
  - silver_crm_campaignmember
  - silver_crm_campaign_eligability__c
  - crm_campaign
sample_questions:
  - "What's the open rate on LeadWelcomeJourney emails last month?"
  - "Top 10 email subjects by unique-click rate in MarketCampaigns"
  - "Per-campaign-group send / open / click breakdown for last week"
  - "Hard-bounce rate per SMTP error code last quarter"
  - "How many customers unsubscribed in May 2026 by CampaignGroup?"
  - "Show me the active push notification campaigns by ChannelType"
  - "Per-Popular-Investor email engagement on the PopularInvestors campaign group"
  - "Which BounceCategory is most common ג€” soft vs hard?"
  - "Total CTR on the VerificationJourney KYC-nudge emails last month"
  - "Daily-sends time-series for the past 30 days from silver_sfmc_sent"
  - "Click-through to URLID breakdown for the IncentivePromotions group"
  - "What proportion of customers in sfmc_filter have ShouldSynced=1?"
  - "How many distinct GCIDs received any email last week?"
  - "Marketing Cloud personalisation: top instruments by LastMonthAmountInvest"
required_tables:
  - main.bi_output.bi_output_marketing_sfmc_sfmc_report
  - main.sfmc.silver_sfmc_sent
  - main.sfmc.silver_sfmc_opens
  - main.sfmc.silver_sfmc_clicks
  - main.sfmc.silver_sfmc_bounces
  - main.sfmc.silver_sfmc_unsubs
  - main.sfmc.silver_sfmc_complaints
  - main.sfmc.silver_sfmc_sendjobs
  - main.sfmc.silver_sfmc_accountjourneylogtracking
  - main.bi_output.bi_output_marketing_sfmc_sfmc_filter
  - main.api_delta.v_backoffice_sfmc_email_stats
  - main.bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument
  - main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi
  - main.experience.bronze_notificationdb_notifications_marketingtemplatemetadata
  - main.experience.bronze_notificationdb_notifications_marketingtemplatecontent
  - main.experience.bronze_notificationdb_dictionary_marketingchanneltype
  - main.experience.bronze_notificationdb_dictionary_marketingcontenttype
  - main.crm.silver_crm_campaign
  - main.crm.silver_crm_campaignmember
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Marketing Comms ג€” SFMC, Marketing Cloud, Push & CRM Campaigns

The post-acquisition outbound layer: emails, push, in-app messages, and CRM campaigns that talk to existing customers (or warm leads). Three platforms: (1) Salesforce Marketing Cloud (SFMC) for emails; (2) Marketing Cloud personalisation engine for product-based recommendations; (3) the in-house notification platform under `notificationdb` for push and in-app. The Salesforce CRM `campaign` object provides the org-level grouping.

## What it covers

### SFMC ג€” the email firehose

Two parallel layers in UC:

**The aggregated layer** ג€” `bi_output.bi_output_marketing_sfmc_sfmc_report` (2.28B rows, 46 cols). One row per `SubscriberID ֳ— Email ֳ— SendID`. The aggregator joins the four event streams (sent / opens / clicks / bounces) into per-send counters: `CountSend` (LONG), `CountOpen`, `UniqueOpen`, `CountClicks`, `UniqueClicks`, `CountBounce`, `Delivered`, `OpenDate`, `ClickDate` (all STRING because ESP-API NULLs serialise as `''`). Carries the campaign-taxonomy columns: `CampaignGroup`, `CampaignSubGroup`, `CampaignName`, `CampaignNumber`, `EmailName`, `Subject`, `SendID`, `SubscriberID`, `GCID`, `SendDateID`, `SentTime`, `LSD` (last-suppressed-date). Partitioned by dashed-string `etr_y` / `etr_ym` / `etr_ymd`.

20-CampaignGroup taxonomy (live 2026 send volumes):

| CampaignGroup | 2026 sends | Lens |
|---|---:|---|
| `Daily` | 111.2M | Daily newsletter blast |
| `MarketCampaigns` | 58.8M | Marketing pushes |
| `USDaily` | 29.1M | US-only newsletter |
| `ProductUpdates` | 25.9M | Feature announcements |
| `IncentivePromotions` | 16.5M | Promo emails |
| `Transact` | 13.4M | Transactional confirmations (deposit / withdrawal / position) |
| `eToroCrypto` | 9.9M | Crypto-product-line emails |
| `Smartportfolio` | 7.9M | Copy-portfolio-product emails |
| `LeadWelcomeJourney` | 7.8M | Welcome sequence for new lead |
| `Automation` | 7.3M | Generic automation flows |
| `AdHocCampaignMarketing` | 6.6M | One-off marketing campaigns |
| `LocalCurrency` | 5.9M | Localised-currency comms |
| `WebinarPromotion` | 5.9M | Webinar invites |
| `ClubRecurring` | 5.1M | Club-tier recurring emails |
| `ColdLeadJourney` | 4.3M | Re-engagement for cold leads |
| `VerificationJourney` | 3.4M | KYC nudge sequence (links to OPS hub) |
| `AdHocCampaignOperational` | 3.4M | One-off operational comms |
| `USWelcomeJourney` | 2.8M | US-specific welcome sequence |
| `PopularInvestors` | 2.6M | PI-related emails |
| `RAFAutomation` | 2.5M | Refer-A-Friend reminder sequence (links to RAF sub-skill) |

**The raw-event layer** ג€” `sfmc.silver_sfmc_*` family. Per-event grain, all columns STRING-typed (because SFMC API returns everything stringified):

| Table | Rows | Use for |
|---|---:|---|
| `silver_sfmc_sent` | 2.9B | Per-send event; the universe of all sends |
| `silver_sfmc_opens` | 1.67B | Per-open event; joined to `sent` on `SendID + SubscriberID` |
| `silver_sfmc_clicks` | 33.6M | Per-click event; carries `URLID`, `SendURLID`, `URL`, `Alias` for the actual link clicked |
| `silver_sfmc_bounces` | 42.2M | Per-bounce event; carries `BounceCategory`, `SMTPCode`, `BounceReason` for deliverability diagnostics |
| `silver_sfmc_unsubs` | 4.4M | Per-unsubscribe event |
| `silver_sfmc_complaints` | 397k | Per-complaint event (spam-report from ESP) |
| `silver_sfmc_sendjobs` | 444k | THE CAMPAIGN-JOB DIMENSION ג€” one row per send-job with `Subject`, `FromName`, `FromEmail`, `SchedTime`, `SentTime`, `EmailName`, `JobStatus`, `IsMultipart`, `PreviewURL`, `Additional` |
| `silver_sfmc_accountjourneylogtracking` | (medium) | Journey-engine state log per subscriber |
| `silver_sfmc_sendautologgingtracking` | (medium) | Send-auto-logging state |

Plus `sfmc.archive_bi_db_sfmc_*` ג€” historical archives of the same events (snapshotted from the previous BI_DB schema, retained for historical analysis).

All silver tables partition on dashed `etr_y` / `etr_ym` / `etr_ymd`. Join key for stitching events: `SendID + SubscriberID + BatchID + TriggeredSendExternalKey` (the 4-tuple is unique). For per-customer engagement: prefer `bi_output_marketing_sfmc_sfmc_report` over the silver tables ג€” it's pre-joined and carries `GCID`.

**The aggregated stats view** ג€” `api_delta.v_backoffice_sfmc_email_stats` (4.13B rows). Lean schema: `GCID`, `SendDateID`, `EmailName`, `CountSend`, `Delivered`, `UniqueOpen`, `UniqueClicks`. This is the BackOffice-facing per-GCID-per-email summary used by BackOffice's customer-engagement panel. NOT a source-of-truth for marketing analytics ג€” use `sfmc_report` for richer columns.

**The targeting filter** ג€” `bi_output.bi_output_marketing_sfmc_sfmc_filter` (52.5M rows). Schema: `RealCID`, `GCID`, `ShouldSynced INT`, `UpdateDate`, dashed-string partitions. This is the "who SHOULD be in SFMC at any moment" sync-filter ג€” customers move in and out as their status changes (opt-in / unsubscribe / closure). For "customers eligible for marketing email right now" filter on this table.

### Marketing Cloud ג€” personalisation engine

`bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument` ג€” per-`(CID, InstrumentID)` snapshot, 14 cols: `CID`, `AccountId`, `LastVisit`, `LastMonthAmountInvest`, `LastMonthOpenPositionsInvest`, `TotalAmountInvest`, `TotalPositionsInvest`, `AssetAmount`, `AssetPositions`, `OpenActiveInstruments`, `InstrumentID`, `InstrumentTypeID`, `InstrumentName`, `LastOpen`, `DateID`, `UpdateDate`. Per-customer ֳ— per-instrument personalisation signals ג€” feeds the personalised "trending in your portfolio" / "you might like" Marketing Cloud recommendation surfaces.

`bi_output.bi_output_marketing_marketingcloud_user_behavior_pi` ג€” per-`(CID, CIDViewed)` snapshot for Popular-Investor exposure: `UserPI` (STRING ג€” flag indicating CID-viewed is a PI), `LastVisit`, `LastOpen`, plus same investment-signal columns as the instrument variant. Feeds the PI-recommendation surfaces.

The `_v` variants (`_instrument_v`, `_pi_v`) are stable view versions used by the Marketing Cloud-side API connector.

### Notification platform ג€” push + in-app

`experience.bronze_notificationdb_notifications_marketingtemplatemetadata` ג€” the template registry. Schema: `TemplateId`, `Name`, `ActionLink_Junk` (bot-protected URL), `ImageUrl`, `ImageTitle`, `TtlSeconds` (time-to-live in seconds), `ExpiresOn`, `LastUpdatedOn`, `LastUpdatedBy`, `Notes`, `Status INT`, `PushActionLink_Junk` (bot-protected push URL), `PushExternalTemplateId` (link to ESP-side push template), `ChannelType`, `NotificationMustSend BOOLEAN`, `ValidForHours`, `SubCategoryId`.

`ChannelType` dictionary (`experience.bronze_notificationdb_dictionary_marketingchanneltype`): `1 = InApp`, `2 = Push`, `3 = InApp & Push`. Just three states.

`marketingcontenttype` dictionary (`bronze_notificationdb_dictionary_marketingcontenttype`) has `Type INT ג†’ TypeDesc` for the content-type taxonomy.

The `_Junk` suffix on URL columns is a bot-protection / obfuscation convention ג€” the actual URLs are wrapped through a junk-id redirection that resolves to the real link at click-time. For deliverability analysis use the `_Junk` columns directly; for content analysis, the `TemplateId` is the join key.

`bronze_notificationdb_notifications_marketingtemplatecontent` carries the per-template per-language content body.

`bronze_notificationdb_notifications_configlabellanguagenamescampaignids` maps Notification-platform campaign IDs to label / language for cross-system reference.

### CRM-side campaign object

Salesforce's standard `Campaign` object:

- `crm.silver_crm_campaign` ג€” Campaign records (Salesforce-grain, `__c` standard object).
- `crm.silver_crm_campaignmember` ג€” per-member campaign-membership records.
- `crm.silver_crm_campaign_eligability__c` ג€” Salesforce custom object for campaign-eligibility tracking.

These are used by the Marketing team for ad-hoc campaign segmentation in Salesforce, often as the SOURCE of `sfmc_filter` populations. Cross-system: `silver_crm_campaign.Id` ג†” `sfmc_report.CampaignName` is a SOFT join (string-match by convention, not strictly enforced).

## Critical Warnings

1. **Tier 1 ג€” Every `silver_sfmc_*` raw event table has ALL columns STRING-typed, including `EventDate`.** SFMC's ESP API returns all fields as strings, and the silver loader preserves that. For time-window queries, ALWAYS use the `etr_ymd` partition column (also string, dashed format): `WHERE etr_y = '2026' AND etr_ymd BETWEEN '2026-05-01' AND '2026-05-31'`. To compare on `EventDate` use `TRY_CAST(EventDate AS TIMESTAMP)` because malformed dates exist as `''` empty-strings.

2. **Tier 1 ג€” On `bi_output_marketing_sfmc_sfmc_report`, the count columns are STRING-typed and need NULL-aware casting before aggregation.** `CountOpen`, `UniqueOpen`, `CountClicks`, `UniqueClicks`, `CountBounce`, `Delivered`, `OpenDate`, `ClickDate` are all STRING because the upstream serialises NULL as empty-string. Pattern: `SUM(CAST(NULLIF(CountOpen, '') AS BIGINT))`. Only `CountSend` is properly typed as `LONG`. Forgetting to cast silently returns NULL aggregates.

3. **Tier 1 ג€” `CampaignGroup` is the FIRST cut for any SFMC analysis. 20 production values.** Filter on this first; `CampaignSubGroup` is the second cut (typically 4-12 values per group). The `Daily / USDaily` groups dominate volume (~140M sends / month combined) ג€” for question "marketing email engagement" the user probably wants `MarketCampaigns / IncentivePromotions / Smartportfolio / eToroCrypto / ProductUpdates / WebinarPromotion` etc., NOT `Daily`. Always confirm whether the user wants marketing-only or all sends.

4. **Tier 1 ג€” Three CampaignGroups cross-reference other domains: `VerificationJourney` ג†’ OPS hub (KYC nudges), `RAFAutomation` ג†’ RAF sub-skill (referral reminders), `Transact` ג†’ payments hub (deposit / withdrawal / position confirmations).** Be explicit about which to include for "marketing-only" questions. Most marketing-attribution analysis EXCLUDES `Transact` and `VerificationJourney` as those are operational / journey-not-marketing.

5. **Tier 1 ג€” `silver_sfmc_*` events DO NOT carry GCID ג€” they carry `SubscriberID` and `SubscriberKey` (both STRING).** GCID mapping lives in `bi_output_marketing_sfmc_sfmc_report` or via `bi_output_marketing_sfmc_sfmc_filter`. For per-customer engagement, prefer `sfmc_report`. For per-SendID deep-dive (which URLs clicked), drive off silver but DO NOT expect GCID to be there ג€” join via `sfmc_filter.SubscriberID = silver_sfmc_clicks.SubscriberID` to get GCID. SubscriberID may not be 1:1 with active GCID for closed customers.

6. **Tier 1 ג€” SendID granularity: one campaign-job (`silver_sfmc_sendjobs.SendID`) has MANY per-recipient SendIDs in the events.** A SendJob is the "blast" (the marketing team's design of a campaign + audience + creative + schedule); each SendID is the per-recipient send event. For "how many unique sends went out in this campaign" use `SUM(CountSend)` on `sfmc_report` for that campaign. For "what did this specific campaign-job look like" use `silver_sfmc_sendjobs.SendID = <ID>` and pull `Subject / FromName / FromEmail / EmailName / SchedTime / SentTime / JobStatus / PreviewURL`.

7. **Tier 2 ג€” `silver_sfmc_bounces.BounceCategory` differentiates hard vs soft bounce; `SMTPCode` is the underlying delivery-failure code.** Hard bounces (invalid address / mailbox-doesn't-exist) trigger ESP auto-unsubscribe; soft bounces (full mailbox / temporary failure) retry. For deliverability KPI tracking, count hard bounces by `BounceCategory`; for full diagnostics, group by `SMTPCode` + `BounceReason`.

8. **Tier 2 ג€” `silver_sfmc_complaints` (397k rows) is the SPAM-report log.** When a recipient marks the email as spam, ESPs propagate the complaint back. High `complaints / sends` rate (>0.1%) damages sender reputation and lowers inbox-placement for ALL sends. The unsubs table (`silver_sfmc_unsubs`) is the standard one-click-unsubscribe; complaints is the spam-button click.

9. **Tier 2 ג€” `bi_output_marketing_sfmc_sfmc_filter.ShouldSynced` is INT (0 / 1) and represents the SYNC-eligibility flag.** Customers with `ShouldSynced = 0` are EXCLUDED from SFMC syncs ג€” closed accounts, unsubscribed, opt-out-from-marketing. Customers move in and out as their status changes. For "customers currently eligible for marketing email" filter on the most-recent partition (`MAX(etr_ymd)`) `WHERE ShouldSynced = 1`.

10. **Tier 2 ג€” `api_delta.v_backoffice_sfmc_email_stats` (4.13B rows) is a DERIVED view, not a source table.** It aggregates `silver_sfmc_*` events into per-`(GCID, SendDateID, EmailName)` summaries for the BackOffice UI. Use for BackOffice-facing per-customer engagement panels; DO NOT use for marketing analytics ג€” `bi_output_marketing_sfmc_sfmc_report` is richer and includes `CampaignGroup`. The 4B-row volume reflects the historical fan-out.

11. **Tier 2 ג€” `bronze_notificationdb_*` push/in-app templates use the `_Junk` URL convention.** `ActionLink_Junk` and `PushActionLink_Junk` are bot-protected URL wrappers ג€” when a customer taps the notification, the junk-URL redirects through eToro's click-tracking subdomain. The actual landing-page URL is NOT in the table; only the wrapped link. For "where did the notification go" you need the click-tracking logs (which live OUTSIDE this hub ג€” typically `de_output` or `experience` event streams).

12. **Tier 2 ג€” `bronze_notificationdb_dictionary_marketingchanneltype` has only 3 values: 1=InApp, 2=Push, 3=InApp & Push.** Templates with ChannelType=3 fan out to both inbox-in-app AND mobile push ג€” counted twice for engagement. The `notificationdb` covers push/in-app ג€” emails are exclusively in SFMC; the two platforms are SEPARATE (no overlap).

13. **Tier 3 ג€” SFMC silver tables have `archive_bi_db_sfmc_*` siblings in the `sfmc` schema.** These are PRE-MIGRATION historical archives from the previous BI_DB schema (`archive_bi_db_sfmc_sent`, `_opens`, `_clicks`, etc.). For analytical-current-state use `silver_sfmc_*`; for "send-history before X" cross-check the archive variants. Same column shape, separated by data age.

14. **Tier 3 ג€” `crm.silver_crm_campaign` and `silver_crm_campaignmember` are Salesforce-grain ג€” soft-delete via `IsDeleted = false`.** Salesforce campaigns may be set up for the marketing team's internal workflow ("plan a Q3 webinar push") without ever generating SFMC sends. Cross-join via `campaign.Id ג†” sfmc_report.CampaignName` is by-convention string-match, NOT a foreign-key. For end-to-end "what CRM campaign drove these sends" the link may not exist.

15. **Tier 3 ג€” The `marketingcloud_user_behavior_*` tables are PERSONALISATION SIGNALS fed back to Marketing Cloud's recommendation engine.** They are NOT engagement data themselves; they feed the upstream personalisation engine that then DECIDES which email/instrument/PI to feature. For "what was recommended to customer X" you'd need the Marketing Cloud API logs (not in UC); for "what customer X did to drive the recommendation" use these tables.

## Canonical query patterns

### Pattern A ג€” Campaign-group engagement summary last month

```sql
SELECT
  CampaignGroup,
  COUNT(DISTINCT SendID) AS n_sends,
  SUM(CountSend) AS total_sends,
  SUM(CAST(NULLIF(UniqueOpen, '') AS BIGINT)) AS unique_opens,
  SUM(CAST(NULLIF(UniqueClicks, '') AS BIGINT)) AS unique_clicks,
  SUM(CAST(NULLIF(CountBounce, '') AS BIGINT)) AS bounces,
  ROUND(100.0 * SUM(CAST(NULLIF(UniqueOpen, '') AS BIGINT)) / NULLIF(SUM(CountSend),0), 2) AS open_rate_pct,
  ROUND(100.0 * SUM(CAST(NULLIF(UniqueClicks, '') AS BIGINT)) / NULLIF(SUM(CountSend),0), 2) AS click_rate_pct
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report
WHERE etr_y = '2026'
  AND etr_ymd BETWEEN '2026-04-01' AND '2026-04-30'
GROUP BY 1
ORDER BY total_sends DESC
```

### Pattern B ג€” Top subject lines by unique-click rate in MarketCampaigns

```sql
SELECT
  Subject,
  EmailName,
  COUNT(DISTINCT SendID) AS n_sends,
  SUM(CountSend) AS total_sends,
  SUM(CAST(NULLIF(UniqueClicks, '') AS BIGINT)) AS unique_clicks,
  ROUND(100.0 * SUM(CAST(NULLIF(UniqueClicks, '') AS BIGINT)) / NULLIF(SUM(CountSend),0), 2) AS click_rate_pct
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report
WHERE etr_y = '2026'
  AND etr_ymd BETWEEN '2026-04-01' AND '2026-04-30'
  AND CampaignGroup = 'MarketCampaigns'
GROUP BY 1, 2
HAVING SUM(CountSend) >= 10000
ORDER BY click_rate_pct DESC
LIMIT 20
```

### Pattern C ג€” Hard-bounce rate per SMTP code last week

```sql
SELECT
  b.BounceCategory,
  b.SMTPCode,
  COUNT(*) AS n_bounces,
  COUNT(DISTINCT b.SubscriberID) AS n_distinct_subscribers
FROM main.sfmc.silver_sfmc_bounces b
WHERE b.etr_y = '2026'
  AND b.etr_ymd >= '2026-05-20'
GROUP BY 1, 2
ORDER BY n_bounces DESC
LIMIT 30
```

### Pattern D ג€” Per-customer SFMC engagement (last 30 days)

```sql
SELECT
  GCID,
  COUNT(DISTINCT SendID) AS sends,
  SUM(CAST(NULLIF(UniqueOpen, '') AS BIGINT)) AS opens,
  SUM(CAST(NULLIF(UniqueClicks, '') AS BIGINT)) AS clicks
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report
WHERE etr_y = '2026'
  AND etr_ymd >= DATE_FORMAT(current_date - INTERVAL 30 DAYS, 'yyyy-MM-dd')
  AND GCID IS NOT NULL
  AND CampaignGroup NOT IN ('Transact', 'VerificationJourney')
GROUP BY 1
ORDER BY clicks DESC
LIMIT 50
```

### Pattern E ג€” Currently SFMC-eligible customer count

```sql
WITH latest AS (
  SELECT MAX(etr_ymd) AS latest_ymd
  FROM main.bi_output.bi_output_marketing_sfmc_sfmc_filter
  WHERE etr_y = '2026'
)
SELECT
  ShouldSynced,
  COUNT(DISTINCT GCID) AS n_customers
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_filter, latest
WHERE etr_ymd = latest.latest_ymd
GROUP BY 1
```

## Federation hooks

- `bi_output_marketing_sfmc_sfmc_report.GCID` joins to `dim_customer_masked.GCID` for customer-master enrichment ג€” see `../domain-customer-and-identity/customer-master-record.md`.
- `CampaignGroup = 'VerificationJourney'` correlates to the KYC nudge cycle measured in `../domain-ops-and-onboarding/electronic-verification-and-registration-funnel.md` (the OPS hub's `registrationfunnel.VerificationLevel3_DateTime`).
- `CampaignGroup = 'RAFAutomation'` correlates to the RAF reminder cycle measured in [`raf-and-incentives.md`](raf-and-incentives.md) (`v_raf`'s referrer-side communications).
- `CampaignGroup = 'Transact'` correlates to deposit / withdrawal events in `../domain-payments/`.
- `marketingcloud_user_behavior_instrument.CID ֳ— InstrumentID` joins to `domain-trading` instrument dim ג€” see `../domain-trading/position-state-and-grain.md` for the instrument dim.
- For email-engagement-driven A/B tests, the experiment-treatment overlay lives in `../domain-product-analytics/ab-testing-and-experimentation.md` ג€” but the EMAIL engagement event itself is here.

## Last verified

2026-05-28 ג€” schema probed on `silver_sfmc_*` tables (all-STRING confirmed including EventDate); `CampaignGroup` taxonomy enumerated (20 production values with 2026 send-volumes); `bounces / unsubs / complaints` distinct from sent / opens / clicks; `marketingchanneltype` enum confirmed (1=InApp, 2=Push, 3=InApp & Push); silver_sfmc_sendjobs identified as canonical campaign-job dimension; sfmc_filter `ShouldSynced` flag verified.
