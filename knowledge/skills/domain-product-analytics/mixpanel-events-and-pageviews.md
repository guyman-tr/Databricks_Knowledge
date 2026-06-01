---
name: domain-product-analytics
description: "Mixpanel ג€” eToro's primary clickstream / UI event store. Three physical layers under main.mixpanel: (1) raw firehose at main.mixpanel.silver and main.mixpanel.bronze (6,225 columns each, every event property a column, ~138M rows/day, partitioned by STRING etr_y='2026' / etr_ym='2026-05' / etr_ymd='2026-05-28' dashed format), event name on mp_event_name (NOT event_name ג€” that's <0.001% populated); (2) curated event-type slices at main.mixpanel.{login_events, feed_events, notifications_events, recurring_deposit_events, search_events} with 25-38 cols each, GCID-keyed via the GCID column, EventName as the event-name column (PascalCase, different from silver), same dashed etr_y/_ym/_ymd partition, history back to 2020-2021; (3) pageview marts at main.mixpanel.{gold_mixpanel_userpageviews, gold_mixpanel_marketpageviews} with 13 cols carrying uniqueID + mp_user_id + InstrumentId + Identifier + Occurred (bigint epoch) + Timestamp + DateID + etr partitions. Identity scheme has FIVE keys: cid (DOUBLE, eToro platform Customer ID resolved upstream), gcid (DOUBLE, cross-product key, preferred for joins to other UC tables), distinct_id (STRING, Mixpanel-internal persistent ID, may be device-derived for anonymous users ג€” do NOT join cross-system on it), mp_anon_id and mp_anon_distinct_id (pre-login anonymous), i_identify_user_id (the eToro user ID passed to Mixpanel's identify() call). Pre-login events have cid IS NULL. The Fivetran-driven schema-flattening produces type-suffix duplicate columns (cid, cid_string, cid_1, cid_1_2 ג€” same logical property, different historical types) and hundreds of corrupt mp_device_id-prefixed / mp_initial_referrer-prefixed columns from an upstream value-injected-into-column-name bug that should be ignored. Top event volumes on a typical day (single day 2026-05-27 sample): Targeted Delivery 43M, Notification Actions BE 12M, Portfolio - Page View 7.6M, Market - Item Clicked 4.7M, Market - Page View 4.2M, Login - Attempt 2.1M, Login - Success 2M, Refer A Friend - Card View 1.5M, Trading.Position.Close - Close Trade Success 1.4M. Derived Mixpanel-event panels for feature adoption and retention live at main.product_analytics_stg.bi_output_product_analytics_{feature_retention_daily_feature_usage, user_sessions_tables, optin_dashboard_aggregation, optin_monthly_optins, optin_optin_history_bronze, 2fa_activation, anomaly_detection_daily_digest, anomaly_detection_scoring, anomaly_detection_market_news, pi_diversification_recommendations}."
triggers:
  - mixpanel.silver
  - mixpanel.bronze
  - main.mixpanel.silver
  - main.mixpanel.bronze
  - mp_event_name
  - mp_distinct_id
  - mp_anon_id
  - mp_anon_distinct_id
  - i_identify_user_id
  - mp_device_id
  - mp_country_code
  - mp_browser
  - mp_app_release
  - mp_app_version
  - mp_lib
  - mp_user_id
  - mixpanel.login_events
  - mixpanel.feed_events
  - mixpanel.notifications_events
  - mixpanel.recurring_deposit_events
  - mixpanel.search_events
  - gold_mixpanel_userpageviews
  - gold_mixpanel_marketpageviews
  - userpageviews
  - marketpageviews
  - vw_mixpanel_login_events
  - Targeted Delivery
  - Notification Actions BE
  - Portfolio - Page View
  - Market - Page View
  - Login - Attempt
  - Login - Success
  - Refer A Friend - Card View
  - distinct_id
  - 6225 columns
  - feature_retention_daily_feature_usage
  - user_sessions_tables
  - optin_dashboard_aggregation
  - optin_monthly_optins
  - optin_optin_history_bronze
  - 2fa_activation
  - anomaly_detection_daily_digest
  - anomaly_detection_scoring
  - pi_diversification_recommendations
  - cid_string
  - cid_1_2
  - mp_device_id corruption
  - EventName PascalCase
sample_questions:
  - "How many users opened the Market page yesterday?"
  - "Show me the top 20 mp_event_name values for the last day"
  - "Why is event_name empty on mixpanel.silver?"
  - "Why are there hundreds of mp_device_id-prefixed columns?"
  - "What's the difference between cid, gcid, distinct_id and mp_anon_id?"
  - "How big is mixpanel.silver per day?"
  - "Which Mixpanel slice should I use for login analysis?"
  - "How do I filter mixpanel.silver by date?"
  - "How do I join Mixpanel events to a CID?"
  - "What does cid_string vs cid mean in mixpanel.silver?"
  - "Show me daily distinct logged-in users via Mixpanel"
  - "How do I get pageview counts by instrument from gold_mixpanel_marketpageviews?"
  - "What's the right way to count anonymous-vs-logged-in funnel drop-off?"
  - "Where are feature-adoption / retention panels derived from Mixpanel?"
  - "How fresh is mixpanel.silver?"
required_tables:
  - main.mixpanel.silver
  - main.mixpanel.bronze
  - main.mixpanel.login_events
  - main.mixpanel.feed_events
  - main.mixpanel.notifications_events
  - main.mixpanel.recurring_deposit_events
  - main.mixpanel.search_events
  - main.mixpanel.gold_mixpanel_userpageviews
  - main.mixpanel.gold_mixpanel_marketpageviews
  - main.product_analytics_stg.bi_output_product_analytics_feature_retention_daily_feature_usage
  - main.product_analytics_stg.bi_output_product_analytics_user_sessions_tables
  - main.product_analytics_stg.bi_output_product_analytics_optin_dashboard_aggregation
  - main.product_analytics_stg.bi_output_product_analytics_2fa_activation
domain_tags:
  - mixpanel
  - clickstream
  - pageviews
  - events
  - product-analytics
  - behavioural
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Mixpanel events & pageviews

The three Mixpanel layers ג€” raw firehose, curated event-type slices, and pageview marts ג€” each have a place. Knowing which to query is the single biggest performance and correctness decision in this sub-domain.

## When to Use

Load for questions about:

- Specific Mixpanel event names ("how many `Login - Success` events yesterday?")
- App-level funnel steps not yet curated into a slice (`silver` is required)
- Cross-event analysis on the same user session (`silver` with mp_distinct_id grouping)
- Pageview rollups per instrument / per user / per market (gold marts)
- Feature adoption / retention / opt-in panels derived from Mixpanel
- Mixpanel identity-resolution debugging ("why is this user missing a cid?")
- Login event volume / failure analysis (`login_events`)
- Notification engagement (`notifications_events`)
- Search query analysis (`search_events`)
- Recurring-deposit funnel (`recurring_deposit_events`)

Do NOT load for:

- A/B test exposure or results ג€” see [`ab-testing-and-experimentation.md`](ab-testing-and-experimentation.md)
- Social feed engagement events (posts, reactions, comments) ג€” those are SERVER-side events under `experience.bronze_event_hub_*streams_*`, not client-side Mixpanel events. See [`feed-and-social-analytics.md`](feed-and-social-analytics.md). NOTE: `mixpanel.feed_events` captures the CLIENT-side UI events around feed interactions and is in scope here, but it's keyed differently and complementary to the server-side stream.
- Customer-static attributes for downstream rollup ג€” `domain-customer-and-identity/customer-master-record.md`
- Customer cluster / LTV models that consume these events upstream ג€” `domain-customer-and-identity/customer-models-and-segmentation.md`

## Scope

In scope: `main.mixpanel.silver` and `bronze` (raw firehose, 6,225 cols, ~138M rows/day, EAV-flattened from Mixpanel through Fivetran); the five curated event-type slices `main.mixpanel.{login_events, feed_events, notifications_events, recurring_deposit_events, search_events}` (25-38 cols, GCID-keyed, EventName PascalCase, dashed etr partitions, history back to 2020-2021); the two pageview marts `main.mixpanel.{gold_mixpanel_userpageviews, gold_mixpanel_marketpageviews}` (13 cols each); the five-identity scheme (`cid`, `gcid`, `distinct_id`, `mp_anon_id`/`mp_anon_distinct_id`, `i_identify_user_id`, `mp_device_id`); the partition convention (STRING-typed dashed `'2026'` / `'2026-05'` / `'2026-05-28'`); the `mp_event_name` vs `event_name` quirk; the type-suffix duplicate-column pattern (`cid` / `cid_string` / `cid_1` / `cid_1_2`); the corrupt-column noise (`mp_device_id<random-digits>`, `mp_initial_referrer<random-digits>`); the derived Mixpanel-event panels at `main.product_analytics_stg.bi_output_product_analytics_{feature_retention_daily_feature_usage, user_sessions_tables, optin_*, 2fa_activation, anomaly_detection_*, pi_diversification_recommendations}`.

Out of scope: ABtoro / Optimizely experimentation tables (this hub's `ab-testing-and-experimentation.md`); server-side feed event hub (`feed-and-social-analytics.md`); customer attribute master tables (`domain-customer-and-identity`); the Mixpanel Fivetran pipeline configuration itself; the Mixpanel SDK in the eToro apps.

Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 ג€” `mixpanel.silver` has 6,225 columns and ~138M rows/day. Never `SELECT *`.** Project exactly the columns you need. Always add a partition filter (`etr_y`, `etr_ym`, or `etr_ymd`). Filtering by partition is the difference between a 5-second query and an outage. Even a 7-day-window aggregation needs explicit column projection; the query planner will keep all 6,225 columns alive otherwise.

2. **Tier 1 ג€” Partition columns are STRING dashed format, not integer.** `etr_y='2026'`, `etr_ym='2026-05'`, `etr_ymd='2026-05-28'`. `WHERE etr_ymd > 20260501` (integer) returns zero rows; `WHERE etr_ymd >= '20260525'` (no-dash string) returns zero rows. Confirm format with `SELECT DISTINCT etr_ymd FROM <table> WHERE etr_y='2026' ORDER BY etr_ymd DESC LIMIT 3` before designing any date filter. This applies uniformly to silver, bronze, every curated slice, and the gold marts.

3. **Tier 1 ג€” Event name is `mp_event_name` on silver/bronze; `EventName` on curated slices.** `event_name` exists on silver but is populated on <0.001% of rows (sample day had 134 non-null `event_name` rows out of 137,570,941 total). Curated slices reverse the convention to PascalCase `EventName`. Porting a query between the two layers without flipping this column name returns a silent empty result.

4. **Tier 1 ג€” Mixpanel has FIVE identity columns; pick the right one.** For join to other UC / DWH tables: prefer `gcid` (DOUBLE, cross-product), fall back to `cid` (DOUBLE). NEVER join on `distinct_id` (Mixpanel-internal ג€” may be a device ID, may be an anon string, may be an old-format CID ג€” unreliable). `mp_anon_id` / `mp_anon_distinct_id` mark pre-login anonymous users; `i_identify_user_id` is the eToro user-ID passed to Mixpanel's `identify()` call (use it only when `gcid`/`cid` is null and you need an upstream re-resolve). Drop rows with `cid IS NULL` for any per-customer rollup unless analysing top-of-funnel anonymous traffic.

5. **Tier 2 ג€” Same logical property may appear under multiple type-suffix columns on silver/bronze.** When Mixpanel-via-Fivetran observed a property sent with multiple types over time (e.g. `cid` sometimes as a number, sometimes as a string, sometimes nested inside a `_1_2_3` path), it created type-discriminated column variants: `cid`, `cid_string`, `cid_1`, `cid_1_2`, `cid_1_2_string`. The unsuffixed name is usually the type the data team standardised on, but rare events may carry the value only in a `_string` / `_blob` / `_1_2` variant. When a Mixpanel query returns a suspicious zero count on `cid`, also check `cid_string` / `cid_1` / `cid_1_2` before concluding the event genuinely lacked the property. The pattern applies to other properties too ג€” search the columns list for `<prop>_string`, `<prop>_1`, `<prop>_numeric`, `<prop>_blob`, `<prop>_boolean`.

6. **Tier 2 ג€” Hundreds of `mp_device_id<random-digits>` and `mp_initial_referrer<random-digits>` columns are upstream Mixpanel-pipeline corruption ג€” ignore them.** They were created by a Mixpanel schema-bug that injected actual device-ID values into the property-name namespace. They carry near-zero non-null data. There's no clean removal path (Fivetran reads them as-is) so the cleanup is being negotiated upstream. Pattern: any `mp_device_id` followed by digits (e.g. `mp_device_id01569188566`, `mp_device_id3911643359`, `mp_device_id_5555`, `mp_device_idnull`, `mp_device_idfalse`) is corruption. The real column is just `mp_device_id`.

7. **Tier 2 ג€” Prefer the curated event-type slices over silver for high-traffic single-event-type questions.** `login_events`, `feed_events`, `notifications_events`, `recurring_deposit_events`, `search_events` are pre-filtered and pre-projected to 25-38 relevant columns, GCID-keyed and partition-ready. They scan ~1000ֳ— less data than silver for the same analytical answer. Use silver only when the event type you need isn't in a slice, OR when you need a property that the slice doesn't carry, OR when you need cross-event-type session analysis on a single mp_distinct_id.

8. **Tier 2 ג€” Pageview marts are at SESSION grain, not event grain.** `gold_mixpanel_userpageviews` and `gold_mixpanel_marketpageviews` aggregate the underlying `Portfolio - Page View` / `Market - Page View` events into user-and-instrument-keyed sessions. Don't double-count by also joining to silver ג€” the marts already de-duplicate. For raw event-level "every single Market PageView happened" use silver; for "how many distinct user-market sessions" use the marts.

9. **Tier 3 ג€” `Occurred` on the pageview marts is a BIGINT epoch (millisecond Unix timestamp), not a date.** Convert with `from_unixtime(Occurred / 1000)` before any human-readable date logic. `Timestamp` (TIMESTAMP type) and `DateID` (INT date dimension key) are also available and easier ג€” use them unless you need millisecond precision.

10. **Tier 3 ג€” `bronze` and `silver` have identical 6,225-column schemas; silver is silver-pipeline cleaned but DOES NOT add or remove rows.** Use silver for 99% of analysis. Use bronze only for Fivetran-side debugging.

11. **Tier 3 ג€” Anonymous funnel-top events are NOT a bug.** Mixpanel fires events from registration / landing / KYC flows before a CID is assigned. `cid IS NULL AND mp_anon_id IS NOT NULL` rows are legitimate pre-login funnel data. Use them when answering "of N people who saw the registration page, how many got to KYC?"; drop them when answering "of N existing customers, how many did X?"

12. **Tier 3 ג€” Derived feature-adoption panels at `product_analytics_stg.bi_output_product_analytics_*` are CONSUMERS, not Mixpanel-source.** They aggregate silver events on a schedule. If a panel's last_updated lags, it's a panel pipeline issue, not a Mixpanel ingestion issue. Check silver's `MAX(etr_ymd)` before debugging a panel.

## Layer-by-layer reference

### Raw firehose

| Table | Cols | Rows/day | When to use |
|---|---:|---:|---|
| `main.mixpanel.silver` | 6225 | ~138M | Default analytical layer. Cleaned/coerced. |
| `main.mixpanel.bronze` | 6225 | ~138M | Identical schema to silver, raw Fivetran. Debug-only. |

### Curated event-type slices (preferred for single-event-type questions)

| Table | Cols | History | Event-name column | Customer key |
|---|---:|---|---|---|
| `main.mixpanel.login_events` | 25 | 2020-01-07 ג†’ today | `EventName` | `GCID` |
| `main.mixpanel.feed_events` | 34 | 2020-01-07 ג†’ today | `EventName` | `GCID` |
| `main.mixpanel.notifications_events` | 38 | 2020-01-07 ג†’ today | `EventName` | `GCID` |
| `main.mixpanel.recurring_deposit_events` | 26 | 2021-01-31 ג†’ today | `EventName` | `GCID` |
| `main.mixpanel.search_events` | 26 | 2020-09-01 ג†’ today | `EventName` | `GCID` |

### Pageview marts (session grain)

| Table | Cols | What |
|---|---:|---|
| `main.mixpanel.gold_mixpanel_userpageviews` | 13 | User-level page views, keyed by `mp_user_id` + `Identifier` |
| `main.mixpanel.gold_mixpanel_marketpageviews` | 13 | Market-page views, keyed by `mp_user_id` + `InstrumentId` |

Shared columns on both marts: `uniqueID`, `mp_user_id`, `mp_event_name`, `Identifier`/`InstrumentId`, `item_id_numeric`, `Occurred` (bigint epoch ms), `Timestamp`, `DateID`, `etr_y` / `etr_ym` / `etr_ymd`, `UpdateDate`.

### Derived Mixpanel-event panels (downstream consumers)

| Table | Lens |
|---|---|
| `main.product_analytics_stg.bi_output_product_analytics_feature_retention_daily_feature_usage` | Per-feature daily usage / retention |
| `main.product_analytics_stg.bi_output_product_analytics_user_sessions_tables` | Session-grain rollups |
| `main.product_analytics_stg.bi_output_product_analytics_optin_dashboard_aggregation` | Opt-in / consent state aggregates |
| `main.product_analytics_stg.bi_output_product_analytics_optin_monthly_optins` | Monthly opt-in flows |
| `main.product_analytics_stg.bi_output_product_analytics_optin_optin_history_bronze` | Per-user opt-in history |
| `main.product_analytics_stg.bi_output_product_analytics_2fa_activation` | 2FA adoption curve |
| `main.product_analytics_stg.bi_output_product_analytics_anomaly_detection_daily_digest` | Anomaly detection daily digest |
| `main.product_analytics_stg.bi_output_product_analytics_anomaly_detection_scoring` | Anomaly scoring per metric |
| `main.product_analytics_stg.bi_output_product_analytics_anomaly_detection_market_news` | News-vs-event-volume correlation |
| `main.product_analytics_stg.bi_output_product_analytics_pi_diversification_recommendations` | PI diversification recs (Mixpanel-event-fed) |

## Top event volumes (single day 2026-05-27)

| Rank | mp_event_name | Day count |
|---:|---|---:|
| 1 | Targeted Delivery | 43,465,005 |
| 2 | Notification Actions BE | 12,311,754 |
| 3 | Portfolio - Page View | 7,634,688 |
| 4 | Market - Item Clicked | 4,735,227 |
| 5 | Market - Page View | 4,232,078 |
| 6 | Portfolio - Item Clicked | 4,228,860 |
| 7 | Bottom Navigation - Portfolio - Click | 2,756,495 |
| 8 | Market - Element Shown | 2,520,579 |
| 9 | Home - Page View | 2,490,159 |
| 10 | Watchlist - Item Clicked | 2,361,925 |
| 11 | Side Navigation Menu - Page View | 2,359,916 |
| 12 | Login - Attempt | 2,074,887 |
| 13 | Login - Success | 2,034,872 |
| 14 | Journey Entry | 2,013,679 |
| 15 | Ticker - View | 1,887,265 |
| 16 | Activity Sent | 1,866,075 |
| 17 | Watchlist - Page View | 1,587,041 |
| 18 | Refer A Friend - Card View | 1,537,771 |
| 19 | Market - Recurring Investment | 1,480,553 |
| 20 | Trading.Position.Close - Close Trade Success | 1,425,867 |

Day total: 137,570,941 events / 42,599 distinct CIDs.

## Canonical query patterns

```sql
-- Count by event name on a single day
SELECT mp_event_name, COUNT(*) AS n
FROM main.mixpanel.silver
WHERE etr_y='2026' AND etr_ymd='2026-05-27'
  AND mp_event_name IS NOT NULL
GROUP BY mp_event_name
ORDER BY n DESC
LIMIT 50;

-- Distinct CIDs doing event X in a week
SELECT mp_event_name, COUNT(DISTINCT cid) AS distinct_cids
FROM main.mixpanel.silver
WHERE etr_y='2026' AND etr_ym='2026-05'
  AND etr_ymd BETWEEN '2026-05-21' AND '2026-05-27'
  AND cid IS NOT NULL
  AND mp_event_name IN ('Login - Success', 'Market - Page View')
GROUP BY mp_event_name;

-- Login analysis via the curated slice (fast)
SELECT EventName, UserCountry, COUNT(*) AS n
FROM main.mixpanel.login_events
WHERE etr_y='2026' AND etr_ymd >= '2026-05-21'
GROUP BY EventName, UserCountry
ORDER BY n DESC;
```

For per-CID aggregates, append `JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap ON event.cid = snap.CID WHERE snap.IsValidCustomer = 1 AND <event-date> BETWEEN snap.FromDateID AND snap.ToDateID` per the [valid-users filter contract](../cross-cutting/valid-users-filter-contract.md).

## Skill provenance

- **Primary sources.** Live UC probes against `main.mixpanel.*` (9 tables) on 2026-05-28: `silver`/`bronze` confirmed 6,225 cols and `mp_event_name` populated on 137.6M of 137.57M rows / day; curated slices (25-38 cols, GCID-keyed, `EventName` PascalCase, dashed etr partitions); pageview marts (13 cols, `Occurred` as bigint epoch ms).
- **Usage data.** `audits/_usage_trigger_xref_20260525T155320Z/`: `main.mixpanel.silver` queried 160ֳ— by 5 users (Class C); phrase `mixpanel` matched in 237 user queries; `mp_event_name` in 195. Genie spaces: ABtoro Genie, Feed Analytics Genie, Customer Segmentation (Mixpanel-leg).
- **Federation.** [`../cross-cutting/valid-users-filter-contract.md`](../cross-cutting/valid-users-filter-contract.md) for per-CID rollup; [`../domain-customer-and-identity/customer-models-and-segmentation.md`](../domain-customer-and-identity/customer-models-and-segmentation.md) for downstream Mixpanel-derived cluster models.
