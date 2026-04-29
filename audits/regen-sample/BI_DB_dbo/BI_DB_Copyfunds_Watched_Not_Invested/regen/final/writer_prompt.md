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
- **Object**: `BI_DB_Copyfunds_Watched_Not_Invested`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_Copyfunds_Watched_Not_Invested/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Copyfunds_Watched_Not_Invested\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Copyfunds_Watched_Not_Invested\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
(
	[Account Manager] [varchar](50) NULL,
	[FundName] [varchar](100) NULL,
	[RealCID] [int] NULL,
	[UserName] [varchar](100) NULL,
	[FundCID] [int] NULL,
	[AccountManagerID] [int] NULL,
	[IsLifetimeCopied] [int] NULL,
	[IsLastYearCopied] [int] NULL,
	[IsCurrentlyCopied] [int] NULL,
	[CopyEquity] [money] NULL,
	[CopyPortfolioEquity] [money] NULL,
	[MoneyAvailable] [money] NULL,
	[LiquidAssetsAnswer] [varchar](100) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[RealCID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


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


### Upstream `DWH_dbo.Dim_Manager` — synapse
- **Resolved as**: `DWH_dbo.Dim_Manager`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md`

# DWH_dbo.Dim_Manager

> 5,152-row dimension table mapping ManagerID to the BackOffice customer-success and support manager who is assigned to a customer account -- combining manager name, active status, team-leader flag, Salesforce CRM ID, and Calendly scheduling ID into a single reference table for customer-manager analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.BackOffice.Manager (BackOffice CRM) + Salesforce (SFManagerID) |
| **Refresh** | Daily (incremental: UPDATE existing + INSERT new; never truncates) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP, PK_ManagerID NOT ENFORCED |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Manager` is the reference table for eToro's BackOffice customer-success managers -- the people (support agents, account managers, team leaders) assigned to serve customer accounts. A customer account typically has an assigned ManagerID that identifies the primary relationship owner in the BackOffice/CRM system.

The table holds 5,152 rows: 1,367 currently active managers (`IsActive=True`) including 1 active team leader, plus 3,785 historical/departed managers (`IsActive=False`). Since rows are never deleted, the table preserves the full history of everyone who has ever been a manager in the system.

Key columns: `FirstName`, `LastName` (personal details), `IsActive` (currently employed/assigned), `IsTeamLeader` (hierarchy flag), `SFManagerID` (Salesforce CRM ID, 18-char), `CalendlyID` (scheduling link). The `UserGroup` and `ParentUserGroup` columns are **not populated** -- both are hardcoded to `'Not Available'` in the ETL SP.

ETL pattern: `SP_Dictionaries_DL_To_Synapse` -- loads a staging intermediate (`Ext_Dim_Manager`) from `DWH_staging.etoro_BackOffice_Manager`, then merges into `Dim_Manager` (UPDATE existing rows, INSERT new rows). A post-load UPDATE sets `SFManagerID` from the Salesforce-to-BackOffice mapping table.

---

## 2. Business Logic

### 2.1 Incremental Merge Pattern (Soft-Delete)

**What**: Unlike most DWH Dim tables that use TRUNCATE+INSERT, Dim_Manager uses an incremental UPDATE+INSERT pattern that preserves historical manager records.

**Rules**:
- **UPDATE**: Existing ManagerID rows are updated with current FirstName, LastName, IsTeamLeader, IsActive, CalendlyID. This means a manager's name, active status, or team-leader flag can change.
- **INSERT**: New ManagerIDs from `etoro_BackOffice_Manager` that do not exist in Dim_Manager are appended. `InsertDate` is set to GETDATE() on first insert only.
- **No DELETE**: Managers who leave the company remain in the table with `IsActive=False`. The table is the full history of all managers.
- **SFManagerID**: Set via a separate post-load UPDATE joining to `SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping`. Managers not in Salesforce have NULL SFManagerID.

### 2.2 UserGroup / ParentUserGroup Not Populated

**What**: The DDL defines `UserGroup` and `ParentUserGroup` columns, but the ETL hardcodes both to `'Not Available'` for all rows.

**Rule**: Do not use `UserGroup` or `ParentUserGroup` for any analysis. Both columns have the literal string `'Not Available'` for every row. The intended team/group hierarchy data has not been implemented.

### 2.3 CalendlyID for Customer Scheduling

**What**: `CalendlyID` holds the manager's Calendly scheduling account identifier, used for customer-facing meeting booking.

**Rule**: Most inactive (historical) managers have `CalendlyID='etoro-club'`, suggesting a default value is set when a manager leaves the system rather than the CalendlyID being set to NULL. Active managers have their personal Calendly IDs. Do not use CalendlyID to infer active status.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (5,152 rows trivially replicated). HEAP -- no clustered index. PK_ManagerID is NOT ENFORCED (Synapse syntax; uniqueness is not guaranteed at the DB level, though duplicates are not expected). Zero JOIN overhead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get manager name for a customer account | `JOIN Dim_Manager ON ManagerID; SELECT FirstName, LastName` |
| Find all currently active managers | `WHERE IsActive = 1` (1,367 rows) |
| Find active team leaders | `WHERE IsActive = 1 AND IsTeamLeader = 1` (1 row currently) |
| Cross-reference with Salesforce | `WHERE SFManagerID IS NOT NULL` |

### 3.3 Gotchas

- **UserGroup = 'Not Available'**: Both `UserGroup` and `ParentUserGroup` are hardcoded placeholder strings. Do not use for grouping or filtering.
- **3,785 inactive managers**: Always filter `WHERE IsActive = 1` for current-state analysis. Leaving out this filter inflates manager counts 4x.
- **CalendlyID default 'etoro-club'**: This is a default value for departed/inactive managers, not a real Calendly account. Filter on IsActive=1 for meaningful CalendlyID usage.
- **HEAP index**: Full table scans on all queries. Acceptable at 5,152 rows.
- **PK NOT ENFORCED**: No database-level guarantee against duplicate ManagerIDs. Validate if using ManagerID as a join key in data quality checks.
- **SFManagerID is NULL for many managers**: Only managers that appear in the Salesforce-to-BackOffice mapping have SFManagerID populated.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ManagerID | int | NO | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the 'acting staff' reference. (Tier 1 — BackOffice.Manager) |
| 2 | UserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. The ETL SP sets this to a literal constant: `'Not Available' as UserGroup`. Intended to represent the manager's team/group but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 3 | ParentUserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. Same as UserGroup -- intended to represent the manager's parent team hierarchy but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 4 | FirstName | varchar(50) | NO | Staff member's first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + ' ' + LastName). (Tier 1 — BackOffice.Manager) |
| 5 | LastName | varchar(50) | NO | Staff member's last name. Combined with FirstName for display. LastName='*' indicates a functional/shared account (e.g., the generic 'support' account). (Tier 1 — BackOffice.Manager) |
| 6 | IsActive | bit | NO | Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked). Do NOT physically delete manager rows — use IsActive=0 to preserve audit history. (Tier 1 — BackOffice.Manager) |
| 7 | IsTeamLeader | bit | NO | Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. (Tier 1 — BackOffice.Manager) |
| 8 | DWHManagerID | int | YES | Always equal to ManagerID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 9 | StatusID | int | YES | Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | YES | ETL run timestamp for the most recent UPDATE that touched this row. Set to GETDATE() on every daily UPDATE. Reflects last ETL run, not production modification. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | YES | ETL run timestamp when the manager row was first inserted into Dim_Manager. Set once on INSERT; not updated on subsequent runs. Unlike most DWH tables, this may reflect the actual first-appearance date for the manager. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 12 | SFManagerID | nvarchar(18) | YES | Salesforce CRM 18-character object ID for this manager (e.g., 0050800000DitvwAAB). Set via post-load UPDATE from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping. NULL for managers not present in the Salesforce mapping. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 13 | CalendlyID | nvarchar(50) | YES | Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. (Tier 1 — BackOffice.Manager) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ManagerID | etoro.BackOffice.Manager | ManagerID | passthrough |
| UserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| ParentUserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| FirstName | etoro.BackOffice.Manager | FirstName | passthrough |
| LastName | etoro.BackOffice.Manager | LastName | passthrough |
| IsActive | etoro.BackOffice.Manager | IsActive | passthrough |
| IsTeamLeader | etoro.BackOffice.Manager | IsTeamLeader | passthrough |
| DWHManagerID | etoro.BackOffice.Manager | ManagerID | rename (= ManagerID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each UPDATE |
| InsertDate | -- | -- | ETL-computed: GETDATE() on first INSERT only |
| SFManagerID | Salesforce SalesForceToBOManagerMapping | SFManagerID | post-load UPDATE via ManagerID join |
| CalendlyID | etoro.BackOffice.Manager | CalendlyID | passthrough (UPDATE) |

### 5.2 ETL Pipeline

```
etoro.BackOffice.Manager  (BackOffice CRM)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_BackOffice_Manager
  |-- SP_Dictionaries_DL_To_Synapse ---|
      1. TRUNCATE Ext_Dim_Manager + INSERT from etoro_BackOffice_Manager
      2. UPDATE Dim_Manager (existing rows: name, active, team-leader, Calendly)
      3. INSERT Dim_Manager (new ManagerIDs not yet in table)
      4. UPDATE SFManagerID from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping
  v
DWH_dbo.Dim_Manager  (5,152 rows; incremental, never truncated)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Manager/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | ManagerID | Identifies the assigned BackOffice manager for each customer |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP; incremental pattern |

---

## 7. Sample Queries

### 7.1 List all currently active managers

```sql
SELECT ManagerID, FirstName, LastName, IsTeamLeader, SFManagerID, CalendlyID
FROM [DWH_dbo].[Dim_Manager]
WHERE IsActive = 1
ORDER BY IsTeamLeader DESC, LastName, FirstName;
```

### 7.2 Count customers per active manager

```sql
SELECT
    m.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Manager] m ON f.ManagerID = m.ManagerID
WHERE m.IsActive = 1
GROUP BY m.ManagerID, m.FirstName, m.LastName
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.4/10 (★★★★☆) | Phases: 8/14*
*Tiers: 6 T1, 5 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Manager | Type: Table | Production Source: etoro.BackOffice.Manager + Salesforce*


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


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Copyfunds_Watched_Not_Invested] AS
 

-- #userfollowfund = get all users that followed in the last Month

DECLARE @dd	AS DATE = DATEADD(DAY,-1,GETDATE() )
DECLARE @ddID AS INT = CAST(CONVERT(CHAR(8),@dd,112) AS INT)
DECLARE @monthback AS DATETIME = DATEADD(MONTH, -1,CONVERT(DATE,@dd) ) 
DECLARE @yearback AS DATE = DATEADD(YEAR,-1,@dd )
DECLARE @yearbackID AS INT = CAST(CONVERT(CHAR(8),@yearback,112) AS INT )

EXECUTE [BI_DB_dbo].[SP_Create_External_Streams_dbo_FollowRelationships_Range] @monthback,@dd, 'BI_DB_dbo.BI_DB_dbo_Relationship_sp' 
 
IF OBJECT_ID('tempdb..#userfollowfund') IS NOT NULL DROP TABLE #userfollowfund
CREATE TABLE #userfollowfund
    WITH (DISTRIBUTION=ROUND_ROBIN,HEAP)
AS

	select 
		substring(FollowerUsername,2,999) [Username]
		,SourceName [FundName]

	from [BI_DB_dbo].[BI_DB_dbo_Relationship_sp]

	where CreatedAt >= @monthback --get all watchlists from the past week

/****************************************************************************/
-- #transformuserdata = filter #userfollowfund to following funds only, then transform userfollowfund raw data into User CIDs, Fund CIDs etc.

IF OBJECT_ID('tempdb..#transformuserdata') IS NOT NULL DROP TABLE #transformuserdata
CREATE TABLE #transformuserdata
    WITH (DISTRIBUTION=HASH(RealCID),CLUSTERED INDEX(RealCID))
AS
 
	select 
		dc1.RealCID
		,dc1.UserName
		,dc1.AccountManagerID
		,dc2.RealCID [FundCID]
		,dc2.UserName [FundName]
	
	
	from #userfollowfund ff
	
	join DWH_dbo.Dim_Customer dc1 With(NOLOCK)
		on lower(dc1.UserName) = ff.Username collate Latin1_General_BIN
	join DWH_dbo.Dim_Customer dc2 With(NOLOCK)
		on lower(dc2.UserName) = substring(ff.FundName,2,999) collate Latin1_General_BIN

	where dc2.AccountTypeID = 9 and dc1.IsValidCustomer = 1

--
IF OBJECT_ID('tempdb..#distincttransformuserdata') IS NOT NULL DROP TABLE #distincttransformuserdata
CREATE TABLE #distincttransformuserdata
    WITH (DISTRIBUTION=HASH(RealCID),CLUSTERED INDEX(RealCID))
AS

	SELECT 
		DISTINCT RealCID	

	FROM #transformuserdata t




/*******************************************************************************/
-- #temp = show if user invested in the followed copyFund

IF OBJECT_ID('tempdb..#temp') IS NOT NULL DROP TABLE #temp
CREATE TABLE #temp
    WITH (DISTRIBUTION=HASH(RealCID),CLUSTERED INDEX(RealCID))
AS 
	Select 
		t.RealCID
		,Max(Case When dm.MirrorTypeID = 4 then 1 else 0 End)									As IsLifetimeCopied
		,MAX(CASE WHEN dm.MirrorTypeID = 4 AND dm.OpenDateID >= @yearbackID THEN 1 ELSE 0 END)	AS IsLastYearCopied
		,MAX(Case When dm.MirrorTypeID = 4 AND dm.CloseDateID = 0 then 1 else 0 End)			As IsCurrentlyCopied
		,SUM(CASE WHEN dm.CloseDateID = 0 THEN dm.Amount ELSE 0 end)							AS CopyEquity
		,SUM(CASE WHEN dm.MirrorTypeID = 4 AND dm.CloseDateID = 0 THEN dm.Amount ELSE 0 end)	AS CopyPortfolioEquity
		
	
	From #transformuserdata t
	
	left Join DWH_dbo.Dim_Mirror dm
		on t.RealCID = dm.CID
	--	and dm.MirrorTypeID = 4
	
	Group By t.RealCID, t.UserName, t.AccountManagerID, t.FundCID, t.FundName




/*****************************************************************************/
-- #final = add equity and manager to #temp

IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
CREATE TABLE #final
    WITH (DISTRIBUTION=HASH(RealCID),CLUSTERED INDEX(RealCID))
AS  

	select 
		(dm.FirstName+' '+ dm.LastName) [Account Manager]
		,tud.FundName
		,t.RealCID
		,tud.UserName
		,tud.FundCID
		,tud.AccountManagerID
		,t.IsLifetimeCopied
		,t.IsLastYearCopied
		,t.IsCurrentlyCopied
		,t.CopyEquity
		,t.CopyPortfolioEquity
		,vl.Credit [MoneyAvailable]
		--,rl.AnswerText [LiquidAssetsAnswer]
		,rl.Q11_AnswerText [LiquidAssetsAnswer]

	from #temp t
	JOIN #transformuserdata tud
			ON t.RealCID = tud.RealCID

	join DWH_dbo.Dim_Manager dm
		on dm.ManagerID = tud.AccountManagerID
	JOIN DWH_dbo.V_Liabilities vl
		ON t.RealCID = vl.CID AND vl.DateID = @ddID
	LEFT JOIN [BI_DB_dbo].[BI_DB_KYC_Panel] rl
		ON t.RealCID = rl.RealCID AND rl.Q11_AnswerID IS NOT NULL

	--where t.IsLifetimeCopied = 0 

/*****************************************************************************/
-- dbo.Copyfunds_Watched_Not_Invested = the actual table with the #final values. drops and re-creates every dat

truncate table [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]


insert into [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested] (
		[Account Manager]
		,FundName
		,RealCID
		,UserName
		,FundCID
		,AccountManagerID
		,IsLifetimeCopied
		,IsLastYearCopied
		,IsCurrentlyCopied
		,CopyEquity
		,CopyPortfolioEquity
		,MoneyAvailable
		,LiquidAssetsAnswer
		,UpdateDate
		)

	select [Account Manager]
      ,[FundName]
      ,[RealCID]
      ,[UserName]
      ,[FundCID]
      ,[AccountManagerID]
	  ,IsLifetimeCopied
	  ,IsLastYearCopied
	  ,IsCurrentlyCopied
	  ,CopyEquity
	  ,CopyPortfolioEquity
	  ,MoneyAvailable
	  ,LiquidAssetsAnswer
	  ,getdate() [UpdateDate]
	from #final 


--EXEC tempdb.dbo.sp_help N'#temp';


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested` | synapse_sp | BI_DB_dbo | SP_Copyfunds_Watched_Not_Invested | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested.sql` |
| `BI_DB_dbo.BI_DB_dbo_Relationship_sp` | unresolved | BI_DB_dbo | BI_DB_dbo_Relationship_sp | `—` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Mirror` | synapse | DWH_dbo | Dim_Mirror | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `DWH_dbo.Dim_Manager` | synapse | DWH_dbo | Dim_Manager | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `BI_DB_dbo.BI_DB_KYC_Panel` | synapse | BI_DB_dbo | BI_DB_KYC_Panel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_KYC_Panel.md` |


---

# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these

Previous attempt scored **7.2** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Fix MoneyAvailable Element description — remove the erroneous 'Answer text for Q11.' prefix; correct opening should be 'Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities.' (2) Fix [Account Manager] NULL semantics — the SP uses INNER JOIN to Dim_Manager, so customers with NULL or unmatched AccountManagerID are excluded entirely, not NULL-populated; document this filtering effect. (3) Add Section 2 subsection documenting the #final fan-out mechanism: because #temp groups by FundCID but does not SELECT it, the JOIN back to #transformuserdata on RealCID alone produces N×N rows for investors watching N funds; this is the root cause of duplicate (RealCID, FundName) pairs. (4) Embed the ETL pipeline ASCII diagram inline in Section 5 of the wiki — do not merely reference the lineage file. (5) Correct footer tier count from '6 T1, 8 T2' to '7 T1, 7 T2' and add quality score and phases-completed list to footer.

Top issues from the judge:
1. [high] `MoneyAvailable` — Element description begins 'Answer text for Q11.' — a copy-paste artifact from LiquidAssetsAnswer. MoneyAvailable is V_Liabilities.Credit (a credit balance), not a KYC question answer. The correct information follows the bad prefix but the opening sentence is factually wrong and will mislead any reader scanning column 12.
2. [high] `[Account Manager]` — Wiki states '[Account Manager]: NULL if no manager is assigned.' This is incorrect. The SP uses an INNER JOIN to Dim_Manager (`join DWH_dbo.Dim_Manager dm on dm.ManagerID = tud.AccountManagerID`), not a LEFT JOIN. Customers with NULL AccountManagerID fail the INNER JOIN predicate (NULL = NULL is false in SQL) and are excluded from the table entirely. The [Account Manager] column is never NULL in practice — rows without a manager are missing, not NULL-populated.
3. [medium] `Section 2 / Business Logic` — #final fan-out bug not documented in Section 2. The SP groups #temp by (RealCID, UserName, AccountManagerID, FundCID, FundName) but does not carry FundCID into the physical #temp table. The subsequent join in #final is `JOIN #transformuserdata tud ON t.RealCID = tud.RealCID` without a FundCID predicate, causing N×N row fan-out for investors watching N funds. This is the root cause of the duplicate (RealCID=54019 × FundName='StanleyDruck13F') rows noted in the review-needed sidecar. Section 2 does not document this mechanism.
4. [medium] `Section 5` — ETL pipeline ASCII diagram is not embedded inline in the wiki's Section 5. The wiki defers to the lineage file ('See BI_DB_Copyfunds_Watched_Not_Invested.lineage.md for full column lineage and ETL pipeline diagram'). The rubric requires the diagram with real object names in the wiki itself.
5. [low] `Footer` — Footer tier count claims '6 T1, 8 T2' but the Elements table contains 7 T1 columns (FundName, RealCID, UserName, FundCID, AccountManagerID, MoneyAvailable, LiquidAssetsAnswer) and 7 T2 columns. Off by one in both directions. Footer also missing quality score and phases-completed list required by the golden reference shape.

Tier 1 paraphrasing failures (must be fixed verbatim):

- **MoneyAvailable**:
  - Upstream: `Credit | Fact_SnapshotEquity.Credit | Direct | T1 (V_Liabilities col 12)`
  - You wrote: `Answer text for Q11. Renamed from V_Liabilities.Credit — the investor's available credit balance as of yesterday. Max observed: $855,862.42. Used by account managers to identify investable capacity.`
  - Loss: Description opens with 'Answer text for Q11' — factually wrong domain (MoneyAvailable is a credit balance, not a KYC answer). Copy-paste artifact from LiquidAssetsAnswer description. Semantic corruption in the first sentence misleads any reader scanning the Elements table.

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
