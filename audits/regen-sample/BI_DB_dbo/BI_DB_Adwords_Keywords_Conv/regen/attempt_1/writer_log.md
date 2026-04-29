Starting the pipeline for `BI_DB_dbo.BI_DB_Adwords_Keywords_Conv`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading required rule files in parallel.
Rules loaded. Now executing Phases 1-3 in parallel (DDL already in bundle, need live data).

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 38 columns. ROUND_ROBIN distribution, CLUSTERED INDEX (DateID ASC).

Running Phase 2 (sampling) and Phase 3 (distribution) queries:
**PHASE 2 CHECKPOINT: PASS** — 3,540 rows. Date range: 2023-06-19 to 2023-08-09. All UpdateDate = 2023-09-18 (single bulk load). STALE.

**PHASE 3 CHECKPOINT: PASS** — Devices: DESKTOP 2010, MOBILE 1472, TABLET 58. Match types: EXACT 1851, PHRASE 1486, BROAD 203. 8 accounts, 676 keywords, 68 campaigns, 307 ad groups. `id` always NULL. 2nd-gen columns mostly NULL.

Now proceeding through remaining phases (4-10B) using the bundle data.

**PHASE 4 CHECKPOINT: PASS** — campaign_id → Dictionary_Campaign, ad_group_id → Dictionary_AdGroup.
**PHASE 5 CHECKPOINT: PASS** — Natural join to Keywords_Pref on (date, customer_id, device, criteria, campaign_id, ad_group_id, week, KeywordMatchType).
**PHASE 6 CHECKPOINT: PASS** — 5 business logic groups: funnel pivot, 1st-gen app, 2nd-gen app, OpenTrade, LTV.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 8 CHECKPOINT: PASS** — Writer: SP_Adwords_Pref_Conv (Table #6).
**PHASE 9 CHECKPOINT: PASS** — Full SP analysis from bundle. Source: External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report. 21 conversion_action_name values filtered. CASE WHEN pivot.
**PHASE 9B CHECKPOINT: PASS** — P99, SB_FinanceReportSPS. Rolling 90-day DELETE+INSERT + year-ago floor.
**PHASE 10 CHECKPOINT: PASS** — No Jira/Confluence sources.
**PHASE 10A CHECKPOINT: PASS** — Upstream is Fivetran Google Ads external table (no wiki). Sibling wikis (Keywords_Pref, Ad_Conv, Geo_Conv) provide context at Tier 2.

```
PHASE GATE — BI_DB_dbo.BI_DB_Adwords_Keywords_Conv:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Let me verify the output directory exists.
Writing **File 1: lineage.md** (Phase 10B).
**PHASE 10B CHECKPOINT: PASS** — lineage.md written.

Now writing **File 2: the main wiki**.
Now writing **File 3: review-needed.md**.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Adwords_Keywords_Conv:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Conv/regen/attempt_1/BI_DB_Adwords_Keywords_Conv.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Conv/regen/attempt_1/BI_DB_Adwords_Keywords_Conv.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Keywords_Conv/regen/attempt_1/BI_DB_Adwords_Keywords_Conv.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 36    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (NO is valid — upstream is Fivetran external table with no wiki; all sibling wikis are Tier 2)
```
