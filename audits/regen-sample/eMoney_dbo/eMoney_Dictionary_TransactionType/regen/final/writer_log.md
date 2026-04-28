MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL/bundle in parallel.
Rules loaded. Now executing pipeline phases. This is a simple 3-column dictionary table — qualifies for the **Simple Dictionary Fast-Path** (P1→P2→P8→P4→P10A→P10B→P11).

**Phase 1 — Structure (from DDL)**:
- 3 columns: `TransactionTypeID` (int NULL), `TransactionType` (varchar(50) NULL), `UpdateDate` (datetime NULL)
- Distribution: REPLICATE, HEAP
- Upstream: `FiatDwhDB.Dictionary.TransactionTypes` (Id → TransactionTypeID, Name → TransactionType)

PHASE 1 CHECKPOINT: PASS

Running Phase 2 (sampling), Phase 3 (distribution), and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS — 15 rows sampled (complete dictionary), values 0=Unknown through 14=CryptoToFiat, all UpdateDate = 2023-06-12.

PHASE 3 CHECKPOINT: PASS — 15 distinct values, 1 row each. Tiny replicated lookup.

PHASE 8 CHECKPOINT: PASS — No SPs in eMoney_dbo reference this table. Only DDL + 2 migration scripts found.

Let me check the migration scripts and generic pipeline mapping for ETL source info.
Now let me check for Jira/Confluence references and find any existing eMoney wiki context.
Good — the existing wiki is a strong reference. Now let me verify the SP business logic references and check for the ETL migration path, then write the three output files.
Good — the SP_eMoney_Calculated_Balance groupings are verified from actual SP code. Now let me also check how FMI/FMO references these types.
Now I have comprehensive evidence. Let me check the output directory exists and write all three files.
Now completing the remaining phase gates and writing all three files.

**Phase 4 — Lookup**: This IS the dictionary table itself. No FK lookups needed.
PHASE 4 CHECKPOINT: PASS

**Phase 9 — SP Logic**: No SPs write to this table. It's loaded via Generic Pipeline (Bronze export → external table). 9 SPs read `TxTypeID` (the FK column in other tables referencing this dictionary).
PHASE 9 CHECKPOINT: PASS (no writer SP — Generic Pipeline load)

**Phase 9B — ETL**: Generic Pipeline Override, daily (1440 min), from prod-banking-fiat server.
PHASE 9B CHECKPOINT: PASS

**Phase 10 — Jira**: [-] Skipped (simple dictionary fast-path)

**Phase 10A — Upstream**: FiatDwhDB.Dictionary.TransactionTypes wiki found and read from bundle. Id→TransactionTypeID (rename, widen), Name→TransactionType (rename, narrow).
PHASE 10A CHECKPOINT: PASS

Now writing the three output files in order.

**Phase 10B — Lineage file (written FIRST):**
PHASE 10B CHECKPOINT: PASS

Now the phase gate and main wiki:

```
PHASE GATE — eMoney_dbo.eMoney_Dictionary_TransactionType [SIMPLE-DICT]:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (trivial — 15-row dict, full enum in P2)
  [x] P4 Lookup       [-] P5 JOIN (no JOINs — this is the lookup target)
  [-] P6 BizLogic (simple dict)  [-] P7 Views (no views reference this directly)
  [x] P8 SP-scan      [x] P9 SP-logic      [-] P9B ETL (Generic Pipeline, no SP orchestration)
  [-] P10 Jira (simple dict)     [x] P10A Upstream     [x] P10B Lineage
  → Ready for P11
```

**Phase 11 — Generate Documentation:**
Now the review-needed sidecar:
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_dbo.eMoney_Dictionary_TransactionType:
  [x] .lineage.md    written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_TransactionType/regen/attempt_1/eMoney_Dictionary_TransactionType.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_TransactionType/regen/attempt_1/eMoney_Dictionary_TransactionType.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_TransactionType/regen/attempt_1/eMoney_Dictionary_TransactionType.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 1    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
