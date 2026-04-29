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

- **Schema**: `Dealing_dbo`
- **Object**: `Dealing_Execution_Slippage`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_Execution_Slippage/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Execution_Slippage\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Execution_Slippage\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_Execution_Slippage.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_Execution_Slippage`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_Execution_Slippage.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_Execution_Slippage]
(
	[Date] [date] NULL,
	[InstrumentID] [int] NULL,
	[Occurred] [datetime] NULL,
	[ExecutionTime] [datetime] NULL,
	[IsBuy] [bit] NULL,
	[Units] [decimal](16, 6) NULL,
	[ExecutionRate] [decimal](16, 6) NULL,
	[eToro_Price] [decimal](16, 6) NULL,
	[ProviderAmount_USD] [decimal](16, 6) NULL,
	[eToro_AmountUSD] [decimal](16, 6) NULL,
	[FX_Rate] [decimal](16, 6) NULL,
	[Slippage] [decimal](16, 6) NULL,
	[SlippageInDollar] [decimal](16, 6) NULL,
	[Slippage_Percent] [decimal](16, 6) NULL,
	[UpdateDate] [datetime] NULL,
	[HedgingMode] [varchar](10) NULL,
	[KustoTime] [datetime] NULL,
	[Kusto_Price] [decimal](16, 6) NULL,
	[BidSpreaded] [decimal](16, 6) NULL,
	[AskSpreaded] [decimal](16, 6) NULL,
	[NumberofTransaction] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_CurrencyPriceWithSplit` — synapse
- **Resolved as**: `DWH_dbo.Fact_CurrencyPriceWithSplit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md`

# DWH_dbo.Fact_CurrencyPriceWithSplit

> Daily price snapshot fact table capturing bid/ask prices per financial instrument per day, with spread-adjusted values, split-adjusted history for corporate-action dates, and pre-computed USD conversion rates.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake export) |
| **Refresh** | Daily (per-date incremental via @dt parameter) |
| | |
| **Synapse Distribution** | HASH(InstrumentID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + NONCLUSTERED(OccurredDateID) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit |
| **UC Format** | Delta (Merge strategy, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Fact_CurrencyPriceWithSplit is the DWH's authoritative daily price reference table. It stores one or more price rows per instrument per calendar day, including the raw bid/ask prices, spread-adjusted prices (AskSpreaded/BidSpreaded), and the last execution rate (RateLastEx). The `isvalid` flag marks whether a given price row was the active price at end-of-day. This table is the primary source for historical price look-ups used in P&L calculations across the warehouse.

Data originates from the PriceLog Candles pipeline in the Data Lake. The staging view `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` delivers daily candlestick prices for all instruments. On dates when a stock split occurs (identified via `DWH_staging.etoro_History_SplitRatio`), the ETL switches to `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for the affected instruments.

Loaded daily by `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)`. The SP deletes all rows for the given date, reloads from staging, then applies a split-branch if split events exist. A final UPDATE pass computes `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` using cross-currency logic to normalize instrument prices to USD. Data covers 2009-06-15 to the present with approximately 17.2M rows across 15,400+ distinct instruments.

---

## 2. Business Logic

### 2.1 Stock Split Price Adjustment

**What**: When a corporate action (stock split) occurs on a given date, prices for the affected instrument must be reloaded using split-adjusted history rather than the standard daily candle.

**Columns Involved**: `InstrumentID`, `OccurredDateID`, `AskSpreaded`, `BidSpreaded`, `Ask`, `Bid`, `RateLastEx`

**Rules**:
- On each daily run, the SP checks `DWH_staging.etoro_History_SplitRatio` for splits on `@dt`
- If split records exist (`@CountRowsSplit > 0`), all rows for the affected `InstrumentID` values are deleted from Fact_CurrencyPriceWithSplit
- Replacement rows are loaded from `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which contains the retroactively adjusted price series
- `ConvertRateIsBuy_1/0` from the pre-split date are preserved via a `#ConvertRateIsBuy` temp table join

**Diagram**:
```
Daily run:
  DELETE WHERE OccurredDateID = @DateID
  INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView

Split check:
  IF etoro_History_SplitRatio has rows for @dt:
    DELETE affected instruments
    INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    PRESERVE ConvertRates from pre-split data via #ConvertRateIsBuy temp table
```

### 2.2 USD Conversion Rate Computation

**What**: After loading prices, the SP computes two pre-calculated USD conversion rates per instrument per day, one for buy-side positions and one for sell-side. These rates allow downstream consumers to convert instrument P&L to USD without re-deriving the currency cross-rate.

**Columns Involved**: `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0`, `Ask`, `Bid`, `InstrumentID`

**Rules**:
- Instrument currency pairs are loaded from `DWH_staging.etoro_Trade_GetInstrument` into `Ext_FCPWS_Instrument`
- If `SellCurrencyID = 1` (USD is the sell/quote currency): rate = 1.00 (already in USD)
- If `BuyCurrencyID = 1` (USD is the base currency): IsBuy_1 = 1/Bid, IsBuy_0 = 1/Ask
- If neither currency is USD: find a bridging instrument with USD as base/quote and apply cross-rate
- `ConvertRateIsBuy_1` is for buy-side positions (IsBuy=1); `ConvertRateIsBuy_0` for sell-side

**Diagram**:
```
For each instrument on @DateID:
  If SellCurrencyID = 1 (USD quote):   ConvertRate = 1.00
  If BuyCurrencyID = 1 (USD base):     ConvertRate = 1/Bid (buy) or 1/Ask (sell)
  If no direct USD pair:               ConvertRate via cross-rate through a USD-paired instrument
  Null if no cross-rate found:         COALESCE(..., 1.00) fallback
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `InstrumentID` with a CLUSTERED COLUMNSTORE index. Always include `InstrumentID` in JOIN conditions for co-location with Dim_Instrument. A secondary NONCLUSTERED index on `OccurredDateID` supports date-range lookups. For date-range queries, filter on `OccurredDateID` (integer YYYYMMDD) rather than `OccurredDate` to leverage the NCI.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the table is registered as `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, stored as Delta with a Merge copy strategy (daily refresh). Partition and Z-ORDER columns are resolved during the write-objects deployment phase.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get USD conversion rate for an instrument on a specific date | `WHERE InstrumentID = @id AND OccurredDateID = @dateID AND isvalid = 1` |
| Full price history for an instrument | `WHERE InstrumentID = @id ORDER BY OccurredDate` |
| End-of-day price for all instruments on a date | `WHERE OccurredDateID = @dateID AND isvalid = 1` |
| Instruments with split events on a date | JOIN to `Ext_FCPWS_History_SplitRatio` on InstrumentID and date range |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON f.InstrumentID = di.InstrumentID | Resolve instrument name, symbol, type |
| DWH_dbo.Dim_Date | ON f.OccurredDateID = dd.DateID | Resolve date to year/month/quarter |
| DWH_dbo.Ext_FCPWS_Instrument | ON f.InstrumentID = ei.InstrumentID | Get buy/sell currency pair for the instrument |

### 3.4 Gotchas

- `isvalid = 0` rows (~46% of all rows) represent non-active price records for the day. Most P&L queries should filter `isvalid = 1` to get the effective end-of-day price.
- `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` are NULL for ~1.3M rows (7.5% of the table) where no cross-rate could be computed. Use `ISNULL(..., 1.0)` in downstream calculations or investigate via `Ext_FCPWS_Instrument`.
- The table has 3 distinct `ProviderID` values. Typical analytical queries do not filter on ProviderID, but be aware that multiple providers may contribute prices for the same instrument on the same date.
- `OccurredDateID` is in YYYYMMDD integer format (e.g., 20240113), not a DATE. The NCI is on this column - prefer it for range filters over `OccurredDate`.
- The ETL is date-parameterized (`@dt`). It does NOT do a full reload - it deletes and reloads one date at a time. Gaps can appear if the SP was not run for a date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | int | YES | Price provider identifier. 3 distinct values in production. Indicates which data provider sourced the price candle. Passed through from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 2 | InstrumentID | int | YES | Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. HASH distribution column - include in all JOINs for optimal Synapse performance. 15,416 distinct instruments in production. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 3 | Occurred | datetime | YES | Exact timestamp when the price was recorded. Sub-day precision. Use OccurredDate or OccurredDateID for date-level aggregations. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 4 | OccurredDate | date | YES | Calendar date of the price record. Date portion of Occurred. Use for date joins or display. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 5 | OccurredDateID | int | YES | Date as YYYYMMDD integer (e.g., 20240113). Secondary NCI index key. Use this column for date-range filters to leverage the NONCLUSTERED index. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 6 | isvalid | int | YES | Row validity flag. 1 = active/valid end-of-day price for this instrument on this date. 0 = non-active record (e.g., intraday snapshot or superseded row). Filter isvalid = 1 for end-of-day analytical queries. ~54% of rows are valid. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 7 | AskSpreaded | numeric(36,12) | YES | Spread-adjusted ask (offer) price for the instrument. The ask price with the broker spread applied. Used in P&L calculations for buy-side opening cost. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 8 | BidSpreaded | numeric(36,12) | YES | Spread-adjusted bid price for the instrument. The bid price with the broker spread applied. Used in P&L calculations for sell-side closing proceeds. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 9 | RateLastEx | numeric(36,12) | YES | Last execution rate for the instrument on this date. The price at which the most recent trade was executed. Reference rate for settlement. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 10 | Ask | numeric(36,12) | YES | Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 11 | Bid | numeric(36,12) | YES | Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 12 | UpdateDate | datetime | NO | DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price timestamp - use Occurred for price time. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 13 | ConvertRateIsBuy_1 | numeric(18,4) | YES | Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 14 | ConvertRateIsBuy_0 | numeric(18,4) | YES | Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProviderID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough |
| InstrumentID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough; on split dates from SplitInstHistory variant |
| Occurred | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough |
| OccurredDate | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough |
| OccurredDateID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough |
| isvalid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough |
| AskSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough |
| BidSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough |
| RateLastEx | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough |
| Ask | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough |
| Bid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough |
| UpdateDate | ETL-computed | N/A | GETDATE() at load time |
| ConvertRateIsBuy_1 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |
| ConvertRateIsBuy_0 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |

No upstream wiki available for DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake intermediate staging layer, not documented in DB_Schema wiki).

### 5.2 ETL Pipeline

```
Data Lake (PriceLog/Candles) -> DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
  -> SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)
    -> DWH_dbo.Fact_CurrencyPriceWithSplit [DELETE for @DateID + INSERT]

Split branch (when etoro_History_SplitRatio has rows for @dt):
  DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    -> re-INSERT split-affected instruments
  DWH_staging.etoro_Trade_GetInstrument -> Ext_FCPWS_Instrument
    -> UPDATE ConvertRateIsBuy_1/0 via cross-currency logic
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Daily price candles from Data Lake |
| Split source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory | Split-adjusted historical prices |
| Split calendar | DWH_staging.etoro_History_SplitRatio | Identifies which instruments had splits on @dt |
| Instrument pairs | DWH_staging.etoro_Trade_GetInstrument | BuyCurrencyID/SellCurrencyID for ConvertRate |
| ETL | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Per-date delete+insert + split branch + ConvertRate UPDATE |
| Target | DWH_dbo.Fact_CurrencyPriceWithSplit | Final DWH daily price table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, type, asset class |
| OccurredDateID | DWH_dbo.Dim_Date (via Dim_Date.DateID) | Date dimension (year, month, quarter) |
| InstrumentID | DWH_dbo.Ext_FCPWS_Instrument | Currency pair lookup used during ConvertRate computation |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | self-JOIN | ConvertRate computation reads same table for cross-rate |
| DWH_dbo.Fact_CustomerUnrealized_PnL (probable) | InstrumentID + OccurredDateID | Currency conversion for unrealized P&L (verify via SP_Fact_CustomerUnrealized_PnL_* analysis) |

---

## 7. Sample Queries

### 7.1 End-of-day prices for a set of instruments on a date

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    f.OccurredDate,
    f.Ask,
    f.Bid,
    f.AskSpreaded,
    f.BidSpreaded,
    f.RateLastEx,
    f.ConvertRateIsBuy_1,
    f.ConvertRateIsBuy_0
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.OccurredDateID = 20240113
  AND f.isvalid = 1
ORDER BY di.InstrumentDisplayName;
```

### 7.2 Price history for a single instrument over a date range

```sql
SELECT
    f.OccurredDate,
    f.Ask,
    f.Bid,
    (f.Ask + f.Bid) / 2.0 AS MidPrice,
    f.ConvertRateIsBuy_1,
    f.isvalid
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
WHERE f.InstrumentID = 1     -- replace with target InstrumentID
  AND f.OccurredDateID BETWEEN 20240101 AND 20240131
  AND f.isvalid = 1
ORDER BY f.OccurredDate;
```

### 7.3 Instruments with NULL ConvertRate (USD-conversion gap check)

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    COUNT(*) AS rows_with_null_rate
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.ConvertRateIsBuy_1 IS NULL
  AND f.isvalid = 1
GROUP BY f.InstrumentID, di.InstrumentDisplayName
ORDER BY rows_with_null_rate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Fact_CurrencyPriceWithSplit | Type: Table | Production Source: DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView*


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> Comprehensive instrument dimension table covering all 15,700+ tradeable assets on the eToro platform -- combining core trade pair definitions (buy/sell currencies), display metadata, financial fundamentals, futures configuration, and platform classification into a single analytics-ready reference.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument (view) + Trade.InstrumentMetaData + Trade.ProviderToInstrument + StockInfo + FuturesMetaData |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None (15K rows; suggest Z-ORDER on InstrumentID) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Instrument` is the DWH's master reference for all tradeable instruments on the eToro platform. It extends the foundational trade pair definition from `Trade.Instrument` (which specifies the buy/sell currency pairing for each instrument) with rich analytics metadata: display names and company info from `Trade.InstrumentMetaData`, trading configuration from `Trade.ProviderToInstrument`, financial market data (market cap, ADV, shares outstanding) from the Rankings/StockInfo system, Bloomberg-style asset classification, and futures-specific parameters. The result is a 47-column analytics hub that serves as the primary instrument lookup for fact table enrichment across DWH analytics.

The production source is `etoro.Trade.GetInstrument` (a view on the production etoroDB-REAL server), which combines `Trade.Instrument` with multiple related tables. The Generic Pipeline exports this view daily to `Bronze/etoro/Trade/GetInstrument/` (UC: `trading.bronze_etoro_trade_getinstrument`). The DWH ETL SP (`SP_Dim_Instrument`) then joins this staging data with six additional staging tables to produce the full 47-column Dim_Instrument. Post-load UPDATE statements enrich price-server tracking, asset classification, and financial fundamentals. Source: upstream wiki available at `Trade/Tables/Trade.Instrument.md` (quality 9.1/10).

The ETL is a full TRUNCATE + INSERT + multiple UPDATEs, running daily with a `@dt` date parameter. `UpdateDate` and `InsertDate` are both set to `GETDATE()` at load time and do NOT reflect production modification times. The SP ends by calling `SP_Dim_Instrument_Snapshot @dt` to update the `Dim_Instrument_Snapshot` table (daily snapshot of futures configuration columns). As of 2026-03-19, the table contains 15,707 rows: 82% Stocks, 8% ETFs, 4% Crypto, 3% Commodities, 2% Indices, 1% Currencies.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of assets from `Dictionary.Currency`/`Dim_Currency`. The pairing determines how prices are quoted, how positions are settled, and how P&L is converted to account currency.

**Columns Involved**: `BuyCurrencyID`, `SellCurrencyID`, `BuyCurrency`, `SellCurrency`

**Rules**:
- For **forex pairs**: BuyCurrencyID is the base currency, SellCurrencyID is the quote currency (e.g., InstrumentID=1: EUR/USD = BuyCurrencyID=2/EUR, SellCurrencyID=1/USD)
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the asset's own InstrumentID in Dim_Currency, and SellCurrencyID is the denomination currency (USD for US stocks, EUR for European stocks, GBX for UK pence-quoted stocks)
- `BuyCurrency` and `SellCurrency` are DWH-added text abbreviations (denormalized from Dictionary.Currency via SP JOIN)
- InstrumentID=0: system/ETL null-sentinel record with all zero/NA values

**Diagram**:
```
Forex:  ID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:  ID=1001 -> Buy=AAPL(1001) / Sell=USD(1) = Apple in USD
EuroSt: ID=1203 -> Buy=Bayer(1203) / Sell=EUR(2) = Bayer AG in EUR
Crypto: ID=XXXX -> Buy=BTC(?) / Sell=USD(1)     = Bitcoin in USD
```

### 2.2 InstrumentType and IsMajor Dual Representation

**What**: Two DWH-specific computed/reformatted columns encode enum values as human-readable text.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`, `IsMajorID`, `IsMajor`

**Rules**:
- `InstrumentType` is CASE-computed in the SP from `InstrumentTypeID`: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Note: type IDs 3, 7, 8, 9 are not defined (gap exists for historical reasons)
- `IsMajorID` = production `IsMajor` bit value (0 or 1). `IsMajor` = text version ('Yes' or 'No'). Analysts should use `IsMajorID` for filtering, `IsMajor` for display
- IsMajor=Yes: 6,963 instruments (major forex + popular stocks/ETFs). IsMajor=No: 8,743 instruments
- DWHInstrumentID always equals InstrumentID (redundant copy, same as the DWHXxxID pattern across all DWH Dim tables)
- StatusID is hardcoded to 1 for all real rows (ETL artifact; NULL only for ID=0 placeholder)

### 2.3 IsFuture Derivation and Futures Columns

**What**: Futures instruments are identified by membership in InstrumentGroups(GroupID=25), and carry additional configuration columns not present for non-futures instruments.

**Columns Involved**: `IsFuture`, `Multiplier`, `ProviderMarginPerLot`, `eToroMarginPerLot`, `SettlementTime`

**Rules**:
- `IsFuture = 1` when the instrument is a member of `DWH_staging.etoro_Trade_InstrumentGroups` with `GroupID=25`. Computed via CASE in SP_Dim_Instrument.
- `Multiplier`: contract size multiplier from `Trade.FuturesMetaData`. NULL for non-futures.
- `ProviderMarginPerLot`: initial margin requirement from the liquidity provider, from `Trade.FuturesInstrumentsInitialMarginByProviderMapping`. NULL for non-futures.
- `eToroMarginPerLot`: eToro's own margin per lot (in asset currency) from `Trade.ProviderToInstrument.InitialMarginInAssetCurrency`. NULL for non-futures.
- `SettlementTime`: daily/weekly settlement time from `Trade.ProviderToInstrument`, formatted as TIME(0) by the SP.

### 2.4 Financial Fundamentals (Post-Load Updates)

**What**: Market data columns are populated via post-load UPDATE statements joining to the Rankings/StockInfo data lake.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `AssetClass`, `IndustryGroup`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- `ADV_Last3Months`: Average Daily Volume over last 3 months (MetadataID=8557). NULL for non-stock instruments or instruments without Rankings data.
- `MKTcap`: Market Capitalization in USD (MetadataID=8735 for stocks, fallback to MetadataID=9315 CryptoMarketCap for crypto). NULL if not covered by Rankings.
- `SharesOutStanding`: Total shares outstanding in units (MetadataID=8444). Stocks only.
- `AssetClass` / `IndustryGroup`: Bloomberg-style classification from `Ext_Dim_Instrument_Classification_Static`. More granular than InstrumentType.
- `PlatformSector` / `PlatformIndustry`: eToro platform taxonomy (MetadataID=8436/8280), may differ from Bloomberg AssetClass/IndustryGroup.
- `ReceivedOnPriceServer`: First date/time an instrument was seen on the price server. POST-LOAD from `Ext_Dim_Instrument_ReceivedOnPriceServerStatic`. NULL for instruments not yet priced.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (all 15,707 rows available on every compute node) with a CLUSTERED INDEX on `InstrumentID`. Since virtually every fact table JOINs to `Dim_Instrument` on `InstrumentID`, replication eliminates shuffle overhead. The clustered index supports range scans and direct lookups efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export is pending write-objects configuration. At 15,707 rows, partitioning is not beneficial -- suggest Z-ORDER on `InstrumentID` for join performance, and `InstrumentTypeID` for type-filtered analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get instrument name and type by ID | `JOIN Dim_Instrument ON InstrumentID; SELECT Name, InstrumentType` |
| Find all major instruments by asset class | `WHERE IsMajorID = 1 AND AssetClass = 'Technology'` |
| Find instruments eligible for long/short | `WHERE AllowBuy = 1 AND AllowSell = 1 AND Tradable = 1` |
| Get market cap for a position | `JOIN Dim_Instrument ON InstrumentID; SELECT MKTcap` |
| Find futures instruments with settlement | `WHERE IsFuture = 1 AND SettlementTime IS NOT NULL` |
| Find US stocks with ISIN | `WHERE InstrumentTypeID = 5 AND ISINCountryCode = 'US' AND ISINCode IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.BuyCurrencyID` | Resolve buy-side currency/asset details |
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.SellCurrencyID` | Resolve sell-side denomination currency |
| DWH_dbo.Dim_HistorySplitRatio | `ON InstrumentID + date range` | Get split adjustment ratios for historical price normalization |
| DWH_dbo.Dim_Instrument_Snapshot | `ON InstrumentID + DateID` | Get point-in-time futures config for historical analysis |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `ON InstrumentID` | Join to price history |

### 3.4 Gotchas

- **InstrumentID=0 is the null-sentinel placeholder**: All fields are 0/NA/NULL. Always filter `WHERE InstrumentID > 0` for analytics.
- **DWHInstrumentID always equals InstrumentID**: This is a redundant copy column -- do not use it as a distinct identifier.
- **StatusID is hardcoded 1**: This column conveys no information (all rows = 1 except the ID=0 placeholder). Do not filter on it.
- **UpdateDate and InsertDate are both ETL timestamps**: Neither reflects when the instrument was created or last modified in production. They reflect the last ETL run (daily, ~midnight).
- **InstrumentType gaps**: TypeIDs 3, 7, 8, 9 are not used. The CASE expression returns 'Other' for any unmapped typeID.
- **IsMajorID vs IsMajor**: Use `IsMajorID` (int 0/1) for WHERE/GROUP BY. Use `IsMajor` ('Yes'/'No') for display only.
- **NULL fundamentals**: ADV_Last3Months, MKTcap, SharesOutStanding are NULL for non-stock instruments and for instruments not covered by Rankings data. Always use LEFT JOIN or ISNULL() when using these for aggregations.
- **AllowBuy/AllowSell = 0 means trading disabled**: Instruments with AllowBuy=0 cannot be opened in the specified direction. This changes dynamically in production but is updated daily in DWH.
- **Dim_Instrument vs Dim_Currency**: Dim_Currency (from Dictionary.Currency) is the master asset registry with type and currency info. Dim_Instrument (from Trade.Instrument) is the trading pair definition with full analytics enrichment. For basic instrument lookups, Dim_Currency suffices. For trading parameters, fundamentals, or pair analysis, use Dim_Instrument.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, Trade.Instrument)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Instrument)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 2 | InstrumentTypeID | int | NO | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%. (Tier 2 -- SP_Dim_Instrument) |
| 3 | InstrumentType | varchar(50) | NO | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 -- SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Always equal to InstrumentID -- redundant copy following the DWH DWH{X}ID pattern. Use InstrumentID for all JOINs. (Tier 2 -- SP_Dim_Instrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all real rows by SP_Dim_Instrument. NULL only for ID=0 placeholder. Conveys no business information. (Tier 2 -- SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks). (Tier 1 -- upstream wiki, Trade.Instrument) |
| 8 | SellCurrencyID | int | NO | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 9 | BuyCurrency | varchar(50) | NO | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 10 | SellCurrency | varchar(50) | NO | Text abbreviation of SellCurrencyID -- denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 11 | TradeRange | int | NO | Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 14 | IsMajorID | int | NO | Integer representation of the production IsMajor flag (0 or 1). 1=major instrument (6,963 instruments -- all major forex pairs and many popular stocks). 0=non-major (8,743 instruments). Renamed from production IsMajor to distinguish from the text version. Use for filtering. (Tier 2 -- SP_Dim_Instrument) |
| 15 | IsMajor | varchar(3) | NO | Text version of IsMajorID -- DWH CASE computed: IsMajorID=1->'Yes', 0->'No'. Use for display. Affects spread calculations and regulatory leverage caps (ESMA allows higher leverage for major forex). (Tier 2 -- SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument on each daily reload. Does NOT reflect production modification date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument, same as UpdateDate. Both reflect the daily load time. Does NOT reflect production insertion date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry classification string from Trade.InstrumentMetaData. Text description (e.g., 'Internet', 'Software'). Similar to but may differ from IndustryGroup (Bloomberg). NULL for non-stock instruments or instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Free-text company description from Trade.InstrumentMetaData. May contain multi-sentence business descriptions of the company. NULL for non-company instruments (forex, commodities, indices). (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number -- 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country code prefix from the ISIN (first 2 characters). Indicates the country of registration (e.g., US, DE, GB). NULL when ISINCode is NULL. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 24 | Tradable | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 25 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. NULL for ID=0 placeholder and some instruments without formal ticker. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 26 | ReceivedOnPriceServer | datetime | YES | First timestamp when the instrument was observed on the price server (from Ext_Dim_Instrument_ReceivedOnPriceServerStatic). Set once and never updated (static history). NULL for instruments not yet priced or newly added instruments that have not yet appeared in price feeds. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of bonus credit that can be applied to trading this instrument, from Trade.ProviderToInstrument. Lower values restrict bonus usage for high-risk/volatile instruments. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Committee on Uniform Securities Identification Procedures number -- 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 30 | Precision | int | YES | Decimal precision for price display and trading (number of decimal places), from Trade.ProviderToInstrument. Determines how many decimals are shown in the UI and used in calculations. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 31 | AllowBuy | int | YES | Flag indicating if long (buy) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Instruments may be buy-disabled due to regulatory restrictions, risk management, or market conditions. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 32 | AllowSell | int | YES | Flag indicating if short (sell) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Many regulated markets prohibit short selling for retail clients. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Bloomberg-style asset class classification from Ext_Dim_Instrument_Classification_Static (e.g., Technology, Consumer Services, Finance). More granular than InstrumentType. NULL for non-stock instruments or instruments not in the classification static table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 34 | IndustryGroup | nvarchar(400) | YES | Bloomberg-style industry group within AssetClass (e.g., Computers, Internet, Banks). Sub-classification of AssetClass. NULL for non-stock instruments or instruments not in the classification table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average Daily Trading Volume over the trailing 3 months (TTM), from Rankings StockInfo MetadataID=8557. In shares/units. NULL for non-stock instruments or instruments without Rankings coverage. Example: Apple ~48M shares/day. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization in USD from Rankings StockInfo (MetadataID=8735 for equities; fallback MetadataID=9315 CryptoMarketCap for crypto). NULL for forex, commodities, and indices. Example: Apple ~3.8T USD. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Total shares outstanding in units from Rankings StockInfo MetadataID=8444. Annual figure. NULL for non-equity instruments. Example: Apple ~14.7B shares. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | Flag (0/1) indicating if the instrument is visible only to internal eToro users (not shown to retail customers). Cast from bit. Used for instruments under development, testing, or institutional-only. NULL for ID=0 placeholder. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 39 | PlatformSector | varchar(max) | YES | eToro platform sector classification from Rankings StockInfo MetadataID=8436. May differ from Bloomberg AssetClass. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | eToro platform industry classification from Rankings StockInfo MetadataID=8280. More granular than PlatformSector. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 41 | IsFuture | int | YES | Derived flag indicating if the instrument is a futures contract: 1=futures, 0=not futures. Computed in SP as CASE WHEN InstrumentID IN (SELECT InstrumentID FROM InstrumentGroups WHERE GroupID=25) THEN 1 ELSE 0. NULL for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Futures contract size multiplier from Trade.FuturesMetaData. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_FuturesMetaData) |
| 43 | ProviderID | int | YES | Liquidity provider identifier from Trade.ProviderToInstrument. Identifies which external market maker or broker provides pricing/liquidity for this instrument. NULL for instruments without a provider mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Initial margin requirement per lot in the provider's terms, from Trade.FuturesInstrumentsInitialMarginByProviderMapping. Primarily relevant for futures instruments. NULL for non-futures or instruments without provider margin data. (Tier 3 -- live data, FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | eToro's own margin requirement per lot in asset currency (InitialMarginInAssetCurrency from Trade.ProviderToInstrument). eToro's internal margin may differ from the provider's margin. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Daily or periodic settlement time for the instrument, from Trade.ProviderToInstrument, formatted as TIME via SP DATEPART conversion. Primarily relevant for futures and CFD instruments with defined settlement windows. NULL for instruments without settlement time defined. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders. (Tier 1 -- upstream wiki, Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | etoro.Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE to text label |
| Name | etoro.Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | etoro.Trade.GetInstrument | InstrumentID | rename (= InstrumentID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| BuyCurrencyID | etoro.Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | etoro.Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via BuyCurrencyID) |
| SellCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via SellCurrencyID) |
| TradeRange | etoro.Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | etoro.Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | etoro.Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | etoro.Trade.GetInstrument | IsMajor | rename (bit to int) |
| IsMajor | etoro.Trade.GetInstrument | IsMajor | CASE to 'Yes'/'No' text |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched |
| Industry | etoro.Trade.InstrumentMetaData | Industry | join-enriched |
| CompanyInfo | etoro.Trade.InstrumentMetaData | CompanyInfo | join-enriched |
| Exchange | etoro.Trade.InstrumentMetaData | Exchange | join-enriched |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | join-enriched |
| ISINCountryCode | etoro.Trade.InstrumentMetaData | ISINCountryCode | join-enriched |
| Tradable | etoro.Trade.GetInstrument | Tradable | CAST to int |
| Symbol | etoro.Trade.GetInstrument | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog (via PriceLog_History_CurrencyPrice_Active) | ReceivedOnPriceServer | join-enriched, post-load UPDATE |
| BonusCreditUsePercent | etoro.Trade.ProviderToInstrument | BonusCreditUsePercent | join-enriched |
| SymbolFull | etoro.Trade.InstrumentMetaData | SymbolFull | join-enriched |
| CUSIP | etoro.Trade.InstrumentCusip | CUSIP | join-enriched |
| Precision | etoro.Trade.ProviderToInstrument | Precision | join-enriched |
| AllowBuy | etoro.Trade.GetInstrument | AllowBuy | CAST to int |
| AllowSell | etoro.Trade.GetInstrument | AllowSell | CAST to int |
| AssetClass | External classification static | AssetClass | join-enriched, post-load UPDATE |
| IndustryGroup | External classification static | IndustryGroup | join-enriched, post-load UPDATE |
| ADV_Last3Months | Rankings.StockInfo (MetadataID=8557) | NumVal | join-enriched, post-load UPDATE |
| MKTcap | Rankings.StockInfo (MetadataID=8735/9315) | NumVal | join-enriched with fallback, post-load UPDATE |
| SharesOutStanding | Rankings.StockInfo (MetadataID=8444) | NumVal | join-enriched, post-load UPDATE |
| VisibleInternallyOnly | etoro.Trade.GetInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo (MetadataID=8436) | StrVal | join-enriched, post-load UPDATE |
| PlatformIndustry | Rankings.StockInfo (MetadataID=8280) | StrVal | join-enriched, post-load UPDATE |
| IsFuture | etoro.Trade.InstrumentGroups (GroupID=25) | InstrumentID membership | CASE derived, post-load |
| Multiplier | etoro.Trade.FuturesMetaData | Multiplier | join-enriched |
| ProviderID | etoro.Trade.ProviderToInstrument | ProviderID | join-enriched |
| ProviderMarginPerLot | etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | join-enriched |
| eToroMarginPerLot | etoro.Trade.ProviderToInstrument | InitialMarginInAssetCurrency | join-enriched |
| SettlementTime | etoro.Trade.ProviderToInstrument | SettlementTime | cast/convert (TIME formatting) |
| OperationMode | etoro.Trade.Instrument | OperationMode | join-enriched (via etoro_Trade_Instrument) |

Upstream wiki: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md` (quality 9.1/10)

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, etoroDB-REAL)
  -> Generic Pipeline (Override, 1440min, Bronze/etoro/Trade/GetInstrument/)
  -> trading.bronze_etoro_trade_getinstrument (UC Bronze)
  -> DWH_staging.etoro_Trade_GetInstrument
  +-> DWH_staging.etoro_Dictionary_Currency (buy/sell currency names)
  +-> DWH_staging.etoro_Trade_InstrumentMetaData (display name, ISIN, exchange, company)
  +-> DWH_staging.etoro_Trade_ProviderToInstrument (provider config, margins, precision)
  +-> DWH_staging.etoro_Trade_InstrumentCusip (CUSIP)
  +-> DWH_staging.etoro_Trade_FuturesMetaData (multiplier)
  +-> DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping
  +-> DWH_staging.etoro_Trade_Instrument (OperationMode, AllowBuy/Sell, Tradable)
  -> SP_Dim_Instrument (TRUNCATE + JOIN INSERT + multiple post-load UPDATEs, daily)
  -> DWH_dbo.Dim_Instrument (15,707 rows)
  -- SP also call

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `Dealing_dbo.Dealing_Execution_Slippage_AssetType` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Execution_Slippage_AssetType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_AssetType.md`

# Dealing_Execution_Slippage_AssetType

## 1. Business Meaning

Daily execution slippage aggregated by asset type and hedging mode. Produced by `SP_Execution_Slippage` alongside `Dealing_Execution_Slippage` — this table collapses individual trade-level slippage into 12 rows per day (6 instrument types × 2 hedging modes: CBH / HBC), giving a high-level view of where eToro earns or loses on execution quality by market segment.

> **PIPELINE STALE**: Last populated **2024-10-03** (5+ months stale as of 2026-03-21). Same root cause as `Dealing_Execution_Slippage`: the Kusto LP price feed (`CopyFromLake.PricesFromProvider_MarketCurrencyPrice`) stopped supplying data. Use `Dealing_Execution_Slippage_AssetType_RequestTime` for current slippage-by-asset-type data (last updated 2025-01-11).

**Hedging modes present:**
- `CBH` — Clearing Broker Hedging: STP execution routed to Apex or BNY Mellon.
- `HBC` — Hedge By Company: eToro internalizes the position and hedges directly.

**Instrument types:** Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF.

**Rows per day:** ~12 (one per InstrumentType × HedgingMode combination when activity exists).

**Slippage sign convention:** Positive = eToro gains (LP executed at better rate than eToro's price). Negative = eToro cost.

## 2. Business Logic

### 2.1 Aggregation from Trade-Level

Populated from `#AssetType` temp table within `SP_Execution_Slippage`:

```sql
SUM(
  (CASE WHEN IsBuy = 1 THEN 1.0 ELSE -1.0 END)
  * (eToro_Price - ExecutionRate)
  * Units * FX_Rate
) AS SlippageInDollar
GROUP BY InstrumentType, HedgingMode
```

Where:
- `eToro_Price` = eToro's quoted price at the time the hedge order was sent (Ask for buys, Bid for sells), from `CopyFromLake.PriceLog_History_CurrencyPrice` matched by `RateIDAtSent`
- `ExecutionRate` = actual LP fill rate from `Dealing_staging.Etoro_Hedge_ExecutionLog`
- `FX_Rate` = USD conversion factor from `DWH_dbo.Fact_CurrencyPriceWithSplit`

### 2.2 Kusto Dependency

Unlike the _RequestTime variant, this table's pipeline requires a valid Kusto price record per trade (via `CROSS APPLY` on `CopyFromLake.PricesFromProvider_MarketCurrencyPrice`). If the Kusto feed is empty, `#KustoPrices` has no rows, `#Total` is empty, and therefore `#AssetType` is empty → no data written.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Cross-node broadcast for JOINs is negligible given the tiny row count (~12/day).

**Typical usage:**
```sql
-- Daily slippage by asset class and hedge mode
SELECT Date, InstrumentType, HedgingMode,
       SlippageInDollar,
       SUM(SlippageInDollar) OVER (PARTITION BY InstrumentType ORDER BY Date ROWS 29 PRECEDING) AS rolling_30d
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
WHERE Date >= '2024-01-01'
ORDER BY Date DESC, SlippageInDollar ASC
```

**Gotcha — stale data:** Any dashboard using this table will show a 5-month gap after Oct 2024. Prefer `Dealing_Execution_Slippage_AssetType_RequestTime` as the active equivalent.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC) for which slippage is aggregated. Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. (Tier 2 — SP_Execution_Slippage) |
| InstrumentType | varchar(50) | Asset class label from `DWH_dbo.Dim_Instrument.InstrumentType`. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Execution_Slippage via Dim_Instrument) |
| HedgingMode | varchar(10) | Routing mode for the execution batch. CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company (eToro internal). Determined by presence in `Dealing_staging.Etoro_Hedge_HBCOrderLog`. (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | money | Sum of USD slippage across all trades in the (Date, InstrumentType, HedgingMode) bucket. Formula: `SUM((IsBuy=1?1:-1)×(eToro_Price−ExecutionRate)×Units×FX_Rate)`. Positive = eToro gains; negative = eToro cost. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). Not a business date. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Trade execution records (ExecutionRate, Units, IsBuy, SendTime) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro quoted price matched by RateIDAtSent |
| `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` | Kusto LP market price — REQUIRED for this pipeline (stale since Oct 2024) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType lookup |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode: CBH vs HBC |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_AssetType`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage` | Parent table; this is its aggregation by InstrumentType + HedgingMode |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` | Parallel table using RequestTime price reference instead of SendTime Kusto price — ACTIVE |
| `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` | Row-level RequestTime variant; source of the _RequestTime aggregation |

## 7. Sample Queries

```sql
-- Compare CBH vs HBC slippage by asset class for a month
SELECT
    InstrumentType,
    HedgingMode,
    SUM(SlippageInDollar) AS total_slippage_usd,
    COUNT(*) AS trading_days
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
WHERE Date BETWEEN '2024-09-01' AND '2024-09-30'
GROUP BY InstrumentType, HedgingMode
ORDER BY total_slippage_usd DESC

-- Rolling 30-day net slippage by asset type
SELECT Date, InstrumentType,
    SUM(SlippageInDollar) OVER (
        PARTITION BY InstrumentType ORDER BY Date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType
ORDER BY Date DESC, InstrumentType
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.


### Upstream `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Execution_Slippage_RequestTime`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_RequestTime.md`

# Dealing_Execution_Slippage_RequestTime

## 1. Business Meaning

Row-level daily execution slippage using the **RequestTime price** as the eToro reference point. For each (InstrumentID × RequestTime × ExecutionTime × IsBuy × ExecutionRate × HedgingMode) combination, records the eToro price at the moment the hedge order was received (`RequestTime`) versus the LP's actual fill rate (`ExecutionRate`), along with USD-denominated P&L impact.

This is the most granular and actively-maintained slippage table in the batch — 29.6M rows across ~2 years, covering 7,477 instruments. It does **not** require the Kusto LP market feed (unlike the non-suffixed `Dealing_Execution_Slippage`), so it continues populating when that feed is broken.

**Last updated:** 2025-01-11 (~2.5 months stale as of 2026-03-21). SP scheduling issue suspected.

**Slippage sign convention:**
- `Slippage` (points) positive = LP charged more than eToro expected = eToro cost.
- `SlippageInDollar` positive = eToro gained (LP rate better than eToro's RequestTime price).

**"RequestTime" definition:** The timestamp of the most recent eToro price event in `CopyFromLake.PriceLog_History_CurrencyPrice` with `Occurred <= ExecutionTime`. This is the last known eToro price just before LP execution.

## 2. Business Logic

### 2.1 Price Matching

For each execution record, the SP uses a `CROSS APPLY` to find the most recent eToro price:
```sql
CROSS APPLY (
  SELECT TOP 1 Occurred, Bid, Ask
  FROM CopyFromLake.PriceLog_History_CurrencyPrice E
  WHERE E.partition_date = @Date
    AND E.InstrumentID = D.InstrumentID
    AND E.Occurred <= D.ExecutionTime
  ORDER BY Occurred DESC
) A
```

`eToro_RequestTimePrice` = `Ask` (IsBuy=1) or `Bid` (IsBuy=0).

### 2.2 Slippage Formulas

```
Slippage         = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_RequestTimePrice)
SlippageInDollar = (IsBuy=1 ? +1 : -1) × (eToro_RequestTimePrice − ExecutionRate) × Units × FX_Rate
Slippage_Percent = (IsBuy=1 ? +1 : -1) × (ExecutionRate − eToro_RequestTimePrice) / eToro_RequestTimePrice
```

Note: `Slippage` and `SlippageInDollar` have **opposite signs** — Slippage (points) positive means eToro cost; SlippageInDollar positive means eToro gain. This is intentional: both are "from eToro's perspective."

### 2.3 USD Conversion

FX rate is computed from `DWH_dbo.Fact_CurrencyPriceWithSplit`:
- Instrument denominated in USD (`SellCurrencyID=1`): FX_Rate = 1
- Instrument with USD as buy currency: FX_Rate = 1 / (Bid or Ask of the instrument)
- GBX instruments: FX_Rate = instrument FX / 100 (pence conversion)
- Cross-currency: FX_Rate = 1 / (cross rate to USD) or cross rate from USD

### 2.4 Aggregation

Multiple raw execution log entries with the same (InstrumentID, RequestTime, ExecutionTime, IsBuy, ExecutionRate, HedgingMode, FX_Rate) are summed into one row:
- `Units` = SUM(Units)
- `ProviderAmount_USD` = SUM(Units × ExecutionRate × FX_Rate)
- `eToro_RequestTimeAmountUSD` = SUM(Units × eToro_RequestTimePrice × FX_Rate)
- `NumberofTransaction` = COUNT(*)

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 29.6M rows. Full scans will be heavy — filter by Date always.

**RequestTime ≠ SendTime:** RequestTime here is the eToro price event time, not the hedge order send time. For execution latency analysis use `DATEDIFF(ms, RequestTime, ExecutionTime)`.

**Typical join:** To get asset type, JOIN to `DWH_dbo.Dim_Instrument ON InstrumentID`.

```sql
-- Summarize daily slippage by HedgingMode for a week
SELECT Date, HedgingMode,
       SUM(SlippageInDollar) AS net_slippage_usd,
       SUM(Units) AS total_units,
       COUNT(*) AS execution_groups
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY Date, HedgingMode
ORDER BY Date DESC

-- Instruments with worst slippage in a given month
SELECT TOP 20
    rt.InstrumentID, di.InstrumentName,
    SUM(rt.SlippageInDollar) AS net_slippage_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime rt
JOIN DWH_dbo.Dim_Instrument di ON rt.InstrumentID = di.InstrumentID
WHERE rt.Date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY rt.InstrumentID, di.InstrumentName
ORDER BY net_slippage_usd ASC
```

**Performance:** ROUND_ROBIN distribution means no skew but full cross-node scan. For heavy aggregations, consider materializing into a temp table first or using the aggregate `_AssetType_RequestTime` table.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC). Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. Partition filter — always include in WHERE. (Tier 2 — SP_Execution_Slippage) |
| InstrumentID | int | FK to `DWH_dbo.Dim_Instrument`. Identifies the hedged instrument. (Tier 1 — upstream wiki, Trade.Instrument) |
| RequestTime | datetime | Timestamp of the last eToro price event (Occurred) in `PriceLog_History_CurrencyPrice` with `Occurred ≤ ExecutionTime`. Millisecond precision. (Tier 2 — SP_Execution_Slippage) |
| ExecutionTime | datetime | Actual LP fill timestamp from `Etoro_Hedge_ExecutionLog`. Millisecond precision. (Tier 2 — SP_Execution_Slippage) |
| IsBuy | bit | 1 = buy (long) position, 0 = sell (short). Determines slippage sign direction. (Tier 2 — SP_Execution_Slippage) |
| Units | decimal(16,6) | Total units traded in this execution group. `SUM(Units)` from raw execution records. (Tier 2 — SP_Execution_Slippage) |
| ExecutionRate | decimal(16,6) | LP fill rate in instrument currency. (Tier 2 — SP_Execution_Slippage) |
| eToro_RequestTimePrice | decimal(16,6) | eToro's last quoted price just before LP execution. Ask for buys, Bid for sells. Source: `PriceLog_History_CurrencyPrice`. (Tier 2 — SP_Execution_Slippage) |
| ProviderAmount_USD | decimal(16,6) | Total LP cost in USD: `SUM(Units × ExecutionRate × FX_Rate)`. (Tier 2 — SP_Execution_Slippage) |
| eToro_RequestTimeAmountUSD | decimal(16,6) | eToro expected cost at RequestTime in USD: `SUM(Units × eToro_RequestTimePrice × FX_Rate)`. (Tier 2 — SP_Execution_Slippage) |
| FX_Rate | decimal(16,6) | FX conversion factor to USD. 1.0 for USD-denominated instruments. From `DWH_dbo.Fact_CurrencyPriceWithSplit`. (Tier 2 — SP_Execution_Slippage) |
| Slippage | decimal(16,6) | Price-unit slippage: `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)`. Positive = eToro cost (LP worse than expected). (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | decimal(16,6) | USD slippage: `(IsBuy=1?+1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate`. Positive = eToro gains. Note: **opposite sign** to `Slippage`. (Tier 2 — SP_Execution_Slippage) |
| Slippage_Percent | decimal(16,6) | Relative slippage: `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)/eToro_RequestTimePrice`. Same sign convention as `Slippage`. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). (Tier 2 — SP_Execution_Slippage) |
| HedgingMode | varchar(10) | CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. (Tier 2 — SP_Execution_Slippage) |
| NumberofTransaction | int | Count of raw `Etoro_Hedge_ExecutionLog` records summed into this row. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Execution records (ExecutionRate, Units, IsBuy, ExecutionTime, HedgeOrderID) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro price at RequestTime (CROSS APPLY: latest Occurred ≤ ExecutionTime) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType, CCY1, BuyCurrencyID, SellCurrencyID |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode lookup |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_RequestTime`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage` | SendTime counterpart; stale since Oct 2024; uses Kusto LP price instead |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` | Aggregation of this table by InstrumentType + HedgingMode |
| `DWH_dbo.Dim_Instrument` | FK on InstrumentID; join for InstrumentName, AssetTypeID |

## 7. Sample Queries

```sql
-- Execution latency distribution (ms) by HedgingMode
SELECT HedgingMode,
    AVG(DATEDIFF(ms, RequestTime, ExecutionTime)) AS avg_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY DATEDIFF(ms, RequestTime, ExecutionTime))
        OVER (PARTITION BY HedgingMode) AS p95_latency_ms
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date = '2025-01-10'
GROUP BY HedgingMode

-- Zero-slippage rate (perfect fill rate)
SELECT Date,
    SUM(CASE WHEN Slippage = 0 THEN NumberofTransaction ELSE 0 END) * 1.0
        / SUM(NumberofTransaction) AS zero_slippage_pct
FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY Date
ORDER BY Date
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.


### Upstream `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_AssetType_RequestTime.md`

# Dealing_Execution_Slippage_AssetType_RequestTime

## 1. Business Meaning

Daily execution slippage aggregated by asset type and hedging mode, using the **RequestTime price** as the reference point (rather than the SendTime Kusto LP price used by the non-suffixed variant). Produced by `SP_Execution_Slippage` as the actively-maintained counterpart to the stale `Dealing_Execution_Slippage_AssetType`.

The key difference: slippage is measured as `ExecutionRate vs. the eToro price at the moment the order was received` (i.e., the last known eToro price snapshot before ExecutionTime), sourced purely from `CopyFromLake.PriceLog_History_CurrencyPrice`. Because this calculation does not require the Kusto LP market feed, it remains operational when the Kusto pipeline is broken.

**Last updated:** 2025-01-11 (active, but ~2.5 months stale as of 2026-03-21 — likely a broader SP scheduling gap).

**Rows per day:** ~12 (6 instrument types × 2 hedging modes: CBH / HBC).

**Slippage sign convention:** Positive = eToro gains (LP executed at better rate than eToro's price). Negative = eToro cost.

## 2. Business Logic

### 2.1 RequestTime Price Reference

Compared to the SendTime variant:

| Variant | Price Reference | Source |
|---------|-----------------|--------|
| `Dealing_Execution_Slippage_AssetType` | Kusto LP market price just before ExecutionTime | `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (STALE) |
| **`Dealing_Execution_Slippage_AssetType_RequestTime`** | **eToro price just before ExecutionTime (from PriceLog)** | `CopyFromLake.PriceLog_History_CurrencyPrice` (ACTIVE) |

### 2.2 Aggregation Formula

```sql
SUM(
  (CASE WHEN IsBuy = 1 THEN 1.0 ELSE -1.0 END)
  * (eToro_RequestTimePrice - ExecutionRate)
  * Units * FX_Rate
) AS SlippageInDollar
GROUP BY InstrumentType, HedgingMode
```

Where `eToro_RequestTimePrice` is the Ask (buy) or Bid (sell) from the PriceLog event with `Occurred <= ExecutionTime` (CROSS APPLY TOP 1 ORDER BY Occurred DESC).

### 2.3 Interpretation

Because the reference price is the eToro spread price (not the raw LP price), this measures how much eToro gained/lost relative to the price it showed to its own hedging system at execution time. This is distinct from pure LP-vs-execution comparison.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN. Negligible data volume (~12 rows/day, ~2693 total rows).

**Prefer this over the non-suffixed variant** for any analysis after Oct 2024, as `Dealing_Execution_Slippage_AssetType` has been stale since then.

```sql
-- Active slippage trend by asset class (last 90 days of available data)
SELECT Date, InstrumentType, HedgingMode, SlippageInDollar
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
WHERE Date >= DATEADD(DAY, -90, '2025-01-11')
ORDER BY Date DESC, SlippageInDollar ASC
```

**Note:** Both AssetType tables stopped updating at similar times (Oct 2024 vs Jan 2025). The Jan 2025 cutoff likely reflects the SP run schedule rather than a different feed issue.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC) for which slippage is aggregated. Equals the ExecutionTime date from `Etoro_Hedge_ExecutionLog`. (Tier 2 — SP_Execution_Slippage) |
| InstrumentType | varchar(40) | Asset class label from `DWH_dbo.Dim_Instrument.InstrumentType`. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Execution_Slippage via Dim_Instrument) |
| HedgingMode | varchar(10) | Routing mode. CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. Determined by presence in `Dealing_staging.Etoro_Hedge_HBCOrderLog`. (Tier 2 — SP_Execution_Slippage) |
| SlippageInDollar | money | Sum of USD slippage using eToro's RequestTime price as reference. Formula: `SUM((IsBuy=1?1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate)`. Positive = eToro gains; negative = eToro cost. (Tier 2 — SP_Execution_Slippage) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE() at SP run time). Not a business date. (Tier 2 — SP_Execution_Slippage) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | Trade execution records (ExecutionRate, Units, IsBuy) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro price at RequestTime (CROSS APPLY: last price with Occurred ≤ ExecutionTime) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Daily FX rates for USD conversion |
| `DWH_dbo.Dim_Instrument` | InstrumentType lookup |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode lookup |

**ETL:** `Dealing_dbo.SP_Execution_Slippage` → `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime`

Note: No Kusto feed dependency — this is why this variant outlived the SendTime tables.

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType` | SendTime variant; stale since Oct 2024; same structure |
| `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` | Row-level source data; this table is its aggregation by InstrumentType + HedgingMode |
| `Dealing_dbo.Dealing_Execution_Slippage` | SendTime row-level source; stale counterpart |

## 7. Sample Queries

```sql
-- Net slippage by asset class (latest available month)
SELECT InstrumentType, HedgingMode,
    SUM(SlippageInDollar) AS total_usd,
    AVG(SlippageInDollar) AS avg_daily_usd
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
WHERE Date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY InstrumentType, HedgingMode
ORDER BY total_usd DESC

-- CBH vs HBC net comparison across all dates
SELECT HedgingMode,
    SUM(SlippageInDollar) AS total_usd,
    MIN(Date) AS first_date,
    MAX(Date) AS last_date
FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
GROUP BY HedgingMode
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_Execution_Slippage`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Execution_Slippage.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_Execution_Slippage] @Date [DATE] AS 
BEGIN

/******************************************************************************************************************************

Author: Adar Cahlon
Date: 02.08.21
Description: Calculate daily slippage between SendTime Vs ExecutionTime and between RequestTime Vs ExecutionTime

 
**************************
** Change History
**************************
Date                   	Author      	SR                Description 
----                   	----------     -----           ----------------------------------
04-08-2021              Adar                           Change the slippage calculation
04-11-2021              Adar                           Separate the trades to HBC/ CBH and add a summary table by Asset Type
09-11-2021              Adar                           Add the slippage between RequestTime Vs ExecutionTime
21-11-2021              Adar                           Change the rate we are taking- for buy positions Ask, for sell positions Bid
20-06-2022              Adar                           Add 4 columns: Kusto- Price & Time, eToro- BidSpraded & AskSpreaded
14-11-2022              Adar                           Change the KustoPrices temp table name (because this is ## table)
14-11-2023              Adar		  SR-218324        Migration -> Synapse
30-11-2023              Adar		  SR-220487        Sum the data per Inst, rates and occurrence & Column NumberofTransaction has been added
18-06-2024              Adar		  SR-257525        Change the price tables to CopyFromLake

*******************************************************************************************************************************/

--EXEC [Dealing_dbo].[SP_Execution_Slippage] '20240613'

--DECLARE @Date DATE = '20240613' --cast(getdate()-1 as date)
DECLARE @NextDate Date= DATEADD(DAY,1,@Date) 


BEGIN
    DECLARE @table1 VARCHAR(500) = 'CopyFromLake.PricesFromProvider_MarketCurrencyPrice'
    EXEC [CopyFromLake].[SP_Copy_Temporary_Data] @dest_table = @table1, @fromdate = @Date, @todate = @Date
END

BEGIN
    DECLARE @table2 VARCHAR(500) = 'CopyFromLake.PriceLog_History_CurrencyPrice'
    EXEC [CopyFromLake].[SP_Copy_Temporary_Data] @dest_table = @table2, @fromdate = @Date, @todate = @Date
END

BEGIN
         DECLARE @table VARCHAR(500) = 'Dealing_staging.Etoro_Hedge_ExecutionLog'
         EXEC [Dealing_staging].[SP_Copy_Temporary_Data] @dest_table = @table, @fromdate = @Date, @todate = @Date
END


--Execution Rates
IF OBJECT_ID('tempdb..#ExecutionRate1') IS NOT NULL 
DROP TABLE #ExecutionRate1 
CREATE TABLE #ExecutionRate1   
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) AS

SELECT @Date Date,
InstrumentID,
er.IsBuy,
Units,
er.ExecutionRate,
ExecutionTime,
RateIDAtSent,
er.OrderID,
SendTime,
CASE WHEN hl.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END HedgingMode,
ROW_NUMBER() OVER (ORDER BY InstrumentID DESC) RN
FROM Dealing_staging.Etoro_Hedge_ExecutionLog er 
LEFT JOIN Dealing_staging.Etoro_Hedge_HBCOrderLog hl 
ON er.OrderID=hl.HedgeID AND er.OrderID>0
WHERE Success = 1
and ExecutionTime >=  @Date
and ExecutionTime < @NextDate
AND HedgeServerID<>5000
AND er.ExecutionRate<>0


--Get FX rates
IF OBJECT_ID('tempdb..#Rates') IS NOT NULL 
DROP TABLE #Rates 
CREATE TABLE #Rates   
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) AS

SELECT di.InstrumentID,
di.BuyCurrencyID,
di.SellCurrencyID,
fcpws.Bid,
fcpws.Ask
FROM DWH_dbo.Fact_CurrencyPriceWithSplit fcpws WITH (NOLOCK)
JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON fcpws.InstrumentID = di.InstrumentID
WHERE fcpws.OccurredDate=@Date



IF OBJECT_ID('tempdb..#FX_Rate') IS NOT NULL 
DROP TABLE #FX_Rate 
CREATE TABLE #FX_Rate   
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) AS
SELECT distinct
	  tn.InstrumentID
	  ,di.InstrumentType
	  ,di.SellCurrency
	  ,tn.IsBuy
	  ,CASE WHEN di.SellCurrencyID = 1 then 1
			WHEN di.BuyCurrencyID = 1 then 1/(CASE WHEN tn.IsBuy= 1 THEN r0.Bid ELSE r0.Ask end)
			WHEN di.SellCurrencyID= 666 THEN 
			COALESCE(100*(1/ CASE WHEN tn.IsBuy=1 THEN r1.Bid ELSE r1.Ask END), 
			CASE tn.IsBuy WHEN 1 THEN 100*r2.Bid ELSE 100*r2.Ask end, 1)
			WHEN di.SellCurrencyID <> 1 and di.BuyCurrencyID <> 1 AND di.SellCurrencyID<>666 THEN 
			COALESCE(1/ CASE WHEN tn.IsBuy=1 THEN r1.Bid ELSE r1.Ask END, 
			CASE tn.IsBuy WHEN 1 THEN r2.Bid ELSE r2.Ask end, 1)
			end FX_Rate	
FROM #ExecutionRate1 tn
JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON tn.InstrumentID = di.InstrumentID
JOIN #Rates r0
ON r0.InstrumentID= tn.InstrumentID
left join #Rates r1
on di.SellCurrencyID = r1.SellCurrencyID and r1.BuyCurrencyID = 1 and di.BuyCurrencyID <> 1
left join #Rates r2
on di.SellCurrencyID = r2.BuyCurrencyID and r2.SellCurrencyID = 1 and di.SellCurrencyID <> 1


IF OBJECT_ID('tempdb..#ExecutionRate') IS NOT NULL 
DROP TABLE #ExecutionRate 
CREATE TABLE #ExecutionRate   
WITH (HEAP, DISTRIBUTION=HASH (RateIDAtSent)) AS

SELECT t.Date
	  ,t.InstrumentID
	  ,InstrumentType
	  ,t.IsBuy
	  ,t.Units
	  ,t.ExecutionRate
	  ,t.ExecutionTime
	  ,t.RateIDAtSent
	  ,fx.SellCurrency
	  ,t.RN
	  ,CASE WHEN fx.SellCurrency= 'GBX' THEN fx.FX_Rate/100 ELSE fx.FX_Rate END FX_Rate
	  ,HedgingMode
FROM #ExecutionRate1 t
join #FX_Rate fx
ON t.InstrumentID = fx.InstrumentID AND t.IsBuy = fx.IsBuy
WHERE t.Units>0


--eToro Price
IF OBJECT_ID('tempdb..#eToroPrice') IS NOT NULL 
DROP TABLE #eToroPrice 
CREATE TABLE #eToroPrice   
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS

SELECT cp.InstrumentID, 
cp.Bid,
cp.Ask,
cp.Occurred,
InstrumentType,
ExecutionTime,
IsBuy,
Units,
ExecutionRate,
HedgingMode,
FX_Rate,
cp.BidSpreaded,
cp.AskSpreaded
FROM #ExecutionRate er
LEFT JOIN CopyFromLake.PriceLog_History_CurrencyPrice cp
ON cp.PriceRateID= er.RateIDAtSent
WHERE cp.partition_date=@Date


IF OBJECT_ID('tempdb..#RelevantInstruments') IS NOT NULL 
DROP TABLE #RelevantInstruments 
CREATE TABLE #RelevantInstruments   
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) AS
SELECT DISTINCT InstrumentID, MAX(ExecutionTime) MAXOccurred
FROM #eToroPrice
GROUP BY InstrumentID


--All Kusto prices for all the instruments
--Using Market_Currency (Kusto)
IF OBJECT_ID('tempdb..#KustoAll_ExecutionSlippage') IS NOT NULL 
DROP TABLE #KustoAll_ExecutionSlippage
CREATE TABLE #KustoAll_ExecutionSlippage
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) AS

select mcp.LiquidityAccountID, 
mcp.InstrumentID,
mcp.Bid,
mcp.Ask,
CAST(OccurredAtServer AS datetime) as OccurredAtServer
from CopyFromLake.PricesFromProvider_MarketCurrencyPrice mcp
inner join #RelevantInstruments ri
on mcp.InstrumentID= ri.InstrumentID
where mcp.OccurredAtServer BETWEEN CONVERT(DATETIME, @Date) 
AND CONVERT(DATETIME, @NextDate)
and mcp.OccurredAtServer<= CAST(MAXOccurred AS DATETIME)
and Bid<=Ask



--The relevant Price from Kusto
IF OBJECT_ID('tempdb..#KustoPrices') IS NOT NULL 
DROP TABLE #KustoPrices
CREATE TABLE #KustoPrices  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS

	SELECT D.InstrumentID
      ,D.InstrumentType
	  ,D.Occurred 
	  ,D.ExecutionTime
	  ,D.IsBuy
	  ,D.Units
	  ,D.ExecutionRate
	  ,D.HedgingMode
	  ,D.Bid
	  ,D.Ask
	  ,D.FX_Rate 
	  ,D.BidSpreaded
	  ,D.AskSpreaded
	  ,A.OccurredAtServer
	  ,A.Bid AS BidKusto
	  ,A.Ask AS AskKusto	
	FROM #eToroPrice D 
CROSS APPLY 
	( 
	SELECT TOP 1 OccurredAtServer, Bid, Ask FROM #KustoAll_ExecutionSlippage E 
	WHERE E.InstrumentID = D.InstrumentID 
	AND E.OccurredAtServer<= D.ExecutionTime
	ORDER BY OccurredAtServer DESC
	) A 



IF OBJECT_ID('tempdb..#Total') IS NOT NULL 
DROP TABLE #Total
CREATE TABLE #Total 
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS
SELECT InstrumentID
      ,InstrumentType
	  ,Occurred 
	  ,ExecutionTime
	  ,ExecutionRate
	  ,HedgingMode
	  ,CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END eToro_Price
	  ,FX_Rate
	  ,IsBuy
	  ,OccurredAtServer KustoTime
	  ,CASE WHEN IsBuy= 1 THEN AskKusto ELSE BidKusto END Kusto_Price
	  ,BidSpreaded
	  ,AskSpreaded
	  ,SUM(Units) AS Units
	  ,SUM(Units*ExecutionRate*FX_Rate) AS ProviderAmount_USD
	  ,SUM(Units*(CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END)*FX_Rate) AS eToro_AmountUSD
	  ,COUNT(*) AS NumberofTransaction
FROM #KustoPrices
GROUP BY InstrumentID
      ,InstrumentType
	  ,Occurred 
	  ,ExecutionTime
	  ,ExecutionRate
	  ,HedgingMode
	  ,CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END
	  ,FX_Rate
	  ,IsBuy
	  ,OccurredAtServer
	  ,CASE WHEN IsBuy= 1 THEN AskKusto ELSE BidKusto END
	  ,BidSpreaded
	  ,AskSpreaded



IF OBJECT_ID('tempdb..#AssetType') IS NOT NULL 
DROP TABLE #AssetType 
CREATE TABLE #AssetType   
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
	InstrumentType
	,HedgingMode
	,SUM((CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(eToro_Price-ExecutionRate)*Units*FX_Rate) SlippageInDollar
FROM #Total
GROUP BY InstrumentType
	,HedgingMode

/******************************************************
****Slippage of the Execution Time vs. Request Time**** 
*******************************************************/  

--eToro Price for execution time
--The relevant Price
IF OBJECT_ID('tempdb..#eToroPrice_RequestTime') IS NOT NULL 
DROP TABLE #eToroPrice_RequestTime 
CREATE TABLE #eToroPrice_RequestTime   
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS

SELECT D.Date
	  ,D.InstrumentID
	  ,D.InstrumentType
	  ,D.IsBuy
	  ,D.Units
	  ,D.ExecutionRate
	  ,D.ExecutionTime
	  ,D.RateIDAtSent
	  ,D.SellCurrency
	  ,D.RN
	  ,D.FX_Rate
	  ,D.HedgingMode
	  ,A.Occurred
	  ,A.Bid
	  ,A.Ask	
FROM #ExecutionRate D 
CROSS APPLY 
( 
SELECT TOP 1 Occurred, Bid, Ask 
FROM CopyFromLake.PriceLog_History_CurrencyPrice E 
WHERE E.partition_date= @Date
AND E.InstrumentID = D.InstrumentID 
AND E.Occurred<= D.ExecutionTime
ORDER BY Occurred DESC
) A 


IF OBJECT_ID('tempdb..#Total_RequestTime') IS NOT NULL 
DROP TABLE #Total_RequestTime
CREATE TABLE #Total_RequestTime
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS
SELECT InstrumentID
      ,InstrumentType
	  ,Occurred RequestTime
	  ,ExecutionTime
	  ,IsBuy
	  ,ExecutionRate
	  ,HedgingMode
	  ,FX_Rate
	  ,CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END eToro_RequestTimePrice
	  ,SUM(Units) AS Units
	  ,SUM(Units*ExecutionRate*FX_Rate) AS ProviderAmount_USD
	  ,SUM(Units*(CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END)*FX_Rate) AS eToro_RequestTimeAmountUSD
	  ,COUNT(*) AS NumberofTransaction
FROM #eToroPrice_RequestTime
GROUP BY InstrumentID
      ,InstrumentType
	  ,Occurred
	  ,ExecutionTime
	  ,IsBuy
	  ,ExecutionRate
	  ,HedgingMode
	  ,FX_Rate
	  ,CASE WHEN IsBuy= 1 THEN Ask ELSE Bid END


IF OBJECT_ID('tempdb..#AssetType_RequestTime') IS NOT NULL 
DROP TABLE #AssetType_RequestTime 
CREATE TABLE #AssetType_RequestTime   
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) AS
SELECT 
	InstrumentType
	,HedgingMode
	,SUM((CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(eToro_RequestTimePrice-ExecutionRate)*Units*FX_Rate) SlippageInDollar
FROM #Total_RequestTime
GROUP BY InstrumentType
	,HedgingMode



/***********************
****insert data into**** 
************************/  

--SendTime Vs ExecutionTime
DELETE FROM Dealing_dbo.Dealing_Execution_Slippage WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Execution_Slippage
(      Date
      ,InstrumentID
	  ,Occurred
	  ,ExecutionTime
	  ,IsBuy
	  ,Units
	  ,ExecutionRate
	  ,eToro_Price
	  ,ProviderAmount_USD
	  ,eToro_AmountUSD
	  ,FX_Rate
	  ,Slippage
	  ,SlippageInDollar
	  ,Slippage_Percent
	  ,UpdateDate
	  ,HedgingMode
	  ,KustoTime
	  ,Kusto_Price
	  ,BidSpreaded
	  ,AskSpreaded
	  ,NumberofTransaction
)

SELECT @Date AS Date
	  ,t.InstrumentID
	  ,t.Occurred
	  ,t.ExecutionTime
	  ,t.IsBuy
	  ,t.Units
	  ,t.ExecutionRate
	  ,t.eToro_Price
	  ,t.ProviderAmount_USD
	  ,t.eToro_AmountUSD
	  ,t.FX_Rate
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.ExecutionRate-t.eToro_Price) 
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.eToro_Price-t.ExecutionRate)*t.Units*t.FX_Rate 
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.ExecutionRate-t.eToro_Price)/t.eToro_Price 
	  ,GETDATE() 
	  ,HedgingMode
	  ,KustoTime
	  ,Kusto_Price
	  ,BidSpreaded
	  ,AskSpreaded
	  ,NumberofTransaction
FROM #Total t


DELETE FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Execution_Slippage_AssetType
(
Date,
InstrumentType,
HedgingMode,
SlippageInDollar,
UpdateDate
)

SELECT @Date AS Date 
      ,InstrumentType
	  ,HedgingMode
	  ,SlippageInDollar
	  ,GETDATE()
FROM #AssetType



--RequestTime Vs ExecutionTime
DELETE FROM Dealing_dbo.Dealing_Execution_Slippage_RequestTime WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Execution_Slippage_RequestTime
(      Date
      ,InstrumentID
	  ,RequestTime
	  ,ExecutionTime
	  ,IsBuy
	  ,Units
	  ,ExecutionRate
	  ,eToro_RequestTimePrice
	  ,ProviderAmount_USD
	  ,eToro_RequestTimeAmountUSD
	  ,FX_Rate
	  ,Slippage
	  ,SlippageInDollar
	  ,Slippage_Percent
	  ,UpdateDate
	  ,HedgingMode
	  ,NumberofTransaction
)

SELECT @Date AS Date
	  ,t.InstrumentID
	  ,t.RequestTime
	  ,t.ExecutionTime
	  ,t.IsBuy
	  ,t.Units
	  ,t.ExecutionRate
	  ,t.eToro_RequestTimePrice
	  ,t.ProviderAmount_USD
	  ,t.eToro_RequestTimeAmountUSD
	  ,t.FX_Rate
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.ExecutionRate-t.eToro_RequestTimePrice) 
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.eToro_RequestTimePrice-t.ExecutionRate)*t.Units*t.FX_Rate 
	  ,(CASE when IsBuy= 1 THEN 1.0 ELSE -1.0 END)*(t.ExecutionRate-t.eToro_RequestTimePrice)/t.eToro_RequestTimePrice 
	  ,GETDATE() 
	  ,HedgingMode
	  ,NumberofTransaction
FROM #Total_RequestTime t


DELETE FROM Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
(
Date,
InstrumentType,
HedgingMode,
SlippageInDollar,
UpdateDate
)

SELECT @Date AS Date 
      ,InstrumentType
	  ,HedgingMode
	  ,SlippageInDollar
	  ,GETDATE()
FROM #AssetType_RequestTime


END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_staging.Etoro_Hedge_ExecutionLog` | unresolved | Dealing_staging | Etoro_Hedge_ExecutionLog | `—` |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | unresolved | CopyFromLake | PriceLog_History_CurrencyPrice | `—` |
| `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` | unresolved | CopyFromLake | PricesFromProvider_MarketCurrencyPrice | `—` |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | synapse | DWH_dbo | Fact_CurrencyPriceWithSplit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `Dealing_staging.Etoro_Hedge_HBCOrderLog` | unresolved | Dealing_staging | Etoro_Hedge_HBCOrderLog | `—` |
| `EL.HedgeServerID` | unresolved | EL | HedgeServerID | `—` |
| `EL.InstrumentID` | unresolved | EL | InstrumentID | `—` |
| `DI.AssetTypeID` | unresolved | DI | AssetTypeID | `—` |
| `EL.IsBuy` | unresolved | EL | IsBuy | `—` |
| `EL.Units` | unresolved | EL | Units | `—` |
| `PH.Rate` | unresolved | PH | Rate | `—` |
| `EL.ExecutionRate` | unresolved | EL | ExecutionRate | `—` |
| `LP.Price` | unresolved | LP | Price | `—` |
| `FX.Price` | unresolved | FX | Price | `—` |
| `EL.SendTime` | unresolved | EL | SendTime | `—` |
| `EL.ExecutionTime` | unresolved | EL | ExecutionTime | `—` |
| `EL.HedgeOrderID` | unresolved | EL | HedgeOrderID | `—` |
| `EL.PositionID` | unresolved | EL | PositionID | `—` |
| `EL.RateIDAtSent` | unresolved | EL | RateIDAtSent | `—` |
| `Dealing_dbo.SP_Execution_Slippage` | synapse_sp | Dealing_dbo | SP_Execution_Slippage | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Execution_Slippage.sql` |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType` | synapse | Dealing_dbo | Dealing_Execution_Slippage_AssetType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_AssetType.md` |
| `Dealing_dbo.Dealing_Execution_Slippage_RequestTime` | synapse | Dealing_dbo | Dealing_Execution_Slippage_RequestTime | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_RequestTime.md` |
| `Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime` | synapse | Dealing_dbo | Dealing_Execution_Slippage_AssetType_RequestTime | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Execution_Slippage_AssetType_RequestTime.md` |

