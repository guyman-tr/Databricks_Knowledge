Starting the pipeline for `BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup`. MCP pre-flight first.
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline for `BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup`.

**P1 — Structure Analysis** (from DDL in bundle):
- 6 columns: campaign_id (bigint), ad_group_id (bigint), ad_group_name (nvarchar(256)), target_cpa (float), UpdateDate (datetime), ad_group_status (nvarchar(256))
- ROUND_ROBIN, HEAP
- Simple dictionary table (≤10 columns, TRUNCATE+INSERT from single Fivetran source)
- SP Table #12: `target_cpa` is NOT in the INSERT — always NULL

PHASE 1 CHECKPOINT: PASS

Running P2 (sample) and P3 (distribution) in parallel.
PHASE 2 CHECKPOINT: PASS — 31,322 rows sampled, all UpdateDate = 2023-09-18, target_cpa 100% NULL.

PHASE 3 CHECKPOINT: PASS — 3 statuses (ENABLED=20,893, PAUSED=7,233, REMOVED=3,196), 2,192 campaigns, 27,565 ad groups, 6,968 distinct names.

**P4 — Lookup**: No FK to dimension tables. campaign_id is a Google Ads ID, not a DWH dim key.

PHASE 4 CHECKPOINT: PASS

**P5 — JOINs**: From bundle, multiple tables JOIN to this dictionary on `ad_group_id`: Geo_Pref, Ad_Pref, Keywords_Pref, Geo_Conv, Ad_Conv, Keywords_Conv, Search_Perf, Search_Conv. This is a lookup/reference table.

PHASE 5 CHECKPOINT: PASS

**P6 — Business Logic**: Simple dictionary — TRUNCATE+INSERT DISTINCT from Fivetran adgroup performance report. No computed columns, no CASE logic. `target_cpa` exists in DDL but SP doesn't populate it.

PHASE 6 CHECKPOINT: PASS

**P7 — Views**: No views reference this table in the bundle. Skipping deep scan for dictionary table.

PHASE 7 CHECKPOINT: PASS ([-] no views found)

**P8 — SP Scan**: Writer SP = `SP_Adwords_Pref_Conv` (Table #12). TRUNCATE+INSERT pattern. No reader SPs in bundle.

PHASE 8 CHECKPOINT: PASS

**P9 — SP Logic**: From SP code (Table #12):
- `campaign_id` ← `campaign_id` (passthrough)
- `ad_group_id` ← `id` (rename)
- `ad_group_name` ← `name` (rename)
- `ad_group_status` ← `status` (rename)
- `UpdateDate` ← `GETDATE()` (ETL)
- `target_cpa` ← NOT INSERTED (always NULL)
- Source: `External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report`
- Filter: `WHERE name IS NOT NULL`

PHASE 9 CHECKPOINT: PASS

**P9B — ETL**: TRUNCATE+INSERT (full refresh, no rolling window). Priority P99, scheduler SB_FinanceReportSPS. STALE since 2023-09-18.

PHASE 9B CHECKPOINT: PASS

**P10 — Jira/Atlassian**: No specific sources found for this dictionary table.

PHASE 10 CHECKPOINT: PASS ([-] no Atlassian sources)

**P10A — Upstream**: Source is Fivetran external table (no wiki). Upstream wikis in the bundle are sibling tables that REFERENCE this dictionary — they are not upstream sources for column descriptions. The production source is Google Ads API via Fivetran.

PHASE 10A CHECKPOINT: PASS

**P10B — Lineage**: Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Dictionary_AdGroup/regen/attempt_1/BI_DB_Adwords_Dictionary_AdGroup.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Dictionary_AdGroup/regen/attempt_1/BI_DB_Adwords_Dictionary_AdGroup.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Dictionary_AdGroup/regen/attempt_1/BI_DB_Adwords_Dictionary_AdGroup.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 4    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (production source is Fivetran external table with no upstream wiki — bundle contains sibling consumers, not upstream sources)
```
