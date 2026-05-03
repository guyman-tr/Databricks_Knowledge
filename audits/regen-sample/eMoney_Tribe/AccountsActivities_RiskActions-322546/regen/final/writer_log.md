MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL parsed from bundle. 15 columns, HASH distributed on `[@Id]`, HEAP storage, 4 NCIs.

Now running Phase 2 (sampling), row count, and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 29.75M rows, date range 2023-12-20 to 2026-04-26. Risk action flag columns are all "0" in sample. `ChangeAccountStatusToReceiveOnly` and `ChangeAccountStatusToSpendOnly` are empty/NULL in older rows, populated with "0" in newer rows.

Now running Phase 3 (distribution on categorical columns) and checking for views referencing this table.
**PHASE 3 CHECKPOINT: PASS** — Distribution on 3 categorical flag columns: `MarkTransactionAsSuspicious` (0=99.9%, 1=0.1%), `ChangeCardStatusToRisk` (0≈100%, 1=2 rows), `RejectTransaction` (all 0).

**PHASE 4 CHECKPOINT: PASS** — No FK/lookup columns to resolve. All action columns are boolean-like flags (0/1).

**PHASE 5 CHECKPOINT: PASS** — Table is LEFT JOINed to `AccountsActivities_AccountActivity-833937` via `[@Id]` in SP_eMoney_Reconciliation_ETLs. No other JOIN patterns.

**PHASE 6 CHECKPOINT: PASS** — Column groups identified: (1) Identity keys (`@Id`, parent FK), (2) Risk action boolean flags (5 columns), (3) ETL date partitioning (`etr_y/ym/ymd`), (4) Metadata (`SynapseUpdateDate`, `Created`, `partition_date`).

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — Writer: eMoney Tribe generic pipeline (raw data lake ingestion). Reader: `SP_eMoney_Reconciliation_ETLs` (LEFT JOIN, selects 5 risk flag columns into `#AccountsActivities` → `ETL_AccountsActivities`).

**PHASE 9 CHECKPOINT: PASS** — SP selects `MarkTransactionAsSuspicious`, `NotifyCardholderBySendingTAIsNotification`, `ChangeCardStatusToRisk`, `ChangeAccountStatusToSuspended`, `RejectTransaction` as direct passthroughs (no transform). `ChangeAccountStatusToReceiveOnly` and `ChangeAccountStatusToSpendOnly` are NOT referenced by the SP (added later to schema).

**PHASE 9B CHECKPOINT: PASS** — Data ingested via eMoney Tribe generic pipeline (data lake → Synapse raw table). Consumed by `SP_eMoney_Reconciliation_ETLs` which builds `ETL_AccountsActivities`.

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness, low-value for raw tribe table).

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki found (`_no_upstream_found.txt` present). This is a raw eMoney Tribe ingestion table from the eMoney (Modulr) card management platform. No production DB wiki exists.

**PHASE 10B CHECKPOINT: PASS** — Writing lineage file now.

```
PHASE GATE — eMoney_Tribe.AccountsActivities_RiskActions-322546:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — eMoney_Tribe.AccountsActivities_RiskActions-322546:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsActivities_RiskActions-322546/regen/attempt_1/AccountsActivities_RiskActions-322546.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsActivities_RiskActions-322546/regen/attempt_1/AccountsActivities_RiskActions-322546.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsActivities_RiskActions-322546/regen/attempt_1/AccountsActivities_RiskActions-322546.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 15    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
