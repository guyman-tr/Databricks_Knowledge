MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing Phase 1 (DDL already in bundle) and Phase 2 (sampling) in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 5 columns (Investor_Type nvarchar(250), EndDateID int, TradingVolume money, TradingValueUSD money, UpdateDate datetime), ROUND_ROBIN HEAP.
**PHASE 2 CHECKPOINT: PASS** — 18 rows, 6 quarterly snapshots (20241231–20260331), 3 investor types per quarter.

**PHASE 3 CHECKPOINT: PASS** — Investor_Type: 3 distinct values (Seychelles=6, EU=6, Other=6). No US or Unclassified rows present despite SP code supporting them.

Now proceeding through phases 4-10B using the bundle and SP code.

- **P4 Lookup**: Investor_Type derived from Dim_Country flags (CountryID=181→Seychelles, CountryID=219→US, EU=1→EU, else→Other). No FK column to resolve.
- **P5 JOIN**: SP joins `#trading_cid` (from Dim_Position aggregation) with `#pop_end` (from Fact_SnapshotCustomer filtered to RegulationID=9).
- **P6 BizLogic**: Aggregation by investor segment. TradingVolume = SUM(open units + close units). TradingValueUSD = SUM(USD-converted open + close values).
- **P7 Views**: No views reference this table.
- **P8 SP-scan**: Writer SP: `SP_Q_AML_FSA_Report`. No other SP reads this table.
- **P9 SP-logic**: Fully traced — all columns sourced from Dim_Position aggregations grouped by investor type flags from Fact_SnapshotCustomer/Dim_Country.
- **P9B ETL**: Quarterly via SP_Q_AML_FSA_Report. DELETE+INSERT per EndDateID.
- **P10 Jira**: Skipped (regen harness).
- **P10A Upstream**: Bundle used — sibling tables documented.
- **P10B Lineage**: Writing now.

```
PHASE GATE — BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Q_AML_FSA_Report_end_InvestorType/regen/attempt_1/BI_DB_Q_AML_FSA_Report_end_InvestorType.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Q_AML_FSA_Report_end_InvestorType/regen/attempt_1/BI_DB_Q_AML_FSA_Report_end_InvestorType.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Q_AML_FSA_Report_end_InvestorType/regen/attempt_1/BI_DB_Q_AML_FSA_Report_end_InvestorType.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (sibling table wikis and SP code used for logic tracing; no Tier 1 applicable — all columns are computed aggregations)
```
