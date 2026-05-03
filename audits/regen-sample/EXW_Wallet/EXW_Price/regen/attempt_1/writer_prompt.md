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

- **Schema**: `EXW_Wallet`
- **Object**: `EXW_Price`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/EXW_Wallet/EXW_Price/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_Wallet\EXW_Price\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_Wallet\EXW_Price\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Tables\EXW_Wallet.EXW_Price.sql`
- **No-upstream marker present**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_Wallet\EXW_Price\regen\_no_upstream_found.txt` — object is dormant or has no resolvable upstream wiki. Footer may say `Production Source: Unknown (dormant)`. Tier 4 inferred is STILL banned — ground every column description in DDL + SP code.

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

# Pre-Resolved Upstream Bundle for `EXW_Wallet.EXW_Price`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.EXW_Price.sql`

```sql
CREATE TABLE [EXW_Wallet].[EXW_Price]
(
	[InstrumentID] [int] NULL,
	[eToroInstrumentID] [int] NULL,
	[CryptoID] [int] NULL,
	[CryptoName] [varchar](50) NULL,
	[AskLast] [decimal](38, 8) NULL,
	[BidLast] [decimal](38, 8) NULL,
	[AvgPrice] [decimal](38, 8) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [varchar](50) NULL,
	[FullDate] [date] NULL,
	[FullDateID] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateFrom] ASC,
		[CryptoID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `EXW_Wallet.SP_Prices`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_Prices.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [EXW_Wallet].[SP_Prices] @dt [DATE] AS

BEGIN
/***************map wallet instrument to etoro instrument and cryptoid***************************/
--SELECT MAX(FullDate) FROM EXW_Wallet.EXW_PriceDaily  2023-11-30


--DECLARE @dt DATE = '20231130'
IF OBJECT_ID('tempdb..#mapping') IS NOT NULL    DROP TABLE #mapping
CREATE TABLE #mapping
(
             InstrumentID   INT NULL
			,eToroInstrumentID  INT NULL
			,CryptoId  INT NULL
			,CryptoName   NVARCHAR(128) Null
			,BlockchainCryptoId  INT NULL
			,BlockchainCryptoName   NVARCHAR(128) Null
)

INSERT INTO #mapping
 
SELECT DISTINCT 
             i.Id AS InstrumentID
			,dct.InstrumentId AS eToroInstrumentID
			,cmrm.CryptoId
			,cmrm.MarketRatesCurrencySymbol AS CryptoName
			,dct.BlockchainCryptoId
			,ct1.Name AS BlockchainCryptoName
FROM  [EXW_Currency].[Instruments]  i 
    JOIN [EXW_Currency].[Currencies]  cb ON cb.Id = i.BuyCurrencyId
    JOIN [EXW_Currency].[Currencies]  cs ON cs.Id = i.SellCurrencyId
LEFT JOIN 
	(
	SELECT DISTINCT Id, CryptoId, MarketRatesCurrencySymbol FROM 
	[EXW_Wallet].[CryptoMarketRatesMappings] WITH (NOLOCK)
	) cmrm
	ON cb.Symbol = cmrm.MarketRatesCurrencySymbol
LEFT JOIN [EXW_Wallet].[CryptoTypes] dct WITH (NOLOCK)
	ON cmrm.CryptoId = dct.CryptoID
LEFT JOIN  [EXW_Wallet].[CryptoTypes] ct1  
		ON dct.BlockchainCryptoId = ct1.CryptoID
WHERE 1=1
AND cmrm.CryptoId IS NOT NULL
AND cs.Symbol = 'USD'

--select * from #mapping   order by 1

IF OBJECT_ID('tempdb..#rates') IS NOT NULL  DROP TABLE #rates
CREATE TABLE #rates(
	[InstrumentID] [int] NULL,
	[eToroInstrumentID] [int] NULL,
	[CryptoId] [int] NULL,
	[CryptoName] [varchar](20) NULL,
	[AskLast] [numeric](36, 18) NULL,
	[LastBid] [numeric](36, 18) NULL,
	[AvgPrice] [numeric](38, 19) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [nvarchar](500) NULL,
	[FullDate] [date] NULL,
	[FullDateID] [int] NULL);

INSERT INTO #rates
SELECT irh.InstrumentID
			 ,m.eToroInstrumentID
			,m.CryptoId
			,m.CryptoName
			,irh.AskRateAvg AS AskLast
			,irh.BidRateAvg AS LastBid
			,(irh.BidRateAvg + irh.AskRateAvg) / 2 AS AvgPrice
			,irh.DateHour AS DateFrom
			,DATEADD(HOUR, 1, irh.DateHour) AS DateTo
			,m.BlockchainCryptoId
			,m.BlockchainCryptoName
			,CAST(irh.DateHour AS DATE) AS FullDate
			,CONVERT(VARCHAR(8),irh.DateHour,112) AS FullDateID
FROM EXW_Wallet.ETL_InstrumentRates_ByHour  irh WITH (NOLOCK)
JOIN #mapping m ON irh.InstrumentID = m.InstrumentID
WHERE 1=1
AND DateHour >= @dt AND DateHour < DATEADD(D,1,@dt)

IF OBJECT_ID ('tempdb..#price') IS NOT NULL DROP TABLE #price
CREATE TABLE #price WITH(HEAP, DISTRIBUTION = HASH(CryptoId))
AS

SELECT CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID
									ELSE CryptoId
									END AS InstrumentID
	,CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID
									ELSE CryptoId
									END AS ETL_InstrumentID
	,eToroInstrumentID
	,CryptoId
	,CryptoName
	,AskLast
	,LastBid
	,AvgPrice
	,DateFrom
	,DateTo
	,BlockchainCryptoId
	,BlockchainCryptoName
	,FullDate
	,FullDateID
FROM #rates 
--select * from #price
-------- completing hourly prices (estimated with last price) when there are missing prices from MarketRates -----------

--- create table of full hours since yesterday with no holes -----



IF OBJECT_ID('tempdb..#inst') IS NOT NULL    DROP TABLE #inst
CREATE TABLE #inst     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

AS 
SELECT 
  a.InstrumentID 
, a.eToroInstrumentID
, a.CryptoId
, a.CryptoName
, a.BlockchainCryptoId
, a.BlockchainCryptoName
, a.FullDate
, a.FullDateID
--, ROW_NUMBER() OVER (ORDER BY a.InstrumentID) AS RN
FROM (
          SELECT DISTINCT InstrumentID
		  , eToroInstrumentID
		  , CryptoId
		  , CryptoName
		  , BlockchainCryptoId
		  , BlockchainCryptoName
          , FullDate
		  , FullDateID
		FROM #price
       WHERE FullDate = @dt
		) a
		--select * from #inst
------- populate with datefrom and dateto -----


---create hours table --------------------
 --declare @dt date= '20231127'
IF OBJECT_ID('tempdb..#24hours') IS NOT NULL    DROP TABLE #24hours
CREATE TABLE #24hours
(
 
 FullDate DATE
,FullDateID INT 
,DateFrom DATETIME NULL 
,DateTo DATETIME NULL 
)
 

DECLARE  @dt_i INT = CAST(CONVERT (VARCHAR(8) , @dt, 112 ) AS INT)
DECLARE @date2 DATEtime = @dt
DECLARE @maxdate DATETIME
DECLARE @rn INT = 1
	IF @dt = CAST(GETDATE() AS DATE)
	BEGIN
		SET @maxdate = DATEADD(hour,-1,GETDATE())
	END 
	ELSE 
		BEGIN 
			SET @maxdate = DATEADD(hour,-1,DATEADD(D,1,CAST(@dt AS DATETIME)))

		END  

	-----------------------------------------

INSERT INTO #24hours
 SELECT 
				  @dt
                 ,@dt_i 
                 ,@date2  
                 ,DATEADD(HOUR,1,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,1,@date2)  
                 ,DATEADD(HOUR,2,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,2,@date2)  
                 ,DATEADD(HOUR,3,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,3,@date2)  
                 ,DATEADD(HOUR,4,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,4,@date2)  
                 ,DATEADD(HOUR,5,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,5,@date2)  
                 ,DATEADD(HOUR,6,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,6,@date2)  
                 ,DATEADD(HOUR,7,@date2)  
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,7,@date2)  
                 ,DATEADD(HOUR,8,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,8,@date2)  
                 ,DATEADD(HOUR,9,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,9,@date2)  
                 ,DATEADD(HOUR,10,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,10,@date2)  
                 ,DATEADD(HOUR,11,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,11,@date2)  
                 ,DATEADD(HOUR,12,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,12,@date2)  
                 ,DATEADD(HOUR,13,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,13,@date2)  
                 ,DATEADD(HOUR,14,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,14,@date2)  
                 ,DATEADD(HOUR,15,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,15,@date2)  
                 ,DATEADD(HOUR,16,@date2) 
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,16,@date2)  
                 ,DATEADD(HOUR,17,@date2)  
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,17,@date2)  
                 ,DATEADD(HOUR,18,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,18,@date2)  
                 ,DATEADD(HOUR,19,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,19,@date2)  
                 ,DATEADD(HOUR,20,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,20,@date2)  
                 ,DATEADD(HOUR,21,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,21,@date2)  
                 ,DATEADD(HOUR,22,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,22,@date2)  
                 ,DATEADD(HOUR,23,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,23,@date2)  
                 ,DATEADD(HOUR,24,@date2)  

WHERE  @date2 <= @maxdate

---cross hours table with instruments


IF OBJECT_ID('tempdb..#allhours') IS NOT NULL    DROP TABLE #allhours
CREATE TABLE #allhours
(
 InstrumentID INT 
,eToroInstrumentID INT
,CryptoId INT
,CryptoName VARCHAR (255)
,BlockchainCryptoId INT  
,BlockchainCryptoName VARCHAR(255)
,FullDate DATE
,FullDateID INT 
,DateFrom DATETIME NULL 
,DateTo DATETIME NULL 
)
 	INSERT INTO #allhours 
                           (
                            InstrumentID  
                           ,eToroInstrumentID 
                           ,CryptoId 
                           ,CryptoName  
                           ,BlockchainCryptoId  
                           ,BlockchainCryptoName 
                           ,FullDate 
                           ,FullDateID 
                           ,DateFrom 
                           ,DateTo
                           )
SELECT
DISTINCT 
 a.InstrumentID 
,a.eToroInstrumentID 
,a.CryptoId 
,a.CryptoName  
,a.BlockchainCryptoId  
,a.BlockchainCryptoName 
,a.FullDate 
,a.FullDateID 
,h.DateFrom
,h.DateTo
FROM #inst a, #24hours h
WHERE a.FullDateID =h.FullDateID

---select * from #allhours
--apply prices to correlated hours ---------
IF OBJECT_ID('tempdb..#pricesprep') IS NOT NULL    DROP TABLE #pricesprep
CREATE TABLE #pricesprep     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
SELECT  
     a.InstrumentID	
	,a.eToroInstrumentID
	,a.CryptoId
	,a.CryptoName
	,AskLast
	,LastBid
	,AvgPrice
	,a.DateFrom
	,a.DateTo
	,a.BlockchainCryptoId
	,a.BlockchainCryptoName
	,a.FullDate
	,a.FullDateID
FROM  #allhours a 
LEFT JOIN #price b ON a.InstrumentID = b.InstrumentID	 AND a.DateFrom = b.DateFrom AND b.DateTo = b.DateTo



IF OBJECT_ID('tempdb..#prices') IS NOT NULL    DROP TABLE #prices
CREATE TABLE #prices     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
SELECT
   a.CryptoId
   ,a.CryptoName
  ,a.InstrumentID
  ,a.eToroInstrumentID
  ,a.BlockchainCryptoId
  ,a.BlockchainCryptoName
  ,a.FullDate
  ,a.FullDateID
  ,a.DateFrom
  ,a.DateTo
  ,a.LastBid  orBid
  ,a.AskLast  orAsk
  ,a.AvgPrice  orAVG
  ,f.AvgPrice
  ,s.AskLast
  ,z.LastBid  
  ,ROW_NUMBER() OVER (PARTITION BY a.CryptoId  ORDER BY DateFrom DESC)Rn
  FROM
    #pricesprep  a
OUTER APPLY
	( SELECT TOP 1 p.AvgPrice
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.AvgPrice IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS f
OUTER APPLY   
	( SELECT TOP 1 p.AskLast
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.AskLast IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS s
OUTER APPLY   
	( SELECT TOP 1 p.LastBid
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.LastBid IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS z
 

---- update missing price from previous values for each InstrumentID ------
IF OBJECT_ID('tempdb..#missing_previous_prices') IS NOT NULL    DROP TABLE #missing_previous_prices
CREATE TABLE #missing_previous_prices     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
	SELECT a.InstrumentID , max(b.DateFrom) DateFrom
		INTO #missing_previous_prices
		FROM #prices a
		JOIN  EXW_Wallet.EXW_Price b
			ON a.InstrumentID = b.InstrumentID
			AND b.DateFrom < CAST(@dt as date)
		WHERE a.AskLast IS NULL
		group by a.InstrumentID



		UPDATE a
		SET AskLast = b.AskLast
		,LastBid = b.BidLast
		,AvgPrice = b.AvgPrice
		FROM #prices a
		JOIN #missing_previous_prices m
			ON m.InstrumentID = a.InstrumentID
		JOIN EXW_Wallet.EXW_Price b
			ON m.InstrumentID = b.InstrumentID
		AND m.DateFrom = b.DateFrom			 
		WHERE a.AskLast IS NULL

---- update price daily ------
--SELECT COUNT(*) , CryptoID  FROM EXW_Wallet.EXW_Price  where  [FullDateID] =20231130 GROUP BY CryptoID HAVING COUNT(*) >24

DELETE FROM EXW_Wallet.EXW_Price
WHERE DateFrom >= @dt AND DateFrom < DATEADD(D,1,@dt)

INSERT INTO EXW_Wallet.EXW_Price ( [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoID]
      ,[CryptoName]
      ,[AskLast]
      ,BidLast
      ,[AvgPrice]
      ,[DateFrom]
      ,[DateTo]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
      ,[UpdateDate])

SELECT [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoId]
      ,CryptoName
      ,[AskLast]
      ,[LastBid]
      ,[AvgPrice]
      ,[DateFrom]
      ,[DateTo]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
	  ,GETDATE()
FROM #prices


----- update price daily -------

DELETE FROM EXW_Wallet.EXW_PriceDaily
WHERE FullDate = @dt

INSERT INTO EXW_Wallet.EXW_PriceDaily ([InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoID]
      ,[CryptoName]
      ,[AvgPrice]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
      ,[UpdateDate])

   SELECT [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoId]
      ,[CryptoName]
      ,[AvgPrice]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
	  ,GETDATE()
FROM  #prices
		WHERE FullDate = @dt
	AND  Rn = 1


END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `EXW_Wallet.SP_Prices` | synapse_sp | EXW_Wallet | SP_Prices | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_Prices.sql` |
| `EXW_Currency.Instruments` | unresolved | EXW_Currency | Instruments | `—` |
| `EXW_Currency.Currencies` | unresolved | EXW_Currency | Currencies | `—` |
| `EXW_Wallet.CryptoMarketRatesMappings` | unresolved | EXW_Wallet | CryptoMarketRatesMappings | `—` |
| `EXW_Wallet.CryptoTypes` | unresolved | EXW_Wallet | CryptoTypes | `—` |
| `EXW_Wallet.ETL_InstrumentRates_ByHour` | unresolved | EXW_Wallet | ETL_InstrumentRates_ByHour | `—` |
| `EXW_Wallet.EXW_PriceDaily` | unresolved | EXW_Wallet | EXW_PriceDaily | `—` |

