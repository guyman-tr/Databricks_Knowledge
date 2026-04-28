MCP PRE-FLIGHT: PASS

Now let me read the rule files and the previous attempt in parallel.
Now let me read the previous attempt files and the DDL, then do the MCP sampling.
Good. I have the previous attempt and understand all 5 judge issues. Now let me do the required MCP sampling (Phase 2 & 3) and then fix the specific issues.
PHASE 1 CHECKPOINT: PASS (DDL read from bundle)
PHASE 2 CHECKPOINT: PASS (2,999,038 rows, 2021-02-10 to 2024-06-07, TOP 10 sampled)
PHASE 3 CHECKPOINT: PASS (distributions verified — 5 accounts, 4841 symbols, NULL patterns confirmed)

Now I have all the data I need. The previous attempt was largely correct — I only need to fix the 5 specific judge issues. Let me also verify the SP source is referenced in the bundle by quickly scanning it.

The SP logic was already thoroughly analyzed in attempt 1. Let me now proceed to write the three corrected output files. Key fixes:

1. **InstrumentID** — restore "Ranges from 0 (system placeholder) to ~21 million IDs allocated." and remove "Passthrough from Dim_Instrument via Symbol/ISIN/CUSIP matching against Apex staging data."
2. **InstrumentDisplayName** — retag as Tier 1, use Dim_Instrument wiki description verbatim
3. **Lineage file** — mark InstrumentDisplayName as Tier 1
4. **Add Phase Gate Checklist** section
5. **Footer** — 2 T1, 19 T2

PHASE 4 CHECKPOINT: PASS (Dim_Instrument wiki in bundle)
PHASE 5 CHECKPOINT: PASS (JOINs identified in attempt 1 SP analysis)
PHASE 6 CHECKPOINT: PASS (Business logic sections from attempt 1)
PHASE 7 CHECKPOINT: [-] (No views reference this table — Dealing_dbo has no views on this object)
PHASE 8 CHECKPOINT: PASS (SP_Apex_PnL identified as writer SP)
PHASE 9 CHECKPOINT: PASS (SP logic deeply analyzed in attempt 1)
PHASE 9B CHECKPOINT: PASS (Daily DELETE+INSERT, @Date parameter)
PHASE 10 CHECKPOINT: [-] (Jira search skipped in regen harness mode)
PHASE 10A CHECKPOINT: PASS (Dim_Instrument upstream wiki in bundle)

Now writing the three files. Lineage first.
PHASE 10B CHECKPOINT: PASS — writing lineage file now.
Now writing the main wiki with all 5 fixes applied:
Now let me verify the Tier 1 descriptions against the upstream wiki verbatim:

**T1 COPY VERIFICATION:**
- **InstrumentID**: upstream = "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." → wiki = identical (no stats stripped, no injected passthrough text) — **IDENTICAL**
- **InstrumentDisplayName**: upstream = "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." → wiki = identical — **IDENTICAL**

```
OUTPUT CHECK — Dealing_dbo.Dealing_Apex_PnL:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_2/Dealing_Apex_PnL.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_2/Dealing_Apex_PnL.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_2/Dealing_Apex_PnL.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 19    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (DWH_dbo.Dim_Instrument wiki — InstrumentID and InstrumentDisplayName)
```
