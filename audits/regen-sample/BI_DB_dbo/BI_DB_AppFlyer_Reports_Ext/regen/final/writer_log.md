MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**Phase 1 — Structure Analysis**: DDL already in the bundle. 84 columns, all `varchar(4000)` or `varchar(500)`, ROUND_ROBIN distribution, HEAP (no clustered index). Two columns have dynamic data masking: `IsReceiptValidated` and `City`. Clear raw data landing table from AppsFlyer mobile attribution platform.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sample), Phase 3 prep, and Phase 8 (SP scan) in parallel.
Sample retrieved successfully. Row count DMV failed (permissions) — let me try an alternative count approach, and read the writer SP.
PHASE 2 CHECKPOINT: PASS — 130.3M rows, data from 2020 to 2025, raw AppsFlyer mobile attribution data.

Now Phase 3 — distribution analysis on categorical columns matching the regex. Picking: `Region`, `CountryCode`, `AttributedTouchType` (capped at 3).
PHASE 3 CHECKPOINT: PASS

Now proceeding with remaining phases. Let me check for views referencing this table and look for any other SPs.
Good — the downstream `BI_DB_AppFlyer_Reports` has an existing wiki. No views reference the _Ext table. SP_AppFlyer_Reports is the only consumer (reads FROM _Ext, inserts INTO the non-Ext table).

Completing remaining phase gates:

- **P4 Lookup**: No FK/dim lookups — raw staging table, all varchar. PASS.
- **P5 JOIN**: SP has no JOINs, straight SELECT from _Ext. PASS.
- **P6 BizLogic**: Column groups identified (attribution, multi-touch contributors, geo, device/app, event, cost). PASS.
- **P7 Views**: No views reference this table. PASS.
- **P8 SP-scan**: Only `SP_AppFlyer_Reports` references this table (as reader). No SP writes to _Ext. PASS.
- **P9 SP-logic**: SP reads from _Ext, applies minor transforms (CAST datetime, CASE WHEN 'None'→NULL, UK→GB normalization, boolean text conversions), inserts into `BI_DB_AppFlyer_Reports`. PASS.
- **P9B ETL**: Externally loaded from AppsFlyer data feed, partitioned by DateID. PASS.
- **P10 Jira**: [-] Regen harness — Atlassian scan skipped.
- **P10A Upstream**: `_no_upstream_found.txt` present — no resolvable upstream wiki. PASS.
- **P10B Lineage**: Writing now.

```
PHASE GATE — BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_AppFlyer_Reports_Ext/regen/attempt_1/BI_DB_AppFlyer_Reports_Ext.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_AppFlyer_Reports_Ext/regen/attempt_1/BI_DB_AppFlyer_Reports_Ext.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_AppFlyer_Reports_Ext/regen/attempt_1/BI_DB_AppFlyer_Reports_Ext.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 86    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
