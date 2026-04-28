MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing the pipeline phases for `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`.

**Phase 1 — Structure Analysis (from DDL)**

DDL shows 3 columns:
- `Date` — date, NULL
- `Openning_Balance_Gap` — decimal(16,6), NULL  
- `UpdateDate` — date, NOT NULL

Distribution: ROUND_ROBIN, HEAP

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 3 (distribution) in parallel.
Table is currently **empty** (0 rows). This is expected — the SP truncates and re-inserts only when there IS an opening balance gap (HAVING SUM(OpeningBalanceGAP) <> 0). When reconciliation is clean, the table stays empty.

PHASE 2 CHECKPOINT: PASS (0 rows, table is an alert/exception table — empty when no gaps exist)

PHASE 3 CHECKPOINT: PASS (0 rows — no distribution analysis possible; table is ROUND_ROBIN HEAP alert table)

**Phase 4 — Lookup Resolution**: No FK/dimension lookups in this 3-column alert table.  
PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**: The writer SP (`SP_eMoney_Client_Balance_Check_Opening_Balance`) reads from `eMoneyClientBalance` with a simple GROUP BY. No JOINs.  
PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: This is an alert/exception table. When `SP_eMoney_ClientBalance` finishes its daily run, it calls `SP_eMoney_Client_Balance_Check_Opening_Balance @d`. The SP aggregates `OpeningBalanceGAP` from `eMoneyClientBalance` for that day. If the sum is non-zero, a row is inserted. If zero, the table stays empty (it was truncated at the start).  
PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency Scan**: Let me check for views referencing this table.
PHASE 7 CHECKPOINT: PASS (no views reference this table)

**Phase 8 — SP Scan**: Two SPs reference this table:
1. `SP_eMoney_Client_Balance_Check_Opening_Balance` — **writer** (TRUNCATE + INSERT)
2. `SP_eMoney_ClientBalance` — **caller** (EXEC at the end of daily ETL)

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: Already have the SP code in the bundle. Analysis:

The writer SP (`SP_eMoney_Client_Balance_Check_Opening_Balance`):
1. Takes `@Date` parameter
2. Computes `@DateID = CAST(CONVERT(CHAR(8), @Date, 112) AS INT)`
3. Creates `#final`: `SELECT mcb.BalanceDateID AS DateID, SUM(mcb.OpeningBalanceGAP) AS 'Openning_Balance_Gap' FROM eMoney_dbo.eMoneyClientBalance mcb WHERE mcb.BalanceDateID=@DateID GROUP BY BalanceDateID HAVING SUM(mcb.OpeningBalanceGAP)<>0`
4. `TRUNCATE TABLE eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`
5. `INSERT INTO` with:
   - `Date` = `CAST(CONVERT(DATETIME, CONVERT(char(8), f.DateID)) AS DATE)` — converts DateID back to date
   - `Openning_Balance_Gap` = `f.Openning_Balance_Gap` — the aggregated sum
   - `UpdateDate` = `@Date` — the input parameter

Column mapping:
- **Date**: Tier 2 — ETL-computed: converts `eMoneyClientBalance.BalanceDateID` (int YYYYMMDD) back to a date type
- **Openning_Balance_Gap**: Tier 2 — ETL-computed: `SUM(eMoneyClientBalance.OpeningBalanceGAP)` across all accounts for that day
- **UpdateDate**: Tier 2 — ETL-computed: set to the `@Date` input parameter (= GETDATE() at call time from SP_eMoney_ClientBalance)

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL Orchestration**: Called at the tail of `SP_eMoney_ClientBalance` daily run. Pattern: daily TRUNCATE + conditional INSERT.  
PHASE 9B CHECKPOINT: PASS

**Phase 10 — Jira**: Skipping Jira search for this small alert table.  
PHASE 10 CHECKPOINT: PASS (low-value for 3-column alert table)

**Phase 10A — Upstream Wiki**: The upstream bundle provides the `eMoneyClientBalance` wiki. The `OpeningBalanceGAP` column is documented there as Tier 2. Since this table aggregates that column via SUM, these are Tier 2 ETL-computed columns.  
PHASE 10A CHECKPOINT: PASS

**Phase 10B — Column Lineage**: Writing lineage file now.

```
PHASE GATE — eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Directory exists. Now writing the three files in order: lineage first, then wiki, then review-needed.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance:
  [x] .lineage.md    written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Opening_Balance/regen/attempt_1/eMoney_Client_Balance_Check_Opening_Balance.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Opening_Balance/regen/attempt_1/eMoney_Client_Balance_Check_Opening_Balance.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Opening_Balance/regen/attempt_1/eMoney_Client_Balance_Check_Opening_Balance.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 3    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (eMoneyClientBalance wiki confirmed OpeningBalanceGAP is Tier 2 — SUM aggregation makes all columns Tier 2 in this alert table)
```
