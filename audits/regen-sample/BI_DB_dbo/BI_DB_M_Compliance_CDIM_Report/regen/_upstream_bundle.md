# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report]
(
	[CID] [int] NULL,
	[Regulation] [varchar](250) NULL,
	[PlayerStatus] [varchar](250) NULL,
	[Club] [varchar](250) NULL,
	[Desk] [nvarchar](250) NULL,
	[Manager] [nvarchar](250) NULL,
	[MifidCategorisation] [nvarchar](250) NULL,
	[CountryOfResidence] [nvarchar](250) NULL,
	[BirthDate] [datetime] NULL,
	[CameFromAffiliate] [int] NULL,
	[VerificationLevel3Date] [date] NULL,
	[Occupation] [nvarchar](250) NULL,
	[RiskRewardSc] [nvarchar](250) NULL,
	[AnnualInc] [nvarchar](250) NULL,
	[CashLiquAst] [nvarchar](250) NULL,
	[PurposeTrad] [nvarchar](250) NULL,
	[PlanInvAmt] [nvarchar](250) NULL,
	[Appropriateness_Status] [nvarchar](250) NULL,
	[AVG_CFD_Leverage] [money] NULL,
	[IsTradedDemo] [int] NULL,
	[UsedDemoBeforeLivePlatform] [int] NULL,
	[KnowledgeAsst] [nvarchar](250) NULL,
	[RelevKnowl] [nvarchar](250) NULL,
	[Inv10Income] [nvarchar](250) NULL,
	[EduTools] [nvarchar](250) NULL,
	[NotCrimea] [nvarchar](250) NULL,
	[ReadRisks] [nvarchar](250) NULL,
	[InvAmtCFD] [nvarchar](250) NULL,
	[WhichInst] [nvarchar](250) NULL,
	[IsraeliQlf] [nvarchar](250) NULL,
	[RiskDiscl] [nvarchar](250) NULL,
	[RiskReview] [nvarchar](250) NULL,
	[SuitExpHigh] [nvarchar](250) NULL,
	[SuitExpLow] [nvarchar](250) NULL,
	[SuitObjHigh] [nvarchar](250) NULL,
	[SuitObjLow] [nvarchar](250) NULL,
	[ExpCrypto] [nvarchar](250) NULL,
	[ExpEquities] [nvarchar](250) NULL,
	[ExpCFD] [nvarchar](250) NULL,
	[TradingFreq] [nvarchar](250) NULL,
	[SourceIncome] [nvarchar](250) NULL,
	[TradExp] [nvarchar](250) NULL,
	[MktsTraded] [nvarchar](250) NULL,
	[SourceFunds] [nvarchar](250) NULL,
	[NegativeMarket] [nvarchar](250) NULL,
	[CFD_Copy_PnL] [money] NULL,
	[CFD_Manual_PnL] [money] NULL,
	[Stocks_Copy_PnL] [money] NULL,
	[Stocks_Manual_PnL] [money] NULL,
	[Crypto_Copy_PnL] [money] NULL,
	[Crypto_Manual_PnL] [money] NULL,
	[UpdateDate] [datetime] NOT NULL
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

Found 15 upstream wiki(s). Read EACH one in full.


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

### Upstream `DWH_dbo.Dim_Channel` — synapse
- **Resolved as**: `DWH_dbo.Dim_Channel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md`

# DWH_dbo.Dim_Channel

> 36-row marketing channel dimension table mapping every sub-channel to its parent channel and organic/paid classification. Sourced from the affiliate system's sub-channel unify-code reference table (`Ext_Dim_SubChannel_UnifyCode`) via `SP_Dim_Channel`. Truncated and reloaded daily by `SP_Dictionaries_DL_To_Synapse`. 20 distinct channels, 36 sub-channels.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel (truncate-and-reload) |
| **Refresh** | Daily (1440 min) — full truncate-and-reload via SP_Dictionaries_DL_To_Synapse |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (SubChannelID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, parquet → delta) |

---

## 1. Business Meaning

Dim_Channel is a small reference/dimension table (36 rows) that defines the marketing channel hierarchy used across eToro's acquisition and attribution reporting. Each row represents a unique sub-channel (e.g., "Google Search", "Taboola", "Direct Mobile") identified by `SubChannelID`, grouped under a parent `Channel` (e.g., "SEM", "Direct", "Affiliate"), and classified as either "Organic" or "Paid".

The table is sourced from `Ext_Dim_SubChannel_UnifyCode`, which is an external table loaded from the affiliate system (fiktivo `tblaff_Affiliates`). The writer SP (`SP_Dim_Channel`) performs a `SELECT DISTINCT` to deduplicate, then applies a CASE-based organic/paid classification before truncating and reloading the target.

SP_Dim_Channel also contains an alerting mechanism: when new sub-channels appear in the source that are not yet in `Dim_Channel`, an HTML email is sent to BI Data Solutions and the BI Analysis Team requesting immediate mapping.

The table is heavily referenced by downstream BI_DB reporting procedures (15+ SPs) for marketing attribution, acquisition funnels, and affiliate analytics.

---

## 2. Business Logic

### 2.1 Organic/Paid Classification

**What**: Each sub-channel is classified as "Organic" or "Paid" based on channel name and sub-channel name rules.
**Columns Involved**: Channel, SubChannel, Organic/Paid
**Rules**:
- Channel IN ('Friend Referral', 'Direct', 'SEO') → 'Organic'
- SubChannel = 'Google Brand' → 'Organic' (even though Channel = 'SEM')
- All other combinations → 'Paid'
- Current distribution: 30 Paid, 6 Organic

### 2.2 Channel Hierarchy

**What**: Two-level marketing hierarchy — Channel (parent) → SubChannel (child).
**Columns Involved**: Channel, SubChannel, SubChannelID
**Rules**:
- SubChannelID is the grain — one row per sub-channel
- A Channel can have 1–13 sub-channels (SEM has 13, most channels have 1)
- SubChannelID values are non-sequential (range 1–52, 36 active)
- Some sub-channels share the same name as their parent channel (e.g., Channel="Events", SubChannel="Events")

### 2.3 Unmapped Channel Alert

**What**: SP_Dim_Channel sends an email alert when new sub-channels appear in the source but are missing from Dim_Channel after load.
**Columns Involved**: SubChannelID, Channel, SubChannel
**Rules**:
- After INSERT, a LEFT JOIN check identifies rows in the source that have no matching SubChannelID in Dim_Channel
- If count > 0, an HTML email is generated listing the unmapped channels
- Recipients: bi-datasolutions@etoro.com, BIAnalysisTeam@etoro.com
- Subject: "New Channels in Affwizz - Need mapping ASAP"

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — appropriate for a 36-row dimension table. No skew concerns.
- **Index**: CLUSTERED INDEX on SubChannelID — supports point lookups when joining from fact tables on SubChannelID.
- At 36 rows, full table scans are negligible. No query optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What channel does SubChannelID X belong to? | `SELECT * FROM DWH_dbo.Dim_Channel WHERE SubChannelID = @id` |
| List all organic channels | `SELECT * FROM DWH_dbo.Dim_Channel WHERE [Organic/Paid] = 'Organic'` |
| How many sub-channels per channel? | `SELECT Channel, COUNT(*) AS SubChannels FROM DWH_dbo.Dim_Channel GROUP BY Channel ORDER BY SubChannels DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with SubChannelID | `ON fact.SubChannelID = dc.SubChannelID` | Resolve marketing channel for customer acquisition |
| Dim_Customer (via SubChannelID) | `ON cust.SubChannelID = dc.SubChannelID` | Attribute customer to acquisition channel |
| BI_DB reporting tables | Various | Marketing cube, acquisition funnel, affiliate reporting |

### 3.4 Gotchas

- **Column name with special character**: `[Organic/Paid]` contains a forward slash — always wrap in square brackets in SQL queries.
- **Google Brand exception**: SubChannelID=4 ("Google Brand") is under Channel="SEM" but classified as "Organic" — the only SEM sub-channel that is organic.
- **Social Organic is Paid**: Despite the name "Social Organic" (SubChannelID=49), it is classified as "Paid" because the CASE logic only checks Channel-level names, not SubChannel names.
- **Non-sequential IDs**: SubChannelID values range from 1 to 52 with gaps — do not assume contiguity.
- **Truncate-and-reload**: All InsertDate/UpdateDate values are identical (the last load timestamp). These columns do NOT track when a channel was first created or last modified historically.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code or DDL with evidence |
| Tier 3 | No upstream traceable; grounded in DDL + naming |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SubChannelID | int | NO | Primary key identifying a unique marketing sub-channel. Non-sequential integer (range 1–52, 36 active). Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannelID via SELECT DISTINCT. Clustered index key. Used as FK join key by downstream fact and BI_DB tables. (Tier 2 — SP_Dim_Channel) |
| 2 | Channel | nvarchar(50) | NO | Top-level marketing channel grouping (e.g., 'SEM', 'Direct', 'Affiliate', 'SEO', 'Friend Referral'). 20 distinct values. Passthrough from Ext_Dim_SubChannel_UnifyCode.Channel via SELECT DISTINCT. Also used as input to the Organic/Paid classification CASE logic. (Tier 2 — SP_Dim_Channel) |
| 3 | SubChannel | varchar(100) | NO | Granular marketing sub-channel name within a Channel (e.g., 'Google Search', 'Taboola', 'Direct Mobile', 'IBs'). 36 distinct values — one per row. Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannel via SELECT DISTINCT. Some sub-channels share their parent Channel name (e.g., Channel='Events', SubChannel='Events'). (Tier 2 — SP_Dim_Channel) |
| 4 | Organic/Paid | varchar(7) | YES | ETL-computed classification: 'Organic' when Channel IN ('Friend Referral', 'Direct', 'SEO') or SubChannel = 'Google Brand'; 'Paid' otherwise. 2 distinct values: Paid (30 rows), Organic (6 rows). NULL is allowed by DDL but not produced by current SP logic. (Tier 2 — SP_Dim_Channel) |
| 5 | InsertDate | datetime | YES | Row insert timestamp set to GETDATE() at SP execution time. Because the table uses truncate-and-reload, all rows share the same InsertDate equal to the last load run. Does not represent the original creation date of the channel. (Tier 2 — SP_Dim_Channel) |
| 6 | UpdateDate | datetime | YES | Row update timestamp set to GETDATE() at SP execution time. Identical to InsertDate on every load due to the truncate-and-reload pattern. Does not track incremental changes. (Tier 2 — SP_Dim_Channel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| SubChannelID | Ext_Dim_SubChannel_UnifyCode | SubChannelID | Passthrough (SELECT DISTINCT) |
| Channel | Ext_Dim_SubChannel_UnifyCode | Channel | Passthrough (SELECT DISTINCT) |
| SubChannel | Ext_Dim_SubChannel_UnifyCode | SubChannel | Passthrough (SELECT DISTINCT) |
| Organic/Paid | — (computed) | — | CASE on Channel + SubChannel values |
| InsertDate | — (computed) | — | GETDATE() |
| UpdateDate | — (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
fiktivo.dbo.tblaff_Affiliates (affiliate system, production)
  |-- External table load (SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) ---|
  v
DWH_dbo.Ext_Dim_SubChannel_UnifyCode (external/staging table)
  |-- SP_Dim_Channel (SELECT DISTINCT + CASE Organic/Paid) ---|
  v
DWH_dbo.Dim_Channel (36 rows, truncate-and-reload daily)
  |-- Generic Pipeline (Override, parquet → delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel (Unity Catalog Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Ext_Dim_SubChannel_UnifyCode | Source external table providing channel/sub-channel reference data |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Key | Purpose |
|-------------------|----------|---------|
| BI_DB_dbo.SP_CIDFirstDates | SubChannelID | Customer first-date acquisition channel attribution |
| BI_DB_dbo.SP_Marketing_Cube | SubChannelID | Marketing analytics cube |
| BI_DB_dbo.SP_H_LiveAcquisitionDashboard | SubChannelID | Live acquisition dashboard |
| BI_DB_dbo.SP_LiveAcquisitionDashboard_Daily | SubChannelID | Daily acquisition dashboard |
| BI_DB_dbo.SP_CIDFunnelFlow | SubChannelID | Customer funnel flow analysis |
| BI_DB_dbo.SP_H_Deposits | SubChannelID | Deposit reporting by channel |
| BI_DB_dbo.SP_PI_Affiliate | SubChannelID | Popular Investor affiliate reporting |
| BI_DB_dbo.SP_VerificationStatus | SubChannelID | Verification status by channel |
| BI_DB_dbo.SP_AffiliatePaymentsReport | SubChannelID | Affiliate payment reporting |
| BI_DB_dbo.SP_M_Active_Affiliate_Monthly | SubChannelID | Monthly active affiliate reporting |
| BI_DB_dbo.SP_M_Compliance_CDIM_Report | SubChannelID | Compliance CDIM reporting |
| BI_DB_dbo.SP_W_Mon_Compliance_CDIM_Report | SubChannelID | Weekly/monthly compliance reporting |
| BI_DB_dbo.QST | SubChannelID | QST reporting |
| BI_DB_dbo.SP_CIDFirstDates_HistoricalRun | SubChannelID | Historical first-dates backfill |
| BI_DB_dbo.SP_M_Active_Aff_Monthly_Region_GroupAff | SubChannelID | Regional affiliate monthly reporting |

---

## 7. Sample Queries

### 7.1 Channel Distribution Summary

```sql
SELECT
    Channel,
    [Organic/Paid],
    COUNT(*) AS SubChannelCount
FROM DWH_dbo.Dim_Channel
GROUP BY Channel, [Organic/Paid]
ORDER BY SubChannelCount DESC;
```

### 7.2 Find All Organic Sub-Channels

```sql
SELECT SubChannelID, Channel, SubChannel
FROM DWH_dbo.Dim_Channel
WHERE [Organic/Paid] = 'Organic'
ORDER BY Channel, SubChannel;
```

### 7.3 Join to Customer First-Dates for Acquisition Attribution

```sql
SELECT
    dc.Channel,
    dc.SubChannel,
    dc.[Organic/Paid],
    COUNT(DISTINCT cfd.CID) AS Customers
FROM BI_DB_dbo.BI_DB_CIDFirstDates cfd
JOIN DWH_dbo.Dim_Channel dc ON cfd.SubChannelID = dc.SubChannelID
GROUP BY dc.Channel, dc.SubChannel, dc.[Organic/Paid]
ORDER BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-28 | Quality: pending/10 | Phases: 12/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 3/10*
*Object: DWH_dbo.Dim_Channel | Type: Table | Production Source: Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel*


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


### Upstream `BI_DB_dbo.BI_DB_Demo_CID_Panel` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Demo_CID_Panel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Demo_CID_Panel.md`

# BI_DB_dbo.BI_DB_Demo_CID_Panel

> 4.55M-row per-CID demo account trading panel tracking each user's first demo trade date, first action product type, first instrument, and number of positions opened within 14 days of demo activation — spanning registrations from September 2007 to January 2025 (4.43M distinct CIDs), refreshed daily via SP_Demo_CID_Panel with incremental INSERT for new CIDs and UPDATE for changed position counts (author: Eti, 2025-01-27 rewrite).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.External_Marketing_Acquisition_Demo via SP_Demo_CID_Panel |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE recent 3 months + INSERT new CIDs (WHERE NOT EXISTS) + UPDATE position counts |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Reg_YearMonth] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Demo_CID_Panel is a marketing acquisition analytics table that tracks demo account usage per customer. Each row represents one CID with their demo account trading behavior: when they first registered, when (and if) they opened their first demo position, what product type that first position was, and how many demo positions they opened within the first 14 days of demo activity.

The table contains 4.55M rows with 4.43M distinct CIDs spanning registration months from September 2007 to January 2025. All current rows have IsTradedDemo = 1 (everyone who has a row has traded demo).

The ETL is incremental: new CIDs from External_Marketing_Acquisition_Demo are inserted (LEFT JOIN WHERE NULL), and existing CIDs get their OpenPositions14days updated if the count changed. The SP also deletes the most recent 3 months and re-inserts to capture late-arriving registration data.

The FirstAction classification uses InstrumentTypeID to categorize the first demo trade: Real Stocks/ETFs (InstrumentTypeID 5,6 + IsBuy=1 + Leverage=1), Fx/Comm/Ind (types 1,2,4), CFD Stocks/ETFs (types 5,6 with leverage or short), Crypto (type 10), Copy (type 0).

---

## 2. Business Logic

### 2.1 First Action Classification

**What**: Categorizes the user's first demo trade by product type using instrument and position characteristics.
**Columns Involved**: FirstAction, FirstInstrument
**Rules**:
- Real Stocks/ETFs: InstrumentID IN (5,6) AND IsBuy=1 AND Leverage=1 (non-leveraged buy)
- Fx/Comm/Ind: InstrumentTypeID IN (1,2,4) — forex, commodities, indices
- CFD Stocks/ETFs: InstrumentTypeID IN (5,6) — leveraged or short stock positions
- Crypto: InstrumentTypeID = 10
- Copy: InstrumentTypeID = 0 — copy trading
- Other: catch-all for unclassified

### 2.2 14-Day Engagement Window

**What**: Tracks early engagement by counting positions opened within 14 days of first demo trade.
**Columns Involved**: OpenPositions14days, FirstDemoTrade
**Rules**:
- Sourced from External_Marketing_Acquisition_Demo.Pos14Days
- Updated daily if the count changes (may increase as positions within the 14-day window are back-filled)
- Higher counts indicate more engaged demo users

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN
- **Clustered Index**: Reg_YearMonth ASC — filter by registration cohort

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Demo-to-real conversion funnel | JOIN BI_DB_CIDFirstDates ON CID to get real account FTD |
| First action distribution by cohort | `GROUP BY Reg_YearMonth, FirstAction` |
| 14-day engagement by product | `AVG(OpenPositions14days) GROUP BY FirstAction` |
| Demo users who never traded real | LEFT JOIN Dim_Customer WHERE IsDepositor=0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile, conversion status |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID | Real account dates for conversion analysis |
| DWH_dbo.Dim_Instrument | ON FirstInstrument = InstrumentID | First instrument details |

### 3.4 Gotchas

- **IsTradedDemo = 1 for ALL rows** — currently no rows with IsTradedDemo=0, so it has no filtering value
- **Reg_YearMonth can be NULL** — some CIDs have registration data missing from the source
- **Max Reg_YearMonth is 2025-01** — data stops at the rewrite date (Eti, 2025-01-27). Newer cohorts may not be populated if External_Marketing_Acquisition_Demo has a lag
- **FirstAction classification uses InstrumentID 5,6 for Real vs CFD** — InstrumentID, not InstrumentTypeID. This likely means specific instruments (BTC/ETH?), not types. The SP comment says InstrumentTypeID but the CASE uses InstrumentID IN (5,6)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code / ETL logic analysis | High |
| Tier 3 | Live data observation + schema inference | Medium |
| Tier 4 | Inferred from naming / context | Lower |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. One row per CID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Reg_YearMonth | char(7) | YES | Registration year-month in YYYY-MM format. CONVERT(VARCHAR(7), Registered, 126). Range: 2007-09 to 2025-01. NULL for some CIDs with missing registration data. Clustered index column. (Tier 2 — SP_Demo_CID_Panel) |
| 3 | FDT_YearMonth | char(7) | YES | First Demo Trade year-month in YYYY-MM format. CONVERT(VARCHAR(7), FirstDemoTrade, 126). NULL if the user never traded demo. (Tier 2 — SP_Demo_CID_Panel) |
| 4 | FirstDemoTrade | date | YES | Date of the user's first demo account trade. From External_Marketing_Acquisition_Demo.FirstDemoTrade. NULL if the user registered but never opened a demo position. (Tier 2 — SP_Demo_CID_Panel) |
| 5 | FirstAction | varchar(50) | YES | Product type of the user's first demo trade. Classified from InstrumentID/InstrumentTypeID/IsBuy/Leverage: 'Real Stocks/ETFs', 'Fx/Comm/Ind', 'CFD Stocks/ETFs', 'Crypto', 'Copy', 'Other'. (Tier 2 — SP_Demo_CID_Panel) |
| 6 | FirstInstrument | bigint | YES | InstrumentID of the user's first demo trade. FK to DWH_dbo.Dim_Instrument.InstrumentID for instrument details. (Tier 2 — SP_Demo_CID_Panel) |
| 7 | IsTradedDemo | tinyint | YES | Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Currently all rows are 1 (only traded users are present). (Tier 2 — SP_Demo_CID_Panel) |
| 8 | OpenPositions14days | int | YES | Number of demo positions opened within 14 days of the first demo trade. From External_Marketing_Acquisition_Demo.Pos14Days. Updated daily if count changes. Higher = more engaged. (Tier 2 — SP_Demo_CID_Panel) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT or UPDATE time. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | External_Marketing_Acquisition_Demo | CID | Passthrough |
| Reg_YearMonth | External_Marketing_Acquisition_Demo | Registered | CONVERT to YYYY-MM |
| FirstDemoTrade | External_Marketing_Acquisition_Demo | FirstDemoTrade | Passthrough |
| FirstAction | External_Marketing_Acquisition_Demo | InstrumentID + IsBuy + Leverage + InstrumentTypeID | CASE classification |
| OpenPositions14days | External_Marketing_Acquisition_Demo | Pos14Days | Passthrough (updated) |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_Marketing_Acquisition_Demo (external table — marketing demo data)
  |-- DELETE recent 3 months + INSERT new CIDs (LEFT JOIN WHERE NULL) ---|
  |-- UPDATE OpenPositions14days WHERE changed ---|
  v
BI_DB_dbo.BI_DB_Demo_CID_Panel (4.55M rows, ROUND_ROBIN, CI(Reg_YearMonth))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| FirstInstrument | DWH_dbo.Dim_Instrument.InstrumentID | First demo instrument |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Marketing acquisition analytics dashboards |

---

## 7. Sample Queries

### 7.1 Demo-to-Real Conversion by First Action

```sql
SELECT dp.FirstAction,
       COUNT(*) AS demo_users,
       SUM(CASE WHEN dc.IsDepositor = 1 THEN 1 ELSE 0 END) AS converted,
       CAST(SUM(CASE WHEN dc.IsDepositor = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS conversion_rate
FROM [BI_DB_dbo].[BI_DB_Demo_CID_Panel] dp
JOIN [DWH_dbo].[Dim_Customer] dc ON dp.CID = dc.RealCID
WHERE dp.Reg_YearMonth >= '2024-01'
GROUP BY dp.FirstAction
ORDER BY conversion_rate DESC;
```

### 7.2 14-Day Engagement Distribution

```sql
SELECT CASE WHEN OpenPositions14days = 0 THEN '0'
            WHEN OpenPositions14days BETWEEN 1 AND 5 THEN '1-5'
            WHEN OpenPositions14days BETWEEN 6 AND 20 THEN '6-20'
            ELSE '20+' END AS engagement_bucket,
       COUNT(*) AS users
FROM [BI_DB_dbo].[BI_DB_Demo_CID_Panel]
WHERE Reg_YearMonth >= '2024-01'
GROUP BY CASE WHEN OpenPositions14days = 0 THEN '0'
              WHEN OpenPositions14days BETWEEN 1 AND 5 THEN '1-5'
              WHEN OpenPositions14days BETWEEN 6 AND 20 THEN '6-20'
              ELSE '20+' END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Demo_CID_Panel | Type: Table | Production Source: External_Marketing_Acquisition_Demo via SP_Demo_CID_Panel*


### Upstream `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md`

# BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market

| Property | Value |
|----------|-------|
| **Object Type** | TABLE |
| **Schema** | BI_DB_dbo |
| **Row Count** | ~17,860,000 |
| **Synapse Distribution** | HASH ( [GCID] ) |
| **Synapse Index** | CLUSTERED INDEX ( [GCID] ASC ) |
| **Source System** | ComplianceStateDB (production) via external tables |
| **Writer SP** | `SP_BI_DB_Scored_Appropriateness_Negative_Market` |
| **ETL Pattern** | TRUNCATE-INSERT (daily full reload) |
| **Refresh** | Daily (SB_Daily, Priority 20) |

## 1. Business Meaning

`BI_DB_Scored_Appropriateness_Negative_Market` is a compliance analytics table that tracks whether eToro customers have passed or failed the **Appropriateness Test** for leveraged trading products (CFDs), and whether their CFD trading has been blocked or allowed as a result. The term "Negative Market" refers to users who fail the appropriateness assessment — they are classified as negative-market participants and restricted from CFD leverage trading per regulatory requirements.

Under CySEC, FCA, and ASIC/GAML regulations, users who fail the appropriateness test are blocked from CFD trading. The table records the block and release lifecycle: when a customer was blocked, why, when they were released, and the duration of the restriction. It covers all customers who have undergone the appropriateness test since February 2020, currently ~17.86 million rows.

**Key business use cases:**
- Compliance reporting: population of blocked vs. allowed customers per regulation
- Operational monitoring: block/release event tracking with reason codes
- FTD (First Time Deposit) cohort analysis by week/month for negative-market populations
- Regional and regulatory segmentation of appropriateness outcomes

**Important caveat:** Six KYC scoring columns (`IsKYC_NM_Trading_Experience`, `IsKYC_NM_Risk_Factor`, `IsKYC_NM`, `AT_Total_Score_KYC`, `AT_Total_Max_Potential_Score`, `IsKYC_AT_Passed`) are **vestigial** — the scoring logic in the SP was commented out and all values are hardcoded to `-1`. Scoring is now handled by the Compliance service (KYC Analyzer) in production, not replicated into this DWH table.

## 2. Business Logic

### 2.1 Population

The table is populated by `SP_BI_DB_Scored_Appropriateness_Negative_Market` via a 5-step ETL:

1. **#pop_AT** — Builds the appropriateness-test population by unioning:
   - `ComplianceStateDB.Compliance.CustomerRestrictions` (filtered to `RestrictionStatusReasonID = 14` — the appropriateness test reason)
   - `ComplianceStateDB.Compliance.UserTradingData`
   Both are joined to `Dictionary.RestrictionStatus` and `Dictionary.RestrictionStatusReason` to decode status/reason names.

2. **#pop_NM_Current** — Extracts the current CFD restriction status from `UserTradingData`, joining back to `#pop_AT` to tie each customer's current block/allow state.

3. **#pop_NM_History + #blockingdata** — Pulls historical CFD restriction events from `ComplianceStateDB.History.UserTradingData`, selects the latest history record per GCID (via `ROW_NUMBER()`), and merges current + historical to determine:
   - **BlockDate / BlockReasonID / BlockReasonDesc**: When and why CFD was blocked
   - **ReleaseDate / ReleaseReasonID / ReleaseReasonDesc**: When and why the block was lifted
   - Logic: `CFDRestrictionStatusID = 1` → currently blocked (block info from current, release from history); `= 2` → currently allowed (block info from history, release from current)

4. **#finaltable** — Final assembly joins `#pop_AT` with `Dim_Customer`, `Dim_Regulation` (×2: current + designated), `Dim_Country`, and `#blockingdata`. Computes FTD time bucketing (EOW_FTD, EOM_FTD, FTDDateID). KYC scoring columns are all set to `-1`.

5. **TRUNCATE + INSERT** — Full daily reload into the target table.

### 2.2 Hardcoded Filter

- `BeginTime >= '2020-02-20'` — Only customers whose restriction event occurred on or after this date are included.

### 2.3 CFD Status Derivation

```sql
CASE WHEN bd.CFDRestrictionStatusID = 1 THEN 'CFD_Blocked'
     WHEN bd.CFDRestrictionStatusID = 2 THEN 'CFD_Allowed'
     ELSE 'CFD_Allowed' END
```

### 2.4 Downstream Consumer SPs

Referenced by at least 9 other SPs — used as a source for aggregated compliance dashboards and negative-market monthly rollups (including `BI_DB_Negative_Market_Monthly_Aggregated` which is populated from this table on end-of-month runs).

## 3. Query Advisory

### 3.1 Distribution & Index Strategy

- **HASH ( GCID )** — Good for customer-level queries; all rows for a given customer are on the same node.
- **CLUSTERED INDEX ( GCID ASC )** — Supports equality and range lookups on GCID.
- For aggregations by regulation, region, or CFD status, expect data movement (shuffle) since those columns are not the distribution key.

### 3.2 Recommended Patterns

| Use Case | Pattern |
|----------|---------|
| Customer lookup | `WHERE GCID = @gcid` — collocated, no shuffle |
| CFD-blocked population | `WHERE CFD_Status = 'CFD_Blocked'` — ~20% of rows (3.6M) |
| Appropriateness failures | `WHERE ApproprietnessScore_Status = 'Failed'` — ~75% of rows (13.4M) |
| Block duration analysis | `WHERE DateDiffBlockRelease IS NOT NULL` — only released customers |
| FTD cohort by month | `GROUP BY EOM_FTD` — pre-computed end-of-month bucket |

### 3.3 Performance Notes

- **17.86M rows** — large table. Pre-filter on regulation or CFD_Status before aggregating.
- **TRUNCATE-INSERT** — single `UpdateDate` per day; no incremental history. For change tracking, compare daily snapshots externally.
- All KYC scoring columns (`IsKYC_NM_*`, `AT_*`) are `-1`. Exclude from queries — they carry no information.

### 3.4 Data Freshness

| Metric | Value |
|--------|-------|
| Last loaded | 2026-03-11 04:54:07 |
| Refresh frequency | Daily |
| Latency | Data reflects ComplianceStateDB state at ETL run time |

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer Real account ID. Maps to Dim_Customer.RealCID. (Tier 1 — etoro.Account.Customer.RealCID) |
| 2 | GCID | int | NO | Global Customer ID. Distribution key and clustered index column. Maps to Dim_Customer.GCID. (Tier 1 — Account.Customer) |
| 3 | IsDepositor | bit | YES | Whether the customer has ever deposited (1=yes, 0=no). From Dim_Customer.IsDepositor. (Tier 1 — CustomerStatic.IsDepositor) |
| 4 | FTD_Date | datetime | YES | First Time Deposit date. Renamed from Dim_Customer.FirstDepositDate. (Tier 1 — Fact_BillingDeposit.MIN(DateTimeUTC)) |
| 5 | FTDDateID | int | YES | Integer date key for FTD_Date. `CAST(CONVERT(CHAR(8), FirstDepositDate, 112) AS INT)` → YYYYMMDD format. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 6 | EOW_FTD | datetime | YES | End-of-week date containing the FTD. `DATEADD(dd, -(DATEPART(dw, FirstDepositDate) - 7), FirstDepositDate)`. Used for weekly FTD cohort grouping. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 7 | EOM_FTD | datetime | YES | End-of-month date containing the FTD. `EOMONTH(FirstDepositDate)`. Used for monthly FTD cohort grouping. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 8 | FTD_Amount | money | YES | First deposit amount in USD. Renamed from Dim_Customer.FirstDepositAmount. (Tier 1 — Fact_BillingDeposit.Amount) |
| 9 | RegulationID | tinyint | YES | Current regulation ID. From Dim_Customer.RegulationID. JOINs to Dim_Regulation.DWHRegulationID. (Tier 1 — Dictionary.Regulation) |
| 10 | RegulationName | varchar(200) | YES | Current regulation name. Decoded from Dim_Regulation.Name via RegulationID. Example values: CySEC, FCA, ASIC, BVI. (Tier 1 — Dictionary.Regulation, join-enriched via Dim_Customer.RegulationID) |
| 11 | RegionID | int | YES | Marketing region ID. Renamed from Dim_Country.MarketingRegionID via Dim_Customer.CountryID. (Tier 1 — Dictionary.MarketingRegion, join-enriched) |
| 12 | RegionName | varchar(200) | YES | Marketing region name (manual override). Renamed from Dim_Country.MarketingRegionManualName. May differ from standard Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). (Tier 1 — Ext_Dim_Country manual override, join-enriched) |
| 13 | CountryID | int | YES | Country of residence ID. From Dim_Customer.CountryID. JOINs to Dim_Country.CountryID. (Tier 1 — Dictionary.Country) |
| 14 | CountryName | varchar(200) | YES | Country name. Decoded from Dim_Country.Name via CountryID. (Tier 1 — Dictionary.Country, join-enriched) |
| 15 | IsKYC_NM_Trading_Experience | int | YES | **VESTIGIAL** — always `-1`. Originally intended for KYC negative-market trading experience score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 16 | IsKYC_NM_Risk_Factor | int | YES | **VESTIGIAL** — always `-1`. Originally intended for KYC negative-market risk factor score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 17 | IsKYC_NM | int | YES | **VESTIGIAL** — always `-1`. Originally intended for combined KYC negative-market pass/fail flag. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 18 | AT_Total_Score_KYC | int | YES | **VESTIGIAL** — always `-1`. Originally intended for Appropriateness Test total KYC score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 19 | AT_Total_Max_Potential_Score | int | YES | **VESTIGIAL** — always `-1`. Originally intended for maximum possible AT score. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 20 | IsKYC_AT_Passed | int | YES | **VESTIGIAL** — always `-1`. Originally intended for whether customer passed KYC-based AT. Scoring logic in SP is commented out. (Tier 2 — SP hardcoded, VESTIGIAL) |
| 21 | RestrictionStatusDesc | varchar(200) | YES | Current CFD restriction status description. From ComplianceStateDB Dictionary.RestrictionStatus.Name. NULL defaults to "Passed" via `ISNULL`. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 22 | CFD_Status | varchar(20) | YES | Derived CFD trading status. `CASE WHEN CFDRestrictionStatusID=1 THEN 'CFD_Blocked' ELSE 'CFD_Allowed'`. 2-value enum: "CFD_Blocked" (20%, 3.6M), "CFD_Allowed" (80%, 14.3M). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 23 | BlockDate | datetime | YES | Date when CFD trading was blocked. From ComplianceStateDB UserTradingData. NULL if never blocked. Source depends on current status: if currently blocked → current.ReasonDate; if released → history.ReasonDate. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 24 | BlockReasonID | int | YES | Block reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 25 | BlockReasonDesc | varchar(500) | YES | Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 26 | ReleaseDate | datetime | YES | Date when CFD block was released. Only populated when `CFDRestrictionStatusID = 2` (currently allowed after prior block). NULL if still blocked or never blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 27 | ReleaseReasonID | int | YES | Release reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if not released. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 28 | ReleaseReasonDesc | varchar(500) | YES | Release reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not released. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 29 | DateDiffBlockRelease | int | YES | Days between block and release. `DATEDIFF(d, BlockDate, ReleaseDate)`. NULL if not yet released or never blocked. Useful for measuring restriction duration. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 30 | AT_Date | datetime | YES | Date the Appropriateness Test was taken. From ComplianceStateDB.Compliance.CustomerRestrictions.BeginTime. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 31 | ApproprietnessScore_Status | varchar(200) | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: "Failed" 75% (13.4M), "Passed" 24% (4.2M), blank 1%, "Borderline Pass" <0.1%. Note: column name contains typo ("Approprietness" vs "Appropriateness"). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 32 | UpdateDate | datetime | YES | ETL execution timestamp. `GETDATE()` — identical across all rows for a given daily load. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed) |
| 33 | DesignatedRegulationName | varchar(200) | YES | Designated (target) regulation name. Decoded from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. May differ from current RegulationName when a customer is being migrated between regulations. (Tier 1 — Dictionary.Regulation, join-enriched via Dim_Customer.DesignatedRegulationID) |
| 34 | BlockSubReasonID | int | YES | Block sub-reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusSubreason. Provides granular classification of why CFD was blocked. NULL if not blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 35 | BlockSubReasonDesc | varchar(500) | YES | Block sub-reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusSubreason.Name. NULL if not blocked. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |

## 5. Lineage

| Source | Relationship | Objects |
|--------|-------------|---------|
| **ComplianceStateDB** (production) | Primary — appropriateness test and CFD restriction data | `Compliance.CustomerRestrictions`, `Compliance.UserTradingData`, `History.UserTradingData`, `Dictionary.RestrictionStatus`, `Dictionary.RestrictionStatusReason`, `Dictionary.RestrictionStatusSubreason` |
| **DWH_dbo.Dim_Customer** | Customer demographics and FTD data | `RealCID`, `GCID`, `IsDepositor`, `FirstDepositDate`, `FirstDepositAmount`, `RegulationID`, `CountryID`, `DesignatedRegulationID` |
| **DWH_dbo.Dim_Regulation** (×2) | Current regulation + designated regulation decode | `Name` via `RegulationID` and `DesignatedRegulationID` |
| **DWH_dbo.Dim_Country** | Country and marketing region decode | `Name`, `MarketingRegionID`, `MarketingRegionManualName` via `CountryID` |

Full column-level lineage: [BI_DB_Scored_Appropriateness_Negative_Market.lineage.md](BI_DB_Scored_Appropriateness_Negative_Market.lineage.md)

## 6. Relationships

| Related Object | Join Condition | Purpose |
|---------------|----------------|---------|
| DWH_dbo.Dim_Customer | `ON GCID = dc.GCID` | Source: customer demographics |
| DWH_dbo.Dim_Regulation | `ON RegulationID = dr.DWHRegulationID` | Source: regulation name decode |
| DWH_dbo.Dim_Country | `ON CountryID = dc1.CountryID` | Source: country/region decode |
| BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated | _Downstream_ — populated from this table on EOM runs | Monthly rollup of negative-market populations |

## 7. Sample Queries

```sql
-- Count of CFD-blocked vs allowed by regulation
SELECT  RegulationName,
        CFD_Status,
        COUNT(*) AS CustomerCount
FROM    BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
WHERE   ApproprietnessScore_Status = 'Failed'
GROUP BY RegulationName, CFD_Status
ORDER BY RegulationName, CFD_Status;

-- Average block duration for released customers
SELECT  RegulationName,
        AVG(CAST(DateDiffBlockRelease AS FLOAT)) AS AvgDaysBlocked,
        COUNT(*) AS ReleasedCount
FROM    BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
WHERE   DateDiffBlockRelease IS NOT NULL
GROUP BY RegulationName
ORDER BY AvgDaysBlocked DESC;
```

## 8. Atlassian Knowledge Sources

| Source | Key Insight |
|--------|-------------|
| [Experience and Objectives questionnaire](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11543019541) | Negative Market applies to new users in all regulations; CySEC/FCA users who fail are blocked from CFD since July 2023 |
| [Block from CFD](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/12061770175) | CFD Block can result from Negative Market OR failing the Suitability Test; ASIC/GAML can also be blocked |
| [Trading Experience according to Regulation](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12236620146) | FCA clients who fail can't trade CFDs for 60 days and 20 trades (as of June 2024) |
| [Compliance Glossary](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/689799236) | CFD Block = block from leverage trading; Scored Appropriateness = calculated in KYC Analyzer; Negative Market = restricted users |
| [HLD: Appropriateness scoring mechanism](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/897777665) | Scoring mechanism for calculating AT status implemented in Compliance service |
| [HLD - ASIC Appropriateness](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2100199454) | ASIC uses the CySEC/FCA appropriateness test but WITHOUT negative market component |

---

| Metric | Value |
|--------|-------|
| **Quality Score** | 8.5 / 10 |
| **Tier 1 Elements** | 13 / 35 (37%) |
| **Tier 2 Elements** | 22 / 35 (63%) |
| **Tier 4 Elements** | 0 |
| **Confidence** | HIGH — SP code fully analyzed, 6 vestigial columns documented |


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

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_M_Compliance_CDIM_Report`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_M_Compliance_CDIM_Report.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_M_Compliance_CDIM_Report] AS
BEGIN
SET NOCOUNT ON;

/****************************************** Declare Dates ***************************************************/
DECLARE @PnLDate INT = CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
DECLARE @PnLDateid INT = CAST(CONVERT(VARCHAR(8), @PnLDate, 112) AS INT)
DECLARE @1yearago DATETIME = DATEADD(YEAR, -1, GETDATE())
DECLARE @1yearagoid INT = CAST(CONVERT(VARCHAR(8), @1yearago, 112) AS INT);

/****************************************** General Population ***************************************************/
-- General Population: FCA Clients who have opened or closed a position in the past year (L3 Verified)
IF OBJECT_ID('tempdb..#pop') IS NOT NULL 
DROP TABLE #pop CREATE TABLE #pop WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT DISTINCT	dc.RealCID AS CID
      ,dr.Name AS Regulation  
	  ,dps.Name AS PlayerStatus 
	  ,dpl.Name AS Club
      ,dc1.Desk
      ,fd.Manager
      ,mif.Name AS MifidCategorisation
      ,dc1.Name AS CountryOfResidence
      ,dc.BirthDate
      ,(CASE WHEN dc.SubChannelID IN (20,31) THEN 1 ELSE 0 END) AS CameFromAffiliate
      ,CONVERT(DATE, fd.VerificationLevel3Date) VerificationLevel3Date
FROM DWH_dbo.Dim_Customer dc 
JOIN DWH_dbo.[Dim_Country] dc1	ON dc1.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID AND dps.PlayerStatusID NOT IN (2,4) -- Blocked, Blocked Upon Request
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.[Dim_Regulation] dr ON dr.DWHRegulationID = dc.RegulationID AND dr.DWHRegulationID =2 -- FCA
LEFT JOIN DWH_dbo.Dim_MifidCategorization mif ON mif.MifidCategorizationID = dc.MifidCategorizationID
LEFT JOIN BI_DB_dbo.[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON dc.RealCID = fd.CID
LEFT JOIN DWH_dbo.Dim_Channel dch ON dch.SubChannelID = dc.SubChannelID
WHERE dc.IsValidCustomer = 1
AND dc.VerificationLevelID = 3
AND dc.IsDepositor= 1 --1,098,931

--SELECT * FROM DWH_dbo.Dim_Channel ORDER BY 2

CREATE CLUSTERED INDEX ci_#pop ON #pop(CID);

-- Opened or closed position in the past year
IF OBJECT_ID('tempdb..#pop2') IS NOT NULL DROP TABLE #pop2
CREATE TABLE #pop2 
	WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT pp.CID
FROM DWH_dbo.Dim_Position dp
JOIN #pop pp ON dp.CID = pp.CID
WHERE (dp.OpenDateID >= @1yearagoid
OR dp.CloseDateID >= @1yearagoid) -- Open or Close within a year -- 526,772

--The date on which the client made their First Action
IF OBJECT_ID('tempdb..#FA') IS NOT NULL
	DROP TABLE #FA CREATE TABLE #FA WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT pp.CID
   ,fa.FirstActionDate
FROM BI_DB_dbo.[BI_DB_First5Actions] fa
JOIN #pop pp ON fa.CID = pp.CID;

--The date on which the client first opened a position on the demo account
IF OBJECT_ID('tempdb..#Demo') IS NOT NULL
	DROP TABLE #Demo CREATE TABLE #Demo WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT demo.CID
   ,demo.IsTradedDemo
   ,demo.FirstDemoTrade
   ,(CASE
		WHEN demo.IsTradedDemo = 0 THEN NULL
		WHEN demo.FirstDemoTrade < fa.FirstActionDate THEN 1
		WHEN demo.FirstDemoTrade >= fa.FirstActionDate THEN 0
	END) AS UsedDemoBeforeLivePlatform
FROM BI_DB_dbo.BI_DB_Demo_CID_Panel demo
JOIN #pop pp ON demo.CID = pp.CID
LEFT JOIN #FA fa ON fa.CID = demo.CID;

--The Appropriateness Test result for each client
IF OBJECT_ID('tempdb..#Appropriateness') IS NOT NULL
	DROP TABLE #Appropriateness CREATE TABLE #Appropriateness WITH (HEAP,DISTRIBUTION=hash(RealCID)) AS
SELECT DISTINCT neg2.RealCID
   ,ApproprietnessScore_Status
FROM BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market neg2
JOIN #pop pp	ON pp.CID = neg2.RealCID;

--The Negative Market result for each client
IF OBJECT_ID('tempdb..#NegativeMarket') IS NOT NULL
	DROP TABLE #NegativeMarket CREATE TABLE #NegativeMarket WITH (HEAP,DISTRIBUTION=hash(RealCID)) AS
SELECT DISTINCT	neg1.RealCID
   ,BlockReasonDesc AS NegativeMarketBlockReasonDesc
FROM BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market neg1
JOIN #pop pp ON pp.CID = neg1.RealCID
WHERE BlockReasonID = 12
AND RestrictionStatusDesc = 'Failed';

--Realised PnL split by Asset Class for each client
IF OBJECT_ID('tempdb..#RealisedPnL') IS NOT NULL
	DROP TABLE #RealisedPnL CREATE TABLE #RealisedPnL WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT pp.CID
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID <> 0 AND
			dp.IsSettled = 0 THEN dp.NetProfit
	END), 0) AS CFD_Copy_RealisedPnL
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID = 0 AND
			dp.IsSettled = 0 THEN dp.NetProfit
	END), 0) AS CFD_Manual_RealisedPnL
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID <> 0 AND
			dp.IsSettled = 1 AND
			di.InstrumentType IN ('Stocks', 'ETF') THEN dp.NetProfit
	END), 0) AS Stocks_Copy_RealisedPnL
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID = 0 AND
			dp.IsSettled = 1 AND
			di.InstrumentType IN ('Stocks', 'ETF') THEN dp.NetProfit
	END), 0) AS Stocks_Manual_RealisedPnL
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID <> 0 AND
			dp.IsSettled = 1 AND
			di.InstrumentType = 'Crypto Currencies' THEN dp.NetProfit
	END), 0) AS Crypto_Copy_RealisedPnL
   ,ISNULL(SUM(CASE
		WHEN dp.MirrorID = 0 AND
			dp.IsSettled = 1 AND
			di.InstrumentType = 'Crypto Currencies' THEN dp.NetProfit
	END), 0) AS Crypto_Manual_RealisedPnL
FROM DWH_dbo.[Dim_Position] dp WITH (NOLOCK)
JOIN #pop pp ON pp.CID = dp.CID
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
GROUP BY pp.CID;

--Unrealised PnL split by Asset Class for each client 
IF OBJECT_ID('tempdb..#UnrealisedPnL') IS NOT NULL
	DROP TABLE #UnrealisedPnL CREATE TABLE #UnrealisedPnL WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT pp.CID
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID <> 0 AND
			ppl.IsSettled = 0 THEN ppl.PositionPnL
	END), 0) AS CFD_Copy_UnrealisedPnL
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID = 0 AND
			ppl.IsSettled = 0 THEN ppl.PositionPnL
	END), 0) AS CFD_Manual_UnrealisedPnL
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID <> 0 AND
			ppl.IsSettled = 1 AND
			di.InstrumentType IN ('Stocks', 'ETF') THEN ppl.PositionPnL
	END), 0) AS Stocks_Copy_UnrealisedPnL
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID = 0 AND
			ppl.IsSettled = 1 AND
			di.InstrumentType IN ('Stocks', 'ETF') THEN ppl.PositionPnL
	END), 0) AS Stocks_Manual_UnrealisedPnL
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID <> 0 AND
			ppl.IsSettled = 1 AND
			di.InstrumentType = 'Crypto Currencies' THEN ppl.PositionPnL
	END), 0) AS Crypto_Copy_UnrealisedPnL
   ,ISNULL(SUM(CASE
		WHEN ppl.MirrorID = 0 AND
			ppl.IsSettled = 1 AND
			di.InstrumentType = 'Crypto Currencies' THEN ppl.PositionPnL
	END), 0) AS Crypto_Manual_UnrealisedPnL
FROM BI_DB_dbo.[BI_DB_PositionPnL] ppl WITH (NOLOCK)
JOIN #pop pp ON pp.CID = ppl.CID
JOIN DWH_dbo.[Dim_Instrument] di ON ppl.InstrumentID = di.InstrumentID
WHERE ppl.DateID = @PnLDateid
GROUP BY pp.CID;

--Overnight Fees (Rollover Fees)
IF OBJECT_ID('tempdb..#Rollover') IS NOT NULL
	DROP TABLE #Rollover CREATE TABLE #Rollover WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT pp.CID
   ,(CASE WHEN [fca].[MirrorID] <> 0 THEN 1	ELSE 0 END) AS IsCopy
   ,-SUM([fca].[Amount]) AS Rollover
FROM DWH_dbo.[Fact_CustomerAction] fca WITH (NOLOCK)
JOIN #pop pp WITH (NOLOCK) 	ON fca.RealCID = pp.CID
WHERE ActionTypeID = 35
AND IsFeeDividend = 1
GROUP BY pp.CID
		,(CASE WHEN [fca].[MirrorID] <> 0 THEN 1 ELSE 0 END);

--SELECT * FROM #Rollover WHERE IsCopy IS NULL

-- Unrealised and Realised PnL Combined
IF OBJECT_ID('tempdb..#LifetimePnL') IS NOT NULL
	DROP TABLE #LifetimePnL CREATE TABLE #LifetimePnL WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	pnl.CID
   ,SUM(CFD_Copy_RealisedPnL) AS CFD_Copy_PnL
   ,SUM(CFD_Manual_RealisedPnL) AS CFD_Manual_PnL
   ,SUM(Stocks_Copy_RealisedPnL) AS Stocks_Copy_PnL
   ,SUM(Stocks_Manual_RealisedPnL) AS Stocks_Manual_PnL
   ,SUM(Crypto_Copy_RealisedPnL) AS Crypto_Copy_PnL
   ,SUM(Crypto_Manual_RealisedPnL) AS Crypto_Manual_PnL
FROM (SELECT
		r.*
	FROM #RealisedPnL r

	UNION ALL

	SELECT
		u.*
	FROM #UnrealisedPnL u) pnl
GROUP BY pnl.CID;


CREATE CLUSTERED INDEX ci_#LifetimePnL ON #LifetimePnL(CID);

--Mean AVG CFD Leverage used to date
IF OBJECT_ID('tempdb..#CFD_Leverage') IS NOT NULL
	DROP TABLE #CFD_Leverage CREATE TABLE #CFD_Leverage WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT DISTINCT pp.CID
      ,AVG(CASE WHEN IsSettled = 0 THEN dp.Leverage * 1.00 END) AS AVG_CFD_Leverage
FROM DWH_dbo.[Dim_Position] dp WITH (NOLOCK)
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
JOIN #pop pp ON pp.CID = dp.CID
GROUP BY pp.CID;

--KYC answers pivoted
IF OBJECT_ID('tempdb..#kyc') IS NOT NULL
	DROP TABLE #kyc CREATE TABLE #kyc WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT DISTINCT pp.CID
   ,QuestionText
   ,AnswerText
FROM BI_DB_dbo.[BI_DB_KYCUserRawDataLeveled] KYC WITH (NOLOCK)
JOIN #pop pp ON KYC.RealCID = pp.CID;

IF OBJECT_ID('tempdb..#KYC_Output') IS NOT NULL
	DROP TABLE #KYC_Output CREATE TABLE #KYC_Output WITH (HEAP,DISTRIBUTION=hash(CID)) AS
SELECT
	DISTINCT CID
   ,[Do you have relevant knowledge in trading?] AS RelevKnowl
   ,[Does the total amount invested by you represent 10% or more of your annual income?] AS Inv10Income
   ,[Educational tools reviewed] AS EduTools
   ,[How much money do you plan to invest in your eToro account in the next year ?] AS PlanInvAmt
   ,[I am Not From Crimea region.] AS NotCrimea
   ,[I have read and understood the Risks involved in CFD's products and I am Above 18.] AS ReadRisks
   ,[Invested amount-Leveraged CFDs] AS InvAmtCFD
   ,[In which instruments do you plan To trade?] AS WhichInst
   ,[Israeli Qualified and Classified statement] AS IsraeliQlf
   ,[Risk disclosure disclaimer] AS RiskDiscl
   ,[Risk disclosure reviewed] AS RiskReview
   ,[Suitability Assessment Experience High Tier disclaimer] AS SuitExpHigh
   ,[Suitability Assessment Experience Low Tier disclaimer] AS SuitExpLow
   ,[Suitability Assessment Objectives High Tier disclaimer] AS SuitObjHigh
   ,[Suitability Assessment Objectives Low Tier disclaimer] AS SuitObjLow
   ,[Trading Experience-Crypto Assets] AS ExpCrypto
   ,[Trading Experience-Equities] AS ExpEquities
   ,[Trading Experience-Leveraged CFDs] AS ExpCFD
   ,[Trading frequency] AS TradingFreq
   ,[Trading Knowledge Assessment] AS KnowledgeAsst
   ,[What are your main sources of income?] AS SourceIncome
   ,[What are your sources of funds] AS SourceFunds
   ,[What best describes your primary purpose of trading with us?] AS PurposeTrad
   ,[What is your level of trading experience?] AS TradExp
   ,[What is your net annual income?] AS AnnualInc
   ,[What Is your occupation?] AS Occupation
   ,[What is your total cash and liquid assets?] AS CashLiquAst
   ,[Which markets have you traded?] AS MktsTraded
   ,[Which risk/reward scenario best describes your expectations with respect to your annual investments with us?] AS RiskRewardSc

FROM (SELECT
		pp.CID
	   ,QuestionText
	   ,AnswerText

	FROM #pop pp
	LEFT JOIN #kyc k ON k.CID = pp.CID) a

PIVOT
(MAX([AnswerText]) FOR QuestionText IN (
[Do you have relevant knowledge in trading?],
[Does the total amount invested by you represent 10% or more of your annual income?],
[Educational tools reviewed],
[How much money do you plan to invest in your eToro account in the next year ?],
[I am Not From Crimea region.],
[I have read and understood the Risks involved in CFD's products and I am Above 18.],
[Invested amount-Leveraged CFDs],
[In which instruments do you plan To trade?],
[Israeli Qualified and Classified statement],
[Risk disclosure disclaimer],
[Risk disclosure reviewed],
[Suitability Assessment Experience High Tier disclaimer],
[Suitability Assessment Experience Low Tier disclaimer],
[Suitability Assessment Objectives High Tier disclaimer],
[Suitability Assessment Objectives Low Tier disclaimer],
[Trading Experience-Crypto Assets],
[Trading Experience-Equities],
[Trading Experience-Leveraged CFDs],
[Trading frequency],
[Trading Knowledge Assessment],
[What are your main sources of income?],
[What are your sources of funds],
[What best describes your primary purpose of trading with us?],
[What is your level of trading experience?],
[What is your net annual income?],
[What Is your occupation?],
[What is your total cash and liquid assets?],
[Which markets have you traded?],
[Which risk/reward scenario best describes your expectations with respect to your annual investments with us?]))
AS pt;

--Final table joining all the Subqueries
IF OBJECT_ID('tempdb..#CD_Final') IS NOT NULL DROP TABLE #CD_Final
CREATE TABLE #CD_Final 
	WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT pp1.CID
	  ,pp1.Regulation
	  ,pp1.PlayerStatus
	  ,pp1.Club
	  ,pp1.Desk
	  ,pp1.Manager
	  ,pp1.MifidCategorisation
	  ,pp1.CountryOfResidence
	  ,pp1.BirthDate
	  ,pp1.CameFromAffiliate
	  ,pp1.VerificationLevel3Date	
   ,[KYC].[Occupation]
   ,[KYC].[RiskRewardSc]
   ,[KYC].[AnnualInc]
   ,[KYC].[CashLiquAst]
   ,[KYC].[PurposeTrad]
   ,[KYC].[PlanInvAmt]
   ,app.ApproprietnessScore_Status AS Appropriateness_Status
   ,cfdl.AVG_CFD_Leverage
   ,demo.IsTradedDemo
   ,demo.UsedDemoBeforeLivePlatform
   ,[KYC].[KnowledgeAsst]
   ,[KYC].[RelevKnowl]
   ,[KYC].[Inv10Income]
   ,[KYC].[EduTools]
   ,[KYC].[NotCrimea]
   ,[KYC].[ReadRisks]
   ,[KYC].[InvAmtCFD]
   ,[KYC].[WhichInst]
   ,[KYC].[IsraeliQlf]
   ,[KYC].[RiskDiscl]
   ,[KYC].[RiskReview]
   ,[KYC].[SuitExpHigh]
   ,[KYC].[SuitExpLow]
   ,[KYC].[SuitObjHigh]
   ,[KYC].[SuitObjLow]
   ,[KYC].[ExpCrypto]
   ,[KYC].[ExpEquities]
   ,[KYC].[ExpCFD]
   ,[KYC].[TradingFreq]
   ,[KYC].[SourceIncome]
   ,[KYC].[TradExp]
   ,[KYC].[MktsTraded]
   ,[KYC].[SourceFunds]
   ,nm.NegativeMarketBlockReasonDesc AS NegativeMarket
   ,pnl.CFD_Copy_PnL - ISNULL(rol1.[Rollover], 0) AS CFD_Copy_PnL
   ,pnl.CFD_Manual_PnL - ISNULL(rol0.[Rollover], 0) AS CFD_Manual_PnL
   ,pnl.Stocks_Copy_PnL
   ,pnl.Stocks_Manual_PnL
   ,pnl.Crypto_Copy_PnL
   ,pnl.Crypto_Manual_PnL 
FROM #pop pp1
JOIN #pop2 pp ON pp1.CID = pp.CID
LEFT JOIN #CFD_Leverage cfdl ON pp1.CID = cfdl.CID
LEFT JOIN #Demo demo ON pp1.CID = demo.CID
LEFT JOIN #NegativeMarket nm ON nm.RealCID = pp1.CID
LEFT JOIN #LifetimePnL pnl ON pp1.CID = pnl.CID
LEFT JOIN #KYC_Output KYC ON pp1.CID = KYC.CID
LEFT JOIN #Appropriateness app ON pp1.CID= app.RealCID
LEFT JOIN #Rollover rol1 ON pp1.CID = rol1.CID AND rol1.IsCopy = 1
LEFT JOIN #Rollover rol0 ON pp1.CID = rol0.CID AND rol0.IsCopy = 0;

-- SELECT * FROM #CD_Final ORDER BY 1

/********** Truncate and Insert **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report 

INSERT INTO BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report
	  (CID
	  ,Regulation
	  ,PlayerStatus
	  ,Club
	  ,Desk
	  ,Manager
	  ,MifidCategorisation
	  ,CountryOfResidence
	  ,BirthDate
	  ,CameFromAffiliate
	  ,VerificationLevel3Date
	  ,Occupation
	  ,RiskRewardSc
	  ,AnnualInc
	  ,CashLiquAst
	  ,PurposeTrad
	  ,PlanInvAmt
	  ,Appropriateness_Status
	  ,AVG_CFD_Leverage
	  ,IsTradedDemo
	  ,UsedDemoBeforeLivePlatform
	  ,KnowledgeAsst
	  ,RelevKnowl
	  ,Inv10Income
	  ,EduTools
	  ,NotCrimea
	  ,ReadRisks
	  ,InvAmtCFD
	  ,WhichInst
	  ,IsraeliQlf
	  ,RiskDiscl
	  ,RiskReview
	  ,SuitExpHigh
	  ,SuitExpLow
	  ,SuitObjHigh
	  ,SuitObjLow
	  ,ExpCrypto
	  ,ExpEquities
	  ,ExpCFD
	  ,TradingFreq
	  ,SourceIncome
	  ,TradExp
	  ,MktsTraded
	  ,SourceFunds
	  ,NegativeMarket
	  ,CFD_Copy_PnL
	  ,CFD_Manual_PnL
	  ,Stocks_Copy_PnL
	  ,Stocks_Manual_PnL
	  ,Crypto_Copy_PnL
	  ,Crypto_Manual_PnL
	  ,UpdateDate)  
SELECT CID
	  ,Regulation
	  ,PlayerStatus
	  ,Club
	  ,Desk
	  ,Manager
	  ,MifidCategorisation
	  ,CountryOfResidence
	  ,BirthDate
	  ,CameFromAffiliate
	  ,VerificationLevel3Date
	  ,Occupation
	  ,RiskRewardSc
	  ,AnnualInc
	  ,CashLiquAst
	  ,PurposeTrad
	  ,PlanInvAmt
	  ,Appropriateness_Status
	  ,AVG_CFD_Leverage
	  ,IsTradedDemo
	  ,UsedDemoBeforeLivePlatform
	  ,KnowledgeAsst
	  ,RelevKnowl
	  ,Inv10Income
	  ,EduTools
	  ,NotCrimea
	  ,ReadRisks
	  ,InvAmtCFD
	  ,WhichInst
	  ,IsraeliQlf
	  ,RiskDiscl
	  ,RiskReview
	  ,SuitExpHigh
	  ,SuitExpLow
	  ,SuitObjHigh
	  ,SuitObjLow
	  ,ExpCrypto
	  ,ExpEquities
	  ,ExpCFD
	  ,TradingFreq
	  ,SourceIncome
	  ,TradExp
	  ,MktsTraded
	  ,SourceFunds
	  ,NegativeMarket
	  ,CFD_Copy_PnL
	  ,CFD_Manual_PnL
	  ,Stocks_Copy_PnL
	  ,Stocks_Manual_PnL
	  ,Crypto_Copy_PnL
	  ,Crypto_Manual_PnL
	  ,GETDATE() AS UpdateDate
FROM #CD_Final 

		
/********** END **********/
END


--complianceuk@etoro.com




GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_M_Compliance_CDIM_Report` | synapse_sp | BI_DB_dbo | SP_M_Compliance_CDIM_Report | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_M_Compliance_CDIM_Report.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_PlayerLevel` | synapse | DWH_dbo | Dim_PlayerLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_MifidCategorization` | synapse | DWH_dbo | Dim_MifidCategorization | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md` |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | synapse | BI_DB_dbo | BI_DB_CIDFirstDates | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `DWH_dbo.Dim_Channel` | synapse | DWH_dbo | Dim_Channel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Channel.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `BI_DB_dbo.BI_DB_First5Actions` | synapse | BI_DB_dbo | BI_DB_First5Actions | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md` |
| `BI_DB_dbo.BI_DB_Demo_CID_Panel` | synapse | BI_DB_dbo | BI_DB_Demo_CID_Panel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Demo_CID_Panel.md` |
| `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market` | synapse | BI_DB_dbo | BI_DB_Scored_Appropriateness_Negative_Market | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Scored_Appropriateness_Negative_Market.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_PositionPnL` | synapse | BI_DB_dbo | BI_DB_PositionPnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `BI_DB_dbo.BI_DB_KYCUserRawDataLeveled` | unresolved | BI_DB_dbo | BI_DB_KYCUserRawDataLeveled | `—` |
