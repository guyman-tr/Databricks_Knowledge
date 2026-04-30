MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report`.

**PHASE 1 CHECKPOINT: PASS** — DDL analyzed from bundle. 51 columns, ROUND_ROBIN distribution, HEAP index.

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
**PHASE 2 CHECKPOINT: PASS** — Table is currently empty (0 rows). TRUNCATE+INSERT pattern; SP may not have run recently. Structure confirmed from DDL.

**PHASE 3 CHECKPOINT: PASS** — Cannot run distribution queries on empty table. Marked `[-]` with reason.

Now running remaining phases. Let me check for views referencing this table.
PHASE GATE — BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report:
```
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (table empty, 0 rows)
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none) [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Starting with the lineage file.
Now writing the main wiki.
Now writing the review-needed file.
Now fixing the tier count in the wiki footer (should be 11 T1, not 10 T1).
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_M_Compliance_CDIM_Report/regen/attempt_1/BI_DB_M_Compliance_CDIM_Report.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_M_Compliance_CDIM_Report/regen/attempt_1/BI_DB_M_Compliance_CDIM_Report.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_M_Compliance_CDIM_Report/regen/attempt_1/BI_DB_M_Compliance_CDIM_Report.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 41    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
