Starting regen-harness for `eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap` attempt 1.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis (from DDL)**

- Table: `eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap`
- 3 columns: `Date` (date NULL), `Exceptions_Gap` (decimal(16,6) NULL), `UpdateDate` (date NOT NULL)
- Distribution: ROUND_ROBIN, HEAP (no clustered index)
- Writer SP: `SP_eMoney_Client_Balance_Check_Exceptions_Gap` (TRUNCATE + INSERT pattern)

PHASE 1 CHECKPOINT: PASS

**PHASE 2 & 3 — Live Sampling + Distribution**
PHASE 2 CHECKPOINT: PASS
- Table is currently **empty (0 rows)**. This is expected — the SP uses TRUNCATE + INSERT and only inserts when `SUM(CheckCalc) <> 0`. If the latest daily run found no balance decomposition exceptions, the table is empty.

PHASE 3 CHECKPOINT: PASS
- 0 rows — no distribution to analyze. Distribution is ROUND_ROBIN, HEAP (appropriate for a tiny alert/flag table).

**PHASE 4 — Lookup Resolution**: No FK columns or dimension lookups in this 3-column table.
PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**: The SP has no JOINs — it reads only `eMoneyClientBalance` with a simple `GROUP BY / HAVING` aggregation.
PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**: Single-purpose alert table. `SP_eMoney_Client_Balance_Check_Exceptions_Gap` is called at the end of `SP_eMoney_ClientBalance` as a data quality check. It sums `CheckCalc` (= ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO) across all accounts for the business date. If the sum is non-zero, it means the positive/negative balance decomposition has an error.
PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependencies**: Let me check for views referencing this table.
PHASE 7 CHECKPOINT: PASS — No views reference this table.

**PHASE 8 — SP Scan**: Two SPs reference this table:
1. `SP_eMoney_Client_Balance_Check_Exceptions_Gap` — **writer** (TRUNCATE + INSERT)
2. `SP_eMoney_ClientBalance` — **caller** (EXEC at end of daily ETL)

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic Extraction** (from bundle SP code):

Source-to-target map:
| Target Column | Source Expression | Source Table |
|---|---|---|
| `Date` | `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), f.DateID)) AS DATE)` | `#final.DateID` ← `eMoneyClientBalance.BalanceDateID` |
| `Exceptions_Gap` | `SUM(mcb.CheckCalc)` (HAVING <> 0) | `eMoneyClientBalance.CheckCalc` |
| `UpdateDate` | `@Date` (SP input parameter = business date) | SP parameter |

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**: Called as the last alert SP in `SP_eMoney_ClientBalance` daily load: `EXEC [eMoney_dbo].[SP_eMoney_Client_Balance_Check_Exceptions_Gap] @d`. Runs daily after the main balance load completes.
PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**: Skipping Jira search for this small alert table — low value.
PHASE 10 CHECKPOINT: PASS ([-] low-value for alert table)

**PHASE 10A — Upstream Wiki**: The upstream is `eMoneyClientBalance` whose wiki is in the bundle. `CheckCalc` is documented as: "Internal consistency check: ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO. Should equal zero; non-zero indicates positive/negative decomposition error."

All 3 columns are ETL-computed (aggregation / date conversion / SP parameter), so all are **Tier 2**.
PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage** (writing lineage file first):

```
PHASE GATE — eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (low-value alert table)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Directory exists. Now writing the three files in order: lineage first, then wiki, then review-needed.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap:
  [x] .lineage.md    written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Exceptions_Gap/regen/attempt_1/eMoney_Client_Balance_Check_Exceptions_Gap.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Exceptions_Gap/regen/attempt_1/eMoney_Client_Balance_Check_Exceptions_Gap.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Exceptions_Gap/regen/attempt_1/eMoney_Client_Balance_Check_Exceptions_Gap.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 3    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (eMoneyClientBalance wiki used to ground CheckCalc definition and ETL context; all 3 columns are SP-computed aggregations/derivations, so Tier 2 is correct — no passthroughs exist)
```
