MCP PRE-FLIGHT: PASS

Now loading rules and reading the DDL + bundle.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL)

Table: `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static`
- 10 columns, all NOT NULL
- Distribution: ROUND_ROBIN
- Index: HEAP
- Columns: Currency (varchar50), CurrencyISO (int), InstrumentID (int), InstrumentName (varchar50), DWHInstrumentID (int), BuyCurrencyID (int), SellCurrencyID (int), BuyCurrency (varchar50), SellCurrency (varchar50), UpdateDate (datetime)

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 (distribution), and Phase 8 (SP scan) in parallel.
Phase 2 sample retrieved. Row count DMV failed on permissions — let me get count directly (small static table) and run distribution analysis.
PHASE 2 CHECKPOINT: PASS (145 rows, 21 currencies, 90 instruments, all UpdateDate = 2022-11-21)

Now let me check for views referencing this table.
Now I have all phase data. Let me print the phase gates and write the output files.

PHASE 3 CHECKPOINT: PASS (21 currencies, USD=~40 rows dominant; 90 instruments; all UpdateDate identical)
PHASE 4 CHECKPOINT: PASS (table IS a lookup — no FK resolution needed)
PHASE 5 CHECKPOINT: PASS (joined by 4 SPs on CurrencyISO + SellCurrencyID=1 or BuyCurrencyID=1)
PHASE 6 CHECKPOINT: PASS (currency-to-FX-instrument mapping for USD conversion)
PHASE 7 CHECKPOINT: PASS (no views reference this table)
PHASE 8 CHECKPOINT: PASS (4 reader SPs, 0 writer SPs — static table)
PHASE 9 CHECKPOINT: PASS (no writer SP — static/manual load)
PHASE 9B CHECKPOINT: PASS (no ETL orchestration — static table)
PHASE 10 CHECKPOINT: [-] (skipped — regen harness, soft gate)
PHASE 10A CHECKPOINT: PASS (_no_upstream_found.txt confirmed — dormant/static)
PHASE 10B CHECKPOINT: writing lineage now

```
PHASE GATE — eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Directory exists. Now writing the three output files in order.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static:
  [x] .lineage.md    written → audits/regen-sample/eMoney_dbo/eMoney_Currency_Instrument_Mapping_Static/regen/attempt_1/eMoney_Currency_Instrument_Mapping_Static.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_dbo/eMoney_Currency_Instrument_Mapping_Static/regen/attempt_1/eMoney_Currency_Instrument_Mapping_Static.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_dbo/eMoney_Currency_Instrument_Mapping_Static/regen/attempt_1/eMoney_Currency_Instrument_Mapping_Static.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 10    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
