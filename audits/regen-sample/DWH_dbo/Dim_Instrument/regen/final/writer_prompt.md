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
- **Object**: `Dim_Instrument`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/DWH_dbo/Dim_Instrument/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_Instrument\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_Instrument\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Tables\DWH_dbo.Dim_Instrument.sql`

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

# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_Instrument`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_Instrument.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_Instrument]
(
	[InstrumentID] [int] NOT NULL,
	[InstrumentTypeID] [int] NOT NULL,
	[InstrumentType] [varchar](50) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[DWHInstrumentID] [int] NOT NULL,
	[StatusID] [int] NULL,
	[BuyCurrencyID] [int] NOT NULL,
	[SellCurrencyID] [int] NOT NULL,
	[BuyCurrency] [varchar](50) NOT NULL,
	[SellCurrency] [varchar](50) NOT NULL,
	[TradeRange] [int] NOT NULL,
	[DollarRatio] [numeric](18, 0) NOT NULL,
	[PipDifferenceThreshold] [bigint] NULL,
	[IsMajorID] [int] NOT NULL,
	[IsMajor] [varchar](3) NOT NULL,
	[UpdateDate] [datetime] NULL,
	[InsertDate] [datetime] NULL,
	[InstrumentDisplayName] [varchar](100) NULL,
	[Industry] [varchar](max) NULL,
	[CompanyInfo] [varchar](max) NULL,
	[Exchange] [varchar](max) NULL,
	[ISINCode] [varchar](30) NULL,
	[ISINCountryCode] [varchar](15) NULL,
	[Tradable] [int] NULL,
	[Symbol] [varchar](100) NULL,
	[ReceivedOnPriceServer] [datetime] NULL,
	[BonusCreditUsePercent] [int] NULL,
	[SymbolFull] [varchar](100) NULL,
	[CUSIP] [varchar](500) NULL,
	[Precision] [int] NULL,
	[AllowBuy] [int] NULL,
	[AllowSell] [int] NULL,
	[AssetClass] [nvarchar](400) NULL,
	[IndustryGroup] [nvarchar](400) NULL,
	[ADV_Last3Months] [numeric](20, 4) NULL,
	[MKTcap] [numeric](20, 4) NULL,
	[SharesOutStanding] [numeric](20, 4) NULL,
	[VisibleInternallyOnly] [int] NULL,
	[PlatformSector] [varchar](max) NULL,
	[PlatformIndustry] [varchar](max) NULL,
	[IsFuture] [int] NULL,
	[Multiplier] [decimal](38, 18) NULL,
	[ProviderID] [int] NULL,
	[ProviderMarginPerLot] [decimal](38, 18) NULL,
	[eToroMarginPerLot] [decimal](38, 18) NULL,
	[SettlementTime] [time](7) NULL,
	[OperationMode] [int] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[InstrumentID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 9 upstream wiki(s). Read EACH one in full.


### Upstream `etoro.Trade.GetInstrument` — production
- **Resolved as**: `etoro.Trade.GetInstrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Views\Trade.GetInstrument.md`

# Trade.GetInstrument

> Instrument deal view that joins Instrument with currency abbreviations and metadata to produce display-ready instrument rows with Name as "BUY/SELL", filtering out InstrumentID=0 and NULL InstrumentTypeID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrument is the primary instrument view used across the trading platform to expose instrument definitions with human-readable display data. It answers: "What instruments are tradeable, and how do I show them in the UI?" The view joins Trade.Instrument with Dictionary.Currency (for buy and sell abbreviations), Trade.InstrumentMetaData (for InstrumentTypeID, Industry, ExchangeID), and computes a display Name as "BUY/SELL" (e.g., EUR/USD, GBP/USD).

The view exists so procedures and APIs can get a single row per instrument with all the attributes needed for display, filtering, and validation. Without it, every caller would need to replicate the JOIN and WHERE logic. Trade.InsertDividend, Trade.GetInstrumentInterestRates, Trade.GetPositionsForFeeBulkGeneral, Trade.CalcOverNightFeeRates, Trade.GetInstrumentWithSpread, and dozens of other procedures use this view to resolve InstrumentTypeID, Name, and trading parameters.

Data flows: The view reads from Trade.Instrument, Dictionary.Currency (twice for buy/sell), and Trade.InstrumentMetaData with NOLOCK. It filters out InstrumentID=0 (system placeholder) and instruments with NULL InstrumentTypeID (incomplete metadata). Rows appear when Instrument and InstrumentMetaData exist and InstrumentMetaData has a valid InstrumentTypeID.

---

## 2. Business Logic

### 2.1 Display Name as BUY/SELL Abbreviation

**What**: The Name column concatenates buy and sell currency abbreviations for display (e.g., EUR/USD).

**Columns/Parameters Involved**: `Name`, `TDCUR_BUY.Abbreviation`, `TDCUR_SEL.Abbreviation`

**Rules**:
- Name = TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation
- For forex: literal pair (EUR/USD, GBP/USD, NZD/USD)
- For stocks: BuyCurrencyID = InstrumentID (asset), SellCurrencyID = denomination (EUR, USD, GBX), so Name shows as "ASSET/CURRENCY"

**Diagram**:
```
Forex:   Buy=EUR, Sell=USD -> Name = "EUR/USD"
Stock:   Buy=1203(Bayer), Sell=EUR -> Name = "Bayer/EUR" (abbreviation from Dictionary.Currency)
```

### 2.2 InstrumentTypeID from Metadata

**What**: InstrumentTypeID comes from InstrumentMetaData, not Instrument. Only instruments with non-NULL InstrumentTypeID appear.

**Columns/Parameters Involved**: `IMD.InstrumentTypeID`, `TSISR.InstrumentID`

**Rules**:
- WHERE IMD.InstrumentTypeID IS NOT NULL - excludes instruments without asset-class metadata
- InstrumentTypeID: 1=Forex, 5=Stocks, 10=Crypto, etc. (Dictionary.CurrencyType)
- Trade.InsertDividend and Trade.UpdateDividend use InstrumentTypeID IN (4,5,6) to restrict dividend-eligible instruments

### 2.3 Exclusion of System Placeholder

**What**: InstrumentID=0 is excluded from the view.

**Columns/Parameters Involved**: `TSISR.InstrumentID`

**Rules**:
- WHERE TSISR.InstrumentID != 0
- InstrumentID=0 is the system placeholder in Trade.Instrument and Dictionary.Currency; never used for real trading

---

## 3. Data Overview

| InstrumentID | Name | BuyCurrencyID | SellCurrencyID | InstrumentTypeID | DollarRatio | IsMajor | Industry | ExchangeID | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 1 | EUR/USD | 2 | 1 | 1 | 1 | true | Basic Materials | 1 | Major forex pair. InstrumentTypeID=1 (Forex). Standard DollarRatio for spot. |
| 2 | GBP/USD | 3 | 1 | 1 | 1 | true | NULL | 1 | GBP/USD forex. Industry NULL for forex (industry applies to stocks). |
| 3 | NZD/USD | 8 | 1 | 1 | 1 | true | NULL | 17 | NZD/USD with different ExchangeID for price routing. |
| 4 | USD/CAD | 1 | 7 | 1 | 1 | true | NULL | 1 | USD/CAD - inverted pair notation. |
| 5 | JPY/USD | 4 | 1 | 1 | 100 | false | NULL | 1 | USD/JPY. DollarRatio=100 because JPY quoted in hundredths. IsMajor=false in sample. |

**Selection criteria**: Picked from live MCP sample. Major forex pairs showing Name format, DollarRatio (1 vs 100 for JPY), and Industry NULL for forex.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. |
| 2 | BuyCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. |
| 3 | SellCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. |
| 4 | InstrumentTypeID | int | YES | - | CODE-BACKED | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. |
| 5 | Name | varchar | NO | - | CODE-BACKED | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). |
| 6 | TradeRange | smallint | NO | - | CODE-BACKED | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. |
| 7 | DollarRatio | decimal(8,2) | NO | - | CODE-BACKED | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. |
| 8 | Passport | timestamp | NO | - | CODE-BACKED | Row version/concurrency token. From Trade.Instrument. |
| 9 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | Max pip difference for price validation. From Trade.Instrument. |
| 10 | IsMajor | bit | NO | - | CODE-BACKED | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. |
| 11 | Industry | varchar(max) | YES | - | CODE-BACKED | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. |
| 12 | ExchangeID | int | YES | - | CODE-BACKED | FK to Price.Exchange. Primary exchange for price feed routing. From Trade.InstrumentMetaData. |
| 13 | OperationMode | tinyint | YES | - | CODE-BACKED | Trading operation mode: 0=Standard, 1=Alternate (e.g., European stocks in non-USD). From Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, BuyCurrencyID, SellCurrencyID | Trade.Instrument | Base/Lookup | Core instrument definition |
| BuyCurrencyID | Dictionary.Currency | Lookup | Buy-side abbreviation |
| SellCurrencyID | Dictionary.Currency | Lookup | Sell-side abbreviation |
| InstrumentTypeID | Dictionary.CurrencyType | Lookup | Asset class |
| ExchangeID | Price.Exchange | Lookup | Primary exchange |
| Industry | Trade.InstrumentMetaData (StocksIndustryID) | Lookup | Industry sector for stocks |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertDividend | WHERE | Reader | Validates InstrumentTypeID IN (4,5,6) |
| Trade.UpdateDividend | WHERE | Reader | Same validation |
| Trade.GetInstrumentInterestRates | FROM | Reader | Instrument data for interest rates |
| Trade.GetInstrumentInterestRates_TRDOPS | FROM | Reader | Same |
| Trade.GetPositionsForFeeBulkGeneral | INNER JOIN | Reader | Fee calculation by instrument |
| Trade.GetPositionsForFeeProcess | INNER JOIN | Reader | Same |
| Trade.CalcOverNightFeeRates | FROM | Reader | Overnight fee rates |
| Trade.GetInstrumentWithSpread | FROM | Reader | Instrument with spread data |
| Trade.CM_GetLeveragesRestrictionsWhiteList | INNER JOIN | Reader | Leverage restrictions |
| Trade.CM_InsertLeveragesRestrictionsWhiteList | WHERE | Reader | Instrument filter |
| Trade.FundMgrSync | INNER JOIN | Reader | Fund manager sync |
| Trade.GetProviderToInstrumentData | INNER JOIN | Reader | Provider-instrument data |
| Trade.GetInstrumentType | FROM | Reader | Instrument type lookup |
| Trade.GetInstrumentDataForAPI | INNER JOIN | Reader | API instrument data |
| Trade.GetForexRates | INNER JOIN | Reader | Forex rate display |
| Trade.MatchInstrumentIDToTickerName | LEFT JOIN | Reader | Ticker matching |
| Trade.InsertNewTradingResourceDefault | JOIN | Reader | Trading resource defaults |
| Trade.ChangeIsSettledForASYCUsers | JOIN | Reader | ASYC user positions |
| Trade.NewCheckBSL, Trade.CheckBSL | JOIN | Reader | BSL validation |
| Trade.GetLeveragesRestrictionsWhiteList | INNER JOIN | Reader | Leverage whitelist |
| Trade.GetInterestRateOverrides | LEFT JOIN | Reader | Interest rate overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrument (view)
├── Trade.Instrument (table)
├── Dictionary.Currency (table) [buy]
├── Dictionary.Currency (table) [sell]
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - base instrument definition |
| Dictionary.Currency | Table | INNER JOIN (twice) - buy and sell abbreviations |
| Trade.InstrumentMetaData | Table | INNER JOIN - InstrumentTypeID, Industry, ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertDividend | Procedure | WHERE InstrumentTypeID validation |
| Trade.UpdateDividend | Procedure | Same |
| Trade.GetInstrumentInterestRates | Procedure | FROM |
| Trade.GetPositionsForFeeBulkGeneral | Procedure | INNER JOIN |
| Trade.CalcOverNightFeeRates | Procedure | FROM |
| Trade.GetInstrumentWithSpread | Procedure | FROM |
| Trade.GetInstrumentDataForAPI | Procedure | INNER JOIN |
| Trade.GetForexRates | Procedure | INNER JOIN |
| (20+ other procedures) | Procedure | Various reads |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get instrument by ID with display name
```sql
SELECT InstrumentID, Name, BuyCurrencyID, SellCurrencyID, InstrumentTypeID,
       DollarRatio, IsMajor, Industry, ExchangeID
  FROM Trade.GetInstrument WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.2 Forex instruments only
```sql
SELECT InstrumentID, Name, TradeRange, PipDifferenceThreshold
  FROM Trade.GetInstrument WITH (NOLOCK)
 WHERE InstrumentTypeID = 1
 ORDER BY Name
```

### 8.3 Resolve instruments to asset class names
```sql
SELECT GI.InstrumentID, GI.Name, GI.InstrumentTypeID, CT.Name AS AssetClassName
  FROM Trade.GetInstrument GI WITH (NOLOCK)
  LEFT JOIN Dictionary.CurrencyType CT WITH (NOLOCK)
    ON GI.InstrumentTypeID = CT.CurrencyTypeID
 WHERE GI.InstrumentID IN (1, 1001, 100000)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trade (schema) | Confluence | Schema context for Trade views |
| Trade.GetInstrument | Confluence | View referenced in documentation |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 20+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetInstrument | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrument.sql*


### Upstream `etoro.Dictionary.Currency` — production
- **Resolved as**: `etoro.Dictionary.Currency`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.Currency.md`

# Dictionary.Currency

> Master reference table defining all 10,669 tradeable instruments (stocks, ETFs, forex pairs, commodities, indices, crypto) on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CurrencyID (INT, CLUSTERED PK) |
| **Row Count** | 10,669 rows across 6 asset classes |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 4 active (PK clustered + unique on Abbreviation + NC on CurrencyTypeID, Name) — all PAGE compressed |
| **Audit Triggers** | 3 (INSERT, UPDATE, DELETE → History.AuditHistory) |

---

## 1. Business Meaning

Dictionary.Currency is one of the most critical tables in the entire eToro database. Despite its name suggesting only currencies, it is the **universal instrument registry** — every tradeable asset on the platform is a row in this table, from EUR/USD forex pairs to Apple stock to Bitcoin.

The legacy naming (Currency/CurrencyID) reflects eToro's origins as a forex-only platform. As the platform expanded to stocks (8,632 instruments), ETFs (652), crypto (630), commodities (412), and indices (167), the table retained its original name while becoming the master instrument table.

CurrencyID is referenced by virtually every trading table: `Trade.PositionTbl.CurrencyID` stores which instrument a position is on, `Trade.DelayedOrderForOpen.CurrencyID` stores which instrument a pending order targets, and instrument configuration tables link features, fees, and restrictions to CurrencyID.

Every DML operation on this table (INSERT, UPDATE, DELETE) is captured column-by-column to `History.AuditHistory` via three ASM-generated audit triggers. This ensures full traceability of instrument configuration changes.

---

## 2. Business Logic

### 2.1 Instrument Classification by Asset Class

**What**: Each instrument belongs to exactly one asset class (CurrencyType), which determines trading rules, margin requirements, and settlement behavior.

**Columns/Parameters Involved**: `CurrencyTypeID`

**Rules**:
- **Stocks** (CurrencyTypeID=5): 8,632 instruments — largest category. Individual company shares. Can be REAL (1x leverage) or CFD.
- **ETF** (CurrencyTypeID=6): 652 instruments — exchange-traded funds. Similar trading rules to stocks.
- **Crypto** (CurrencyTypeID=10): 630 instruments — Bitcoin, Ethereum, etc. ESMA caps retail leverage at 2x. Can be REAL at 1x.
- **Commodity** (CurrencyTypeID=2): 412 instruments — Gold, Oil, Silver, etc. Always CFD. ESMA caps retail at 10x.
- **Forex** (CurrencyTypeID=1): 176 instruments — currency pairs. Always CFD. ESMA caps retail at 30x (majors) / 20x (minors).
- **Indices** (CurrencyTypeID=4): 167 instruments — S&P 500, NASDAQ, DJ30, etc. Always CFD. ESMA caps retail at 20x.

### 2.2 Bitmask System (Legacy)

**What**: The Mask column encodes each instrument's identity as a power-of-2 bitmask for legacy systems.

**Columns/Parameters Involved**: `Mask`

**Rules**:
- USD=1 (2^0), EUR=2 (2^1), GBP=4 (2^2), JPY=8 (2^3), AUD=16 (2^4), CHF=32 (2^5), CAD=64 (2^6), NZD=128 (2^7)
- The ForexType in views like Dictionary.GetCurrency is computed as: `LOG(Mask)/LOG(2) + 1`
- Many newer instruments (stocks, crypto) have Mask=0 or NULL — bitmask is only meaningful for legacy forex instruments
- This system has a hard ceiling of 31 instruments (INT has 31 usable bits) — now exceeded, hence only used for original forex pairs

### 2.3 EEA Stock Exchange Compliance

**What**: Flags whether a stock is listed on a European Economic Area exchange, which triggers MiFID II PRIIPs regulations.

**Columns/Parameters Involved**: `EEAStockExchange`

**Rules**:
- EEAStockExchange=1 for 216 instruments listed on EU/EEA exchanges (London, Frankfurt, Paris, Amsterdam, etc.)
- These instruments require KID (Key Information Document) availability under PRIIPs regulation
- Affects which instruments are available to retail EU clients without professional classification

### 2.4 ISIN and ISO Identification

**What**: International securities identification codes for regulatory reporting and cross-system integration.

**Columns/Parameters Involved**: `ISINCode`, `ISOCode`, `ISOName`

**Rules**:
- ISINCode: 12-character International Securities Identification Number (for stocks, ETFs, bonds). NULL for forex/commodities.
- ISOCode: ISO 4217 currency code number (for forex base currencies). "840"=USD, "978"=EUR, "826"=GBP. NULL for stocks.
- ISOName: ISO 4217 three-letter currency code. Same as Abbreviation for forex, NULL for stocks.

---

## 3. Data Overview

| CurrencyID | Asset Class | Abbreviation | Name | CurrencySymbol | ISIN | Meaning |
|---|---|---|---|---|---|---|
| 0 | Forex | 000 | NULL | - | - | Placeholder/null instrument. Used as default/unknown. |
| 1 | Forex | USD | United States Dollar | $ | - | The US Dollar — the platform's base settlement currency. All PnL ultimately converts to USD. Mask=1 (first bit). |
| 2 | Forex | EUR | Euro | € | - | The Euro — second most traded currency on the platform. Default currency for European users. Mask=2. |
| 3 | Forex | GBP | Pound Sterling | £ | - | British Pound. Default currency for UK users. Mask=4. |
| 1001 | Stocks | AAPL.US | Apple Inc | - | US0378331005 | Apple stock — one of the most traded instruments. EEAStockExchange=0 (US-listed). CurrencyTypeID=5. |
| 100001 | Crypto | BTC | Bitcoin | ₿ | - | Bitcoin — first and most traded cryptocurrency. CurrencyTypeID=10. Available REAL at 1x or CFD at 2x. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Primary key identifying the instrument. 0=NULL placeholder, 1-8=major forex currencies, 1000+=stocks, 100000+=crypto. Referenced by Trade.PositionTbl.CurrencyID, Trade.DelayedOrderForOpen.CurrencyID, and virtually all trading tables. |
| 2 | CurrencyTypeID | int | NO | - | VERIFIED | FK to Dictionary.CurrencyType. Asset class: 1=Forex (176), 2=Commodity (412), 4=Indices (167), 5=Stocks (8,632), 6=ETF (652), 10=Crypto (630). Determines trading rules, leverage limits, and settlement eligibility. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | Full instrument name. "United States of America, US Dollar" for forex, company name for stocks, coin name for crypto. Padded with spaces (legacy). |
| 4 | Abbreviation | varchar(20) | NO | - | VERIFIED | Trading symbol / ticker. "USD", "AAPL.US", "BTC", "GOLD". UNIQUE constraint. The primary identifier used in UIs and APIs. |
| 5 | Mask | int | YES | - | VERIFIED | Legacy bitmask value — power of 2 for original forex instruments. Used by Dictionary.GetCurrency/GetCommodity/GetIndices views to compute ForexType. 0 or NULL for newer instruments (stocks, crypto). |
| 6 | EEAStockExchange | bit | NO | (0) | VERIFIED | Whether listed on a European Economic Area stock exchange. 216 instruments flagged. Triggers MiFID II PRIIPs KID requirements. Default=0. |
| 7 | ISINCode | varchar(25) | YES | - | VERIFIED | International Securities Identification Number. 12-character code for stocks/ETFs (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for regulatory reporting and cross-system matching. |
| 8 | CurrencySymbol | nchar(5) | YES | - | VERIFIED | Display symbol for the currency/instrument. "$" for USD, "€" for EUR, "£" for GBP. NULL for stocks and many instruments that use Abbreviation instead. |
| 9 | InterestRateID | int | YES | (NULL) | VERIFIED | FK to Dictionary.InterestRateOld. Links to interest/swap rate configuration for overnight fee calculations. Only applicable to forex/commodity instruments with overnight rollover. NULL for stocks, ETFs, crypto. |
| 10 | ISOCode | varchar(10) | YES | - | VERIFIED | ISO 4217 numeric currency code. "840"=USD, "978"=EUR, "826"=GBP. Used for international financial reporting. NULL for non-currency instruments. |
| 11 | DisplayName | varchar(50) | YES | - | VERIFIED | Alternative display name for UI purposes. Currently NULL for most instruments — the platform uses Name or Abbreviation instead. |
| 12 | ISOName | varchar(10) | YES | - | VERIFIED | ISO 4217 alphabetic currency code. Same as Abbreviation for currencies ("USD", "EUR"). NULL for stocks and non-currency instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Verified |
|---------|---------------|-------------------|----------|
| CurrencyTypeID | Dictionary.CurrencyType | FK (explicit) | Yes — FK_DCUT_DCUR |
| InterestRateID | Dictionary.InterestRateOld | FK (explicit) | Yes — FK_Currency_InterestRateID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | DefaultCurrencyID | FK (explicit) | Default trading currency per country |
| Trade.PositionTbl | CurrencyID | Implicit Lookup | Which instrument every position is on |
| Trade.DelayedOrderForOpen | CurrencyID | Implicit Lookup | Pending order instrument |
| Dictionary.GetCurrency | CurrencyID | View | Forex instruments (CurrencyTypeID=1) |
| Dictionary.GetCommodity | CurrencyID | View | Commodity instruments (CurrencyTypeID=2) |
| Dictionary.GetIndices | CurrencyID | View | Index instruments (CurrencyTypeID=3/4) |
| Dictionary.CurrencyTypeSafty | - | View (schema-bound) | CurrencyType stable access |
| Trade.UpdateInstrumentsSymbolFull | CurrencyID | Write | Instrument metadata updates |
| Trade.GetAllInstrumentCategoriesForAPI | CurrencyID | Read | API instrument catalog |
| SalesForce.GetInstruments | CurrencyID | Read | CRM instrument sync |
| History.GetOnePipValueDollarHedge | CurrencyID | Read | PnL/pip calculations |
| Hedge.GetUnrealizedCustomersData | CurrencyID | Read | Hedge exposure |
| 25+ additional procedures | CurrencyID | Read | BackOffice, Billing, Trade, MIMOAlerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Currency
 ├── Dictionary.CurrencyType (FK: CurrencyTypeID)
 └── Dictionary.InterestRateOld (FK: InterestRateID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | FK: Asset class classification |
| Dictionary.InterestRateOld | Table | FK: Overnight interest/swap rate config |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: Default currency per country |
| Trade.PositionTbl | Table | Every position references an instrument |
| Trade.DelayedOrderForOpen | Table | Every pending order references an instrument |
| Dictionary.GetCurrency/GetCommodity/GetIndices | Views | Asset-class filtered instrument lists |
| History.AuditHistory | Table | Audit trail via triggers |
| 25+ stored procedures | Procs | Instrument lookups across all schemas |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| PK_DCUR | CLUSTERED PK | CurrencyID ASC | - | - | PAGE | Active |
| DCUR_ABBR | NC UNIQUE | Abbreviation ASC | - | - | PAGE | Active |
| DCUR_CURRENCYTYPE | NC | CurrencyTypeID ASC | - | - | PAGE | Active |
| DCUR_NAME | NC | Name ASC | - | - | PAGE | Active |

### 7.2 Audit Triggers

| Trigger | Event | Target | Description |
|---------|-------|--------|-------------|
| AuditDelete_Dictionary_Currency | DELETE | History.AuditHistory | Logs old values for every column when an instrument is deleted |
| AuditInsert_Dictionary_Currency | INSERT | History.AuditHistory | Logs new values for every column when an instrument is added |
| AuditUpdate_Dictionary_Currency | UPDATE | History.AuditHistory | Logs old→new value pairs for each changed column per instrument |

All triggers are ASM-generated (Automated Schema Management). They call `Internal.GetUserAndAppName` to capture the user/application performing the change.

### 7.3 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCUR | PRIMARY KEY | Unique instrument identifier |
| DCUR_ABBR | UNIQUE | No duplicate trading symbols |
| FK_DCUT_DCUR | FOREIGN KEY | CurrencyTypeID → Dictionary.CurrencyType |
| FK_Currency_InterestRateID | FOREIGN KEY | InterestRateID → Dictionary.InterestRateOld |
| Def_DictionaryCurrency_EEAStockExchange | DEFAULT | EEAStockExchange defaults to 0 |

---

## 8. Sample Queries

### 8.1 Count instruments by asset class
```sql
SELECT  ct.Name AS AssetClass, COUNT(*) AS InstrumentCount
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
GROUP BY ct.Name
ORDER BY InstrumentCount DESC;
```

### 8.2 Find instrument by ticker
```sql
SELECT  CurrencyID, Name, Abbreviation, ct.Name AS AssetClass,
        ISINCode, CurrencySymbol, EEAStockExchange
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
WHERE   c.Abbreviation = 'AAPL.US';
```

### 8.3 List all EEA-listed stocks
```sql
SELECT  CurrencyID, Abbreviation, Name, ISINCode
FROM    [Dictionary].[Currency] WITH (NOLOCK)
WHERE   EEAStockExchange = 1
ORDER BY Abbreviation;
```

### 8.4 Find forex instruments with interest rates
```sql
SELECT  c.CurrencyID, c.Abbreviation, c.CurrencySymbol,
        ir.InterestRateID, ir.Description AS InterestRateDesc
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
LEFT JOIN [Dictionary].[InterestRateOld] ir WITH (NOLOCK) ON c.InterestRateID = ir.InterestRateID
WHERE   c.CurrencyTypeID = 1
ORDER BY c.CurrencyID;
```

### 8.5 Audit trail — recent instrument changes
```sql
SELECT TOP 20 AuditDate, UserName, AppName, ColumnName, OldValue, NewValue, Operation
FROM   [History].[AuditHistory] WITH (NOLOCK)
WHERE  SchemaName = 'Dictionary' AND TableName = 'Currency'
ORDER BY AuditDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Currency.

---

*Generated: 2026-03-13 | Enriched: MCP live data | Quality: 9.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 25+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Currency | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Currency.sql*


### Upstream `etoro.Trade.InstrumentMetaData` — production
- **Resolved as**: `etoro.Trade.InstrumentMetaData`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.InstrumentMetaData.md`

# Trade.InstrumentMetaData

> Extended metadata for each tradeable instrument (display names, symbols, images, regulatory identifiers, fee config) - UI presentation and operational config layer that supplements Trade.Instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, PK) |
| **Partition** | No |
| **Indexes** | 5 active (clustered PK, UNQ SymbolFull, IX_Cusip, IX_InstrumentTypeID) |

---

## 1. Business Meaning

Trade.InstrumentMetaData stores the extended configuration and presentation metadata for every tradeable instrument on the eToro platform. While Trade.Instrument defines the core buy/sell currency pairing and Dictionary.Currency holds asset definitions, InstrumentMetaData adds the layer that drives the UI and operational rules: display names, ticker symbols, CDN image URLs, exchange assignments, regulatory codes (ISIN, CUSIP, SEDOL), rollover fees, chart timeframe groups, and visibility/tradability flags.

This table exists because the trading engine needs more than just the instrument pair - it needs to know how to display the instrument in the app, which exchange to use for price feeds, which chart intervals to offer, whether the instrument is tradable or visible, and how to identify it for compliance (ISIN for stocks, CFI codes, etc.). Without InstrumentMetaData, the platform could not render instrument pickers, show correct symbols in position views, or route equity orders to the right exchange.

Data flows: Rows are created by Trade.InsertInstrumentMetaData, Trade.InsertInstrumentMetadataSecurityOpsAPI, Stocks.AddNewStock, and Internal.Newcurrency_3163 (legacy instrument setup). Procedures that update metadata include Trade.UpdateInstrumentsSymbolFull, Trade.UpdateInstrumentExchange, Trade.UpdateInstrumentType, Trade.UpdateCusip, Trade.UpdateInstrumentsMetaDataConfigurations, and Trade.UpdateFuturesMetadataSecurityOpsAPI. Trade.DisableInstrument and dbo.EnableInstrument toggle Tradable and InstrumentVisible. The table is system-versioned (temporal) to History.InstrumentMetaData; audit triggers log changes to History.AuditHistory. Read by 60+ views and procedures for positions, orders, dividends, fee calculation, and API responses.

---

## 2. Business Logic

### 2.1 Visibility and Tradability Control

**What**: Whether an instrument appears in the UI and can be traded. Two independent flags control display vs execution.

**Columns/Parameters Involved**: `InstrumentVisible`, `Tradable`

**Rules**:
- InstrumentVisible = 1: Instrument appears in discovery, search, and instrument lists. 0 = hidden from UI (e.g., delisted but positions still exist).
- Tradable = 1: Orders can be placed. 0 = trading disabled (e.g., during corporate actions, delisting).
- Trade.DisableInstrument sets both to 0. dbo.EnableInstrument sets both to 1.
- GetInstrumentsRates filters: (InstrumentVisible = 1 OR ProviderToInstrument.Enabled = 1) AND Tradable = 1 for price display.
- GetEnabledAndListedInstruments uses InstrumentMetaData to filter instruments visible and tradable per provider.

**Diagram**:
```
Instrument State:
InstrumentVisible=0, Tradable=0 -> Hidden and untradeable (delisted)
InstrumentVisible=1, Tradable=0 -> Visible but trading disabled
InstrumentVisible=1, Tradable=1 -> Active (normal state)
```

### 2.2 Candle Timeframe Group

**What**: Links the instrument to a group (Forex=1, Stocks=2) that defines which chart intervals are available via Trade.CandleGroupToIntervals.

**Columns/Parameters Involved**: `CandleTimeframeGroup`, Trade.CandleIntervalGroups.GroupID

**Rules**:
- 1 = Forex group (all 9 timeframes). 2 = Stocks group (same 9, different display rules). FK to Trade.CandleIntervalGroups.
- Trade.InsertInstrumentMetaData defaults to 2 (Stocks). Forex instruments use 1.
- Trade.GetInstrumentsTimeframeID joins InstrumentMetaData to CandleGroupToIntervals to return InstrumentID + TimeframeID for available chart intervals.

### 2.3 Instrument Type (Asset Class)

**What**: Asset class from Dictionary.CurrencyType - determines trading rules, min position size, price feed routing.

**Columns/Parameters Involved**: `InstrumentTypeID`, Dictionary.CurrencyType.CurrencyTypeID

**Rules**:
- 1=Forex, 2=Commodity, 3=CFD (legacy), 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType (constraint name FK_InstrumentMetaData_InstrumentType).
- Used by fee config (GetRolloverFeeAlertThresholds), exposure (Stocks.GetExposure), and instrument setup. Must match Dictionary.Currency.CurrencyTypeID for the same InstrumentID.

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | Symbol | SymbolFull | InstrumentTypeID | CandleTimeframeGroup | Meaning |
|---|---|---|---|---|---|---|
| 1 | EUR/USD | EURUSD | EURUSD | 1 | 1 | Major forex pair. CandleTimeframeGroup=1 (Forex). Visible and tradable. PriceSourceID=0 (eToro internal). |
| 1001 | Apple | AAPL | AAPL | 5 | 2 | US equity (Stocks). CandleTimeframeGroup=2 (Stocks). ISINCode=US0378331005. PriceSourceID=3 (Xignite). ExchangeID=4 (NASDAQ). |
| 1002 | Alphabet | GOOG | GOOG | 5 | 2 | US equity (Stocks). Different StocksIndustryID (8=Technology vs 3=Consumer Goods). PriceSourceID=3. |
| 100000 | Bitcoin | BTC | BTC | 10 | 2 | Cryptocurrency. CandleTimeframeGroup=2. ExchangeID=8 (BATS). PriceSourceID=0 (eToro). |
| 610 | ETORIAN610 | ETORIAN610 | ETORIAN610 | 5 | 2 | Synthetic/etorian instrument. StocksIndustryID=3. Illustrates non-standard symbol usage. |

**Selection criteria for the 5 rows:**
- Forex (1), Stocks (1001, 1002, 610), Crypto (100000) to show asset class variety.
- Major forex, major equity, etorian edge case.
- Include InstrumentTypeID, CandleTimeframeGroup, and symbol patterns representative of the table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Primary key. References Trade.Instrument.InstrumentID. Same value as Dictionary.Currency.CurrencyID for the instrument. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | CODE-BACKED | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. |
| 3 | InstrumentTypeImage | varchar(max) | YES | - | NAME-INFERRED | URL or path for instrument type icon. Nullable; CDN avatars often built from InstrumentID instead (InstrumentImageSmall/etc). |
| 4 | Ticker | varchar(max) | YES | - | CODE-BACKED | Ticker path for price/quote APIs. Trade.InsertInstrumentMetaData sets '/ticker' by default. Used for external ticker lookups. |
| 5 | ChartTicker | varchar(max) | YES | - | NAME-INFERRED | Alternate ticker for charting services. Null when same as Ticker. |
| 6 | InstrumentImageSmall | varchar(max) | YES | - | CODE-BACKED | CDN URL for small avatar. Trade.InsertInstrumentMetaData builds: etoro-cdn.etorostatic.com/market-avatars/{InstrumentID}/35x35.png. |
| 7 | InstrumentImageMedium | varchar(max) | YES | - | CODE-BACKED | CDN URL for medium avatar. Pattern: .../50x50.png. |
| 8 | InstrumentImageLarge | varchar(max) | YES | - | CODE-BACKED | CDN URL for large avatar. Pattern: .../150x150.png. |
| 9 | Exchange | varchar(max) | YES | - | CODE-BACKED | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. |
| 10 | Industry | varchar(max) | YES | - | CODE-BACKED | Industry sector label (e.g., "Technology", "Consumer Goods"). Used for stocks; NULL for forex/crypto. |
| 11 | CompanyInfo | varchar(max) | YES | - | NAME-INFERRED | Extended company/instrument description. Nullable. |
| 12 | DailyRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Overnight holding fee rate for weekdays, per lot/unit. NULL when not configured. |
| 13 | WeekendRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Overnight fee for weekend holds. NULL when not configured. |
| 14 | ContractRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Rollover fee for contract-based instruments (futures, etc.). NULL when N/A. |
| 15 | InstrumentVisible | int | YES | (1) | CODE-BACKED | Visibility: 1 = shown in UI, 0 = hidden. Default 1. dbo.EnableInstrument/Trade.DisableInstrument set this. Filtered by GetInstrumentsRates, GetEnabledAndListedInstruments. |
| 16 | Symbol | varchar(100) | YES | - | CODE-BACKED | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. |
| 17 | CandleTimeframeGroup | int | YES | - | CODE-BACKED | FK to Trade.CandleIntervalGroups.GroupID. 1=Forex, 2=Stocks. Controls which chart intervals are available. See [Trade.CandleIntervalGroups](Trade.CandleIntervalGroups.md). |
| 18 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | Full/canonical symbol, UNIQUE. Used for instrument lookup (e.g., Trade.GetOrdersForExecutionReportV2_JUNK: SELECT InstrumentID FROM InstrumentMetaData WHERE Symbol = @Symbol). Primary identifier in Security Ops API. |
| 19 | Tradable | bit | YES | - | CODE-BACKED | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. Required for GetInstrumentsRates, GetEnabledAndListedInstruments. |
| 20 | ExchangeID | int | YES | - | CODE-BACKED | FK to Price.Exchange. Primary exchange for this instrument. Used for fee config (Trade.ExchangeInstrumentFeeDefinition), price feed routing. trg_update_Trade_InstrumentMetaData validates ExchangeID exists in ExchangeInstrumentFeeDefinition. |
| 21 | StocksIndustryID | int | YES | - | CODE-BACKED | Industry classification for stocks. Dictionary.StocksIndustry or similar. NULL for forex/crypto. Used in Trade.GetInstrumentMetaDataExtend as Industry (ISNULL to 0). |
| 22 | ISINCode | varchar(30) | YES | - | CODE-BACKED | International Securities Identification Number. Required for stocks (e.g., US0378331005 for Apple). NULL for forex/crypto. Used for compliance and dividend matching. |
| 23 | ISINCountryCode | varchar(15) | YES | - | CODE-BACKED | Country prefix of ISIN (e.g., "US"). Audit-tracked. |
| 24 | ContractExpire | bit | NO | (0) | CODE-BACKED | 1 = instrument has expiry (futures, options). 0 = no expiry (stocks, forex, crypto). Default 0. |
| 25 | InstrumentTypeSubCategoryID | int | YES | - | CODE-BACKED | Subclassification within asset class. References Dictionary or lookup. NULL for most instruments. Trade.GetAllInstrumentTypeSubCategoryForAPI exposes subcategories. |
| 26 | InstrumentTypeID | int | YES | - | CODE-BACKED | Asset class. FK to Dictionary.CurrencyType.CurrencyTypeID. 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. See [Dictionary.CurrencyType](../Dictionary/Tables/Dictionary.CurrencyType.md). |
| 27 | PriceSourceID | int | NO | (0) | CODE-BACKED | Price feed source. 0 = eToro internal. 3 = Xignite (stocks/ETF). Validated via Dictionary.PriceSourceName. Used for price routing and allocation. |
| 28 | Cusip | varchar(255) | YES | - | CODE-BACKED | CUSIP identifier (US/Canada securities). Trade.UpdateCusip, Trade.GetInstrumentCusip, Trade.CusipsToInstrumentIDs. Indexed (IX_Cusip). |
| 29 | CreateDate | datetime | YES | (getutcdate()) | CODE-BACKED | UTC timestamp when the instrument metadata row was created. |
| 30 | UnderlyingExchangeID | int | YES | - | NAME-INFERRED | Exchange for underlying when instrument is derivative. NULL for spot instruments. |
| 31 | DbLoginName | (computed) | - | - | CODE-BACKED | Computed: suser_name(). Current DB login for audit context. |
| 32 | AppLoginName | (computed) | - | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context for audit. |
| 33 | SysStartTime | datetime2(7) | NO | (getutcdate()) | CODE-BACKED | System-versioning start. Generated always as row start. |
| 34 | SysEndTime | datetime2(7) | NO | ('9999-12-31 23:59:59.9999999') | CODE-BACKED | System-versioning end. Generated always as row end. History in History.InstrumentMetaData. |
| 35 | SEDOL | varchar(50) | YES | - | CODE-BACKED | SEDOL identifier (UK securities). Alternative to ISIN/CUSIP for some instruments. |
| 36 | SubCategory | varchar(255) | YES | - | NAME-INFERRED | Human-readable subcategory label. May duplicate InstrumentTypeSubCategoryID. |
| 37 | CFICode | varchar(6) | YES | - | CODE-BACKED | Classification of Financial Instruments code (ISO 10962). 6-character code for instrument classification. Trade.InsertInstrumentMetaData accepts @CFICode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (implicit) | Same PK; InstrumentMetaData extends Instrument. |
| CandleTimeframeGroup | Trade.CandleIntervalGroups | FK | Chart timeframe group (Forex/Stocks). |
| InstrumentTypeID | Dictionary.CurrencyType | FK | Asset class (Forex, Stocks, Crypto, etc.). |
| ExchangeID | Price.Exchange | Lookup | Primary exchange for price/execution. |
| StocksIndustryID | Dictionary.StocksIndustry | Lookup | Industry for stocks. |
| UnderlyingExchangeID | Price.Exchange | Lookup | Underlying exchange for derivatives. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrument | IMD | JOIN | Instrument deal view joins InstrumentMetaData. |
| Trade.GetInstrumentMetaData | - | View | Direct view over this table. |
| Trade.GetInstrumentMetaDataExtend | - | View | Extended metadata view. |
| Trade.GetPositionsForDataApi | meta | JOIN | Position data includes metadata. |
| Trade.GetAggregatedPositionsForDataApi | meta | JOIN | Aggregated positions. |
| Trade.GetPositionsForFeeBulkGeneral | IMD | JOIN | Fee calculation by instrument. |
| Trade.GetDividendsByStatus | IMD | JOIN | Dividend data with instrument metadata. |
| Trade.GetInstrumentByIdSecurityOpsAPI | - | SELECT | Security Ops API by InstrumentID. |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | im | JOIN | Futures metadata. |
| Trade.GetInstrumentSymbolFull | imd | FROM | Symbol lookup. |
| Trade.GetEnabledAndListedInstruments | m | JOIN | Enabled/listed filter. |
| Trade.GetInstrumentsAndInstrumentsGroups | imd | JOIN | Instruments and groups. |
| Trade.CheckValidInstruments | - | SELECT/UPDATE | Validation and copy logic. |
| Trade.InsertInstrumentMetaData | - | INSERT | Primary insert procedure. |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | - | INSERT | Security Ops API insert. |
| Trade.DisableInstrument | - | UPDATE | Sets Tradable=0, InstrumentVisible=0. |
| dbo.EnableInstrument | - | UPDATE | Sets Tradable=1, InstrumentVisible=1. |
| Trade.UpdateInstrumentsSymbolFullExtend | timd | UPDATE | Symbol full updates. |
| Trade.USAggregatePositionBySymbolForMonitor | - | JOIN | US aggregation. |
| Trade.GetAleErrorReport / V2 | tim | JOIN | ALE error report. |
| Trade.FailedDelayedCopyOrders | tim | JOIN | Delayed copy orders. |
| Trade.GetBacktraderCustomerData | IMD/TIMD | JOIN | Backtrader data. |
| Trade.GetCustomerManualOpenPositions | m | JOIN | Manual positions. |
| Trade.AlertForExitOrders_which_should_have_clsoed1 | imd | JOIN | Exit order alerts. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentMetaData (table)
```
This object has no code-level dependencies. Tables have no FROM/JOIN in CREATE TABLE. FK targets (Trade.CandleIntervalGroups, Dictionary.CurrencyType) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CandleIntervalGroups | Table | FK: CandleTimeframeGroup -> GroupID |
| Dictionary.CurrencyType | Table | FK: InstrumentTypeID -> CurrencyTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentMetaData | View | Direct select |
| Trade.GetInstrumentMetaDataExtend | View | Extended metadata view |
| Trade.GetInstrument | View | JOIN for deal data |
| Trade.GetInstrumentDeal | View | Via GetInstrument |
| Trade.InsertInstrumentMetaData | Procedure | INSERT |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | INSERT |
| Trade.UpdateInstrumentsMetaDataConfigurations | Procedure | UPDATE |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Procedure | UPDATE |
| Trade.DisableInstrument | Procedure | UPDATE |
| Trade.GetInstrumentByIdSecurityOpsAPI | Procedure | SELECT |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Procedure | SELECT |
| Trade.GetInstrumentsTimeframeID | Procedure | JOIN with CandleGroupToIntervals |
| Trade.GetPositionsForDataApi | Procedure | JOIN |
| Trade.GetAggregatedPositionsForDataApi | Procedure | JOIN |
| Trade.GetDividendsByStatus | Procedure | JOIN |
| Trade.GetInstrumentSymbolFull | Procedure | Symbol lookup |
| Trade.GetEnabledAndListedInstruments | Procedure | Filter |
| Trade.CheckValidInstruments | Procedure | Validation |
| Trade.USAggregatePositionBySymbolForMonitor | Procedure | JOIN |
| Stocks.AddNewStock | Procedure | INSERT (via Internal flow) |
| dbo.EnableInstrument | Procedure | UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentMetaData | CLUSTERED | InstrumentID ASC | - | - | Active |
| UNQ_TradeInstrumentMetaData_SymbolFull | NC UNIQUE | SymbolFull ASC | - | - | Active |
| IX_Cusip | NC | Cusip ASC | - | - | Active |
| IX_InstrumentTypeID | NC | InstrumentTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentMetaData | PRIMARY KEY | InstrumentID clustered |
| UNQ_TradeInstrumentMetaData_SymbolFull | UNIQUE | SymbolFull must be unique |
| DF_InstrumentMetaData_InstrumentVisible | DEFAULT | InstrumentVisible = 1 |
| (unnamed) | DEFAULT | ContractExpire = 0 |
| DF_InstrumentMetaDataPriceSourceID | DEFAULT | PriceSourceID = 0 |
| DF_InstrumentCreateDate | DEFAULT | CreateDate = getutcdate() |
| DF_InstrumentMetaData_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentMetaData_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| FK_InstrumentMetaData_CandleIntervalGroups | FOREIGN KEY | CandleTimeframeGroup -> Trade.CandleIntervalGroups.GroupID |
| FK_InstrumentMetaData_InstrumentType | FOREIGN KEY | InstrumentTypeID -> Dictionary.CurrencyType.CurrencyTypeID |

---

## 8. Sample Queries

### 8.1 List visible tradable instruments by asset class
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.SymbolFull, ct.Name AS AssetClass
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON imd.InstrumentTypeID = ct.CurrencyTypeID
WHERE imd.InstrumentVisible = 1 AND imd.Tradable = 1
ORDER BY imd.InstrumentTypeID, imd.SymbolFull;
```

### 8.2 Get metadata for an instrument by SymbolFull
```sql
SELECT imd.*, cig.GroupName AS CandleGroup
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
LEFT JOIN Trade.CandleIntervalGroups cig WITH (NOLOCK) ON imd.CandleTimeframeGroup = cig.GroupID
WHERE imd.SymbolFull = 'AAPL';
```

### 8.3 Instruments with rollover fees configured
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.SymbolFull,
       imd.DailyRolloverFee, imd.WeekendRolloverFee, imd.ContractRolloverFee
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE imd.DailyRolloverFee IS NOT NULL
   OR imd.WeekendRolloverFee IS NOT NULL
   OR imd.ContractRolloverFee IS NOT NULL
ORDER BY imd.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DBs and DB Main](https://etoro.atlassian.net/wiki/spaces/CM/pages/2106130488) | Confluence | Database context for Trade schema |
| [Security Master Ops API - Duplicate Symbol Full](https://etoro.atlassian.net/wiki/spaces/CM/pages/14016348165) | Confluence | SymbolFull uniqueness and Security Ops API |
| [Asset Universe - Fields in use in each API and Service](https://etoro.atlassian.net/wiki/spaces/CM/pages/13224083616) | Confluence | Instrument metadata usage across APIs |
| [HLD - Visibility Update](https://etoro.atlassian.net/wiki/spaces/CM/pages/13210976290) | Confluence | InstrumentVisible / Tradable visibility logic |
| [Instrument On Paper testing](https://etoro.atlassian.net/wiki/spaces/CM/pages/12929433601) | Confluence | Instrument testing flows |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 1,4,5,7,8,10,11*
*Sources: Atlassian: 5 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMetaData | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentMetaData.sql*


### Upstream `etoro.Trade.Instrument` — production
- **Resolved as**: `etoro.Trade.Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md`

# Trade.Instrument

> Core instrument definition table that pairs a buy currency/asset with a sell currency to define every tradeable instrument on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 7 active |

---

## 1. Business Meaning

Trade.Instrument is the foundational instrument definition table in the Trade schema. While Dictionary.Currency holds the master registry of all tradeable assets (stocks, forex, crypto, etc.), Trade.Instrument defines the **pairing relationship** between two Dictionary.Currency entries - the buy side and the sell side - that together form a tradeable instrument. For forex, this is literal (e.g., EUR/USD = BuyCurrencyID=EUR, SellCurrencyID=USD). For stocks and other non-forex assets, BuyCurrencyID equals the InstrumentID in Dictionary.Currency for that asset, and SellCurrencyID is the denomination currency.

This table exists because eToro's trading engine requires every instrument to have both a buy-side and sell-side definition for rate calculation, price conversion, and P&L computation. Without it, the system cannot determine how to quote prices or convert values to USD (or any other base currency). Every position, order, hedge, and exposure calculation ultimately depends on the instrument pairs defined here.

Data is created via `Trade.InstrumentAdd`, which calls `Internal.GetInstrumentID` to allocate the next available InstrumentID. The table is read by virtually every trading view and procedure - over 20 views and 20+ stored procedures reference it directly. Audit triggers (ASM-generated) track INSERT, UPDATE, and DELETE operations to `History.AuditHistory`, and system versioning tracks all row changes to `History.Instrument`.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of currencies/assets from Dictionary.Currency.

**Columns/Parameters Involved**: `BuyCurrencyID`, `SellCurrencyID`

**Rules**:
- For **forex pairs**: BuyCurrencyID and SellCurrencyID are both actual currencies (e.g., InstrumentID=1: EUR/USD where BuyCurrencyID=2 (EUR), SellCurrencyID=1 (USD))
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the InstrumentID in Dictionary.Currency for that asset (e.g., InstrumentID=1203: Bayer AG where BuyCurrencyID=1203), and SellCurrencyID is the denomination currency (e.g., EUR for European stocks, USD for US stocks)
- The combination (BuyCurrencyID, SellCurrencyID) is enforced UNIQUE by the `TISR_PAIR` index - no duplicate pairs
- Default value 0 for both columns maps to InstrumentID=0 (a system/placeholder record)

**Diagram**:
```
Forex:   InstrumentID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:   InstrumentID=1203 -> Buy=1203(Bayer) / Sell=EUR(2) = Bayer AG in EUR
Crypto:  InstrumentID=2031 -> Buy=2031(easyJet) / Sell=GBX(666) = easyJet in GBP pence
```

### 2.2 DollarRatio - Price Scaling Factor

**What**: A multiplier used to normalize instrument prices to USD-comparable values.

**Columns/Parameters Involved**: `DollarRatio`

**Rules**:
- Most instruments have DollarRatio=1 (price is already in standard units)
- Japanese Yen pairs use DollarRatio=100 because JPY is quoted in 100ths (e.g., USD/JPY at 150 means 150 yen per dollar)
- Used in P&L calculations and conversion rate computations across the platform

### 2.3 Order Matching Engine (OME) Distribution

**What**: Instruments are distributed across multiple OME instances for load balancing.

**Columns/Parameters Involved**: `OMEID`, `ShardID`

**Rules**:
- OMEID values 2-5 distribute instruments roughly equally (~2,620 each) across 4 OME instances
- OMEID=1 is reserved (only 1 instrument, likely the system placeholder)
- ShardID distributes data across database shards: 1 (4,564), 2 (4,712), 8 (1,208), 0 (placeholder)
- These values determine which OME server handles order matching and which database shard stores position data

### 2.4 Operation Mode

**What**: Controls the trading operation mode for the instrument.

**Columns/Parameters Involved**: `OperationMode`

**Rules**:
- OperationMode=0 (default, 10,402 instruments): Standard trading mode
- OperationMode=1 (83 instruments): Alternate operation mode - observed primarily on European stock CFDs (e.g., Bayer AG, BMW) traded in non-USD denominations

---

## 3. Data Overview

| InstrumentID | BuyCurrencyID | BuyCurrency | SellCurrencyID | SellCurrency | IsMajor | DollarRatio | Meaning |
|---|---|---|---|---|---|---|---|
| 0 | 0 | (system) | 0 | (system) | true | 0 | System placeholder record with all zero values. Never used for real trading. |
| 1 | 2 | EUR | 1 | USD | true | 1 | EUR/USD - the most traded forex pair globally. Marked as major with standard dollar ratio. |
| 5 | 4 | JPY | 1 | USD | false | 100 | USD/JPY - Japanese Yen pair. DollarRatio=100 because JPY is quoted in hundredths compared to other currencies. |
| 1203 | 1203 | Bayer AG | 2 | EUR | false | 1 | European stock CFD. BuyCurrencyID equals InstrumentID, denominated in EUR. OperationMode=1. |
| 2031 | 2031 | easyJet | 666 | GBX | false | 1 | UK stock CFD denominated in GBP pence (GBX). OperationMode=1. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key identifying the tradeable instrument pair. Allocated by `Internal.GetInstrumentID` during creation via `Trade.InstrumentAdd`. Values range from 0 (system placeholder) to 21,100,110. Referenced by virtually every trading table. |
| 2 | BuyCurrencyID | int | NO | 0 | VERIFIED | The buy-side asset of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the base currency (e.g., EUR in EUR/USD). For stocks/ETFs/crypto: the asset itself (BuyCurrencyID = the asset's CurrencyID in Dictionary.Currency). 10,252 distinct values. |
| 3 | SellCurrencyID | int | NO | 0 | VERIFIED | The sell-side (denomination) currency of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading currency (USD, EUR, GBX). 67 distinct values - far fewer than BuyCurrencyID since many assets share the same denomination. |
| 4 | TradeRange | smallint | NO | - | CODE-BACKED | The allowed trade range (pip distance) for the instrument. Determines how far from market price a pending order can be placed. Set during instrument creation via `Trade.InstrumentAdd`. |
| 5 | DollarRatio | decimal(8,2) | NO | - | VERIFIED | Price scaling factor for USD normalization. Most instruments = 1. Japanese Yen pairs = 100 (because JPY prices are 100x larger numerically). Used in P&L and conversion rate calculations across the platform. |
| 6 | Passport | timestamp | NO | - | CODE-BACKED | Row version / concurrency token. Automatically maintained by SQL Server. Returned as OUTPUT from `Trade.InstrumentAdd` for optimistic concurrency control. |
| 7 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | Maximum allowed pip difference threshold for the instrument. Used for price validation - if a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. Values range from 1 to 10,000. Audited on INSERT/UPDATE/DELETE. |
| 8 | IsMajor | bit | NO | 0 | VERIFIED | Flag indicating whether the instrument is classified as a "major" instrument. 1 = major (5,831 instruments, includes all major forex pairs and many popular assets), 0 = minor (4,654 instruments). Affects spread calculations, margin requirements, and regulatory leverage caps (ESMA allows higher leverage for major forex pairs). |
| 9 | PriceServerID | int | YES | - | CODE-BACKED | Identifies which price server feeds rate data for this instrument. 14 distinct values (1-10, 15, 16, 25, 100). NULL for 1 record (the system placeholder). Determines the source of real-time price feeds. Audited on INSERT/UPDATE/DELETE. |
| 10 | ShardID | int | NO | - | VERIFIED | Database shard assignment for the instrument. Determines which database shard stores position and order data. Values: 0 (1 - placeholder), 1 (4,564 instruments), 2 (4,712), 8 (1,208). Audited on INSERT/UPDATE/DELETE. |
| 11 | OMEID | int | YES | - | CODE-BACKED | Order Matching Engine instance assignment. Determines which OME server handles order matching for this instrument. Values: 1 (1 - system), 2 (2,622), 3 (2,621), 4 (2,620), 5 (2,621). Round-robin distribution across 4 active OME instances. |
| 12 | DbLoginName | computed | NO | - | VERIFIED | Computed: `SUSER_NAME()`. Captures the SQL Server login name of the current session. Used for audit trail purposes alongside the ASM triggers. |
| 13 | AppLoginName | computed | NO | - | VERIFIED | Computed: `CONVERT(VARCHAR(500), CONTEXT_INFO())`. Reads the application-set context info to identify which application service made the change. Used for audit trail alongside DbLoginName. |
| 14 | SysStartTime | datetime2(7) | NO | GETUTCDATE() | VERIFIED | System versioning row start time. Automatically set when a row is inserted or updated. Part of the temporal table mechanism tracking all changes to History.Instrument. |
| 15 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | VERIFIED | System versioning row end time. Set to max datetime for current rows. When a row is updated or deleted, the previous version's SysEndTime is set to the modification time in History.Instrument. |
| 16 | OperationMode | tinyint | YES | 0 | CODE-BACKED | Trading operation mode for the instrument. 0 = Standard mode (10,402 instruments - default for all asset types), 1 = Alternate mode (83 instruments - primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BuyCurrencyID | Dictionary.Currency | FK | The buy-side asset/currency. For forex: base currency. For stocks: the asset itself. |
| SellCurrencyID | Dictionary.Currency | FK | The sell-side denomination currency. For forex: quote currency. For stocks: trading currency. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | InstrumentID | FK/JOIN | Maps instruments to their liquidity providers and trading configurations |
| Trade.InstrumentMetaData | InstrumentID | JOIN | Extended metadata for instruments (display names, categories, etc.) |
| Trade.InstrumentActivitySchedule | InstrumentID | JOIN | Trading hours and activity windows per instrument |
| Trade.InstrumentConversion | InstrumentID | JOIN | Currency conversion rates and mappings |
| Trade.InstrumentImages | InstrumentID | JOIN | Logos and visual assets for instruments |
| Trade.InstrumentSpread | InstrumentID | JOIN | Spread configurations per instrument |
| Trade.IndexDividends | InstrumentID | JOIN | Dividend payments for index instruments |
| Trade.TradonomiContracts | InstrumentID | JOIN | Liquidity provider contract assignments |
| Trade.LiquidityProviderContracts | InstrumentID | JOIN | Detailed liquidity provider contract terms |
| Trade.GetInstrument (view) | InstrumentID | JOIN | Core instrument view joining Instrument + metadata |
| Trade.GetProviderToInstrument (view) | InstrumentID | JOIN | Provider-instrument mapping view |
| Trade.GetPositionData (view) | InstrumentID | JOIN | Position data view enriched with instrument details |
| Trade.FnGetConversionInstrument (function) | InstrumentID | JOIN | Finds the conversion instrument for a given currency pair |
| Trade.InstrumentAdd (procedure) | InstrumentID | Writer | Creates new instrument records |
| Trade.InsertInstrumentRealTable (procedure) | InstrumentID | Writer | Bulk instrument data loading |
| Trade.GetAllInstrumentData (procedure) | InstrumentID | Reader | Retrieves full instrument dataset |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Instrument (table)
├── Dictionary.Currency (table) [via BuyCurrencyID FK]
└── Dictionary.Currency (table) [via SellCurrencyID FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK target for both BuyCurrencyID and SellCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | References InstrumentID |
| Trade.InstrumentMetaData | Table | References InstrumentID |
| Trade.InstrumentActivitySchedule | Table | References InstrumentID |
| Trade.InstrumentConversion | Table | References InstrumentID |
| Trade.InstrumentImages | Table | References InstrumentID |
| Trade.InstrumentSpread | Table | References InstrumentID |
| Trade.IndexDividends | Table | References InstrumentID |
| Trade.TradonomiContracts | Table | References InstrumentID |
| Trade.LiquidityProviderContracts | Table | References InstrumentID |
| Trade.GetInstrument | View | JOINs to Instrument for base instrument data |
| Trade.GetInstrumentConfiguration | View | JOINs to Instrument for configuration views |
| Trade.GetInstrumentDataDealing | View | JOINs for dealing desk data |
| Trade.GetProviderToInstrument | View | JOINs for provider mappings |
| Trade.GetPositionData | View | JOINs to resolve instrument info on positions |
| Trade.GetCurrentPriceAndConversionRate | View | JOINs for price conversion |
| Trade.FnGetConversionInstrument | Function | Reads Instrument to find conversion pairs |
| Trade.FunGetInstrumentConfiguration | Function | Reads instrument configuration |
| Trade.InstrumentAdd | Procedure | INSERTs new instruments |
| Trade.GetAllInstrumentData | Procedure | SELECTs instrument data |
| Trade.CheckValidInstruments | Procedure | Validates instrument configurations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TISR | NC PK (UNIQUE) | InstrumentID | - | - | Active |
| ClusteredIndex- | CLUSTERED (UNIQUE) | InstrumentID | - | - | Active |
| IXInstrumentID | NC | InstrumentID, SellCurrencyID | - | - | Active |
| IX_SellCurrencyID | NC | SellCurrencyID | InstrumentID, BuyCurrencyID | - | Active |
| TISR_BUY | NC | BuyCurrencyID | - | - | Active |
| TISR_PAIR | NC (UNIQUE) | BuyCurrencyID, SellCurrencyID | - | - | Active |
| TISR_SELL | NC | SellCurrencyID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TDCUR_TSISU | FK | BuyCurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_TDCUR_TSISV | FK | SellCurrencyID -> Dictionary.Currency(CurrencyID) |
| TISR_NULLBUY | DEFAULT | BuyCurrencyID defaults to 0 |
| TISR_NULLSELL | DEFAULT | SellCurrencyID defaults to 0 |
| DB_TradeInstrumentIsMajor | DEFAULT | IsMajor defaults to 0 (not major) |
| D_OperationMode | DEFAULT | OperationMode defaults to 0 (standard) |
| DF_Instrument_SysStart | DEFAULT | SysStartTime defaults to GETUTCDATE() |
| DF_Instrument_SysEnd | DEFAULT | SysEndTime defaults to '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Get all major forex instruments with currency names
```sql
SELECT i.InstrumentID,
       bc.Abbreviation AS BuyCurrency,
       sc.Abbreviation AS SellCurrency,
       i.DollarRatio,
       i.PriceServerID
  FROM Trade.Instrument i WITH (NOLOCK)
  JOIN Dictionary.Currency bc WITH (NOLOCK) ON i.BuyCurrencyID = bc.CurrencyID
  JOIN Dictionary.Currency sc WITH (NOLOCK) ON i.SellCurrencyID = sc.CurrencyID
 WHERE i.IsMajor = 1
   AND i.BuyCurrencyID < 100
   AND i.SellCurrencyID < 100
 ORDER BY i.InstrumentID
```

### 8.2 Find instruments assigned to a specific OME and shard
```sql
SELECT i.InstrumentID,
       i.OMEID,
       i.ShardID,
       i.OperationMode
  FROM Trade.Instrument i WITH (NOLOCK)
 WHERE i.OMEID = 3
   AND i.ShardID = 1
 ORDER BY i.InstrumentID
```

### 8.3 Instrument distribution summary by OME and shard
```sql
SELECT i.OMEID,
       i.ShardID,
       COUNT(*) AS InstrumentCount,
       SUM(CASE WHEN i.IsMajor = 1 THEN 1 ELSE 0 END) AS MajorCount
  FROM Trade.Instrument i WITH (NOLOCK)
 WHERE i.OMEID IS NOT NULL
 GROUP BY i.OMEID, i.ShardID
 ORDER BY i.OMEID, i.ShardID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Instruments MAPI 20 July 21 | Confluence | API documentation for instrument management endpoints |
| Instruments Discovery API | Confluence | API for instrument discovery and search functionality |
| No Prices - Add sources to instruments in Price desk | Confluence | Price feed configuration and source management for instruments |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.1/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Instrument | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Instrument.sql*


### Upstream `etoro.Trade.ProviderToInstrument` — production
- **Resolved as**: `etoro.Trade.ProviderToInstrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.ProviderToInstrument.md`

# Trade.ProviderToInstrument

> Per-provider, per-instrument trading configuration that defines fees, limits, allowed operations, and risk parameters for each instrument routed through each execution provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID (composite PK) |
| **Partition** | No |
| **Indexes** | 4 active (PK + IX_ProviderToInstrument_AmountFormula, TPVI_INSTRUMENT, TPVI_PROVIDER) |

---

## 1. Business Meaning

Trade.ProviderToInstrument is the junction table that links each Trade.Provider (execution venue, e.g., Tradonomi) to each Trade.Instrument (tradeable asset, e.g., EUR/USD, Bayer AG) and holds the provider-specific trading configuration for that pair. While Trade.Instrument defines what can be traded and Trade.Provider defines who executes, ProviderToInstrument defines **how** each instrument is traded through each provider: precision, fees, min/max position size, spread parameters, and dozens of Allow* flags that control which trading operations are permitted.

This table exists because the same instrument can be offered through multiple providers with different terms (fees, leverage, order types), and a single provider may offer thousands of instruments with varying configurations. Without it, the system could not determine which operations are allowed for a given position, what fees to apply, or what risk limits (stop-loss, take-profit, max position) apply. Trade.GetProviderToInstrument, position views (GetPositionData, GetPositionDataSlim), and order/close procedures all JOIN here to resolve Unit, Precision, MinPositionAmount, and Allow* flags.

Data is created via `Trade.ProviderToInstrumentAdd` and edited by `Trade.ProviderToInstrumentEdit`. On INSERT, triggers populate `Trade.CurrencyPrice` with zero bid/ask and `History.ProviderToInstrument` with a new valid-from row. System versioning tracks all changes to `History.TradeProviderToInstrument`. ASM-generated audit triggers log key columns to `History.AuditHistory`.

---

## 2. Business Logic

### 2.1 Provider-Instrument Pair as Trading Configuration

**What**: Each row is a unique (ProviderID, InstrumentID) pair that defines trading parameters for that combination.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Enabled`, `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowClosePosition`, `AllowExitOrder`, etc.

**Rules**:
- One row per (ProviderID, InstrumentID). Enabled=1 means the instrument is tradeable through that provider; Enabled=0 disables trading.
- AllowBuy/AllowSell control direction. AllowPendingOrders/AllowEntryOrders control order types. AllowClosePosition/AllowExitOrder control close behavior.
- VisibleInternallyOnly=1 hides the instrument from external clients; used for internal/ops instruments.
- Trade.CheckValidInstruments, Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage raise error 60127 if InstrumentID is not found in ProviderToInstrument.

**Diagram**:
```
ProviderID=1 (Tradonomi) + InstrumentID=1 (EUR/USD) -> AllowBuy=1, AllowSell=1, Precision=3, Unit=1000
ProviderID=1 + InstrumentID=2 (GBP) -> AllowBuy=1, AllowSell=0 (sell disabled)
ProviderID=1 + InstrumentID=3 (NZD/USD) -> AllowBuy=0, AllowSell=1
```

### 2.2 Stop-Loss and Take-Profit Constraints

**What**: Min/max and default values for SL/TP percentages, with separate rules for leveraged vs non-leveraged positions.

**Columns/Parameters Involved**: `MinStopLossPercentage`, `MaxStopLossPercentage`, `DefaultStopLossPercentage`, `MinTakeProfitPercentage`, `MaxTakeProfitPercentage`, `DefaultTakeProfitPercentage`, `AllowLeveragedLongSL`, `AllowNonLeveragedLongSL`, `AllowLeveragedShortSL`, `AllowNonLeveragedShortSL`, `AllowLeveragedLongTP`, etc.

**Rules**:
- User-configured SL/TP must lie within [MinStopLossPercentage, MaxStopLossPercentage] and [MinTakeProfitPercentage, MaxTakeProfitPercentage].
- AllowLeveragedLongSL/AllowNonLeveragedLongSL (and Short equivalents) control whether SL is allowed for each direction and leverage type.
- DefaultStopLossPercentage/DefaultTakeProfitPercentage are used when opening positions without explicit SL/TP.
- GuaranteeSLTP=1 means broker guarantees execution at SL/TP levels; AllowEditSLTP controls whether user can change after open.

### 2.3 Fee and Margin Configuration

**What**: End-of-week, overnight, and holding fees plus margin requirements per instrument-provider pair.

**Columns/Parameters Involved**: `EndOfWeekFee`, `BuyEOWFee`, `SellEOWFee`, `BuyOverNightFee`, `SellOverNightFee`, `EtoroHoldingFeeSpreadFactor`, `Leverage1MaintenanceMargin`, `Unit`, `UnitMargin`, `LiquidityLotSize`, `LiquidityLotCost`.

**Rules**:
- EOW and overnight fees can differ by direction (Buy vs Sell). EtoroHoldingFeeSpreadFactor > 0 (CHECK constraint).
- Leverage1MaintenanceMargin is the margin percentage at 1x leverage.
- Unit and UnitMargin drive position size and pip-value calculations. HedgeExposureQuery uses PTI.Unit when resolving exposure.

---

## 3. Data Overview

| ProviderID | InstrumentID | PresentationCode | Enabled | AllowBuy | AllowSell | VisibleInternallyOnly | Meaning |
|------------|--------------|------------------|---------|----------|-----------|------------------------|---------|
| 1 | 1 | EURUSD= | 1 | 1 | 1 | 0 | EUR/USD forex pair. Full buy/sell, external. Standard forex configuration for major pair. |
| 1 | 2 | GBP= | 1 | 1 | 0 | 1 | GBP currency. Buy only, internally visible (likely ops/test). Sell disabled. |
| 1 | 3 | NZDUSD12= | 1 | 0 | 1 | 0 | NZD/USD pair. Sell only (no buy). Used when swap/funding favors one direction. |
| 1 | 5 | JPY= | 1 | 1 | 1 | 0 | JPY forex. Both directions, pending/entry orders allowed. High pip-value instrument (AboveDollarPrecision=3). |
| 1 | 10 | EURJPY= | 1 | 1 | 1 | 0 | EUR/JPY cross. Full trading. Leverage1MaintenanceMargin=0 indicates special margin treatment. |

**Selection criteria**: Picked from live TOP 10 by InstrumentID. EUR/USD (1), GBP (2), NZD/USD (3), CAD (4), JPY (5), CHF (6), AUD (7), EUR/GBP (8), EUR/CHF (9), EUR/JPY (10) show variety of AllowBuy/AllowSell combinations and VisibleInternallyOnly.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 0 | CODE-BACKED | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). Part of PK. |
| 2 | InstrumentID | int | NO | 0 | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. Part of PK. |
| 3 | Precision | tinyint | NO | - | CODE-BACKED | Decimal places for price display and rounding. Used by Trade.ChangeTreePropertiesPerInstrument, Trade.UpdatePositionsTakeProfitByInstrumentID. |
| 4 | PaymentBid | int | NO | - | CODE-BACKED | Bid-side payment adjustment (basis points or similar). Negative values observed (e.g., -250). |
| 5 | PaymentAsk | int | NO | - | CODE-BACKED | Ask-side payment adjustment. Positive values observed (e.g., 250). |
| 6 | PresentationCode | varchar(20) | NO | - | CODE-BACKED | Display code for the instrument (e.g., EURUSD=, GBP=, JPY=). Used in UI and reporting. |
| 7 | StopLossPercentage | int | NO | - | CODE-BACKED | Legacy or alternate SL percentage field. Sample data shows 0. |
| 8 | EndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week holding fee. Used in ClaimEndOfWeekFee, fee calculations. |
| 9 | Unit | int | NO | - | CODE-BACKED | Base unit size for the instrument. HedgeExposureQuery uses PTI.Unit. Typically 1000 for forex. |
| 10 | UnitMargin | int | NO | - | CODE-BACKED | Margin factor per unit. Used in margin and exposure calculations. |
| 11 | Benchmark | int | NO | - | CODE-BACKED | Reference value for pricing (e.g., 10000 for forex). |
| 12 | LiquidityLotSize | int | NO | - | CODE-BACKED | Lot size for liquidity provider orders. |
| 13 | LiquidityLotCost | money | NO | - | CODE-BACKED | Cost per liquidity lot. |
| 14 | DisplayOrder | int | NO | - | CODE-BACKED | Sort order for UI display. |
| 15 | WeekendPips | int | YES | - | CODE-BACKED | Weekend spread or fee in pips. |
| 16 | MinimumSpread | dbo.dtPrice | YES | - | CODE-BACKED | Minimum spread allowed. |
| 17 | OrdersSpread | int | YES | - | CODE-BACKED | Spread applied to orders. Sample 200. |
| 18 | OrdersSpreadMax | int | YES | - | CODE-BACKED | Maximum spread for orders. Sample 10. |
| 19 | MarketRange | int | YES | - | CODE-BACKED | Market range validation limit. Sample 10000000. |
| 20 | SpreadPct | dbo.dtPrice | NO | 0 | CODE-BACKED | Spread as percentage. |
| 21 | BonusCreditUsePercent | int | NO | 0 | CODE-BACKED | Percentage of position that can use bonus credit. Trade.InstrumentNWADecreasePercentage view. |
| 22 | BuyEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for buy positions. |
| 23 | SellEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for sell positions. |
| 24 | BuyOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for buy positions. |
| 25 | SellOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for sell positions. |
| 26 | MaxStopLossPercentage | decimal(5,2) | NO | 100 | CODE-BACKED | Maximum allowed stop-loss percentage. Enforced on edit. |
| 27 | Enabled | tinyint | NO | 0 | CODE-BACKED | 1=instrument tradeable through this provider, 0=disabled. Trade.GetProviderToInstrument filters Enabled=1. |
| 28 | AllowedRateDiffPercentage | decimal(5,2) | NO | 90 | CODE-BACKED | Max allowed rate difference for order execution validation. |
| 29 | EtoroHoldingFeeSpreadFactor | money | NO | 1 | CODE-BACKED | Multiplier for eToro holding fee. CHECK > 0. |
| 30 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Max position size in units. CHECK <= 2147483647. |
| 31 | MinPositionAmount | money | NO | - | CODE-BACKED | Minimum position size in currency. Trade.InstrumentMinPositionAmount view. |
| 32 | AllowBuy | bit | NO | 1 | CODE-BACKED | 1=buy allowed, 0=buy disabled for this instrument-provider pair. |
| 33 | AllowSell | bit | NO | 1 | CODE-BACKED | 1=sell allowed, 0=sell disabled. |
| 34 | AllowPendingOrders | bit | NO | 1 | CODE-BACKED | 1=pending orders allowed, 0=market only. |
| 35 | AllowEntryOrders | bit | NO | 1 | CODE-BACKED | 1=entry orders allowed, 0=no entry orders. |
| 36 | VisibleInternallyOnly | bit | NO | 0 | CODE-BACKED | 1=hidden from external clients (internal/ops only), 0=visible to all. |
| 37 | AllowClosePosition | bit | NO | 1 | CODE-BACKED | 1=user can close position, 0=close disabled. |
| 38 | AllowExitOrder | bit | NO | 1 | CODE-BACKED | 1=exit orders allowed, 0=no exit orders. |
| 39 | GuaranteeSLTP | bit | NO | 0 | CODE-BACKED | 1=broker guarantees SL/TP execution, 0=no guarantee. |
| 40 | AllowEditSLTP | bit | NO | 1 | CODE-BACKED | 1=user can edit SL/TP after open, 0=no edit. |
| 41 | MaxTakeProfitPercentage | decimal(7,2) | NO | 1000 | CODE-BACKED | Maximum allowed take-profit percentage. |
| 42 | MaxClosingPriceDiffPercentage | decimal(5,2) | YES | - | CODE-BACKED | Max allowed closing price difference. Sample 5. |
| 43 | SettledBuyMaxLeverage | int | NO | 0 | CODE-BACKED | Max leverage for settled (real) buy positions. 0=not applicable. |
| 44 | SettledSellMaxLeverage | int | NO | 0 | CODE-BACKED | Max leverage for settled sell positions. |
| 45 | AllowManualTrading | bit | NO | 1 | CODE-BACKED | 1=manual trading allowed, 0=copy-only or disabled. |
| 46 | Leverage1MaintenanceMargin | decimal(5,2) | NO | 100 | CODE-BACKED | Maintenance margin percentage at 1x leverage. Sample 100 or 11.11. |
| 47 | RequiresW8Ben | bit | NO | 0 | CODE-BACKED | 1=US tax form W-8BEN required for this instrument, 0=not required. |
| 48 | MinStopLossPercentage | decimal(5,2) | NO | 0 | CODE-BACKED | Minimum allowed stop-loss percentage. |
| 49 | MinTakeProfitPercentage | decimal(7,2) | NO | 0 | CODE-BACKED | Minimum allowed take-profit percentage. |
| 50 | DefaultStopLossPercentage | decimal(5,2) | NO | 50 | CODE-BACKED | Default SL when opening without explicit SL. |
| 51 | DefaultTakeProfitPercentage | decimal(7,2) | NO | 50 | CODE-BACKED | Default TP when opening without explicit TP. |
| 52 | AllowTrailingStopLoss | bit | NO | 1 | CODE-BACKED | 1=trailing SL allowed, 0=not allowed. |
| 53 | DefaultTrailingStopLoss | bit | NO | 0 | CODE-BACKED | 1=trailing SL on by default, 0=off by default. |
| 54 | AllowEditStopLoss | bit | NO | 1 | CODE-BACKED | 1=user can edit SL, 0=no edit. |
| 55 | AllowEditTakeProfit | bit | NO | 1 | CODE-BACKED | 1=user can edit TP, 0=no edit. |
| 56 | AllowLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged long positions, 0=not allowed. |
| 57 | AllowNonLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged long, 0=not allowed. |
| 58 | AllowLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged short, 0=not allowed. |
| 59 | AllowNonLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged short, 0=not allowed. |
| 60 | AllowLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged long, 0=not allowed. |
| 61 | AllowNonLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged long, 0=not allowed. |
| 62 | AllowLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged short, 0=not allowed. |
| 63 | AllowNonLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged short, 0=not allowed. |
| 64 | AllowRedeem | tinyint | NO | 0 | CODE-BACKED | Redeem/withdrawal allowance. 0=no redeem, 1+=allowed with constraints. |
| 65 | MinPositionUnitsForRedeem | decimal(16,8) | YES | 0.1 | CODE-BACKED | Min units for redeem when AllowRedeem > 0. |
| 66 | MaxPositionUnitsForRedeem | decimal(16,8) | YES | 100000 | CODE-BACKED | Max units for redeem. |
| 67 | AllowEditStopLossLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit SL allowed for leveraged positions, 0=no edit. |
| 68 | AllowEditTakeProfitLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit TP allowed for leveraged positions, 0=no edit. |
| 69 | AllowPartialClosePosition | tinyint | NO | 1 | CODE-BACKED | 1=partial close allowed, 0=full close only. |
| 70 | DefaultStopLossPercentageLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for leveraged positions. |
| 71 | DefaultStopLossPercentageNonLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for non-leveraged positions. |
| 72 | ExchangeFeeMultiplier | tinyint | YES | - | CODE-BACKED | Multiplier for exchange fee. Sample 2 or 4. |
| 73 | DbLoginName | varchar(128) | NO | - | CODE-BACKED | Computed: suser_name(). Current DB login. |
| 74 | AppLoginName | varchar(500) | NO | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context. |
| 75 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start. GENERATED ALWAYS AS ROW START. |
| 76 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System versioning row end. GENERATED ALWAYS AS ROW END. |
| 77 | AboveDollarPrecision | tinyint | NO | - | CODE-BACKED | Precision for amounts above dollar threshold. Sample 3 or 5. |
| 78 | MarketRangeValidationType | tinyint | NO | 1 | CODE-BACKED | How market range is validated. 1=default, 2=percentage-based. |
| 79 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Market range as percentage when MarketRangeValidationType=2. Sample 0.2, 0.5. |
| 80 | DesignatedExecutionSystem | tinyint | NO | 1 | CODE-BACKED | Execution system routing. 1=default. Trade.UpdateDesignatedExecutionSystemBulk updates. |
| 81 | InitialMarginInAssetCurrency | decimal(16,8) | YES | - | CODE-BACKED | Initial margin in asset currency. Sample 90, 3, or NULL. |
| 82 | StopLossMarginInAssetCurrency | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss margin in asset currency. Sample 80, 3, or NULL. |
| 83 | AllowedOpenOrderType | tinyint | NO | 0 | CODE-BACKED | Allowed open order types. 0=default. |
| 84 | UnitsQuantityType | tinyint | NO | 0 | CODE-BACKED | How units/quantity are expressed. 0=default. |
| 85 | TradeUnitType | tinyint | NO | 0 | CODE-BACKED | Unit type for trading. 0=default. |
| 86 | OrderFillBehaviorType | tinyint | NO | 0 | CODE-BACKED | Order fill behavior. 0=default. |
| 87 | AmountFormula | tinyint | NO | 0 | CODE-BACKED | Formula for position amount calculation. Indexed for lookups. |
| 88 | Slippage | decimal(10,4) | YES | - | CODE-BACKED | Allowed slippage. Sample 0, 3, 8. Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage. |
| 89 | ExtendedMarginAllowed | bit | NO | 0 | CODE-BACKED | 1=extended margin allowed, 0=standard only. |
| 90 | AllowedRateDiffPercentageUpside | decimal(8,2) | NO | 999 | CODE-BACKED | Max rate diff on upside. Default 999 (effectively unlimited). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | FK | Execution provider (e.g., Tradonomi). ProviderToInstrument rows exist per provider-instrument pair. |
| InstrumentID | Trade.Instrument | FK | Tradeable instrument. Each instrument can have multiple provider configs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetProviderToInstrument | FROM | JOIN | Primary view exposing provider-instrument config to clients. |
| Trade.GetInstrumentTradingData | FROM | JOIN | Instrument trading data. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | TP2I | JOIN | Position data with Unit, Precision, config. |
| Trade.GetInstrumentDataDealing | PTI | JOIN | Dealing instrument data. |
| Trade.SplitOpenPositions | FROM | JOIN | Split positions by provider-instrument. |
| Trade.ProviderToInstrumentAdd | INSERT | Writer | Creates new rows. |
| Trade.ProviderToInstrumentEdit | UPDATE | Modifier | Updates config. |
| Trade.ProviderToInstrumentDelete | DELETE | Deleter | Removes provider-instrument link. |
| Trade.CheckValidInstruments | EXISTS | Lookup | Validates instrument exists in ProviderToInstrument. |
| Trade.HedgeExposureQuery | PTI | JOIN | Resolves Unit for hedge exposure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrument (table)
├── Trade.Provider (table)
└── Trade.Instrument (table)
      └── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | FK ProviderID. Provider must exist. |
| Trade.Instrument | Table | FK InstrumentID. Instrument must exist. |
| dbo.dtPrice | UDT | Used for MinimumSpread, SpreadPct columns. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | Primary read path. |
| Trade.GetInstrumentTradingData | View | JOIN for config. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | View | JOIN for Unit, config. |
| Trade.ProviderToInstrumentAdd | Procedure | INSERT. |
| Trade.ProviderToInstrumentEdit | Procedure | UPDATE. |
| Trade.ProviderToInstrumentDelete | Procedure | DELETE. |
| Trade.CheckValidInstruments | Procedure | EXISTS check. |
| Trade.HedgeExposureQuery | Procedure | JOIN for Unit. |
| Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage | Procedure | Read/update Slippage. |
| History.TradeProviderToInstrument | Table | System versioning history. |
| History.ProviderToInstrument | Table | Trigger-maintained history (ValidFrom/ValidTo). |
| Trade.CurrencyPrice | Table | InstrumentProviderInsert trigger seeds row on INSERT. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPVI | NC PK | ProviderID, InstrumentID | - | - | Active |
| IX_ProviderToInstrument_AmountFormula | NC | InstrumentID, ProviderID | AmountFormula | - | Active |
| TPVI_INSTRUMENT | NC | InstrumentID | - | - | Active |
| TPVI_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TSISR_TSPTI | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_TSPRV_TSPTI | FK | ProviderID -> Trade.Provider(ProviderID) |
| CH_TradeProviderToInstrument_EtoroHoldingFeeSpreadFactor | CHECK | EtoroHoldingFeeSpreadFactor > 0 |
| chk_MaxPositionUnits_max_value | CHECK | MaxPositionUnits <= 2147483647 |
| TPVI_NULLPROVIDER | DEFAULT | ProviderID = 0 |
| TPVI_NULLINSTRUMENT | DEFAULT | InstrumentID = 0 |
| (Multiple) | DEFAULT | Various columns have defaults per DDL |

---

## 8. Sample Queries

### 8.1 List enabled instruments for a provider
```sql
SELECT pti.InstrumentID, pti.PresentationCode, pti.Precision, pti.Unit, pti.MinPositionAmount,
       pti.AllowBuy, pti.AllowSell, pti.Enabled
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 WHERE pti.ProviderID = 1 AND pti.Enabled = 1
 ORDER BY pti.InstrumentID;
```

### 8.2 Get provider-instrument config with instrument and provider names
```sql
SELECT pti.ProviderID, prov.Name AS ProviderName, pti.InstrumentID, ins.BuyCurrencyID, ins.SellCurrencyID,
       pti.PresentationCode, pti.Precision, pti.Unit, pti.MinPositionAmount, pti.MaxStopLossPercentage,
       pti.AllowBuy, pti.AllowSell
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 INNER JOIN Trade.Provider prov WITH (NOLOCK) ON prov.ProviderID = pti.ProviderID
 INNER JOIN Trade.Instrument ins WITH (NOLOCK) ON ins.InstrumentID = pti.InstrumentID
 WHERE pti.Enabled = 1
 ORDER BY pti.InstrumentID, pti.ProviderID;
```

### 8.3 Find instruments with sell disabled (buy-only)
```sql
SELECT pti.InstrumentID, pti.PresentationCode, pti.ProviderID, pti.AllowBuy, pti.AllowSell,
       pti.VisibleInternallyOnly
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 WHERE pti.Enabled = 1 AND pti.AllowBuy = 1 AND pti.AllowSell = 0
 ORDER BY pti.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Important DBs and DB Main | Confluence | Database architecture context |
| EtoroOps Flows - Screen List Documentation | Confluence | Ops workflow references |
| Routing Tool Mapping | Confluence | Provider/instrument routing context |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 90 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 20+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrument | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ProviderToInstrument.sql*


### Upstream `etoro.Trade.InstrumentCusip` — production
- **Resolved as**: `etoro.Trade.InstrumentCusip`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Views\Trade.InstrumentCusip.md`

# Trade.InstrumentCusip

> Thin projection of Trade.InstrumentMetaData exposing InstrumentID, CUSIP (aliased from Cusip), and ISINCode for compliance and lookup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentCusip provides a minimal interface to regulatory identifiers (CUSIP and ISIN) per instrument. CUSIP (Committee on Uniform Securities Identification Procedures) is used primarily for US and Canadian securities; ISIN (International Securities Identification Number) is the global standard. This view exists to simplify lookups where only these identifiers are needed - for example SalesForce integration, Trade.CheckValidInstruments validation, or Trade.UpdateCusip bulk updates - without selecting the full InstrumentMetaData row.

Without this view, callers would SELECT InstrumentID, Cusip, ISINCode directly from InstrumentMetaData. The view adds the CUSIP alias (Cusip -> CUSIP) for consistency with external systems that expect uppercase CUSIP as the column name.

---

## 2. Business Logic

### 2.1 Regulatory Identifier Projection

**What**: Expose InstrumentID and the two main regulatory codes (CUSIP, ISIN) from InstrumentMetaData.

**Columns/Parameters Involved**: `InstrumentID`, `CUSIP`, `ISINCode`

**Rules**:
- Direct SELECT from Trade.InstrumentMetaData with no filters.
- CUSIP is an alias for the Cusip column (CUSIP = Cusip).
- ISINCode is passed through unchanged.
- Both CUSIP and ISINCode are nullable; stocks typically have ISIN, US/Canada securities may have CUSIP. Forex and crypto usually have NULL for both.

**Diagram**:
```
Trade.InstrumentMetaData
    |-- InstrumentID
    |-- Cusip -> aliased as CUSIP
    |-- ISINCode
    v
Trade.InstrumentCusip (InstrumentID, CUSIP, ISINCode)
```

---

## 3. Data Overview

| InstrumentID | CUSIP | ISINCode | Meaning |
|--------------|-------|----------|---------|
| 1 | aaa123 | ccc345 | Sample/test data with both codes |
| 2 | NULL | NULL | Forex or non-equity; no regulatory IDs |
| 3 | NULL | NULL | Same pattern |
| 4 | NULL | NULL | Same pattern |
| 5 | NULL | NULL | Same pattern |

**Selection criteria for the 5 rows:** TOP 5 from live query. InstrumentID 1 has both CUSIP and ISINCode (likely test data). InstrumentIDs 2-5 have NULL for both - typical for forex or instruments without regulatory identifiers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK of Trade.Instrument. Same as InstrumentMetaData.InstrumentID. Identifies the tradeable instrument. |
| 2 | CUSIP | varchar(255) | YES | - | CODE-BACKED | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. |
| 3 | ISINCode | varchar(30) | YES | - | CODE-BACKED | International Securities Identification Number. From InstrumentMetaData.ISINCode. Required for stocks in many jurisdictions. NULL for forex, crypto. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via InstrumentMetaData.InstrumentID |

### 5.2 Base Tables (FROM)

| Table | How Used |
|-------|----------|
| Trade.InstrumentMetaData | Direct SELECT of InstrumentID, Cusip (as CUSIP), ISINCode |

### 5.3 Referenced By (other objects point to this)

| Source Object | Role | Description |
|---------------|------|-------------|
| SalesForce.GetInstruments | READER | LEFT JOIN Trade.InstrumentCusip TC for CUSIP/ISIN in instrument list |
| Trade.CheckValidInstruments | READER | UNION ALL includes SELECT TOP 1 1 FROM Trade.InstrumentCusip WHERE InstrumentID=@InstrumentID for validation |
| Trade.UpdateCusip | MODIFIER | Reads from Trade.InstrumentCusip (alias a) as part of CUSIP update logic |
| Trade.GetInstrumentCusip | Procedure | Different object - reads InstrumentMetaData directly; returns Cusip, SEDOL. Not a consumer of this view. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentCusip (view)
    |
    +-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - source of InstrumentID, Cusip, ISINCode |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SalesForce.GetInstruments | Procedure | LEFT JOIN for CUSIP/ISIN |
| Trade.CheckValidInstruments | Procedure | EXISTS-style validation |
| Trade.UpdateCusip | Procedure | FROM in update logic |

---

## 7. Technical Details

### 7.1 DDL Summary

- **Base table**: Trade.InstrumentMetaData
- **Logic**: SELECT InstrumentID, CUSIP = Cusip, ISINCode. No WHERE, no JOINs.
- **Output**: InstrumentID, CUSIP, ISINCode

### 7.2 Column Sources

| Output Column | Source Table | Source Column |
|---------------|--------------|---------------|
| InstrumentID | Trade.InstrumentMetaData | InstrumentID |
| CUSIP | Trade.InstrumentMetaData | Cusip (aliased) |
| ISINCode | Trade.InstrumentMetaData | ISINCode |

---

## 8. Sample Queries

### 8.1 Get CUSIP and ISIN for instruments
```sql
SELECT InstrumentID, CUSIP, ISINCode
FROM Trade.InstrumentCusip WITH (NOLOCK)
WHERE InstrumentID IN (1, 1001, 1002)
ORDER BY InstrumentID;
```

### 8.2 Instruments with CUSIP populated
```sql
SELECT InstrumentID, CUSIP, ISINCode
FROM Trade.InstrumentCusip WITH (NOLOCK)
WHERE CUSIP IS NOT NULL
ORDER BY InstrumentID;
```

### 8.3 Join with instrument metadata for full context
```sql
SELECT tc.InstrumentID, tc.CUSIP, tc.ISINCode,
       imd.InstrumentDisplayName, imd.SymbolFull
FROM Trade.InstrumentCusip tc WITH (NOLOCK)
JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON tc.InstrumentID = imd.InstrumentID
WHERE tc.ISINCode IS NOT NULL
ORDER BY tc.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentCusip | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentCusip.sql*


### Upstream `etoro.Trade.InstrumentGroups` — production
- **Resolved as**: `etoro.Trade.InstrumentGroups`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.InstrumentGroups.md`

# Trade.InstrumentGroups

> Junction table mapping trading instruments to classification groups, enabling the platform to control which instruments are restricted to real stock only, blocked from copy trading, CFD-only, US-restricted, or subject to Net Open Position (NOP) exposure limits.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (InstrumentID, GroupID) CLUSTERED |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 341 (MCP verified) |
| **Indexes** | 1 active (PK only) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON, history: History.TradeInstrumentGroups |

---

## 1. Business Meaning

Trade.InstrumentGroups is a many-to-many junction table that classifies trading instruments into behavioral groups. Each group defines a specific characteristic or restriction that applies to all instruments assigned to it. For example, an instrument in the "RealOnly" group (GroupID=1) can only be traded as a real stock purchase, while an instrument in "CopyBlock" (GroupID=2) cannot be opened via copy trading. An instrument can belong to multiple groups simultaneously (e.g., both RealOnly and US_Restricted).

Without this table, the platform would have no centralized mechanism to enforce instrument-level trading restrictions. Fee calculations (Trade.FnGetCloseFixPerLot, Trade.FnGetCloseFeeInPercentage), copy-trade restrictions (Trade.GetSmartCopyRestrictions), and regulatory compliance (US_Restricted group) all depend on group membership lookups.

Group assignments are managed by back-office operations through Trade.InsertInstrumentGroup and Trade.DeleteInstrumentGroup, both accepting TVP (Trade.InstrumentGroupsTbl) for bulk operations. The AppLoginName parameter is stored in CONTEXT_INFO for temporal audit trail. The INSERT trigger (TRG_InstrumentGroups_INSERT) forces a dummy UPDATE immediately after INSERT to ensure the temporal system captures the initial row version with the correct CONTEXT_INFO.

---

## 2. Business Logic

### 2.1 Instrument Group Membership

**What**: Determines whether a specific instrument belongs to a specific group, controlling trading behavior and restrictions.

**Columns/Parameters Involved**: `InstrumentID`, `GroupID`, `ProviderID`

**Rules**:
- An instrument can belong to zero or more groups simultaneously
- Group membership is checked by Trade.IsInstrumentInGroup(InstrumentID, GroupID) which returns BIT (1=in group, 0=not)
- Key business groups (by active instrument count):
  - GroupID 49: Most instruments (88) - used in fee calculations
  - GroupID 1 "RealOnly" (76 instruments): Instrument can only be traded as real stock, not CFD
  - GroupID 2 "CopyBlock" (73 instruments): Instrument cannot be opened via CopyTrader
  - GroupID 4 "US_Restricted" (68 instruments): Instrument restricted for US-regulated customers
  - GroupID 3 "CFDOnly": Instrument can only be traded as CFD, not real stock
- MaxNOP groups (33-52): Net Open Position exposure limits per tier (A=$80M, B=$40M, C=$20M, D=$12M, E=$10M)

**Diagram**:
```
Instrument (e.g., Apple stock)
    |
    +-- Group 1: RealOnly      --> Can buy real shares
    +-- Group 2: CopyBlock     --> Cannot be copy-traded
    +-- Group 4: US_Restricted  --> Restricted for US clients
    +-- Group 49: (fee group)   --> Specific fee schedule applies

Trade.IsInstrumentInGroup(@InstrumentID, @GroupID) = 1/0
    |
    +-- Used by: Fee calculations, copy-trade validation, regulatory checks
```

### 2.2 Temporal Audit via INSERT Trigger

**What**: Ensures every INSERT operation is captured in the temporal history with the correct application context.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- TRG_InstrumentGroups_INSERT fires after each INSERT and performs a no-op UPDATE (sets columns to their own values)
- This forces SQL Server temporal system to record a "before" snapshot in History.TradeInstrumentGroups
- The computed AppLoginName column captures the CONTEXT_INFO set by the calling procedure, identifying the back-office user who made the change
- CONTEXT_INFO is set by Trade.InsertInstrumentGroup / Trade.DeleteInstrumentGroup from the @AppLoginName parameter

---

## 3. Data Overview

| ProviderID | InstrumentID | GroupID | GroupName | Meaning |
|---|---|---|---|---|
| 1 | 1 | 1 | RealOnly | This instrument (ID 1) with provider 1 is restricted to real stock purchases only - customers cannot trade it as a CFD |
| 1 | 1 | 2 | CopyBlock | Same instrument is also blocked from being opened via CopyTrader - customers can only trade it independently |
| 1 | 1 | 4 | US_Restricted | Also restricted for US-regulated accounts - US customers cannot trade this instrument |
| 1 | 1 | 38 | MaxNOPLimit_C_OLD_$1.25M | Subject to an older $1.25M net open position limit in tier C |
| 1 | 5 | 26 | QaAutomation01 | QA automation test group assignment - used for automated testing of group membership logic |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | VERIFIED | Liquidity provider/broker identifier. Part of composite FK to Trade.ProviderToInstrument(ProviderID, InstrumentID). All current rows use ProviderID=1 (primary provider). Determines which provider's instrument listing this group membership applies to. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Trading instrument identifier. Part of composite PK (InstrumentID, GroupID) and composite FK to Trade.ProviderToInstrument. References the instrument being classified. An instrument can appear in multiple rows with different GroupIDs. |
| 3 | GroupID | int | NO | - | VERIFIED | Group classification identifier. Part of composite PK. FK to Dictionary.TradingInstrumentGroups(GroupID). Key values: 1=RealOnly (real stock only), 2=CopyBlock (no copy-trading), 3=CFDOnly, 4=US_Restricted. 315 total groups exist including MaxNOP limits and QA automation groups. Checked by Trade.IsInstrumentInGroup and used in fee calculations. |
| 4 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW START). Records when this group assignment became effective. Default is current UTC time at INSERT. Part of PERIOD FOR SYSTEM_TIME. |
| 5 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW END). Records when this group assignment was removed or changed. Value of 9999-12-31 indicates the assignment is current. Part of PERIOD FOR SYSTEM_TIME. |
| 6 | DbLoginName | computed | NO | - | VERIFIED | Computed audit column: `suser_name()`. Captures the SQL Server login name of the session that last modified this row. Used for auditing which database account performed the change. |
| 7 | AppLoginName | computed | NO | - | CODE-BACKED | Computed audit column: `CONVERT(varchar(500), context_info())`. Captures the application-level user identity from CONTEXT_INFO, which is set by Trade.InsertInstrumentGroup and Trade.DeleteInstrumentGroup from the @AppLoginName parameter. Identifies the back-office operator who made the group assignment change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Dictionary.TradingInstrumentGroups | Explicit FK (FK_Group) | Maps to the group definition (name, description). 315 possible groups covering trading restrictions, NOP limits, and test groups. |
| (ProviderID, InstrumentID) | Trade.ProviderToInstrument | Explicit FK (FK_ProviderToInstrument) | Validates that the instrument-provider combination exists. Ensures group assignments only apply to active provider-instrument pairs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.TradeInstrumentGroups | - | Temporal History | System-versioned history of all group assignment changes |
| Trade.IsInstrumentInGroup | InstrumentID, GroupID | SELECT EXISTS | Scalar function returning BIT - primary lookup for group membership checks |
| Trade.FnGetCloseFixPerLot | - | JOIN | Uses group membership for close-fee-per-lot calculations |
| Trade.FnGetCloseFeeInPercentage | - | JOIN | Uses group membership for percentage-based close fee calculations |
| Trade.InsertInstrumentGroup | ProviderID, InstrumentID, GroupID | INSERT | Bulk inserts group assignments from TVP (Trade.InstrumentGroupsTbl) |
| Trade.DeleteInstrumentGroup | ProviderID, InstrumentID, GroupID | DELETE | Bulk removes group assignments from TVP |
| Trade.GetSmartCopyRestrictions | - | Reader | Reads group membership for copy-trade restriction validation |
| Trade.GetInstrumentsAndInstrumentsGroups | - | Reader | Returns instruments with their group assignments |
| Trade.GetInstrumentDataForAPI | - | Reader | Includes group data in API instrument responses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentGroups (table)
+-- Dictionary.TradingInstrumentGroups (table) [FK target]
+-- Trade.ProviderToInstrument (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradingInstrumentGroups | Table | FK target - GroupID references GroupID |
| Trade.ProviderToInstrument | Table | FK target - (ProviderID, InstrumentID) composite FK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.TradeInstrumentGroups | Table | Temporal history table |
| Trade.IsInstrumentInGroup | Function | Checks group membership (SELECT EXISTS) |
| Trade.FnGetCloseFixPerLot | Function | JOINs for fee calculation |
| Trade.FnGetCloseFeeInPercentage | Function | JOINs for percentage fee calculation |
| Trade.InsertInstrumentGroup | Stored Procedure | Writer - bulk INSERT from TVP |
| Trade.DeleteInstrumentGroup | Stored Procedure | Deleter - bulk DELETE via TVP |
| Trade.GetSmartCopyRestrictions | Stored Procedure | Reader - copy-trade restriction checks |
| Trade.GetInstrumentsAndInstrumentsGroups | Stored Procedure | Reader - returns group assignments |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reader - API instrument data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | InstrumentID ASC, GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (PK) | PRIMARY KEY | Composite (InstrumentID, GroupID) - ensures each instrument can appear in each group at most once |
| FK_Group | FOREIGN KEY | GroupID -> Dictionary.TradingInstrumentGroups(GroupID). WITH CHECK |
| FK_ProviderToInstrument | FOREIGN KEY | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument(ProviderID, InstrumentID). WITH CHECK |

---

## 8. Sample Queries

### 8.1 List all group assignments for a specific instrument
```sql
SELECT  ig.InstrumentID,
        ig.ProviderID,
        tig.GroupName,
        ig.GroupID
FROM    Trade.InstrumentGroups ig WITH (NOLOCK)
JOIN    Dictionary.TradingInstrumentGroups tig WITH (NOLOCK)
        ON ig.GroupID = tig.GroupID
WHERE   ig.InstrumentID = 1
ORDER BY tig.GroupName;
```

### 8.2 Check if an instrument is in a specific group
```sql
SELECT  Trade.IsInstrumentInGroup(1, 2) AS IsInCopyBlockGroup;
```

### 8.3 View group assignment change history for an instrument
```sql
SELECT  InstrumentID,
        GroupID,
        DbLoginName,
        AppLoginName,
        SysStartTime,
        SysEndTime
FROM    Trade.InstrumentGroups
FOR SYSTEM_TIME ALL
WHERE   InstrumentID = 1
ORDER BY GroupID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from DDL analysis, live data sampling (341 rows across 22 groups), and procedure logic analysis (Trade.InsertInstrumentGroup, Trade.DeleteInstrumentGroup, Trade.IsInstrumentInGroup).

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentGroups | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentGroups.sql*


### Upstream `etoro.Trade.FuturesMetaData` — production
- **Resolved as**: `etoro.Trade.FuturesMetaData`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.FuturesMetaData.md`

# Trade.FuturesMetaData

> Per-instrument futures contract metadata: contract size, tick, expiration, settlement, and pricing parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_ExpirationDateTime) |
| **System Versioning** | Yes → History.FuturesMetaData |

---

## 1. Business Meaning

**WHAT**: Trade.FuturesMetaData stores contract-specific parameters for futures instruments. Each row corresponds to one Trade.Instrument that is a futures contract. It defines the multiplier (contract size), minimal tick (price granularity), last trading and expiration dates, settlement time, index point value, and optional settlement method and unit of measure.

**WHY**: Futures contracts have standardized terms that differ from spot instruments. The trading engine needs these values to calculate position sizing, margin, overnight fees (via Trade.CalcOverNightFeeRates), and API exposure for Security Ops. Without this table, the system cannot correctly price or risk-manage futures positions.

**HOW**: Data is bulk-inserted during instrument onboarding via `Trade.InsertInstrumentRealTable` from `##Trade_FuturesMetaData`, and instrument validation uses `Trade.CheckValidInstruments` to ensure futures have metadata. `Trade.UpdateFuturesMetadataSecurityOpsAPI` updates rows; reads come from `Trade.GetAllFuturesMetadataSecurityOpsAPI`, `Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI`, `Trade.GetAllInstrumentData`, `Trade.GetInstrumentDataForAPI`, and overnight fee calculations. System versioning maintains full history in History.FuturesMetaData.

---

## 2. Business Logic

### 2.1 Instrument One-to-One

**What**: Exactly one metadata row per futures InstrumentID.

**Rules**:
- InstrumentID is the primary key; each futures instrument has at most one row.
- LEFT JOIN from instrument views; only futures instruments have matches.
- Trade.CheckValidInstruments asserts existence of a row for futures before allowing use.

**Diagram**:
```
Trade.Instrument (InstrumentID)
        |
        | 1:1
        v
Trade.FuturesMetaData (InstrumentID, Multiplier, MinimalTick, ExpirationDateTime, ...)
        |
        v
History.FuturesMetaData (temporal history)
```

### 2.2 Contract Sizing and Tick

**What**: Multiplier and MinimalTick define contract economics.

**Rules**:
- Multiplier: contract size per point (e.g., 1, 2, 100). Used with price for notional.
- MinimalTick: smallest price increment (e.g., 0.25, 0.5, 0.01). Used for rounding and spread.
- IndexPointValue: value per point move (observed 1, 2, 3, 100).

### 2.3 Expiration and Settlement

**What**: LastTradingDateTime and ExpirationDateTime bound the contract lifecycle.

**Rules**:
- LastTradingDateTime: when trading ceases.
- ExpirationDateTime: contract maturity. Some use 2222-01-01 for perpetuals.
- SettlementTime: time-of-day for settlement (stored as time(7)).
- IX_ExpirationDateTime supports queries by expiration.

### 2.4 SettlementMethod and UnitOfMeasure

**What**: Optional taxonomy for settlement type and unit.

**Rules**:
- SettlementMethod (tinyint): 0 observed; NULL for legacy rows.
- UnitOfMeasure (tinyint): 0 or 1 observed; NULL for legacy rows.

---

## 3. Data Overview

| InstrumentID | Multiplier | MinimalTick | LastTradingDateTime | ExpirationDateTime | Meaning |
|--------------|------------|-------------|---------------------|--------------------|---------|
| 481 | 1 | 0.25 | 2025-12-19 10:29 | 2024-10-31 21:00 | Index futures, tight tick, short expiry. |
| 482 | 2 | 0.5 | 2025-12-14 10:29 | 2024-11-30 21:00 | Larger contract, wider tick. |
| 484 | 3 | 0.75 | 2025-09-27 11:58 | 2024-12-31 21:00 | Expired contract (historical). |
| 998 | 2 | 0.25 | 2025-11-12 12:13 | 2222-01-01 | Perpetual-style (far future expiry). |
| 999 | 100 | 0.01 | 2222-01-01 | 2222-01-01 | Large multiplier, fine tick; likely index. |

**Row count**: ~250 (live query). Selection: TOP 5 by InstrumentID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key. FK to Trade.Instrument. One row per futures instrument. |
| 2 | Multiplier | decimal(20,10) | NO | - | VERIFIED | Contract size per point. Used for notional and fee calculation. |
| 3 | MinimalTick | decimal(20,10) | NO | - | VERIFIED | Smallest price increment in contract units. |
| 4 | LastTradingDateTime | datetime | NO | - | VERIFIED | When trading stops for this contract. |
| 5 | ExpirationDateTime | datetime | NO | - | VERIFIED | Contract maturity. 2222-01-01 for perpetuals. |
| 6 | SettlementTime | time(7) | NO | - | VERIFIED | Time of day for settlement. |
| 7 | IndexPointValue | decimal(20,10) | NO | - | CODE-BACKED | Dollar/value per point move. Used in exposure and fee calc. |
| 8 | DbLoginName | nvarchar(128) | - | AS (suser_name()) | NAME-INFERRED | Computed; database login at insert. |
| 9 | AppLoginName | varchar(500) | - | AS (CONVERT(varchar(500),context_info())) | NAME-INFERRED | Computed; application context at insert. |
| 10 | SysStartTime | datetime2(7) | NO | GENERATED | VERIFIED | Row start for system versioning. |
| 11 | SysEndTime | datetime2(7) | NO | GENERATED | VERIFIED | Row end for system versioning. |
| 12 | SettlementMethod | tinyint | YES | - | CODE-BACKED | Settlement type; 0 or NULL. |
| 13 | UnitOfMeasure | tinyint | YES | - | CODE-BACKED | Unit of measure; 0, 1, or NULL. |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Join Column | Description |
|------------------|-------------|-------------|
| Trade.Instrument | InstrumentID | Each futures instrument must exist in Instrument. |

### 5.2 Referenced By

| Referencing Object | Purpose |
|--------------------|---------|
| Trade.InsertInstrumentRealTable | Bulk insert from ##Trade_FuturesMetaData. |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Updates metadata. |
| Trade.GetAllFuturesMetadataSecurityOpsAPI | Returns all futures metadata. |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Returns metadata by InstrumentID. |
| Trade.GetInstrumentDataForAPI, Trade.GetInstrumentDataForAPITest | LEFT JOIN for API instrument payload. |
| Trade.GetAllInstrumentData, Trade.GetAllInstrumentDisplayDatasForAPI | LEFT JOIN for instrument display. |
| Trade.CalcOverNightFeeRates, Trade.CalcOverNightFeeRates_TRDOPS, Trade.Elad111 | LEFT JOIN for overnight fee calculation. |
| Trade.CheckValidInstruments | Validates futures have metadata. |
| History.FuturesMetaData | Temporal history table. |

---

## 6. Dependencies

### 6.0 Chain

```
Trade.Instrument → Trade.FuturesMetaData → History.FuturesMetaData
```

### 6.1 Depends On

| Object | Type |
|--------|------|
| Trade.Instrument | Table |

### 6.2 Depended On By

| Object | Type |
|--------|------|
| History.FuturesMetaData | History Table |
| Trade.InsertInstrumentRealTable | Procedure |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Procedure |
| Trade.GetAllFuturesMetadataSecurityOpsAPI | Procedure |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Procedure |
| Trade.GetInstrumentDataForAPI | Procedure |
| Trade.GetInstrumentDataForAPITest | Procedure |
| Trade.GetAllInstrumentData | Procedure |
| Trade.GetAllInstrumentDisplayDatasForAPI | Procedure |
| Trade.CalcOverNightFeeRates | Procedure |
| Trade.CalcOverNightFeeRates_TRDOPS | Procedure |
| Trade.Elad111 | Procedure |
| Trade.CheckValidInstruments | Procedure |

---

## 7. Technical Details

### 7.1 Indexes

| Index | Type | Key Columns | Purpose |
|-------|------|-------------|---------|
| PK_FuturesMetaData | CLUSTERED | InstrumentID | Primary key. |
| IX_ExpirationDateTime | NONCLUSTERED | ExpirationDateTime | Expiration-based queries. |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_FuturesMetaData | PRIMARY KEY | InstrumentID |
| PERIOD FOR SYSTEM_TIME | System Versioning | (SysStartTime, SysEndTime) |

**Trigger**: Tr_T_FuturesMetaData_INSERT — no-op UPDATE on insert (legacy pattern).

---

## 8. Sample Queries

```sql
-- Count futures contracts with metadata
SELECT COUNT(*) AS Cnt
FROM Trade.FuturesMetaData WITH (NOLOCK);

-- Top 5 futures by InstrumentID
SELECT TOP 5 InstrumentID, Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, IndexPointValue
FROM Trade.FuturesMetaData WITH (NOLOCK)
ORDER BY InstrumentID;

-- Expiring soon (next 30 days)
SELECT InstrumentID, Multiplier, MinimalTick, ExpirationDateTime
FROM Trade.FuturesMetaData WITH (NOLOCK)
WHERE ExpirationDateTime BETWEEN GETUTCDATE() AND DATEADD(DAY, 30, GETUTCDATE())
ORDER BY ExpirationDateTime;
```

---

## 9. Atlassian Knowledge Sources

- Jira/Confluence: Not yet linked for this table.
- Code references: 14+ procedures/views in Trade schema.

---

*Generated: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*


### Upstream `etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping` — production
- **Resolved as**: `etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.FuturesInstrumentsInitialMarginByProviderMapping.md`

# Trade.FuturesInstrumentsInitialMarginByProviderMapping

> Per-instrument-per-provider initial margin requirements for futures contracts, defining the cash margin needed to open a futures position with each liquidity provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + ProviderID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table stores the initial margin requirements for each futures instrument per liquidity provider. Initial margin is the cash deposit required to open a futures position - it varies by instrument (based on contract volatility and size) and by provider (each provider sets its own margin requirements). This per-provider mapping is essential because eToro routes trades through multiple liquidity providers, each with different margin schedules.

Without this table, the platform could not validate whether a customer has sufficient margin to open a futures position, or correctly calculate the margin requirements displayed to users. The margin amounts must match the provider's requirements to avoid rejected trades or margin calls.

Settings are managed through `Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping` (updates existing mappings) and `Trade.UpdateFuturesOpsConfigurations` (bulk operations). Temporal versioning provides full audit trail of margin changes, critical for regulatory compliance in futures trading.

---

## 2. Business Logic

### 2.1 Provider-Specific Margin Requirements

**What**: The same futures instrument can have different margin requirements depending on which liquidity provider executes the trade.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`, `InitialMargin`

**Rules**:
- Each InstrumentID + ProviderID combination has exactly one InitialMargin value
- InitialMargin is expressed in the instrument's currency (dollars for US futures)
- Values range widely: from $6 for highly liquid instruments to $1,200+ for expensive contracts
- When a customer opens a futures position, the system looks up the margin for the instrument and the selected provider

### 2.2 Dual Audit Trail

**What**: Changes are tracked both by database login and application login for regulatory compliance.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- DbLoginName captures the database-level identity via SUSER_NAME()
- AppLoginName captures the application-level identity via CONTEXT_INFO()
- Temporal versioning tracks all historical margin values - essential for resolving disputes about margin requirements at time of trade

---

## 3. Data Overview

| InstrumentID | ProviderID | InitialMargin | Meaning |
|-------------|-----------|---------------|---------|
| 1 | 99 | 6.00 | Very low margin for a highly liquid instrument - likely a micro/mini futures contract |
| 2 | 99 | 20.00 | Low-margin instrument via provider 99 |
| 3 | 99 | 1,200.00 | High-margin instrument - likely a standard-size commodity or index futures contract |
| 481 | 99 | 165.00 | Mid-range margin for a specialty futures instrument |
| 482 | 99 | 61.11 | Moderate margin - non-round number suggests external provider-set requirement |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier for the futures contract. References Trade.Instrument. Part of composite PK. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider that sets this margin requirement. References Trade.Provider. Part of composite PK. Each provider has its own margin schedule. |
| 3 | InitialMargin | decimal(10,2) | NO | - | CODE-BACKED | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Range: $6 to $1,200+. |
| 4 | DbLoginName | AS (suser_name()) | NO | Computed | VERIFIED | Computed column capturing the Windows/SQL login that made the change. Database-level audit trail. |
| 5 | AppLoginName | AS (CONVERT(varchar(500), context_info())) | NO | Computed | VERIFIED | Computed column capturing the application-level login via CONTEXT_INFO(). Application-level audit trail. |
| 6 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | VERIFIED | System-managed temporal column marking when this margin configuration became effective. |
| 7 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | VERIFIED | System-managed temporal column marking when this margin configuration was superseded. 9999-12-31 = current active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Futures instrument these margin requirements apply to |
| ProviderID | Trade.Provider | Implicit | Liquidity provider setting the margin requirement |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | - | Writer | Updates margin values |
| Trade.UpdateFuturesOpsConfigurations | - | Writer | Bulk operations margin configuration |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | - | Reader | Retrieves current margin mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Stored Procedure | Updates margin requirements |
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | Bulk configuration management |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | Stored Procedure | Reads current margin data |
| History.FuturesInstrumentsInitialMarginByProviderMapping | History Table | Temporal history of all margin changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FuturesInstrumentsInitialMarginByProviderMapping | CLUSTERED PK | InstrumentID, ProviderID | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FuturesInstrumentsInitialMarginByProviderMapping | PRIMARY KEY | One row per instrument-provider combination |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | Tracks row validity period |
| SYSTEM_VERSIONING | TEMPORAL | History tracked in History.FuturesInstrumentsInitialMarginByProviderMapping |
| Tr_T_FuturesInstrumentsInitialMarginByProviderMapping_INSERT | TRIGGER (FOR INSERT) | Self-update to trigger temporal versioning on initial insert |

---

## 8. Sample Queries

### 8.1 Get margin requirements for a specific instrument across all providers
```sql
SELECT InstrumentID, ProviderID, InitialMargin
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
```

### 8.2 Find instruments with highest margin requirements
```sql
SELECT TOP 20 InstrumentID, ProviderID, InitialMargin
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
ORDER BY InitialMargin DESC
```

### 8.3 View margin change history for an instrument
```sql
SELECT InstrumentID, ProviderID, InitialMargin,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM   History.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FuturesInstrumentsInitialMarginByProviderMapping | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FuturesInstrumentsInitialMarginByProviderMapping.sql*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Dim_Instrument`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Instrument.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dim_Instrument] @dt [Date] AS
BEGIN
-- EXEC  [DWH_dbo].[SP_Dim_Instrument] '2024-12-02'
/********************************************************************************************
Author:      
Date:        
Description: 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
24.07.2022	   Inbal BML	Adding MetadataID 9315 in filter in EXTRACT TABLE [Ext_Dim_Instrument_StockInfo_InstrumentData]
30.10.2024     Inbal BML	Adding new cloumns to Dim_Instrument for Future project (IsFuture,Multiplier,ProviderID,ProviderMargin,eToroMargin,SettlementTime)
25.03.2026     Eyal Boas    a temporary fix to handle the type mismatch in the NumVal column   
*********************************************************************************************/
--declare @dt as date = '2024-12-10'
TRUNCATE TABLE [DWH_dbo].Dim_Instrument

INSERT INTO [DWH_dbo].[Dim_Instrument]
           ([InstrumentID]
           ,[InstrumentTypeID]
           ,[InstrumentType]
           ,[Name]
           ,[DWHInstrumentID]
           ,[StatusID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID]
           ,[BuyCurrency]
           ,[SellCurrency]
           ,[TradeRange]
           ,[DollarRatio]
           ,[PipDifferenceThreshold]
           ,[IsMajorID]
           ,[IsMajor]
           ,[UpdateDate]
           ,[InsertDate]
           ,[InstrumentDisplayName]
           ,[Industry]
           ,[CompanyInfo]
           ,[Exchange]
           ,[ISINCode]
           ,[ISINCountryCode]
           ,[Tradable]
           ,[Symbol]
           ,[BonusCreditUsePercent]
           ,[SymbolFull]
           ,[CUSIP]
           ,[Precision]
           ,[AllowBuy]
           ,[AllowSell]
           ,[VisibleInternallyOnly]
		   ,[IsFuture]
		   ,[Multiplier]
		   ,[ProviderID]
		   ,[ProviderMarginPerLot]
		   ,[eToroMarginPerLot]
		   ,[SettlementTime]
		   ,[OperationMode]
		   )


SELECT
b.InstrumentID,
b.InstrumentTypeID,
CASE WHEN b.InstrumentTypeID=1 THEN 'Currencies'
WHEN b.InstrumentTypeID=2 THEN 'Commodities'
WHEN b.InstrumentTypeID=4 THEN 'Indices'
WHEN b.InstrumentTypeID=5 THEN 'Stocks'
WHEN b.InstrumentTypeID = 6 THEN 'ETF'
WHEN b.InstrumentTypeID = 10 THEN 'Crypto Currencies'
Else 'Other'
END AS InstrumentType,
b.Name,
b.InstrumentID AS DWHInstrumentID,
1 AS [StatusID],
b.BuyCurrencyID,
b.SellCurrencyID,
[BuyCurrency].[Abbreviation] BuyCurrency,
[SellCurrency].[Abbreviation] SellCurrency,
b.TradeRange,
b.DollarRatio,
b.PipDifferenceThreshold,
b.IsMajor AS [IsMajorID],
CASE WHEN b.IsMajor = 1 THEN 'Yes' ELSE 'No'
END IsMajor,
GETDATE() AS UpdateDate,
GETDATE() AS InsertDate,
InstrumentMetaData.InstrumentDisplayName,
InstrumentMetaData.Industry,
InstrumentMetaData.CompanyInfo,
InstrumentMetaData.Exchange,
InstrumentMetaData.ISINCode,
InstrumentMetaData.ISINCountryCode,
case 
when Tradable in (1,0) then cast(Tradable as int)  
end as Tradable
, Symbol
,pt.BonusCreditUsePercent
,InstrumentMetaData.SymbolFull
,ic.CUSIP
,pt.Precision
,cast(AllowBuy as int) as AllowBuy
,cast(AllowSell as int) as AllowSell
,cast(VisibleInternallyOnly as int) as VisibleInternallyOnly
, case when b.InstrumentID in (select distinct InstrumentID from [DWH_staging].[etoro_Trade_InstrumentGroups] where GroupID=25) then 1 else 0  end  as IsFuture   ---Inbal 29/10/2024
,fm.Multiplier
,pt.ProviderID
,fii.InitialMargin  as ProviderMarginPerLot
,pt.InitialMarginInAssetCurrency as eToroMarginPerLot
,cast(format(DATEPART(HOUR,  SettlementTime)*100 + DATEPART(MINUTE,  SettlementTime)*1, '00:00') as time) as SettlementTime
,eti.[OperationMode]
FROM
[DWH_staging].[etoro_Trade_GetInstrument] b
INNER JOIN
[DWH_staging].[etoro_Dictionary_Currency] [BuyCurrency]
ON b.[BuyCurrencyID] = [BuyCurrency].[CurrencyID]
INNER JOIN
[DWH_staging].[etoro_Dictionary_Currency] [SellCurrency]
ON b.[SellCurrencyID] = [SellCurrency].[CurrencyID]
LEFT JOIN
[DWH_staging].[etoro_Trade_InstrumentMetaData] as InstrumentMetaData
on b.InstrumentID = InstrumentMetaData.InstrumentID
LEFT JOIN 
[DWH_staging].[etoro_Trade_ProviderToInstrument] pt 
ON b.InstrumentID = pt.InstrumentID
LEFT JOIN 
[DWH_staging].[etoro_Trade_InstrumentCusip] ic 
ON b.InstrumentID = ic.InstrumentID
LEFT JOIN  ---Inbal 29/10/2024
[DWH_staging].[etoro_Trade_FuturesMetaData] fm 
ON b.InstrumentID = fm.InstrumentID
LEFT JOIN  ---Inbal 12/11/2024
[DWH_staging].[etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping]  fii 
ON b.InstrumentID =  fii.InstrumentID
Left join [DWH_staging].[etoro_Trade_Instrument] eti 
ON eti.[InstrumentID] = b.InstrumentID

TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData
 
 ------ this is a temporary fix to handle the type mismatch in the NumVal column -----
 update [DWH_staging].[Rankings_StockInfo_InstrumentData] set NumVal = NumVal/1000
where len(NumVal) > 35
--------------------------------------------------------------------------------------

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_StockInfo_InstrumentData]
           ([InstrumentID]
           ,[Description]
           ,[KeyName]
           ,[NumVal])
select 
InstrumentID,
sm.Description,
sm.KeyName,
rs.NumVal
FROM [DWH_staging].[Rankings_StockInfo_InstrumentData] rs WITH(NOLOCK)
join [DWH_staging].[Rankings_StockInfo_Metadata] sm
on rs.MetadataID= sm.MetadataID
where rs.MetadataID in (8557, 8703, 8735, 8444, 9315)


TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData_Platform

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_StockInfo_InstrumentData_Platform]
           ([InstrumentID]
           ,[PlatformSector]
           ,[PlatformIndustry])
SELECT InstrumentID
,Sector AS PlatformSector
,Industry AS PlatformIndustry FROM 
(select InstrumentID, 
MAX(CASE WHEN MetadataID=8436 THEN StrVal END) Sector,
MAX(CASE WHEN MetadataID=8280 THEN StrVal END) Industry
FROM [DWH_staging].[Rankings_StockInfo_InstrumentData] WITH (NOLOCK) 
WHERE MetadataID IN (8436 ,8280) 
GROUP BY InstrumentID) a

TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerCurrent

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_ReceivedOnPriceServerCurrent]
           ([InstrumentID]
           ,[ReceivedOnPriceServer])
select InstrumentID,min(ReceivedOnPriceServer) as ReceivedOnPriceServer 
  from [DWH_staging].[PriceLog_History_CurrencyPrice_Active]
 where 
Occurred>=dateadd(dd,-1, cast(getdate() as date)) and Occurred <  cast(getdate() as date)
group by InstrumentID


INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_ReceivedOnPriceServerStatic]
           ([InstrumentID]
           ,[ReceivedOnPriceServer])
select 
a.[InstrumentID]
,a.[ReceivedOnPriceServer]
from 
[DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerCurrent a
left join [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerStatic b
on a.InstrumentID = b.InstrumentID
where b.InstrumentID is null


Update	[DWH_dbo].Dim_Instrument
 set [ReceivedOnPriceServer] = b.[ReceivedOnPriceServer]
from [DWH_dbo].Dim_Instrument a
join [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerStatic b
on a.InstrumentID = b.InstrumentID
where a.[ReceivedOnPriceServer] is null


Update [DWH_dbo].Dim_Instrument
Set
AssetClass = b.AssetClass,
IndustryGroup = b.IndustryGroup
from [DWH_dbo].Dim_Instrument  a
join [DWH_dbo].Ext_Dim_Instrument_Classification_Static b
on a.InstrumentID = b.InstrumentID

UPDATE [DWH_dbo].Dim_Instrument
SET
ADV_Last3Months = ra.NumVal ,
MKTcap = isnull(ra2.NumVal , ra5.NumVal ),
SharesOutStanding = ra3.NumVal 
FROM [DWH_dbo].Dim_Instrument di
LEFT JOIN [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra
ON ra.InstrumentID= di.InstrumentID AND ra.KeyName='AverageDailyVolumeLast3Months-TTM' --MetadataID=8557
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra2
ON ra2.InstrumentID= di.InstrumentID AND ra2.KeyName='MarketCapitalization-TTM' --MetadataID=8735
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra3
ON ra3.InstrumentID= di.InstrumentID AND ra3.KeyName='SharesOutstandingCurrent-Annual' --MetadataID=8444
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra4
ON ra4.InstrumentID= di.InstrumentID AND ra4.KeyName='LastClose-TTM'  --MetadataID=8703
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra5
ON ra5.InstrumentID= di.InstrumentID AND ra5.KeyName='CryptoMarketCap' --MetadataID=9315

UPDATE [DWH_dbo].Dim_Instrument
SET
PlatformSector = b.[PlatformSector] ,
PlatformIndustry = b.[PlatformIndustry] 
FROM [DWH_dbo].Dim_Instrument di
LEFT JOIN [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData_Platform b
ON b.InstrumentID= di.InstrumentID 



INSERT INTO [DWH_dbo].[Dim_Instrument]
           ([InstrumentID]
           ,[InstrumentTypeID]
           ,[InstrumentType]
           ,[Name]
           ,[DWHInstrumentID]
           ,[StatusID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID]
           ,[BuyCurrency]
           ,[SellCurrency]
           ,[TradeRange]
           ,[DollarRatio]
           ,[PipDifferenceThreshold]
           ,[IsMajorID]
           ,[IsMajor]
           ,[UpdateDate]
           ,[InsertDate]
           ,[InstrumentDisplayName]
           ,[Industry]
           ,[CompanyInfo]
           ,[Exchange]
           ,[ISINCode]
           ,[ISINCountryCode]
           ,[Tradable]
           ,[Symbol]
           ,[ReceivedOnPriceServer]
           ,[BonusCreditUsePercent]
           ,[SymbolFull]
           ,[CUSIP]
           ,[Precision]
           ,[AllowBuy]
           ,[AllowSell]
           ,[AssetClass]
           ,[IndustryGroup]
           ,[ADV_Last3Months]
           ,[MKTcap]
           ,[SharesOutStanding]
           ,[VisibleInternallyOnly]
           ,[PlatformSector]
           ,[PlatformIndustry]
		   ,[IsFuture]
		   ,[Multiplier]
		   ,[ProviderID]
		   ,[ProviderMarginPerLot]
		   ,[eToroMarginPerLot]
		   ,[SettlementTime])
     VALUES
		  (
		 0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,NULL	
		,0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,0	
		,0	
		,0	
		,'NA'	
		,NULL	
		,NULL	
		,'NA'	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		  )

EXEC [DWH_dbo].[SP_Dim_Instrument_Snapshot]  @dt 

END

GO

```

### SP `DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dim_Instrument_bkp_2025_11_24] @dt [Date] AS
BEGIN
-- EXEC  [DWH_dbo].[SP_Dim_Instrument] '2024-12-02'
/********************************************************************************************
Author:      
Date:        
Description: 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
24.07.2022	   Inbal BML	Adding MetadataID 9315 in filter in EXTRACT TABLE [Ext_Dim_Instrument_StockInfo_InstrumentData]
30.10.2024     Inbal BML	Adding new cloumns to Dim_Instrument for Future project (IsFuture,Multiplier,ProviderID,ProviderMargin,eToroMargin,SettlementTime)
  
*********************************************************************************************/
--declare @dt as date = '2024-12-10'
TRUNCATE TABLE [DWH_dbo].Dim_Instrument

INSERT INTO [DWH_dbo].[Dim_Instrument]
           ([InstrumentID]
           ,[InstrumentTypeID]
           ,[InstrumentType]
           ,[Name]
           ,[DWHInstrumentID]
           ,[StatusID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID]
           ,[BuyCurrency]
           ,[SellCurrency]
           ,[TradeRange]
           ,[DollarRatio]
           ,[PipDifferenceThreshold]
           ,[IsMajorID]
           ,[IsMajor]
           ,[UpdateDate]
           ,[InsertDate]
           ,[InstrumentDisplayName]
           ,[Industry]
           ,[CompanyInfo]
           ,[Exchange]
           ,[ISINCode]
           ,[ISINCountryCode]
           ,[Tradable]
           ,[Symbol]
           ,[BonusCreditUsePercent]
           ,[SymbolFull]
           ,[CUSIP]
           ,[Precision]
           ,[AllowBuy]
           ,[AllowSell]
           ,[VisibleInternallyOnly]
		   ,[IsFuture]
		   ,[Multiplier]
		   ,[ProviderID]
		   ,[ProviderMarginPerLot]
		   ,[eToroMarginPerLot]
		   ,[SettlementTime]		   
		   )


SELECT
b.InstrumentID,
b.InstrumentTypeID,
CASE WHEN b.InstrumentTypeID=1 THEN 'Currencies'
WHEN b.InstrumentTypeID=2 THEN 'Commodities'
WHEN b.InstrumentTypeID=4 THEN 'Indices'
WHEN b.InstrumentTypeID=5 THEN 'Stocks'
WHEN b.InstrumentTypeID = 6 THEN 'ETF'
WHEN b.InstrumentTypeID = 10 THEN 'Crypto Currencies'
Else 'Other'
END AS InstrumentType,
b.Name,
b.InstrumentID AS DWHInstrumentID,
1 AS [StatusID],
b.BuyCurrencyID,
b.SellCurrencyID,
[BuyCurrency].[Abbreviation] BuyCurrency,
[SellCurrency].[Abbreviation] SellCurrency,
b.TradeRange,
b.DollarRatio,
b.PipDifferenceThreshold,
b.IsMajor AS [IsMajorID],
CASE WHEN b.IsMajor = 1 THEN 'Yes' ELSE 'No'
END IsMajor,
GETDATE() AS UpdateDate,
GETDATE() AS InsertDate,
InstrumentMetaData.InstrumentDisplayName,
InstrumentMetaData.Industry,
InstrumentMetaData.CompanyInfo,
InstrumentMetaData.Exchange,
InstrumentMetaData.ISINCode,
InstrumentMetaData.ISINCountryCode,
case 
when Tradable in (1,0) then cast(Tradable as int)  
end as Tradable
, Symbol
,pt.BonusCreditUsePercent
,InstrumentMetaData.SymbolFull
,ic.CUSIP
,pt.Precision
,cast(AllowBuy as int) as AllowBuy
,cast(AllowSell as int) as AllowSell
,cast(VisibleInternallyOnly as int) as VisibleInternallyOnly
, case when b.InstrumentID in (select distinct InstrumentID from [DWH_staging].[etoro_Trade_InstrumentGroups] where GroupID=25) then 1 else 0  end  as IsFuture   ---Inbal 29/10/2024
,fm.Multiplier
,pt.ProviderID
,fii.InitialMargin  as ProviderMarginPerLot
,pt.InitialMarginInAssetCurrency as eToroMarginPerLot
,cast(format(DATEPART(HOUR,  SettlementTime)*100 + DATEPART(MINUTE,  SettlementTime)*1, '00:00') as time) as SettlementTime
FROM
[DWH_staging].[etoro_Trade_GetInstrument] b
INNER JOIN
[DWH_staging].[etoro_Dictionary_Currency] [BuyCurrency]
ON b.[BuyCurrencyID] = [BuyCurrency].[CurrencyID]
INNER JOIN
[DWH_staging].[etoro_Dictionary_Currency] [SellCurrency]
ON b.[SellCurrencyID] = [SellCurrency].[CurrencyID]
LEFT JOIN
[DWH_staging].[etoro_Trade_InstrumentMetaData] as InstrumentMetaData
on b.InstrumentID = InstrumentMetaData.InstrumentID
LEFT JOIN 
[DWH_staging].[etoro_Trade_ProviderToInstrument] pt 
ON b.InstrumentID = pt.InstrumentID
LEFT JOIN 
[DWH_staging].[etoro_Trade_InstrumentCusip] ic 
ON b.InstrumentID = ic.InstrumentID
LEFT JOIN  ---Inbal 29/10/2024
[DWH_staging].[etoro_Trade_FuturesMetaData] fm 
ON b.InstrumentID = fm.InstrumentID
LEFT JOIN  ---Inbal 12/11/2024
[DWH_staging].[etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping]  fii 
ON b.InstrumentID =  fii.InstrumentID

TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_StockInfo_InstrumentData]
           ([InstrumentID]
           ,[Description]
           ,[KeyName]
           ,[NumVal])
select 
InstrumentID,
sm.Description,
sm.KeyName,
rs.NumVal
FROM [DWH_staging].[Rankings_StockInfo_InstrumentData] rs WITH(NOLOCK)
join [DWH_staging].[Rankings_StockInfo_Metadata] sm
on rs.MetadataID= sm.MetadataID
where rs.MetadataID in (8557, 8703, 8735, 8444, 9315)


TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData_Platform

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_StockInfo_InstrumentData_Platform]
           ([InstrumentID]
           ,[PlatformSector]
           ,[PlatformIndustry])
SELECT InstrumentID
,Sector AS PlatformSector
,Industry AS PlatformIndustry FROM 
(select InstrumentID, 
MAX(CASE WHEN MetadataID=8436 THEN StrVal END) Sector,
MAX(CASE WHEN MetadataID=8280 THEN StrVal END) Industry
FROM [DWH_staging].[Rankings_StockInfo_InstrumentData] WITH (NOLOCK) 
WHERE MetadataID IN (8436 ,8280) 
GROUP BY InstrumentID) a

TRUNCATE TABLE [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerCurrent

INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_ReceivedOnPriceServerCurrent]
           ([InstrumentID]
           ,[ReceivedOnPriceServer])
select InstrumentID,min(ReceivedOnPriceServer) as ReceivedOnPriceServer 
  from [DWH_staging].[PriceLog_History_CurrencyPrice_Active]
 where 
Occurred>=dateadd(dd,-1, cast(getdate() as date)) and Occurred <  cast(getdate() as date)
group by InstrumentID


INSERT INTO [DWH_dbo].[Ext_Dim_Instrument_ReceivedOnPriceServerStatic]
           ([InstrumentID]
           ,[ReceivedOnPriceServer])
select 
a.[InstrumentID]
,a.[ReceivedOnPriceServer]
from 
[DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerCurrent a
left join [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerStatic b
on a.InstrumentID = b.InstrumentID
where b.InstrumentID is null


Update	[DWH_dbo].Dim_Instrument
 set [ReceivedOnPriceServer] = b.[ReceivedOnPriceServer]
from [DWH_dbo].Dim_Instrument a
join [DWH_dbo].Ext_Dim_Instrument_ReceivedOnPriceServerStatic b
on a.InstrumentID = b.InstrumentID
where a.[ReceivedOnPriceServer] is null


Update [DWH_dbo].Dim_Instrument
Set
AssetClass = b.AssetClass,
IndustryGroup = b.IndustryGroup
from [DWH_dbo].Dim_Instrument  a
join [DWH_dbo].Ext_Dim_Instrument_Classification_Static b
on a.InstrumentID = b.InstrumentID

UPDATE [DWH_dbo].Dim_Instrument
SET
ADV_Last3Months = ra.NumVal ,
MKTcap = isnull(ra2.NumVal , ra5.NumVal ),
SharesOutStanding = ra3.NumVal 
FROM [DWH_dbo].Dim_Instrument di
LEFT JOIN [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra
ON ra.InstrumentID= di.InstrumentID AND ra.KeyName='AverageDailyVolumeLast3Months-TTM' --MetadataID=8557
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra2
ON ra2.InstrumentID= di.InstrumentID AND ra2.KeyName='MarketCapitalization-TTM' --MetadataID=8735
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra3
ON ra3.InstrumentID= di.InstrumentID AND ra3.KeyName='SharesOutstandingCurrent-Annual' --MetadataID=8444
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra4
ON ra4.InstrumentID= di.InstrumentID AND ra4.KeyName='LastClose-TTM'  --MetadataID=8703
LEFT JOIN  [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData ra5
ON ra5.InstrumentID= di.InstrumentID AND ra5.KeyName='CryptoMarketCap' --MetadataID=9315

UPDATE [DWH_dbo].Dim_Instrument
SET
PlatformSector = b.[PlatformSector] ,
PlatformIndustry = b.[PlatformIndustry] 
FROM [DWH_dbo].Dim_Instrument di
LEFT JOIN [DWH_dbo].Ext_Dim_Instrument_StockInfo_InstrumentData_Platform b
ON b.InstrumentID= di.InstrumentID 



INSERT INTO [DWH_dbo].[Dim_Instrument]
           ([InstrumentID]
           ,[InstrumentTypeID]
           ,[InstrumentType]
           ,[Name]
           ,[DWHInstrumentID]
           ,[StatusID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID]
           ,[BuyCurrency]
           ,[SellCurrency]
           ,[TradeRange]
           ,[DollarRatio]
           ,[PipDifferenceThreshold]
           ,[IsMajorID]
           ,[IsMajor]
           ,[UpdateDate]
           ,[InsertDate]
           ,[InstrumentDisplayName]
           ,[Industry]
           ,[CompanyInfo]
           ,[Exchange]
           ,[ISINCode]
           ,[ISINCountryCode]
           ,[Tradable]
           ,[Symbol]
           ,[ReceivedOnPriceServer]
           ,[BonusCreditUsePercent]
           ,[SymbolFull]
           ,[CUSIP]
           ,[Precision]
           ,[AllowBuy]
           ,[AllowSell]
           ,[AssetClass]
           ,[IndustryGroup]
           ,[ADV_Last3Months]
           ,[MKTcap]
           ,[SharesOutStanding]
           ,[VisibleInternallyOnly]
           ,[PlatformSector]
           ,[PlatformIndustry]
		   ,[IsFuture]
		   ,[Multiplier]
		   ,[ProviderID]
		   ,[ProviderMarginPerLot]
		   ,[eToroMarginPerLot]
		   ,[SettlementTime])
     VALUES
		  (
		 0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,NULL	
		,0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,0	
		,0	
		,0	
		,'NA'	
		,NULL	
		,NULL	
		,'NA'	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		  )

EXEC [DWH_dbo].[SP_Dim_Instrument_Snapshot]  @dt 

END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_instrument | `—` |
| `etoro.Trade.GetInstrument` | production | Trade | GetInstrument | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Views\Trade.GetInstrument.md` |
| `DWH_dbo.SP_Dim_Instrument` | synapse_sp | DWH_dbo | SP_Dim_Instrument | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Instrument.sql` |
| `etoro.Dictionary.Currency` | production | Dictionary | Currency | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.Currency.md` |
| `etoro.Trade.InstrumentMetaData` | production | Trade | InstrumentMetaData | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.InstrumentMetaData.md` |
| `etoro.Trade.Instrument` | production | Trade | Instrument | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md` |
| `etoro.Trade.ProviderToInstrument` | production | Trade | ProviderToInstrument | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.ProviderToInstrument.md` |
| `etoro.Trade.InstrumentCusip` | production | Trade | InstrumentCusip | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Views\Trade.InstrumentCusip.md` |
| `Rankings.StockInfo` | unresolved | Rankings | StockInfo | `—` |
| `etoro.Trade.InstrumentGroups` | production | Trade | InstrumentGroups | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.InstrumentGroups.md` |
| `etoro.Trade.FuturesMetaData` | production | Trade | FuturesMetaData | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.FuturesMetaData.md` |
| `etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping` | production | Trade | FuturesInstrumentsInitialMarginByProviderMapping | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.FuturesInstrumentsInitialMarginByProviderMapping.md` |
| `DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24` | synapse_sp | DWH_dbo | SP_Dim_Instrument_bkp_2025_11_24 | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24.sql` |
| `DWH_staging.etoro_Trade_InstrumentGroups` | unresolved | DWH_staging | etoro_Trade_InstrumentGroups | `—` |
| `DWH_staging.etoro_Trade_GetInstrument` | unresolved | DWH_staging | etoro_Trade_GetInstrument | `—` |
| `DWH_staging.etoro_Dictionary_Currency` | unresolved | DWH_staging | etoro_Dictionary_Currency | `—` |
| `DWH_staging.etoro_Trade_InstrumentMetaData` | unresolved | DWH_staging | etoro_Trade_InstrumentMetaData | `—` |
| `DWH_staging.etoro_Trade_ProviderToInstrument` | unresolved | DWH_staging | etoro_Trade_ProviderToInstrument | `—` |
| `DWH_staging.etoro_Trade_InstrumentCusip` | unresolved | DWH_staging | etoro_Trade_InstrumentCusip | `—` |
| `DWH_staging.etoro_Trade_FuturesMetaData` | unresolved | DWH_staging | etoro_Trade_FuturesMetaData | `—` |
| `DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping` | unresolved | DWH_staging | etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping | `—` |
| `DWH_staging.etoro_Trade_Instrument` | unresolved | DWH_staging | etoro_Trade_Instrument | `—` |
| `DWH_staging.Rankings_StockInfo_InstrumentData` | unresolved | DWH_staging | Rankings_StockInfo_InstrumentData | `—` |
| `DWH_staging.Rankings_StockInfo_Metadata` | unresolved | DWH_staging | Rankings_StockInfo_Metadata | `—` |
| `DWH_staging.PriceLog_History_CurrencyPrice_Active` | unresolved | DWH_staging | PriceLog_History_CurrencyPrice_Active | `—` |
| `DWH_dbo.Ext_Dim_Instrument_ReceivedOnPriceServerCurrent` | unresolved | DWH_dbo | Ext_Dim_Instrument_ReceivedOnPriceServerCurrent | `—` |
| `DWH_dbo.Ext_Dim_Instrument_ReceivedOnPriceServerStatic` | unresolved | DWH_dbo | Ext_Dim_Instrument_ReceivedOnPriceServerStatic | `—` |
| `DWH_dbo.Ext_Dim_Instrument_Classification_Static` | unresolved | DWH_dbo | Ext_Dim_Instrument_Classification_Static | `—` |
| `DWH_dbo.Ext_Dim_Instrument_StockInfo_InstrumentData` | unresolved | DWH_dbo | Ext_Dim_Instrument_StockInfo_InstrumentData | `—` |
| `DWH_dbo.Ext_Dim_Instrument_StockInfo_InstrumentData_Platform` | unresolved | DWH_dbo | Ext_Dim_Instrument_StockInfo_InstrumentData_Platform | `—` |

