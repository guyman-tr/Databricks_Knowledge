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
- **Object**: `LTV_Conversions_Multipliers_Table`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/LTV_Conversions_Multipliers_Table/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\LTV_Conversions_Multipliers_Table\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\LTV_Conversions_Multipliers_Table\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.LTV_Conversions_Multipliers_Table.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.LTV_Conversions_Multipliers_Table`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.LTV_Conversions_Multipliers_Table.sql`

```sql
CREATE TABLE [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
(
	[Region] [nvarchar](300) NULL,
	[First_Cluster] [nvarchar](300) NULL,
	[Currency] [nvarchar](300) NULL,
	[TotalFullCommission] [money] NULL,
	[RolloverFee] [money] NULL,
	[ConversionFee] [money] NULL,
	[Revenue_LTV_WO_Conversions] [money] NULL,
	[Revenue_LTV_Incl_Conversions] [money] NULL,
	[Revenue_Change_Percentage] [float] NULL,
	[Clients] [int] NULL,
	[Revenue_Change_Percentage_Fixed] [float] NULL,
	[UpdateDate] [date] NOT NULL
)
WITH
(
	DISTRIBUTION = HASH ( [Region] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.Function_Revenue_Total` — synapse
- **Resolved as**: `BI_DB_dbo.Function_Revenue_Total`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Revenue_Total.md`

# Function_Revenue_Total

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 31 (T1: 10, T2: 21) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns collectible revenue at customer-by-date grain aligned with DDR (daily revenue-generating actions), joined to snapshot customer attributes for segmentation. Staking is unioned separately from `Function_Revenue_StakingFee` (with one-month lag vs DDR) and excluded metric rows named `StakingLagOneMonth` from the main fact.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DDR_Fact_Revenue_Generating_Actions | BI_DB_dbo |
| Dim_Revenue_Metrics | BI_DB_dbo |
| Function_Revenue_StakingFee | BI_DB_dbo |
| Dim_Range | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RealCID; Function_Revenue_StakingFee.CID | Direct (UNION) | T1 |
| 2 | DateID | BI_DB_DDR_Fact_Revenue_Generating_Actions.DateID; Function_Revenue_StakingFee.DateID | Direct (UNION) | T1 |
| 3 | Date | BI_DB_DDR_Fact_Revenue_Generating_Actions.DateID; Function_Revenue_StakingFee.DateID | CONVERT(DATE, CONVERT(VARCHAR(8), DateID), 112) | T2 |
| 4 | Metric | BI_DB_DDR_Fact_Revenue_Generating_Actions.Metric | DDR: direct; Staking branch: 'Staking' | T2 |
| 5 | InstrumentTypeID | BI_DB_DDR_Fact_Revenue_Generating_Actions.InstrumentTypeID | DDR: direct; Staking: 10 | T2 |
| 6 | IsSettled | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsSettled | DDR: direct; Staking: 1 | T2 |
| 7 | IsCopy | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsCopy | DDR: direct; Staking: NULL | T2 |
| 8 | CountTransactions | BI_DB_DDR_Fact_Revenue_Generating_Actions.CountTransactions | DDR: direct; Staking: NULL | T2 |
| 9 | IncludedInTotalRevenue | BI_DB_DDR_Fact_Revenue_Generating_Actions.IncludedInTotalRevenue | DDR: direct; Staking: 1 | T2 |
| 10 | CountAsActiveTrade | BI_DB_DDR_Fact_Revenue_Generating_Actions.CountAsActiveTrade | DDR: direct; Staking: 0 | T2 |
| 11 | IsBuy | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsBuy | DDR: direct; Staking: 1 | T2 |
| 12 | IsLeveraged | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsLeveraged | DDR: direct; Staking: 0 | T2 |
| 13 | IsFuture | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsFuture | DDR: direct; Staking: 0 | T2 |
| 14 | IsCopyFund | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsCopyFund | DDR: direct; Staking: 0 | T2 |
| 15 | IsOpenedFromIBAN | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsOpenedFromIBAN | DDR: direct; Staking: NULL | T2 |
| 16 | IsClosedToIBAN | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsClosedToIBAN | DDR: direct; Staking: NULL | T2 |
| 17 | IsRecurring | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsRecurring | DDR: direct; Staking: NULL | T2 |
| 18 | IsAirDrop | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsAirDrop | DDR: direct; Staking: NULL | T2 |
| 19 | IsSQF | BI_DB_DDR_Fact_Revenue_Generating_Actions.IsSQF | DDR: direct; Staking: 0 | T2 |
| 20 | RevenueMetricID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RevenueMetricID | DDR: direct; Staking: 12 | T2 |
| 21 | RevenueMetricCategoryID | BI_DB_DDR_Fact_Revenue_Generating_Actions.RevenueMetricCategoryID | DDR: direct; Staking: 4 | T2 |
| 22 | RevenueMetricCategory | Dim_Revenue_Metrics.RevenueMetricCategory | JOIN on Metric; Staking branch: 'RevShare' | T2 |
| 23 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer; Function_Revenue_StakingFee.IsValidCustomer | Direct (UNION) | T1 |
| 24 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB; Function_Revenue_StakingFee.IsCreditReportValidCB | Direct (UNION) | T1 |
| 25 | CountryID | Fact_SnapshotCustomer.CountryID; Function_Revenue_StakingFee.CountryID | Direct (UNION) | T1 |
| 26 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID; Function_Revenue_StakingFee.PlayerLevelID | Direct (UNION) | T1 |
| 27 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID; Function_Revenue_StakingFee.PlayerStatusID | Direct (UNION) | T1 |
| 28 | RegulationID | Fact_SnapshotCustomer.RegulationID; Function_Revenue_StakingFee.RegulationID | Direct (UNION) | T1 |
| 29 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID; Function_Revenue_StakingFee.AccountTypeID | Direct (UNION) | T1 |
| 30 | AffiliateID | Fact_SnapshotCustomer.AffiliateID; Function_Revenue_StakingFee.AffiliateID | Direct (UNION) | T1 |
| 31 | Amount | BI_DB_DDR_Fact_Revenue_Generating_Actions.Amount; Function_Revenue_StakingFee.TotalUSDDistributed | **DDR branch:** `SUM(ga.Amount)` grouped after `WHERE ga.DateID BETWEEN @sdateInt AND @edateInt` AND `ga.Metric <> 'StakingLagOneMonth'` (staking lag rows excluded from this union part). **Staking branch:** `SUM(frsf.TotalUSDDistributed)` from `Function_Revenue_StakingFee(@sdateInt,@edateInt)` with `@OnlyValidCustomers` filter on `frsf.IsValidCustomer` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-02-12 | Guy M | Added staking |
| 2025-05-06 | Guy M | Added ticket fee by percent (and before that C2F, share lending) |
| 2025-06-23 | Guy M | Added IsSQF and IsFuture |
| 2025-10-17 | Guy M | Replaced calls with DDR revenue table for performance; staking still calls its function (DDR has 1-month lag) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*


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

### Upstream `DWH_dbo.Fact_BillingDeposit` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingDeposit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`

# DWH_dbo.Fact_BillingDeposit

> Central deposit transaction fact table — 73.9M rows recording every eToro deposit attempt with full payment lifecycle state, routing details, exchange metadata, and ~90 XML-extracted payment data attributes. Updated daily from etoro.Billing.Deposit via SP_Fact_BillingDeposit_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Deposit + etoro.Billing.Funding + etoro.Billing.RecurringDeposit (SP join) |
| **Refresh** | Daily (SP_Fact_BillingDeposit_DL_To_Synapse, rolling DELETE + INSERT) |
| | |
| **Synapse Distribution** | HASH (DepositID) |
| **Synapse Index** | CLUSTERED (DepositID ASC) + NC (PaymentStatusID ASC, ExpirationDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_BillingDeposit` is the DWH's authoritative record of every deposit attempt on the eToro platform — approved, declined, pending, charged back, or refunded. With 73.9M rows, it is the primary billing analytics table, used for FTD (First Time Deposit) attribution, payment provider performance, fraud analysis, exchange revenue reporting, regulatory compliance segmentation, and customer lifecycle analytics.

The table combines data from three production sources:
1. **`Billing.Deposit`** — the core deposit ledger (direct passthrough for 35 columns)
2. **`Billing.Funding`** — payment instrument details (FundingTypeID, IsRefundExcluded, DocumentRequired, AFT flags)
3. **`Billing.RecurringDeposit`** — recurring deposit configuration (OUTER APPLY for IsRecurring flag)

Additionally, ~91 columns are extracted from XML blobs stored in `Billing.Deposit.PaymentData` and `Billing.Deposit.FundingData` using the DWH UDF `ExtractXMLValue`. These cover payment-method-specific fields that vary by funding type (credit card BIN details, bank account info, e-wallet data, etc.).

**ETL pattern** (`SP_Fact_BillingDeposit_DL_To_Synapse`):
1. DELETE rows from `Ext_FBD_Fact_BillingDeposit` for the ModificationDateID window
2. INSERT from staging into Ext_FBD (multi-source JOIN + XML extraction)
3. DELETE from main `Fact_BillingDeposit` for the window
4. INSERT from Ext_FBD into Fact_BillingDeposit
5. UPDATE `PlatformID` from `Fact_CustomerAction` WHERE ActionTypeID=14 matching on SessionID (second SP pass: `EXEC SP_Fact_BillingDeposit @Yesterday`)

**Amount capping**: As of 2025-04-17, an `Amount CASE` expression caps extreme values before storage to prevent outlier distortion in aggregations.

**PlatformID enrichment**: The platform the customer used when depositing is not stored in Billing.Deposit — it is looked up via a session-to-platform join against `Fact_CustomerAction` (ActionTypeID=14, session-based match) in a second ETL pass.

**Upstream wiki**: `Billing.Deposit` has a full upstream wiki (documented in DB_Schema) providing Tier 1 column descriptions for 35 DWH columns.

---

## 2. Business Logic

### 2.1 Deposit Status Lifecycle

**What**: Deposits progress through states from submission through approval, decline, or reversal.

**Columns Involved**: `PaymentStatusID`, `RiskManagementStatusID`, `MatchStatusID`

**Rules**:
- `PaymentStatusID=2` (Approved) is the only successful terminal state — drives customer account crediting via Billing.AmountAdd in production
- `PaymentStatusID=35` (DeclineByRRE) represents real-time risk engine declines (~10.2% of deposits)
- `PaymentStatusID=13` (Pending), `5` (InProcess): intermediate states for offline/wire deposits
- States 11-12, 26, 37-39 represent post-approval reversals (Chargeback, Refund, and their reversals)
- For full state machine, see upstream wiki: Billing.Deposit §2.1

### 2.2 First Time Deposit (FTD)

**What**: `IsFTD=1` marks the customer's first ever approved deposit — the event that triggers marketing attribution and FTD bonus eligibility.

**Columns Involved**: `IsFTD`, `CID`, `DepositID`

**Rules**:
- Only one deposit per customer can have `IsFTD=1` (monotonic guarantee from production)
- `IsFTD=0` for DepositTypeID=4 (MoneyTransfer/internal transfer) regardless of deposit history
- ~60.6% of Billing.Deposit rows have IsFTD=1 (many customers deposit exactly once)
- DWH stores this as `int` (0/1) rather than `bit` in production

### 2.3 Amount and Exchange Rate

**What**: Deposits are stored in deposit currency (CurrencyID) and pre-computed to USD (AmountUSD).

**Columns Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `AmountUSD`

**Rules**:
- `Amount` is in deposit currency; stored as MONEY (4 decimal places)
- As of 2025-04-17: Amount is capped via CASE expression before storage (prevents extreme outlier values)
- `AmountUSD = Amount × ExchangeRate` (DWH-computed in ETL)
- `BaseExchangeRate` stores the rate before fee markup; `ExchangeFee` stores the fee
- For USD deposits: ExchangeRate=1.0, AmountUSD=Amount

### 2.4 XML-Extracted Payment Data (~91 Columns)

**What**: `Billing.Deposit.PaymentData` and `FundingData` store provider-specific XML blobs. The DWH ETL extracts ~91 attributes using `ExtractXMLValue(xml_blob, attribute_name)` into dedicated nvarchar(max) columns.

**Rules**:
- Each `*AsString`, `*AsDecimal`, `*AsInteger` suffix column is a single XML attribute extracted by name
- The payment data schema varies by FundingTypeID — credit card deposits populate card-specific fields; bank wire deposits populate bank-specific fields; e-wallet deposits populate e-wallet fields
- NULL in any XML column means either: (a) the attribute doesn't exist for this funding type, or (b) it was absent from the XML for this deposit
- `ThreeDsResponseType` is a notable XML-extracted field — joins to Dim_ThreeDsResponseTypes via TRY_CAST(...AS INT)

### 2.5 Platform Attribution

**What**: `PlatformID` identifies the device/platform the customer was on when making the deposit (web, iOS, Android, etc.).

**Columns Involved**: `PlatformID`, `SessionID`

**Rules**:
- `PlatformID` is NOT from Billing.Deposit — it's populated via a second ETL pass:
  `UPDATE Fact_BillingDeposit SET PlatformID = (SELECT PlatformID FROM Fact_CustomerAction WHERE ActionTypeID=14 AND SessionID = Fact_BillingDeposit.SessionID)`
- If no matching Fact_CustomerAction row exists for the session, PlatformID remains NULL
- ActionTypeID=14 represents a "Deposit" action type in Fact_CustomerAction

### 2.6 Recurring Deposits

**What**: `IsRecurring` identifies deposits that are part of a scheduled recurring deposit plan.

**Columns Involved**: `IsRecurring`, `DepositID`

**Rules**:
- `IsRecurring = 1` when a matching row exists in `Billing.RecurringDeposit` for this deposit (OUTER APPLY)
- `IsRecurring = 0` for one-time deposits
- Recurring deposits may have DepositTypeID=3 (Recurring) or DepositTypeID=5 (RecurringInvestment)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(DepositID)` ensures even distribution — each deposit has a unique ID so this is an optimal hash key for point lookups and JOINs by deposit. The clustered index on `DepositID` makes per-deposit point lookups fast. The NC index on `(PaymentStatusID, ExpirationDateID)` supports filtered queries by status and expiration date.

**Warning**: At 73.9M rows, full-table scans are expensive. Always filter by `ModificationDateID` or `PaymentStatusID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily approved deposit volume | WHERE PaymentStatusID=2, GROUP BY ModificationDateID |
| FTD analysis | WHERE IsFTD=1 AND PaymentStatusID=2 |
| Exchange fee revenue | SUM(AmountUSD - Amount/ExchangeRate×BaseExchangeRate) |
| Regulation-specific deposits | WHERE ProcessRegulationID = @regId |
| Platform breakdown | GROUP BY PlatformID (JOIN Dim_Platform) |
| 3DS outcome analysis | TRY_CAST(ThreeDsResponseType AS INT) JOIN Dim_ThreeDsResponseTypes |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer demographics |
| DWH_dbo.Dim_Date | ON ModificationDateID | Time dimension |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_Platform | ON PlatformID | Device/platform |
| DWH_dbo.Dim_ThreeDsResponseTypes | ON TRY_CAST(ThreeDsResponseType AS INT) | 3DS outcome |

### 3.4 Gotchas

- **73.9M rows**: Always filter. Prefer ModificationDateID or ExpirationDateID index for range queries
- **XML columns are all nvarchar(max)**: Aggregating or joining on XML-extracted columns requires TRY_CAST — they are stored as strings regardless of semantic type
- **`v` column**: This unnamed column (`v`) is an XML-extracted field with no descriptive name — artifact of the XML schema. Contents unknown without domain review
- **PlatformID may be NULL**: Session-to-platform join succeeds only if the deposit session was logged in Fact_CustomerAction
- **AmountUSD is ETL-computed**: Not from production; recalculated as Amount×ExchangeRate at ETL time. For exact USD reconciliation, use Amount×ExchangeRate directly
- **ExpirationDateID formula**: Complex derived calculation from ExpirationDateAsString XML field — not a simple date conversion

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Billing.Deposit) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

**Note**: Elements are grouped by category for readability.

### 4.1 Core Deposit Identifiers & Status (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | int | YES | Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH. (Tier 1 — upstream wiki, Billing.Deposit) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. (Tier 1 — upstream wiki, Billing.Deposit) |
| 3 | PaymentStatusID | int | YES | Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki. NC index key. (Tier 1 — upstream wiki, Billing.Deposit) |
| 4 | IsFTD | int | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production). (Tier 1 — upstream wiki, Billing.Deposit) |
| 5 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — upstream wiki, Billing.Deposit) |
| 6 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 7 | RiskManagementStatusID | int | YES | Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. (Tier 1 — upstream wiki, Billing.Deposit) |
| 8 | MatchStatusID | tinyint | YES | PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.2 Amount & Currency (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations. (Tier 1 — upstream wiki, Billing.Deposit) |
| 10 | CurrencyID | int | YES | Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — upstream wiki, Billing.Deposit) |
| 11 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 12 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 13 | ExchangeFee | int | YES | Exchange fee in provider-specific integer encoding (basis points). Added by Adi (19/02/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 14 | Commission | money | YES | Commission charged on this deposit. Default 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 15 | AmountUSD | decimal(11,2) | YES | Deposit amount converted to USD. DWH-computed: Amount × ExchangeRate. Not from production source — pre-computed in ETL for reporting convenience. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.3 Payment Instrument & Routing (from Billing.Deposit + Billing.Funding — Tier 1 + Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 16 | FundingID | int | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — upstream wiki, Billing.Deposit) |
| 17 | FundingTypeID | int | YES | Type of payment instrument. Sourced from Billing.Funding.FundingTypeID (not from Billing.Deposit directly). Categorizes the deposit by payment method (credit card, wire, ACH, etc.). (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 18 | DepotID | int | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 19 | ProtocolMIDSettingsID | int | YES | Merchant ID configuration profile. Default 0=no specific MID. Added 2018-10-24. (Tier 1 — upstream wiki, Billing.Deposit) |
| 20 | MerchantAccountID | int | YES | Merchant account legal entity for regulatory routing. Added with DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |
| 21 | RoutingReasonID | int | YES | Reason code for routing path selection. Values 1-8; 3=most common (~29%). ~31% NULL for legacy records. Added PAYUS-3061, 2021-06-15. (Tier 1 — upstream wiki, Billing.Deposit) |
| 22 | ProcessRegulationID | int | YES | Regulatory entity/jurisdiction: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=AU (~2.5%), others for ASIC etc. Added DBA-646, 2021-09-05. (Tier 1 — upstream wiki, Billing.Deposit) |
| 23 | FlowID | int | YES | Deposit UX flow variant. NULL=default (98.9%), 1=new flow (0.97%), 3=specific variant. Added PAYIL-8362, 2024-04-18. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.4 Identifiers & Timestamps (from Billing.Deposit — Tier 1 + DWH Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | Approved | bit | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — upstream wiki, Billing.Deposit) |
| 25 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 26 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 27 | ExTransactionID | varchar(50) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — upstream wiki, Billing.Deposit) |
| 28 | RefundVerificationCode | varchar(50) | YES | Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. (Tier 1 — upstream wiki, Billing.Deposit) |
| 29 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 30 | SessionID | bigint | YES | Application session ID. Used for PlatformID enrichment via Fact_CustomerAction JOIN (second ETL pass). (Tier 1 — upstream wiki, Billing.Deposit) |
| 31 | ManagerID | int | YES | Operations manager who processed this deposit. 0=automated. (Tier 1 — upstream wiki, Billing.Deposit) |
| 32 | FunnelID | int | YES | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — upstream wiki, Billing.Deposit) |
| 33 | PaymentGeneration | int | YES | Payment infrastructure generation: 0=Gen0 (7.7%), 1=Gen1 (92%). Added 2020-04-19. (Tier 1 — upstream wiki, Billing.Deposit) |
| 34 | ModificationDateID | int | YES | ETL key. Integer YYYYMMDD derived from ModificationDate (CONVERT(INT, date)). Used for rolling-window DELETE+INSERT. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 35 | ExpirationDateID | int | YES | Integer date ID derived from ExpirationDateAsString XML attribute via a complex formula in SP. Represents card expiration date as YYYYMMDD. NC index key. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 36 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution. Not from production. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.5 Bonus & Campaign (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | BonusStatusID | int | YES | Promotional bonus status. Values: 0=New, 1=Approved, 2=Declined, 3=Reverted. Only 239 non-zero records in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 38 | BonusAmount | money | YES | Bonus amount credited with this deposit. NULL when no bonus applies. (Tier 1 — upstream wiki, Billing.Deposit) |
| 39 | BonusErrorCode | int | YES | Error code when bonus processing fails (BonusStatusID=2). NULL when bonus succeeds or not attempted. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.6 Platform & Recurring (DWH-enriched — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | PlatformID | int | YES | Device/platform the customer used for this deposit. NOT from Billing.Deposit — enriched via second ETL pass: JOIN Fact_CustomerAction ON SessionID WHERE ActionTypeID=14. NULL if no matching session action found. References DWH_dbo.Dim_Platform. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 41 | IsRecurring | int | YES | 1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 42 | IsSetBalanceCompleted | int | YES | 1=account crediting (Billing.AmountAdd) completed for this deposit. Added DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.7 Funding Instrument Metadata (from Billing.Funding — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | IsRefundExcluded | int | YES | Whether this deposit is excluded from refund eligibility. Sourced from Billing.Funding.IsRefundExcluded. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 44 | DocumentRequired | int | YES | Whether documentation was required for this deposit/funding instrument. Sourced from Billing.Funding.DocumentRequired. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 45 | IsAftSupportedAsBool | bit | YES | Whether Account Funding Transaction (AFT) is supported by this funding instrument. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 46 | IsAftEligibleAsBool | bit | YES | Whether this deposit was eligible for AFT processing. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 47 | IsAftProcessedAsBool | bit | YES | Whether this deposit was actually processed via AFT. Sourced from Billing.Funding or Billing.Deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.8 XML-Extracted Payment Data Fields (~91 Columns — Tier 2)

The following columns are all extracted from `Billing.Deposit.PaymentData` or `FundingData` XML blobs using `ExtractXMLValue(xml_blob, 'AttributeName')`. Each column stores the string value of a single XML attribute. All are `nvarchar(max)` unless noted. NULL means the attribute was absent in the XML for this deposit/funding type.

| # | Element | Notes |
|---|---------|-------|
| 48 | SecuredCardDataAsString | Tokenized card data reference |
| 49 | BinCodeAsString | Card BIN (first 6-8 digits) |
| 50 | BinCountryIDAsInteger (int) | Country of card BIN |
| 51 | CardTypeIDAsInteger (int) | Card type ID (Visa, MC, etc.) |
| 52 | CountryIDAsInteger (int) | Customer country from payment data |
| 53 | StateIDAsInteger (int) | Customer state/province from payment data |
| 54 | BankIDAsInteger (int) | Bank identifier integer |
| 55 | AccountNameAsString | Bank account holder name |
| 56 | AccountTypeAsString | Bank account type (checking, savings) |
| 57 | BankAccountAsString | Bank account number (masked) |
| 58 | BankAddressAsString | Bank address |
| 59 | BankCodeAsDecimal | Bank code (numeric string) |
| 60 | BankDetailsAccountIDAsString | Bank details account identifier |
| 61 | BankIDAsString | Bank identifier string |
| 62 | BankNameAsString | Name of the bank |
| 63 | BICCodeAsString | SWIFT/BIC code for wire transfers |
| 64 | CIDAsString | Customer ID as string (XML cross-check) |
| 65 | v | XML-extracted field with no descriptive name (artifact) — contents require domain review |
| 66 | CustomerAddressAsString | Customer's billing address |
| 67 | CustomerNameAsString | Customer name from payment instrument |
| 68 | FundingType | Funding type label from XML |
| 69 | MaskedAccountIDAsString | Masked account/card identifier for display |
| 70 | PurseAsString | E-wallet purse/account ID |
| 71 | RoutingNumberAsString | US ACH routing number |
| 72 | SecureIDAsDecimal | Secure transaction ID (numeric string) |
| 73 | SortCodeAsString | UK bank sort code |
| 74 | AccountBalanceAsDecimal | Account balance from payment provider |
| 75 | AccountHolderAsString | Account holder name |
| 76 | AccountIDAsDecimal | Account identifier (numeric string) |
| 77 | ACHBankAccountIDAsInteger | ACH bank account reference ID |
| 78 | Address1AsString | Billing address line 1 |
| 79 | Address2AsString | Billing address line 2 |
| 80 | AdviseAsString | Payment provider advisory message |
| 81 | AvailableBalanceAsDecimal | Available balance from provider |
| 82 | BankCodeAsString | Bank code (string form) |
| 83 | BillNumberAsString | Bill/invoice number |
| 84 | BuildingNumberAsString | Building number in address |
| 85 | CardHolderPhoneNumberBodyAsString | Cardholder phone number body |
| 86 | CardHolderPhoneNumberPrefixAsString | Cardholder phone number prefix |
| 87 | CardNumberAsString | Card number (masked) |
| 88 | CityAsString | Billing city |
| 89 | CountryIDAsString | Country identifier string |
| 90 | CountryNameAsString | Country name from payment XML |
| 91 | CreatedAtAsString | Payment instrument creation timestamp |
| 92 | CurrentBalanceAsDecimal | Current balance from provider |
| 93 | CustomerIDAsString | Customer ID string from payment data |
| 94 | EmailAsString | Customer email from payment instrument |
| 95 | EndPointIDAsString | Payment provider endpoint identifier |
| 96 | ErrorCodeAsString | Provider error code on decline |
| 97 | ErrorTypeAsString | Provider error type classification |
| 98 | FirstNameAsString | Cardholder/account holder first name |
| 99 | IBANCodeAsString | IBAN for wire/SEPA transfers |
| 100 | InitialTransactionIDAsString | Initial transaction ID for recurring |
| 101 | IPAsString | Customer IP as string |
| 102 | LanguageIDAsInteger | Language ID from payment data |
| 103 | LastNameAsString | Cardholder/account holder last name |
| 104 | MD5AsString | MD5 hash from payment provider |
| 105 | PayerAsString | Payer name (PayPal/e-wallet) |
| 106 | PayerBusiness | Payer business name (PayPal) |
| 107 | PayerIDAsString | Payer identifier string |
| 108 | PayerPurseAsString | Payer purse/wallet ID |
| 109 | PayerStatus | Payer verification status |
| 110 | PaymentAmountAsDecimal | Amount from payment XML |
| 111 | PaymentDateAsDateTime | Payment date from XML |
| 112 | PaymentGuaranteeAsString | Payment guarantee code |
| 113 | PaymentModeAsInteger | Payment processing mode |
| 114 | PaymentProviderTransactionStatusAsString | Status string from provider |
| 115 | PaymentStatusAsInteger | Status integer from provider |
| 116 | PaymentTypeAsString | Payment type label from provider |
| 117 | PlaidItemIDAsString | Plaid (ACH) item identifier |
| 118 | PlaidNamesAsString | Plaid account holder names |
| 119 | PlatformIDAsInteger | Platform from payment XML (separate from PlatformID) |
| 120 | PromotionCodeAsString | Promotion/voucher code used |
| 121 | PSPCodeAsString | Payment service provider code |
| 122 | RapidFirstNameAsString | Rapid (payout) first name |
| 123 | RapidLastNameAsString | Rapid (payout) last name |
| 124 | ResponseMessageAsString | Provider response message |
| 125 | ResponseTimeAsString | Provider response time |
| 126 | SecretKeyAsString | Provider secret key (masked/reference) |
| 127 | ThreeDsAsJson | Raw 3DS authentication data as JSON string |
| 128 | ThreeDsResponseType | 3DS outcome ID as string. Cast to INT to JOIN Dim_ThreeDsResponseTypes. 15 possible values (0-14). |
| 129 | TokenAsString | Payment token from tokenization service |
| 130 | TransactionIDAsString | Provider transaction ID string |
| 131 | ZipCodeAsString | Billing postal/ZIP code |
| 132 | MOPCountry | Method-of-Payment country code |
| 133 | SwiftCodeAsString | SWIFT code for wire transfers |
| 134 | ClientBankNameAsString | Client's bank name |
| 135 | BankName | Bank name (varchar(100), not nvarchar(max)) |
| 136 | CardCategory | Card category label (varchar(50)) |

*All XML-extracted columns: Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse (ExtractXMLValue)*

---

## 5. Lineage

### 5.1 Production Sources

| Source | DWH Columns | Transform |
|--------|-------------|-----------|
| etoro.Billing.Deposit (d) | CID, CurrencyID, Commission, Approved, ModificationDate, FundingID, ExchangeRate, DepositID, ProcessorValueDate, DepotID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount (capped), PaymentDate, IPAddress, ClearingHouseEffectiveDate, IsFTD, RefundVerificationCode, MatchStatusID, BonusStatusID, BonusAmount, BonusErrorCode, ExTransactionID, BaseExchangeRate, ExchangeFee, ProtocolMIDSettingsID, FunnelID, SessionID, PaymentGeneration, ProcessRegulationID, MerchantAccountID, IsSetBalanceCompleted, RoutingReasonID, FlowID | Mostly passthrough; Amount has CASE cap |
| etoro.Billing.Funding (f) | FundingTypeID, IsRefundExcluded, DocumentRequired, IsAftSupportedAsBool, IsAftEligibleAsBool, IsAftProcessedAsBool | JOIN on FundingID |
| etoro.Billing.RecurringDeposit | IsRecurring | OUTER APPLY check |
| ETL-computed | ModificationDateID, ExpirationDateID, AmountUSD, UpdateDate | SP formulas |
| XML (d.PaymentData / d.FundingData) | ~91 XML columns | ExtractXMLValue(xml, 'attr') |
| DWH_dbo.Fact_CustomerAction (2nd pass) | PlatformID | UPDATE via SessionID JOIN, ActionTypeID=14 |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (etoroDB-REAL, 73.9M rows)
  + etoro.Billing.Funding (payment instruments)
  + etoro.Billing.RecurringDeposit (recurring schedule)
  |
  v [Generic Pipeline — daily, 1440 min, Override]
Bronze/etoro/Billing/Deposit/
  |
  v [staging]
DWH_staging.etoro_Billing_Deposit + etoro_Billing_Funding + etoro_Billing_RecurringDeposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — Pass 1]
    1. DELETE Ext_FBD (rolling window by ModificationDateID)
    2. INSERT Ext_FBD from staging (multi-source JOIN + ~91 ExtractXMLValue calls)
    3. DELETE Fact_BillingDeposit (same window)
    4. INSERT Fact_BillingDeposit from Ext_FBD
  |
  v [SP_Fact_BillingDeposit @Yesterday — Pass 2]
    UPDATE PlatformID via Fact_CustomerAction (SessionID JOIN, ActionTypeID=14)
DWH_dbo.Fact_BillingDeposit (73.9M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| RiskManagementStatusID | DWH_dbo.Dim_RiskManagementStatus | Risk engine decision |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension |
| ExpirationDateID | DWH_dbo.Dim_Date | Card expiration date |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| PlatformID | DWH_dbo.Dim_Platform | Device/platform |
| FunnelID | DWH_dbo.Dim_Funnel | Marketing funnel |
| TRY_CAST(ThreeDsResponseType AS INT) | DWH_dbo.Dim_ThreeDsResponseTypes | 3DS authentication outcome |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Cashout_State | DepositID | Linked deposit for refund/chargeback cashouts |
| SP_Fact_BillingDeposit (2nd pass) | SessionID | Platform enrichment pass reads this table |

---

## 7. Sample Queries

### 7.1 Daily approved deposit volume (USD)

```sql
SELECT
    ModificationDateID,
    COUNT(*) AS DepositCount,
    SUM(AmountUSD) AS TotalUSD,
    SUM(CASE WHEN IsFTD=1 THEN 1 ELSE 0 END) AS FTDCount
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE PaymentStatusID = 2
  AND ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-30,GETDATE()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC
```

### 7.2 Decline rate by regulation entity

```sql
SELECT
    ProcessRegulationID,
    COUNT(*) AS TotalDeposits,
    SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN PaymentStatusID = 35 THEN 1 ELSE 0 END) AS DeclinedByRRE,
    CAST(SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS float) / COUNT(*) AS ApprovalRate
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-7,GETDATE()), 112))
GROUP BY ProcessRegulationID
ORDER BY TotalDeposits DESC
```

### 7.3 3DS outc

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_BI_DB_LTV_Conversions_Multipliers_Table] AS 

/********************************************************************************************
=============================================
Authors:     Jan Iablunovskey (Insights Team)
Create Date: 2024-09-24
Title:       Static Table for LTV Model with Conversion Matrix Multipliers
Description: This SP generates a static table for the LTV model, incorporating conversion fees into the revenue used in the model.

The table contains multipliers based on:
- Region (Current)
- First Cluster
- USD/Non-USD (checks the first month’s deposits to determine the most frequent currency).

All revenue is accumulated until 20240930, with FTDs from 2019-2021. 
Small groups (less then 100 clients) and NULLs will receive the value of their respective region.


**************************
** Change History
**************************
Date                 Author                   Description
2025-10-17           Guy M					  this proc is using the total revenew function which became unworkable. changed the underlying from all the functions to reading from the DDR 
											   table, much more efficient - but this changed some of the name conventions, so added case statement to handle. 
----------           -----------              -------------------------------------
----------           -----------              -------------------------------------
*********************************************************************************************/

IF CAST(GETDATE() AS DATE) <= '2024-10-30'--- Making sure that SP will not run daily

BEGIN

BEGIN

/********** Accumulated Revenue **********/

IF OBJECT_ID('tempdb..#Revenue') IS NOT NULL DROP TABLE #Revenue
CREATE TABLE #Revenue
    WITH (HEAP,DISTRIBUTION=hash(CID))
AS
SELECT
	frt.RealCID  AS CID
   , CASE WHEN frt.Metric = 'FullCommission' THEN 'TotalFullCommission' ELSE  frt.Metric END AS Metric
   ,SUM(frt.Amount) AS Amount
FROM BI_DB_dbo.Function_Revenue_Total(20190101,20241027, 1) frt
WHERE frt.Metric IN ('TotalFullCommission','RolloverFee','ConversionFee') 
GROUP BY 
    frt.RealCID  
    ,frt.Metric

/********** Flat Revenue Table **********/

IF OBJECT_ID('tempdb..#Flat_Revenue') IS NOT NULL DROP TABLE #Flat_Revenue
CREATE TABLE #Flat_Revenue
    WITH (HEAP,DISTRIBUTION=hash(CID))
AS
SELECT pr.CID
      ,dc.VerificationLevelID
      ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
	  ,DATEADD(DAY,30,dc.FirstDepositDate) AS First_Month_Date
	  ,dc1.MarketingRegionManualName AS Region
      ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END) AS TotalFullCommission
	  ,SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END) AS RolloverFee
	  ,SUM(CASE WHEN pr.Metric = 'ConversionFee' THEN pr.Amount ELSE 0 END) AS ConversionFee
	  ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END) AS Revenue_LTV_WO_Conversions
	  ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'ConversionFee' THEN pr.Amount ELSE 0 END) AS Revenue_LTV_Incl_Conversions
FROM #Revenue pr
INNER JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON dc.RealCID=pr.CID AND YEAR(dc.FirstDepositDate) IN (2019,2020,2021) AND dc.IsDepositor=1
INNER JOIN DWH_dbo.Dim_Country dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
GROUP BY pr.CID
      ,CAST(dc.FirstDepositDate AS DATE) 
	  ,DATEADD(DAY,30,dc.FirstDepositDate) 
	  ,dc1.MarketingRegionManualName
	  ,dc.VerificationLevelID

   
/********** First Cluster (Seniority 1) **********/

IF OBJECT_ID('tempdb..#First_Cluster') IS NOT NULL DROP TABLE #First_Cluster
CREATE TABLE #First_Cluster
    WITH (HEAP,DISTRIBUTION=hash(CID))
AS
SELECT fr.*
      , CASE
	    WHEN bdcmpfd.ClusterDetail IS NOT NULL THEN bdcmpfd.ClusterDetail
	    WHEN bdcmpfd.FirstAction IS NOT NULL AND
		fr.VerificationLevelID = 3 THEN 'No Cluster - Active'
	    ELSE 'No Cluster - Inactive'
        END AS First_Cluster
FROM #Flat_Revenue fr
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd WITH (NOLOCK)
ON fr.CID = bdcmpfd.CID
AND bdcmpfd.Seniority = 1 

/********** First Month Currency Preference Deposits **********/

IF OBJECT_ID('tempdb..#Currency') IS NOT NULL DROP TABLE #Currency
CREATE TABLE #Currency
WITH (HEAP,DISTRIBUTION=hash(CID))
AS
SELECT c.*
       ,CASE WHEN c.CurrencyID = 1 THEN 'USD' ELSE 'Non_USD' END AS Currency
FROM (
SELECT b.CID
      ,b.CurrencyID
      ,ROW_NUMBER() OVER (PARTITION BY b.CID ORDER BY b.AmountUSD DESC) AS Row_Num
FROM (
SELECT fbd.CID
      ,fbd.CurrencyID
	  ,SUM(fbd.AmountUSD) AS AmountUSD
FROM DWH_dbo.Fact_BillingDeposit fbd WITH (NOLOCK)
INNER JOIN #Flat_Revenue fr ON fbd.CID = fr.CID AND fbd.ModificationDate>=fr.FirstDepositDate AND fbd.ModificationDate<=fr.First_Month_Date 
WHERE fbd.PaymentStatusID=2 
GROUP BY 
       fbd.CID
      ,fbd.CurrencyID ) b)c
WHERE c.Row_Num=1  

/********** Region/Currency Revenue Change Percentage **********/

IF OBJECT_ID('tempdb..#Region') IS NOT NULL DROP TABLE #Region
CREATE TABLE #Region
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  fr.Region
       ,c.Currency
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM #Flat_Revenue fr
LEFT JOIN #Currency c ON c.CID=fr.CID
GROUP BY fr.Region
        ,c.Currency 

/********** Region/Cluster Revenue Change Percentage **********/

IF OBJECT_ID('tempdb..#Region2') IS NOT NULL DROP TABLE #Region2
CREATE TABLE #Region2
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  fr.Region
       ,fc.First_Cluster
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM #Flat_Revenue fr
LEFT JOIN #First_Cluster fc ON fr.CID=fc.CID
GROUP BY fr.Region
       ,fc.First_Cluster

/********** Region Revenue Change Percentage **********/

IF OBJECT_ID('tempdb..#Region3') IS NOT NULL DROP TABLE #Region3
CREATE TABLE #Region3
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT  fr.Region
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM #Flat_Revenue fr
GROUP BY fr.Region

/********** Create a table of all combintaions for Region, Cluster, Curency Type **********/

IF OBJECT_ID('tempdb..#Combinations') IS NOT NULL DROP TABLE #Combinations
CREATE TABLE #Combinations
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
-- Combine regions, clusters, and currencies
SELECT 
    region.Region,
    cluster.First_Cluster, 
    currency.Currency 

FROM 
    -- Get distinct regions and append NULL
    (SELECT DISTINCT r.Region FROM #Region r  UNION ALL SELECT NULL) region

CROSS JOIN 
    -- Get distinct clusters and append NULL
    (SELECT DISTINCT fc.First_Cluster FROM #First_Cluster fc ) cluster

CROSS JOIN
    -- Get distinct currencies and append NULL
    (SELECT DISTINCT c.Currency FROM #Currency c UNION ALL SELECT NULL) currency 

WHERE region.Region IS NOT NULL 

/********* Pre Final **********/

IF OBJECT_ID('tempdb..#PreFinal') IS NOT NULL DROP TABLE #PreFinal
CREATE TABLE #PreFinal
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT fr.Region
      ,fc.First_Cluster
	  ,c.Currency
	  ,SUM(fr.TotalFullCommission) AS TotalFullCommission
	  ,SUM(fr.RolloverFee) AS RolloverFee
	  ,SUM(fr.ConversionFee) AS ConversionFee
	  ,SUM(fr.Revenue_LTV_WO_Conversions) AS Revenue_LTV_WO_Conversions
	  ,SUM(fr.Revenue_LTV_Incl_Conversions) AS Revenue_LTV_Incl_Conversions
	  ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	   ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
	  ,COUNT(*) AS Clients
FROM #Flat_Revenue fr
LEFT JOIN #First_Cluster fc ON fr.CID=fc.CID
LEFT JOIN #Currency c ON c.CID=fr.CID
GROUP BY fr.Region
      ,fc.First_Cluster
	  ,c.Currency 

/********* Final **********/

IF OBJECT_ID('tempdb..#Final1') IS NOT NULL DROP TABLE #Final1
CREATE TABLE #Final1
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT c.*
      ,CASE WHEN c.Revenue_Change_Percentage >0.1 THEN 0.1---Avoid Extreme increase
	        WHEN c.Region='USA' THEN 0 --- No conversion fees in USA
	        WHEN c.Clients <100  THEN r2.Revenue_Change_Percentage --- Fix to small groups 
			WHEN c.First_Cluster IS NOT NULL AND c.Currency IS NULL THEN r1.Revenue_Change_Percentage---NULL logic
			WHEN c.First_Cluster IS NULL AND c.Currency IS NOT NULL THEN r.Revenue_Change_Percentage---NULL logic
			WHEN c.First_Cluster IS NULL AND c.Currency IS NULL THEN r2.Revenue_Change_Percentage---NULL logic
			WHEN c.TotalFullCommission IS NULL THEN r2.Revenue_Change_Percentage---NULL logic
		    ELSE c.Revenue_Change_Percentage 
		    END AS Revenue_Change_Percentage_Fixed
FROM (
SELECT cb.*
      ,pf.TotalFullCommission
	  ,pf.RolloverFee
	  ,pf.ConversionFee
	  ,pf.Revenue_LTV_WO_Conversions
	  ,pf.Revenue_LTV_Incl_Conversions
	  ,pf.Revenue_Change_Percentage
	  ,ISNULL(pf.Clients,0) AS Clients
FROM #Combinations cb
LEFT JOIN #PreFinal pf 
    ON ISNULL(cb.Region, 'N/A') = ISNULL(pf.Region, 'N/A')
   AND ISNULL(cb.First_Cluster, 'N/A') = ISNULL(pf.First_Cluster, 'N/A')
   AND ISNULL(cb.Currency, 'N/A') = ISNULL(pf.Currency, 'N/A')) c
LEFT JOIN #Region r ON r.Region=c.Region AND r.Currency=c.Currency
LEFT JOIN #Region3 r2 ON r2.Region=c.Region
LEFT JOIN #Region2 r1 ON r1.Region=c.Region AND r1.First_Cluster=c.First_Cluster

TRUNCATE TABLE [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
INSERT INTO [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
(
[Region],
[First_Cluster],
[Currency],
[TotalFullCommission],
[RolloverFee],
[ConversionFee],
[Revenue_LTV_WO_Conversions],
[Revenue_LTV_Incl_Conversions],
[Revenue_Change_Percentage],
[Clients],
[Revenue_Change_Percentage_Fixed],
[UpdateDate]
)
SELECT
[Region],
[First_Cluster],
[Currency],
[TotalFullCommission],
[RolloverFee],
[ConversionFee],
[Revenue_LTV_WO_Conversions],
[Revenue_LTV_Incl_Conversions],
[Revenue_Change_Percentage],
[Clients],
[Revenue_Change_Percentage_Fixed],
GETDATE() AS UpdateDate
FROM #Final1 

END 

END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table` | synapse_sp | BI_DB_dbo | SP_BI_DB_LTV_Conversions_Multipliers_Table | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table.sql` |
| `BI_DB_dbo.Function_Revenue_Total` | synapse | BI_DB_dbo | Function_Revenue_Total | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Revenue_Total.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_MonthlyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |

