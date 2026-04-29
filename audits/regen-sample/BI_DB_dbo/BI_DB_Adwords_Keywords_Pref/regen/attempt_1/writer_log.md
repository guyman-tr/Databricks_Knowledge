Starting MCP pre-flight check.
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Starting with Phase 1 (DDL already in bundle) and Phase 2 (live sampling).

**PHASE 1 — Structure Analysis**

From the DDL in the bundle:
- 24 columns
- Distribution: ROUND_ROBIN
- Index: CLUSTERED INDEX (DateID ASC)
- Source: SP_Adwords_Pref_Conv (Table #3)
- Fivetran source: `External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report`
- `id` column is commented out in SP INSERT → always NULL

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 and Phase 3 queries in parallel.
PHASE 2 CHECKPOINT: PASS
- 223,519 rows
- Date range: 2023-06-19 to 2023-09-17
- UpdateDate: all 2023-09-18 (single bulk load, STALE)
- 9 Google Ads accounts, 3 devices, 3 match types, USD only
- `id` column: all NULL (223,519 nulls = 100%)

PHASE 3 CHECKPOINT: PASS
- Devices: DESKTOP=124,751, MOBILE=92,744, TABLET=6,024
- Match types: EXACT=103,476, PHRASE=100,698, BROAD=19,345
- Status: ENABLED=223,474, PAUSED=45
- Quality scores: 0=71,969, 5=36,898, 3=34,307, 7=18,851, 1=18,670
- 38,209 rows with clicks/cost; 1,690 rows with conversions

PHASE 4 CHECKPOINT: PASS — campaign_id → Dictionary_Campaign, ad_group_id → Dictionary_AdGroup (same pattern as sibling tables)

PHASE 5 CHECKPOINT: PASS — Keywords_Pref pairs with Keywords_Conv on (date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType)

PHASE 6 CHECKPOINT: PASS — Performance metrics (impressions, clicks, cost, video_views, interactions, Conversions), search share metrics (search_impression_share, search_budget_lost_top_impression_share, search_rank_lost_impression_share), keyword metadata (criteria, quality_score, status, KeywordMatchType)

PHASE 7 CHECKPOINT: [-] No views reference this table in SSDT

PHASE 8 CHECKPOINT: PASS — Writer SP: SP_Adwords_Pref_Conv (Table #3)

PHASE 9 CHECKPOINT: PASS — All column mappings traced from SP code (see bundle)

PHASE 9B CHECKPOINT: PASS — P99 priority, SB_FinanceReportSPS schedule, rolling 90-day DELETE+INSERT + year-ago floor

PHASE 10 CHECKPOINT: [-] No Jira/Confluence sources found for this specific table

PHASE 10A CHECKPOINT: PASS — Production source: Fivetran Google Ads connector → keywords performance report. Sibling wikis in bundle confirm same SP cluster pattern.

Now writing the three output files. Starting with lineage.
PHASE 10B — Writing lineage file first.
PHASE 10B CHECKPOINT: PASS

Now writing the main wiki.
Now writing the review-needed sidecar.
PHASE GATE — BI_DB_dbo.BI_DB_Adwords_Keywords_Pref:
```
PHASE GATE — BI_DB_dbo.BI_DB_Adwords_Keywords_Pref:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no sources found)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Adwords_Keywords_Pref:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Pref/regen/attempt_1/BI_DB_Adwords_Keywords_Pref.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Pref/regen/attempt_1/BI_DB_Adwords_Keywords_Pref.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Pref/regen/attempt_1/BI_DB_Adwords_Keywords_Pref.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 22    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (NO is valid — production source is Fivetran external table with no wiki; sibling Adwords tables are peers, not upstreams)
```
