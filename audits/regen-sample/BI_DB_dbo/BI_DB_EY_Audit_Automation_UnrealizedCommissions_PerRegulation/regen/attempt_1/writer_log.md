MCP PRE-FLIGHT: Testing Synapse connectivity...
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now I'll begin the pipeline phases. Let me start with Phase 1 (DDL already in the bundle) and Phase 2 (live sampling) in parallel.

**PHASE 1 — Structure Analysis**

From the DDL in the bundle:
- **Table**: `BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation`
- **Distribution**: ROUND_ROBIN
- **Index**: CLUSTERED INDEX (DateID ASC)
- **9 columns**: DateID (int), Date (date), Regulation (varchar(50)), InstrumentID (int), InstrumentType (varchar(50)), UnrealizedCommissionChange (decimal(16,6)), UnrealizedFullCommissionChange (decimal(16,6)), UnrealizedPnLChange (decimal(16,6)), UpdateDate (datetime NOT NULL)

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 and Phase 3 queries.
PHASE 2 CHECKPOINT: PASS — Sample data retrieved, date range 2024-07-13 to 2025-04-14.

Now running Phase 3 (distribution) and an approximate row count.
PHASE 3 CHECKPOINT: PASS — Regulation (12 values), InstrumentType (6 values) distributions captured.

Now I have all the data I need. Let me proceed through the remaining phases using the bundle context, then write the output files.

**Phase 4 — Lookup Resolution**: InstrumentID → Dim_Instrument, Regulation → Dim_Regulation (wiki in bundle). DateID is YYYYMMDD int key.

**Phase 5 — JOIN Analysis**: From SP code, the table is populated via `#byRegulation` temp table which JOINs `Fact_SnapshotCustomer` (on CID/RealCID), `Dim_Range` (on DateRangeID with date range filter), and `Dim_Regulation` (on RegulationID/DWHRegulationID).

**Phase 6 — Business Logic**: This table stores daily per-regulation, per-instrument unrealized commission and PnL changes for EY audit automation. The SP computes position-level unrealized changes (end date minus start date) then aggregates by regulation using customer snapshot data.

**Phase 7 — Views**: No views reference this table based on the bundle.

**Phase 8 — SP Scan**: Writer SP is `SP_EY_Audit_Auditor_Unrealized_Calculations` (full code in bundle).

**Phase 9 — SP Logic**: From the SP code, the INSERT into this table selects from `#byRegulation` which aggregates `#regPrep` (itself aggregated from `#testresults`) JOINed with `Fact_SnapshotCustomer` + `Dim_Range` + `Dim_Regulation`. The three metric columns are `SUM` aggregations. `Regulation` comes from `Dim_Regulation.Name`. `InstrumentID` and `InstrumentType` pass through from `#testresults` which inherits from `BI_DB_EY_Audit_Opened_Positions`.

**Phase 9B — ETL**: Runs daily via `SP_EY_Audit_Auditor_Unrealized_Calculations @date`. DELETE+INSERT pattern per DateID.

**Phase 10 — Jira**: Skipped (no Atlassian MCP available in this context).

**Phase 10A — Upstream Wiki**: Bundle provides Dim_Position, Dim_Regulation, Fact_SnapshotCustomer, Dim_Range, BI_DB_Client_Balance_Aggregate_Level_New wikis.

**Phase 10B — Lineage**: Ready to write.

```
PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no MCP) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation/regen/attempt_1/BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 7    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
