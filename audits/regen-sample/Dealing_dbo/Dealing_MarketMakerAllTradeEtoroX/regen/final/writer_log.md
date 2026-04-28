MCP PRE-FLIGHT: PASS

Now loading the required rules files.
Rules loaded. The bundle confirms: no DDL in SSDT, no upstream wiki, `_no_upstream_found.txt` present — this is a dormant/dropped object. Let me check if it exists in live Synapse.

**Phase 1 — Structure Analysis**
Table doesn't exist in live Synapse. There's a `HOLD_` prefixed version in SSDT and an SP that references it. Let me read those.
Key findings:
- Table was **removed** on 2024-03-04 (SR-239249 by Gili) — the entire EtoroX INSERT block in `SP_MarketMakerAllTrade` is commented out
- Only `HOLD_Dealing_MarketMakerAllTradeEtoroX` exists in SSDT (archive copy)
- Table does NOT exist in live Synapse
- 20 columns from the HOLD DDL
- Source was `CopyFromLake.MarketMaker_ExchangesData_Trades` via joins to staging instrument/exchange tables

Let me check if the HOLD table exists in Synapse for sampling.
The HOLD table exists. Let me sample it and get structure info.

PHASE 1 CHECKPOINT: PASS — Structure from HOLD DDL (20 columns, ROUND_ROBIN, CLUSTERED INDEX on Date)

**Phase 2 — Live Data Sampling**
Got sample data. Let me get row count via a different approach and do distribution analysis.
PHASE 2 CHECKPOINT: PASS — ~5M rows, date range 2022-05-01 to 2024-02-20, HOLD table sampled

**Phase 3 — Distribution Analysis**
PHASE 3 CHECKPOINT: PASS — Distribution captured for Name (2 values), Side (2), PartyName (6), FeeCurrency (74, mostly blank), Instrument_Name (many crypto pairs)

**Phase 4 — Lookup Resolution**

No foreign keys or lookup/dim references in this table. All columns are flat data.

PHASE 4 CHECKPOINT: PASS — No lookups to resolve

**Phase 5 — JOIN Analysis**

The SP shows JOINs to:
- `Dealing_staging.External_MarketMaker_dbo_Instruments` (on InstrumentId → yields Instrument_Name)
- `Dealing_staging.External_MarketMaker_dbo_Exchanges` (on ExchangeId → yields Name)

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic Discovery**

From the SP code:
- Side: CASE WHEN Side=1 THEN 'Sell', Side=0 THEN 'Buy'
- Price/Quantity: uses raw values from exchange, -1 sentinel means no data
- Unit: Sign-adjusted quantity based on Side (negative for Sell, positive for Buy)
- Value: Complex formula involving Unit × Price minus Fee, with FeeCurrency-based branching
- Fee: -1 sentinel → '0'
- ApiPrice/APiQuantity/ApiFunds: Compare API vs executed — show '0' if equal, else show the executed values
- DIFF column (in main table, not in EtoroX): Marks discrepancies between API and executed
- The EtoroX variant is simpler — no DIFF, no Dealer column

PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency Scan**
PHASE 7 CHECKPOINT: PASS — No views reference this table

**Phase 8 — SP Scan**

Already found: `SP_MarketMakerAllTrade` — the only SP that references this table. The EtoroX section is fully commented out since 2024-03-04.

PHASE 8 CHECKPOINT: PASS — 1 SP found (writer, now disabled)

**Phase 9 — SP Logic Extraction**

From the commented-out SP code (lines 148-233), the EtoroX data flow was:

1. Source: `CopyFromLake.MarketMaker_ExchangesData_Trades` (ht) — crypto exchange trades from eToroX
2. JOIN `Dealing_staging.External_MarketMaker_dbo_Instruments` (mi) ON InstrumentId → `mi.Name AS Instrument_Name`
3. JOIN `Dealing_staging.External_MarketMaker_dbo_Exchanges` (me) ON ExchangeId → `me.Name`
4. Side: CASE 1→'Sell', 0→'Buy'
5. Price: CASE -1→'0' ELSE raw
6. Quantity: CASE -1→'0' ELSE raw
7. Funds: Price × Quantity
8. ApiPrice: passthrough from source
9. ApiQuantity: passthrough from source
10. ApiFunds: ApiPrice × ApiQuantity
11. Fee: CASE -1→'0' ELSE raw
12. Unit: Side-adjusted quantity (Sell → negative, Buy → positive)
13. Value: Complex: Unit×(-1)×Price - Fee, with FeeCurrency branching
14. UpdateDate: GETDATE()

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL Orchestration**

The SP was called daily with `@Date` parameter. Load pattern: DELETE date + INSERT (daily snapshot replacement). Disabled since 2024-03-04.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian Knowledge Scan**
No direct Atlassian references to this specific table. The results are general Market Maker docs.

PHASE 10 CHECKPOINT: PASS — No table-specific Jira/Confluence found

**Phase 10A — Upstream Wiki**

No upstream wiki available (confirmed by `_no_upstream_found.txt`). Source was `CopyFromLake.MarketMaker_ExchangesData_Trades` which is a lake-copy staging table with no wiki.

PHASE 10A CHECKPOINT: PASS — No upstream wiki (dormant object, source is staging lake copy)

**Phase 10B — Column Lineage (write .lineage.md FIRST)**

Now let me check the generic pipeline mapping for UC target info, then write the three output files.
No UC target. Now let me read the golden reference once more quickly to confirm the lineage format, then write all three files.
Now let me print the phase gate and write all three files.

```
PHASE GATE — Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

PHASE 10B CHECKPOINT: PASS

Now writing all three files.
Now writing the main wiki.
All three files written. Final output:

```
OUTPUT CHECK — Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_MarketMakerAllTradeEtoroX/regen/attempt_1/Dealing_MarketMakerAllTradeEtoroX.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_MarketMakerAllTradeEtoroX/regen/attempt_1/Dealing_MarketMakerAllTradeEtoroX.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_MarketMakerAllTradeEtoroX/regen/attempt_1/Dealing_MarketMakerAllTradeEtoroX.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 9    Tier3: 12    Tier4: 0
  Bundle inheritance used: NO  (YES — _no_upstream_found.txt exists, no upstream wiki resolvable)
```
