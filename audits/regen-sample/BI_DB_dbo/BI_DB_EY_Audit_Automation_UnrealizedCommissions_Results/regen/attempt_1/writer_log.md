MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL loaded from bundle: 10 columns, ROUND_ROBIN, HEAP.

Running Phase 2 (sampling) and Phase 3 prep.
**PHASE 2 CHECKPOINT: PASS** — 1,347 rows, date range 2023-07-01 to 2025-04-14, 449 distinct dates, 3 metric pairs per date. IsPriceFound is always NULL.

**PHASE 3 CHECKPOINT: PASS** — No columns match the distribution regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). Zero distribution queries needed. Stored_Proc has 1 distinct value, Metric_a/Metric_b have 3 each (already captured).

Now proceeding through phases 4-10B. The SP code is in the bundle. Let me trace the columns:

From the SP code in the bundle, the INSERT into this table is clear:

```sql
INSERT INTO BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results
SELECT
    CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112) AS [Date]
  , 'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse' AS Stored_Proc
  , ma.Metric_a
  , ma.Metric_a_Value
  , mb.Metric_b
  , mb.Metric_b_Value
  , Metric_a_Value - Metric_b_Value AS [Diff$]
  , ABS((Metric_a_Value - Metric_b_Value)/Metric_b_Value * 100) AS [Diff%]
  , NULL AS IsPriceFound
  , GETDATE() AS UpdateDate
```

All columns are ETL-computed by `SP_EY_Audit_Auditor_Unrealized_Calculations`. The table compares EY audit-computed unrealized metrics (from `#testresults`) against client balance metrics (from `BI_DB_Client_Balance_Aggregate_Level_New`).

Phases 4-10A analysis:
- **P4**: No FK lookups needed — no *ID columns referencing dims
- **P5**: JOINs in the SP between `#testresults` aggregation and `BI_DB_Client_Balance_Aggregate_Level_New`
- **P6**: Business logic is the audit comparison pattern
- **P7**: No views reference this table (small audit results table)
- **P8**: Writer SP is `SP_EY_Audit_Auditor_Unrealized_Calculations`
- **P9**: SP logic fully traced from bundle
- **P9B**: Daily ETL, DELETE+INSERT per date
- **P10**: No Atlassian MCP available
- **P10A**: Upstream is entirely ETL-derived; the companion table `BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation` is documented in the bundle

Now let me check for any views referencing this table.
Good — only the DDL and the writer SP reference this table. No views.

```
PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (no categorical cols match regex)
  [-] P4 Lookup (no FK IDs)  [x] P5 JOIN   [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no Atlassian MCP)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Lineage first.
Now writing the main wiki.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 10    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (no Tier 1 sources exist -- all columns are ETL-computed by the SP)
```
