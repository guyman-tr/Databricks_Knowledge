---
name: domain-product-analytics
description: "Social feed engagement ג€” eToro's server-side stream of post / comment / emotion / followdiscussion / save / spam events at main.experience.bronze_event_hub_prod_event_streaming_we_streams_* ג€” fed by event-hub from the feed micro-service, with deeply nested struct payloads carrying the FULL post entity (Owner, Message, Tags, Attachments, Mentions, IsSpam, EditStatus) plus a Trade/Order/Copy/Poll/MarketEvent/Share sub-struct under EventPayloadRowData_Entity_Metadata depending on post type. Critical inventory: out of the 9 sibling streams_* tables, only SIX are alive ג€” streams_post (etr_ymd-partitioned dashed format, 4,345 rows on 2026-05-27), streams_comment (etr_ymd, 2,600 rows / day), streams_emotion (etr_ymd, 5,324 rows / day), streams_followdiscussion (etr_ymd, alive), streams_save (NO etr_ymd partition ג€” 372k total rows lifetime, alive 2026-05-28), streams_spam (NO etr_ymd partition ג€” 244k total rows lifetime, alive); the remaining THREE (streams_reaction, streams_follow, streams_pin) are EMPTY OR STALE (streams_reaction and streams_follow have zero rows; streams_pin last-written 2023-10-22). Two-key identity scheme on every event: EventPayloadRowData_Requester (the actor ג€” reactor / commenter / saver) and EventPayloadRowData_Entity_Owner (the entity owner ג€” post author for a reaction, followed-user for a follow); both carry Id (STRING, GCID-like, may need CAST(... AS BIGINT) to join Mixpanel/customer GCID DOUBLE) + Username + Avatar + Roles array + IsBlocked + CountryCode (numeric) + PiLevel. EventPayloadRowData_Entity_Type discriminates the post type and tells you which sub-struct inside EventPayloadRowData_Entity_Metadata is non-null (Trade / Order / Copy / Poll / MarketEvent / Share ג€” exactly one populated per row). Mixpanel-side CLIENT-feed events are captured separately in main.mixpanel.feed_events (34 cols, GCID-keyed, EventName PascalCase, dashed etr partition, ExperimentName + ExperimentVariant integrated for A/B context, ItemType / ItemID / ItemLocation / TimeOnPost / ParentItemID / SharedPostID / PostID / FeedOwner / FeedOwnerType / FeedType / Source columns ג€” use this for 'how long did users spend on a post', 'click-through from feed item', 'per-FeedType engagement breakdown'). Feed-ranking simulation outputs (NOT actual events) live at main.product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_{market_top_feed_user_weights, news_feed_user_weights, post_read_rank_weights} ג€” those are MODEL simulations of alternative ranking weights against historical data, do not mistake them for 'users actually saw this feed'. Legacy: main.experience.bronze_streams_streams (older Streams DB bronze, mostly superseded). Impression events: main.experience.bronze_event_hub_prod_event_streaming_we_impression_events_impressionevent. Social-graph state: main.experience.bronze_event_hub_prod_event_streaming_we_social_relations_follow (follow relationships)."
triggers:
  - feed
  - social feed
  - feed analytics
  - feed events
  - streams_post
  - streams_comment
  - streams_emotion
  - streams_reaction
  - streams_follow
  - streams_followdiscussion
  - streams_save
  - streams_pin
  - streams_spam
  - bronze_event_hub_prod_event_streaming_we_streams_post
  - bronze_event_hub_prod_event_streaming_we_streams_comment
  - bronze_event_hub_prod_event_streaming_we_streams_emotion
  - bronze_event_hub_prod_event_streaming_we_streams_followdiscussion
  - bronze_event_hub_prod_event_streaming_we_streams_save
  - bronze_event_hub_prod_event_streaming_we_streams_spam
  - bronze_event_hub_prod_event_streaming_we_impression_events_impressionevent
  - bronze_event_hub_prod_event_streaming_we_social_relations_follow
  - bronze_streams_streams
  - mixpanel.feed_events
  - feed_events
  - EventPayloadRowData
  - EventPayloadRowData_Entity
  - EventPayloadRowData_Entity_Id
  - EventPayloadRowData_Entity_Owner
  - EventPayloadRowData_Entity_Message
  - EventPayloadRowData_Entity_Metadata
  - EventPayloadRowData_Entity_Metadata_Trade
  - EventPayloadRowData_Entity_Metadata_Order
  - EventPayloadRowData_Entity_Metadata_Copy
  - EventPayloadRowData_Entity_Metadata_MarketEvent
  - EventPayloadRowData_Entity_Metadata_Poll
  - EventPayloadRowData_Entity_Metadata_Share
  - EventPayloadRowData_Entity_Type
  - EventPayloadRowData_Entity_IsSpam
  - EventPayloadRowData_Entity_EditStatus
  - EventPayloadRowData_Requester
  - EventPayloadRowData_Requester_Id
  - EventPayloadRowData_Requester_Username
  - EventPayloadRowData_Requester_PiLevel
  - EventPayloadRowData_Requester_CountryCode
  - Requester vs Entity_Owner
  - Entity_Owner
  - feed_ranking_formulas_simulations
  - feed_ranking_formulas_simulations_market_top_feed_user_weights
  - feed_ranking_formulas_simulations_news_feed_user_weights
  - feed_ranking_formulas_simulations_post_read_rank_weights
  - feed ranking simulation
  - feed Analytics Genie
  - post engagement
  - feed engagement
  - PiLevel
  - FeedType
  - FeedOwner
  - FeedOwnerType
  - ItemType
  - ItemID
  - PostID
  - TimeOnPost
  - SharedPostID
  - copy trade post
  - market event post
sample_questions:
  - "How many posts were created yesterday?"
  - "Show me the top 10 markets mentioned in feed posts last week"
  - "Which Popular Investors had the highest comment volume?"
  - "What does the difference between Requester and Entity_Owner mean?"
  - "How do I read the Trade struct from a streams_post payload?"
  - "Why does streams_reaction have zero rows?"
  - "Which streams_* tables have an etr_ymd partition and which don't?"
  - "How fresh is streams_pin?"
  - "How does mixpanel.feed_events differ from streams_post?"
  - "How do I compute average TimeOnPost per FeedType?"
  - "Show me the feed-ranking simulation outputs for the news feed"
  - "How do I count distinct posters per CountryCode?"
  - "What's the right table for 'follow' events given streams_follow is empty?"
  - "How do I find posts about a specific InstrumentId?"
  - "Where are spam reports captured?"
required_tables:
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_post
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_comment
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_emotion
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_followdiscussion
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_save
  - main.experience.bronze_event_hub_prod_event_streaming_we_streams_spam
  - main.experience.bronze_event_hub_prod_event_streaming_we_impression_events_impressionevent
  - main.experience.bronze_event_hub_prod_event_streaming_we_social_relations_follow
  - main.experience.bronze_streams_streams
  - main.mixpanel.feed_events
  - main.product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_market_top_feed_user_weights
  - main.product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_news_feed_user_weights
  - main.product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_post_read_rank_weights
domain_tags:
  - feed
  - social
  - engagement
  - streams
  - product-analytics
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Feed & social-feed analytics

eToro's social feed is the differentiator vs. a plain brokerage. Two complementary event streams capture engagement: the SERVER-side event-hub `streams_*` family (a post was created, a comment was made, an emotion was emoted) and the CLIENT-side `mixpanel.feed_events` (a user spent N seconds on a post, clicked through to an instrument). Use both ג€” they answer different questions.

## When to Use

Load for questions about:

- Post / comment / emotion volume and engagement
- Who-posted-about-what (Trade, Order, Copy, MarketEvent struct in payload)
- Popular Investor feed activity
- Spam reports / spam classification (`streams_spam`)
- Save / bookmark events (`streams_save`)
- Followdiscussion events
- Feed impressions (`impression_events_impressionevent`)
- Time-on-post / feed click-through (use `mixpanel.feed_events`)
- Feed-ranking model simulation outputs (NOT actual user engagement)
- Social-graph follow state (`social_relations_follow` for graph state; the server-side `streams_follow` event log is EMPTY ג€” see warnings)

Do NOT load for:

- Mixpanel client-side UI events more broadly ג€” [`mixpanel-events-and-pageviews.md`](mixpanel-events-and-pageviews.md)
- A/B-test variants assigned to feed users ג€” [`ab-testing-and-experimentation.md`](ab-testing-and-experimentation.md), then join via GCID
- The trading positions behind a feed-post `Trade` struct ג€” `domain-trading/position-state-and-grain.md` (`EventPayloadRowData_Entity_Metadata_Trade_PositionId` joins to `Dim_Position` / `Fact_Position`)
- Copy-trading semantics ג€” `domain-trading/copy-trading-and-mirror.md` (`Metadata_Copy_User_Id` is the copied user)
- Market-event semantics (earnings releases, etc.) ג€” `domain-trading/instruments-and-asset-classes.md`

## Scope

In scope: the 9-table `main.experience.bronze_event_hub_prod_event_streaming_we_streams_*` family with their alive/empty/stale status; the nested-struct payload schema (top-level `EventPayloadRowData_Entity_*` and `EventPayloadRowData_Requester_*` plus exploded leaf columns); the post-type discrimination via `EventPayloadRowData_Entity_Type` and which `_Metadata_<X>` sub-struct it implies; the Requester vs Entity_Owner identity dual; the dashed-string-partition convention where present (etr_y / etr_ym / etr_ymd) and the un-partitioned alternative-time strategy using `EventPayloadRowData_Entity_Created` (TIMESTAMP); `main.mixpanel.feed_events` (34 cols, GCID-keyed, client-side feed UI events with ExperimentName/ExperimentVariant integration); the feed-ranking simulation outputs at `product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_*` (3 tables); legacy `experience.bronze_streams_streams`; impression-event hub.

Out of scope: the feed-service codebase; the feed-ranking ML training pipelines (only the simulation OUTPUTS are scoped); the live feed-API endpoints; copy-trading mirroring infrastructure (`domain-trading/copy-trading-and-mirror.md`); the actual trade behind `Metadata_Trade_PositionId` (`domain-trading`).

Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 ג€” Of the 9 sibling `streams_*` tables, only 6 are usable. THREE are dead and you must NOT rely on them.** Verified on 2026-05-28:

   | Table | Status | etr_ymd partition? | Note |
   |---|---|---|---|
   | `streams_post` | **ALIVE** (4,345 rows on 2026-05-27) | yes (dashed) | Primary post-creation event |
   | `streams_comment` | **ALIVE** (2,600 rows / day) | yes (dashed) | Comments on posts |
   | `streams_emotion` | **ALIVE** (5,324 rows / day) | yes (dashed) | Likes / reactions (modern channel ג€” replaces streams_reaction) |
   | `streams_followdiscussion` | **ALIVE** | yes (dashed) | Follow a post-discussion thread |
   | `streams_save` | **ALIVE** (~372k total, fresh) | **NO** | Save / bookmark; use `EventPayloadRowData_Entity_Created` timestamp filter |
   | `streams_spam` | **ALIVE** (~244k total, fresh) | **NO** | Spam reports; use `EventPayloadRowData_Entity_Created` timestamp filter |
   | `streams_reaction` | **EMPTY** (0 rows) | no | Superseded by `streams_emotion`. Do NOT use. |
   | `streams_follow` | **EMPTY** (0 rows) | no | Follow events are NOT here. Use `social_relations_follow` for follow-graph state. |
   | `streams_pin` | **STALE** (last write 2023-10-22) | no | Pin events stopped flowing. Don't use for current data. |

2. **Tier 1 ג€” Partition columns exist on SOME but not all alive streams_* tables.** `streams_post`, `streams_comment`, `streams_emotion`, `streams_followdiscussion` have `etr_y` / `etr_ym` / `etr_ymd` as STRING dashed format (e.g. `etr_ymd='2026-05-27'`). `streams_save` and `streams_spam` have NO etr partitions and you MUST filter on `EventPayloadRowData_Entity_Created` (TIMESTAMP type) using `WHERE EventPayloadRowData_Entity_Created >= TIMESTAMP'2026-05-21'` syntax ג€” string comparison (`>= '2026-05-21'`) silently returns zero rows.

3. **Tier 1 ג€” Identity is split into Requester (the actor) and Entity_Owner (the acted-upon).** On a comment event: Requester is the commenter, Entity_Owner is the post author. On a follow-discussion event: Requester is the follower, Entity_Owner is the post author. On a save: Requester is the saver, Entity_Owner is the post author. On a spam report: Requester is the reporter, Entity_Owner is the post author. **Swapping them inverts the analysis.** Both carry `Id` (STRING, GCID-like), `Username`, `Avatar`, `Roles`, `IsBlocked`, `CountryCode` (numeric), `PiLevel`. For joining to Mixpanel `gcid` (DOUBLE) or customer tables, `CAST(EventPayloadRowData_Requester_Id AS BIGINT)` is the safe pattern.

4. **Tier 1 ג€” `EventPayloadRowData_Entity_Type` discriminates which `_Metadata_<X>` sub-struct is populated.** Exactly ONE of `_Metadata_Trade`, `_Metadata_Order`, `_Metadata_Copy`, `_Metadata_Poll`, `_Metadata_MarketEvent`, `_Metadata_Share` is non-null per row, depending on post type. Examples: a post-about-a-trade populates `_Metadata_Trade.PositionId / Market / Gain / Rate / Direction`; a copy-trading post populates `_Metadata_Copy.User.Id / Username`; a market-event post populates `_Metadata_MarketEvent.EarningReportId / Market / EstimatedEps / EarningsDate`. Always inspect `Entity_Type` before reading a sub-struct, or join its meaning to the relevant per-type filter.

5. **Tier 2 ג€” `mixpanel.feed_events` is CLIENT-side; streams_* are SERVER-side. They answer different questions.** `mixpanel.feed_events` tracks `What did the user see / click / spend time on?` ג€” `ItemType`, `ItemID`, `ItemLocation`, `TimeOnPost`, `FeedType`, `Source`, `ExperimentName`/`ExperimentVariant`. `streams_post`/`streams_comment` track `What did the user create on the server?`. Some questions need both: "did users in experiment variant X create more posts about crypto?" needs `feed_events` (for variant filter) and `streams_post` (for post creation). Join via GCID ג€” `mixpanel.feed_events.GCID` (INT) ג†” `CAST(streams_post.EventPayloadRowData_Requester_Id AS BIGINT)`.

6. **Tier 2 ג€” `feed_ranking_formulas_simulations_*` are MODEL SIMULATIONS, not actual events.** They evaluate alternative ranking-weight schemes against historical data to estimate what users WOULD have engaged with. Three tables: `_market_top_feed_user_weights`, `_news_feed_user_weights`, `_post_read_rank_weights`. Do NOT mistake them for "users actually saw this feed item". For actual feed-engagement use streams_* (server) and mixpanel.feed_events (client).

7. **Tier 2 ג€” `bronze_streams_streams` is legacy.** Pre-event-hub Streams DB bronze. Mostly superseded by the `bronze_event_hub_prod_event_streaming_we_streams_*` family. Use only when investigating pre-2022 feed history.

8. **Tier 2 ג€” `social_relations_follow` is the SOCIAL-GRAPH STATE table, not the follow-EVENT stream.** Since `streams_follow` is empty, this is your only source for follow relationships. It exposes the current follower-followee state (and possibly historical state via etr partitions ג€” verify before use).

9. **Tier 3 ג€” `EventPayloadRowData_Entity_IsDeleted = TRUE` rows are tombstones, not active posts.** Soft-delete pattern. For "active feed content right now" filter `IsDeleted = FALSE` or NULL. For "what was posted then deleted" include them but treat as a separate cohort.

10. **Tier 3 ג€” `EventPayloadRowData_Entity_IsSpam = TRUE` are server-classified spam posts.** Different from the `streams_spam` table (which is user-reported spam). For a clean "real" feed cohort, filter out both `IsSpam = TRUE` posts AND posts that have rows in `streams_spam`.

11. **Tier 3 ג€” `EditStatus` indicates a post was edited.** Use to interpret why `EventPayloadRowData_Entity_Updated` differs from `_Created` ג€” an edit vs. a different downstream change. Treat post text from edited posts as the LATEST `Message_Text` value, not the original.

12. **Tier 3 ג€” `Roles` is an array<int> with values per role (Popular Investor, Verified, etc.).** Exact role-ID enum lives upstream in the user-service dictionary. Use `array_contains(EventPayloadRowData_Requester_Roles, <role_id>)` to filter. Popular-Investor analysis typically lives in `domain-trading/copy-trading-and-mirror.md`.

13. **Tier 3 ג€” `Tags` array carries `Market` references (instrument tags) the post was about.** Use to find "posts tagging EURUSD" without parsing free-form Message text. Mentions array carries `User` references (Popular Investor mentions). Attachments carry images/videos.

## Canonical query patterns

```sql
-- Daily post volume by Requester country (alive table with etr_ymd)
SELECT etr_ymd,
       EventPayloadRowData_Requester_CountryCode AS country_code,
       COUNT(*) AS posts
FROM main.experience.bronze_event_hub_prod_event_streaming_we_streams_post
WHERE etr_y='2026' AND etr_ymd BETWEEN '2026-05-21' AND '2026-05-27'
  AND EventPayloadRowData_Entity_IsDeleted = FALSE
  AND COALESCE(EventPayloadRowData_Entity_IsSpam, FALSE) = FALSE
GROUP BY etr_ymd, EventPayloadRowData_Requester_CountryCode
ORDER BY etr_ymd, posts DESC;

-- Engagement (emotions + comments) per author last 7 days
WITH emotion AS (
  SELECT CAST(EventPayloadRowData_Entity_Owner_Id AS BIGINT) AS author_gcid,
         COUNT(*) AS emotion_count
  FROM main.experience.bronze_event_hub_prod_event_streaming_we_streams_emotion
  WHERE etr_y='2026' AND etr_ymd >= '2026-05-21'
  GROUP BY 1
),
comment AS (
  SELECT CAST(EventPayloadRowData_Entity_Owner_Id AS BIGINT) AS author_gcid,
         COUNT(*) AS comment_count
  FROM main.experience.bronze_event_hub_prod_event_streaming_we_streams_comment
  WHERE etr_y='2026' AND etr_ymd >= '2026-05-21'
  GROUP BY 1
)
SELECT COALESCE(e.author_gcid, c.author_gcid) AS author_gcid,
       COALESCE(e.emotion_count, 0) AS emotions,
       COALESCE(c.comment_count, 0) AS comments
FROM emotion e
FULL OUTER JOIN comment c USING (author_gcid)
ORDER BY emotions + comments DESC
LIMIT 50;

-- Saves last week (table without etr partition ג€” use timestamp filter)
SELECT DATE(EventPayloadRowData_Entity_Created) AS day, COUNT(*) AS saves
FROM main.experience.bronze_event_hub_prod_event_streaming_we_streams_save
WHERE EventPayloadRowData_Entity_Created >= TIMESTAMP'2026-05-21'
  AND EventPayloadRowData_Entity_Created < TIMESTAMP'2026-05-28'
GROUP BY 1 ORDER BY 1;

-- Posts about a specific instrument (via Tags array)
SELECT EventPayloadRowData_Entity_Id, EventPayloadRowData_Requester_Username,
       EventPayloadRowData_Entity_Message_Text
FROM main.experience.bronze_event_hub_prod_event_streaming_we_streams_post
WHERE etr_y='2026' AND etr_ymd >= '2026-05-21'
  AND EXISTS (
    SELECT 1 FROM UNNEST(EventPayloadRowData_Entity_Tags) t
    WHERE t.Market.SymbolName = 'AAPL'
  )
LIMIT 50;

-- Mixpanel client-side feed engagement per FeedType x ExperimentVariant
SELECT FeedType, ExperimentVariant, COUNT(*) AS events,
       AVG(TimeOnPost) AS avg_time_on_post
FROM main.mixpanel.feed_events
WHERE etr_y='2026' AND etr_ymd >= '2026-05-21'
GROUP BY FeedType, ExperimentVariant
ORDER BY events DESC;
```

## Skill provenance

- **Primary sources.** Live UC probes on 2026-05-28: streams_post (4,345 rows / day 2026-05-27, etr_ymd dashed), streams_comment (2,600 / day), streams_emotion (5,324 / day), streams_followdiscussion (alive); streams_reaction and streams_follow confirmed 0 rows; streams_pin last-written 2023-10-22; streams_save and streams_spam fresh (max 2026-05-28) but without etr_ymd partition columns. Schema of `streams_post` confirmed (52 columns: 1 unflattened `EventPayloadRowData` struct + ~40 exploded leaf columns + 3 etr partitions + `event_hub_region`).
- **Usage data.** Feed Analytics Genie space `01f105b421e7187baa5e81595599f7f3` ran 27 queries against `mixpanel.silver` and `experience.bronze_event_hub_prod_event_streaming_we_streams_post`. The cross-references between feed events and trades (via Metadata_Trade_PositionId) drive several Class-D Genie spaces.
- **Federation.** [`mixpanel-events-and-pageviews.md`](mixpanel-events-and-pageviews.md) for client-side `mixpanel.feed_events`; [`ab-testing-and-experimentation.md`](ab-testing-and-experimentation.md) for ExperimentName/Variant context; [`../domain-trading/position-state-and-grain.md`](../domain-trading/position-state-and-grain.md) for the PositionId in Metadata_Trade.
