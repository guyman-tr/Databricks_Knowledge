MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Starting pipeline execution.

**PHASE 1 CHECKPOINT: PASS** — DDL parsed from bundle:
- 7 columns, all nullable
- Distribution: ROUND_ROBIN
- Index: CLUSTERED INDEX (DateID ASC, InstrumentID ASC)
- Source: `EXW_Currency.vInstrumentRatesForWeek` via `SP_ETL_InstrumentRates_ByHour`

Now running Phase 2 (sampling) and looking up the source view definition in parallel.
**PHASE 2 CHECKPOINT: PASS** — 6,679,831 rows, DateID range 20180423–20260425, ~193 distinct instruments (recent), active table with daily refresh.

**PHASE 3 CHECKPOINT: PASS** — No columns match the categorical regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). Zero distribution queries needed.

Now running Phases 4–10 in parallel where possible. The SP logic is already in the bundle. Let me check for views referencing this table and any Jira context.
Now I have all the information needed. Let me consolidate the phase results:

**PHASE 4 CHECKPOINT: PASS** — InstrumentID maps to instruments in `EXW_Currency.vInstrumentRatesForWeek`; no Dim lookup tables involved.

**PHASE 5 CHECKPOINT: PASS** — No JOINs in the writer SP (single source: `EXW_Currency.vInstrumentRatesForWeek`).

**PHASE 6 CHECKPOINT: PASS** — Business logic: hourly aggregation of instrument ask/bid rates with date boundary handling for previous-day and current-day windows.

**PHASE 7 CHECKPOINT: PASS** — No views reference this table. Downstream consumer: `EXW_Wallet.SP_Prices` reads this table to feed `EXW_Wallet.EXW_Price` and `EXW_Wallet.EXW_PriceDaily`.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: `EXW_Wallet.SP_ETL_InstrumentRates_ByHour`. Reader SP: `EXW_Wallet.SP_Prices`. No other references.

**PHASE 9 CHECKPOINT: PASS** — SP logic fully analyzed from bundle. All columns traced to `EXW_Currency.vInstrumentRatesForWeek` with transforms (AVG, CASE, GETDATE).

**PHASE 9B CHECKPOINT: PASS** — SP accepts `@date DATE` parameter, processes two windows (previous day + current day). DELETE-then-INSERT pattern for `DateID >= @prevdateid`. Not orchestrated by any parent SP in this schema.

**PHASE 10 CHECKPOINT: [-]** — Skipping Jira/Confluence search (regen harness, low-value for ETL staging table).

**PHASE 10A CHECKPOINT: PASS** — `_no_upstream_found.txt` present. No upstream wiki available. All columns grounded in DDL + SP code.

Now writing the three output files.

**PHASE 10B CHECKPOINT: PASS** — Writing lineage file first.

```
PHASE GATE — EXW_Wallet.ETL_InstrumentRates_ByHour:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
```
OUTPUT CHECK — EXW_Wallet.ETL_InstrumentRates_ByHour:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/ETL_InstrumentRates_ByHour/regen/attempt_1/ETL_InstrumentRates_ByHour.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/ETL_InstrumentRates_ByHour/regen/attempt_1/ETL_InstrumentRates_ByHour.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/ETL_InstrumentRates_ByHour/regen/attempt_1/ETL_InstrumentRates_ByHour.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 7    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
