MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings`.

**PHASE 1 — Structure Analysis (from DDL in bundle)**

7 columns: `Date` (date), `DateID` (int), `TransactionID` (varchar(20)), `MIDName` (varchar(50)), `MID` (varchar(50)), `ActionType` (varchar(50)), `UpdateDate` (datetime). Distribution: HASH(TransactionID). Clustered index on Date ASC.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
PHASE 2 CHECKPOINT: PASS — 15.8M rows, date range 2024-01-01 to 2025-09-10. Sample shows deposit/withdraw MID routing metadata.

PHASE 3 CHECKPOINT: PASS — ActionType: Deposit ~63%, Withdraw ~37%. MIDName: 10 distinct values (eToroEU, eToroUK, EMUK, eToroAU, eToroME, eToroUS, eToroSEY, NA, eToroSG, blank). MID: eToroMoneyEU, eToroMoneyUK, NuveiEU, PayPalEU, WorldpayEU, etc.

Phases 4-10B — Analyzing SP logic and tracing columns. All 7 columns are ETL-computed (Tier 2) — this table is a pure metadata/lookup built by complex MID resolution logic in `SP_PIPs_Report_MID_Settings`. No direct passthroughs from upstream wikis exist.

```
PHASE GATE — BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [-] P4 Lookup (no FK-ID columns)  [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (metadata table, no view consumers found in bundle)  [x] P8 SP-scan
  [x] P9 SP-logic      [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream    [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PIPs_Report_MID_Settings/regen/attempt_1/BI_DB_PIPs_Report_MID_Settings.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PIPs_Report_MID_Settings/regen/attempt_1/BI_DB_PIPs_Report_MID_Settings.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PIPs_Report_MID_Settings/regen/attempt_1/BI_DB_PIPs_Report_MID_Settings.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 7    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (business context from BI_DB_DepositWithdrawFee, Dim_BillingProtocolMIDSettingsID, Dim_Regulation, Fact_BillingDeposit, Fact_BillingWithdraw, Fact_CustomerAction, Fact_SnapshotCustomer, Dim_Range wikis informed SP logic tracing; no Tier 1 passthroughs exist — all columns are ETL-computed)
```
