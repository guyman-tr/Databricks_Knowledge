MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `eMoney_Tribe.AccountsActivities_862157`.

**PHASE 1 CHECKPOINT: PASS** — DDL analyzed from bundle. 9 columns, HASH(@Id), HEAP, 3 NCIs.

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 29,752,610 rows, date range 2021-09-05 to 2026-04-26. Source: Treezor XML extract. Writer SP: `SP_eMoney_Reconciliation_ETLs`.

Phase 3: Checking for categorical columns matching the distribution regex. None of the 9 columns (`@Created`, `@Id`, `@FileName`, `etr_y`, `etr_ym`, `etr_ymd`, `SynapseUpdateDate`, `partition_date`, `Created`) match `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`. Running NULL rate check only.
**PHASE 3 CHECKPOINT: PASS** — No categorical columns match distribution regex. NULL analysis: `etr_y/ym/ymd` ~99.8% NULL, `Created` ~41.6% NULL, all others fully populated.

**PHASE 4 CHECKPOINT: PASS** — No *ID columns referencing dims/dicts.

**PHASE 5 CHECKPOINT: PASS** — SP joins `AccountsActivities_862157` (alias `aa`) on `[@Id]` to child tables: `AccountsActivities_AccountActivity-833937`, `AccountsActivities_RiskActions-322546`, `AccountsActivities_SecurityChecks-471048`.

**PHASE 6 CHECKPOINT: PASS** — Raw Treezor XML envelope table. No business logic in this table itself; logic lives in the child tables and SP.

**PHASE 7 CHECKPOINT: PASS** — No views reference this table (grep confirmed only SP reference).

**PHASE 8 CHECKPOINT: PASS** — Single writer/reader SP: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs`. Also has a `_tmp` variant in `eMoney_Tribe_tmp`.

**PHASE 9 CHECKPOINT: PASS** — SP reads `@Created` (for incremental WHERE filter) and `@Id` (for JOIN key). No columns from this table are selected into the output — it is purely a container/envelope joined to child tables. Output goes to `ETL_AccountsActivities`.

**PHASE 9B CHECKPOINT: PASS** — Incremental load pattern: `MAX(Created)` from target, delete-reload from that date. SP authored by eMoney & Wallet Data Analytics Team (Ofir Ovadia, 2022-11-16).

**PHASE 10 CHECKPOINT: PASS** — SP header references Freshservice change #20353. No Jira/Confluence search needed for raw tribe table.

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` present. No upstream wiki resolvable. Production source: Treezor API XML exports.

Now writing the three output files.

```
PHASE GATE — eMoney_Tribe.AccountsActivities_862157:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.AccountsActivities_862157:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsActivities_862157/regen/attempt_1/AccountsActivities_862157.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsActivities_862157/regen/attempt_1/AccountsActivities_862157.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsActivities_862157/regen/attempt_1/AccountsActivities_862157.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
