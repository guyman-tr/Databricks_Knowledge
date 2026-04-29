MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Let me start with Phase 1 (DDL already in bundle) and Phase 2 (live sampling) simultaneously.

**PHASE 1 — Structure Analysis (from bundle DDL)**

| # | Column | Type | Nullable |
|---|--------|------|----------|
| 1 | Date | date | YES |
| 2 | AccountNumber | varchar(20) | YES |
| 3 | Equity_Start | decimal(16,6) | YES |
| 4 | Equity_End | decimal(16,6) | YES |
| 5 | Transfers | decimal(16,8) | YES |
| 6 | PnL | decimal(16,6) | YES |
| 7 | UpdateDate | datetime | YES |
| 8 | Dividends | decimal(16,6) | YES |

Distribution: ROUND_ROBIN, CLUSTERED INDEX on `[Date]` ASC.

PHASE 1 CHECKPOINT: PASS
**PHASE 2 — Live Data Sampling**

- **Row count**: 5,130
- **Date range**: 2021-02-10 to 2024-06-07
- **Last ETL update**: 2024-06-08 09:19:24 — **STALE** (no loads for ~2 years)
- **Sample**: 6 distinct accounts (3EU05028, 3EU05027, 3EU05026, 3EU05025, 3EU05000, 3EU00101)
- **Writer SP**: `Dealing_dbo.SP_Apex_PnL` (confirmed from bundle)
- **ETL pattern**: DELETE WHERE Date=@Date + INSERT (WTD grain)

PHASE 2 CHECKPOINT: PASS
**PHASE 3 — Distribution Analysis**

- 6 distinct AccountNumber values (3EU05025: 896, 3EU00101: 896, 3EU05000: 896, 3EU05027: 886, 3EU05026: 825, 3EU05028: 731)
- NULL rates: Transfers 57%, Dividends 54%, Equity_End 14%, Equity_Start 4%, PnL 0%

PHASE 3 CHECKPOINT: PASS

**PHASE 4 — Lookup Resolution**: No FK columns to Dim tables. [-] Not applicable.

**PHASE 5 — JOIN Analysis**: SP uses FULL OUTER JOINs between #Equity, #Transfers, #Dividends_PerAcc on AccountNumber. Source staging tables: LP_APEX_EXT981_3EU (equity), LP_APEX_EXT869_3EU (transfers/dividends).

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**: PnL = Equity_End - Equity_Start - Transfers (WTD equity bridge). Transfers filtered by TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL'). Dividends filtered by TerminalID = '$+DIV'. WTD window: Friday-before to @Date.

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependencies**: [-] No views reference this table in SSDT (small equity-level table).

**PHASE 8 — SP Scan**: Writer SP = `Dealing_dbo.SP_Apex_PnL` (confirmed from bundle). Same SP writes Dealing_Apex_PnL, Dealing_Apex_PnL_Daily, Dealing_Apex_PnL_EE, and Dealing_Apex_PnL_EE_Daily.

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic Extraction**: Full source-to-target mapping traced from SP code (see above analysis). All columns traced to staging sources or ETL computation.

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**: DELETE WHERE Date=@Date + INSERT. Weekly (Saturday reporting date per SP WTD calendar logic). Schedule: same as Dealing_Apex_PnL family. **Stale since 2024-06-08.**

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**: [-] Skipping per regen-harness (no Atlassian search in isolated mode).

**PHASE 10A — Upstream Wiki**: Bundle contains 5 upstream wikis. The staging sources (LP_APEX_EXT981_3EU, LP_APEX_EXT869_3EU) are unresolved — no upstream wiki. All columns are ETL-computed from external LP files. No Tier 1 sources available.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**: Writing lineage file now.

```
PHASE GATE — Dealing_dbo.Dealing_Apex_PnL_EE:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_Apex_PnL_EE:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE/regen/attempt_1/Dealing_Apex_PnL_EE.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE/regen/attempt_1/Dealing_Apex_PnL_EE.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE/regen/attempt_1/Dealing_Apex_PnL_EE.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 8    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — all upstream sources are unresolved staging tables with no wiki)
```
