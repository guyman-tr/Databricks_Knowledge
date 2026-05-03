MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL parsed from bundle. 14 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on (DateFrom ASC, CryptoID ASC). All columns nullable.

Now running Phase 2 (sampling) and row count.
**PHASE 2 CHECKPOINT: PASS** — ~9.95M rows, date range 2018-04-23 to 2026-04-25, 172 distinct cryptos, 12 blockchain types, ~4128 rows/day (172 instruments × 24 hours). Active table, daily refresh.

Now Phase 3 (Distribution). Checking categorical columns against the regex `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class` — no columns match. Running distribution on BlockchainCryptoName as it's the closest to a categorical column (12 distinct values).
**PHASE 3 CHECKPOINT: PASS** — 12 blockchain types (ETH dominates at 93.6%), eToroInstrumentID NULL for ~65% of rows (instruments without eToro mapping). No price NULLs in recent data.

Proceeding through remaining phases:

**PHASE 4 CHECKPOINT: PASS** — No Dim/Dictionary FK lookups; all references are to EXW_Wallet internal tables.

**PHASE 5 CHECKPOINT: PASS** — SP_Prices joins: EXW_Currency.Instruments → Currencies → CryptoMarketRatesMappings → CryptoTypes, then ETL_InstrumentRates_ByHour for rate data.

**PHASE 6 CHECKPOINT: PASS** — Key business logic: (1) InstrumentID remapping (>=100000 → eToroInstrumentID, else CryptoId), (2) hourly price gap-filling via OUTER APPLY + prior-day backfill, (3) AvgPrice = (Bid+Ask)/2.

**PHASE 7 CHECKPOINT: PASS** — No views referencing this table found in bundle.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: EXW_Wallet.SP_Prices. Delete+insert pattern per date.

**PHASE 9 CHECKPOINT: PASS** — Full column-level tracing completed from SP source.

**PHASE 9B CHECKPOINT: PASS** — Daily refresh via SP_Prices(@dt). Delete rows for @dt, insert from ETL_InstrumentRates_ByHour with gap-filling.

**PHASE 10 CHECKPOINT: [-]** — Skipped in regen-harness mode.

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` present. No upstream wiki resolvable.

Now writing the three output files.

```
PHASE GATE — EXW_Wallet.EXW_Price:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

**PHASE 10B** — Writing lineage file first.
Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.EXW_Price:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/EXW_Price/regen/attempt_1/EXW_Price.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/EXW_Price/regen/attempt_1/EXW_Price.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/EXW_Price/regen/attempt_1/EXW_Price.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 14    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
