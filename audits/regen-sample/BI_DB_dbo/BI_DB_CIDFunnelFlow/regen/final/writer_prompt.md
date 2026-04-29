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
- **Object**: `BI_DB_CIDFunnelFlow`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_CIDFunnelFlow/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CIDFunnelFlow\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CIDFunnelFlow\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_CIDFunnelFlow.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CIDFunnelFlow`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CIDFunnelFlow.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CIDFunnelFlow]
(
	[RealCID] [int] NOT NULL,
	[Date] [date] NULL,
	[Region] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[State] [varchar](100) NULL,
	[Channel] [nvarchar](50) NULL,
	[SubChannel] [varchar](100) NULL,
	[Funnel] [varchar](50) NULL,
	[DesignatedRegulation] [varchar](50) NULL,
	[Regulation] [varchar](50) NULL,
	[AffiliateID] [int] NULL,
	[FunnelFrom] [varchar](50) NULL,
	[Platform] [varchar](50) NULL,
	[REG] [int] NULL,
	[EmailVerification] [int] NULL,
	[V1] [int] NULL,
	[V2] [int] NULL,
	[V3] [int] NULL,
	[EV] [int] NULL,
	[SendToEV] [int] NULL,
	[PEP] [varchar](50) NULL,
	[ProofOfAddress] [int] NULL,
	[ProofOfIdentity] [int] NULL,
	[PhoneVerified] [int] NULL,
	[POA_POI] [int] NULL,
	[POA_POI_Phone] [int] NULL,
	[DepositAttempt] [int] NULL,
	[FTD] [int] NULL,
	[IsContacted] [int] NULL,
	[PhoneContacted] [int] NULL,
	[EmailContacted] [int] NULL,
	[PhoneContactedSucceed] [int] NULL,
	[EmailContactedSucceed] [int] NULL,
	[ConvOver96H] [int] NULL,
	[PendingVerification] [int] NULL,
	[ReportDateID] [varchar](8) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[ReportDateID] ASC,
		[RealCID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 13 upstream wiki(s). Read EACH one in full.


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


### Upstream `DWH_dbo.Dim_State_and_Province` — synapse
- **Resolved as**: `DWH_dbo.Dim_State_and_Province`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_State_and_Province.md`

# DWH_dbo.Dim_State_and_Province

> Geographic dimension mapping 181 IP-based region codes to country-level sub-divisions (states, provinces, territories). Joins etoro.Dictionary.RegionByIP codes with Dictionary.RegionName full labels. Sourced daily via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RegionByIP + etoro.Dictionary.RegionName (JOIN) |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (implied — see DDL) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_State_and_Province` maps IP-based geographic region identifiers to human-readable sub-country labels (states, provinces, territories). When customers register or transact, their IP address is resolved to a country and sub-country region. This dimension bridges the numeric `RegionByIP_ID` (from `Dictionary.RegionByIP`) with the full geographic name from `Dictionary.RegionName`.

The table contains 181 rows — a subset of the full `Dictionary.RegionByIP` (4,206 entries). The reduction occurs because the ETL uses an INNER JOIN between `RegionByIP` (indexed by RegionByIP_ID, CountryID, and a short code in Name) and `RegionName` (which stores full ShortName and Name per country). Only regions with a matching `RegionName.ShortName = RegionByIP.Name` for the same country appear in DWH.

Source pipeline: SP_Dictionaries_DL_To_Synapse performs TRUNCATE + INSERT with:
```sql
SELECT rei.RegionByIP_ID, ren.CountryID, ren.ShortName, ren.Name, GETDATE()
FROM etoro_Dictionary_RegionByIP AS rei
JOIN etoro_Dictionary_RegionName AS ren
  ON rei.Name = ren.ShortName AND rei.CountryID = ren.CountryID
```

---

## 2. Business Logic

### 2.1 IP Region to Full Name Resolution

**What**: Maps the numeric IP-geolocation region code (RegionByIP_ID) to a country and human-readable geographic name.

**Columns Involved**: `RegionByIP_ID`, `CountryID`, `ShortName`, `Name`

**Rules**:
- `RegionByIP_ID` is the join key used in customer fact/dim tables (stored in `Customer.CustomerStatic.RegionByIP_ID`)
- `ShortName` is the short alphanumeric code used by IP geolocation providers (e.g., "CA", "NY", "64")
- `Name` is the full geographic label (e.g., "California", "New York") from Dictionary.RegionName
- The INNER JOIN means only 181 of 4,206 total regions are present — regions without a matching `RegionName` entry are excluded from DWH
- `CountryID` references DWH_dbo.Dim_Country for country-level lookups

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 181-row table — full local copy on every node, zero data movement on JOINs to large customer fact tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer geographic distribution by state/province | JOIN customer fact/dim ON RegionByIP_ID |
| Filter to specific country regions | WHERE CountryID = <DWH country ID> |
| Resolve region code to full name | JOIN ON RegionByIP_ID, display Name column |

### 3.3 Gotchas

- **181 rows ≠ complete global coverage**: Only regions with matching RegionName entries are present. Customer regions not in this table will produce NULL JOINs
- **Two "name" concepts**: `ShortName` is the geolocation provider's short code; `Name` is the human-readable full label
- **CountryID in DWH context**: References Dim_Country.CountryID for country enrichment

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegionByIP_ID | int | NOT NULL | Primary join key. Auto-incrementing surrogate PK from `Dictionary.RegionByIP` (IDENTITY NOT FOR REPLICATION). Stored in `Customer.CustomerStatic.RegionByIP_ID` and used to identify the sub-country region detected from a customer's IP address at registration. (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| 2 | CountryID | int | NOT NULL | Country this region belongs to. FK to `DWH_dbo.Dim_Country.CountryID`. Sourced from `Dictionary.RegionName.CountryID` (the RegionName side of the join). Used for country-level geographic aggregation. (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| 3 | ShortName | nvarchar(50) | YES | Short alphanumeric region code used by IP geolocation providers. Examples: "CA", "NY", "64". This is the code that matched `Dictionary.RegionByIP.Name` in the ETL join condition. Used for cross-referencing with geolocation provider outputs. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 4 | Name | nvarchar(50) | YES | Full human-readable geographic name of the region — state, province, or territory. Sourced from `Dictionary.RegionName.Name`. Examples: "California", "New York", "Ontario". Used in reporting to display readable geographic labels. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RegionByIP_ID | etoro.Dictionary.RegionByIP | RegionByIP_ID | Passthrough (JOIN driver key) |
| CountryID | etoro.Dictionary.RegionName | CountryID | Passthrough |
| ShortName | etoro.Dictionary.RegionName | ShortName | Passthrough (also the JOIN condition with RegionByIP.Name) |
| Name | etoro.Dictionary.RegionName | Name | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.RegionByIP (etoroDB-REAL, 4,206 rows)
  + etoro.Dictionary.RegionName (full region names)
  |
  v [INNER JOIN on rei.Name = ren.ShortName AND rei.CountryID = ren.CountryID]
  |
  v [Generic Pipeline — daily, Override]
DWH_staging.etoro_Dictionary_RegionByIP + DWH_staging.etoro_Dictionary_RegionName
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT (JOIN result)]
DWH_dbo.Dim_State_and_Province (181 rows — inner join subset)
```

| Step | Object | Description |
|------|--------|-------------|
| Source A | etoro.Dictionary.RegionByIP | 4,206 IP region codes |
| Source B | etoro.Dictionary.RegionName | Full geographic names per country/shortcode |
| Lake | Bronze/etoro/Dictionary/RegionByIP/, RegionName/ | Daily full exports |
| Staging | DWH_staging.etoro_Dictionary_RegionByIP + etoro_Dictionary_RegionName | Raw staging imports |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT with INNER JOIN; 181 rows result |
| Target | DWH_dbo.Dim_State_and_Province | 181 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RegionByIP_ID | etoro.Dictionary.RegionByIP | Primary production source |
| CountryID | DWH_dbo.Dim_Country | Country dimension for geographic rollup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | RegionByIP_ID | Customer's detected IP region at registration |

---

## 7. Sample Queries

### 7.1 List all states/provinces

```sql
SELECT RegionByIP_ID, CountryID, ShortName, Name
FROM [DWH_dbo].[Dim_State_and_Province]
ORDER BY CountryID, Name
```

### 7.2 Customer count by state/province (US example)

```sql
SELECT
    sp.Name AS StateName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_State_and_Province] sp
    ON dc.RegionByIP_ID = sp.RegionByIP_ID
JOIN [DWH_dbo].[Dim_Country] c
    ON sp.CountryID = c.CountryID
WHERE c.CountryName = 'United States'
GROUP BY sp.Name
ORDER BY CustomerCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT COUNT(*) AS RowCount, MAX(UpdateDate) AS LastUpdate
FROM [DWH_dbo].[Dim_State_and_Province]
-- RowCount should be ~181; LastUpdate should be today
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4-Inferred | Elements: 9.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 7.5/10*
*Object: DWH_dbo.Dim_State_and_Province | Type: Table | Production Source: etoro.Dictionary.RegionByIP + etoro.Dictionary.RegionName*


### Upstream `DWH_dbo.Dim_Funnel` — synapse
- **Resolved as**: `DWH_dbo.Dim_Funnel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Funnel.md`

# DWH_dbo.Dim_Funnel

> Acquisition funnel dimension - maps funnel IDs to the channel or product surface through which eToro customers registered, with platform classification. Used in customer, deposit, and action analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Funnel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Funnel` is an acquisition channel dimension mapping 129 funnel IDs (range -9 to 130) to the registration surface or product entry point through which an eToro customer first arrived. Funnels represent web pages, mobile apps, partner sites, and internal tools.

**FunnelID=-9 (AutomationTest)** and **FunnelID=0 (Unknown)** are special sentinel values. SP_Dim_Customer uses `ISNULL(FunnelID, 0)` coercing NULLs to 0 (Unknown).

`PlatformID` classifies the broad channel:
- 0 = Unspecified/internal (AutomationTest, Unknown, Sit&Play, Mobile generic, BackOffice, etc.)
- 1 = Web (eToro Client, Web Trader, Web Registration, Open Book, Cashier, eToro Website, etc.)
- 2 = iOS (iOS eToro Trader)
- 3 = Android (Android eToro Trader, Android Trade Alerts)

The dimension is actively consumed by `Dim_Customer` (registration funnel for each customer), `Fact_BillingDeposit` (funnel at deposit time), and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Funnel Channel Classification

**What**: Funnels represent the specific registration or entry channel for a customer. PlatformID provides a coarser platform grouping.

**Columns Involved**: `FunnelID`, `Name`, `PlatformID`

**Rules**:
- Web funnels (PlatformID=1): "eToro Client", "Web Trader", "Web Registration", "Open Book", "Cashier", "eToro Website", "Landing Page", "eToroUSA Website", "eToroPartners Website"
- iOS funnels (PlatformID=2): "iOS eToro Trader"
- Android funnels (PlatformID=3): "Android eToro Trader", "Android Trade Alerts"
- Unspecified/internal (PlatformID=0): "AutomationTest" (FunnelID=-9), "Unknown" (FunnelID=0), "Mobile" (generic), "BackOffice", "Copy.me", "Sit & Play"

**Key funnels observed**:
```
-9  | AutomationTest          | 0 (internal test)
0   | Unknown                 | 0 (null sentinel)
1   | eToro Client            | 1 (web)
2   | Web Trader              | 1 (web)
3   | Web Registration        | 1 (web)
6   | Mobile                  | 0 (generic mobile)
15  | Android eToro Trader    | 3 (Android)
17  | iOS eToro Trader        | 2 (iOS)
18  | eToroUSA Website        | 1 (web, US market)
19  | eToroPartners Website   | 1 (web, partners)
```

### 2.2 Null-Sentinel Pattern

**What**: FunnelID=0 (Unknown) serves as a null-safe join target.

**Columns Involved**: `FunnelID`

**Rules**:
- SP_Dim_Customer uses `ISNULL(FunnelID, 0) AS FunnelID` to coerce NULLs to 0 before load
- SP_Dim_Customer change detection: `OR ISNULL(dc.FunnelID,0) <> ISNULL(a.FunnelID,0)`
- Fact tables with FunnelID=0 represent customers/transactions where the registration channel is unknown

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (129 rows - appropriate). HEAP index - full scans on all lookups, negligible impact at 129 rows. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 129 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FunnelID to funnel name | `LEFT JOIN DWH_dbo.Dim_Funnel ON FunnelID` |
| Group by platform (Web/iOS/Android) | `GROUP BY PlatformID` with CASE decode |
| Exclude automation/unknown funnels | `WHERE FunnelID > 0` |
| Count customers by acquisition funnel | `JOIN Dim_Customer ON FunnelID GROUP BY Name` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON FunnelID | Customer acquisition channel |
| DWH_dbo.Fact_BillingDeposit | ON FunnelID | Funnel context for deposits |
| DWH_dbo.Fact_CustomerAction | ON FunnelID | Funnel context for customer actions |

### 3.4 Gotchas

- **HEAP index**: Unlike most Dim_ tables with CLUSTERED INDEX, Dim_Funnel uses HEAP. Point-lookups are full scans but negligible at 129 rows.
- **FunnelID=-9 is negative**: AutomationTest has FunnelID=-9. Filters like `WHERE FunnelID > 0` correctly exclude both AutomationTest and Unknown.
- **PlatformID is unresolved**: There is no `Dim_Platform` table in DWH_dbo. PlatformID values (0-3) must be decoded manually or via Dim_PlatformType (if applicable).
- **Name not renamed**: Unlike most Dim_ tables where Name becomes XxxName (e.g., FunnelName), this column stays as `Name`.
- **StatusID hardcoded**: All rows have StatusID=1. No deactivation mechanism visible.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FunnelID | int | NO | Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. (Tier 1 — Dictionary.Funnel) |
| 2 | Name | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 — Dictionary.Funnel) |
| 3 | PlatformID | int | YES | Platform category for this funnel. 0=Unknown/Cross-platform, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. (Tier 1 — Dictionary.Funnel) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate per run). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all rows. Likely means active. No Dim_Status table in DWH to decode. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FunnelID | etoro.Dictionary.Funnel | FunnelID | passthrough |
| Name | etoro.Dictionary.Funnel | Name | passthrough |
| PlatformID | etoro.Dictionary.Funnel | PlatformID | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| StatusID | - | - | ETL-computed: hardcoded 1 |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Funnel -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Funnel -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 698) -> DWH_dbo.Dim_Funnel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Funnel | Funnel dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/Funnel/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_Funnel | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds UpdateDate/InsertDate=GETDATE(), StatusID=1. |
| Target | DWH_dbo.Dim_Funnel | 129-row REPLICATE/HEAP funnel dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | FunnelID | Customer acquisition funnel (registration channel) |
| DWH_dbo.Fact_BillingDeposit | FunnelID | Funnel context at deposit time |
| DWH_dbo.Fact_CustomerAction | FunnelID | Funnel context for customer financial actions |

---

## 7. Sample Queries

### 7.1 All active funnels by platform

```sql
SELECT FunnelID, Name,
    CASE PlatformID
        WHEN 0 THEN 'Unspecified/Internal'
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Unknown'
    END AS PlatformName
FROM DWH_dbo.Dim_Funnel
WHERE FunnelID > 0
ORDER BY PlatformID, FunnelID
```

### 7.2 Customer count by acquisition platform

```sql
SELECT
    CASE f.PlatformID
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Other'
    END AS Platform,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_Funnel f ON dc.FunnelID = f.FunnelID
WHERE dc.FunnelID > 0
GROUP BY f.PlatformID
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 3 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Funnel | Type: Table | Production Source: etoro.Dictionary.Funnel*


### Upstream `DWH_dbo.Dim_Platform` — synapse
- **Resolved as**: `DWH_dbo.Dim_Platform`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Platform.md`

# DWH_dbo.Dim_Platform

> Lookup table defining the 4 client access platform types (Undefined, Web, IOS, Android) used to tag customer actions and sessions with their originating device platform.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Platform |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlatformID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_Platform is a 4-row dictionary defining the device and application platforms from which customers access the eToro trading application. Every user session, trade, and interaction is tagged with a platform identifier to enable per-platform analytics, feature flagging, and UX customization. Platform determines which features are available (some are web-only or mobile-only), which UI is rendered, and which API endpoints are called.

The data originates from `etoro.Dictionary.Platform` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/Platform/` in the data lake. In production, the PK column is named `Id`; the DWH ETL renames it to `PlatformID`.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_Platform`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale due to known schema-wide ETL disruption.

**Note**: No DWH SPs other than SP_Dictionaries_DL_To_Synapse were found referencing this table in the SSDT repo. This dimension may be lightly used or orphaned within the current DWH batch of documented tables -- confirm consumer SPs when Dim_Customer and Fact tables are available for cross-reference.

---

## 2. Business Logic

### 2.1 Multi-Platform Access Classification

**What**: Classifies each user session or action by the device/app platform from which it originated.

**Columns Involved**: `PlatformID`, `Platform`

**Rules**:
- **ID=0 (Undefined)** -- Platform not detected or not applicable. Used for server-side operations, API calls without user-agent context, or legacy records before platform tracking was added.
- **ID=1 (Web)** -- Browser-based access. Full feature set, desktop-optimized trading interface.
- **ID=2 (IOS)** -- Apple iOS native app. Mobile-optimized trading, push notifications, Face ID authentication.
- **ID=3 (Android)** -- Google Android native app. Mobile-optimized trading, push notifications, biometric authentication.
- Feature flags can be platform-specific (e.g., a feature rolled out to iOS before Android).

**Diagram**:
```
Platform Types
  0 = Undefined (server-side / platform detection failed)
  1 = Web       (browser -- desktop or mobile browser)
  2 = IOS       (Apple native app -- iPhone/iPad)
  3 = Android   (Google native app)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `PlatformID`. With only 4 rows, REPLICATE is optimal -- every compute node holds a full copy, making JOIN operations zero-shuffle-cost. Always join on `PlatformID`.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform`. With 4 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does a PlatformID mean? | JOIN Dim_Platform ON PlatformID for the label |
| Platform split of customer actions | GROUP BY PlatformID with this dim for labels |
| Mobile vs Web breakdown | Group IDs 2+3 as "Mobile", ID 1 as "Web", ID 0 as "Undefined" |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer (when available) | ON dc.PlatformID = dp.PlatformID | Resolve platform label per customer (confirm column name in Dim_Customer) |
| Fact tables referencing PlatformID | ON ft.PlatformID = dp.PlatformID | Resolve platform label in fact-level analytics |

### 3.4 Gotchas

- **Column rename**: Production table has `Id` (not `PlatformID`). The DWH ETL renames it during load (`SELECT [Id] AS PlatformID`). Do not query production using `PlatformID` -- it won't exist.
- **ID=0 exists**: The table has an ID=0 row (Undefined). Standard INNER JOIN is safe but may exclude undefined records from counts.
- **Potentially orphaned**: Only SP_Dictionaries_DL_To_Synapse was found referencing this table in the current SSDT scan. Verify active consumer SPs when Fact tables are documented.
- **Note: Distinct from Dim_PlatformType**: Dim_PlatformType (13 rows, batch 5) is a legacy migration table covering historical platform categories. Dim_Platform (4 rows) is the actively ETL'd production dictionary. They serve different purposes.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.Platform) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlatformID | int | YES | DWH platform identifier. 0=Undefined, 1=Web, 2=IOS, 3=Android. Renamed from `Id` in the production source (etoro.Dictionary.Platform) by the DWH ETL. Referenced by session and action tracking tables to indicate the originating device platform. DWH note: column renamed from production `Id` to `PlatformID` during TRUNCATE+INSERT load. (Tier 1 - upstream wiki, Dictionary.Platform) |
| 2 | Platform | nvarchar(20) | YES | Platform name label: "Undefined", "Web", "IOS", "Android". Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name. (Tier 1 - upstream wiki, Dictionary.Platform) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlatformID | etoro.Dictionary.Platform | Id | rename (Id -> PlatformID) |
| Platform | etoro.Dictionary.Platform | Platform | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.Platform.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.Platform
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/Platform/
  -> DWH_staging.etoro_Dictionary_Platform
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT; Id -> PlatformID rename)
  -> DWH_dbo.Dim_Platform
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Platform | Production platform dictionary (etoroDB-REAL) -- PK column is `Id` |
| Lake | Bronze/etoro/Dictionary/Platform/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_Platform | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; renames `Id` to `PlatformID` and overrides UpdateDate to GETDATE() |
| Target | DWH_dbo.Dim_Platform | 4-row enum lookup, REPLICATE distributed |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo (pending tables) | PlatformID | Platform label resolution in customer and fact tables -- confirm when Dim_Customer and Fact tables are documented |

---

## 7. Sample Queries

### 7.1 List all platform types

```sql
SELECT PlatformID,
       Platform
FROM   [DWH_dbo].[Dim_Platform]
ORDER BY PlatformID;
```

### 7.2 Mobile vs Web breakdown (analytical grouping)

```sql
SELECT  CASE dp.PlatformID
            WHEN 1 THEN 'Web'
            WHEN 2 THEN 'Mobile (iOS)'
            WHEN 3 THEN 'Mobile (Android)'
            ELSE 'Undefined'
        END            AS PlatformGroup,
        dp.Platform,
        dp.PlatformID
FROM    [DWH_dbo].[Dim_Platform] dp
ORDER BY dp.PlatformID;
```

### 7.3 Resolve PlatformID in a fact table (template)

```sql
-- Replace FactTable and PlatformID_col with the actual table and column name
SELECT  ft.*,
        dp.Platform
FROM    [DWH_dbo].[SomeFactTable] ft
LEFT JOIN [DWH_dbo].[Dim_Platform] dp
        ON ft.PlatformID = dp.PlatformID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.6/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Platform | Type: Table | Production Source: etoro.Dictionary.Platform*


### Upstream `DWH_dbo.Dim_Affiliate` — synapse
- **Resolved as**: `DWH_dbo.Dim_Affiliate`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Affiliate.md`

# DWH_dbo.Dim_Affiliate

> Denormalized affiliate partner dimension — combines AffWizz affiliate profile, channel/sub-channel classification, trading account linkage, and aggregated registration/FTD/FTDe metrics across multiple time windows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Row Count** | Low thousands (one row per affiliate partner) |
| **Production Source** | `fiktivo_dbo.tblaff_Affiliates` (AffWizz) via `Ext_Dim_Channel_Affiliate_UnifyCode` |
| **Refresh** | Daily full reload (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (AffiliateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` |
| **UC Target (PII)** | `pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate` |
| **UC Masked Columns** | Email,City |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Affiliate` is the master dimension for eToro's affiliate marketing partners. Each row represents one affiliate partner (identified by `AffiliateID`), combining:

- **Profile data** from the AffWizz affiliate management system (contact, company, website, login credentials)
- **Channel classification** (SubChannel, Channel) from the unified channel mapping
- **Trading account linkage** — resolving up to 4 username variants to find the affiliate's own eToro trading account
- **Performance aggregates** — Registration, FTD (First Time Deposit), and FTDe (First Time Deposit equivalent) counts across 7 time windows each (Yesterday, ThisMonth, LastMonth, ThisQuarter, LastQuarter, ThisYear, LastYear, Lifetime)
- **Contract classification** — affiliate payment model derived from ContractName keywords

The table answers: "Who is this affiliate, how are they classified, what contract do they have, and what are their referral performance metrics?"

### Key Business Concepts

- **FTD vs FTDe**: FTD = First Time Deposit (real money). FTDe = First Time Deposit equivalent (includes demo-to-real conversions or other qualifying events)
- **SubChannel/Channel**: Marketing classification inherited from `Ext_Dim_SubChannel_UnifyCode` — same logic as `Dim_Channel` (see Dim_Channel.md)
- **MasterAffiliateID**: Hierarchical relationship — some affiliates operate under a master affiliate umbrella
- **ContractType**: Numerically encoded payment model (0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=0-Commission, 8=CPL/CPR)

---

## 2. Business Logic

### 2.1 ContractType Classification

**What**: Derives the affiliate payment model from the free-text `ContractName` field.

**Columns Involved**: ContractType, ContractName, AffiliateID, Channel

**Rules** (evaluated in order, first match wins):
```
AffiliateID IN (12306, 14596, 30122, 37665, 18230) → 6 (eCost — hardcoded overrides)
ContractName LIKE '%internal campaigns%'             → 6 (eCost)
ContractName LIKE '%rev%' AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpa%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpl%'                → 4 (Hybrid)
ContractName LIKE '%rev%' AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rs%'  AND '%cpr%'                → 4 (Hybrid)
ContractName LIKE '%rev%'                            → 3 (RevShare)
ContractName LIKE '%rs%'                             → 3 (RevShare)
ContractName LIKE '%cpa%'                            → 2 (CPA)
ContractName LIKE '%plan%'                           → 2 (CPA)
ContractName LIKE '%mati%' AND '%cpl%'               → 8 (CPL)
ContractName LIKE '%mati%' AND '%%%'                 → 3 (RevShare)
ContractName LIKE '%cpl%'                            → 8 (CPL)
ContractName LIKE '%cpr%'                            → 8 (CPR)
Channel = 'Affiliate' AND ContractName LIKE '%0 commission%' → 7 (Zero Commission)
ELSE                                                 → 0 (N/A)
```

### 2.2 Trading Account Resolution

**What**: Links affiliate to their own eToro trading account using COALESCE across 4 username lookups.

**Columns Involved**: TradingAccount_RealCID, TradingAccount_UserName

**Rules**:
```
TradingAccount_RealCID = COALESCE(BO1.CID, BO2.CID, BO3.CID, BO4.CID)
TradingAccount_UserName = COALESCE(BO1.UserName, BO2.UserName, BO3.UserName, BO4.UserName)

Where BO1..BO4 = Ext_Dim_Affiliate_Customer joined on UserName1..UserName4
Collation: Latin1_General_BIN (case-sensitive, binary comparison)
```

### 2.3 SubChannel/Channel Inheritance

**What**: SubChannelID, SubChannel, and Channel are inherited from `Ext_Dim_SubChannel_UnifyCode`, joined on AffiliateID.

**Logic**: Same unified classification as Dim_Channel — see `Dim_Channel.md` for the full SubChannelID-to-Channel mapping rules.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is `REPLICATE` — a full copy exists on every compute node. JOINs with fact tables (which are typically HASH-distributed) will always use local data. The CLUSTERED INDEX on AffiliateID supports equality lookups and range scans.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliate performance summary | `SELECT * FROM Dim_Affiliate WHERE AffiliateID = @id` |
| All affiliates in a channel | `WHERE Channel = 'Affiliate'` or `Channel = 'Organic'` |
| Active affiliates | `WHERE AccountActivated = 1` |
| Hierarchy — sub-affiliates | `WHERE MasterAffiliateID = @masterAffId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Channel | ON SubChannelID = SubChannelID | Channel attributes (but Dim_Affiliate already has SubChannel/Channel) |
| DWH_dbo.Dim_Customer | ON AffiliateID = AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Affiliate country name |
| DWH_dbo.Fact_AffiliateCommission | ON AffiliateID = AffiliateID | Commission payments |

### 3.4 Gotchas

- **Masked columns**: `Email` and `City` are masked with `default()` — users without UNMASK permission see obfuscated values
- **ContractType is computed**: Derived from ContractName pattern matching. Not a source value. If ContractName doesn't match any rule → 0 (N/A)
- **TradingAccount_RealCID can be NULL**: If none of the 4 username variants resolve to an eToro user
- **Registration/FTD metrics are pre-aggregated**: These are period-level counts, not row-level data. They come from separate staging tables (`Ext_Dim_Affiliate_Registrations`, `Ext_Dim_Affiliate_FTD`, `Ext_Dim_Affiliate_FTDe`)

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | NO | Unique affiliate partner identifier from AffWizz system. Primary key. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 2 | DateCreated | datetime | NO | Date the affiliate was created/registered in AffWizz. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 3 | SubChannelID | tinyint | NO | Marketing sub-channel identifier. JOINs to Dim_Channel.SubChannelID. Values: 1=Affiliate Partners, 2=SEM, 3=SEO, etc. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 4 | Contact | nvarchar(1000) | YES | Primary contact information for the affiliate partner. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 5 | ContractName | nvarchar(100) | YES | Free-text name of the affiliate's contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 6 | ContractType | tinyint | YES | Computed affiliate payment model: 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Derived from ContractName via CASE expression. (Tier 2 — SP_Dim_Affiliate) |
| 7 | AffiliatesGroupsName | nvarchar(50) | YES | Marketing group the affiliate belongs to. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 8 | AccountActivated | bit | YES | Whether the affiliate account is active. 1=Active, 0/NULL=Inactive. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 9 | LoginName | nvarchar(1000) | YES | Affiliate's login name in the AffWizz system. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 10 | TradingAccount_RealCID | bigint | YES | Affiliate's own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. (Tier 2 — SP_Dim_Affiliate) |
| 11 | TradingAccount_UserName | varchar(50) | YES | eToro username that matched for the affiliate's trading account. First non-NULL from 4 UserName variants. (Tier 2 — SP_Dim_Affiliate) |
| 12 | Email | nvarchar(255) | YES | Affiliate's email address. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 13 | CompanyAddress | nvarchar(255) | YES | Affiliate's company street address. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 14 | City | nvarchar(255) | YES | Affiliate's city. **MASKED** with default() — requires UNMASK permission. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 15 | CountryID | int | YES | Affiliate's country. JOINs to Dim_Country.CountryID. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 16 | WebSiteURL | nvarchar(255) | YES | Affiliate's website URL used for referral traffic. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 17 | RegistrationFirstDate | datetime | YES | Date of the affiliate's first referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 18 | RegistrationLastDate | datetime | YES | Date of the affiliate's most recent referred registration. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 19 | RegistrationLifeTime | int | YES | Total registrations referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 20 | RegistrationYesterday | int | YES | Registrations referred yesterday. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 21 | RegistrationLastMonth | int | YES | Registrations referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 22 | RegistrationLastQuarter | int | YES | Registrations referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 23 | RegistrationLastYear | int | YES | Registrations referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 24 | FTDFirstDate | datetime | YES | Date of the affiliate's first referred FTD (First Time Deposit). (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 25 | FTDLastDate | datetime | YES | Date of the most recent referred FTD. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 26 | FTDLifeTime | int | YES | Total FTDs referred by this affiliate, all time. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 27 | FTDYesterday | int | YES | FTDs referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 28 | FTDLastMonth | int | YES | FTDs referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 29 | FTDLastQuarter | int | YES | FTDs referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 30 | FTDLastYear | int | YES | FTDs referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 31 | FTDeFirstDate | datetime | YES | Date of the affiliate's first referred FTDe (FTD equivalent — includes qualifying non-deposit events). (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 32 | FTDeLastDate | datetime | YES | Date of the most recent referred FTDe. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 33 | FTDeLifeTime | int | YES | Total FTDe events referred all time. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 34 | FTDeYesterday | int | YES | FTDe events referred yesterday. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 35 | FTDeLastMonth | int | YES | FTDe events referred last calendar month. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 36 | FTDeLastQuarter | int | YES | FTDe events referred last calendar quarter. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 37 | FTDeLastYear | int | YES | FTDe events referred last calendar year. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 38 | MasterAffiliateID | int | YES | Parent/master affiliate in the hierarchy. NULL if this is a standalone or top-level affiliate. JOINs to Dim_Affiliate.AffiliateID (self-reference). (Tier 2 — Ext_Dim_Affiliate_MasterAffiliate) |
| 39 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() during SP_Dim_Affiliate execution. (Tier 2 — SP_Dim_Affiliate) |
| 40 | RegistrationThisMonth | int | YES | Registrations referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 41 | RegistrationThisQuarter | int | YES | Registrations referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 42 | RegistrationThisYear | int | YES | Registrations referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_Registrations) |
| 43 | FTDeThisMonth | int | YES | FTDe events referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 44 | FTDeThisQuarter | int | YES | FTDe events referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 45 | FTDeThisYear | int | YES | FTDe events referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTDe) |
| 46 | FTDThisMonth | int | YES | FTDs referred current calendar month to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 47 | FTDThisQuarter | int | YES | FTDs referred current calendar quarter to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 48 | FTDThisYear | int | YES | FTDs referred current calendar year to date. (Tier 2 — Ext_Dim_Affiliate_FTD) |
| 49 | LanguageName | nvarchar(255) | YES | Affiliate's preferred language. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 50 | WebSiteTitle | nvarchar(256) | YES | Title/name of the affiliate's website. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 51 | GCID | int | YES | Global Customer ID linking the affiliate to the eToro customer graph. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 52 | EntityName | nvarchar(510) | YES | Legal entity name for the affiliate company. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 53 | ContactPersonFullName | nvarchar(510) | YES | Full name of the affiliate's primary contact person. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 54 | Telephone | nvarchar(50) | YES | Affiliate contact phone number. (Tier 2 — Ext_Dim_Channel_Affiliate_UnifyCode) |
| 55 | SubChannel | nvarchar(50) | NO | Marketing sub-channel name (e.g., "Affiliate Partners", "SEM Brand"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |
| 56 | Channel | nvarchar(50) | NO | Top-level marketing channel (e.g., "Paid", "Organic", "Affiliate"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 — SP_Dim_Affiliate) |

---

## 5. Lineage

### 5.1 Source Architecture

```
fiktivo_dbo (AffWizz staging tables)
    │
    ├─ SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse
    │   → Ext_Dim_Channel_Affiliate_UnifyCode (base affiliate profile)
    │   → Ext_Dim_SubChannel_UnifyCode (channel classification)
    │
    ├─ Ext_Dim_Affiliate_Customer (trading account lookups)
    ├─ Ext_Dim_Affiliate_Registrations (registration metrics)
    ├─ Ext_Dim_Affiliate_FTD (FTD metrics)
    ├─ Ext_Dim_Affiliate_FTDe (FTDe metrics)
    └─ Ext_Dim_Affiliate_MasterAffiliate (hierarchy)
         │
         └─ SP_Dim_Affiliate → Dim_Affiliate
```

### 5.2 Staging Table Sources

| Staging Table | Role | Join Key |
|--------------|------|----------|
| Ext_Dim_Channel_Affiliate_UnifyCode | Base profile, contact, company data | AffiliateID (base) |
| Ext_Dim_SubChannel_UnifyCode | SubChannelID, SubChannel, Channel, DateCreated | AffiliateID |
| Ext_Dim_Affiliate_Customer (×4) | TradingAccount_RealCID, TradingAccount_UserName | UserName1..4 (COLLATE Latin1_General_BIN) |
| Ext_Dim_Affiliate_Registrations | Registration metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTD | FTD metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_FTDe | FTDe metrics (7 time windows) | AffiliateID |
| Ext_Dim_Affiliate_MasterAffiliate | MasterAffiliateID | AffiliateID |

---

## 6. Relationships

### 6.1 References To (this table points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| SubChannelID | DWH_dbo.Dim_Channel | Channel dimension (implicit FK) |
| CountryID | DWH_dbo.Dim_Country | Affiliate's country |
| MasterAffiliateID | DWH_dbo.Dim_Affiliate | Self-reference: parent affiliate |
| GCID | DWH_dbo.Dim_Customer | Affiliate as customer (implicit FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Key | Description |
|--------------|----------|-------------|
| DWH_dbo.Dim_Customer | AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Fact_AffiliateCommission | AffiliateID | Commission payments |
| DWH_dbo.Dim_Channel | SubChannelID (shared) | Same channel classification |

---

## 7. Sample Queries

### 7.1 Top affiliates by lifetime FTDs

```sql
SELECT TOP 20
    a.AffiliateID,
    a.EntityName,
    a.ContractName,
    a.Channel,
    a.SubChannel,
    a.FTDLifeTime,
    a.RegistrationLifeTime,
    CASE WHEN a.RegistrationLifeTime > 0
         THEN CAST(a.FTDLifeTime AS FLOAT) / a.RegistrationLifeTime
         ELSE 0 END AS ConversionRate
FROM DWH_dbo.Dim_Affiliate a
WHERE a.AccountActivated = 1
ORDER BY a.FTDLifeTime DESC;
```

### 7.2 Affiliate hierarchy

```sql
SELECT
    child.AffiliateID,
    child.EntityName AS ChildEntity,
    master.AffiliateID AS MasterID,
    master.EntityName AS MasterEntity
FROM DWH_dbo.Dim_Affiliate child
JOIN DWH_dbo.Dim_Affiliate master ON child.MasterAffiliateID = master.AffiliateID
ORDER BY master.AffiliateID, child.AffiliateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key knowledge extracted |
|--------|------|-------------------------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | AffWizz / affiliate platform overview: registration links with affiliate id + campaign query strings; sub-affiliate hierarchy (up to 5 levels); Fiktivo as hosting context — aligns with `AffiliateID`, campaign-style identifiers, and `MasterAffiliateID`. |
| [Affiliate - Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541/Affiliate+-Data+migration) | Confluence | Documents migration of affiliate commission data from legacy fiktivo tables — confirms `fiktivo` DB as the system of record for affiliate entities that feed DWH staging. |
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Lists `fiktivo.dbo.tblaff_*` (e.g. `tblaff_Affiliates`, `tblaff_MarketingExpense`, `tblaff_AffiliatesGroups`, `tblaff_AffiliateTypes`) as DWH pipeline sources — matches `Dim_Affiliate` lineage. |
| [PI As Affiliate](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13178109958/PI+As+Affiliate) | Confluence | Partners Portal proxies Affiliate API; notes use of existing SPs against Fiktivo DB — supports interpretation of affiliate profile and trading-account linkage fields as AffWizz/Fiktivo-sourced. |
| [Affiliates Compliance Review and Monitoring Procedure 2026](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/1593278467/Affiliates+Compliance+Review+and+Monitoring+Procedure+2026) | Confluence | Operational context: AffWizz login, search by Affiliate ID — mirrors `AffiliateID` as the operational key. |

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable; P10 Atlassian refresh)*
*Tiers: 0 T1, 56 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Affiliate | Type: Table | Production Source: fiktivo_dbo.tblaff_Affiliates (AffWizz)*


### Upstream `DWH_dbo.Dim_Channel` — synapse
- **Resolved as**: `DWH_dbo.Dim_Channel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md`

# DWH_dbo.Dim_Channel

> Marketing acquisition channel and sub-channel classification dimension, mapping affiliate traffic sources to a standardized channel taxonomy with an Organic/Paid split.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | fiktivo_dbo.tblaff_Affiliates (AffWizz affiliate system) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (SubChannelID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel` |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_Channel is the marketing acquisition channel dimension for eToro's DWH. It classifies every affiliate sub-channel into a standardized channel hierarchy with an Organic vs. Paid indicator. Each row represents a unique sub-channel (e.g., "Google Brand", "FB", "Taboola") mapped to a parent channel (e.g., "SEM", "Direct", "Affiliate"). The Organic/Paid flag enables marketing analysts to split spend and attribution without re-deriving the classification.

The data originates from the AffWizz affiliate management system (fiktivo database). The production source tables are `fiktivo_dbo.tblaff_Affiliates` joined with `fiktivo_dbo.tblaff_MarketingExpense` and `fiktivo_dbo.tblaff_AffiliatesGroups`. There is no upstream production wiki — AffWizz is an external affiliate platform with no semantic documentation in the DB_Schema repository. All column descriptions are derived from ETL SP code analysis (Tier 2).

The table is loaded daily via a two-step ETL chain: `SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse` (builds the raw affiliate-to-subchannel mapping via a massive CASE expression with 30+ sub-channel types) → `SP_Dim_Channel` (deduplicates and applies the Organic/Paid classification). Both steps use TRUNCATE + INSERT (full reload).

---

## 2. Business Logic

### 2.1 Sub-Channel Classification (SubChannelID Mapping)

**What**: Each affiliate is classified into one of ~30 sub-channel types based on the affiliate's Channel (from MarketingExpense) and the Contact string (campaign identifier).

**Columns Involved**: `SubChannelID`, `SubChannel`, `Channel`

**Rules**:
- SubChannelID is NOT a production FK — it is a DWH-derived classification computed via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse
- The mapping parses the affiliate Contact string (lowercased) to detect platforms: `sem.facebook%` → FB (32), `%taboola%` → Taboola (33), `sem.twitter%` → Twitter (34), `%outbrain%` → Outbrain (35)
- Google sub-channels are further split: Brand (4), Search (5), UAC (38), Discovery (50), GDN → SEM Other (11)
- SubChannelID=0 = "Unknown" (unmapped affiliates)
- Introducing Agents channel is reclassified to "Affiliate" at the Channel level

**Diagram**:
```
AffWizz MarketingExpense.Channel
  ├── Direct ─────────────► Direct (19) / Direct Mobile (1) / SMM (18)
  ├── SEM ────────────────► Google Brand (4) / Google Search (5) / FB (32) /
  │                         Taboola (33) / Twitter (34) / Outbrain (35) /
  │                         Bing Search (37) / Google UAC (38) / YT (22) /
  │                         ASA (36) / Discovery (50) / TikTok (51) / SEM Other (11)
  ├── SEO ────────────────► SEO (21)
  ├── Affiliate ──────────► Affiliate (31)
  ├── Introducing Agents ─► IBs (20) [Channel overridden to "Affiliate"]
  ├── Mobile Acquisition ─► Mobile CPA (40) / Mobile Non-CPA (39)
  ├── Media Programmatic ─► Media Programmatic (41)
  ├── Media CPA ──────────► Media CPA (45)
  ├── Media Performance ──► Media Performance (42)
  ├── Content Partnerships ► Content Partnerships (44)
  ├── Friend Referral ────► Friend Referral (43)
  ├── TV ─────────────────► TV (48)
  ├── Social Organic ─────► Social Organic (49)
  ├── Sponsorships ───────► Sponsorships (27)
  ├── OOH ────────────────► OOH (26)
  ├── PR ─────────────────► PR (24)
  ├── Events ─────────────► Events (25)
  ├── Club ───────────────► Club (29)
  ├── Productions ────────► Productions (30)
  ├── systems ────────────► systems (28)
  ├── Affiliate Branding ─► Affiliate Branding (52)
  └── (unmapped) ─────────► Unknown (0)
```

### 2.2 Organic/Paid Classification

**What**: A binary marketing spend classification applied on top of the Channel hierarchy.

**Columns Involved**: `Organic/Paid`

**Rules**:
- "Organic" if Channel IN ('Friend Referral', 'Direct', 'SEO')
- "Organic" if SubChannel = 'Google Brand' (brand searches treated as organic despite being SEM)
- All other channels = "Paid"
- This classification is computed in SP_Dim_Channel (second ETL step), NOT in the upstream source

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses ROUND_ROBIN distribution with a CLUSTERED INDEX on `SubChannelID`. The table is small (estimated ~50 rows) so distribution strategy has minimal performance impact. It is frequently JOINed via SubChannelID from Dim_Customer, Dim_Affiliate, and Fact_CustomerAction.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All organic channels | `WHERE [Organic/Paid] = 'Organic'` — note the special column name requires brackets |
| Customers by marketing channel | JOIN Dim_Customer ON SubChannelID = SubChannelID, GROUP BY Channel |
| SEM platform breakdown | `WHERE Channel = 'SEM'`, then GROUP BY SubChannel |
| FTD attribution by channel | JOIN Fact_CustomerAction (ActionTypeID=14 for FTD) ON SubChannelID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Channel.SubChannelID = Dim_Customer.SubChannelID | Resolve customer acquisition channel |
| DWH_dbo.Dim_Affiliate | ON Dim_Channel.SubChannelID = Dim_Affiliate.SubChannelID | Link affiliate to its channel classification |
| DWH_dbo.Fact_CustomerAction | ON Dim_Channel.SubChannelID = Fact_CustomerAction.SubChannelID | Channel attribution for customer events |

### 3.4 Gotchas

- **Column name with special character**: The `Organic/Paid` column contains a forward slash — always use square brackets `[Organic/Paid]` in queries
- **SubChannelID=0 = Unknown**: Unmapped affiliates get ID=0. Use LEFT JOIN or handle 0 explicitly in analytics
- **ROUND_ROBIN on a small table**: Consider that this table should likely be REPLICATE for better JOIN performance, but the current ROUND_ROBIN works given the tiny row count
- **Google Brand is Organic**: Despite being an SEM (paid search) sub-channel, Google Brand queries are classified as "Organic" — this is an intentional business decision, not a bug
- **Introducing Agents → Affiliate**: At the Channel level, "Introducing Agents" is overridden to "Affiliate", but SubChannel remains "IBs" (20)
- **No SubChannelID=0 row**: The SP filters `WHERE SubChannelID != 0`, so the sentinel row is excluded from the final table. Unknown affiliates have no matching dim row — use LEFT JOIN

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| ★★★★★ | Tier 5 — domain expert | `(Tier 5 — domain expert)` |
| ★★★★☆ | Tier 1 — upstream wiki | `(Tier 1 — upstream wiki)` |
| ★★★☆☆ | Tier 2 — SP code | `(Tier 2 — SP code)` |
| ★★☆☆☆ | Tier 3 — live data / DDL | `(Tier 3 — DDL)` |
| ★☆☆☆☆ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SubChannelID | int | NO | Primary key. DWH-derived sub-channel identifier assigned via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse. Maps affiliate contact strings to ~30 standardized sub-channel categories (e.g., 4=Google Brand, 5=Google Search, 32=FB, 33=Taboola). NOT a production FK — computed entirely in DWH ETL. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 2 | Channel | nvarchar(50) | NO | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' → 'Affiliate', AffiliateID IN (56662,56663) → 'Direct'. Common values: Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 3 | SubChannel | varchar(100) | NO | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Taboola', 'Twitter', 'Outbrain', 'Bing Search', 'Direct', 'SEO', 'Affiliate', 'IBs'. Derived via parallel CASE expression alongside SubChannelID. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 4 | Organic/Paid | varchar(7) | YES | Binary marketing spend classification. 'Organic' for channels Friend Referral, Direct, SEO, and Google Brand. 'Paid' for all others. Computed in SP_Dim_Channel (second ETL step). Note: column name contains a slash — requires square brackets in queries. (Tier 2 — SP_Dim_Channel) |
| 5 | InsertDate | datetime | YES | ETL metadata: timestamp when this row was first inserted by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. (Tier 2 — SP_Dim_Channel) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. Same as InsertDate since table is TRUNCATE+INSERT. (Tier 2 — SP_Dim_Channel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| SubChannelID | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName, AffiliatesGroupsName | CASE expression mapping 30+ patterns to integer IDs |
| Channel | fiktivo_dbo.tblaff_MarketingExpense | MarketingExpenseName | CASE with overrides (Introducing Agents → Affiliate) |
| SubChannel | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName | Parallel CASE to SubChannelID, returns name strings |
| Organic/Paid | N/A | N/A | DWH-computed: CASE on Channel + SubChannel values |
| InsertDate | N/A | N/A | GETDATE() at ETL time |
| UpdateDate | N/A | N/A | GETDATE() at ETL time |

No upstream wiki exists for the fiktivo (AffWizz) database. All descriptions are derived from SP code analysis.

### 5.2 ETL Pipeline

```
fiktivo_dbo.tblaff_Affiliates → Generic Pipeline → DWH_staging.fiktivo_dbo_tblaff_Affiliates → SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse → Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel → Dim_Channel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense + tblaff_AffiliatesGroups + tblaff_AffiliateTypes | AffWizz affiliate management system tables |
| Lake | DWH_staging.fiktivo_dbo_tblaff_* | Staging tables from data lake export |
| ETL 1 | SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse | Joins 7 staging tables, builds Ext_Dim_Channel_Affiliate_UnifyCode, then derives SubChannelID/SubChannel/Channel via massive CASE mapping into Ext_Dim_SubChannel_UnifyCode |
| ETL 2 | SP_Dim_Channel | SELECT DISTINCT from Ext_Dim_SubChannel_UnifyCode, applies Organic/Paid CASE, TRUNCATE+INSERT into Dim_Channel |
| Target | DWH_dbo.Dim_Channel | Final marketing channel dimension |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | — | Dim_Channel has no FK references to other Dim tables |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | SubChannelID | Customer acquisition sub-channel at registration |
| DWH_dbo.Dim_Affiliate | SubChannelID | Affiliate's assigned marketing sub-channel |
| DWH_dbo.Fact_CustomerAction | SubChannelID | Sub-channel attribution for customer events |
| DWH_dbo.Fact_SnapshotCustomer | SubChannelID | Point-in-time customer sub-channel snapshot |
| DWH_dbo.V_Dim_Customer | SubChannelID | Pass-through from Dim_Customer |

---

## 7. Sample Queries

### 7.1 Marketing channel performance: FTD count by Channel and Organic/Paid split

```sql
SELECT
    dc.Channel,
    dc.[Organic/Paid],
    COUNT(DISTINCT fca.RealCID) AS FTD_Customers
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Channel dc ON dc.SubChannelID = fca.SubChannelID
WHERE fca.ActionTypeID = 14  -- First Time Deposit
  AND fca.DateID >= 20260101
GROUP BY dc.Channel, dc.[Organic/Paid]
ORDER BY FTD_Customers DESC;
```

### 7.2 Sub-channel breakdown for SEM traffic

```sql
SELECT
    dc.SubChannelID,
    dc.SubChannel,
    dc.[Organic/Paid],
    COUNT(DISTINCT cust.RealCID) AS Registered_Customers
FROM DWH_dbo.Dim_Customer cust
JOIN DWH_dbo.Dim_Channel dc ON dc.SubChannelID = cust.SubChannelID
WHERE dc.Channel = 'SEM'
GROUP BY dc.SubChannelID, dc.SubChannel, dc.[Organic/Paid]
ORDER BY Registered_Customers DESC;
```

### 7.3 All channels with their Organic/Paid classification

```sql
SELECT
    SubChannelID,
    Channel,
    SubChannel,
    [Organic/Paid]
FROM DWH_dbo.Dim_Channel
ORDER BY Channel, SubChannel;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | AffWizz system overview: sub-affiliates up to 5 levels deep, campaigns are free-text marketing identifiers |
| [Affiliate Process - Details Change](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/13254492166/Affiliate+Process+-Details+Change) | Confluence | Manual process to change affiliate marketing channel in AffWiz — confirms Channel is an editable attribute |
| [Creating an Affiliate ID](https://etoro-jira.atlassian.net/wiki/spaces/MU/pages/12032574011/Creating+an+Affiliate+ID) | Confluence | Channel chosen during affiliate onboarding depending on activity type |
| [DWH Process Failure (DWH SP Failure + Delay) - 2023-11-17](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12143165455/DWH+Process+Failure+DWH+SP+Failure+Delay+-+2023-11-17.) | Confluence | Postmortem: fix **Channel/Sub Channel** logic in the relevant SP and rerun dependent SPs — validates that channel/sub-channel classification is business-critical DWH logic (same domain as `Dim_Channel`). |
| [Affiliate Attribution - Update Affiliate ID](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12050989066/Affiliate+Attribution+-+Update+Affiliate+ID) | Confluence | Describes **organic vs non-organic** attribution rules and channel IDs (e.g. Direct vs other channels) when updating affiliate mappings — business context for Organic/Paid and channel overrides. |

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 8/14 (P2,P3 skipped — Synapse MCP unavailable; P10 Atlassian refresh)*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7.5/10*
*Object: DWH_dbo.Dim_Channel | Type: Table | Production Source: fiktivo_dbo.tblaff_Affiliates (AffWizz)*


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


### SP `BI_DB_dbo.SP_CIDFunnelFlow`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CIDFunnelFlow.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_CIDFunnelFlow] @Date [date] AS
BEGIN

--[SP_CIDFunnelFlow] '20190409'
--DECLARE @Date date = DATEADD(DAY,-1,GETDATE())



 IF OBJECT_ID('tempdb..#POP') IS NOT NULL DROP TABLE #POP
CREATE TABLE #POP  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
select 
RealCID
,DC.FunnelFromID
,DC.AffiliateID
,DC.CountryID
,case when DC.CountryID = 219 then RegionID end RegionID
,DC.IsValidCustomer
,DC.RegisteredReal
,DC.IsEmailVerified
,DC.VerificationLevelID
,DC.PlayerStatusID
,DC.EvMatchStatus
,DC.ScreeningStatusID
,DC.FirstDepositDate
,DC.DesignatedRegulationID
,DC.RegulationChangeDate
,DC.RegulationID
,case when IsIDProof =1 and IsIDProofExpiryDate >= @Date then 1 else 0 end IsIDProof
,case when IsAddressProof =1 and IsAddressProofExpiryDate >= @Date then 1 else 0 end IsAddressProof
,case when [PhoneVerifiedID] in (1,2) then 1 else 0 end IsPhoneVerified
,e.Name FunnelFrom
,f.Platform
FROM DWH_dbo.[Dim_Customer] DC with(nolock)
left join DWH_dbo.Dim_Funnel e  WITH(NOLOCK) on DC.FunnelFromID = e.FunnelID
left join DWH_dbo.Dim_Platform f  WITH(NOLOCK) on e.PlatformID = f.PlatformID
--left join [ETL_ Source].etoro_rep.[BackOffice].[Customer] cd on DC.RealCID = cd.CID
where RegisteredReal >= dateadd(month,-12,@Date)
and IsValidCustomer = 1




  IF OBJECT_ID('tempdb..#DesignatedRegulation') IS NOT NULL DROP TABLE #DesignatedRegulation
CREATE TABLE #DesignatedRegulation
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT sc1.RealCID
,sc1.DesignatedRegulationID
,min(dr1.FromDateID)DateID
from DWH_dbo.Fact_SnapshotCustomer sc1 with (NOLOCK)
join DWH_dbo.Dim_Range dr1 with (NOLOCK) on dr1.DateRangeID = sc1.DateRangeID 
join #POP P on sc1.RealCID = P.RealCID
where sc1.DesignatedRegulationID is not null and dr1.FromDateID >= CONVERT(VARCHAR(8), cast(RegisteredReal as date), 112)
group by sc1.RealCID
,sc1.DesignatedRegulationID




   IF OBJECT_ID('tempdb..#DesignatedRegulation2') IS NOT NULL DROP TABLE #DesignatedRegulation2
CREATE TABLE #DesignatedRegulation2
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
select RealCID
,DesignatedRegulationID
,DateID
,RANK() over(partition by RealCID ORDER BY DateID) rn
from #DesignatedRegulation

/*
DROP TABLE IF EXISTS #POAPOI

SELECT  
 cd.CID
,max(case when dd.DocumentTypeID =1 and ( boc.DocumentStatusID = 6 or boc.DocumentStatusID = 3) then 1 else 0 end) ProofOfAddress
,max(case when dd.DocumentTypeID =2 and ( boc.DocumentStatusID = 5 or boc.DocumentStatusID = 3) then 1 else 0 end) ProofOfIdentity
,max(case when (dd.DocumentTypeID =2 and ( boc.DocumentStatusID = 5 or boc.DocumentStatusID = 3)) and (dd.DocumentTypeID =1 and ( boc.DocumentStatusID = 6 or boc.DocumentStatusID = 3)) then 1 else 0 end) POA_POI
into #POAPOI
FROM #POP P
join [ETL_ Source].etoro_rep.[BackOffice].[CustomerDocument] cd on P.RealCID = cd.CID
JOIN [ETL_ Source].etoro_rep.[BackOffice].[CustomerDocumentToDocumentType] dd	ON cd.DocumentID = dd.DocumentID
JOIN [ETL_ Source].etoro_rep.History.BackOfficeCustomer boc ON cd.CID = boc.CID AND( boc.DocumentStatusID = 5 or boc.DocumentStatusID = 6 or boc.DocumentStatusID = 3) --5=POIApproved 6=POAApproved 3=Accepted
WHERE ( (dd.DocumentTypeID =1 and /*cd.DateAdded >= dateadd(month,-12,@Date)*/ dd.ExpiryDate>@Date)
				or
			(dd.DocumentTypeID =2 ))
group by cd.CID
*/



TRUNCATE TABLE  BI_DB_dbo.BI_DB_CIDFunnelFlow


insert into BI_DB_dbo.BI_DB_CIDFunnelFlow
(
	[RealCID]
      ,[Date]
      ,[Region]
      ,[Country]
      ,[State]
      ,[Channel]
      ,[SubChannel]
      ,[Funnel]
      ,[DesignatedRegulation]
      ,[Regulation]
      ,[AffiliateID]
	  ,[FunnelFrom]
	  ,[Platform]
      ,[REG]
      ,[EmailVerification]
      ,[V1]
      ,[V2]
      ,[V3]
      ,[EV]
      ,[SendToEV]
      ,[PEP]
      ,[ProofOfAddress]
      ,[ProofOfIdentity]
      ,[PhoneVerified]
      ,[POA_POI]
      ,[DepositAttempt]
      ,[FTD]
      ,[IsContacted]
     ,[PhoneContacted]
	,[EmailContacted]
	,[PhoneContactedSucceed]
	,[EmailContactedSucceed] 
      ,[ConvOver96H]
      ,[PendingVerification]
      ,[ReportDateID]
      ,[UpdateDate]
	  )
	  
	
select 
DC.RealCID
,cast(RegisteredReal as date) Date
,DCCC.Region
,DCCC.Name Country
,DS.Name State
,DCC.Channel
,DCC.SubChannel
,DF.Name Funnel
,DR.Name DesignatedRegulation
,DR2.Name Regulation
,DC.AffiliateID
,DC.FunnelFrom
,DC.Platform 
		,MAX(case when DC.RegisteredReal > '19000101' then 1 else 0 end) REG
		,MAX(IsEmailVerified) EmailVerification
		,MAX(case when VerificationLevelID >= 1 then 1 else 0 end ) V1
		,MAX(case when VerificationLevelID >= 2 then 1 else 0 end ) V2
		,MAX(case when VerificationLevelID = 3 then 1 else 0 end ) V3
		,MAX(case when EvMatchStatus = 2 then 1 else 0 end) EV
		,MAX(case when EvMatchStatus in (1,2,3) then 1 else 0 end) SendToEV
		,PEP.Name PEP
		,MAX(isnull(DC.IsAddressProof,0)) ProofOfAddress
		,MAX(isnull(DC.IsIDProof,0)) ProofOfIdentity
		,MAX(isnull(DC.IsPhoneVerified,0)) PhoneVerified
		,MAX(case when DC.IsIDProof >0 and DC.IsAddressProof > 0 then 1 else 0 end ) POA_POI
		,MAX(case when bd.CID is not null then 1 else 0 end) DepositAttempt
		,MAX(case when DC.FirstDepositDate > '19000101' then 1 else 0 end) FTD
        ,MAX(CASE WHEN (sf.CreatedDate_SF < DC.FirstDepositDate) or (cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF >RegisteredReal) THEN 1 ELSE 0 END) AS IsContacted
        ,MAX(CASE WHEN sf.ActionName = 'Contacted__c' and ((sf.CreatedDate_SF < DC.FirstDepositDate) or (cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF >RegisteredReal)) THEN 1 ELSE 0 END) AS PhoneContacted
        ,MAX(CASE WHEN sf.ActionName = 'Outbound_Email__c' and ((sf.CreatedDate_SF < DC.FirstDepositDate) or (cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF >RegisteredReal)) THEN 1 ELSE 0 END) AS EmailContacted
      	,MAX(CASE WHEN sf.ActionName = 'Phone_Call_Succeed__c' and ((sf.CreatedDate_SF < DC.FirstDepositDate) or (cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF >RegisteredReal)) THEN 1 ELSE 0 END) AS PhoneContactedSucceed
        ,MAX(CASE WHEN sf.ActionName = 'Completed_Contact_Email__c' and ((sf.CreatedDate_SF < DC.FirstDepositDate) or (cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF >RegisteredReal)) THEN 1 ELSE 0 END) AS EmailContactedSucceed
        ,MAX(CASE WHEN DATEDIFF(hh,DC.RegisteredReal,DC.FirstDepositDate)>96 THEN 1 ELSE 0 END) AS ConvOver96H
		,MAX (case when PlayerStatusID = 13 and VerificationLevelID != 3  then 1 else 0 end ) PendingVerification
		,CONVERT(VARCHAR(8), cast(RegisteredReal as date), 112) ReportDateID
		,GETDATE()as UpdateDate

FROM #POP DC with(nolock)
left join DWH_dbo.[Dim_Funnel] DF with(nolock) on DC.FunnelFromID = DF.FunnelID
left join DWH_dbo.[Dim_Platform] DP with(nolock) on DF.PlatformID=DP.PlatformID
left join DWH_dbo.Dim_Affiliate DA with(nolock) on DC.AffiliateID = DA.AffiliateID
left join DWH_dbo.[Dim_Channel] DCC with(nolock) on DA.SubChannelID = DCC.SubChannelID
Left join DWH_dbo.Dim_Country DCCC with(nolock) on DC.CountryID = DCCC.CountryID
left join DWH_dbo.[Dim_State_and_Province] DS with(nolock) on DC.RegionID = DS.RegionByIP_ID
left join (select CID, max(case when PaymentStatusID = 2 then 1 end) Depositor from DWH_dbo.Fact_BillingDeposit /*[ETL_ Source].etoro_rep.Billing.vDeposit*/ with(nolock) group by CID) bd on bd.CID = DC.RealCID
--left join #POAPOI POAPOI on POAPOI.CID = DC.RealCID
left join #DesignatedRegulation2 re on re.RealCID=DC.RealCID and re.rn=1
Left join DWH_dbo.Dim_Regulation DR  with(nolock) on re.DesignatedRegulationID = DR.ID
Left join DWH_dbo.Dim_Regulation DR2  with(nolock) on DC.RegulationID = DR2.ID
LEFT JOIN BI_DB_dbo.BI_DB_UsageTracking_SF sf WITH(NOLOCK) ON sf.CID = DC.RealCID /*AND (sf.ActionName = 'Phone_Call_Succeed__c' or sf.ActionName = 'Completed_Contact_Email__c')*/
left join DWH_dbo.[Dim_ScreeningStatus] PEP  WITH(NOLOCK) on DC.ScreeningStatusID = PEP.ScreeningStatusID
group by 
DC.RealCID
,cast(RegisteredReal as date) 
,DCCC.Region
,DCCC.Name 
,DS.Name 
,DCC.Channel
,DCC.SubChannel
,DF.Name 
,DR.Name 
,DR2.Name 
,DC.AffiliateID
,PEP.Name
,DC.FunnelFrom
,DC.Platform 


END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_CIDFunnelFlow` | synapse_sp | BI_DB_dbo | SP_CIDFunnelFlow | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CIDFunnelFlow.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `BI_DB_dbo.BI_DB_UsageTracking_SF` | synapse | BI_DB_dbo | BI_DB_UsageTracking_SF | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_UsageTracking_SF.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_State_and_Province` | synapse | DWH_dbo | Dim_State_and_Province | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_State_and_Province.md` |
| `DWH_dbo.Dim_Funnel` | synapse | DWH_dbo | Dim_Funnel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Funnel.md` |
| `DWH_dbo.Dim_Platform` | synapse | DWH_dbo | Dim_Platform | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Platform.md` |
| `DWH_dbo.Dim_Affiliate` | synapse | DWH_dbo | Dim_Affiliate | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Affiliate.md` |
| `DWH_dbo.Dim_Channel` | synapse | DWH_dbo | Dim_Channel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md` |
| `DWH_dbo.Dim_ScreeningStatus` | synapse | DWH_dbo | Dim_ScreeningStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ScreeningStatus.md` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |

