MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL/bundle in parallel.
Rules loaded. DDL has 3 columns: `AccountProgramID`, `AccountProgram`, `UpdateDate`. REPLICATE, HEAP. This qualifies for **Simple Dictionary Fast-Path** (≤10 columns).

**PHASE 1 CHECKPOINT: PASS** — 3 columns from DDL.

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 3 rows: 0=Unknown, 1=card, 2=iban. All updated 2023-06-12.

**PHASE 8 CHECKPOINT: PASS** — Referenced by 2 SPs (readers): `SP_eMoney_Dim_Account`, `SP_eMoney_Account_Mappings`.

Now let me find the writer SP and check if there's a dictionaries SP.
Let me read the migration scripts and external table to trace the ETL chain.
Now let me check the generic pipeline mapping and find how data flows into the target table.
Now I have the full ETL chain. Let me check the UC target for the gold layer.
All research phases complete. Let me verify the output directory exists, then write the three files.
**PHASE 4 CHECKPOINT: PASS** — This IS the lookup table; no outgoing lookup references.

**PHASE 10 CHECKPOINT: PASS** — Jira search skipped (simple dictionary fast-path).

**PHASE 10A CHECKPOINT: PASS** — Upstream wiki found: `FiatDwhDB.Dictionary.AccountPrograms` (prod-banking-fiat). Column mapping: `Id→AccountProgramID`, `Name→AccountProgram`.

**PHASE 10B** — Writing lineage file now.

PHASE GATE CHECK — eMoney_Dictionary_AccountProgram [SIMPLE-DICT]:
```
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist (simple dict, 3 rows)   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
```

Now writing all three output files. Lineage first, then wiki, then review-needed.
T1 COPY VERIFICATION:
```
  AccountProgramID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban." — IDENTICAL + inline values appended (≤15 dict rule)
  AccountProgram: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown, 1=card, 2=iban." — IDENTICAL + inline values appended (≤15 dict rule)
```

```
OUTPUT CHECK — eMoney_dbo.eMoney_Dictionary_AccountProgram:
  [x] .lineage.md    written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_AccountProgram/regen/attempt_1/eMoney_Dictionary_AccountProgram.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_AccountProgram/regen/attempt_1/eMoney_Dictionary_AccountProgram.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_dbo/eMoney_Dictionary_AccountProgram/regen/attempt_1/eMoney_Dictionary_AccountProgram.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 1    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
