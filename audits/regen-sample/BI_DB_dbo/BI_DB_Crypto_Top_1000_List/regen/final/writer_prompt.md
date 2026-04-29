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

## ⛔ REGEN-HARNESS BREVITY OVERRIDE

This is a regen-harness run; we are optimising for token efficiency. The judge's
HARD assertions (8 sections present; ETL diagram in 5.2; Element table shape; row
count = DDL column count; Tier suffix on every Element row) all REMAIN MANDATORY.
Soft prose around them is CAPPED — defer to these caps even when the
GOLDEN-REFERENCE example (Dim_Mirror) shows verbose prose.

| Section | Cap |
|---|---|
| 1. Business Meaning | <=120 words. One paragraph. Must include row count, date range, ETL SP, source. |
| 2. Business Logic | <=2 subsections; each <=80 words What/Columns/Rules. Skip section entirely if no non-trivial logic. |
| 3.1 Distribution & Index | <=2 sentences. |
| 3.2 Common Query Patterns | Table only, max 3 rows, no commentary. |
| 3.3 Common JOINs | Table only, max 3 rows, no commentary. |
| 3.4 Gotchas | <=4 bullets, one line each. |
| 4. Elements | Each row Description: ONE sentence ending `(Tier N — source)`. No multi-sentence per-column descriptions. Inline dictionary values when <=15 distinct (per GOLDEN-REFERENCE Section C). |
| 5.2 ETL Pipeline | Diagram + 1 sentence below. No additional prose. |
| 6. Relationships | Tables only, no prose around them. |
| 7. Sample Queries | EXACTLY 2 queries. One sentence header each, no explanation paragraph. |
| 8. Atlassian Knowledge | Bullets only. |

These caps cut output from ~22K tokens to ~10K tokens per object. Keep the
information density HIGH, drop the explanation/narrative prose. The wiki is for
analysts and AI agents who already know the domain — they do not need essay-style
context.

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
- **Object**: `BI_DB_Crypto_Top_1000_List`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_Crypto_Top_1000_List/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Crypto_Top_1000_List\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Crypto_Top_1000_List\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_Crypto_Top_1000_List.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Crypto_Top_1000_List`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Crypto_Top_1000_List.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Crypto_Top_1000_List]
(
	[CID] [int] NULL,
	[GCID] [int] NULL,
	[Region] [nvarchar](50) NULL,
	[AccountManager] [nvarchar](150) NULL,
	[Club] [nvarchar](50) NULL,
	[LastLoggedIn] [date] NULL,
	[LastDepositDate] [date] NULL,
	[LastPosOpenDate] [date] NULL,
	[LastContacted] [date] NULL,
	[LastCryptoPosOpenDate] [date] NULL,
	[Equity] [decimal](19, 4) NULL,
	[ACC_Revenue] [decimal](19, 4) NULL,
	[ACC_Revenue_Crypto] [decimal](19, 4) NULL,
	[Revenue_Crypto_from_20230801] [decimal](19, 4) NULL,
	[Revenue_Crypto_from_20231201] [decimal](19, 4) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CID] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 7 upstream wiki(s). Read EACH one in full.


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

### Upstream `BI_DB_dbo.BI_DB_DailyCommisionReport` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_DailyCommisionReport`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md`

# BI_DB_dbo.BI_DB_DailyCommisionReport

**Schema**: BI_DB_dbo | **Object Type**: Table | **Batch**: 20 | **Generated**: 2026-04-21

## Purpose

Foundational daily commission and trading revenue report at customer × instrument × position-type grain. The primary revenue truth table for BI_DB_dbo: aggregates all commission, rollover, and fee types (9 distinct revenue categories) for every active customer-instrument combination on each reporting date. Grain: RealCID × FullDate × InstrumentID × IsSettled × IsMirror × IsBuy × IsLeverage × IsLeverageMoreThen20 × IsAirDrop × SettlementTypeID × IsMarginTrade.

Revenue metrics are sourced from a suite of foundation-layer TVFs (`Function_Revenue_FullCommissions`, `Function_Revenue_Commissions`, `Function_Revenue_RolloverFee`, etc.), abstracting the raw Fact_CustomerAction logic. Customer dimensions are sourced from `BI_DB_Client_Balance_CID_Level_New` (point-in-time as of @DateID).

This table is the upstream dependency for: `BI_DB_DailyCommisionReport_Instrument_Agg`, `BI_DB_DailyCommisionReport_Last2weeks`, `BI_DB_DailyCommisionReport_ThisMonth`, `BI_DB_DailyCommisionReport_LastYear`, `BI_DB_DailyCommisionReport_Yesterday`, and downstream objects including user-segment and equity snapshots.

## Properties

| Property | Value |
|----------|-------|
| Full Name | BI_DB_dbo.BI_DB_DailyCommisionReport |
| Writer SP | SP_DailyCommisionReport |
| Refresh Pattern | DELETE WHERE DateID=@DateID + INSERT (incremental by date, @Date parameter) |
| Row Count | ~179K rows per date (2026-04-12 sample: 179,538); count(*)>2B total, overflows INT |
| Date Range | 2018-01-01 to 2026-04-12 (3,024 distinct dates) |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (DateID ASC, RealCID ASC) |
| UC Target | _Not_Migrated |
| SP Author | Multiple (original author unknown; Guy M 2023, 2024-07, 2025-07 overhaul, 2026-01) |

## Elements

### Customer / Population Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 1 | RealCID | Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID. Hash distribution key in temp tables. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 2 | UserName | Customer username from Dim_Customer.UserName as of @DateID. | DWH_dbo.Dim_Customer | Tier 2 — SP_DailyCommisionReport |
| 7 | CountryID | Integer country key from Fact_SnapshotCustomer.CountryID as of @DateID. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 8 | Country | Full country name — sourced from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name). | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 9 | Region | Marketing region label — Dim_Country.MarketingRegionManualName via direct JOIN on Fact_SnapshotCustomer.CountryID. NOT geographic region — uses eToro marketing territory classification. | DWH_dbo.Dim_Country | Tier 2 — SP_DailyCommisionReport |
| 10 | Manager | Account manager full name — Dim_Manager.FirstName + ' ' + LastName via Fact_SnapshotCustomer.AccountManagerID. | DWH_dbo.Dim_Manager | Tier 2 — SP_DailyCommisionReport |
| 11 | Club | Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.Club. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 20 | FirstDepositDate | Customer's very first deposit date from Dim_Customer. Used for cohort (FTD Year) analysis in the Instrument_Agg satellite. | DWH_dbo.Dim_Customer | Tier 2 — SP_DailyCommisionReport |
| 21 | Regulation | Regulatory jurisdiction label as of @DateID — from BI_DB_Client_Balance_CID_Level_New.ToRegulation (e.g., FCA, CySEC, FSA Seychelles). | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 22 | Mifid | MiFID categorization label as of @DateID — from BI_DB_Client_Balance_CID_Level_New.MifidCategory. Values: Retail, Professional, Retail Pending, etc. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 29 | RegulationID | Integer regulation key from Fact_SnapshotCustomer.RegulationID as of @DateID. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 30 | PlayerLevelID | Integer player level key (1=Silver, 2=Gold, 3=Platinum, 4=Demo, etc.) from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 31 | MifidCategorizationID | Integer MiFID categorization key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 32 | IsValidCustomer | 1 if customer meets eToro's valid customer criteria (non-demo, depositor, active) as of @DateID. From Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 33 | IsCreditReportValidCB | Credit report validity flag for US credit bureau reporting. From Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 34 | Label | Customer segment label as of @DateID (e.g., 'Proprietary', internal classification). From BI_DB_Client_Balance_CID_Level_New.Label. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 35 | PlayerStatusID | Integer player status key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 36 | PlayerStatus | Player status name (Normal, Blocked, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.PlayerStatus. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 37 | AccountStatusID | Integer account status key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 38 | AccountStatusName | Account status name from Dim_AccountStatus via LEFT JOIN. | DWH_dbo.Dim_AccountStatus | Tier 2 — SP_DailyCommisionReport |
| 39 | AccountTypeID | Integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.) from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 40 | AccountType | Account type name as of @DateID. From BI_DB_Client_Balance_CID_Level_New.AccountType. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 44 | IsEtoroTradingCID | Flag for internal eToro trading/housekeeping accounts. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 45 | IsGlenEagleAccount | Flag for Glen Eagle Securities subsidiary accounts. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 46 | eToroTradingGroupUser | eToro trading group identifier string. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 50 | US_State | US state/province short name for US-regulated customers — Dim_State_and_Province.ShortName via LEFT JOIN (RegionByIP_ID, CountryID=219). NULL for non-US customers. | DWH_dbo.Dim_State_and_Province | Tier 2 — SP_DailyCommisionReport |
| 70 | IsDLTUser | Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added 2024-07-30. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |

### Date / Identifier Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 12 | FullDate | Reporting date — the @Date SP input parameter. Matches the DELETE key for idempotent reload. | @Date parameter | Tier 2 — SP_DailyCommisionReport |
| 13 | DateID | YYYYMMDD integer — CAST(CONVERT(CHAR(8),@Date,112) AS INT). Clustering key for date-range scans. | @Date parameter | Tier 2 — SP_DailyCommisionReport |
| 18 | UpdateDate | GETDATE() at ETL execution time. | — | Tier 2 — SP_DailyCommisionReport |

### Instrument / Position Dimension Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 3 | InstrumentID | Instrument integer key from Dim_Instrument, propagated through revenue TVFs. | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 4 | Instrument | Instrument name from Dim_Instrument.Name (e.g., EUR/USD, AAPL, BTC/USD). | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 5 | InstrumentTypeID | Instrument type integer key (1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto Currencies, etc.). | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 6 | InstrumentType | Instrument type label from Dim_Instrument.InstrumentType. | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 23 | IsSettled | 1=real/settled position (customer owns underlying asset), 0=CFD. From Fact_CustomerAction/Dim_Position. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 24 | IsMirror | 1=copy-trading position (MirrorID>0), 0=manual trade. CASE WHEN MirrorID>0 THEN 1 ELSE 0. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 63 | IsBuy | 1=long (buy) position, 0=short (sell) position. From Dim_Position.IsBuy. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 64 | IsLeverage | 1 if position Leverage > 1, else 0. From Dim_Position.Leverage. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 65 | IsLeverageMoreThen20 | 1 if position Leverage > 20, else 0. High-leverage flag with regulatory significance (ESMA/MiFID leverage limits). | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 66 | IsAirDrop | 1 for positions created via crypto airdrop distributions. From Dim_Position.IsAirDrop. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 67 | SettlementTypeID | Position settlement type: CASE WHEN SettlementTypeID IS NULL THEN IsSettled ELSE SettlementTypeID END. Key values: 0=CFD, 1=Real, 5=Margin trade. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 77 | IsMarginTrade | 1 if SettlementTypeID=5 (margin-funded position) in Fact_CustomerAction. Added 2025-10-23. | DWH_dbo.Fact_CustomerAction | Tier 2 — SP_DailyCommisionReport |

### Commission Metric Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 14 | Commissions | Net commission — SUM(TotalCommission) from Function_Revenue_Commissions. Commission on opens (ActionTypeID IN 1,2,3,39) + CommissionOnClose adjustment on closes (ActionTypeID IN 4,5,6,28,40). The "net to eToro" commission figure. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 15 | FullCommissions | Gross full commission — SUM(TotalFullCommission) from Function_Revenue_FullCommissions. Used for MIFID regulatory revenue reporting. Includes the full spread-embedded commission without adjustments. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 25 | CommissionOnOpen | Commission on position opens (ActionTypeID IN 1,2,3,39). Component of Commissions. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 26 | CommissionOnCloseAdjustment | Commission close adjustment — SUM(CommissionOnClose - CommissionByUnits) for close actions. Net of unit-based component on close. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 27 | FullCommissionOnOpen | Gross full commission for open actions. Component of FullCommissions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 28 | FullCommissionOnCloseAdjustment | Gross full commission adjustment on close — SUM(FullCommissionOnClose - FullCommissionByUnits) for close actions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 51 | CommissionOnClose | Raw commission on closed positions (ActionTypeID IN 4,5,6,28,40) before unit adjustment. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 56 | UnrealizedCommissionChange | Daily change in unrealized spread commission embedded in open positions: new positions opened on @DateID gain unrealized commission; positions closed on @DateID release it. Computed as (CommissionOnOpen for new opens) minus (CommissionByUnitsAtClose for closes on positions opened prior to @DateID). | DWH_dbo.Fact_CustomerAction + Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 57 | FullCommissionOnClose | Gross full commission on closed positions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 61 | RealizedFullCommission | Gross realized full commission — SUM(FullCommissionOnClose) for positions closed on @DateID. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 52 | CommissionByUnitsAtClose | **Always NULL** — set to NULL in INSERT since 2025-07-16 overhaul. Legacy column. | — | Tier 4 — Legacy/Deprecated |
| 53 | UnrealizedCommissionNew | **Always NULL** — legacy unrealized commission decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 54 | UnrealizedCommissionOldClosing | **Always NULL** — legacy unrealized commission decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 55 | RealizedCommission | **Always NULL** — computed in intermediate temp table but explicitly set to NULL in the INSERT since 2025-07-16. Do not use. | — | Tier 4 — Legacy/Deprecated |
| 58 | FullCommissionByUnitsAtClose | **Always NULL** — legacy gross commission by units at close, not populated. | — | Tier 4 — Legacy/Deprecated |
| 59 | UnrealizedFullCommissionNew | **Always NULL** — legacy gross unrealized decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 60 | UnrealizedFullCommissionOldClosing | **Always NULL** — legacy gross unrealized decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 62 | UnealizedFullCommissionChange | **Always NULL** — legacy gross unrealized change, not populated. **"Un*e*alized" is a persisted DDL typo** (missing 'r'); actual column name in the database contains the misspelling. | — | Tier 4 — Legacy/Deprecated |

### Fee / Volume Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 16 | VolumeOnOpen | USD trading volume for positions opened on @DateID — SUM(VolumeOpen) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 17 | VolumeOnClose | USD trading volume for positions closed on @DateID — SUM(VolumeClose) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 19 | RollOverFee | Daily overnight rollover/carry fee — SUM(RolloverFee) from Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight. | BI_DB_dbo.Function_Revenue_RolloverFee | Tier 2 — SP_DailyCommisionReport |
| 68 | RollOverFee_SDRT | UK Stamp Duty Reserve Tax — SUM(SDRT) from Function_Revenue_SDRT. Applies to UK equity transactions. Added 2023-10-31. | BI_DB_dbo.Function_Revenue_SDRT | Tier 2 — SP_DailyCommisionReport |
| 69 | TradingFees | Composite trading fee total — ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0). Added 2024-02-25 as "Ticket Fee + Islamic Fee" summary. | Multiple Function_Revenue_* | Tier 2 — SP_DailyCommisionReport |
| 71 | TicketFee | Per-ticket transaction fee — SUM(TicketFee) from Function_Revenue_TicketFee. Fixed fee per trade. | BI_DB_dbo.Function_Revenue_TicketFee | Tier 2 — SP_DailyCommisionReport |
| 72 | TicketFeeByPercent | Percentage-based ticket fee — SUM(TicketFeeByPercent) from Function_Revenue_TicketFeeByPercent. Alternative percentage fee structure. | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Tier 2 — SP_DailyCommisionReport |
| 73 | AdminFee | Islamic finance / administration fee — SUM(AdminFee) from Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover. | BI_DB_dbo.Function_Revenue_AdminFee | Tier 2 — SP_DailyCommisionReport |
| 74 | SpotAdjustFee | Spot price adjustment fee — SUM(SpotAdjustFee) from Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing. | BI_DB_dbo.Function_Revenue_SpotAdjustFee | Tier 2 — SP_DailyCommisionReport |
| 75 | InvestedAmountOpen | USD invested amount for positions opened on @DateID — SUM(InvestedAmountOpen) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 76 | CountUU | Count of unique customers in this grain combination — COUNT(DISTINCT CID) from Function_Trading_Volume. Typically 1 per row (grain includes RealCID), but may be >1 in aggregated contexts. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |

### Legacy / Deprecated Columns (Always NULL)

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 41 | IsOutlier | **Always NULL** — not populated since 2025-07-16 SP overhaul. Was previously used to flag statistical outlier customers. | — | Tier 4 — Legacy/Deprecated |
| 42 | Transition | **Always NULL** — legacy column for regulation transition tracking. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 43 | IsGermanBaFIN | **Always NULL** — legacy flag for German BaFin-regulated customers. Not populated (replaced by Regulation column logic). | — | Tier 4 — Legacy/Deprecated |
| 47 | RegulationIDPrev | **Always NULL** — legacy tracking for previous regulation ID before a regulation change. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 48 | RegulationPrev | **Always NULL** — legacy previous regulation name. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 49 | IsCreditReportValidCBPrev | **Always NULL** — legacy previous credit report validity. Not populated. | — | Tier 4 — Legacy/Deprecated |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (@DateID)
  + DWH_dbo.Fact_SnapshotCustomer (via Dim_Range DateRangeID)
  + DWH_dbo.Dim_Manager, Dim_Customer, Dim_Country, Dim_AccountStatus, Dim_State_and_Province
  → #pop (customer universe as of @DateID — hash distributed by RealCID)

Revenue TVFs → individual revenue temp tables → FULL OUTER JOIN → #allMetrics:
  Function_Revenue_FullCommissions  → #FullComm
  Function_Revenue_Commissions      → #Comm
  Function_Revenue_RolloverFee      → #Rollovers
  Function_Revenue_TicketFee        → #TicketFee
  Function_Revenue_TicketFeeByPercent → #TicketFeeByPercent
  Function_Revenue_AdminFee         → #AdminFee
  Function_Revenue_SpotAdjustFee    → #SpotAdjustFee
  Function_Revenue_SDRT             → #sdrt
  Function_Trading_Volume           → #volumes
  Fact_CustomerAction + Dim_Position → #addUnrealizedChange → #unrealizedCommChange

#pop LEFT JOIN #allMetrics → #final (filtered: WHERE NOT all metrics IS NULL)

  |-- SP_DailyCommisionReport @Date
  |     DELETE FROM BI_DB_DailyCommisionReport WHERE DateID=@DateID
  |     INSERT INTO BI_DB_DailyCommisionReport FROM #final
  |     DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID=@DateID
  |     INSERT INTO BI_DB_DailyCommisionReport_Instrument_Agg (instrument-grouped aggregation)
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (2018-01-01 – 2026-04-12 | 3,024 dates | ~179K rows/date | COUNT(*)>2B | CLUSTERED INDEX DateID,RealCID | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|

Downstream satellite tables (read from this table):
  BI_DB_DailyCommisionReport_Last2weeks
  BI_DB_DailyCommisionReport_ThisMonth
  BI_DB_DailyCommisionReport_MonthlyData
  BI_DB_DailyCommisionReport_LastYear
  BI_DB_DailyCommisionReport_ThisYear
  BI_DB_DailyCommisionReport_Yesterday
```

## Gotchas

**14 always-NULL legacy columns**: Columns 41-43 (IsOutlier, Transition, IsGermanBaFIN), 47-49 (RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev), and 52-55 / 58-60 / 62 (various unrealized commission decompositions) are ALWAYS NULL in current inserts. The SP explicitly sets them to NULL since the 2025-07-16 overhaul. Do not rely on these for analysis.

**"Un*e*alized" DDL typo**: Column 62 `UnealizedFullCommissionChange` contains a persisted misspelling (missing 'r' in 'Unrealized'). This is the actual column name in the DDL. It is also always NULL. Reference it as `[UnealizedFullCommissionChange]` in queries (though since it's always NULL, this rarely matters).

**Commissions vs FullCommissions**: These are two distinct revenue measures. `Commissions` is the net eToro-earned commission. `FullCommissions` is the gross commission (including the portion that may flow to other parties under MIFID/regulatory reporting). For P&L analysis use `Commissions`; for regulatory reporting use `FullCommissions`.

**COUNT(*) overflows INT**: The table has more than 2 billion rows total (spans 2018–2026, ~179K rows/day). `SELECT COUNT(*) FROM BI_DB_DailyCommisionReport` returns an arithmetic overflow error. Use `COUNT_BIG(*)` or `CAST(COUNT(*) AS BIGINT)` to avoid. For date-filtered queries this is not an issue.

**Row count filter**: The #final step filters out rows where ALL metric columns are NULL (`WHERE NOT (FullCommissions IS NULL AND Commissions IS NULL AND ... CountUU IS NULL)`). This means only customers with actual activity on @DateID (via any of the 9 revenue TVFs) appear. The population (#pop) may be larger than the final insert.

**Same-SP dual-write**: SP_DailyCommisionReport writes both BI_DB_DailyCommisionReport AND BI_DB_DailyCommisionReport_Instrument_Agg in a single execution. These two tables are always in sync for the same @DateID.

**Foundation TVF dependency**: All revenue metrics depend on the foundation TVFs (`Function_Revenue_FullCommissions`, etc.) being up to date. If these functions contain bugs or are modified, all downstream DDR metrics are affected simultaneously. The 2025-07-16 overhaul aligned this table to "foundation functions" — prior SP versions used direct Fact_CustomerAction queries.

**IsDLTUser flag (2024-07-30)**: DLT (Distributed Ledger Technology) users have different regulatory treatment for real crypto positions. Historical rows before 2024-07-30 will have NULL for IsDLTUser.

**IsMarginTrade flag (2025-10-23)**: Rows before 2025-10-23 will have NULL for IsMarginTrade.

## Sample Queries

```sql
-- Daily revenue by instrument type for a specific date
SELECT
    FullDate,
    InstrumentType,
    SUM(Commissions)       AS Net_Commissions,
    SUM(FullCommissions)   AS Gross_FullCommissions,
    SUM(RollOverFee)       AS Rollover_Revenue,
    SUM(TradingFees)       AS Trading_Fees,
    SUM(RollOverFee_SDRT)  AS SDRT,
    SUM(VolumeOnOpen)      AS Volume_Opened
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID = 20260412
GROUP BY FullDate, InstrumentType
ORDER BY Gross_FullCommissions DESC;
```

```sql
-- Customer revenue by regulation — prior 30 days (use DateID range for performance)
SELECT
    Regulation,
    Club,
    SUM(Commissions)     AS Net_Commissions,
    SUM(FullCommissions) AS Gross_FullCommissions,
    SUM(RollOverFee)     AS Rollover,
    SUM(AdminFee)        AS Islamic_Fee
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID BETWEEN 20260313 AND 20260412
  AND IsValidCustomer = 1
GROUP BY Regulation, Club
ORDER BY Gross_FullCommissions DESC;
```

```sql
-- Crypto real vs CFD commission breakdown
SELECT
    FullDate,
    CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD' END AS Position_Type,
    CASE WHEN IsMirror = 1 THEN 'Copy' ELSE 'Manual' END AS Trade_Origin,
    SUM(FullCommissions)         AS FullCommissions,
    SUM(UnrealizedCommissionChange) AS UnrealizedChange,
    SUM(RollOverFee)             AS Rollover
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID = 20260412
  AND InstrumentTypeID = 10  -- Crypto
GROUP BY FullDate, IsSettled, IsMirror
ORDER BY FullCommissions DESC;
```

## Related Objects

| Object | Relationship |
|--------|-------------|
| SP_DailyCommisionReport | Writer stored procedure |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg | Instrument-aggregated satellite; written by same SP execution |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks | Rolling 2-week window subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth | Current-month subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData | Monthly aggregation |
| BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear | Prior-year subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday | Yesterday-only snapshot |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Population source (customer dimensions) |
| BI_DB_dbo.Function_Revenue_FullCommissions | Foundation TVF for FullCommissions |
| BI_DB_dbo.Function_Revenue_Commissions | Foundation TVF for Commissions |
| BI_DB_dbo.Function_Revenue_RolloverFee | Foundation TVF for RollOverFee |
| BI_DB_dbo.Function_Revenue_SDRT | Foundation TVF for SDRT (UK stamp duty) |
| BI_DB_dbo.Function_Trading_Volume | Foundation TVF for VolumeOnOpen/Close, InvestedAmountOpen, CountUU |
| DWH_dbo.Fact_CustomerAction | Raw action source for commission TVFs and UnrealizedCommissionChange |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot source for population dimensions |


### Upstream `BI_DB_dbo.BI_DB_UsageTracking_SF` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_UsageTracking_SF`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_UsageTracking_SF.md`

# BI_DB_dbo.BI_DB_UsageTracking_SF

> Salesforce CRM account activity log — records every account-level action taken by customer service and account management reps, enabling tracking of rep-to-customer contact history and funnel activity analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — event log) |
| **Production Source** | Salesforce CRM → DLT-CRM pipeline → ADLS Gold/CRM/UsageTracking/*.parquet |
| **Refresh** | Full refresh — TRUNCATE + INSERT (SP_UsageTracking_SF, no date param) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CreatedDate_SF ASC, CID ASC) |
| **Synapse NCI** | NCL_IX_BI_DBUsageTrackingSF_CID_ActionName (CID, ActionName) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_UsageTracking_SF` captures every account-level activity event from the Salesforce CRM system. Each row represents an action taken on a customer account — such as a call, email, case update, or ownership change — along with who performed the action and when.

This table is one of the most widely consumed tables in the BI_DB schema, referenced by 17+ SPs across account management, reporting, and compliance workflows. Key use cases:
- **Contact tracking**: Which rep last contacted a customer, and when
- **Funnel analysis**: Tracking customer engagement through conversion stages
- **High-value customer management**: Identifying recent rep activity on high-balance customers before cashout approvals
- **CID first dates**: Determining the first date of various activities per customer

Data originates from Salesforce, flows through the DLT-CRM pipeline to ADLS Gold layer, and is loaded via COPY INTO. Originally populated via SSIS (migrated 2024-04-03 by Katy F).

---

## 2. Business Logic

### 2.1 Deduplication

**What**: Source data is deduplicated during load.

**Rules**:
- GROUP BY all columns except CreatedDate and UpdateDate
- `CreatedDate` = MIN(CreatedDate) from the group — takes the earliest creation timestamp per unique event

### 2.2 Manager Resolution

**What**: Manager context for the rep who performed the action.

**Columns Involved**: `ManagerID`, `CreatedByManagerID`

**Rules**:
- `CreatedByManagerID` = `ManagerID` — they are the same value (duplicated in the INSERT)
- Represents the internal manager ID of the rep who created/performed the action

### 2.3 Full Refresh

**What**: The entire table is rebuilt each load.

**Rules**:
- TRUNCATE TABLE before INSERT — no incremental logic
- Complete historical CRM activity is reloaded from ADLS Gold parquet files each run

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: No distribution key — the table is accessed in diverse patterns.

**CLUSTERED INDEX (CreatedDate_SF ASC, CID ASC)**: Efficient for date-range + customer queries.

**NCI (CID, ActionName)**: Covers the common pattern of filtering by customer + specific action type.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer details |
| BI_DB_dbo.BI_DB_CID_DailyPanel | ON CID | Daily panel enrichment |

### 3.3 Gotchas

- **Full TRUNCATE refresh**: There is no date filter — the entire table is rebuilt every load. Query timing matters for data freshness.
- **ActionName truncation**: Source ActionName is varchar(200) but target is varchar(50). Long action names may be truncated.
- **Salesforce IDs are 18-char nvarchar**: AccountHistoryID, AccountID, CreatedByID, OwnerID are Salesforce record IDs — always 18 characters.
- **CreatedByManagerID = ManagerID**: These are always the same value. The duplication appears intentional for consumer SP compatibility.
- **No ID column in INSERT**: The `ID` column appears to be auto-generated (likely IDENTITY) — not populated by the SP.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_UsageTracking_SF) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NULL | Auto-generated surrogate key. Not populated by the writer SP — likely IDENTITY column. (Tier 4 — [UNVERIFIED]) |
| 2 | AccountHistoryID | nvarchar(18) | NULL | Salesforce Account History record ID (18-char SF ID). Unique per history event. (Tier 2 — SP_UsageTracking_SF) |
| 3 | AccountID | nvarchar(18) | NULL | Salesforce Account record ID. Links to the customer's SF Account object. (Tier 2 — SP_UsageTracking_SF) |
| 4 | ActionName | varchar(50) | NULL | Type of CRM action performed (e.g., call, email, case update, ownership change). Truncated from 200-char source. (Tier 2 — SP_UsageTracking_SF) |
| 5 | CreatedByID | nvarchar(18) | NULL | Salesforce User ID of the rep who performed the action. (Tier 2 — SP_UsageTracking_SF) |
| 6 | CreatedDate_SF | datetime | NULL | Timestamp when the action was recorded in Salesforce. Clustered index key. (Tier 2 — SP_UsageTracking_SF) |
| 7 | OwnerID | nvarchar(18) | NULL | Salesforce User ID of the account owner at the time of the action. (Tier 2 — SP_UsageTracking_SF) |
| 8 | ManagerID | int | NULL | Internal manager ID of the rep who performed the action. Maps to internal HR/management hierarchy. (Tier 4 — [UNVERIFIED]) |
| 9 | CID | int | NULL | Customer ID mapped from the Salesforce Account. FK to Dim_Customer. (Tier 2 — SP_UsageTracking_SF) |
| 10 | CreatedDate | datetime | NULL | Earliest creation timestamp for this event group (MIN after dedup). May differ from CreatedDate_SF. (Tier 2 — SP_UsageTracking_SF) |
| 11 | CreatedByManagerID | int | NULL | Duplicate of ManagerID — the internal manager of the rep who performed the action. Always equals ManagerID. (Tier 2 — SP_UsageTracking_SF) |
| 12 | UpdateDate | datetime | NULL | ETL load timestamp — GETDATE(). (Tier 2 — SP_UsageTracking_SF) |

---

## 5. Lineage

### 5.1 Pipeline

```
Salesforce CRM (Account History)
  → DLT-CRM pipeline (Azure)
    → ADLS Gold: dldataplatformprodwe.dfs.core.windows.net/internal-sources/Gold/CRM/UsageTracking/*.parquet
      │
      └─ SP_UsageTracking_SF
          ├─ COPY INTO #UsageTracking (from ADLS parquet)
          ├─ TRUNCATE TABLE BI_DB_UsageTracking_SF
          └─ INSERT (GROUP BY dedup + MIN(CreatedDate) + GETDATE())
```

### 5.2 Key Source Tables

| Source | Columns Used |
|--------|-------------|
| Gold/CRM/UsageTracking (parquet) | AccountHistoryID, AccountID, ActionName, CreatedByID, CreatedDate_SF, OwnerID, CID, ManagerID, CreatedDate |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | CID | Customer details |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_CIDFirstDates | CID, CreatedDate_SF | First activity dates per customer |
| SP_AM_Contacted | CID, ActionName | Account manager contact tracking |
| SP_AM_Portfolio_Summary | CID | Portfolio summary with SF activity |
| SP_CID_DailyPanel_Club | CID | Daily panel enrichment |
| SP_CIDFunnelFlow | CID, ActionName | Funnel flow analysis |
| SP_NewContactActivityPerRep | CreatedByID, ActionName | Per-rep activity reporting |
| SP_InvestorReportDetails | CID | Investor report enrichment |
| (+ 10 more consumer SPs) | various | Reporting, compliance, management dashboards |

---

## 7. Sample Queries

### 7.1 Recent activity per customer

```sql
SELECT  CID, ActionName, CreatedDate_SF, CreatedByID
FROM    [BI_DB_dbo].[BI_DB_UsageTracking_SF]
WHERE   CID = 12345678
ORDER BY CreatedDate_SF DESC;
```

### 7.2 Activity volume by action type

```sql
SELECT  ActionName,
        COUNT(*) AS ActionCount,
        COUNT(DISTINCT CID) AS UniqueCustomers,
        MIN(CreatedDate_SF) AS FirstSeen,
        MAX(CreatedDate_SF) AS LastSeen
FROM    [BI_DB_dbo].[BI_DB_UsageTracking_SF]
WHERE   CreatedDate_SF >= '2026-01-01'
GROUP BY ActionName
ORDER BY ActionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Salesforce](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/13482328083) | Confluence | Salesforce is eToro's CRM — used for communication with clients and collaboration |
| [Big Data Platform migration](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/1942847659) | Confluence | Documents BI_DB InterestDaily and other external source assignments |

---

*Generated: 2026-03-22 | Quality: 7.5/10 (★★★☆☆) | Phases: 12/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 10 T2, 0 T3, 2 T4 [UNVERIFIED] (ID auto-gen, ManagerID source), 0 T5 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_UsageTracking_SF | Type: Table | Source: Salesforce CRM → DLT-CRM → ADLS Gold/CRM/UsageTracking*


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

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Crypto_Top_1000_List`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Crypto_Top_1000_List.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Crypto_Top_1000_List] @Date [DATE] AS

BEGIN;

/**************************************Start Main Comment History******************************************************
=============================================
Authors:     Jan Iablunovskey
Create Date: 2023-11-08
Description: Populate the top 1000 Crypto clients that has less then 100$ revenue since 20230801. 
             This data will be used by AMs to bring those clients back.
=============================================

**************************
** Change History
**************************
Date                 Author                   Description
2023-11-13     |       Jan           |         New column Added [Revenue_Crypto_from_20231201]
2023-11-23     |        Jan          |           1,000 list update due to caclulation change
----------           -----------              -------------------------------------
****************************************End Main Comment History****************************************************/

/********** Step 01 **********/
/********** Declare variables **********/
--DECLARE @Date DATE = '20231125'
DECLARE @after_date AS DATE = '20230801'
DECLARE @after_date_INT INT = CAST(CONVERT(VARCHAR(8), @after_date, 112) AS INT)
DECLARE @after_date_end AS DATE = '20231115'
DECLARE @after_date_INT_end INT = CAST(CONVERT(VARCHAR(8), @after_date_end, 112) AS INT)
DECLARE @campaign_start AS DATE = '20231201'
DECLARE @campaign_start_INT INT = CAST(CONVERT(VARCHAR(8), @campaign_start, 112) AS INT)
DECLARE @BeginOfMonth AS DATE = DATEADD(Month,DATEDIFF(Month,0,@Date),0)

/********** Step 02 **********/
/********** Relevant population **********/

---Used for the 1,000 clients list

--SELECT TOP 1000   bddcr.RealCID AS CID
--		,SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Revenue_Crypto
--		,SUM(CASE WHEN InstrumentTypeID = 10 AND bddcr.DateID>=@after_date_INT AND bddcr.DateID<=@after_date_INT_end THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Revenue_Crypto_from_20230801
--FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr
--INNER JOIN DWH_dbo.Dim_Customer dc ON bddcr.RealCID = dc.RealCID AND bddcr.IsValidCustomer=1
--GROUP BY bddcr.RealCID
--HAVING SUM(CASE WHEN InstrumentTypeID = 10 AND bddcr.DateID>=@after_date_INT AND bddcr.DateID<=@after_date_INT_end THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)<1000 AND 
--SUM(CASE WHEN InstrumentTypeID = 10 AND bddcr.DateID>=@after_date_INT AND bddcr.DateID<=@after_date_INT_end THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)>0
--ORDER BY SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) DESC

IF OBJECT_ID('tempdb..#List') IS NOT NULL DROP TABLE #List
CREATE TABLE #List
WITH (DISTRIBUTION = HASH(RealCID),CLUSTERED INDEX (RealCID)) 
AS
SELECT *
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)
WHERE dc.RealCID IN 
('16914414',
'7635590',
'8097190',
'6803852',
'15843338',
'7703574',
'19292238',
'8889101',
'17921272',
'7074504',
'8539614',
'7581285',
'7889327',
'7881512',
'15986010',
'24644951',
'4891611',
'7836107',
'25951411',
'589795',
'8080919',
'11645015',
'8103636',
'8062106',
'7306834',
'7810953',
'5655321',
'17126994',
'18093576',
'7225856',
'8029712',
'8577959',
'10367917',
'24823211',
'8451914',
'6997472',
'2313767',
'7984950',
'13952456',
'403763',
'19827345',
'8264037',
'7759508',
'7130055',
'7222591',
'12858456',
'8582023',
'8955192',
'17969462',
'7497128',
'10781882',
'17149340',
'11696559',
'7772156',
'20438474',
'12339975',
'8993053',
'12771315',
'7692390',
'15923722',
'7433451',
'18655814',
'12026557',
'7931793',
'7403477',
'2684840',
'3628588',
'3746237',
'10315174',
'6769321',
'8335753',
'7403967',
'19467403',
'7616776',
'15058657',
'24415235',
'7472189',
'14530251',
'17489832',
'6796300',
'14443589',
'7538209',
'8227744',
'15618744',
'3855647',
'25122148',
'8551820',
'16910441',
'11434759',
'8482698',
'7719716',
'6536986',
'29945106',
'6437018',
'905456',
'7888757',
'18179455',
'7589040',
'2295900',
'9049504',
'7912011',
'7712687',
'22367323',
'8001493',
'18178723',
'9176595',
'6149892',
'10235942',
'13344053',
'10025054',
'12179157',
'3578212',
'14446470',
'10954282',
'8844504',
'7631948',
'17970529',
'21535405',
'17989157',
'15232292',
'12859125',
'8131116',
'6796252',
'17099989',
'17165079',
'6747358',
'8090006',
'21605856',
'7872809',
'6999250',
'22168355',
'11224726',
'17971587',
'7668776',
'14478567',
'8141106',
'4894779',
'3195732',
'10886845',
'5977710',
'7463363',
'1617354',
'7115271',
'6819322',
'13091967',
'9013975',
'7724514',
'17013016',
'7791446',
'12907340',
'12267531',
'15635499',
'10084357',
'7022490',
'6888615',
'8633919',
'6394114',
'6254967',
'9469321',
'15297077',
'18204908',
'6706126',
'11715903',
'8434403',
'8292047',
'19290572',
'8280723',
'14204118',
'6412103',
'18227468',
'7697020',
'8380834',
'15409428',
'12440177',
'6911125',
'3030764',
'3389382',
'5858408',
'5561645',
'7730666',
'6834926',
'11233672',
'7849013',
'7471824',
'7203980',
'6926350',
'8649211',
'8025861',
'12986120',
'7983502',
'4727305',
'17414311',
'7274472',
'19690181',
'3268528',
'7274969',
'14064842',
'6682767',
'8778836',
'18131382',
'13125805',
'7736835',
'8605854',
'9150144',
'15615522',
'13552793',
'1980429',
'7777941',
'6622592',
'10718437',
'15846216',
'10614403',
'7315123',
'12717701',
'11491166',
'6028472',
'6253465',
'7533947',
'7892113',
'7906504',
'8591133',
'13087087',
'13578624',
'13917371',
'17919465',
'8173052',
'7573627',
'7594066',
'20688930',
'7661001',
'8448839',
'10399403',
'8187667',
'6423639',
'7172217',
'6388684',
'8039405',
'11510254',
'7664751',
'6721691',
'7724932',
'16570054',
'7752672',
'11903948',
'5996453',
'14609577',
'7009424',
'7872960',
'18364404',
'16991622',
'7816060',
'21076741',
'9813536',
'9150912',
'19898295',
'23031737',
'7640462',
'7511629',
'8086918',
'9671148',
'17124932',
'17691206',
'13775185',
'8985538',
'15790115',
'11909135',
'6408118',
'7676731',
'17809472',
'18179860',
'8117770',
'14217378',
'8432562',
'6161329',
'13486984',
'7344661',
'13663619',
'8567182',
'8023994',
'9103581',
'10342876',
'6949372',
'7846008',
'10184337',
'7867700',
'7578694',
'13997376',
'7449504',
'8300333',
'15989177',
'10303532',
'13663416',
'12351957',
'8583363',
'25811184',
'2909003',
'9741366',
'9638636',
'10519591',
'15624633',
'24850732',
'8003291',
'7904147',
'7600951',
'22921692',
'8612752',
'18035153',
'17290813',
'6938307',
'6413774',
'19632706',
'16456768',
'7708767',
'6314307',
'10284490',
'8877583',
'8880302',
'4101397',
'7832110',
'4005873',
'7978758',
'7679499',
'5981868',
'8876532',
'8536274',
'21184768',
'8528492',
'8260306',
'8505810',
'17343110',
'4185181',
'8391482',
'17684386',
'7521366',
'21151107',
'8273860',
'6357726',
'14621221',
'7609450',
'6860746',
'21098495',
'8363234',
'6931423',
'8302148',
'6987013',
'19289716',
'8446323',
'12390973',
'7812864',
'17744362',
'8037525',
'6856782',
'8835980',
'22532701',
'20244489',
'8501822',
'13337761',
'6441384',
'16044986',
'7433505',
'8202964',
'16412449',
'18128128',
'8094068',
'8269490',
'17078844',
'8198569',
'5799135',
'9045170',
'8485446',
'18649849',
'7457433',
'8704215',
'14061626',
'14785335',
'9013385',
'20087500',
'14238043',
'8804874',
'20196178',
'17743644',
'7864011',
'16873998',
'5823894',
'17251500',
'8576756',
'7646396',
'11748912',
'21047106',
'7954967',
'6572285',
'9069204',
'6696928',
'7001908',
'18379707',
'7221127',
'15761157',
'19690758',
'17156255',
'5909661',
'7656764',
'11483469',
'9618573',
'7695179',
'15472910',
'16330989',
'5947554',
'7105882',
'8441432',
'6660563',
'8721629',
'19128937',
'7778193',
'6887247',
'18556197',
'15691767',
'22550298',
'7653761',
'18075781',
'15341504',
'7038729',
'16572728',
'7636662',
'7308898',
'6793275',
'23256254',
'7928364',
'12208397',
'19990415',
'22372946',
'6850169',
'8436473',
'8582000',
'13147516',
'8136333',
'7896675',
'7402581',
'6848698',
'8515572',
'7628601',
'8035046',
'8240925',
'9688070',
'19666414',
'7625052',
'6272492',
'13630491',
'8032335',
'8689341',
'5425907',
'8606791',
'3504642',
'25785794',
'11749804',
'23262207',
'18797451',
'7176469',
'7706684',
'12303194',
'8248364',
'12852197',
'9530041',
'18292606',
'12372383',
'8300063',
'8113830',
'9998612',
'17253772',
'6517599',
'15689243',
'7300337',
'6476288',
'8102659',
'7524310',
'8464189',
'7574108',
'9084779',
'5278368',
'17202686',
'13152671',
'8269902',
'6311001',
'19688996',
'24250986',
'19613876',
'8080946',
'10359015',
'8648539',
'7686012',
'17791396',
'6916078',
'9693837',
'12038197',
'7935328',
'7450883',
'27872365',
'13051882',
'7650833',
'7119446',
'8738492',
'7091164',
'7890898',
'9638766',
'18491016',
'9479960',
'18712196',
'11906673',
'17317413',
'22410399',
'10458176',
'7618478',
'14645440',
'8678388',
'379757',
'6899207',
'12551904',
'8009230',
'7773429',
'7465536',
'7855872',
'8132890',
'20202738',
'8880152',
'8122279',
'20846572',
'13085897',
'8117998',
'6695246',
'13831118',
'7623421',
'2671425',
'8682235',
'13109320',
'7333724',
'15400890',
'6953424',
'10397919',
'7252599',
'6850277',
'8535922',
'7276111',
'7176870',
'13420775',
'19385561',
'10355224',
'7539644',
'21349194',
'7570889',
'7494990',
'7355537',
'10848583',
'22976153',
'19319739',
'13026907',
'17033861',
'7508813',
'3473185',
'5665501',
'8734839',
'20610375',
'16354649',
'7082467',
'6975494',
'7907967',
'7039643',
'14907030',
'20017449',
'1036629',
'23090439',
'8241256',
'7899941',
'6835676',
'8134709',
'7370482',
'7770020',
'7111397',
'10312928',
'17745140',
'9213447',
'6845052',
'24673008',
'19904000',
'7366636',
'7660900',
'7701037',
'8846995',
'8426737',
'3534652',
'9426666',
'16633555',
'11477937',
'17242967',
'18739116',
'18514231',
'7260075',
'18104211',
'24158034',
'9045422',
'9905868',
'9649550',
'22936185',
'7280413',
'8714877',
'8067122',
'7456791',
'6631018',
'6155997',
'4293099',
'8220646',
'10604384',
'8225192',
'12082588',
'13937535',
'8585785',
'11243343',
'8476658',
'10068040',
'6825977',
'6884132',
'13570577',
'14133736',
'7863932',
'5840225',
'8280007',
'15184999',
'9592361',
'7404495',
'24465714',
'18294368',
'10117467',
'16057063',
'19694752',
'7330634',
'14561996',
'9186855',
'17116596',
'7975402',
'14246391',
'3412697',
'7768340',
'18731023',
'6409347',
'15308852',
'14899259',
'10936927',
'8708721',
'20986487',
'7482105',
'22085043',
'6694823',
'16986806',
'12011575',
'5967987',
'7897143',
'7778177',
'7880697',
'17090594',
'9690250',
'6341675',
'17373259',
'15146148',
'6974839',
'16932052',
'13242272',
'7905253',
'8476713',
'14535362',
'13735255',
'18093502',
'7001507',
'17297368',
'17533671',
'6326451',
'12309366',
'7350826',
'13888101',
'5539672',
'7704445',
'8958708',
'16925774',
'19918837',
'7065476',
'18236095',
'9637949',
'8735175',
'9483095',
'20079724',
'6114589',
'9183778',
'19541107',
'12232087',
'8393768',
'8338332',
'15846056',
'15932840',
'6906140',
'19202913',
'8270115',
'7017445',
'18206495',
'18281424',
'7326887',
'26527771',
'17267030',
'13922434',
'8256062',
'19872737',
'9938985',
'12684171',
'14181709',
'7393432',
'16565787',
'3290685',
'6900112',
'3680709',
'8029985',
'8078459',
'15403282',
'13282608',
'17456649',
'8531440',
'20417749',
'10685378',
'6166233',
'6855346',
'16411999',
'6368600',
'15318250',
'13668658',
'16763043',
'10863923',
'6201309',
'6926927',
'9015802',
'9473186',
'16303242',
'3962991',
'13427213',
'21827706',
'8229420',
'10587188',
'6581544',
'6254408',
'6377374',
'6996485',
'7791886',
'15598219',
'21833320',
'6395834',
'14258445',
'8010549',
'6835225',
'8239413',
'297621',
'8515772',
'22028325',
'7459201',
'14204622',
'12225585',
'7619713',
'21164082',
'10707460',
'10651370',
'17001590',
'6942605',
'8280949',
'17128195',
'4216189',
'20427206',
'10253241',
'7397874',
'22214021',
'19289891',
'9076484',
'17255052',
'14215099',
'9616849',
'8548905',
'7416669',
'15365846',
'13037245',
'16840580',
'6456284',
'26057595',
'6480284',
'18743317',
'13164360',
'18239341',
'13471342',
'7858178',
'8538537',
'20342065',
'7639441',
'24197437',
'6440315',
'7861607',
'6506332',
'8228075',
'8709045',
'9267587',
'12169028',
'15541540',
'2656901',
'8398652',
'7997688',
'3984898',
'16829817',
'7598545',
'7062946',
'13141866',
'8953021',
'7029078',
'9046226',
'8054219',
'8219813',
'5565410',
'8341511',
'8070220',
'13028230',
'7848590',
'17302971',
'8110175',
'4059712',
'16318882',
'7445557',
'7519076',
'6281502',
'6761652',
'15841161',
'11470588',
'7498782',
'23703072',
'10151727',
'10743388',
'8690514',
'12855876',
'17205494',
'11788452',
'17597248',
'1370146',
'8830325',
'19557836',
'7394728',
'11772185',
'8549473',
'8772291',
'18146509',
'10580368',
'14131144',
'12395425',
'8398630',
'7248491',
'13394512',
'6967269',
'11638342',
'7190313',
'20541491',
'8113533',
'8230256',
'7492400',
'14224425',
'14479050',
'6748227',
'12519227',
'8957619',
'24944898',
'17287027',
'7175679',
'8757616',
'12590672',
'7832207',
'6721638',
'15361759',
'7387523',
'9105350',
'7642125',
'7734390',
'22012999',
'8350451',
'7854203',
'7474342',
'18471161',
'7436297',
'7800884',
'8755989',
'8292098',
'6306325',
'8056650',
'8589966',
'7643619',
'8150057',
'14492923',
'8130342',
'6843378',
'8068912',
'17340425',
'294081',
'20155960',
'16534076',
'7377753',
'7638637',
'7251160',
'12566700',
'5055968',
'18890527',
'8190916',
'8352922',
'7389791',
'20400470',
'19875308',
'9195518',
'9384205',
'7340935',
'17022351',
'20391374',
'8502087',
'7486673',
'18156272',
'19452563',
'8040163',
'8112156',
'9076813',
'29428304',
'7686083',
'6256625',
'9526776',
'5073426',
'17143199',
'10276956',
'7514433',
'17961739',
'12611072',
'3784505',
'21252334',
'7813081',
'6416954',
'22131708',
'18632341',
'14992254',
'13443272',
'10965052',
'8728877',
'7461792',
'8076048',
'8211199',
'8266544',
'3446398',
'17325862',
'8073290',
'8646588',
'6708595',
'6748401',
'10029249',
'14563656',
'18250503',
'8225265',
'8361967',
'20070368',
'18728683',
'15342658',
'17287646',
'7446477',
'10429523',
'7346591',
'11869184',
'7482321',
'8344637',
'8692360',
'17348906',
'8178492',
'11096027',
'23034892',
'17135348',
'18346094',
'25371554',
'7428409',
'19959234',
'20272831',
'16721923',
'16604619',
'13487924',
'13459261',
'6794929',
'17509568',
'22188642',
'13002577',
'6476192',
'7380765',
'20705885',
'22781390',
'16470481',
'5733280',
'13249993',
'6387799',
'6858416',
'22182069',
'11421993',
'10562881',
'10230964',
'7026812'
)

IF OBJECT_ID('tempdb..#Pop') IS NOT NULL DROP TABLE #Pop
CREATE TABLE #Pop
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX (CID)) 
AS
SELECT   bddcr.RealCID AS CID
		,SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Revenue_Crypto
		,SUM(CASE WHEN InstrumentTypeID = 10 AND bddcr.DateID>=@after_date_INT AND bddcr.DateID<=@after_date_INT_end THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Revenue_Crypto_from_20230801---Until 20231115
		,SUM(CASE WHEN InstrumentTypeID = 10 AND bddcr.DateID>=@campaign_start_INT THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Revenue_Crypto_from_20231201
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr WITH (NOLOCK)
INNER JOIN #List l ON bddcr.RealCID=l.RealCID
GROUP BY bddcr.RealCID


/********** Step 03 **********/
/********** Last contacted **********/

IF OBJECT_ID('tempdb..#Last_Contact') IS NOT NULL DROP TABLE #Last_Contact
CREATE TABLE #Last_Contact
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX (CID)) 
AS
SELECT  bduts.CID
       ,MAX(CAST(bduts.CreatedDate AS DATE)) AS Last_contact
FROM BI_DB_dbo.BI_DB_UsageTracking_SF bduts WITH (NOLOCK)
INNER JOIN #Pop p ON bduts.CID = p.CID
WHERE bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c')
GROUP BY bduts.CID

/********** Step 04**********/
/********** Last Crypto position opened **********/

IF OBJECT_ID('tempdb..#Last_Crypto_open') IS NOT NULL DROP TABLE #Last_Crypto_open
CREATE TABLE #Last_Crypto_open
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX (CID)) 
AS
SELECT dp.CID
      ,MAX(CAST(dp.OpenOccurred AS DATE)) AS OpenOccurred
FROM DWH_dbo.Dim_Position dp WITH (NOLOCK)
INNER JOIN #Pop p ON dp.CID = p.CID
INNER JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK) ON dp.InstrumentID = di.InstrumentID
WHERE di.InstrumentTypeID=10 AND dp.MirrorID=0 
GROUP BY dp.CID

/********** Step 05**********/
/********** Delete and insert to final table **********/

TRUNCATE TABLE [BI_DB_dbo].[BI_DB_Crypto_Top_1000_List]

INSERT INTO [BI_DB_dbo].[BI_DB_Crypto_Top_1000_List]
(
    [CID],
	[GCID],
	[Region],
	[AccountManager],
	[Club],
	[LastLoggedIn],
	[LastDepositDate],
	[LastPosOpenDate],
	[LastContacted],
	[LastCryptoPosOpenDate],
	[Equity],
	[ACC_Revenue],
	[ACC_Revenue_Crypto],
	[Revenue_Crypto_from_20230801],
	[Revenue_Crypto_from_20231201],
	[UpdateDate]
)

SELECT  bdcmpfd.CID
       ,bdcd.GCID
       ,bdcmpfd.NewMarketingRegion AS Region
	   ,bdcmpfd.AccountManager
	   ,bdcd.Club
	   ,bdcmpfd.LastLoggedIn
	   ,CAST(bdcd.LastDepositDate AS DATE) AS LastDepositDate
	   ,CAST(bdcd.LastPosOpenDate AS DATE) AS LastPosOpenDate 
	   ,ISNULL(lc.Last_contact,NULL) AS LastContacted
	   ,ISNULL(lco.OpenOccurred,NULL) AS LastCryptoPosOpenDate
	   ,bdcmpfd.EOM_Equity AS Equity
	   ,bdcmpfd.ACC_Revenue_Total AS ACC_Revenue
	   ,SUM(p.Revenue_Crypto) AS ACC_Revenue_Crypto
	   ,SUM(p.Revenue_Crypto_from_20230801) AS Revenue_Crypto_from_20230801
	   ,SUM(p.Revenue_Crypto_from_20231201) AS Revenue_Crypto_from_20231201
	   ,GETDATE() AS UpdateDate
FROM  BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd 
INNER JOIN #Pop p ON bdcmpfd.CID = p.CID
LEFT JOIN #Last_Contact lc ON bdcmpfd.CID = lc.CID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON bdcmpfd.CID = bdcd.CID
LEFT JOIN #Last_Crypto_open lco ON bdcmpfd.CID = lco.CID
WHERE bdcmpfd.ActiveDate=@BeginOfMonth 
GROUP BY bdcmpfd.CID
       ,bdcd.GCID
       ,bdcmpfd.NewMarketingRegion 
	   ,bdcmpfd.AccountManager
	   ,bdcd.Club
	   ,bdcmpfd.LastLoggedIn
	   ,bdcd.LastDepositDate
	   ,bdcd.LastPosOpenDate
	   ,ISNULL(lc.Last_contact,NULL)
	   ,ISNULL(lco.OpenOccurred,NULL)
	   ,bdcmpfd.EOM_Equity 
	   ,bdcmpfd.ACC_Revenue_Total


/********** SP END **********/
END





GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Crypto_Top_1000_List` | synapse_sp | BI_DB_dbo | SP_Crypto_Top_1000_List | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Crypto_Top_1000_List.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `BI_DB_dbo.BI_DB_DailyCommisionReport` | synapse | BI_DB_dbo | BI_DB_DailyCommisionReport | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md` |
| `BI_DB_dbo.BI_DB_UsageTracking_SF` | synapse | BI_DB_dbo | BI_DB_UsageTracking_SF | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_UsageTracking_SF.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_MonthlyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | synapse | BI_DB_dbo | BI_DB_CIDFirstDates | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |

