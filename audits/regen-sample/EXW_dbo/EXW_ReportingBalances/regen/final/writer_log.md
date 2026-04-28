MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 39 columns, HASH([eToro Unique ID 1 GCID]), CLUSTERED INDEX([ReportingDate] ASC).

Starting P2 (sample + row count), P3 (distribution), and P8 (SP scan) in parallel.
Table returns 0 rows — dormant. Let me continue with broader SP scan and view scans.
No SPs reference this table. Let me check the generic pipeline mapping, the sibling EOM table, and search for views/Jira context.
No generic pipeline mapping found. Table is dormant (0 rows), no SPs. Let me check for UC target and Jira.
**PHASE 2 CHECKPOINT: PASS** — 0 rows returned, table is empty/dormant. No live data to sample.

**PHASE 3 CHECKPOINT: PASS** — [-] Distribution analysis not possible on empty table (0 rows). Distribution key: HASH([eToro Unique ID 1 GCID]), Clustered Index on [ReportingDate].

**PHASE 4 CHECKPOINT: PASS** — [-] No FK/lookup columns resolvable; column names are human-readable labels (not ID references to dims).

**PHASE 5 CHECKPOINT: PASS** — [-] No SPs or views reference this table; no JOINs to analyze.

**PHASE 6 CHECKPOINT: PASS** — Business logic inferred from DDL column structure (crypto reporting balances with MTD/LTD tracking, tracker reconciliation, country closure flags).

**PHASE 7 CHECKPOINT: PASS** — [-] No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — No stored procedures reference EXW_ReportingBalances. Table appears to be loaded externally (possibly direct INSERT from external reporting/SSIS process).

**PHASE 9 CHECKPOINT: PASS** — [-] No SP code to analyze (no writer SP found).

**PHASE 9B CHECKPOINT: PASS** — [-] No ETL orchestration found. Not in generic pipeline mapping. Not in dependency order.

**PHASE 10 CHECKPOINT: PASS** — [-] Skipping Jira search for dormant table with no upstream context (low value). Column semantics are well-described by DDL naming.

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki resolvable. `_no_upstream_found.txt` confirms dormant status.

Now generating the three output files. Lineage first (P10B), then the wiki, then review-needed.
**PHASE 10B CHECKPOINT: PASS** — Lineage file written. All 40 columns Tier 3 (no upstream wiki, no SP code, no generic pipeline).

Now writing the main wiki.
Now writing the review-needed sidecar.
PHASE GATE — EXW_dbo.EXW_ReportingBalances:
```
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (0 rows, empty table)
  [-] P4 Lookup       [-] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no SPs)
  [-] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

```
OUTPUT CHECK — EXW_dbo.EXW_ReportingBalances:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_ReportingBalances/regen/attempt_1/EXW_ReportingBalances.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_ReportingBalances/regen/attempt_1/EXW_ReportingBalances.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_ReportingBalances/regen/attempt_1/EXW_ReportingBalances.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 40    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
