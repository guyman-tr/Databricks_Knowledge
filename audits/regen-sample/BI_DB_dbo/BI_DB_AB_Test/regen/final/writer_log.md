MCP PRE-FLIGHT: PASS

Now loading the required rules.
Rules loaded. Now executing pipeline phases. Starting with parallel Phase 1 (DDL already in bundle), Phase 2 (sampling), Phase 3 (distribution), and Phase 8 (SP scan).

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 8 columns, HASH(RealCID), CLUSTERED INDEX(DateID, Name).
**PHASE 2 CHECKPOINT: PASS** — 314,240 rows, 2 tests, date range 2020-06-10 to 2023-04-29, 312,861 distinct CIDs.
**PHASE 3 CHECKPOINT: PASS** — All columns non-NULL. 2 distinct tests, 2 BI_Owners (Tom only), 2 Business_Owners, IsControl: 0=205,346 / 1=108,894.

Now checking for views referencing this table and looking for any SP references.
No SPs, no views reference this table. It's dormant/manually loaded. Let me check for existing wikis that can provide context for RealCID and do a quick Atlassian search.
**PHASE 4 CHECKPOINT: PASS** — No dim/dict FKs to resolve (flat structure).
**PHASE 5 CHECKPOINT: PASS** — No SPs/views JOIN to this table.
**PHASE 6 CHECKPOINT: PASS** — AB test group assignment table, 2 tests, control/treatment split.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 8 CHECKPOINT: PASS** — No writer/reader SPs found (dormant, manually loaded).
**PHASE 9 CHECKPOINT: [-]** — No SP code exists for this table.
**PHASE 9B CHECKPOINT: [-]** — No ETL orchestration (manually loaded).
**PHASE 10 CHECKPOINT: PASS** — Jira DS-1703 found (table creation ticket).
**PHASE 10A CHECKPOINT: [-]** — `_no_upstream_found.txt` confirmed; no upstream wiki.
**PHASE 10B CHECKPOINT: PASS** — Writing lineage now.

RealCID inherits from local Synapse wiki `Dim_Customer.md`: "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)"

```
PHASE GATE — BI_DB_dbo.BI_DB_AB_Test:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [-] P4 Lookup        [-] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [-] P8 SP-scan       [-] P9 SP-logic
  [-] P9B ETL          [x] P10 Jira         [-] P10A Upstream
  [x] P10B Lineage     → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_AB_Test:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_AB_Test/regen/attempt_1/BI_DB_AB_Test.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_AB_Test/regen/attempt_1/BI_DB_AB_Test.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_AB_Test/regen/attempt_1/BI_DB_AB_Test.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 0    Tier3: 7    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists; RealCID inherited from local Synapse wiki Dim_Customer.md)
```
