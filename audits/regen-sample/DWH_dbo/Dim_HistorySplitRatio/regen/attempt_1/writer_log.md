MCP PRE-FLIGHT: PASS

Now let me read the upstream bundle and the DDL file to start the pipeline phases.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle):
- Table: `DWH_dbo.Dim_HistorySplitRatio`
- 9 columns: ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted, UpdateDate
- Distribution: REPLICATE
- Index: CLUSTERED INDEX on (InstrumentID ASC, MinDate ASC, MaxDate ASC)

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 (distribution), and scanning for views/SPs.
PHASE 2 CHECKPOINT: PASS (16,014 rows, MinDate range 2000-01-01 to 2026-04-24, full truncate/reload pattern — all UpdateDate = 2026-04-27)

PHASE 3 CHECKPOINT: PASS (15,037 distinct instruments, 965 rows with non-unity PriceRatio, ratios range from 0.00004167 to 11,178,000)

Now running Phases 4-10B.
All phase data collected. Let me now complete the remaining phase gates and write the output files.

PHASE 4 CHECKPOINT: PASS (InstrumentID FK to Trade.Instrument — no dim lookups needed in SP)
PHASE 5 CHECKPOINT: PASS (SP has no JOINs — straight SELECT from staging)
PHASE 6 CHECKPOINT: PASS (Split ratio time-series pattern, adjusted vs unadjusted ratios)
PHASE 7 CHECKPOINT: PASS (No views reference this table)
PHASE 8 CHECKPOINT: PASS (One writer SP: SP_Dim_HistorySplitRatio_DL_To_Synapse)
PHASE 9 CHECKPOINT: PASS (All columns passthrough except UpdateDate = GETDATE())
PHASE 9B CHECKPOINT: PASS (Daily truncate/reload, Override copy strategy, 1440 min frequency)
PHASE 10 CHECKPOINT: PASS (Atlassian search skipped in regen harness mode)
PHASE 10A CHECKPOINT: PASS (Upstream wiki: History.SplitRatio from etoro — present in bundle)

Now writing Phase 10B lineage file first, then wiki, then review sidecar.

```
PHASE GATE — DWH_dbo.Dim_HistorySplitRatio:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
PHASE 10B CHECKPOINT: PASS

Now writing the main wiki file.
Now writing the review sidecar.
All three files written. Now running post-write validation.

**T1 COPY VERIFICATION:**
- ID: upstream 16 words → wiki 16 words — IDENTICAL
- InstrumentID: upstream 25 words → wiki 25 words — IDENTICAL
- MinDate: upstream 29 words → wiki 29 words — IDENTICAL
- MaxDate: upstream 30 words → wiki 30 words — IDENTICAL
- PriceRatio: upstream 36 words → wiki 36 words — IDENTICAL
- AmountRatio: upstream 36 words → wiki 36 words — IDENTICAL
- PriceRatioUnAdjusted: upstream 16 words → wiki 16 words + DWH note — IDENTICAL (note appended)
- AmountRatioUnAdjusted: upstream 8 words → wiki 8 words + DWH note — IDENTICAL (note appended)

**Post-write validation checks:**
- Section check: All 8 `## N.` headers present — PASS
- Elements check: `## 4. Elements` contains markdown table — PASS
- Line count: 162 lines (minimum 100 for tables) — PASS
- Tier suffix check: All 9 descriptions end with `(Tier N — source)` — PASS
- Quality score in footer — PASS
- Element count: 9 columns in DDL, 9 rows in Elements — PASS
- `.review-needed.md` does NOT contain `## 4. Elements` — PASS
- `.lineage.md` exists and contains column lineage table — PASS
- COLUMN STATS CHECK: 0 descriptions contain table-level stats — PASS
- UPSTREAM SEARCH LOG CHECK: present — PASS
- Formula vagueness check: 0 matches — PASS

```
OUTPUT CHECK — DWH_dbo.Dim_HistorySplitRatio:
  [x] .lineage.md    written → audits/regen-sample/DWH_dbo/Dim_HistorySplitRatio/regen/attempt_1/Dim_HistorySplitRatio.lineage.md
  [x] .md            written → audits/regen-sample/DWH_dbo/Dim_HistorySplitRatio/regen/attempt_1/Dim_HistorySplitRatio.md
  [x] .review-needed.md written → audits/regen-sample/DWH_dbo/Dim_HistorySplitRatio/regen/attempt_1/Dim_HistorySplitRatio.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 8    Tier2: 1    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
