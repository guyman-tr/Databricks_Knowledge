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
   **Tier 2** with the transform stated. The source after `(Tier 2 — …)` MUST
   name the **upstream TABLE the transform reads from**, NOT the SP that
   performs the transform. The SP is the tool; the table is the data source.
   Examples:
   - `ABS(Fact_Deposit_State.Amount)` → `(Tier 2 — Fact_Deposit_State)`
   - `CASE WHEN x.IsSettled = 1 THEN 'Real' END` → `(Tier 2 — Fact_BillingDeposit)`
   - Pure passthrough from a DWH fact (no production wiki) →
     `(Tier 2 — Fact_X)`, NOT `(Tier 2 — SP_X)`.
   - Multi-source UNION → list both tables, slash-separated:
     `(Tier 2 — Fact_Deposit_State / Fact_Cashout_State)`.
   The ONLY case where an SP name belongs in the source is when the column is
   purely synthesized inside the SP with no input table column (e.g.
   `GETDATE()`, `@StartDateID`, fixed literal). Then write `(Tier 2 — SP_X)`.
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
- **Object**: `BI_DB_MarketingCloudUserBehaviorInstrument`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorInstrument/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_MarketingCloudUserBehaviorInstrument\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_MarketingCloudUserBehaviorInstrument\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument]
(
	[CID] [int] NOT NULL,
	[AccountId] [nvarchar](18) NULL,
	[UpdateDate] [datetime] NULL,
	[LastVisit] [datetime] NULL,
	[LastMonthAmountInvest] [money] NULL,
	[LastMonthOpenPositionsInvest] [int] NULL,
	[TotalAmountInvest] [money] NULL,
	[TotalPositionsInvest] [int] NULL,
	[AssetAmount] [money] NULL,
	[AssetPositions] [int] NULL,
	[OpenActiveInstruments] [int] NULL,
	[InstrumentID] [int] NULL,
	[DateID] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[InstrumentName] [varchar](100) NULL,
	[LastOpen] [date] NULL
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

Found 4 upstream wiki(s). Read EACH one in full.


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


### Upstream `DWH_dbo.Dim_Position` — synapse
- **Resolved as**: `DWH_dbo.Dim_Position`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md`

# DWH_dbo.Dim_Position

> Core trading position table containing every opened and closed position on the eToro platform since 2007, with financial metrics (P&L, commissions, forex rates), lifecycle timestamps, social trading relationships (mirrors/copies/copy funds), regulatory context, and 20+ market price and spread columns added incrementally since 2022.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Position (open) + etoro.History.ClosePosition (closed) |
| **Refresh** | Daily (incremental via SP_Dim_Position_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (CloseDateID ASC, PositionID ASC) |
| **Synapse Partitions** | Monthly by CloseDateID, 2007-01-01 through 2026-02-28 (230+ partitions) |
| **Synapse Indexes** | IX_Dim_Position_CID, IX_Dim_Position_CloseDateID, IX_Dim_Position_CloseDateIDOpenDateID, IX_Dim_Position_CloseOccurred_OpenOccurred, IX_Dim_Position_Instrument |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` |
| **UC Format** | Delta |
| **UC Partitioned By** | CloseDateID (monthly) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_Position is the central trading record table in DWH, containing every position (trade) ever opened on the eToro platform. Each row represents a single trading position lifecycle: opened by a customer (CID) on an instrument (InstrumentID), held for some duration, and either still open (CloseDateID=0) or closed with a final NetProfit. The data spans positions from 2007-08-27 to the most recent load date (2026-03-10 as of last ETL run 2026-03-11).

**Position types represented**:
- **Retail positions**: Opened by customers directly in the eToro web/mobile app
- **Mirror/CopyTrading positions**: Opened when a customer copies another trader (MirrorID links to Dim_Mirror); ParentPositionID links to the "master" position
- **Copy Fund positions**: IsCopyFundPosition=1 when the position's root (TreeID) belongs to a fund account (AccountTypeID=9)
- **AirDrop positions**: IsAirDrop=1 for positions created via airdrop events (crypto)
- **ReOpen positions**: IsReOpen=1 for positions reopened after a ReOpen event; ReopenForPositionID points to the original

**Open vs Closed state**:
- Open position: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00'
- Closed position: CloseDateID=YYYYMMDD (e.g., 20260310), CloseOccurred = actual close timestamp

**Data Sources (merged in ETL)**:
- Open positions: `etoro_Trade_OpenPositionEndOfDay` (today's snapshot of all open positions)
- Closed positions: `etoro_History_ClosePositionEndOfDay` (positions that closed on @dt)

**134 columns** covering financial amounts, forex rates at open/close, market prices (spread data), execution IDs, order IDs, hedge types, and fee calculations added through 2025.

---

## 2. Business Logic

### 2.1 Open vs Closed Position States

**What**: The same position row transitions from "open" to "closed" as its lifecycle progresses.

**Columns Involved**: `CloseDateID`, `CloseOccurred`, `NetProfit`, `EndForexRate`, `ClosePositionReasonID`

**Rules**:
- **Open state**: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00.000'. NetProfit holds unrealized P&L (updated daily). EndForexRate=NULL (position not yet closed).
- **Closed state**: CloseDateID=YYYYMMDD int (e.g., 20260310), CloseOccurred=actual datetime. NetProfit holds realized P&L. ClosePositionReasonID explains why it closed.
- **ETL daily cycle**: Each day, rows for positions that opened or closed that day are deleted/updated and re-inserted fresh from staging.
- **CloseDateID=19000101** is a transient internal state used during ETL processing (positions being "reset" before re-insertion); analysts should filter `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed closed positions.
- **OpenDateID and CloseDateID**: Both are YYYYMMDD integers, NOT dates. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.

**Diagram**:
```
Position lifecycle in Dim_Position:
  Day 1 (open):  CloseDateID=0,        CloseOccurred='1900-01-01'  <-- still open
  Day N (close): CloseDateID=YYYYMMDD, CloseOccurred=actual time   <-- closed
  During ETL:    CloseDateID=19000101  <-- transient, skip in queries
```

### 2.2 Social Trading Relationships

**What**: How copy-trading and mirror relationships are encoded.

**Columns Involved**: `MirrorID`, `ParentPositionID`, `OrigParentPositionID`, `TreeID`, `IsCopyFundPosition`

**Rules**:
- **MirrorID**: FK to Dim_Mirror. When a customer copies another trader, all positions generated share the same MirrorID.
- **ParentPositionID**: The position ID of the "master" position being copied. NULL for original/manual positions.
- **OrigParentPositionID**: The original parent (before any reopen/rebalance operations).
- **TreeID**: FK back to Dim_Position.PositionID -- points to the root position of the copy tree. Used to identify CopyFund positions.
- **IsCopyFundPosition=1**: The position belongs to a copy-fund tree (TreeID's CID has AccountTypeID=9).

### 2.3 Financial Metrics and Commissions

**What**: How P&L and commission amounts flow through a position lifecycle.

**Columns Involved**: `Amount`, `NetProfit`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `EndOfWeekFee`, `PnLInDollars`

**Rules**:
- **Amount**: Position notional value in USD at open.
- **NetProfit**: Realized P&L for closed positions; unrealized daily P&L for open positions (updated daily from EndOfDayPnLInDollars).
- **Commission**: Opening commission charged.
- **CommissionOnClose**: Closing commission. Set to 0 for open positions; filled when position closes.
- **FullCommission / FullCommissionOnClose**: Total commissions including all components.
- **EndOfWeekFee**: Overnight fee charged on weekends for leveraged positions. CloseOnEndOfWeek=1 means position auto-closes at weekend.
- **PnLInDollars**: Unrealized daily P&L for open positions (from EndOfDayPnLInDollars staging column); realized at close.

### 2.4 Position Segmentation and Regulation

**What**: Regulatory context and platform categorization at time of open.

**Columns Involved**: `RegulationIDOnOpen`, `PlatformTypeID`, `PositionSegment`

**Rules**:
- **RegulationIDOnOpen**: The regulatory jurisdiction (entity) the customer belonged to at the time of opening. Derived from a JOIN with etoro_History_BackOfficeCustomer at ETL time. 1=UK/FCA, 2=Cyprus/CySEC, etc.
- **PlatformTypeID**: FK to Dim_PlatformType. 1=Web, 2=iOS, 3=Android, 0=Undefined.
- **PositionSegment**: Internal segment classification (smallint).

### 2.5 Volume and Unit Calculations

**What**: ETL-computed unit and volume metrics.

**Columns Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `Volume`, `VolumeOnClose`, `UnitMargin`, `InitialUnits`

**Rules**:
- **AmountInUnitsDecimal**: Position size in instrument units (e.g., shares, crypto coins).
- **LotCountDecimal**: Position size in lots.
- **Volume**: ETL-computed = ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion factor, 0) -- approximates USD equivalent at open.
- **VolumeOnClose**: Similar calculation using EndForexRate at close.
- **UnitMargin**: Margin per unit for leveraged positions.
- **InitialUnits**: Original units before any partial-close or partial-reopen adjustments.

### 2.6 Open/Close Rates and Market Prices

**What**: The forex rates, market prices, and spread data captured at open and close.

**Columns Involved**: `InitForexRate`, `EndForexRate`, `SpreadedPipBid`, `SpreadedPipAsk`, `InitForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate`, `EndForex_*`, `OpenMarket_*`, `CloseMarket_*`

**Rules**:
- **InitForexRate / EndForexRate**: The execution rate at open and close respectively (in instrument's base currency per USD or USD per instrument).
- **InitForex_* columns**: Ask, Bid, spreaded variants, and USD conversion rate at the INIT price rate ID (raw price book). Populated from PriceLog_History_CurrencyPrice_Active.
- **EndForex_***: Same price book data at the END (close) rate.
- **OpenMarket_* / CloseMarket_***: Market prices at the time of market open/close events. Added 2023-03-07 (12 columns).
- **SpreadedPipBid / SpreadedPipAsk**: Bid/ask spread in pips at execution.

### 2.7 Fees and Taxes (Post-2025)

**What**: Tax and fee components added in 2025.

**Columns Involved**: `OpenTotalTaxes`, `CloseTotalTaxes`, `OpenTotalFees`, `CloseTotalFees`, `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpenByUnits`, `EstimateCloseFeeOnOpen`, `Close_PnLInDollars`, `Close_CalculationRate`, `Close_ConversionRate`, `Close_PriceType`, `CurrentCalculationRate`, `CurrentConversionRate`

**Rules**:
- Added 2025-06-25 (Adi Ferber) and 2025-09-08 (Daniel Kaplan).
- These columns will be NULL for positions opened/closed before the ETL addition date.
- `EstimateCloseFeeForCFD/OnOpenByUnits/OnOpen`: Fee estimates for CFD instruments at open.
- `Close_PnLInDollars / Close_CalculationRate / Close_ConversionRate / Close_PriceType`: Close-side P&L metrics with explicit calculation chain.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Partitioning

**HASH (PositionID)**: Rows distributed by PositionID across nodes. Single-position lookups are efficient. JOINs between two HASH(PositionID) tables (e.g., Dim_Position JOIN Dim_PositionChangeLog by PositionID) are co-located and fast.

**Clustered Index (CloseDateID, PositionID)**: Clustered on close date -- date-range queries on closed positions are efficient. Open-position queries (CloseDateID=0) hit a single partition.

**Monthly partitioning**: Partitioned from 2007-01-01 to 2026-02-28 by CloseDateID. Always include a CloseDateID range filter in queries to enable partition elimination. Without it, all 230+ partitions are scanned.

**NOT ENFORCED PK**: The primary key on (PositionID, CloseDateID) is NOT ENFORCED. Synapse does not validate uniqueness. PositionID is logically unique per position, but be aware: duplicate PositionIDs can exist if ETL has a bug.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position`. Partitioned monthly by CloseDateID. Use `WHERE CloseDateID >= 20260101` style filters for partition pruning. Z-ORDER on PositionID within each partition is beneficial for position-lookup workloads.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get closed positions for a date range | WHERE CloseDateID BETWEEN 20260101 AND 20260310 |
| Get all open positions | WHERE CloseDateID = 0 |
| Get a customer's positions | WHERE CID = X AND CloseDateID BETWEEN ... (always include date range!) |
| P&L for closed positions | SUM(NetProfit) WHERE CloseDateID > 0 AND CloseDateID != 19000101 |
| CopyTrading positions only | WHERE MirrorID IS NOT NULL |
| Direct (non-copy) positions | WHERE MirrorID IS NULL AND ParentPositionID IS NULL |
| CopyFund positions only | WHERE IsCopyFundPosition = 1 |
| Long positions only | WHERE IsBuy = 1 |
| Short positions | WHERE IsBuy = 0 |
| By instrument | WHERE InstrumentID = X AND CloseDateID BETWEEN ... |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer info, tier, country |
| DWH_dbo.Dim_Currency | ON CurrencyID | Position base currency |
| DWH_dbo.Dim_Mirror | ON MirrorID | Copy-trading relationship details |
| DWH_dbo.Dim_ClosePositionReason | ON ClosePositionReasonID | Why position was closed |
| DWH_dbo.Dim_Platform | ON PlatformTypeID | Platform used to open |
| DWH_dbo.Dim_Date | ON OpenDateID / CloseDateID | Calendar dimensions |
| DWH_dbo.Dim_PositionChangeLog | ON PositionID | Position lifecycle changes (IsSettled, Amount changes) |

### 3.4 Gotchas

- **NEVER query without CloseDateID filter**: Without a date range filter, Synapse scans all 230+ monthly partitions. Always include `WHERE CloseDateID BETWEEN X AND Y` or `WHERE CloseDateID = 0`.
- **CloseDateID=0 for open, CloseDateID=19000101 during ETL**: Exclude 19000101 in most queries: `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed-closed positions.
- **OpenDateID and CloseDateID are int, not date**: They are in YYYYMMDD format. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.
- **HASH distribution on PositionID**: Very efficient for single-position or position-list queries. Less efficient for large customer-level scans (CID is not the distribution key).
- **NOT ENFORCED PK**: PositionID uniqueness is not enforced by the database. Check for duplicates if needed.
- **134 columns -- many nullable**: Most columns beyond the core set are NULL for older positions predating their addition (2022-2025). Don't assume non-null.
- **Volume = ETL-computed approximation**: Volume (int) is rounded to nearest integer. VolumeOnClose uses EndForexRate which may differ. Not always perfectly accurate.
- **UpdateDate = GETDATE() or GETUTCDATE()**: Mixed -- open positions use GETDATE(), UPDATE path for closing positions uses GETUTCDATE(). Not a reliable "modified since" field.
- **IsPartialCloseParent / IsPartialCloseChild**: 1 if this position was split via partial close. Use OriginalPositionID to trace the original. Generally filter ISNULL(IsPartialCloseChild,0)=0 on OPEN metrics only — NEVER on CLOSE. Some open metrics (e.g., volume) are already pro-rated, so excluding children would be wrong. Apply the filter case-by-case.
- **RegulationIDOnOpen is 0 for unmatched**: If the ETL JOIN with BackOfficeCustomer history finds no regulation at that date, ISNULL defaults to 0.
- **AmountInUnitsDecimal may change**: Position amount can be adjusted (e.g., partial close). Dim_PositionChangeLog tracks historical amount values.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 - MCP live data) |
| * | Tier 4 - Inferred from name | (Tier 4 - [UNVERIFIED]) |

Note: Upstream production wikis available for Trade.PositionTbl and Trade.OpenPositionEndOfDay. Columns with direct passthrough or view-computed staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2.

**Column Groups** (134 total):

#### Group A: Core Identity (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 3 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 4 | CurrencyID | int | NO | FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0. (Tier 1 — Trade.PositionTbl) |
| 5 | ProviderID | int | NO | References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen). (Tier 1 — Trade.PositionTbl) |

#### Group B: Lifecycle Timestamps and Date IDs (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | OpenOccurred | datetime | NO | When position was persisted (mapped from Occurred in production). Default getutcdate(). (Tier 1 — Trade.PositionTbl) |
| 7 | CloseOccurred | datetime | NO | When close was persisted. (Tier 1 — Trade.PositionTbl) |
| 8 | OpenDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 9 | CloseDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 10 | RequestOpenOccurred | datetime2(7) | YES | When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time). (Tier 1 — Trade.PositionTbl) |
| 11 | RequestCloseOccurred | datetime2(7) | YES | When close request arrived at API. (Tier 1 — Trade.PositionTbl) |

#### Group C: Financial Metrics (13 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Amount | money | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl) |
| 14 | InitialAmountCents | money | YES | Initial amount in cents. Used for ratio calculations. (Tier 1 — Trade.PositionTbl) |
| 15 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 16 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 17 | PnLInDollars | decimal(38,6) | YES | Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 18 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 19 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 20 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 21 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 22 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 23 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 24 | EndOfWeekFee | money | NO | Overnight/weekend carry fee. (Tier 1 — Trade.PositionTbl) |

#### Group D: ETL-Computed Volumes and Units (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | LotCountDecimal | decimal(16,6) | YES | Lot count from provider. Used for hedge aggregation and unit-based sizing. (Tier 1 — Trade.PositionTbl) |
| 26 | UnitMargin | decimal(15,8) | YES | Margin per unit. From Trade.ProviderToInstrument. (Tier 1 — Trade.PositionTbl) |
| 27 | Volume | int | YES | ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 28 | VolumeOnClose | int | YES | ETL-computed USD volume at close: ROUND(AmountInUnitsDecimal * EndForexRate * USD conversion, 0). 0 for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group E: Direction, Leverage, and Trade Settings (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | IsBuy | bit | NO | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 30 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 31 | CloseOnEndOfWeek | bit | NO | Weekend-close flag. 1 = position auto-closes at end of trading week. (Tier 1 — Trade.PositionTbl) |
| 32 | LimitRate | decimal(16,8) | YES | Take-profit rate set at open (or most recent update). (Tier 1 — Trade.PositionTbl) |
| 33 | StopRate | decimal(16,8) | YES | Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog. (Tier 1 — Trade.PositionTbl) |

#### Group F: Forex Rates (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | InitForexRate | decimal(16,8) | NO | Opening price rate at position open. Used for PnL calculation. (Tier 1 — Trade.PositionTbl) |
| 35 | EndForexRate | decimal(16,8) | YES | Closing rate at position close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |
| 36 | LastOpConversionRate | decimal(16,8) | YES | Conversion rate for last operation. (Tier 1 — Trade.PositionTbl) |
| 37 | InitConversionRate | decimal(16,8) | YES | Currency conversion rate at open. (Tier 1 — Trade.PositionTbl) |
| 38 | SpreadedPipBid | decimal(16,8) | YES | Bid rate with spread at open. From Trade.CurrencyPrice/spread config. (Tier 1 — Trade.PositionTbl) |
| 39 | SpreadedPipAsk | decimal(16,8) | YES | Ask rate with spread at open. (Tier 1 — Trade.PositionTbl) |

#### Group G: Price Rate IDs and Execution IDs (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | InitForexPriceRateID | bigint | YES | FK to price log table -- the specific price rate record at open. (Tier 1 — Trade.PositionTbl) |
| 41 | EndForexPriceRateID | bigint | YES | Price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 42 | LastOpPriceRateID | bigint | YES | Last operation price rate ID. (Tier 1 — Trade.PositionTbl) |
| 43 | LastOpPriceRate | decimal(16,8) | YES | Last operation price. Updated on partial close, dividend, etc. (Tier 1 — Trade.PositionTbl) |
| 44 | OpenMarketPriceRateID | bigint | YES | Market price rate ID at open. (Tier 1 — Trade.PositionTbl) |
| 45 | CloseMarketPriceRateID | bigint | YES | Market price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 46 | InitConversionRateID | bigint | YES | Conversion rate record ID at open. (Tier 1 — Trade.PositionTbl) |

#### Group H: Execution IDs (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | InitExecutionID | bigint | YES | Execution record ID at open. (Tier 1 — Trade.PositionTbl) |
| 48 | EndExecutionID | bigint | YES | Execution record ID at close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |

#### Group I: Market Price Data at Open (10 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 49 | InitForex_Ask | numeric(16,8) | YES | Raw ask price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | InitForex_Bid | numeric(16,8) | YES | Raw bid price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 51 | InitForex_AskSpreaded | numeric(16,8) | YES | Ask price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 52 | InitForex_BidSpreaded | numeric(16,8) | YES | Bid price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 53 | InitForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 54 | EndForex_Ask | numeric(16,8) | YES | Raw ask at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 55 | EndForex_Bid | numeric(16,8) | YES | Raw bid at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 56 | EndForex_AskSpreaded | numeric(16,8) | YES | Spreaded ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 57 | EndForex_BidSpreaded | numeric(16,8) | YES | Spreaded bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 58 | EndForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at close from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group J: Market Spread Data (8 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 59 | OpenMarket_Ask | numeric(16,8) | YES | Market ask at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 60 | OpenMarket_Bid | numeric(16,8) | YES | Market bid at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 61 | OpenMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 62 | OpenMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | OpenMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 64 | OpenMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 65 | CloseMarket_Ask | numeric(16,8) | YES | Market ask at close event. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 66 | CloseMarket_Bid | numeric(16,8) | YES | Market bid at close event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group K: Close Market Spread (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 67 | CloseMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | CloseMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 69 | CloseMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 70 | CloseMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group L: Markup and Spread Metrics (7 columns -- added 2024-01-15)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 71 | OpenMarketSpread | decimal(38,18) | YES | Spread at open. (Tier 1 — Trade.PositionTbl) |
| 72 | CloseMarketSpread | decimal(38,18) | YES | Spread at close. (Tier 1 — Trade.PositionTbl) |
| 73 | CloseMarkupOnOpen | decimal(38,18) | YES | Close markup projected at open. (Tier 1 — Trade.PositionTbl) |
| 74 | OpenMarkup | decimal(38,18) | YES | Markup at open. (Tier 1 — Trade.PositionTbl) |
| 75 | CloseMarkup | decimal(38,18) | YES | Markup at close. (Tier 1 — Trade.PositionTbl) |
| 76 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 77 | SpreadedCommission | int | YES | Spread-related commission component. (Tier 1 — Trade.PositionTbl) |

#### Group M: Social Trading and Hierarchy (8 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 79 | HedgeID | int | YES | FK to Trade.Hedge. Broker executed hedge. NULL until hedge is opened. (Tier 1 — Trade.PositionTbl) |
| 80 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 81 | ParentPositionID | bigint | YES | Copy-trade parent. 0/1 = root. Positive = child of referenced position. (Tier 1 — Trade.PositionTbl) |
| 82 | OrigParentPositionID | bigint | YES | Original parent before any detachment. (Tier 1 — Trade.PositionTbl) |
| 83 | TreeID | bigint | YES | Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative. (Tier 1 — Trade.PositionTbl) |
| 84 | IsCopyFundPosition | int | YES | 1=position belongs to a copy fund tree (TreeID's CID has AccountTypeID=9). ETL-computed via JOIN chain. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 85 | IsOpenOpen | bit | YES | Open-on-open copy behavior. From Mirror. (Tier 1 — Trade.PositionTbl) |

#### Group N: Partial Close and ReOpen (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 87 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 88 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 89 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 90 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 91 | IsPartialCloseChildFromReOpen | int | YES | 1=partial close child that was created via a ReOpen flow. (Tier 4 - [UNVERIFIED]) |
| 92 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group O: Settlement and Redemption (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 93 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 94 | IsSettledOnOpen | int | YES | 1 = real asset, 0 = CFD asset. Value at position open (snapshot); same 0/1 encoding as IsSettled. (Tier 5 — Expert Review) |
| 95 | RedeemStatus | tinyint | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 96 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 97 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Customer` — synapse
- **Resolved as**: `DWH_dbo.Dim_Customer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`

﻿# DWH_dbo.Dim_Customer

> Master customer dimension table for the DWH; consolidates identity, demographics, compliance status, acquisition tracking, and external integrations from 14+ staging sources into a single slowly-changing Type 1 dimension with explicit change detection, PII masking, and multi-phase post-load enrichment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | RealCID (PK NOT ENFORCED, CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(RealCID) |
| **Index** | CLUSTERED INDEX (RealCID ASC); PK NONCLUSTERED NOT ENFORCED |
| **Column Count** | 107 |
| **PII Masking** | 14 columns with Dynamic Data Masking |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Tables** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked PII) |
| **UC Copy Strategy** | Override |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | CDC-style: change detection → DELETE/INSERT → multi-phase UPDATE enrichment |

---

## 1. Business Meaning

`Dim_Customer` is the DWH's central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer.

The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle.

Two UC copies exist:
- **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics
- **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" JOINs `Dim_Customer` on CID=RealCID for country, regulation, and status filtering
- **BI Queries**: Nearly every DWH fact table JOINs to Dim_Customer (via CID=RealCID) for customer segmentation
- **Synapse Training**: Confluence "Temporary Tables in Synapse" uses Dim_Customer as a reference example for HASH distribution optimization

---

## 5. Lineage

### 2.1 Staging Sources (14+ tables)

| Staging Table | Production Source | Role |
|--------------|-------------------|------|
| `DWH_staging.etoro_Customer_Customer` | Customer.CustomerStatic | Core customer profile (identity, demographics, registration) |
| `DWH_staging.etoro_BackOffice_Customer` | BackOffice.Customer | Compliance/admin attributes (verification, risk, regulation, guru status) |
| `DWH_staging.etoro_History_Customer` | History.Customer | Latest version for change detection (SCD) |
| `DWH_staging.etoro_History_BackOfficeCustomer` | History.BackOfficeCustomer | Latest version for BO attribute change detection |
| `DWH_staging.STS_Audit_UserOperationsData` | STS_Audit.UserOperationsData | 2FA enable/disable tracking |
| `DWH_staging.ContactVerification_Phone_Customer` | ContactVerification.Phone.Customer | Phone number, verification status |
| `DWH_staging.UserApiDB_Customer_Avatars` | UserApiDB.Customer.Avatars | Avatar upload tracking |
| `DWH_staging.etoro_Billing_vDeposit` | Billing.vDeposit | Legacy FTD source (replaced by below) |
| `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits` | CustomerFinanceDB.Customer.FirstTimeDeposits | FTD date, amount, platform, recovery date |
| `DWH_staging.ScreeningService_Screening_UserScreening` | ScreeningService.Screening.UserScreening | Screening/compliance status |
| `DWH_staging.SalesForce_DB_Prod_dbo_IdMapTopology` | SalesForce_DB_Prod.dbo.IdMapTopology | SalesForce account ID mapping |
| `DWH_staging.etoro_BackOffice_CustomerDocument` + `etoro_BackOffice_CustomerDocumentToDocumentType` | BackOffice.CustomerDocument | Address proof & ID proof status |
| `DWH_staging.etoro_Customer_CustomerStatic` | Customer.CustomerStatic | ApexID only |
| `DWH_staging.UserApiDB_Customer_CustomerIdentification` | UserApiDB.Customer.CustomerIdentification | GCID, DemoCID, TanganyID, DltID |
| `DWH_staging.ComplianceStateDB_Compliance_StocksLending` | ComplianceStateDB.Compliance.StocksLending | EquiLendID, StocksLendingStatusID |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | (DWH internal) | SubChannelID via AffiliateID mapping |

### 2.2 ETL Pipeline (SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer)

```
ORCHESTRATOR (SP_Dim_Customer_DL_To_Synapse):
  1. Load 14 staging/external tables:
     Ext_Dim_Customer_Affiliate, Ext_Dim_Customer_BOCustomer, Ext_Dim_Customer_2FA,
     Ext_Dim_Customer_PhoneCustomer, Ext_Dim_Customer_Customer, Ext_Dim_Customer_Avatars,
     Ext_etoro_Billing_vDeposit, Ext_CustomerFinanceDB_Customer_FirstTimeDeposits,
     Ext_Dim_Customer_ScreeningStatusID, Ext_Dim_Customer_SF_ID, Ext_Dim_Customer_Document,
     Ext_Dim_CustomerStatic, Ext_Dim_Customer_CustomerIdentification, Ext_Dim_Customer_StocksLending
  2. EXEC SP_Dim_Customer

CORE LOGIC (SP_Dim_Customer):
  Step 1: Build #customer — JOIN Ext_Customer_Customer + Ext_BOCustomer
          Compute: IsValidCustomer, IsCreditReportValidCB
          Rename: SerialID→AffiliateID, ManagerID→AccountManagerID, isEmployeeAccount→EmployeeAccount
  Step 2: Detect #new (CIDs not yet in Dim_Customer)
  Step 3: Detect #update (50+ column comparison using ISNULL + COLLATE)
  Step 4: Build #full_list (new OR updated CIDs) with 2FA from Ext_2FA
  Step 5: Preserve #CustomerInitalIndicaton (deposit, avatar, document, Tangany, DLT, phone, FTD fields)
  Step 6: BEGIN TRAN: DELETE matching CIDs → INSERT with preserved indicators
  Step 7: Post-transaction UPDATEs:
          Avatar → HasAvatar, AvatarUploadDate
          Deposit → IsDepositor, FirstDepositDate, FirstDepositAmount, FTD fields
          ScreeningStatusID → from screening service
          SalesForceAccountID → from SF ID map
          Document proofs → IsAddressProof, IsIDProof + expiry dates
          2FA → from audit log
          SubChannelID → from affiliate mapping
          ApexID → from CustomerStatic
          Phone → PhoneNumber, IsPhoneVerified, PhoneVerificationDate
          Tangany → TanganyID, TanganyStatusID
          DLT → DltID, DltStatusID
          StocksLending → EquiLendID, StocksLendingStatusID
  Step 8: Populate Ext_Dim_Customer_ExternalID_GCID, update UserName_Lower
```

### 2.3 Key Column Renames

| DWH Column | Source Column | Source Table | Why |
|-----------|-------------|-------------|-----|
| RealCID | CID | etoro_Customer_Customer | Disambiguate from other CID uses in DWH |
| AffiliateID | SerialID | etoro_Customer_Customer | Business-friendly name |
| AccountManagerID | ManagerID | etoro_BackOffice_Customer | Disambiguate from other ManagerID columns |
| EmployeeAccount | isEmployeeAccount | etoro_BackOffice_Customer | Normalize casing |
| RegisteredReal | Registered | etoro_Customer_Customer | Clarify real-account registration |

### 2.4 DWH-Computed Columns

| Column | Computation |
|--------|------------|
| IsValidCustomer | `1` when PlayerLevelID≠4 AND LabelID NOT IN (30,26) AND CountryID≠250; else `0` |
| IsCreditReportValidCB | Similar to IsValidCustomer but also excludes PlayerLevelID=4 when AccountTypeID≠2, and has specific CID exceptions for CountryID=250 |
| UpdateDate | `GETDATE()` — ETL timestamp |
| UserName_Lower | `LOWER(UserName)` — set in final UPDATE |

---

## 4. Elements

### 3.1 Customer Identity

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 1 | RealCID | int | NO | No | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | No | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | int | YES | No | Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer) |
| 4 | OriginalCID | int | YES | No | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 5 | ID | uniqueidentifier | NO | No | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 6 | ExternalID | decimal(38,0) | YES | No | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |

### 3.2 Personal Information (PII — Masked)

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 7 | UserName | varchar(20) | YES | Yes | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 8 | UserName_Lower | varchar(20) | YES | Yes | Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 9 | FirstName | nvarchar(50) | YES | Yes | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 10 | LastName | nvarchar(50) | YES | Yes | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 11 | MiddleName | nvarchar(50) | YES | Yes | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | char(1) | YES | Yes | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | BirthDate | datetime | YES | Yes | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 14 | Email | varchar(50) | YES | Yes | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Yes | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | IP | varchar(15) | YES | Yes | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 17 | Zip | nvarchar(50) | YES | Yes | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 18 | City | nvarchar(50) | YES | Yes | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 19 | Address | nvarchar(100) | YES | Yes | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 20 | BuildingNumber | nvarchar(30) | YES | Yes | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |

### 3.3 Acquisition & Marketing

| # | Column | Type | Description |
|---|--------|------|-------------|
| 21 | AffiliateID | int | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 22 | CampaignID | int | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 — Customer.CustomerStatic) |
| 23 | SubChannelID | int | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 24 | LabelID | int | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 — Customer.CustomerStatic) |
| 25 | BannerID | int | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 26 | FunnelID | int | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 — Customer.CustomerStatic) |
| 27 | FunnelFromID | int | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — Customer.CustomerStatic) |
| 28 | DownloadID | int | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — Customer.CustomerStatic) |
| 29 | ReferralID | int | Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 30 | SubSerialID | varchar(1024) | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic) |

### 3.4 Registration & Account Lifecycle

| # | Column | Type | Description |
|---|--------|------|-------------|
| 31 | RegisteredReal | datetime | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 32 | RegisteredDemo | datetime | Demo account registration date. Source unclear — may be populated separately. (Tier 2 — SP_Dim_Customer) |
| 33 | AccountExpirationDate | datetime | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 — Customer.CustomerStatic) |
| 34 | AccountStatusID | int | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 35 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 36 | PlayerStatusReasonID | int | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 37 | PlayerStatusSubReasonID | int | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 38 | PendingClosureStatusID | tinyint | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Customer.CustomerStatic) |
| 39 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 40 | AccountTypeID | int | Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 — BackOffice.Customer) |
| 41 | IsDepositor | bit | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 42 | FirstDepositDate | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 43 | FirstDepositAmount | money | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |

### 3.5 Compliance & Regulation

| # | Column | Type | Description |
|---|--------|------|-------------|
| 44 | RegulationID | tinyint | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 45 | DesignatedRegulationID | int | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 46 | RegulationChangeDate | datetime | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 — BackOffice.Customer) |
| 47 | CountryID | int | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 48 | CountryIDByIP | int | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 — Customer.CustomerStatic) |
| 49 | CitizenshipCountryID | int | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — Customer.CustomerStatic) |
| 50 | POBCountryID | int | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — Customer.CustomerStatic) |
| 51 | RegionID | int | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — Customer.CustomerStatic) |
| 52 | RegionByIP_ID | int | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — Customer.CustomerStatic) |
| 53 | VerificationLevelID | int | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — BackOffice.Customer) |
| 54 | DocsOK | tinyint | Whether required documents are verified. (Tier 2 — SP_Dim_Customer) |
| 55 | DocumentStatusID | int | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 56 | IsAddressProof | int | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 57 | IsAddressProofExpiryDate | datetime | Expiry date of address proof document. (Tier 2 — SP_Dim_Customer) |
| 58 | IsIDProof | int | Whether ID proof document is on file (1/0). (Tier 2 — SP_Dim_Customer) |
| 59 | IsIDProofExpiryDate | datetime | Expiry date of ID proof document. (Tier 2 — SP_Dim_Customer) |
| 60 | SuitabilityTestStatusID | int | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — BackOffice.Customer) |
| 61 | MifidCategorizationID | int | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 — BackOffice.Customer) |
| 62 | ScreeningStatusID | int | Compliance screening status. Updated from ScreeningService. (Tier 2 — SP_Dim_Customer) |
| 63 | WorldCheckID | int | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 64 | WorldCheckResultsUpdated | datetime | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 65 | IsEDD | bit | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | Bankruptcy | tinyint | Bankruptcy flag. (Tier 2 — SP_Dim_Customer) |
| 67 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 68 | IsCreditReportValidCB | int | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 — SP_Dim_Customer) |

### 3.6 Risk & Communication

| # | Column | Type | Description |
|---|--------|------|-------------|
| 69 | RiskStatusID | int | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 — BackOffice.Customer) |
| 70 | RiskClassificationID | int | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 — BackOffice.Customer) |
| 71 | EmployeeAccount | tinyint | 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 — BackOffice.Customer) |
| 72 | LanguageID | int | Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 73 | CommunicationLanguageID | int | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 — Customer.CustomerStatic) |
| 74 | IsEmailVerified | int | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 — Customer.CustomerStatic) |
| 75 | PrivacyPolicyID | int | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — Customer.CustomerStatic) |
| 76 | IsCopyBlocked | bit | 1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 — BackOffice.Customer) |

### 3.7 Social & Trading Features

| # | Column | Type | Description |
|---|--------|------|-------------|
| 77 | GuruStatusID | smallint | eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 — BackOffice.Customer) |
| 78 | NumOfGurus | int | Number of Popular Investors this customer is copying. (Tier 2 — SP_Dim_Customer) |
| 79 | NumOfCopiers | int | Number of customers copying this customer's trades. (Tier 2 — SP_Dim_Customer) |
| 80 | NumOfRAF | int | Number of successful Refer-A-Friend referrals. (Tier 2 — SP_Dim_Customer) |
| 81 | SocialConnectID | int | Social media connection type. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 82 | PremiumAccount | tinyint | Whether this is a premium account. (Tier 2 — SP_Dim_Customer) |
| 83 | Evangelist | tinyint | Whether this customer is an evangelist/ambassador. (Tier 2 — SP_Dim_Customer) |
| 84 | HasAvatar | tinyint | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 — SP_Dim_Customer) |
| 85 | AvatarUploadDate | datetime | When the avatar was uploaded. (Tier 2 — SP_Dim_Customer) |
| 86 | EvMatchStatus | int | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |

### 3.8 Account Management

| # | Column | Type | Description |
|---|--------|------|-------------|
| 87 | AccountManagerID | int | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer) |
| 88 | UpdateDate | datetime | ETL load/update timestamp (GETDATE()). (Tier 2 — SP_Dim_Customer) |
| 89 | SalesForceAccountID | nvarchar(18) | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — BackOffice.Customer) |

### 3.9 Authentication & Phone Verification

| # | Column | Type | Description |
|---|--------|------|-------------|
| 90 | 2FA | int | Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 91 | PhoneVerifiedID | int | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — BackOffice.Customer) |
| 92 | PhoneNumber | varchar(30) | Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 — SP_Dim_Customer) |
| 93 | IsPhoneVerified | bit | Whether phone is verified (VerificationStatusID IN (1,2) → 1). (Tier 2 — SP_Dim_Customer) |
| 94 | PhoneVerificationDate | smalldatetime | Date phone was verified. '1900-01-01' if not verified. (Tier 2 — SP_Dim_Customer) |

### 3.10 External Integrations

| # | Column | Type | Description |
|---|--------|------|-------------|
| 95 | ApexID | varchar(8) | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — Customer.CustomerStatic) |
| 96 | TanganyID | nvarchar(max) | Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 97 | TanganyStatusID | tinyint | Tangany integration status. (Tier 2 — SP_Dim_Customer) |
| 98 | EquiLendID | nvarchar(max) | EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 — SP_Dim_Customer) |
| 99 | StocksLendingStatusID | int | Stocks lending consent status. (Tier 2 — SP_Dim_Customer) |
| 100 | DltID | nvarchar(max) | Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 101 | DltStatusID | int | DLT integration status. (Tier 2 — SP_Dim_Customer) |
| 102 | HasWallet | int | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |

### 3.11 FTD (First Time Deposit) Tracking

| # | Column | Type | Description |
|---|--------|------|-------------|
| 103 | FTDPlatformID | nvarchar(4000) | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 104 | FTDTransactionID | nvarchar(4000) | Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 105 | FTDRecoveryDate | datetime2(7) | Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |

### 3.12 Miscellaneous

| # | Column | Type | Description |
|---|--------|------|-------------|
| 106 | CashoutFeeGroupID | int | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — BackOffice.Customer) |
| 107 | WeekendFeePrecentage | int | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 — Customer.CustomerStatic) |

---

## 2. Business Logic

### 4.1 Change Detection (CDC-Style)

The SP compares 50+ columns between `#customer` (staging) and existing `Dim_Customer` using `ISNULL(old,0) <> ISNULL(new,0)` with explicit `COLLATE Latin1_General_100_BIN` for string columns. Only customers with actual changes (or new customers) are processed. This prevents unnecessary row churn.

### 4.2 Indicator Preservation

When a customer row is updated (DELETE+INSERT), certain indicator fields are preserved from the old row via `#CustomerInitalIndicaton`: FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor, ScreeningStatusID, SalesForceAccountID, document proofs, WorldCheckID, Tangany, Phone, EquiLend, DLT, FTD fields. These are then refreshed in subsequent post-load UPDATEs if new data is available.

### 4.3 Multi-Source Identity Resolution

Customer attributes come from multiple microservices. The ETL uses `ISNULL(history_version, current_value)` patterns to prefer the latest History version (with temporal filtering: ValidFrom < @CurrentDate, ValidFrom >= @DelayDate, ValidTo >= @CurrentDate) over the current snapshot, ensuring the most up-to-date attribute values are captured.

### 4.4 FTD Recovery Date Logic

The `FirstDepositDate` is updated using: if the existing `FirstDepositDate` (as date) is earlier than `FTDRecoveryDate`, use `FTDRecoveryDate`; otherwise use the `FTDDate`. This handles cases where an FTD was reversed and re-deposited on a different day.

### 4.5 IsValidCustomer Business Rule

```
IsValidCustomer = 1 WHEN:
  PlayerLevelID ≠ 4 (not Popular Investor)
  AND LabelID NOT IN (30, 26) (not bonus-only or specific label)
  AND CountryID ≠ 250
```

This excludes demo-like, internal, and specific-jurisdiction accounts from standard reporting.

---

## 6. Relationships

### 5.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CountryID / CountryIDByIP / CitizenshipCountryID / POBCountryID | Dim_Country | CountryID = CountryID |
| AffiliateID | Dim_Affiliate | AffiliateID = AffiliateID |
| CampaignID | Dim_Campaign | CampaignID = CampaignID |
| AccountTypeID | Dim_AccountType | AccountTypeID = AccountTypeID |
| AccountStatusID | Dim_AccountStatus | AccountStatusID = AccountStatusID |
| PlayerLevelID | (Dictionary.PlayerLevel — no DWH dim) | — |
| GuruStatusID | Dim_GuruStatus | GuruStatusID = GuruStatusID |
| FunnelID | Dim_Funnel | FunnelID = FunnelID |
| DocumentStatusID | Dim_DocumentStatus | DocumentStatusID = DocumentStatusID |
| EvMatchStatus | Dim_EvMatchStatus | EvMatchStatus = EvMatchStatus |
| CashoutFeeGroupID | Dim_CashoutFeeGroup | CashoutFeeGroupID = CashoutFeeGroupID |

### 5.2 Fact Table Relationships

Nearly every DWH fact table JOINs to Dim_Customer:
- `Fact_BillingWithdraw.CID = Dim_Customer.RealCID`
- `Fact_CustomerUnrealized_PnL.CID = Dim_Customer.RealCID`
- `Fact_SnapshotCustomer.RealCID = Dim_Customer.RealCID`
- `Fact_CustomerAction.CID = Dim_Customer.RealCID`
- `Dim_Position.CID = Dim_Customer.RealCID`

### 5.3 Source Chain

```
Production Microservices                    DWH Staging                         Synapse DWH
──────────────────────                    ──────────                         ───────────
Customer.CustomerStatic          →  etoro_Customer_Customer            ─┐
BackOffice.Customer              →  etoro_BackOffice_Customer          ─┤
History.Customer                 →  etoro_History_Customer             ─┤
History.BackOfficeCustomer       →  etoro_History_BackOfficeCustomer   ─┤  

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Mirror` — synapse
- **Resolved as**: `DWH_dbo.Dim_Mirror`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md`

# DWH_dbo.Dim_Mirror

> 11.1M-row copy-trading relationship dimension table tracking every CopyTrader, CopyMe (Popular Investor), Smart Portfolio, and Fund mirror relationship from 2011 to present -- capturing the copier (CID), the copied person (ParentCID), investment amount, open/close dates, risk settings, and financial performance for each copy relationship.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Mirror (active) + etoro.History.Mirror (closed) + etoro.BackOffice.Customer (IsCopyFundMirror) |
| **Refresh** | Daily (incremental differential -- never truncated) |
| | |
| **Synapse Distribution** | HASH (MirrorID) |
| **Synapse Index** | CLUSTERED INDEX (OpenDateID ASC, MirrorID ASC) + 2 NC indexes (OpenOccurred, ParentCID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` |
| **UC Format** | delta |
| **UC Partitioned By** | None (Override export; suggest partition by OpenDateID year) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Mirror` is the DWH's primary record of all copy-trading relationships on the eToro platform. A "mirror" is the connection established when Customer A (the copier, `CID`) chooses to copy Customer B (the copied person, `ParentCID`/`ParentUserName`). Once established, trades opened by B are automatically mirrored proportionally in A's account, scaled to the mirror's `Amount`.

The table covers the full history of eToro's social trading product from its earliest CopyTrader relationships in 2011 through the present. It holds 11,145,368 rows across four mirror types: Regular copy (85.2%), Fund mirrors (14.1%), CopyMe/Popular Investor (0.7%), and Smart Portfolio/Social Index (0.001%).

**ETL pattern**: Incremental daily differential. The SP (`SP_Dim_Mirror_DL_To_Synapse`) merges updates from two staging sources:
1. `etoro_Trade_Mirror` -- real-time active mirrors (open positions)
2. `etoro_History_Mirror` -- historical/closed mirrors (close events with final P&L)

Rows are never deleted from Dim_Mirror (except for same-day re-processing). The `CloseDateID=0` / `CloseOccurred='1900-01-01'` sentinel marks currently open mirrors.

---

## 2. Business Logic

### 2.1 Open vs. Closed Mirror Sentinel

**What**: A mirror may be open (still actively copying) or closed. The SP uses sentinel values to distinguish open mirrors from closed ones.

**Columns Involved**: `CloseOccurred`, `CloseDateID`, `IsActive`

**Rules**:
- **Open mirror**: `CloseDateID = 0`, `CloseOccurred = '1900-01-01 00:00:00'`. This is the active sentinel -- the copier is still copying.
- **Closed mirror**: `CloseDateID > 0`, `CloseOccurred` = actual close datetime. The copier stopped copying.
- **IsActive**: Production flag from Trade.Mirror / History.Mirror. Can be 0 for rows where `CloseDateID=0` (e.g., paused or deactivated but not formally closed). Do not rely on IsActive alone for open/closed filtering -- use `CloseDateID = 0`.
- **For filtering active mirrors**: `WHERE CloseDateID = 0` (669,921 currently open: 468,911 Regular + 9 CopyMe + 201,001 Fund)

### 2.2 Dual-Source ETL (Real vs. History)

**What**: Open mirrors come from `Trade.Mirror` (real-time system table); closed mirrors come from `History.Mirror` (event log). The daily SP merges both.

**Rules**:
- `etoro_Trade_Mirror` provides the current state of each open mirror (IsActive, Amount, risk settings, running P&L).
- `etoro_History_Mirror MirrorOperationID=2` provides close events (CloseOccurred, CloseDateID, RealziedPnL at close).
- `etoro_History_Mirror MirrorOperationID=1` provides open events (SessionID at open time).
- When a mirror appears in both History (closed today) and Real (still shown as open), History takes precedence (duplicates removed).
- Close dates with CloseOccurred >= today are treated as still-open and get sentinel values (1900-01-01, CloseDateID=0).

### 2.3 IsCopyFundMirror Derivation

**What**: `IsCopyFundMirror` identifies mirrors where the copied entity is an eToro-managed fund account, not a regular customer.

**Rule**: `IsCopyFundMirror = 1` when `ParentCID` is in `etoro_BackOffice_Customer WHERE AccountTypeID = 9` (Fund account type). NULL/0 for regular customer-to-customer copies. Fund mirrors are a distinct product from the Regular CopyTrader relationship.

### 2.4 RealziedPnL Typo

**What**: The column `RealziedPnL` contains the realized profit/loss for the mirror (net profit at close). The column name has a persistent typo ("Realzied" instead of "Realized") that exists in both the DDL and the SP.

**Rule**: This column is populated from `History.Mirror.NetProfit` at close time. For open mirrors, it reflects the running net profit at the last SP update. Always reference as `RealziedPnL` (with the typo) in queries -- the DDL name is authoritative.

### 2.5 MirrorSL and Risk Controls

**What**: Copy-trading relationships can have a stop-loss that automatically closes the mirror if losses exceed a threshold.

**Columns Involved**: `MirrorSL`, `MirrorSLPercentage`, `PauseCopy`

**Rules**:
- `MirrorSL`: Stop-loss amount in absolute USD terms. Mirror closes if cumulative loss reaches this amount.
- `MirrorSLPercentage`: Stop-loss as percentage of `InitialInvestment`. A setting of 40 means "close mirror if I lose 40% of my initial investment".
- `PauseCopy`: 1 if the copier has paused the copy (no new trades are mirrored). Paused copies are still open (CloseDateID=0) but not actively mirroring new trades.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH(MirrorID)**: MirrorID is the distribution key. JOINs on MirrorID are co-located (no shuffle). JOINs on CID, ParentCID, or OpenDateID may require broadcast/shuffle -- consider the fact table's distribution when planning multi-table JOINs.

**CLUSTERED INDEX (OpenDateID, MirrorID)**: Optimized for date-filtered queries on OpenDateID + MirrorID lookup. The two NC indexes support:
- `IX_Dim_Mirror`: OpenOccurred scans (datetime-based open date filtering)
- `IX_Dim_Mirror_ParentCID`: ParentCID lookups (find all copiers of a given Popular Investor)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count currently active copy relationships | `WHERE CloseDateID = 0 AND MirrorTypeID = 1` |
| Find all copiers of a specific Popular Investor | `WHERE ParentCID = X AND MirrorTypeID IN (1, 2)` |
| Mirror P&L attribution | `JOIN Dim_Mirror ON MirrorID; SELECT RealziedPnL, InitialInvestment` |
| Date-range analysis of new copy relationships | `WHERE OpenDateID BETWEEN 20250101 AND 20250131` |
| Identify copies with stop-loss set | `WHERE MirrorSL > 0 OR MirrorSLPercentage > 0` |
| Find paused copies | `WHERE PauseCopy = 1 AND CloseDateID = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_MirrorType | `ON MirrorTypeID` | Get copy type name (Regular, CopyMe, Social Index, Fund) |
| DWH_dbo.Dim_Date | `ON OpenDateID` or `CloseDateID` | Calendar metadata for open/close dates |
| CustomerStatic (or similar) | `ON CID` | Copier customer details |
| CustomerStatic | `ON ParentCID` | Copied person (Popular Investor) details |

### 3.4 Gotchas

- **CloseOccurred='1900-01-01' = open mirror**: Do NOT interpret this as a historical date. It is the ETL sentinel for "not yet closed". Filter `WHERE CloseDateID = 0` for open mirrors.
- **RealziedPnL has a typo**: Column name is `RealziedPnL` (not `RealizedPnL`). This is the authoritative DDL name -- use the typo in queries.
- **IsActive is not a reliable closed indicator**: Use `CloseDateID = 0` for "is open". IsActive can be 0 for open-but-paused mirrors.
- **11.1M rows, never truncated**: Full table scans are expensive. Always filter on `OpenDateID` (clustered key) or `MirrorID` (distribution/hash key) for efficient queries.
- **MirrorTypeID=3 (Social Index) only 122 rows**: This product type has minimal representation -- likely a legacy or very limited product.
- **IsCopyFundMirror NULL vs 0**: The column can be NULL (not set in older rows) or 0/1. `ISNULL(IsCopyFundMirror, 0) = 1` for fund mirror filtering.
- **SessionID NULL for old rows**: The SessionID column was added later; historical mirrors (pre-2011 to early 2020s) may have NULL SessionID.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Mirror_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MirrorID | int | NO | Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. (Tier 1 — Trade.Mirror) |
| 2 | CID | int | NO | Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. (Tier 1 — Trade.Mirror) |
| 3 | ParentCID | int | YES | Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 — Trade.Mirror) |
| 4 | ParentUserName | varchar(50) | YES | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 — Trade.Mirror) |
| 5 | Amount | numeric(16,8) | YES | Allocation amount in dollars. Credit allocated to this mirror. Trade.RegisterMirror sets from @AmountInCents/100. (Tier 1 — Trade.Mirror) |
| 6 | OpenOccurred | datetime | YES | Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch). (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 7 | OpenDateID | int | YES | yyyymmdd integer of OpenOccurred. Clustered index key -- use for efficient date-range filtering. ETL-computed: `convert(int, convert(varchar, dateadd(day, datediff(day, 0, Occurred), 0), 112))`. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 8 | CloseOccurred | datetime | YES | Datetime the copy relationship was closed. '1900-01-01 00:00:00' sentinel = still open (CloseDateID=0). For closed mirrors, this is History.Mirror.ModificationDate at the close event. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 9 | CloseDateID | int | YES | yyyymmdd integer of CloseOccurred. 0 = open mirror (active); > 0 = closed on that date. Primary filter for open/closed status. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 10 | MirrorTypeID | int | YES | 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. (Tier 1 — Trade.Mirror) |
| 11 | CloseMirrorActionType | int | YES | Why mirror closed: 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach (Dictionary.CloseMirrorActionType). NULL when active. (Tier 1 — Trade.Mirror) |
| 12 | IsActive | tinyint | YES | 1=mirror is live (copier follows leader), 0=mirror closed. Trade.ChangeMirrorState, Trade.PostClosePositionActions update. (Tier 1 — Trade.Mirror) |
| 13 | IsOpenOpen | bit | YES | Flag for open-on-open copy behavior. NULL in sample data. Used by copy logic. (Tier 1 — Trade.Mirror) |
| 14 | PauseCopy | bit | YES | 0=copying, 1=paused. No new positions when paused. Trade.MirrorPauseCopy updates. (Tier 1 — Trade.Mirror) |
| 15 | MirrorSL | money | YES | Absolute mirror stop-loss threshold in dollars. Trade.RegisterMirror validates against MirrorSLPercentage. (Tier 1 — Trade.Mirror) |
| 16 | MirrorSLPercentage | money | YES | MSL as percentage. Default 2. Trade.RegisterMirror validates MirrorSL = Amount * (MirrorSLPercentage/100). (Tier 1 — Trade.Mirror) |
| 17 | RealizedEquity | money | YES | Realized equity for this mirror. Used with MirrorCalculationType=0 for MSL. Updated on position close. (Tier 1 — Trade.Mirror) |
| 18 | InitialInvestment | money | YES | Initial allocation. Trade.RegisterMirror sets from @AmountInDollars or @InitialInvestment. (Tier 1 — Trade.Mirror) |
| 19 | WithdrawalSummary | money | YES | Sum of withdrawals from mirror. (Tier 1 — Trade.Mirror) |
| 20 | DepositSummary | money | YES | Sum of deposits into mirror. Trade.RegisterMirror accepts from caller. (Tier 1 — Trade.Mirror) |
| 21 | RealziedPnL | money | YES | Net realized profit/loss of the mirror in USD. NOTE: column name has a typo ('Realzied' not 'Realized') — use exact spelling in queries. For closed mirrors: final P&L from History.Mirror.NetProfit. For open mirrors: running net profit. Upstream: DWH column RealziedPnL maps to Trade.Mirror.NetProfit. (Tier 1 — Trade.Mirror) |
| 22 | GuruTPV | money | YES | Guru/leader take-profit value. NULL in sample. Optional override. (Tier 1 — Trade.Mirror) |
| 23 | UseCopyDividend | tinyint | YES | 1=copy dividends to copier, 0=do not. Trade.MirrorDividendWithdrawal checks. (Tier 1 — Trade.Mirror) |
| 24 | UpdateDate | datetime | YES | ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 25 | SessionID | bigint | YES | Session identifier from History.Mirror.SessionID at the mirror open event (MirrorOperationID=1). Links the mirror opening to a specific trading session. NULL for older historical mirrors predating SessionID tracking. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |
| 26 | IsCopyFundMirror | int | YES | 1 if the ParentCID is an eToro Fund account (BackOffice AccountTypeID=9); 0 or NULL for regular customer-to-customer copies. Derived post-load from BackOffice_Customer data. Fund mirrors (IsCopyFundMirror=1) overlap with MirrorTypeID=4. (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| MirrorID | etoro.Trade.Mirror | MirrorID | passthrough |
| CID | etoro.Trade.Mirror | CID | passthrough |
| ParentCID | etoro.Trade.Mirror | ParentCID | passthrough |
| ParentUserName | etoro.Trade.Mirror | ParentUserName | passthrough |
| Amount | etoro.Trade.Mirror | Amount | passthrough (updated from History) |
| OpenOccurred | etoro.Trade.Mirror | Occurred | rename (open event timestamp) |
| OpenDateID | etoro.Trade.Mirror | Occurred | ETL-computed: yyyymmdd integer |
| CloseOccurred | etoro.History.Mirror | ModificationDate | passthrough (close event); '1900-01-01' sentinel for open |
| CloseDateID | etoro.History.Mirror | ModificationDate | ETL-computed: yyyymmdd integer; 0 for open |
| MirrorTypeID | etoro.Trade.Mirror | MirrorTypeID | passthrough |
| CloseMirrorActionType | etoro.Trade.Mirror | CloseMirrorActionType | passthrough |
| IsActive | etoro.Trade.Mirror | IsActive | passthrough |
| IsOpenOpen | etoro.Trade.Mirror | IsOpenOpen | passthrough |
| PauseCopy | etoro.Trade.Mirror | PauseCopy | passthrough |
| MirrorSL | etoro.Trade.Mirror | MirrorSL | passthrough |
| MirrorSLPercentage | etoro.Trade.Mirror | MirrorSLPercentage | passthrough |
| RealizedEquity | etoro.Trade.Mirror | RealizedEquity | passthrough |
| InitialInvestment | etoro.Trade.Mirror | InitialInvestment | passthrough |
| WithdrawalSummary | etoro.Trade.Mirror | WithdrawalSummary | passthrough |
| DepositSummary | etoro.Trade.Mirror | DepositSummary | passthrough |
| RealziedPnL | etoro.History.Mirror | NetProfit | rename (at close); running value from Trade.Mirror otherwise |
| GuruTPV | etoro.Trade.Mirror | GuruTPV | passthrough |
| UseCopyDividend | etoro.Trade.Mirror | UseCopyDividend | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| SessionID | etoro.History.Mirror (MirrorOperationID=1) | SessionID | post-load UPDATE (open event session) |
| IsCopyFundMirror | etoro.BackOffice.Customer (AccountTypeID=9) | CID membership | ETL-computed: 1 if ParentCID in Fund accounts |

### 5.2 ETL Pipeline

```
etoro.Trade.Mirror (active, etoroDB-REAL)
etoro.History.Mirror (events, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_Mirror      (real/open mirrors)
DWH_staging.etoro_History_Mirror    (closed mirror events)
DWH_staging.etoro_BackOffice_Customer (AccountTypeID=9, for IsCopyFundMirror)
  |-- SP_Dim_Mirror_DL_To_Synapse @dt (incremental MERGE, daily) ---|
    1. Delete/reset yesterday's rows
    2. Load Ext_Dim_Mirror_Real from etoro_Trade_Mirror
    3. Load Ext_Dim_Mirror_History from etoro_History_Mirror (MirrorOperationID=2, close events)
    4. UPDATE + INSERT from History (existing open mirrors closed today)
    5. Set IsCopyFundMirror from Fund CIDs
    6. Remove Real duplicates also in History (History takes precedence)
    7. MERGE Ext_Dim_Mirror_Real -> Dim_Mirror (UPDATE open + INSERT new)
    8. UPDATE SessionID from History (MirrorOperationID=1, open events)
  v
DWH_dbo.Dim_Mirror  (11,145,368 rows; incremental, never fully truncated)
  |-- Generic Pipeline (Override, 1440min, delta) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Mirror/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MirrorTypeID | DWH_dbo.Dim_MirrorType | Copy relationship type (Regular, CopyMe, Social Index, Fund) |
| CID | Customer dimension | Copier customer |
| ParentCID | Customer dimension | Copied person / Popular Investor / Fund |
| OpenDateID | DWH_dbo.Dim_Date | Calendar date of mirror open event |
| CloseDateID | DWH_dbo.Dim_Date | Calendar date of mirror close event |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH fact tables | MirrorID | Copy-trading-related fact tables join on MirrorID for relationship context |
| DWH_dbo.SP_Dim_Mirror_DL_To_Synapse | (loads this table) | Complex incremental ETL SP |

---

## 7. Sample Queries

### 7.1 Find all currently active Regular CopyTrader relationships

```sql
SELECT
    m.MirrorID,
    m.CID,
    m.ParentCID,
    m.ParentUserName,
    m.Amount,
    m.OpenOccurred,
    m.RealziedPnL,
    m.PauseCopy
FROM [DWH_dbo].[Dim_Mirror] m
WHERE m.CloseDateID = 0
  AND m.MirrorTypeID = 1
ORDER BY m.Amount DESC;
```

### 7.2 Get all copiers of a specific Popular Investor

```sql
SELECT
    m.MirrorID,
    m.CID,
    m.Amount,
    m.OpenOccurred,
    m.CloseOccurred,
    m.RealziedPnL,
    mt.MirrorTypeName
FROM [DWH_dbo].[Dim_Mirror] m
JOIN [DWH_dbo].[Dim_MirrorType] mt ON m.MirrorTypeID = mt.MirrorTypeID
WHERE m.ParentCID = 818634   -- example Popular Investor CID
ORDER BY m.OpenOccurred;
```

### 7.3 Monthly new copy relationships by type

```sql
SELECT
    m.OpenDateID / 100 AS YearMonth,
    mt.MirrorTypeName,
    COUNT(DISTINCT m.MirrorID) AS NewMirrors,
    SUM(m.InitialInvestment) AS TotalInitialInvestment
FROM [DWH_dbo].[Dim_Mirror] m
JOIN [DWH_dbo].[Dim_MirrorType] mt ON m.MirrorTypeID = mt.MirrorTypeID
WHERE m.OpenDateID BETWEEN 20250101 AND 20251231
GROUP BY m.OpenDateID / 100, mt.MirrorTypeName
ORDER BY YearMonth, mt.MirrorTypeName;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 9.0/10 (★★★★★) | Phases: 10/14*
*Tiers: 19 T1, 7 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 26/26, Logic: 10/10, Relationships: 9/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Mirror | Type: Table | Production Source: etoro.Trade.Mirror + etoro.History.Mirror*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_MarketingCloudUserBehavior`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_MarketingCloudUserBehavior.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_MarketingCloudUserBehavior] @date [DATE] AS
/********************************************************************************************
Author:      Katy F
Date:        2023-08-31
Description: MarketingCloud UserBehavior Daily DataSet to be uploaded to SFTP
 
**************************
** Change History
**************************
Date		  Author       Description   
----------    ----------   ------------------------------------
2023-08-31     Katy F       Create SP. Migrated from AZR-WE-DWH-01.[SalesForce_DB_Prod].[dbo].[SP_UserBehavior]

*********************************************************************************************/

BEGIN
--/*

--declare @date DATE = '20231101'

--*/
DECLARE @DateID INT = CONVERT(VARCHAR(8),@date,112)

DECLARE @DeleteDate INT = CONVERT(VARCHAR(8), DATEADD(M,-1,CAST(GETDATE() AS DATE)),112) 

DELETE [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument]
WHERE DateID < @DeleteDate

DELETE [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
WHERE DateID < @DeleteDate

------- Instrument -------

   IF OBJECT_ID('tempdb..#Instrument') IS NOT NULL DROP TABLE #Instrument
    CREATE TABLE #Instrument
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
    AS
SELECT a.RealCID
,a.InstrumentID 
,di.SymbolFull  InstrumentName
,di.InstrumentTypeID
,MAX(a.Occurred) LastVisit 
,DateID
FROM  DWH_pagetracking.[Fact_MarketPageViews]  a  With(nolock) 
inner JOIN DWH_dbo.Dim_Instrument di  With(nolock)  ON a.InstrumentID = di.InstrumentID
where DateID = @DateID 
group by a.RealCID,a.InstrumentID ,di.SymbolFull ,di.InstrumentTypeID, DateID


IF OBJECT_ID('tempdb..#dp_AmountInvestInstrument') IS NOT NULL DROP TABLE #dp_AmountInvestInstrument
CREATE TABLE #dp_AmountInvestInstrument
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  
dp.CID
,dp.InstrumentID
,MAX(dp.OpenDateID) LastOpen 
,SUM(CASE WHEN LEFT(dp.OpenDateID,6)=CONVERT(VARCHAR(6),GETDATE(),112) THEN dp.Amount ELSE 0 END) LastMonthAmountInvest
,SUM(CASE WHEN LEFT(dp.OpenDateID,6)=CONVERT(VARCHAR(6),GETDATE(),112) THEN 1 ELSE 0 END) LastMonthOpenPositionsInvest
,SUM(dp.Amount) TotalAmountInvest
,COUNT(dp.PositionID) TotalPositionsInvest
FROM #Instrument ins
inner JOIN DWH_dbo.Dim_Position dp  With(nolock ) ON dp.InstrumentID = ins.InstrumentID and dp.CID=ins.RealCID
WHERE dp.MirrorID=0 
GROUP BY dp.CID,dp.InstrumentID


IF OBJECT_ID('tempdb..#dpAssetInstrument') IS NOT NULL DROP TABLE #dpAssetInstrument
CREATE TABLE #dpAssetInstrument
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT dp.CID
,di.InstrumentTypeID
,COUNT(CASE WHEN dp.CloseDateID=0 THEN dp.PositionID END)OpenActiveInstruments
,SUM(dp.Amount) AssetAmount
,COUNT(*)AssetPositions
FROM (select distinct RealCID from #Instrument)  cid
inner join DWH_dbo.Dim_Position dp  With(nolock ) on dp.CID=cid.RealCID
inner join DWH_dbo.Dim_Instrument di  With(nolock)  ON dp.InstrumentID=di.InstrumentID
WHERE dp.MirrorID=0 
GROUP BY dp.CID,di.InstrumentTypeID

IF OBJECT_ID('tempdb..#InstrumentResults') IS NOT NULL DROP TABLE #InstrumentResults
CREATE TABLE #InstrumentResults
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
select 
ins.RealCID CID
,ins.InstrumentID 
,ins.InstrumentTypeID 
,ins.InstrumentName
,ins.LastVisit 
,CONVERT(date, CONVERT(varchar(8), dai.LastOpen), 112)  LastOpen
,dai.LastMonthAmountInvest
,dai.LastMonthOpenPositionsInvest
,dai.TotalAmountInvest
,dai.TotalPositionsInvest
,da.OpenActiveInstruments
,da.AssetAmount
,da.AssetPositions
,DateID
from #Instrument ins
inner join #dp_AmountInvestInstrument dai on dai.InstrumentID = ins.InstrumentID and dai.CID=ins.RealCID
inner join #dpAssetInstrument da ON da.CID=ins.RealCID AND da.InstrumentTypeID=ins.InstrumentTypeID



---------------------------------

update a
set
InstrumentName = i.InstrumentName
,InstrumentTypeID =i.InstrumentTypeID
,LastVisit = i.LastVisit 
,LastOpen = i.LastOpen
,LastMonthAmountInvest = i.LastMonthAmountInvest
,LastMonthOpenPositionsInvest = i.LastMonthOpenPositionsInvest
,TotalAmountInvest=i.TotalAmountInvest
,TotalPositionsInvest=i.TotalPositionsInvest
,OpenActiveInstruments=i.OpenActiveInstruments
,AssetAmount=i.AssetAmount
,AssetPositions=i.AssetPositions
,DateID=i.DateID
,UpdateDate = GETDATE()

from [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument] a
join #InstrumentResults i ON a.CID=i.CID and a.InstrumentID =i.InstrumentID 
where 
ISNULL( a.InstrumentName,'') <> ISNULL(i.InstrumentName,'')
or ISNULL(a.LastVisit,'1900-01-01') <> ISNULL(i.LastVisit ,'1900-01-01')
or ISNULL(a.LastOpen,'1900-01-01') <> ISNULL(i.LastOpen,'1900-01-01')
or ISNULL(a.LastMonthAmountInvest,0) <>ISNULL(i.LastMonthAmountInvest,0)
or ISNULL(a.LastMonthOpenPositionsInvest,0) <>ISNULL(i.LastMonthOpenPositionsInvest,0)
or ISNULL(a.TotalAmountInvest,0) <> ISNULL(i.TotalAmountInvest,0)
or ISNULL(a.TotalPositionsInvest,0)<> ISNULL(i.TotalPositionsInvest,0)
or ISNULL(a.OpenActiveInstruments,0) <> ISNULL(i.OpenActiveInstruments,0)
or ISNULL(a.AssetAmount,0) <> ISNULL(i.AssetAmount,0)
or ISNULL(a.AssetPositions,0) <> ISNULL(i.AssetPositions,0)

INSERT INTO [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument] 
(CID,InstrumentID,InstrumentTypeID,
InstrumentName,LastVisit,LastOpen,LastMonthAmountInvest,LastMonthOpenPositionsInvest,TotalAmountInvest,TotalPositionsInvest,OpenActiveInstruments,AssetAmount,AssetPositions,DateID, UpdateDate)

select  CID,InstrumentID,InstrumentTypeID
,InstrumentName,LastVisit
,LastOpen,LastMonthAmountInvest,LastMonthOpenPositionsInvest
,TotalAmountInvest,TotalPositionsInvest,OpenActiveInstruments,AssetAmount,AssetPositions,DateID 
,GETDATE()
from #InstrumentResults ir
WHERE NOT EXISTS (SELECT NULL FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument] WHERE CID=ir.CID and  InstrumentID =ir.InstrumentID )

UPDATE a
SET AccountId = idmt.SalesForceAccountID
,UpdateDate = GETDATE()
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument] a
	JOIN DWH_dbo.Dim_Customer idmt 
		ON a.CID = idmt.RealCID 
WHERE AccountId IS NULL


------- PI -------

   IF OBJECT_ID('tempdb..#PI') IS NOT NULL DROP TABLE #PI
    CREATE TABLE #PI
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
    AS

SELECT 
fupv.RealCID 
,dc.UserName as UserPI
,CIDViewed 
,MAX(fupv.Occurred) LastVisit
,DateID 
from DWH_pagetracking.[Fact_UserPageViews] fupv  With(nolock)  
inner JOIN DWH_dbo.Dim_Customer dc  With(nolock) ON fupv.CIDViewed=dc.RealCID
where DateID = @DateID
group by fupv.RealCID,dc.UserName,CIDViewed, DateID



   IF OBJECT_ID('tempdb..#dp_AmountInvestPI') IS NOT NULL DROP TABLE #dp_AmountInvestPI
    CREATE TABLE #dp_AmountInvestPI
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

    AS
SELECT dp.CID, dm.ParentCID
,MAX(dm.OpenDateID) LastOpen
,SUM(case when LEFT(dp.OpenDateID,6)=CONVERT(VARCHAR(6),GETDATE(),112) then dp.Amount else 0 end) LastMonthAmountInvest
,SUM(case when LEFT(dp.OpenDateID,6)=CONVERT(VARCHAR(6),GETDATE(),112) then 1 else 0 end) LastMonthOpenPositionsInvest
,dm.RealizedEquity TotalAmountInvest
,COUNT(dp.PositionID) TotalPositionsInvest
,COUNT(CASE WHEN dp.CloseDateID=0 THEN dp.PositionID END)OpenActiveInstruments
FROM #PI 
inner join DWH_dbo.Dim_Position dp  With(nolock) on  dp.CID=#PI.RealCID 
inner join DWH_dbo.Dim_Mirror dm  With(nolock) ON dp.MirrorID = dm.MirrorID AND dp.CID = dm.CID
GROUP BY dp.CID,dm.ParentCID, dm.RealizedEquity

   IF OBJECT_ID('tempdb..#dpAssetPI ') IS NOT NULL DROP TABLE #dpAssetPI 
    CREATE TABLE #dpAssetPI 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
    AS
SELECT aip.CID, aip.ParentCID,
MAX(aip.LastOpen)LastOpen,
SUM(aip.LastMonthAmountInvest)LastMonthAmountInvest,
SUM(aip.LastMonthOpenPositionsInvest)LastMonthOpenPositionsInvest,
SUM(aip.TotalPositionsInvest)TotalPositionsInvest,
SUM(aip.OpenActiveInstruments)OpenActiveInstruments,
SUM(TotalAmountInvest)TotalAmountInvest
FROM #dp_AmountInvestPI aip 
GROUP BY aip.CID, aip.ParentCID


   IF OBJECT_ID('tempdb..#PIResults') IS NOT NULL DROP TABLE #PIResults	
    CREATE TABLE #PIResults	 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
    AS
SELECT  p.RealCID CID 
		,p.CIDViewed 
       ,p.UserPI 
       ,p.LastVisit
       ,CONVERT(date, CONVERT(varchar(8), ap.LastOpen), 112) LastOpen
       ,ap.LastMonthAmountInvest
	   ,ap.LastMonthOpenPositionsInvest
       ,ap.TotalAmountInvest 
       ,ap.TotalPositionsInvest 
	   ,ap.OpenActiveInstruments
	   ,DateID
from  #PI p
inner join #dpAssetPI  ap on p.RealCID =ap.CID  AND ap.ParentCID=p.CIDViewed
  
-----------------------
update a
set
UserPI = p.UserPI
,LastVisit = p.LastVisit 
,LastOpen = p.LastOpen
,LastMonthAmountInvest = p.LastMonthAmountInvest
,LastMonthOpenPositionsInvest = p.LastMonthOpenPositionsInvest
,TotalAmountInvest=p.TotalAmountInvest
,TotalPositionsInvest=p.TotalPositionsInvest
,OpenActiveInstruments=p.OpenActiveInstruments
,DateID=p.DateID
,UpdateDate = GETDATE()
from [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI] a
join #PIResults p ON a.CID=p.CID and a.CIDViewed=p.CIDViewed
where 
ISNULL(a.LastVisit,'1900-01-01') <> ISNULL(p.LastVisit ,'1900-01-01')
or ISNULL(a.LastOpen,'1900-01-01') <> ISNULL(p.LastOpen,'1900-01-01')
or ISNULL(a.LastMonthAmountInvest,0) <>ISNULL(p.LastMonthAmountInvest,0)
or ISNULL(a.LastMonthOpenPositionsInvest,0) <>ISNULL(p.LastMonthOpenPositionsInvest,0)
or ISNULL(a.TotalAmountInvest,0) <> ISNULL(p.TotalAmountInvest,0)
or ISNULL(a.TotalPositionsInvest,0)<> ISNULL(p.TotalPositionsInvest,0)
or ISNULL(a.OpenActiveInstruments,0) <> ISNULL(p.OpenActiveInstruments,0)


INSERT INTO [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI] (CID,
UserPI,LastVisit
,LastOpen,LastMonthAmountInvest,LastMonthOpenPositionsInvest
,TotalAmountInvest,TotalPositionsInvest,OpenActiveInstruments
,DateID,CIDViewed, UpdateDate)

SELECT  CID 
,UserPI,LastVisit
,LastOpen,LastMonthAmountInvest,LastMonthOpenPositionsInvest
,TotalAmountInvest,TotalPositionsInvest,OpenActiveInstruments
,DateID  ,CIDViewed
,GETDATE()
from #PIResults pr
WHERE NOT EXISTS (SELECT NULL FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI] WHERE CID=pr.CID and CIDViewed=pr.CIDViewed)


UPDATE a
SET AccountId = idmt.SalesForceAccountID
,UpdateDate = GETDATE()
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI] a
	JOIN DWH_dbo.Dim_Customer idmt 
		ON a.CID = idmt.RealCID 
WHERE AccountId IS NULL

-------------------------------------------------------------------------


END /* END SP */


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_MarketingCloudUserBehavior` | synapse_sp | BI_DB_dbo | SP_MarketingCloudUserBehavior | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_MarketingCloudUserBehavior.sql` |
| `DWH_pagetracking.Fact_MarketPageViews` | unresolved | DWH_pagetracking | Fact_MarketPageViews | `—` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_pagetracking.Fact_UserPageViews` | unresolved | DWH_pagetracking | Fact_UserPageViews | `—` |
| `DWH_dbo.Dim_Mirror` | synapse | DWH_dbo | Dim_Mirror | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI` | unresolved | BI_DB_dbo | BI_DB_MarketingCloudUserBehaviorPI | `—` |

