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
- **Object**: `BI_DB_Q_AML_FSA_Report_end_InvestorType`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_Q_AML_FSA_Report_end_InvestorType/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Q_AML_FSA_Report_end_InvestorType\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Q_AML_FSA_Report_end_InvestorType\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Q_AML_FSA_Report_end_InvestorType]
(
	[Investor_Type] [nvarchar](250) NULL,
	[EndDateID] [int] NULL,
	[TradingVolume] [money] NULL,
	[TradingValueUSD] [money] NULL,
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

Found 21 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_SnapshotCustomer` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotCustomer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md`

# DWH_dbo.Fact_SnapshotCustomer

> Daily SCD Type 2 snapshot of every eToro customer's current state — the central customer-attribute table powering regulatory reporting, risk, and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Ext_FSC_Real_Customer_Customer (CC), Ext_FSC_BackOffice_Customer (BO), Ext_FSC_BackOffice_RegulationChangeLog, Ext_FSC_Customer_FirstTimeDeposits, Ext_FSC_PhoneCustomer, Ext_FSC_StocksLending, Ext_Dim_Customer_CustomerIdentification_DLT |
| **Refresh** | Daily via MERGE (SP_Fact_SnapshotCustomer), orchestrated by SP_Fact_SnapshotCustomer_DL_To_Synapse |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI(RealCID ASC) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked; matches `_generic_pipeline_mapping.json` generic_id=1115, `business_group` DWH). Unmasked PII export: `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`. |
| **UC Format** | delta |
| **UC Partitioned By** | N/A (view is unpartitioned) |
| **UC Table Type** | Two UC targets: `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked) + `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked) |

---

## 1. Business Meaning

Fact_SnapshotCustomer is the central customer state table in the DWH. For every eToro customer (RealCID), it holds one row per distinct attribute state within a year, recording which attributes were active between FromDate and ToDate (encoded together in `DateRangeID`). The pattern is SCD Type 2 by year: each year's rows are closed as attribute changes occur, and a new open row is created with the updated state. At year-end, all open rows are closed and reopened with the new year's date range.

As of 2026-03-19: **406M+ total rows**, **46.4M distinct customers**, data from **2007-08-22 to present**. 302M rows are "currently open" (ToDate = year-end). 11.9% of current open rows represent depositors; 98.0% are valid customers (IsValidCustomer=1).

The SP loads data from 6 source systems via staging Ext_FSC tables pre-populated by SP_Fact_SnapshotCustomer_DL_To_Synapse. The core CC (Customer Core) source provides demographics and status; the BO (Back Office) source provides risk/compliance attributes. RegulationID is taken from RegulationChangeLog — **not** from Back Office — because regulation changes take effect end-of-day.

8 legacy columns (DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist) are present in the DDL but NOT populated by the current SP. They carry DEFAULT (0) values.

---

## 2. Business Logic

### 2.1 SCD Type 2 Pattern — DateRangeID

**What**: Each customer-state row has a DateRangeID encoding both the open date (FromDate) and close date (ToDate) as a 12-digit bigint.

**Columns Involved**: `DateRangeID`, `RealCID`

**Rules**:
- DateRangeID = `YYYYMMDD` (open date, 8 chars) + `MMDDD` (year-end month+day, 4 chars) → e.g., `202603101231` = opened 2026-03-10, closes 2026-12-31
- When an attribute changes, the SP updates DateRangeID of the existing row to close it (right 4 chars become yesterday's MMDD), then inserts a new row with today's open date + year-end
- To get the **most current row** per customer: `RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'`
- On January 1st: all prior year's open rows are closed (12-31) and re-opened for the new year
- The `Dim_Range` dimension table stores FromDateID + ToDateID for each DateRangeID

### 2.2 IsValidCustomer — Segment Flag

**What**: Computed flag indicating whether a customer is a "valid" retail customer for analytics (excludes demo, blocked countries, excluded labels).

**Columns Involved**: `IsValidCustomer`, `PlayerLevelID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsValidCustomer = 1 IF:
  PlayerLevelID <> 4 (not demo)
  AND LabelID NOT IN (30, 26) (not internal/excluded label)
  AND CountryID <> 250 (not blocked country)
ELSE 0
```
Pre-2020-03-14 rule additionally excluded AccountTypeID=9.

### 2.3 IsCreditReportValidCB — Credit Reporting Flag

**What**: Flag indicating whether a customer is eligible for credit report validation (CB = CreditBureau context).

**Columns Involved**: `IsCreditReportValidCB`, `PlayerLevelID`, `AccountTypeID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsCreditReportValidCB = 1 IF:
  NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)  (not non-real demo)
  AND LabelID NOT IN (26, 30)
  AND NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243))
ELSE 0
```

### 2.4 RegulationID — End-of-Day Rule

**What**: A customer's regulatory jurisdiction is taken from RegulationChangeLog (end-of-day change), NOT from the back-office system (immediate change), because regulation changes take effect at end of day for business/legal reasons.

**Columns Involved**: `RegulationID`, sourced from `Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID`

### 2.5 GDPR Erasure Masking

**What**: When a GDPR deletion request is processed, the UserName in Customer Core gets a `DelUserName` prefix. The SP detects this and masks Email, City, Address, Zip, and PhoneNumber in Fact_SnapshotCustomer.

**Columns Involved**: `Email`, `City`, `Address`, `Zip`, `PhoneNumber`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution + CCI makes per-customer aggregations and filters on RealCID highly efficient — queries that filter or join on RealCID benefit from colocation. The NCI on RealCID provides efficient point-lookup for single customers.

**Warning**: With 406M rows, full table scans are expensive. Always filter by DateRangeID or a specific year range when possible.

### 3.1b UC (Databricks) Storage

**In Databricks**, the data is accessed via `V_Fact_SnapshotCustomer_FromDateID` (generic_id=1115), not directly. Two UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` — full PII (gated access)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` — Email/City/Address/Zip masked

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current state for all customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Current state for one customer | `WHERE RealCID = @cid AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Customer state on a specific date | `WHERE RealCID = @cid AND LEFT(CAST(DateRangeID AS VARCHAR(12)),8) <= @date AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) >= RIGHT(@date, 4)` |
| Count of depositors | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsDepositor = 1` |
| Valid retail customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsValidCustomer = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name/region |
| DWH_dbo.Dim_Label | ON f.LabelID = dl.LabelID | Brand/label name |
| DWH_dbo.Dim_Language | ON f.LanguageID = dl.LanguageID | Customer language |
| DWH_dbo.Dim_VerificationLevel | ON f.VerificationLevelID = dv.VerificationLevelID | KYC verification status |
| DWH_dbo.Dim_PlayerStatus | ON f.PlayerStatusID = dp.PlayerStatusID | Account lifecycle status |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_AccountStatus | ON f.AccountStatusID = das.AccountStatusID | Account enabled/disabled |
| DWH_dbo.Dim_Range | ON f.DateRangeID = dr.DateRangeID | Decode FromDateID + ToDateID |
| DWH_dbo.Fact_Guru_Copiers | ON f.RealCID = fg.RealCID | Copy-trading activity |

### 3.4 Gotchas

- **DateRangeID is NOT a date** — it is a 12-digit bigint encoding (FromDate)(ToDate MMDD). Always extract with LEFT(...,8) for FromDate and RIGHT(...,4) for ToDate MMDD.
- **Most-current-row filter**: `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` gets the currently open row, but after year-end closure this may temporarily return 0 rows. Use `MAX(DateRangeID)` per RealCID as a safer alternative.
- **Legacy columns with 0 defaults**: DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist are all DEFAULT 0 and NOT populated by the current SP. Do not rely on them.
- **PII masking**: Email, City, Address, Zip are dynamically masked (`MASKED WITH (FUNCTION = 'default()')`). Users without `UNMASK` permission see NULL. PhoneNumber is NOT masked at DDL level but is GDPR-erased via the SP for deleted users.
- **WeekendFeePrecentage** (note: typo in column name — "Precentage" instead of "Percentage") — use as-is.
- **AccountStatusID distribution**: 1=93.2% (Active), 0=6.1% (unknown/default), 2=0.9% (Inactive). Only 3 distinct values observed.
- **Not exported directly to UC** — join via `V_Fact_SnapshotCustomer_FromDateID` in UC.

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
| 1 | GCID | int | NO | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 2 | RealCID | int | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 3 | DemoCID | int | YES | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 4 | CustomerChangeTypeID | tinyint | YES | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=Insert, 2=Update). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 5 | CurentValue | int | YES | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 6 | PreviousValue | int | YES | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 7 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 8 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 9 | LanguageID | int | YES | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | VerificationLevelID | int | YES | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | DocsOK | smallint | YES | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 12 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | Bankruptcy | smallint | YES | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 16 | CommunicationLanguageID | int | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | PremiumAccount | smallint | YES | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 18 | Evangelist | smallint | YES | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 19 | GuruStatusID | smallint | YES | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 20 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 21 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | DateRangeID | bigint | YES | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | PendingClosureStatusID | tinyint | YES | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | DocumentStatusID | int | YES | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | IsEmailVerified | int | YES | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | DesignatedRegulationID | int | YES | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | EvMatchStatus | int | YES | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | RegionID | int | YES | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | PlayerStatusReasonID | int | YES | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | Email | nvarchar(50) | YES | Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | City | nvarchar(50) | YES | Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Address | nvarchar(100) | YES | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | Zip | nvarchar(50) | YES | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | PhoneNumber | varchar(30) | YES | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneVerificationDateID | varchar(8) | YES | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | WeekendFeePrecentage | int | YES | Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | DltStatusID | int | YES | DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | DltID | nvarchar(100) | YES | DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | EquiLendID | varchar(4000) | YES | EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | StocksLendingStatusID | int | YES | Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source System | Source Object | Source Column | Transform |
|---------------|--------------|---------------|---------------|-----------|
| RealCID | Customer Core (CC) | Ext_FSC_Real_Customer_Customer | CID | Passthrough |
| GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) |
| CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) |
| LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) |
| LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) |
| PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) |
| CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) |
| AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) |
| PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) |
| IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) |
| PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) |
| RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) |
| PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) |
| PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) |
| WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) |
| AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) |
| Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking |
| City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking |
| Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking |
| Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking |
| VerificationLevelID | Back Office (BO) | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) |
| RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) |
| RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) |
| GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) |
| AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) |
| AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) |
| DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) |
| SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) |
| MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) |
| DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) |
| EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) |
| RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) — end-of-day |
| IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID exists in FTD table |
| PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') |
| IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 |
| PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 |
| DltStatusID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| DltID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending |
| StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending |
| DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) |
| IsValidCustomer | ETL-computed | N/A | N/A | CASE on PlayerLevelID, LabelID, CountryID |
| IsCreditReportValidCB | ETL-computed | N/A | N/A | CASE on PlayerLevelID, AccountTypeID, LabelID, CountryID |
| UpdateDate | ETL-computed | N/A | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → Ext_FSC_BackOffice_Customer
  → Ext_FSC_BackOffice_RegulationChangeLog

FTD System → CustomerFinanceDB_Customer_FirstTimeDeposits
  → Ext_FSC_Customer_FirstTimeDeposits

Phone Verification → ContactVerification_Phone_Customer
  → Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → Ext_Dim_Customer_CustomerIdentification_DLT

Stocks Lending → ComplianceStateDB_Compliance_StocksLending
  → Ext_FSC_StocksLending

[All above via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  → SP_Fact_SnapshotCustomer(@dt) [MERGE + DateRange update]
  → DWH_dbo.Fact_SnapshotCustomer
```

| Step | Object | Description |
|------|--------|-------------|
| Source Load | SP_Fact_SnapshotCustomer_DL_To_Synapse | Loads 6 Ext_FSC staging tables from DL, then calls inner SP |
| ETL | SP_Fact_SnapshotCustomer (Author: Boris Slutski, 2018-03-11) | MERGE: close existing rows + INSERT new rows + Dim_Range update |
| Target | DWH_dbo.Fact_SnapshotCustomer | DWH customer snapshot table |
| UC Export | V_Fact_SnapshotCustomer_FromDateID (generic_id=1115) | Daily Merge to UC (two targets: PII + masked) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country name/region |
| LabelID | DWH_dbo.Dim_Label | Brand/label name |
| LanguageID | DWH_dbo.Dim_Language | Language name |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC tier |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account lifecycle status |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Real vs demo tier |
| RiskStatusID | DWH_dbo.Dim_RiskStatus | Risk status |
| RiskClassificationID | DWH_dbo.Dim_RiskClassification | Risk classification |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Popular Investor status |
| RegulationID / DesignatedRegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| AccountStatusID | DWH_dbo.Dim_AccountStatus | Account enabled/disabled |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type |
| DocumentStatusID | DWH_dbo.Dim_DocumentStatus | KYC document status |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons | Status reason code |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | eVerify match status |
| PendingClosureStatusID | DWH_dbo.Dim_PendingClosureStatus | Closure status |
| DateRangeID | DWH_dbo.Dim_Range | SCD2 date range decode |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Guru_Copiers | RealCID | SP_Fact_Guru_Copiers joins FSC for guru/copier state |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | All columns | Databricks export view (generic_id=1115) |
| DWH_dbo.V_Fact_SnapshotCustomer | All columns | Alternative view (not in generic mapping) |
| DWH_dbo.Dim_Range | DateRangeID | SP inserts new DateRangeIDs into Dim_Range |

---

## 7. Sample Queries

### 7.1 Current customer state for a single customer

```sql
SELECT
    f.RealCID,
    f.GCID,
    f.AccountStatusID,
    f.PlayerStatusID,
    f.CountryID,
    f.RegulationID,
    f.IsDepositor,
    f.IsValidCustomer,
    f.DateRangeID,
    LEFT(CAST(f.DateRangeID AS VARCHAR(12)), 8) AS FromDateYYYYMMDD
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
WHERE f.RealCID = 12345678
  AND RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231';
```

### 7.2 Count of valid retail depositors by country (current snapshot)

```sql
SELECT
    dc.CountryName,
    COUNT(DISTINCT f.RealCID) AS depositor_count
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
JOIN [DWH_dbo].[Dim_Country] dc ON f.CountryID = dc.CountryID
WHERE RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231'
  AND f.IsDepositor = 1
  AND f.IsValidCustomer = 1
GROUP BY dc.CountryName
ORDER BY depositor_count DESC;
```

### 7.3 Customers who changed regulation during 2025 (history)

```sql
SELECT
    f.RealCID,
    f.Regula

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Range` — synapse
- **Resolved as**: `DWH_dbo.Dim_Range`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`

# DWH_dbo.Dim_Range

> DWH-internal date range helper table mapping (FromDate, ToDate) pairs as composite keys, used by Snapshot analytics to efficiently join year-to-date and multi-period equity/customer snapshots.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-internal (generated by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer) |
| **Refresh** | Daily - INSERT-only accumulation by Snapshot SPs |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time.

This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted.

As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side.

---

## 2. Business Logic

### 2.1 DateRangeID Encoding

**What**: DateRangeID is a deterministic composite key encoding both FromDate and MMDD(ToDate) into a single 12-digit BigInt.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- Formula: `DateRangeID = CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`
- Example: FromDateID=20070101, ToDateID=20071231 -> DateRangeID=200701011231
- Decoding FromDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 8))`
- Decoding ToDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 4) + RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4))`
- The YEAR component of ToDateID is always the SAME as the YEAR of FromDateID (only MMDD of ToDate is stored in the last 4 digits)

**Diagram**:
```
DateRangeID (12-digit BigInt):
  [ YYYY | MM | DD | MM | DD ]
  [  From Year  | From MMDD  | To MMDD ]
   |___________|             |________|
   Chars 1-8 = FromDateID    Chars 9-12 = MMDD(ToDate)

  ToDateID = YYYY(FromDate) + MMDD(ToDate)
  -> Year-end range example:
     FromDate=2020-03-15, ToDate=2020-12-31
     DateRangeID = 202003151231
     ToDateID    = 20201231
```

### 2.2 Snapshot Range Pattern

**What**: Dim_Range is the bridge between individual customer dates and fiscal/calendar year-end periods in Snapshot reports.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- The primary use case is "from customer registration/event date to year-end": FromDate = customer's start date, ToDate = December 31 of that year
- The SPs also generate non-year-end ranges when snapshots require partial-period measurements
- The table grows daily as new snapshot dates are processed
- No deduplication needed - DateRangeID uniqueness is enforced by the NOT EXISTS check in both SPs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a composite CLUSTERED INDEX on (DateRangeID, FromDateID, ToDateID) and three Non-Clustered Indexes: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, and IX_Dim_Range_FromDateID_ToDateID. The NCI indexes are unusual for Synapse (which typically uses only CCI) and suggest heavy range-based lookups by the Snapshot SPs. Always filter on FromDateID or ToDateID directly to leverage these indexes.

Note: PRIMARY KEY (DateRangeID) is declared NOT ENFORCED - Synapse does not validate uniqueness but the ETL SPs maintain it via NOT EXISTS guards.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` is Parquet. With 1.3M rows, consider filtering on FromDateID for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the DateRangeID for a specific (from, to) pair | `SELECT DateRangeID FROM DWH_dbo.Dim_Range WHERE FromDateID = @from AND ToDateID = @to` |
| Find all ranges starting from a given date | `WHERE FromDateID = @date` (uses IX_Dim_Range_FromDateID) |
| Look up range details from a DateRangeID | `SELECT FromDateID, ToDateID FROM DWH_dbo.Dim_Range WHERE DateRangeID = @id` |
| Check how many ranges exist for a year | `WHERE FromDateID BETWEEN @year*10000+101 AND @year*10000+1231` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotEquity | DateRangeID | Resolve snapshot equity date ranges |
| DWH_dbo.Fact_SnapshotCustomer | DateRangeID | Resolve snapshot customer date ranges |
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | View-level access to snapshot equity with resolved ranges |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridging |

### 3.4 Gotchas

- **ToDate YEAR = FromDate YEAR**: The DateRangeID encoding only stores MMDD of ToDate. The year of ToDate is derived from FromDate's year. This means all ranges in this table are within-year ranges - cross-year ranges cannot be represented.
- **INSERT-only, no TRUNCATE**: Both writer SPs use NOT EXISTS guards, making the table append-only. Rows are never deleted. If a DateRangeID is erroneously created, it persists forever.
- **Primary key NOT ENFORCED**: Synapse does not verify uniqueness of DateRangeID. Trust the ETL logic, not the constraint.
- **DateRangeID is a STRING-derived number**: Always treat DateRangeID as a derived key, not a business ID. Decode using LEFT/RIGHT string operations if needed.
- **1.3M rows for a dim table**: Larger than typical dimensions. REPLICATE is appropriate given daily Snapshot SP joins from all distributions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3b - DDL structure | `(Tier 3b - DDL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateRangeID | bigint | NO | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 2 | FromDateID | int | NO | Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 3 | ToDateID | int | NO | End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateRangeID | DWH-internal (computed) | - | ETL-computed: CONCAT(YYYYMMDD(@date), MMDD(@largedate)) |
| FromDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 8) |
| ToDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 4) + RIGHT(DateRangeID, 4) |
| UpdateDate | - | - | ETL-computed: GETDATE() at insert time |

### 5.2 ETL Pipeline

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT new DateRangeIDs --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
```

| Step | Object | Description |
|------|--------|-------------|
| Writer 1 | SP_Fact_SnapshotEquity | INSERTs new (FromDate, ToDate) pairs from #outputdata temp table (Action='UPDATE') |
| Writer 2 | SP_Fact_SnapshotCustomer | INSERTs new (FromDate, ToDate) pairs from #outputdata and #UpdatedRanges temp tables |
| Guard | NOT EXISTS check | Both SPs use NOT EXISTS to prevent duplicate DateRangeIDs |
| Target | DWH_dbo.Dim_Range | Append-only. 1.3M rows as of 2026-03-10 |
| Export | Generic Pipeline (daily) | Exports to dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - DateRangeID, FromDateID, and ToDateID are DWH-internal keys with no external FK targets.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | Snapshot equity view with date range context |
| DWH_dbo.V_Fact_SnapshotEquity_FromDateID | DateRangeID / FromDateID | Snapshot equity filtered by customer registration date |
| DWH_dbo.V_Fact_SnapshotCustomer | DateRangeID | Snapshot customer view with date range context |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | DateRangeID / FromDateID | Snapshot customer filtered by registration date |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridge view |

---

## 7. Sample Queries

### 7.1 Decode a DateRangeID back to its components
```sql
SELECT
    DateRangeID,
    FromDateID,
    ToDateID,
    -- Verify encoding formula
    CONVERT(BIGINT,
        LEFT(CONVERT(VARCHAR(12), DateRangeID), 4)
        + RIGHT(CONVERT(VARCHAR(12), DateRangeID), 4)
    ) AS ToDateID_decoded
FROM [DWH_dbo].[Dim_Range]
WHERE DateRangeID = 200701011231
```

### 7.2 Find all year-end ranges (FromDate to Dec 31 of same year)
```sql
SELECT DateRangeID, FromDateID, ToDateID
FROM [DWH_dbo].[Dim_Range]
WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'
ORDER BY FromDateID DESC
```

### 7.3 Count ranges per year
```sql
SELECT
    LEFT(CAST(FromDateID AS VARCHAR(8)), 4) AS FromYear,
    COUNT(*) AS range_count
FROM [DWH_dbo].[Dim_Range]
GROUP BY LEFT(CAST(FromDateID AS VARCHAR(8)), 4)
ORDER BY FromYear DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 3 T2, 1 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Range | Type: Table | Production Source: DWH-internal (SP_Fact_SnapshotEquity + SP_Fact_SnapshotCustomer)*


### Upstream `DWH_dbo.Dim_PlayerStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md`

# DWH_dbo.Dim_PlayerStatus

> Permission matrix table defining 16 account restriction states (Normal through Block Deposit & Trading) that control which platform capabilities -- trading, deposits, withdrawals, login, social, and copy-trading -- are enabled for each customer.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerStatus defines 16 distinct account restriction states in the eToro platform, each encoding a granular permission matrix controlling what a user can and cannot do. Unlike Dim_AccountStatus (binary open/closed), PlayerStatus provides fine-grained control over trading, deposits, withdrawals, social features, and copy-trading. This enables compliance and fraud teams to surgically restrict specific capabilities without full account lockout.

The data originates from `etoro.Dictionary.PlayerStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override) to the data lake, and `SP_Dictionaries_DL_To_Synapse` loads it via TRUNCATE + INSERT, plus a separate sentinel INSERT for ID=0 (N/A placeholder). The ETL adds 4 computed columns (DWHPlayerStatusID, StatusID, UpdateDate, InsertDate) and **drops 2 production columns** (`CanCopy` and `GetsInterest`).

PlayerStatusID is stored in Dim_Customer and is read by virtually every user-facing operation -- login, trading, funding, social posting, and copy-trading -- to enforce permission checks. The permission flags are queried directly from this table rather than hardcoded in business logic.

---

## 2. Business Logic

### 2.1 Permission Matrix System

**What**: Each player status defines a complete set of boolean permissions that gate platform features.

**Columns Involved**: `IsBlocked`, `CanEditPosition`, `CanOpenPosition`, `CanClosePosition`, `CanDeposit`, `CanRequestWithdraw`, `CanLogin`, `CanChatAndPost`, `CanBeCopied`

**Rules**:
- **Full Block** (IsBlocked=1): IDs 2, 4, 6, 7, 8, 14 -- user cannot log in. All capabilities disabled.
- **Partial Restriction**: IDs 3, 9, 10, 11, 12, 13, 15 -- user can access some features but not others.
- **Full Access**: IDs 1, 5 -- all capabilities enabled. ID=5 (Warning) is identical to Normal in permissions but signals compliance flagging.
- **Close-Only / Wind-Down**: IDs 9 (Trade & MIMO Blocked) and 15 (Block Deposit & Trading) -- user can close existing positions and log in, but cannot open new positions or deposit.

**Diagram**:
```
Access Level Summary:
  ID=1  Normal                -- All capabilities ON
  ID=5  Warning               -- All ON + compliance flag
  ID=3  Chat Blocked          -- All ON except CanChatAndPost
  ID=10 Deposit Blocked       -- All ON except CanDeposit
  ID=12 Copy Block            -- All ON except CanBeCopied (note: DWH lacks CanCopy col)
  ID=9  Trade & MIMO Blocked  -- Close+Login only; no open/deposit/withdraw
  ID=13 Pending Verification  -- Close+Login only
  ID=15 Block Deposit&Trading -- Close+Login+Chat+Copy; no open/deposit
  ID=11 Social Index          -- All ON except CanDeposit + CanRequestWithdraw
  ID=2  Blocked               -- ALL OFF (full lockout, cannot login)
  ID=4  Blocked Upon Request  -- ALL OFF (self-requested lockout)
  ID=6  Under Investigation   -- ALL OFF (compliance hold)
  ID=7  Scalpers Block        -- ALL OFF (trading abuse)
  ID=8  PayPal Investigation  -- ALL OFF (payment fraud)
  ID=14 Failed Verification   -- ALL OFF (KYC failure)
  ID=0  N/A                   -- All OFF (DWH ETL placeholder)
```

### 2.2 Status Transition Patterns

**What**: Common pathways between player statuses driven by compliance, fraud, and user lifecycle events.

**Columns Involved**: `PlayerStatusID`

**Rules**:
- New accounts: 1 (Normal) or 13 (Pending Verification) depending on regulation
- Compliance investigation: 1 -> 6 (Under Investigation) -> 1 (cleared) or 2 (blocked)
- KYC timeout: 13 (Pending) -> 14 (Failed Verification) if docs not submitted
- Self-service closure: 1 -> 4 (Blocked Upon Request)
- Scalping detection: 1 -> 7 (Scalpers Block)
- PayPal fraud: 1 -> 8 (PayPal Investigation)
- Wind-down: 1 -> 9 or 15 (close-only mode for accounts under investigation)

### 2.3 Schema Drift -- Dropped Production Columns

**What**: Two production permission columns are not loaded into DWH.

**Dropped**:
- `CanCopy` (bit, default 1) -- whether user can copy other traders. Status 12 (Copy Block) sets this to 0.
- `GetsInterest` (bit) -- whether overnight fees/credits apply to user's positions. NOT available in DWH.

**Impact**: Analysts cannot determine from DWH whether a given status blocks copy-trading (CanCopy) or overnight interest (GetsInterest). For these, query production or the upstream wiki.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP means no CCI/sort -- for 16 rows this is irrelevant to performance, but row order is arbitrary without ORDER BY. Always join on `PlayerStatusID`. With REPLICATE, JOINs are zero-cost (all nodes have a full copy).

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed. Full scan of 16 rows is trivial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve a PlayerStatusID to a name | JOIN Dim_PlayerStatus ON PlayerStatusID |
| Find customers who cannot trade | JOIN Dim_Customer, filter CanOpenPosition = 0 or IsBlocked = 1 |
| Count customers by restriction category | GROUP BY IsBlocked + CanOpenPosition combination |
| Find wind-down accounts (close-only) | Filter CanClosePosition = 1 AND CanOpenPosition = 0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusID = dps.PlayerStatusID | Resolve status name and permission flags per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusID = dps.PlayerStatusID | View-level status resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusID = dps.PlayerStatusID | Customer status in daily snapshots |

### 3.4 Gotchas

- **HEAP index**: Like Dim_PlayerLevel, this table uses HEAP. No guaranteed row order without ORDER BY.
- **ID=0 sentinel**: All permission bits are 0 for ID=0 (N/A). LEFT JOIN if the fact table may have NULL or missing PlayerStatusID.
- **CanCopy and GetsInterest are MISSING**: These two production columns are not in DWH. Analysts needing copy-block or interest-eligibility logic must use production data.
- **Status 5 (Warning) = same permissions as Status 1 (Normal)**: All permission flags are identical. The only difference is the compliance signal encoded in the ID itself.
- **Status names have trailing spaces**: Live data shows "Blocked" with trailing whitespace for some status names (e.g., Name column for ID=2). Apply RTRIM() in comparisons if matching by name string.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusID | int | NO | Primary key identifying the restriction state. 0=N/A (sentinel), 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. FK from Dim_Customer. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 2 | Name | varchar(50) | NO | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 3 | IsBlocked | bit | NO | Master block flag. 1 for statuses 2, 4, 6, 7, 8, 14 -- ALL capabilities disabled including login. 0 for statuses where individual CanX flags control granular permissions. Checked by login and order entry procedures. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 4 | CanEditPosition | bit | YES | Whether the user can modify existing position parameters (SL/TP/trailing stop). False when IsBlocked=1 and for close-only statuses (9, 13, 15). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 5 | CanOpenPosition | bit | YES | Whether the user can open new trading positions. False when IsBlocked=1 and for close-only statuses (9, 13, 15). True for all active/warning/partial statuses. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 6 | CanClosePosition | bit | YES | Whether the user can close existing positions. True even for most restricted statuses -- regulators require users to be able to exit. Only IsBlocked=1 statuses set this to False. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 7 | CanDeposit | bit | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only statuses (9, 15), status 10 (Deposit Blocked), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 8 | CanRequestWithdraw | bit | YES | Whether the user can request withdrawals. False for full-block statuses (IsBlocked=1), close-only statuses (9, 13, 15), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 9 | CanLogin | bit | YES | Whether the user can authenticate and access the platform. False when IsBlocked=1. True for all partial-restriction statuses -- wind-down users can view their portfolio. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 10 | CanChatAndPost | bit | YES | Whether the user can post to the social feed or chat. False when IsBlocked=1 and for status 3 (Chat Blocked). True for all other statuses including close-only. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 11 | CanBeCopied | bit | YES | Whether other users can start copying this user's trades. False when IsBlocked=1. Used to hide restricted users from the CopyTrader marketplace. Note: CanCopy (whether THIS user can copy others) is NOT loaded into DWH. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 12 | DWHPlayerStatusID | int | YES | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerStatusID] AS [DWHPlayerStatusID]. 0 for the ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 13 | StatusID | int | YES | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. Standard DWH ETL convention for SP_Dictionaries_DL_To_Synapse-loaded tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 14 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 15 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusID | Dictionary.PlayerStatus | PlayerStatusID | passthrough |
| Name | Dictionary.PlayerStatus | Name | passthrough |
| IsBlocked | Dictionary.PlayerStatus | IsBlocked | passthrough |
| CanEditPosition | Dictionary.PlayerStatus | CanEditPosition | passthrough |
| CanOpenPosition | Dictionary.PlayerStatus | CanOpenPosition | passthrough |
| CanClosePosition | Dictionary.PlayerStatus | CanClosePosition | passthrough |
| CanDeposit | Dictionary.PlayerStatus | CanDeposit | passthrough |
| CanRequestWithdraw | Dictionary.PlayerStatus | CanRequestWithdraw | passthrough |
| CanLogin | Dictionary.PlayerStatus | CanLogin | passthrough |
| CanChatAndPost | Dictionary.PlayerStatus | CanChatAndPost | passthrough |
| CanBeCopied | Dictionary.PlayerStatus | CanBeCopied | passthrough |
| DWHPlayerStatusID | -- | -- | ETL-computed: = PlayerStatusID (redundant surrogate) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |
| InsertDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |

**Dropped from production**: CanCopy (bit), GetsInterest (bit).

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatus.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatus
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/PlayerStatus/
  -> DWH_staging.etoro_Dictionary_PlayerStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatus | 15 rows, 13 columns (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/PlayerStatus/ | Daily full export via Generic Pipeline |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatus | 11 passthrough cols loaded |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; adds 4 computed cols; drops CanCopy, GetsInterest |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1568) | INSERT VALUES for ID=0 N/A sentinel with all-false permissions |
| Target | DWH_dbo.Dim_PlayerStatus | 16 rows (0-15), 15 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusID | Customer's current account restriction state |
| DWH_dbo.V_Dim_Customer | PlayerStatusID | View-level customer status |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Daily snapshot of customer restriction state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusID | Year-end snapshot status |

---

## 7. Sample Queries

### 7.1 List all statuses with key permission flags

```sql
SELECT PlayerStatusID,
       Name,
       IsBlocked,
       CanOpenPosition,
       CanClosePosition,
       CanDeposit,
       CanLogin
FROM   [DWH_dbo].[Dim_PlayerStatus]
WHERE  PlayerStatusID > 0
ORDER BY PlayerStatusID;
```

### 7.2 Count customers by restriction category

```sql
SELECT  CASE
            WHEN dps.IsBlocked = 1          THEN 'Full Block'
            WHEN dps.CanOpenPosition = 0    THEN 'Close-Only / Restricted'
            WHEN dps.CanDeposit = 0         THEN 'Deposit Blocked'
            ELSE 'Active'
        END               AS RestrictionCategory,
        dps.Name          AS PlayerStatus,
        COUNT(*)          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.PlayerStatusID > 0
GROUP BY dps.IsBlocked, dps.CanOpenPosition, dps.CanDeposit, dps.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find customers in wind-down state (can close, cannot open)

```sql
SELECT  dc.CID,
        dps.Name   AS PlayerStatus
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.CanClosePosition = 1
        AND dps.CanOpenPosition = 0
        AND dps.PlayerStatusID > 0;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 11 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatus | Type: Table | Production Source: etoro.Dictionary.PlayerStatus*


### Upstream `DWH_dbo.Dim_Regulation` — synapse
- **Resolved as**: `DWH_dbo.Dim_Regulation`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md`

# DWH_dbo.Dim_Regulation

> Lookup table defining the 15 regulatory jurisdictions under which eToro operates globally, with DWH-specific grouping (ClusterRegulationID) for analytics aggregation.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Regulation |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity holding the corresponding license. This classification drives multi-jurisdiction compliance - it determines which rules apply to each customer, what instruments they can trade, what leverage limits are enforced, and how their funds are segregated. (Tier 1 - upstream wiki, Dictionary.Regulation)

RegulationID is one of the most frequently joined columns in the DWH. It is assigned to users at registration (CustomerStatic.RegulationID) and propagated through every subsequent operation - deposits, trading, copy-trading, and compliance reporting. V_Dim_Customer joins Dim_Regulation to resolve the regulation name for every customer.

**DWH vs Production differences**: The DWH strips 6 columns from production (IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID) and adds 3 DWH-specific columns (DWHRegulationID = ID alias, StatusID = hardcoded 1, ClusterRegulationID = grouping logic). Analysts needing US/non-US split or jurisdiction names should reference the upstream wiki or query production via the Bronze layer.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_Regulation. All 15 rows have StatusID=1 (Active). No sentinel row.

---

## 2. Business Logic

### 2.1 ClusterRegulationID Grouping

**What**: The ETL groups certain regulations into a single cluster (ID=1) for analytics aggregation.

**Columns Involved**: `ClusterRegulationID`, `ID`

**Rules**:
- IDs 0 (None), 1 (CySEC), 5 (BVI) -> ClusterRegulationID=1 (grouped as "CySEC/BVI/None" cluster)
- All other IDs -> ClusterRegulationID = ID (each regulation is its own cluster)

**Rationale**: BVI (5) is the non-US fallback regulation for users in jurisdictions without a specific eToro entity. CySEC (1) is the primary EU regulation. None (0) is the sentinel for unassigned users. Grouping them under cluster 1 allows DWH analytics to treat these three as a single reporting unit.

```
ClusterRegulationID mapping:
  ID=0 (None)    -> Cluster 1
  ID=1 (CySEC)   -> Cluster 1
  ID=5 (BVI)     -> Cluster 1
  All others     -> Cluster = ID (FCA=2, NFA=3, ASIC=4, eToroUS=6, ...)
```

### 2.2 DWH Column Gaps vs Production

**What**: The DWH drops 6 production columns that are needed for full compliance analysis.

**Columns Dropped**:
- `IsUSA` - US/non-US jurisdiction flag (critical for instrument availability branching)
- `JurisdictionName` - eToro legal entity name (e.g., "eToro EU", "eToro UK")
- `BankID` - FK to Dictionary.Bank (custodian banking partner)
- `RegulationLongName` - Full formal name (e.g., "Cyprus Securities Exchange Commission")
- `RegulationShortName` - Abbreviated code for compact display
- `DefaultRegulationID` - Self-reference fallback (non-US->BVI, US->eToroUS)

**Impact**: DWH analytics that need US vs non-US split must either hardcode the IDs (6, 7, 8, 12, 14 are US) or join to the Bronze layer. See Section 3.4 Gotchas.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ID. With 15 rows, REPLICATE is optimal. Join on ID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RegulationID to name in customer data | `LEFT JOIN DWH_dbo.Dim_Regulation r ON r.ID = cs.RegulationID` |
| Group analytics by regulation cluster | `GROUP BY r.ClusterRegulationID` |
| US vs non-US split (without IsUSA) | `WHERE r.ID IN (6, 7, 8, 12, 14)` for US; else non-US |
| Full customer record with regulation | Use `DWH_dbo.V_Dim_Customer` (pre-joins Dim_Regulation) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.CustomerStatic / V_Dim_Customer | ON r.ID = cs.RegulationID | Resolve regulation name per customer |
| DWH_dbo.V_Dim_Customer | Dim_Regulation already joined (INNER JOIN on RegulationID) | Use view instead of re-joining |

### 3.4 Gotchas

- **IsUSA not in DWH**: Production Dictionary.Regulation.IsUSA (US=1, non-US=0) is dropped by ETL. DWH analysts must hardcode: US regulations = IDs 6, 7, 8, 12, 14.
- **DWHRegulationID = ID**: These two columns always have the same value. DWHRegulationID is an ETL alias and appears redundant. Prefer ID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **Cluster 1 includes 3 regulations**: ClusterRegulationID=1 covers None (0), CySEC (1), and BVI (5). Aggregating by ClusterRegulationID will merge these three.
- **V_Dim_Customer uses INNER JOIN**: V_Dim_Customer has `INNER JOIN Dim_Regulation ON ID = RegulationID`. Customers with NULL RegulationID would be excluded.
- **Production has 6 more columns**: If you need IsUSA, JurisdictionName, or DefaultRegulationID, use the Bronze/staging layer or etoro.Dictionary.Regulation directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.Regulation)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | DWHRegulationID | tinyint | YES | ETL-computed alias of ID - always equals ID. `[ID] as [DWHRegulationID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field not present in production. Use ID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL (`1 as [StatusID]`). Not present in production Dictionary.Regulation. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate since table is TRUNCATE+INSERTed daily. Not present in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | ClusterRegulationID | tinyint | YES | ETL-computed grouping: `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None (0), CySEC (1), and BVI (5) into cluster 1. All other regulations map to their own ID. Used for analytics aggregation where BVI/CySEC/None are treated as a single reporting unit. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.Regulation | ID | passthrough |
| Name | etoro.Dictionary.Regulation | Name | passthrough |
| DWHRegulationID | - | - | ETL-computed: [ID] aliased as DWHRegulationID |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| ClusterRegulationID | - | - | ETL-computed: CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END |

**Lost from production** (dropped by ETL):

| Production Column | Type | Reason Dropped |
|-------------------|------|----------------|
| IsUSA | tinyint | Not carried to DWH; hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | varchar(30) | Not carried to DWH |
| BankID | int | Not carried to DWH |
| RegulationLongName | varchar(100) | Not carried to DWH |
| RegulationShortName | varchar(50) | Not carried to DWH |
| DefaultRegulationID | int | Not carried to DWH |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.Regulation.md (quality 9.2, 15 rows documented)

### 5.2 ETL Pipeline

```
etoro.Dictionary.Regulation -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Regulation -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_Regulation
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Regulation | 15 current rows (IDs 0-14) |
| Staging | DWH_staging.etoro_Dictionary_Regulation | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRegulationID, StatusID, InsertDate, UpdateDate, ClusterRegulationID. Drops 6 production columns. |
| Target | DWH_dbo.Dim_Regulation | 15 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - production FKs (BankID, DefaultRegulationID) are dropped by ETL.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | ID (INNER JOIN on RegulationID) | Pre-joined customer view resolves regulation name |
| DWH_dbo.CustomerStatic | RegulationID | Every customer assigned a regulation at registration |

---

## 7. Sample Queries

### 7.1 List all regulations with cluster groupings
```sql
SELECT
    ID,
    Name,
    DWHRegulationID,
    ClusterRegulationID,
    StatusID
FROM [DWH_dbo].[Dim_Regulation]
ORDER BY ID
```

### 7.2 US vs non-US regulation breakdown
```sql
SELECT
    CASE WHEN ID IN (6, 7, 8, 12, 14) THEN 'US' ELSE 'Non-US' END AS Region,
    ID,
    Name
FROM [DWH_dbo].[Dim_Regulation]
WHERE ID > 0
ORDER BY Region, ID
```

### 7.3 Customer count by regulation cluster
```sql
SELECT
    r.ClusterRegulationID,
    r.Name AS PrimaryRegulationName,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_Regulation] r ON r.ID = cs.RegulationID
GROUP BY r.ClusterRegulationID, r.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Regulation | Type: Table | Production Source: etoro.Dictionary.Regulation*


### Upstream `DWH_dbo.Dim_Country` — synapse
- **Resolved as**: `DWH_dbo.Dim_Country`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md`

# DWH_dbo.Dim_Country

> Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes. One of the most-referenced dimension tables in the DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Country (primary) + etoro.Dictionary.MarketingRegion (region label) + Ext_Dim_Country (EU flags) + Ext_Dim_Country_Region_Desk (desk/CFKey) + ComplianceStateDB.Compliance.RegulationCountry (regulation) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, full TRUNCATE+INSERT + 3 UPDATE passes) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (non-clustered PK on CountryID NOT ENFORCED) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Country` is one of the most heavily-referenced dimension tables in the DWH. It defines every country and territory the eToro platform recognizes (251 rows: 250 active countries + 1 "Not available" placeholder at CountryID=0). Each row provides geographic classification, regulatory risk attributes, marketing segmentation, and compliance data for users registered from that country.

When a customer registers, their CountryID determines: which regulatory entity governs them (via RegulationID), what AML/KYC scrutiny level applies (IsHighRiskCountry, RiskGroupID), what marketing desk handles them (Desk), and whether they can receive RAF bonuses (IsEligibleForRAFBonusCountry).

The ETL is multi-step: TRUNCATE+INSERT from etoro.Dictionary.Country (primary, joined to etoro.Dictionary.MarketingRegion for the Region label), then three UPDATE passes that patch in EU classification from Ext_Dim_Country, Desk/CFKey from Ext_Dim_Country_Region_Desk, and RegulationID from ComplianceStateDB.Compliance.RegulationCountry. Several columns present in the upstream Dictionary.Country source are dropped in DWH (IsSettlementRestricted, DefaultCurrencyID, LanguageID, IsActive, PhonePrefix, IsoCode).

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 High-Risk Country Flag (Computed)

**What**: IsHighRiskCountry is derived from RiskGroupID in the ETL, not passed through from source. AML-flagged countries trigger enhanced due diligence.

**Columns Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `CASE WHEN RiskGroupID IN (0, 4) THEN 0 ELSE 1 END` -> IsHighRiskCountry
- RiskGroupID=0 (None): 70 countries -> not high risk
- RiskGroupID=4 (Verified before deposit): 2 countries -> not high risk
- RiskGroupID=1 (High risk country): 100 countries -> high risk
- RiskGroupID=2 (High risk for new clients): 71 countries -> high risk
- RiskGroupID=3 (High risk FATF country): 8 countries -> high risk
- High-risk countries trigger enhanced document verification, manual review of first deposit, and reduced transaction monitoring thresholds

**Diagram**:
```
RiskGroupID -> IsHighRiskCountry
0 (None)                  -> 0  (70 countries)
4 (Verified bfr deposit)  -> 0  (2 countries)
1 (High risk)             -> 1  (100 countries)
2 (High risk new clients) -> 1  (71 countries)
3 (High risk FATF)        -> 1  (8 countries)
```

### 2.2 EU vs. European Country Classification

**What**: Two separate flags distinguish full EU membership from broader European geography.

**Columns Involved**: `EU`, `IsEuropeanCountry`

**Rules**:
- EU=1: 27 countries with full EU membership (legal/treaty member states)
- IsEuropeanCountry=1: 66 countries total (27 EU members + 39 other European countries)
- Source: Ext_Dim_Country (manual extension table), not from etoro.Dictionary.Country
- EU=1 always implies IsEuropeanCountry=1. IsEuropeanCountry=1 does NOT imply EU=1.

### 2.3 Region vs. MarketingRegion

**What**: DWH exposes two separate geographic segmentations. `Region` is marketing-driven; the source geographic `RegionID` is dropped.

**Columns Involved**: `Region`, `MarketingRegionID`, `MarketingRegionManualName`, `Desk`

**Rules**:
- `Region` is loaded from etoro.Dictionary.MarketingRegion.Name (y.Name AS Region in SP). It is the marketing region label.
- `MarketingRegionManualName` is a manual override from Ext_Dim_Country - may differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE).
- `Desk` is a sales/support desk assignment from Ext_Dim_Country_Region_Desk, joined via MarketingRegionID.
- The upstream Dictionary.Country source has a geographic `RegionID` pointing to Dictionary.Region - this is NOT loaded to DWH.
- 22 distinct Region values in DWH (South & Central America=40, Africa=38, ROW=38, French=23, etc.)

### 2.4 Dropped Source Columns (Compliance-Critical)

**What**: Several compliance and localization columns present in the upstream source are NOT loaded to DWH.

**Dropped from etoro.Dictionary.Country**:
- `IsSettlementRestricted`: 21 countries restricted to CFD-only trading (cannot hold REAL assets). Includes United States (SEC/FINRA). CRITICAL for compliance analysts.
- `DefaultCurrencyID`: Trading account default currency (USD/EUR/GBP/AUD/CAD/PLN).
- `LanguageID`: UI language default.
- `IsActive`: Whether country is active on platform.
- `PhonePrefix`: International dialing code.
- `IsoCode`: ISO 3166-1 numeric code.
- `RegionID`: Geographic region FK (DWH replaces with text Region label from MarketingRegion).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE (correct for a 251-row dimension - broadcast to all nodes avoids data movement on JOINs). HEAP means no sorted index. The non-clustered PK on CountryID is NOT ENFORCED - duplicates are theoretically possible but prevented by ETL TRUNCATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (251 rows). Z-ORDER on CountryID optional for join optimization.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode country for a customer | `JOIN DWH_dbo.Dim_Country d ON f.CountryID = d.CountryID` |
| Filter high-risk countries | `WHERE d.IsHighRiskCountry = 1` |
| Filter EU customers | `WHERE d.EU = 1` |
| Group by marketing region | `GROUP BY d.Region` |
| Find regulation for a country | `SELECT RegulationID FROM Dim_Country WHERE CountryID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON c.CountryID = d.CountryID | Decode customer country attributes |
| DWH_dbo.Fact_BillingDeposit | ON f.CountryID = d.CountryID | Country-level deposit analytics |
| DWH_dbo.Dim_CountryBin | ON c.CountryID = d.CountryID | BIN-to-country card mapping |
| DWH_dbo.V_Dim_Customer | ON v.CountryID = d.CountryID | Customer view with country decode |

### 3.4 Gotchas

- CountryID=0 ("Not available") is a real row - use `WHERE CountryID > 0` to exclude the placeholder in population-level queries.
- `IsHighRiskCountry` is RECOMPUTED from `RiskGroupID` by the ETL (not passthrough from source). If source IsHighRiskCountry changes but RiskGroupID stays the same, DWH will not reflect the change.
- `IsSettlementRestricted` is NOT in DWH. This critical compliance flag must be looked up in the source etoro.Dictionary.Country if needed.
- `Region` reflects `MarketingRegion.Name`, not the geographic `Dictionary.Region`. The two segmentations differ (e.g., Albania: geographic region=Europe, marketing Region=ROE).
- `DWHCountryID` always equals `CountryID` (redundant copy from SP: `x.CountryID AS DWHCountryID`). Never use both in GROUP BY.
- `StatusID` is hardcoded to 1 for all rows (including CountryID=0). No meaningful variation.
- `InsertDate` and `UpdateDate` are both set to GETDATE() on each daily reload - they reflect ETL run time, not original insert or data change time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki) |
| 2 | Abbreviation | char(2) | NO | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | LongAbbreviation | char(3) | NO | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). Unique per row. Used in some international reporting standards and Compliance.GetCountryLongAbbreviation (WorldCheck KYC/AML integration). (Tier 1 - Dictionary.Country upstream wiki) |
| 4 | Name | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 5 | IsHighRiskCountry | tinyint | YES | AML/compliance risk flag. 0=standard risk, 1=high risk. RECOMPUTED by SP from RiskGroupID: `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. 179 high-risk countries. Triggers enhanced due diligence and stricter transaction monitoring. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows by SP. Intended to indicate active status. In practice carries no variation. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | DWHCountryID | int | NO | Redundant copy of CountryID (set to `x.CountryID AS DWHCountryID` in SP). Always equals CountryID. Retained for legacy compatibility. Do not use both CountryID and DWHCountryID in the same GROUP BY. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily full reload. Reflects ETL run time, not when country data actually changed. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate) on each daily full reload. Not a true insert timestamp - both dates are refreshed on every reload due to TRUNCATE+INSERT. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 11 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join - NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. (Tier 3 - Ext_Dim_Country live data) |
| 12 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 - Ext_Dim_Country_Region_Desk via SP) |
| 13 | RegulationID | int | YES | Regulatory entity ID governing users from this country. Loaded from ComplianceStateDB.Compliance.RegulationCountry via Ext_Dim_Country_Regulation staging. Left join - NULL if country not in compliance mapping. References the regulatory framework (e.g., CySEC, FCA, ASIC). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse via ComplianceStateDB) |
| 14 | CFKey | int | YES | Clearing/settlement framework key for this country's marketing region. Loaded from Ext_Dim_Country_Region_Desk.CFKey via MarketingRegionID join. Exact business meaning unclear - likely maps to a clearing firm or settlement category. (Tier 3 - Ext_Dim_Country_Region_Desk live data) |
| 15 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 - Dictionary.Country upstream wiki) |
| 16 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. (Tier 1 - Dictionary.Country upstream wiki) |
| 17 | IsEligibleForRAFBonusCountry | int | YES | Whether users from this country can participate in the Refer-A-Friend bonus program. Source: CAST(etoro.Dictionary.Country.IsEligibleForRAFBonusCountry AS int) - type cast from bit to int. 1=eligible (most countries), 0=ineligible (regulatory/fraud restrictions). (Tier 1 - Dictionary.Country upstream wiki) |
| 18 | IsEuropeanCountry | int | YES | Whether this country is geographically European (broader than EU membership). 1=European (66 countries total: 27 EU + 39 others), 0=non-European. Source: Ext_Dim_Country manual extension table. Always >= EU flag. (Tier 3 - Ext_Dim_Country live data) |
| 19 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Ext_Dim_Country live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough (nvarchar(max) -> char(2)) |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough (nvarchar(max) -> char(3)) |
| Name | etoro.Dictionary.Country | Name | passthrough |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed: CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END |
| Region | etoro.Dictionary.MarketingRegion | Name | rename (y.Name AS Region via JOIN on MarketingRegionID) |
| StatusID | - | - | ETL-computed (hardcoded constant 1) |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy (x.CountryID AS DWHCountryID, always = CountryID) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| InsertDate | - | - | ETL-computed (GETDATE()) |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE pass (LEFT JOIN on CountryID) |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE pass via Ext_Dim_Country_Regulation staging |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type cast (CAST(bit AS int)) |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE pass (LEFT JOIN on CountryID) |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE pass (LEFT JOIN on CountryID) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10).

### 5.2 ETL Pipeline

```
etoro.Dictionary.Country (x)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial population: 19 cols partially loaded)
  -> UPDATE from DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> TRUNCATE+INSERT DWH_dbo.Ext_Dim_Country_Regulation from DWH_staging.ComplianceStateDB_Compliance_RegulationCountry
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (fully loaded)
```

Note: The same SP also loads Dim_CountryIPAnonymous in the same transaction.

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Country | Master country reference (251 rows). 16-column source, DWH drops 8 columns. |
| Source | etoro.Dictionary.MarketingRegion | Marketing region labels. Provides Region text and MarketingRegionID. |
| Staging | DWH_staging.etoro_Dictionary_Country | Raw staging: 16 cols, HEAP ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT. Computes IsHighRiskCountry from RiskGroupID. Joins MarketingRegion. Hardcodes StatusID=1. Sets GETDATE() for UpdateDate/InsertDate. |
| Patch 1 | DWH_dbo.Ext_Dim_Country | Manual extension table: EU=1/0, IsEuropeanCountry=1/0, MarketingRegionManualName. LEFT JOIN on CountryID. |
| Patch 2 | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk and CFKey lookup by MarketingRegionID. LEFT JOIN on MarketingRegionID=RegionID. |
| Patch 3 | DWH_dbo.Ext_Dim_Country_Regulation | Regulation staging loaded from ComplianceStateDB.Compliance.RegulationCountry. Then LEFT JOIN on CountryID. |
| Target | DWH_dbo.Dim_Country | Final DWH dimension (251 rows). |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MarketingRegionID | etoro.Dictionary.MarketingRegion | Marketing region segment. Implicit FK (not enforced in Synapse). |
| RiskGroupID | etoro.Dictionary.CountryRiskGroup | Country risk classification. Implicit FK (not enforced in Synapse). |
| RegulationID | ComplianceStateDB (Regulation) | Regulatory entity governing country users. Sourced from ComplianceStateDB. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | CountryID | Customer view JOINs to Dim_Country for country attributes. |
| DWH_dbo.Dim_CountryIP | CountryID | IP-to-country lookup table references Dim_Country via Abbreviation join. |
| DWH_dbo.Dim_CountryIPAnonymous | CountryID | Anonymous proxy IP table; CountryID set via Abbreviation-to-CountryID lookup against Dim_Country. |
| DWH_dbo.SP_Fact_BillingDeposit | CountryID | Billing deposit facts reference Dim_Country for country-level analytics. |
| BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table | CountryID | LTV modeling references country dimension. |
| BI_DB_dbo.SP_Group_LTV_Table | CountryID | Group LTV analytics references country dimension. |

---

## 7. Sample Queries

### 7.1 Decode customer country
```sql
SELECT c.CustomerID, d.Name AS Country, d.Region, d.IsHighRiskCountry
FROM [DWH_dbo].[Dim_Customer] c
JOIN [DWH_dbo].[Dim_Country] d ON c.CountryID = d.CountryID
WHERE d.IsHighRiskCountry = 1;
```

### 7.2 Countries by EU membership
```sql
SELECT CountryID, Name, Abbreviation, EU, IsEuropeanCountry, Region
FROM [DWH_dbo].[Dim_Country]
WHERE EU = 1
ORDER BY Name;
```

### 7.3 Risk group distribution
```sql
SELECT RiskGroupID, IsHighRiskCountry, COUNT(*) AS CountryCount
FROM [DWH_dbo].[Dim_Country]
WHERE CountryID > 0
GROUP BY RiskGroupID, IsHighRiskCountry
ORDER BY RiskGroupID;
```

### 7.4 RAF-ineligible countries by region
```sql
SELECT Region, Name, Abbreviation
FROM [DWH_dbo].[Dim_Country]
WHERE IsEligibleForRAFBonusCountry = 0 AND CountryID > 0
ORDER BY Region, Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, 16 VERIFIED columns).

---

*Generated: 2026-03-19 | Quality: 8.8/10 (4 stars) | Phases: 9/14 (full pipeline, no Atlassian)*
*Tiers: 6 T1, 8 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Country | Type: Table | Production Source: etoro.Dictionary.Country + etoro.Dictionary.MarketingRegion + Ext_Dim_Country + ComplianceStateDB*


### Upstream `DWH_dbo.Dim_AccountType` — synapse
- **Resolved as**: `DWH_dbo.Dim_AccountType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md`

# DWH_dbo.Dim_AccountType

> Lookup dimension classifying eToro accounts by ownership type and purpose. Controls feature access, regulatory treatment, fee structures, and compliance monitoring. Sourced daily from etoro.Dictionary.AccountType via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountType is the DWH version of etoro.Dictionary.AccountType. It classifies every eToro account into one of 18 categories based on ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how accounts are monitored for compliance.

Source: etoro.Dictionary.AccountType on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Dictionary/AccountType/ and staged into DWH_staging.etoro_Dictionary_AccountType. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

The DWH table has 19 rows: IDs 0-18. ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP). DWHAccountTypeID is set equal to AccountTypeID by the ETL and carries no additional information. StatusID is hardcoded to 1. UpdateDate and InsertDate are both set to GETDATE() at load time.

Account types are assigned at customer registration and stored in Customer.CustomerStatic. They are read across BackOffice, Trade, Hedge, Billing, and Compliance systems. The account type rarely changes after initial assignment.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types cluster into functional groups that determine system behavior, regulatory treatment, and fee structures.

**Columns Involved**: `AccountTypeID`, `Name`

**Rules**:
- Retail accounts (1=Private, 4=Joint, 14=SMSF, 16=Administrated): Standard users subject to full retail regulation
- Corporate accounts (2=Corporate, 15=Affiliate Corporate): Business entities with enhanced KYC and reporting
- Partner accounts (3=IB, 5=White Label, 6=Affiliate Private, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- Internal accounts (7=Employee, 10=eToro Group, 11=News, 13=Analyst, 17=Funded Employee): eToro-operated accounts with enhanced compliance monitoring
- Managed accounts (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements
- 18=Trust: Registered after the upstream wiki was generated; classification consistent with retail/managed category
- AccountTypeID=0 (N/A): DWH placeholder for NULL-safe JOINs

**Value Map** (19 rows in DWH):

| AccountTypeID | Name | Category |
|---|---|---|
| 0 | N/A | DWH placeholder |
| 1 | Private | Retail |
| 2 | Corporate | Corporate |
| 3 | IB Account | Partner |
| 4 | Joint Account | Retail |
| 5 | White Label | Partner |
| 6 | Affiliate Private Account | Partner |
| 7 | Employee Account | Internal |
| 8 | Custodian | Managed |
| 9 | Fund | Managed |
| 10 | eToro Group Account | Internal |
| 11 | News | Internal |
| 12 | White List | Partner |
| 13 | Analyst | Internal |
| 14 | SMSF | Retail |
| 15 | Affiliate Corporate Account | Corporate |
| 16 | Administrated Account | Retail |
| 17 | Funded Employee Account | Internal |
| 18 | Trust | Retail/Managed |

### 2.2 Fund and Copy Trading Routing

**What**: AccountTypeID=9 (Fund) receives special handling in copy trading and fund management.

**Columns Involved**: `AccountTypeID`

**Rules**:
- AccountTypeID=9 (Fund) accounts have special copy-trading settlement restrictions
- Fund allocation procedures route based on account type
- Hedge procedures use account type to route to correct liquidity accounts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a HEAP index. REPLICATE is correct for a 19-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs with fact tables. HEAP is appropriate for a table this small with no range queries.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 19-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All retail (Private) customers | JOIN Dim_Customer ON AccountTypeID, filter AccountTypeID = 1 |
| Fund accounts and their performance | JOIN fact tables on CID, filter AccountTypeID = 9 |
| Internal vs external account split | CASE WHEN AccountTypeID IN (7,10,11,13,17) THEN 'Internal' ELSE 'External' END |
| Resolve type ID to name | JOIN Dim_AccountType ON AccountTypeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID | Resolve account type for each customer |

### 3.4 Gotchas

- **DWHAccountTypeID = AccountTypeID**: This column is always equal to AccountTypeID. It is an ETL artifact with no additional information -- do not use it as a join key when AccountTypeID is available.
- **Name, not AccountTypeName**: The DWH column is called `Name` (not `AccountTypeName` like the production source). When joining or comparing to upstream wikis, note the rename.
- **ID=0 from production source**: Unlike other DWH Dim_ tables, the ID=0 (N/A) placeholder row comes from the production Dictionary.AccountType table itself, not from an explicit DWH SP insert.
- **18=Trust not in upstream wiki**: Type 18 (Trust) appears in the DWH live data but was added after the upstream Dictionary.AccountType wiki was generated.
- **StatusID always 1**: Hardcoded by ETL convention, carries no business meaning.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | int | NOT NULL | Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. Referenced by Dim_Customer.AccountTypeID. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 2 | Name | varchar(50) | NOT NULL | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 | DWHAccountTypeID | int | NOT NULL | ETL surrogate key. Set equal to AccountTypeID by SP_Dictionaries_DL_To_Synapse (SELECT AccountTypeID AS DWHAccountTypeID). Carries no additional information beyond AccountTypeID. Present for DWH schema consistency with other Dim_ tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | NOT NULL | ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | NOT NULL | ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | Passthrough |
| Name | etoro.Dictionary.AccountType | AccountTypeName | Passthrough (renamed) |
| DWHAccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | ETL-computed: SELECT AccountTypeID AS DWHAccountTypeID |
| StatusID | - | - | ETL-computed: hardcoded to 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| InsertDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountType -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/AccountType/ -> DWH_staging.etoro_Dictionary_AccountType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_AccountType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountType | 19-row production lookup (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/AccountType/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_AccountType | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; DWHAccountTypeID=AccountTypeID; StatusID=1; UpdateDate/InsertDate=GETDATE() |
| Target | DWH_dbo.Dim_AccountType | 19 rows (ID=0 through ID=18) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountTypeID | etoro.Dictionary.AccountType | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountTypeID | Customer account type lookup (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all account types

```sql
SELECT AccountTypeID, Name
FROM [DWH_dbo].[Dim_AccountType]
ORDER BY AccountTypeID
-- Returns: 0=N/A, 1=Private, 2=Corporate ... 18=Trust
```

### 7.2 Count customers by account type

```sql
SELECT
    dat.Name AS AccountTypeName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_AccountType] dat
    ON dc.AccountTypeID = dat.AccountTypeID
WHERE dat.AccountTypeID > 0
GROUP BY dat.Name
ORDER BY CustomerCount DESC
```

### 7.3 Internal vs external account breakdown

```sql
SELECT
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END AS AccountCategory,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer]
GROUP BY
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.0/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_AccountType | Type: Table | Production Source: etoro.Dictionary.AccountType*


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

### Upstream `DWH_dbo.Dim_MifidCategorization` — synapse
- **Resolved as**: `DWH_dbo.Dim_MifidCategorization`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md`

# DWH_dbo.Dim_MifidCategorization

> 6-row regulatory reference table mapping MifidCategorizationID to the MiFID II customer classification tier -- identifying each customer as Retail, Professional, or Elective Professional under EU MiFID II financial regulation, which determines applicable leverage limits, margin requirements, and investor-protection rules.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.MifidCategorization (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (MifidCategorizationID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (6 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_MifidCategorization` maps the MiFID II customer classification IDs used throughout the eToro platform to human-readable tier names. MiFID II (Markets in Financial Instruments Directive II) is the EU regulatory framework governing retail and professional financial clients. Customer classification determines leverage caps, margin requirements, negative balance protection eligibility, and disclosure obligations.

The 6 rows define the complete classification space:

| ID | Name | Meaning |
|----|------|---------|
| 0 | None | Not classified / not applicable (e.g., US customers not subject to MiFID) |
| 1 | Retail | Standard retail client -- maximum investor protection, lowest leverage limits |
| 2 | Professional | Institutional or experienced investor -- lower protection, higher leverage allowed |
| 3 | Elective professional | Retail client who has applied for professional status (opted-up) |
| 4 | Retail Pending | Retail classification in progress (e.g., registration not yet complete) |
| 5 | Pending | General pending state (categorization in progress) |

ETL: part of `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_MifidCategorization`).

---

## 2. Business Logic

### 2.1 MiFID II Classification Tiers

**What**: Customer accounts are classified into one of these tiers based on their trading experience, financial knowledge, and portfolio size.

**Rules**:
- **Retail (1)**: The default classification. ESMA leverage caps apply (e.g., 30:1 for major forex). Full investor protection: negative balance protection, margin close-out rules.
- **Professional (2)**: Reserved for institutional clients and high-net-worth individuals meeting regulatory criteria. Higher leverage allowed; reduced investor protections.
- **Elective Professional (3)**: A retail client who has voluntarily opted up to professional status after meeting specific criteria (trading frequency, portfolio size, experience). eToro-specific status that lies between 1 and 2.
- **None (0)**: Not subject to MiFID II (e.g., US-regulated accounts under CFTC/NFA rules, or unclassified system accounts).
- **Retail Pending (4) / Pending (5)**: Transitional states during onboarding or reclassification.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get customer MiFID tier by name | `JOIN Dim_MifidCategorization ON MifidCategorizationID; SELECT Name` |
| Find all retail customers | `WHERE MifidCategorizationID = 1` |
| Find professional/elective-professional | `WHERE MifidCategorizationID IN (2, 3)` |
| Exclude unclassified/pending | `WHERE MifidCategorizationID IN (1, 2, 3)` |

### 3.2 Gotchas

- **MifidCategorizationID=0 is NOT a null-sentinel for EU customers**: For EU customers, 0 means "not classified" which may be a data quality issue. NULL is different from 0.
- **UpdateDate is GETDATE() at load**: Does not reflect when the classification definitions last changed in production.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — Dictionary (upstream wiki) | `(Tier 1 — Dictionary.MifidCategorization)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MifidCategorizationID | int | NO | MiFID II client classification tier: 0=None (non-EU), 1=Retail (full protection, default), 2=Professional (reduced protection), 3=Elective Professional (opted-in retail), 4=Retail Pending (under review), 5=Pending (assessment incomplete). Referenced by BackOffice.Customer.MifidCategorizationID (FK, DEFAULT 1) and History.BackOfficeCustomer. Feeds into computed column TradingRiskStatusID. (Tier 1 — Dictionary.MifidCategorization) |
| 2 | Name | varchar | YES | Human-readable classification label. Used in compliance dashboards and regulatory reports. (Tier 1 — Dictionary.MifidCategorization) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| MifidCategorizationID | etoro.Dictionary.MifidCategorization | MifidCategorizationID | passthrough |
| Name | etoro.Dictionary.MifidCategorization | Name | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.MifidCategorization  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_MifidCategorization
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_MifidCategorization  (6 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_MifidCategorization/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | MifidCategorizationID | Customer's MiFID II regulatory classification |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 Count customers by MiFID tier

```sql
SELECT
    mc.MifidCategorizationID,
    mc.Name AS MifidTier,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_MifidCategorization] mc ON f.MifidCategorizationID = mc.MifidCategorizationID
GROUP BY mc.MifidCategorizationID, mc.Name
ORDER BY mc.MifidCategorizationID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 3/3, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_MifidCategorization | Type: Table | Production Source: etoro.Dictionary.MifidCategorization*


### Upstream `DWH_dbo.Dim_ScreeningStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_ScreeningStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ScreeningStatus.md`

# DWH_dbo.Dim_ScreeningStatus

> Lookup table defining the 8 AML/compliance screening outcomes for customer identity checks against sanctions lists, PEP registries, and risk databases (e.g., World-Check). Source is the ScreeningService microservice, not the core etoro Dictionary.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | ScreeningService.Dictionary.ScreeningStatus (ScreeningServiceDB) |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ScreeningStatusID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_ScreeningStatus defines the 8 possible outcomes of a customer identity screening check against AML (Anti-Money Laundering) and compliance databases - including sanctions lists, PEP (Politically Exposed Person) registries, and adverse media risk databases. (Tier 3 - live data inferred from values; no upstream wiki found)

When a customer is onboarded or reviewed, their identity is screened by the ScreeningService (a dedicated compliance microservice, separate from the core etoro platform). The result is stored as a ScreeningStatusID on the customer record. Statuses range from clean (NoMatch=1, no risk identified) through various alert levels (PEP=3, RiskMatch=4, SanctionsMatch=7) to process states (PendingInvestigation=2, Technical=5, MultipleMatch=6).

Notably, this table's source is `ScreeningService.Dictionary.ScreeningStatus` from `ScreeningServiceDB` - not the standard etoro Dictionary database used by most Dim_ tables. The staging table is `DWH_staging.ScreeningService_Dictionary_ScreeningStatus` (naming pattern differs from `etoro_Dictionary_*`). No DWH-specific alias columns (DWHxxx, StatusID) are added by the ETL - this is the simplest ETL transformation pattern in the SP_Dictionaries SP.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.ScreeningService_Dictionary_ScreeningStatus. Source column `ID` is renamed to `ScreeningStatusID` in DWH.

---

## 2. Business Logic

### 2.1 Screening Outcome Classification

**What**: The 8 statuses represent distinct outcomes of the AML/compliance screening workflow.

**Columns Involved**: `ScreeningStatusID`, `Name`

**Status Meanings** (Tier 3 - inferred from names and compliance domain knowledge):
- 0 = Unknown: Default/no screening result available yet
- 1 = NoMatch: Clean result - no match found on any screening list
- 2 = PendingInvestigation: Match found, under compliance review
- 3 = PEP: Politically Exposed Person detected - requires enhanced due diligence
- 4 = RiskMatch: General risk match found on screening database
- 5 = Technical: Technical/processing error during screening
- 6 = MultipleMatch: Multiple potential matches found - requires manual disambiguation
- 7 = SanctionsMatch: Match against official sanctions list - most severe, typically blocks account

**Alert Severity** (inferred):
```
Clean:     NoMatch (1)
Process:   PendingInvestigation (2), MultipleMatch (6), Technical (5)
Alert:     PEP (3), RiskMatch (4)
Critical:  SanctionsMatch (7)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ScreeningStatusID. With 8 rows, REPLICATE is optimal.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus` is Parquet. Bronze source at `bi_db.bronze_screeningservice_dictionary_screeningstatus` is also available.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ScreeningStatusID to label | `LEFT JOIN DWH_dbo.Dim_ScreeningStatus ss ON ss.ScreeningStatusID = fact.ScreeningStatusID` |
| Flagged customers (non-clean) | `WHERE ss.ScreeningStatusID NOT IN (0, 1, 5)` |
| Critical matches (sanctions) | `WHERE ss.ScreeningStatusID = 7` |
| PEP customers | `WHERE ss.ScreeningStatusID = 3` |

### 3.3 Gotchas

- **Different source system**: Unlike all other Dim_ tables from SP_Dictionaries (which read etoro.Dictionary.*), this table reads from ScreeningServiceDB. The staging table is `ScreeningService_Dictionary_ScreeningStatus` (not `etoro_Dictionary_*`).
- **ID -> ScreeningStatusID rename**: The production source column is `ID`, renamed to `ScreeningStatusID` in the DWH. No other ETL transformations (no DWHxxx alias, no StatusID).
- **No upstream wiki**: No Dictionary.ScreeningStatus.md exists in DB_Schema/etoro/Wiki. Descriptions are Tier 3 (inferred from names).
- **SanctionsMatch severity**: This is the most compliance-critical status. Customers with ScreeningStatusID=7 are likely blocked from trading and subject to mandatory reporting.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data / name inference | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ScreeningStatusID | int | NO | Primary key for screening outcome. Renamed from production `ID` column by ETL. 0=Unknown, 1=NoMatch, 2=PendingInvestigation, 3=PEP, 4=RiskMatch, 5=Technical, 6=MultipleMatch, 7=SanctionsMatch. (Tier 2 - SP code rename from ID; Tier 3 - live data values) |
| 2 | Name | varchar(255) | NO | Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. (Tier 3 - live data) |
| 3 | UpdateDate | datetime | NO | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ScreeningStatusID | ScreeningService.Dictionary.ScreeningStatus | ID | rename |
| Name | ScreeningService.Dictionary.ScreeningStatus | Name | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |

No upstream wiki found. Production source is ScreeningServiceDB (separate from etoro main database).

### 5.2 ETL Pipeline

```
ScreeningService.Dictionary.ScreeningStatus (ScreeningServiceDB)
  -> Generic Pipeline (daily, Override)
  -> Bronze/ScreeningService/Dictionary/ScreeningStatus/
  -> bi_db.bronze_screeningservice_dictionary_screeningstatus (UC Bronze)
  -> DWH_staging.ScreeningService_Dictionary_ScreeningStatus
  -> SP_Dictionaries_DL_To_Synapse
  -> DWH_dbo.Dim_ScreeningStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | ScreeningService.Dictionary.ScreeningStatus | 8 rows (IDs 0-7). AML compliance microservice DB. |
| Bronze UC | bi_db.bronze_screeningservice_dictionary_screeningstatus | Raw Bronze copy |
| Staging | DWH_staging.ScreeningService_Dictionary_ScreeningStatus | DWH staging (naming: ScreeningService_* not etoro_*) |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames ID -> ScreeningStatusID. Adds UpdateDate. No DWHxxx alias or StatusID. |
| Target | DWH_dbo.Dim_ScreeningStatus | 8 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table in the SSDT repo. Customer fact tables carrying ScreeningStatusID can join for label resolution.

---

## 7. Sample Queries

### 7.1 List all screening statuses
```sql
SELECT
    ScreeningStatusID,
    Name
FROM [DWH_dbo].[Dim_ScreeningStatus]
ORDER BY ScreeningStatusID
```

### 7.2 Customer count by screening outcome
```sql
SELECT
    ss.Name AS ScreeningOutcome,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_ScreeningStatus] ss
    ON ss.ScreeningStatusID = cs.ScreeningStatusID
GROUP BY ss.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 7.5/10 (★★★☆☆) | Phases: 7/14 (fast-path)*
*Tiers: 0 T1, 1 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 4/10, Sources: 7/10*
*Note: Quality limited by no upstream wiki - no Dictionary.ScreeningStatus.md in DB_Schema. Values inferred from names.*
*Object: DWH_dbo.Dim_ScreeningStatus | Type: Table | Production Source: ScreeningService.Dictionary.ScreeningStatus*


### Upstream `DWH_dbo.Dim_PlayerStatusReasons` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatusReasons`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md`

# DWH_dbo.Dim_PlayerStatusReasons

> Lookup table defining 44 reason codes explaining why a customer's account status was changed -- from compliance/AML actions and KYC failures to chargebacks, user-initiated closures, and administrative decisions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (44 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusReasons is the first level of a two-tier reason classification hierarchy for account status changes. When an account is blocked, suspended, restricted, or closed, the system records both the new status (Dim_PlayerStatus) and the broad reason category for the change. This table provides that top-level category.

The 44 reason codes (IDs 0-43) span the full range of account status change triggers: compliance/AML investigations (IDs 6, 10, 11, 18), KYC failures (1, 2, 39), risk flags (4, 7, 14, 25, 34, 35), fraud/chargebacks (5, 23, 24, 30-32), user-initiated actions (3, 20, 21, 22), payment issues (13, 16, 17, 38), and administrative decisions (8, 9, 12, 19, 37, 40-43). ID=0 (None) is the default when no reason has been explicitly recorded.

This table works as a hierarchy with Dim_PlayerStatusSubReasons -- Reason gives the broad category (e.g., "Chargeback"), and SubReason provides granular detail (e.g., "ACH CHBK", "Credit Card CHBK"). Dim_Customer and Fact_SnapshotCustomer store both PlayerStatusReasonID and PlayerStatusSubReasonID for every customer.

Data originates from `etoro.Dictionary.PlayerStatusReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT passthrough.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Major groupings of the 44 account status change reasons.

**Columns Involved**: `PlayerStatusReasonID`, `Name`

**Rules**:
- **ID=0 (None)**: Default state -- no explicit reason recorded. Included in production table, not a DWH-only sentinel.
- **Compliance/AML** (6, 10, 11, 18): AML-Account Closed, AML, AML review, WCH match (World Check sanctions screening)
- **KYC/Verification** (1, 2, 27, 39): Failed Verification, Expired Document, Pending Docs, KYC
- **Risk/Fraud** (4, 7, 14, 15, 25, 34, 35): Risk, HRC (High Risk Country), Risk Check, 3rd Party, Abuse, Abusive Trading, Hacked Account
- **Chargebacks** (5, 23, 24, 30, 31, 32): Chargeback, ACH Chargeback, PWMB Chargeback, CheckoutChargeback, CheckoutRetrievel, CheckoutCaptureDecline
- **User-Initiated** (3, 20, 21, 22): CloseAccountByUser, Right to be forgotten (GDPR), Self-Service, By request
- **Payment Issues** (13, 16, 17, 38): Overpayment, PayPal Investigation, NOC/NOF/RFI, Deposits
- **Account Types** (26, 28, 29, 36): Affiliate Account, Employee Account, PI Account, Partners & PIs
- **Administrative** (8, 9, 12, 19, 37, 40, 42, 43): Underage, Deceased, Off Market Abuse, Other, CS management decision, Account Closed, Corporate, Gap
- **Regulatory** (33, 41): eToro Money Restriction, Tax (FATCA/CRS)

### 2.2 Reason-SubReason Hierarchy

**What**: Reasons are further refined by sub-reasons stored in Dim_PlayerStatusSubReasons.

**Columns Involved**: `PlayerStatusReasonID`

**Rules**:
- Not every reason is valid for every status -- BackOffice.PlayerStatusToReason governs valid status-to-reason combinations (production side).
- Not every sub-reason is valid for every reason -- BackOffice.PlayerStatusReasonToSubReason governs valid reason-to-subreason combinations (production side).
- Both PlayerStatusReasonID and PlayerStatusSubReasonID are stored together on Dim_Customer and Fact_SnapshotCustomer.
- ID=0 (None) is the default -- use `WHERE PlayerStatusReasonID > 0` to filter to customers with explicit status change reasons.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusReasonID. With 44 rows, performance is never a concern. JOIN to Dim_Customer or Fact_SnapshotCustomer on PlayerStatusReasonID is straightforward.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`. With 44 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What reason was given for a blocked customer? | JOIN Dim_Customer ON PlayerStatusReasonID |
| Count customers blocked per reason | GROUP BY PlayerStatusReasonID on Fact_SnapshotCustomer |
| Filter to AML-related reasons only | WHERE PlayerStatusReasonID IN (6, 10, 11, 18) |
| Exclude "no reason" rows | WHERE PlayerStatusReasonID > 0 |
| What sub-reasons exist under a reason? | JOIN Dim_PlayerStatusSubReasons -- mapping in production BackOffice only |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Resolve reason name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | View-level reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in year-end snapshots |

### 3.4 Gotchas

- **Name is nullable**: Unlike most DWH dimension columns, `Name` is varchar(50) NULL. Handle NULL safely: `ISNULL(Name, 'Unknown')`.
- **ID=0 is a real production row (None)**: Unlike other Dim_ tables, there is no DWH-only ID=0 sentinel -- row 0 comes directly from production and means "no reason specified".
- **ETL staleness**: UpdateDate = 2026-03-11 for all rows (8+ days as of 2026-03-19) -- consistent with known SP_Dictionaries_DL_To_Synapse disruption across the schema.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combinations are only in production BackOffice.PlayerStatusReasonToSubReason. DWH has both dimension tables but not the mapping table.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusReasonID | int | NO | Primary key identifying the account status change reason. Range 0-43. 0=None (no reason -- real production row, not a DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Represents first-level classification in the Reason->SubReason hierarchy. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 2 | Name | varchar(50) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share the same timestamp per reload (2026-03-11 as of last load). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | PlayerStatusReasonID | passthrough |
| Name | Dictionary.PlayerStatusReasons | Name | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT)
  -> DWH_dbo.Dim_PlayerStatusReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusReasons | Production reason dictionary (etoroDB-REAL) -- 2 data cols + metadata, 44 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusReasons | Raw staging import -- passthrough cols |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~999) | TRUNCATE + INSERT SELECT; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusReasons | 44 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusReasonID | Customer's current status change reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusReasonID | View exposing reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusReasonID | Reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all status change reasons

```sql
SELECT PlayerStatusReasonID,
       Name
FROM   [DWH_dbo].[Dim_PlayerStatusReasons]
ORDER BY PlayerStatusReasonID;
```

### 7.2 Count customers by status reason (excluding "no reason")

```sql
SELECT  dpsr.Name            AS StatusReason,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID > 0
GROUP BY dpsr.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find all AML and compliance-blocked customers

```sql
SELECT  dc.CID,
        dpsr.Name  AS StatusReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID IN (6, 10, 11, 18)  -- AML variants + WCH match
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusReasons*


### Upstream `DWH_dbo.Dim_PlayerStatusSubReasons` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatusSubReasons`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md`

# DWH_dbo.Dim_PlayerStatusSubReasons

> Lookup table defining 83 granular sub-reason codes for account status changes -- providing the second-level detail beneath Dim_PlayerStatusReasons, covering fraud types, chargeback sources, compliance investigations, AML triggers, and regulatory requirements.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusSubReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusSubReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (83 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusSubReasons provides the second level of detail for account status changes, working beneath Dim_PlayerStatusReasons. While the Reason gives the broad category (e.g., "Chargeback"), the SubReason gives the specific detail (e.g., "ACH CHBK", "Credit Card CHBK", "PayPal CHBK"). This two-level classification gives compliance, risk, and operations teams the granularity needed for investigation tracking and reporting.

The 83 sub-reasons (IDs 0-82) span: fraud types (Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party), verification failures (Failed Verification, POI/POA Required), chargeback sources (ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK -- 11 variants), screening results (Sanctions, PEP, WCH matches), AML triggers (Investigation, AML Trigger, SAR filed, Law enforcement request), regulatory (FATCA, CRS, W-8BEN, corporate LEI), and operational states (1st Warning, 2nd Warning, Vulnerable Client).

This table is always used together with Dim_PlayerStatusReasons -- both IDs are stored on Dim_Customer and Fact_SnapshotCustomer for every customer. ID=0 (None) is the default when no specific sub-reason has been recorded.

**COLUMN RENAME**: Production column `Name` is renamed to `PlayerStatusSubReasonName` in DWH. All other columns are passthrough.

**ALL COLUMNS NULLABLE**: Unlike Dim_PlayerStatusReasons, all 3 DWH columns (including the PK PlayerStatusSubReasonID) are defined as NULL in the DDL. This is structurally unusual.

Data originates from `etoro.Dictionary.PlayerStatusSubReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusSubReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT with a Name -> PlayerStatusSubReasonName rename.

---

## 2. Business Logic

### 2.1 Sub-Reason Categories

**What**: Major groupings of the 83 sub-reasons.

**Columns Involved**: `PlayerStatusSubReasonID`, `PlayerStatusSubReasonName`

**Rules**:
- **ID=0 (None)**: Default -- no specific sub-reason recorded. Comes from production (not a DWH-only placeholder).
- **Fraud/Abuse** (1-6, 49, 64-65): Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party, Lost Funds, 3rd Party Trading, Market Abuse, Affiliate Abuse
- **Verification** (7, 24-26, 59, 61, 81-82): Failed Verification, Closed Verification, Selfie, Expired POI/POA, Pending Docs, 15-Day Failure, POI Required, POA Required
- **Chargeback Sources** (35-45): ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK, Other MOP CHBK, 3rd Party CHBK, CO Logic CHBK, Currency Difference CHBK, Fraud CHBK, Risk Refunded CHBK, Service/Complaint CHBK
- **Screening** (13-16, 31-34): WCH negative results, Sanctions, PEP Failed Verification, Possible Match (old and new naming)
- **AML/Investigation** (17-21, 73-74): Investigation, Cross Border, AML Trigger, Business Method, Mixed Funds, SAR Filed, Law Enforcement Request
- **Deposit-Related** (22-23, 29, 46-48, 53, 69, 78-79): FTD, Redeposit, PWMB Failed Deposit, 3rd Party FTD/Business MOP/Redeposit, ACH Failed Deposit, Preapproved Monitoring, Failed Min FTD, Failed Deposit
- **Warnings** (62-63): 1st Warning, 2nd Warning/Termination
- **Account Types** (54-58): Affiliate Account, Affiliate Re-linked, Affiliate Terminated, PI 2nd Account, PI Account
- **Regulatory** (60, 66-68, 70-72, 76): Corp Expired LEI, FATCA, CRS, FATCA0013, Corporate LEI issues, Corporate/SMSF Pending Docs, W-8BEN
- **Other** (8-12, 50-52, 75, 77, 80): Service/technical issues, Risk Refunded, Currency Differences, CO Logic, No Triggers, PayPal Investigation, Risk Check, Low Risk, Vulnerable Client, Negative Balance, UAE PASS Reactivation

**Abbreviation Glossary**: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, LEI=Legal Entity Identifier, PEP=Politically Exposed Person, SAR=Suspicious Activity Report, WCH=World Check, CRS=Common Reporting Standard, FATCA=Foreign Account Tax Compliance Act.

### 2.2 Reason-SubReason Hierarchy

**What**: Sub-reasons are always paired with a parent reason.

**Columns Involved**: `PlayerStatusSubReasonID`

**Rules**:
- Used alongside PlayerStatusReasonID -- both are stored on Dim_Customer.
- In production, valid Reason->SubReason combinations are governed by BackOffice.PlayerStatusReasonToSubReason (not replicated to DWH).
- ID=0 (None) as sub-reason typically accompanies ID=0 (None) as reason -- meaning neither level has been explicitly set.
- Use `WHERE PlayerStatusSubReasonID > 0` to filter to customers with explicit sub-reason classifications.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusSubReasonID. With 83 rows, performance is never a concern. All columns are nullable -- apply ISNULL() defensively.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`. With 83 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What sub-reason for a customer? | JOIN Dim_Customer ON PlayerStatusSubReasonID |
| Find all chargeback sub-reasons | WHERE PlayerStatusSubReasonName LIKE '%CHBK%' |
| Count customers by sub-reason | GROUP BY PlayerStatusSubReasonID on Fact_SnapshotCustomer |
| Exclude "no sub-reason" rows | WHERE PlayerStatusSubReasonID > 0 |
| Combine with parent reason | JOIN BOTH Dim_PlayerStatusReasons AND Dim_PlayerStatusSubReasons |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Resolve sub-reason per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | View-level sub-reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in year-end snapshots |

### 3.4 Gotchas

- **Column rename**: Production `Name` -> DWH `PlayerStatusSubReasonName`. Do NOT query for `Name` in DWH; the column does not exist.
- **ALL columns nullable**: PlayerStatusSubReasonID itself is defined as NULL in the DDL (unusual for a PK). Handle potential NULLs defensively even on the ID column.
- **ID=0 is a real production row**: Row 0 (None) comes from production -- not a DWH-only ETL placeholder.
- **CHBK abbreviation**: All chargeback sub-reasons use the abbreviation "CHBK" not "Chargeback". Filter with LIKE '%CHBK%' to find them.
- **ETL staleness**: UpdateDate = 2026-03-11 (8+ days stale as of 2026-03-19) -- consistent with schema-wide SP_Dictionaries_DL_To_Synapse disruption.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combination table (BackOffice.PlayerStatusReasonToSubReason) is only in production. DWH does not replicate it.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusSubReasonID | int | YES | Primary key identifying the granular sub-reason (NOTE: DDL allows NULL -- unusual for a PK). Range 0-82. 0=None (real production row, not DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Provides second-level detail beneath PlayerStatusReasonID. (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 2 | PlayerStatusSubReasonName | varchar(50) | YES | Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share same timestamp per reload (2026-03-11 as of last load). Also nullable in DWH DDL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonID | passthrough |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | rename (Name -> PlayerStatusSubReasonName) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusSubReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusSubReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusSubReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT, Name -> PlayerStatusSubReasonName)
  -> DWH_dbo.Dim_PlayerStatusSubReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusSubReasons | Production sub-reason dictionary (etoroDB-REAL) -- 2 data cols, 83 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusSubReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusSubReasons | Raw staging import -- Name col stored as `Name` |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~1015) | TRUNCATE + INSERT SELECT; Name -> PlayerStatusSubReasonName rename; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusSubReasons | 83 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | Customer's current status change sub-reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusSubReasonID | View exposing sub-reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | Sub-reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusSubReasonID | Sub-reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all chargeback sub-reasons

```sql
SELECT PlayerStatusSubReasonID,
       PlayerStatusSubReasonName
FROM   [DWH_dbo].[Dim_PlayerStatusSubReasons]
WHERE  PlayerStatusSubReasonName LIKE '%CHBK%'
ORDER BY PlayerStatusSubReasonID;
```

### 7.2 Count customers by sub-reason (excluding none)

```sql
SELECT  dpssr.PlayerStatusSubReasonName  AS SubReason,
        COUNT(*)                          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusSubReasonID > 0
GROUP BY dpssr.PlayerStatusSubReasonName
ORDER BY CustomerCount DESC;
```

### 7.3 Full reason + sub-reason for each customer

```sql
SELECT  dc.CID,
        dpsr.Name                         AS Reason,
        dpssr.PlayerStatusSubReasonName   AS SubReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusReasonID > 0
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusSubReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusSubReasons*


### Upstream `BI_DB_dbo.BI_DB_KYC_Panel` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_KYC_Panel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_KYC_Panel.md`

# BI_DB_dbo.BI_DB_KYC_Panel

> Daily full-rebuild KYC questionnaire snapshot (21.7M rows) covering every valid eToro customer's assessment-questionnaire answers, experience level, CFD eligibility, trading activity windows, and demographic enrichment — pivoted from UserApiDB.KYC.CustomerAnswers via an external table bridge and rebuilt from scratch every day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.dbo.V_CustomerAnswers_Range_KYC_Panel (external table) + Dim_Customer (population gate) + BI_DB_First5Actions + BI_DB_Scored_Appropriateness_Negative_Market |
| **Refresh** | Daily — SP_KYC_Panel @Date; full TRUNCATE + INSERT; rows with all KYC answers NULL are deleted post-insert |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX (GCID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_KYC_Panel` is the central KYC analytics table in the BI_DB schema. It holds one row per valid eToro customer (IsValidCustomer=1 from Dim_Customer), pivoted from the raw KYC questionnaire answer store in UserApiDB. Each row aggregates all of a customer's KYC question responses alongside computed assessments, regulatory demographics, CFD eligibility, and early trading behavior metrics.

The table is rebuilt daily from scratch (TRUNCATE + full INSERT). It is keyed by `GCID` (Global Customer ID from UserApiDB), not by `RealCID` (eToro production CID). Both identifiers are present. Post-insert, rows where all KYC answer columns are NULL are deleted — ensuring the table only contains customers with at least one questionnaire response.

As of 2026-04-13: 21,690,259 rows. Four assessment types are present: AnswerID_101_104 (38.8%), AnswerID_142_146 (32.8%), N/A (28.3%), AnswerID_84_87 (0.15%). CFD status: 65.8% CFD_Allowed, 17.2% CFD_Blocked, 16.9% NULL (no CFD assessment). Experience levels: Non (30.7%), Low (24.4%), N/A (23.1%), High (9.7%), Med (7.7%).

**KEY ANOMALY — `RegulatgionName` column typo**: Column 56 is named `[RegulatgionName]` (extra 'g' in "Regulation"). This matches the SP code exactly. Do NOT reference this column as `RegulatgionName` in queries — use `RegulationID` + join to Dim_Regulation instead, or use `QUOTENAME` to handle the typo.

---

## 2. Business Logic

### 2.1 Population Gate

**What**: Only "valid" customers are included. Non-valid customers (internal accounts, excluded markets, blocked countries) are excluded at the source query.
**Columns Involved**: All columns
**Rules**:
- `JOIN DWH_dbo.Dim_Customer WHERE IsValidCustomer=1` — excludes PlayerLevelID=4 (Internal), certain label IDs, and CountryID=250 (excluded market)
- Post-insert DELETE: `WHERE [all KYC answer columns] IS NULL` — removes customers with zero questionnaire responses
- Non-depositor FTD_Date = '1900-01-01' (from Dim_Customer.FirstDepositDate sentinel)

### 2.2 Assessment Type Segmentation

**What**: The `Assessment_Type` column categorizes each customer's KYC appropriateness assessment version. Three answer ID ranges correspond to three questionnaire generations.
**Columns Involved**: `Assessment_Type`, `Total_Points_Assessment_142_146`, `Q23_Assessment`, `Q23_AnswerID`
**Rules**:
- Answer IDs 84–87 → `'AnswerID_84_87'` (0.15% of customers — oldest/legacy assessment)
- Answer IDs 101–104 → `'AnswerID_101_104'` (38.8% — second-generation assessment)
- Answer IDs 142–146 → `'AnswerID_142_146'` (32.8% — current assessment)
- All others → `'N/A'` (28.3% — no valid appropriateness assessment)

```
Assessment generations:
  Legacy (84-87)       0.15%  — oldest questionnaire form
  2nd-Gen (101-104)   38.8%  — standard assessment
  Current (142-146)   32.8%  — latest assessment
  N/A                 28.3%  — no assessment recorded
```

### 2.3 Appropriateness Score (142-146 Type Only)

**What**: `Total_Points_Assessment_142_146` contains a numeric appropriateness score only for customers with Assessment_Type='AnswerID_142_146'. All other customers receive a sentinel value of -100.
**Columns Involved**: `Total_Points_Assessment_142_146`, `Assessment_Type`
**Rules**:
- For 142-146 type: +2 per correct answer, -2 per wrong answer. Higher score = more appropriate for CFD trading.
- For all other types: value = -100 (sentinel — NOT a real score, DO NOT average or compare across Assessment_Type values)
- A score of 0 indicates equal correct/wrong answers, not "no data"

```
CRITICAL: -100 = sentinel for non-142-146 customers
           0   = tied correct/wrong for 142-146 customers
  Always filter: WHERE Assessment_Type = 'AnswerID_142_146' before scoring analysis
```

### 2.4 Experience Level Computation

**What**: `Experience_Level` aggregates trading experience across three asset classes (equities, crypto, CFDs) into a single tier.
**Columns Involved**: `Experience_Level`, `Q33_Experience_Equities`, `Q34_Experience_Crypto`, `Q35_Experience_CFDs`, `Q33_AnswerID`, `Q34_AnswerID`, `Q35_AnswerID`
**Rules**:
- Each of Q33/Q34/Q35 answer IDs is mapped to a numeric tier: 1=Non, 2=Low, 3=Med, 4=High
- `Experience_Level = MAX(tier across Q33, Q34, Q35)` → labeled as Non/Low/Med/High
- 'N/A' when no Q33/Q34/Q35 answers exist

```
Experience_Level derivation:
  Q33 answer ID → tier (Non/Low/Med/High)
  Q34 answer ID → tier
  Q35 answer ID → tier
  Experience_Level = MAX(Q33_tier, Q34_tier, Q35_tier) as label
```

### 2.5 Multi-Select Question Handling (Q15, Q26, Q27, Q30, Q32)

**What**: Several questions allow multiple answers. These are handled differently from single-select questions.
**Columns Involved**: `Q15_AnswerText`, `Q26_AnswerText`, `Is_PI_Stocks`, `Is_PI_Crypto`, `Is_PI_FX`, `Q30_Is_*`, `Q32_Is_*`
**Rules**:
- **Q15 (Sources of Income) / Q26 (Sources of Funds)**: Multi-select. `_AnswerText` columns are STRING_AGG of all selected answer texts. `_AnswerID` columns hold only the last/primary answer ID.
- **Q27 (Planned Investment Instrument)**: Multi-select. `Q27_Planned_Investment_Instrument` is the last answer ID. Boolean flags `Is_PI_Stocks`, `Is_PI_Crypto`, `Is_PI_FX` = 1 if that instrument was selected.
- **Q30 (FINRA)**: Multi-select. Flags extracted: `Q30_Is_Shareholder`, `Q30_Is_Employed_By_Broker`, `Q30_Is_Public_Official`, `Q30_Is_None_Apply_To_Me`.
- **Q32 (PEP/Money Manager)**: Same flag pattern as Q30.

### 2.6 CFD Status

**What**: `CFD_Status` reflects whether the customer is currently allowed to trade CFDs, based on scores from the appropriateness assessment.
**Columns Involved**: `CFD_Status`, `CFD_BlockDate`, `CFD_BlockReasonDesc`, `CFD_ReleaseDate`, `CFD_ReleaseReasonDesc`, `DateDiffBlockRelease`
**Rules**:
- Sourced from `BI_DB_Scored_Appropriateness_Negative_Market` (LEFT JOIN on RealCID)
- 'CFD_Allowed': customer scored sufficiently on appropriateness OR passed re-assessment
- 'CFD_Blocked': customer failed appropriateness threshold
- NULL: no CFD assessment record (16.9% of population — newer or unassessed customers)
- `DateDiffBlockRelease`: days from block to release; NULL if still blocked or never blocked

### 2.7 Temporal Grouping Columns

**What**: Two bucketed time-distance columns describe how quickly customers deposited and how long ago they deposited.
**Columns Involved**: `GapInDays_Reg_to_FTD_Group`, `DaysFromFTD_Group`
**Rules**:
- `GapInDays_Reg_to_FTD_Group`: `DATEDIFF(DAY, Reg_Date, FTD_Date)` bucketed: '0', '1-3', '4-7', '8-14', '15-30', '31+', 'N/A'
- `DaysFromFTD_Group`: `DATEDIFF(DAY, FTD_Date, GETDATE()-1)` bucketed: '0', '1-7', '8-14', '15-30', '31+', 'N/A'. **CRITICAL: This column is recalculated every day. A customer who deposited 7 days ago will move from '1-7' to '8-14' on the 8th day. The value is a snapshot of "age since FTD as of yesterday" — NOT a stable dimension.**
- Non-depositors: both columns = 'N/A'

### 2.8 Q3 Composite Answer Text

**What**: `Q3_AnswerText` for Q3 (Trading Knowledge) is a computed composite string, not a raw answer text.
**Columns Involved**: `Q3_AnswerText`, `Q3_Trading_Knowledge`, `Q3_Is_Professional_Knowledge`
**Rules**:
- Q3 is a multi-part question assessing educational/professional credentials
- `Q3_AnswerText` = STRING_AGG of active indicators from: Is_Courses, Is_Professional_Experience, Is_Academic_Degree
- Possible composite values: e.g., "Professional Experience, Academic Degree" (multiple flags can be active)
- `Q3_Is_Professional_Knowledge` = 1 if any professional indicator flag is active

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CLUSTERED INDEX(GCID ASC). Point-lookups and joins on GCID are fast. With 21.7M rows, always use a WHERE clause when possible. The table is rebuilt daily — snapshot date is reflected in the single UpdateDate value (all rows have the same UpdateDate from the daily run).

### 3.2 GCID vs. RealCID

This table is **keyed on GCID**, not CID/RealCID. Most DWH fact tables use RealCID/CID as the join key. When joining this table to fact tables, use `RealCID` for the join, not GCID. The `GCID` column in this table maps to `Dim_Customer.GCID` and is the distribution key for performance.

### 3.3 RegulatgionName Typo

Column 56 has a **deliberate typo**: `[RegulatgionName]` (extra 'g'). This matches the SP code. Reference it in queries using square-bracket quoting: `[RegulatgionName]`. Alternatively, join to Dim_Regulation on RegulationID for cleaner access to the regulation name.

### 3.4 Assessment Score Filtering

**Always filter by Assessment_Type before using Total_Points_Assessment_142_146**: The -100 sentinel for non-142-146 customers will corrupt averages and ranges if included. Pattern:
```sql
WHERE Assessment_Type = 'AnswerID_142_146'
-- then: AVG(Total_Points_Assessment_142_146), etc.
```

### 3.5 DaysFromFTD_Group Is Not Stable

Do NOT use `DaysFromFTD_Group` as a join key or in GROUP BY for time-series analysis. Its value changes every day. Use `FTD_Date` and compute the desired window in your query. `DaysFromFTD_Group` is useful only as a filter (e.g., "customers who deposited in the last 7 days yesterday").

### 3.6 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get KYC profile for a customer | `WHERE RealCID = X` (use RealCID, not GCID, for DWH joins) |
| Appropriateness score distribution | `WHERE Assessment_Type = 'AnswerID_142_146' GROUP BY Total_Points_Assessment_142_146` |
| CFD-blocked customers by regulation | `WHERE CFD_Status = 'CFD_Blocked' GROUP BY [RegulatgionName]` |
| Recent depositors (last 7 days) | `WHERE DaysFromFTD_Group = '0' OR DaysFromFTD_Group = '1-7'` |
| Customers who plan to invest in stocks | `WHERE Is_PI_Stocks = 1` |
| PEP-flagged customers | `WHERE Q32_Is_Public_Official = 1` |
| Experience level by regulation | `GROUP BY Experience_Level, [RegulatgionName]` |

---

## 4. Elements

| # | Column | Type | Nullable | Confidence | Tier | Description |
|---|--------|------|----------|------------|------|-------------|
| 1 | RealCID | bigint | YES | CODE-BACKED | T2 | eToro production CID (RealCID from Dim_Customer). Join key to all DWH fact tables via CID=RealCID. |
| 2 | GCID | bigint | YES | CODE-BACKED | T2 | Global Customer ID from UserApiDB. Distribution key. Join key to KYC source tables. Prefer RealCID for DWH joins. |
| 3 | IsFTD | bit | YES | CODE-BACKED | T2 | 1 if customer has made at least one deposit (Dim_Customer.IsDepositor=1). 0 for non-depositors. |
| 4 | IsFirstAction | bit | YES | CODE-BACKED | T2 | 1 if customer has performed at least one trading action (BI_DB_First5Actions.FirstAction IS NOT NULL). |
| 5 | FunnelName | varchar(200) | YES | CODE-BACKED | T2 | Acquisition funnel segment: 'SocialCopy' (came via copy trading), 'Copy' (other copy), 'Direct' (organic), 'None' (unclassified). |
| 6 | Reg_Date | date | YES | CODE-BACKED | T2 | Registration date (YYYYMMDD char format cast to date). From Dim_Customer.RegisteredReal. |
| 7 | Reg_Month | bigint | YES | CODE-BACKED | T2 | Registration year-month as YYYYMM integer. Useful for monthly cohort aggregation. |
| 8 | FTD_Date | date | YES | CODE-BACKED | T2 | First Time Deposit date. '1900-01-01' for non-depositors. |
| 9 | FTD_Month | bigint | YES | CODE-BACKED | T2 | FTD year-month as YYYYMM integer. |
| 10 | Q3_Trading_Knowledge | varchar(200) | YES | CODE-BACKED | T2 | Q3 raw answer ID (trading knowledge: educational and professional background). |
| 11 | Q3_Is_Professional_Knowledge | smallint | YES | CODE-BACKED | T2 | 1 if Q3 responses indicate professional trading knowledge (courses, experience, or academic degree). |
| 12 | Q3_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Composite STRING_AGG of Q3 credential flags (e.g., "Professional Experience, Academic Degree"). Not a single answer text. |
| 13 | Q23_Assessment | varchar(200) | YES | CODE-BACKED | T2 | Q23 raw answer ID. Q23 is the core appropriateness assessment question. |
| 14 | Q23_Is_Assessment_Pass | smallint | YES | CODE-BACKED | T2 | 1 if Q23 answer ID meets the pass threshold. |
| 15 | Q23_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q23. |
| 16 | Experience_Level | varchar(50) | YES | CODE-BACKED | T2 | Composite experience tier: MAX(Q33, Q34, Q35 tiers) → 'Non', 'Low', 'Med', 'High', 'N/A'. See §2.4. |
| 17 | Q33_Experience_Equities | varchar(200) | YES | CODE-BACKED | T2 | Q33 raw answer ID (equities trading experience). |
| 18 | Q33_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q33. |
| 19 | Q34_Experience_Crypto | varchar(200) | YES | CODE-BACKED | T2 | Q34 raw answer ID (crypto trading experience). |
| 20 | Q34_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q34. |
| 21 | Q35_Experience_CFDs | varchar(200) | YES | CODE-BACKED | T2 | Q35 raw answer ID (CFD trading experience). |
| 22 | Q35_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q35. |
| 23 | Q2_Experience | varchar(200) | YES | CODE-BACKED | T2 | Q2 raw answer ID (general trading experience years). |
| 24 | Q2_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q2. |
| 25 | Q10_Annual_Income | varchar(200) | YES | CODE-BACKED | T2 | Q10 raw answer ID (annual income bracket). |
| 26 | Q10_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q10. |
| 27 | Q11_Liquid_Assets | varchar(200) | YES | CODE-BACKED | T2 | Q11 raw answer ID (liquid assets bracket). |
| 28 | Q11_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q11. |
| 29 | Q9_Risk_Reward_Scenario | varchar(200) | YES | CODE-BACKED | T2 | Q9 raw answer ID (risk/reward scenario understanding). |
| 30 | Q9_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q9. |
| 31 | Q14_Planned_Invested_Amount | varchar(200) | YES | CODE-BACKED | T2 | Q14 raw answer ID (total planned investment amount bracket). |
| 32 | Q14_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q14. |
| 33 | Q27_Planned_Investment_Instrument | varchar(200) | YES | CODE-BACKED | T2 | Q27 raw answer ID (planned instrument types — multi-select). Prefer Is_PI_* flags for individual instrument checks. |
| 34 | Is_PI_Stocks | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in Stocks (from Q27 multi-select). |
| 35 | Is_PI_Crypto | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in Crypto (from Q27). |
| 36 | Is_PI_FX | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in FX/CFDs (from Q27). |
| 37 | Total_PI_Answers | smallint | YES | CODE-BACKED | T2 | Count of distinct instrument selections in Q27 (0–3). |
| 38 | Q5_Trading_Strategy | varchar(200) | YES | CODE-BACKED | T2 | Q5 raw answer ID (preferred trading strategy). |
| 39 | Q5_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q5. |
| 40 | Q8_Trading_Primary_Purpose | varchar(200) | YES | CODE-BACKED | T2 | Q8 raw answer ID (primary purpose for trading: income/growth/speculation/etc.). |
| 41 | Q8_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q8. |
| 42 | Q15_Sources_of_Income | varchar(200) | YES | CODE-BACKED | T2 | Q15 primary/last answer ID (sources of income — multi-select question). |
| 43 | Q15_AnswerText | varchar(max) | YES | CODE-BACKED | T2 | STRING_AGG of all selected income source answer texts (multi-select). |
| 44 | Q26_Sources_of_Funds | varchar(200) | YES | CODE-BACKED | T2 | Q26 primary/last answer ID (sources of funds for investment — multi-select). |
| 45 | Q26_AnswerText | varchar(max) | YES | CODE-BACKED | T2 | STRING_AGG of all selected fund source answer texts (multi-select). |
| 46 | Q18_Occupation | varchar(200) | YES | CODE-BACKED | T2 | Q18 raw answer ID (occupation category). |
| 47 | Q18_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q18. |
| 48 | GapInDays_Reg_to_FTD_Group | varchar(200) | YES | CODE-BACKED | T2 | Days from registration to FTD, bucketed: '0', '1-3', '4-7', '8-14', '15-30', '31+', 'N/A'. |
| 49 | DaysFromFTD_Group | varchar(200) | YES | CODE-BACKED | T2 | Days from FTD to yesterday, bucketed: '0', '1-7', '8-14', '15-30', '31+', 'N/A'. RECOMPUTED DAILY — not stable. |
| 50 | VerificationLevelID | smallint | YES | CODE-BACKED | T1 | KYC verification tier ID. 1=Basic, 2=Verified, 3=Fully Verified, etc. From Dim_Customer. |
| 51 | CountryID | int | YES | CODE-BACKED | T1 | FK to Dim_Country. Customer's registered country. |
| 52 | CountryName | varchar(100) | YES | CODE-BACKED | T1 | Country name from Dim_Country. |
| 53 | Region | varchar(100) | YES | CODE-BACKED | T1 | Marketing region label from Dim_Country (e.g., 'EMEA', 'LatAm', 'APAC'). |
| 54 | EU | bit | YES | CODE-BACKED | T1 | 1 if customer's country is an EU member state. From Dim_Country. |
| 55 | RegulationID | int | YES | CODE-BACKED | T1 | FK to Dim_Regulation. Regulatory jurisdiction governing this customer. |
| 56 | RegulatgionName | varchar(200) | YES | CODE-BACKED | T2 | Regulation name from Dim_Regulation. NOTE: column name contains typo 'RegulatgionName' (extra 'g') — matches SP code. Use square brackets when referencing. |
| 57 | Club | varchar(200) | YES | CODE-BACKED | T1 | eToro Club loyalty tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) from Dim_PlayerLevel. |
| 58 | Gender | varchar(200) | YES | CODE-BACKED | T1 | Customer self-reported gender. From Dim_Customer. |
| 59 | Age_Curr | int | YES | CODE-BACKED | T1 | Current age in years. From Dim_Customer. |
| 60 | Age_On_Reg | int | YES | INFERRED | T3 | Age at time of registration. From Dim_Customer. |
| 61 | CFD_Status | varchar(50) | YES | CODE-BACKED | T2 | CFD access status: 'CFD_Allowed', 'CFD_Blocked', or NULL (no assessment). From BI_DB_Scored_Appropriateness_Negative_Market. See §2.6. |
| 62 | CFD_BlockDate | date | YES | CODE-BACKED | T2 | Date CFD access was blocked. NULL if never blocked. |
| 63 | CFD_BlockReasonDesc | varchar(200) | YES | CODE-BACKED | T2 | Reason description for CFD block (e.g., 'Failed Appropriateness Test'). |
| 64 | CFD_ReleaseDate | date | YES | CODE-BACKED | T2 | Date CFD access was restored after blocking. NULL if still blocked or never blocked. |
| 65 | CFD_ReleaseReasonDesc | varchar(200) | YES | CODE-BACKED | T2 | Reason description for CFD release. |
| 66 | DateDiffBlockRelease | int | YES | CODE-BACKED | T2 | Days between CFD block date and release date. NULL if still blocked or never blocked. |
| 67 | FirstDepositAmount | bigint | YES | CODE-BACKED | T1 | First deposit amount in USD. From Dim_Customer.FirstDepositAmount. |
| 68 | FirstAction_Date | date | YES | CODE-BACKED | T2 | Date of customer's first trading action. From BI_DB_First5Actions. |
| 69 | FirstAction_Month | bigint | YES | CODE-BACKED | T2 | First action year-month as YYYYMM. |
| 70 | FirstAction | varchar(200) | YES | CODE-BACKED | T2 | Type of first trading action (e.g., 'Buy', 'CopyTrade'). From BI_DB_First5Actions. |
| 71 | FirstAction_Detailed | varchar(200) | YES | CODE-BACKED | T2 | More detailed first action description. From BI_DB_First5Actions. |
| 72 | FirstInstrument | varchar(200) | YES | CODE-BACKED | T2 | First instrument traded (symbol or instrument name). From BI_DB_First5Actions. |
| 73 | Deposit7days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 7 days after FTD. From BI_DB_First5Actions. |
| 74 | Deposit14days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 14 days after FTD. From BI_DB_First5Actions. |
| 75 | Deposit30days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 30 days after FTD. From BI_DB_First5Actions. |
| 76 | Revenue7days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue generated in first 7 days after FTD. From BI_DB_First5Actions. |
| 77 | Revenue14days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue in first 14 days after FTD. From BI_DB_First5Actions. |
| 78 | Revenue30days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue in first 30 days after FTD. From BI_DB_First5Actions. |
| 79 | Equity7days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer account equity at 7 days after FTD. From BI_DB_First5Actions. |
| 80 | Equity14days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer equity at 14 days after FTD. From BI_DB_First5Actions. |
| 81 | Equity30days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer equity at 30 days after FTD. From BI_DB_First5Actions. |
| 82 | Q23_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q23 (appropriateness assessment). Used in Assessment_Type derivation. |
| 83 | Q33_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q33 (equities experience). Used in Experience_Level computation. |
| 84 | Q34_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q34 (crypto experience). Used in Experience_Level computation. |
| 85 | Q35_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q35 (CFD experience). Used in Experience_Level computation. |
| 86 | Q2_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q2. |
| 87 | Q10_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q10. |
| 88 | Q11_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q11. |
| 89 | Q9_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q9. |
| 90 | Q14_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q14. |
| 91 | Q5_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q5. |
| 92 | Q8_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q8. |
| 93 | Q18_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q18. |
| 94 | UpdateDate | datetime | YES | CODE-BACKED | T2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 95 | KYC_LastUpdateDate | datetime | YES | CODE-BACKED | T2 | Latest KYC answer submission timestamp from UserApiDB (MAX OccurredAt per GCID). Reflects when customer last updated their questionnaire responses. |
| 96 | Q29_Time_Frame_Investing | varchar(200) | YES | CODE-BACKED | T2 | Q29 raw answer ID (intended investment time frame: short/medium/long term). |
| 97 | Q29_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q29. |
| 98 | Q29_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q29. |
| 99 | Q36_US_Permanent_Resident | varchar(200) | YES | CODE-BACKED | T2 | Q36 raw answer ID (US permanent residency status — FinCEN/NFA-regulated customers). |
| 100 | Q36_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q36. |
| 101 | Q36_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q36. |
| 102 | Q40_W9_Certification | varchar(200) | YES | CODE-BACKED | T2 | Q40 raw answer ID (W9 tax certification — US-specific compliance). |
| 103 | Q40_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q40. |
| 104 | Q40_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q40. |
| 105 | Q30_FINRA | varchar(200) | YES | CODE-BACKED | T2 | Q30 raw answer ID (FINRA/broker affiliation — multi-select, US-regulated customers). |
| 106 | Q30_Is_Shareholder | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "10%+ shareholder of a publicly traded company". |
| 107 | Q30_Is_Employed_By_Broker | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "employed by a broker/dealer or FINRA member firm". |
| 108 | Q30_Is_Public_Official | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "government official or public figure". |
| 109 | Q30_Is_None_Apply_To_Me | bit | YES | CODE-BACKED | T2 | 1 if Q30 answer is "none of the above". |
| 110 | Q32_PEP_MM_Question | varchar(200) | YES | CODE-BACKED | T2 | Q32 raw answer ID (PEP / money manager declaration — multi-select). |
| 111 | Q32_Is_Shareholder | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes shareholder status. |
| 112 | Q32_Is_Employed_By_Broker | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes broker/dealer employment. |
| 113 | Q32_Is_Public_Official | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes public official / PEP status. |
| 114 | Q32_Is_None_Apply_To_Me | bit | YES | CODE-BACKED | T2 | 1 if Q32 is "none apply to me". |
| 115 | Q50_Is_Vulnerable_Client | varchar(200) | YES | CODE-BACKED | T2 | Q50 raw answer ID (FCA Consumer Duty vulnerable client self-assessment — FCA-regulated only). |
| 116 | Q50_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q50. |
| 117 | Q50_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q50. |
| 118 | Q45_Invested_Amount_CFDs | varchar(200) | YES | CODE-BACKED | T2 | Q45 raw answer ID (total amount invested in CFDs historically). |
| 119 | Q45_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q45. |
| 120 | Q45_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q45. |
| 121 | Q47_Invested_Amount_Equities | varchar(200) | YES | CODE-BACKED | T2 | Q47 raw answer ID (total amount invested in equities historically). |
| 122 | Q47_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q47. |
| 123 | Q47_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q47. |
| 124 | Q48_Invested_Amount_Crypto | varchar(200) | YES | CODE-BACKED | T2 | Q48 raw answer ID (total amount invested in crypto historically). |
| 125 | Q48_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q48. |
| 126 | Q48_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q48. |
| 127 | Assessment_Type | varchar(200) | YES | CODE-BACKED | T2 | KYC assessment questionnaire version: 'AnswerID_84_87' (legacy), 'AnswerID_101_104', 'AnswerID_142_146' (current), 'N/A'. See §2.2. |
| 128 | Total_Points_Assessment_142_146 | int | YES | CODE-BACKED | T2 | Appropriateness score for AnswerID_142_146 type (+2 correct/-2 wrong). -100 sentinel for all other Assessment_Type values. See §2.3. |

---

## 5. Lineage

See `BI_DB_KYC_Panel.lineage.md` for full column lineage.

### ETL Pipeline Summary

```
UserApiDB.KYC.CustomerAnswers (production — 180M+ rows)
  └── V_CustomerAnswers (UserApiDB view — GCID + QuestionId + AnswerId + texts)
        └── UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel (external table — KYC Panel scope)
              └── BI_DB_KYC_Questions_Answers_Row_Data (intermediate pivot staging)

DWH_dbo.Dim_Customer (IsValidCustomer=1) + Dim_Country + Dim_Regulation + Dim_PlayerLevel + Dim_Funnel
BI_DB_dbo.BI_DB_First5Actions (trading window metrics)
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (CFD eligibility)

  └── SP_KYC_Panel (@Date) — TRUNCATE + full INSERT + DELETE (null-answer rows)
        v
BI_DB_dbo.BI_DB_KYC_Panel (21.7M rows, HASH(GCID), daily snapshot)
```

---

## 6. Relationships

### Produced By
| SP | Schedule | Priority | Pattern |
|----|----------|----------|---------|
| SP_KYC_Panel | Daily | P0 (base layer) | TRUNCATE + full INSERT; delete rows with all answers NULL |

### Read By (known consumers)
| Consumer | Join Key | Purpose |
|---------|---------|---------|
| SP_Regulation_Change_Abuse | Listed in OpsDB dependencies (unverified at code level — SP code does not reference BI_DB_KYC_Panel) | Suspected stale dependency |

---

## 7. Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Verbatim from upstream wiki (DWH_dbo Dim* docs) |
| T2 | ETL-computed — traced to SP code |
| T3 | Inferred from data sampling or naming |
| T4 | Best-available guess |

---

*Documented 2026-04-22 — Batch 33 | SP: SP_KYC_Panel | Quality target: 8.5+*


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


### Upstream `DWH_dbo.V_Liabilities` — synapse
- **Resolved as**: `DWH_dbo.V_Liabilities`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md`

# DWH_dbo.V_Liabilities

> Daily customer liabilities view combining equity snapshots (`Fact_SnapshotEquity`) with unrealized PnL (`Fact_CustomerUnrealized_PnL`) to compute **ActualNWA** (credit-capped net worth), **Liabilities** (customer obligations to the platform), **WA_Liabilities** (credit-covered portion), and asset-class breakdowns — the central view for regulatory balance reporting, dormant fee calculations, AML monitoring, and client balance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Source Tables** | Fact_SnapshotEquity (a), V_M2M_Date_DateRange (b), Fact_CustomerUnrealized_PnL (c), Fact_Guru_Copiers (gc — dead join) |
| **Key Identifier** | CID + DateID |
| **Output Columns** | 75 (T1: 63, T2: 12) |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` |
| **Data Scope** | All dates **before today** (`DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)`) |
| **Generated** | 2026-03-22 |

---

## 1. Business Meaning

`V_Liabilities` is the platform's primary view for computing what eToro owes each customer (liabilities) and how much of the customer's balance is "real" vs promotional credit.

**Core formula** — let `NetEquity = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`:
- **ActualNWA** (Non-Withdrawable Amount): The portion of NetEquity covered by BonusCredit. Clamped to `[0, BonusCredit]`. If the customer's NetEquity exceeds their BonusCredit, ActualNWA = BonusCredit. If NetEquity goes negative, ActualNWA = 0.
- **Liabilities**: InProcessCashouts + the portion of NetEquity **above** BonusCredit. This is what eToro owes the customer — real money, not promotional credit.
- **Balance**: Liabilities + ActualNWA = RealizedEquity + PositionPnL (Confluence: "Summary of V-Liabilities")

**Business context** (from Confluence):
- "If clients lose money, their Actual NWA will reflect only what's left. A client has $1000, loses $200 → Actual NWA = $800. When they profit back to $2000 → Actual NWA = $1000 and Liabilities show $1000 bonus credit."
- The view excludes today's date because end-of-day snapshots (FSE + FCUPNL) must both be loaded before the view is meaningful.

**Key consumers**: SP_DDR_Fact_AUM, SP_Client_Balance_New, SP_Client_Balance_Breakdown, SP_Q_AML_EDD_US_Report, SP_Q_AML_FSA_Report, SP_AML_PI_Abuse, SP_AML_BI_Alerts_New_Singapore, SP_CIDFirstDates, SP_CID_DailyPanel_FullData, SP_CID_MonthlyPanel_FullData, SP_MarketingCloudDaily, SP_Copyfunds_SignificantAllocation, SP_Fact_RegulationTransfer, SP_TIN_Gap, SP_BI_DB_W8_Users_Status, SP_BI_DB_CO_Cluster_Daily, SP_IR_Dashboard_Monitor_Checks, SP_OPS_MultipleAccounts, SP_Q_QSR_New.

---

## 2. Business Logic

### 2.1 Join Structure

```
Fact_SnapshotEquity a                   -- daily equity snapshot per CID
  JOIN V_M2M_Date_DateRange b           -- expands DateRangeID → one row per calendar day (DateKey)
    ON a.DateRangeID = b.DateRangeID
  LEFT JOIN Fact_CustomerUnrealized_PnL c  -- daily PnL snapshot per CID
    ON a.CID = c.CID AND b.DateKey = c.DateModified
  LEFT JOIN Fact_Guru_Copiers gc        -- DEAD JOIN: no columns selected (Boris Slutski, 2021-01-11)
    ON a.CID = gc.CID AND b.DateKey = gc.DateID
WHERE b.DateKey < today
```

### 2.2 Computed Column Formulas

All computed columns use a common intermediate value:

```
NetEquity = ISNULL(TotalPositionsAmount, 0) + ISNULL(TotalCash, 0)
          + ISNULL(TotalStockOrders, 0) + ISNULL(PositionPnL, 0)
```

Note: `TotalStockOrders` is a legacy column hardcoded to 0 since 2019 (see Fact_SnapshotEquity wiki). Its presence in the formula is a historical artifact — it does not affect computation.

| Column | Formula |
|--------|---------|
| **ActualNWA** | `CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END` |
| **Liabilities** | `InProcessCashouts + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END` |
| **WA_Liabilities** | `MIN(Liabilities_excl_cashouts, Credit)` — the portion of liabilities coverable by credit |
| **Liabilities_InUsedMargin** | `MAX(Liabilities_excl_cashouts - Credit, 0)` — liabilities exceeding available credit |
| **LiabilitiesStockReal** | `ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0)` |
| **LiabilitiesCryptoReal** | `ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)` |
| **LiabilitiesCrypto_TRS** | `ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0)` |
| **LiabilitiesFuturesReal** | `ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0)` |
| **TotalStockManualPosition** | `TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount` |
| **ManualStockPositionPnL** | `StocksPositionPnL - MirrorStocksPositionPnL` |
| **TotalCryptoManualPosition** | `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount` |
| **TotalCryptoManualPosition_TRS** | `TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS` |

---

## 3. Source Objects

| Object | Schema | Alias | Role |
|--------|--------|-------|------|
| Fact_SnapshotEquity | DWH_dbo | a | Equity balances, cash, positions, AUM, credit |
| V_M2M_Date_DateRange | DWH_dbo | b | Expands DateRangeID to per-day rows (DateKey, FullDate) |
| Fact_CustomerUnrealized_PnL | DWH_dbo | c | Unrealized PnL, NOP, notional, commissions, risk |
| Fact_Guru_Copiers | DWH_dbo | gc | **Dead join** — no columns selected. LEFT JOIN preserved from 2021, can be removed. |

---

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | Fact_SnapshotEquity.CID | Direct | T1 |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | Direct (alias DateKey → DateID) | T1 |
| 3 | FullDate | V_M2M_Date_DateRange.FullDate | Direct | T1 |
| 4 | RealizedEquity | Fact_SnapshotEquity.RealizedEquity | Direct | T1 |
| 5 | TotalPositionsAmount | Fact_SnapshotEquity.TotalPositionsAmount | Direct | T1 |
| 6 | TotalCash | Fact_SnapshotEquity.TotalCash | Direct | T1 |
| 7 | InProcessCashouts | Fact_SnapshotEquity.InProcessCashouts | Direct | T1 |
| 8 | TotalMirrorPositionsAmount | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Direct | T1 |
| 9 | TotalMirrorCash | Fact_SnapshotEquity.TotalMirrorCash | Direct | T1 |
| 10 | TotalStockOrders | Fact_SnapshotEquity.TotalStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 11 | TotalMirrorStockOrders | Fact_SnapshotEquity.TotalMirrorStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 12 | Credit | Fact_SnapshotEquity.Credit | Direct | T1 |
| 13 | AUM | Fact_SnapshotEquity.AUM | Direct | T1 |
| 14 | BonusCredit | Fact_SnapshotEquity.BonusCredit | Direct | T1 |
| 15 | TotalStockPositionAmount | Fact_SnapshotEquity.TotalStockPositionAmount | Direct | T1 |
| 16 | TotalMirrorStockPositionAmount | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Direct | T1 |
| 17 | PositionPnL | Fact_CustomerUnrealized_PnL.PositionPnL | Direct | T1 |
| 18 | CopyPositionPnL | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Direct | T1 |
| 19 | StandardDeviation | Fact_CustomerUnrealized_PnL.StandardDeviation | Direct | T1 |
| 20 | CommissionOnOpen | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Direct | T1 |
| 21 | ActualNWA | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0) | T2 |
| 22 | Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END | T2 |
| 23 | WA_Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MIN(Liabilities_excl_cashouts, Credit) — credit-capped liabilities | T2 |
| 24 | Liabilities_InUsedMargin | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MAX(Liabilities_excl_cashouts - Credit, 0) — liabilities beyond credit | T2 |
| 25 | StocksPositionPnL | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Direct | T1 |
| 26 | TotalStockManualPosition | Fact_SnapshotEquity | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | T2 |
| 27 | ManualStockPositionPnL | Fact_CustomerUnrealized_PnL | StocksPositionPnL - MirrorStocksPositionPnL | T2 |
| 28 | MirrorStocksPositionPnL | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Direct | T1 |
| 29 | CryptoPositionPnL | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Direct | T1 |
| 30 | ManualCryptoPositionPnL | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Direct | T1 |
| 31 | CopyCryptoPositionPnL | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Direct | T1 |
| 32 | TotalCryptoPositionAmount | Fact_SnapshotEquity.TotalCryptoPositionAmount | Direct | T1 |
| 33 | TotalCryptoManualPosition | Fact_SnapshotEquity | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount | T2 |
| 34 | CopyFundAUM | Fact_SnapshotEquity.CopyFundAUM | Direct | T1 |
| 35 | CopyFundPnL | Fact_CustomerUnrealized_PnL.CopyFundPnL | Direct | T1 |
| 36 | NOP | Fact_CustomerUnrealized_PnL.NOP | Direct | T1 |
| 37 | Notional | Fact_CustomerUnrealized_PnL.Notional | Direct | T1 |
| 38 | NOP_Crypto | Fact_CustomerUnrealized_PnL.NOP_Crypto | Direct | T1 |
| 39 | Notional_Crypto | Fact_CustomerUnrealized_PnL.Notional_Crypto | Direct | T1 |
| 40 | NOP_CFD | Fact_CustomerUnrealized_PnL.NOP_CFD | Direct | T1 |
| 41 | Notional_CFD | Fact_CustomerUnrealized_PnL.Notional_CFD | Direct | T1 |
| 42 | NOP_Crypto_CFD | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Direct | T1 |
| 43 | Notional_Crypto_CFD | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Direct | T1 |
| 44 | PositionPnLStocksReal | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Direct | T1 |
| 45 | PositionPnLCryptoReal | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Direct | T1 |
| 46 | TotalRealStocks | Fact_SnapshotEquity.TotalRealStocks | Direct | T1 |
| 47 | TotalRealCrypto | Fact_SnapshotEquity.TotalRealCrypto | Direct | T1 |
| 48 | LiabilitiesStockReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0) | T2 |
| 49 | LiabilitiesCryptoReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0) | T2 |
| 50 | CommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Direct | T1 |
| 51 | CopyCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Direct | T1 |
| 52 | CryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Direct | T1 |
| 53 | FullCommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Direct | T1 |
| 54 | ManualCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Direct | T1 |
| 55 | NOP_Crypto_TRS | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Direct | T1 |
| 56 | Notional_Crypto_TRS | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Direct | T1 |
| 57 | Total_TRSCrypto | Fact_SnapshotEquity.Total_TRSCrypto | Direct | T1 |
| 58 | TotalCryptoPositionAmount_TRS | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Direct | T1 |
| 59 | TotalCryptoManualPosition_TRS | Fact_SnapshotEquity | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS | T2 |
| 60 | LiabilitiesCrypto_TRS | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0) | T2 |
| 61 | MirrorRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL | Direct | T1 |
| 62 | ManualRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL | Direct | T1 |
| 63 | NOP_FuturesReal | Fact_CustomerUnrealized_PnL.NOP_FuturesReal | Direct | T1 |
| 64 | Notional_FuturesReal | Fact_CustomerUnrealized_PnL.Notional_FuturesReal | Direct | T1 |
| 65 | PositionPnLFuturesReal | Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal | Direct | T1 |
| 66 | FullCommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal | Direct | T1 |
| 67 | CommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal | Direct | T1 |
| 68 | TotalMirrorRealFuturesPositionAmount | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Direct | T1 |
| 69 | TotalRealFutures | Fact_SnapshotEquity.TotalRealFutures | Direct | T1 |
| 70 | TotalFuturesProviderMargin | Fact_SnapshotEquity.TotalFuturesProviderMargin | Direct | T1 |
| 71 | LiabilitiesFuturesReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0) | T2 |
| 72 | NOP_StocksMargin | Fact_CustomerUnrealized_PnL.NOP_StocksMargin | Direct | T1 |
| 73 | PositionPnLStocksMargin | Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin | Direct | T1 |
| 74 | TotalStocksMargin | Fact_SnapshotEquity.TotalStocksMargin | Direct | T1 |
| 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Direct | T1 |

---

## 5. Query Advisory

- **Always filter by DateID** — the view contains the full history of daily snapshots. Unfiltered queries are expensive.
- **Balance formula**: `Liabilities + ActualNWA` or equivalently `ISNULL(RealizedEquity,0) + ISNULL(PositionPnL,0)` (Confluence)
- **TotalCash decomposition**: `TotalCash = Credit + TotalMirrorCash` (Confluence)
- **Today's data is excluded** — the WHERE clause filters `DateKey < today`. This is by design; use yesterday's date.
- **LEFT JOIN to FCUPNL**: PnL columns will be NULL for CIDs with no open positions on a given date. Use ISNULL when aggregating.

---

## 6. Relationships

### 6.1 Upstream Sources

| Source | Join Key | Columns Contributed |
|--------|----------|-------------------|
| Fact_SnapshotEquity | CID + DateRangeID → V_M2M_Date_DateRange | Equity, cash, positions, credit, AUM, asset-class amounts (32 columns) |
| Fact_CustomerUnrealized_PnL | CID + DateModified = DateKey | PnL, NOP, notional, commissions, risk (31 columns) |
| V_M2M_Date_DateRange | DateRangeID | DateKey (→ DateID), FullDate |

### 6.2 Downstream Consumers (20+ SPs)

| SP | Schema | Usage Pattern |
|----|--------|---------------|
| SP_DDR_Fact_AUM | BI_DB_dbo | AUM dashboard aggregation |
| SP_Client_Balance_New | BI_DB_dbo | Customer balance reporting |
| SP_Client_Balance_Breakdown | BI_DB_dbo | Detailed balance decomposition |
| SP_Q_AML_EDD_US_Report | BI_DB_dbo | AML enhanced due diligence (US) |
| SP_Q_AML_FSA_Report | BI_DB_dbo | AML FSA regulatory report |
| SP_AML_PI_Abuse | BI_DB_dbo | Popular Investor abuse detection |
| SP_AML_BI_Alerts_New_Singapore | BI_DB_dbo | AML alerts (Singapore) |
| SP_Fact_RegulationTransfer | DWH_dbo | Regulation transfer processing |
| SP_Fact_CustomerUnrealized_PnL | DWH_dbo | Uses equity from FSE for risk weights |
| SP_CIDFirstDates | BI_DB_dbo | First date tracking per CID |
| SP_MarketingCloudDaily | BI_DB_dbo | Marketing data feed |
| SP_Copyfunds_SignificantAllocation | BI_DB_dbo | Copy fund allocation analysis |
| SP_Q_QSR_New | BI_DB_dbo | QSR regulatory report |
| SP_TIN_Gap | BI_DB_dbo | TIN gap analysis |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Daily customer panel |
| SP_CID_MonthlyPanel_FullData | BI_DB_dbo | Monthly customer panel |
| SP_BI_DB_CO_Cluster_Daily | BI_DB_dbo | Cashout clustering |
| SP_BI_DB_W8_Users_Status | BI_DB_dbo | W8 tax form status |
| SP_IR_Dashboard_Monitor_Checks | BI_DB_dbo | IR dashboard monitoring |
| SP_OPS_MultipleAccounts | BI_DB_dbo | Multiple account detection |
| SP_M_Affiliates_FraudMonitoring | BI_DB_dbo | Affiliate fraud monitoring |

---

## 7. Sample Queries

```sql
-- Customer balance for yesterday
SELECT CID, DateID,
       Liabilities + ActualNWA AS Balance,
       Liabilities, ActualNWA, Credit,
       RealizedEquity, PositionPnL
FROM DWH_dbo.V_Liabilities
WHERE DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)
  AND CID = 12345;

-- Platform total liabilities trend (last 7 days)
SELECT DateID,
       SUM(Liabilities) AS TotalLiabilities,
       SUM(ActualNWA) AS TotalNWA,
       SUM(Liabilities) + SUM(ActualNWA) AS TotalBalance,
       COUNT(DISTINCT CID) AS Customers
FROM DWH_dbo.V_Liabilities
WHERE DateID >= CAST(CONVERT(CHAR(8), GETDATE()-8, 112) AS INT)
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Summary of V-Liabilities (Confluence/BI) | Authoritative business definitions: Balance = Liabilities + ActualNWA = RealizedEquity + PositionPnL. BonusCredit examples. TotalCash = Credit + TotalMirrorCash. |
| BI Dictionary (Confluence/BI) | "V_Liabilities: a view that summarizes or exposes customer liabilities, such as negative balances, equity, Position PnL, etc." |
| DDR Tables (Confluence) | "BI_DB_DDR_Fact_AUM is the same as V_Liabilities table (daily snapshot per user)" — notes equivalence for equity/AUM |
| Azure Data Platform Projects (Confluence/BDP) | Lists V_Liabilities as a Gold-tier replicated asset |
| PNL flow (Confluence/BDP) | V_Liabilities as downstream consumer of PnL pipeline |
| Dormant Fee (Confluence/REGTECH) | Uses V_Liabilities.Liabilities and Credit for dormant fee eligibility |
| Credit Line COs (Confluence/OTS) | NWA / Credit Line rules: "Credit Line × 3 = AAA; Equity - AAA = what can be CO" |

---
*Generated: 2026-03-22 | Reviewed: 2026-03-28 (Batch 17) | Quality: 9.2/10 (★★★★★)*
*Tiers: 63 T1, 12 T2, 0 T3, 0 T4 | Phases: 1,5,7,8,10,11 | 75 cols individually documented — no shortcuts*


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

### Upstream `DWH_dbo.Fact_CustomerAction` — synapse
- **Resolved as**: `DWH_dbo.Fact_CustomerAction`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`

# DWH_dbo.Fact_CustomerAction

> The central customer activity fact table in the Synapse DWH, recording every significant user action — position opens/closes, logins, deposits, cashouts, fees, bonuses, social engagement, copy-trade operations, and more — as one row per event.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | ~11 billion |
| **Production Sources** | `History.Credit` (via `History.ActiveCredit`), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `STS_Audit_UserOperationsData` (logins), `Billing.Login` (cashier logins), `Customer.CustomerStatic` (registrations) |
| **Refresh** | Daily (midnight ETL via SWITCH partition) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + 4 nonclustered |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **UC Format** | Delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | EXTERNAL |

---

## 1. Business Meaning

`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?"

The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema:
1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging
2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging
3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007)
4. **Logins** (ActionTypeID 14): From `STS_Audit_UserOperationsData` (Session Tracking Service) with platform/browser detection
5. **Registrations** (ActionTypeID 41): From `Customer.CustomerStatic`

Because the table unions fundamentally different event types, **most columns are only populated for specific ActionTypeIDs**. Position-related columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are NULL/0 for non-position events. Fee-specific columns (IsFeeDividend, DividendID) are only set for ActionTypeID=35. This is a sparse fact table by design.

The data originates from production systems, flows through the Azure Data Lake and DWH staging tables, and is loaded by `SP_Fact_CustomerAction_DL_To_Synapse` (staging extract) and `SP_Fact_CustomerAction` (transform + load). Post-load, `SP_Fact_CustomerAction_IsParitalCloseParent` marks partial-close parents. The load uses SWITCH partition for daily increments.

---

## 2. Business Logic

### 2.1 ActionTypeID — Event Classification

**What**: Every row is classified by ActionTypeID, which determines what type of customer action occurred and which columns are populated.

**Columns Involved**: `ActionTypeID`, mapped via `DWH_dbo.Dim_ActionType`

**Rules**:

| ActionTypeID | Name | Category | Source |
|---|---|---|---|
| 1 | ManualPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID=0 |
| 2 | CopyPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID>0, OrigParentPositionID>0 |
| 3 | CopyPlusPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID>0 |
| 4 | ManualPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 5 | CopyPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 6 | CopyPlusPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 7 | Deposit | Deposit | History.Credit (CreditTypeID=1) |
| 8 | Cashout | Cashout | History.Credit (CreditTypeID=2) |
| 9 | Bonus | Bonus | History.Credit (CreditTypeID=7) |
| 10 | Cashout request | Cashout request | History.Credit (CreditTypeID=9) |
| 11 | Chargeback | Chargeback | History.Credit (CreditTypeID=11) |
| 12 | Refund | Refund | History.Credit (CreditTypeID=12) |
| 14 | LoggedIn | LoggedIn | STS_Audit_UserOperationsData |
| 15 | Account balance to mirror | Mirror ops | History.Credit (CreditTypeID=18) |
| 16 | Mirror balance to account | Mirror ops | History.Credit (CreditTypeID=19) |
| 17 | Register new mirror | Mirror ops | History.Credit (CreditTypeID=20) |
| 18 | Unregister mirror | Mirror ops | History.Credit (CreditTypeID=21) |
| 19 | Detach position from mirror | DetachPosition | History.Credit |
| 21-26 | Publish Post/Comment/Like, Received Post/Comment/Like | Social engagement | **DEAD DATA** — legacy rows exist but no longer updated. No active ETL. |
| 27 | DepositAttempt | DepositAttempt | History.Credit |
| 28 | DetachedPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 29 | Cashier Loggin | Cashier login | Billing.Login |
| 30 | Processed Cashout | Processed Cashout | History.Credit (CreditTypeID=2 processed) |
| 32 | Edit StopLoss | Edit StopLoss | History.Credit (CreditTypeID=13) |
| 34 | Open Stock Order | Stock order | History.Credit (CreditTypeID=29) |
| 35 | End Of The Week Fee | Fees | History.Credit (CreditTypeID=14) — overnight, weekend, dividend, SDRT, ticket fees |
| 36 | Compensation | Compensation | History.Credit (CreditTypeID=6) |
| 37 | Reverse cashout | Reverse cashout | History.Credit (CreditTypeID=8) |
| 38 | Affiliate Deposit | Deposit | History.Credit |
| 39 | PositionOpenTypeUnknown | PositionOpen | Position open without matching History.Credit (fix at weekly maintenance) |
| 40 | PositionCloseTypeUnknown | PositionClose | Position close without matching History.Credit |
| 41 | Customer Registration | Registration | Customer.CustomerStatic |
| 42 | Cashout Rollback | Chargeback | History.Credit (CreditTypeID=33) |
| 43 | Reverse Deposit | Reverse Deposit | History.Credit (CreditTypeID=32) |
| 44 | InternalDeposit | Deposit | History.Credit (MoveMoneyReasonID=5) |
| 45 | InternalWithdraw | Withdraw | History.Credit (MoveMoneyReasonID=5) |

### 2.2 IsFeeDividend — Fee Sub-Classification

**What**: For ActionTypeID=35 (End of Week Fee), classifies the specific fee type.

**Columns Involved**: `IsFeeDividend`, `Description`

**Rules** (per DSM-1463):
- `1` = Overnight/weekend fee (Description: "Over night fee", "Weekend fee")
- `2` = Dividend payment (Description LIKE '%dividend%')
- `3` = SDRT charge (Description LIKE '%sdrt%')
- `4` = Ticket fees (Description: "OpenTotalFees" or "CloseTotalFees")
- `NULL` = Not ActionTypeID=35

### 2.3 Position-Derived Columns (Shared with Dim_Position)

**What**: ~33 columns in Fact_CustomerAction are copies of the same data from `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay` that also populates `DWH_dbo.Dim_Position`. These columns display the same data under the same column names but are populated independently at ETL time.

**Shared columns**: `PositionID`, `InstrumentID`, `Amount`, `Leverage`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `MirrorID`, `IsSettled`, `InitialUnits`, `IsDiscounted`, `CommissionByUnits`, `FullCommissionByUnits`, `RegulationIDOnOpen`, `ReopenForPositionID`, `IsReOpen`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `OriginalPositionID`, `IsPartialCloseParent`, `IsPartialCloseChild`, `IsAirDrop`, `SettlementTypeID`, `DLTOpen`, `DLTClose`, `OpenMarkupByUnits`, `IsBuy`, `NetProfit`, `RedeemStatus`, `RedeemID`, `IsRedeem`

**Rules**:
- These columns are ONLY populated for position events (ActionTypeID IN 1-6, 28, 39, 40)
- For non-position events, these columns are 0 or NULL
- The ETL joins from staging tables directly — NOT from Dim_Position itself
- Column meanings are identical to Dim_Position (see `Dim_Position.md` for detailed descriptions)

### 2.4 PlatformID — Product/Platform Resolution

**What**: Identifies which product/platform the action originated from. Badly named — it's actually a FK to `Dim_Product.ProductID`, not a standalone platform enum.

**Columns Involved**: `PlatformID`

**Rules**:
- Only populated for ActionTypeID=14 (logins) and 41 (registrations)
- Resolve via JOIN to `DWH_dbo.Dim_Product` — provides Product, Platform, and SubPlatform columns
- Do NOT hard-code value mappings (101=Android, etc.) — always JOIN to Dim_Product

**Query pattern**:
```sql
SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Product dp ON fca.PlatformID = dp.ProductID
WHERE fca.ActionTypeID = 14
```

### 2.6 Reopen Commission Adjustment

**What**: For reopened positions (IsReOpen=1), the commission at close is adjusted.

**Columns Involved**: `CommissionOnClose`, `FullCommissionOnClose`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsReOpen`, `ReopenForPositionID`

**Rules**:
- `CommissionOnClose = new_position.CommissionOnClose - original_position.CommissionOnClose`
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve original values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX + 4 nonclustered indexes (`ActionTypeID+DateID`, `ActionTypeID`, `CompensationReasonID`, `RealCID+DateID`). Always include `RealCID` in WHERE or JOIN for optimal single-distribution queries. The columnstore index enables efficient analytical scans across the ~11B rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as **Delta** (EXTERNAL, ~430 GB, ~7K files), partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). Always include partition columns in WHERE clauses for partition pruning — e.g., `WHERE etr_y = '2025' AND etr_ym = '202503'` will skip scanning irrelevant partitions. Given the table's ~11B rows, partition pruning is critical for any practical query. The partition columns are Databricks-layer additions not present in the Synapse source. Deletion vectors are enabled (`delta.enableDeletionVectors = true`).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All logins for a customer | `WHERE ActionTypeID = 14 AND RealCID = @cid` |
| Position opens in a date range | `WHERE ActionTypeID IN (1,2,3) AND DateID BETWEEN @start AND @end` |
| Revenue (commissions) | `WHERE ActionTypeID IN (1,2,3,4,5,6,28) AND Commission > 0` |
| Deposits for a customer | `WHERE ActionTypeID = 7 AND RealCID = @cid` |
| Overnight fees | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| First-time deposits (FTD) | `WHERE IsFTD = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_ActionType` | `ON fca.ActionTypeID = dat.ActionTypeID` | Action type name and category |
| `DWH_dbo.Dim_Customer` | `ON fca.RealCID = dc.RealCID` | Customer demographics, country |
| `DWH_dbo.Dim_Instrument` | `ON fca.InstrumentID = di.InstrumentID` | Instrument name (position events only) |
| `DWH_dbo.Dim_Position` | `ON fca.PositionID = dp.PositionID` | Full position details (avoid when possible — heavy join on 11B rows) |
| `DWH_dbo.Dim_BonusType` | `ON fca.BonusTypeID = dbt.BonusTypeID` | Bonus type name, IsWithdrawable (bonus events only) |
| `DWH_dbo.Dim_Campaign` | `ON fca.CampaignID = dcm.CampaignID` | Campaign code, description, dates |
| `DWH_dbo.Dim_Country` | `ON fca.CountryIDByIP = dco.CountryID` | Country name from IP geolocation |
| `DWH_dbo.Dim_FundingType` | `ON fca.FundingTypeID = dft.FundingTypeID` | Payment method name (deposit/cashout events) |
| `DWH_dbo.Dim_PaymentStatus` | `ON fca.PaymentStatusID = dps.PaymentStatusID` | Payment status name |
| `DWH_dbo.Dim_Product` | `ON fca.PlatformID = dp.ProductID` | Product, Platform, SubPlatform (logins/registrations only) |
| `DWH_dbo.Dim_Date` | `ON fca.DateID = dd.DateID` | Calendar attributes |
| `DWH_dbo.Dim_Regulation` | `ON fca.RegulationIDOnOpen = dr.ID` | Regulation name |

### 3.4 Gotchas

- **Most columns are only populated for specific ActionTypeIDs.** InstrumentID, Leverage, Commission, IsBuy are all 0/NULL for logins, deposits, social events, etc.
- **11 billion rows** — always filter by ActionTypeID + DateID to avoid full scans
- **IsReal is always 1** in this table — it only contains real-account actions (no demo)
- **Leverage=0 means non-position event**, not "no leverage". For actual position opens, Leverage=1 means no leverage (real ownership)
- **IsBuy NULL** means non-position event. For position events: True=Buy, False=Sell
- **Description is sparse** — only populated for fee events (ActionTypeID=35) and a few others. Contains human-readable strings like "Over night fee", "Payment caused by dividend", "OpenTotalFees"
- **PlatformTypeID** vs **PlatformID**: PlatformTypeID is a legacy field (0=default, 99=STS); PlatformID is a FK to `Dim_Product.ProductID` (badly named — always JOIN to Dim_Product, don't hard-code values)
- **StatusID is nearly always 1** (~11B rows with StatusID=1, ~2M NULL)
- **DemoCID is always 0** (real accounts only)
- **HistoryID is NOT unique** — despite being intended as a key, it contains duplicates. Never use it for JOINs, deduplication, or row identification

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 11 | Amount | decimal(11,2) | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 12 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 13 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 16 | CampaignID | int | NO | Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert) |
| 19 | LoginID | int | NO | Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 21 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned) |
| 26 | DateID | int | NO | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed) |
| 27 | TimeID | int | NO | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed) |
| 28 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21) |
| 31 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | bit | YES | Deprecated/unused column. Always NULL. (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | int | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer's regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | int | YES | Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 57 | IsFTD | int | YES | First-Time Deposit flag: 1 = this is the customer's first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed) |
| 58 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description) |
| 62 | IsAirDrop | int | YES | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | DividendID | int | YES | Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions) |
| 64 | MoveMoneyReasonID | int | YES | Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |
| 66 | DLTOpen | smallint | YES | DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 67 | DLTClose | smallint | YES | DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 69 | Description | varchar(255) | YES | Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 — History.Credit, added 2024-08) |
| 70 | IsBuy | bit | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 71 | CreditID | bigint | YES | Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07) |

---

## 5. Relationships

### 5.1 References To

| Target Object | Join Column | Purpose |
|--------------|-------------|---------|
| DWH_dbo.Dim_ActionType | ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Customer | RealCID | Customer demographics, country, regulation |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument name, type (position events only) |
| DWH_dbo.Dim_Position | PositionID | Full position details (position events only) |
| DWH_dbo.Dim_Product | PlatformID → ProductID | Product, Platform, SubPlatform (badly named FK) |
| DWH_dbo.Dim_Regulation | RegulationIDOnOpen | Regulation name at event time |
| DWH_dbo.Dim_Date | DateID | Calendar attributes |
| DWH_dbo.Dim_BonusType | BonusTypeID | Bonus type name, IsWithdrawable, IsActive |
| DWH_dbo.Dim_Campaign | CampaignID | Campaign code, description, dates, bonus amount |
| DWH_dbo.Dim_Country | CountryIDByIP → CountryID | Country name (IP geolocation) |
| DWH_dbo.Dim_FundingType | FundingTypeID | Payment method name and properties |
| DWH_dbo.Dim_PaymentStatus | PaymentStatusID | Payment status name |
| Dictionary.CreditType | (via CreditID → History.Credit) | Credit type classification |
| Dictionary.MoveMoneyReason | MoveMoneyReasonID | Money movement reason |

### 5.2 Referenced By

| Source Object | Type | Usage |
|--------------|------|-------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | Function | First deposit across platforms |
| BI_DB_dbo.Function_Population_Active_Traders | Function | Active trader population |
| BI_DB_dbo.Function_Population_First_Time_Funded | Function | FTD population |
| BI_DB_dbo.Function_Population_First_Trading_Action | Function | First trading action |
| BI_DB_dbo.Function_Population_OTD_DateRange | Function | OTD date range population |
| BI_DB_dbo.Function_Revenue_Commissions | Function | Commission revenue calculation |
| BI_DB_dbo.Function_Revenue_FullCommissions | Function | Full commission revenue |
| BI_DB_dbo.Function_Revenue_CashoutFee_* | Function | Cashout fee revenue |
| BI_DB_dbo.Function_Revenue_DormantFee | Function | Dormant fee revenue |
| BI_DB_dbo.Function_Revenue_Share_Lending | Function | Share lending revenue |
| BI_DB_dbo.Function_Revenue_TransferCoinFee | Function | Crypto transfer fee revenue |
| BI_DB_dbo.V_C2P_Positions | View | CRM-to-position mapping |
| DWH_dbo.V_FCA_NumOfLogins_mean_1q | View | Average login count (1 quarter) |
| DWH_dbo.SP_Fact_FirstCustomerAction | SP | First action per customer |
| DWH_dbo.Fact_FirstCustomerAction | Table | Derivative table: first action per customer per type |

---

## 6. Dependencies

### 6.1 ETL Pipeline

```
Production Sources:
  History.ActiveCredit + Archive Credit Tables (2007-2022Q1)
    → History.Credit (view, UNION ALL)
      → Generic Pipeline → DWH_staging.Ext_FCA_Real_History_Credit_ForFactAction
  
  Trade.PositionTbl → Trade.OpenPositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Trade_Position
  
  History.Position_Active → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_History_Position
  
  STS_Audit_UserOperationsData (Session Tracking Service)
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Audit_Loggin
  
  Billing.Login → DWH_staging.etoro_Billing_Login
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Cashier_Loggin
  
  Customer.CustomerStatic → DWH_staging.etoro_Customer_CustomerStatic
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Customer_Registration

All staging → SP_Fact_CustomerAction → Ext_FCA_Fact_CustomerAction
  → SP_Fact_CustomerAction_SWITCH → Fact_CustomerAction (SWITCH partition)
  → SP_Fact_CustomerAction_IsParitalCloseParent (post-load update)
```

### 6.2 ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Fact_CustomerAction_DL_To_Synapse | Stage 1: Extract data from lake staging tables into Ext_FCA_* intermediate tables |
| SP_Fact_CustomerAction | Stage 2: Transform and load into Ext_FCA_Fact_C

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

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


### Upstream `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_start.md`

# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start

> ~1.49M-row quarterly AML reporting table capturing start-of-quarter customer snapshots for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` via DELETE+INSERT per quarter. Population: IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3. Contains 11 quarterly snapshots (20231231–20260101) covering 234,560 distinct CIDs with demographic, compliance, activity, and equity attributes.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (DELETE+INSERT per quarter-start snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,489,727 (11 quarterly snapshots, 20231231–20260101) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_start` captures start-of-quarter customer snapshots for the FSA Seychelles AML regulatory report. Each row represents one customer (CID) at one quarter-start date, providing a comprehensive view of their demographic profile, account status, investor classification, activity indicators, and equity positions.

The table is restricted to FSA Seychelles regulated customers (RegulationID=9) who are verified depositors (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3). It is the start-of-period counterpart to `BI_DB_Q_AML_FSA_Report_end` — both are produced by the same `SP_Q_AML_FSA_Report`. The start snapshot uses `Dim_Range` filtered on `@StartDateID` (first day of the quarter), while the end snapshot uses `@EndDateID` (last day of the quarter). Together they enable quarter-over-quarter change analysis for regulatory compliance.

The SP also writes three companion end-of-period tables: `_end` (customer detail), `_end_Market_Value` (market value by instrument type), `_end_Positions` (per-CID trading volumes), and `_end_InvestorType` (aggregated trading by investor segment).

With 11 quarterly snapshots spanning Q4 2023 through Q1 2026, the table enables trend analysis for regulatory compliance metrics including PEP status, account closures/suspensions, investor type distribution, activity rates, and equity positions at the beginning of each reporting period.

---

## 2. Business Logic

### 2.1 Investor Type Classification

**What**: Mutually exclusive investor type flags based on customer country.
**Columns Involved**: `Is_Seychelles_Investor`, `Is_United_States_Investor`, `Is_EU_Investor`, `Is_Other_Country_Investor`
**Rules**:
- `Is_Seychelles_Investor` = 1 if CountryID = 181
- `Is_United_States_Investor` = 1 if CountryID = 219
- `Is_EU_Investor` = 1 if Dim_Country.EU = 1
- `Is_Other_Country_Investor` = 1 if none of the above apply (EU=0 AND CountryID<>219 AND CountryID<>181)

### 2.2 Account Status Flags

**What**: Derived flags for closed and suspended account detection.
**Columns Involved**: `Is_Closed_Account`, `Is_Suspended_Account`
**Rules**:
- `Is_Closed_Account` = 1 if PlayerStatusID IN (2, 4) AND PlayerStatusReasonID IN (3, 6, 40)
- `Is_Suspended_Account` = 1 if PlayerStatusID NOT IN (1, 2, 4, 5)

### 2.3 Seychelles Categorization

**What**: Binary categorization from BackOffice for FSA Seychelles regulatory classification.
**Columns Involved**: `SeychellesCategorization`
**Rules**:
- 'Advanced' if SeychellesCategorizationID = 2 (from External_etoro_BackOffice_Customer, Verified=1)
- 'Basic' otherwise (default)

### 2.4 Account Type Group

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeID = 1 → 'Natural Persons'
- AccountTypeID = 2 → 'Legal Entities'
- Otherwise → 'Other'

### 2.5 Age Group Bucketing

**What**: Age bucketed into standard demographic bands.
**Columns Involved**: `Age_Group`, `Age`
**Rules**:
- Age = DATEDIFF(YEAR, BirthDate, @Date) where @Date is the adjusted SP input
- Age_Group: '18-25', '26-35', '36-45', '46-55', '56-65', '66+', 'N/A' (if BirthDate is NULL or age < 18)

### 2.6 PEP Flag

**What**: Politically Exposed Person indicator from screening status.
**Columns Involved**: `Is_PEP`
**Rules**:
- Is_PEP = 1 if ScreeningStatusID = 3
- Is_PEP = 0 otherwise

### 2.7 Activity Flag

**What**: Customer activity indicator for the quarter.
**Columns Involved**: `Is_Active`, `OpenedOrClosedPos`, `DepositesOrCashout`
**Rules**:
- `OpenedOrClosedPos` = 1 if opened or closed any position during the quarter (from Dim_Position where OpenDateID or CloseDateID between @StartDateID and @EndDateID)
- `DepositesOrCashout` = 1 if any deposit or cashout during the quarter (from Fact_CustomerAction where ActionTypeID IN (7,8))
- `Is_Active` = 1 if either OpenedOrClosedPos = 1 OR DepositesOrCashout = 1

### 2.8 High Net Worth Flag

**What**: Identifies customers who self-reported net worth over $1M.
**Columns Involved**: `Is_High_Net_Worth`
**Rules**:
- Is_High_Net_Worth = 1 if Q11_AnswerID = 38 (Over $1M) in BI_DB_KYC_Panel
- Note: HNW lookup uses the end-of-period population (#pop_end) even for the start table

### 2.9 Equity Calculations

**What**: Customer equity position at quarter end.
**Columns Involved**: `UnrealizedEquity`, `RealizedEquity`
**Rules**:
- `UnrealizedEquity` = SUM(Amount + PositionPnL) from BI_DB_PositionPnL at @EndDateID. ISNULL → 0 for customers without positions.
- `RealizedEquity` = SUM(RealizedEquity) from V_Liabilities at @EndDateID. ISNULL → 0 for customers without liabilities.
- Note: Both equity columns are computed from end-of-period data even for the start snapshot.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. ~1.49M rows across 11 quarterly snapshots. Filter on `Report_Start_Date` for single-quarter analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest quarter snapshot | `WHERE Report_Start_Date = (SELECT MAX(Report_Start_Date) FROM BI_DB_Q_AML_FSA_Report_start)` |
| PEP customer count by quarter | `SELECT Report_Start_Date, SUM(Is_PEP) FROM ... GROUP BY Report_Start_Date` |
| Active customer rate trend | `SELECT Report_Start_Date, AVG(CAST(Is_Active AS FLOAT)) FROM ... GROUP BY Report_Start_Date` |
| Investor type breakdown | `SELECT Report_Start_Date, SUM(Is_Seychelles_Investor), SUM(Is_EU_Investor), SUM(Is_United_States_Investor), SUM(Is_Other_Country_Investor) FROM ... GROUP BY Report_Start_Date` |
| High net worth with large equity | `WHERE Is_High_Net_Worth = 1 AND UnrealizedEquity > 100000` |
| Quarter-over-quarter change | `JOIN BI_DB_Q_AML_FSA_Report_end e ON s.CID = e.CID AND s.Report_Start_Date = e.Report_End_Date - quarter_offset` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_Q_AML_FSA_Report_end | `CID = CID` | Start vs end comparison for same customers |
| BI_DB_Q_AML_FSA_Report_end_Positions | `CID = CID` | Per-instrument trading volumes (end-of-quarter) |

### 3.4 Gotchas

- **Report_Start_Date is int, not date**: Stored as YYYYMMDD integer (e.g., 20260101). Use `CAST(CAST(Report_Start_Date AS VARCHAR) AS DATE)` for date functions.
- **Misspelled column**: `DepositesOrCashout` — note the typo "Deposites" (not "Deposits").
- **Multiple quarters in one table**: Always filter on `Report_Start_Date` to avoid mixing snapshots.
- **Equity uses end-of-period data**: UnrealizedEquity and RealizedEquity are computed from @EndDateID, not @StartDateID. This is a design choice in the SP — start-of-quarter demographic snapshot includes end-of-quarter equity.
- **HNW uses end-of-period population**: The High Net Worth lookup joins against #pop_end, meaning the HNW flag reflects end-of-period KYC answers applied to start-of-period customers.
- **UnrealizedEquity defaults to 0**: ISNULL wrapping means 0 = no open positions, not "equity is zero."
- **RealizedEquity defaults to 0**: Same ISNULL logic — 0 means no V_Liabilities record.
- **Is_Active combines two signals**: A customer can be "active" solely from a deposit/cashout with no trading activity.
- **Population is filtered**: Only FSA Seychelles (RegulationID=9), verified depositors. Do not assume all Seychelles customers are included.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Mapped from Fact_SnapshotCustomer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Regulatory jurisdiction name. Always 'FSA Seychelles' in this table due to RegulationID=9 filter. Passthrough from Dim_Regulation.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Regulation) |
| 3 | Country | varchar(250) | YES | Full country name in English. Unique per row. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 4 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Values: Normal, Block Deposit & Trading, etc. Passthrough from Dim_PlayerStatus.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatus) |
| 5 | PlayerStatusReasons | varchar(250) | YES | Human-readable reason for the player status. Passthrough from Dim_PlayerStatusReasons.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusReasons) |
| 6 | PlayerStatusSubReasonName | varchar(250) | YES | Granular sub-reason beneath the primary status reason. Passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusSubReasons) |
| 7 | EU | int | YES | Whether this country is a full EU member state. 1=EU member, 0=non-EU. Passthrough from Dim_Country.EU. Source: Ext_Dim_Country manual extension table. (Tier 3 — Ext_Dim_Country) |
| 8 | Desk | varchar(250) | YES | Sales/support desk assignment for this country. Passthrough from Dim_Country.Desk. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. (Tier 3 — Ext_Dim_Country_Region_Desk) |
| 9 | Region | varchar(250) | YES | Marketing region label for this country. Passthrough from Dim_Country.Region. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | RiskGroupID | int | YES | Customer risk group identifier from Fact_SnapshotCustomer. (Tier 2 — SP_Q_AML_FSA_Report, Fact_SnapshotCustomer) |
| 11 | SeychellesCategorization | varchar(250) | YES | FSA Seychelles regulatory categorization: 'Advanced' if SeychellesCategorizationID=2, else 'Basic'. Derived from External_etoro_BackOffice_Customer (Verified=1 filter). (Tier 2 — SP_Q_AML_FSA_Report, BackOffice.Customer) |
| 12 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (AccountTypeID=1), 'Legal Entities' (AccountTypeID=2), or 'Other'. Derived from Fact_SnapshotCustomer.AccountTypeID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 13 | Account_Type | varchar(250) | YES | Specific account type name. Passthrough from Dim_AccountType.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 14 | Age_Group | varchar(250) | YES | Demographic age band: 18-25, 26-35, 36-45, 46-55, 56-65, 66+, or N/A. Computed from Dim_Customer.BirthDate relative to the SP @Date parameter. (Tier 2 — SP_Q_AML_FSA_Report) |
| 15 | Age | int | YES | Customer age in years at SP execution date. Computed as DATEDIFF(YEAR, BirthDate, @Date). (Tier 2 — SP_Q_AML_FSA_Report) |
| 16 | MifidCategorization | varchar(250) | YES | MiFID II investor categorization (Retail, Professional, Eligible Counterparty, Retail Pending). Passthrough from Dim_MifidCategorization.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_MifidCategorization) |
| 17 | ScreeningStatus | varchar(250) | YES | AML screening status label. Passthrough from Dim_ScreeningStatus.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 18 | Is_PEP | int | YES | Politically Exposed Person flag. 1 if Dim_Customer.ScreeningStatusID=3, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 19 | Is_Closed_Account | int | YES | Closed account flag. 1 if PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 20 | Is_Suspended_Account | int | YES | Suspended account flag. 1 if PlayerStatusID NOT IN (1,2,4,5), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 21 | Is_Seychelles_Investor | int | YES | Seychelles investor flag. 1 if CountryID=181, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 22 | Is_United_States_Investor | int | YES | United States investor flag. 1 if CountryID=219, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 23 | Is_EU_Investor | int | YES | EU investor flag. 1 if Dim_Country.EU=1, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 24 | Is_Other_Country_Investor | int | YES | Other country investor flag. 1 if not Seychelles (CountryID<>181), not US (CountryID<>219), and not EU (EU=0), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 25 | OpenedOrClosedPos | int | YES | Position activity flag. 1 if customer opened or closed any position during the quarter (OpenDateID or CloseDateID between @StartDateID and @EndDateID). Derived from Dim_Position. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 26 | DepositesOrCashout | int | YES | Deposit/cashout activity flag. 1 if customer had any deposit or cashout during the quarter (ActionTypeID IN (7,8)). Note: column name contains typo ("Deposites"). Derived from Fact_CustomerAction. (Tier 2 — SP_Q_AML_FSA_Report, Fact_CustomerAction) |
| 27 | Is_Active | int | YES | Overall activity flag. 1 if OpenedOrClosedPos=1 OR DepositesOrCashout=1, else 0. Composite of position and monetary activity. (Tier 2 — SP_Q_AML_FSA_Report) |
| 28 | Is_High_Net_Worth | int | YES | High net worth flag. 1 if Q11_AnswerID=38 (Over $1M) in BI_DB_KYC_Panel, else 0. Note: lookup uses end-of-period population. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_KYC_Panel) |
| 29 | UnrealizedEquity | money | YES | Sum of unrealized equity (Amount + PositionPnL) from BI_DB_PositionPnL at quarter end date (@EndDateID). ISNULL defaults to 0 for customers without open positions. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_PositionPnL) |
| 30 | RealizedEquity | money | YES | Sum of realized equity from V_Liabilities at quarter end date (@EndDateID). ISNULL defaults to 0 for customers without liabilities record. (Tier 2 — SP_Q_AML_FSA_Report, V_Liabilities) |
| 31 | Report_Start_Date | int | YES | Quarter-start date as integer in YYYYMMDD format (e.g., 20260101). Identifies which quarterly snapshot this row belongs to. Note: earlier snapshots used quarter-end dates; later snapshots use quarter-start dates. (Tier 2 — SP_Q_AML_FSA_Report) |
| 32 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Fact_SnapshotCustomer |
| Regulation | Dictionary.Regulation | Name | dim-lookup (RegulationID=9 filter) |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup via Dim_PlayerStatus |
| PlayerStatusReasons | Dictionary.PlayerStatusReasons | Name | dim-lookup via Dim_PlayerStatusReasons |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonName | dim-lookup via Dim_PlayerStatusSubReasons |
| EU | Dim_Country | EU | passthrough (source: Ext_Dim_Country) |
| Desk | Dim_Country | Desk | passthrough (source: Ext_Dim_Country_Region_Desk) |
| Region | Dim_Country | Region | passthrough (source: Dictionary.MarketingRegion) |
| RiskGroupID | Fact_SnapshotCustomer | RiskGroupID | passthrough |
| SeychellesCategorization | BackOffice.Customer | SeychellesCategorizationID | CASE: 2='Advanced', else 'Basic' |
| Account_Type_Group | Dim_AccountType | AccountTypeID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| Account_Type | Dim_AccountType | Name | dim-lookup passthrough |
| Age_Group, Age | Customer.CustomerStatic | BirthDate | computed age bucketing |
| MifidCategorization | Dim_MifidCategorization | Name | dim-lookup passthrough |
| ScreeningStatus | Dim_ScreeningStatus | Name | dim-lookup passthrough |
| Is_PEP | Dim_ScreeningStatus | ScreeningStatusID | CASE: 3=1, else 0 |
| Is_Closed_Account | Dim_PlayerStatus, Dim_PlayerStatusReasons | PlayerStatusID, PlayerStatusReasonID | compound CASE |
| Is_Suspended_Account | Dim_PlayerStatus | PlayerStatusID | CASE: NOT IN (1,2,4,5)=1 |
| Is_Seychelles_Investor | Dim_Country | CountryID | CASE: 181=1 |
| Is_United_States_Investor | Dim_Country | CountryID | CASE: 219=1 |
| Is_EU_Investor | Dim_Country | EU | CASE: 1=1 |
| Is_Other_Country_Investor | (computed) | — | residual flag |
| OpenedOrClosedPos | Dim_Position | CID | activity check during quarter |
| DepositesOrCashout | Fact_CustomerAction | CID | activity check during quarter |
| Is_Active | (computed) | — | OR of OpenedOrClosedPos and DepositesOrCashout |
| Is_High_Net_Worth | BI_DB_KYC_Panel | Q11_AnswerID | CASE: 38=1 |
| UnrealizedEquity | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) at @EndDateID |
| RealizedEquity | V_Liabilities | RealizedEquity | SUM at @EndDateID |
| Report_Start_Date | (computed) | — | @StartDateID = quarter-start YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (primary — quarterly snapshot, RegulationID=9)
DWH_dbo.Dim_Customer (HASH(RealCID))
DWH_dbo.Dim_Country (REPLICATE)
DWH_dbo.Dim_Regulation (REPLICATE)
DWH_dbo.Dim_PlayerStatus (REPLICATE)
DWH_dbo.Dim_PlayerStatusReasons (REPLICATE)
DWH_dbo.Dim_PlayerStatusSubReasons (REPLICATE)
DWH_dbo.Dim_AccountType (REPLICATE)
DWH_dbo.Dim_MifidCategorization (REPLICATE)
DWH_dbo.Dim_ScreeningStatus (REPLICATE)
BI_DB_dbo.External_etoro_BackOffice_Customer (SeychellesCategorization)
BI_DB_dbo.BI_DB_KYC_Panel (High Net Worth Q11)
BI_DB_dbo.BI_DB_PositionPnL (unrealized equity)
DWH_dbo.V_Liabilities (realized equity)
DWH_dbo.Dim_Position (position activity)
DWH_dbo.Fact_CustomerAction (deposit/cashout activity)
  |
  |-- SP_Q_AML_FSA_Report (quarterly DELETE+INSERT per Report_Start_Date)
  |   Step 1: Filter Fact_SnapshotCustomer for RegulationID=9, IsDepositor=1,
  |           IsValidCustomer=1, VerificationLevelID=3 at @StartDateID via Dim_Range
  |   Step 2: JOIN to 8+ dimension tables for demographic/status attributes
  |   Step 3: Compute investor type flags (Seychelles/US/EU/Other)
  |   Step 4: Compute account status flags (Closed/Suspended/PEP)
  |   Step 5: Compute activity flags from Dim_Position + Fact_CustomerAction
  |   Step 6: Compute equity from BI_DB_PositionPnL + V_Liabilities (@EndDateID)
  |   Step 7: Compute High Net Worth from BI_DB_KYC_Panel
  |   Step 8: DELETE + INSERT into target table by Report_Start_Date
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start (~1.49M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory start-of-quarter report)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| EU, Desk, Region | DWH_dbo.Dim_Country | Geographic attributes |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account restriction status |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons (Name) | Status change reason |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority |
| Account_Type_Group, Account_Type | DWH_dbo.Dim_AccountType | Account type classification |
| MifidCategorization | DWH_dbo.Dim_MifidCategorization | MiFID II categorization |
| ScreeningStatus, Is_PEP | DWH_dbo.Dim_ScreeningStatus | AML screening status |
| SeychellesCategorization | BI_DB_dbo.External_etoro_BackOffice_Customer | Seychelles regulatory classification |
| Is_High_Net_Worth | BI_DB_dbo.BI_DB_KYC_Panel | KYC Q11 net worth answer |
| UnrealizedEquity | BI_DB_dbo.BI_DB_PositionPnL | Open position equity |
| RealizedEquity | DWH_dbo.V_Liabilities | Closed position equity |
| OpenedOrClosedPos | DWH_dbo.Dim_Position | Position activity |
| DepositesOrCashout | DWH_dbo.Fact_CustomerAction | Monetary activity |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, end-of-quarter counterpart for same CID population |

---

## 7. Sample Queries

### 7.1 PEP Customer Count by Quarter

```sql
SELECT
    Report_Start_Date,
    COUNT(*) AS Total_Customers,
    SUM(Is_PEP) AS PEP_Count,
    CAST(SUM(Is_PEP) AS FLOAT) / COUNT(*) * 100 AS PEP_Pct
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
GROUP BY Report_Start_Date
ORDER BY Report_Start_Date
```

### 7.2 Investor Type Distribution — Latest Quarter

```sql
SELECT
    Report_Start_Date,
    SUM(Is_Seychelles_Investor) AS Seychelles,
    SUM(Is_United_States_Investor) AS US,
    SUM(Is_EU_Investor) AS EU,
    SUM(Is_Other_Country_Investor) AS Other_Country
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
WHERE Report_Start_Date = (SELECT MAX(Report_Start_Date) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start)
GROUP BY Report_Start_Date
```

### 7.3 Start vs End Customer Count Comparison

```sql
SELECT
    s.Report_Start_Date,
    COUNT(DISTINCT s.CID) AS Start_CIDs,
    COUNT(DISTINCT e.CID) AS End_CIDs
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start s
LEFT JOIN BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end e
    ON s.CID = e.CID
GROUP BY s.Report_Start_Date
ORDER BY s.Report_Start_Date
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table. The FSA Seychelles AML report cluster is documented through the sibling `_end` table and associated regulatory compliance Confluence pages.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 2 T1, 27 T2, 2 T3, 0 T4, 1 T5 | Elements: 32/32, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer via SP_Q_AML_FSA_Report*


### Upstream `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end.md`

# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end

> 1.46M-row quarterly AML reporting table capturing end-of-quarter customer snapshots for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` via TRUNCATE+INSERT per quarter. Population: IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3. Contains 9 quarterly snapshots (Q1 2024 through Q1 2026) covering 241,467 distinct CIDs with demographic, compliance, activity, and equity attributes.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (TRUNCATE+INSERT per quarter-end snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,455,064 (9 quarterly snapshots, 20240331–20260331) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end` captures end-of-quarter customer snapshots for the FSA Seychelles AML regulatory report. Each row represents one customer (CID) at one quarter-end date, providing a comprehensive view of their demographic profile, account status, investor classification, activity indicators, and equity positions.

The table is restricted to FSA Seychelles regulated customers (RegulationID=9) who are verified depositors (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3). It is one of three companion tables produced by `SP_Q_AML_FSA_Report` — this table provides the customer-level detail, while `BI_DB_Q_AML_FSA_Report_end_Market_Value` aggregates market values and `BI_DB_Q_AML_FSA_Report_end_Positions` captures per-instrument trading volumes.

With 9 quarterly snapshots spanning Q1 2024 through Q1 2026, the table enables quarter-over-quarter trend analysis for regulatory compliance metrics including PEP status, account closures/suspensions, investor type distribution, activity rates, and equity positions.

---

## 2. Business Logic

### 2.1 Investor Type Classification

**What**: Mutually exclusive investor type flags based on customer country.
**Columns Involved**: `Is_Seychelles_Investor`, `Is_United_States_Investor`, `Is_EU_Investor`, `Is_Other_Country_Investor`
**Rules**:
- `Is_Seychelles_Investor` = 1 if CountryID = 181
- `Is_United_States_Investor` = 1 if CountryID = 219
- `Is_EU_Investor` = 1 if Dim_Country.EU = 1
- `Is_Other_Country_Investor` = 1 if none of the above apply

### 2.2 Account Status Flags

**What**: Derived flags for closed and suspended account detection.
**Columns Involved**: `Is_Closed_Account`, `Is_Suspended_Account`
**Rules**:
- `Is_Closed_Account` = 1 if PlayerStatusID IN (2, 4) AND PlayerStatusReasonID IN (3, 6, 40)
- `Is_Suspended_Account` = 1 if PlayerStatusID NOT IN (1, 2, 4, 5)

### 2.3 Seychelles Categorization

**What**: Binary categorization from BackOffice for FSA Seychelles regulatory classification.
**Columns Involved**: `SeychellesCategorization`
**Rules**:
- 'Advanced' if SeychellesCategorizationID = 2 (from External_etoro_BackOffice_Customer)
- 'Basic' otherwise (default)

### 2.4 Account Type Group

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeGroupID = 1 → 'Natural Persons'
- AccountTypeGroupID = 2 → 'Legal Entities'
- Otherwise → 'Other'

### 2.5 Age Group Bucketing

**What**: Age bucketed into standard demographic bands.
**Columns Involved**: `Age_Group`, `Age`
**Rules**:
- Age = DATEDIFF(year, BirthDate, Report_End_Date)
- Age_Group: '18-25', '26-35', '36-45', '46-55', '56-65', '66+', 'N/A' (if BirthDate is NULL)

### 2.6 PEP Flag

**What**: Politically Exposed Person indicator from screening status.
**Columns Involved**: `Is_PEP`
**Rules**:
- Is_PEP = 1 if ScreeningStatusID = 3
- Is_PEP = 0 otherwise

### 2.7 Activity Flag

**What**: Customer activity indicator for the quarter.
**Columns Involved**: `Is_Active`, `OpenedOrClosedPos`, `DepositesOrCashout`
**Rules**:
- `OpenedOrClosedPos` = 1 if opened or closed any position during the quarter (from Dim_Position)
- `DepositesOrCashout` = 1 if any deposit or cashout during the quarter (from Fact_CustomerAction)
- `Is_Active` = 1 if either OpenedOrClosedPos = 1 OR DepositesOrCashout = 1

### 2.8 High Net Worth Flag

**What**: Identifies customers who self-reported net worth over $1M.
**Columns Involved**: `Is_High_Net_Worth`
**Rules**:
- Is_High_Net_Worth = 1 if Q11_AnswerID = 38 (Over $1M) in BI_DB_KYC_Panel

### 2.9 Equity Calculations

**What**: Customer equity position at quarter end.
**Columns Involved**: `UnrealizedEquity`, `RealizedEquity`
**Rules**:
- `UnrealizedEquity` = SUM(Amount + PositionPnL) from BI_DB_PositionPnL at quarter end date
- `RealizedEquity` = SUM from V_Liabilities at quarter end date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. 1.46M rows across 9 quarterly snapshots. Filter on `Report_End_Date` for single-quarter analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest quarter snapshot | `WHERE Report_End_Date = (SELECT MAX(Report_End_Date) FROM BI_DB_Q_AML_FSA_Report_end)` |
| PEP customer count by quarter | `SELECT Report_End_Date, SUM(Is_PEP) FROM ... GROUP BY Report_End_Date` |
| Active customer rate trend | `SELECT Report_End_Date, AVG(CAST(Is_Active AS FLOAT)) FROM ... GROUP BY Report_End_Date` |
| Investor type breakdown | `SELECT Report_End_Date, SUM(Is_Seychelles_Investor), SUM(Is_EU_Investor), SUM(Is_United_States_Investor), SUM(Is_Other_Country_Investor) FROM ... GROUP BY Report_End_Date` |
| High net worth with large equity | `WHERE Is_High_Net_Worth = 1 AND UnrealizedEquity > 100000` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_Q_AML_FSA_Report_end_Positions | `CID = CID AND Report_End_Date = Report_End_Date` | Per-instrument trading volumes |
| BI_DB_Q_AML_FSA_Report_end_Market_Value | `Report_End_Date = End_DateID` | Aggregated market values (no CID join — aggregated table) |

### 3.4 Gotchas

- **Report_End_Date is int, not date**: Stored as YYYYMMDD integer (e.g., 20260331). Use `CAST(CAST(Report_End_Date AS VARCHAR) AS DATE)` for date functions.
- **Misspelled column**: `DepositesOrCashout` — note the typo "Deposites" (not "Deposits").
- **Multiple quarters in one table**: Always filter on `Report_End_Date` to avoid mixing snapshots.
- **UnrealizedEquity can be NULL**: Customers with no open positions at quarter end will have NULL, not 0.
- **RealizedEquity can be NULL**: Customers with no liabilities record will have NULL.
- **Is_Active combines two signals**: A customer can be "active" solely from a deposit/cashout with no trading activity.
- **Population is filtered**: Only FSA Seychelles (RegulationID=9), verified depositors. Do not assume all Seychelles customers are included.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Regulatory jurisdiction name. Always 'FSA Seychelles' in this table due to RegulationID=9 filter. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Regulation) |
| 3 | Country | varchar(250) | YES | Full country name in English. Unique per row. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 4 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Values: Normal, Block Deposit & Trading, etc. Passthrough from Dim_PlayerStatus. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatus) |
| 5 | PlayerStatusReasons | varchar(250) | YES | Human-readable reason for the player status. Passthrough from Dim_PlayerStatusReasons. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusReasons) |
| 6 | PlayerStatusSubReasonName | varchar(250) | YES | Granular sub-reason beneath the primary status reason. Passthrough from Dim_PlayerStatusSubReasons. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusSubReasons) |
| 7 | EU | int | YES | EU membership flag from Dim_Country. 1=EU member state, 0=non-EU. (Tier 1 — Dim_Country) |
| 8 | Desk | varchar(250) | YES | Regional desk assignment from Dim_Country. Used for internal operational routing. (Tier 3 — Dim_Country) |
| 9 | Region | varchar(250) | YES | Geographic region classification from Dim_Country. (Tier 2 — Dim_Country) |
| 10 | RiskGroupID | int | YES | Customer risk group identifier from Fact_SnapshotCustomer. (Tier 2 — SP_Q_AML_FSA_Report, Fact_SnapshotCustomer) |
| 11 | SeychellesCategorization | varchar(250) | YES | FSA Seychelles regulatory categorization: 'Advanced' if SeychellesCategorizationID=2, else 'Basic'. Derived from External_etoro_BackOffice_Customer. (Tier 2 — SP_Q_AML_FSA_Report, BackOffice.Customer) |
| 12 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (GroupID=1), 'Legal Entities' (GroupID=2), or 'Other'. Derived from Dim_AccountType.AccountTypeGroupID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 13 | Account_Type | varchar(250) | YES | Specific account type name. Passthrough from Dim_AccountType. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 14 | Age_Group | varchar(50) | YES | Demographic age band: 18-25, 26-35, 36-45, 46-55, 56-65, 66+, or N/A. Computed from BirthDate relative to Report_End_Date. (Tier 2 — SP_Q_AML_FSA_Report) |
| 15 | Age | int | YES | Customer age in years at quarter end. Computed as DATEDIFF(year, BirthDate, Report_End_Date). (Tier 2 — SP_Q_AML_FSA_Report) |
| 16 | MifidCategorization | varchar(250) | YES | MiFID II investor categorization (Retail, Professional, Eligible Counterparty). Passthrough from Dim_MifidCategorization. (Tier 2 — SP_Q_AML_FSA_Report, Dim_MifidCategorization) |
| 17 | ScreeningStatus | varchar(250) | YES | AML screening status label. Passthrough from Dim_ScreeningStatus. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 18 | Is_PEP | int | YES | Politically Exposed Person flag. 1 if ScreeningStatusID=3, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 19 | Is_Closed_Account | int | YES | Closed account flag. 1 if PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 20 | Is_Suspended_Account | int | YES | Suspended account flag. 1 if PlayerStatusID NOT IN (1,2,4,5), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 21 | Is_Seychelles_Investor | int | YES | Seychelles investor flag. 1 if CountryID=181, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 22 | Is_United_States_Investor | int | YES | United States investor flag. 1 if CountryID=219, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 23 | Is_EU_Investor | int | YES | EU investor flag. 1 if Dim_Country.EU=1, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 24 | Is_Other_Country_Investor | int | YES | Other country investor flag. 1 if not Seychelles, not US, and not EU, else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 25 | OpenedOrClosedPos | int | YES | Position activity flag. 1 if customer opened or closed any position during the quarter. Derived from Dim_Position. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 26 | DepositesOrCashout | int | YES | Deposit/cashout activity flag. 1 if customer had any deposit or cashout during the quarter. Note: column name contains typo ("Deposites"). Derived from Fact_CustomerAction. (Tier 2 — SP_Q_AML_FSA_Report, Fact_CustomerAction) |
| 27 | Is_Active | int | YES | Overall activity flag. 1 if OpenedOrClosedPos=1 OR DepositesOrCashout=1, else 0. Composite of position and monetary activity. (Tier 2 — SP_Q_AML_FSA_Report) |
| 28 | Is_High_Net_Worth | int | YES | High net worth flag. 1 if Q11_AnswerID=38 (Over $1M) in BI_DB_KYC_Panel, else 0. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_KYC_Panel) |
| 29 | UnrealizedEquity | money | YES | Sum of unrealized equity (Amount + PositionPnL) from BI_DB_PositionPnL at quarter end. NULL if no open positions. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_PositionPnL) |
| 30 | RealizedEquity | money | YES | Sum of realized equity from V_Liabilities at quarter end. NULL if no liabilities record. (Tier 2 — SP_Q_AML_FSA_Report, V_Liabilities) |
| 31 | Report_End_Date | int | YES | Quarter-end date as integer in YYYYMMDD format (e.g., 20240331, 20260331). Identifies which quarterly snapshot this row belongs to. (Tier 2 — SP_Q_AML_FSA_Report) |
| 32 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | dim-lookup (RegulationID=9 filter) |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup via Dim_PlayerStatus |
| PlayerStatusReasons | Dictionary.PlayerStatusReasons | Name | dim-lookup via Dim_PlayerStatusReasons |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | dim-lookup via Dim_PlayerStatusSubReasons |
| EU | Dim_Country | EU | passthrough |
| Desk | Dim_Country | Desk | passthrough |
| Region | Dim_Country | Region | passthrough |
| RiskGroupID | Fact_SnapshotCustomer | RiskGroupID | passthrough |
| SeychellesCategorization | BackOffice.Customer | SeychellesCategorizationID | CASE: 2='Advanced', else 'Basic' |
| Account_Type_Group | Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| Account_Type | Dim_AccountType | Name | dim-lookup passthrough |
| Age_Group, Age | Customer.CustomerStatic | BirthDate | computed age bucketing |
| MifidCategorization | Dim_MifidCategorization | Name | dim-lookup passthrough |
| ScreeningStatus | Dim_ScreeningStatus | Name | dim-lookup passthrough |
| Is_PEP | Dim_ScreeningStatus | ScreeningStatusID | CASE: 3=1, else 0 |
| Is_Closed_Account | Dim_PlayerStatus, Dim_PlayerStatusReasons | PlayerStatusID, PlayerStatusReasonID | compound CASE |
| Is_Suspended_Account | Dim_PlayerStatus | PlayerStatusID | CASE: NOT IN (1,2,4,5)=1 |
| Is_Seychelles_Investor | Dim_Country | CountryID | CASE: 181=1 |
| Is_United_States_Investor | Dim_Country | CountryID | CASE: 219=1 |
| Is_EU_Investor | Dim_Country | EU | CASE: 1=1 |
| Is_Other_Country_Investor | (computed) | — | residual flag |
| OpenedOrClosedPos | Dim_Position | CID | activity check during quarter |
| DepositesOrCashout | Fact_CustomerAction | CID | activity check during quarter |
| Is_Active | (computed) | — | OR of OpenedOrClosedPos and DepositesOrCashout |
| Is_High_Net_Worth | BI_DB_KYC_Panel | Q11_AnswerID | CASE: 38=1 |
| UnrealizedEquity | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) |
| RealizedEquity | V_Liabilities | — | SUM at quarter end |
| Report_End_Date | (computed) | — | quarter-end YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (primary — quarterly snapshot, RegulationID=9)
DWH_dbo.Dim_Customer (HASH(RealCID))
DWH_dbo.Dim_Country (REPLICATE)
DWH_dbo.Dim_Regulation (REPLICATE)
DWH_dbo.Dim_PlayerStatus (REPLICATE)
DWH_dbo.Dim_PlayerStatusReasons (REPLICATE)
DWH_dbo.Dim_PlayerStatusSubReasons (REPLICATE)
DWH_dbo.Dim_AccountType (REPLICATE)
DWH_dbo.Dim_MifidCategorization (REPLICATE)
DWH_dbo.Dim_ScreeningStatus (REPLICATE)
BI_DB_dbo.External_etoro_BackOffice_Customer (SeychellesCategorization)
BI_DB_dbo.BI_DB_KYC_Panel (High Net Worth Q11)
BI_DB_dbo.BI_DB_PositionPnL (unrealized equity)
DWH_dbo.V_Liabilities (realized equity)
DWH_dbo.Dim_Position (position activity)
DWH_dbo.Fact_CustomerAction (deposit/cashout activity)
  |
  |-- SP_Q_AML_FSA_Report (quarterly TRUNCATE+INSERT)
  |   Step 1: Filter Fact_SnapshotCustomer for RegulationID=9, IsDepositor=1,
  |           IsValidCustomer=1, VerificationLevelID=3
  |   Step 2: JOIN to 8+ dimension tables for demographic/status attributes
  |   Step 3: Compute investor type flags (Seychelles/US/EU/Other)
  |   Step 4: Compute account status flags (Closed/Suspended/PEP)
  |   Step 5: Compute activity flags from Dim_Position + Fact_CustomerAction
  |   Step 6: Compute equity from BI_DB_PositionPnL + V_Liabilities
  |   Step 7: Compute High Net Worth from BI_DB_KYC_Panel
  |   Step 8: INSERT into target table
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end (1.46M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| EU, Desk, Region | DWH_dbo.Dim_Country | Geographic attributes |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account restriction status |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons (Name) | Status change reason |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority |
| Account_Type_Group, Account_Type | DWH_dbo.Dim_AccountType | Account type classification |
| MifidCategorization | DWH_dbo.Dim_MifidCategorization | MiFID II categorization |
| ScreeningStatus, Is_PEP | DWH_dbo.Dim_ScreeningStatus | AML screening status |
| SeychellesCategorization | BI_DB_dbo.External_etoro_BackOffice_Customer | Seychelles regulatory classification |
| Is_High_Net_Worth | BI_DB_dbo.BI_DB_KYC_Panel | KYC Q11 net worth answer |
| UnrealizedEquity | BI_DB_dbo.BI_DB_PositionPnL | Open position equity |
| RealizedEquity | DWH_dbo.V_Liabilities | Closed position equity |
| OpenedOrClosedPos | DWH_dbo.Dim_Position | Position activity |
| DepositesOrCashout | DWH_dbo.Fact_CustomerAction | Monetary activity |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Sibling table — same SP, joins on CID + Report_End_Date |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Sibling table — same SP, joins on Report_End_Date (End_DateID) |

---

## 7. Sample Queries

### 7.1 PEP Customer Count by Quarter

```sql
SELECT
    Report_End_Date,
    COUNT(*) AS Total_Customers,
    SUM(Is_PEP) AS PEP_Count,
    CAST(SUM(Is_PEP) AS FLOAT) / COUNT(*) * 100 AS PEP_Pct
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end
GROUP BY Report_End_Date
ORDER BY Report_End_Date
```

### 7.2 Investor Type Distribution — Latest Quarter

```sql
SELECT
    SUM(Is_Seychelles_Investor) AS Seychelles,
    SUM(Is_United_States_Investor) AS US,
    SUM(Is_EU_Investor) AS EU,
    SUM(Is_Other_Country_Investor) AS Other_Country,
    COUNT(*) AS Total
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end
WHERE Report_End_Date = (SELECT MAX(Report_End_Date) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end)
```

### 7.3 High Net Worth Customers with Significant Unrealized Equity

```sql
SELECT CID, Country, SeychellesCategorization, Account_Type_Group,
       UnrealizedEquity, RealizedEquity, Report_End_Date
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end
WHERE Is_High_Net_Worth = 1
  AND UnrealizedEquity > 100000
ORDER BY UnrealizedEquity DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 29 T2, 1 T3, 0 T4, 0 T5 | Elements: 32/32, Logic: 9/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer via SP_Q_AML_FSA_Report*


### Upstream `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end_Market_Value.md`

# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value

> 207K-row quarterly aggregated table containing market value of open positions at quarter end, broken down by Instrument_Type and Account_Type_Group. Populated by `SP_Q_AML_FSA_Report` for FSA Seychelles (RegulationID=9) regulated customers. Sibling table to `BI_DB_Q_AML_FSA_Report_end` (customer detail) and `BI_DB_Q_AML_FSA_Report_end_Positions` (per-customer trading volumes).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (TRUNCATE+INSERT per quarter-end snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~207,198 (9 quarterly snapshots) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end_Market_Value` provides an aggregated view of the market value of all open positions held by FSA Seychelles regulated customers at each quarter end. Each row represents one combination of Instrument_Type, Account_Type_Group, and quarter-end date, with the total market value summed across all customers in that segment.

This table supports the FSA Seychelles quarterly AML report by quantifying the total value of assets under management across different instrument categories (Stocks, ETFs, Real Crypto, CFD Crypto, Other CFDs, Other) and account types (Natural Persons, Legal Entities, Other).

Market_Value is computed as `SUM(AmountInUnitsDecimal * RateBid * USD_CR)` from BI_DB_PositionPnL for open positions at the quarter-end date. This represents the notional USD value of all open positions.

**Note**: Early data (Q1 2024) shows many rows with empty Instrument_Type values — likely a bug in early SP runs where the instrument classification logic was incomplete or the Dim_Instrument join failed for some instruments.

---

## 2. Business Logic

### 2.1 Market Value Calculation

**What**: Total market value of open positions per instrument type and account type group at quarter end.
**Columns Involved**: `Market_Value`
**Rules**:
- Market_Value = SUM(AmountInUnitsDecimal * RateBid * USD_CR) from BI_DB_PositionPnL
- Only includes open positions (CloseDateID=0 or equivalent) at the quarter-end date
- AmountInUnitsDecimal = number of units held
- RateBid = market bid price at snapshot time
- USD_CR = USD conversion rate for non-USD denominated instruments

### 2.2 Instrument Type Classification

**What**: Categorizes instruments into regulatory reporting buckets.
**Columns Involved**: `Instrument_Type`
**Rules**:
- InstrumentTypeID = 5 → 'Stocks'
- InstrumentTypeID = 6 → 'ETFs'
- InstrumentTypeID = 10 AND IsSettled = 1 → 'Real_Crypto' (physically settled crypto)
- InstrumentTypeID = 10 AND IsSettled = 0 → 'CFD_Crypto' (crypto CFDs)
- IsSettled = 0 AND InstrumentTypeID NOT IN (5, 6, 10) → 'Other_CFDs'
- Otherwise → 'Other'
- **Bug note**: Empty Instrument_Type values appear in Q1 2024 data

### 2.3 Account Type Group Classification

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeGroupID = 1 → 'Natural Persons'
- AccountTypeGroupID = 2 → 'Legal Entities'
- Otherwise → 'Other'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table (~207K rows across 9 quarters). Full table scans are efficient.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total market value by quarter | `SELECT End_DateID, SUM(Market_Value) FROM ... GROUP BY End_DateID` |
| Crypto vs non-crypto split | `WHERE Instrument_Type IN ('Real_Crypto','CFD_Crypto')` vs rest |
| Natural persons market exposure | `WHERE Account_Type_Group = 'Natural Persons'` |
| Quarter-over-quarter change | Self-join on End_DateID with LAG() |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Q_AML_FSA_Report_end | `End_DateID = Report_End_Date` | Combine market values with customer-level detail (aggregated level only) |
| BI_DB_Q_AML_FSA_Report_end_Positions | `End_DateID = Report_End_Date AND Instrument_Type = Instrument_Type AND Account_Type_Group = Account_Type_Group` | Combine market value with trading volume |

### 3.4 Gotchas

- **Empty Instrument_Type in early data**: Q1 2024 has rows with blank Instrument_Type — likely a bug in early SP runs. Filter with `WHERE Instrument_Type <> ''` or `WHERE LEN(Instrument_Type) > 0`.
- **End_DateID is int, not date**: Stored as YYYYMMDD integer. Use `CAST(CAST(End_DateID AS VARCHAR) AS DATE)` for date functions.
- **Aggregated table — no CID**: This table has no customer-level granularity. Use the sibling `_end` table for customer detail.
- **Market_Value is money type**: Money type has 4 decimal places. Be aware of implicit rounding in arithmetic operations.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Market_Value | money | YES | Total market value of open positions in USD: SUM(AmountInUnitsDecimal * RateBid * USD_CR) from BI_DB_PositionPnL at quarter end. Represents notional value for all customers in the Instrument_Type + Account_Type_Group segment. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_PositionPnL) |
| 2 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (GroupID=1), 'Legal Entities' (GroupID=2), or 'Other'. Derived from Dim_AccountType.AccountTypeGroupID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 3 | End_DateID | int | YES | Quarter-end date as integer in YYYYMMDD format (e.g., 20240331, 20260331). Identifies which quarterly snapshot this row belongs to. (Tier 2 — SP_Q_AML_FSA_Report) |
| 4 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |
| 5 | Instrument_Type | varchar(200) | YES | Instrument classification: 'Stocks' (IT=5), 'ETFs' (IT=6), 'Real_Crypto' (IT=10 settled), 'CFD_Crypto' (IT=10 not settled), 'Other_CFDs' (not settled non-crypto), 'Other'. Empty values appear in Q1 2024 data due to early-run bug. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Market_Value | BI_DB_PositionPnL | AmountInUnitsDecimal, RateBid, USD_CR | SUM(AmountInUnitsDecimal * RateBid * USD_CR) for open positions |
| Account_Type_Group | Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| End_DateID | (computed) | — | quarter-end YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |
| Instrument_Type | Dim_Instrument | InstrumentTypeID, IsSettled | CASE classification (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other) |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (open positions at quarter end)
DWH_dbo.Dim_Instrument (InstrumentTypeID, IsSettled for classification)
DWH_dbo.Dim_AccountType (AccountTypeGroupID for account type grouping)
  |
  |-- SP_Q_AML_FSA_Report (quarterly TRUNCATE+INSERT)
  |   Step 1: Filter BI_DB_PositionPnL for open positions at quarter-end date
  |   Step 2: JOIN to Dim_Instrument for InstrumentTypeID + IsSettled
  |   Step 3: Classify Instrument_Type (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other)
  |   Step 4: Classify Account_Type_Group from Dim_AccountType
  |   Step 5: Aggregate SUM(AmountInUnitsDecimal * RateBid * USD_CR)
  |           GROUP BY Instrument_Type, Account_Type_Group, End_DateID
  |   Step 6: INSERT into target table
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value (207K rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report — market value component)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Market_Value | BI_DB_dbo.BI_DB_PositionPnL | Source of position values |
| Instrument_Type | DWH_dbo.Dim_Instrument | Instrument classification |
| Account_Type_Group | DWH_dbo.Dim_AccountType | Account type classification |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, joins on End_DateID = Report_End_Date |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Sibling table — same SP, joins on End_DateID = Report_End_Date |

---

## 7. Sample Queries

### 7.1 Total Market Value by Quarter

```sql
SELECT
    End_DateID,
    SUM(Market_Value) AS Total_Market_Value,
    COUNT(*) AS Segment_Count
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE Instrument_Type <> '' OR Instrument_Type IS NOT NULL
GROUP BY End_DateID
ORDER BY End_DateID
```

### 7.2 Crypto Exposure by Quarter and Account Type

```sql
SELECT
    End_DateID,
    Account_Type_Group,
    Instrument_Type,
    Market_Value
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE Instrument_Type IN ('Real_Crypto', 'CFD_Crypto')
ORDER BY End_DateID, Account_Type_Group
```

### 7.3 Instrument Type Breakdown — Latest Quarter

```sql
SELECT
    Instrument_Type,
    Account_Type_Group,
    Market_Value,
    Market_Value * 100.0 / SUM(Market_Value) OVER () AS Pct_of_Total
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE End_DateID = (SELECT MAX(End_DateID) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value)
  AND LEN(Instrument_Type) > 0
ORDER BY Market_Value DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Type: Table | Production Source: BI_DB_dbo.BI_DB_PositionPnL via SP_Q_AML_FSA_Report*


### Upstream `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end_Positions.md`

# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions

> 1.09M-row quarterly table capturing per-customer, per-instrument-type trading volume and value within each quarter for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` alongside sibling tables `BI_DB_Q_AML_FSA_Report_end` (customer detail) and `BI_DB_Q_AML_FSA_Report_end_Market_Value` (aggregated market values). Population: IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (TRUNCATE+INSERT per quarter-end snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,085,687 (9 quarterly snapshots) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end_Positions` captures per-customer, per-instrument-type trading activity within each quarter for the FSA Seychelles AML regulatory report. Each row represents one CID's trading volume and value for a specific instrument type (Stocks, ETFs, Real_Crypto, CFD_Crypto, Other_CFDs, Other) within a single quarter.

The table enables analysis of trading behavior patterns across instrument types for regulatory compliance monitoring. TradingVolume measures the total number of units traded (opens + closes), while TradingValue measures the total USD-equivalent monetary value of those trades.

This is one of three companion tables produced by `SP_Q_AML_FSA_Report`:
- `BI_DB_Q_AML_FSA_Report_end` — customer-level demographic and status snapshot
- `BI_DB_Q_AML_FSA_Report_end_Market_Value` — aggregated market value by instrument type
- `BI_DB_Q_AML_FSA_Report_end_Positions` (this table) — per-customer trading volumes and values

---

## 2. Business Logic

### 2.1 Trading Volume Calculation

**What**: Total units traded per customer per instrument type within the quarter.
**Columns Involved**: `TradingVolume`
**Rules**:
- For position opens during the quarter: SUM(InitialUnits) — the number of units at position opening
- For position closes during the quarter: SUM(AmountInUnitsDecimal) — the number of units at position closing
- TradingVolume = sum of both open and close unit quantities
- Measured in instrument units (shares, coins, lots, etc.)

### 2.2 Trading Value Calculation

**What**: Total USD-equivalent value of trades per customer per instrument type within the quarter.
**Columns Involved**: `TradingValue`
**Rules**:
- For position opens: SUM(InitialUnits * InitForexRate * InitConversionRate) — value at time of opening
- For position closes: SUM(AmountInUnitsDecimal * EndForexRate * EndForex_USDConversionRate) — value at time of closing
- TradingValue = sum of both open and close monetary values in USD
- Forex rates convert from instrument currency to USD

### 2.3 Instrument Type Classification

**What**: Categorizes instruments into regulatory reporting buckets.
**Columns Involved**: `Instrument_Type`
**Rules**:
- InstrumentTypeID = 5 → 'Stocks'
- InstrumentTypeID = 6 → 'ETFs'
- InstrumentTypeID = 10 AND IsSettled = 1 → 'Real_Crypto' (physically settled crypto)
- InstrumentTypeID = 10 AND IsSettled = 0 → 'CFD_Crypto' (crypto CFDs)
- IsSettled = 0 AND InstrumentTypeID NOT IN (5, 6, 10) → 'Other_CFDs'
- Otherwise → 'Other'

### 2.4 Account Type Group Classification

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeGroupID = 1 → 'Natural Persons'
- AccountTypeGroupID = 2 → 'Legal Entities'
- Otherwise → 'Other'

### 2.5 Activity Flag

**What**: Customer activity indicator for the quarter.
**Columns Involved**: `Is_Active`
**Rules**:
- Is_Active = 1 if the customer opened/closed any position or had any deposit/cashout during the quarter
- Same logic as in sibling `BI_DB_Q_AML_FSA_Report_end` table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — 1.09M rows across 9 quarters. Filter on `Report_End_Date` for single-quarter analysis. No hash key; JOINs to other tables on CID will be broadcast joins.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top traders by value | `SELECT TOP 100 CID, SUM(TradingValue) FROM ... WHERE Report_End_Date = X GROUP BY CID ORDER BY 2 DESC` |
| Crypto trading volume trend | `WHERE Instrument_Type IN ('Real_Crypto','CFD_Crypto') GROUP BY Report_End_Date` |
| Instrument type breakdown by quarter | `SELECT Report_End_Date, Instrument_Type, SUM(TradingValue) FROM ... GROUP BY Report_End_Date, Instrument_Type` |
| Inactive customers with positions | `WHERE Is_Active = 0 AND TradingVolume > 0` — should not exist logically |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Q_AML_FSA_Report_end | `CID = CID AND Report_End_Date = Report_End_Date` | Enrich with customer demographics and equity |
| BI_DB_Q_AML_FSA_Report_end_Market_Value | `Report_End_Date = End_DateID AND Instrument_Type = Instrument_Type AND Account_Type_Group = Account_Type_Group` | Combine trading volume with market value |
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |

### 3.4 Gotchas

- **Report_End_Date is int, not date**: Stored as YYYYMMDD integer (e.g., 20240331). Use `CAST(CAST(Report_End_Date AS VARCHAR) AS DATE)` for date functions.
- **TradingVolume units vary by instrument**: Stocks = shares, Crypto = coins, CFDs = lots. Do not compare TradingVolume across instrument types without normalization.
- **TradingValue is in USD**: Forex conversion rates applied at trade time (open or close), not at quarter end. Values are historical, not mark-to-market.
- **Multiple rows per CID per quarter**: One row per CID per Instrument_Type per quarter. A customer trading Stocks and Crypto will have 2 rows for the same quarter.
- **Money type columns**: TradingVolume and TradingValue are money type (4 decimal places). Be aware of implicit rounding.
- **Is_Active may seem redundant**: A row with TradingVolume > 0 implies activity, but Is_Active also includes deposit/cashout-only activity from the sibling table's logic.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Instrument_Type | varchar(250) | YES | Instrument classification: 'Stocks' (IT=5), 'ETFs' (IT=6), 'Real_Crypto' (IT=10 settled), 'CFD_Crypto' (IT=10 not settled), 'Other_CFDs' (not settled non-crypto), 'Other'. Derived from Dim_Instrument. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Instrument) |
| 3 | TradingVolume | money | YES | Total units traded during the quarter: SUM of InitialUnits (opens) + AmountInUnitsDecimal (closes) from Dim_Position. Units depend on instrument type (shares, coins, lots). (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 4 | TradingValue | money | YES | Total USD-equivalent trade value during the quarter: SUM of (InitialUnits*InitForexRate*InitConversionRate) for opens + (AmountInUnitsDecimal*EndForexRate*EndForex_USDConversionRate) for closes. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 5 | Report_End_Date | int | YES | Quarter-end date as integer in YYYYMMDD format (e.g., 20240331, 20260331). Identifies which quarterly snapshot this row belongs to. (Tier 2 — SP_Q_AML_FSA_Report) |
| 6 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |
| 7 | Is_Active | int | YES | Activity flag. 1 if customer had position or deposit/cashout activity during the quarter, else 0. Same logic as sibling _end table. (Tier 2 — SP_Q_AML_FSA_Report) |
| 8 | Country | varchar(250) | YES | Full country name in English. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 9 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (GroupID=1), 'Legal Entities' (GroupID=2), or 'Other'. Derived from Dim_AccountType.AccountTypeGroupID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Dim_Customer |
| Instrument_Type | Dim_Instrument | InstrumentTypeID, IsSettled | CASE classification (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other) |
| TradingVolume | Dim_Position | InitialUnits, AmountInUnitsDecimal | SUM of opens + closes during quarter |
| TradingValue | Dim_Position | InitialUnits, InitForexRate, InitConversionRate, AmountInUnitsDecimal, EndForexRate, EndForex_USDConversionRate | SUM of USD-converted open + close values |
| Report_End_Date | (computed) | — | quarter-end YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |
| Is_Active | Dim_Position + Fact_CustomerAction | CID | 1 if position or deposit/cashout activity |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| Account_Type_Group | Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (position opens/closes during quarter)
DWH_dbo.Dim_Instrument (InstrumentTypeID, IsSettled for classification)
DWH_dbo.Dim_Customer (HASH(RealCID) — CID mapping)
DWH_dbo.Dim_Country (REPLICATE — Country name)
DWH_dbo.Dim_AccountType (REPLICATE — Account_Type_Group)
DWH_dbo.Fact_CustomerAction (deposit/cashout activity for Is_Active)
  |
  |-- SP_Q_AML_FSA_Report (quarterly TRUNCATE+INSERT)
  |   Step 1: Filter Dim_Position for opens/closes within the quarter date range
  |   Step 2: JOIN to Dim_Instrument for InstrumentTypeID + IsSettled
  |   Step 3: Classify Instrument_Type (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other)
  |   Step 4: Compute TradingVolume = SUM(InitialUnits opens + AmountInUnitsDecimal closes)
  |   Step 5: Compute TradingValue = SUM(units * forex rates) for opens and closes
  |   Step 6: Aggregate per CID, Instrument_Type, quarter
  |   Step 7: JOIN Country + Account_Type_Group + Is_Active
  |   Step 8: INSERT into target table
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions (1.09M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report — positions component)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| Instrument_Type | DWH_dbo.Dim_Instrument | Instrument classification |
| TradingVolume, TradingValue | DWH_dbo.Dim_Position | Position open/close data |
| Account_Type_Group | DWH_dbo.Dim_AccountType | Account type classification |
| Is_Active | DWH_dbo.Fact_CustomerAction | Deposit/cashout activity |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, joins on CID + Report_End_Date |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Sibling table — same SP, joins on Report_End_Date + Instrument_Type + Account_Type_Group |

---

## 7. Sample Queries

### 7.1 Top 20 Traders by Value — Latest Quarter

```sql
SELECT TOP 20
    CID,
    Country,
    Account_Type_Group,
    SUM(TradingValue) AS Total_Trading_Value,
    SUM(TradingVolume) AS Total_Trading_Volume
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
WHERE Report_End_Date = (SELECT MAX(Report_End_Date) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions)
GROUP BY CID, Country, Account_Type_Group
ORDER BY Total_Trading_Value DESC
```

### 7.2 Crypto Trading Trend by Quarter

```sql
SELECT
    Report_End_Date,
    Instrument_Type,
    COUNT(DISTINCT CID) AS Unique_Traders,
    SUM(TradingValue) AS Total_Value,
    SUM(TradingVolume) AS Total_Volume
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
WHERE Instrument_Type IN ('Real_Crypto', 'CFD_Crypto')
GROUP BY Report_End_Date, Instrument_Type
ORDER BY Report_End_Date, Instrument_Type
```

### 7.3 Per-Customer Trading Summary with Demographics

```sql
SELECT
    p.CID,
    e.Country,
    e.SeychellesCategorization,
    e.Account_Type_Group,
    p.Instrument_Type,
    p.TradingVolume,
    p.TradingValue,
    e.UnrealizedEquity,
    e.RealizedEquity
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions p
JOIN BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end e
  ON p.CID = e.CID AND p.Report_End_Date = e.Report_End_Date
WHERE p.Report_End_Date = 20260331
  AND p.TradingValue > 100000
ORDER BY p.TradingValue DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 8/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Type: Table | Production Source: DWH_dbo.Dim_Position via SP_Q_AML_FSA_Report*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Q_AML_FSA_Report`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Q_AML_FSA_Report.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Q_AML_FSA_Report] @Date [DATE] AS
BEGIN
SET NOCOUNT ON;

-- EXEC BI_DB_dbo.SP_Q_AML_FSA_Report '20250917' 

/**************************** Date Parameters ************************************/
-- Adjust @Date to be +1 day (so 31/03 becomes 01/04)
	--DECLARE @Date AS DATE = CAST(GETDATE()-1 AS DATE)
	DECLARE @DateID INT = CAST(CONVERT(CHAR(8),@Date,112) AS INT)
    SELECT @Date = DATEADD(DAY, 1, @Date); 
--	DECLARE @Date AS DATE = '20250501'

    DECLARE @StartDate DATE;
    DECLARE @EndDate DATE;
    DECLARE @StartDateID INT;
    DECLARE @EndDateID INT;

/********** Determine Start/End of Previous Quarter **********/
    IF MONTH(@Date) BETWEEN 1 AND 3 -- Q1 (Jan-Mar)
    BEGIN
        -- Previous quarter is Q4 of previous year
        SET @StartDate = DATEFROMPARTS(YEAR(@Date) - 1, 10, 1);
        SET @EndDate = DATEFROMPARTS(YEAR(@Date) - 1, 12, 31);
    END
    ELSE IF MONTH(@Date) BETWEEN 4 AND 6 -- Q2 (Apr-Jun)
    BEGIN
        -- Previous quarter is Q1 of current year
        SET @StartDate = DATEFROMPARTS(YEAR(@Date), 1, 1);
        SET @EndDate = DATEFROMPARTS(YEAR(@Date), 3, 31);
    END
    ELSE IF MONTH(@Date) BETWEEN 7 AND 9 -- Q3 (Jul-Sep)
    BEGIN
        -- Previous quarter is Q2 of current year
        SET @StartDate = DATEFROMPARTS(YEAR(@Date), 4, 1);
        SET @EndDate = DATEFROMPARTS(YEAR(@Date), 6, 30);
    END
    ELSE -- Q4 (Oct-Dec)
    BEGIN
        -- Previous quarter is Q3 of current year
        SET @StartDate = DATEFROMPARTS(YEAR(@Date), 7, 1);
        SET @EndDate = DATEFROMPARTS(YEAR(@Date), 9, 30);
    END

    -- Convert to INT format
    SET @StartDateID = CAST(CONVERT(CHAR(8), @StartDate, 112) AS INT);
    SET @EndDateID = CAST(CONVERT(CHAR(8), @EndDate, 112) AS INT);

/**************************** General Population ************************************/

IF OBJECT_ID('tempdb..#fsa_categorization') IS NOT NULL DROP TABLE #fsa_categorization
CREATE TABLE #fsa_categorization
    WITH (HEAP ,DISTRIBUTION = HASH(CID))
AS
SELECT DISTINCT cc.CID	 
	  ,cc.SeychellesCategorizationID
FROM [BI_DB_dbo].[External_etoro_BackOffice_Customer] cc
WHERE cc.Verified=1
--2 advanced, the rest is basic

-- Start of Period
IF OBJECT_ID('tempdb..#pop_start') IS NOT NULL DROP TABLE #pop_start
CREATE TABLE #pop_start  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS									
SELECT fsc.RealCID	AS 'CID'
	  ,dr1.Name 'Regulation'
	  ,dc.Name 'Country' 
	  ,dps.Name AS PlayerStatus
	  ,dpsr.Name AS PlayerStatusReasons
	  ,dpssr.PlayerStatusSubReasonName
	  ,dc.EU
	  ,dc.Desk
	  ,dc.Region
	  ,dc.RiskGroupID	
	  ,CASE WHEN fc.SeychellesCategorizationID =2 THEN 'Advanced' ELSE 'Basic' END AS SeychellesCategorization
	  ,CASE WHEN fsc.AccountTypeID = 1 THEN 'Natural Persons'								
	        WHEN fsc.AccountTypeID = 2 THEN 'Legal Entities'								
       ELSE 'Other' END 'Account_Type_Group'									
	  ,dat.Name 'Account_Type'								
	  ,CASE WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 18 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 25 THEN '18-25'								
	        WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 26 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 35 THEN '26-35'								
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 36 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 45 THEN '36-45'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 46 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 55 THEN '46-55'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 56 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 65 THEN '56-65'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 66 THEN '66+'						
       ELSE 'N/A' END 'Age_Group' 									
	  ,DATEDIFF(YEAR, dc1.BirthDate, @Date) 'Age'					
	  ,dmc.Name MifidCategorization
	  ,dss.Name AS ScreeningStatus
	  ,CASE WHEN dc1.ScreeningStatusID = 3 THEN 1 ELSE 0 END AS Is_PEP
	  ,CASE WHEN fsc.PlayerStatusID IN (2,4) AND dc1.PlayerStatusReasonID IN (3,6,40) THEN 1 ELSE 0 END AS Is_Closed_Account
	  ,CASE WHEN fsc.PlayerStatusID NOT IN (1,2,4,5) THEN 1 ELSE 0 END AS Is_Suspended_Account
	  ,CASE WHEN fsc.CountryID = 181 THEN 1 ELSE 0 END AS Is_Seychelles_Investor
	  ,CASE WHEN fsc.CountryID = 219 THEN 1 ELSE 0 END AS Is_United_States_Investor
	  ,CASE WHEN dc.EU =1  THEN 1 ELSE 0 END AS Is_EU_Investor
	  ,CASE WHEN dc.EU =0 AND fsc.CountryID <>219 AND fsc.CountryID <>181  THEN 1 ELSE 0 END AS Is_Other_Country_Investor
FROM DWH_dbo.Fact_SnapshotCustomer fsc									
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND @StartDateID BETWEEN dr.FromDateID AND dr.ToDateID									
JOIN DWH_dbo.Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID  
JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID AND fsc.RegulationID = 9	-- FSA								
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID									
JOIN DWH_dbo.Dim_AccountType dat ON fsc.AccountTypeID = dat.AccountTypeID									
JOIN DWH_dbo.Dim_Customer dc1 ON fsc.RealCID = dc1.RealCID
JOIN DWH_dbo.Dim_MifidCategorization dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dc1.ScreeningStatusID = dss.ScreeningStatusID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
LEFT JOIN #fsa_categorization fc ON fsc.RealCID = fc.CID
WHERE fsc.IsDepositor =1									
  AND fsc.IsValidCustomer = 1									
  AND fsc.VerificationLevelID = 3 	

-- End of Period
IF OBJECT_ID('tempdb..#pop_end') IS NOT NULL DROP TABLE #pop_end
CREATE TABLE #pop_end  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS									
SELECT fsc.RealCID	AS 'CID'
	  ,dr1.Name 'Regulation'
	  ,dc.Name 'Country' 	
	  ,dps.Name AS PlayerStatus
	  ,dpsr.Name AS PlayerStatusReasons
	  ,dpssr.PlayerStatusSubReasonName
	  ,dc.EU
	  ,dc.Desk
	  ,dc.Region
	  ,dc.RiskGroupID	
	  ,CASE WHEN fc.SeychellesCategorizationID =2 THEN 'Advanced' ELSE 'Basic' END AS SeychellesCategorization
	  ,CASE WHEN fsc.AccountTypeID = 1 THEN 'Natural Persons'								
	        WHEN fsc.AccountTypeID = 2 THEN 'Legal Entities'								
       ELSE 'Other' END 'Account_Type_Group'									
	  ,dat.Name 'Account_Type'								
	  ,CASE WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 18 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 25 THEN '18-25'								
	        WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 26 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 35 THEN '26-35'								
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 36 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 45 THEN '36-45'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 46 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 55 THEN '46-55'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 56 AND DATEDIFF(YEAR, dc1.BirthDate, @Date) <= 65 THEN '56-65'						
			WHEN DATEDIFF(YEAR, dc1.BirthDate, @Date) >= 66 THEN '66+'						
       ELSE 'N/A' END 'Age_Group' 									
	  ,DATEDIFF(YEAR, dc1.BirthDate, @Date) 'Age'					
	  ,dmc.Name MifidCategorization
	  ,dss.Name AS ScreeningStatus
	  ,CASE WHEN dc1.ScreeningStatusID = 3 THEN 1 ELSE 0 END AS Is_PEP
	  ,CASE WHEN fsc.PlayerStatusID IN (2,4) AND dc1.PlayerStatusReasonID IN (3,6,40) THEN 1 ELSE 0 END AS Is_Closed_Account
	  ,CASE WHEN fsc.PlayerStatusID NOT IN (1,2,4,5) THEN 1 ELSE 0 END AS Is_Suspended_Account
	  ,CASE WHEN fsc.CountryID = 181 THEN 1 ELSE 0 END AS Is_Seychelles_Investor
	  ,CASE WHEN fsc.CountryID = 219 THEN 1 ELSE 0 END AS Is_United_States_Investor
	  ,CASE WHEN dc.EU =1  THEN 1 ELSE 0 END AS Is_EU_Investor
	  ,CASE WHEN dc.EU =0 AND fsc.CountryID <>219 AND fsc.CountryID <>181  THEN 1 ELSE 0 END AS Is_Other_Country_Investor
FROM DWH_dbo.Fact_SnapshotCustomer fsc									
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND @EndDateID BETWEEN dr.FromDateID AND dr.ToDateID									
JOIN DWH_dbo.Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID AND fsc.RegulationID = 9	-- FSA								
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID									
JOIN DWH_dbo.Dim_AccountType dat ON fsc.AccountTypeID = dat.AccountTypeID									
JOIN DWH_dbo.Dim_Customer dc1 ON fsc.RealCID = dc1.RealCID
JOIN DWH_dbo.Dim_MifidCategorization dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dc1.ScreeningStatusID = dss.ScreeningStatusID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
LEFT JOIN #fsa_categorization fc ON fsc.RealCID = fc.CID
WHERE fsc.IsDepositor =1									
  AND fsc.IsValidCustomer = 1									
  AND fsc.VerificationLevelID = 3 	

/** Adding Info **/
-- High Net Worth Individual
IF OBJECT_ID('tempdb..#High_Net_Worth') IS NOT NULL DROP TABLE #High_Net_Worth
CREATE TABLE #High_Net_Worth  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS	
SELECT DISTINCT pop.CID	
FROM #pop_end pop
JOIN BI_DB_dbo.BI_DB_KYC_Panel bdkp ON pop.CID=bdkp.RealCID
WHERE bdkp.Q11_AnswerText IS NOT NULL									
AND bdkp.Q11_AnswerID = 38 -- Over $1M (High Net- Worth)		

--Unrealized Equity
IF OBJECT_ID('tempdb..#UnrealizedEquity') IS NOT NULL DROP TABLE #UnrealizedEquity
CREATE TABLE #UnrealizedEquity  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT  DISTINCT pop.CID, SUM(bdppl.Amount+bdppl.PositionPnL) UnrealizedEquity
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN #pop_end pop ON bdppl.CID = pop.CID
WHERE bdppl.DateID=@EndDateID
GROUP BY pop.CID

--Realized Equity
IF OBJECT_ID('tempdb..#RealizedEquity') IS NOT NULL DROP TABLE #RealizedEquity
CREATE TABLE #RealizedEquity  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT DISTINCT pop.CID, SUM(vl.RealizedEquity) RealizedEquity
FROM DWH_dbo.V_Liabilities vl
JOIN #pop_end pop ON vl.CID = pop.CID
WHERE vl.DateID=@EndDateID
GROUP BY pop.CID

----------------------------------------------------
-----------------------------------------------------
-- Classification of Active Clients - Start of period
IF OBJECT_ID('tempdb..#position_active_s') IS NOT NULL DROP TABLE #position_active_s
CREATE TABLE #position_active_s
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS			
SELECT DISTINCT dp.CID
FROM DWH_dbo.Dim_Position dp
JOIN #pop_start pop ON dp.CID = pop.CID
WHERE (dp.OpenDateID BETWEEN @StartDateID AND @EndDateID)									
	  OR (dp.CloseDateID BETWEEN @StartDateID AND @EndDateID)

IF OBJECT_ID('tempdb..#deposit_cashout_active_s') IS NOT NULL DROP TABLE #deposit_cashout_active_s
CREATE TABLE #deposit_cashout_active_s
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS			
SELECT DISTINCT pop.CID
FROM DWH_dbo.Fact_CustomerAction fca
JOIN #pop_start pop ON fca.RealCID=pop.CID
WHERE fca.ActionTypeID IN (7,8) AND fca.DateID BETWEEN @StartDateID AND @EndDateID

-- Final Active/Inactive Start of period
IF OBJECT_ID('tempdb..#pop_active_start') IS NOT NULL DROP TABLE #pop_active_start
CREATE TABLE #pop_active_start
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS	
SELECT a.* 
	  ,CASE WHEN a.OpenedOrClosedPos =1 OR a.DepositesOrCashout =1 THEN 1 ELSE 0 END AS Is_Active
FROM 
(SELECT pop.*
	  ,CASE WHEN pa.CID IS NOT NULL THEN 1 ELSE 0 END AS 'OpenedOrClosedPos'
	  ,CASE WHEN dc.CID IS NOT NULL THEN 1 ELSE 0 END AS 'DepositesOrCashout'
FROM #pop_start pop
LEFT JOIN #position_active_s  pa ON pop.CID = pa.CID
LEFT JOIN #deposit_cashout_active_s dc ON pop.CID = dc.CID)a

----------------------------------------------------
----------------------------------------------------
-- Classification of Active Clients - End of period
IF OBJECT_ID('tempdb..#position_active_e') IS NOT NULL DROP TABLE #position_active_e
CREATE TABLE #position_active_e
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS			
SELECT DISTINCT dp.CID
FROM DWH_dbo.Dim_Position dp
JOIN #pop_end pop ON dp.CID = pop.CID
WHERE (dp.OpenDateID BETWEEN @StartDateID AND @EndDateID)									
	  OR (dp.CloseDateID BETWEEN @StartDateID AND @EndDateID)

IF OBJECT_ID('tempdb..#deposit_cashout_e') IS NOT NULL DROP TABLE #deposit_cashout_e
CREATE TABLE #deposit_cashout_e
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS			
SELECT DISTINCT pop.CID
FROM DWH_dbo.Fact_CustomerAction fca
JOIN #pop_end pop ON fca.RealCID=pop.CID
WHERE fca.ActionTypeID IN (7,8) AND fca.DateID BETWEEN @StartDateID AND @EndDateID

-- Final Active/Inactive end of period 
IF OBJECT_ID('tempdb..#pop_active_e') IS NOT NULL DROP TABLE #pop_active_e
CREATE TABLE #pop_active_e
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS	
SELECT a.*
	  ,CASE WHEN a.OpenedOrClosedPos =1 OR a.DepositesOrCashout =1 THEN 1 ELSE 0 END AS Is_Active
FROM
(SELECT pop.*
	   ,CASE WHEN pa.CID IS NOT NULL THEN 1 ELSE 0 END AS 'OpenedOrClosedPos'
	   ,CASE WHEN dc.CID IS NOT NULL THEN 1 ELSE 0 END AS 'DepositesOrCashout'
FROM #pop_end pop
LEFT JOIN #position_active_e pa ON pop.CID = pa.CID
LEFT JOIN #deposit_cashout_e dc ON pop.CID = dc.CID)a

----------------------------------------------------
----------------------------------------------------

--  Final Table start of period
IF OBJECT_ID('tempdb..#final_table_start') IS NOT NULL DROP TABLE #final_table_start
CREATE TABLE #final_table_start
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT pp.*
	  ,CASE WHEN hnw.CID IS NOT NULL THEN 1 ELSE 0 END AS Is_High_Net_Worth
	  ,ISNULL(ue.UnrealizedEquity,0) UnrealizedEquity
	  ,ISNULL(re.RealizedEquity,0) RealizedEquity
	  ,@StartDateID AS Report_Start_Date	
FROM #pop_active_start pp
LEFT JOIN #High_Net_Worth hnw ON pp.CID = hnw.CID
LEFT JOIN #UnrealizedEquity ue ON pp.CID = ue.CID
LEFT JOIN #RealizedEquity re ON pp.CID = re.CID

-- Final Table end of period
IF OBJECT_ID('tempdb..#final_table_end') IS NOT NULL DROP TABLE #final_table_end
CREATE TABLE #final_table_end
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT pp.*
	  ,CASE WHEN hnw.CID IS NOT NULL THEN 1 ELSE 0 END AS Is_High_Net_Worth
	  ,ISNULL(ue.UnrealizedEquity,0) UnrealizedEquity
	  ,ISNULL(re.RealizedEquity,0) RealizedEquity
	  ,@EndDateID AS Report_End_Date	
FROM #pop_active_e pp
LEFT JOIN #High_Net_Worth hnw ON pp.CID = hnw.CID
LEFT JOIN #UnrealizedEquity ue ON pp.CID = ue.CID
LEFT JOIN #RealizedEquity re ON pp.CID = re.CID

-- SELECT * FROM #final_table_start
-- SELECT COUNT(*) FROM #final_table_end
----------------------------------------------------
----------------------------------------------------

-- Trading Information - Positions - CID + Country Level
/**
Trading Volume  = Initial Units (open) + Amount in Units (close)
Trading Value = Initial Units * Initial Forex rate * Initial USD Conversion rate >>> During the Q
**/

IF OBJECT_ID('tempdb..#Pop_Positions') IS NOT NULL DROP TABLE #Pop_Positions
CREATE TABLE #Pop_Positions  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT a.CID
	  ,a.Instrument_Type
	  ,a.Is_Active -- > Not Relevant
	  ,a.Country
	  ,a.Account_Type_Group
	  ,a.Report_End_Date	  
	  ,(a.OpenTradingVolume + a.CloseTradingVolume) AS TradingVolume
	  ,(a.OpenTradingValue + a.CloseTradingValue) AS TradingValue
FROM 
(SELECT dp.CID	
	   ,pa.Is_Active
	   ,pa.Country
	   ,pa.Account_Type_Group
	  ,CASE WHEN di.InstrumentTypeID IN (5) THEN 'Stocks'
			WHEN di.InstrumentTypeID IN (6)  THEN 'ETFs' 	
	        WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled = 1 THEN 'Real_Crypto'	
			WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled = 0 THEN 'CFD_Crypto'	
			WHEN dp.IsSettled = 0 AND di.InstrumentTypeID <> 10 THEN 'Other_CFDs' 				
            ELSE 'Other' END 'Instrument_Type' 	
	  ,CASE WHEN dp.OpenDateID >= @StartDateID 
			     AND dp.OpenDateID <= @EndDateID
			     AND ISNULL(dp.IsPartialCloseChild,0) = 0 
	  THEN ISNULL(dp.InitialUnits,0) 
	  ELSE 0 END AS OpenTradingVolume
	  ,CASE WHEN dp.CloseDateID >= @StartDateID 
			     AND dp.CloseDateID <= @EndDateID			    
	  THEN ISNULL(dp.AmountInUnitsDecimal,0) 
	  ELSE 0 END AS CloseTradingVolume
	  ,CASE WHEN dp.OpenDateID >= @StartDateID 
			     AND dp.OpenDateID <= @EndDateID
			     AND ISNULL(dp.IsPartialCloseChild,0) = 0 
	  THEN ISNULL(dp.InitialUnits,0) * ISNULL(dp.InitForexRate,1) * ISNULL(dp.InitConversionRate,1)
	  ELSE 0 END AS OpenTradingValue
	  ,CASE WHEN dp.CloseDateID >= @StartDateID 
			     AND dp.CloseDateID <= @EndDateID			    
	  THEN ISNULL(dp.AmountInUnitsDecimal,0) * ISNULL(dp.EndForexRate,1) *ISNULL(dp.EndForex_USDConversionRate,1)
	  ELSE 0 END AS CloseTradingValue	
	  ,@EndDateID AS Report_End_Date	
FROM DWH_dbo.Dim_Position dp	
JOIN #final_table_end pa ON dp.CID = pa.CID  --- > Only Active
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID  									
WHERE (dp.OpenDateID >= @StartDateID AND dp.OpenDateID <= @EndDateID)					
	  OR (dp.CloseDateID >= @StartDateID  AND dp.CloseDateID <= @EndDateID)	-- Open or close a position within the period			
)a


IF OBJECT_ID('tempdb..#Pop_Positions_final') IS NOT NULL DROP TABLE #Pop_Positions_final
CREATE TABLE #Pop_Positions_final  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS	  	
SELECT CID
	  ,Instrument_Type
	  ,Report_End_Date	
	  ,Is_Active -- Not Relevant only active
	  ,Country
	  ,Account_Type_Group
	  ,SUM(TradingVolume) TradingVolume
	  ,SUM(TradingValue) TradingValue
FROM #Pop_Positions
GROUP BY CID ,Instrument_Type ,Report_End_Date,Is_Active ,Country,Account_Type_Group

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Investor Type:
IF OBJECT_ID('tempdb..#trade_events') IS NOT NULL DROP TABLE #trade_events;
CREATE TABLE #trade_events WITH (HEAP, DISTRIBUTION = HASH(CID)) AS
SELECT
    dp.CID,
    -- open leg
    CASE WHEN dp.OpenDateID BETWEEN @StartDateID AND @EndDateID
              AND ISNULL(dp.IsPartialCloseChild,0) = 0
         THEN ISNULL(dp.InitialUnits,0) ELSE 0 END AS OpenUnits,
    CASE WHEN dp.OpenDateID BETWEEN @StartDateID AND @EndDateID
              AND ISNULL(dp.IsPartialCloseChild,0) = 0
         THEN ISNULL(dp.InitialUnits,0) * ISNULL(dp.InitForexRate,1.0) * ISNULL(dp.InitConversionRate,1.0)
         ELSE 0 END AS OpenValueUSD,
    -- close leg
    CASE WHEN dp.CloseDateID BETWEEN @StartDateID AND @EndDateID
         THEN ISNULL(dp.AmountInUnitsDecimal,0) ELSE 0 END AS CloseUnits,
    CASE WHEN dp.CloseDateID BETWEEN @StartDateID AND @EndDateID
         THEN ISNULL(dp.AmountInUnitsDecimal,0) * ISNULL(dp.EndForexRate,1.0) * ISNULL(dp.EndForex_USDConversionRate,1.0)
         ELSE 0 END AS CloseValueUSD
		 ,@EndDateID AS EndDateID
FROM DWH_dbo.Dim_Position dp
JOIN #pop_end pe ON pe.CID = dp.CID
WHERE (dp.OpenDateID  BETWEEN @StartDateID AND @EndDateID)
   OR (dp.CloseDateID BETWEEN @StartDateID AND @EndDateID);

IF OBJECT_ID('tempdb..#trading_cid') IS NOT NULL DROP TABLE #trading_cid;
CREATE TABLE #trading_cid WITH (HEAP, DISTRIBUTION = HASH(CID)) AS
SELECT
    CID,
	EndDateID,
    SUM(OpenUnits + CloseUnits)                       AS TradingVolume,
    SUM(OpenValueUSD + CloseValueUSD)                 AS TradingValueUSD
FROM #trade_events
GROUP BY CID,EndDateID

-- FINAL Trading output per Investor Type (one row per investor segment)
IF OBJECT_ID('tempdb..#investor_Type') IS NOT NULL DROP TABLE #investor_Type
CREATE TABLE #investor_Type WITH (HEAP, DISTRIBUTION = ROUND_ROBIN) AS
SELECT
    CASE 
      WHEN pe.Is_Seychelles_Investor = 1         THEN 'Seychelles'
      WHEN pe.Is_United_States_Investor = 1      THEN 'US'
      WHEN pe.Is_EU_Investor = 1                 THEN 'EU'
      WHEN pe.Is_Other_Country_Investor = 1      THEN 'Other'
      ELSE 'Unclassified'
    END AS Investor_Type,
	EndDateID,
    SUM(tc.TradingVolume)   AS TradingVolume,
    SUM(tc.TradingValueUSD) AS TradingValueUSD
FROM #trading_cid tc
JOIN #pop_end pe ON pe.CID = tc.CID
GROUP BY EndDateID,
    CASE 
      WHEN pe.Is_Seychelles_Investor = 1         THEN 'Seychelles'
      WHEN pe.Is_United_States_Investor = 1      THEN 'US'
      WHEN pe.Is_EU_Investor = 1                 THEN 'EU'
      WHEN pe.Is_Other_Country_Investor = 1      THEN 'Other'
      ELSE 'Unclassified'
    END
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Market Value - Open positions > For the end of the period

-- Open positions as of end-of-period
IF OBJECT_ID('tempdb..#open_positions_eod') IS NOT NULL DROP TABLE #open_positions_eod;
CREATE TABLE #open_positions_eod WITH (HEAP, DISTRIBUTION = HASH(PositionID)) AS
SELECT dp.PositionID, dp.CID
FROM DWH_dbo.Dim_Position dp
JOIN #pop_end pe ON pe.CID = dp.CID
WHERE dp.OpenDateID <= @EndDateID
  AND (dp.CloseDateID =0);

-- Map PositionID -> Instrument_Type 
IF OBJECT_ID('tempdb..#pos_types') IS NOT NULL DROP TABLE #pos_types;
CREATE TABLE #pos_types WITH (HEAP, DISTRIBUTION = HASH(PositionID)) AS
SELECT  op.PositionID,
        CASE 
          WHEN di.InstrumentTypeID = 5 THEN 'Stocks'
          WHEN di.InstrumentTypeID = 6 THEN 'ETFs'
          WHEN di.InstrumentTypeID = 10 AND dp.IsSettled = 1 THEN 'Real_Crypto'
          WHEN di.InstrumentTypeID = 10 AND dp.IsSettled = 0 THEN 'CFD_Crypto'
          WHEN dp.IsSettled = 0 AND di.InstrumentTypeID <> 10 THEN 'Other_CFDs'
          ELSE 'Other'
        END AS Instrument_Type
FROM #open_positions_eod op
JOIN DWH_dbo.Dim_Position  dp ON dp.PositionID = op.PositionID
JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID = dp.InstrumentID;

-- End-of-day valuation (one row per PositionID on @EndDateID)
IF OBJECT_ID('tempdb..#mv_eod') IS NOT NULL DROP TABLE #mv_eod;
CREATE TABLE #mv_eod WITH (HEAP, DISTRIBUTION = HASH(PositionID)) AS
SELECT  op.PositionID,
        op.CID,
        CAST(ISNULL(pp.AmountInUnitsDecimal,0) * ISNULL(pp.RateBid,1.0) * ISNULL(pp.USD_CR,1.0)
             AS DECIMAL(38,8)) AS Market_Value
			 ,@EndDateID AS End_DateID 
FROM #open_positions_eod op
JOIN BI_DB_dbo.BI_DB_PositionPnL pp
  ON pp.PositionID = op.PositionID
 AND pp.DateID     = @EndDateID;

-- FINAL MV output
IF OBJECT_ID('tempdb..#Market_Value') IS NOT NULL DROP TABLE #Market_Value;
CREATE TABLE #Market_Value WITH (HEAP, DISTRIBUTION = ROUND_ROBIN) AS
SELECT
    pt.Instrument_Type,
    pe.Account_Type_Group,
	mv.End_DateID,
    SUM(mv.Market_Value) AS Market_Value
FROM #mv_eod mv
JOIN #pos_types pt ON pt.PositionID = mv.PositionID
JOIN #pop_end  pe ON pe.CID = mv.CID
GROUP BY pt.Instrument_Type, pe.Account_Type_Group,mv.End_DateID

-- SELECT * FROM #Market_Value
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-- Check:
--IF OBJECT_ID('tempdb..#samples') IS NOT NULL DROP TABLE #samples
--CREATE TABLE #samples  
--    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
--AS	
--SELECT TOP 6 mv.CID
--FROM #mv_eod mv
--JOIN #pos_types pt ON pt.PositionID = mv.PositionID
--WHERE pt.Instrument_Type = 'ETFs'



--IF OBJECT_ID('tempdb..#qa_etf_pos_detail') IS NOT NULL DROP TABLE #qa_etf_pos_detail
--CREATE TABLE #qa_etf_pos_detail  
--    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
--AS	
--SELECT
--    mv.CID,
--    mv.PositionID,
--    pt.Instrument_Type,
--    pe.Account_Type_Group,
--    CAST(mv.Market_Value_USD AS DECIMAL(38,8)) AS MV_USD
--FROM #mv_eod mv
--JOIN #pos_types pt ON pt.PositionID = mv.PositionID
--JOIN #pop_end  pe ON pe.CID        = mv.CID
--JOIN #samples sc ON sc.CID     = mv.CID
--WHERE pt.Instrument_Type = 'ETFs'

--/* Client x Account_Type_Group totals (should match any other rollup you do) */
--IF OBJECT_ID('tempdb..#qa_etf_client_mv') IS NOT NULL DROP TABLE #qa_etf_client_mv
--CREATE TABLE #qa_etf_client_mv WITH (HEAP, DISTRIBUTION = HASH(CID)) AS
--SELECT
--    CID,
--    Account_Type_Group,
--    SUM(MV_USD) AS MV_USD
--FROM #qa_etf_pos_detail
--GROUP BY CID, Account_Type_Group;

--IF OBJECT_ID('tempdb..#qa_etf_subset_rollup') IS NOT NULL DROP TABLE #qa_etf_subset_rollup;
--CREATE TABLE #qa_etf_subset_rollup WITH (HEAP, DISTRIBUTION = ROUND_ROBIN) AS
--SELECT
--    Instrument_Type,
--    Account_Type_Group,
--    SUM(MV_USD) AS MV_USD
--FROM #qa_etf_pos_detail
--GROUP BY Instrument_Type, Account_Type_Group;

--/* Re-sum the detail and compare to the client table (should be identical) */
--SELECT
--    d.CID,
--    d.Account_Type_Group,
--    SUM(d.MV_USD) AS Detail_Sum,
--    c.MV_USD      AS Client_Sum,
--    SUM(d.MV_USD) - c.MV_USD AS Diff
--FROM #qa_etf_pos_detail d
--JOIN #qa_etf_client_mv c
--  ON c.CID = d.CID AND c.Account_Type_Group = d.Account_Type_Group
--GROUP BY d.CID, d.Account_Type_Group, c.MV_USD
--ORDER BY ABS(SUM(d.MV_USD) - c.MV_USD) DESC;




-- Final Table - End of Period
IF OBJECT_ID('tempdb..#final_final_end') IS NOT NULL DROP TABLE #final_final_end
CREATE TABLE #final_final_end  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS	
SELECT ff.CID
	  ,ff.Regulation
	  ,ff.Country
	  ,ff.PlayerStatus
	  ,ff.PlayerStatusReasons
	  ,ff.SeychellesCategorization
	  ,ff.Account_Type_Group
	  ,ff.Account_Type
	  ,ff.Age_Group
	  ,ff.Age
	  ,ff.MifidCategorization
	  ,ff.ScreeningStatus
	  ,ff.Is_PEP
	  ,ff.Is_Closed_Account
	  ,ff.Is_Suspended_Account
	  ,ff.Is_Seychelles_Investor
	  ,ff.Is_United_States_Investor
	  ,ff.Is_EU_Investor
	  ,ff.Is_Other_Country_Investor
	  ,ff.OpenedOrClosedPos
	  ,ff.DepositesOrCashout
	  ,ff.Is_Active
	  ,ff.Is_High_Net_Worth
	  ,ff.UnrealizedEquity
	  ,ff.RealizedEquity	
	  ,ff.Report_End_Date 
FROM #final_table_end ff

-- Final Table - Start of Period
IF OBJECT_ID('tempdb..#final_final_start') IS NOT NULL DROP TABLE #final_final_start
CREATE TABLE #final_final_start  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS	
SELECT fts.CID
	  ,fts.Regulation
	  ,fts.Country
	  ,fts.PlayerStatus
	  ,fts.PlayerStatusReasons
	  ,fts.PlayerStatusSubReasonName
	  ,fts.EU
	  ,fts.Desk
	  ,fts.Region
	  ,fts.RiskGroupID
	  ,fts.SeychellesCategorization
	  ,fts.Account_Type_Group
	  ,fts.Account_Type
	  ,fts.Age_Group
	  ,fts.Age
	  ,fts.MifidCategorization
	  ,fts.ScreeningStatus
	  ,fts.Is_PEP
	  ,fts.Is_Closed_Account
	  ,fts.Is_Suspended_Account
	  ,fts.Is_Seychelles_Investor
	  ,fts.Is_United_States_Investor
	  ,fts.Is_EU_Investor
	  ,fts.Is_Other_Country_Investor
	  ,fts.OpenedOrClosedPos
	  ,fts.DepositesOrCashout
	  ,fts.Is_Active
	  ,fts.Is_High_Net_Worth
	  ,fts.UnrealizedEquity
	  ,fts.RealizedEquity
	  ,fts.Report_Start_Date 
FROM #final_table_start fts

/********** Delete and Insert into Table **********/
DELETE FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
WHERE Report_Start_Date = @StartDateID

INSERT INTO BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
	  (CID
	  ,Regulation
	  ,Country
	  ,PlayerStatus
	  ,PlayerStatusReasons
	  ,PlayerStatusSubReasonName
	  ,EU
	  ,Desk
	  ,Region
	  ,RiskGroupID
	  ,SeychellesCategorization
	  ,Account_Type_Group
	  ,Account_Type
	  ,Age_Group
	  ,Age
	  ,MifidCategorization
	  ,ScreeningStatus
	  ,Is_PEP
	  ,Is_Closed_Account
	  ,Is_Suspended_Account
	  ,Is_Seychelles_Investor
	  ,Is_United_States_Investor
	  ,Is_EU_Investor
	  ,Is_Other_Country_Investor
	  ,OpenedOrClosedPos
	  ,DepositesOrCashout
	  ,Is_Active
	  ,Is_High_Net_Worth
	  ,UnrealizedEquity
	  ,RealizedEquity
	  ,Report_Start_Date
	  ,UpdateDate
	 )
SELECT CID
	  ,Regulation
	  ,Country
	  ,PlayerStatus
	  ,PlayerStatusReasons
	  ,PlayerStatusSubReasonName
	  ,EU
	  ,Desk
	  ,Region
	  ,RiskGroupID
	  ,SeychellesCategorization
	  ,Account_Type_Group
	  ,Account_Type
	  ,Age_Group
	  ,Age
	  ,MifidCategorization
	  ,ScreeningStatus
	  ,Is_PEP
	  ,Is_Closed_Account
	  ,Is_Suspended_Account
	  ,Is_Seychelles_Investor
	  ,Is_United_States_Investor
	  ,Is_EU_Investor
	  ,Is_Other_Country_Investor
	  ,OpenedOrClosedPos
	  ,DepositesOrCashout
	  ,Is_Active
	  ,Is_High_Net_Worth
	  ,UnrealizedEquity
	  ,RealizedEquity
	  ,Report_Start_Date
	  ,GETDATE() AS UpdateDate
FROM #final_final_start  

/********** Delete and Insert into Table **********/
DELETE FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end
WHERE Report_End_Date = @EndDateID

INSERT INTO BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end
	  (CID
	  ,Regulation
	  ,Country
	  ,PlayerStatus
	  ,PlayerStatusReasons
	  ,PlayerStatusSubReasonName
	  ,EU
	  ,Desk
	  ,Region
	  ,RiskGroupID
	  ,SeychellesCategorization
	  ,Account_Type_Group
	  ,Account_Type
	  ,Age_Group
	  ,Age
	  ,MifidCategorization
	  ,ScreeningStatus
	  ,Is_PEP
	  ,Is_Closed_Account
	  ,Is_Suspended_Account
	  ,Is_Seychelles_Investor
	  ,Is_United_States_Investor
	  ,Is_EU_Investor
	  ,Is_Other_Country_Investor
	  ,OpenedOrClosedPos
	  ,DepositesOrCashout
	  ,Is_Active
	  ,Is_High_Net_Worth
	  ,UnrealizedEquity
	  ,RealizedEquity
	  ,Report_End_Date
	  ,UpdateDate)
SELECT CID
	  ,Regulation
	  ,Country
	  ,PlayerStatus
	  ,PlayerStatusReasons
	  ,PlayerStatusSubReasonName
	  ,EU
	  ,Desk
	  ,Region
	  ,RiskGroupID
	  ,SeychellesCategorization
	  ,Account_Type_Group
	  ,Account_Type
	  ,Age_Group
	  ,Age
	  ,MifidCategorization
	  ,ScreeningStatus
	  ,Is_PEP
	  ,Is_Closed_Account
	  ,Is_Suspended_Account
	  ,Is_Seychelles_Investor
	  ,Is_United_States_Investor
	  ,Is_EU_Investor
	  ,Is_Other_Country_Investor
	  ,OpenedOrClosedPos
	  ,DepositesOrCashout
	  ,Is_Active
	  ,Is_High_Net_Worth
	  ,UnrealizedEquity
	  ,RealizedEquity
	  ,Report_End_Date
	  ,GETDATE() AS UpdateDate
FROM #final_table_end    

/********** Delete and Insert into Table - Market Value**********/
DELETE FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE End_DateID = @EndDateID

INSERT INTO BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
	  (Instrument_Type
	  ,Account_Type_Group
	  ,End_DateID
	  ,Market_Value
	  ,UpdateDate)
SELECT Instrument_Type
	  ,Account_Type_Group
	  ,End_DateID
	  ,Market_Value
	  ,GETDATE() AS UpdateDate
FROM #Market_Value

/********** Delete and Insert into Table -Positions**********/
DELETE FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
WHERE Report_End_Date = @EndDateID

INSERT INTO BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
	  (CID
	  ,Instrument_Type
	  ,Report_End_Date
	  ,Is_Active
	  ,Country
	  ,Account_Type_Group
	  ,TradingVolume
	  ,TradingValue
	  ,UpdateDate)
SELECT CID
	  ,Instrument_Type
	  ,Report_End_Date
	  ,Is_Active
	  ,Country
	  ,Account_Type_Group
	  ,TradingVolume
	  ,TradingValue
	  ,GETDATE() AS UpdateDate
FROM #Pop_Positions_final 


/********** Delete and Insert into Table -InvestorType **********/
DELETE FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType
WHERE EndDateID = @EndDateID

INSERT INTO BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType
	  (Investor_Type
	  ,EndDateID
	  ,TradingVolume
	  ,TradingValueUSD 
	 ,UpdateDate)
SELECT Investor_Type
	  ,EndDateID
	  ,TradingVolume
	  ,TradingValueUSD 
	   ,GETDATE() AS UpdateDate
FROM #investor_Type

/********** END SP **********/
END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Q_AML_FSA_Report` | synapse_sp | BI_DB_dbo | SP_Q_AML_FSA_Report | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Q_AML_FSA_Report.sql` |
| `BI_DB_dbo.External_etoro_BackOffice_Customer` | unresolved | BI_DB_dbo | External_etoro_BackOffice_Customer | `—` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_AccountType` | synapse | DWH_dbo | Dim_AccountType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_MifidCategorization` | synapse | DWH_dbo | Dim_MifidCategorization | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md` |
| `DWH_dbo.Dim_ScreeningStatus` | synapse | DWH_dbo | Dim_ScreeningStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ScreeningStatus.md` |
| `DWH_dbo.Dim_PlayerStatusReasons` | synapse | DWH_dbo | Dim_PlayerStatusReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | synapse | DWH_dbo | Dim_PlayerStatusSubReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `BI_DB_dbo.BI_DB_KYC_Panel` | synapse | BI_DB_dbo | BI_DB_KYC_Panel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_KYC_Panel.md` |
| `BI_DB_dbo.BI_DB_PositionPnL` | synapse | BI_DB_dbo | BI_DB_PositionPnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start` | synapse | BI_DB_dbo | BI_DB_Q_AML_FSA_Report_start | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_start.md` |
| `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end` | synapse | BI_DB_dbo | BI_DB_Q_AML_FSA_Report_end | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end.md` |
| `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value` | synapse | BI_DB_dbo | BI_DB_Q_AML_FSA_Report_end_Market_Value | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end_Market_Value.md` |
| `BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions` | synapse | BI_DB_dbo | BI_DB_Q_AML_FSA_Report_end_Positions | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Q_AML_FSA_Report_end_Positions.md` |

