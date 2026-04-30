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

## ⛔ PHASE 3 DISTRIBUTION CAP

Phase 3 (distribution analysis) is capped at **at most 3 categorical columns**
per object. Pick those whose names match the regex
`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`.
Skip free-text columns entirely (Email, Description, Comment, Note, Address,
Name, Url, Subject, Body, Reason).

If fewer than 3 columns match the regex, run distribution queries on however
many DO match — running zero distribution queries is OK if the table has no
obviously-categorical columns.

---

## ⛔ OUTPUT DIRECTORY GUARANTEE

The directory listed under **Absolute output directory** in the Object Header
ALREADY EXISTS, was created by the harness, and is empty (apart from the
writer_prompt.md you are reading). DO NOT run `Bash ls` to check it. DO NOT
run `Bash mkdir`. Just call `Write` directly with the absolute paths from the
Object Header for the three required files.

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

- **Schema**: `BI_DB_dbo`
- **Object**: `BI_DB_EY_Audit_Automation_IFRSControl_Results`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Automation_IFRSControl_Results/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_EY_Audit_Automation_IFRSControl_Results\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_EY_Audit_Automation_IFRSControl_Results\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results.sql`

---

# build-wiki-bidb-batch

You are running the DWH Semantic Documentation pipeline for schema BI_DB_dbo.
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
- **OpsDB priority file**: `.specify/Configs/opsdb-objects-status.json`
- **OpsDB dependencies**: `.specify/Configs/opsdb-procedure-dependencies.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_EY_Audit_Automation_IFRSControl_Results]
(
	[Date] [date] NULL,
	[Stored_Proc] [varchar](200) NULL,
	[Metric_a] [varchar](200) NULL,
	[Metric_a_Value] [decimal](18, 4) NULL,
	[Metric_b] [varchar](200) NULL,
	[Metric_b_Value] [decimal](18, 4) NULL,
	[Diff] [decimal](18, 4) NULL,
	[Diff_Percentage] [decimal](18, 4) NULL,
	[IsPriceFound] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 2 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> 15,707-row replicated dimension table containing every tradeable instrument on the eToro platform — forex pairs, stocks, ETFs, commodities, indices, and crypto — sourced from Trade.GetInstrument, Trade.InstrumentMetaData, Trade.ProviderToInstrument, Trade.FuturesMetaData, and Rankings.StockInfo via SP_Dim_Instrument (truncate-and-reload).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument + Trade.InstrumentMetaData + Trade.ProviderToInstrument + Trade.FuturesMetaData via SP_Dim_Instrument |
| **Refresh** | Daily truncate-and-reload via SP_Dim_Instrument @dt |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline) |

---

## 1. Business Meaning

Dim_Instrument is the master instrument dimension for the DWH, containing 15,707 rows representing every tradeable instrument on the eToro platform. It covers Stocks (12,849), ETFs (1,287), Crypto Currencies (667), Commodities (503), Indices (247), and Currencies/Forex (153), plus one sentinel row (InstrumentID=0, 'NA').

The table is populated by `DWH_dbo.SP_Dim_Instrument`, which performs a full truncate-and-reload on each run. The SP joins the staging replica of the production `Trade.GetInstrument` view with `Dictionary.Currency` (for buy/sell abbreviations), `Trade.InstrumentMetaData` (display names, symbols, exchange, ISIN, industry), `Trade.ProviderToInstrument` (precision, allow flags, bonus credit, provider margin), `Trade.InstrumentCusip` (CUSIP identifiers), `Trade.FuturesMetaData` (multiplier, settlement time), `Trade.FuturesInstrumentsInitialMarginByProviderMapping` (provider margin per lot), and `Trade.Instrument` (OperationMode).

After the initial INSERT, the SP performs post-insert UPDATEs to enrich rows with: ReceivedOnPriceServer (from PriceLog history), AssetClass/IndustryGroup (from a static classification table), ADV_Last3Months/MKTcap/SharesOutStanding (from Rankings.StockInfo.InstrumentData), and PlatformSector/PlatformIndustry (from Rankings platform metadata). Finally, a sentinel row (InstrumentID=0) is inserted with 'NA' placeholder values, and `SP_Dim_Instrument_Snapshot` is called for date-partitioned snapshots.

---

## 2. Business Logic

### 2.1 InstrumentType CASE Mapping

**What**: Translates numeric InstrumentTypeID into human-readable asset class labels.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`

**Rules**:
- 1 = Currencies (153 instruments)
- 2 = Commodities (503)
- 4 = Indices (247)
- 5 = Stocks (12,849)
- 6 = ETF (1,287)
- 10 = Crypto Currencies (667)
- All others = Other

### 2.2 IsMajor Flag Mapping

**What**: Converts the production bit flag IsMajor (0/1) into a Yes/No string.

**Columns Involved**: `IsMajorID`, `IsMajor`

**Rules**:
- IsMajorID stores the raw bit value from Trade.GetInstrument.IsMajor
- IsMajor = 'Yes' when IsMajorID = 1, 'No' otherwise
- Yes: 6,963 instruments; No: 8,743; NA: 1 (sentinel)

### 2.3 IsFuture Derivation from InstrumentGroups

**What**: Determines whether an instrument is a futures contract based on membership in GroupID=25 in Trade.InstrumentGroups.

**Columns Involved**: `IsFuture`

**Rules**:
- 1 if InstrumentID exists in Trade.InstrumentGroups WHERE GroupID=25
- 0 otherwise
- 243 instruments flagged as futures; 15,463 non-futures

### 2.4 Post-Insert Market Data Enrichment

**What**: After the main INSERT, the SP updates financial metrics from Rankings.StockInfo data.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- ADV_Last3Months from MetadataID=8557 (KeyName='AverageDailyVolumeLast3Months-TTM')
- MKTcap = ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — falls back to crypto market cap
- SharesOutStanding from MetadataID=8444 (KeyName='SharesOutstandingCurrent-Annual')
- PlatformSector from MetadataID=8436 (StrVal, pivoted)
- PlatformIndustry from MetadataID=8280 (StrVal, pivoted)

### 2.5 Sentinel Row

**What**: A placeholder row with InstrumentID=0 is inserted at the end of the SP for FK safety.

**Columns Involved**: All

**Rules**:
- InstrumentID=0, InstrumentTypeID=0, InstrumentType='NA', Name='NA'
- Most nullable columns set to NULL
- StatusID=NULL (vs 1 for data rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution means the full table is copied to every compute node — ideal for a 15K-row dimension used in JOINs with large fact tables. CLUSTERED INDEX on InstrumentID supports point lookups and range scans. No distribution key to worry about for colocation.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up an instrument by ID | `WHERE InstrumentID = @id` — clustered index seek |
| Filter by asset class | `WHERE InstrumentType = 'Stocks'` or `WHERE InstrumentTypeID = 5` |
| Find tradeable instruments | `WHERE Tradable = 1` |
| Futures only | `WHERE IsFuture = 1` |
| Search by symbol | `WHERE Symbol = 'AAPL'` or `WHERE SymbolFull = 'AAPL'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables (positions, orders) | `ON f.InstrumentID = di.InstrumentID` | Resolve instrument name, type, exchange |
| Dim_Customer | Via fact table bridge | Instrument exposure per customer |
| Fact_CurrencyPriceWithSplit | `ON f.InstrumentID = di.InstrumentID` | Price data with instrument metadata |

### 3.4 Gotchas

- **InstrumentID=0 is a sentinel** — exclude it with `WHERE InstrumentID > 0` in aggregations
- **IsMajor is a varchar 'Yes'/'No'**, not a bit — use IsMajorID (int) for numeric filters
- **InstrumentType 'NA'** only appears on the sentinel row
- **Multiplier is NULL** for 15,464 of 15,707 rows — only populated for futures instruments
- **AssetClass is NULL** for 13,557 rows — only populated from the static classification table
- **OperationMode is NULL** for sentinel row only; 0=Standard (13,140), 1=Alternate (2,566, primarily European stock CFDs)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_Dim_Instrument — transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) |
| 2 | InstrumentTypeID | int | NO | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) |
| 3 | InstrumentType | varchar(50) | NO | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. (Tier 1 — Trade.GetInstrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all data rows; NULL for sentinel row (InstrumentID=0). (Tier 2 — SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 8 | SellCurrencyID | int | NO | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 9 | BuyCurrency | varchar(50) | NO | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 — Dictionary.Currency) |
| 10 | SellCurrency | varchar(50) | NO | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) |
| 11 | TradeRange | int | NO | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Max pip difference for price validation. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 14 | IsMajorID | int | NO | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). (Tier 1 — Trade.GetInstrument) |
| 15 | IsMajor | varchar(3) | NO | ETL-computed label from IsMajorID: 'Yes' when IsMajor=1, 'No' otherwise. (Tier 2 — SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 — Trade.InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. (Tier 1 — Trade.InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 — Trade.InstrumentMetaData) |
| 24 | Tradable | int | YES | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. (Tier 1 — Trade.InstrumentMetaData) |
| 25 | Symbol | varchar(100) | YES | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 — Trade.InstrumentMetaData) |
| 26 | ReceivedOnPriceServer | datetime | YES | Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 — SP_Dim_Instrument) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — Trade.InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. (Tier 1 — Trade.InstrumentCusip) |
| 30 | Precision | int | YES | Decimal places for price display and rounding. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 31 | AllowBuy | int | YES | 1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 32 | AllowSell | int | YES | 1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Asset class classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. NULL for 13,557 of 15,707 rows. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 34 | IndustryGroup | nvarchar(400) | YES | Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average daily trading volume over the last 3 months (TTM). From Rankings.StockInfo.InstrumentData MetadataID=8557. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization. ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — uses stock market cap when available, falls back to crypto market cap. From Rankings.StockInfo MetadataID=8735/9315. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Current shares outstanding (annual). From Rankings.StockInfo.InstrumentData MetadataID=8444. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | 1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 39 | PlatformSector | varchar(max) | YES | Platform-level sector classification from Rankings.StockInfo MetadataID=8436 (StrVal pivot). E.g., "Electronic Technology", "Technology Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | Platform-level industry classification from Rankings.StockInfo MetadataID=8280 (StrVal pivot). E.g., "Telecommunications Equipment", "Internet Software Or Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 41 | IsFuture | int | YES | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). (Tier 1 — Trade.FuturesMetaData) |
| 43 | ProviderID | int | YES | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. (Tier 1 — Trade.FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Time of day for settlement. DWH note: reformatted from Trade.FuturesMetaData.SettlementTime via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00'). (Tier 1 — Trade.FuturesMetaData) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). From Trade.Instrument. (Tier 1 — Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| InstrumentID | Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | SP_Dim_Instrument | InstrumentTypeID | CASE mapping |
| Name | Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | Trade.GetInstrument | InstrumentID | Alias |
| StatusID | SP_Dim_Instrument | — | Hardcoded 1 |
| BuyCurrencyID | Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | Dictionary.Currency | Abbreviation | Buy-side join |
| SellCurrency | Dictionary.Currency | Abbreviation | Sell-side join |
| TradeRange | Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | Trade.GetInstrument | IsMajor | Rename |
| IsMajor | SP_Dim_Instrument | IsMajor | CASE Yes/No |
| UpdateDate | SP_Dim_Instrument | — | GETDATE() |
| InsertDate | SP_Dim_Instrument | — | GETDATE() |
| InstrumentDisplayName | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough |
| Industry | Trade.InstrumentMetaData | Industry | Passthrough |
| CompanyInfo | Trade.InstrumentMetaData | CompanyInfo | Passthrough |
| Exchange | Trade.InstrumentMetaData | Exchange | Passthrough |
| ISINCode | Trade.InstrumentMetaData | ISINCode | Passthrough |
| ISINCountryCode | Trade.InstrumentMetaData | ISINCountryCode | Passthrough |
| Tradable | Trade.InstrumentMetaData | Tradable | CAST to int |
| Symbol | Trade.InstrumentMetaData | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog_History_CurrencyPrice_Active | ReceivedOnPriceServer | MIN aggregation + static persistence |
| BonusCreditUsePercent | Trade.ProviderToInstrument | BonusCreditUsePercent | Passthrough |
| SymbolFull | Trade.InstrumentMetaData | SymbolFull | Passthrough |
| CUSIP | Trade.InstrumentCusip | CUSIP | Passthrough |
| Precision | Trade.ProviderToInstrument | Precision | Passthrough |
| AllowBuy | Trade.ProviderToInstrument | AllowBuy | CAST to int |
| AllowSell | Trade.ProviderToInstrument | AllowSell | CAST to int |
| AssetClass | Ext_Dim_Instrument_Classification_Static | AssetClass | Post-insert UPDATE |
| IndustryGroup | Ext_Dim_Instrument_Classification_Static | IndustryGroup | Post-insert UPDATE |
| ADV_Last3Months | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE, KeyName filter |
| MKTcap | Rankings.StockInfo.InstrumentData | NumVal | ISNULL(MarketCap, CryptoMarketCap) |
| SharesOutStanding | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE, KeyName filter |
| VisibleInternallyOnly | Trade.ProviderToInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo.InstrumentData | StrVal | Pivoted MetadataID=8436 |
| PlatformIndustry | Rankings.StockInfo.InstrumentData | StrVal | Pivoted MetadataID=8280 |
| IsFuture | Trade.InstrumentGroups | GroupID=25 | CASE membership check |
| Multiplier | Trade.FuturesMetaData | Multiplier | Passthrough |
| ProviderID | Trade.ProviderToInstrument | ProviderID | Passthrough |
| ProviderMarginPerLot | Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | Rename |
| eToroMarginPerLot | Trade.ProviderToInstrument | InitialMarginInAssetCurrency | Rename |
| SettlementTime | Trade.FuturesMetaData | SettlementTime | Time reformatting |
| OperationMode | Trade.Instrument | OperationMode | Passthrough |

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, joins Instrument + Currency + InstrumentMetaData)
etoro.Dictionary.Currency (table, buy + sell abbreviations)
etoro.Trade.InstrumentMetaData (table, display/symbol/exchange/ISIN)
etoro.Trade.ProviderToInstrument (table, precision/allow/margin)
etoro.Trade.InstrumentCusip (view, CUSIP/ISIN)
etoro.Trade.FuturesMetaData (table, multiplier/settlement)
etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping (table, provider margin)
etoro.Trade.Instrument (table, OperationMode)
etoro.Trade.InstrumentGroups (table, GroupID=25 for futures flag)
Rankings.StockInfo.InstrumentData (table, market data metrics)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_GetInstrument + etoro_Dictionary_Currency + ...
  |-- SP_Dim_Instrument @dt (truncate-and-reload + post-insert UPDATEs) ---|
  v
DWH_dbo.Dim_Instrument (15,707 rows)
  |-- SP_Dim_Instrument_Snapshot @dt (date-partitioned snapshot) ---|
  |-- Generic Pipeline (Override, delta) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Asset class (1=Forex, 5=Stocks, 10=Crypto, etc.) |
| BuyCurrencyID | Dictionary.Currency | Buy-side asset / base currency |
| SellCurrencyID | Dictionary.Currency | Sell-side denomination currency |
| ProviderID | Trade.Provider | Execution provider |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact tables (positions, orders, trades) | InstrumentID | Instrument dimension lookup |
| Fact_CurrencyPriceWithSplit | InstrumentID | Price data with instrument metadata |
| BI_DB aggregation tables | InstrumentID | Instrument attributes for reporting |

---

## 7. Sample Queries

### 7.1 Instrument breakdown by asset class
```sql
SELECT InstrumentType, COUNT(*) AS InstrumentCount
FROM DWH_dbo.Dim_Instrument
WHERE InstrumentID > 0
GROUP BY InstrumentType
ORDER BY InstrumentCount DESC
```

### 7.2 Find a stock by symbol with market data
```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, SymbolFull,
       Exchange, ISINCode, AssetClass, IndustryGroup,
       ADV_Last3Months, MKTcap, SharesOutStanding
FROM DWH_dbo.Dim_Instrument
WHERE Symbol = 'AAPL'
```

### 7.3 List futures instruments with margin data
```sql
SELECT InstrumentID, Name, InstrumentDisplayName, Multiplier,
       ProviderMarginPerLot, eToroMarginPerLot, SettlementTime
FROM DWH_dbo.Dim_Instrument
WHERE IsFuture = 1
ORDER BY InstrumentID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 30 T1, 13 T2, 2 T3, 0 T4, 0 T5 | Elements: 47/47, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Instrument | Type: Table | Production Source: Trade.GetInstrument + Trade.InstrumentMetaData via SP_Dim_Instrument*


### Upstream `BI_DB_dbo.BI_DB_IFRS15_Daily_Balance` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_IFRS15_Daily_Balance`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_IFRS15_Daily_Balance.md`

# BI_DB_dbo.BI_DB_IFRS15_Daily_Balance

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (Date ASC) |
| **Writer SP** | BI_DB_dbo.SP_IFRS_15_Balance |
| **ETL Pattern** | DELETE WHERE Date + ExcelOrder scope + INSERT (within WHILE loop for 2 days) |
| **OpsDB Priority** | 20 |
| **Frequency** | Daily |
| **Row Estimate** | ~600–800 rows/day (20+ metric rows × N instruments × dimension combinations) |
| **UC Target** | Not Migrated |

## Overview

Daily aggregated IFRS 15 revenue recognition metrics for eToro's crypto (real/settled) and CFD (synthetic) position book. Each row represents one combination of **metric × position type × instrument × customer segment dimensions** for a given date. The table is structured to mirror the Finance team's IFRS 15 reconciliation spreadsheet, with `ExcelOrder` providing the exact row ordering used in Tableau/Excel reporting.

**IFRS 15 context**: International Financial Reporting Standard 15 governs revenue recognition for contracts with customers. For eToro, the key question is: when does spread/commission revenue get recognized — at position open, position close, or proportionally over the position's life? The opening/closing balance metrics and flow metrics in this table form a complete reconciliation of the crypto position book from T-1 to T.

**Instrument scope**: Crypto only — InstrumentTypeID=10 (cryptocurrency) plus InstrumentID=624 (a crypto index added in 2025). FX, stocks, and commodities are excluded.

**Sister table**: `BI_DB_IFRS_15_Daily_Positions` (same writer SP, position-level granularity) is written first and then read back to generate the aggregated rows in this table.

## ETL Summary

```
WHILE @loopstartdate <= @date   (runs for @date-1 and @date):
  1. Build temp tables:
     #C2P_Positions   — Copy-to-Portfolio positions (CompensationReasonID=134)
     #realTanganystatus — Tangany/DLT status snapshot per CID at @startDateInt
     #outliers        — Outlier CIDs from BI_DB_Outliers_New
     #openingBalancPnl — BI_DB_PositionPnL at @date-1 + prices + regulation
     #ClosingBalancePnl — BI_DB_PositionPnL at @date + prices + regulation
     #intoDLT / #outFromDLT — DLT status changers (EXCEPT set logic)
     #Prices / #Prices2 — Latest prices per instrument
     #ticketfeepercentage — Ticket-fee-% commissions (Function_Revenue_TicketFeeByPercent)
     #relposFCA        — Open/close actions per position (Fact_CustomerAction)
     #relpos           — Positions with open or close on @date (Dim_Position JOIN)
     #changelogPrep    — CFD/Real conversion events (Dim_PositionChangeLog, ChangeTypeID 12/13)
     #dailyFlow        — Final CFD↔Real conversion flow
     #finalZeroAgg     — Zero-balance metrics (Client_Balance_Breakdown_Instrument_Level)
     #openingBalance   — Aggregated opening balance per instrument × segment
     #closingBalance   — Aggregated closing balance per instrument × segment
  2. DELETE FROM BI_DB_IFRS_15_Daily_Positions WHERE DateID = @startDateInt
     INSERT INTO BI_DB_IFRS_15_Daily_Positions (position-level detail)
  3. DELETE FROM BI_DB_IFRS15_Daily_Balance WHERE Date = @startDate AND ExcelOrder NOT IN (32,33)
     INSERT 29 UNION ALL branches (ExcelOrder 1–29)

After WHILE loop:
  4. DELETE WHERE Date = @DLTEndDate AND ExcelOrder IN (32,33)
     INSERT ExcelOrder 32 (IntoDLTStatusOpeningBalance) + 33 (OutOfDLTStatusClosingBalance)
     (DLT balance rows for customers entering/leaving DLT status)
```

**Two-day loop rationale**: Some crypto redeems only materialize in `Fact_BillingRedeem` the day after the actual event. Running the loop for both @date-1 and @date ensures the previous day is retroactively corrected.

## Column Reference

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | ExcelOrder | int | YES | Display ordering key mapping rows to specific positions in the IFRS 15 reconciliation spreadsheet. Values 1–29 (loop body) + 32, 33 (DLT section, outside loop). ExcelOrder 15 is intentionally absent (metric removed; gap preserved for Tableau compatibility). | Tier 2 |
| 2 | Metric | varchar(100) | YES | Named IFRS 15 metric category. See Metric Taxonomy table below for all values and their IFRS meaning. Determines which financial flow or balance component this row represents. | Tier 2 |
| 3 | PositionType | varchar(100) | YES | Metric subcategory describing the position's settlement status at open and/or close. For balance rows: 'NA'. For flow rows: e.g., 'OpenReal', 'OpenRealLatestCFD', 'ClosedReal', 'ConvertedCFDToReal'. | Tier 2 |
| 4 | Date | date | YES | Report date — the date this metric row represents. Within the WHILE loop, this is @startDate (which ranges from @date-1 to @date). For DLT rows (ExcelOrder 32,33): @DLTEndDate = @date. | Tier 2 |
| 5 | YearMonth | varchar(6) | YES | YYYYMM format period identifier derived from Date. Used for monthly aggregation in Tableau/Excel reporting. | Tier 2 |
| 6 | Name | varchar(100) | YES | Crypto instrument name — specifically the BuyCurrency name from Dim_Instrument (e.g., 'BTC', 'ETH', 'XRP', 'SOL'). Identifies which crypto asset this row refers to. | Tier 2 |
| 7 | PositionTiming | varchar(100) | YES | Position lifecycle timing relative to the report period. For flow metrics: 'Opened_In_Period_Not_Closed' (opened today, still open), 'Opened_And_Closed_In_Period' (day trade), 'Opened_Before_Period_Closed_InPeriod' (previous open, closed today). 'NA' for balance and conversion metrics. | Tier 2 |
| 8 | TotalUnits | float | YES | Total position size in crypto units (number of tokens). For long positions: positive; for short positions: negative (multiplied by -1 in CASE). For commission and fee metrics: 0. Sourced from AmountInUnitsDecimal (closing balance) or InitialUnits (opening/flow). | Tier 2 |
| 9 | USDValue | float | YES | Total USD value for this metric row. Semantic depends on Metric: (a) Balance rows: SUM(TotalNOP) = net open position at market price; (b) Flow rows: SUM(ComputedVolumeOpen) or SUM(ComputedVolumeClose) = notional traded volume; (c) Commission rows: SUM(-FullCommission) = negative of commission charged; (d) Zero metrics: SUM(TotalZero) = uncommitted balance; (e) DLT rows: SUM(Amount + PositionPnL) = custodied crypto value. | Tier 2 |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE() at INSERT time). | ETL_METADATA |
| 11 | IsValidCustomer | int | YES | Customer validity flag at report date. From Fact_SnapshotCustomer: 1 = valid customer; 0 = invalid. Used to separate valid vs. invalid customer book in IFRS reconciliation. | Tier 2 |
| 12 | IsCreditReportValidCB | int | YES | Credit bureau validity flag at report date. From Fact_SnapshotCustomer: 1 = customer has valid credit bureau check; 0 = invalid. Separates credit-valid from credit-invalid sub-books in IFRS reports. | Tier 2 |
| 13 | IsOutlier | int | YES | Statistical outlier flag. From BI_DB_Outliers_New: 1 = customer is a position-size outlier (large unusual position that could distort aggregate metrics); 0 = normal customer. NULL for DLT balance rows (ExcelOrder 32, 33). | Tier 2 |
| 14 | OutlierTransition | varchar(100) | YES | Outlier transition description from BI_DB_Outliers_New.Transition. 'NoTransition' = customer is not an outlier or has no transition. Specific transition names describe what kind of outlier event occurred. NULL for DLT balance rows. | Tier 2 |
| 15 | TanganyStatus | varchar(20) | YES | Crypto custody status from BI_DB_Client_Balance_CID_Level_New. Tangany is eToro's crypto custody provider. MAX(TanganyStatus) per CID at the report date. Distinguishes how the customer's real crypto is held (e.g., 'Internal' = eToro internal custody, 'Customer' = Tangany customer custody). | Tier 2 |
| 16 | IsDLTUser | int | YES | Distributed Ledger Technology user flag from BI_DB_Client_Balance_CID_Level_New. MAX(IsDLTUser) per CID at report date. 1 = customer holds real crypto in DLT/blockchain custody (Fact_SnapshotCustomer.DltStatusID=4); 0 = standard crypto position. DLT users appear or disappear from balance aggregations when their DLT status changes — the ExcelOrder 32/33 rows compensate for these gaps. | Tier 2 |
| 17 | TicketFeeVolume | decimal(16,8) | YES | Volume-weighted ticket fee percentage commission. Computed by Function_Revenue_TicketFeeByPercent(@startDateInt, @endDateInt, 0). SUM of TicketFeeByPercent per position grouped into each IFRS metric row. 0.0 for balance rows, zero metrics, and commission rows. Non-zero for BuyReal, SellReal, BuyCFD, SellCFD, Redeem, and Staking flow rows. | Tier 2 |
| 18 | IsC2P | int | YES | Copy-to-Portfolio flag: 1 = position was opened as a copy/mirror trade (identified via CompensationReasonID=134 in External_Bronze_etoro_Trade_AdminPositionLog); 0 = direct trade. "C2P" = Copy to Portfolio. | Tier 2 |
| 19 | IsTransferOut | int | YES | Transfer-out flag: 1 = position was closed due to an account transfer out (ClosePositionReasonID=22 in Dim_Position); 0 = normal position close. NULL for DLT balance rows (ExcelOrder 32,33) and for Zero metrics where NULL is passed explicitly. | Tier 2 |
| 20 | Regulation | varchar(50) | YES | Customer regulation name at the time of the action. Joined from Dim_Regulation via Fact_SnapshotCustomer.RegulationID at the SCD-valid date range. Represents the regulatory jurisdiction of the customer's positions (e.g., 'ASIC', 'CySEC', 'FCA'). | Tier 2 |

## Metric Taxonomy

| ExcelOrder | Metric | PositionType Values | Financial Meaning |
|-----------|--------|---------------------|------------------|
| 1 | OpeningBalanceReal | NA | Real (settled) crypto book balance at T-1 close |
| 1 | OpeningBalanceCFD | NA | CFD (synthetic) crypto book balance at T-1 close |
| 2 | BuyReal | OpenReal, OpenReal (redeem) | New real crypto positions opened on T |
| 3 | BuyReal | OpenRealLatestCFD | Real crypto opened on T that converted to CFD by day end |
| 4 | SellReal | ClosedReal | Real crypto positions closed on T (started real) |
| 5 | SellReal | ClosedRealOpenedCFD | Real crypto positions closed on T (started as CFD) |
| 6 | BuyCFD | OpenCFD | New CFD crypto positions opened on T |
| 7 | BuyCFD | OpenCFDLatestReal | CFD crypto opened on T that converted to real by day end |
| 8 | BuyCFD | OpenCFD_SellShort | Short-sell CFD positions opened on T |
| 9 | SellCFD | OpenCFDLatestCFD | CFD crypto positions closed on T (started + closed CFD) |
| 10 | SellCFD | OpenRealLatestCFD | CFD positions closed on T (started real, closed CFD) |
| 11 | SellCFD | OpenCFD_BuyShort | Short CFD positions closed on T |
| 12 | RedeemSell | CloseReal | Real crypto positions redeemed (crypto withdrawal) on T |
| 13 | StakingBuy | OpenReal | Staking/airdrop positions opened on T (non-redeem) |
| 14 | StakingSell | CloseReal | Staking positions closed on T |
| 15 | *(absent)* | — | Intentional gap in numbering (metric removed) |
| 16 | StakingBuy | OpenReal | Staking positions opened via redeem mechanism on T |
| 17 | RedeemStakingSell | CloseReal | Staking-redeem positions closed on T |
| 18 | SellReal | ConvertedRealToCFD | Volume of Real→CFD conversion events on T |
| 19 | BuyReal | ConvertedCFDToReal | Volume of CFD→Real conversion events on T |
| 20 | SellCFD | ConvertedCFDToReal | CFD sold leg of CFD→Real conversions on T |
| 21 | BuyCFD | ConvertedRealToCFD | CFD bought leg of Real→CFD conversions on T |
| 22 | ValidZeroReal | NA | Uncommitted real balance for valid customers |
| 23 | ValidZeroCFD | NA | Uncommitted CFD balance for valid customers |
| 24 | InValidZeroReal | NA | Uncommitted real balance for invalid customers |
| 25 | InValidZeroCFD | NA | Uncommitted CFD balance for invalid customers |
| 26 | FullCommissionReal | NA | Total full commission on real positions (negated) |
| 27 | FullCommissionCFD | NA | Total full commission on CFD positions (negated) |
| 28 | ClosingBalanceReal | NA | Real crypto book balance at T close |
| 29 | ClosingBalanceCFD | NA | CFD crypto book balance at T close |
| 32 | IntoDLTStatusOpeningBalance | NA | Opening balance of customers who entered DLT status on T |
| 33 | OutOfDLTStatusClosingBalance | NA | Closing balance of customers who exited DLT status on T |

## Dimension Cuts

Each metric row in this table is split across combinations of these dimension values (GROUP BY keys):

| Dimension | Column | Source |
|-----------|--------|--------|
| Instrument | Name | Dim_Instrument.BuyCurrency |
| Position lifecycle | PositionTiming | SP CASE logic |
| Customer validity | IsValidCustomer | Fact_SnapshotCustomer |
| Credit validity | IsCreditReportValidCB | Fact_SnapshotCustomer |
| Outlier status | IsOutlier / OutlierTransition | BI_DB_Outliers_New |
| Custody status | TanganyStatus | BI_DB_Client_Balance_CID_Level_New |
| DLT user | IsDLTUser | BI_DB_Client_Balance_CID_Level_New |
| Copy-trade | IsC2P | External_Bronze_etoro_Trade_AdminPositionLog |
| Transfer | IsTransferOut | Dim_Position.ClosePositionReasonID |
| Regulation | Regulation | Dim_Regulation via Fact_SnapshotCustomer |

## Upstream Dependencies

| Upstream Object | Type | Role |
|----------------|------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Table | Primary — daily crypto NOP snapshot |
| BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions | Table | Sister table; position-level rows written first, then read back for aggregation |
| BI_DB_dbo.BI_DB_Outliers_New | Table | Outlier CID flags |
| BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level | Table | Zero/uncommitted balance metrics |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table | TanganyStatus + IsDLTUser per CID |
| BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Function | Ticket-fee-percentage commissions |
| BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | External Table | C2P position identification |
| DWH_dbo.Dim_Position | Table | Position metadata, forex rates, partial-close |
| DWH_dbo.Dim_PositionChangeLog | Table | CFD↔Real conversions |
| DWH_dbo.Fact_CustomerAction | Table | IsSettled, IsRedeem per action |
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Tables | Customer validity + regulation at SCD date |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | Instrument prices for NOP/volume |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Table | 60-min candle prices for changelog flows |
| DWH_dbo.Fact_BillingRedeem | Table | Late-redeem status corrections |
| DWH_dbo.Dim_Instrument | Table | Crypto scope filter + instrument name |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |

## Data Quality Notes

- **Two-day loop (retroactive fix)**: The SP always re-runs the previous day (@date-1) in the same execution to catch late-materializing redeems from Fact_BillingRedeem. The last date run may be slightly off until the next day's execution corrects it.
- **DLT rows are written outside the loop**: ExcelOrder 32 and 33 are excluded from the main DELETE scope (`ExcelOrder NOT IN (32,33)`) and handled separately. This means a re-run for a historical date will NOT update the DLT rows for that date unless the DLT DELETE block is also triggered.
- **ExcelOrder 15 intentionally absent**: The numbering skips from 14 to 16. This is a legacy gap from a metric that was removed. Tableau reports must not assume sequential ExcelOrder values.
- **float precision**: TotalUnits and USDValue use FLOAT, which can introduce floating-point rounding errors in large aggregations. For exact financial reconciliation, sum discrepancies of ≤ 0.001 may be artifacts.
- **NOLOCK hints throughout**: The SP uses `WITH (NOLOCK)` extensively. Under high concurrency, dirty reads are possible in some temp tables. The 2-day loop partially mitigates this by correcting the prior day.

## UC Target

Not Migrated. No `.alter.sql` generated (wiki-only batch).


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_EY_Audit_IFRS_Control`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_IFRS_Control.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_EY_Audit_IFRS_Control] @date [date] AS 
     
/********************************************************************************************      
Author:      Guy Manova       
Date:        2024-01-25      

Description: counts the total crypto buy-sell as a control for the IFRS cycle
      
**************************      
** Change History      
**************************      
Date			Author       Description       
   
2024-02-01		Guy M		 small tweak - added Isnull to IsSettledOnOpen in a couple of places
2024-03-15		Guy M		 neglected the status RedeemStakingSell in the comparison, was cauasing small discrepancy

*/

BEGIN 


-- DECLARE @date DATE = '20240308'
DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)
  
IF OBJECT_ID('tempdb..#OpenedBeforeclosedYesterday') IS NOT NULL DROP TABLE #OpenedBeforeclosedYesterday
CREATE TABLE #OpenedBeforeclosedYesterday  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  
 eaacp.PositionID  
  , eaacp.IsBuy  
  , eaacp.IsPartialCloseChild  
  , eaacp.IsSettled  
  , eaacp.IsAirDrop  
  , eaacp.IsSettledOnOpen  
  , eaacp.IsRedeem  
  , eaacp.OpenDateID  
  , eaacp.CloseDateID  
  , eaacp.Units  
  , eaacp.InitialUnits  
  , eaacp.InstrumentID  
  , 'Opened_Before_Period_Closed_InPeriod' AS PositionTiming  
  , 0 AS VolumeOnOpen  
  , eaacp.VolumeOnClose AS VolumeOnClose  
FROM BI_DB_dbo.BI_DB_EY_Audit_Closed_Positions eaacp  
 JOIN DWH_dbo.Dim_Instrument eaadi  
  ON eaacp.InstrumentID = eaadi.InstrumentID AND eaadi.InstrumentTypeID = 10  
WHERE eaacp.CloseDateID = @dateID AND eaacp.OpenDateID < @dateID  

-- SELECT * FROM #OpenedBeforeclosedYesterday oby
  
--DECLARE @date DATE = '20240203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

IF OBJECT_ID('tempdb..#OpenedYesterdayclosedYesterday') IS NOT NULL DROP TABLE #OpenedYesterdayclosedYesterday
CREATE TABLE #OpenedYesterdayclosedYesterday  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  
 eaacp.PositionID  
  , eaacp.IsBuy  
  , eaacp.IsPartialCloseChild  
  , eaacp.IsSettled  
  , eaacp.IsAirDrop  
  , eaacp.IsSettledOnOpen  
  , eaacp.IsRedeem  
  , eaacp.OpenDateID  
  , eaacp.CloseDateID  
  , eaacp.Units  
  , eaacp.InitialUnits  
  , eaacp.InstrumentID  
  , 'Opened_And_Closed_In_Period' AS PositionTiming  
  , eaacp.Volume AS VolumeOnOpen  
  , eaacp.VolumeOnClose AS VolumeOnClose  
FROM BI_DB_dbo.BI_DB_EY_Audit_Closed_Positions eaacp  
 JOIN DWH_dbo.Dim_Instrument eaadi  
  ON eaacp.InstrumentID = eaadi.InstrumentID AND eaadi.InstrumentTypeID = 10  
WHERE eaacp.CloseDateID = @dateID AND eaacp.OpenDateID = @dateID  
  
--DECLARE @date DATE = '20240203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

IF OBJECT_ID('tempdb..#openedYesterdayStillOpen') IS NOT NULL DROP TABLE #openedYesterdayStillOpen
CREATE TABLE #openedYesterdayStillOpen  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  
 eaaop.PositionID  
  , eaaop.IsBuy  
  , eaaop.IsPartialCloseChild  
  , eaaop.IsSettled  
  , eaaop.IsAirDrop  
  , eaaop.IsSettledOnOpen  
  , eaaop.Is_Redeem  
  , eaaop.OpenDateID  
  , eaaop.CloseDateID  
  , NULL AS Units  
  , eaaop.InitialUnits  
  , eaaop.InstrumentID  
  , 'Opened_In_Period_Not_Closed' AS PositionTiming  
  , eaaop.Volume AS VolumeOnOpen  
  , 0 AS VolumeOnClose  
FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions eaaop  
 JOIN DWH_dbo.Dim_Instrument eaadi  
  ON eaaop.InstrumentID = eaadi.InstrumentID AND eaadi.InstrumentTypeID = 10  
WHERE eaaop.OpenDateID = @dateID AND (eaaop.CloseDateID = 0 OR eaaop.CloseDateID > @dateID)  
AND eaaop.DateID = @dateID  



--DECLARE @date DATE = '20240203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

IF OBJECT_ID('tempdb..#changelog') IS NOT NULL DROP TABLE #changelog -- select * from #changelog
CREATE TABLE #changelog  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  
 CASE WHEN eaacl.PreviousIsSettled=0 THEN 'CFD_To_Real' ELSE 'Real_To_CFD' END AS ChangeType  
  , eaacl.PositionID  
  , eaacl.AmountInUnits AS Units  
  , NULL AS InitialUnits  
  , eaacl.PreviousIsSettled  
  , eaacl.IsSettled  
  , eaacl.AmountChanged AS VolumeOnOpen  
  , eaacl.AmountChanged AS VolumeOnClose  
FROM BI_DB_dbo.BI_DB_EY_Audit_ChangeLog eaacl  
WHERE eaacl.OccurredDateID = @dateID  
AND eaacl.ChangeTypeID = 13  

--DECLARE @date DATE = '20230203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)
  
IF OBJECT_ID('tempdb..#auditpos') IS NOT NULL DROP TABLE #auditpos
CREATE TABLE #auditpos  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT *   
INTO #auditpos  
FROM #OpenedBeforeclosedYesterday oby  
UNION ALL SELECT * FROM #OpenedYesterdayclosedYesterday oyy  
UNION ALL SELECT * FROM #openedYesterdayStillOpen yso  
UNION ALL  
SELECT  
 c.PositionID  
  , NULL AS IsBuy  
  , NULL AS ISPartialCloseChild  
  , c.IsSettled  
  , NULL AS IsAirdrop  
  , c.PreviousIsSettled AS IsSettledOpen  
  , NULL AS IsRedeem  
  , NULL AS OpenDateID  
  , NULL AS CloseDateID  
  , c.Units  
  , c.InitialUnits  
  , NULL AS InstrumentID  
  , c.ChangeType AS PositionTiming  
  , c.VolumeOnOpen  
  , c.VolumeOnClose  
FROM #changelog c  
  

IF OBJECT_ID('tempdb..#IFRSCompare') IS NOT NULL DROP TABLE #IFRSCompare

CREATE TABLE #IFRSCompare

(
 Date DATE NULL,  
 Metric VARCHAR (100) null,  
 TotalUnits FLOAT NULL ,
 PositionID BIGINT NULL,
 PositionType VARCHAR (30) null
) 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

--DECLARE @date DATE = '20240203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)
    
INSERT INTO #IFRSCompare  
SELECT @date, a.Metric, SUM(a.TotalUnits) AS TotalUnits , a.PositionID  , a.PositionType
FROM   
(  
SELECT   
  'Buy' AS Metric  
 , 'RegulatBuy' AS PositionType  
 , PositionID  
 , PositionTiming  
 , a.InitialUnits AS TotalUnits  
FROM  #auditpos a   
WHERE 1 = 1  
AND a.IsBuy = 1  
AND PositionTiming IN ('Opened_And_Closed_In_Period','Opened_In_Period_Not_Closed')  
AND ISNULL(a.IsPartialCloseChild,0) = 0
UNION ALL   
SELECT   
  'Buy' AS Metric  
 , 'SellShort' AS PositionType  
 , PositionID  
 , PositionTiming  
 , a.Units AS TotalUnits  
FROM  #auditpos a   
WHERE 1 = 1  
AND a.IsBuy = 0 
AND PositionTiming IN ('Opened_And_Closed_In_Period','Opened_Before_Period_Closed_InPeriod') 
UNION ALL   
SELECT   
  'Sell' AS Metric  
 , 'RegulatSell' AS PositionType  
 , PositionID  
 , PositionTiming  
 , a.Units AS TotalUnits  
FROM  #auditpos a   
WHERE 1 = 1  
AND a.IsBuy = 1
AND PositionTiming IN ('Opened_And_Closed_In_Period','Opened_Before_Period_Closed_InPeriod')  
UNION ALL   
SELECT   
  'Sell' AS Metric  
 , 'BuyShort' AS PositionType  
 , PositionID  
 , PositionTiming  
 , a.InitialUnits AS TotalUnits  
FROM  #auditpos a   
WHERE 1 = 1  
AND a.IsBuy = 0 
AND PositionTiming IN ('Opened_And_Closed_In_Period','Opened_In_Period_Not_Closed')  
AND ISNULL(a.IsPartialCloseChild,0) = 0
) a  
GROUP BY a.Metric , a.PositionID, a.PositionType


----- table writes ------  
  
DELETE FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results WHERE Date = @date 
  
-- buy real  
 
--DECLARE @date DATE = '20240203'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

insert INTO  BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results
SELECT @date  
  , 'SP_EY_Audit_Automation_IFRS_Contorl' AS Stored_Proc   
  , 'TotalBuy_Calc_detailed' AS Metric_a  
  , SUM(a.TotalUnits) AS Metric_a_Value  
     , 'IFRSTotalBuy' AS Metric_b  
     , SUM (b.TotalUnits) AS Metric_b_Value  
     , SUM(ISNULL(a.TotalUnits,0)) - SUM (isnull(b.TotalUnits,0)) AS Diff  
     , ROUND(abs(SUM(ISNULL(a.TotalUnits,0)) - SUM(ISNULL(b.TotalUnits,0)))/SUM(ISNULL(b.TotalUnits,0)) * 100,4) AS Diff_Percentage  
  , NULL AS IsPriceFound  
  , GETDATE() AS UpdateDate  
FROM   
(  
SELECT  
  SUM (TotalUnits) AS TotalUnits  
FROM #IFRSCompare    
WHERE Metric = 'Buy'
) a  
CROSS JOIN   
 (SELECT SUM(TotalUnits) TotalUnits  
  FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb   
  WHERE Date = @date AND Metric in ('BuyCFD','BuyReal','StakingBuy')
  ) b  
UNION all
SELECT @date  
  , 'SP_EY_Audit_Automation_IFRS_Contorl' AS Stored_Proc   
  , 'TotalSell_Calc_detailed' AS Metric_a  
  , SUM(a.TotalUnits) AS Metric_a_Value  
     , 'IFRSTotalSell' AS Metric_b  
     , SUM (b.TotalUnits) AS Metric_b_Value  
     , SUM(ISNULL(a.TotalUnits,0)) - SUM (isnull(b.TotalUnits,0)) AS Diff  
     , ROUND(abs(SUM(ISNULL(a.TotalUnits,0)) - SUM(ISNULL(b.TotalUnits,0)))/SUM(ISNULL(b.TotalUnits,0)) * 100,4) AS Diff_Percentage  
  , NULL AS IsPriceFound  
  , GETDATE() AS UpdateDate  
FROM   
(  
SELECT  
  SUM (TotalUnits) AS TotalUnits  
FROM #IFRSCompare    
WHERE Metric = 'Sell'
) a  
CROSS JOIN   
 (SELECT SUM(TotalUnits) TotalUnits  
  FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb   
  WHERE Date = @date AND Metric in ('RedeemSell','SellCFD','SellReal','StakingSell','RedeemStakingSell')
  ) b  
  
  
END  
  
-- select * from BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results order by 1





GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_EY_Audit_IFRS_Control` | synapse_sp | BI_DB_dbo | SP_EY_Audit_IFRS_Control | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_IFRS_Control.sql` |
| `BI_DB_dbo.BI_DB_EY_Audit_Closed_Positions` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_Closed_Positions | `—` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_Opened_Positions | `—` |
| `BI_DB_dbo.BI_DB_EY_Audit_ChangeLog` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_ChangeLog | `—` |
| `BI_DB_dbo.BI_DB_IFRS15_Daily_Balance` | synapse | BI_DB_dbo | BI_DB_IFRS15_Daily_Balance | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_IFRS15_Daily_Balance.md` |

