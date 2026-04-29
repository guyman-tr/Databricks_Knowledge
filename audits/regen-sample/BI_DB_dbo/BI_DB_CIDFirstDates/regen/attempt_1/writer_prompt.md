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
- **Object**: `BI_DB_CIDFirstDates`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_CIDFirstDates/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CIDFirstDates\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CIDFirstDates\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_CIDFirstDates.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CIDFirstDates`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CIDFirstDates.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CIDFirstDates]
(
	[CID] [int] NOT NULL,
	[GCID] [int] NULL,
	[OriginalCID] [int] NULL,
	[UserName] [varchar](500) NULL,
	[Club] [varchar](500) NULL,
	[SerialID] [int] NULL,
	[Channel] [nvarchar](500) NOT NULL,
	[SubChannel] [nvarchar](500) NOT NULL,
	[LabelName] [varchar](500) NULL,
	[Country] [varchar](500) NULL,
	[Language] [char](500) NULL,
	[Region] [nvarchar](500) NOT NULL,
	[PotentialDesk] [varchar](8000) NULL,
	[Email] [varchar](500) MASKED WITH (FUNCTION = 'default()') NULL,
	[Credit] [money] NULL,
	[RealizedEquity] [money] NULL,
	[SocialConnect] [int] NULL,
	[Verified] [int] NULL,
	[KYC] [int] NULL,
	[DocsOK] [int] NULL,
	[Blocked] [int] NULL,
	[IsSales] [int] NULL,
	[HasPic] [int] NULL,
	[Bankruptcy] [int] NULL,
	[FunnelName] [varchar](500) NULL,
	[DownloadID] [int] NULL,
	[registered] [datetime] NOT NULL,
	[FirstTimeUser] [datetime] NULL,
	[FirstLoggedIn] [datetime] NULL,
	[FirstDemoLoggedIn] [datetime] NULL,
	[FirstDemoPosOpenDate] [datetime] NULL,
	[FirstDemoMirrorRegistrationDate] [datetime] NULL,
	[LastDemoMirrorRegistrationDate] [datetime] NULL,
	[FirstDemoMirrorPosOpenDate] [datetime] NULL,
	[FirstCashierLogin] [datetime] NULL,
	[FirstDepositAttempt] [datetime] NULL,
	[FirstDepositAttemptAmount] [numeric](36, 12) NULL,
	[FirstDepositAttemptProcessor] [varchar](500) NULL,
	[FirstDepositAttemptFundingType] [varchar](500) NULL,
	[FirstDepositDate] [datetime] NULL,
	[FirstDepositProcessor] [varchar](500) NULL,
	[FirstDepositFundingType] [varchar](500) NULL,
	[FirstDepositAmount] [money] NULL,
	[FirstEngagementDate] [datetime] NULL,
	[FirstPosOpenDate] [datetime] NULL,
	[FirstMirrorRegistrationDate] [datetime] NULL,
	[LastMirrorRegistrationDate] [datetime] NULL,
	[FirstMirrorPosOpenDate] [datetime] NULL,
	[FirstLeadDate] [datetime] NULL,
	[FirstDepositAmountExtended] [money] NULL,
	[ReferralID] [int] NULL,
	[LastDemoLoggedIn] [datetime] NULL,
	[LastDemoMirrorPosOpenDate] [datetime] NULL,
	[LastDemoPosOpenDate] [datetime] NULL,
	[LastEngagementDate] [datetime] NULL,
	[LastLoggedIn] [datetime] NULL,
	[LastMirrorPosOpenDate] [datetime] NULL,
	[LastPosOpenDate] [datetime] NULL,
	[CertifiedGuru] [int] NULL,
	[FirstTimeBeingCopied] [datetime] NULL,
	[LastTimeBeingCopied] [datetime] NULL,
	[Gender] [char](1) NULL,
	[CountryID] [int] NULL,
	[FirstMenualPosOpenDate] [datetime] NULL,
	[BirthDate] [datetime] NULL,
	[CommunicationLanguage] [varchar](500) NULL,
	[LastMenualPosOpenDate] [datetime] NULL,
	[FirstTimeSocialConnect] [datetime] NULL,
	[LastCashierLogin] [datetime] NULL,
	[FirstCashoutDate] [datetime] NULL,
	[FunnelFromName] [varchar](500) NULL,
	[BannerID] [int] NULL,
	[SubAffiliateID] [nvarchar](1024) NULL,
	[FirstCampaignID] [nvarchar](1024) NULL,
	[FirstCampaignDate] [datetime] NULL,
	[FirstCampaignAmount] [money] NULL,
	[FirstStocksOpenDate] [datetime] NULL,
	[SevenDayRetained] [int] NULL,
	[FirstToSevenDayRetained] [int] NULL,
	[FirstDateRetained] [int] NULL,
	[LastContactAttemptDate_ByPhone] [datetime] MASKED WITH (FUNCTION = 'default()') NULL,
	[LastContactDate] [datetime] NULL,
	[LastContactAttemptDate] [datetime] NULL,
	[LastContactDate_ByPhone] [datetime] MASKED WITH (FUNCTION = 'default()') NULL,
	[FirstContactAttemptDate] [datetime] NULL,
	[FirstContactAttemptDate_ByPhone] [datetime] MASKED WITH (FUNCTION = 'default()') NULL,
	[FirstContactDate] [datetime] NULL,
	[FirstContactDate_ByPhone] [datetime] MASKED WITH (FUNCTION = 'default()') NULL,
	[PremiumAccount] [int] NULL,
	[Evangelist] [int] NULL,
	[FirstToThirtyDayRetained] [int] NULL,
	[FirstWallEngagement] [datetime] NULL,
	[FeedUnBlocked] [tinyint] NULL,
	[PrivacyPolicyID] [tinyint] NULL,
	[IP] [bigint] MASKED WITH (FUNCTION = 'default()') NULL,
	[FeedUnlocked] [tinyint] NULL,
	[Follow5UsersDate] [datetime] NULL,
	[NumberOfUsersFollowed] [int] NULL,
	[PopularInvestor] [int] NULL,
	[Manager] [nvarchar](500) NULL,
	[SuitabilityTestCompletedAt] [datetime] NULL,
	[PassedSuitabilityTest] [int] NULL,
	[Model_FTDsOTDs] [float] NULL,
	[Model_Leads] [float] NULL,
	[LastDepositDate] [datetime] NULL,
	[LastDepositAmount] [money] NULL,
	[LastDepositFundingType] [varchar](500) NULL,
	[Model_ReDepositor] [money] NULL,
	[RegulationID] [int] NULL,
	[RiskGroup] [varchar](500) NULL,
	[DepositGroup] [varchar](500) NULL,
	[UpdateDate] [datetime] NULL,
	[VerificationLevel1Date] [datetime] NULL,
	[VerificationLevel2Date] [datetime] NULL,
	[VerificationLevel3Date] [datetime] NULL,
	[EmailVerifiedDate] [date] NULL,
	[FirstInstallDate] [datetime] NULL,
	[EvMatchStatusDate] [datetime] NULL,
	[State] [varchar](100) NULL,
	[PhoneVerifiedDate] [datetime] NULL,
	[KycModeID] [int] NULL,
	[PEPCreatedTime] [datetime] NULL,
	[PEPStatusUpdatedDate] [datetime] NULL,
	[isPassedPEP] [tinyint] NULL,
	[PEPStatusID] [int] NULL,
	[EvMatchStatus] [int] NULL,
	[FTDIsLessThanAWeek] [int] NULL,
	[DesignatedRegulationID] [int] NULL,
	[ProfessionalApplicationDate] [date] NULL,
	[LastCampaignSentDate] [datetime] NULL,
	[NewMarketingRegion] [varchar](100) NULL,
	[IsFundedNew] [tinyint] NULL,
	[FirstNewFundedDate] [date] NULL,
	[LastNewFundedDate] [date] NULL,
	[IsAirDropBefore] [tinyint] NULL,
	[SignedW8Date] [date] NULL,
	[LastCashoutDate] [datetime] NULL,
	[LastPublishedPostDate] [date] NULL,
	[LastActionDateForLifeStage] [date] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CID] ),
	CLUSTERED INDEX
	(
		[CID] ASC
	)
)

GO
ALTER TABLE [BI_DB_dbo].[BI_DB_CIDFirstDates] ADD  CONSTRAINT [df_FirstDepositAmount_]  DEFAULT ((0)) FOR [FirstDepositAmount]
GO

```

---

## Upstream Wikis Found

Found 27 upstream wiki(s). Read EACH one in full.


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


### Upstream `DWH_dbo.Dim_Label` — synapse
- **Resolved as**: `DWH_dbo.Dim_Label`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Label.md`

# DWH_dbo.Dim_Label

> Small 26-row dictionary table mapping LabelID to the white-label broker brand name -- identifying which eToro-platform white-label partner (e.g., RetailFX, ICMarkets, eToroUSA) a customer account was acquired under or associated with.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Label (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (LabelID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (26 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Label` is a reference dictionary for eToro's white-label broker network -- the companies that licensed the eToro platform to offer it under their own brand to customers in specific regions. Each row maps a LabelID to a brand name (e.g., `RetailFX`, `ICMarkets`, `eToroUSA`, `Euroforex`). The label identifies which white-label channel a customer account originated from or is associated with.

The table has 26 rows. Most entries represent historical white-label partners from eToro's early expansion phase (2010-2015), when the platform was licensed to regional brokers. Some remain active (e.g., `eToroUSA`, `eToroChina`); others (e.g., `JCLyons`, `BT`, `Trend-Online`) are legacy brands that are no longer active. LabelID 0 (`eToro`) and LabelID 1 (`eToro`) are both the core eToro brand -- the distinction between 0 and 1 is a legacy artifact.

ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Label`, which is loaded from the Generic Pipeline Bronze export of the production `Dictionary.Label` table.

---

## 2. Business Logic

### 2.1 White-Label Brand Identification

**What**: Each customer account in the DWH has an associated LabelID identifying the broker brand under which they were onboarded.

**Rules**:
- LabelID=0 and LabelID=1 both map to `eToro` -- legacy dual-entry. Use `IN (0, 1)` or join to Name for eToro's own customers.
- Most white-label partners (LabelID 2-31) represent historical licensee brands. Many are no longer actively onboarding customers.
- `eToroUSA` (LabelID=14), `eToroRussia` (LabelID=29), `eToroChina` (LabelID=31) are eToro's own regional sub-brands.
- `eToro-Partners` (LabelID=27), `etoro-raf` (LabelID=28) may represent internal partner/referral channels.
- `Dealing` (LabelID=30) likely represents accounts assigned to the dealing desk.

### 2.2 DWHLabelID Redundancy

**What**: `DWHLabelID` is always equal to `LabelID` -- a standard DWH denormalization pattern seen across all Dim tables.

**Rule**: `DWHLabelID = LabelID` (from SP: `[LabelID] as [DWHLabelID]`). Do not use DWHLabelID for JOINs; use LabelID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (26 rows fit trivially on every node). CLUSTERED INDEX on LabelID. Zero JOIN overhead when joining to fact tables on LabelID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get label name for customer account | `JOIN Dim_Label ON LabelID; SELECT Name` |
| Find all eToro-brand accounts | `WHERE LabelID IN (0, 1, 14, 29, 31)` (eToro core + regional sub-brands) |
| Segment by white-label vs eToro-direct | `WHERE LabelID BETWEEN 2 AND 13` (legacy white-label partners) |

### 3.3 Gotchas

- **LabelID 0 and 1 both = eToro**: Use `IN (0, 1)` or `Name = 'eToro'` for the core eToro brand.
- **StatusID is always 1**: ETL hardcodes StatusID=1 for all rows. Not a meaningful filter.
- **UpdateDate/InsertDate are both GETDATE()**: ETL timestamps from the daily load, not production modification dates.
- **Legacy brands**: Most non-eToro labels are historical. Volume in fact tables for these LabelIDs will be concentrated in earlier years.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- Upstream dictionary | `(Tier 1 — Dictionary.Label)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LabelID | int | NO | Primary key identifying the platform brand/label. 0/1/9=eToro (primary), 2=RetailFX, 10-26=white-label partners, 14=eToroUSA, 27=Partners, 29=eToroRussia, 30=Dealing, 31=eToroChina. Stored in customer records and referenced across billing, reporting, and registration procedures. (Tier 1 — Dictionary.Label) |
| 2 | Name | varchar(50) | NO | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). (Tier 1 — Dictionary.Label) |
| 3 | DWHLabelID | int | YES | Always equal to LabelID. Standard DWH DWH{X}ID redundancy pattern (ETL: `[LabelID] as [DWHLabelID]`). Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all rows (ETL: `1 as StatusID`). Conveys no business information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time, identical to UpdateDate (TRUNCATE + INSERT pattern). Does not reflect production insertion date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| LabelID | etoro.Dictionary.Label | LabelID | passthrough |
| Name | etoro.Dictionary.Label | Name | passthrough |
| DWHLabelID | etoro.Dictionary.Label | LabelID | rename (= LabelID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Label  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Label
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Label  (26 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Label/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | LabelID | Identifies the white-label brand for customer accounts |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 List all active white-label brands

```sql
SELECT LabelID, Name
FROM [DWH_dbo].[Dim_Label]
ORDER BY LabelID;
```

### 7.2 Segment accounts by eToro-brand vs white-label

```sql
SELECT
    CASE
        WHEN l.LabelID IN (0, 1, 14, 29, 31) THEN 'eToro Brand'
        ELSE 'White-Label Partner'
    END AS BrandType,
    l.Name,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Label] l ON f.LabelID = l.LabelID
GROUP BY l.LabelID, l.Name
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.1/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 6/6, Logic: 8/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Label | Type: Table | Production Source: etoro.Dictionary.Label*


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


### Upstream `DWH_dbo.Dim_Language` — synapse
- **Resolved as**: `DWH_dbo.Dim_Language`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md`

# DWH_dbo.Dim_Language

> Small 29-row dictionary table mapping LanguageID to the language name, ISO 639-1 code, and IETF BCP 47 culture code -- representing the 28 languages supported by the eToro platform for customer UI localization and communication preferences.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Language (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (no clustered index) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (29 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Language` is the platform's language reference table, mapping each LanguageID to the human-readable language name, its ISO 639-1 two-letter code, and its IETF BCP 47 culture code. The 29 rows cover 28 supported platform languages plus a LanguageID=0 null-sentinel (`N/A`). Customer profiles and events carry a LanguageID indicating the customer's selected UI language and preferred communication locale.

The table includes two Chinese variants (LanguageID=4 `Chinese`/zh-CN for Simplified, LanguageID=18 `ChineseTraditional`/zh-TW for Traditional) and two English variants (LanguageID=1 `English`/en-GB for British, LanguageID=25 `EnglishUS`/en-US for American). Both variants share the same IsoCode but differ in CultureCode.

ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Language`. The table is HEAP-indexed (no clustered index) because at 29 rows, index overhead is negligible.

---

## 2. Business Logic

### 2.1 IsoCode vs CultureCode

**What**: `IsoCode` is a 2-letter ISO 639-1 language code; `CultureCode` is a 5-character IETF BCP 47 locale tag combining language and region.

**Rules**:
- Use `IsoCode` for language-only grouping (e.g., all Portuguese speakers regardless of region).
- Use `CultureCode` for locale-specific formatting, currency, and routing (e.g., pt-BR for Brazilian Portuguese vs pt-PT for European Portuguese).
- Two CultureCodes share the same IsoCode=`zh`: zh-CN (Chinese Simplified) and zh-TW (Chinese Traditional). When aggregating by IsoCode, `zh` will include both.
- Two CultureCodes share IsoCode=`en`: en-GB and en-US. For global English aggregation, use `IsoCode = 'en'`.
- Two CultureCodes share IsoCode=`pt`: pt-BR (Brazilian) and pt-PT (European Portuguese).

### 2.2 LanguageID=0 Null-Sentinel

**Rule**: LanguageID=0 has Name='N/A', IsoCode='N/A', CultureCode='N/A'. This is the DWH standard placeholder for missing/unknown language data. Always filter `WHERE LanguageID > 0` for language analytics.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (29 rows), HEAP. Zero JOIN overhead on any node. HEAP is acceptable at this row count -- no scan benefit from a clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get language name for customer | `JOIN Dim_Language ON LanguageID; SELECT Name, IsoCode` |
| Group customers by language | `GROUP BY l.IsoCode, l.Name` |
| Find all English-language customers | `WHERE IsoCode = 'en'` (includes both en-GB and en-US) |
| Distinguish British vs American English | `WHERE CultureCode IN ('en-GB', 'en-US')` |

### 3.3 Gotchas

- **HEAP index**: Full table scans on all queries. Acceptable at 29 rows; zero performance concern.
- **IsoCode is nchar(10)**: Padded with spaces. When comparing, use TRIM() or LIKE pattern if needed.
- **CultureCode is nchar(10)**: Same padding issue.
- **Shared IsoCode for zh and pt**: Grouping by IsoCode merges Simplified/Traditional Chinese and BR/EU Portuguese. Use CultureCode for differentiation.
- **StatusID is always 1**: ETL hardcodes it. No informational value.
- **Name column is char(50)**: Fixed-width with space padding (e.g., 'English' appears as 'English   ...'). Use RTRIM(Name) in display queries.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- Upstream dictionary | `(Tier 1 — Dictionary.Language)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LanguageID | int | NO | Primary key identifying the language. 1=English(UK), 2=German, 3=Arabic, 4=Chinese, 5=Russian, 6=Spanish, 7=French, 8=Italian, 9=Japanese, 10=Portuguese(BR), 11=Turkish, 12=Greek, 13=Korean, 14=Swedish, 15=Norwegian, 16=Hungarian, 17=Polish, 18=ChineseTraditional, 19=Dutch, 20=EuropeanPortuguese, 21=Czech, 22=Malay, 23=Danish, 24=Romanian, 25=EnglishUS, 26=Vietnamese, 27=Thai, 28=Finnish. Referenced by Dictionary.Country.LanguageID. (Tier 1 — Dictionary.Language) |
| 2 | Name | char(50) | NO | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. (Tier 1 — Dictionary.Language) |
| 3 | DWHLanguageID | int | YES | Always equal to LanguageID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time, same as UpdateDate. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 7 | IsoCode | nchar(10) | YES | ISO 639-1 two-letter language code (e.g., 'en', 'de', 'ar'). Used for URL routing, API locale headers, and content management. (Tier 1 — Dictionary.Language) |
| 8 | CultureCode | nchar(10) | YES | .NET culture code for full locale specification (e.g., 'en-GB', 'de-DE', 'zh-CN'). Used for number formatting, date formatting, and currency display. (Tier 1 — Dictionary.Language) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| LanguageID | etoro.Dictionary.Language | LanguageID | passthrough |
| Name | etoro.Dictionary.Language | Name | passthrough |
| DWHLanguageID | etoro.Dictionary.Language | LanguageID | rename (= LanguageID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| IsoCode | etoro.Dictionary.Language | IsoCode | passthrough |
| CultureCode | etoro.Dictionary.Language | CultureCode | passthrough |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Language  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Language
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Language  (29 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Language/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer profile dimension tables | LanguageID | Customer's selected platform language |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 List all supported languages with locale codes

```sql
SELECT LanguageID, RTRIM(Name) AS Language, RTRIM(IsoCode) AS IsoCode, RTRIM(CultureCode) AS CultureCode
FROM [DWH_dbo].[Dim_Language]
WHERE LanguageID > 0
ORDER BY LanguageID;
```

### 7.2 Group customer registrations by language family

```sql
SELECT
    RTRIM(l.IsoCode) AS IsoCode,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Language] l ON f.LanguageID = l.LanguageID
WHERE l.LanguageID > 0
GROUP BY l.IsoCode
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 4 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Language | Type: Table | Production Source: etoro.Dictionary.Language*


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


### Upstream `DWH_dbo.Dim_PlayerLevel` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerLevel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md`

# DWH_dbo.Dim_PlayerLevel

> Lookup table defining the 7 eToro Club loyalty tiers (Bronze through Diamond plus Internal) with tier-specific cashout wait times and display sort order. NOTE: DWH drops the primary equity qualification thresholds (RealizedEquityFrom/To, DaysInRiskBeforeDowngrade) present in production.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerLevel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerLevel defines the eToro Club loyalty program tiers that segment customers by their realized equity (account value). Each tier grants progressively better benefits: faster cashout processing, higher service priority, and dedicated account management. The tiers in ascending rank are: Bronze -> Silver -> Gold -> Platinum -> Platinum Plus -> Diamond, plus a special Internal tier for employee/test accounts.

The data originates from `etoro.Dictionary.PlayerLevel` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PlayerLevel/` in the data lake. Production has 7 active tier rows (IDs 1-7); DWH adds a synthetic ID=0 N/A placeholder.

**CRITICAL SCHEMA DRIFT**: The DWH ETL loads only 8 of the production's 13 columns. The following production columns are DROPPED and not available in DWH: `RealizedEquityFrom`, `RealizedEquityTo` (the primary tier qualification thresholds), `IsWalletRedeemAllowed`, `ThresholdPercentToCurrentLevel`, and `DaysInRiskBeforeDowngrade`. For tier qualification logic, query the upstream `etoro.Dictionary.PlayerLevel` directly or the upstream wiki. The DWH table is suitable only for resolving tier names and cashout hours -- not for equity-based tier evaluation.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from staging, followed by a separate INSERT VALUES for the ID=0 N/A sentinel using `@ddate` (midnight timestamp). Refreshes daily.

---

## 2. Business Logic

### 2.1 Tier Hierarchy and Rank Order

**What**: Six customer-facing loyalty tiers plus one internal tier, ranked by realized equity.

**Columns Involved**: `PlayerLevelID`, `Name`, `Sort`

**Rules**:
- IDs are NOT in rank order -- use `Sort` column for display ordering.
- Sort order: 0=Internal (excluded), 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond.
- Internal (ID=4) is excluded from customer-facing reports: `WHERE PlayerLevelID <> 4`.
- ID=0 (N/A) is a DWH-only ETL placeholder for NULL FK safety. Not in production.

**Diagram**:
```
Tier Hierarchy (by Sort/Rank):
  Sort 1 = Bronze     (ID=1) -- entry level
  Sort 2 = Silver     (ID=5)
  Sort 3 = Gold       (ID=3)
  Sort 4 = Platinum   (ID=2)
  Sort 5 = Platinum + (ID=6)
  Sort 6 = Diamond    (ID=7) -- top tier
  Sort 0 = Internal   (ID=4) -- excluded
  (ID=0  = N/A       -- DWH ETL placeholder)
```

### 2.2 Cashout Processing Speed by Tier

**What**: Higher tiers receive priority cashout processing as a loyalty benefit.

**Columns Involved**: `CashoutPendingHours`

**Rules**:
- **120 hours (5 days)**: Bronze (1), Silver (5), Internal (4), N/A (0)
- **72 hours (3 days)**: Gold (3)
- **24 hours (1 day)**: Platinum (2), Platinum Plus (6), Diamond (7)
- This is one of the most impactful benefits of upper tier membership.

### 2.3 Legacy Lot/Deposit Thresholds (Deprecated)

**What**: Historical tier qualification fields -- superseded by RealizedEquity (not in DWH).

**Columns Involved**: `FromSumLotCount`, `ToSumLotCount`, `FromSumDeposit`, `ToSumDeposit`

**Rules**:
- All set to `-1` for Platinum (2), Platinum Plus (6), Diamond (7) -- meaning "disabled/not applicable".
- Bronze (1) has 1-3000 lots, $0-$999 deposit; Silver (5) has 3001-20000 lots, $1000-$4999; Gold (3) has 20001-100000 lots, $5000-$19999.
- These columns are legacy artifacts. The current tier system uses `RealizedEquityFrom/To` which are NOT loaded into DWH.
- Value -1 = "threshold disabled -- upper tier, equity-based qualification only".

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP (no clustering) is unusual for dimension tables -- most Dim_ tables use CLUSTERED INDEX. With only 8 rows, HEAP is not a concern for performance but means scans are unordered. Always use `ORDER BY Sort` for consistent tier display.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`. With 8 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What tier is a customer in? | JOIN Dim_Customer ON PlayerLevelID for Name |
| Tier distribution of customer base | GROUP BY PlayerLevelID, exclude Internal (ID=4) |
| Display tiers in rank order | ORDER BY Sort ASC, exclude ID=0 and ID=4 |
| Cashout processing time for a tier | SELECT CashoutPendingHours WHERE PlayerLevelID = X |
| What are the equity thresholds? | NOT available in DWH -- use upstream wiki or prod data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerLevelID = dpl.PlayerLevelID | Resolve tier name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerLevelID = dpl.PlayerLevelID | View-level tier resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerLevelID = dpl.PlayerLevelID | Tier in daily snapshots |

### 3.4 Gotchas

- **IDs are NOT in rank order**: PlayerLevelID 2=Platinum, 3=Gold, 5=Silver. Always use `Sort` for ordering tiers. Filtering `PlayerLevelID > 3` does NOT mean "higher than Gold".
- **Internal tier (ID=4)**: Must be excluded in most customer analytics: `WHERE PlayerLevelID <> 4` or `WHERE PlayerLevelID NOT IN (0, 4)`.
- **-1 in range columns means disabled**: For Platinum/Platinum Plus/Diamond, FromSumLotCount=-1 and ToSumLotCount=-1 indicate the legacy lot-count threshold is not used. Do NOT interpret -1 as a valid lot count.
- **Critical columns missing from DWH**: `RealizedEquityFrom`, `RealizedEquityTo`, `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`, and `IsWalletRedeemAllowed` are ALL in production but NOT in DWH. For equity-tier evaluation, use the upstream source.
- **HEAP index**: Unlike most DWH Dim_ tables, this uses HEAP (no CCI). Row order is not guaranteed without explicit ORDER BY.
- **ID=0 midnight timestamp**: The N/A placeholder (ID=0) has midnight InsertDate/UpdateDate from `@ddate = CAST(GETDATE() AS DATE)`, while production rows have full timestamps from GETDATE().

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerLevelID | int | NO | Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 2 | Name | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 3 | CashoutPendingHours | int | NO | Maximum hours a cashout request waits before processing. 24=1 day (Platinum/Platinum Plus/Diamond), 72=3 days (Gold), 120=5 days (Bronze/Silver/Internal). Key loyalty benefit -- higher tiers get faster withdrawals. 0 for N/A placeholder. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 4 | FromSumLotCount | int | NO | Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (Platinum/Platinum Plus/Diamond -- threshold disabled). Superseded by RealizedEquityFrom (not loaded in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 5 | ToSumLotCount | int | NO | Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (threshold disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 6 | FromSumDeposit | int | NO | Legacy: minimum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityFrom (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 7 | ToSumDeposit | int | NO | Legacy: maximum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 8 | Sort | int | NO | Display order for tier hierarchy. 0=Internal/N/A, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use ASC sort on this column for correct tier rank ordering. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 9 | DWHPlayerLevelID | int | NO | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerLevelID] AS [DWHPlayerLevelID]. 0 for ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 12 | StatusID | tinyint | NO | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. DWH ETL convention for dictionary tables loaded by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerLevelID | Dictionary.PlayerLevel | PlayerLevelID | passthrough |
| Name | Dictionary.PlayerLevel | Name | passthrough |
| CashoutPendingHours | Dictionary.PlayerLevel | CashoutPendingHours | passthrough |
| FromSumLotCount | Dictionary.PlayerLevel | FromSumLotCount | passthrough |
| ToSumLotCount | Dictionary.PlayerLevel | ToSumLotCount | passthrough |
| FromSumDeposit | Dictionary.PlayerLevel | FromSumDeposit | passthrough |
| ToSumDeposit | Dictionary.PlayerLevel | ToSumDeposit | passthrough |
| Sort | Dictionary.PlayerLevel | Sort | passthrough |
| DWHPlayerLevelID | -- | -- | ETL-computed: = PlayerLevelID (redundant surrogate) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| InsertDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |

**Dropped from production (schema drift)**: IsWalletRedeemAllowed, RealizedEquityFrom, RealizedEquityTo, ThresholdPercentToCurrentLevel, DaysInRiskBeforeDowngrade.

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerLevel.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerLevel
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerLevel/
  -> DWH_staging.etoro_Dictionary_PlayerLevel
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerLevel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerLevel | Production tier dictionary (etoroDB-REAL) -- 13 cols, 7 rows |
| Lake | Bronze/etoro/Dictionary/PlayerLevel/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerLevel | Raw staging import -- 8 passthrough cols only |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse (line ~931) | TRUNCATE + INSERT SELECT; adds 4 computed cols; drops 5 production cols |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1538) | INSERT VALUES for ID=0 N/A sentinel using @ddate (midnight) |
| Target | DWH_dbo.Dim_PlayerLevel | 8 rows, 12 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerLevelID | Customer's current loyalty tier |
| DWH_dbo.V_Dim_Customer | PlayerLevelID | View exposing tier for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Daily snapshot of customer tier |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerLevelID | Year-end snapshot tier |

---

## 7. Sample Queries

### 7.1 List all tiers in rank order

```sql
SELECT PlayerLevelID,
       Name,
       Sort,
       CashoutPendingHours
FROM   [DWH_dbo].[Dim_PlayerLevel]
WHERE  PlayerLevelID NOT IN (0, 4)   -- exclude N/A and Internal
ORDER BY Sort ASC;
```

### 7.2 Count customers by tier (excluding internal)

```sql
SELECT  dpl.Name             AS Tier,
        dpl.Sort,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID NOT IN (0, 4)
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 7.3 Identify customers in premium tiers (24h cashout)

```sql
SELECT  dc.CID,
        dpl.Name  AS Tier,
        dpl.CashoutPendingHours
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.CashoutPendingHours = 24   -- Platinum, Platinum Plus, Diamond
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 8 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerLevel | Type: Table | Production Source: etoro.Dictionary.PlayerLevel*


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


### Upstream `DWH_dbo.Dim_VerificationLevel` — synapse
- **Resolved as**: `DWH_dbo.Dim_VerificationLevel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md`

# DWH_dbo.Dim_VerificationLevel

> Lookup dimension defining the four progressive KYC identity verification tiers (Level 0–3) that gate platform capabilities — from unverified registration through full KYC with complete trading and withdrawal access. Also includes a DWH-internal ID=-1 sentinel row. Sourced daily from etoro.Dictionary.VerificationLevel via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.VerificationLevel |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT + sentinel row) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (ID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_VerificationLevel` defines the progressive identity verification tiers that eToro customers pass through as they complete KYC (Know Your Customer) requirements. Each level represents a milestone unlocking additional platform capabilities. Level 0 is the starting state (unverified); Level 3 is full KYC with unrestricted access.

Without this table, the DWH cannot segment customers by identity verification status. Regulatory requirements (MiFID II, ASIC, CySEC) mandate that large withdrawals, leveraged trading, and real stock purchases require minimum verification thresholds. This dimension provides the classification system for those segments in DWH analytics.

Source: `etoro.Dictionary.VerificationLevel` on etoroDB-REAL. Loaded by SP_Dictionaries_DL_To_Synapse with TRUNCATE + INSERT. Two DWH-specific additions beyond the source data:
1. `DWHVerificationLevelID` — populated as a copy of `ID` (passthrough alias used in DWH ETL)
2. `StatusID` — hardcoded to 1 for all rows (ETL active-row convention)
3. An ID=-1 sentinel row is inserted after the main load for NULL-safe JOINs in fact tables

---

## 2. Business Logic

### 2.1 Progressive Verification Tiers

**What**: Four levels from unverified to fully KYC-verified, each unlocking more platform features.

**Columns Involved**: `ID`, `Name`

**Rules**:
- Level 0 — baseline state after registration; severe restrictions on trading and withdrawals
- Level 1 — basic verification complete (e.g., email confirmed, basic questionnaire); limited trading allowed
- Level 2 — intermediate verification (POI document submitted or under review); moderate trading access
- Level 3 — full KYC (POI + POA confirmed); complete platform access: unlimited withdrawals, all instruments, leveraged trading, real stocks

**Diagram**:
```
Registration → Level 0 (Unverified)
                    |
              Email/basic verified
                    v
              Level 1 (Basic)
                    |
              POI submitted
                    v
              Level 2 (Intermediate)
                    |
              POI + POA confirmed
                    v
              Level 3 (Full KYC)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 6-row table (5 source rows + 1 sentinel). Zero data movement on JOINs. Clustered index on `ID` for point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer count by verification tier | JOIN Dim_Customer ON VerificationLevelID = ID |
| Fully KYC customers | Filter ID = 3 |
| Unverified customer share | Filter ID = 0 |

### 3.3 Gotchas

- **DWHVerificationLevelID is a duplicate of ID**: This column has the same value as `ID` for every row. It is a DWH ETL convention artifact, not a separate key
- **StatusID is always 1**: Hardcoded by ETL, carries no business meaning
- **ID=-1 sentinel**: Added by SP_Dictionaries_DL_To_Synapse for NULL-safe JOINs in fact tables. Not a real verification level

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NOT NULL | Verification tier identifier. Clustered index key. 0=Unverified (registration default, severe restrictions), 1=Basic (limited trading), 2=Intermediate (POI submitted, moderate access), 3=Full KYC (all features unlocked). -1=DWH sentinel (NULL-safe JOIN placeholder). Stored in customer dimension tables as VerificationLevelID and checked by 60+ procedures to gate trading, withdrawals, and compliance operations. (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| 2 | Name | varchar(50) | YES | Display label for the tier. "Level 0" through "Level 3". Used in BackOffice UI, compliance reports, and customer analytics. Nullable by DDL but all production rows are populated. (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| 3 | DWHVerificationLevelID | int | YES | DWH ETL alias for the ID column. Populated as `[ID] AS [DWHVerificationLevelID]` in SP_Dictionaries_DL_To_Synapse — always equals ID. Used internally by DWH ETL procedures that reference this column name; carries the same value as ID. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | ETL active-row indicator. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from the production source; carries no business meaning. DWH-wide ETL convention. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp for row insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.VerificationLevel | ID | Passthrough |
| Name | etoro.Dictionary.VerificationLevel | Name | Passthrough |
| DWHVerificationLevelID | etoro.Dictionary.VerificationLevel | ID | Alias copy of ID |
| StatusID | — | — | ETL-computed: hardcoded to 1 |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |
| InsertDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.VerificationLevel (etoroDB-REAL, 4 rows: 0-3)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/VerificationLevel/
  |
  v [staging]
DWH_staging.etoro_Dictionary_VerificationLevel
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT + ID=-1 sentinel]
DWH_dbo.Dim_VerificationLevel (5 rows: -1, 0, 1, 2, 3)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.VerificationLevel | 4-row KYC tier table (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/VerificationLevel/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_VerificationLevel | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; DWHVerificationLevelID=ID; StatusID=1; UpdateDate/InsertDate=GETDATE(); ID=-1 sentinel added |
| Target | DWH_dbo.Dim_VerificationLevel | 5 rows (-1,0,1,2,3) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ID | etoro.Dictionary.VerificationLevel | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | VerificationLevelID | Customer KYC tier (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all verification tiers

```sql
SELECT ID, Name, DWHVerificationLevelID
FROM [DWH_dbo].[Dim_VerificationLevel]
WHERE ID >= 0
ORDER BY ID
-- Returns: 0=Level 0, 1=Level 1, 2=Level 2, 3=Level 3
```

### 7.2 Customer distribution by verification level

```sql
SELECT
    vl.Name AS VerificationLevel,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_VerificationLevel] vl
    ON dc.VerificationLevelID = vl.ID
WHERE vl.ID >= 0
GROUP BY vl.Name
ORDER BY vl.ID
```

### 7.3 ETL freshness check

```sql
SELECT ID, Name, UpdateDate
FROM [DWH_dbo].[Dim_VerificationLevel]
ORDER BY ID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4-Inferred | Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Dim_VerificationLevel | Type: Table | Production Source: etoro.Dictionary.VerificationLevel*


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

### Upstream `DWH_dbo.Fact_FirstCustomerAction` — synapse
- **Resolved as**: `DWH_dbo.Fact_FirstCustomerAction`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_FirstCustomerAction.md`

# DWH_dbo.Fact_FirstCustomerAction

> Records the first time each customer performed each type of action on the platform — first deposit, first trade, first withdrawal, etc. — enabling funnel analysis and customer lifecycle milestone tracking.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — milestone/snapshot) |
| **Row Count** | Millions (one row per GCID × ActionTypeID, growing as new customers act) |
| **Production Source** | DWH_dbo.Fact_CustomerAction (DWH-internal derivation) |
| **Refresh** | Daily incremental — DELETE yesterday + re-MERGE from Fact_CustomerAction |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **Synapse NCI** | IX_Fact_FirstCustomerAction_ActionTypeID (DateID, ActionTypeID, FirstEver) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction` |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_FirstCustomerAction` captures the milestone moment when a customer performs each type of action for the first time. While `Fact_CustomerAction` logs every action event, this table filters down to only the **first occurrence** per customer per action type. It answers:

- "When did this customer make their first deposit?" (ActionTypeID for deposit)
- "When was their first trade?" (ActionTypeID for trade)
- "What was the funnel conversion path — registration → first deposit → first trade?"

The table enables:
- **Customer funnel analysis** — time between registration and first deposit (FTD), first trade, etc.
- **Cohort analysis** — grouping customers by the date of their first key action
- **Marketing attribution** — linking first actions to acquisition campaigns via CampaignID
- **Lifecycle milestones** — tracking which customers have completed key activation steps

### FirstEver flag

The `FirstEver` column distinguishes:
- **FirstEver = 1**: This is the absolute first time this customer performed this ActionTypeID. One row per (GCID, ActionTypeID).
- **FirstEver = 0**: A unique event (by HistoryID) captured via a secondary MERGE. These represent "first occurrences" at a more granular level — first with a specific instrument, first from a specific platform, etc.

---

## 2. Business Logic

### 2.1 Two-Stage MERGE Pattern

**What**: The SP uses two sequential MERGE operations to capture "firsts" at different granularity levels.

**MERGE 1 — First per Action Type**:
```
Source: Fact_CustomerAction WHERE DateID = @dateid
        → Deduplicated by HistoryID (keep first by Occurred, PositionID, SessionID)
        → Ranked by (ActionTypeID, GCID) → rn2 = row_number
        
MERGE INTO Fact_FirstCustomerAction ON ActionTypeID = ActionTypeID AND GCID = GCID
WHEN NOT MATCHED AND rn2 = 1 → INSERT with FirstEver = 1
```

**MERGE 2 — First per HistoryID**:
```
MERGE INTO Fact_FirstCustomerAction ON HistoryID = HistoryID
WHEN NOT MATCHED → INSERT with FirstEver = 0
```

### 2.2 Daily Re-Processing

**What**: The orchestrator SP deletes and re-processes yesterday's data.

```
DELETE FROM Fact_FirstCustomerAction WHERE FirstOccurred >= @Yesterday
EXEC SP_Fact_FirstCustomerAction @Yesterday
```

This ensures idempotency — running for the same date twice produces the same result.

### 2.3 Default Values

Many FK columns default to 0 (not NULL), indicating "not applicable" rather than "unknown":
InstrumentID, PositionID, CampaignID, BonusTypeID, FundingTypeID, LoginID, MirrorID, WithdrawID, CaseID, CompensationReasonID, WithdrawPaymentID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH(RealCID) with a CLUSTERED INDEX on RealCID, enabling efficient customer-level lookups. A non-clustered index on (DateID, ActionTypeID, FirstEver) supports date-range and action-type filtered queries.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's first deposit date | `WHERE GCID = @gcid AND ActionTypeID = @depositActionType AND FirstEver = 1` |
| All first milestones for a customer | `WHERE GCID = @gcid AND FirstEver = 1 ORDER BY FirstOccurred` |
| Daily first-deposit cohort | `WHERE ActionTypeID = @depositType AND FirstEver = 1 AND DateID = @dt` |
| Time-to-first-trade after registration | JOIN with customer registration date, filter FirstEver = 1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GCID = GCID | Customer demographics |
| DWH_dbo.Dim_ActionType | ON ActionTypeID = ActionTypeID | Action type description |
| DWH_dbo.Dim_Instrument | ON InstrumentID = InstrumentID | Instrument of first trade |
| DWH_dbo.Dim_Campaign | ON CampaignID = CampaignID | Attribution campaign |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |
| DWH_dbo.Fact_CustomerAction | ON HistoryID = HistoryID | Full event details |

### 3.4 Gotchas

- **0 vs NULL**: Most FK columns use 0 (not NULL) for "not applicable". JOIN with `WHERE InstrumentID > 0` to exclude irrelevant lookups
- **FirstEver flag**: For standard funnel analysis, always filter `FirstEver = 1`. FirstEver = 0 rows are supplementary granular events
- **Re-processing window**: Yesterday's data is DELETE+re-MERGEd daily. Querying during ETL may show gaps
- **RealCID distribution**: HASH(RealCID) — JOINs on GCID may require data movement. Use RealCID when possible for co-located JOINs

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — unique cross-platform identifier. (Tier 2 — Fact_CustomerAction passthrough) |
| 2 | RealCID | int | NO | Real-money account Customer ID. Distribution key and clustered index. (Tier 2 — Fact_CustomerAction passthrough) |
| 3 | DemoCID | int | NO | Demo account Customer ID. (Tier 2 — Fact_CustomerAction passthrough) |
| 4 | FirstOccurred | datetime | NO | Timestamp when this action type was first performed by the customer. Mapped from Fact_CustomerAction.Occurred. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 5 | IPNumber | bigint | NO | IP address (as integer) from which the first action was performed. (Tier 2 — Fact_CustomerAction passthrough) |
| 6 | IsReal | tinyint | NO | Whether the first action was on a Real (1) or Demo (0) account. (Tier 2 — Fact_CustomerAction passthrough) |
| 7 | ActionTypeID | smallint | NO | Type of customer action (e.g., deposit, trade, withdrawal). JOINs to Dim_ActionType. Part of the business key with GCID. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 8 | PlatformTypeID | smallint | NO | Platform used for the first action (web, iOS, Android). JOINs to Dim_PlatformType. (Tier 2 — Fact_CustomerAction passthrough) |
| 9 | InstrumentID | int | NO | Instrument involved in the first action (for trades). Default 0 = not applicable. JOINs to Dim_Instrument. (Tier 2 — Fact_CustomerAction passthrough) |
| 10 | Amount | decimal(11,2) | NO | Monetary amount of the first action (e.g., first deposit amount). (Tier 2 — Fact_CustomerAction passthrough) |
| 11 | PositionID | bigint | NO | Position ID for trade-related first actions. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 12 | CampaignID | int | NO | Marketing campaign active at time of first action. Default 0 = no campaign. JOINs to Dim_Campaign. (Tier 2 — Fact_CustomerAction passthrough) |
| 13 | BonusTypeID | smallint | NO | Bonus type associated with the first action. Default 0 = none. JOINs to Dim_BonusType. (Tier 2 — Fact_CustomerAction passthrough) |
| 14 | FundingTypeID | smallint | NO | Funding method for the first deposit/withdrawal. Default 0 = not applicable. JOINs to Dim_FundingType. (Tier 2 — Fact_CustomerAction passthrough) |
| 15 | LoginID | int | NO | Login session ID for the first action. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 16 | MirrorID | int | NO | Copy trading mirror ID if the first action was a copy trade. Default 0 = not a copy trade. (Tier 2 — Fact_CustomerAction passthrough) |
| 17 | WithdrawID | int | NO | Withdrawal transaction ID for first withdrawal actions. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 18 | PostID | uniqueidentifier | YES | Social feed post ID if the first action was a social interaction. NULL if not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 19 | CaseID | int | NO | Support case ID if the first action was case-related. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 20 | UpdateDate | datetime | NO | ETL timestamp — GETDATE() during MERGE execution. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 21 | UpdateDateID | int | YES | Date portion of UpdateDate in YYYYMMDD format (ETL lineage key; BI Dictionary references first-deposit and milestone dates in DWH). (Tier 4 — Confluence, BI Dictionary) |
| 22 | DateID | int | NO | Date of the first action in YYYYMMDD format. JOINs to Dim_Date. (Tier 2 — Fact_CustomerAction passthrough) |
| 23 | TimeID | int | NO | Time of the first action in HHMMSS format. JOINs to Dim_Time. (Tier 2 — Fact_CustomerAction passthrough) |
| 24 | CompensationReasonID | int | NO | Reason for compensation if the first action was a compensation event. Default 0 = not applicable. JOINs to Dim_CompensationReason. (Tier 2 — Fact_CustomerAction passthrough) |
| 25 | WithdrawPaymentID | int | NO | Payment method ID for first withdrawal. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 26 | DepositID | int | YES | Deposit transaction ID for first deposit actions. NULL if not a deposit. (Tier 2 — Fact_CustomerAction passthrough) |
| 27 | HistoryID | decimal(38,0) | YES | Unique history event identifier from production. Links back to Fact_CustomerAction.HistoryID. Used as secondary MERGE key. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 28 | FirstEver | int | YES | 1 = absolute first time this GCID performed this ActionTypeID. 0 = unique HistoryID event captured via secondary MERGE. (Tier 2 — SP_Fact_FirstCustomerAction) |

---

## 5. Lineage

### 5.1 Source Pipeline

```
Production → Data Lake → DWH_staging → SP_Fact_CustomerAction_DL_To_Synapse → Fact_CustomerAction
                                                                                    │
                                        SP_Fact_FirstCustomerAction_DL_To_Synapse ──┘
                                            │
                                            └─ SP_Fact_FirstCustomerAction (MERGE ×2)
                                                → Fact_FirstCustomerAction
```

### 5.2 Column Mapping

All columns except `FirstOccurred`, `UpdateDate`, `UpdateDateID`, and `FirstEver` are direct passthroughs from `Fact_CustomerAction`. `FirstOccurred` maps to `Fact_CustomerAction.Occurred`.

---

## 6. Relationships

### 6.1 References To (this table points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID, RealCID, DemoCID | DWH_dbo.Dim_Customer | Customer who performed the action |
| ActionTypeID | DWH_dbo.Dim_ActionType | Type of action |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument (for trades) |
| CampaignID | DWH_dbo.Dim_Campaign | Marketing campaign |
| PlatformTypeID | DWH_dbo.Dim_PlatformType | Platform used |
| BonusTypeID | DWH_dbo.Dim_BonusType | Bonus type |
| FundingTypeID | DWH_dbo.Dim_FundingType | Funding method |
| CompensationReasonID | DWH_dbo.Dim_CompensationReason | Compensation reason |
| DateID | DWH_dbo.Dim_Date | Calendar date |
| HistoryID | DWH_dbo.Fact_CustomerAction | Source event |

### 6.2 Referenced By

No known downstream consumers — this is a terminal analytical table used for ad-hoc funnel queries.

---

## 7. Sample Queries

### 7.1 Time to first deposit after registration

```sql
SELECT
    f.GCID,
    c.RegistrationDateID,
    f.DateID AS FirstDepositDateID,
    DATEDIFF(DAY,
        CAST(CAST(c.RegistrationDateID AS VARCHAR) AS DATE),
        CAST(CAST(f.DateID AS VARCHAR) AS DATE)
    ) AS DaysToFirstDeposit
FROM DWH_dbo.Fact_FirstCustomerAction f
JOIN DWH_dbo.Dim_Customer c ON f.GCID = c.GCID
WHERE f.ActionTypeID = @depositActionTypeID
  AND f.FirstEver = 1
  AND f.DateID >= 20260101;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | DWH usage: first deposit date, first login, customer actions — aligns with “first occurrence” analytics. |
| [Unified FTD Event & API](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12815073330/Unified+FTD+Event+API) | Confluence | First-time deposit API (`/customers/{gcid}/first-time-deposit`) — parallel concept to first-deposit milestones. |
| [Minimum / Maximum Deposit limitations](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11706499284/Minimum+Maximum+Deposit+limitations) | Confluence | **FTD** (first-time deposit) business rules. |
| [Global Deposit/FTD - Integrating with new account](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13558218769/Global+Deposit+FTD+-+Integrating+with+new+account) | Confluence | Unified FTD metrics and API paths in payments. |

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4 [UNVERIFIED], 1 T4 — Confluence, 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Fact_FirstCustomerAction | Type: Table | Production Source: Fact_CustomerAction (DWH-internal)*


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

### Upstream `DWH_dbo.Dim_FundingType` — synapse
- **Resolved as**: `DWH_dbo.Dim_FundingType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md`

# DWH_dbo.Dim_FundingType

> Payment method dimension - maps funding type IDs to payment method names and behavioral flags for eToro deposits, withdrawals, and cashout eligibility. Used by billing and customer action fact tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FundingType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundingTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FundingType` is a payment method dimension with 44 rows (FundingTypeID 0-44, with ID 41 absent). Each row represents a payment method or funding channel that eToro customers use for deposits and withdrawals. Methods span credit cards, bank transfers, e-wallets, crypto, regional payment systems (Yandex, Qiwi, AliPay, WeChat, Przelewy24), and eToro-internal channels (eToroCryptoWallet, eToroMoney).

Three behavioral flags classify each method:
- `IsNewStyle`: modern-era payment integration (True = post-legacy platform)
- `IsSingleFunding`: one-time/single use (True = e.g., BankDraft, InternalPayment)
- `IsCashoutActive`: cashout/withdrawal supported via this method (True = bidirectional)

**FundingTypeID=0 (N/A)** is a DWH-injected synthetic null-sentinel row, inserted after the main staging load as a hardcoded VALUES insert. Fact tables use `ISNULL(FundingTypeID, 0)` to replace NULLs with this sentinel, enabling NULL-safe joins.

**FundingTypeID=27 (eToroCryptoWallet)** has hardcoded business logic: `SP_Fact_CustomerAction` calculates `IsRedeem = 1` when CreditTypeID=2 AND FundingTypeID=27. This hardcoding creates a maintenance risk if the crypto wallet ID changes.

This dimension is actively consumed by three major fact tables: `Fact_BillingDeposit`, `Fact_BillingWithdraw`, and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Payment Method Classification Flags

**What**: Three bit flags classify payment method behavior.

**Columns Involved**: `IsNewStyle`, `IsSingleFunding`, `IsCashoutActive`

**Rules**:
- `IsNewStyle`: FALSE only for BankDraft (4), WesternUnion (5), MoneyGram (9). These are legacy payment methods.
- `IsSingleFunding`: TRUE for one-time or non-reusable methods: BankDraft (4), WesternUnion (5), MoneyGram (9), InternalPayment (16), TestDeposit (18), IBDeposit (19)
- `IsCashoutActive`: FALSE for methods where withdrawal is not supported: Giropay (11), Payoneer (14), Sofort (15), InternalPayment (16), LocalBankWire (17), TestDeposit (18), CashU (24), AliPay (25), WeChat (26), RapidTransfer (30), AstroPay (31), EtoroOptions (42), MoneyFarm (44)

### 2.2 Null Sentinel (FundingTypeID=0)

**What**: FundingTypeID=0 / Name='N/A' is a synthetic row added post-staging to represent unknown/missing funding type.

**Columns Involved**: `FundingTypeID`, `DWHFundingTypeID`

**Rules**:
- SP_Fact_CustomerAction uses `ISNULL(FundingTypeID, 0)` and `ISNULL(d.FundingTypeID, ISNULL(dd.FundingTypeID, 0))` to coerce NULLs to 0
- For the N/A row: DWHFundingTypeID=0 (same as FundingTypeID), all flags=False
- Inserted via hardcoded VALUES block in SP_Dictionaries (not from staging)

### 2.3 eToroCryptoWallet Hardcoded Logic

**What**: FundingTypeID=27 (eToroCryptoWallet) drives the `IsRedeem` flag in Fact_CustomerAction.

**Columns Involved**: `FundingTypeID`

**Rules**:
- `IsRedeem = CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`
- This hardcoded check appears in multiple sections of SP_Fact_CustomerAction
- Risk: If eToroCryptoWallet is assigned a new FundingTypeID, IsRedeem calculation breaks silently

### 2.4 DWHFundingTypeID Passthrough

**What**: `DWHFundingTypeID` mirrors `FundingTypeID` for all source rows (passthrough from staging).

**Rules**:
- For rows from staging: `DWHFundingTypeID = FundingTypeID` (same value, ETL SET `[FundingTypeID] as [DWHFundingTypeID]`)
- For the N/A row (FundingTypeID=0): `DWHFundingTypeID = 0`
- Purpose is likely for DWH-layer remapping or future surrogate key substitution. Currently identical to FundingTypeID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (44 rows - appropriate). CLUSTERED INDEX on FundingTypeID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 44 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundingTypeID to name | `LEFT JOIN DWH_dbo.Dim_FundingType ON FundingTypeID` |
| Find cashout-eligible methods | `WHERE IsCashoutActive = 1` |
| Identify legacy payment methods | `WHERE IsNewStyle = 0` |
| Exclude N/A sentinel | `WHERE FundingTypeID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | ON FundingTypeID | Payment method for deposits |
| DWH_dbo.Fact_BillingWithdraw | ON FundingTypeID_Withdraw / FundingTypeID_Funding | Payment method for withdrawals |
| DWH_dbo.Fact_CustomerAction | ON FundingTypeID | Payment method for customer financial actions |

### 3.4 Gotchas

- **FundingTypeID=0 is synthetic**: The N/A row (ID=0) does not come from the source system. It is DWH-injected after TRUNCATE+INSERT. Never filter it out blindly - fact tables use it for NULL FK rows.
- **FundingTypeID=41 missing**: The sequence jumps from 40 to 42. ID 41 was likely deleted or never assigned.
- **FundingTypeID=27 hardcoded**: eToroCryptoWallet ID is hardcoded in SP_Fact_CustomerAction for IsRedeem logic. Do not renumber/reassign this ID.
- **FundingTypeID is smallint NULL**: Nullable primary key with NOT NULL-equivalent usage. Join columns in fact tables may be int - implicit type conversion occurs.
- **Fact_BillingWithdraw has TWO FK columns**: `FundingTypeID_Withdraw` (the withdrawal method) and `FundingTypeID_Funding` (the original funding method). Both reference this dimension.

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
| 1 | FundingTypeID | smallint | YES | Primary key identifying the payment method. (Tier 1 — Dictionary.FundingType) |
| 2 | Name | varchar(50) | NO | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 — Dictionary.FundingType) |
| 3 | IsNewStyle | bit | NO | Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 — Dictionary.FundingType) |
| 4 | IsSingleFunding | bit | NO | Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 — Dictionary.FundingType) |
| 5 | IsCashoutActive | bit | NO | Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 — Dictionary.FundingType) |
| 6 | DWHFundingTypeID | smallint | NO | DWH copy of FundingTypeID. SET in ETL as `[FundingTypeID] as [DWHFundingTypeID]`. Currently identical to FundingTypeID for all rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows (both staging rows and N/A sentinel). Likely means active. No corresponding Dim_Status table found. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 8 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() (stored as @ddate variable). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 9 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate). Both columns set on each run. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | passthrough |
| Name | etoro.Dictionary.FundingType | Name | passthrough |
| IsNewStyle | etoro.Dictionary.FundingType | IsNewStyle | passthrough |
| IsSingleFunding | etoro.Dictionary.FundingType | IsSingleFunding | passthrough |
| IsCashoutActive | etoro.Dictionary.FundingType | IsCashoutActive | passthrough |
| DWHFundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | ETL-computed: same as FundingTypeID (alias) |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FundingType -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FundingType
    -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 672) -> Dim_FundingType (rows 1-44)
    -> SP_Dictionaries_DL_To_Synapse (VALUES INSERT, ~line 1475) -> Dim_FundingType row 0 (N/A sentinel)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FundingType | Payment method dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FundingType/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FundingType | Raw import |
| ETL (main) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 672 | TRUNCATE + INSERT. Adds DWHFundingTypeID=FundingTypeID, StatusID=1, UpdateDate/InsertDate=GETDATE(). |
| ETL (sentinel) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 1475 | Hardcoded VALUES INSERT for FundingTypeID=0, Name='N/A'. |
| Target | DWH_dbo.Dim_FundingType | 44-row REPLICATE/CLUSTERED dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingDeposit | FundingTypeID | Payment method for each deposit transaction |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Withdrawal payment method |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Funding | Original funding method for withdrawal |
| DWH_dbo.Fact_CustomerAction | FundingTypeID | Payment method for customer financial actions |

---

## 7. Sample Queries

### 7.1 All payment methods with cashout support

```sql
SELECT FundingTypeID, Name, IsNewStyle, IsSingleFunding
FROM DWH_dbo.Dim_FundingType
WHERE IsCashoutActive = 1 AND FundingTypeID > 0
ORDER BY FundingTypeID
```

### 7.2 Legacy (non-new-style) methods

```sql
SELECT FundingTypeID, Name, IsSingleFunding, IsCashoutActive
FROM DWH_dbo.Dim_FundingType
WHERE IsNewStyle = 0 AND FundingTypeID > 0
```

### 7.3 Join deposits with payment method name

```sql
SELECT ft.Name AS PaymentMethod, COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit bd
JOIN DWH_dbo.Dim_FundingType ft ON bd.FundingTypeID = ft.FundingTypeID
WHERE ft.FundingTypeID > 0
GROUP BY ft.Name
ORDER BY DepositCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 8/10*
*Object: DWH_dbo.Dim_FundingType | Type: Table | Production Source: etoro.Dictionary.FundingType*


### Upstream `DWH_dbo.Dim_BillingDepot` — synapse
- **Resolved as**: `DWH_dbo.Dim_BillingDepot`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md`

# DWH_dbo.Dim_BillingDepot

> Lookup dimension of payment gateway endpoints ("depots"), each configuring one (FundingType + PaymentType + Protocol) routing combination. Sourced daily from etoro.Billing.Depot via SP_Dictionaries_DL_To_Synapse. 163 rows; 114 active.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Depot |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingDepot is the DWH version of etoro.Billing.Depot -- the central payment gateway routing configuration table. Each row defines one payment depot: a named combination of payment method (FundingTypeID), payment direction (PaymentTypeID: Deposit/Cashout/Refund), and processing gateway (ProtocolID). The routing engine selects a depot to process each transaction based on these three dimensions plus customer-specific factors (regulation, BIN, quotas).

Source: etoro.Billing.Depot on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Billing/Depot/ and staged into DWH_staging.etoro_Billing_Depot. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

163 rows total (DepotID range 1-174 with gaps); 114 active (70%), 49 inactive (legacy or decommissioned). The DWH includes only 7 of the 8 production columns -- PayoutGeneration and Features are excluded by the ETL SELECT.

Sample depots: 1=MoneyBookers USD, 7=Neteller, 10=Wire, 3=WebMoney, 4=Giropay.

---

## 2. Business Logic

### 2.1 Depot Routing Selection

**What**: The payment routing engine selects a depot for each transaction based on FundingTypeID, PaymentTypeID, and ProtocolID combined with customer-specific routing criteria.

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `IsActive`

**Rules**:
- Only depots with IsActive=1 are eligible for routing (114 of 163)
- IsActive=0 or NULL means the depot is inactive (legacy or decommissioned) -- excluded from routing
- The (FundingTypeID, PaymentTypeID, ProtocolID) triple uniquely identifies a depot endpoint
- PaymentTypeID: 1=Deposit, 2=Cashout, 3=Refund

**Dimension Relationships**:
- FundingTypeID references Dictionary.FundingType (payment method: CreditCard, Wire, Neteller, etc.)
- PaymentTypeID references Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
- ProtocolID references Dictionary.Protocol (specific gateway API)

### 2.2 DWH Completeness Note

**Excluded from DWH**: The production Billing.Depot table also has PayoutGeneration (automated payout file support) and Features (per-depot JSON/XML configuration flags). These columns are not in the SP SELECT and are not present in Dim_BillingDepot. Analyses requiring payout generation capability or feature flags must query the production source.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. REPLICATE is correct for a 163-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs. The clustered index on DepotID supports efficient point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 163-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active payment depots | WHERE IsActive = 1 |
| Deposit depots by payment method | WHERE PaymentTypeID = 1, GROUP BY FundingTypeID |
| Cashout-capable depots | WHERE PaymentTypeID = 2 AND IsActive = 1 |
| Depots for a specific gateway | WHERE ProtocolID = N |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON DepotID | MID configuration per depot |
| Fact tables (deposit/cashout) | ON DepotID | Resolve depot name and attributes for transactions |

### 3.4 Gotchas

- **IsActive NULL = Inactive**: The column is nullable. NULL should be treated as inactive (not eligible for routing). Use `WHERE IsActive = 1` rather than `WHERE IsActive <> 0`.
- **No InsertDate**: Unlike most other Dim_ tables loaded by SP_Dictionaries, this table has only UpdateDate (no InsertDate, no StatusID, no DWH surrogate key).
- **PayoutGeneration/Features not in DWH**: Two production columns are excluded. For payout batch analysis, the production source must be queried directly.
- **163 rows total, 114 active**: Inactive rows represent legacy/decommissioned gateway integrations. Do not assume all rows are usable.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.Depot) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepotID | int | NOT NULL | Primary key. Manually assigned (no IDENTITY). Stable identifier for this payment gateway endpoint. Range 1-174 with gaps; 163 rows. Referenced by fact deposit/cashout tables and MID settings. (Tier 1 - upstream wiki, Billing.Depot) |
| 2 | FundingTypeID | int | NOT NULL | Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References Dictionary.FundingType. 38 distinct values across 163 depots. (Tier 1 - upstream wiki, Billing.Depot) |
| 3 | PaymentTypeID | int | NOT NULL | Direction of payment flow. 1=Deposit, 2=Cashout, 3=Refund. References Dictionary.PaymentType. (Tier 1 - upstream wiki, Billing.Depot) |
| 4 | ProtocolID | int | NOT NULL | Payment processing protocol/gateway. References Dictionary.Protocol. Identifies the specific API or connection (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). (Tier 1 - upstream wiki, Billing.Depot) |
| 5 | Name | varchar(50) | NOT NULL | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, Billing.Depot) |
| 6 | IsActive | bit | YES | Whether this depot currently accepts transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. (Tier 1 - upstream wiki, Billing.Depot) |
| 7 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production depot configuration changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DepotID | etoro.Billing.Depot | DepotID | Passthrough |
| FundingTypeID | etoro.Billing.Depot | FundingTypeID | Passthrough |
| PaymentTypeID | etoro.Billing.Depot | PaymentTypeID | Passthrough |
| ProtocolID | etoro.Billing.Depot | ProtocolID | Passthrough |
| Name | etoro.Billing.Depot | Name | Passthrough |
| IsActive | etoro.Billing.Depot | IsActive | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| *(excluded)* | etoro.Billing.Depot | PayoutGeneration | Not loaded into DWH |
| *(excluded)* | etoro.Billing.Depot | Features | Not loaded into DWH |

### 5.2 ETL Pipeline

```
etoro.Billing.Depot -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/Depot/ -> DWH_staging.etoro_Billing_Depot -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingDepot
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.Depot | 163-row payment depot registry (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/Depot/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_Depot | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; 7 of 8 production columns loaded; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingDepot | 163 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepotID | etoro.Billing.Depot | Production source (upstream reference) |
| FundingTypeID | etoro.Dictionary.FundingType | Payment method lookup (implicit -- no FK in DWH) |
| PaymentTypeID | etoro.Dictionary.PaymentType | Payment direction lookup (implicit -- no FK in DWH) |
| ProtocolID | etoro.Dictionary.Protocol | Gateway protocol lookup (implicit -- no FK in DWH) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | DepotID | MID configuration per depot |

---

## 7. Sample Queries

### 7.1 List active depots

```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID
FROM [DWH_dbo].[Dim_BillingDepot]
WHERE IsActive = 1
ORDER BY FundingTypeID, PaymentTypeID
```

### 7.2 Count depots by payment direction

```sql
SELECT
    PaymentTypeID,
    CASE PaymentTypeID WHEN 1 THEN 'Deposit' WHEN 2 THEN 'Cashout' WHEN 3 THEN 'Refund' ELSE 'Unknown' END AS Direction,
    COUNT(*) AS TotalDepots,
    SUM(CAST(ISNULL(IsActive, 0) AS INT)) AS ActiveDepots
FROM [DWH_dbo].[Dim_BillingDepot]
GROUP BY PaymentTypeID
ORDER BY PaymentTypeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS DepotCount
FROM [DWH_dbo].[Dim_BillingDepot]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 6 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingDepot | Type: Table | Production Source: etoro.Billing.Depot*


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


### Upstream `BI_DB_dbo.BI_DB_AppFlyer_Reports` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_AppFlyer_Reports`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AppFlyer_Reports.md`

---
table: BI_DB_dbo.BI_DB_AppFlyer_Reports
schema: BI_DB_dbo
documented: 2026-04-22
batch: 51
quality_score: 8.5
tier: Tier 3
row_count_approx: 128600000
date_range: 2022-10-25 to 2026-04-12
etl_frequency: Daily
etl_sp: BI_DB_dbo.SP_AppFlyer_Reports
opsdb_priority: 0
---

# BI_DB_AppFlyer_Reports

## 1. Purpose

User-level and event-level mobile attribution log from the **AppFlyer platform**. This is the raw, per-install and per-in-app-event export — the most granular AppFlyer dataset in BI_DB_dbo. Each row represents a single attributed mobile event: either an app install or an in-app event (trade, registration, deposit, KYC, etc.) attributed to a specific acquisition source.

Three AppFlyer report types are merged into this table, distinguished by `EtoroReport`:
- **`OrganicInstalls`** — installs not attributed to any paid campaign
- **`Installs`** — installs attributed to paid media (click or impression)
- **`InAppEvents`** — post-install in-app events carrying business outcomes (trades, registrations, FTDs, redeposits)

Used by the marketing analytics team for channel attribution, conversion funnel analysis, and LTV modeling. Feeds directly into `BI_DB_MarketingDailyRawData` / `BI_DB_MarketingMonthlyRawData` via `SP_Marketing_Cube`.

## 2. Source & Lineage

| Layer | Object |
|-------|--------|
| Origin | AppFlyer Platform (third-party mobile attribution SaaS) |
| Staging | `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext` (all-varchar, HEAP staging) |
| Writer SP | `BI_DB_dbo.SP_AppFlyer_Reports` (Katy F, 2016-05-25) |
| ETL pattern | Daily DELETE+INSERT (single-day replace by `DateID`) |
| OpsDB | Priority 0, SB_Daily, ProcessType SQL |

AppFlyer merges three report types into one staging export → SP type-casts key fields, standardizes CountryCode, and rejects malformed timestamp strings → typed target. `UpdateDate` column is in the DDL but **not in the INSERT list** — always NULL.

See [BI_DB_AppFlyer_Reports.lineage.md](BI_DB_AppFlyer_Reports.lineage.md) for full pipeline detail.

## 3. Grain

One row per **attributed mobile event** (install or in-app event).

- `EtoroReport` partitions the event type: `OrganicInstalls` / `Installs` / `InAppEvents`
- `AppsFlyerID` is the unique AppFlyer device+install identifier — the closest thing to a row key
- `CustomerUserID` (when populated) links an in-app event to an eToro customer (hashed)
- `DateID` / `Date` = **event date** (the date the event fired). For `InAppEvents`, this differs from `InstallTime`.

## 4. Distribution & Clustering

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Clustering | CLUSTERED INDEX on `Date ASC, EtoroReport ASC` |
| Date range (live) | 2022-10-25 → 2026-04-12 |
| Row count | ~128.6M (86.3M OrganicInstalls + 35.6M InAppEvents + 6.8M Installs) |

## 5. Column Reference

### Attribution & Touch Columns

| Column | Type | Description |
|--------|------|-------------|
| `AttributedTouchType` | varchar(4000) | Attribution model: `click` (user clicked an ad), `impression` (view-through attribution), or empty/NULL (organic — no paid touch). 88.4M empty rows (organic), 31.8M click, 8.0M impression. |
| `AttributedTouchTime` | datetime | Timestamp of the attributed ad click or impression. NULL for organic installs (SP converts AppFlyer 'None' string → SQL NULL). |
| `InstallTime` | datetime | Timestamp when the app was installed. Present on all rows (install events and in-app events alike). For InAppEvents, this is the original install date — may be far in the past. |
| `AttributionLookback` | varchar(4000) | AppFlyer attribution lookback window setting active at the time of attribution (e.g., `'1d'`, `'7d'`). |
| `ReengagementWindow` | varchar(4000) | AppFlyer re-engagement window for retargeting campaigns. |
| `IsPrimaryAttribution` | varchar(4000) | `'true'` / `'false'` string. Indicates whether this is the primary attributed source (vs a re-engagement event). SP normalizes all non-'1' values to 'false'. |
| `IsRetargeting` | varchar(4000) | `'true'` / `'false'` string. Whether this event is from a retargeting (re-engagement) campaign rather than new user acquisition. |
| `RetargetingConversionType` | varchar(4000) | For retargeting events: the conversion type (e.g., `re-engagement`, `re-attribution`). NULL for non-retargeting rows. |

### Campaign & Media Source Columns

| Column | Type | Description |
|--------|------|-------------|
| `Partner` | varchar(4000) | AppFlyer partner agency or integrated partner name. |
| `MediaSource` | varchar(4000) | Attribution source — ad network or channel. Examples: `googleadwords_int` (Google UAC), `bytedanceglobal_int` (TikTok), `Facebook Ads`, `eToroWeb` (web-to-app redirect), `Organic`, `restricted`. |
| `Channel` | varchar(4000) | Sub-channel within the media source (e.g., `ACI_Search`, `GoogleSearch`). |
| `Keywords` | varchar(4000) | Search keywords associated with the paid campaign (for search campaigns). |
| `Campaign` | varchar(4000) | Campaign name as reported by AppFlyer. Format varies by network. |
| `CampaignID` | varchar(4000) | Numeric campaign identifier from the ad network. |
| `Adset` | varchar(4000) | Ad set name within the campaign. |
| `AdsetID` | varchar(4000) | Ad set numeric identifier. |
| `Ad` | varchar(4000) | Individual ad creative name or description. |
| `AdID` | varchar(4000) | Ad creative numeric identifier. |
| `AdType` | varchar(4000) | Ad format type (e.g., `ClickToDownload`). |
| `SiteID` | varchar(4000) | Publisher site identifier (for DSP/network buys). |
| `SubSiteID` | varchar(4000) | Sub-publisher identifier. |
| `SubParam1` – `SubParam5` | varchar(4000) | Custom tracking parameters passed through AppFlyer deep link (`af_sub1`–`af_sub5`). Used for publisher IDs, placement names, and custom tracking values. |
| `CostModel` | varchar(4000) | Pricing model for this placement (CPC, CPM, CPA, etc.). |
| `CostValue` | varchar(4000) | Cost amount per unit in the cost model. |
| `CostCurrency` | varchar(4000) | Currency of the cost value. |

### Multi-Touch Attribution (Contributor Columns)

AppFlyer records up to 3 contributing touchpoints before the attributed install. Contributor1 is the most recent non-attributed touch.

| Column | Type | Description |
|--------|------|-------------|
| `Contributor1Partner` | varchar(4000) | Partner of the first contributing (non-attributed) touch. |
| `Contributor1MediaSource` | varchar(4000) | Media source of contributing touch 1. |
| `Contributor1Campaign` | varchar(4000) | Campaign of contributing touch 1. |
| `Contributor1TouchType` | varchar(4000) | Touch type of contributing touch 1 (click/impression). |
| `Contributor1TouchTime` | varchar(4000) | Timestamp of contributing touch 1, stored as varchar. SP converts 'None'/'USD'/'usd' → NULL. |
| `Contributor2Partner` | varchar(4000) | Partner of contributing touch 2. |
| `Contributor2MediaSource` | varchar(4000) | Media source of contributing touch 2. |
| `Contributor2Campaign` | varchar(4000) | Campaign of contributing touch 2. |
| `Contributor2TouchType` | varchar(4000) | Touch type of contributing touch 2. |
| `Contributor2TouchTime` | varchar(4000) | Timestamp of contributing touch 2, stored as varchar. Same NULL conversion as Contributor1TouchTime. |
| `Contributor3Partner` | varchar(4000) | Partner of contributing touch 3. |
| `Contributor3MediaSource` | varchar(4000) | Media source of contributing touch 3. |
| `Contributor3Campaign` | varchar(4000) | Campaign of contributing touch 3. |
| `Contributor3TouchType` | varchar(4000) | Touch type of contributing touch 3. |
| `Contributor3TouchTime` | **datetime** | Timestamp of contributing touch 3, stored as datetime (inconsistent with Contributor1/2TouchTime which are varchar — architectural anomaly). |

### Geographic Columns

| Column | Type | Description |
|--------|------|-------------|
| `Region` | varchar(4000) | AppFlyer macro-region code (e.g., `EU`, `AS`, `NA`). |
| `CountryCode` | varchar(4000) | ISO-2 country code. SP applies `CASE WHEN 'UK' THEN 'GB'` standardization (unlike `BI_DB_AppFlyer_Geo` which does not). |
| `State` | varchar(4000) | State or province (where available). |
| `City` | varchar(500) | **DDM-masked** with `default()` function. Shows as `'xxxx'` to non-privileged users. Contains the city of the device at install/event time. |
| `PostalCode` | varchar(4000) | Postal/ZIP code of the device. |
| `DMA` | varchar(4000) | DMA (Designated Market Area) code — US-only market area identifier. 'None' for non-US. |
| `Operator` | varchar(4000) | Mobile network operator name (e.g., 'Vodafone'). |
| `Carrier` | varchar(4000) | Mobile carrier identifier. |
| `WIFI` | varchar(4000) | `'true'` / `'false'` string. Whether the device was on Wi-Fi at the time of the event. |

### Device & App Columns

| Column | Type | Description |
|--------|------|-------------|
| `AppsFlyerID` | varchar(4000) | AppFlyer's unique device+install identifier. Primary key at AppFlyer's system level — identifies a specific install on a specific device. |
| `AdvertisingID` | varchar(4000) | Android GAID (Google Advertising ID) — device-level advertising identifier for Android. |
| `IDFA` | varchar(4000) | iOS IDFA (Identifier for Advertisers) — device-level advertising identifier for iOS. May be empty post-iOS14 ATT framework changes. |
| `IDFV` | varchar(4000) | iOS IDFV (Identifier for Vendor) — app-level device identifier for iOS. |
| `AndroidID` | varchar(4000) | Android hardware device ID. |
| `IMEI` | varchar(4000) | Device IMEI number. Typically empty for modern devices (IMEI collection restricted). |
| `CustomerUserID` | varchar(4000) | Hashed eToro customer identifier passed to AppFlyer at registration/login. Links AppFlyer events to eToro users. Present on InAppEvents for registered users; empty on raw installs. |
| `Platform` | varchar(4000) | Mobile OS: `'android'` or `'ios'`. ~75% android, ~23% ios; ~2% None (unknown/legacy). |
| `DeviceType` | varchar(4000) | Device form factor (phone, tablet). Often empty. |
| `OSVersion` | varchar(4000) | Operating system version string (e.g., `'13'`, `'16.1.1'`). |
| `AppVersion` | varchar(4000) | eToro app version string (e.g., `'651.114.0'`, `'618.0.0'`). |
| `SDKVersion` | varchar(4000) | AppFlyer SDK version embedded in the app (e.g., `'v6.12.2'`). |
| `AppID` | varchar(4000) | App store identifier (Android: `'com.etoro.openbook'`; iOS: `'id674984916'`). Uses dot notation (native format), unlike `EtoroAppID`. |
| `AppName` | varchar(4000) | App store display name at the time of the event. Not a constant — changed over time (e.g., `'eToro: Investing made social'` → `'eToro: Trade. Invest. Connect.'`). |
| `BundleID` | varchar(4000) | iOS/Android bundle identifier. Same value as `AppID`. |
| `Language` | varchar(4000) | Device language setting (e.g., `'Deutsch'`, `'English'`). |
| `UserAgent` | varchar(4000) | HTTP user agent string from the attribution redirect. Often empty. |

### Event Columns

| Column | Type | Description |
|--------|------|-------------|
| `EventName` | varchar(4000) | Name of the event as reported by AppFlyer. For install rows: `'install'`. For InAppEvents: business event names such as `'Open Trade'` (24.6M), `'Registration_S2S'` (2.1M), `'Redeposit_S2S'` (2.1M), `'registration'` (1.9M), `'Verification Level - 1/2/3'`, `'Redeposit'`, `'FTD_S2S'`. Suffix `_S2S` = server-to-server event reported by eToro backend (more reliable than SDK events). |
| `EventTime` | varchar(4000) | Timestamp string of when the in-app event fired (stored as varchar, not cast to datetime). For install events, same as `InstallTime`. |
| `EventValue` | varchar(4000) | JSON payload for in-app events containing AppFlyer event parameters. Example: `{"af_content":"Bitcoin","af_content_type":"Crypto","af_content_id":"100000","is_copy":"False","af_revenue":"14"}`. Empty for install events. |
| `EventRevenue` | varchar(4000) | Revenue amount associated with this event in the reported currency. Populated for trade events (e.g., `'14'`, `'250'`, `'2244'`). |
| `EventRevenueCurrency` | varchar(4000) | Currency of EventRevenue (typically `'USD'`). |
| `EventRevenueUSD` | varchar(4000) | Revenue converted to USD. Same value as EventRevenue when currency is already USD. |
| `EventSource` | varchar(4000) | How the event was reported: `'SDK'` (AppFlyer SDK on device, ~95M rows) or `'S2S'` (server-to-server from eToro backend, ~31.5M rows). ~1M rows have garbled values (malformed JSON fragments from upstream AppFlyer export data quality issues). |
| `IsReceiptValidated` | varchar(4000) | AppFlyer receipt validation result for in-app purchases. Typically empty (most events are not app-store purchases). |
| `HTTPReferrer` | varchar(4000) | HTTP referrer URL from the AppFlyer attribution redirect. Truncated to 4000 chars by SP (`LEFT([HTTPReferrer], 4000)`). |
| `OriginalURL` | varchar(4000) | Original deep link URL used in the attribution (e.g., `etoro://markets/gold`). |

### ETL & Partition Columns

| Column | Type | Description |
|--------|------|-------------|
| `DateID` | INT | Event date as YYYYMMDD integer. ETL partition key used by SP for DELETE+INSERT targeting. `DateID = Date` in YYYYMMDD format. |
| `Date` | datetime | Event date (the date on which this install or in-app event occurred). **Not the install date** for InAppEvents — may differ from `InstallTime` significantly. |
| `EtoroAppID` | varchar(4000) | AppFlyer app identifier: `'com_etoro_openbook'` (Android, using underscore separator) or `'id674984916'` (iOS). |
| `EtoroAppName` | varchar(4000) | Human-readable platform label: `'OneApp Android'` or `'OneApp iOS'`. Set by the AppFlyer export config; consistent within this table. |
| `EtoroReport` | varchar(4000) | AppFlyer report type — the key partition dimension. Values: `'OrganicInstalls'` (86.3M), `'InAppEvents'` (35.6M), `'Installs'` (6.8M). Always filter by this column to avoid mixing event types. |
| `UpdateDate` | datetime | **Always NULL.** Column exists in DDL but is not in the SP INSERT list — never populated. |

## 6. ETL Notes

- **SP_AppFlyer_Reports** runs daily with parameter `@dt DATE`. DELETE WHERE `DateID = @dt_int` then INSERT from `BI_DB_AppFlyer_Reports_Ext`.
- Most columns pass through unchanged from the all-varchar staging table — only `AttributedTouchTime`, `InstallTime`, `Contributor3TouchTime` are cast to datetime; `DateID` is int; `Date` is datetime.
- `CountryCode` is the only standardization applied: 'UK' → 'GB'.
- `HTTPReferrer` is truncated to 4000 chars (same as column size — prevents overflow).
- `UpdateDate` was likely intended for ETL timestamp tracking but was never wired into the INSERT.

## 7. Usage Notes

- **Always filter by `EtoroReport`** before aggregating — mixing install and in-app event rows produces meaningless counts.
- **Install funnel**: `EtoroReport IN ('OrganicInstalls','Installs')` AND `EventName = 'install'` → unique installs per channel/geo.
- **Revenue attribution**: `EtoroReport = 'InAppEvents'` AND `EventName IN ('Open Trade','FTD_S2S','Redeposit_S2S')` → attributed revenue events.
- **User linkage**: `CustomerUserID` links AppFlyer events to eToro users (hashed). Available for InAppEvents from registered users; empty on raw installs.
- **Date vs InstallTime**: For cohort analysis (events by install month), use `InstallTime`. For event volume analysis (events by calendar day), use `Date`/`DateID`.
- **S2S vs SDK events**: `EventSource = 'S2S'` events are server-reported (higher fidelity). `EventSource = 'SDK'` events come from the device SDK (may have delays or duplicates in edge cases).
- **Platform split**: `Platform = 'android'` (75%) vs `Platform = 'ios'` (23%). `EtoroAppID` provides a cleaner split than `Platform` (no None rows).
- **City data**: Only accessible to privileged users with unmasked access to DDM columns.
- **Aggregate geo summary**: For aggregate country-level metrics without PII sensitivity, use `BI_DB_AppFlyer_Geo` instead.

## 8. Quality & Caveats

| Issue | Detail |
|-------|--------|
| `UpdateDate` always NULL | Column exists in DDL but SP never populates it. Do not use for ETL freshness tracking. |
| `EventSource` garbled values | ~1.1M rows have malformed EventSource values (fragments like `"af_revenue":"0"}"` or `USD`). These are upstream AppFlyer data quality issues, not ETL corruption. Filter `EventSource IN ('SDK','S2S')` for clean analysis. |
| `Contributor3TouchTime` type mismatch | DDL types it as `datetime` while `Contributor1/2TouchTime` are `varchar`. SP behavior is consistent (NULL cleanup), but the inconsistency means Contributor3TouchTime cannot hold the same malformed strings that Contributor1/2 might. |
| `City` DDM-masked | Shows as `'xxxx'` to non-privileged users. Cannot be used for geographic analysis without elevated access. |
| IDFA sparsity | Post-iOS14 ATT framework (2021), most iOS users opt out of IDFA tracking. Expect high NULL/empty rate for IDFA on recent iOS rows. |
| `AppName` not constant | Changed across app versions. Do not use as a stable filter — use `EtoroAppID` or `Platform` instead. |
| `EventTime` as varchar | Stored as string, not datetime. Parse with `TRY_CAST(EventTime AS datetime)` if needed. |
| No CID column | `CustomerUserID` is hashed — requires mapping to resolve to eToro CIDs. For user-level eToro analytics, join via the CustomerUserID hash mapping table (if available). |


### Upstream `BI_DB_dbo.Function_Population_Funded` — synapse
- **Resolved as**: `BI_DB_dbo.Function_Population_Funded`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Population_Funded.md`

# Function_Population_Funded

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 3 (T1: 0, T2: 3) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

On a single **`@dateInt`**, returns customers who are **past their first-funded date** per `Function_Population_First_Time_Funded` **and** have **positive combined equity** that day from **trading-platform balances**, **eMoney** settled balance, or **options** AUM (valid customers only on options leg). Prevents “funded” without an actual deposit/funded milestone.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @dateInt | INT | Date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Function_Population_First_Time_Funded | BI_DB_dbo |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo |
| eMoneyClientBalance | eMoney_dbo |
| Function_AUM_OptionsPlatform | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | BI_DB_Client_Balance_CID_Level_New.DateID, eMoneyClientBalance.BalanceDateID, Function_AUM_OptionsPlatform.DateID | All legs **`= @dateInt`**; outer `GROUP BY DateID, RealCID` | T2 |
| 2 | RealCID | BI_DB_Client_Balance_CID_Level_New.CID, eMoneyClientBalance.CID, Function_AUM_OptionsPlatform.RealCID | `CID AS RealCID` / direct from options TVF; **inner join** to **`Function_Population_First_Time_Funded`** on **`RealCID`** with **`FirstFundedDateID <= DateID`** | T2 |
| 3 | Equity | BI_DB_Client_Balance_CID_Level_New, eMoneyClientBalance, Function_AUM_OptionsPlatform | `SUM(Equity)` over union: **(1)** `SUM(ISNULL(TotalLiability,0)+ISNULL(actualNWA,0))` per CID **WHERE** `DateID = @dateInt`; **(2)** `ClosingBalanceBO * USDApproxRate` **WHERE** `BalanceDateID = @dateInt` **AND** `ClosingBalanceCalc > 0`; **(3)** `OptionsTotalEquity` from **`Function_AUM_OptionsPlatform(@dateInt, 1)`** **WHERE** `DateID = @dateInt` **AND** `OptionsTotalEquity > 0`. **Kept only if** joined first-funded row exists **and** aggregated **`Equity > 0`** | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-08-03 | Guy M | Fix: bonus users without deposit no longer counted funded |
| 2025-11-05 | Guy M | IBAN and options equity refresh |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*


### Upstream `BI_DB_dbo.Function_Population_First_Time_Funded` — synapse
- **Resolved as**: `BI_DB_dbo.Function_Population_First_Time_Funded`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Population_First_Time_Funded.md`

# Function_Population_First_Time_Funded

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 18 (T1: 2, T2: 16) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

For **depositors** with a warehouse **FTD** (excluding a curated “bad FTD” set), joins **first verified** snapshot range and left-joins **first trade**, **first IOB** (interest-on-balance), and **first options trade**. Computes a single **FirstFundedDateID/Date** as the latest of FTD, verification, and the earliest qualifying trading/options/IOB activity.

## 2. Parameters

No parameters.

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Dim_Customer | DWH_dbo |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo |
| Dim_FTDPlatform | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Position | DWH_dbo |
| Function_Revenue_OptionsPlatform | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Dim_Customer.RealCID | Direct (via `DWH_FTD`) | T1 |
| 2 | FTDPlatformID | Dim_Customer.FTDPlatformID | Direct | T1 |
| 3 | FTDPlatform | Dim_FTDPlatform.FTDPlatformName | `COALESCE(FTDPlatformName, 'TP')` | T2 |
| 4 | FTDDateID | Dim_Customer.FirstDepositDate | `CAST(CONVERT(VARCHAR(8), FirstDepositDate, 112) AS INT)` | T2 |
| 5 | FTDDate | Dim_Customer.FirstDepositDate | `CAST(FirstDepositDate AS DATE)` | T2 |
| 6 | FTDTime | Dim_Customer.FirstDepositDate | Same timestamp as FTD column (first deposit) | T2 |
| 7 | FirstTradeDateID | Dim_Position.OpenDateID | `MIN(OpenDateID)` **WHERE** `ISNULL(IsAirDrop,0) = 0`, grouped by `CID AS RealCID` | T2 |
| 8 | FirstTradeDate | Dim_Position.OpenDateID | `CONVERT(DATE, CONVERT(VARCHAR(8), MIN(OpenDateID)), 112)` under same **non-airdrop** position filter as row 7 | T2 |
| 9 | FirstTradeTime | Dim_Position.OpenOccurred | `MIN(OpenOccurred)` under same **non-airdrop** position filter as row 7 | T2 |
| 10 | FirstIOBDateID | Fact_CustomerAction.Occurred | `MIN(CAST(FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT))` where `ActionTypeID = 36` and `CompensationReasonID = 57` | T2 |
| 11 | FirstIOBDate | Fact_CustomerAction.Occurred | `CAST(MIN(Occurred) AS DATE)` | T2 |
| 12 | FirstIOBTime | Fact_CustomerAction.Occurred | `MIN(Occurred)` | T2 |
| 13 | FirstOptionsTradeDateID | Function_Revenue_OptionsPlatform.FirstTradeDateID | `MIN(FirstTradeDateID)` by `RealCID` | T2 |
| 14 | FirstOptionsTradeDate | Function_Revenue_OptionsPlatform.FirstTradeDate | `MIN(FirstTradeDate)` | T2 |
| 15 | FirstVerifiedDateID | Dim_Range.FromDateID | `MIN(FromDateID)` where `VerificationLevelID = 3` on snapshot | T2 |
| 16 | FirstVerifiedDate | Dim_Range.FromDateID | `CONVERT(DATE, CONVERT(VARCHAR(8), MIN(FromDateID)), 112)` | T2 |
| 17 | FirstFundedDateID | Dim_Customer, Dim_Range, Dim_Position, Fact_CustomerAction, Function_Revenue_OptionsPlatform | `GREATEST(FTDDateID, FirstVerifiedDateID, COALESCE(LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID), COALESCE(...)))` | T2 |
| 18 | FirstFundedDate | *(same as row 17)* | `CONVERT(DATE, CONVERT(VARCHAR(8), FirstFundedDateID), 112)` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-08-20 | Guy M | IOB alternative; removed false FTDs |
| 2025-09-30 | Guy M | IOB logic fix (trade after IOB) |
| 2025-10-16 | Guy M | Options trade; null handling |
| 2025-11-23 | Guy M | Bad FTD removal without harming legitimate later FTDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*


### Upstream `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md`

# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status

> 13.3B-row DDR customer daily status dimension — full daily snapshot of every customer's deposit status, account segmentation, FTD dates across all platforms (TP, IBAN, Options, MoneyFarm), regulation, login activity, and funded/active trading flags, providing the segmentation backbone for the entire DDR framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension — DDR daily customer status snapshot) |
| **Production Source** | Derived from 15+ sources via `SP_DDR_Customer_Daily_Status` — `BI_DB_Client_Balance_CID_Level_New`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Fact_CustomerAction`, `eMoney_Fact_Transaction_Status`, `MIMO_AllPlatforms`, plus 5 population functions |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Customer_Daily_Status` is the **central customer segmentation table** for the DDR framework. It maintains a **full daily snapshot** (not SCD) of every customer who has ever appeared in the eToro ecosystem — one row per CID per calendar day.

The population is built from five mutually exclusive sources:
1. **TP (Trading Platform)** — customers with balance records in `BI_DB_Client_Balance_CID_Level_New`
2. **IBAN (eMoney)** — IBAN-only customers from `eMoney_Fact_Transaction_Status` not in TP
3. **Options** — Options-platform customers from `Dim_Customer` (FTDPlatformID=2) not in TP/IBAN
4. **Options MIMO** — Options customers found only in MIMO transaction data
5. **MoneyFarm** — MoneyFarm customers (FTDPlatformID=4) not in any of the above

Each customer is then enriched with:
- **Platform-specific FTD dates and amounts** (TP, IBAN, Options, MoneyFarm)
- **Global FTD** — earliest deposit across all platforms
- **Daily MIMO flags** — deposited today, first deposit today, redeposited, cashed out, per platform
- **Account segmentation** — active trader, balance-only, portfolio-only, inactive
- **Snapshot attributes** — regulation, player status, country, MiFID categorization
- **Login activity** — logged in today, split by depositor type
- **Funded status** — IsFunded, FirstTimeFunded, FirstFundedDateID, FirstIOBDateID

The table was created in July 2024 by Guy Manova. Significant changelog includes IBAN C2F fix (Aug 2025), Options FTDs (Oct 2025), global FTD coercion logic (Nov 2025), MoneyFarm support (Nov 2025), and deduplication fix (Dec 2025).

**ETL**: `SP_DDR_Customer_Daily_Status` runs daily (Priority 99, SB_Daily). Data spans from 2007-10-01 to present with ~13.3B rows across ~6.8M distinct CIDs.

---

## 2. Business Logic

### 2.1 Population Building (5-Layer Waterfall)

**What**: Builds the complete customer universe from five mutually exclusive sources.

**Rules**:
- TP population first (from `BI_DB_Client_Balance_CID_Level_New` for the date)
- IBAN-only users added second (settled deposits, TxTypeID 7/14, not in TP)
- Options users third (FTDPlatformID=2, not in TP/IBAN)
- Options MIMO users fourth (from MIMO Options table, not in any above)
- MoneyFarm users last (FTDPlatformID=4, not in any above)

### 2.2 Platform-Specific FTD Assignment

**What**: Assigns first-time-deposit date, date ID, and amount per platform.

**Columns Involved**: `TP_FTD_DateID/Date/FTDA`, `IBAN_FTD_DateID/Date/FTDA`, `Options_FTD_DateID/Date/FTDA`, `MoneyFarm_FTD_DateID/Date/FTDA`, `Global_FTD_DateID/Date/FTDA`

**Rules**:
- Each platform FTD comes from `Dim_Customer` filtered by `FTDPlatformID` (1=TP, 2=Options, 3=IBAN, 4=MoneyFarm)
- `Global_FTD` = earliest FTD across all platforms (MIN date)
- `IsDepositorGlobal` = 1 when `FirstDepositDate > '1900-01-01'`

### 2.3 Daily MIMO Flags (Coercion Logic)

**What**: Derives daily deposit/withdraw flags from `BI_DB_DDR_Fact_MIMO_AllPlatforms` with timing coercion.

**Columns Involved**: `GlobalDeposited`, `GlobalFirstDeposited`, `GlobalRedeposited`, `GlobalCashedOut`, `Redeemed`, `DepositedTP/IBAN/Options`, `ReDepositedTP/IBAN/Options`, `TPFirstDeposited`, `IBANFirstDeposited`, `OptionsFirstDeposited`, `TPExternalFirstDeposited`

**Rules**:
- FTD coercion: `Dim_Customer.FirstDepositDate` may differ from MIMO transaction date (recovery dates). The SP coerces the MIMO date to match Dim_Customer for consistency.
- `GlobalDeposited` = deposited today on any platform (excluding internal transfers)
- `GlobalFirstDeposited` = first deposit ever on any platform today
- `GlobalRedeposited` = deposited today but not FTD and not internal
- `TPExternalFirstDeposited` = TP FTD excluding internal transfers (FundingTypeID ≠ 33)

### 2.4 Account Segmentation

**What**: Classifies each customer into one of three mutually exclusive DDR engagement tiers using three TVFs. Top tier wins — evaluation is in priority order.

**Columns Involved**: `ActiveTraded`, `BalanceOnlyAccount`, `Portfolio_Only`, `AccountActive`, `AccountInActive`

**Tier hierarchy (mutually exclusive, priority top-to-bottom)**:
1. **Active Traders** (`ActiveTraded = 1`): Customer explicitly opened a new position (ActionTypeID 1 or 39), opened or added capital to a copy mirror (ActionTypeID 15=OpenMirror, 17=AddMirror), or placed an Options trade on this date. Auto-created copy positions — positions auto-generated when a copied trader opens a position — do NOT qualify; only deliberate mirror opens/additions count. Sourced from `Function_Population_Active_Traders`.
2. **Portfolio Only** (`Portfolio_Only = 1`): Customer holds at least one open TP position or Options position (via Apex buy-power data) but placed no qualifying trading actions in the period. The HODL segment — investors who traded historically and still hold. Includes copy positions (MirrorID>0) and CopyFund/Smart Portfolio (MirrorTypeID=4) positions. Explicitly excludes anyone in Active Traders. Sourced from `Function_Population_Portfolio_Only`.
3. **Balance Only** (`BalanceOnlyAccount > 0`): Customer has positive equity on at least one platform (TP, eMoney/IBAN, or Options) but holds no open positions and placed no trading actions in the period. The lowest engagement tier — cash at eToro, no portfolio. Returns the customer's maximum total equity (numeric, not 0/1). Excludes both Active Traders and Portfolio Only customers. Sourced from `Function_Population_Balance_Only_Accounts`.

- `AccountActive` = `CASE WHEN ActiveTraded = 1 OR Portfolio_Only = 1 THEN 1 ELSE 0 END`
- `AccountInActive` = customer is in none of the three active tiers

### 2.5 Login Activity

**What**: Classifies logins by depositor type.

**Columns Involved**: `LoggedIn`, `LoggedInTPDepositor`, `LoggedInIBANDepositor`, `LoggedInGlobalDepositor`

**Rules**:
- `LoggedIn` = 1 if customer has ActionTypeID 14 on the date
- `LoggedInTPDepositor` = logged in AND has TP FTD
- `LoggedInIBANDepositor` = logged in AND has IBAN FTD
- `LoggedInGlobalDepositor` = logged in AND has any FTD (global depositor)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. **Always filter on DateID** — this is a 13.3B row table. For single-customer queries, filter on both DateID and RealCID.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active traders for a date | `WHERE ActiveTraded = 1 AND DateID = @dateID` |
| Global FTDs today | `WHERE GlobalFirstDeposited = 1 AND DateID = @dateID` |
| Customer status breakdown | `GROUP BY ActiveTraded, BalanceOnlyAccount, Portfolio_Only, AccountInActive WHERE DateID = @dateID` |
| Depositor logins by region | `WHERE LoggedInGlobalDepositor = 1 GROUP BY MarketingRegion` |
| TP vs IBAN FTD trend | `SUM(TPFirstDeposited), SUM(IBANFirstDeposited) GROUP BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID + DateID | AUM per customer for the date |
| BI_DB_dbo.BI_DB_DDR_Fact_PnL | RealCID + DateID | Revenue per customer |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | RealCID + DateID | MIMO transaction details |
| DWH_dbo.Dim_Customer | RealCID | Extended customer attributes |
| DWH_dbo.Dim_Regulation | RegulationID | Regulation name |
| DWH_dbo.Dim_Country | CountryID | Country details |

### 3.4 Gotchas

- **One row per CID per day** — full snapshot, not SCD. Every customer appears for every date they were in the system.
- **13.3B rows** — second largest table in BI_DB. Filter on DateID first.
- **FTD coercion**: `Dim_Customer` FTD dates can differ from MIMO transaction dates due to recovery logic. The SP coerces dates to match Dim_Customer, which is the authoritative source.
- **Mutually exclusive segments**: A customer is in exactly one of ActiveTraded, BalanceOnlyAccount, Portfolio_Only, or Inactive. `AccountActive = ActiveTraded OR Portfolio_Only`.
- **FirstFundedDateID/FirstActionDateID sentinel**: Value `30000101` means no event (future sentinel date).
- **FirstActionType = 'NoAction'**: Customer has not taken any trading action yet.
- **MarketingRegion**: From `Dim_Country.MarketingRegionManualName`, not from Dim_Customer directly.
- **Options FTD coercion UPDATE**: Post-insert UPDATE sets OptionsFirstDeposited=1 when Options_FTD_DateID = @dateID but MIMO data didn't arrive.
- **Deduplication**: ROW_NUMBER at the end ensures one row per CID even if production bugs create duplicate source rows.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Customer_Daily_Status) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date — equals parameter `@date`. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 2 | DateID | int | YES | Business date as YYYYMMDD integer. Delete/replace key. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 3 | RealCID | int | YES | Real customer ID. Population from 5-layer waterfall (TP → IBAN → Options → OptionsMIMO → MoneyFarm). HASH distribution key. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 4 | TP_FTD_DateID | int | YES | Trading Platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=1. NULL if no TP FTD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 5 | TP_FTD_Date | datetime | YES | Trading Platform first-time deposit datetime. From Dim_Customer.FirstDepositDate where FTDPlatformID=1. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 6 | TP_FTDA | decimal(16,6) | YES | Trading Platform first-time deposit amount in USD. From Dim_Customer.FirstDepositAmount where FTDPlatformID=1. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 7 | IBAN_FTD_DateID | int | YES | IBAN (eMoney) first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=3. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 8 | IBAN_FTD_Date | datetime | YES | IBAN first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 9 | IBAN_FTDA | decimal(16,6) | YES | IBAN first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 10 | TP_External_FTDA | decimal(16,6) | YES | TP external FTD amount — excludes internal transfers (FundingTypeID ≠ 33). From MIMO aggregation. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 11 | Global_FTD_DateID | int | YES | Global first-time deposit date (YYYYMMDD) — earliest across all platforms. MIN(TP, IBAN, Options, MoneyFarm). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 12 | Global_FTD_Date | datetime | YES | Global first-time deposit datetime — earliest across all platforms. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 13 | Global_FTDA | decimal(16,6) | YES | Global first-time deposit amount in USD — amount of the earliest deposit. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 14 | IsDepositorGlobal | int | YES | Global depositor flag. 1 when Dim_Customer.FirstDepositDate > '1900-01-01'. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 15 | GlobalDeposited | int | YES | Deposited today on any platform (excluding internal transfers). ISNULL(0). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 16 | GlobalFirstDeposited | int | YES | First deposit ever on any platform today. From MIMO IsGlobalFTD flag. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 17 | GlobalRedeposited | int | YES | Redeposited today (not FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 18 | GlobalCashedOut | int | YES | Withdrew today on any platform (excluding internal transfers). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 19 | Redeemed | int | YES | Billing redeem withdrawal today. From MIMO IsRedeem flag. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 20 | DepositedTP | int | YES | Deposited today on Trading Platform (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 21 | DepositedIBAN | int | YES | Deposited today on IBAN/eMoney (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 22 | ReDepositedTP | int | YES | Redeposited today on TP (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 23 | ReDepositedIBAN | int | YES | Redeposited today on IBAN (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 24 | TPFirstDeposited | int | YES | First deposit on Trading Platform today. From MIMO IsPlatformFTD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 25 | IBANFirstDeposited | int | YES | First deposit on IBAN/eMoney today. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 26 | TPExternalFirstDeposited | int | YES | First external TP deposit today (excl FundingTypeID=33 internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 27 | ActiveTraded | int | YES | **DDR top engagement tier.** 1 if the customer explicitly opened a new position (ActionTypeID 1 or 39), opened/added capital to a copy mirror (ActionTypeID 15=OpenMirror, 17=AddMirror), or placed an Options trade on this date. Auto-created copy positions (generated when a copied trader opens) do NOT qualify — only deliberate mirror opens/additions count. Includes Options trading via Function_Revenue_OptionsPlatform. Source: Function_Population_Active_Traders. (Tier 1 — Function_Population_Active_Traders) |
| 28 | BalanceOnlyAccount | decimal(16,6) | YES | **DDR lowest engagement tier — cash at eToro, no portfolio (numeric equity, not 0/1).** Customer has positive equity on any platform (TP NWA+Liability, eMoney ClosingBalanceBO×FXRate, Options TotalEquity from Apex buy-power) but holds no open positions and placed no qualifying trading actions in the period. Returns the customer’s maximum combined equity across all platforms. Excludes Active Traders and Portfolio Only (higher tiers win). Source: Function_Population_Balance_Only_Accounts. (Tier 1 — Function_Population_Balance_Only_Accounts) |
| 29 | Portfolio_Only | int | YES | **DDR middle engagement tier — the HODL segment.** 1 if the customer holds at least one open TP position or Options position (Apex buy-power) but placed no qualifying trading actions in the period. Includes copy positions (MirrorID>0) and CopyFund/Smart Portfolio (MirrorTypeID=4). Excludes Active Traders (higher priority wins). Source: Function_Population_Portfolio_Only. (Tier 1 — Function_Population_Portfolio_Only) |
| 30 | AccountActive | int | YES | Account is active. CASE WHEN ActiveTraded=1 OR Portfolio_Only=1 THEN 1 ELSE 0. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 31 | AccountInActive | int | YES | Account is completely inactive (not in any of the 3 active segments). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 32 | RegulationID | int | YES | Regulation ID from Fact_SnapshotCustomer for the date range. FK → DWH_dbo.Dim_Regulation. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 33 | DesignatedRegulationID | int | YES | Designated regulation ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 34 | PlayerStatusID | int | YES | Player status ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 35 | IsCreditReportValidCB | int | YES | Credit report valid flag from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 36 | IsValidCustomer | int | YES | Valid customer flag from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 37 | AccountTypeID | int | YES | Account type ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 38 | CountryID | decimal(16,6) | YES | Country ID from Fact_SnapshotCustomer. FK → DWH_dbo.Dim_Country. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 39 | MarketingRegion | varchar(100) | YES | Marketing region name. From Dim_Country.MarketingRegionManualName joined via CountryID. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 40 | MifidCategorizationID | decimal(16,6) | YES | MiFID categorization ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 41 | PlayerLevelID | int | YES | Player level ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 42 | IsDepositor | int | YES | TP depositor flag from Fact_SnapshotCustomer (SCD-based). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 43 | IsFunded | int | YES | **1 if the customer meets ALL four funded criteria on this date:** (1) real deposit per Dim_Customer.IsDepositor=1 (excludes 13K bad-FTD cohort:  FTDs on Aug 18-20 2025 with no subsequent real deposit); (2) KYC verified to level 3 (VerificationLevelID=3); (3) at least one non-airdrop activity completed — a TP trade (Dim_Position.IsAirDrop=0), IOB interest credit (Fact_CustomerAction ActionTypeID=36/CompensationReasonID=57), or Options trade; AND (4) positive equity on this date across TP, eMoney, or Options. All four conditions must hold simultaneously. Source: Function_Population_Funded. (Tier 1 — Function_Population_Funded) |
| 44 | FirstTimeFunded | int | YES | **1 on the exact date the customer first crossed the fully-funded threshold.** Computed as CASE WHEN FirstFundedDateID = @dateID THEN 1 ELSE 0. This date is always on or after the first deposit date — it only fires when KYC (level 3) and first qualifying activity (trade/IOB/options) are also complete simultaneously. A customer who deposited months ago but only recently verified will fire FirstTimeFunded on their verification date (if they had prior activity). Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 45 | FirstFundedDateID | int | YES | **Permanent graduation date (YYYYMMDD) — the LATEST of the three funded milestones.** Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Counterintuitively this is NOT the first deposit date — it is the last day on which all three conditions were simultaneously satisfied for the first time. Example: deposited Jan 1, verified Jan 5, first trade Jan 10 → FirstFundedDateID = 20260110. Sentinel 30000101 = not yet funded. Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 46 | FirstActionType | varchar(50) | YES | First trading action type (e.g., 'Crypto', 'Forex', 'Stocks'). From Function_Population_First_Trading_Action. 'NoAction' if none or future. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 47 | FirstActionDateID | int | YES | Date of first trading action (YYYYMMDD). Sentinel 30000101 = no action. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 48 | LoggedIn | int | YES | Logged in today. 1 when ActionTypeID=14 in Fact_CustomerAction. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 49 | LoggedInTPDepositor | int | YES | Logged in today AND is a TP depositor. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 50 | LoggedInIBANDepositor | int | YES | Logged in today AND is an IBAN depositor. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 51 | LoggedInGlobalDepositor | int | YES | Logged in today AND is a global depositor (any platform). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 52 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 53 | FirstIOBDateID | int | YES | **Date of first Interest on Balance (IOB) credit (YYYYMMDD).** IOB is an interest payment credited to customer accounts (Fact_CustomerAction, ActionTypeID=36, CompensationReasonID=57). Added Aug 2025 as an alternative qualifying activity for Funded status alongside trading a position or Options trade. A customer who never traded but receives IOB interest while meeting deposit+KYC criteria counts as Funded. NULL = no IOB credit ever received. Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 54 | FirstIOBTime | datetime | YES | **Exact timestamp of the customer’s first Interest on Balance credit.** Used alongside FTDDateID and FirstVerifiedDateID inside Function_Population_First_Time_Funded when computing FirstFundedDateID via GREATEST(). NULL if no IOB credit was ever received. (Tier 1 — Function_Population_First_Time_Funded) |
| 55 | Options_FTD_DateID | int | YES | Options platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=2. Added Oct 2025. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 56 | Options_FTD_Date | datetime | YES | Options platform first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 57 | Options_FTDA | decimal(16,6) | YES | Options platform first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 58 | OptionsFirstDeposited | int | YES | First deposit on Options platform today. May be set by post-insert UPDATE when MIMO data missing. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 59 | DepositedOptions | int | YES | Deposited today on Options platform (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 60 | ReDepositedOptions | int | YES | Redeposited today on Options (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 61 | MoneyFarm_FTD_DateID | int | YES | MoneyFarm first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=4. Added Nov 2025. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 62 | MoneyFarm_FTD_Date | datetime | YES | MoneyFarm first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 63 | MoneyFarm_FTDA | decimal(16,6) | YES | MoneyFarm first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 64 | MoneyFarmFirstDeposited | int | YES | First deposit on MoneyFarm platform today. CASE WHEN MoneyFarm_FTD_DateID = @dateID THEN 1. (Tier 2 — SP_DDR_Customer_Daily_Status) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Transform |
|---------------------|-------------------|-----------|
| Population (col 3) | BI_DB_Client_Balance_CID_Level_New + eMoney_Fact_Transaction_Status + Dim_Customer + MIMO_Options | 5-layer waterfall UNION |
| Platform FTDs (cols 4-13, 55-63) | Dim_Customer × Dim_FTDPlatform | CASE by FTDPlatformID |
| MIMO daily flags (cols 14-26, 58-60) | BI_DB_DDR_Fact_MIMO_AllPlatforms + coercion logic | MAX/CASE aggregation |
| Segments (cols 27-31) | Population functions (Active/BalanceOnly/Portfolio) | Function calls |
| Snapshot attrs (cols 32-42) | Fact_SnapshotCustomer + Dim_Range + Dim_Country | passthrough |
| Funded/Action (cols 43-47) | Population functions (Funded/FirstTimeFunded/FirstAction) | Function calls |
| Login (cols 48-51) | Fact_CustomerAction (ActionTypeID=14) | CASE + depositor join |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (TP population)
  + eMoney_dbo.eMoney_Fact_Transaction_Status (IBAN-only)
  + DWH_dbo.Dim_Customer (Options, MoneyFarm)
  + BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform (Options MIMO)
  → #population (5-layer waterfall)
     |
     + Fact_SnapshotCustomer + Dim_Range → #fsc
     + Function_Population_Funded → #funded
     + Function_Population_First_Time_Funded → #firstTimeFunded
     + Function_Population_First_Trading_Action → #FirstActions
     + Function_Population_Balance_Only_Accounts → #balanceOnly
     + Function_Population_Portfolio_Only → #portfolioOnly
     + Function_Population_Active_Traders → #activeTraders
     + Dim_Customer → #globalFTDs → platform-specific FTD temps
     + MIMO_AllPlatforms → #mimoUsersPrep → coercion → #mimoUsers
     + Fact_CustomerAction → #loggedIn → #depositorsLoggedIn
     |
     → #enrichStatusActions (merge all + dedup RN=1)
        |
        → SP_DDR_Customer_Daily_Status(@date) [Priority 99, SB_Daily]
             |-- DELETE WHERE DateID = @dateID
             |-- UPDATE Options FTD coercion
             |-- INSERT from #enrichStatusActions WHERE RN=1
             v
        BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (13.3B rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation lookup |
| CountryID | DWH_dbo.Dim_Country | Country lookup |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type lookup |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Player status lookup |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID categorization |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status | — | Periodic aggregation reads daily status |
| BI_DB_dbo.BI_DB_V_DDR_* | — | All DDR views reference this for customer segmentation |
| BI_DB_dbo.SP_DDR_* | — | DDR SPs use this as the customer dimension |

---

## 7. Sample Queries

### 7.1 Active traders by regulation for a date

```sql
SELECT d.RegulationName, COUNT(*) AS ActiveTraders
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status s
JOIN DWH_dbo.Dim_Regulation d ON s.RegulationID = d.RegulationID
WHERE s.DateID = 20260309 AND s.ActiveTraded = 1
GROUP BY d.RegulationName
ORDER BY ActiveTraders DESC
```

### 7.2 Global FTDs by marketing region this month

```sql
SELECT MarketingRegion,
       SUM(GlobalFirstDeposited) AS FTD_Count,
       SUM(Global_FTDA) AS FTD_Volume
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
WHERE DateID BETWEEN 20260301 AND 20260309
  AND GlobalFirstDeposited = 1
GROUP BY MarketingRegion
ORDER BY FTD_Count DESC
```

### 7.3 Account segmentation breakdown

```sql
SELECT DateID,
       SUM(ActiveTraded) AS Active,
       SUM(CASE WHEN BalanceOnlyAccount > 0 THEN 1 ELSE 0 END) AS BalanceOnly,
       SUM(Portfolio_Only) AS PortfolioOnly,
       SUM(AccountInActive) AS Inactive
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
WHERE DateID = 20260309
GROUP BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14*
*Tiers: 0 T1, 64 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | Type: Table | Production Source: SP_DDR_Customer_Daily_Status (15+ sources)*


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> Comprehensive instrument dimension table covering all 15,700+ tradeable assets on the eToro platform -- combining core trade pair definitions (buy/sell currencies), display metadata, financial fundamentals, futures configuration, and platform classification into a single analytics-ready reference.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument (view) + Trade.InstrumentMetaData + Trade.ProviderToInstrument + StockInfo + FuturesMetaData |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None (15K rows; suggest Z-ORDER on InstrumentID) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Instrument` is the DWH's master reference for all tradeable instruments on the eToro platform. It extends the foundational trade pair definition from `Trade.Instrument` (which specifies the buy/sell currency pairing for each instrument) with rich analytics metadata: display names and company info from `Trade.InstrumentMetaData`, trading configuration from `Trade.ProviderToInstrument`, financial market data (market cap, ADV, shares outstanding) from the Rankings/StockInfo system, Bloomberg-style asset classification, and futures-specific parameters. The result is a 47-column analytics hub that serves as the primary instrument lookup for fact table enrichment across DWH analytics.

The production source is `etoro.Trade.GetInstrument` (a view on the production etoroDB-REAL server), which combines `Trade.Instrument` with multiple related tables. The Generic Pipeline exports this view daily to `Bronze/etoro/Trade/GetInstrument/` (UC: `trading.bronze_etoro_trade_getinstrument`). The DWH ETL SP (`SP_Dim_Instrument`) then joins this staging data with six additional staging tables to produce the full 47-column Dim_Instrument. Post-load UPDATE statements enrich price-server tracking, asset classification, and financial fundamentals. Source: upstream wiki available at `Trade/Tables/Trade.Instrument.md` (quality 9.1/10).

The ETL is a full TRUNCATE + INSERT + multiple UPDATEs, running daily with a `@dt` date parameter. `UpdateDate` and `InsertDate` are both set to `GETDATE()` at load time and do NOT reflect production modification times. The SP ends by calling `SP_Dim_Instrument_Snapshot @dt` to update the `Dim_Instrument_Snapshot` table (daily snapshot of futures configuration columns). As of 2026-03-19, the table contains 15,707 rows: 82% Stocks, 8% ETFs, 4% Crypto, 3% Commodities, 2% Indices, 1% Currencies.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of assets from `Dictionary.Currency`/`Dim_Currency`. The pairing determines how prices are quoted, how positions are settled, and how P&L is converted to account currency.

**Columns Involved**: `BuyCurrencyID`, `SellCurrencyID`, `BuyCurrency`, `SellCurrency`

**Rules**:
- For **forex pairs**: BuyCurrencyID is the base currency, SellCurrencyID is the quote currency (e.g., InstrumentID=1: EUR/USD = BuyCurrencyID=2/EUR, SellCurrencyID=1/USD)
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the asset's own InstrumentID in Dim_Currency, and SellCurrencyID is the denomination currency (USD for US stocks, EUR for European stocks, GBX for UK pence-quoted stocks)
- `BuyCurrency` and `SellCurrency` are DWH-added text abbreviations (denormalized from Dictionary.Currency via SP JOIN)
- InstrumentID=0: system/ETL null-sentinel record with all zero/NA values

**Diagram**:
```
Forex:  ID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:  ID=1001 -> Buy=AAPL(1001) / Sell=USD(1) = Apple in USD
EuroSt: ID=1203 -> Buy=Bayer(1203) / Sell=EUR(2) = Bayer AG in EUR
Crypto: ID=XXXX -> Buy=BTC(?) / Sell=USD(1)     = Bitcoin in USD
```

### 2.2 InstrumentType and IsMajor Dual Representation

**What**: Two DWH-specific computed/reformatted columns encode enum values as human-readable text.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`, `IsMajorID`, `IsMajor`

**Rules**:
- `InstrumentType` is CASE-computed in the SP from `InstrumentTypeID`: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Note: type IDs 3, 7, 8, 9 are not defined (gap exists for historical reasons)
- `IsMajorID` = production `IsMajor` bit value (0 or 1). `IsMajor` = text version ('Yes' or 'No'). Analysts should use `IsMajorID` for filtering, `IsMajor` for display
- IsMajor=Yes: 6,963 instruments (major forex + popular stocks/ETFs). IsMajor=No: 8,743 instruments
- DWHInstrumentID always equals InstrumentID (redundant copy, same as the DWHXxxID pattern across all DWH Dim tables)
- StatusID is hardcoded to 1 for all real rows (ETL artifact; NULL only for ID=0 placeholder)

### 2.3 IsFuture Derivation and Futures Columns

**What**: Futures instruments are identified by membership in InstrumentGroups(GroupID=25), and carry additional configuration columns not present for non-futures instruments.

**Columns Involved**: `IsFuture`, `Multiplier`, `ProviderMarginPerLot`, `eToroMarginPerLot`, `SettlementTime`

**Rules**:
- `IsFuture = 1` when the instrument is a member of `DWH_staging.etoro_Trade_InstrumentGroups` with `GroupID=25`. Computed via CASE in SP_Dim_Instrument.
- `Multiplier`: contract size multiplier from `Trade.FuturesMetaData`. NULL for non-futures.
- `ProviderMarginPerLot`: initial margin requirement from the liquidity provider, from `Trade.FuturesInstrumentsInitialMarginByProviderMapping`. NULL for non-futures.
- `eToroMarginPerLot`: eToro's own margin per lot (in asset currency) from `Trade.ProviderToInstrument.InitialMarginInAssetCurrency`. NULL for non-futures.
- `SettlementTime`: daily/weekly settlement time from `Trade.ProviderToInstrument`, formatted as TIME(0) by the SP.

### 2.4 Financial Fundamentals (Post-Load Updates)

**What**: Market data columns are populated via post-load UPDATE statements joining to the Rankings/StockInfo data lake.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `AssetClass`, `IndustryGroup`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- `ADV_Last3Months`: Average Daily Volume over last 3 months (MetadataID=8557). NULL for non-stock instruments or instruments without Rankings data.
- `MKTcap`: Market Capitalization in USD (MetadataID=8735 for stocks, fallback to MetadataID=9315 CryptoMarketCap for crypto). NULL if not covered by Rankings.
- `SharesOutStanding`: Total shares outstanding in units (MetadataID=8444). Stocks only.
- `AssetClass` / `IndustryGroup`: Bloomberg-style classification from `Ext_Dim_Instrument_Classification_Static`. More granular than InstrumentType.
- `PlatformSector` / `PlatformIndustry`: eToro platform taxonomy (MetadataID=8436/8280), may differ from Bloomberg AssetClass/IndustryGroup.
- `ReceivedOnPriceServer`: First date/time an instrument was seen on the price server. POST-LOAD from `Ext_Dim_Instrument_ReceivedOnPriceServerStatic`. NULL for instruments not yet priced.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (all 15,707 rows available on every compute node) with a CLUSTERED INDEX on `InstrumentID`. Since virtually every fact table JOINs to `Dim_Instrument` on `InstrumentID`, replication eliminates shuffle overhead. The clustered index supports range scans and direct lookups efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export is pending write-objects configuration. At 15,707 rows, partitioning is not beneficial -- suggest Z-ORDER on `InstrumentID` for join performance, and `InstrumentTypeID` for type-filtered analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get instrument name and type by ID | `JOIN Dim_Instrument ON InstrumentID; SELECT Name, InstrumentType` |
| Find all major instruments by asset class | `WHERE IsMajorID = 1 AND AssetClass = 'Technology'` |
| Find instruments eligible for long/short | `WHERE AllowBuy = 1 AND AllowSell = 1 AND Tradable = 1` |
| Get market cap for a position | `JOIN Dim_Instrument ON InstrumentID; SELECT MKTcap` |
| Find futures instruments with settlement | `WHERE IsFuture = 1 AND SettlementTime IS NOT NULL` |
| Find US stocks with ISIN | `WHERE InstrumentTypeID = 5 AND ISINCountryCode = 'US' AND ISINCode IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.BuyCurrencyID` | Resolve buy-side currency/asset details |
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.SellCurrencyID` | Resolve sell-side denomination currency |
| DWH_dbo.Dim_HistorySplitRatio | `ON InstrumentID + date range` | Get split adjustment ratios for historical price normalization |
| DWH_dbo.Dim_Instrument_Snapshot | `ON InstrumentID + DateID` | Get point-in-time futures config for historical analysis |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `ON InstrumentID` | Join to price history |

### 3.4 Gotchas

- **InstrumentID=0 is the null-sentinel placeholder**: All fields are 0/NA/NULL. Always filter `WHERE InstrumentID > 0` for analytics.
- **DWHInstrumentID always equals InstrumentID**: This is a redundant copy column -- do not use it as a distinct identifier.
- **StatusID is hardcoded 1**: This column conveys no information (all rows = 1 except the ID=0 placeholder). Do not filter on it.
- **UpdateDate and InsertDate are both ETL timestamps**: Neither reflects when the instrument was created or last modified in production. They reflect the last ETL run (daily, ~midnight).
- **InstrumentType gaps**: TypeIDs 3, 7, 8, 9 are not used. The CASE expression returns 'Other' for any unmapped typeID.
- **IsMajorID vs IsMajor**: Use `IsMajorID` (int 0/1) for WHERE/GROUP BY. Use `IsMajor` ('Yes'/'No') for display only.
- **NULL fundamentals**: ADV_Last3Months, MKTcap, SharesOutStanding are NULL for non-stock instruments and for instruments not covered by Rankings data. Always use LEFT JOIN or ISNULL() when using these for aggregations.
- **AllowBuy/AllowSell = 0 means trading disabled**: Instruments with AllowBuy=0 cannot be opened in the specified direction. This changes dynamically in production but is updated daily in DWH.
- **Dim_Instrument vs Dim_Currency**: Dim_Currency (from Dictionary.Currency) is the master asset registry with type and currency info. Dim_Instrument (from Trade.Instrument) is the trading pair definition with full analytics enrichment. For basic instrument lookups, Dim_Currency suffices. For trading parameters, fundamentals, or pair analysis, use Dim_Instrument.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, Trade.Instrument)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Instrument)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 2 | InstrumentTypeID | int | NO | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%. (Tier 2 -- SP_Dim_Instrument) |
| 3 | InstrumentType | varchar(50) | NO | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 -- SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Always equal to InstrumentID -- redundant copy following the DWH DWH{X}ID pattern. Use InstrumentID for all JOINs. (Tier 2 -- SP_Dim_Instrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all real rows by SP_Dim_Instrument. NULL only for ID=0 placeholder. Conveys no business information. (Tier 2 -- SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks). (Tier 1 -- upstream wiki, Trade.Instrument) |
| 8 | SellCurrencyID | int | NO | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 9 | BuyCurrency | varchar(50) | NO | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 10 | SellCurrency | varchar(50) | NO | Text abbreviation of SellCurrencyID -- denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 11 | TradeRange | int | NO | Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 14 | IsMajorID | int | NO | Integer representation of the production IsMajor flag (0 or 1). 1=major instrument (6,963 instruments -- all major forex pairs and many popular stocks). 0=non-major (8,743 instruments). Renamed from production IsMajor to distinguish from the text version. Use for filtering. (Tier 2 -- SP_Dim_Instrument) |
| 15 | IsMajor | varchar(3) | NO | Text version of IsMajorID -- DWH CASE computed: IsMajorID=1->'Yes', 0->'No'. Use for display. Affects spread calculations and regulatory leverage caps (ESMA allows higher leverage for major forex). (Tier 2 -- SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument on each daily reload. Does NOT reflect production modification date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument, same as UpdateDate. Both reflect the daily load time. Does NOT reflect production insertion date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry classification string from Trade.InstrumentMetaData. Text description (e.g., 'Internet', 'Software'). Similar to but may differ from IndustryGroup (Bloomberg). NULL for non-stock instruments or instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Free-text company description from Trade.InstrumentMetaData. May contain multi-sentence business descriptions of the company. NULL for non-company instruments (forex, commodities, indices). (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number -- 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country code prefix from the ISIN (first 2 characters). Indicates the country of registration (e.g., US, DE, GB). NULL when ISINCode is NULL. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 24 | Tradable | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 25 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. NULL for ID=0 placeholder and some instruments without formal ticker. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 26 | ReceivedOnPriceServer | datetime | YES | First timestamp when the instrument was observed on the price server (from Ext_Dim_Instrument_ReceivedOnPriceServerStatic). Set once and never updated (static history). NULL for instruments not yet priced or newly added instruments that have not yet appeared in price feeds. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of bonus credit that can be applied to trading this instrument, from Trade.ProviderToInstrument. Lower values restrict bonus usage for high-risk/volatile instruments. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Committee on Uniform Securities Identification Procedures number -- 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 30 | Precision | int | YES | Decimal precision for price display and trading (number of decimal places), from Trade.ProviderToInstrument. Determines how many decimals are shown in the UI and used in calculations. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 31 | AllowBuy | int | YES | Flag indicating if long (buy) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Instruments may be buy-disabled due to regulatory restrictions, risk management, or market conditions. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 32 | AllowSell | int | YES | Flag indicating if short (sell) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Many regulated markets prohibit short selling for retail clients. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Bloomberg-style asset class classification from Ext_Dim_Instrument_Classification_Static (e.g., Technology, Consumer Services, Finance). More granular than InstrumentType. NULL for non-stock instruments or instruments not in the classification static table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 34 | IndustryGroup | nvarchar(400) | YES | Bloomberg-style industry group within AssetClass (e.g., Computers, Internet, Banks). Sub-classification of AssetClass. NULL for non-stock instruments or instruments not in the classification table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average Daily Trading Volume over the trailing 3 months (TTM), from Rankings StockInfo MetadataID=8557. In shares/units. NULL for non-stock instruments or instruments without Rankings coverage. Example: Apple ~48M shares/day. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization in USD from Rankings StockInfo (MetadataID=8735 for equities; fallback MetadataID=9315 CryptoMarketCap for crypto). NULL for forex, commodities, and indices. Example: Apple ~3.8T USD. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Total shares outstanding in units from Rankings StockInfo MetadataID=8444. Annual figure. NULL for non-equity instruments. Example: Apple ~14.7B shares. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | Flag (0/1) indicating if the instrument is visible only to internal eToro users (not shown to retail customers). Cast from bit. Used for instruments under development, testing, or institutional-only. NULL for ID=0 placeholder. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 39 | PlatformSector | varchar(max) | YES | eToro platform sector classification from Rankings StockInfo MetadataID=8436. May differ from Bloomberg AssetClass. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | eToro platform industry classification from Rankings StockInfo MetadataID=8280. More granular than PlatformSector. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 41 | IsFuture | int | YES | Derived flag indicating if the instrument is a futures contract: 1=futures, 0=not futures. Computed in SP as CASE WHEN InstrumentID IN (SELECT InstrumentID FROM InstrumentGroups WHERE GroupID=25) THEN 1 ELSE 0. NULL for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Futures contract size multiplier from Trade.FuturesMetaData. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_FuturesMetaData) |
| 43 | ProviderID | int | YES | Liquidity provider identifier from Trade.ProviderToInstrument. Identifies which external market maker or broker provides pricing/liquidity for this instrument. NULL for instruments without a provider mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Initial margin requirement per lot in the provider's terms, from Trade.FuturesInstrumentsInitialMarginByProviderMapping. Primarily relevant for futures instruments. NULL for non-futures or instruments without provider margin data. (Tier 3 -- live data, FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | eToro's own margin requirement per lot in asset currency (InitialMarginInAssetCurrency from Trade.ProviderToInstrument). eToro's internal margin may differ from the provider's margin. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Daily or periodic settlement time for the instrument, from Trade.ProviderToInstrument, formatted as TIME via SP DATEPART conversion. Primarily relevant for futures and CFD instruments with defined settlement windows. NULL for instruments without settlement time defined. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders. (Tier 1 -- upstream wiki, Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | etoro.Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE to text label |
| Name | etoro.Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | etoro.Trade.GetInstrument | InstrumentID | rename (= InstrumentID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| BuyCurrencyID | etoro.Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | etoro.Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via BuyCurrencyID) |
| SellCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via SellCurrencyID) |
| TradeRange | etoro.Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | etoro.Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | etoro.Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | etoro.Trade.GetInstrument | IsMajor | rename (bit to int) |
| IsMajor | etoro.Trade.GetInstrument | IsMajor | CASE to 'Yes'/'No' text |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched |
| Industry | etoro.Trade.InstrumentMetaData | Industry | join-enriched |
| CompanyInfo | etoro.Trade.InstrumentMetaData | CompanyInfo | join-enriched |
| Exchange | etoro.Trade.InstrumentMetaData | Exchange | join-enriched |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | join-enriched |
| ISINCountryCode | etoro.Trade.InstrumentMetaData | ISINCountryCode | join-enriched |
| Tradable | etoro.Trade.GetInstrument | Tradable | CAST to int |
| Symbol | etoro.Trade.GetInstrument | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog (via PriceLog_History_CurrencyPrice_Active) | ReceivedOnPriceServer | join-enriched, post-load UPDATE |
| BonusCreditUsePercent | etoro.Trade.ProviderToInstrument | BonusCreditUsePercent | join-enriched |
| SymbolFull | etoro.Trade.InstrumentMetaData | SymbolFull | join-enriched |
| CUSIP | etoro.Trade.InstrumentCusip | CUSIP | join-enriched |
| Precision | etoro.Trade.ProviderToInstrument | Precision | join-enriched |
| AllowBuy | etoro.Trade.GetInstrument | AllowBuy | CAST to int |
| AllowSell | etoro.Trade.GetInstrument | AllowSell | CAST to int |
| AssetClass | External classification static | AssetClass | join-enriched, post-load UPDATE |
| IndustryGroup | External classification static | IndustryGroup | join-enriched, post-load UPDATE |
| ADV_Last3Months | Rankings.StockInfo (MetadataID=8557) | NumVal | join-enriched, post-load UPDATE |
| MKTcap | Rankings.StockInfo (MetadataID=8735/9315) | NumVal | join-enriched with fallback, post-load UPDATE |
| SharesOutStanding | Rankings.StockInfo (MetadataID=8444) | NumVal | join-enriched, post-load UPDATE |
| VisibleInternallyOnly | etoro.Trade.GetInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo (MetadataID=8436) | StrVal | join-enriched, post-load UPDATE |
| PlatformIndustry | Rankings.StockInfo (MetadataID=8280) | StrVal | join-enriched, post-load UPDATE |
| IsFuture | etoro.Trade.InstrumentGroups (GroupID=25) | InstrumentID membership | CASE derived, post-load |
| Multiplier | etoro.Trade.FuturesMetaData | Multiplier | join-enriched |
| ProviderID | etoro.Trade.ProviderToInstrument | ProviderID | join-enriched |
| ProviderMarginPerLot | etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | join-enriched |
| eToroMarginPerLot | etoro.Trade.ProviderToInstrument | InitialMarginInAssetCurrency | join-enriched |
| SettlementTime | etoro.Trade.ProviderToInstrument | SettlementTime | cast/convert (TIME formatting) |
| OperationMode | etoro.Trade.Instrument | OperationMode | join-enriched (via etoro_Trade_Instrument) |

Upstream wiki: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md` (quality 9.1/10)

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, etoroDB-REAL)
  -> Generic Pipeline (Override, 1440min, Bronze/etoro/Trade/GetInstrument/)
  -> trading.bronze_etoro_trade_getinstrument (UC Bronze)
  -> DWH_staging.etoro_Trade_GetInstrument
  +-> DWH_staging.etoro_Dictionary_Currency (buy/sell currency names)
  +-> DWH_staging.etoro_Trade_InstrumentMetaData (display name, ISIN, exchange, company)
  +-> DWH_staging.etoro_Trade_ProviderToInstrument (provider config, margins, precision)
  +-> DWH_staging.etoro_Trade_InstrumentCusip (CUSIP)
  +-> DWH_staging.etoro_Trade_FuturesMetaData (multiplier)
  +-> DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping
  +-> DWH_staging.etoro_Trade_Instrument (OperationMode, AllowBuy/Sell, Tradable)
  -> SP_Dim_Instrument (TRUNCATE + JOIN INSERT + multiple post-load UPDATEs, daily)
  -> DWH_dbo.Dim_Instrument (15,707 rows)
  -- SP also call

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_CIDFirstDates`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CIDFirstDates.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_CIDFirstDates] @date [DATETIME] AS      
BEGIN        
--EXEC [BI_DB_dbo].[SP_CIDFirstDates] '2025-10-20'
/********************************************************************************************      
Author:   Adi Ferber      
Date:        2016-03-01      
Description: SP calulates user user segment according to AvgSTD      
      
**************************      
** Change History      
**************************      
Date        Author         Description       
----------  ----------     ------------------------------------      
01/3/2016   Adi Ferber       Create SP      
27/3/2016   Adi Ferber       improving   and otimazations of SP      
04/08/2016  AdiFerber       Adding Risk group update for the table       
29/12/2016  Max             Index rebuild add      
2017-01-26  Katy            DISABLE Demo step - no usage        
2017-02-09  Katy            update #Contacts state to MAX date LastContacted & MIN FirstContactDate       
2017-02-12  Katy            update #Contacts - enable LastContactDate_ByPhone update      
2017-02-15  Katy            add DELETE CID's with PlayerLevelID = 4      
2017-02-20  Katy            LastDepositDate update statement fix      
2017-09-27  Adi             comment all the IP's column      
2017-10-01  Adi             Ad rebuild to max's index only on Saturday      
2018-05-07  Boris           rebuild index only on Saturday move to diffent process      
2018-08-29  Boris           add 3 columns VerificationLevelDate      
2019-01-14  Boris           remove table Dim_Desk to Dim_Country      
2019-02-18  Boris           add EvMatchStatusDate      
2019-04-02  Sivan/Boris     add State  + PhoneVerifiedDate      
2019-06-05  Yev             add KYCModeID, PEPCreatedTime, PEPStatusUpdatedDate, isPassedPEP, PEPStatusID, EvMatchStatus, FTDIsLessThanAWeek, DesignatedRegulationID      
2019-07-21  Boris           update column VerificationLevelDate from Fact_SnapshotCustomer       
2019-08-13  Amir            Removing Parmeter for updating FirstInstallDate - Updating all Users install date (Row 1289)      
2019-09-01  Guy Barkat      Added ProApplicationDate column      
2019-09-11  Boris Slutski   Change index to #CustomerData      
2019-12-15  Boris           change linked server from  ETL_ Source.[etoro_  rep] to [AZR-W-REAL-DB-2-BIDBUser].[etoro]      
2019-12-30  Luda Garces     Add updated PotentionalDesk to the #updatenew and the final table (as of today, PotentionalDesk was missing out on updating the final table)      
2020-01-20  Ariel           Change on Section Actions-Stop using filter UpdateDate on Fact_CustomerAction + Change on Section KycModeID +Section PEP      
2020-02-04  Boris           Disable code to the source [ETL_Source].[OpenBook]      
2020-03-08  Evyatar         Added Last Cmpaign sent date   
2020-10-20  Tom B           Update LastContact date  
2020-11-30  Amir G          Remove FirstInstallDate from SP (Created New SP fro updating this column - [dbo].SP_FirstInstallDate_Update)  
2021-02-09  Eti R           Added NewMarketingRegion column  
2021-02-15  Amir G          Adding NewFunded Status & FirstNewFunded Date  
2021-02-17  Amir G          Addding LastNewFundedDate  
2021-02-25  Amir G          Adding Columns: 1.Received Airdrop before                                       
                                            2.Signed W8ben form  
                                            3.MaxClub  
                                            4.MaxClub FirstDate  
2021-06-27  Evyatar Tzaihy  Adding LastCashoutDate/  
2021-09-13  Amir G          Adding 1.LastPublishedPostDate  
                                   2.LastAtionDateForLifeStage  
2022-02-17  Guy Manova      changed all direct update BI_DB_CIDFirstDates inference to alias, and all the left joins to joins.   
2022-02-22  Guy Manova      replcaed several sources and commented out several sections which were incorrect/inefficient/deprecated/zero rows  
2022-02-22  Guy Manova      ran one time script to nullify discontinued data points: KYC ,SuitabilityTestCompletedAt,PassedSuitabilityTest   
                           ,PEPCreatedTime ,PEPStatusUpdatedDate,isPassedPEP ,PEPStatusID   
                           ,FirstLeadDate ,Bankruptcy   
2022-02-22  Guy Manova     changed logics for FirstDepositAttemtpDate, FirstDepositDate, LastDepositDate                 
  
         
2022-02-29  Boris Slutski  Disable part of W8SignDate  
2022-05-12  Daniel Kaplan  Disable part of BI_DB_SFMC_Report
2022-06-19  Tal Cohen      Add delete for run date-to avoid duplications
2022-11-10  Eti Rozolio    shortly run time of update EvMatchStatus & DesignatedRegulationID
2023-02-27  Eti Rozolio    fixing the LastNewFundedDate
2023-05-09  Eti Rozolio    Disable RiskGroup & DepositGroup fields 
2023-01-04	Tom Boksenbojm Replacing Customer.Customer with 
2025-07-31  Nitsan Sharabi  Updating fundind data to include FTD global 
2025-09-17  Nitsan Sharabi Update for FTD global 
2025-10-22 Adi Meidan- Changing NewFunded Logic
2025-10-26 Jan Iablunovskey Added filter to FTD data dc.FTDPlatformID=1
2025-11-05 Jan Iablunovskey replaced FTD data dc.FTDPlatformID=1 with CAST(D.DepositID AS NVARCHAR(4000)) 
*********************************************************************************************/      

--declare @date datetime = cast(getdate()-1 as date) PRINT @date          
DECLARE @auxdate as DATETIME =dateadd(day,1,@date)       
DECLARE @dateINT as INT  =convert(int, convert(varchar(10), @date, 112))      
DECLARE @auxdateINT as INT  =convert(int, convert(varchar(10), @auxdate, 112))    
DECLARE @yesterday DATE = GETDATE()-1  
  
/*************************************************************************************************************************/      
/*                     BUILDING TABLES             */      
/*************************************************************************************************************************/      
 -- this cuts the #internal build by 4X   
IF OBJECT_ID('tempdb..#cust') IS NOT NULL DROP TABLE #cust
CREATE TABLE #cust  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT dc.RealCID AS CID ,  
       dc.IsValidCustomer,  
       dc.GCID,      
       dc.OriginalCID,      
       dc.RegionID,  
       dc.RegionByIP_ID,  
       dc.UserName,      
       dc.PlayerLevelID,      
       dc.PlayerStatusID,      
       dc.BirthDate,      
       dc.Gender,      
       dc.Email,      
       dc.CountryID,      
       dc.LanguageID,      
       dc.LabelID,      
       dc.CommunicationLanguageID,      
       dc.PrivacyPolicyID,      
       dc.SubSerialID,      
       dc.AffiliateID ,      
       dc.VerificationLevelID,      
       dc.AccountManagerID,      
       dc.RegulationID,      
       dc.FunnelID,      
       dc.FunnelFromID,      
       dc.RegisteredDemo,      
       dc.RegisteredReal,      
       dc.ReferralID,      
       dc.DownloadID,      
       dc.BannerID,      
       dc.IP          
FROM [DWH_dbo].[Dim_Customer] dc with (NOLOCK)      
WHERE 1=1
  
  
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #cust'  
IF OBJECT_ID('tempdb..#internal') IS NOT NULL DROP TABLE #internal
CREATE TABLE #internal  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS       
SELECT CID         
FROM #cust with (NOLOCK)      
WHERE IsValidCustomer  =0 ---PlayerLevelID = 4      
      
  
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #internal'   
IF OBJECT_ID('tempdb..#delete') IS NOT NULL DROP TABLE #delete
CREATE TABLE #delete  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS           
SELECT a.CID         
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(NOLOCK)      
JOIN #internal b ON a.CID=b.CID       
  
  
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #delete'        
DELETE FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]
WHERE CID IN (SELECT CID FROM #delete)      





IF OBJECT_ID('tempdb..#TotalCustomers') IS NOT NULL DROP TABLE #TotalCustomers
CREATE TABLE #TotalCustomers  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS     
SELECT dc.CID AS CID,      
    dc.GCID,      
    dc.OriginalCID,      
    dc.UserName,      
    dc.PlayerLevelID,      
    dc.PlayerStatusID,      
    dc.BirthDate,      
    dc.Gender,      
    dc.Email,      
    dc.CountryID,      
    ds.Name State,      
    dc.LanguageID,      
    dc.LabelID,      
    dc.CommunicationLanguageID,      
    dc.PrivacyPolicyID,      
    dc.SubSerialID,      
    dc.AffiliateID ,      
    dc.VerificationLevelID,      
    dc.AccountManagerID,      
    dc.RegulationID,      
    dc.FunnelID,      
    dc.FunnelFromID,      
    dc.RegisteredDemo,      
    dc.RegisteredReal,      
    dc.ReferralID,      
    dc.DownloadID,      
    dc.BannerID,      
    dc.IP          
FROM #cust dc with (nolock)      
LEFT JOIN [DWH_dbo].[Dim_State_and_Province] ds with(nolock) ON dc.RegionID = ds.RegionByIP_ID      
WHERE dc.IsValidCustomer  =1     
         
  
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #TotalCustomers'  
IF OBJECT_ID('tempdb..#CustomerData') IS NOT NULL DROP TABLE #CustomerData
CREATE TABLE #CustomerData  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS       
SELECT   cc.CID as CID      
        ,cc.GCID as GCID      
        ,cc.OriginalCID as OriginalCID      
        ,cc.UserName            
        ,country.Desk as PotentialDesk         
        ,pl.Name as Club      
        ,ISNULL(chan.Channel,'Direct') as Channel      
        ,ISNULL(chan.SubChannel,'Direct') as SubChannel      
        ,country.Name as Country       
        ,language.Name as Language      
        ,fun.Name as FunnelName            
        ,country.Region    
        ,country.MarketingRegionManualName AS NewMarketingRegion 
        ,ln.Name as LabelName      
        ,cc.AffiliateID as SerialID      
        ,(CASE when cc.RegisteredDemo < cc.RegisteredReal THEN cc.RegisteredDemo ELSE cc.RegisteredReal END) as  registered      
        ,(case when cc.[PlayerStatusID] in (2,4,6,7,8,9) then 1 else 0 end ) as Blocked      
        ,cc.Email      
        ,cc.ReferralID      
        ,cc.DownloadID      
        ,cc.Gender      
        ,cc.RegulationID      
        ,comlang.Name as CommunicationLanguage      
        ,cc.CountryID      
        ,cc.State      
        ,cc.BirthDate      
        ,funF.Name as FunnelFromName      
        ,cc.BannerID      
        ,cc.SubSerialID      
        ,cc.PrivacyPolicyID      
        ,ver.ID as Verified      
        ,man.FirstName+' '+man.LastName as Manager            
FROM #TotalCustomers cc      
LEFT JOIN [DWH_dbo].Dim_Funnel fun with (NOLOCK) ON cc.FunnelID=fun.FunnelID      
LEFT JOIN [DWH_dbo].Dim_Funnel funF  with (NOLOCK) ON cc.FunnelFromID=funF.FunnelID      
LEFT JOIN [DWH_dbo].Dim_Label ln with (NOLOCK) ON ln.[LabelID]=cc.[LabelID]      
LEFT JOIN [DWH_dbo].Dim_Country country with (NOLOCK) ON cc.CountryID=country.CountryID      
LEFT JOIN [DWH_dbo].Dim_Language language with (NOLOCK) ON cc.LanguageID=language.LanguageID      
LEFT JOIN [DWH_dbo].Dim_Affiliate aff  with(nolock) ON cc.AffiliateID=aff.AffiliateID      
LEFT JOIN [DWH_dbo].Dim_Channel chan with(nolock) ON aff.SubChannelID=chan.SubChannelID      
LEFT JOIN [DWH_dbo].Dim_PlayerLevel pl  with (NOLOCK) ON pl.PlayerLevelID=cc.PlayerLevelID      
LEFT JOIN [DWH_dbo].Dim_PlayerStatus pls with (NOLOCK) ON pls.PlayerStatusID=cc.PlayerStatusID      
LEFT JOIN [DWH_dbo].Dim_Language comlang with (NOLOCK) ON cc.CommunicationLanguageID=comlang.LanguageID      
LEFT JOIN [DWH_dbo].Dim_VerificationLevel ver with(nolock) ON ver.DWHVerificationLevelID=cc.VerificationLevelID      
LEFT JOIN [DWH_dbo].Dim_Manager man with(nolock) ON man.ManagerID=cc.AccountManagerID      
   

-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #CustomerData'      
/********************************************************UPDATE GENERAL DATA**************************************************************************************/      
/*update slowly changing dimnetion*/      
/*club*/      
/*language*/      
/*Comunicatlanguage*/      
/*is blocked*/      
/*Email*/          
--update existing customers       
    
IF OBJECT_ID('tempdb..#existingCIDFD') IS NOT NULL DROP TABLE #existingCIDFD
CREATE TABLE #existingCIDFD
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT *   
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] bdcd  
 

-- this can be improved by getting rid of unnecessary collation and casting but the gain isn't worth the effort or possible errors/ 
IF OBJECT_ID('tempdb..#updatenew') IS NOT NULL DROP TABLE #updatenew
CREATE TABLE #updatenew  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS   
SELECT b.*     
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #CustomerData b ON a.CID=b.CID       
WHERE ISNULL(a.Club,'') <> isnull(b.Club,'') COLLATE Latin1_General_BIN      
   OR ISNULL(a.Language,'')<> isnull(CAST(b.Language AS varchar(50)),'') COLLATE Latin1_General_BIN      
   OR ISNULL(a.CommunicationLanguage,'')<>isnull(CAST(b.CommunicationLanguage AS varchar(50)),'') COLLATE Latin1_General_BIN       
   OR a.Blocked<>b.Blocked      
   OR isnull(a.Email,'')<>isnull(CAST(b.Email AS varchar(50)),'') COLLATE Latin1_General_BIN      
   OR a.PrivacyPolicyID<>b.PrivacyPolicyID      
   OR isnull(a.BirthDate,'3000-01-01')<>isnull(b.BirthDate,'3000-01-01')      
   OR isnull(a.Gender,'N')!=CAST(isnull(b.Gender,'N') AS varchar(1)) COLLATE Latin1_General_BIN       
   OR isnull(a.SubAffiliateID,'N')<>isnull(b.SubSerialID,'N')  COLLATE Latin1_General_BIN      
   OR a.SerialID!=b.SerialID      
   OR a.LabelName<>CAST(b.LabelName AS varchar(50)) COLLATE Latin1_General_BIN       
   OR isnull(a.PotentialDesk,'')<>isnull(b.PotentialDesk,'') COLLATE Latin1_General_BIN               -- Luda 30.12.19      
   OR isnull(a.Region,'')<>isnull(b.Region,'') COLLATE Latin1_General_BIN   
   OR isnull(a.NewMarketingRegion,'')<>isnull(b.NewMarketingRegion,'') COLLATE Latin1_General_BIN   --Eti 2021-02-09  
   OR isnull(a.CountryID,'')<>isnull(b.CountryID,'')       
   OR isnull(a.State,'')<>isnull(b.State,'') COLLATE Latin1_General_BIN       
   OR a.Channel <>CAST(isnull(b.Channel ,'Direct') AS varchar(50)) COLLATE Latin1_General_BIN        
   OR a.SubChannel<>CAST(isnull(b.SubChannel ,'Direct')  AS varchar(50)) COLLATE Latin1_General_BIN       
   OR a.Verified<>b.Verified      
   OR isnull(a.Manager,'')<>CAST(b.Manager AS varchar(50)) COLLATE Latin1_General_BIN       
   OR a.RegulationID<>b.RegulationID      
    
 
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #updatenew'  
      
/********************************************************INSERT NEW GENERAL DATA**************************************************************************************/      
      
-- get new customers into CID_FisrtDates        
IF OBJECT_ID('tempdb..#NewCustomers') IS NOT NULL DROP TABLE #NewCustomers
CREATE TABLE #NewCustomers  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS        
SELECT   a.CID      
        ,a.GCID      
        ,a.OriginalCID      
        ,a.UserName       
        ,a.PotentialDesk      
        ,a.Club      
        ,a.Channel      
        ,a.SubChannel      
        ,a.Country       
        ,a.State      
        ,a.Language      
        ,a.FunnelName      
        ,a.Region    
        ,a.NewMarketingRegion 
        ,a.LabelName      
        ,a.SerialID      
        ,a.registered      
        ,a.Blocked      
        ,a.Email      
        ,a.ReferralID      
        ,a.DownloadID      
        ,a.Gender      
        ,a.RegulationID      
        ,a.CommunicationLanguage      
        ,a.CountryID      
        ,a.BirthDate      
        ,a.FunnelFromName      
        ,a.BannerID      
        ,a.SubSerialID       
        ,a.PrivacyPolicyID      
        ,a.Verified      
        ,a. Manager            
FROM #CustomerData  a with (NOLOCK)      
LEFT JOIN #existingCIDFD b with(nolock) ON a.CID=b.CID          
WHERE b.CID IS NULL      
     



---insert into CID_FisrtDates al new customers    
INSERT INTO [BI_DB_dbo].[BI_DB_CIDFirstDates]
( CID      
 ,GCID      
 ,OriginalCID      
 ,UserName      
 ,PotentialDesk      
 ,Club      
 ,Channel      
 ,SubChannel      
 ,Country       
 ,State      
 ,Language      
 ,FunnelName      
 ,Region      
 ,NewMarketingRegion
 ,LabelName      
 ,SerialID      
 ,registered      
 ,Blocked      
 ,Email      
 ,ReferralID      
 ,DownloadID      
 ,Gender           
 ,RegulationID                
 ,CommunicationLanguage      
 ,CountryID      
 ,BirthDate      
 ,FunnelFromName      
 ,[BannerID]      
 ,SubAffiliateID      
 ,PrivacyPolicyID      
 ,Verified      
 ,Manager      
 ,UpdateDate)      
     
SELECT CID      
      ,GCID      
      ,OriginalCID      
      ,UserName      
      ,PotentialDesk      
      ,Club      
      ,Channel      
      ,SubChannel      
      ,Country       
      ,State      
      ,Language      
      ,FunnelName      
      ,Region   
      ,NewMarketingRegion 
      ,LabelName      
      ,SerialID      
      ,registered      
      ,Blocked      
      ,Email      
      ,ReferralID      
      ,DownloadID      
      ,Gender           
      ,RegulationID                
      ,CommunicationLanguage      
      ,CountryID      
      ,BirthDate      
      ,FunnelFromName      
      ,[BannerID]      
      ,SubSerialID as SubAffiliateID     
      ,PrivacyPolicyID      
      ,Verified      
      ,Manager      
      ,getdate()                   
FROM #NewCustomers        

UPDATE a      
set  Club=b.Club      
    ,Language=b.Language      
    ,CommunicationLanguage=b.CommunicationLanguage      
    ,Blocked=b.Blocked      
    ,Email=b.Email      
    ,BirthDate=b.BirthDate      
    ,Gender=b.Gender      
    ,PotentialDesk=b.PotentialDesk     
    ,Region=b.Region   
    ,NewMarketingRegion=b.NewMarketingRegion
    ,CountryID=b.CountryID      
    ,Country=b.Country      
    ,State=b.State      
    ,PrivacyPolicyID=b.PrivacyPolicyID      
    ,SubAffiliateID=b.SubSerialID      
    ,SerialID=b.SerialID      
    ,LabelName=b.LabelName      
    ,SubChannel=b.SubChannel      
    ,Channel=b.Channel      
    ,Verified=b.Verified      
    ,Manager=b.Manager      
    ,RegulationID=b.RegulationID      
    ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #updatenew b ON a.CID=b.CID    
  
  -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate updateTheMissingCIDs'  
     
/*************************************************************************************************************************/      
/*                     Actions                */      
/*************************************************************************************************************************/      
      

IF OBJECT_ID('tempdb..#fca') IS NOT NULL DROP TABLE #fca
CREATE TABLE #fca  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT   
   a.GCID  
  , a.RealCID AS CID  
  , a.Occurred  
  , a.ActionTypeID  
  , a.Amount  
  , a.FundingTypeID  
  , a.MirrorID  
  , a.WithdrawID  
  , a.DurationInSeconds  
  , a.PostID  
  , a.CaseID  
  , a.DateID  
  , a.CompensationReasonID  
  , a.WithdrawPaymentID  
  , a.DepositID  
  , a.SessionID  
  , a.IsRedeem  
  , a.PlatformID  
  , a.PaymentStatusID  
  , a.IsFTD  
  , a.CountryIDByIP  
  , a.IsAirDrop  
  , a.rn  
  , a.rn_desc    
FROM (SELECT *  
             ,row_number() over(partition by RealCID,ActionTypeID order by Occurred) as rn      
             ,row_number() over(partition by RealCID,ActionTypeID order by Occurred desc) as rn_desc    
      FROM [DWH_dbo].[Fact_CustomerAction] fca  
      WHERE DateID>=@dateINT and DateID<@auxdateINT  
      AND fca.ActionTypeID IN (1,2,7,8,14,15,17,21,29,34,41)) a  
WHERE rn = 1 OR a.rn_desc = 1  
 
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #fca'  

IF OBJECT_ID('tempdb..#hc') IS NOT NULL DROP TABLE #hc
CREATE TABLE #hc  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS             
SELECT CID      
    ,Occurred      
    ,Amount      
    ,ActionTypeID      
    ,MirrorID      
    ,DepositID   
    ,IsFTD  
    ,rn  
    ,rn_desc     
FROM #fca hc   
WHERE hc.ActionTypeID = 7  
       
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #hc'  
  
------------------------------------------------------------------  
/*login*/--much less records on the original query ther are two logins #cash #login  
IF OBJECT_ID('tempdb..#Login1') IS NOT NULL DROP TABLE #Login1
CREATE TABLE #Login1  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS     
SELECT hc.CID, hc.Occurred AS LoggedIn , ActionTypeID, CASE WHEN rn=1 then 'min' ELSE 'max' end as type          
FROM #fca hc   
WHERE hc.ActionTypeID in (14,29)  

 -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Login1'    
-----------------------------------------------------------      
    
/*attemts*/ 
IF OBJECT_ID('tempdb..#attempts') IS NOT NULL DROP TABLE #attempts
CREATE TABLE #attempts  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS     
SELECT ffa.RealCID AS CID  
      ,ffa.DepositID  
      ,ffa.FirstOccurred  
      ,ffa.DateID  
      ,ffa.Amount  
      ,1 AS ExchangeRate -- this isn't needed, but this is USD amount replacing Prod Currency amount, so to keep with minimal changes (Guy 2022-02-17)   
FROM [DWH_dbo].[Fact_FirstCustomerAction] ffa  
WHERE ffa.DateID = @dateINT  
  AND ffa.ActionTypeID = 27  
  AND ffa.FirstOccurred BETWEEN @date AND @auxdate 
 
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #attempts'  
 
 -- the logic for this was wrong, going to the wrong table (BillingDeposit only holds last status), and using wrong logic of RNs (looking only at yesterday   
 -- instead of all time  
IF OBJECT_ID('tempdb..#pre_depositatt') IS NOT NULL DROP TABLE #pre_depositatt
CREATE TABLE #pre_depositatt  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS    
SELECT D.CID ,      
       D.DepositID,      
       'NA' AS DepotID,      
       'NA' AS FundingID,  
       D.Amount,      
       D.ExchangeRate,     
       null as rn,      
       null as rndesc,      
       D.FirstOccurred AS PaymentDate       
FROM #attempts D  with(NOLOCK)    -- replaced going to vDeposits via linked server (Guy 2022-02-17)   
     
 -- create only attempts deposits +funding      
 -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #pre_depositatt'  

 
IF OBJECT_ID('tempdb..#DepositFundatt') IS NOT NULL DROP TABLE #DepositFundatt
CREATE TABLE #DepositFundatt  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS        
SELECT D.CID ,      
       NULL AS FundingID,      
       D.DepositID,      
       D.PaymentDate,      
       'NA' as FundingTypeName,      
       D.Amount*D.ExchangeRate as FirstDepositAttemptAmount,     
       'NA' as Processor,      
       D.rn,      
       D.rndesc          
FROM #pre_depositatt D         

 -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #DepositFundatt'  
      
/*funding */           
--step 1      
IF OBJECT_ID('tempdb..#DepositFund') IS NOT NULL DROP TABLE #DepositFund
CREATE TABLE #DepositFund  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS          -- it's unclear what is the purpose of this. it's identical to the #DepositFundatt table. no new info.   
SELECT D.CID ,      
       'NULL' AS FundingID,      
       D.DepositID,      
       D.Amount*D.ExchangeRate as FirstDepositAttemptAmount,    
       'NA'  as Processor    
FROM #pre_depositatt  D with(NOLOCK)  
 
 -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #DepositFund'  
      
-- step 2        
/*  
this part of the process is a) wrong,  it takes deposit attempts instead of deposits. since there is no way to provide an efficient   
method of FundingID to FirstAttempt, and it's no used in any proc on BI_DB, i'm commenting out the section and building a new #funding table   
which only brings first deposits, not first deposit attmepts. attempts will be shown without funding type and processor.    
*/  
      
IF OBJECT_ID('tempdb..#funding') IS NOT NULL DROP TABLE #funding
CREATE TABLE #funding  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT dc.RealCID as CID
      ,D.FundingID
	  ,D.DepositID
	  ,D.DepotID 
	  ,D.FundingTypeID
	  ,F.Name as FundingTypeName
	  ,dbd.Name AS Processor
	  ,dc.FirstDepositAmount AS FirstDepositAmount /*Nitsan */ 
      ,df.PaymentDate AS FirstDepositAttmeptDate
	  ,df.FirstDepositAttemptAmount
	  ,dc.FirstDepositDate AS FirstDepositDate      /*Nitsan*/   
FROM DWH_dbo.Dim_Customer dc 
LEFT JOIN [DWH_dbo].[Fact_BillingDeposit] D  ON dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000))  /*Jan*/
AND D.ModificationDateID =@dateINT  AND D.IsFTD = 1  /*Nitsan*/
LEFT JOIN [DWH_dbo].[Dim_FundingType] F with(NOLOCK) ON D.FundingTypeID = F.FundingTypeID      
LEFT JOIN [DWH_dbo].[Dim_BillingDepot] dbd ON D.DepotID = dbd.DepotID  
LEFT JOIN #DepositFundatt df ON D.CID = df.CID  



   
   -- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #funding' 
   
IF OBJECT_ID('tempdb..#fundingLast') IS NOT NULL DROP TABLE #fundingLast
CREATE TABLE #fundingLast  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT fbd.CID
      ,fbd.FundingID
	  ,fbd.DepositID
	  ,fbd.DepotID 
	  ,fbd.FundingTypeID
	  ,F.Name as FundingTypeName
	  ,dbd.Name AS Processor
	  ,D.Amount*fbd.ExchangeRate AS LastDepositAmount    
      ,df.PaymentDate AS LastDepositAttmeptDate
      ,df.FirstDepositAttemptAmount
      ,fbd.ModificationDate AS LastDepositDate        
FROM #hc D  
LEFT JOIN [DWH_dbo].[Fact_BillingDeposit] fbd ON D.CID = fbd.CID AND D.DepositID = fbd.DepositID  
LEFT join [DWH_dbo].[Dim_FundingType] F with(NOLOCK) ON fbd.FundingTypeID = F.FundingTypeID      
LEFT JOIN [DWH_dbo].[Dim_BillingDepot] dbd ON fbd.DepotID = dbd.DepotID  
LEFT JOIN #DepositFundatt df ON fbd.CID = df.CID  
WHERE D.rn_desc = 1 
   
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #fundingLast'  
  
  
/**********************************************************************************************/      
/*                                Depoists                                                    */       
/*                         */      
/**********************************************************************************************/      
  
--first deposits data     
UPDATE a     
SET  FirstDepositProcessor= b.Processor        
    ,FirstDepositFundingType=b.FundingTypeName      
    ,FirstDepositDate=b.Occurred      
    ,FirstDepositAmount=b.Amount      
    ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)   
JOIN  (SELECT funds.CID       
             ,funds.FirstDepositDate AS Occurred    
             ,funds.Processor      
             ,FundingTypeName      
             ,funds.FirstDepositAmount as Amount      
       FROM #funding funds) b ON a.CID=b.CID      
WHERE a.FirstDepositDate is null  or a.FirstDepositDate>b.Occurred  
OR year(a.FirstDepositDate) = '1900' /* Nitsan*/
  
      
--last deposits data     
UPDATE a      
SET  LastDepositFundingType=b.FundingTypeName      
    ,LastDepositDate=b.Occurred      
    ,LastDepositAmount=b.Amount      
    ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock) 
JOIN (SELECT funds.CID       
            ,funds.LastDepositDate AS Occurred  
            ,funds.Processor      
            ,FundingTypeName      
            ,funds.LastDepositAmount as Amount      
      FROM #fundingLast funds) b ON a.CID=b.CID            
WHERE a.LastDepositDate is null  or a.LastDepositDate<b.Occurred     
  
      
      
UPDATE a      
SET  FirstDepositAttempt= b.PaymentDate      
    ,FirstDepositAttemptAmount= b.FirstDepositAttemptAmount      
    ,FirstDepositAttemptProcessor= b.Processor        
    ,FirstDepositAttemptFundingType= b.FundingTypeName        
    ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)    
JOIN #DepositFundatt  b ON a.CID=b.CID    
WHERE a.FirstDepositAttempt is null or a.FirstDepositAttempt>@date      
      
/**********************************************************************************************/      
/*                           Login                                                            */       
/*                         */      
/**********************************************************************************************/      
    
/*Cashier*/      
UPDATE a     
SET FirstCashierLogin=LoggedIn      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID,LoggedIn       
      FROM #Login1      
      WHERE ActionTypeID=29  and type='min') b ON(a.CID=b.CID)      
WHERE a.FirstCashierLogin is null or a.FirstCashierLogin>@date      
      
UPDATE a    
SET LastCashierLogin=LoggedIn      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID,max (LoggedIn)as LoggedIn       
      FROM #Login1      
      WHERE ActionTypeID=29       
      GROUP BY  CID ) b ON(a.CID=b.CID)     
      
/*Login*/           
UPDATE a      
SET FirstLoggedIn =b.LoggedIn      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID,LoggedIn       
      FROM #Login1 
	  WHERE ActionTypeID=14  and type='min') b ON (a.CID=b.CID)      
WHERE a.FirstLoggedIn is null or a.FirstLoggedIn>@date          
      
UPDATE a      
SET LastLoggedIn =b.LoggedIn      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]  a with(nolock)      
JOIN (SELECT CID,max (LoggedIn)as LoggedIn       
      FROM #Login1 
	  WHERE ActionTypeID=14        
      GROUP BY  CID)b ON (a.CID=b.CID)      
    
/**********************************************************************************************/      
/*                           Position and Mirror                                              */       
/*                         */      
/**********************************************************************************************/      
  
UPDATE a     
SET FirstPosOpenDate= b.FirstPosOpenDate      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT  CID,min(Occurred)  AS FirstPosOpenDate      
	  FROM #fca     
      WHERE ActionTypeID in (1,2) AND rn = 1  
      GROUP BY CID) b ON (a.CID=b.CID)      
WHERE a.FirstPosOpenDate is null or a.FirstPosOpenDate>@date     
       
UPDATE a      
SET FirstMenualPosOpenDate=b.FirstMenualPosOpenDate        
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT  CID,Occurred  AS FirstMenualPosOpenDate      
      FROM #fca      
      WHERE ActionTypeID=1 AND rn = 1) b ON (a.CID=b.CID)      
WHERE a.FirstMenualPosOpenDate is null or a.FirstMenualPosOpenDate>@date        
      
UPDATE a      
SET FirstMirrorPosOpenDate=b.FirstMirrorPosOpenDate      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT  CID,Occurred  AS FirstMirrorPosOpenDate      
      FROM #fca      
      WHERE ActionTypeID=2 AND rn = 1) b ON (a.CID=b.CID)      
WHERE a.FirstMirrorPosOpenDate is null or a.FirstMirrorPosOpenDate>@date           
          
UPDATE a      
SET FirstMirrorRegistrationDate=b.FirstMirrorRegistrationDate      
    ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT  CID,Occurred  AS FirstMirrorRegistrationDate      
      FROM #fca      
      WHERE ActionTypeID=17 AND rn = 1) b ON (a.CID=b.CID)      
WHERE a.FirstMirrorRegistrationDate is null  or a.FirstMirrorRegistrationDate>@date           
       
UPDATE a    
SET FirstStocksOpenDate=b.FirstStocksOpenDate      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT  CID,Occurred AS FirstStocksOpenDate      
      FROM #fca      
      WHERE ActionTypeID =34  AND rn = 1) b ON (a.CID=b.CID)      
WHERE a.FirstStocksOpenDate is null or a.FirstStocksOpenDate>@date           
      
      
UPDATE a     
SET LastPosOpenDate=isnull(b.LastPosOpenDate,a.LastPosOpenDate)      
   ,LastMirrorPosOpenDate=isnull(b.LastMirrorPosOpenDate,a.LastMirrorPosOpenDate)      
   ,LastMenualPosOpenDate=isnull(b.LastMenualPosOpenDate,a.LastMenualPosOpenDate)      
   ,LastMirrorRegistrationDate=isnull(b.LastMirrorRegistrationDate,a.LastMirrorRegistrationDate)      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID      
            ,max(CASE WHEN ActionTypeID in (1,2) THEN Occurred END) AS LastPosOpenDate      
            ,max(CASE WHEN ActionTypeID = 1 THEN Occurred END) AS LastMenualPosOpenDate      
            ,max(CASE WHEN ActionTypeID = 2 THEN  Occurred END) AS LastMirrorPosOpenDate      
            ,max(CASE WHEN ActionTypeID = 17 THEN Occurred END) AS LastMirrorRegistrationDate      
      FROM #fca      
      WHERE ActionTypeID in (1,2,17)      
      GROUP BY CID ) b ON (a.CID=b.CID)           
      
/*************************************************************************************************************************/      
/*                     cashout                     */      
/*************************************************************************************************************************/              
UPDATE a     
SET FirstCashoutDate= b.Occurred        
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID,Occurred as Occurred      
      FROM #fca       
      WHERE ActionTypeID=8 and rn = 1) b ON a.CID=b.CID      
WHERE a.FirstCashoutDate is null or a.FirstCashoutDate>@date      
  
UPDATE a      
SET LastCashoutDate= b.Occurred        
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN (SELECT CID,Occurred as Occurred      
      FROM #fca       
      WHERE ActionTypeID=8 and rn_desc = 1) b ON a.CID=b.CID      
WHERE a.LastCashoutDate is null or a.LastCashoutDate>@date           
  
       
/**********************************************************************************************/      
/*                           Credit +RealizedEquity                                           */       
/*                         */      
/**********************************************************************************************/      

IF @date = @yesterday
BEGIN 

IF OBJECT_ID('tempdb..#Liabilities') IS NOT NULL DROP TABLE #Liabilities
CREATE TABLE #Liabilities  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT CID      
    ,DateID      
    ,Credit      
    ,RealizedEquity           
FROM [DWH_dbo].[V_Liabilities]  with(nolock)      
WHERE DateID=@dateINT    
      
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Liabilities'  
   
UPDATE a      
SET Credit=isnull(l.Credit,0)      
   ,RealizedEquity=isnull(l.RealizedEquity,0)      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(NOLOCK)      
JOIN #Liabilities l ON a.CID=l.CID      

END
      
      
/*************************************************************************************************************************/      
/*                     copy                */      
/*************************************************************************************************************************/      
      
/*Copiers*/      
IF OBJECT_ID('tempdb..#copy') IS NOT NULL DROP TABLE #copy
CREATE TABLE #copy  
WITH (HEAP,DISTRIBUTION=HASH(ParentCID))
AS  
SELECT ParentCID,
       MIN(OpenOccurred) as FirstTimeBeingCopied,
	   MAX(OpenOccurred) as LastTimeBeingCopied          
FROM  [DWH_dbo].[Dim_Mirror] with(nolock)      
WHERE OpenOccurred >=@date and OpenOccurred<@auxdate        
GROUP BY ParentCID      
          
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #copy'  
   
UPDATE a      
SET  FirstTimeBeingCopied= b.FirstTimeBeingCopied        
     ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #copy b ON a.CID=b.ParentCID     
WHERE a.FirstTimeBeingCopied is null or a.FirstTimeBeingCopied>@date    
      
UPDATE a      
SET LastTimeBeingCopied= b.LastTimeBeingCopied      
   ,UpdateDate = GETDATE()        
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #copy b ON a.CID=b.ParentCID     

--------------------------------------------------------------------------------------------------------------------------------      
--Disable because unrelevant
--Risk groups
--IF OBJECT_ID('tempdb..#Risk') IS NOT NULL DROP TABLE #Risk
--CREATE TABLE #Risk  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS
--SELECT RealCID AS CID
--      ,ROW_NUMBER () OVER (PARTITION BY  RealCID ORDER BY UpdateDate DESC) rn      
--      ,RiskGroup      
--      ,DepositGroup        
--FROM [BI_DB_dbo].[BI_DB_User_Segment]    
--WHERE UpdateDate>=DATEADD(DAY,-2, @date) and UpdateDate<@auxdate      

---- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Risk'  
  
--UPDATE a       
--SET RiskGroup=b.RiskGroup    
--   ,DepositGroup=b.DepositGroup      
--   ,UpdateDate = getdate()      
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]  a with(nolock)      
----JOIN #Risk b with (NOLOCK) ON a.CID=b.RealCID   
--JOIN #Risk b with (NOLOCK) ON a.CID=b.CID ------ Fixed by Eyal
--WHERE b.rn=1      


--------------------------------------------------------------------------------------------------------------------------------      
--Social  
--Table not update since Sep 2018!!!
--UPDATE a    
--SET SocialConnect=1      
--   ,FirstTimeSocialConnect=b.ConnectDate      
--   ,UpdateDate = getdate()      
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
--JOIN [AZR-W-REAL-DB-2-BIDBUser].[etoro].Customer.PrivacyUniqueIdentity b with (NOLOCK) ON a.CID=b.CID  
--WHERE a.SocialConnect is NULL    


      
  ------Union all 
IF OBJECT_ID('tempdb..#Contacts') IS NOT NULL DROP TABLE #Contacts
CREATE TABLE #Contacts  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT CID  
      ,MAX(ut.CreatedDate_SF) LastContactDate  
      ,MIN(ut.CreatedDate_SF) FirstContactDate  
      ,MAX(CASE WHEN ActionName = 'Phone_Call_Succeed__c'  THEN CreatedDate_SF END)   LastContactDate_ByPhone     
FROM [BI_DB_dbo].[BI_DB_UsageTracking_SF] ut WITH (NOLOCK)  
WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c')  
GROUP BY CID   
    
  
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Contacts'  
      
UPDATE a    
SET LastContactDate=b.LastContactDate      
   ,FirstContactDate=case when a.FirstContactDate is null or a.FirstContactDate>b.FirstContactDate  then b.FirstContactDate else a.FirstContactDate end      
   ,LastContactDate_ByPhone = b.LastContactDate_ByPhone      
   ,UpdateDate = getdate()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #Contacts b ON(a.CID=b.CID)     


/**************************Engegment**********************************/-- comment by adi
--EXEC [BI_DB_dbo].[SP_Create_External_Streams_dbo_Entries] @date, 'pre_eng'

--IF OBJECT_ID('tempdb..#pre_eng') IS NOT NULL DROP TABLE #pre_eng
--CREATE TABLE #pre_eng  
--WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
--AS
--SELECT SUBSTRING(Username,2,100) Username
--      ,OccurredAt 
--FROM [BI_DB_dbo].External_Streams_dbo_Entries_pre_eng
--WHERE TypeName IN ('Comment','Like','Discussion')
--  AND OccurredAt>=CAST(CONVERT(VARCHAR, @date,112) AS VARCHAR(10)) AND OccurredAt<CAST(CONVERT(VARCHAR, @auxdate,112) AS VARCHAR(10))


--IF OBJECT_ID('tempdb..#eng_final') IS NOT NULL DROP TABLE #eng_final
--CREATE TABLE #eng_final  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS      
--SELECT RealCID CID
--      ,OccurredAt    
--FROM #pre_eng a 
--JOIN [DWH_dbo].[Dim_Customer] c with(nolock) ON a.Username=c.UserName    
--WHERE PlayerLevelID!=4    
    

  
--IF OBJECT_ID('tempdb..#eng') IS NOT NULL DROP TABLE #eng
--CREATE TABLE #eng  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS   
--SELECT CID 
--      ,MIN(OccurredAt) as FirstEngagementDate      
--      ,MAX(OccurredAt) as LastEngagementDate          
--FROM #eng_final    
--GROUP BY CID    
    
  
    
--UPDATE a     
--SET FirstEngagementDate= b.FirstEngagementDate       
--   ,UpdateDate = GETDATE()       
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
--JOIN #eng b ON a.CID=b.CID     
--WHERE a.FirstEngagementDate IS NULL OR a.FirstEngagementDate>@date       
      
      
--UPDATE a     
--SET LastEngagementDate= b.LastEngagementDate       
--   ,UpdateDate = GETDATE()       
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
--JOIN #eng b ON a.CID=b.CID    
-- comment by adi
--------------------------------------------------------------------------------------------------------------------------------
EXEC [BI_DB_dbo].[SP_Create_External_etoro_History_Credit] @date, 'coup'


--Campaign
IF OBJECT_ID('tempdb..#coup') IS NOT NULL DROP TABLE #coup
CREATE TABLE #coup  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS       
SELECT [CID]  -- we also Dim_Campaig but where do we have history and also have the subserialid or maby it the first one on the DWH       
      ,[CampaignID]      
      ,[Occurred]       
      ,[Payment]         
FROM(SELECT [CID]      
           ,[CampaignID]      
           ,[Occurred]       
           ,[Payment]      
           ,ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Occurred) rn      
     FROM [BI_DB_dbo].[External_etoro_History_Credit_coup] --[AZR-W-REAL-DB-2-BIDBUser].[etoro].[History].[Credit] with(nolock)      
     WHERE [CampaignID] IS NOT NULL AND cast(Occurred as date)>=@date AND Occurred<@auxdate --AND CID = @cid  
     )t      
WHERE rn=1      
          
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #coup'  

UPDATE  a      
SET [FirstCampaignID] = b.[CampaignID]      
   ,[FirstCampaignDate] = b.[Occurred]      
   ,[FirstCampaignAmount] = b.[Payment]      
   ,UpdateDate = GETDATE()      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #coup b ON a.CID=b.CID      
WHERE a.[FirstCampaignDate] is null or a.[FirstCampaignDate] >=@date       
      
--------------------------------------------------------------------------------------------------------------------------------      
     
--**************************************************************--      
--*********        VERFICATION UPDATE PART     *****************--      
--**************************************************************--     
EXEC [BI_DB_dbo].[SP_Create_External_etoro_history_BackOfficeCustomer] @date, 'BackOfficeCaustomerTable'


IF OBJECT_ID('tempdb..#BackOfficeCaustomerTable') IS NOT NULL DROP TABLE #BackOfficeCaustomerTable
CREATE TABLE #BackOfficeCaustomerTable  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS          
SELECT CID , 
       MIN(CASE WHEN HB.PhoneVerifiedID in (1,2) THEN ValidFrom --1=AutomaticallyVerified, 2=ManualyVerified      
                END) AS PhoneVerifiedDate        
FROM  [BI_DB_dbo].[External_etoro_history_BackOfficeCustomer_BackOfficeCaustomerTable] AS HB --[AZR-W-REAL-DB-2-BIDBUser].[etoro].[History].[BackOfficeCustomer]      
WHERE ValidFrom >=@date and ValidFrom < @auxdate   --AND HB.CID = @cid  
GROUP BY CID       
      
            
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #BackOfficeCaustomerTable'  
      
--**************************************************************--      
--*********        VERFICATION UPDATE PART - NEW Version     *****************--      
--**************************************************************--      
IF OBJECT_ID('tempdb..#BackOfficeCustomer') IS NOT NULL DROP TABLE #BackOfficeCustomer
CREATE TABLE #BackOfficeCustomer  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS         
SELECT sc1.RealCID AS CID   
      ,CAST(CONVERT(DATETIME,CONVERT(varchar(10),MIN(CASE WHEN sc1.VerificationLevelID = 1 THEN dr1.FromDateID END)))AS DATE) AS VerificationLevel1Date      
      ,CAST(CONVERT(DATETIME,CONVERT(varchar(10),MIN(CASE WHEN sc1.VerificationLevelID = 2 THEN dr1.FromDateID END)))AS DATE) AS VerificationLevel2Date      
      ,CAST(CONVERT(DATETIME,CONVERT(varchar(10),MIN(CASE WHEN sc1.VerificationLevelID = 3 THEN dr1.FromDateID END)))AS DATE) AS VerificationLevel3Date      
      ,CAST(CONVERT(DATETIME,CONVERT(varchar(10),MIN(CASE WHEN sc1.EvMatchStatus = 2 THEN dr1.FromDateID END)))AS DATE) AS EvMatchStatusDate      
      ,MIN(CASE WHEN sc1.IsEmailVerified = 1 THEN dr1.FromDateID END) AS EmailVerifiedDateID      
      ,CAST(CONVERT(DATETIME,CONVERT(varchar(10),MIN(CASE WHEN sc1.IsEmailVerified = 1 THEN dr1.FromDateID END)))AS DATE) AS EmailVerifiedDate      
FROM [DWH_dbo].[Fact_SnapshotCustomer] sc1 with (NOLOCK)      
JOIN [DWH_dbo].[Dim_Range] dr1 with (NOLOCK) ON dr1.DateRangeID = sc1.DateRangeID      
GROUP BY sc1.RealCID      
          
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #BackOfficeCustomer'  
      
--VerificationLevel1Date      
UPDATE a    
SET VerificationLevel1Date = b.VerificationLevel1Date      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCustomer  b ON a.CID=b.CID       
WHERE a.VerificationLevel1Date IS NULL AND b.VerificationLevel1Date IS NOT NULL    
      
--VerificationLevel2Date      
UPDATE a     
SET VerificationLevel2Date = b.VerificationLevel2Date,      
    VerificationLevel1Date = (CASE WHEN a.VerificationLevel1Date IS NULL THEN b.VerificationLevel2Date ELSE a.VerificationLevel1Date END)      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCustomer  b ON a.CID=b.CID      
WHERE a.VerificationLevel2Date IS NULL AND b.VerificationLevel2Date IS NOT NULL    
      
--VerificationLevel3Date      
UPDATE a      
SET VerificationLevel3Date = b.VerificationLevel3Date,      
    VerificationLevel2Date =  (CASE WHEN a.VerificationLevel2Date IS NULL THEN b.VerificationLevel3Date ELSE a.VerificationLevel2Date END),      
    VerificationLevel1Date = (CASE WHEN a.VerificationLevel1Date IS NULL THEN b.VerificationLevel3Date ELSE a.VerificationLevel1Date END)      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCustomer  b ON a.CID=b.CID       
WHERE a.VerificationLevel3Date IS NULL AND b.VerificationLevel3Date IS NOT NULL     
    
	
----FirstInstallDate
IF OBJECT_ID('tempdb..#CIDinstallNULL') IS NOT NULL DROP TABLE #CIDinstallNULL
CREATE TABLE #CIDinstallNULL
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT CID
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a
WHERE a.FirstInstallDate IS NULL


--IF OBJECT_ID('tempdb..#connection') IS NOT NULL DROP TABLE #connection
--CREATE TABLE #connection
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS      
--SELECT a.CID
--      ,a.TrackingValue     
--FROM [BI_DB_dbo].[External_etoro_Customer_TrackingId] a
--JOIN #CIDinstallNULL b ON a.CID=b.CID
--WHERE CAST(Occurred AS DATE) = @date  


/*Tom Boksenbojm 01/04/2024*/
IF OBJECT_ID('tempdb..#connection') IS NOT NULL DROP TABLE #connection
CREATE TABLE #connection
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS    
SELECT  a.CID
       ,MAX(a.AppsflyerID) AppsflyerID
FROM [BI_DB_dbo].[External_MarketPerformance_Tracking_Customer] a
INNER JOIN #CIDinstallNULL b 
ON a.CID=b.CID
WHERE UpdatedAt >=@date  
AND UpdatedAt < DATEADD(DAY,1,@date)  
GROUP BY a.CID
    
IF OBJECT_ID('tempdb..#A') IS NOT NULL DROP TABLE #A
CREATE TABLE #A
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS   
SELECT CID      
      ,FirstInstallDate      
FROM (SELECT b.CID      
            ,MIN(EventTime) FirstInstallDate       
      FROM [BI_DB_dbo].[BI_DB_AppFlyer_Reports] a with (nolock)        
      LEFT JOIN #connection b ON a.AppsFlyerID =b.AppsflyerID COLLATE Latin1_General_Bin       
      WHERE EventName = 'install'   
      GROUP BY b.CID)a    

      
UPDATE a      
SET FirstInstallDate= b.FirstInstallDate      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #A b ON a.CID=b.CID       



--EmailVerifiedDate     
UPDATE a      
SET EmailVerifiedDate = b.EmailVerifiedDate      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCustomer  b ON a.CID=b.CID       
WHERE a.EmailVerifiedDate IS NULL AND b.EmailVerifiedDate IS NOT NULL      
      
      
UPDATE a      
SET EvMatchStatusDate = b.EvMatchStatusDate      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCustomer  b ON a.CID=b.CID       
WHERE a.EvMatchStatusDate IS NULL AND b.EvMatchStatusDate IS NOT NULL

      
--EvMatchStatusDate      
UPDATE a    
SET PhoneVerifiedDate= b.PhoneVerifiedDate      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)      
JOIN #BackOfficeCaustomerTable  b ON a.CID=b.CID       
WHERE a.PhoneVerifiedDate IS NULL AND b.PhoneVerifiedDate IS NOT NULL    


EXEC [BI_DB_dbo].[SP_Create_External_ComplianceStateDB_Compliance_CustomerKycMode] @date , 'CustomerKycMode'
    
IF OBJECT_ID('tempdb..#CustomerKycMode') IS NOT NULL DROP TABLE #CustomerKycMode
CREATE TABLE #CustomerKycMode  
WITH (HEAP,DISTRIBUTION=HASH(GCID))
AS  
SELECT GCID,KycModeID       
FROM [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerKycMode_CustomerKycMode]    --[Compliance].[ComplianceStateDB].[Compliance].[CustomerKycMode]
WHERE UpdateTime >= @date AND UpdateTime<@auxdate
       
-- insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #CustomerKycMode'  
      
UPDATE a      
SET KycModeID= b.KycModeID      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
JOIN #CustomerKycMode b ON a.GCID = b.GCID       
  
      
--EV Updating
IF OBJECT_ID('tempdb..#Update_EvMatchStatus') IS NOT NULL DROP TABLE #Update_EvMatchStatus
CREATE TABLE #Update_EvMatchStatus  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT a.CID, b.EvMatchStatus
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
JOIN [DWH_dbo].[Dim_Customer] b with (NOLOCK)  on a.CID = b.RealCID 
WHERE ISNULL(a.EvMatchStatus,-1)<>ISNULL(b.EvMatchStatus,-1)


UPDATE a  
SET EvMatchStatus= b.EvMatchStatus      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
JOIN #Update_EvMatchStatus b with (NOLOCK) on a.CID = b.CID 

IF OBJECT_ID('tempdb..#Update_DesignatedRegulationID') IS NOT NULL DROP TABLE #Update_DesignatedRegulationID
CREATE TABLE #Update_DesignatedRegulationID  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS 
SELECT a.CID, b.DesignatedRegulationID
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
JOIN [DWH_dbo].[Dim_Customer] b with (NOLOCK)  on a.CID = b.RealCID 
WHERE ISNULL(a.DesignatedRegulationID,-1)<>ISNULL(b.DesignatedRegulationID,-1)


 
UPDATE a  
SET DesignatedRegulationID = b.DesignatedRegulationID       
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
JOIN #Update_DesignatedRegulationID b with (NOLOCK) ON a.CID = b.CID  

      
--FASTFTD      
UPDATE a     
SET FTDIsLessThanAWeek = CASE WHEN DATEDIFF(DAY,a.registered,a.FirstDepositDate) < 8 and a.FirstDepositAmount > 0  THEN 1 ELSE 0 END      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)       
WHERE a.registered>getdate()-10  
      
-- Professional Application Date
UPDATE a   
SET ProfessionalApplicationDate = pl.ApplicationDate      
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a with(nolock)  
JOIN [DWH_dbo].[Dim_Customer] dc ON a.CID=dc.RealCID
JOIN [BI_DB_dbo].[External_ComplianceStateDB_Compliance_CustomerProfessionalQuestionnaireResult] pl ON dc.GCID = pl.GCID      
WHERE pl.ApplicationDate >= @date AND pl.ApplicationDate < DATEADD(d,1,@date)

 /***********************************************************IsFunded**************************************/  
--IF OBJECT_ID('tempdb..#LTF_Prep') IS NOT NULL DROP TABLE #LTF_Prep
--CREATE TABLE #LTF_Prep  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS
--SELECT a.CID  
--      ,MAX(CASE WHEN dd.FullDate>=@date THEN @date ELSE dd.FullDate END) LastFundedDate 
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a 
--JOIN [DWH_dbo].[Fact_SnapshotEquity] fse WITH (NOLOCK) ON a.CID = fse.CID AND fse.RealizedEquity >0
--JOIN [DWH_dbo].[Dim_Range] dr WITH (NOLOCK) ON fse.DateRangeID = dr.DateRangeID
--JOIN [DWH_dbo].[Dim_Date] dd WITH (NOLOCK) ON dr.ToDateID = DateKey
--JOIN [DWH_dbo].[Dim_Customer] dc ON dc.RealCID=a.CID AND dc.IsDepositor=1
--WHERE FirstNewFundedDate IS NOT NULL  
--AND a.FirstDepositDate IS NOT NULL  
--AND a.IsFundedNew = 1  
--GROUP BY a.CID  

----------------------------------------------------------------------------------------------  
--IF OBJECT_ID('tempdb..#IsFundedNew') IS NOT NULL DROP TABLE #IsFundedNew
--CREATE TABLE #IsFundedNew  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS 
--SELECT DISTINCT fd.CID  
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH(NOLOCK)  
--JOIN [DWH_dbo].[V_Liabilities] vl ON fd.CID = vl.CID AND vl.DateID = @dateINT  
--JOIN [DWH_dbo].[Dim_Customer] dc ON dc.RealCID = fd.CID  
--WHERE fd.FirstDepositDate IS NOT NULL  
--  AND vl.Liabilities+vl.ActualNWA >0  
--  AND fd.FirstPosOpenDate IS NOT NULL   
--  AND dc.VerificationLevelID = 3 
  
-------------------New IsFundedNew - Adi 21.10.25-----------
--DECLARE @dateINT as INT  =20251001--convert(int, convert(varchar(10), @date, 112)) 
--select top 10 * FROM BI_DB_dbo.Function_Population_Funded(@dateINT) fpf



IF OBJECT_ID('tempdb..#IsFundedNew') IS NOT NULL DROP TABLE #IsFundedNew
CREATE TABLE #IsFundedNew  
WITH (HEAP,DISTRIBUTION=HASH(RealCID))
AS 
SELECT RealCID
FROM BI_DB_dbo.Function_Population_Funded(@dateINT) fpf

--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #IsFundedNew'  
  
UPDATE fd    
SET fd.IsFundedNew = case when ifn.RealCID is null then 0 ELSE 1 end  --CASE WHEN ifn.CID IS NOT NULL THEN 1 ELSE 0 END  

FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH(NOLOCK)  
left JOIN #IsFundedNew ifn ON fd.CID = ifn.RealCID   
  
 ------------------------------------------------  
--IF OBJECT_ID('tempdb..#FTFprep') IS NOT NULL DROP TABLE #FTFprep
--CREATE TABLE #FTFprep  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS   
--SELECT faf.CID  
--      ,CAST(faf.FirstDepositDate AS DATE) AS FirstDepositDate  
--      ,CAST(faf.VerificationLevel3Date AS DATE) AS VerificationLevel3Date  
--      ,CAST(faf.FirstPosOpenDate AS DATE) AS FirstPosOpenDate   
--FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] faf  WITH(NOLOCK)  
--WHERE faf.FirstDepositDate IS NOT NULL  
--  AND faf.VerificationLevel3Date IS NOT NULL  
--  AND faf.FirstPosOpenDate IS NOT NULL  
--  AND faf.FirstNewFundedDate IS NULL  

--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #FTFprep' 

--IF OBJECT_ID('tempdb..#FTF') IS NOT NULL DROP TABLE #FTF
--CREATE TABLE #FTF  
--WITH (HEAP,DISTRIBUTION=HASH(CID))
--AS  
--SELECT CID  
--       ,CASE WHEN t.FirstDepositDate = FirstPosOpenDate AND FirstPosOpenDate = VerificationLevel3Date THEN t.FirstDepositDate         
--             WHEN t.VerificationLevel3Date < t.FirstDepositDate AND t.FirstDepositDate < t.FirstPosOpenDate THEN t.FirstPosOpenDate   
--             WHEN t.VerificationLevel3Date < t.FirstDepositDate AND t.FirstDepositDate = t.FirstPosOpenDate THEN t.FirstDepositDate   
--             WHEN t.VerificationLevel3Date < t.FirstPosOpenDate AND t.FirstPosOpenDate < t.FirstDepositDate THEN t.FirstDepositDate --ask how could be???  
--             WHEN t.VerificationLevel3Date < t.FirstPosOpenDate AND t.FirstPosOpenDate = t.FirstDepositDate THEN t.FirstDepositDate   
--             WHEN t.VerificationLevel3Date = t.FirstPosOpenDate AND t.FirstPosOpenDate < t.FirstDepositDate THEN t.FirstDepositDate   --ask how could be???  
--             WHEN t.FirstDepositDate < t.VerificationLevel3Date AND t.VerificationLevel3Date < t.FirstPosOpenDate THEN t.FirstPosOpenDate   
--             WHEN t.FirstDepositDate < t.VerificationLevel3Date AND t.VerificationLevel3Date = t.FirstPosOpenDate THEN t.FirstPosOpenDate   
--             WHEN t.FirstDepositDate = t.VerificationLevel3Date AND t.VerificationLevel3Date < t.FirstPosOpenDate THEN t.FirstPosOpenDate   
--             WHEN t.FirstDepositDate < t.FirstPosOpenDate AND t.FirstPosOpenDate < t.VerificationLevel3Date THEN t.VerificationLevel3Date   
--             WHEN t.FirstDepositDate < t.FirstPosOpenDate AND t.FirstPosOpenDate = t.VerificationLevel3Date THEN t.FirstPosOpenDate   
--             WHEN t.FirstDepositDate = t.FirstPosOpenDate AND t.FirstPosOpenDate < t.VerificationLevel3Date THEN t.VerificationLevel3Date   
--             ELSE FirstPosOpenDate END AS NewFunded_Date     
--FROM #FTFprep t  
 
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #FTF'  
  
 -------------------First Time Funded - Adi 21.10.25----------- 
 IF OBJECT_ID('tempdb..#FTF') IS NOT NULL DROP TABLE #FTF
CREATE TABLE #FTF  
WITH (HEAP,DISTRIBUTION=HASH(RealCID))
AS  

SELECT RealCID,FirstFundedDate
FROM BI_DB_dbo.Function_Population_First_Time_Funded() fpftf


UPDATE a  
SET FirstNewFundedDate = f.FirstFundedDate  
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a WITH(NOLOCK)  
JOIN #FTF f ON a.CID = f.RealCID  
WHERE a.FirstNewFundedDate IS NULL   
/***********************************************************************************************************************************************************/  

 -------------------Last Time Funded - Adi 21.10.25----------- 

-- DECLARE @Date DATE='2025-10-20'
--DECLARE @DateID INT = CAST(FORMAT(CAST(@Date AS DATE),'yyyyMMdd') as INT)
--DECLARE @YesterdayDate DATE=DATEADD(dd,-1,@Date)
--DECLARE @YesterdayDateID INT= DWH_dbo.DateToDateID(@YesterdayDate)

IF OBJECT_ID('tempdb..#funded_ddr') IS NOT NULL DROP TABLE #funded_ddr
CREATE TABLE #funded_ddr
WITH (DISTRIBUTION = HASH(RealCID),HEAP) 
AS
SELECT bddcds.RealCID, max([Date]) AS LastFundedDate
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
WHERE bddcds.IsFunded = 1
GROUP BY bddcds.RealCID

IF OBJECT_ID('tempdb..#funded_yesterday') IS NOT NULL DROP TABLE #funded_yesterday
CREATE TABLE #funded_yesterday
WITH (DISTRIBUTION = HASH(RealCID),HEAP) 
AS
SELECT RealCID,DateID,CONVERT(DATE, CONVERT(CHAR(8), DateID))[Date]
FROM BI_DB_dbo.Function_Population_Funded(@dateINT) fpf

IF OBJECT_ID('tempdb..#LTF') IS NOT NULL DROP TABLE #LTF
CREATE TABLE #LTF
WITH (DISTRIBUTION = HASH(RealCID),HEAP) 
AS
SELECT 
      COALESCE(fd.RealCID,fy.RealCID) RealCID
    , COALESCE(fy.[Date], fd.LastFundedDate) AS LastFundedDate
FROM #funded_ddr fd
FULL OUTER JOIN  #funded_yesterday fy ON fd.RealCID=fy.RealCID



UPDATE a
SET a.LastNewFundedDate = b.LastFundedDate
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] a
JOIN #LTF b ON a.CID = b.RealCID  
--WHERE a.LastNewFundedDate<>b.LastFundedDate

/***********************************************************************************************************************************************************/  
  
----Received Airdrop before  
IF OBJECT_ID('tempdb..#Airdropbefore') IS NOT NULL DROP TABLE #Airdropbefore
CREATE TABLE #Airdropbefore  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS    
SELECT DISTINCT fca.RealCID AS CID 
FROM [DWH_dbo].[Fact_CustomerAction] fca  WITH (NOLOCK)  
JOIN [DWH_dbo].[Dim_Instrument] di  WITH (NOLOCK) ON fca.InstrumentID = di.InstrumentID  
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates]  dc  WITH (NOLOCK) ON fca.RealCID = dc.CID  
WHERE fca.IsAirDrop =1  
  AND fca.ActionTypeID=1  
  AND di.InstrumentTypeID=5  
  AND dc.FirstDepositDate IS NOT NULL  
  AND fca.DateID >= CAST(CONVERT(VARCHAR(8), DATEADD(DAY,-30,GETDATE()), 112) AS INT)  
  AND IsAirDropBefore = 0  
 
--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Airdropbefore'  
  
  
UPDATE fd  
SET IsAirDropBefore = CASE WHEN a.CID IS NOT NULL THEN 1 ELSE 0 END  
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates]  fd  
JOIN #Airdropbefore a ON a.CID = fd.CID  
WHERE fd.IsAirDropBefore = 0  


------LastPublishedPostDate & LastAtionDateForLifeStage 

IF OBJECT_ID('tempdb..#Events') IS NOT NULL DROP TABLE #Events
CREATE TABLE #Events  
WITH (HEAP,DISTRIBUTION=HASH(CID))
AS    
SELECT DISTINCT fca.CID  
               ,CASE WHEN fca.ActionTypeID = 21  THEN 'PublishPost'  ELSE  'LifeStageEvent'  END AS ActionType  
               ,CAST(MAX(fca.Occurred) AS DATE) AS LastDate    
FROM #fca fca  WITH (NOLOCK)  
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH (NOLOCK)  ON fca.CID = fd.CID  
WHERE fca.ActionTypeID IN (1,15,17,21)  
  AND fca.DateID =@dateINT
GROUP BY fca.CID  
        ,CASE WHEN fca.ActionTypeID = 21  THEN 'PublishPost'  ELSE  'LifeStageEvent'  END  


--insert into  ##CIDFixtimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #Events'  
  
UPDATE fd  
SET LastPublishedPostDate = a.LastDate 
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH (NOLOCK)  
JOIN #Events a ON a.CID = fd.CID
WHERE a.ActionType = 'PublishPost'

UPDATE fd  
SET LastActionDateForLifeStage = a.LastDate 
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd  WITH (NOLOCK)  
JOIN #Events a ON a.CID = fd.CID  
WHERE a.ActionType = 'LifeStageEvent'
  

END 

-----check---
--select distinct IsFundedNew
--from [BI_DB_dbo].[BI_DB_CIDFirstDates]
--where CID=16109718
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_CIDFirstDates` | synapse_sp | BI_DB_dbo | SP_CIDFirstDates | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CIDFirstDates.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_State_and_Province` | synapse | DWH_dbo | Dim_State_and_Province | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_State_and_Province.md` |
| `DWH_dbo.Dim_Funnel` | synapse | DWH_dbo | Dim_Funnel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Funnel.md` |
| `DWH_dbo.Dim_Label` | synapse | DWH_dbo | Dim_Label | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Label.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_Language` | synapse | DWH_dbo | Dim_Language | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `DWH_dbo.Dim_Affiliate` | synapse | DWH_dbo | Dim_Affiliate | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Affiliate.md` |
| `DWH_dbo.Dim_Channel` | synapse | DWH_dbo | Dim_Channel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md` |
| `DWH_dbo.Dim_PlayerLevel` | synapse | DWH_dbo | Dim_PlayerLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_VerificationLevel` | synapse | DWH_dbo | Dim_VerificationLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `DWH_dbo.Dim_Manager` | synapse | DWH_dbo | Dim_Manager | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `DWH_dbo.Fact_FirstCustomerAction` | synapse | DWH_dbo | Fact_FirstCustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_FirstCustomerAction.md` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `DWH_dbo.Dim_FundingType` | synapse | DWH_dbo | Dim_FundingType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `DWH_dbo.Dim_BillingDepot` | synapse | DWH_dbo | Dim_BillingDepot | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `DWH_dbo.Dim_Mirror` | synapse | DWH_dbo | Dim_Mirror | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `BI_DB_dbo.BI_DB_UsageTracking_SF` | synapse | BI_DB_dbo | BI_DB_UsageTracking_SF | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_UsageTracking_SF.md` |
| `BI_DB_dbo.External_etoro_History_Credit_coup` | unresolved | BI_DB_dbo | External_etoro_History_Credit_coup | `—` |
| `BI_DB_dbo.External_etoro_history_BackOfficeCustomer_BackOfficeCaustomerTable` | unresolved | BI_DB_dbo | External_etoro_history_BackOfficeCustomer_BackOfficeCaustomerTable | `—` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `BI_DB_dbo.External_MarketPerformance_Tracking_Customer` | unresolved | BI_DB_dbo | External_MarketPerformance_Tracking_Customer | `—` |
| `BI_DB_dbo.BI_DB_AppFlyer_Reports` | synapse | BI_DB_dbo | BI_DB_AppFlyer_Reports | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AppFlyer_Reports.md` |
| `BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerKycMode_CustomerKycMode` | unresolved | BI_DB_dbo | External_ComplianceStateDB_Compliance_CustomerKycMode_CustomerKycMode | `—` |
| `BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerProfessionalQuestionnaireResult` | unresolved | BI_DB_dbo | External_ComplianceStateDB_Compliance_CustomerProfessionalQuestionnaireResult | `—` |
| `BI_DB_dbo.Function_Population_Funded` | synapse | BI_DB_dbo | Function_Population_Funded | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Population_Funded.md` |
| `BI_DB_dbo.Function_Population_First_Time_Funded` | synapse | BI_DB_dbo | Function_Population_First_Time_Funded | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Functions\Function_Population_First_Time_Funded.md` |
| `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | synapse | BI_DB_dbo | BI_DB_DDR_Customer_Daily_Status | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

