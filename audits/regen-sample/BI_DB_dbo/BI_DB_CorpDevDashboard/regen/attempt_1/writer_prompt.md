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

- **Schema**: `BI_DB_dbo`
- **Object**: `BI_DB_CorpDevDashboard`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_CorpDevDashboard/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CorpDevDashboard\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CorpDevDashboard\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_CorpDevDashboard.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CorpDevDashboard`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CorpDevDashboard.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CorpDevDashboard]
(
	[Active_Month] [int] NULL,
	[ActiveDate] [date] NULL,
	[Indicator] [varchar](5) NULL,
	[Region] [varchar](50) NULL,
	[EOM_Club] [varchar](50) NULL,
	[Age] [int] NULL,
	[FirstAction] [varchar](50) NULL,
	[FirstCross] [varchar](50) NULL,
	[Regs] [bigint] NULL,
	[CIDs] [bigint] NULL,
	[EOM_IsFunded] [bigint] NULL,
	[NewFundedAccounts] [bigint] NULL,
	[NewTrades_Copy] [bigint] NULL,
	[NewTrades_Total] [bigint] NULL,
	[Revenue_Currencies] [money] NULL,
	[Revenue_Commodities] [money] NULL,
	[Revenue_Crypto] [money] NULL,
	[Revenue_Equities] [money] NULL,
	[Revenue_Total] [money] NULL,
	[EOM_Equity] [money] NULL,
	[UpdateDate] [datetime] NULL,
	[Actions] [int] NULL,
	[EOM_AUA_Currencies] [money] NULL,
	[EOM_AUA_Commodities] [money] NULL,
	[EOM_AUA_Crypto] [money] NULL,
	[EOM_AUA_Equities] [money] NULL,
	[Total_Deposits] [money] NULL,
	[Total_Cashouts] [money] NULL,
	[Total_PnL] [money] NULL,
	[Liked] [int] NULL,
	[Shared] [int] NULL,
	[WereCopied] [int] NULL,
	[CopiedOther] [int] NULL,
	[MaxFunded] [int] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CIDs] ),
	CLUSTERED INDEX
	(
		[Active_Month] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md`

# BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData

> Monthly per-depositor customer panel — the broadest monthly CRM fact table in BI_DB_dbo. 189 columns covering registration, trading activity, revenue, PnL, equity, copy trading, lifetime accumulators, life-stage classification, and LTV predictions. One row per depositor (IsFunded) per calendar month. 353.8M rows total; 5.87M distinct CIDs; date range 2007-08 to present (oldest data in BI_DB_dbo).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL (see Section 4) |
| **Refresh** | Daily — DELETE WHERE ActiveDate = @BeginOfMonth + INSERT, then 4× POST-INSERT UPDATEs (SP_CID_MonthlyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (ActiveDate ASC, CID ASC) |
| **Row Count** | ~353.8M total; ~5.87M per month-slice (April 2026) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_MonthlyPanel_FullData` is the primary **monthly CRM analytics panel** for all eToro depositors — the widest monthly customer table in BI_DB_dbo. For each customer who is classified as "funded" (IsFunded), it provides a full monthly snapshot of their trading activity, financial position, revenue contribution, lifecycle stage, and accumulated lifetime totals.

The table serves as the central input for:
- **CRM and retention analytics**: Club tier distribution, life-stage transitions (EOM_LSD), churn (IsChurn_ThisM) and win-back (IsWB_ThisM) detection
- **Revenue reporting**: Monthly and lifetime revenue by instrument type and fee category; two revenue total formulas (legacy Revenue_Total and current Revenue_Total_New since 2025)
- **LTV modeling**: Six LTV columns written by a separate SP (`SP_LTV_BI_Actual`) representing 1Y, 3Y, and 8Y lifetime value predictions
- **PnL and equity tracking**: End-of-month equity by asset class and leverage tier
- **Acquisition analytics**: Channel, affiliate, first action, and seniority data from the customer's registration
- **Compliance**: AML last ticket date, IsChurn flag, professional client status

**Population boundary**: Only **funded/depositing customers** are included. Non-depositing registered users are absent. ~5.87M distinct CIDs as of April 2026; earliest CID dates from 2007-08 (oldest data in BI_DB_dbo).

**Instrument taxonomy**: Activity, revenue, PnL, and equity columns are systematically repeated across 6 asset-class families:
- **Copy** — copy-mirror positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** sub-divides four asset classes (Real Stocks, CFD Stocks, Real Crypto, CFD Crypto):
- **Lev1** — 1:1 leverage, IsBuy=1 (long un-leveraged position)
- **LevCFD** — leveraged or short position (CFD-style)

**ACC_ prefix**: Accumulator columns carry a running lifetime total from the customer's first month. Each month's value = current month's metric + prior month's ACC_ value (self-reference pattern). For a customer's first ever month, ACC_ initialises from the current month values only.

**Column evolution**: The SP has been extended many times since 2019. Columns 176–189 (ActiveOpenManual, ActiveOpenWOAirdrop, ActiveOpenWOAirdropManual, EOM_LSD, ActiveOpen_AirDrop, ActiveOpen_Mirror, ActiveOpen_Manual, ActiveOpen_IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, Revenue_Total_New, ACC_Revenue_Total_New, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, Revenue_TicketFeeByPercent) were added 2021–2025. Historical rows pre-dating those additions will show NULL.

---

## 2. Business Logic

### 2.1 EOM_Club — Monthly Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of the calendar month, based on `Dim_PlayerLevel` with a LowBronze/HighBronze split applied within BI_DB_dbo.

**Columns Involved**: `EOM_Club`

**Rules**:
```
EOM_Club =
  WHEN EOM_Equity < 1000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                         → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                      → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split at the $1,000 equity mark. Observed distribution (April 2026): LowBronze 79.6%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOM_Regulation — Regulatory Jurisdiction

**What**: Customer's regulatory entity at end of month, from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`.

**Columns Involved**: `EOM_Regulation`

**Observed values (April 2026)**: CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, FinCEN 1.7%, FSRA 1.5%, ASIC 0.9%, MAS, FINRAONLY, NFA, BVI, NYDFS+FINRA, eToroUS (<1% each).

### 2.3 Active / ActiveOpen / NewTrades Definitions

**Columns Involved**: `Active`, `ActiveOpen`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`, `ActiveOpen_AirDrop`, `NewTrades_*`, `Active_*`, `ActiveOpen_*`

**Rules**:
```
Active = 1       → customer closed ≥1 position this calendar month (any asset class)
ActiveOpen = 1   → CASE WHEN ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1 THEN 1 ELSE 0 END
                   (Or Filizer update 2025-01-06)
ActiveUser = 1   → EOM_Equity > 0 (customer has any equity at month end)
NewTrades_Total  → count of all newly opened positions (across all asset classes) this month
```
Note: `ActiveOpen` is a composite flag. A customer counts as ActiveOpen if they have any open manual, new-mirror, or add-mirror position. Copy-portfolio positions count separately (`ActiveOpen_Copy`, `IsOpen_CopyPortfolio`).

### 2.4 Revenue Taxonomy (Post-2025 Update)

**What**: Two parallel revenue totals exist due to the 2025 fee component expansion by Or Filizer.

**Columns Involved**: `Revenue_Total`, `Revenue_Total_New`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Formulas**:
```
FullCommissions = Revenue_Copy + Revenue_Real_Crypto + Revenue_CFD_Crypto
                + Revenue_Real_Stocks + Revenue_CFD_Stocks + Revenue_FX/Comm/Ind + Revenue_Other
                [sourced from BI_DB_DailyCommisionReport]

Revenue_Total     = FullCommissions only (LEGACY formula — excludes function fees)

Revenue_Total_New = FullCommissions
                  + Revenue_AdminFee (Islamic account admin fee)
                  + Revenue_TicketFees (Function_Revenue_TicketFee)
                  + Revenue_ConversionFees (Function_Revenue_ConversionFee)
                  + Revenue_SpotAdjustFee (Islamic spot adjustment fee)
                  + Revenue_TicketFeeByPercent (Function_Revenue_TicketFeeByPercent)

Revenue_IslamicFees = Revenue_AdminFee + Revenue_SpotAdjustFee
                   [fee components specific to Islamic/swap-free accounts]

Transactional_Revenue_Total = Revenue_Total_New − Revenue_ConversionFees
                             [excludes currency conversion fees; pure transactional/trading revenue]
```
**Guidance**: Use `Revenue_Total_New` for all current reporting. `Revenue_Total` is retained for historical comparability only. `Transactional_Revenue_Total` is used when conversion fee effects should be excluded (e.g., revenue from trading activity only).

### 2.5 ACC_ Column Accumulation Pattern

**What**: Running lifetime totals built by reading the prior month's row from the same table.

**Columns Involved**: All `ACC_*` columns (22 columns)

**Pattern**:
```sql
-- Pseudo-code for each ACC_ column:
ACC_Revenue_Total_New(this_month) =
    Revenue_Total_New(this_month)
  + ISNULL(ACC_Revenue_Total_New FROM same_table WHERE ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth), 0)
```
The prior month's ACC_ value is fetched into temp table `#History` via a SELECT on the same Synapse table. For a customer's first month in the table (no prior row exists), `ACC_` initialises to the current month's value only.

**Important**: Because the current month's row is deleted and re-inserted daily (while the month is open), the `#History` lookup always reads the prior *closed* month. The current month's running total accumulates correctly only when the prior month is locked.

### 2.6 IsChurn_ThisM / IsWB_ThisM — Churn and Win-Back Flags

**What**: Monthly churn and win-back event detection based on IsFunded_New transitions.

**Columns Involved**: `IsChurn_ThisM`, `IsWB_ThisM`, `IsFunded_New`

**Rules** (POST-INSERT UPDATE from #ChurnWB):
```
IsChurn_ThisM = 1   when prior_month.IsFunded_New > 0  AND  this_month.IsFunded_New = 0
IsWB_ThisM    = 1   when prior_month.IsFunded_New = 0  AND  this_month.IsFunded_New > 0
```
The prior month's `IsFunded_New` is read from the already-inserted row for `ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth)`.

### 2.7 Seniority_FundedNew — Adjusted Seniority Since First Funding

**What**: Months since the customer's "new funded" date — a composite date that takes the latest of FTD, first action, and KYC level-3 completion dates, rounded to month start.

**Columns Involved**: `Seniority_FundedNew`, `Seniority`

**Rules** (POST-INSERT UPDATE from #Seniority_FundedNew):
```
NewFunded_Date0 = MAX(
    DATEFROMPARTS(YEAR(FTDDate), MONTH(FTDDate), 1),
    DATEFROMPARTS(YEAR(FirstActionDate), MONTH(FirstActionDate), 1),
    DATEFROMPARTS(YEAR(V3_Date), MONTH(V3_Date), 1)
)
Seniority_FundedNew = DATEDIFF(MONTH, NewFunded_Date0, ActiveDate)
                      (NULL for unfunded customers or if dates unavailable)

Seniority (original) = DATEDIFF(MONTH, FTDdate, @BeginOfMonth)
```

### 2.8 LTV Columns — Populated by Separate SP

**What**: Six LTV model predictions. NOT set by `SP_CID_MonthlyPanel_FullData` — they are hardcoded `0` in the initial INSERT to avoid an SP→table circular dependency.

**Columns Involved**: `LTV_1Y`, `LTV_3Y`, `LTV_8Y`, `LTV_8Y_NoExtreme`, `LTV_Expected_bySeniority`, `NoExtremeLTV_Expected_bySeniority`

**Rules**:
```
SP_CID_MonthlyPanel_FullData: LTV_* = 0 (hardcoded, prevents loop)
SP_LTV_BI_Actual:             LTV_* = model predictions (runs separately, UPDATEs these columns)
```
Circular dependency note: `SP_LTV_BI_Actual` reads from `BI_DB_CID_MonthlyPanel_FullData` (for revenue/activity input features), so if `SP_CID_MonthlyPanel_FullData` tried to read LTV from itself, it would create a loop. The solution is to initialise LTV to 0 and let `SP_LTV_BI_Actual` fill them in on a separate pass.

### 2.9 EOM_LSD — Life Stage Description

**What**: 17-value customer lifecycle classification at end of month, set from `BI_DB_CID_LifeStageDefinition`.

**Columns Involved**: `EOM_LSD`

**Observed values (April 2026)**:
| Life Stage | Count | % |
|---|---|---|
| Dump Churn | 2,184,880 | 37.2% |
| Holder | 1,139,396 | 19.4% |
| No Activity - Not Funded | 712,990 | 12.2% |
| Active Open Club | 311,045 | 5.3% |
| Active Open | 296,517 | 5.0% |
| Churn over 60 days | 286,978 | 4.9% |
| Active Open 30-90 days | 257,397 | 4.4% |
| Holder Club | 193,957 | 3.3% |
| No Activity - Funded | 169,824 | 2.9% |
| Active Open 30-90 days Club | 115,709 | 2.0% |
| Win Back Active Open | 72,325 | 1.2% |
| Active LogIn | 40,768 | 0.7% |
| Churn 31-60 days | 38,262 | 0.7% |
| Churn 14-30 days | 22,393 | 0.4% |
| New Funded | 9,458 | 0.2% |
| New Depositor Only | 6,003 | 0.1% |
| Win Back Deposit | 267 | 0.004% |

---

## 3. Query Advisory

### 3.1 Grain and Filtering
- **One row per CID per calendar month**. Always filter `WHERE ActiveDate = '20XX-MM-01'` (first day of month) for a single-month slice. Do NOT filter on Active_Month (char type has trailing spaces, comparisons can fail).
- **ActiveDate is DATE type** (not INT). Use `ActiveDate = '2026-04-01'` not `ActiveDate = 20260401`.
- **Bracket-escape "/" column names**: `[Active_FX/Comm/Ind]`, `[Revenue_FX/Comm/Ind]`, `[PnL_FX/Comm/Ind]`, `[ACC_Revenue_FX/Comm/Ind]`, `[ACC_PnL_FX/Comm/Ind]`, `[AmountIn_NewTrades_FX/Comm/Ind]`, `[NewTrades_FX/Comm/Ind]`, `[EOM_Equity_FX/Comm/Ind]`.

### 3.2 Revenue Columns — Which to Use
- Use **`Revenue_Total_New`** for all current revenue analysis (includes all fee components since 2025).
- Use **`Revenue_Total`** only for pre-2025 historical comparability — it excludes function-based fees.
- Use **`Transactional_Revenue_Total`** when you want to exclude currency conversion fees (e.g., pure trading activity measurement).
- Use **`ACC_Revenue_Total_New`** for lifetime revenue totals. Do NOT use `ACC_Revenue_Total` for new analysis — it accumulates the legacy formula.

### 3.3 LTV Columns
- **LTV columns are always 0 unless SP_LTV_BI_Actual has run for that month**. If you see all-zero LTV values, check whether the LTV SP has been executed. LTV is typically available for historical months only.
- LTV applies to funded/active customers only; check for 0 vs NULL before aggregating.

### 3.4 ACC_ Column Behaviour for Current Month
- The current open month's ACC_ values accumulate correctly only after the prior month is locked. For the **live/current month**, ACC_ reflects: prior month's ACC_ + current run's values. It is refreshed daily on DELETE+INSERT.
- Do NOT compare ACC_ totals across different months for the same CID — the prior month's value is included, making comparisons misleading.

### 3.5 Lev1/LevCFD Sub-Tier Columns
- The **plain** `Active_Real_Stocks`, `Active_CFD_Stocks`, etc. columns include **both Lev1 and LevCFD** combined.
- `Active_Real_Stocks_Lev1` and `Active_CFD_Stocks_LevCFD` are **sub-breakdowns** of the plain columns.
- Note: the Lev1/LevCFD flag columns (Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL) are stored as `[money]` type in the DDL, though semantically binary (0 or 1 for Active/ActiveOpen). This is a known DDL quirk.
- These columns contain NULL for pre-2023 periods when the Lev split was not yet tracked.

### 3.6 EOM_Segment Always NULL
- The `EOM_Segment` column is always NULL in practice — it was reserved but never populated by the ETL.

### 3.7 Large Table Query Guidance
- With 353.8M rows, **always filter on `ActiveDate`** before adding other predicates. `ActiveDate` is the leading index key.
- The table is HASH(CID)-distributed. Joins to other HASH(CID) tables (e.g., BI_DB_CID_DailyPanel_FullData) are co-located — no data movement.
- Avoid `COUNT(*)` without a date filter. Use `sys.dm_pdw_nodes_db_partition_stats` for rowcount estimates.
- For `GROUP BY` analytics on a single month, add `WHERE ActiveDate = '20XX-MM-01'` and include `ActiveDate` in the GROUP BY if reporting multiple months.

### 3.8 CountryID vs Country / Region
- `CountryID` (int, FK → Dim_Country) is the canonical geographic key. JOIN to `DWH_dbo.Dim_Country` for country attributes.
- `Country` (varchar) and `Region` (varchar) are denormalized strings copied from Dim_Customer at ETL time. They may lag Dim_Country changes by up to one day.
- `NewMarketingRegion` is a more recent marketing region label that may differ from `Region` for some countries.

---

## 4. Data Elements

### 4.1 Identity / Grain

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | NO | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | Active_Month | char(7) | NO | Calendar month this row represents, in YYYY-MM format with trailing space pad to 7 chars (e.g., '202604 '). Grain identifier alongside ActiveDate. Always use ActiveDate (DATE) for filtering; char comparisons on Active_Month can fail due to trailing space. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 3 | ActiveDate | date | NO | First day of the calendar month (e.g., 2026-04-01). Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for month slices. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 109 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_CID_MonthlyPanel_FullData. Refreshed daily during the current open month. (Tier 2 — ETL metadata) |

### 4.2 Registration & Acquisition

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | Seniority | int | YES | Months since first deposit: DATEDIFF(MONTH, FTDdate, ActiveDate). 0 = FTD month. NULL for customers without a deposit. Observed range: 0–225 months (2007–2026). (Tier 2 — SP_CID_MonthlyPanel_FullData, BI_DB_CIDFirstDates) |
| 5 | RegMonth | char(7) | YES | Month of customer registration in YYYY-MM format. (Tier 2 — Dim_Customer via #CIDs) |
| 6 | RegDate | date | YES | Exact date of customer registration. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 7 | IsReg_ThisM | tinyint | YES | 1 if the customer registered during this calendar month; 0 otherwise. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 8 | FTD_Month | char(7) | YES | Month of first time deposit (FTD) in YYYY-MM format. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 9 | FTDdate | date | YES | Exact date of first deposit. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 10 | IsFTD_ThisM | tinyint | YES | 1 if the customer made their first deposit this calendar month; 0 otherwise. (Tier 2 — BI_DB_CIDFirstDates) |
| 11 | FTDA | money | YES | First time deposit amount (USD). Amount of the initial deposit event. (Tier 2 — BI_DB_CIDFirstDates) |
| 12 | Region | varchar(50) | YES | Marketing region name as of ETL run (e.g., 'ROW', 'UK', 'CEE', 'Latam'). Denormalized from Dim_Customer. May differ from NewMarketingRegion for some countries. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 13 | Country | varchar(50) | YES | Customer's country name (e.g., 'United Kingdom', 'Israel'). Denormalized from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 14 | Channel | varchar(50) | YES | Acquisition channel (e.g., 'Affiliate', 'SEM', 'Media Performance'). (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 15 | SubChannel | varchar(250) | YES | Acquisition sub-channel. More granular than Channel. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 16 | AffiliateID | bigint | YES | Affiliate partner identifier. FK → DWH_dbo.Dim_Affiliate. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 17 | FirstAction | varchar(50) | YES | Instrument type of the customer's first-ever trade (e.g., 'FX/Commodities/Indices', 'Crypto'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 18 | FirstInstrument | varchar(250) | YES | Name of the specific instrument in the customer's first trade (e.g., 'EUR/USD', 'BTC'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 19 | V2_Complete | tinyint | YES | 1 if KYC level 2 (identity verification) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 20 | V3_Complete | tinyint | YES | 1 if KYC level 3 (enhanced due diligence / proof of address) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |

### 4.3 Engagement & State

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | LastPosOpenDate | date | YES | Date of the customer's last position open event (any instrument) up to and including this month. (Tier 2 — Fact_CustomerAction) |
| 22 | LastLoggedIn | date | YES | Date of the customer's last login before end of this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 23 | IsPro | tinyint | YES | 1 if the customer has professional client status (from External_BI_OUTPUT_Customer_ProfessionalCustomers). (Tier 2 — External table) |
| 24 | IsOTD | tinyint | YES | 1 if the customer is classified as OTD (Over-the-Desk / client service tier). (Tier 2 — Fact_SnapshotCustomer) |
| 110 | AccountManager | varchar(250) | YES | Name of the assigned account manager at ETL run time. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 111 | IsIslamic | tinyint | YES | 1 if the customer's account is Islamic (swap-free). Islamic accounts incur AdminFee and SpotAdjustFee instead of overnight swaps. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 112 | IsContacted | tinyint | YES | 1 if the customer was contacted by sales/CRM this month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 113 | IsContactedAmount | money | YES | Amount associated with the CRM contact event this month (if applicable). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 117 | LastApplicationProAccountDate | date | YES | Date of the customer's most recent professional account application. 1900-01-01 if no application. (Tier 2 — Fact_SnapshotCustomer) |
| 173 | LastAMLTicketDate | date | YES | Most recent AML-related Salesforce case date for this customer (POST-INSERT UPDATE from BI_DB_SF_Cases_Panel). NULL if no AML case history. (Tier 2 — BI_DB_SF_Cases_Panel) |

### 4.4 EOM Classification & Segmentation

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | EOM_Club | varchar(50) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 26 | EOM_Regulation | varchar(50) | YES | Regulatory jurisdiction at end of month (e.g., CySEC, FCA, FinCEN+FINRA, ASIC & GAML). Sourced from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 15 distinct values observed. (Tier 2 — Fact_SnapshotCustomer / Dim_Regulation) |
| 27 | EOM_Equity | money | YES | Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. (Tier 2 — DWH_dbo.V_Liabilities) |
| 28 | EOM_Balance | money | YES | Cash balance (USD) at end of month — equity minus unrealised PnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| 29 | EOM_Segment | varchar(50) | YES | Reserved classification field. Always NULL in practice — never populated by current ETL. (Tier 2 — Reserved) |
| 32 | ActiveUser | tinyint | YES | 1 if EOM_Equity > 0 (customer has any portfolio value at month end). Broader than Active or ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 114 | EOM_IsFunded | tinyint | YES | Legacy funded flag at end of month from Fact_SnapshotCustomer snapshot. Differs from IsEOM_Funded_NEW / IsFunded_New in calculation. Use IsFunded_New or IsEOM_Funded_NEW for current analysis. (Tier 2 — Fact_SnapshotCustomer) |
| 158 | IsFunded_New | tinyint | YES | Current funding flag (new definition). Used as the base for IsChurn_ThisM and IsWB_ThisM churn detection. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 159 | Seniority_FundedNew | int | YES | Months since customer's "new funded" date: DATEDIFF(MONTH, MAX(FTDMonth, FirstActionMonth, V3Month), ActiveDate). NULL for unfunded customers. (Tier 2 — BI_DB_CIDFirstDates + BI_DB_First5Actions, POST-INSERT UPDATE) |
| 168 | NewMarketingRegion | varchar(50) | YES | Marketing region label (newer vintage than Region). Values: ROW, UK, CEE, Nordics, Latam, SEA, Australia, etc. (Tier 2 — Fact_SnapshotCustomer / Dim_Customer) |
| 169 | ClusterDetail | varchar(50) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. (Tier 2 — BI_DB_CID_DailyCluster) |
| 170 | IsEOM_Funded_NEW | tinyint | YES | End-of-month funded flag under the new funded definition. Closely related to IsFunded_New; reflects EOM state. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 172 | CountryID | int | YES | FK → DWH_dbo.Dim_Country.CountryID. Use for country attribute lookups (regulation, AML risk, EU membership). CountryID=0 = Not available. (Tier 1 — DWH_dbo.Dim_Country wiki) |
| 174 | IsChurn_ThisM | int | YES | 1 if customer was funded last month (IsFunded_New=1) but not this month (IsFunded_New=0). Churn event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 175 | IsWB_ThisM | int | YES | 1 if customer was not funded last month but is funded this month. Win-back event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 179 | EOM_LSD | nvarchar(50) | YES | Life Stage Description at end of month from BI_DB_CID_LifeStageDefinition. 17 possible values: e.g., 'Dump Churn', 'Holder', 'Active Open Club', 'New Funded', 'Win Back Active Open'. (Tier 2 — BI_DB_CID_LifeStageDefinition) |

### 4.5 Activity Flags — Top Level

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | Active | tinyint | YES | 1 if customer closed ≥1 position this month (any asset class). (Tier 2 — Fact_CustomerAction) |
| 34 | ActiveOpen | tinyint | YES | 1 if customer has open positions at month end. Composite: 1 when ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1. (Tier 2 — SP_CID_MonthlyPanel_FullData, Or Filizer 2025-01-06) |
| 176 | ActiveOpenManual | int | YES | Count of open manual (non-copy) positions at month end. Stored as count, not a binary flag. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 177 | ActiveOpenWOAirdrop | int | YES | Count of open positions at month end, excluding airdrop-type positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 178 | ActiveOpenWOAirdropManual | int | YES | Count of open manual positions at month end excluding airdrop positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |

### 4.6 Activity Flags — Asset Class

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 45 | Active_Copy | tinyint | YES | 1 if customer had active copy trades closed this month. (Tier 2 — Fact_CustomerAction) |
| 46 | Active_Real_Stocks | tinyint | YES | 1 if customer closed ≥1 real (settled) stock/ETF position this month. (Tier 2 — Fact_CustomerAction) |
| 47 | Active_CFD_Stocks | tinyint | YES | 1 if customer closed ≥1 CFD (leveraged) stock position this month. (Tier 2 — Fact_CustomerAction) |
| 48 | Active_Real_Crypto | tinyint | YES | 1 if customer closed ≥1 settled crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 49 | Active_CFD_Crypto | tinyint | YES | 1 if customer closed ≥1 CFD crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 50 | [Active_FX/Comm/Ind] | tinyint | YES | 1 if customer closed ≥1 FX/commodity/index position this month. Column name contains "/" — must use bracket quoting. (Tier 2 — Fact_CustomerAction) |
| 51 | ActiveOpen_Copy | tinyint | YES | 1 if customer has open copy trades at month end. (Tier 2 — Fact_CustomerAction) |
| 52 | ActiveOpen_Real_Stocks | tinyint | YES | 1 if customer has open real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 53 | ActiveOpen_CFD_Stocks | tinyint | YES | 1 if customer has open CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 54 | ActiveOpen_Real_Crypto | tinyint | YES | 1 if customer has open settled crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 55 | ActiveOpen_CFD_Crypto | tinyint | YES | 1 if customer has open CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 56 | [ActiveOpen_FX/Comm/Ind] | tinyint | YES | 1 if customer has open FX/commodity/index positions at month end. Bracket-quote required. (Tier 2 — Fact_CustomerAction) |
| 180 | ActiveOpen_AirDrop | int | YES | 1 if customer has open airdrop-type positions at month end. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 181 | ActiveOpen_Mirror | int | YES | 1 if customer has open mirror/add-mirror copy positions at month end. CASE WHEN NewMirror=1 OR AddMirror=1. (Tier 2 — Dim_Mirror via #mrr/#addmrr) |
| 182 | ActiveOpen_Manual | int | YES | 1 if customer has open manually-executed positions at month end (non-copy). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 183 | ActiveOpen_IncludeCopy | int | YES | 1 if customer has open positions including copy trades at month end. Superset of ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 128 | Active_Real_Stocks_Lev1 | money | YES | Flag (stored as money: 0.0 or 1.0) — customer traded real stocks with 1:1 leverage (un-leveraged long) this month. (Tier 2 — Fact_CustomerAction Lev sub-split) |
| 129 | Active_CFD_Stocks_LevCFD | money | YES | Flag — customer traded leveraged/short CFD stock positions this month. (Tier 2 — Fact_CustomerAction) |
| 130 | Active_Real_Crypto_Lev1 | money | YES | Flag — customer traded un-leveraged real crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 131 | Active_CFD_Crypto_LevCFD | money | YES | Flag — customer traded leveraged/short CFD crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 132 | ActiveOpen_Real_Stocks_Lev1 | money | YES | Flag — customer has open un-leveraged real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 133 | ActiveOpen_CFD_Stocks_LevCFD | money | YES | Flag — customer has open leveraged CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 134 | ActiveOpen_Real_Crypto_Lev1 | money | YES | Flag — customer has open un-leveraged real crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 135 | ActiveOpen_CFD_Crypto_LevCFD | money | YES | Flag — customer has open leveraged CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |

### 4.7 Copy / Portfolio Copy Activity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 35 | IsOpen_Copy | tinyint | YES | 1 if customer has an open copy trade relationship at month end. (Tier 2 — Fact_CustomerAction) |
| 36 | Count_Opened_Copy | int | YES | Number of new copy trade relationships opened this month. (Tier 2 — Fact_CustomerAction) |
| 37 | Count_Closed_Copy | int | YES | Number of copy trade relationships closed this month. (Tier 2 — Fact_CustomerAction) |
| 38 | MoneyIn_Copy | money | YES | USD amount allocated to new copy trades this month. (Tier 2 — Fact_CustomerAction) |
| 39 | MoneyOut_Copy | money | YES | USD amount withdrawn from copy trades this month (stop-copy events). (Tier 2 — Fact_CustomerAction) |
| 40 | IsOpen_CopyPortfolio | tinyint | YES | 1 if customer has an open copy-portfolio (SmartPo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `BI_DB_dbo.BI_DB_First5Actions` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_First5Actions`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md`

# BI_DB_First5Actions

> Customer onboarding behavior profile. One row per depositor. Records the first five trading actions each customer took, the asset classes they touched, key revenue/deposit/equity milestones at 1/7/14/30/60/90/180/360-day windows post-FTD, and demographics from registration. The primary analytical use case is understanding "what did this customer do first after depositing?" — a critical input for activation and retention analysis. Used directly by SP_DepositUsersFirstTouchPoints.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED INDEX (FirstDepositDate ASC) |
| **Row Count** | ~46.3M rows (one per depositor) |
| **FTD Range** | 1900-01-01 (sentinel) to 2026-04-12 |
| **NULL FirstAction** | ~88.3% (deposited but never traded within first 5 actions window) |
| **Writer SP** | SP_First5Actions |
| **Write Pattern** | TRUNCATE + INSERT (full refresh, no date parameter) |
| **UC Status** | Not Migrated |
| **LTV Column** | Disabled — hardcoded to 0 since 2022-06-02 |

---

## Business Context

`BI_DB_First5Actions` answers the question: *"What did this customer do first after depositing, and how did they perform in subsequent weeks/months?"*

The table is scoped to **depositors only** — the SP filters `BI_DB_CIDFirstDates WHERE FirstDepositDate IS NOT NULL`. Customers who registered but never deposited are excluded.

The 88.3% NULL `FirstAction` rate reflects that most depositors never open a trading position — they deposit money but do not actively trade within the system's tracking window for the first 5 position-opening actions.

The **cross columns** (`FirstCross`, `FirstCrossNew`, etc.) represent "asset class crossings" — each time a customer trades in a *different* asset class from their previous trade. The legacy series (`FirstCross..FifthCross`) uses the older `BI_DB_CustomerCross` source; the new series (`FirstCrossNew..FifthCrossNew`) uses `BI_DB_CustomerCross_New` with the updated `ActionTypeNew` taxonomy.

**Action type taxonomies**:
| Column Group | Values |
|---|---|
| FirstAction..FifthAction (coarse) | Crypto, FX/Commodities/Indices, Stocks/ETFs, Copy, Copy Fund |
| FirstActionTypeNew (mid-level) | Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund |
| FirstAction_Detailed (granular) | Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund |
| FirstCross..FifthCross (legacy) | Same as ActionType_Detailed |
| FirstCrossNew..FifthCrossNew (new) | Same as ActionTypeNew |

**Real vs CFD Stocks distinction** (FirstAction_Detailed only):
- Real Stocks/ETFs = `InstrumentTypeID IN (5,6) AND Leverage=1 AND IsBuy=1`
- CFD Stocks/ETFs = `InstrumentTypeID IN (5,6) AND (Leverage>1 OR IsBuy=0)`

---

## Column Elements

### Identity & Acquisition

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | CID | int | NO | Tier 1 | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | AffiliateID | int | YES | Tier 1 | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Tier 2 | Marketing acquisition channel. Passed through from BI_DB_CIDFirstDates.Channel (resolved via Dim_Affiliate → Dim_Channel). ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. |
| 8 | SubChannel | nvarchar(500) | NO | Tier 2 | Marketing sub-channel. Passed through from BI_DB_CIDFirstDates.SubChannel. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. |

### Geography

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 5 | Region | nvarchar(500) | NO | Tier 2 | Marketing region at time of registration. From BI_DB_CIDFirstDates.Region (Dim_Country.Region). Values: North Europe, French, Eastern Europe, LATAM, etc. |
| 6 | Country | varchar(500) | YES | Tier 2 | Country of residence name in English. From BI_DB_CIDFirstDates.Country (Dim_Country.Name via CountryID). |
| 75 | NewMarketingRegion | varchar(50) | YES | Tier 2 | Updated marketing region grouping. From BI_DB_CIDFirstDates.NewMarketingRegion (Dim_Country.MarketingRegionManualName). Introduced 2021-02-10. Preferred over Region for current segmentation. |

### First Deposit

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 3 | FirstDepositDate | datetime | YES | Tier 2 | Date and time of customer's first successful deposit. From BI_DB_CIDFirstDates.FirstDepositDate (Dim_Customer.FirstDepositDate ← CustomerFinanceDB.FirstTimeDeposits). 1900-01-01 = no deposit (sentinel — these rows exist in CIDFirstDates but are filtered out by this SP). |
| 4 | FirstDepositAmount | money | YES | Tier 2 | Amount in USD of customer's first deposit. From BI_DB_CIDFirstDates.FirstDepositAmount (Dim_Customer.FirstDepositAmount ← CustomerFinanceDB.FirstTimeDeposits). YTD avg ~$696. Default 0 for $0 deposits. |

### First Action (coarse classification)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 9 | FirstAction | varchar(22) | YES | Tier 2 | Asset class of the customer's 1st open position. CASE on InstrumentTypeID+MirrorID: 'Crypto' (typeID=10), 'FX/Commodities/Indices' (1/2/4), 'Stocks/ETFs' (5/6), 'Copy Fund' (CopyFund manager), 'Copy'. NULL if no position opened (~88.3%). Distribution: Crypto 5.3%, Stocks/ETFs 3.6%, Copy 1.4%, FX/Commodities/Indices 1.3%, Copy Fund 0.1%. |
| 10 | FirstActionDate | datetime | YES | Tier 2 | Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)). |
| 11 | FirstInstrument | varchar(50) | YES | Tier 2 | Display name of the first traded instrument. ISNULL(ParentUserName, InstrumentName): for Copy positions, shows the copied trader's username; for direct trades, shows Dim_Instrument.Name. |
| 12 | SecondAction | varchar(22) | YES | Tier 2 | Asset class of 2nd open position. Same CASE as FirstAction. NULL if fewer than 2 positions. |
| 13 | SecondInstrument | varchar(50) | YES | Tier 2 | Display name for 2nd position (same pattern as FirstInstrument). |
| 14 | ThirdAction | varchar(22) | YES | Tier 2 | Asset class of 3rd open position. |
| 15 | ThirdInstrument | varchar(50) | YES | Tier 2 | Display name for 3rd position. |
| 16 | FourthAction | varchar(22) | YES | Tier 2 | Asset class of 4th open position. |
| 17 | FourthInstrument | varchar(50) | YES | Tier 2 | Display name for 4th position. |
| 18 | FifthAction | varchar(22) | YES | Tier 2 | Asset class of 5th open position. |
| 19 | FifthInstrument | varchar(50) | YES | Tier 2 | Display name for 5th position. |

### Action Dates & Leverages (2nd–5th)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 35 | FirstLeverage | int | YES | Tier 2 | Leverage used for 1st open position. From BI_DB_CustomerFirst5OpenPositions.Leverage, rank=1. 1 = real (unlevered) stock purchase. >1 = CFD/leveraged position. |
| 36 | SecondActionDate | date | YES | Tier 2 | Date of 2nd open position (Occurred, rank=2). |
| 37 | ThirdActionDate | date | YES | Tier 2 | Date of 3rd open position (rank=3). |
| 38 | FourthActionDate | date | YES | Tier 2 | Date of 4th open position (rank=4). |
| 39 | FifthActionDate | date | YES | Tier 2 | Date of 5th open position (rank=5). |
| 40 | SecondLeverage | int | YES | Tier 2 | Leverage for 2nd position (rank=2). |
| 41 | ThirdLeverage | int | YES | Tier 2 | Leverage for 3rd position (rank=3). |
| 42 | FourthLeverage | int | YES | Tier 2 | Leverage for 4th position (rank=4). |
| 43 | FifthLeverage | int | YES | Tier 2 | Leverage for 5th position (rank=5). |

### Detailed Action Classification

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 44 | FirstAction_Detailed | varchar(50) | YES | Tier 2 | Granular asset class for 1st position. Distinguishes 'Real Stocks/ETFs' (Leverage=1, IsBuy=1) from 'CFD Stocks/ETFs' (Leverage>1 or IsBuy=0). Values: Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund. |
| 69 | SecondAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 2nd position (same schema as FirstAction_Detailed). |
| 70 | ThirdAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 3rd position. |
| 71 | FourthAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 4th position. |
| 72 | FifthAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 5th position. |
| 76 | FirstActionTypeNew | nvarchar(50) | YES | Tier 2 | First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. |

### Traded Asset Flags

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 20 | Traded_FX/Commodities/Indices | int | YES | Tier 2 | 1 if FirstAction or any of the 5 cross positions = 'FX/Commodities/Indices'. 0 otherwise. Useful for "ever touched FX" segmentation. |
| 21 | Traded_Stocks/ETFs | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Stocks/ETFs', 'Real Stocks/ETFs', or 'CFD Stocks/ETFs'. 0 otherwise. |
| 22 | TradedCrypto | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Crypto'. 0 otherwise. |
| 23 | TradedCopy | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Copy'. 0 otherwise. |
| 24 | TradedCopyFund | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Copy Fund'. 0 otherwise. |

### Legacy Cross-Asset Sequence (BI_DB_CustomerCross)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 25 | FirstCross | varchar(22) | YES | Tier 2 | Detailed asset class of 1st position (legacy). From BI_DB_CustomerCross PIVOT (ActionType_Detailed, rn=1). Same values as FirstAction_Detailed. ~6.5% non-NULL. |
| 26 | FirstCrossDate | datetime | YES | Tier 2 | Datetime of 1st cross event (from BI_DB_CustomerCross.Occurred, rn=1). |
| 27 | SecondCross | varchar(22) | YES | Tier 2 | Detailed asset class of 2nd cross position (rn=2). |
| 28 | SecondCrossDate | datetime | YES | Tier 2 | Datetime of 2nd cross (rn=2). |
| 29 | ThirdCross | varchar(22) | YES | Tier 2 | Detailed asset class of 3rd cross (rn=3). |
| 30 | ThirdCrossDate | datetime | YES | Tier 2 | Datetime of 3rd cross (rn=3). |
| 31 | FourthCross | varchar(22) | YES | Tier 2 | Detailed asset class of 4th cross (rn=4). |
| 32 | FourthCrossDate | datetime | YES | Tier 2 | Datetime of 4th cross (rn=4). |
| 73 | FifthCross | varchar(22) | YES | Tier 2 | Detailed asset class of 5th cross (rn=5). |
| 74 | FifthCrossDate | datetime | YES | Tier 2 | Datetime of 5th cross (rn=5). |

### New Cross-Asset Sequence (BI_DB_CustomerCross_New)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 86 | FirstCrossNew | nvarchar(50) | YES | Tier 2 | Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses. |
| 77 | FirstCrossDateNew | date | YES | Tier 2 | Date of 1st new-taxonomy cross (BI_DB_CustomerCross_New.Occurred, rn=1). |
| 78 | SecondCrossNew | nvarchar(50) | YES | Tier 2 | 2nd cross position (new taxonomy, rn=2). |
| 79 | SecondCrossDateNew | date | YES | Tier 2 | Date of 2nd new cross (rn=2). |
| 80 | ThirdCrossNew | nvarchar(50) | YES | Tier 2 | 3rd cross position (rn=3). |
| 81 | ThirdCrossDateNew | date | YES | Tier 2 | Date of 3rd new cross (rn=3). |
| 82 | FourthCrossNew | nvarchar(50) | YES | Tier 2 | 4th cross position (rn=4). |
| 83 | FourthCrossDateNew | date | YES | Tier 2 | Date of 4th new cross (rn=4). |
| 84 | FifthCrossNew | nvarchar(50) | YES | Tier 2 | 5th cross position (rn=5). |
| 85 | FifthCrossDateNew | date | YES | Tier 2 | Date of 5th new cross (rn=5). |

### Revenue Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 45 | Revenue1day | decimal(38,2) | YES | Tier 2 | Company revenue from this customer in the 1 day following FTD. From BI_DB_CID_BalanceDays. NULL if elapsed days since FTD < 0. |
| 46 | Revenue7days | decimal(38,2) | YES | Tier 2 | Revenue in 7 days post-FTD. NULL if < 6 days elapsed. |
| 47 | Revenue14days | decimal(38,2) | YES | Tier 2 | Revenue in 14 days post-FTD. NULL if < 13 days elapsed. |
| 48 | Revenue30days | decimal(38,2) | YES | Tier 2 | Revenue in 30 days post-FTD. NULL if < 29 days elapsed. ~10% populated; min=-$15,567, max=$1.54M, avg=$68.80. |
| 49 | Revenue60days | decimal(38,2) | YES | Tier 2 | Revenue in 60 days post-FTD. NULL if < 59 days. |
| 50 | Revenue90days | decimal(38,2) | YES | Tier 2 | Revenue in 90 days post-FTD. NULL if < 89 days. |
| 51 | Revenue180days | decimal(38,2) | YES | Tier 2 | Revenue in 180 days post-FTD. NULL if < 179 days. |
| 52 | Revenue360days | decimal(38,2) | YES | Tier 2 | Revenue in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Revenue365days (column name mismatch). NULL if < 364 days elapsed. |

### Deposit Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 53 | Deposit1day | decimal(38,2) | YES | Tier 2 | Total deposit amount in 1 day post-FTD. From BI_DB_CID_BalanceDays.Deposit1day. |
| 54 | Deposit7days | decimal(38,2) | YES | Tier 2 | Total deposits in 7 days post-FTD (includes FTD itself). NULL if < 6 days elapsed. |
| 55 | Deposit14days | decimal(38,2) | YES | Tier 2 | Total deposits in 14 days post-FTD. |
| 56 | Deposit30days | decimal(38,2) | YES | Tier 2 | Total deposits in 30 days post-FTD. ~12.6% populated. |
| 57 | Deposit60days | decimal(38,2) | YES | Tier 2 | Total deposits in 60 days post-FTD. |
| 58 | Deposit90days | decimal(38,2) | YES | Tier 2 | Total deposits in 90 days post-FTD. |
| 59 | Deposit180days | decimal(38,2) | YES | Tier 2 | Total deposits in 180 days post-FTD. |
| 60 | Deposit360days | decimal(38,2) | YES | Tier 2 | Total deposits in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Deposit365days. |

### Equity Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 61 | Equity1day | decimal(38,4) | YES | Tier 2 | Account equity snapshot 1 day post-FTD. From BI_DB_CID_BalanceDays.Equity1day. |
| 62 | Equity7days | decimal(38,4) | YES | Tier 2 | Equity 7 days post-FTD. NULL if < 6 days elapsed. |
| 63 | Equity14days | decimal(38,4) | YES | Tier 2 | Equity 14 days post-FTD. |
| 64 | Equity30days | decimal(38,4) | YES | Tier 2 | Equity 30 days post-FTD. ~12.6% populated. |
| 65 | Equity60days | decimal(38,4) | YES | Tier 2 | Equity 60 days post-FTD. |
| 66 | Equity90days | decimal(38,4) | YES | Tier 2 | Equity 90 days post-FTD. |
| 67 | Equity180days | decimal(38,4) | YES | Tier 2 | Equity 180 days post-FTD. |
| 68 | Equity360days | decimal(38,4) | YES | Tier 2 | Equity 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Equity365days. |

### Metadata

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 33 | UpdateDate | datetime | NO | Tier 2 | Timestamp of SP execution that wrote this row. GETDATE() at INSERT time. |
| 34 | LTV | float | YES | Tier 2 | **DISABLED** — hardcoded to 0 for all rows since 2022-06-02 (Jan change). Previously intended to store lifetime value. Do not use. |

---

## ETL Pipeline

```
BI_DB_CIDFirstDates (WHERE FirstDepositDate IS NOT NULL)
  ├─ demographics: CID, AffiliateID, FTD dates/amounts, Channel, SubChannel, Region, Country
  │
BI_DB_CustomerFirst5OpenPositions (ActionNumber IN 1..5)
  ├─ + Dim_Instrument (InstrumentTypeID → ActionType CASE)
  ├─ + Dim_Mirror (MirrorID → ParentUserName for Copy)
  ├─ + Dim_Customer (AccountTypeID=9 → Copy Fund IDs)
  │     → #Actions2 (pivot 5 actions per customer with types)
  │
BI_DB_CustomerCross → #final (legacy cross sequence)
BI_DB_CustomerCross_New → #final2 (new cross sequence)
BI_DB_CID_BalanceDays → Revenue/Deposit/Equity 1d..360d windows
  │
  |-- SP_First5Actions (TRUNCATE + full INSERT) --|
  v
BI_DB_dbo.BI_DB_First5Actions (46.3M rows, one per depositor)
  |-- UC: Not Migrated --|
```

---

## Sample Queries

```sql
-- First-action distribution for 2024 depositors
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS cnt,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct
FROM BI_DB_dbo.BI_DB_First5Actions
WHERE FirstDepositDate >= '2024-01-01' AND YEAR(FirstDepositDate) != 1900
GROUP BY FirstAction
ORDER BY cnt DESC;
```

```sql
-- Revenue 30 days after FTD by first action type
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS depositors,
    AVG(Revenue30days) AS avg_rev_30d,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Revenue30days)
        OVER (PARTITION BY FirstAction) AS median_rev_30d
FROM BI_DB_dbo.BI_DB_First5Actions
WHERE Revenue30days IS NOT NULL
GROUP BY FirstAction
ORDER BY avg_rev_30d DESC;
```

```sql
-- Cross-asset rate: what % traded multiple asset classes?
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS total,
    SUM(CASE WHEN SecondCrossNew IS NOT NULL THEN 1 ELSE 0 END) AS crossed_once,
    SUM(CASE WHEN ThirdCrossNew IS NOT NULL THEN 1 ELSE 0 END) AS crossed_twice
FROM BI_DB_dbo.BI_DB_First5Actions
GROUP BY FirstAction;
```

---

## Relationships

| Related Object | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Country, regulation, player level enrichment |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID = CID | Upstream demographics source |
| BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ON CID = RealCID | Source for first 5 actions |
| BI_DB_dbo.BI_DB_CID_BalanceDays | ON CID = CID | Revenue/Deposit/Equity window metrics |
| BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints | ON CID = CID | Downstream consumer |


### Upstream `BI_DB_dbo.BI_DB_CIDFirstDates` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CIDFirstDates`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`

# BI_DB_dbo.BI_DB_CIDFirstDates

> 46.7M-row customer lifecycle milestone table tracking every eToro customer's first and last occurrence of key platform events -- registration, deposit, login, trade, copy, contact, verification, and funded status -- serving as the central customer-level dimension for BI reporting, CRM enrichment, and lifecycle segmentation. Updated daily by SP_CIDFirstDates via incremental INSERT (new customers) + UPDATE (changed attributes and new events).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension -- customer lifecycle milestones) |
| **Row Count** | ~46.7M (one row per valid customer) |
| **Date Range** | Registrations from 2007-08-29 to present |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (core), Fact_CustomerAction (events), Fact_BillingDeposit (deposits), V_Liabilities (equity), Dim_Mirror (copy), BI_DB_UsageTracking_SF (CRM contacts), Fact_SnapshotCustomer (verification), Function_Population_Funded/First_Time_Funded (funded status), BI_DB_DDR_Customer_Daily_Status (last funded), BI_DB_AppFlyer_Reports (mobile install) |
| **Refresh** | Daily incremental -- INSERT new valid customers + multi-pass UPDATE for changed attributes and new events (SP_CIDFirstDates) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFirstDates` is the BI layer's master customer lifecycle dimension. It maintains one row per valid customer (IsValidCustomer=1 in Dim_Customer, i.e., not PlayerLevelID=4, not LabelID 26/30, not CountryID=250), capturing:

- **Identity & demographics**: CID, GCID, UserName, Gender, BirthDate, Email, Country, CountryID, State, Language, CommunicationLanguage
- **Acquisition**: Channel, SubChannel, SerialID (AffiliateID), LabelName, FunnelName, FunnelFromName, BannerID, SubAffiliateID, DownloadID, ReferralID
- **Account status**: Club (PlayerLevel name), Blocked flag, Verified (VerificationLevel), RegulationID, DesignatedRegulationID, Manager, PrivacyPolicyID
- **Deposit milestones**: FirstDepositAttempt/Amount/Processor/FundingType, FirstDeposit/LastDeposit dates/amounts/funding types, Credit, RealizedEquity
- **Trading milestones**: FirstPosOpenDate, FirstMenualPosOpenDate, FirstMirrorPosOpenDate, FirstMirrorRegistrationDate, FirstStocksOpenDate, and their Last counterparts
- **Login milestones**: FirstLoggedIn, LastLoggedIn, FirstCashierLogin, LastCashierLogin
- **Social/copy milestones**: FirstTimeBeingCopied, LastTimeBeingCopied
- **Contact milestones**: FirstContactDate, LastContactDate, LastContactDate_ByPhone (from Salesforce CRM)
- **Verification milestones**: VerificationLevel1/2/3Date, EmailVerifiedDate, EvMatchStatusDate, PhoneVerifiedDate
- **Funded status**: IsFundedNew, FirstNewFundedDate, LastNewFundedDate
- **Cashout milestones**: FirstCashoutDate, LastCashoutDate
- **Other**: FirstInstallDate (mobile), FirstCampaignID/Date/Amount, KycModeID, ProfessionalApplicationDate, IsAirDropBefore, FTDIsLessThanAWeek

The table is populated from 15+ sources via SP_CIDFirstDates (Author: Adi Ferber, 2016-03-01). The SP first builds a full valid-customer set from Dim_Customer, inserts new customers with demographic/acquisition attributes, then runs ~20 multi-pass UPDATEs to populate first/last event dates from Fact_CustomerAction, deposit details from Fact_BillingDeposit, equity from V_Liabilities, copy data from Dim_Mirror, CRM contacts from BI_DB_UsageTracking_SF, verification dates from Fact_SnapshotCustomer, and funded status from the Function_Population_Funded/First_Time_Funded TVFs.

**Important**: Many columns are **deprecated** and no longer updated. Columns like KYC, DocsOK, Bankruptcy, PremiumAccount, Evangelist, SuitabilityTestCompletedAt, PassedSuitabilityTest, PEPCreatedTime, PEPStatusUpdatedDate, isPassedPEP, PEPStatusID were explicitly nullified on 2022-02-22. Demo-related columns (FirstDemoLoggedIn, FirstDemoPosOpenDate, etc.) were disabled in 2017. Social/engagement columns were disabled when source tables stopped updating. RiskGroup and DepositGroup were disabled 2023-05-09. These columns remain in the DDL but carry NULL/0 for all rows.

Invalid customers (IsValidCustomer=0) are actively DELETED from this table each run.

---

## 2. Business Logic

### 2.1 Valid Customer Population

**What**: Only valid customers are tracked. Invalid customers are deleted each run.

**Columns Involved**: CID, all columns

**Rules**:
- Valid = IsValidCustomer=1 in Dim_Customer (PlayerLevelID != 4, LabelID NOT IN (26,30), CountryID != 250)
- Invalid customers are identified via `#internal` temp table and DELETEd from BI_DB_CIDFirstDates
- New valid customers not yet in the table are INSERTed with demographic/acquisition attributes
- Changed attributes (Club, Language, Email, Blocked, etc.) trigger UPDATEs via change detection using COLLATE Latin1_General_BIN comparison

### 2.2 Blocked Flag Derivation

**What**: Binary flag indicating whether the customer account is restricted.

**Columns Involved**: `Blocked`

**Rules**:
- `CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0 END`
- PlayerStatusID values: 2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked

### 2.3 Registration Date Logic

**What**: The `registered` column takes the earlier of demo and real registration dates.

**Columns Involved**: `registered`

**Rules**:
- `CASE WHEN RegisteredDemo < RegisteredReal THEN RegisteredDemo ELSE RegisteredReal END`
- This captures the customer's first interaction with the platform regardless of account type

### 2.4 First/Last Event Pattern

**What**: Most first/last date columns follow a consistent pattern from Fact_CustomerAction.

**Columns Involved**: FirstLoggedIn, LastLoggedIn, FirstPosOpenDate, LastPosOpenDate, FirstCashierLogin, LastCashierLogin, FirstCashoutDate, LastCashoutDate, FirstMirrorRegistrationDate, LastMirrorRegistrationDate, FirstMenualPosOpenDate, LastMenualPosOpenDate, FirstMirrorPosOpenDate, LastMirrorPosOpenDate, FirstStocksOpenDate

**Rules**:
- SP filters Fact_CustomerAction by DateID range (today only) and ActionTypeID
- First dates: UPDATE only WHERE current value IS NULL or > @date (never overwrite an earlier first)
- Last dates: UPDATE with MAX(Occurred) -- always overwrite with latest
- ActionTypeID mapping: 1=ManualPositionOpen, 2=CopyPositionOpen, 7=Deposit, 8=Cashout, 14=Login, 15=AccountToMirror, 17=RegisterMirror, 21=PublishPost, 29=CashierLogin, 34=OpenStockOrder

### 2.5 Deposit Details (First and Last)

**What**: First and last deposit details including processor, funding type, amount, and date.

**Columns Involved**: FirstDepositDate, FirstDepositAmount, FirstDepositProcessor, FirstDepositFundingType, LastDepositDate, LastDepositAmount, LastDepositFundingType

**Rules**:
- FirstDeposit: Sourced via Dim_Customer.FTDTransactionID joined to Fact_BillingDeposit (IsFTD=1), enriched with Dim_FundingType.Name and Dim_BillingDepot.Name
- LastDeposit: From today's Fact_CustomerAction ActionTypeID=7 rows joined back to Fact_BillingDeposit
- FirstDepositAttempt: From Fact_FirstCustomerAction WHERE ActionTypeID=27 (deposit attempt)
- Amount is in USD (Amount * ExchangeRate for last deposit)

### 2.6 Credit and Equity Snapshot

**What**: Daily credit and realized equity from V_Liabilities, updated only for yesterday's date.

**Columns Involved**: `Credit`, `RealizedEquity`

**Rules**:
- Only updated when `@date = @yesterday` (i.e., running for the most recent day)
- `Credit = ISNULL(V_Liabilities.Credit, 0)`
- `RealizedEquity = ISNULL(V_Liabilities.RealizedEquity, 0)`

### 2.7 Funded Status (IsFundedNew)

**What**: Whether the customer meets all four funded criteria today.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- `IsFundedNew`: 1 if customer is in the result set of Function_Population_Funded(@dateINT), else 0. The function requires: (1) past first-funded date, (2) positive combined equity across TP/eMoney/Options
- `FirstNewFundedDate`: From Function_Population_First_Time_Funded(). Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Only set once (WHERE NULL)
- `LastNewFundedDate`: COALESCE of MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1 and current Function_Population_Funded result

### 2.8 FTD Speed Flag

**What**: Whether the customer's first deposit was within 7 days of registration.

**Columns Involved**: `FTDIsLessThanAWeek`

**Rules**:
- `CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0 THEN 1 ELSE 0 END`
- Only computed for customers registered in the last 10 days

### 2.9 Copy Milestones

**What**: First and last time another customer started copying this customer's trades.

**Columns Involved**: `FirstTimeBeingCopied`, `LastTimeBeingCopied`

**Rules**:
- Source: Dim_Mirror WHERE OpenOccurred in today's date range, grouped by ParentCID
- First: MIN(OpenOccurred), only if current value is NULL or > @date
- Last: MAX(OpenOccurred), always updated

### 2.10 Verification Dates

**What**: First date each verification level was reached, plus email and phone verification dates.

**Columns Involved**: `VerificationLevel1Date`, `VerificationLevel2Date`, `VerificationLevel3Date`, `EmailVerifiedDate`, `EvMatchStatusDate`, `PhoneVerifiedDate`

**Rules**:
- Sourced from Fact_SnapshotCustomer joined to Dim_Range (FromDateID)
- VerificationLevelNDate = MIN(FromDateID) WHERE VerificationLevelID = N
- Backfill logic: if Level 3 date is set but Level 2 is NULL, Level 2 is set to Level 3 date (cascade)
- EmailVerifiedDate = MIN(FromDateID) WHERE IsEmailVerified = 1
- EvMatchStatusDate = MIN(FromDateID) WHERE EvMatchStatus = 2
- PhoneVerifiedDate from BackOffice history WHERE PhoneVerifiedID IN (1,2)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) with CLUSTERED INDEX on CID. Single-customer lookups are optimal (data-local). Cross-customer aggregations by Channel, Country, or Region work well with the columnstore segment elimination on the clustered index. 46.7M rows -- manageable for full scans but prefer filtered queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer lifecycle summary | `SELECT * WHERE CID = @cid` |
| FTD funnel (registered → first deposit) | `SELECT Channel, COUNT(*) WHERE FirstDepositDate IS NOT NULL GROUP BY Channel` |
| Time-to-first-deposit | `DATEDIFF(DAY, registered, FirstDepositDate) WHERE FirstDepositDate > '1900-01-01'` |
| Currently funded customers | `WHERE IsFundedNew = 1` |
| Active copiers (Popular Investors) | `WHERE FirstTimeBeingCopied IS NOT NULL` |
| Recently contacted customers | `WHERE LastContactDate >= DATEADD(DAY, -7, GETDATE())` |
| Verification funnel | `COUNT by VerificationLevel3Date IS NOT NULL vs IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Extended customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID | Country details beyond Name/Region |
| DWH_dbo.Dim_Regulation | ON RegulationID | Regulation name |
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | ON CID = RealCID AND DateID | Daily status for a specific date |

### 3.4 Gotchas

- **46.7M rows, NOT all customers**: Only IsValidCustomer=1 customers. Invalid customers (PlayerLevelID=4, LabelID 26/30, CountryID=250) are actively deleted each run
- **~40 deprecated columns**: Many columns carry NULL/0 for all rows. See the Elements table for individual deprecation notes. Do not use deprecated columns for analytics
- **FirstDepositDate sentinel**: `1900-01-01` means no deposit, not a historical deposit. Filter `WHERE FirstDepositDate > '1900-01-01'` for depositors
- **FirstLeadDate sentinel**: Set to `1900-01-01` universally -- deprecated
- **Credit/RealizedEquity**: Only updated when SP runs for yesterday's date. Not a real-time snapshot -- reflects previous day's end-of-day values
- **registered is MIN(demo, real)**: Not the real-account registration date. For real-only registration, use Dim_Customer.RegisteredReal
- **Channel defaults to 'Direct'**: ISNULL(Channel, 'Direct') is applied in the SP. Customers without an affiliate mapping show 'Direct'
- **Manager is concatenated**: `FirstName + ' ' + LastName` from Dim_Manager. NULL if no manager assigned
- **IsFundedNew can toggle**: A customer can be funded one day and not the next (if equity drops to 0). It reflects the CURRENT day's funded status, not a permanent flag
- **FirstNewFundedDate is permanent**: Once set, it is never overwritten (WHERE NULL guard). It represents the graduation date, not a daily status

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 -- upstream wiki verbatim | (Tier 1 -- {source}) |
| Tier 2 -- SP ETL code | (Tier 2 -- SP_CIDFirstDates) |
| Tier 3 -- deprecated/not populated | (Tier 3 -- deprecated) |

### 4.1 Customer Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -- Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -- Customer.CustomerStatic) |
| 3 | OriginalCID | int | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 4 | UserName | varchar(500) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 -- Customer.CustomerStatic) |

### 4.2 Acquisition & Classification

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 5 | Club | varchar(500) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 -- Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' -> 'Affiliate', AffiliateID IN (56662,56663) -> 'Direct'. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.Channel. ISNULL default 'Direct' for customers without affiliate mapping. (Tier 2 -- SP_CIDFirstDates via Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Derived via parallel CASE expression alongside SubChannelID. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.SubChannel. ISNULL default 'Direct'. (Tier 2 -- SP_CIDFirstDates via Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). Dim-lookup from Dim_Label.Name via LabelID. (Tier 1 -- Dictionary.Label) |
| 10 | Country | varchar(500) | YES | Full country name in English. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -- Dictionary.Country) |
| 11 | Language | char(500) | YES | Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected. (Tier 1 -- Dictionary.Language) |
| 12 | Region | nvarchar(500) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Dim-lookup from Dim_Country.Region via CountryID. (Tier 1 -- Dictionary.MarketingRegion) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping. (Tier 1 -- Ext_Dim_Country_Region_Desk) |
| 14 | Email | varchar(500) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 15 | FunnelName | varchar(500) | YES | Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through. (Tier 1 -- Dictionary.Funnel) |
| 16 | DownloadID | int | YES | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 -- Customer.CustomerStatic) |
| 17 | FunnelFromName | varchar(500) | YES | Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID. (Tier 1 -- Dictionary.Funnel) |
| 18 | BannerID | int | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 -- Customer.CustomerStatic) |
| 19 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID. (Tier 1 -- Customer.CustomerStatic) |
| 20 | ReferralID | int | YES | Referral CID -- the customer who referred this customer (for RAF program tracking). (Tier 1 -- Customer.CustomerStatic) |

### 4.3 Account Status & Demographics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | Blocked | int | YES | Account block flag. ETL-computed: 1 when PlayerStatusID IN (2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked), else 0. (Tier 2 -- SP_CIDFirstDates) |
| 22 | Verified | int | YES | KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID. (Tier 1 -- Dictionary.VerificationLevel) |
| 23 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only. (Tier 1 -- Customer.CustomerStatic) |
| 24 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 25 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 -- Customer.CustomerStatic) |
| 26 | CommunicationLanguage | varchar(500) | YES | Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language). (Tier 1 -- Dictionary.Language) |
| 27 | Manager | nvarchar(500) | YES | Assigned account manager full name. ETL-computed: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via AccountManagerID. NULL if no manager assigned. (Tier 2 -- SP_CIDFirstDates) |
| 28 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 -- BackOffice.Customer) |
| 29 | DesignatedRegulationID | int | YES | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 -- BackOffice.Customer) |
| 30 | PrivacyPolicyID | tinyint | YES | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 -- Customer.CustomerStatic) |
| 31 | IP | bigint | YES | Registration IP address as numeric value. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 32 | State | varchar(100) | YES | Full human-readable geographic name of the region -- state, province, or territory. Sourced from Dictionary.RegionName.Name. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = RegionByIP_ID. NULL if region not in the 181-row Dim_State_and_Province table. (Tier 1 -- Dictionary.RegionName) |
| 33 | NewMarketingRegion | varchar(100) | YES | Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE). (Tier 1 -- Ext_Dim_Country) |

### 4.4 Registration & Login Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | registered | datetime | NO | Earliest registration date across demo and real accounts. ETL-computed: MIN(RegisteredDemo, RegisteredReal). Not the real-account-only date. (Tier 2 -- SP_CIDFirstDates) |
| 35 | FirstLoggedIn | datetime | YES | First platform login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 36 | LastLoggedIn | datetime | YES | Most recent platform login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 37 | FirstCashierLogin | datetime | YES | First cashier/billing login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |
| 38 | LastCashierLogin | datetime | YES | Most recent cashier login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |

### 4.5 Deposit Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 39 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first deposit attempt (whether successful or not). From Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 -- SP_CIDFirstDates) |
| 40 | FirstDepositAttemptAmount | numeric(36,12) | YES | Amount of the first deposit attempt in USD. (Tier 2 -- SP_CIDFirstDates) |
| 41 | FirstDepositAttemptProcessor | varchar(500) | YES | Payment processor name for the first deposit attempt. Dim-lookup from Dim_BillingDepot.Name via DepotID. (Tier 2 -- SP_CIDFirstDates) |
| 42 | FirstDepositAttemptFundingType | varchar(500) | YES | Payment method name for the first deposit attempt. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 43 | FirstDepositDate | datetime | YES | Date of first successful deposit. From Dim_Customer.FirstDepositDate via FTDTransactionID join to Fact_BillingDeposit. Sentinel 1900-01-01 = no deposit. (Tier 2 -- SP_CIDFirstDates) |
| 44 | FirstDepositProcessor | varchar(500) | YES | Payment processor name for the first successful deposit. Dim-lookup from Dim_BillingDepot.Name. (Tier 2 -- SP_CIDFirstDates) |
| 45 | FirstDepositFundingType | varchar(500) | YES | Payment method name for the first successful deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 46 | FirstDepositAmount | money | YES | Amount of first deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 -- SP_CIDFirstDates) |
| 47 | Credit | money | YES | Customer credit balance (promotional/bonus credit). Daily snapshot from V_Liabilities.Credit. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 48 | RealizedEquity | money | YES | Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 49 | LastDepositDate | datetime | YES | Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. (Tier 2 -- SP_CIDFirstDates) |
| 50 | LastDepositAmount | money | YES | Most recent deposit amount in USD (Amount * ExchangeRate). (Tier 2 -- SP_CIDFirstDates) |
| 51 | LastDepositFundingType | varchar(500) | YES | Payment method name for the most recent deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 52 | FirstDepositAmountExtended | money | YES | Not populated by current SP. Deprecated. (Tier 3 -- deprecated) |

### 4.6 Trading Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | FirstPosOpenDate | datetime | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 54 | LastPosOpenDate | datetime | YES | Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 55 | FirstMenualPosOpenDate | datetime | YES | First manual (non-copy) position open timestamp. MIN(Occurred) WHERE ActionTypeID=1. Note: column name has typo 'Menual' (not 'Manual'). (Tier 2 -- SP_CIDFirstDates) |
| 56 | LastMenualPosOpenDate | datetime | YES | Most recent manual position open timestamp. MAX(Occurred) WHERE ActionTypeID=1. (Tier 2 -- SP_CIDFirstDates) |
| 57 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open timestamp. MIN(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 58 | LastMirrorPosOpenDate | datetime | YES | Most recent copy-trade position open. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 59 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade mirror registration timestamp. MIN(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 60 | LastMirrorRegistrationDate | datetime | YES | Most recent copy-trade mirror registration. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 61 | FirstStocksOpenDate | datetime | YES | First stock order open timestamp. MIN(Occurred) WHERE ActionTypeID=34. (Tier 2 -- SP_CIDFirstDates) |

### 4.7 Cashout Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 62 | FirstCashoutDate | datetime | YES | First withdrawal timestamp. MIN(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |
| 63 | LastCashoutDate | datetime | YES | Most recent withdrawal timestamp. MAX(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |

### 4.8 Copy & Social Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 64 | FirstTimeBeingCopied | datetime | YES | First time another customer started copying this customer's trades. MIN(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |
| 65 | LastTimeBeingCopied | datetime | YES | Most recent time another customer started copying this customer. MAX(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |

### 4.9 Contact Milestones (Salesforce CRM)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | LastContactDate | datetime | YES | Most recent successful contact date. MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 -- SP_CIDFirstDates) |
| 67 | LastContactDate_ByPhone | datetime | YES | Most recent successful phone contact. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. Dynamically masked. (Tier 2 -- SP_CIDFirstDates) |
| 68 | FirstContactDate | datetime | YES | First successful contact date. MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN successful contacts. (Tier 2 -- SP_CIDFirstDates) |
| 69 | FirstContactDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 70 | LastContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 71 | LastContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 72 | FirstContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 73 | FirstContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |

### 4.10 Verification & Compliance Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | VerificationLevel1Date | datetime | YES | Date customer first reached KYC verification level 1 (basic). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=1. Backfilled from Level 2/3 dates if missing. (Tier 2 -- SP_CIDFirstDates) |
| 75 | VerificationLevel2Date | datetime | YES | Date customer first reached KYC verification level 2 (intermediate). MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from Level 3 date if missing. (Tier 2 -- SP_CIDFirstDates) |
| 76 | VerificationLevel3Date | datetime | YES | Date customer first reached KYC verification level 3 (full KYC). MIN(FromDateID) WHERE VerificationLevelID=3. (Tier 2 -- SP_CIDFirstDates) |
| 77 | EmailVerifiedDate | date | YES | Date customer verified their email address. MIN(FromDateID) from Fact_SnapshotCustomer WHERE IsEmailVerified=1. (Tier 2 -- SP_CIDFirstDates) |
| 78 | EvMatchStatusDate | datetime | YES | Date electronic verification matched (EvMatchStatus=2). MIN(FromDateID) from Fact_SnapshotCustomer. (Tier 2 -- SP_CIDFirstDates) |
| 79 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 -- BackOffice.Customer) |
| 80 | PhoneVerifiedDate | datetime | YES | Date phone number was verified. MIN(ValidFrom) from BackOffice history WHERE PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). (Tier 2 -- SP_CIDFirstDates) |
| 81 | KycModeID | int | YES | KYC workflow mode from ComplianceStateDB.Compliance.CustomerKycMode. Updated via GCID join. (Tier 2 -- SP_CIDFirstDates) |
| 82 | ProfessionalApplicationDate | date | YES | Date the customer applied for MiFID II professional categorization. From ComplianceStateDB.Compliance.CustomerProfessionalQuesti

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `BI_DB_dbo.BI_DB_PositionPnL` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PositionPnL`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md`

# BI_DB_dbo.BI_DB_PositionPnL

## 1. Overview

Daily end-of-day snapshot of **open trading positions** with unrealized P&L, rates, commissions, NOP, and close-price metrics. Grain is **one row per position per calendar day** (`DateID` + `PositionID`); only positions open as of end of `@dt` appear for that `DateID`.

## 2. Business Context

- **Rules**: Positions are sourced from `DWH_dbo.Dim_Position` with `OpenDateID < @ReportDateID` and still open on `@dt` (`CloseDateID >= @ReportDateID` or `CloseDateID = 0`). `Dim_PositionChangeLog` rewinds `Amount`, `StopRate`, `AmountInUnitsDecimal`, and `IsSettled` when changes occur after `@dt`; rows with partial-close child (`ChangeTypeID = 11`) after `@dt` are removed. Stock splits adjust `InitForexRate`, units, and EOD rates via `Dim_HistorySplitRatio` and `#Prices`. **PositionPnL** is `PnLInDollars` from Dim_Position (authoritative PnL engine) since 2024-03-24; **Price** and **NOP** still use SP formulas from EOD rates and `Dim_Instrument` FX chains. **DailyPnL** is updated after load as today `PositionPnL` minus prior day `PositionPnL` per `PositionID`.
- **Consumers**: Finance and CMR reporting; downstream BI_DB procedures and views (e.g. crypto zero / loan / NOP stacks, IFRS, compliance, dashboards) read this table as the canonical daily position P&L snapshot.

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object type** | Table |
| **Column count** | 39 |
| **Distribution** | `HASH (PositionID)` |
| **Clustered index** | `(DateID ASC, Date ASC, CID ASC, PositionID ASC)` |
| **Partitioning** | `PARTITION (DateID RANGE LEFT FOR VALUES (...))` -- daily boundaries aligned with main table (typically 2015 through current horizon) |
| **Nonclustered index** | `IX_BI_DB_PositionPnL_CID` on `(DateID, CID)` on main table (per deployment; switch staging builds CID NCIs on switch tables) |

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CID) |
| 2 | PositionID | bigint | NO | Unique position key; Synapse distribution key. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PositionID) |
| 3 | InstrumentID | int | NO | Traded instrument. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InstrumentID) |
| 4 | MirrorID | int | YES | Copy-trading mirror link when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.MirrorID) |
| 5 | Commission | money | NO | Opening commission in dollars. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Commission) |
| 6 | InitForexRate | numeric(16,8) | NO | Open rate; split-adjusted in SP when position spans a split. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InitForexRate / split logic) |
| 7 | SpreadedPipBid | numeric(16,8) | YES | Bid with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipBid) |
| 8 | SpreadedPipAsk | numeric(16,8) | YES | Ask with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipAsk) |
| 9 | PositionPnL | decimal(16,4) | YES | Unrealized P&L in USD; from `PnLInDollars` (replaces legacy formula). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PnLInDollars) |
| 10 | Price | numeric(38,6) | YES | Per-unit price-move expression × USD conversion factor from `#Pre_UnrealizedPnL` (bid/ask vs InitForexRate and instrument FX chain). (Tier 2 -- SP_PositionPnL, computed from #OpenPositions + Dim_Instrument + #Prices) |
| 11 | HedgeServerID | int | YES | Hedge server for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.HedgeServerID) |
| 12 | Amount | money | NO | Position amount in USD; rewound via `Dim_PositionChangeLog` when SL/partial-close edits after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Amount / PositionChangeLog.PreviousAmount) |
| 13 | AmountInUnitsDecimal | numeric(16,6) | YES | Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.AmountInUnitsDecimal / split + PositionChangeLog) |
| 14 | LimitRate | numeric(16,8) | NO | Take-profit rate. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.LimitRate) |
| 15 | StopRate | numeric(16,8) | NO | Stop-loss rate; rewound to `PreviousStopRate` when edited after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.StopRate / PositionChangeLog) |
| 16 | IsBuy | bit | NO | Long (1) vs short (0). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.IsBuy) |
| 17 | Occurred | datetime | NO | Position open timestamp (`OpenOccurred`). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.OpenOccurred) |
| 18 | Date | date | YES | Snapshot calendar date `@dt`. (Tier 3 -- SP_PositionPnL, parameter @dt) |
| 19 | DateID | int | NO | Snapshot date as YYYYMMDD; partition key. (Tier 3 -- SP_PositionPnL, CAST(CONVERT(CHAR(8),@dt,112) AS INT)) |
| 20 | UpdateDate | datetime | YES | Row load timestamp at insert (`GETDATE()`). (Tier 3 -- SP_PositionPnL, GETDATE()) |
| 21 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (`ChangeTypeID = 13`) when applicable. (Tier 5 — Expert Review) |
| 22 | NOP | money | YES | Net open position in USD from units × pair rate × direction × conversion (see `#Pre_UnrealizedPnL`). (Tier 2 -- SP_PositionPnL, computed) |
| 23 | DailyPnL | decimal(16,4) | YES | Day-over-day change: `PositionPnL - prior day PositionPnL` (NULL until post-switch UPDATE). (Tier 3 -- SP_PositionPnL, UPDATE vs prior DateID) |
| 24 | Leverage | int | YES | Position leverage. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Leverage) |
| 25 | RateBid | numeric(36,12) | YES | EOD bid from latest `Fact_CurrencyPriceWithSplit` row before `@ReportDate`, split-adjusted; uses `BidLastWithoutSpread` when discounted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 26 | RateAsk | numeric(36,12) | YES | EOD ask from same price row, split-adjusted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 27 | USD_CR | money | YES | End-of-day conversion rate used with PnL context; from Dim_Position `CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 28 | SettlementTypeID | int | YES | Modern settlement type from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SettlementTypeID) |
| 29 | EstimateCloseFeeForCFD | numeric(19,8) | YES | Estimated close fee for CFD from production PnL inputs. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeForCFD) |
| 30 | EstimateCloseFeeOnOpenByUnits | numeric(19,8) | YES | Estimated close fee per units-at-open path. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpenByUnits) |
| 31 | EstimateCloseFeeOnOpen | numeric(19,8) | YES | Estimated close fee from open parameters. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpen) |
| 32 | Close_PnLInDollars | decimal(19,4) | YES | Official close-price P&L in dollars from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PnLInDollars) |
| 33 | Close_CalculationRate | decimal(18,8) | YES | Rate used for close P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_CalculationRate) |
| 34 | Close_ConversionRate | decimal(18,8) | YES | FX conversion at close for regulated P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_ConversionRate) |
| 35 | Close_PriceType | int | YES | Close price type indicator from upstream PnL. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PriceType) |
| 36 | CurrentCalculationRate | numeric(18,8) | YES | Max-date calculation rate for last-bid style P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentCalculationRate) |
| 37 | CurrentConversionRate | numeric(18,8) | YES | Conversion rate paired with current calculation rate (same source family as USD_CR). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 38 | Close_NOP | numeric(18,8) | YES | NOP using close rates: `AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |
| 39 | Current_NOP | numeric(18,8) | YES | NOP using current rates: `AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |

## 5. Relationships

**Source tables (ETL read path)**

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Open positions, PnL dollars, fees, close/current rates, core attributes |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Latest bid/ask before `@ReportDate` per instrument |
| DWH_dbo.Dim_HistorySplitRatio | Split boundaries and ratios for rate/unit adjustment |
| DWH_dbo.Dim_PositionChangeLog | Rewind deletes/updates for post-`@dt` changes |
| DWH_dbo.Dim_Instrument (+ self-joins / #Prices) | Instrument currency pair and USD cross for Price and NOP |

**Consumers (representative)**

Includes finance and CMR pipelines and many BI_DB dependents such as **`BI_DB_Crypto_Zero`**, **`BI_DB_Real_Crypto_Loan`**, **`BI_DB_DailyZero_TreeSize_NEW`** (and related daily zero / NOP procedures), plus roll-over and dividend logic (**`SP_RollOverFee_Dividends`** reads prior-day `AmountInUnitsDecimal`), IFRS, compliance, and diagnostics. Confirm additional references with a repo search on `BI_DB_PositionPnL`.

## 6. ETL & Lifecycle

| Aspect | Detail |
|--------|--------|
| **Writer** | `BI_DB_dbo.SP_PositionPnL` @dt |
| **OpsDB** | Priority **99**, ProcessType **4** (FinanceReportSPS), frequency **Daily** |
| **Pattern** | Build `#UnrealizedPnL` -- create `BI_DB_PositionPnL_SWITCH_SINGLE` with same distribution/index/partition scheme as main table -- `INSERT ... SELECT` from `#UnrealizedPnL` -- `SP_BI_DB_PositionPnL_SWITCH` partition swap -- `UPDATE` **DailyPnL** vs previous `DateID` |
| **Grain** | One row per open `PositionID` per `DateID` |
| **Delete scope** | Daily partition replaced via switch for the target `DateID` (not a full-table DELETE) |

## 7. Query Advisory

- **Partition elimination**: Always filter **`WHERE DateID = ...` or a tight `DateID` range**; scanning all daily partitions is prohibitively expensive.
- **Distribution**: **`PositionID`** is the hash key -- joins and GROUP BY on `PositionID` minimize movement; filtering large sets by `CID` alone may benefit from **`IX_BI_DB_PositionPnL_CID (DateID, CID)`** when present.
- **Semantics**: Table holds **open** positions only for each snapshot date; closed-position economics live in `Dim_Position` / fact tables.
- **DailyPnL**: Populated in a second step; for intraday copies of switch tables, expect NULL until the main-table UPDATE runs.

## 8. Classification & Status

| Field | Value |
|-------|--------|
| **Domain** | Finance / trading P&L and exposure |
| **Sensitivity** | Customer and position-level financial data -- internal use only |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


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


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_CorpDevDashboard`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CorpDevDashboard.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_CorpDevDashboard] @date [date] AS 
     
/********************************************************************************************      
Author:      Amir Gurewitz       
Date:        2021-05-24      
Description: Aggregate Data from MonthlyPanel fixed for CorpDev Dashboard
      
**************************      
** Change History      
**************************      
Date         Author       Description       
      
07-06.21     Amir	      Adding Actions Column
24-06-21     Amir         Fix First Action Issue
18-10-21     Amir         Add AUA BY AssetType
22-12-21     Jan          Add Social Data and  MaxFunded
----------    ----------   ------------------------------------*/      

--exec [BI_DB_dbo].[SP_CorpDevDashboard] '20230509'

BEGIN  

--DECLARE @date DATE = cast(getdate()-1 as date)
DECLARE @SdateINT INT =  YEAR(@date)*100+MONTH(@date) 
DECLARE @dateINT  INT = [BI_DB_dbo].DateToDateID(@date)


-----Like (funded)-----
IF OBJECT_ID('tempdb..#Like') IS NOT NULL DROP TABLE #Like
CREATE TABLE #Like  
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP)
AS
SELECT YEAR(a.ActionDate)*100+MONTH(a.ActionDate) YearMonth
      ,bdcmpfd.Region
      ,COUNT (DISTINCT a.RealCID) Liked
FROM [BI_DB_dbo].[BI_DB_Social_Activity] a WITH(NOLOCK)
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] bdcmpfd WITH(NOLOCK) ON a.RealCID= bdcmpfd.CID AND YEAR(a.ActionDate)*100+MONTH(a.ActionDate)=bdcmpfd.Active_Month
WHERE a.ActionTypeID =3 
  AND bdcmpfd.IsEOM_Funded_NEW = 1 
  AND YEAR(a.ActionDate)*100+MONTH(a.ActionDate)=@SdateINT
GROUP BY YEAR(a.ActionDate)*100+MONTH(a.ActionDate)
         ,bdcmpfd.Region


-------Share (funded)------
IF OBJECT_ID('tempdb..#Share') IS NOT NULL DROP TABLE #Share
CREATE TABLE #Share  
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP)
AS
SELECT YEAR(a.ActionDate)*100+MONTH(a.ActionDate) YearMonth
      ,bdcmpfd.Region
      ,COUNT (DISTINCT a.RealCID) Shared
FROM [BI_DB_dbo].[BI_DB_Social_Activity] a WITH(NOLOCK)
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] bdcmpfd WITH(NOLOCK) ON a.RealCID= bdcmpfd.CID  AND YEAR(a.ActionDate)*100+MONTH(a.ActionDate)=bdcmpfd.Active_Month
WHERE a.ActionTypeID =4 
  AND bdcmpfd.IsEOM_Funded_NEW = 1 
  AND YEAR(a.ActionDate)*100+MONTH(a.ActionDate)=@SdateINT
GROUP BY YEAR(a.ActionDate)*100+MONTH(a.ActionDate)
          ,bdcmpfd.Region


-----Were copied (funded)----
IF OBJECT_ID('tempdb..#WereCopied') IS NOT NULL DROP TABLE #WereCopied
CREATE TABLE #WereCopied  
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP)
AS
SELECT  YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred) YearMonth
       ,bdcmpfd.Region
	   ,COUNT (DISTINCT bdgc.ParentCID) WereCopied
FROM [BI_DB_dbo].[BI_DB_Guru_Copiers] bdgc WITH(NOLOCK)
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] bdcmpfd WITH(NOLOCK) ON bdgc.ParentCID= bdcmpfd.CID  AND YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)=bdcmpfd.Active_Month 
WHERE bdcmpfd.IsEOM_Funded_NEW = 1 
  AND YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)=@SdateINT
GROUP BY YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)
            ,bdcmpfd.Region


------Copied other (funded)------
IF OBJECT_ID('tempdb..#CopiedOther') IS NOT NULL DROP TABLE #CopiedOther
CREATE TABLE #CopiedOther  
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP)
AS
SELECT YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred) YearMonth
      ,bdcmpfd.Region
	  ,COUNT (DISTINCT bdgc.CID) CopiedOther
FROM [BI_DB_dbo].[BI_DB_Guru_Copiers] bdgc WITH(NOLOCK)
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] bdcmpfd WITH(NOLOCK) ON bdgc.CID= bdcmpfd.CID  AND YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)=bdcmpfd.Active_Month
WHERE bdcmpfd.IsEOM_Funded_NEW = 1 
  AND YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)=@SdateINT
GROUP BY YEAR(bdgc.Occurred)*100+MONTH(bdgc.Occurred)
          ,bdcmpfd.Region

/****************************************************************************************************************/
IF OBJECT_ID('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp
CREATE TABLE #tmp  
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP)
AS
SELECT mp.Active_Month
      ,mp.ActiveDate
	  ,'All' AS Indicator
      ,CASE WHEN  mp.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN mp.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		    WHEN mp.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	   ELSE 'Europe' END AS Region
      ,mp.EOM_Club
	  ,NULL AS Age
	  ,NULL AS  FirstAction
	  ,NULL  AS FirstCross
      ,0 AS Regs
	  ,COUNT(DISTINCT mp.CID) AS CIDs
	  ,SUM(mp.IsEOM_Funded_NEW) EOM_IsFunded
	  ,COUNT(DISTINCT CASE WHEN mp.Seniority_FundedNew = 0 THEN mp.CID ELSE NULL END) AS NewFundedAccounts
	  ,SUM(mp.NewTrades_Copy) AS NewTrades_Copy
	  ,SUM(mp.NewTrades_Total) AS NewTrades_Total
	  ,SUM(mp.A_Revenue_Currencies) AS Revenue_Currencies
	  ,SUM(mp.A_Revenue_Commodities) AS Revenue_Commodities
	  ,SUM(mp.A_Revenue_Crypto) AS Revenue_Crypto
	  ,SUM(mp.A_Revenue_Equities) AS Revenue_Equities
	  ,SUM(mp.Revenue_Total) AS Revenue_Total
	  ,SUM(mp.EOM_Equity) AS EOM_Equity
	  ,0 AS  Actions
	  ,0 AS EOM_AUA_Currencies
	  ,0 AS EOM_AUA_Commodities
	  ,0 AS EOM_AUA_Crypto
	  ,0 AS EOM_AUA_Equities
	  ,SUM(mp.TotalDeposits) AS Total_Deposits
	  ,SUM(mp.TotalCashouts) AS Total_Cashouts
	  ,SUM(mp.PnL_Total)  AS Total_PnL
	  ,0 AS Liked
	  ,0 AS Shared
	  ,0 AS WereCopied
	  ,0 AS CopiedOther
	 ,SUM(mp.IsFunded_New) MaxFunded
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] mp WITH(NOLOCK)
WHERE mp.Active_Month = @SdateINT
GROUP BY mp.Active_Month
        ,mp.ActiveDate
        ,CASE WHEN mp.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
              WHEN mp.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
	  		  WHEN mp.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	     ELSE 'Europe' END
	     ,mp.EOM_Club

UNION

SELECT YEAR(fd.FirstActionDate)*100+MONTH(fd.FirstActionDate) 
      ,DATEFROMPARTS(YEAR(fd.FirstActionDate),MONTH(fd.FirstActionDate),1)
	  ,'FA'
	  ,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
	        WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	   ELSE 'Europe' END 
      ,NULL
	  ,NULL
	  ,fd.FirstActionTypeNew
	  ,fd.FirstCrossNew
      ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,COUNT(*) 
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
	  ,0
FROM [BI_DB_dbo].[BI_DB_First5Actions]  fd  WITH(NOLOCK)
WHERE YEAR(fd.FirstActionDate)*100+MONTH(fd.FirstActionDate) = @SdateINT
  AND fd.FirstActionTypeNew IS NOT NULL
GROUP BY YEAR(fd.FirstActionDate)*100+MONTH(fd.FirstActionDate) 
        ,DATEFROMPARTS(YEAR(fd.FirstActionDate),MONTH(fd.FirstActionDate),1)
		,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
              WHEN Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
			  WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
		 ELSE 'Europe' END 
	    ,fd.FirstActionTypeNew
	    ,fd.FirstCrossNew

UNION

SELECT YEAR(fd.registered)*100+MONTH(fd.registered) 
      ,DATEFROMPARTS(YEAR(fd.registered),MONTH(fd.registered),1)
	  ,'Regs'
	  ,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		    WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
       ELSE 'Europe' END 
     ,NULL
	 ,NULL
	 ,NULL
	 ,NULL
     ,COUNT(*)
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH(NOLOCK)
WHERE YEAR(fd.registered)*100+MONTH(fd.registered)  = @SdateINT
GROUP BY YEAR(fd.registered)*100+MONTH(fd.registered) 
        ,DATEFROMPARTS(YEAR(fd.registered),MONTH(fd.registered),1)
		,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
              WHEN Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		      WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
		 ELSE 'Europe' END 

UNION

SELECT YEAR(mp.ActiveDate)*100+MONTH(mp.ActiveDate) 
      ,DATEFROMPARTS(YEAR(mp.ActiveDate),MONTH(mp.ActiveDate),1)
	  ,'Age'
	  ,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN fd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
	        WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	   ELSE 'Europe' END 
     ,mp.EOM_Club
	 ,SUM(DATEDIFF(DAY, fd.BirthDate, mp.ActiveDate) / 365.25)
	 ,NULL
	 ,NULL
	 ,0
     ,COUNT(*)
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] mp WITH(NOLOCK)
LEFT JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH(NOLOCK) ON mp.CID = fd.CID AND fd.FirstDepositDate IS NOT NULL
WHERE IsFunded_New = 1
GROUP BY YEAR(mp.ActiveDate)*100+MONTH(mp.ActiveDate) 
        ,DATEFROMPARTS(YEAR(mp.ActiveDate),MONTH(mp.ActiveDate),1)
		,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
              WHEN fd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		      WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
		 ELSE 'Europe' END 
       ,mp.EOM_Club

UNION

SELECT YEAR(mp.Date)*100+MONTH(mp.Date) 
      ,DATEFROMPARTS(YEAR(mp.Date),MONTH(mp.Date),1)
	  ,'AUA'
	  ,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN fd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		    WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	   ELSE 'Europe' END 
     ,NULL
	 ,NULL
	 ,NULL
	 ,NULL
	 ,0
     ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,SUM(CASE WHEN di.InstrumentTypeID = 1 THEN mp.Amount + mp.PositionPnL ELSE 0 END) AS EOM_AUA_Currencies
	 ,SUM(CASE WHEN di.InstrumentTypeID = 2 THEN mp.Amount + mp.PositionPnL ELSE 0 END) AS EOM_AUA_Commodities
	 ,SUM(CASE WHEN di.InstrumentTypeID = 10 THEN mp.Amount + mp.PositionPnL ELSE 0 END) AS EOM_AUA_Crypto
	 ,SUM(CASE WHEN di.InstrumentTypeID IN(4,5,6) THEN mp.Amount + mp.PositionPnL ELSE 0 END) AS EOM_AUA_Equities
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
FROM [BI_DB_dbo].[BI_DB_PositionPnL]  mp WITH(NOLOCK)
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH(NOLOCK) ON mp.CID = fd.CID 
JOIN [DWH_dbo].[Dim_Instrument] di ON mp.InstrumentID = di.InstrumentID
WHERE fd.FirstDepositDate IS NOT NULL
  AND mp.DateID = @dateINT
GROUP BY YEAR(mp.Date)*100+MONTH(mp.Date) 
        ,DATEFROMPARTS(YEAR(mp.Date),MONTH(mp.Date),1)
		,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
              WHEN fd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
		      WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
		 ELSE 'Europe' END 
    
UNION

SELECT YEAR(fd.ActiveDate)*100+MONTH(fd.ActiveDate) 
      ,DATEFROMPARTS(YEAR(fd.ActiveDate),MONTH(fd.ActiveDate),1)
	  ,'Soc'
	  ,CASE WHEN  fd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
            WHEN fd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
	        WHEN fd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
	   ELSE 'Europe' END 
     ,NULL
	 ,NULL
	 ,NULL
	 ,NULL
	 ,0
     ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,0
	 ,ISNULL(l.Liked,0)
	 ,ISNULL(s.Shared,0) 
	 ,ISNULL(wc.WereCopied,0)
	 ,ISNULL(co.CopiedOther,0) 
	 ,0
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] fd WITH(NOLOCK)
LEFT JOIN #Like l ON fd.Region = l.Region AND l.YearMonth=YEAR(fd.ActiveDate)*100+MONTH(fd.ActiveDate)
LEFT JOIN #Share s ON YEAR(fd.ActiveDate)*100+MONTH(fd.ActiveDate) = s.YearMonth AND fd.Region = s.Region
LEFT JOIN #WereCopied wc ON fd.Region = wc.Region AND YEAR(fd.ActiveDate)*100+MONTH(fd.ActiveDate) = wc.YearMonth
LEFT JOIN #CopiedOther co ON fd.Region = co.Region AND YEAR(fd.ActiveDate)*100+MONTH(fd.ActiveDate) = co.YearMonth
WHERE fd.Active_Month = @SdateINT

/**************************************************************************************************************/

DELETE FROM [BI_DB_dbo].[BI_DB_CorpDevDashboard]
WHERE Active_Month = @SdateINT

INSERT INTO [BI_DB_dbo].[BI_DB_CorpDevDashboard]
SELECT Active_Month
        ,ActiveDate
		,Indicator
		,Region
		,EOM_Club
	    ,Age
		,FirstAction
		,FirstCross
		,Regs
		,CIDs
		,EOM_IsFunded
		,NewFundedAccounts
		,NewTrades_Copy
		,NewTrades_Total
		,Revenue_Currencies
		,Revenue_Commodities
		,Revenue_Crypto
		,Revenue_Equities
		,Revenue_Total
		,EOM_Equity		
       ,GETDATE() AS UpdateDate 
		,Actions
		,EOM_AUA_Currencies
		,EOM_AUA_Commodities
		,EOM_AUA_Crypto
		,EOM_AUA_Equities
		,Total_Deposits
		,Total_Cashouts
		,Total_PnL
		,Liked
	    ,Shared
	    ,WereCopied
	    ,CopiedOther
		 ,MaxFunded
FROM #tmp t

END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_CorpDevDashboard` | synapse_sp | BI_DB_dbo | SP_CorpDevDashboard | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CorpDevDashboard.sql` |
| `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_MonthlyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |
| `BI_DB_dbo.BI_DB_First5Actions` | synapse | BI_DB_dbo | BI_DB_First5Actions | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md` |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | synapse | BI_DB_dbo | BI_DB_CIDFirstDates | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `BI_DB_dbo.BI_DB_PositionPnL` | synapse | BI_DB_dbo | BI_DB_PositionPnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

