Starting MCP pre-flight check.
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing Phase 1 (DDL already in bundle) and running Phase 2/3 MCP queries in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 25 columns, HASH(customer_id), CLUSTERED INDEX(month ASC).
**PHASE 2 CHECKPOINT: PASS** — Sample retrieved. Date range: 2023-05-01 to 2023-08-01. All UpdateDate = 2023-09-18 (single bulk load). Now running Phase 3 distribution queries.
**PHASE 3 CHECKPOINT: PASS** — 12,992 rows. Devices: DESKTOP 61%, MOBILE 38%. Match types: EXACT 39%, NEAR_EXACT 27%. Month range: May–Aug 2023 (volume drops sharply after June).

Running P4-P9 checks in parallel.
Phase results compiled:
- **P4**: campaign_id → Dictionary_Campaign, ad_group_id → Dictionary_AdGroup (no Dim lookups in SP for this table)
- **P5**: Joins with Search_Perf on month+customer_id+query+device+match_type
- **P6**: Funnel conversion pivot + app conversion tracking (1st-gen only)
- **P7**: No views reference this table
- **P8**: Only writer SP: SP_Adwords_Pref_Conv (Table #10 of 12)
- **P9**: Full SP logic traced — column-by-column mapping done
- **P9B**: Monthly rolling DELETE+INSERT, 4-month window, part of P99 SB_FinanceReportSPS schedule
- **P10**: No Jira/Confluence sources
- **P10A**: Upstream is Fivetran external table (no wiki). Sibling tables in bundle are co-outputs, not upstreams.

```
PHASE GATE — BI_DB_dbo.BI_DB_Adwords_Search_Conv:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no sources found)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now checking the output directory and writing the three files.
Good, the directory exists. Now writing the three output files in order: lineage first, then wiki, then review-needed.
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Adwords_Search_Conv:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Search_Conv/regen/attempt_1/BI_DB_Adwords_Search_Conv.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Search_Conv/regen/attempt_1/BI_DB_Adwords_Search_Conv.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Adwords_Search_Conv/regen/attempt_1/BI_DB_Adwords_Search_Conv.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 22    Tier3: 0    Tier4: 2
  Bundle inheritance used: NO  (NO is valid — upstream is Fivetran external table with no wiki; sibling tables in bundle are co-outputs, not upstream sources)
```
