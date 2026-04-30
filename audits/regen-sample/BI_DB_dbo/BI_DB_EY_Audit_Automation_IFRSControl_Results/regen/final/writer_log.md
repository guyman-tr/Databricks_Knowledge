MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL.
Rules loaded. Now running Phase 1 (DDL already in bundle) and Phase 2 (live sampling).

**PHASE 1 CHECKPOINT: PASS** — DDL has 10 columns, ROUND_ROBIN distribution, HEAP.

Running Phase 2 queries.
**PHASE 2 CHECKPOINT: PASS** — 1,066 rows, date range 2024-01-24 to 2025-06-30, 2 rows per day (Buy + Sell), daily refresh.

Now Phase 3. Checking column names against the categorical regex `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class` — none of the 10 columns match. The only categorical-ish columns are `Stored_Proc`, `Metric_a`, `Metric_b` but they don't match the regex. Running zero distribution queries is valid per the rules.
**PHASE 3 CHECKPOINT: PASS** — No regex-matching categorical columns. Ran distributions on Stored_Proc (1 value), Metric_a (8 values), Metric_b (8 values) for context. IsPriceFound is always NULL.

Now running through the remaining phases. Phase 4 (Lookup) — no FK/ID columns referencing dims. Phase 5 (JOIN) — SP joins to BI_DB_EY_Audit_Closed_Positions, BI_DB_EY_Audit_Opened_Positions, BI_DB_EY_Audit_ChangeLog, Dim_Instrument, BI_DB_IFRS15_Daily_Balance. Phase 6 (Business Logic) — the SP computes Buy/Sell totals from position-level data and compares against IFRS15_Daily_Balance aggregates. Phase 7 (Views) — let me check if any views reference this table.
Only referenced by its own DDL and the writer SP. No views, no other SPs.

**PHASE 4 CHECKPOINT: PASS** — No FK/ID columns requiring lookup resolution.
**PHASE 5 CHECKPOINT: PASS** — SP joins: BI_DB_EY_Audit_Closed_Positions, BI_DB_EY_Audit_Opened_Positions, BI_DB_EY_Audit_ChangeLog (via temp tables), Dim_Instrument (InstrumentTypeID=10 filter), BI_DB_IFRS15_Daily_Balance (comparison source).
**PHASE 6 CHECKPOINT: PASS** — Two-metric comparison pattern: Buy total vs IFRS Buy, Sell total vs IFRS Sell. Diff and Diff_Percentage computed.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 8 CHECKPOINT: PASS** — Single writer SP: SP_EY_Audit_IFRS_Control. No reader SPs found.
**PHASE 9 CHECKPOINT: PASS** — SP logic fully traced from bundle. All columns are ETL-computed (Tier 2). Date=@date param, Stored_Proc=hardcoded string, Metric_a/b=hardcoded labels, values=SUMs from position data vs IFRS balance, Diff=arithmetic, IsPriceFound=always NULL, UpdateDate=GETDATE().
**PHASE 9B CHECKPOINT: PASS** — Daily execution, DELETE+INSERT pattern keyed on Date.
**PHASE 10 CHECKPOINT: [-]** — Regen harness mode, Atlassian skipped.
**PHASE 10A CHECKPOINT: PASS** — Upstream bundle contains Dim_Instrument and BI_DB_IFRS15_Daily_Balance wikis. However, no columns in this table are passthroughs — all are SP-computed audit metrics.
**PHASE 10B** — Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Now writing the main wiki.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_IFRSControl_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_IFRSControl_Results.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_IFRSControl_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_IFRSControl_Results.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_IFRSControl_Results/regen/attempt_1/BI_DB_EY_Audit_Automation_IFRSControl_Results.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 10    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (no columns are passthroughs — all ETL-computed audit metrics)
```
