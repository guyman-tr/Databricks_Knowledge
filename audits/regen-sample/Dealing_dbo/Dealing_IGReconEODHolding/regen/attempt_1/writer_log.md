Starting the regen pipeline for `Dealing_dbo.Dealing_IGReconEODHolding`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the rule files in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure (DDL)**

From the bundle DDL: 28 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `[Date] ASC`. All columns nullable.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
Total rows: ~7,955. Date range: 2023-10-27 to 2026-04-24. Active daily refresh confirmed (latest data 2026-04-24, UpdateDate 2026-04-25).

PHASE 2 CHECKPOINT: PASS

**PHASE 3 — Distribution Analysis**
PHASE 3 CHECKPOINT: PASS

Key distributions: 7,955 rows. 8 HedgeServerIDs (997 NULL = IG-only rows). 6 Account_Numbers (2,726 NULL = eToro-only). 8 currencies (USD 56%). Exchange: CFD 51%, Commodity 28%.

**Phases 4-9B — Analysis from SP code in bundle**

From `SP_IGRecon`, the EOD holdings flow:
- **eToro side**: `Dealing_Duco_EODRecon` filtered by @TotalDate, joined with Fivetran IG LP mappings. GBX→GBP normalization applied.
- **IG side**: `LP_IG_PS_EODPositions` with instrument resolution via ISIN or hardcoded #MarketNameToID. Oil ×100 multiplier. Sign convention via (2*IsBuy-1).
- **Final**: FULL OUTER JOIN on InstrumentID + AccountID. Diff columns computed as ISNULL(IG,0)−ISNULL(eToro,0).
- **Weekend logic**: Sunday→Friday-2, Saturday skipped entirely.

All columns traced — every column is ETL-computed (Tier 2) or GETDATE() (Tier 3). No pure passthroughs from a Tier 1 production source exist because the upstream `Dealing_Duco_EODRecon` is itself all Tier 2.

PHASE 4 CHECKPOINT: PASS
PHASE 5 CHECKPOINT: PASS
PHASE 6 CHECKPOINT: PASS
PHASE 7 CHECKPOINT: PASS (no views found referencing this table in bundle)
PHASE 8 CHECKPOINT: PASS
PHASE 9 CHECKPOINT: PASS
PHASE 9B CHECKPOINT: PASS
PHASE 10 CHECKPOINT: PASS (Jira skip — regen harness mode)
PHASE 10A CHECKPOINT: PASS (4 upstream wikis consumed from bundle)
PHASE 10B CHECKPOINT: PASS (lineage ready)

```
PHASE GATE — Dealing_dbo.Dealing_IGReconEODHolding:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```

Now writing the three output files.
Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_IGReconEODHolding:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_IGReconEODHolding/regen/attempt_1/Dealing_IGReconEODHolding.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_IGReconEODHolding/regen/attempt_1/Dealing_IGReconEODHolding.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_IGReconEODHolding/regen/attempt_1/Dealing_IGReconEODHolding.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 27    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES (4 upstream wikis consumed; all columns traced through SP code — no Tier 1 sources exist because upstream Dealing_Duco_EODRecon is itself all Tier 2, and IG LP files have no wiki)
```
