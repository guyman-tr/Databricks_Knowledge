

**MCP PRE-FLIGHT — Testing Synapse connectivity**
MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now starting the pipeline phases. Let me run Phase 1 (DDL analysis from the bundle) and Phase 2 (live sampling) simultaneously.

**PHASE 1 — Structure Analysis**

From the DDL in the bundle:
- **8 columns**: Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, UpdateDate, Dividends
- **Distribution**: ROUND_ROBIN
- **Clustered Index**: Date ASC
- All columns nullable

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
PHASE 2 CHECKPOINT: PASS — 2,491 rows, date range 2022-07-06 to 2024-06-07, 6 distinct accounts. **Stale since 2024-06-08**.

**PHASE 3 — Distribution Analysis**
PHASE 3 CHECKPOINT: PASS — 6 accounts, most with ~427 rows each. Transfers NULL 61%, Dividends NULL 52%, Equity_Start NULL 7.6%, Equity_End NULL 3%.

**PHASE 4 — Lookup Resolution**: No FK/lookup columns in this table. All columns are financial values or identifiers.
PHASE 4 CHECKPOINT: PASS (no lookups needed)

**PHASE 5 — JOIN Analysis**: The SP code shows this table is populated from FULL OUTER JOINs of `#Equity_Daily`, `#Transfers_Daily`, and `#Dividends_PerAcc_Daily` — all keyed on `AccountNumber`.
PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**: PnL formula is `Equity_End - Equity_Start - Transfers`. Dividends are aggregated separately. Daily grain uses previous business day (skipping weekends) for Equity_Start.
PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependency Scan**
PHASE 7 CHECKPOINT: PASS — No views reference this table. Only the DDL and writer SP.

**PHASE 8 — SP Scan**: Writer SP is `SP_Apex_PnL` (confirmed in bundle and grep above). No other SPs reference this table.
PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic Extraction**

From the SP code in the bundle, the EE_Daily INSERT block:

```sql
DELETE FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily WHERE Date = @Date
INSERT INTO Dealing_dbo.Dealing_Apex_PnL_EE_Daily
(Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, UpdateDate, Dividends)

SELECT @Date
    ,ISNULL(ISNULL(e.AccountNumber,t.AccountNumber),d.AccountNumber)
    ,e.Equity_Start
    ,e.Equity_End
    ,t.Transfers
    ,ISNULL(e.Equity_End,0) - ISNULL(e.Equity_Start,0) - ISNULL(t.Transfers,0) AS PnL
    ,GETDATE() AS UpdateDate
    ,d.Dividends
FROM #Equity_Daily e
FULL OUTER JOIN #Transfers_Daily t ON t.AccountNumber = e.AccountNumber
FULL OUTER JOIN #Dividends_PerAcc_Daily d ON e.AccountNumber = d.AccountNumber
```

Source temp tables:
- `#Equity_Daily` ← `#EquityStart_ApexFiles_Daily` (LP_APEX_EXT981_3EU @ @PreviousDayID) FULL JOIN `#EquityEnd_ApexFiles` (LP_APEX_EXT981_3EU @ @DateID)
- `#Transfers_Daily` ← LP_APEX_EXT869_3EU @ @DateID, TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL'), SUM(-Amount)
- `#Dividends_PerAcc_Daily` ← aggregated from `#Dividends_ApexFiles_Daily` ← LP_APEX_EXT869_3EU @ @DateID, TerminalID = '$+DIV', SUM(-Amount)
- `@PreviousDay`: skips weekends (Monday uses Friday)

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**: SP_Apex_PnL loads all four Apex tables in one run. DELETE+INSERT pattern by @Date. Part of daily Dealing batch.
PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**: Upstream wikis report no Atlassian sources for the Apex PnL family.
PHASE 10 CHECKPOINT: PASS (no Atlassian sources found)

**PHASE 10A — Upstream Wiki**: The bundle provides wikis for `Dealing_Apex_PnL_EE` (WTD equity sibling), `Dealing_Apex_PnL`, `Dealing_Apex_PnL_Daily`, `Dealing_DailyZeroPnL_Stocks`, and `Dim_Instrument`. This table is a sibling loaded by the same SP — all columns are SP-computed (Tier 2), not passthroughs from another documented table.
PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**: Writing lineage file first.

Now let me verify the output directory exists and write the three files.
Good, the directory exists. Now printing the phase gate and writing the three output files.

```
PHASE GATE — Dealing_dbo.Dealing_Apex_PnL_EE_Daily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Printing final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_Apex_PnL_EE_Daily:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE_Daily/regen/attempt_1/Dealing_Apex_PnL_EE_Daily.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE_Daily/regen/attempt_1/Dealing_Apex_PnL_EE_Daily.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE_Daily/regen/attempt_1/Dealing_Apex_PnL_EE_Daily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 8    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (sibling wikis consulted for context and relationship documentation; no Tier 1 inheritance possible — all columns are SP-computed from LP external staging with no documented upstream wikis)
```
