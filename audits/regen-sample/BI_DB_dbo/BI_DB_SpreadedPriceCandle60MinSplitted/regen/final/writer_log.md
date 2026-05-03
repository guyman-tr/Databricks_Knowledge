MCP PRE-FLIGHT: PASS

Now loading the required rule files and the DDL.
Rules loaded. Now proceeding with the pipeline phases.

**PHASE 1 — Structure Analysis** (from bundle DDL)

Table: `BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted`
- 21 columns
- Distribution: ROUND_ROBIN
- Clustered Index: DateFrom ASC, DateTo ASC, ProviderID ASC, InstrumentID ASC
- NCI: IX_BI_DB_SpreadedPriceCandle60MinSplitted on (InstrumentID ASC, DateFrom ASC)
- Column groups: Provider/Instrument IDs, Date range, Ask OHLC prices + timestamps, Bid OHLC prices + timestamps, UpdateDate

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep (row count), and Phase 8 (SP scan) in parallel.
Row count DMV failed on permissions. Let me get count and date range, and read the referencing SPs.
PHASE 2 CHECKPOINT: PASS — 48.8M rows, 2 providers, 8,445 instruments, date range 2015-01-01 to 2024-06-02

Now let me check the Dealing SPs that reference this table and run Phase 3 distribution analysis.
PHASE 3 CHECKPOINT: PASS — ProviderID: 0=4,349 rows, 1=48,799,502 rows. No other categorical columns match the distribution regex.

Now let me check how SP_Max_NOP references this table and look for any writer SP.
No writer SP found. Table is loaded externally. Let me read SP_Max_NOP's usage context and the JUNK migration script for more clues.
Now let me check for views and Jira references in parallel.
PHASE 4 CHECKPOINT: PASS — ProviderID and InstrumentID are FK-like columns; no Dim wikis directly applicable for Tier 1 inheritance.

PHASE 5 CHECKPOINT: [-] No writer SP exists; JOINs only in reader SPs.

PHASE 6 CHECKPOINT: PASS — OHLC candle data pattern identified: Ask/Bid × First/Last/Min/Max prices with occurrence timestamps, 60-minute intervals.

PHASE 7 CHECKPOINT: PASS — No views reference this table.

PHASE 8 CHECKPOINT: PASS — 4 reader SPs found (SP_DailyNOP_ByInstrument, SP_M_EOMExposures, SP_NOP_LPandClients, SP_Max_NOP), 0 writer SPs.

PHASE 9 CHECKPOINT: [-] No writer SP exists in Synapse. Table loaded externally from production Candle Builder service.

PHASE 9B CHECKPOINT: [-] No ETL orchestration — externally loaded via migration schema.

PHASE 10 CHECKPOINT: PASS — Confluence Candle Builder docs found; production source is Price:12 (Candles DB) on AO-CANDLES-LSN.

PHASE 10A CHECKPOINT: PASS — _no_upstream_found.txt present; no upstream wiki resolvable.

PHASE 10B — Writing lineage file now, then the wiki and review-needed files.

```
PHASE GATE — BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [-] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic
  [-] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK --- BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted:
  [x] .lineage.md    written -> audits/regen-sample/BI_DB_dbo/BI_DB_SpreadedPriceCandle60MinSplitted/regen/attempt_1/BI_DB_SpreadedPriceCandle60MinSplitted.lineage.md
  [x] .md            written -> audits/regen-sample/BI_DB_dbo/BI_DB_SpreadedPriceCandle60MinSplitted/regen/attempt_1/BI_DB_SpreadedPriceCandle60MinSplitted.md
  [x] .review-needed.md written -> audits/regen-sample/BI_DB_dbo/BI_DB_SpreadedPriceCandle60MinSplitted/regen/attempt_1/BI_DB_SpreadedPriceCandle60MinSplitted.review-needed.md
  [-] .alter.sql     deferred (regen harness --- judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 21    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
