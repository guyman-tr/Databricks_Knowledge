MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now executing the pipeline phases. Starting with P1 (DDL already read), P2 (live sampling), and P8 (SP scan) in parallel.

**PHASE 1 CHECKPOINT: PASS** — 19 columns, REPLICATE distribution, HEAP, 4 NCI indexes.
**PHASE 2 CHECKPOINT: PASS** — 3,763,876 rows, date range 2023-12-20 to 2026-04-26, sampled 10 rows.

Now running Phase 3 (distribution) and Phase 7 (view scan) in parallel.
**PHASE 3 CHECKPOINT: PASS** — 0 columns match the categorical regex. Security check columns are boolean flags (0/1). Ran 1 validation query confirming the pattern.

**PHASE 4 CHECKPOINT: PASS** — No *ID FK columns referencing dim/dictionary tables.

**PHASE 5 CHECKPOINT: PASS** — LEFT JOINed to `Authorizes_Authorize-312243` on `@Id` in `SP_eMoney_Reconciliation_ETLs`.

**PHASE 6 CHECKPOINT: PASS** — Boolean security check flags for card authorization events. Column groups: security checks (CardExpirationDatePresent through Signature), ETL metadata (etr_y/ym/ymd, SynapseUpdateDate, Created, partition_date), identifiers (@Id, @Authorizes_Authorize@Id).

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: `SP_eMoney_Reconciliation_ETLs` (reads this table, writes to `ETL_Authorize`).

**PHASE 9 CHECKPOINT: PASS** — SP reads security check columns as passthrough (no transforms). Table is a Tribe XML-shredded child table joined to parent `Authorizes_Authorize-312243` on `@Id`.

**PHASE 9B CHECKPOINT: PASS** — Incremental load pattern based on `MAX(Created)` watermark.

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness mode).

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` confirms no resolvable upstream wiki. Table is a Generic Pipeline / Tribe XML-shredded raw table.

Now let me check the generic pipeline mapping for this table to understand the ETL source chain.
Good. Now I have the full ETL chain. Let me emit the phase gate and write the three output files.

**PHASE 10B** — Writing lineage file first.

```
PHASE GATE — eMoney_Tribe.Authorizes_SecurityChecks-30662:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
**PHASE 10B CHECKPOINT: PASS** — `.lineage.md` written.

Now writing the main wiki and review-needed files.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.Authorizes_SecurityChecks-30662:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/Authorizes_SecurityChecks-30662/regen/attempt_1/Authorizes_SecurityChecks-30662.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/Authorizes_SecurityChecks-30662/regen/attempt_1/Authorizes_SecurityChecks-30662.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/Authorizes_SecurityChecks-30662/regen/attempt_1/Authorizes_SecurityChecks-30662.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 19    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
