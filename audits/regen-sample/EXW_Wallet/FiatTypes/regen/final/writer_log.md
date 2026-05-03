MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline for `EXW_Wallet.FiatTypes`.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

Columns: 12 — `Id`, `FiatId`, `FiatName`, `IsActive`, `AvatarUrl`, `Precision`, `InstrumentId`, `NumericCode`, `etr_y`, `etr_ym`, `etr_ymd`, `SynapseUpdateDate`
Distribution: ROUND_ROBIN, HEAP. All columns nullable.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
Good — only 4 rows (USD, EUR, GBP, AUD). Small reference table. Let me read the referencing SP and check for distribution columns.

PHASE 2 CHECKPOINT: PASS (4 rows sampled, small lookup table with 4 fiat currencies)
PHASE 3 CHECKPOINT: PASS (IsActive: 4/4 True — single-value distribution, no other categorical columns match the regex pattern)

Now let me check for views, generic pipeline mapping, and complete the remaining phases.
Good. Now I have all the context needed. Let me complete the remaining phase gates.

PHASE 4 CHECKPOINT: PASS (InstrumentId → trading instrument FK; NumericCode → ISO 4217; FiatId → internal currency ID)
PHASE 5 CHECKPOINT: PASS (JOINed via `c.FiatID = ft.FiatId` in SP_EXW_C2F_E2E providing FiatName as FiatCurrency)
PHASE 6 CHECKPOINT: PASS (Simple 4-row dictionary: USD, EUR, GBP, AUD)
PHASE 7 CHECKPOINT: PASS (No views reference this table)
PHASE 8 CHECKPOINT: PASS (1 reader SP: SP_EXW_C2F_E2E; no writer SP — loaded via generic pipeline)
PHASE 9 CHECKPOINT: PASS (No writer SP — direct Override copy from WalletDB.Wallet.FiatTypes via generic pipeline)
PHASE 9B CHECKPOINT: PASS (Daily refresh, Override strategy, 1440 min frequency)
PHASE 10 CHECKPOINT: [-] (Small reference table, low Jira value — soft skip)
PHASE 10A CHECKPOINT: PASS (Generic pipeline: WalletDB.Wallet.FiatTypes → Bronze lake → EXW_Wallet.FiatTypes; no upstream wiki — _no_upstream_found.txt confirmed)
PHASE 10B CHECKPOINT: Writing lineage file now.

```
PHASE GATE — EXW_Wallet.FiatTypes:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (small ref table)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — EXW_Wallet.FiatTypes:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/FiatTypes/regen/attempt_1/FiatTypes.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/FiatTypes/regen/attempt_1/FiatTypes.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/FiatTypes/regen/attempt_1/FiatTypes.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 4    Tier3: 8    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
