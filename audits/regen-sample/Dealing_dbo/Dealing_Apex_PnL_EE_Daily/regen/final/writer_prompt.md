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
- **Object**: `Dealing_Apex_PnL_EE_Daily`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_EE_Daily/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Apex_PnL_EE_Daily\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Apex_PnL_EE_Daily\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_Apex_PnL_EE_Daily.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_Apex_PnL_EE_Daily`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_Apex_PnL_EE_Daily.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_Apex_PnL_EE_Daily]
(
	[Date] [date] NULL,
	[AccountNumber] [varchar](20) NULL,
	[Equity_Start] [decimal](16, 6) NULL,
	[Equity_End] [decimal](16, 6) NULL,
	[Transfers] [decimal](16, 8) NULL,
	[PnL] [decimal](16, 6) NULL,
	[UpdateDate] [datetime] NULL,
	[Dividends] [decimal](16, 6) NULL
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

### Upstream `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_DailyZeroPnL_Stocks.md`

# Dealing_dbo.Dealing_DailyZeroPnL_Stocks

## 1. Overview

**Daily eToro revenue (Zero P&L) aggregated by instrument** for stocks and ETFs. Each row represents one combination of date, hedge server, instrument, leverage tier, CFD flag, regulation, MiFID category, trading mode (IsManual), and stock index membership. Realized Zero comes from positions closed on the report date; Unrealized Zero reflects the mark-to-market P&L on open positions. The table is a foundational feed for downstream Dealing revenue analytics, Apex P&L reconciliation, credit risk, and hedge cost calculations.

**Row grain**: `Date` + `HedgeServerID` + `InstrumentID` + `Industry` + `InstrumentType` + `IsManual` + `Leverage` + `IsCFD` + `Regulation` + `MifID`.

---

## 2. Business Context

`SP_DailyZeroPnL_Stocks` (Author: Amir Gurewitz 2020-06-09, migrated to Synapse by Gal in Jan 2024) calculates the daily Zero P&L for `InstrumentTypeID IN (5, 6)` (Stocks and ETFs).

**Realized Zero** is computed for positions with `CloseDateID = @RepDate`: NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro zero formula).

**Unrealized Zero** (ChangeInUnrealizedZero) is computed for open positions as DailyPnL + commission adjustment: captures intraday P&L movement for positions still open at EOD.

**NOP** (Net Open Position) is aggregated as `SUM(ABS(NOP_in_USD))` using the (2*IsBuy-1) sign convention, with FX conversion via `Fact_CurrencyPriceWithSplit`.

**StockIndex** mapping comes from `BI_DB_dbo.BI_DB_IndexesMapping_Static` to classify instruments into index groups (e.g., S&P500, NASDAQ).

**Key business rules**:

- **InstrumentTypeID filter**: Only Stocks (5) and ETFs (6) — FX/crypto excluded.
- **DELETE-INSERT by date**: Idempotent daily reload.
- **MifID and Regulation** from `Fact_SnapshotCustomer` for the report date — used by compliance/reporting consumers.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 26 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~275,000,000 |
| **Date range** | Active and current (daily refresh confirmed) |
| **Recent sample** | Rows for 2026-03-20 with mixed Regulation values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the zero P&L snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, @RepDate) |
| 2 | HedgeServerID | int | YES | Hedge server identifier for the position set. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.HedgeServerID) |
| 3 | Industry | varchar(250) | YES | Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry) |
| 4 | InstrumentType | varchar(50) | YES | Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentID) |
| 6 | InstrumentDisplayName | varchar(250) | YES | Display name of the instrument. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 7 | StockIndex | varchar(50) | YES | Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_IndexesMapping_Static.IndexName) |
| 8 | IsManual | tinyint | YES | Flag indicating manual (non-automated) trading positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsManual) |
| 9 | Leverage | int | YES | Position leverage tier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.Leverage) |
| 10 | IsCFD | tinyint | YES | 1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsSettled / HedgeServerID) |
| 11 | Regulation | varchar(50) | YES | Regulatory jurisdiction of the customer (e.g., ASIC, FCA, CySEC). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Regulation.Name) |
| 12 | MifID | int | YES | MiFID categorization ID of the customer snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Fact_SnapshotCustomer.MifidCategorizationID) |
| 13 | RealizedCommission | money | YES | Aggregate commission charged on positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.CommissionOnClose) |
| 14 | RealizedZero | money | YES | Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL / NetProfit / CommissionOnClose) |
| 15 | ChangeInUnrealizedZero | money | YES | Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL) |
| 16 | TotalZero | money | YES | RealizedZero + ChangeInUnrealizedZero for the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, computed) |
| 17 | NOP | money | YES | Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 18 | OpenPositions | money | YES | Count of open positions in the group (as money type). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL) |
| 19 | NOP_Units | numeric(38,6) | YES | Net open position in instrument units (signed: positive=long, negative=short). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal with sign) |
| 20 | VolumeOnOpen | bigint | YES | Cumulative open-action volume for positions opened on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnOpen) |
| 21 | VolumeOnClose | bigint | YES | Cumulative close-action volume for positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnClose) |
| 22 | OpenPositionValue | money | YES | Aggregated USD value of open positions (units × price). (Tier 2 -- SP_DailyZeroPnL_Stocks, computed from NOP and FX rate) |
| 23 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE()) |
| 24 | InstrumentName | varchar(100) | YES | Short instrument name/ticker symbol. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Name) |
| 25 | Units | decimal(16,6) | YES | Net units held across the group's open positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 26 | Currency | varchar(50) | YES | Trade currency of the instrument (SellCurrency). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.SellCurrency) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary position P&L fact (NOP, DailyPnL, CommissionOnClose, IsSettled) |
| Dim_Position | DWH_dbo | Position attributes (OpenDateID, CloseDateID, HedgeServerID, Leverage) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation and MiFID snapshot for report date |
| Dim_Range | DWH_dbo | Snapshot date range lookup |
| Dim_Instrument | DWH_dbo | Instrument metadata (InstrumentType, Industry, SellCurrency) |
| Dim_Regulation | DWH_dbo | Regulation name lookup |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for NOP USD conversion |
| BI_DB_IndexesMapping_Static | BI_DB_dbo | Stock index membership mapping |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Apex_PnL | Dealing_dbo | Apex P&L report — depends on this table |
| Dealing_Apex_PnL_Daily | Dealing_dbo | Daily Apex P&L |
| Dealing_Apex_PnL_EE / EE_Daily | Dealing_dbo | eToro Europe variant |
| Dealing_CFDs_Stocks_Credit_Risk | Dealing_dbo | CFD stock credit risk |
| Dealing_HedgeCost | Dealing_dbo | Hedge cost calculation |
| Dealing_Manual_Exec_Trade / Summary | Dealing_dbo | Manual execution trade analytics |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DailyZeroPnL_Stocks |
| **Author** | Amir Gurewitz (2020-06-09); Synapse migration by Gal (2024-01) |
| **ETL Pattern** | DELETE WHERE Date=@dd + INSERT |
| **Schedule** | Daily — SB_Daily (P0) |
| **Parameter** | @dd (DATE) — the report date |
| **Delete Scope** | `DELETE WHERE Date = @dd` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Clustered index** | Filter on `Date` first for optimal performance. |
| **CFD vs Real** | Use `IsCFD` flag to split; Real = `IsSettled=1` or `HedgeServerID IN (3,9,102,112,125,126,81)`. |
| **NOP sign** | `NOP_Units` is signed (positive=long, negative=short). `NOP` is absolute USD value. |
| **Zero formula** | RealizedZero = NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro Zero definition). |
| **Downstream** | Several Dealing_dbo tables depend on this as a source — changes to filters here ripple broadly. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Revenue Analytics |
| **Sub-domain** | Daily Zero P&L — Stocks & ETFs |
| **Sensitivity** | Aggregated (no individual customer data exposed) |
| **Quality Score** | 8.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


### Upstream `Dealing_dbo.Dealing_Apex_PnL` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Apex_PnL`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL.md`

# Dealing_dbo.Dealing_Apex_PnL

> Week-to-date (WTD) PnL reconciliation for eToro’s Apex Clearing LP account by instrument — Middle Office compares internal valuations to Apex statements; **data is stale (frozen since June 2024)**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing LP external files → `Dealing_staging.LP_APEX_EXT872_3EU_217314` (trades/dividends) + `LP_APEX_EXT982_3EU` (NOP/holdings) + `PriceLog_History_CurrencyPrice` + `Dealing_DailyZeroPnL_Stocks` |
| **Refresh** | Weekly (Saturday reporting date per `SP_Apex_PnL`; same SP also loads daily and equity variants) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last pipeline update **2024-06-08 09:19**. The table has had **no fresh loads for roughly nine months** (as of March 2026). Treat all figures as **historical** unless the Apex LP pipeline is reactivated; downstream consumers should confirm whether Apex Clearing remains the active US equities LP.

This table answers: **What was eToro’s net PnL on each symbol/instrument held at Apex for the week ending on `Date`?** Apex is a US clearing broker for US stocks and ETFs. Grain is **one row per `(Date, AccountNumber, Symbol)`** for **week-to-date** metrics. It supports **Dealing / Middle Office** in verifying that eToro’s internal position valuations match Apex’s statements.

**Data lineage & freshness (operational context):** The writer is **`Dealing_dbo.SP_Apex_PnL`**. Sources include Apex staging position and activity data, internal DB prices (`PriceLog_History_CurrencyPrice`), zero-position adjustments from **`Dealing_DailyZeroPnL_Stocks`**, and **`DWH_dbo.Dim_Instrument`** for symbol resolution. Refresh was intended as **weekly WTD** (Saturday date logic); **Phase 2 sampling confirmed stale data** and **bank-holiday handling in the SP** (NOP uses the previous business day on holidays). **PII:** No client CID — account-level LP data only.

**Price-reconciliation intent:** Non-`_DBPrice` amounts use **Apex closing prices**; `*_DBPrice` columns use **eToro’s internal database prices**. Comparing `PnL` vs `PnL_DBPrice` highlights valuation differences between Apex and eToro.

## 2. Business Logic

**WTD PnL formula** (from `SP_Apex_PnL`, Apex-priced path):

```
PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees
PnL_DBPrice = NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees
```

- **`NOP_Start` / `NOP_End`:** Net open position (market value) at **week start** (Friday EOD of the prior week) and **week end** (`Date`), using Apex marks.
- **`Trades`:** Net value of trades in the week (buys add, sells subtract) from Apex trade activity.
- **`Dividends`:** Dividend income from Apex for the symbol in the week.
- **`AdditionalFees`:** Apex fees/adjustments (e.g. borrow, corporate actions) included in PnL.
- **`Zero`:** Adjustment from **`Dealing_DailyZeroPnL_Stocks`** so PnL reflects positions that **opened and fully closed to zero** within the week (without this, WTD PnL can miss those names).

**Instrument mapping:** `InstrumentID` / `InstrumentDisplayName` come from matching Apex **Symbol / CUSIP / ISIN** to **`DWH_dbo.Dim_Instrument`**; **NULL `InstrumentID`** means the row could not be reconciled to the DWH instrument dimension.

**Typical filters:** `WHERE Date = @ReportDate AND AccountNumber = @Acct` or by `Symbol` for a single-name check.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Distribution** | **ROUND_ROBIN** — no hash key; large scans are driven by **`Date`** and predicates on **`AccountNumber`** / **`Symbol`**. |
| **Clustering** | **Clustered on `Date` ASC** — **always filter `Date`** (or a tight date range) to limit scans. |
| **Joins** | Join to **`DWH_dbo.Dim_Instrument`** on **`InstrumentID`** when you need instrument attributes (expect **NULL InstrumentID** for unmatched Apex symbols). |
| **Scale** | Approximately **~3.0M rows** historically (2021-02-10 through 2024-06-07); acceptable for date-scoped reporting but avoid full-table scans in ad hoc work. |
| **Stale data** | Do not assume “current week” — confirm **`MAX(Date)`** and **`UpdateDate`** before publishing numbers. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Report date** — the **Saturday / end-of-week** date for which this **week-to-date** PnL row applies; aligns with SP WTD calendar logic. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex LP account number** (e.g. eToro’s account at Apex Clearing); groups all symbols under the same clearer account. (Tier 2 — SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | **Instrument symbol as Apex reports it** (e.g. `AAPL`, `SPY`); used with CUSIP/ISIN to resolve **`DWH_dbo.Dim_Instrument`**. (Tier 2 — SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | **Net open position at week start** (prior Friday EOD), valued at **Apex’s closing price** — opening mark for the WTD bridge. (Tier 2 — SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | **NOP at week start** using **eToro internal DB price** × quantity — pairs with Apex NOP for **mark-to-market reconciliation**. (Tier 2 — SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | **Net open position at week end** (`Date`), **Apex closing price** — closing mark for the WTD bridge. (Tier 2 — SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | **NOP at week end** using **eToro DB bid** × quantity — internal mark at the same point as `NOP_End`. (Tier 2 — SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | **Net traded notional** for the week from Apex activity (buys vs sells); enters the PnL formula with a **minus** sign. (Tier 2 — SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | **Dividend income** credited via Apex for this **symbol** during the week. (Tier 2 — SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | **Week-to-date PnL using Apex prices:** `NOP_End - NOP_Start - Trades + Dividends + AdditionalFees` — primary “statement-side” PnL. (Tier 2 — SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | **WTD PnL using eToro DB prices** on NOP start/end — compare to **`PnL`** to isolate **price-source** differences vs Apex. (Tier 2 — SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | **Row load timestamp** from the ETL (`GETDATE()` in `SP_Apex_PnL`) — when this row was last written. (Tier 2 — SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | **eToro instrument key** from **`DWH_dbo.Dim_Instrument`** when Apex identifiers match; **NULL** if no match. (Tier 2 — SP_Apex_PnL) |
| 14 | InstrumentDisplayName | varchar(100) | YES | **eToro display name** for the instrument — may differ from Apex **`Symbol`**. (Tier 2 — SP_Apex_PnL) |
| 15 | Price_Start | decimal(16,6) | YES | **Apex closing price** at **week start** (prior Friday EOD). (Tier 2 — SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | **eToro DB bid** at week start — supports **price-level** reconciliation alongside `Price_Start`. (Tier 2 — SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | **Apex closing price** at **week end** (`Date`). (Tier 2 — SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | **eToro DB bid** at week end — pairs with `Price_End`. (Tier 2 — SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | **Additional Apex fees/adjustments** (borrow, corp actions, etc.) **included** in the published PnL bridge. (Tier 2 — SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | **Total traded volume in units** at Apex for the symbol during the week. (Tier 2 — SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | **Zero PnL adjustment** aggregated from **`Dealing_DailyZeroPnL_Stocks`** for the week — captures names **fully closed to zero** so WTD PnL is complete. (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

Authoritative column-level mapping and the full ETL chain are documented in **`Dealing_Apex_PnL.lineage.md`** (do not duplicate here). Summary:

- **External:** Apex LP files land in **`Dealing_staging.LP_APEX_EXT872_3EU_217314`** (trades/dividends) and **`LP_APEX_EXT982_3EU`** (NOP/holdings).
- **Internal:** **`PriceLog_History_CurrencyPrice`** supplies DB marks; **`Dealing_DailyZeroPnL_Stocks`** feeds **`Zero`**; **`DWH_dbo.Dim_Instrument`** resolves **`InstrumentID`**; **`DWH_dbo.Dim_Date`** supports calendar/holiday logic in the SP.
- **Writer:** **`Dealing_dbo.SP_Apex_PnL`** — **no Generic Pipeline** mapping; lineage is **LP external staging**, not a standard warehouse pipeline code path.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL_Daily`** | **Same SP** (`SP_Apex_PnL`), **same column layout** — **daily** grain (prior business day NOP vs week-start NOP). Use daily for **DOD** checks; use this table for **WTD**. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE`** | **Equity-level WTD** total for the Apex account (no symbol split); reconciles **account equity** vs this **per-symbol** roll-up. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Equity-level daily** counterpart (same SP family). |
| **`Dealing_dbo.Dealing_DailyZeroPnL_Stocks`** | **Source of `Zero`** column (sum over the week). |
| **`DWH_dbo.Dim_Instrument`** | **Instrument resolution** for `InstrumentID` / display name. |
| **`Dealing_staging.LP_APEX_EXT872_3EU_217314`** | Apex **activity** staging (trades/dividends). |
| **`Dealing_staging.LP_APEX_EXT982_3EU`** | Apex **position/NOP** staging. |

**Cross-check:** Summing **symbol-level `PnL`** across all symbols for a date should **approximate** **`Dealing_Apex_PnL_EE.PnL`** after **transfers and presentation differences** — investigate gaps with Middle Office.

## 7. Sample Queries

**Latest available WTD snapshot (stale-aware):**

```sql
SELECT MAX(Date) AS LastReportDate, MAX(UpdateDate) AS LastLoad
FROM Dealing_dbo.Dealing_Apex_PnL;
```

**Single week, single account — symbol-level PnL vs DB-priced PnL:**

```sql
SELECT Symbol, InstrumentID, PnL, PnL_DBPrice,
       PnL - PnL_DBPrice AS PnL_VsDB_MarkDiff
FROM Dealing_dbo.Dealing_Apex_PnL
WHERE Date = '2024-06-07'
  AND AccountNumber = @AccountNumber
ORDER BY ABS(PnL - PnL_DBPrice) DESC;
```

**Attach instrument attributes for matched rows:**

```sql
SELECT p.Date, p.Symbol, p.PnL, i.InstrumentDisplayName
FROM Dealing_dbo.Dealing_Apex_PnL AS p
LEFT JOIN DWH_dbo.Dim_Instrument AS i
  ON i.InstrumentID = p.InstrumentID
WHERE p.Date = @ReportDate
  AND p.AccountNumber = @AccountNumber;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL | Type: Table | Production Source: LP external data*


### Upstream `Dealing_dbo.Dealing_Apex_PnL_EE` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Apex_PnL_EE`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL_EE.md`

# Dealing_dbo.Dealing_Apex_PnL_EE

> **Equity-level** (account-level) week-to-date PnL for the Apex Clearing LP — total **account equity** change, not per symbol; **stale since June 2024**, written by **`SP_Apex_PnL`**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex LP **equity / statement** style feeds via staging (equity balances, transfers, aggregate dividends) — same **`SP_Apex_PnL`** family as symbol tables; see **`Dealing_Apex_PnL_EE.lineage.md`** |
| **Refresh** | Weekly WTD (Saturday-style report date aligned with symbol WTD table) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last update **2024-06-08 09:19**. Do not use for current exposure — **historical reconciliation only** unless the pipeline is revived.

**“EE” = equity-level:** This table holds **one Apex account’s total equity PnL** for the **week**, **without symbol granularity**. It answers: **How did eToro’s Apex account equity move this week** after **cash transfers**, and how does that compare to **aggregated position PnL** from **`Dealing_Apex_PnL`**?

**Middle Office use:** **Account-level** sign-off vs Apex **equity statements**; complements **`Dealing_Apex_PnL`** (per-symbol) and **`Dealing_Apex_PnL_Daily` / `Dealing_Apex_PnL_EE_Daily`** for other grains.

**Size:** Only **~5,130 rows** historically (**2021-02-10 → 2024-06-07**) — typically **a few rows per `Date`** (often **one row per `AccountNumber`** per week). **No PII** at client level.

**Dividends vs PnL:** **`Dividends`** is **aggregate dividend income across all instruments** for the account in the week. The **`PnL`** formula shown below is **equity-based** and **does not add dividends inside the same expression** — analysts may **add dividends** when presenting **total income** for the week (see Business Logic).

## 2. Business Logic

**Equity WTD formula** (from `SP_Apex_PnL` analysis):

```
PnL = Equity_End - Equity_Start - Transfers
```

- **`Equity_Start`:** **Total account equity** at **week start** (prior **Friday EOD**), **USD**.
- **`Equity_End`:** **Total account equity** at **`Date` EOD**, **USD**.
- **`Transfers`:** **Net cash** moved **into/out of** the Apex account during the week (deposits/withdrawals of hedge cash). **Positive** = funds received at Apex; **negative** = funds withdrawn.
- **`Dividends`:** **Sum of dividends** credited to the account for the week (**all symbols**).

**Reconciliation hints (from domain notes):**

- Summing **`Dealing_Apex_PnL.PnL`** across **all symbols** for a **`Date`** should **approximately** match **`Dealing_Apex_PnL_EE.PnL`**, **after transfers and presentation** — material gaps may indicate **unmapped positions**, **fees booked only at equity level**, or **timing**.
- **`PnL`** as defined **excludes embedding `Dividends`** in the same formula — for a **“total P&L including income”** narrative, **add `Dividends` explicitly** when that is the business definition.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Size** | **Very small** — performance is trivial; still **filter `Date`** for clarity. |
| **Distribution** | **ROUND_ROBIN**; **clustered on `Date`**. |
| **Grain** | **Account equity WTD** — **not** symbol level; join **symbol facts** from **`Dealing_Apex_PnL`**. |
| **Transfers** | Understand **sign convention** before interpreting **PnL** — large transfers can **mask** market PnL if not normalized. |
| **Stale** | Always print **`MAX(Date)`** in audit outputs. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **WTD report date** — **end-of-week** anchor (Saturday-style), aligned with **`Dealing_Apex_PnL.Date`** semantics. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex account** key — **COALESCE**-style resolution across equity/transfers/dividend feeds in SP when identifiers differ by feed. (Tier 2 — SP_Apex_PnL) |
| 3 | Equity_Start | decimal(16,6) | YES | **Total equity (USD)** at **week start** — **Friday EOD** prior to **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 4 | Equity_End | decimal(16,6) | YES | **Total equity (USD)** at **`Date` EOD** — closing equity on the statement. (Tier 2 — SP_Apex_PnL) |
| 5 | Transfers | decimal(16,8) | YES | **Net transfers** for the week — **cash movement** into/out of Apex; use to **explain** equity step changes separate from **market PnL**. (Tier 2 — SP_Apex_PnL) |
| 6 | PnL | decimal(16,6) | YES | **Equity PnL:** `Equity_End - Equity_Start - Transfers` — **does not** roll **`Dividends`** into this expression per SP logic. (Tier 2 — SP_Apex_PnL) |
| 7 | UpdateDate | datetime | YES | **ETL timestamp** (`GETDATE()` from `SP_Apex_PnL`). (Tier 2 — SP_Apex_PnL) |
| 8 | Dividends | decimal(16,6) | YES | **Aggregate dividends** for the **account** for the week (all instruments). (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

See **`Dealing_Apex_PnL_EE.lineage.md`**. **Summary:** Same **`SP_Apex_PnL`** execution as the symbol tables. **Inputs** are **Apex equity / transfer / dividend** aggregates (via staging); **`AccountNumber`** may be derived from **whichever feed carries it** when joins are built. **No Generic Pipeline** code — **LP external** classification.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL`** | **Per-symbol WTD** — **sum of symbol PnL** should **relate to** this **`PnL`** after **transfers** and **presentation**; use both for **full** Middle Office story. |
| **`Dealing_dbo.Dealing_Apex_PnL_Daily`** | **Daily symbol** detail — drill from **equity** anomalies into **names**. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Daily equity** counterpart from the **same SP** — DOD **account** bridge. |
| **Apex staging (equity/transfers/dividends)** | Upstream of **`SP_Apex_PnL`** — see lineage file for column mapping. |

## 7. Sample Queries

**Latest equity snapshot (stale check):**

```sql
SELECT MAX(Date) AS LastReportDate, COUNT(*) AS RowCount
FROM Dealing_dbo.Dealing_Apex_PnL_EE;
```

**One week, one account — equity bridge components:**

```sql
SELECT Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, Dividends,
       Equity_End - Equity_Start AS RawEquityDelta
FROM Dealing_dbo.Dealing_Apex_PnL_EE
WHERE Date = @WeekEndDate
  AND AccountNumber = @AccountNumber;
```

**Compare account PnL to sum of symbol WTD (investigation only):**

```sql
SELECT e.PnL AS EquityPnL,
       SUM(s.PnL) AS SumSymbolPnL,
       e.PnL - SUM(s.PnL) AS Diff
FROM Dealing_dbo.Dealing_Apex_PnL_EE AS e
JOIN Dealing_dbo.Dealing_Apex_PnL AS s
  ON s.Date = e.Date
 AND s.AccountNumber = e.AccountNumber
WHERE e.Date = @WeekEndDate
  AND e.AccountNumber = @AccountNumber
GROUP BY e.PnL;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL_EE | Type: Table | Production Source: LP external data*


### Upstream `Dealing_dbo.Dealing_Apex_PnL_Daily` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Apex_PnL_Daily`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL_Daily.md`

# Dealing_dbo.Dealing_Apex_PnL_Daily

> Daily grain Apex Clearing LP PnL by instrument for Middle Office reconciliation (prior business day NOP to current day NOP); **same writer as WTD** — **data stale since June 2024**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Same as `Dealing_Apex_PnL` — Apex LP staging **`LP_APEX_EXT872_3EU_217314`** + **`LP_APEX_EXT982_3EU`**, internal **`PriceLog_History_CurrencyPrice`**, **`Dealing_DailyZeroPnL_Stocks`**, **`DWH_dbo.Dim_Instrument`** |
| **Refresh** | Daily (within `SP_Apex_PnL` daily logic path; WTD and equity tables loaded in the same SP run) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last pipeline update **2024-06-08 09:19**. Like the WTD table, this object is **frozen in time** for operational use unless the Apex feed and `SP_Apex_PnL` job are restored.

**Daily grain:** One row per **`(Date, AccountNumber, Symbol)`** for **one trading day’s** PnL bridge. Whereas **`Dealing_Apex_PnL`** uses **week-start NOP** (Friday prior), this table uses **previous business day NOP** as **`NOP_Start`** (the SP **skips weekends** — e.g. Monday’s **`NOP_Start`** reflects **Friday’s** close). Middle Office uses it for **day-over-day** reconciliation against Apex activity and marks.

**Business question:** **What was the daily PnL on each Apex-held symbol** using the same PnL bridge formula as WTD, but with **one-day** trade/dividend/fee windows?

**Operational context & freshness:** Written by **`Dealing_dbo.SP_Apex_PnL`** alongside **`Dealing_Apex_PnL`**, **`Dealing_Apex_PnL_EE`**, and **`Dealing_Apex_PnL_EE_Daily`**. **Phase 2** sampling confirmed **stale** data. Historical volume **~1.655M rows** with date range **2022-07-06 → 2024-06-07** (shorter history than WTD, which starts **2021-02-10** — implies daily path was introduced or backfilled later).

**Reconciliation:** Compare **`PnL`** (Apex marks) vs **`PnL_DBPrice`** (internal DB marks) the same way as the WTD table.

## 2. Business Logic

**Daily PnL formula** (same algebraic form as WTD; **NOP_Start** semantics differ):

```
PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees
PnL_DBPrice = NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees
```

- **`NOP_Start`:** **Prior business day EOD** NOP at **Apex** price (not last Friday unless the prior day was Friday).
- **`NOP_End`:** **This `Date` EOD** NOP at Apex.
- **`Trades` / `Dividends` / `AdditionalFees` / `Volume`:** **Intraday / daily** windows from Apex files (not week aggregates).
- **`Zero`:** **Daily** zero adjustment — positions **fully closed on this day**.

**Weekend rule:** On **Monday**, **`NOP_Start`** aligns to **Friday EOD** (no Saturday/Sunday NOP in the bridge).

**Aggregation intuition:** Summing **`Dealing_Apex_PnL_Daily.PnL`** across **weekdays in a week** should **approximately** match **`Dealing_Apex_PnL.PnL`** for the **same week-ending `Date`**; small differences may arise from **rounding**, **holiday calendars**, or **edge cases** — validate with Middle Office for official sign-off.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Distribution / index** | **ROUND_ROBIN**; **clustered on `Date`** — **filter `Date`** (or small ranges) in all queries. |
| **WTD vs daily** | Use **`Dealing_Apex_PnL_Daily`** for **DOD**; use **`Dealing_Apex_PnL`** for **WTD** packs. |
| **Monday rows** | Expect **`NOP_Start`** to reflect **Friday** — do not assume “yesterday” is calendar yesterday. |
| **Scale** | **~1.65M rows** — moderate; still avoid unbounded scans. |
| **Instrument join** | **`LEFT JOIN DWH_dbo.Dim_Instrument`** on **`InstrumentID`**; allow **NULLs** for unmatched Apex symbols. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** for the row — **one trading day** per **`AccountNumber` + `Symbol`**; not necessarily a Saturday (unlike WTD header date semantics). (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex LP account** identifier — same meaning as WTD table. (Tier 2 — SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | **Apex-reported symbol**; joins to **`DWH_dbo.Dim_Instrument`** via **`InstrumentID`** when matched. (Tier 2 — SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | **NOP at prior business day EOD**, **Apex price** — **Monday rows use Friday** as prior business day. (Tier 2 — SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | **Prior-day NOP** using **eToro DB** marks — pairs with `NOP_Start` for mark reconciliation. (Tier 2 — SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | **NOP at this day’s market close**, **Apex price**. (Tier 2 — SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | **Same-day NOP** using **eToro DB** bid × qty. (Tier 2 — SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | **Net trade notional for this day only** from Apex activity. (Tier 2 — SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | **Dividends credited on this day** for the symbol. (Tier 2 — SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | **Daily PnL (Apex marks):** `NOP_End - NOP_Start - Trades + Dividends + AdditionalFees`. (Tier 2 — SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | **Daily PnL** using **DB-priced NOP** start/end — isolate internal vs Apex mark variance. (Tier 2 — SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | **ETL row timestamp** from **`GETDATE()`** in `SP_Apex_PnL`. (Tier 2 — SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | **Resolved instrument key**; **NULL** when Apex identifiers do not map to **`Dim_Instrument`**. (Tier 2 — SP_Apex_PnL) |
| 14 | InstrumentDisplayName | varchar(100) | YES | **eToro-facing instrument name** for reporting. (Tier 2 — SP_Apex_PnL) |
| 15 | Price_Start | decimal(16,6) | YES | **Apex close** at **prior business day** (start mark for the daily bridge). (Tier 2 — SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | **eToro DB bid** at prior business day. (Tier 2 — SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | **Apex close** on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | **eToro DB bid** on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | **Fees/adjustments for the day** included in the PnL bridge. (Tier 2 — SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | **Traded units** for the symbol on **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | **Daily zero PnL adjustment** for names **closed to zero on this day** (from **`Dealing_DailyZeroPnL_Stocks`** path in SP). (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

See **`Dealing_Apex_PnL_Daily.lineage.md`**. **Summary:** Same **Apex staging** inputs and **`SP_Apex_PnL`** writer as **`Dealing_Apex_PnL`**. The SP uses **daily temp pipelines** (e.g. **`#NOP_Daily`**, **`#Trades_ApexFiles_Daily`**) for **prior-day** NOP and **daily** activity instead of **WTD** aggregates. **Column mapping** is **parallel** to the WTD table; only **windowing** differs.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL`** | **WTD** sibling — **same columns**, **week-start NOP** logic; primary alternative grain for **weekly** packs. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Equity-level daily** from the same SP — use when **account totals** are needed without symbol detail. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE`** | **Equity WTD** — ties **account-level** to **symbol roll-ups** over a week. |
| **`Dealing_dbo.Dealing_DailyZeroPnL_Stocks`** | Feeds **`Zero`** at **daily** resolution. |
| **`DWH_dbo.Dim_Instrument`** | Instrument attributes for matched **`InstrumentID`**. |
| **Apex staging tables** | Same as WTD — **`LP_APEX_EXT872_3EU_217314`**, **`LP_APEX_EXT982_3EU`**. |

## 7. Sample Queries

**Confirm daily history depth vs WTD:**

```sql
SELECT 'Daily' AS tbl, MIN(Date) AS min_d, MAX(Date) AS max_d, COUNT(*) AS rows
FROM Dealing_dbo.Dealing_Apex_PnL_Daily
UNION ALL
SELECT 'WTD', MIN(Date), MAX(Date), COUNT(*)
FROM Dealing_dbo.Dealing_Apex_PnL;
```

**Day-over-day PnL for one symbol:**

```sql
SELECT Date, PnL, PnL_DBPrice, NOP_Start, NOP_End, Trades, Dividends, Zero
FROM Dealing_dbo.Dealing_Apex_PnL_Daily
WHERE AccountNumber = @AccountNumber
  AND Symbol = @Symbol
  AND Date BETWEEN @From AND @To
ORDER BY Date;
```

**Rough weekly check: sum of daily vs WTD row**

```sql
-- Sum daily PnL for US equity week Mon-Fri ending Saturday report date @WeekEnd
SELECT SUM(d.PnL) AS SumDailyPnL
FROM Dealing_dbo.Dealing_Apex_PnL_Daily AS d
WHERE d.AccountNumber = @AccountNumber
  AND d.Symbol = @Symbol
  AND d.Date > DATEADD(DAY, -7, @WeekEnd)
  AND d.Date <= @WeekEnd;

SELECT w.PnL AS WtdPnL
FROM Dealing_dbo.Dealing_Apex_PnL AS w
WHERE w.AccountNumber = @AccountNumber
  AND w.Symbol = @Symbol
  AND w.Date = @WeekEnd;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL_Daily | Type: Table | Production Source: LP external data*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_Apex_PnL`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Apex_PnL.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_Apex_PnL] @Date [DATE] AS  
BEGIN

/******************************************************************************************************************************
Author: Sarah Benchitrit
Date: 2021-07-25
Description: Daily SP / Apex PnL for Middle Office
 
**************************
** Change History
**************************
Date					Author			SR/PR		 Description 
----                    ----------		-------		-----------------------------------
2023-11-05				Sarah						Check if Apex tables are ready before running the script
2023-11-16				Sarah						Reverse previous change
2024-02-15				NirW						Changed BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks to Dealing_dbo.Dealing_DailyZeroPnL_Stocks
*******************************************************************************************************************************/

-- EXEC [Dealing_dbo].[SP_Apex_PnL] '2023-11-06'

--DECLARE @Date DATE = '2023-11-03'
DECLARE @DateID INT = CASE WHEN (SELECT dd.IsBankHoliday FROM DWH_dbo.Dim_Date dd WHERE dd.DateKey = Dealing_dbo.DateToDateID(@Date)) = 'Y' -- When @Date is a bank holiday, take the NOP End from the day before
						THEN Dealing_dbo.DateToDateID(DATEADD(DAY,-1,@Date))
						ELSE Dealing_dbo.DateToDateID(@Date) END
DECLARE @FridayBefore DATE = CASE WHEN @DateID BETWEEN 20230101 AND 20230107 THEN '2022-12-30' ELSE
CASE WHEN (SELECT DayNumberOfWeek_Sun_Start FROM DWH_dbo.Dim_Date WHERE DateKey = @DateID) = 7
											THEN DATEADD(day,-1,@Date)
								ELSE (SELECT FullDate FROM DWH_dbo.Dim_Date 
										WHERE SSWeekNumberOfYear = (SELECT SSWeekNumberOfYear FROM DWH_dbo.Dim_Date WHERE DateKey = @DateID)-1  
											AND CalendarYear = (SELECT CalendarYear FROM DWH_dbo.Dim_Date WHERE DateKey = @DateID)
											AND DayNumberOfWeek_Sun_Start = 6) END END-- Friday before even if @Date is a Saturday (which would mean- same week)
DECLARE @FridayBeforeID INT = CASE WHEN (SELECT dd.IsBankHoliday FROM DWH_dbo.Dim_Date dd WHERE dd.DateKey = Dealing_dbo.DateToDateID(@FridayBefore)) = 'Y' -- When @FridayBefore is a bank holiday, take the NOP Start from the day before
						THEN Dealing_dbo.DateToDateID(DATEADD(DAY,-1,@FridayBefore))
								WHEN @FridayBefore = '2022-04-15' THEN 20220414 -- manual fix, in our DB this day (easter) is wrongly considered as a workday
						ELSE Dealing_dbo.DateToDateID(@FridayBefore) END
DECLARE @SaturdayBefore DATE = DATEADD(DAY,1,@FridayBefore)
DECLARE @SaturdayBeforeID INT = Dealing_dbo.DateToDateID(@SaturdayBefore)

declare @PreviousDay date = CASE WHEN (SELECT DayNumberOfWeek_Sun_Start FROM DWH_dbo.Dim_Date WHERE DateKey = @DateID) = 2
											THEN DATEADD(day,-3,@Date)
								ELSE dateadd(day,-1,@Date) end -- Skip the weekend on the daily report
declare @PreviousDayID int = Dealing_dbo.DateToDateID(@PreviousDay)


--PRINT @Date
--PRINT @FridayBefore
--PRINT @SaturdayBefore



--======= Run dependency if need to re-run the SP on a specific day =======

IF NOT EXISTS (SELECT TOP 1 * FROM Dealing_staging.PriceLog_History_CurrencyPrice WHERE etr_ymd = @Date )  
    BEGIN 
        DECLARE @table VARCHAR(500) = 'Dealing_staging.PriceLog_History_CurrencyPrice'
        EXEC [Dealing_staging].[SP_Copy_Temporary_Data] @dest_table = @table, @fromdate = @Date, @todate = @Date
    END
--=========================================================================


--------------------
---- Apex instruments table to find InstrumentID (ISIN/CUSIP/Symbol don't always match)
--------------------

IF OBJECT_ID('tempdb..#Apex_Ins1') IS NOT NULL
DROP TABLE #Apex_Ins1

CREATE TABLE #Apex_Ins1
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT DISTINCT InstrumentID, InstrumentDisplayName, ta.Symbol,ta.Cusip,ta.ISIN
FROM Dealing_staging.LP_APEX_EXT872_3EU_217314 ta WITH (NOLOCK)
LEFT JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON ta.Symbol = di.Symbol AND di.InstrumentTypeID IN (5,6) 
AND di.Exchange IN ('NASDAQ','NYSE','Nasdaq','Chicago Board Options Exchange','CBOE','OTCMKTS','OTC Markets Stock Exchange')
AND di.Tradable=1
WHERE ta.ReportDateID >= @FridayBeforeID

Create CLUSTERED index #Apex_Ins1 on #Apex_Ins1 (InstrumentID) 


IF OBJECT_ID('tempdb..#Apex_Ins2') IS NOT NULL
DROP TABLE #Apex_Ins2

CREATE TABLE #Apex_Ins2
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT DISTINCT InstrumentID, InstrumentDisplayName, ta.Symbol,ta.Cusip,ta.ISIN
FROM Dealing_staging.LP_APEX_EXT872_3EU_217314 ta WITH (NOLOCK)
left JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON ta.ISIN = di.ISINCode AND di.InstrumentTypeID IN (5,6) 
AND di.Exchange IN ('NASDAQ','NYSE','Nasdaq','Chicago Board Options Exchange','CBOE','OTCMKTS','OTC Markets Stock Exchange')
AND di.Tradable=1
WHERE  di.InstrumentID NOT IN (SELECT InstrumentID FROM #Apex_Ins1 ai WHERE ai.InstrumentID IS NOT NULL) 
AND ta.ReportDateID >= @FridayBeforeID



IF OBJECT_ID('tempdb..#Apex_Ins') IS NOT NULL
DROP TABLE #Apex_Ins

CREATE TABLE #Apex_Ins
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT
	  ISNULL(af.InstrumentID,af2.InstrumentID) InstrumentID
	  ,ISNULL(af.InstrumentDisplayName,af2.InstrumentDisplayName) InstrumentDisplayName
	  ,af.Symbol
	  ,af.ISIN
	  ,af.Cusip
FROM #Apex_Ins1 af
LEFT JOIN  #Apex_Ins2 af2
ON af.Symbol = af2.Symbol AND af.ISIN = af2.ISIN AND af.Cusip = af2.Cusip


--SELECT * FROM #Apex_Ins ai

-------------
-- NOP Start/End
-------------

--Get eToro rates and conversion rates at end of trading session (not EOD / 24:00)

IF OBJECT_ID('tempdb..#Rates_raw') IS NOT NULL
DROP TABLE #Rates_raw

CREATE TABLE #Rates_raw 
(InstrumentID INT
	,Occurred DATE
	,Ask decimal(16,6)
	,Bid decimal(16,6)
) 
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN)

declare @Day date = @FridayBefore;
while @Day <= @Date
begin

DECLARE @start DATETIME = @Day
DECLARE @end DATETIME = case when datepart(weekday,@Day) = 6 then DATEADD(hour, 21.5, cast(@Day as datetime)) -- Markets close at 21:30 on Fridays
							else DATEADD(hour, 22, cast(@Day as datetime)) end -- 22:00 on weekdays

INSERT INTO #Rates_raw

SELECT a.InstrumentID
		,a.Occurred
		,a.AskSpreaded
		,a.BidSpreaded
			FROM (SELECT cpa.InstrumentID
					,CAST(cpa.Occurred AS DATE) AS Occurred
					,cpa.AskSpreaded
					,cpa.BidSpreaded
					,ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY PriceRateID DESC) AS rn
			FROM  Dealing_staging.PriceLog_History_CurrencyPrice cpa WITH (NOLOCK)   
			WHERE cpa.Occurred >= @start
			AND cpa.Occurred < @end) a
WHERE rn = 1      

set @Day = dateadd(day,1,@Day);
end;


--SELECT * FROM #Rates_raw rr where InstrumentID = 1001

IF OBJECT_ID('tempdb..#Rates') IS NOT NULL
DROP TABLE #Rates

CREATE TABLE #Rates
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT Dealing_dbo.DateToDateID(rr.Occurred) as OccurredDateID
,di.InstrumentID
,di.BuyCurrency
,di.SellCurrency
,di.BuyCurrencyID
,di.SellCurrencyID
--,rr.Bid
--,rr.Ask
,case when SellCurrencyID = 666 then rr.Bid/100 else rr.Bid end Bid -- convert GBPX to GBP
,case when SellCurrencyID = 666 then rr.Ask/100 else rr.Ask end Ask
FROM #Rates_raw rr
JOIN DWH_dbo.Dim_Instrument di
ON rr.InstrumentID = di.InstrumentID
--WHERE Occurred = '20210921'
WHERE Occurred BETWEEN @FridayBefore AND @Date

--select * from #Rates where InstrumentID = 1005


-- NOP Start (Friday EOD of the previous week)

IF OBJECT_ID('tempdb..#NOPStart_ApexFiles') IS NOT NULL -- WTD
DROP TABLE #NOPStart_ApexFiles

CREATE TABLE #NOPStart_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
 
SELECT ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,(CASE WHEN TradeQuantity like '%e+%' THEN CAST(LEFT(TradeQuantity,CHARINDEX('e+',TradeQuantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(TradeQuantity,3) AS INT)) ELSE TradeQuantity END)
			AS TradeQuantity_Start
		,p.Bid AS Price_Start_DB
		,cast(lp.ClosingPrice as Decimal(16,6)) as Price_Start
	  ,(CASE WHEN MarketValue like '%e+%' THEN CAST(LEFT(MarketValue,CHARINDEX('e+',MarketValue)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(MarketValue,3) AS INT)) ELSE MarketValue END)
			AS NOP_Start
FROM Dealing_staging.LP_APEX_EXT982_3EU lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Symbol = ai.Symbol AND lp.CUSIP = ai.Cusip
LEFT JOIN #Rates p
ON ai.InstrumentID = p.InstrumentID AND ReportDateID = OccurredDateID
WHERE ReportDateID = @FridayBeforeID
GROUP BY lp.ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,lp.TradeQuantity
		,p.Bid
		,lp.ClosingPrice
		,lp.MarketValue



IF OBJECT_ID('tempdb..#NOPStart_ApexFiles_Daily') IS NOT NULL -- Daily
DROP TABLE #NOPStart_ApexFiles_Daily

CREATE TABLE #NOPStart_ApexFiles_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
 
SELECT ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,(CASE WHEN TradeQuantity like '%e+%' THEN CAST(LEFT(TradeQuantity,CHARINDEX('e+',TradeQuantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(TradeQuantity,3) AS INT)) ELSE TradeQuantity END)
			AS TradeQuantity_Start
		,p.Bid AS Price_Start_DB
		,cast(lp.ClosingPrice as Decimal(16,6)) as Price_Start
	  ,(CASE WHEN MarketValue like '%e+%' THEN CAST(LEFT(MarketValue,CHARINDEX('e+',MarketValue)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(MarketValue,3) AS INT)) ELSE MarketValue END)
			AS NOP_Start
FROM Dealing_staging.LP_APEX_EXT982_3EU lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Symbol = ai.Symbol AND lp.CUSIP = ai.Cusip
LEFT JOIN #Rates p
ON ai.InstrumentID = p.InstrumentID AND ReportDateID = OccurredDateID
WHERE ReportDateID = @PreviousDayID
GROUP BY lp.ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,lp.TradeQuantity
		,p.Bid
		,lp.ClosingPrice
		,lp.MarketValue



-- NOP End (Current day EOD)

IF OBJECT_ID('tempdb..#NOPEnd_ApexFiles') IS NOT NULL
DROP TABLE #NOPEnd_ApexFiles

CREATE TABLE #NOPEnd_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,(CASE WHEN TradeQuantity like '%e+%' THEN CAST(LEFT(TradeQuantity,CHARINDEX('e+',TradeQuantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(TradeQuantity,3) AS INT)) ELSE TradeQuantity END)
			AS TradeQuantity_End
		,p.Bid AS Price_End_DB
		,cast(lp.ClosingPrice as Decimal(16,6)) as Price_End
	  ,(CASE WHEN MarketValue like '%e+%' THEN CAST(LEFT(MarketValue,CHARINDEX('e+',MarketValue)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(MarketValue,3) AS INT)) ELSE MarketValue END)
			AS NOP_End
FROM Dealing_staging.LP_APEX_EXT982_3EU lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Symbol = ai.Symbol AND lp.CUSIP = ai.Cusip
LEFT JOIN #Rates p
ON ai.InstrumentID = p.InstrumentID AND ReportDateID = OccurredDateID
WHERE ReportDateID = @DateID 
GROUP BY lp.ReportDateID
		,ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,lp.TradeQuantity
		,p.Bid
		,lp.ClosingPrice
		,lp.MarketValue



-- NOP Start and End

IF OBJECT_ID('tempdb..#NOP') IS NOT NULL  -- WTD
DROP TABLE #NOP

CREATE TABLE #NOP
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ISNULL(s.InstrumentID,e.InstrumentID) InstrumentID
		,ISNULL(s.InstrumentDisplayName,e.InstrumentDisplayName) InstrumentDisplayName
		,ISNULL(s.Symbol, e.Symbol) Symbol
		,ISNULL(s.AccountNumber,e.AccountNumber) AccountNumber
	  ,s.NOP_Start
	  ,s.Price_Start
	  ,s.Price_Start_DB
	  ,s.TradeQuantity_Start*s.Price_Start_DB AS NOP_Start_DBPrice
	  ,e.NOP_End
	  ,e.Price_End
	  ,e.Price_End_DB
	  ,e.TradeQuantity_End*e.Price_End_DB AS NOP_End_DBPrice
FROM #NOPStart_ApexFiles s
FULL JOIN #NOPEnd_ApexFiles e
ON s.Symbol = e.Symbol AND s.AccountNumber = e.AccountNumber


--SELECT * FROM #NOP n


IF OBJECT_ID('tempdb..#NOP_Daily') IS NOT NULL -- Daily
DROP TABLE #NOP_Daily

CREATE TABLE #NOP_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ISNULL(s.InstrumentID,e.InstrumentID) InstrumentID
		,ISNULL(s.InstrumentDisplayName,e.InstrumentDisplayName) InstrumentDisplayName
		,ISNULL(s.Symbol, e.Symbol) Symbol
		,ISNULL(s.AccountNumber,e.AccountNumber) AccountNumber
	  ,s.NOP_Start
	  ,s.Price_Start
	  ,s.Price_Start_DB
	  ,s.TradeQuantity_Start*s.Price_Start_DB AS NOP_Start_DBPrice
	  ,e.NOP_End
	  ,e.Price_End
	  ,e.Price_End_DB
	  ,e.TradeQuantity_End*e.Price_End_DB AS NOP_End_DBPrice
FROM #NOPStart_ApexFiles_Daily s
FULL JOIN #NOPEnd_ApexFiles e
ON s.Symbol = e.Symbol AND s.AccountNumber = e.AccountNumber


---------------
-- Trades
---------------
 
-- Aggregated from the previous Friday EOD (ie from Saturday) until current day

IF OBJECT_ID('tempdb..#Trades_ApexFiles') IS NOT NULL -- WTD
DROP TABLE #Trades_ApexFiles

CREATE TABLE #Trades_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,SUM((CASE WHEN Quantity like '%e+%' THEN CAST(LEFT(Quantity,CHARINDEX('e+',Quantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(Quantity,3) AS INT)) 
					ELSE CAST(Quantity AS DECIMAL(16,6)) END)*CAST(lp.Price AS DECIMAL(16,6)) + CAST(lp.FeeSec AS DECIMAL(16,6)) 
					+ case when Fee5 <> '' then CAST(lp.Fee5 AS DECIMAL(16,6)) else 0 END) AS Trades
		,SUM(abs((CASE WHEN Quantity like '%e+%' THEN CAST(LEFT(Quantity,CHARINDEX('e+',Quantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(Quantity,3) AS INT)) 
					ELSE CAST(Quantity AS DECIMAL(16,6)) END)*CAST(lp.Price AS DECIMAL(16,6)) + CAST(lp.FeeSec AS DECIMAL(16,6)) 
					+ case when Fee5 <> '' then CAST(lp.Fee5 AS DECIMAL(16,6)) else 0 END)) AS Volume
FROM Dealing_staging.LP_APEX_EXT872_3EU_217314 lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Symbol = ai.Symbol AND lp.ISIN = ai.ISIN AND lp.Cusip = ai.Cusip
WHERE ReportDateID BETWEEN @SaturdayBeforeID AND @DateID
GROUP BY ai.InstrumentID 
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		
--SELECT * FROM #Trades_ApexFiles taf


IF OBJECT_ID('tempdb..#Trades_ApexFiles_Daily') IS NOT NULL --Daily
DROP TABLE #Trades_ApexFiles_Daily

CREATE TABLE #Trades_ApexFiles_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ai.InstrumentID
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber
		,SUM((CASE WHEN Quantity like '%e+%' THEN CAST(LEFT(Quantity,CHARINDEX('e+',Quantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(Quantity,3) AS INT)) 
					ELSE CAST(Quantity AS DECIMAL(16,6)) END)*CAST(lp.Price AS DECIMAL(16,6)) + CAST(lp.FeeSec AS DECIMAL(16,6)) 
					+ case when Fee5 <> '' then CAST(lp.Fee5 AS DECIMAL(16,6)) else 0 END) AS Trades
		,SUM(abs((CASE WHEN Quantity like '%e+%' THEN CAST(LEFT(Quantity,CHARINDEX('e+',Quantity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(Quantity,3) AS INT)) 
					ELSE CAST(Quantity AS DECIMAL(16,6)) END)*CAST(lp.Price AS DECIMAL(16,6)) + CAST(lp.FeeSec AS DECIMAL(16,6)) 
					+ case when Fee5 <> '' then CAST(lp.Fee5 AS DECIMAL(16,6)) else 0 END)) AS Volume
FROM Dealing_staging.LP_APEX_EXT872_3EU_217314 lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Symbol = ai.Symbol AND lp.ISIN = ai.ISIN AND lp.Cusip = ai.Cusip
WHERE ReportDateID = @DateID
GROUP BY ai.InstrumentID 
		,ai.InstrumentDisplayName
		,lp.Symbol
		,lp.AccountNumber



--------------
-- Dividends and additional fees
--------------

-- Aggregated from the previous Friday EOD (ie from Saturday) until current day

IF OBJECT_ID('tempdb..#Dividends_ApexFiles') IS NOT NULL --WTD
DROP TABLE #Dividends_ApexFiles

CREATE TABLE #Dividends_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ai.InstrumentID
		,ai.InstrumentDisplayName
		,ai.Symbol
		,lp.AccountNumber
	  ,SUM(case when lp.TerminalID = '$+DIV' then -CAST(lp.Amount AS DECIMAL(16,6)) else 0 end) AS Dividends
	  ,sum(case when lp.TerminalID <> '$+DIV' then -CAST(lp.Amount AS DECIMAL(16,6)) else 0 end) as AdditionalFees
FROM Dealing_staging.LP_APEX_EXT869_3EU lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Cusip = ai.Cusip
WHERE lp.ReportDateID BETWEEN @SaturdayBeforeID AND @DateID 
		and lp.TerminalID not IN ('CSCSG','FWWRD','MGLOA','MGJNL')
GROUP BY ai.InstrumentID 
		,ai.InstrumentDisplayName
		,ai.Symbol
		,lp.AccountNumber

--select * from #Dividends_ApexFiles where AccountNumber = '3EU05025'


IF OBJECT_ID('tempdb..#Dividends_ApexFiles_Daily') IS NOT NULL --Daily
DROP TABLE #Dividends_ApexFiles_Daily

CREATE TABLE #Dividends_ApexFiles_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ai.InstrumentID
		,ai.InstrumentDisplayName
		,ai.Symbol
		,lp.AccountNumber
	  ,SUM(case when lp.TerminalID = '$+DIV' then -CAST(lp.Amount AS DECIMAL(16,6)) else 0 end) AS Dividends
	  ,sum(case when lp.TerminalID <> '$+DIV' then -CAST(lp.Amount AS DECIMAL(16,6)) else 0 end) as AdditionalFees
FROM Dealing_staging.LP_APEX_EXT869_3EU lp WITH (NOLOCK)
LEFT JOIN #Apex_Ins ai
ON lp.Cusip = ai.Cusip
WHERE lp.ReportDateID = @DateID 
		and lp.TerminalID not IN ('CSCSG','FWWRD','MGLOA','MGJNL')
GROUP BY ai.InstrumentID 
		,ai.InstrumentDisplayName
		,ai.Symbol
		,lp.AccountNumber


-----------
-- Equity Start/End
-----------


-- Equity Start (Friday EOD of the previous week)

IF OBJECT_ID('tempdb..#EquityStart_ApexFiles') IS NOT NULL --WTD
DROP TABLE #EquityStart_ApexFiles

CREATE TABLE #EquityStart_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ReportDateID
		,lp.AccountNumber
	  ,(CASE WHEN lp.TotalEquity like '%e+%' THEN CAST(LEFT(lp.TotalEquity,CHARINDEX('e+',lp.TotalEquity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(lp.TotalEquity,3) AS INT)) ELSE lp.TotalEquity END)
			AS Equity_Start
FROM Dealing_staging.LP_APEX_EXT981_3EU lp WITH (NOLOCK)
WHERE ReportDateID = @FridayBeforeID
GROUP BY lp.ReportDateID
		,lp.AccountNumber
		,lp.TotalEquity



IF OBJECT_ID('tempdb..#EquityStart_ApexFiles_Daily') IS NOT NULL -- Daily
DROP TABLE #EquityStart_ApexFiles_Daily

CREATE TABLE #EquityStart_ApexFiles_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ReportDateID
		,lp.AccountNumber
	  ,(CASE WHEN lp.TotalEquity like '%e+%' THEN CAST(LEFT(lp.TotalEquity,CHARINDEX('e+',lp.TotalEquity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(lp.TotalEquity,3) AS INT)) ELSE lp.TotalEquity END)
			AS Equity_Start
FROM Dealing_staging.LP_APEX_EXT981_3EU lp WITH (NOLOCK)
WHERE ReportDateID = @PreviousDayID
GROUP BY lp.ReportDateID
		,lp.AccountNumber
		,lp.TotalEquity



-- Equity End (Current day EOD)

IF OBJECT_ID('tempdb..#EquityEnd_ApexFiles') IS NOT NULL
DROP TABLE #EquityEnd_ApexFiles

CREATE TABLE #EquityEnd_ApexFiles
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ReportDateID
		,lp.AccountNumber
	  ,(CASE WHEN lp.TotalEquity like '%e+%' THEN CAST(LEFT(lp.TotalEquity,CHARINDEX('e+',lp.TotalEquity)-1) AS DECIMAL(16,6))*POWER(10,CAST(RIGHT(lp.TotalEquity,3) AS INT)) ELSE lp.TotalEquity END)
			AS Equity_End
FROM Dealing_staging.LP_APEX_EXT981_3EU lp WITH (NOLOCK)
WHERE ReportDateID = @DateID 
GROUP BY lp.ReportDateID
		,lp.AccountNumber
		,lp.TotalEquity




-- Equity Start and End

IF OBJECT_ID('tempdb..#Equity') IS NOT NULL --WTD
DROP TABLE #Equity

CREATE TABLE #Equity
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ISNULL(s.AccountNumber,e.AccountNumber) AccountNumber
	  ,s.Equity_Start
	  ,e.Equity_End
FROM #EquityStart_ApexFiles s
FULL JOIN #EquityEnd_ApexFiles e
ON s.AccountNumber = e.AccountNumber



IF OBJECT_ID('tempdb..#Equity_Daily') IS NOT NULL --Daily
DROP TABLE #Equity_Daily

CREATE TABLE #Equity_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT ISNULL(s.AccountNumber,e.AccountNumber) AccountNumber
	  ,s.Equity_Start
	  ,e.Equity_End
FROM #EquityStart_ApexFiles_Daily s
FULL JOIN #EquityEnd_ApexFiles e
ON s.AccountNumber = e.AccountNumber



IF OBJECT_ID('tempdb..#Transfers') IS NOT NULL --WTD
DROP TABLE #Transfers

CREATE TABLE #Transfers
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT t.AccountNumber
		,SUM(-t.Amount) AS Transfers
FROM Dealing_staging.LP_APEX_EXT869_3EU t WITH (NOLOCK)
WHERE ReportDateID BETWEEN @SaturdayBeforeID AND @DateID
		AND t.TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL')
GROUP BY t.AccountNumber



IF OBJECT_ID('tempdb..#Transfers_Daily') IS NOT NULL --Daily
DROP TABLE #Transfers_Daily

CREATE TABLE #Transfers_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT t.AccountNumber
		,SUM(-t.Amount) AS Transfers
FROM Dealing_staging.LP_APEX_EXT869_3EU t WITH (NOLOCK)
WHERE ReportDateID = @DateID
		AND t.TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL')
GROUP BY t.AccountNumber


----------
-- Dividends Per Account
----------

IF OBJECT_ID('tempdb..#Dividends_PerAcc') IS NOT NULL --WTD
DROP TABLE #Dividends_PerAcc

CREATE TABLE #Dividends_PerAcc
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT daf.AccountNumber
		,SUM(daf.Dividends) AS Dividends
FROM #Dividends_ApexFiles daf
GROUP BY daf.AccountNumber

--SELECT * FROM #Dividends_PerAcc dpa


IF OBJECT_ID('tempdb..#Dividends_PerAcc_Daily') IS NOT NULL --Daily
DROP TABLE #Dividends_PerAcc_Daily

CREATE TABLE #Dividends_PerAcc_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT daf.AccountNumber
		,SUM(daf.Dividends) AS Dividends
FROM #Dividends_ApexFiles_Daily daf
GROUP BY daf.AccountNumber

--------------
-- Zero
--------------

IF OBJECT_ID('tempdb..#AccountToHS') IS NOT NULL
DROP TABLE #AccountToHS

CREATE TABLE #AccountToHS (AccountNumber VARCHAR(50), HedgeServerID INT)
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN)

INSERT INTO #AccountToHS VALUES ('3EU05026',9)
INSERT INTO #AccountToHS VALUES ('3EU05025',112)
INSERT INTO #AccountToHS VALUES ('3EU05027',102)
INSERT INTO #AccountToHS VALUES ('3EU00101',223)
INSERT INTO #AccountToHS VALUES ('3EU05028',3)



IF OBJECT_ID('tempdb..#Zero') IS NOT NULL --WTD
DROP TABLE #Zero

CREATE TABLE #Zero
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT z.HedgeServerID
		,ath.AccountNumber
		,z.InstrumentID
		,SUM(TotalZero) AS Zero
FROM Dealing_dbo.Dealing_DailyZeroPnL_Stocks z WITH (NOLOCK)
JOIN #Apex_Ins ai
ON ai.InstrumentID = z.InstrumentID AND ai.InstrumentID IS NOT NULL
JOIN #AccountToHS ath
ON ath.HedgeServerID = z.HedgeServerID
WHERE Date BETWEEN @SaturdayBefore AND @Date
GROUP BY z.HedgeServerID
		,ath.AccountNumber
		,z.InstrumentID


IF OBJECT_ID('tempdb..#Zero_Daily') IS NOT NULL --Daily
DROP TABLE #Zero_Daily

CREATE TABLE #Zero_Daily
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT z.HedgeServerID
		,ath.AccountNumber
		,z.InstrumentID
		,SUM(TotalZero) AS Zero
FROM Dealing_dbo.Dealing_DailyZeroPnL_Stocks z WITH (NOLOCK)
JOIN #Apex_Ins ai
ON ai.InstrumentID = z.InstrumentID AND ai.InstrumentID IS NOT NULL
JOIN #AccountToHS ath
ON ath.HedgeServerID = z.HedgeServerID
WHERE Date = @Date
GROUP BY z.HedgeServerID
		,ath.AccountNumber
		,z.InstrumentID

--------
-- Final
--------

-- WTD

DELETE FROM Dealing_dbo.Dealing_Apex_PnL
WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Apex_PnL
(Date
	,AccountNumber
	,Symbol
	,NOP_Start
	,NOP_Start_DBPrice
	,NOP_End
	,NOP_End_DBPrice
	,Trades
	,Dividends
	,PnL
	,PnL_DBPrice
		,UpdateDate
		,InstrumentID
		,InstrumentDisplayName
	,Price_Start
	,Price_Start_DB
	,Price_End
	,Price_End_DB
	,AdditionalFees
	,Volume
	,Zero
)

SELECT @Date
		,COALESCE(n.AccountNumber,taf.AccountNumber,d.AccountNumber) AS AccountNumber
		,COALESCE(n.Symbol,taf.Symbol,d.Symbol) AS Symbol
		,n.NOP_Start
		,n.NOP_Start_DBPrice
		,n.NOP_End
		,n.NOP_End_DBPrice
		,taf.Trades
		,d.Dividends
		,ISNULL(n.NOP_End,0) - ISNULL(n.NOP_Start,0) - ISNULL(taf.Trades,0) + isnull(d.Dividends,0) + isnull(d.AdditionalFees,0) AS PnL
		,ISNULL(n.NOP_End_DBPrice,0) - ISNULL(n.NOP_Start_DBPrice,0) - ISNULL(taf.Trades,0) + isnull(d.Dividends,0) + isnull(d.AdditionalFees,0) AS PnL_DBPrice
		,GETDATE() AS UpdateDate
		,COALESCE(n.InstrumentID,taf.InstrumentID,d.InstrumentID) InstrumentID
		,COALESCE(n.InstrumentDisplayName,taf.InstrumentDisplayName,d.InstrumentDisplayName) InstrumentDisplayName
	  ,n.Price_Start
	  ,n.Price_Start_DB
	  ,n.Price_End
	  ,n.Price_End_DB
	  ,d.AdditionalFees
	  ,taf.Volume
	  ,z.Zero
FROM #NOP n
FULL OUTER JOIN #Trades_ApexFiles taf
ON n.Symbol = taf.Symbol AND n.AccountNumber = taf.AccountNumber
FULL OUTER JOIN #Dividends_ApexFiles d
ON n.Symbol = d.Symbol AND n.AccountNumber = d.AccountNumber
LEFT JOIN #Zero z
ON z.AccountNumber = COALESCE(n.AccountNumber,taf.AccountNumber,d.AccountNumber) AND z.InstrumentID = COALESCE(n.InstrumentID,taf.InstrumentID,d.InstrumentID)



DELETE FROM Dealing_dbo.Dealing_Apex_PnL_EE WHERE Date = @Date
INSERT INTO Dealing_dbo.Dealing_Apex_PnL_EE
(Date
	,AccountNumber
	,Equity_Start
	,Equity_End
	,Transfers
	,PnL
	,UpdateDate
	,Dividends)

SELECT @Date
		,ISNULL(ISNULL(e.AccountNumber,t.AccountNumber),d.AccountNumber) AS AccountNumber
		,e.Equity_Start
		,e.Equity_End
		,t.Transfers
		,ISNULL(e.Equity_End,0) - ISNULL(e.Equity_Start,0) - ISNULL(t.Transfers,0) AS PnL
		,GETDATE() AS UpdateDate
		,d.Dividends
FROM #Equity e
FULL OUTER JOIN #Transfers t
ON t.AccountNumber = e.AccountNumber
FULL OUTER JOIN #Dividends_PerAcc d
ON e.AccountNumber = d.AccountNumber


-- Daily

DELETE FROM Dealing_dbo.Dealing_Apex_PnL_Daily
WHERE Date = @Date

INSERT INTO Dealing_dbo.Dealing_Apex_PnL_Daily
(Date
	,AccountNumber
	,Symbol
	,NOP_Start
	,NOP_Start_DBPrice
	,NOP_End
	,NOP_End_DBPrice
	,Trades
	,Dividends
	,PnL
	,PnL_DBPrice
		,UpdateDate
		,InstrumentID
		,InstrumentDisplayName
	,Price_Start
	,Price_Start_DB
	,Price_End
	,Price_End_DB
	,AdditionalFees
	,Volume
	,Zero
)

SELECT @Date
		,COALESCE(n.AccountNumber,taf.AccountNumber,d.AccountNumber) AS AccountNumber
		,COALESCE(n.Symbol,taf.Symbol,d.Symbol) AS Symbol
		,n.NOP_Start
		,n.NOP_Start_DBPrice
		,n.NOP_End
		,n.NOP_End_DBPrice
		,taf.Trades
		,d.Dividends
		,ISNULL(n.NOP_End,0) - ISNULL(n.NOP_Start,0) - ISNULL(taf.Trades,0) + isnull(d.Dividends,0) + isnull(d.AdditionalFees,0) AS PnL
		,ISNULL(n.NOP_End_DBPrice,0) - ISNULL(n.NOP_Start_DBPrice,0) - ISNULL(taf.Trades,0) + isnull(d.Dividends,0) + isnull(d.AdditionalFees,0) AS PnL_DBPrice
		,GETDATE() AS UpdateDate
		,COALESCE(n.InstrumentID,taf.InstrumentID,d.InstrumentID) InstrumentID
		,COALESCE(n.InstrumentDisplayName,taf.InstrumentDisplayName,d.InstrumentDisplayName) InstrumentDisplayName
	  ,n.Price_Start
	  ,n.Price_Start_DB
	  ,n.Price_End
	  ,n.Price_End_DB
	  ,d.AdditionalFees
	  ,taf.Volume
	  ,z.Zero
FROM #NOP_Daily n
FULL OUTER JOIN #Trades_ApexFiles_Daily taf
ON n.Symbol = taf.Symbol AND n.AccountNumber = taf.AccountNumber
FULL OUTER JOIN #Dividends_ApexFiles_Daily d
ON n.Symbol = d.Symbol AND n.AccountNumber = d.AccountNumber
LEFT JOIN #Zero_Daily z
ON z.AccountNumber = COALESCE(n.AccountNumber,taf.AccountNumber,d.AccountNumber) AND z.InstrumentID = COALESCE(n.InstrumentID,taf.InstrumentID,d.InstrumentID)



DELETE FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily WHERE Date = @Date
INSERT INTO Dealing_dbo.Dealing_Apex_PnL_EE_Daily
(Date
	,AccountNumber
	,Equity_Start
	,Equity_End
	,Transfers
	,PnL
	,UpdateDate
	,Dividends)

SELECT @Date
		,ISNULL(ISNULL(e.AccountNumber,t.AccountNumber),d.AccountNumber) AS AccountNumber
		,e.Equity_Start
		,e.Equity_End
		,t.Transfers
		,ISNULL(e.Equity_End,0) - ISNULL(e.Equity_Start,0) - ISNULL(t.Transfers,0) AS PnL
		,GETDATE() AS UpdateDate
		,d.Dividends
FROM #Equity_Daily e
FULL OUTER JOIN #Transfers_Daily t
ON t.AccountNumber = e.AccountNumber
FULL OUTER JOIN #Dividends_PerAcc_Daily d
ON e.AccountNumber = d.AccountNumber


END



--SELECT max(Date) FROM Dealing_dbo.Dealing_Apex_PnL WHERE Date = '2023-07-31' order by AccountNumber,Symbol
--SELECT * FROM Dealing_dbo.Dealing_Apex_PnL_EE WHERE Date = '2023-07-31' ORDER BY AccountNumber

--SELECT * FROM Dealing_dbo.Dealing_Apex_PnL_Daily WHERE Date = '2022-06-16' 
--SELECT * FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily WHERE Date = '2022-06-16'
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_Apex_PnL` | synapse_sp | Dealing_dbo | SP_Apex_PnL | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Apex_PnL.sql` |
| `DWH_dbo.Dim_Date` | unresolved | DWH_dbo | Dim_Date | `—` |
| `Dealing_staging.PriceLog_History_CurrencyPrice` | unresolved | Dealing_staging | PriceLog_History_CurrencyPrice | `—` |
| `Dealing_staging.LP_APEX_EXT872_3EU_217314` | unresolved | Dealing_staging | LP_APEX_EXT872_3EU_217314 | `—` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `Dealing_staging.LP_APEX_EXT982_3EU` | unresolved | Dealing_staging | LP_APEX_EXT982_3EU | `—` |
| `Dealing_staging.LP_APEX_EXT869_3EU` | unresolved | Dealing_staging | LP_APEX_EXT869_3EU | `—` |
| `Dealing_staging.LP_APEX_EXT981_3EU` | unresolved | Dealing_staging | LP_APEX_EXT981_3EU | `—` |
| `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` | synapse | Dealing_dbo | Dealing_DailyZeroPnL_Stocks | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_DailyZeroPnL_Stocks.md` |
| `Dealing_dbo.Dealing_Apex_PnL` | synapse | Dealing_dbo | Dealing_Apex_PnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL.md` |
| `Dealing_dbo.Dealing_Apex_PnL_EE` | synapse | Dealing_dbo | Dealing_Apex_PnL_EE | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL_EE.md` |
| `Dealing_dbo.Dealing_Apex_PnL_Daily` | synapse | Dealing_dbo | Dealing_Apex_PnL_Daily | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Apex_PnL_Daily.md` |

