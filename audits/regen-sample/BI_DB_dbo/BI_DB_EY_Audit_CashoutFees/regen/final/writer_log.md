Starting the regen harness for `BI_DB_dbo.BI_DB_EY_Audit_CashoutFees`. MCP pre-flight first.
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing Phase 1 (DDL already in bundle), Phase 2 (sampling), and Phase 3 (distribution) in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle: 12 columns, ROUND_ROBIN distribution, CLUSTERED INDEX (DateID, WithdrawID).
**PHASE 2 CHECKPOINT: PASS** — Sample: 10 rows retrieved. Data spans DateID 20230101 to 20251027 (1,028 distinct dates). Commission mostly 0.0, Category always 'CashOut'.

Now Phase 3 — distribution on categorical columns (capped at 3): Regulation, Country, Category.
**PHASE 3 CHECKPOINT: PASS** — 6.1M rows. Regulation: 11 distinct values (CySEC dominant). Country: 147 distinct. Category: always 'CashOut'.

Now proceeding through remaining phases. The SP code is already in the bundle — I have full traceability.

**PHASE 4 CHECKPOINT: PASS** — All dim lookups resolved via bundle (Dim_Regulation, Dim_PlayerLevel, Dim_Country, Dim_AccountType, Dim_GuruStatus, Dim_Range).

**PHASE 5 CHECKPOINT: PASS** — JOINs analyzed from SP code: Fact_CustomerAction → Fact_SnapshotCustomer (RealCID) → 5 dim tables + Dim_Range for date range resolution.

**PHASE 6 CHECKPOINT: PASS** — Business logic: EY audit report for cashout fees on processed cashouts (ActionTypeID=30), filtered to IsCreditReportValidCB=1 and IsRedeem=0. Commission negated and summed per WithdrawID.

**PHASE 7 CHECKPOINT: [-]** — No views reference this BI_DB table (audit-specific).

**PHASE 8 CHECKPOINT: PASS** — Writer SP: `SP_EY_Audit_CashoutFees` (Author: Guy Manova, 2023-07-26). Includes date gap-fill logic.

**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced. Column mapping complete (see below).

**PHASE 9B CHECKPOINT: PASS** — Daily refresh via SP_EY_Audit_CashoutFees with @date parameter. DELETE+INSERT pattern per DateID. Auto gap-fill for missing dates.

**PHASE 10 CHECKPOINT: [-]** — Atlassian MCP not available this session.

**PHASE 10A CHECKPOINT: PASS** — All 8 upstream wikis in bundle read and traced.

Now writing the three output files. Lineage first.

```
PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_CashoutFees:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

**PHASE 10B** — Writing `.lineage.md` first.
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_CashoutFees:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_CashoutFees/regen/attempt_1/BI_DB_EY_Audit_CashoutFees.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_CashoutFees/regen/attempt_1/BI_DB_EY_Audit_CashoutFees.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_CashoutFees/regen/attempt_1/BI_DB_EY_Audit_CashoutFees.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 7    Tier2: 5    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
