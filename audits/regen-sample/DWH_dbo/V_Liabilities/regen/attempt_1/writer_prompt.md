# Regen Harness — Writer Prompt

# Regen Harness — Writer (single-object mode)

You are running the DWH Semantic Documentation pipeline on **ONE OBJECT** in
isolated regen-harness mode. This is NOT the normal batch loop. You are NOT
reading `_index.md`, NOT updating any index file, NOT processing other
objects, NOT running cross-schema sync. You document one object end-to-end and
exit.

---

## ⛔ MCP PRE-FLIGHT — MANDATORY

Before reading any rule files or DDL:

1. Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`.
2. **If it fails or the tool does not exist**: print `REGEN ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. A wiki without live data sampling is INCOMPLETE and WILL FAIL the adversarial judge.
3. **If it succeeds**: print `MCP PRE-FLIGHT: PASS` and continue.

No exceptions. No "code-only documentation" fallback. No "I'll skip Phase 2 because the table looks dormant" — the judge sees the dormant footer too and will fail you for missing data evidence.

---

## ⛔ PRE-RESOLVED UPSTREAM CONTEXT — your Tier 1 inheritance source is below, USE IT

The block titled **"## PRE-RESOLVED UPSTREAM BUNDLE"** in this prompt was
assembled **deterministically by the harness, before you started**. It contains:

- The **DDL** for the object you are documenting (verbatim from SSDT).
- Every **upstream wiki** the harness could resolve from the existing
  `.lineage.md` plus DDL-derived references — both local Synapse wikis and
  remote production-DB wikis (DB_Schema, ExperianceDBs, etc.).
- For any stored procedure mentioned in the lineage, the **SP source code**
  pulled from `DataPlatform\SynapseSQLPool1\sql_dp_prod_we\...`.

**Treat this bundle as your AUTHORITATIVE source for Tier 1 inheritance.** You
are NOT permitted to claim "no upstream wiki could be found" if the bundle
contains one. You ARE permitted to read additional files via the `Read` tool
if you need more context.

### Tier rules — re-stated, NON-NEGOTIABLE

For every column in the object:

1. **Passthrough or rename WITH upstream wiki present in the bundle** →
   **Tier 1**. Description MUST be a verbatim quote from the upstream wiki.
   Do not paraphrase. Do not "improve". Do not generalize vendor names. Do not
   drop NULL semantics. The judge will run a character-by-character
   comparison.
2. **ETL-computed** (CASE / arithmetic / aggregation visible in the SP source) →
   **Tier 2** with the transform stated.
3. **Dim-lookup passthrough** (`SELECT dim.X` with no transform AND `Dim_X`
   has its own Tier 1 origin documented in the bundle) → **Tier 1 with the
   dim's origin** (e.g. `Dictionary.Country`), NOT `Tier 2 via SP_X` and NOT
   `Tier 1 via Dim_X` (Dim_X is a relay, not a root). Quote the dim's wiki
   verbatim.
4. **No source traceable from bundle, DDL, JOINs, or SP source** →
   **Tier 3** with explicit reason. Be specific: "PII column, no upstream wiki
   located, name suggests …".
5. **`Tier 4 — inferred from name`** is BANNED unless the bundle explicitly
   shows the column has no upstream and no SP code touches it. Lazy Tier 4 is
   the #1 reason wikis fail the judge. If you are tempted to write Tier 4
   with no other evidence, you have skipped Phase 9 — go back and read the
   SP source in the bundle.

### Footer rules

- If the bundle contains AT LEAST ONE upstream wiki: the footer MUST identify
  the production source(s). Writing `Production Source: Unknown (dormant)`
  when the bundle proves an upstream exists is an automatic fail.
- If `_no_upstream_found.txt` exists in the regen folder: it is OK to mark
  the table as dormant in the footer, but you MUST still ground every column
  description in the DDL + SP code rather than `Tier 4 — inferred`.

---

## Output paths — write here, NOT into the main wiki tree

Write all THREE output files into:

```
audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/
  {Object}.md
  {Object}.lineage.md
  {Object}.review-needed.md
```

`{Schema}`, `{Object}`, and `{N}` are passed in via the prompt header below.

**DO NOT** write into `knowledge/synapse/Wiki/` under any circumstances. The
main tree is read-only for this run. **DO NOT** modify `_index.md` or any
`_batch_context.json`. **DO NOT** generate `.alter.sql`. **DO NOT** run Phase
16 — the adversarial judge runs as a separate, fresh claude process AFTER you
exit. Pretending to evaluate yourself wastes tokens.

---

## Pipeline scope for this single object

Run phases 1 through 11 inclusive. Skip Phase 16. Skip Phase 11W (no ALTER).
Skip cross-object index updates. Skip `_batch_context.json` writes.

Required phase gates (you must print them as you complete each):

```
PHASE GATE — {Schema}.{Object}:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

If a phase truly cannot run (e.g. no SPs reference the table), mark it `[-]`
with a one-line reason. Skipping P2 or P3 because "the table is small" is
NOT a valid reason — sample it.

---

## Outputs — three files, exact shape

Follow the GOLDEN-REFERENCE in
`.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`.

1. **`{Object}.lineage.md`** — written FIRST (Phase 10B). Source Objects
   table + Column Lineage table. Every Tier 1 row must point to a file in the
   pre-resolved bundle (or to a wiki you read independently).
2. **`{Object}.md`** — the main wiki, 8 sections, every column in
   Section 4's Elements table, every description ending with
   `(Tier N — source)`.
3. **`{Object}.review-needed.md`** — items needing human review. MUST NOT
   contain a `## 4. Elements` section.

---

## Final checklist before exiting

Print, verbatim:

```
OUTPUT CHECK — {Schema}.{Object}:
  [x] .lineage.md    written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.lineage.md
  [x] .md            written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.md
  [x] .review-needed.md written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: N    Tier2: N    Tier3: N    Tier4: N
  Bundle inheritance used: YES/NO  (NO is only valid if `_no_upstream_found.txt` exists)
```

Then EXIT. Do not run a self-evaluation. Do not "double-check by re-reading
the wiki you just wrote". Do not append a verdict block. The judge runs in a
separate process with its own context.


---

# Object Header

- **Schema**: `DWH_dbo`
- **Object**: `V_Liabilities`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/DWH_dbo/V_Liabilities/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\V_Liabilities\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\V_Liabilities\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Views\DWH_dbo.V_Liabilities.sql`

---

# build-wiki-dwh-batch

You are running the DWH Semantic Documentation pipeline for a Synapse DWH schema.
**Wiki-only mode** — generate documentation files only. ALTER scripts are generated separately later via `/generate-alter-dwh`.

## ⛔ MCP PRE-FLIGHT — NON-NEGOTIABLE, CHECK BEFORE ANYTHING ELSE

Before loading rules, before reading the index, before planning anything:

1. **Test Synapse MCP**: Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`
2. **If it fails or the tool does not exist**: Print `BATCH ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. Do NOT proceed. Do NOT fall back to "prior batch context data". Do NOT use a "schema practice" of skipping MCP. A wiki without live data sampling is INCOMPLETE and WILL NOT PASS the adversarial evaluator. STOP HERE.
3. **If it succeeds**: Print `MCP PRE-FLIGHT: PASS` and continue to Instructions.

There is NO exception to this rule. No "prior context", no "code-only documentation", no "graceful degradation". MCP down = batch aborted. Period.

---

## Instructions (regen-harness, single object)

1. **Load rules** — read these in order before anything else:
   - `.cursor/rules/semantic-layer-core/repo-first-access.mdc`
   - `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc`
   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`
   - `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`
   - `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc`

2. **Skip batch planning** — do NOT read `_index.md`, do NOT touch
   `_batch_context.json`, do NOT scan the blacklist. The harness
   already chose this object.

3. **Run the pipeline for THIS object only**: phases 1 through 11
   inclusive. Use the pre-resolved upstream bundle (provided below)
   as your authoritative Tier 1 source. Generate three files in
   `audits/regen-sample/{schema}/{object}/regen/attempt_{N}/`:
   `.lineage.md`, `.md`, `.review-needed.md`. Do NOT generate
   `.alter.sql`. Do NOT modify any file under `knowledge/synapse/Wiki/`.

4. **Skip Phase 16** — the adversarial judge runs in a separate,
   fresh claude process after you exit. Self-evaluation here wastes
   tokens and pollutes the comparison.

5. **Exit cleanly** after printing the OUTPUT CHECK block defined in
   the Regen Harness preamble.

## Key resources

- **SSDT DDL files**: `C:\Users\guyman\Documents\github\DataPlatform\` (repo-first for structure)
- **Upstream wikis (dynamic)**: Load `knowledge/synapse/Wiki/_upstream_wiki_routing.json` for Tier 1 repo locations. Includes DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, ComplianceDBs, PaymentsDBs and more.
- **DWH upstream wikis**: `knowledge/synapse/Wiki/DWH_dbo/` (for cross-schema references)
- **Dependency graph**: `knowledge/synapse/Wiki/_dependency_order.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

## Batch size reference

| Schema | Batch Size |
|--------|-----------|
| DWH_dbo | 4 |
| BI_DB_dbo | 3 |
| Dealing_dbo | 4 |
| EXW_dbo | 3 |
| eMoney_dbo | 4 |
| Default | 3 |

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `DWH_dbo.V_Liabilities`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.V_Liabilities.sql`

```sql
CREATE VIEW [DWH_dbo].[V_Liabilities] AS SELECT a.CID
	   ,DateKey AS DateID
	   ,FullDate
	   ,a.RealizedEquity
      ,a.TotalPositionsAmount
      ,a.TotalCash
      ,a.InProcessCashouts
      ,a.TotalMirrorPositionsAmount
      ,a.TotalMirrorCash
      ,a.TotalStockOrders
      ,a.TotalMirrorStockOrders
      ,a.Credit
      ,a.AUM
      ,a.BonusCredit
	  ,a.TotalStockPositionAmount
	  ,a.TotalMirrorStockPositionAmount
	  ,c.PositionPnL
	  ,c.CopyPositionPnL
	  ,c.StandardDeviation
	  ,c.CommissionOnOpen
	   ,CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)>ISNULL(BonusCredit,0) THEN ISNULL(BonusCredit,0) 
			   WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 0
			   ELSE ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
		 END AS ActualNWA
       ,ISNULL(InProcessCashouts,0)+CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)>0 THEN 
	                                          ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)
                                         WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 
										      ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
										ELSE 0 END AS Liabilities

       ,CASE WHEN (CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)>0 THEN 
	                                          ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)
                                         WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 
										      ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
										ELSE 0 END)>Credit THEN Credit 
			ELSE (CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)>0 THEN 
	                                          ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)
                                         WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 
										      ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
										ELSE 0 END) END AS WA_Liabilities
      ,CASE WHEN (CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)>0 THEN 
	                                          ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)
                                         WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 
										      ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
										ELSE 0 END)>Credit THEN 
            (CASE WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)>0 THEN 
	                                          ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)-ISNULL(BonusCredit,0)
                                         WHEN ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)<0 THEN 
										      ISNULL(TotalPositionsAmount, 0)+ISNULL(TotalCash, 0)+ISNULL(TotalStockOrders, 0)+ISNULL(PositionPnL,0)
										ELSE 0 END)-Credit ELSE 0 END AS Liabilities_InUsedMargin
		,StocksPositionPnL
		,TotalStockPositionAmount+TotalStockOrders - TotalMirrorStockPositionAmount AS TotalStockManualPosition
	   ,StocksPositionPnL - MirrorStocksPositionPnL AS ManualStockPositionPnL
	   ,MirrorStocksPositionPnL
	   ,CryptoPositionPnL
	   ,ManualCryptoPositionPnL
	   ,CopyCryptoPositionPnL
       ,TotalCryptoPositionAmount
	   ,TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount AS TotalCryptoManualPosition 
	   ,CopyFundAUM
	   ,CopyFundPnL
	   ,NOP
	   ,Notional
	   ,NOP_Crypto
	   ,Notional_Crypto
	   ,NOP_CFD
	   ,Notional_CFD
	   ,NOP_Crypto_CFD
	   ,Notional_Crypto_CFD
	   ,PositionPnLStocksReal
	   ,PositionPnLCryptoReal
	   ,TotalRealStocks
	   ,TotalRealCrypto
	   ,ISNULL(PositionPnLStocksReal, 0)+ISNULL(TotalRealStocks,0) AS LiabilitiesStockReal
	   ,ISNULL(PositionPnLCryptoReal, 0)+ISNULL(TotalRealCrypto,0) AS LiabilitiesCryptoReal
	   ,c.CommissionByUnitsCrypto_TRS
	   ,c.CopyCryptoPositionPnL_TRS
	   ,c.CryptoPositionPnL_TRS
	   ,c.FullCommissionByUnitsCrypto_TRS
	   ,c.ManualCryptoPositionPnL_TRS
	   ,c.NOP_Crypto_TRS
	   ,c.Notional_Crypto_TRS
	   ,a.Total_TRSCrypto
	   ,a.TotalCryptoPositionAmount_TRS
	   ,a.TotalCryptoPositionAmount_TRS - a.TotalMirrorCryptoPositionAmount_TRS  as TotalCryptoManualPosition_TRS
       ,isnull(c.CryptoPositionPnL_TRS,0) + isnull(a.Total_TRSCrypto,0) as LiabilitiesCrypto_TRS
	   , MirrorRealFuturesPositionPnL 
	   , ManualRealFuturesPositionPnL 
	   , NOP_FuturesReal
	   , Notional_FuturesReal 
	   , PositionPnLFuturesReal 
	   , FullCommissionByUnitsFuturesReal 
	   , CommissionByUnitsFuturesReal 
	   , TotalMirrorRealFuturesPositionAmount 
	   , TotalRealFutures
	   , TotalFuturesProviderMargin 
       ,isnull(c.PositionPnLFuturesReal,0) + isnull(a.TotalRealFutures,0) as LiabilitiesFuturesReal
	   ------------------StockMargin------------------
	   ,NOP_StocksMargin
	   ,PositionPnLStocksMargin
	   ,TotalStocksMargin
	   ,TotalStockMarginLoanValue
FROM  DWH_dbo.Fact_SnapshotEquity a WITH(NOLOCK) 
JOIN DWH_dbo.V_M2M_Date_DateRange b
ON(a.DateRangeID=b.DateRangeID)
LEFT  JOIN DWH_dbo.Fact_CustomerUnrealized_PnL c WITH(NOLOCK) 
ON(a.CID=c.CID AND b.DateKey=c.DateModified)
LEFT  JOIN DWH_dbo.Fact_Guru_Copiers gc WITH(NOLOCK)  --- 2021.01.11 - Boris Slutski
ON(a.CID=gc.CID AND b.DateKey=gc.DateID)
WHERE	b.DateKey<CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT);
GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_SnapshotEquity` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotEquity`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotEquity.md`

# DWH_dbo.Fact_SnapshotEquity

> Daily customer equity snapshot storing end-of-day balance breakdowns — cash, position amounts, in-process cashouts, realized equity, AUM, and asset-class splits (stocks, crypto, TRS, futures, stock margin) — per customer per date range, providing the foundational time-series dataset for portfolio valuation, liabilities reporting, regulatory balance snapshots, and customer-level financial analytics across the platform.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | History.ActiveCredit + Trade.OpenPositionEndOfDay + History.ClosePositionEndOfDay + Billing.Withdraw (multi-source aggregate) |
| **Key Identifier** | CID + DateRangeID (PK NOT ENFORCED) |
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED COLUMNSTORE; NCI on CID |
| **Column Count** | 32 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC export** | Base table **Fact_SnapshotEquity** is not listed as its own `uc_table` in `_generic_pipeline_mapping.json` (this snapshot). Unity Catalog carries the **views**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity` (**V_Fact_SnapshotEquity**, generic_id=416, parquet) and `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid` (**V_Fact_SnapshotEquity_FromDateID**, generic_id=1121, delta). `V_Liabilities` and other consumers read equity through these (expanded dates / FromDateID). |
| **Refresh** | Daily |
| **ETL Pattern** | Multi-SP orchestration: staging extract → position aggregation → equity assembly → MERGE |

---

## 1. Business Meaning

`Fact_SnapshotEquity` captures a daily end-of-day financial snapshot per customer (CID). Each row represents one customer's complete balance picture for a date range, combining:

- **Cash balances**: TotalCash (running balance from History.ActiveCredit), TotalCashCalculation (parallel computation), TotalMirrorCash (cash minus credit)
- **Position amounts**: total, mirror, stock, crypto, real stocks, real crypto, TRS crypto, futures, and stock margin breakdowns — all aggregated from open and recently-closed positions
- **Liabilities**: InProcessCashouts (pending withdrawals not yet finalized), Credit (outstanding credit/bonus)
- **Portfolio metrics**: RealizedEquity (total account value including unrealized PnL), AUM (Assets Under Management = TotalMirrorPositionAmount + TotalCash - Credit)

The table uses a `DateRangeID` (bigint) that encodes a "from date + to date" pair (format: `YYYYMMDDYYYYMMDD`), enabling Slowly Changing Dimension behavior. New snapshots insert with `FromDate=today, ToDate=Dec31`. When an existing customer's equity changes the next day, the MERGE updates the previous row's ToDate to yesterday, then inserts a new row. This means `V_Fact_SnapshotEquity` (which JOINs to `Dim_Range` + `Dim_Date`) can reproduce any historical day's equity without storing a separate row per CID per day.

### Business Usage

- **Platform Portfolio Display**: "The Portfolio value figure represented on the platform is Unrealized equity" (Confluence: DWH View Fact_SnapshotEquity). Formula: `Cash Available + Total Invested + Profit/Loss = Unrealized Equity`
- **AUM Dashboard**: AUM shown on the PI Dashboard as "Total Unrealized Copy Amount of the Copiers" (Confluence: AUM Life Cycle). Formula: `AUM = Cash + Investment`
- **V_Liabilities**: Downstream view computes liabilities from this table: `RealizedEquity = TotalPositionsAmount + TotalCash + InProcessCashouts`
- **UserStatsAPI**: Serves `CID, DateModified, PositionPnL` from V_Fact_SnapshotEquity (Confluence: DWH Usage)
- **Average Daily Equity HLD**: Flow 5 in Periodic Rankings uses equity snapshots from DWH_rep to calculate average daily equity (Confluence: Flow 5: Average Daily Equity HLD)
- **Client Balance / Regulatory**: SP_Client_Balance_New, SP_Y_RBSF, SP_CashRiskMatrix all consume this table for balance-based analytics

---

## 2. Business Logic

### 2.1 ETL Orchestration (SP_Fact_SnapshotEquity_DL_To_Synapse)

The main ETL SP orchestrates a 4-phase pipeline:

```
Phase 1: Data Extraction (staging tables)
  - Delete forward-looking rows if re-running for a past date
  - Truncate + load 9 staging tables from DWH_staging:
    Ext_FSE_History_WithdrawToFundingAction  ← History.WithdrawToFundingAction
    Ext_FSE_History_WithdrawAction           ← History.WithdrawAction
    Ext_FSE_Billing_WithdrawToFunding        ← Billing.WithdrawToFunding
    Ext_FSE_Billing_Withdraw                 ← Billing.Withdraw
    Ext_FSE_TotalCashChangeAll               ← SUM(TotalCashChange) from History.ActiveCredit for @dt
    Ext_FSE_Real_History_Credit              ← Last credit event per CID per day (ROW_NUMBER) from History.ActiveCredit
    Ext_FSE_History_Position                 ← Closed positions from History.ClosePositionEndOfDay + GetInstrument
    Ext_FSE_Trade_Position                   ← Open positions from Trade.OpenPositionEndOfDay + GetInstrument
    Ext_FSE_PositionChangeLog                ← IsSettled changes from History.PositionChangeLog (ChangeTypeID=13)
    Ext_FSE_History_Credit                   ← SUM(-TotalCashChange) for CreditTypeID=13 (position credits)
  - Dedup: remove Trade positions that also appear in History (same PositionID)

Phase 2: InProcessCashouts (SP_Fact_SnapshotEquity_InProcessCashouts)
  - Calculates pending withdrawal amounts per CID
  - Excludes withdrawals with finalized statuses (3,4,5,6) from History.WithdrawAction
  - Adds partially processed amounts from split-payment withdrawals

Phase 3: Position Aggregation (SP_Fact_SnapshotEquity_TotalPositionAmount)
  - Unions open + closed positions into #PositionAmount
  - Adjusts IsSettled using PositionChangeLog (reverts to PreviousIsSettled)
  - Subtracts History.Credit CreditTypeID=13 amounts from position values
  - Aggregates per CID into asset class buckets using InstrumentTypeID + IsSettled + SettlementTypeID + IsFuture
  - Futures detection via JOIN to Dim_Instrument_Snapshot (IsFuture=1)

Phase 4: Final Assembly (SP_Fact_SnapshotEquity)
  - JOINs: Real_History_Credit × InProcessCashouts × TotalPositionAmount × TotalCashChangeAll × #TotalCashPreviousDate
  - Computes TotalCash, RealizedEquity, AUM, TotalMirrorCash
  - Inserts into Ext_FSE_Fact_SnapshotEquity
  - MERGE into Fact_SnapshotEquity (UPDATE DateRangeID end-date for changed CIDs, INSERT new CIDs)
  - Inserts new DateRangeIDs into Dim_Range
  - Year-end closure on Jan 1st: carries over previous year's final snapshot for CIDs without activity
```

### 2.2 DateRangeID Encoding

DateRangeID is a 12-digit bigint encoding two dates: `YYYYMMDDYYYY` (FromDate + ToDate year/month/day suffix).

- New row: `@date` + `1231` (e.g., `202501241231` = from Jan 24 to Dec 31)
- When equity changes: MERGE updates existing row's suffix to `@daybefore` (closing the range), then INSERTs a fresh row with current date to Dec 31

The view `V_Fact_SnapshotEquity` decodes this via `Dim_Range` (FromDateID, ToDateID) and JOINs `Dim_Date` to produce one row per CID per calendar day.

### 2.3 Position Amount Classification

The position aggregation SP classifies amounts by asset class using these rules:

| Metric | Condition |
|--------|-----------|
| TotalStockPositionAmount | InstrumentTypeID IN (5,6) AND NOT futures |
| TotalCryptoPositionAmount | InstrumentTypeID = 10 AND NOT futures |
| TotalRealStocks | IsSettled=1 AND stock AND NOT futures |
| TotalRealCrypto | IsSettled=1 AND crypto AND NOT futures |
| TotalRealCryptoLoan | IsSettled=1 AND crypto AND NOT futures AND Leverage=2 → InitialAmount |
| TotalCryptoPositionAmount_TRS | Crypto AND SettlementTypeID=2 AND NOT futures |
| Total_TRSCrypto | IsSettled=0 AND crypto AND SettlementTypeID=2 |
| TotalRealFutures | IsFuture=1 (from Dim_Instrument_Snapshot) |
| TotalFuturesProviderMargin | IsFuture=1 → LotCountDecimal × ProviderMarginPerLot |
| TotalFuturesLockedCash | IsFuture=1 → NewAmount - (LotCountDecimal × ProviderMarginPerLot) |
| TotalStocksMargin | SettlementTypeID=5 |
| TotalStockMarginLoanValue | SettlementTypeID=5 AND Leverage<>1 → InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount |

Mirror variants add `MirrorID > 0 AND ISNULL(ParentPositionID, 0) != 0`.

### 2.4 Key Formulas

- **TotalCash** = TotalCashPreviousDate (from last Fact_SnapshotEquity row for the year) + TotalCashChangeAll (sum of TotalCashChange from History.ActiveCredit for @dt)
- **RealizedEquity** = IF History.ActiveCredit.RealizedEquity = 0 THEN TotalCash + TotalPositionAmount + InProcessCashouts ELSE History.ActiveCredit.RealizedEquity
- **AUM** = TotalMirrorPositionAmount + TotalCash - Credit
- **TotalMirrorCash** = TotalCash - Credit

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(CID)**: All queries for a single customer are single-node. Date-range queries across customers require data movement.
- **CLUSTERED COLUMNSTORE**: Optimized for analytical aggregations across many customers. Compression benefits from many zero/ISNULL values in position amount columns.
- **NCI on CID**: Point-lookup acceleration for customer-specific queries.
- **PK (CID, DateRangeID) NOT ENFORCED**: Logical uniqueness constraint; no physical enforcement overhead on Synapse.

### 3.2 Data Freshness

- Daily load via `SP_Fact_SnapshotEquity_DL_To_Synapse`
- Depends on DWH_staging tables being loaded first (History.ActiveCredit, positions, withdrawals)
- Position data adjusted by IsSettled changes logged in History.PositionChangeLog
- Year-end carryover logic runs on Jan 1st — copies previous year's final snapshot for inactive CIDs

---

## 4. Elements

> Note: This is a fully DWH-computed snapshot table. No upstream production wikis exist for the primary sources (History.ActiveCredit, History.Credit). All columns are Tier 2 — computed/aggregated by the ETL SPs from 10+ staging tables. The Confluence page "DWH View Fact_SnapshotEquity" provides authoritative business definitions used below.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 — SP_Fact_SnapshotEquity) |
| 2 | DateRangeID | bigint | NO | Encoded date range as 12-digit bigint (YYYYMMDDYYYY). FromDate in first 8 digits, ToDate suffix in last 4 digits. New rows get @date+1231; updated rows get end-date set to @daybefore. Decoded via Dim_Range. Part of PK. (Tier 2 — SP_Fact_SnapshotEquity) |
| 3 | TotalPositionsAmount | money | NO | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 4 | TotalCash | money | NO | Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read. (Tier 2 — SP_Fact_SnapshotEquity) |
| 5 | InProcessCashouts | money | NO | Sum of pending withdrawal amounts for this CID that have not yet been finalized (statuses other than 3=Processed, 4=Cancelled, 5,6). Includes partially processed amounts for split-payment withdrawals plus associated fees. Computed by SP_Fact_SnapshotEquity_InProcessCashouts from Billing.Withdraw, History.WithdrawAction, and History.WithdrawToFundingAction. (Tier 2 — SP_Fact_SnapshotEquity_InProcessCashouts) |
| 6 | TotalMirrorPositionsAmount | money | NO | Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only, excluding the parent/guru's own positions). Represents the CID's total investment in copy relationships. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 7 | TotalMirrorCash | money | NO | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 2 — SP_Fact_SnapshotEquity) |
| 8 | TotalStockOrders | money | NO | Legacy column, hardcoded to 0. Removed 2019-03-03 (Boris Slutski) — no data in PROD since 2015. Kept for schema compatibility. (Tier 2 — SP_Fact_SnapshotEquity) |
| 9 | TotalMirrorStockOrders | money | NO | Legacy column, hardcoded to 0. Removed 2019-03-03 alongside TotalStockOrders. Kept for schema compatibility. (Tier 2 — SP_Fact_SnapshotEquity) |
| 10 | RealizedEquity | money | NO | Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: "Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity." (Tier 2 — SP_Fact_SnapshotEquity) |
| 11 | Credit | money | NO | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations. (Tier 2 — SP_Fact_SnapshotEquity) |
| 12 | AUM | money | NO | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers." (Tier 2 — SP_Fact_SnapshotEquity) |
| 13 | BonusCredit | money | YES | Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: "History.Credit.CreditTypeID = 5, 7 → BackOffice.BonusType.BonusTypeID → History.Credit.BonusTypeID". ISNULL to 0 in ETL. (Tier 2 — SP_Fact_SnapshotEquity) |
| 14 | CreditID | bigint | YES | Last CreditID for this CID on this date from History.ActiveCredit. Selected as the most recent credit event via ROW_NUMBER(PARTITION BY CID, DateID ORDER BY Occurred DESC, CreditID DESC). Used for auditing which credit record drives the snapshot. (Tier 2 — SP_Fact_SnapshotEquity_DL_To_Synapse) |
| 15 | UpdateDate | datetime | YES | ETL load timestamp (GETDATE() at MERGE/INSERT time). Used for detecting recent updates in the year-end carryover and IsSettled change handling. (Tier 2 — SP_Fact_SnapshotEquity) |
| 16 | TotalStockPositionAmount | money | YES | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). Added with mutual exclusivity fix (Guy M, 2025-07-29). (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 17 | TotalMirrorStockPositionAmount | money | YES | Mirror (copy-trading) subset of TotalStockPositionAmount. Adds MirrorID > 0 AND ParentPositionID != 0. Same mutual exclusivity fix with futures. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 18 | TotalCryptoPositionAmount | money | YES | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. Confluence: "TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount" (approximately, excluding other types). (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 19 | TotalMirrorCryptoPositionAmount | money | YES | Mirror (copy-trading) subset of TotalCryptoPositionAmount. Same conditions plus MirrorID > 0 AND ParentPositionID != 0. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 20 | TotalRealStocks | decimal(16,2) | YES | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. "Real" means the customer owns the underlying asset (settled/delivered). Updated via IsSettled change tracking from History.PositionChangeLog. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 21 | TotalRealCrypto | decimal(16,2) | YES | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND instrument is NOT a future. Real crypto ownership (settled positions). Updated via IsSettled change tracking. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 22 | TotalRealCryptoLoan | decimal(16,2) | YES | Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND NOT future AND Leverage = 2. Represents the initial investment in leveraged real crypto positions (the loan portion). Changed from Amount to InitialAmount on 2020-03-25. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 23 | TotalCashCalculation | money | YES | Parallel computation of TotalCash (same formula: TotalCashPreviousDate + TotalCashChangeAll). Exists as a validation/audit column to cross-check TotalCash. (Tier 2 — SP_Fact_SnapshotEquity) |
| 24 | TotalCryptoPositionAmount_TRS | decimal(16,2) | YES | Sum of crypto position amounts where SettlementTypeID = 2 (TRS — Total Return Swap) AND instrument is NOT a future. Added 2022-01-27 (Inbal BML). TRS positions have different regulatory treatment than settled positions. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 25 | TotalMirrorCryptoPositionAmount_TRS | decimal(16,2) | YES | Mirror (copy-trading) subset of TotalCryptoPositionAmount_TRS. TRS crypto positions in copy relationships. Added 2022-01-27. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 26 | Total_TRSCrypto | decimal(16,2) | YES | Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). Added 2022-01-27. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 27 | TotalMirrorRealFuturesPositionAmount | decimal(16,2) | YES | Sum of futures position amounts where MirrorID > 0. From Dim_Instrument_Snapshot.IsFuture = 1. Added 2024-10-30 (Daniel Kaplan). (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 28 | TotalRealFutures | decimal(16,2) | YES | Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 29 | TotalFuturesProviderMargin | decimal(16,2) | YES | Sum of provider margin for futures positions: LotCountDecimal × Dim_Instrument_Snapshot.ProviderMarginPerLot. Represents the margin required by the futures provider. Added 2024-10-30. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 30 | TotalFuturesLockedCash | decimal(18,4) | YES | Cash locked in futures positions beyond provider margin: NewAmount - (LotCountDecimal × ProviderMarginPerLot). Represents customer cash tied up as additional margin. Added 2024-10-30. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 31 | TotalStocksMargin | decimal(16,2) | YES | Sum of stock margin position amounts where SettlementTypeID = 5. Represents margin-traded stock positions (not fully settled). Added 2025-09-30 (Daniel Kaplan). (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |
| 32 | TotalStockMarginLoanValue | decimal(16,2) | YES | Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) |

---

## 5. Lineage

### 5.1 Staging Sources (from DWH_staging)

| DWH Staging Table | Production Source | Role |
|-------------------|-------------------|------|
| etoro_History_ActiveCredit | History.ActiveCredit | TotalCash running balance, RealizedEquity, Credit, BonusCredit, CreditID |
| etoro_History_ClosePositionEndOfDay | History.ClosePositionEndOfDay | Same-day closed positions for position amount aggregation |
| etoro_Trade_OpenPositionEndOfDay | Trade.OpenPositionEndOfDay | Open positions for position amount aggregation |
| etoro_History_PositionChangeLog | History.PositionChangeLog | IsSettled changes (ChangeTypeID=13) for real stock/crypto tracking |
| etoro_History_Credit | History.Credit | CreditTypeID=13 position credit adjustments |
| etoro_Billing_Withdraw | Billing.Withdraw | InProcessCashouts calculation |
| etoro_History_WithdrawAction | History.WithdrawAction | Withdraw status history for cashout computation |
| etoro_History_WithdrawToFundingAction | History.WithdrawToFundingAction | Payment leg status for partial processing |
| etoro_Billing_WithdrawToFunding | Billing.WithdrawToFunding | Payment leg amounts for partial processing |
| etoro_Trade_GetInstrument | Trade.GetInstrument | InstrumentTypeID for asset class classification |

### 5.2 Internal DWH Dependencies

| Table/Object | Role |
|------|------|
| Dim_Instrument_Snapshot | IsFuture flag + ProviderMarginPerLot for futures detection (snapshot per DateID) |
| Dim_Range | Decodes DateRangeID into FromDateID + ToDateID |
| Dim_Date | Calendar table for V_Fact_SnapshotEquity view |
| Ext_FSE_Fact_SnapshotEquity | Staging table for the final MERGE assembly |
| Ext_FSE_TotalPositionAmount | Per-CID aggregated position amounts by asset class |
| Ext_FSE_InProcessCashouts | Per-CID pending cashout totals |
| Ext_FSE_Real_History_Credit | Last credit event per CID per day |
| Ext_FSE_TotalCashChangeAll | Sum of TotalCashChange per CID for the day |

### 5.3 Upstream Wiki Availability

| Source Table | Wiki Available | Path |
|-------------|---------------|------|
| History.ActiveCredit | No | Not yet documented |
| History.Credit | No | Not yet documented |
| History.ClosePositionEndOfDay | No | Not yet documented |
| Trade.OpenPositionEndOfDay | Yes (view) | `DB_Schema/etoro/Wiki/Trade/Views/Trade.OpenPositionEndOfDay.md` |
| History.PositionChangeLog | No | Not yet documented |
| Billing.Withdraw | Yes | `DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` |
| Trade.GetInstrument | No | Not yet documented |

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| DateRangeID | Dim_Range | DateRangeID = DateRangeID → FromDateID, ToDateID |

### 6.2 Downstream Views

| View | Purpose |
|------|---------|
| V_Fact_SnapshotEquity | Expands DateRangeID via Dim_Range + Dim_Date to produce one row per CID per calendar day (DateKey) |
| V_Fact_SnapshotEquity_FromDateID | Filtered variant for date-range lookups |
| V_Fact_SnapshotEquity_ForDWHRep | Replication variant for DWH_rep database |
| V_Liabilities | Computes liabilities: RealizedEquity = TotalPositionsAmount + TotalCash + InProcessCashouts |

### 6.3 Downstream SPs (BI_DB)

| SP | Usage |
|----|-------|
| SP_Client_Balance_New | Customer balance reporting |
| SP_CIDFirstDates | First date tracking per CID |
| SP_DDR | Daily Data Report |
| SP_Y_RBSF | Regulatory balance reporting |
| SP_User_Segment_Snapshot | Customer segmentation |
| SP_LTV_Multiplier_Model | Lifetime value modeling |
| SP_CashRiskMatrix | Cash risk analysis |
| SP_Fact_CustomerUnrealized_PnL | Unrealized PnL computation (depends on this table for equity) |

### 6.4 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Customer equity snapshot for a specific date
SELECT fse.CID, fse.TotalCash, fse.TotalPositionsAmount,
       fse.RealizedEquity, fse.AUM, fse.InProcessCashouts
FROM DWH_dbo.V_Fact_SnapshotEquity fse
WHERE fse.DateKey = 20260318
  AND fse.CID = 12345;

-- Daily equity trend for a customer (last 30 days)
SELECT fse.DateKey, fse.TotalCash, fse.RealizedEquity,
       fse.TotalRealStocks, fse.TotalRealCrypto, fse.TotalRealFutures
FROM DWH_dbo.V_Fact_SnapshotEquity fse
WHERE fse.CID = 12345
  AND fse.DateKey >= 20260217
ORDER BY fse.DateKey;

-- Total platform AUM by date
SELECT fse.DateKey, SUM(fse.AUM) AS PlatformAUM,
       COUNT(DISTINCT fse.CID) AS ActiveCustomers
FROM DWH_dbo.V_Fact_SnapshotEquity fse
WHERE fse.DateKey = 20260318
GROUP BY fse.DateKey;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| DWH View Fact_SnapshotEquity (Confluence/DROD) | Detailed column-by-column business definitions with example values; formula explanations for TotalCash, RealizedEquity, AUM, InProcessCashouts |
| DWH Usage (Confluence/DROD) | Documents downstream consumers: UserStatsAPI, V_M2M_Date_DateRange, multiple BI SPs |
| AUM Life Cycle (Confluence/DROD) | Explains AUM = Cash + Investment with full component breakdown |
| Flow 5: Average Daily Equity HLD (Confluence/DROD) | Periodic Rankings flow using equity snapshots for average daily equity calculation |
| Summary of V-Liabilities (Confluence/BI) | Documents how V_Liabilities derives liabilities from Fact_SnapshotEquity fields |
| DWH DWH_Status and DataSolutionsProcessesStatus (Confluence/BDP) | Job scheduling: Task "Fact_SnapshotEquity" with DWH_Status=1 and replication process |

---
*Generated: 2026-03-19 | Quality: 9.0/10*
*Tiers: 0 T1, 32 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `DWH_dbo.Fact_SnapshotEquity` | synapse | DWH_dbo | Fact_SnapshotEquity | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotEquity.md` |

