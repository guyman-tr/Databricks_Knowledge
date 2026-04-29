MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Now let me run the live data queries and check the sister table's UC target pattern in parallel.
PHASE 1 CHECKPOINT: PASS — DDL read from bundle (34 columns, ROUND_ROBIN, CLUSTERED INDEX Date ASC)
PHASE 2 CHECKPOINT: PASS — 6,176,145 rows, date range 2021-01-02 to 2025-06-29, years: 2021=2.51M, 2022=2.88M, 2023=766K, 2025=20K (no 2024 data)
PHASE 3 CHECKPOINT: PASS — Regulation (11 distinct), SettlementType (3: Real/CFD/TRS), Country (83 distinct)
PHASE 4 CHECKPOINT: PASS — Dim_Regulation, Dim_Instrument, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus resolved from bundle
PHASE 5 CHECKPOINT: PASS — JOINs in SP: Dim_Position, BI_DB_PositionPnL, Fact_SnapshotCustomer+Dim_Range, Dim_Instrument, Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus
PHASE 6 CHECKPOINT: PASS — Zero P&L reconciliation logic, tree-size bucketing, CFD/Real/TRS settlement, invalid customer filter
PHASE 7 CHECKPOINT: [-] No views reference this table (regen scope)
PHASE 8 CHECKPOINT: PASS — Writer: SP_DailyZero_TreeSize_NEW_InvalidCustomers
PHASE 9 CHECKPOINT: PASS — Full SP logic traced from bundle
PHASE 9B CHECKPOINT: [-] Not in OpsDB (sister SP_DailyZero_TreeSize_NEW is Priority 99, FinanceReportSPS)
PHASE 10 CHECKPOINT: [-] Atlassian skipped (regen harness)
PHASE 10A CHECKPOINT: PASS — 9 upstream wikis in bundle
PHASE 10B CHECKPOINT: Writing lineage now

PHASE GATE — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [-] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Writing the three output files now.
All three files written. Let me verify the judge's fixes were applied:

**Judge fix verification:**
1. **MifID** -- Re-tagged as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)` with verbatim description including 'DEFAULT 0', 'FK to Dim_MifidCategorization', and SP rename note.
2. **IsValidCustomer** -- Re-tagged as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)` with verbatim FSC description including 'Approx 98% of current rows = 1'. Added table-specific note: 'Always 0 in this table (SP filters WHERE IsValidCustomer=0)'.
3. **IsCreditReportValidCB** -- Re-tagged as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)` with verbatim FSC description.
4. **UC Target** -- Added to property table as `_Not_Migrated` with sister table pattern reference.
5. **Sparse 2025 gotcha** -- Added in Section 3.4 with specific numbers (20K vs 2.5M-2.9M) and the missing 2024 data.

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_2/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_2/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_2/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 9    Tier2: 24    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES
```
