MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Starting with Phase 1 (DDL already in bundle), Phase 2 (sampling), and Phase 8 (SP scan) in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL parsed from bundle: 8 columns, HASH(@Id), CLUSTERED INDEX on @Id.
**PHASE 2 CHECKPOINT: PASS** — 1.52B rows, date range 2023-12-20 to 2026-04-26. Sample retrieved.

Now Phase 3 (distribution). No columns match the categorical regex `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`. Checking NULL/empty rates on the etr_ columns.
**PHASE 3 CHECKPOINT: PASS** — No categorical columns match the distribution regex. etr_ fields are mostly empty. @Id == parent FK in all sampled data.
**PHASE 4 CHECKPOINT: PASS** — No FK lookups needed; raw landing table with only IDs and metadata columns.

**PHASE 5 CHECKPOINT: PASS** — SP_eMoney_Reconciliation_ETLs LEFT JOINs this table on @Id to AccountsSnapshots_AccountSnapshot-956050. Only aar.[@Id] is selected.

**PHASE 6 CHECKPOINT: PASS** — Bridge/link table connecting account snapshots to bank accounts. etr_ columns are ETL date partition fields (mostly empty). No complex business logic.

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — Referenced by SP_eMoney_Reconciliation_ETLs (reader) and NewSBUpdateStatsBigTables (stats maintenance).

**PHASE 9 CHECKPOINT: PASS** — SP reads only aar.[@Id] from this table via LEFT JOIN. Table is a raw Tribe data landing zone, not a write target of the SP.

**PHASE 9B CHECKPOINT: PASS** — Loaded by Tribe platform API data pipeline (external to Synapse SPs). SP_eMoney_Reconciliation_ETLs is the downstream consumer.

**PHASE 10 CHECKPOINT: PASS** — Skipping Jira search for raw Tribe landing table with no-upstream marker.

**PHASE 10A CHECKPOINT: PASS** — _no_upstream_found.txt marker present. No upstream wiki resolvable. Dormant/raw landing table.

Now writing the three output files. Starting with the lineage file.
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.

Now writing the main wiki and review-needed files.
PHASE GATE — eMoney_Tribe.AccountsSnapshots_BankAccounts-795870:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (raw Tribe landing, no-upstream marker)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```

```
OUTPUT CHECK — eMoney_Tribe.AccountsSnapshots_BankAccounts-795870:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccounts-795870/regen/attempt_1/AccountsSnapshots_BankAccounts-795870.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccounts-795870/regen/attempt_1/AccountsSnapshots_BankAccounts-795870.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccounts-795870/regen/attempt_1/AccountsSnapshots_BankAccounts-795870.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 8    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
