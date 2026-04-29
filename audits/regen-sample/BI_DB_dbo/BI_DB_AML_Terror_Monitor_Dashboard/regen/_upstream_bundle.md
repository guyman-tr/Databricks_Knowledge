# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AML_Terror_Monitor_Dashboard]
(
	[CID] [int] NULL,
	[Regulation] [varchar](250) NULL,
	[KYC_Country] [varchar](250) NULL,
	[CitizenshipCountry] [varchar](250) NULL,
	[POBCountry] [varchar](250) NULL,
	[CountryByIP_Residency] [varchar](250) NULL,
	[PlayerStatus] [varchar](250) NULL,
	[Club] [varchar](250) NULL,
	[HasWallet] [int] NULL,
	[RegisteredReal] [datetime] NULL,
	[FirstDepositDate] [datetime] NULL,
	[FirstDepositAmount] [money] NULL,
	[ScreeningStatus] [varchar](250) NULL,
	[RiskScoreName] [varchar](250) NULL,
	[Equity] [money] NULL,
	[Total_Deposits] [money] NULL,
	[Total_CO] [money] NULL,
	[Has_eMoney_Account] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[AMLEntity] [varchar](250) NULL,
	[AMLSubEntity] [varchar](250) NULL,
	[AMLSubEntity_2] [varchar](250) NULL
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

Found 10 upstream wiki(s). Read EACH one in full.


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


### Upstream `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AML_SubEntity_Categorization.md`

# BI_DB_dbo.BI_DB_AML_SubEntity_Categorization

> 2.11M-row daily snapshot table classifying every verified depositor customer into one or more AML sub-entities (eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta) based on their KYC country, regulation, and eToro Money account type. Rebuilt daily via TRUNCATE+INSERT from DWH_dbo dimensions and eMoney account data. Last updated 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation + eMoney_dbo.eMoney_Dim_Account via SP_AML_SubEntity_Categorization |
| **Refresh** | Daily (SB_Daily, Priority 20). TRUNCATE + INSERT — full rebuild every run. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Copy Strategy** | Override (full daily replace) |
| **Business Group** | compliance |

---

## 1. Business Meaning

`BI_DB_AML_SubEntity_Categorization` is the canonical AML sub-entity classification table for eToro's regulated entity structure. Each row represents one verified depositor customer (VerificationLevelID ≥ 2, IsDepositor = 1, IsValidCustomer = 1) and records which eToro legal sub-entities are responsible for their AML oversight.

The `AML_Sub_Entity` column contains a comma-separated string of applicable labels:
- **eToro_Germany** — CySEC-regulated customer in Germany with a crypto wallet or real crypto positions
- **eToro_Gibraltar** — Customer in any non-Germany country under CySEC/FCA/ASIC/ASIC&GAML/FSA Seychelles with a crypto wallet
- **eToro_Money_UK** — CySEC/FCA customer with a UK Card or IBAN eToro Money account
- **eToro_Money_Malta** — CySEC customer with an EU IBAN eToro Money account in an EU/EEA country, fully KYC-verified (VerLevel=3)

A single customer can qualify for multiple sub-entities (2.11M rows total; 334,000+ rows have multi-entity assignments). The table is fully rebuilt daily — no incremental updates.

As of 2026-04-13: 966K customers assigned to eToro_Money_Malta alone, 460K to eToro_Money_UK, 234K to eToro_Gibraltar, 109K to eToro_Germany. Regulation split: CySEC (66%), FCA (31%), FSA Seychelles (1.5%), ASIC&GAML (1.3%), ASIC (0.2%). Nearly all rows (99.999%) have VerificationLevelID=3 (fully verified); 17 rows at level 2.

The table is consumed by `SP_AML_Terror_Monitor_Dashboard` and `SP_M_AML_Report` for compliance monitoring and AML reporting workflows.

---

## 2. Business Logic

### 2.1 eToro Germany Population

**What**: Identifies CySEC-regulated customers resident in Germany who hold crypto assets.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- KYC country = Germany (Dim_Country.CountryID = 79)
- RegulationID = 1 (CySEC)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1
- PLUS: HasWallet = 1 OR had real crypto positions (InstrumentTypeID=10, IsSettled=1) as of yesterday

### 2.2 eToro Gibraltar Population

**What**: Customers with crypto wallets outside Germany, under major regulations.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- KYC country ≠ Germany (CountryID ≠ 79)
- RegulationID IN (1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1, HasWallet = 1

### 2.3 eToro Money UK Population

**What**: Customers with an active UK eToro Money account (Card UK or IBAN UK).
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- RegulationID IN (1=CySEC, 2=FCA)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1
- Card UK path: eMoney_Dim_Account.AccountSubProgramID IN (1=Card Premium UK, 2=Card Standard UK) AND CardID IS NOT NULL AND UK country (CountryID=218)
- IBAN UK path: eMoney_Dim_Account.AccountSubProgramID IN (3, 4, 8) — any country eligible

### 2.4 eToro Money Malta Population

**What**: Customers with an EU IBAN eToro Money account who are fully KYC-verified EU/EEA residents.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- RegulationID = 1 (CySEC only)
- VerificationLevelID = 3 (fully verified — stricter than other populations)
- IsDepositor = 1
- eMoney_Dim_Account.AccountSubProgramID IN (5, 6, 7, 9) — EU IBAN programs
- KYC country must be in the EEA/EU hardcoded list (37 country IDs)

### 2.5 Multi-Entity Dedup and STRING_AGG

**What**: A customer can qualify for multiple sub-entities simultaneously.
**Columns Involved**: AML_Sub_Entity
**Rules**:
- All 4 populations are UNIONed into #finaltbl
- ROW_NUMBER() dedup by CID picks the row with the longest combined entity label string (most qualifying entities)
- STRING_AGG(AMLValue, ', ') concatenates all applicable sub-entity labels into a comma-separated string
- A CID can appear as e.g. "eToro_Germany, eToro_Money_Malta" if they qualify for both

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED INDEX(CID ASC). Efficient for CID-level lookups and JOINs to other HASH(CID) tables (Dim_Customer, BI_DB_CID_Daily_NWA, etc.). No partitioning — the full 2.11M rows are always current (single daily snapshot).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "Which sub-entity does customer X belong to?" | `SELECT AML_Sub_Entity FROM BI_DB_AML_SubEntity_Categorization WHERE CID = @cid` |
| "All customers in eToro_Germany?" | `WHERE AML_Sub_Entity LIKE '%eToro_Germany%'` (LIKE because multi-valued CSV) |
| "Count per sub-entity?" | `SELECT AML_Sub_Entity, COUNT(*) FROM … GROUP BY AML_Sub_Entity` (counts combinations, not individual entities) |
| "All eToro Money Malta customers under FCA?" | `WHERE AML_Sub_Entity LIKE '%eToro_Money_Malta%' AND RegulationID = 2` — NOTE: FCA is not eligible for Malta per SP logic; result will be 0. Use CySEC (1). |
| "Get country + regulation for AML report?" | JOIN to Dim_Country on CountryID, Dim_Regulation on RegulationID for enriched decode |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `AML.CID = dc.RealCID` | Enrich with customer demographics |
| DWH_dbo.Dim_Country | `AML.CountryID = dc.CountryID` | Country name decode |
| DWH_dbo.Dim_Regulation | `AML.RegulationID = dr.DWHRegulationID` | Regulation name decode |
| BI_DB_dbo.BI_DB_PositionPnL | `AML.CID = pnl.CID` | Cross-reference with position P&L |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | `AML.CID = ch.CID` | AML status change history |

### 3.4 Gotchas

- **AML_Sub_Entity is a multi-value CSV string** — do NOT use `= 'eToro_Germany'` for filtering; use `LIKE '%eToro_Germany%'`. This pattern is non-trivial to aggregate accurately.
- **Not a universe of all customers** — only verified (VerLevel≥2) depositors with active eToro Money or crypto wallet holdings qualify. Silent exclusion of unverified, non-depositors, and TP-only customers.
- **eToro_Money_Malta requires VerLevel=3 only** — the other three populations accept VerLevel≥2 (includes level 2). This is a data quality distinction: most customers qualify at level 3.
- **Germany population dual-criteria**: HasWallet OR RealCrypto. Both paths produce label "eToro_Germany" — the sub-entity label does not distinguish which criterion triggered.
- **Full rebuild daily** — UpdateDate is the same for all rows in a given day's run (confirmed: all 2.11M rows have UpdateDate 2026-04-13 04:05:57). Do not use UpdateDate for change tracking.
- **AML_Sub_Entity can be NULL** — if a CID qualifies under a population where all entity labels (AMLSubEntity, AMLEntity, AMLSubEntity_2) are NULL (edge case). Filter `WHERE AML_Sub_Entity IS NOT NULL` when needed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description copied verbatim from upstream wiki (DWH_dbo.Dim_Customer or production source) |
| **Tier 2** | Derived from SP code analysis or DWH-layer ETL logic |
| **Tier 3** | Inferred from data patterns and context; no SP confirmation |
| **Tier 4** | Best available knowledge; limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer (RealCID). (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer via Dim_Country.DWHCountryID=CountryID identity. (Tier 1 — Customer.CustomerStatic) |
| 4 | Country | varchar(50) | NO | Country name, denormalized from DWH_dbo.Dim_Country.Name. Matches CountryID. Included to avoid join in downstream AML reports. (Tier 2 — SP_AML_SubEntity_Categorization) |
| 5 | RegulationID | tinyint | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. In this table: 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML only (other regulations are excluded by SP eligibility criteria). (Tier 1 — BackOffice.Customer) |
| 6 | Regulation | varchar(50) | YES | Regulation name, denormalized from DWH_dbo.Dim_Regulation.Name. Matches RegulationID. (Tier 2 — SP_AML_SubEntity_Categorization) |
| 7 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. All rows share the same timestamp per daily run (single TRUNCATE+INSERT batch). (Tier 2 — SP_AML_SubEntity_Categorization) |
| 8 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Only VerLevel≥2 customers are in this table; 99.999% are VerLevel=3. (Tier 1 — BackOffice.Customer) |
| 9 | AML_Sub_Entity | nvarchar(max) | YES | ETL-computed comma-separated list of eToro AML sub-entities this customer qualifies for. Possible values (may be combined): eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta. NULL if no entity label applies. Use LIKE '%value%' for filtering. (Tier 2 — SP_AML_SubEntity_Categorization) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough (DWHCountryID=CountryID) |
| Country | DWH_dbo.Dim_Country | Name | Denormalized join |
| RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Denormalized join |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| AML_Sub_Entity | DWH_dbo.Dim_Customer + eMoney_dbo.eMoney_Dim_Account | Multiple fields | STRING_AGG of 4 population labels |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (RealCID, GCID, CountryID, RegulationID, VerificationLevelID, HasWallet, IsValidCustomer, IsDepositor)
DWH_dbo.Dim_Country  (CountryID, Name — for Germany=79, EEA list, UK=218)
DWH_dbo.Dim_Regulation (Name)
DWH_dbo.Dim_Instrument (InstrumentTypeID=10 for crypto check)
BI_DB_dbo.BI_DB_PositionPnL (RealCrypto position check for Germany population)
eMoney_dbo.eMoney_Dim_Account (AccountSubProgramID for UK Card/IBAN, EU IBAN Malta)
  |
  |-- SP_AML_SubEntity_Categorization ---|
  |   Step 01-03: #germany03 (eToro_Germany — CySEC+Germany+crypto)
  |   Step 04:    #gibraltar01 (eToro_Gibraltar — non-Germany+wallet+major regs)
  |   Step 05-06: #etoromoney02 (eToro_Money_UK — CySEC/FCA+UK card/IBAN)
  |   Step 07-08: #etoromalta02 (eToro_Money_Malta — CySEC+EU IBAN+EEA country)
  |   Step 10:    #finaltbl (UNION all 4 populations)
  |   Step 11:    #finaltbl2 ROW_NUMBER dedup by CID (keep max-label-length row)
  |   Step 12:    #finaltbl4 STRING_AGG → AML_Sub_Entity
  |   Step 13:    TRUNCATE BI_DB_AML_SubEntity_Categorization
  |   Step 14:    INSERT INTO target (2.11M rows)
  v
BI_DB_dbo.BI_DB_AML_SubEntity_Categorization (2.11M rows, daily TRUNCATE+INSERT)
  |
  |-- Generic Pipeline (Override, delta, daily, 1440 min) ---|
  v
compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension — source of CID, GCID, CountryID, RegulationID, VerificationLevelID |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country dimension — source of Country name |
| RegulationID | DWH_dbo.Dim_Regulation.DWHRegulationID | Regulation dimension — source of Regulation name |
| (AML filter) | BI_DB_dbo.BI_DB_PositionPnL.CID | Crypto position check for Germany population |
| (eMoney) | eMoney_dbo.eMoney_Dim_Account.CID | eMoney account sub-program lookup for UK/Malta populations |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard | Reads AML_Sub_Entity for AML terrorism monitoring dashboard |
| BI_DB_dbo.SP_M_AML_Report | Reads AML_Sub_Entity for monthly AML reporting |

---

## 7. Sample Queries

### All eToro Money UK customers under FCA regulation

```sql
SELECT CID, GCID, Country, Regulation, AML_Sub_Entity
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization]
WHERE AML_Sub_Entity LIKE '%eToro_Money_UK%'
  AND RegulationID = 2  -- FCA
ORDER BY CID;
```

### Sub-entity count distribution

```sql
SELECT AML_Sub_Entity, COUNT(*) AS customer_count
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization]
GROUP BY AML_Sub_Entity
ORDER BY customer_count DESC;
```

### Germany + Malta dual-entity customers

```sql
SELECT sc.CID, sc.Country, sc.AML_Sub_Entity
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization] sc
WHERE sc.AML_Sub_Entity LIKE '%eToro_Germany%'
  AND sc.AML_Sub_Entity LIKE '%eToro_Money_Malta%'
ORDER BY sc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped — AML sub-entity classification logic is fully captured in SP_AML_SubEntity_Categorization code and DWH dimension wikis). The four entity classifications (Germany, Gibraltar, Money UK, Money Malta) align with eToro's regulated entity structure for crypto AML oversight.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14 (P10 Jira skipped)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 | Elements: 9/9 | Logic: 5 subsections*
*Object: BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | Type: Table | Production Source: DWH_dbo.Dim_Customer + eMoney_dbo.eMoney_Dim_Account via SP_AML_SubEntity_Categorization*


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

### Upstream `eMoney_dbo.eMoney_Dim_Account` — synapse
- **Resolved as**: `eMoney_dbo.eMoney_Dim_Account`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md`

# eMoney_dbo.eMoney_Dim_Account

> One row per eToro Money fiat currency balance, consolidating currency-balance identity, customer DWH enrichment, bank account and card details, account program history, and change-detection flags from FiatDwhDB and DWH_dbo sources. 2,034,012 rows; currency balances created 2020-11-09 to 2026-04-13; refreshed daily via DELETE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dimension) |
| **Production Source** | FiatDwhDB (eToro Money fiat platform DWH) via SP_eMoney_Dim_Account |
| **Refresh** | Daily DELETE + INSERT (Step 3 of SP_eMoney_Execute_Group_One; @Date = yesterday) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CurrencyBalanceID ASC); NCI (CID ASC) |
| **Row Count** | 2,034,012 (sampled 2026-04-13) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dim_Account` is the central account dimension for eToro Money (eTM), the fiat banking product. Each row represents one **currency balance** — the fundamental money-holding unit in the fiat platform. A single customer (GCID) can have multiple currency balances (e.g., EUR and GBP), so this table is at currency-balance grain, not customer grain.

The table consolidates three layers of data:
1. **FiatDwhDB identity** — currency balance, fiat account, bank account, card, and current status fields sourced from FiatDwhDB tables (FiatCurrencyBalances, FiatAccount, FiatBankAccount, FiatCards, FiatCardStatuses, FiatAccountStatuses, FiatAccountsProperties, FiatCurrencyBalancesStatuses)
2. **DWH customer enrichment** — club, regulation, country, and player status attributes from DWH_dbo.Dim_Customer and registration-time snapshots from Fact_SnapshotCustomer, joined via GCID
3. **DWH-computed fields** — IsValidETM composite flag, change-detection flags, seniority months, entity mapping

The ETL SP (`SP_eMoney_Dim_Account`) runs daily in an 11-step pipeline. It builds temp tables for each source cluster, filters to the primary currency balance per GCID (`GCID_Unique_Count=1`) for DWH enrichment joins, then performs a full DELETE + INSERT. Rows with `GCID_Unique_Count > 1` are secondary accounts and will have NULL customer attributes (CID, ClubID, RegulationID, etc.).

**Entity distribution** (2026-04-13): Malta 66.6%, UK 31.4%, AUS 2.0%.
**Account program distribution**: IBAN 95.3%, card 4.7%.
**Note on GCID=0**: Cancelled accounts are recorded with GCID=0; `IsCancelledAccount` = 1 for these rows.

---

## 2. Business Logic

### 2.1 Currency Balance Grain

**What**: The table is at currency-balance grain, not customer grain. One GCID can appear on multiple rows (one per currency balance / account type).

**Columns Involved**: `CurrencyBalanceID`, `AccountID`, `GCID`, `GCID_Unique_Count`

**Rules**:
- `CurrencyBalanceID` = `FiatCurrencyBalances.Id` — the primary key of this table's logical entity
- `AccountID` = `FiatAccount.Id` — one account can hold multiple currency balances
- `GCID_Unique_Count` = `ROW_NUMBER() PARTITION BY GCID ORDER BY AccountCreateTime DESC` — rank 1 = most recently created eMoney account for this customer
- Customer enrichment (CID, ClubID, RegulationID, etc.) is populated only for rows with `GCID_Unique_Count = 1`; secondary accounts have NULL for all DWH customer attributes

### 2.2 Primary Account Identification (GCID_Unique_Count=1 Rule)

**What**: DWH customer attributes are only available for the primary eMoney account per customer.

**Columns Involved**: `GCID_Unique_Count`, `CID`, `ClubID`, `RegulationID`, `CountryID`, `PlayerStatusID`, and all `Reg*` snapshot columns

**Rules**:
- Only rows where `GCID_Unique_Count = 1` are joined to `DWH_dbo.Dim_Customer` and `Fact_SnapshotCustomer`
- Rows with `GCID_Unique_Count > 1` have NULL in all customer-DWH enrichment columns
- `GCID_Unique_Count` itself is always populated (not NULL) — it indicates rank, not count
- Use `WHERE GCID_Unique_Count = 1` when joining to trading-side CID-based analysis

### 2.3 Current vs Registration-Time Attributes

**What**: The table captures two time points for club, regulation, country, player status, and account program: the current state and the state at eMoney account creation.

**Columns Involved**: `ClubID`/`RegClubID`, `RegulationID`/`RegRegulationID`, `CountryID`/`RegCountryID`, `PlayerStatusID`/`RegPlayerStatusID`, `AccountProgramID`/`RegAccountProgramID`, `AccountSubProgramID`/`RegAccountSubProgramID`

**Rules**:
- `Reg*` columns come from `Fact_SnapshotCustomer` joined at the `AccountCreateDateID` range — they represent the customer's attributes at the time they opened their eMoney account
- Current columns (no prefix) come from current `Dim_Customer` values
- Change flags (`HasClubChanged`, `HasRegulationChanged`, etc.) are 1 when the corresponding current and reg values differ

### 2.4 IsValidETM Composite Flag

**What**: Composite flag combining trading-side validity, test account exclusion, and cancelled account exclusion.

**Columns Involved**: `IsValidETM`, `IsValidCustomer`, `IsTestAccount`, `IsCancelledAccount`

**Rules**:
- `IsValidETM = 1` when ALL three conditions hold: `IsValidCustomer=1`, `IsTestAccount=0`, `IsCancelledAccount=0`
- `IsValidCustomer` is sourced from `Dim_Customer` (excludes Popular Investors, label 30/26 accounts, and CountryID=250)
- `IsTestAccount=1` when GCID appears in the Fivetran Google Sheets test-user list (`eMoney_google_sheets.emoney_test_users`)
- `IsCancelledAccount=1` when `GCID=0` (cancelled accounts stored with a zero GCID)
- Use `IsValidETM = 1` as the standard filter for production eMoney analytics

### 2.5 Account Program and Sub-Program (Current vs Registration)

**What**: The `AccountProgramID`/`AccountSubProgramID` reflect the customer's current program; the `RegAccountProgramID`/`RegAccountSubProgramID` reflect what was assigned at account creation.

**Columns Involved**: `AccountProgramID`, `AccountSubProgramID`, `RegAccountProgramID`, `RegAccountSubProgramID`, `CountAccountProgramChanges`, `CountAccountSubProgramChanges`

**Rules**:
- Current program: `ISNULL(latest FiatAccountsProperties record, original FiatAccount value)` — ensures latest program change is reflected
- `CountAccountProgramChanges`: number of distinct program values seen; set to 0 if the count was ≤1 (i.e., never changed; 0 = never changed, N≥2 = changed N times)
- Sub-programs (16 active: 1=Card Premium UK through 16=IBAN Black DKK) map region and tier

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is distributed on `HASH(CID)`. Most analytics joins are `CID`-based (eToro trading platform joins), so shuffle is minimized. However, `CurrencyBalanceID` is the clustered index key, making point lookups by currency balance ID efficient.

The NCI on `CID` speeds up `WHERE CID = N` predicates common in user-level queries.

**Note**: For eMoney-only analysis (without trading-side JOIN), consider joining on `GCID` — but GCID is not the distribution key, so cross-joins will cause data movement. Filter to `GCID_Unique_Count = 1` first to reduce scan size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| eTM KPIs by entity/club/regulation | Filter `IsValidETM=1 AND GCID_Unique_Count=1`, GROUP BY Entity, RegulationID, ClubID |
| Account program distribution | GROUP BY AccountProgram WHERE GCID_Unique_Count=1 |
| Customers with card | WHERE HasCard=1 AND GCID_Unique_Count=1 |
| AUS entity onboarding funnel | WHERE Entity='AUS', filter by AccountCreateDate range |
| Regulation migrations | WHERE HasRegulationChanged=1 AND RegulationID <> RegRegulationID |
| UK IBAN holders | WHERE Entity='UK' AND AccountProgramID=2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON da.CID = dc.RealCID | Full trading profile for eTM customer |
| eMoney_dbo.eMoney_Dim_Transaction | ON da.CID = dt.CID | Transaction history for this account |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON da.CID = fts.CID | All transaction status events |
| eMoney_dbo.eMoneyClientBalance | ON da.CurrencyBalanceID = cb.CurrencyBalanceID | Daily balance reconciliation |
| DWH_dbo.Dim_Country | ON da.CountryID = c.CountryID | Country name/region lookup |
| DWH_dbo.Dim_Regulation | ON da.RegulationID = r.DWHRegulationID | Regulation name |

### 3.4 Gotchas

- **GCID_Unique_Count > 1 rows have NULL customer attributes**: Joining without filtering GCID_Unique_Count=1 will cause inflated counts and NULL-rich result sets.
- **GCID=0 rows**: Cancelled accounts appear with GCID=0. Use `IsCancelledAccount=0` to exclude them.
- **CID is NULL for secondary accounts**: `CID` is NULL when GCID_Unique_Count > 1; cannot use CID for cross-table JOINs on those rows.
- **UpdateDate = GETDATE() at INSERT time**: Not a business timestamp; it marks when the daily refresh ran.
- **BankAccountIBAN, BankAccountNumber, BankAccountName** are PII fields — masked in analytics environments (Synapse DDM enforced at FiatDwhDB source; may be masked in UC gold copy too).
- **NULL bank account fields**: Card-program accounts have no bank account linkage; BankAccountID and all BankAccount* columns will be NULL.
- **NULL card fields**: IBAN-only accounts may have HasCard=0 and NULL card columns.
- **TP_FTDDate sentinel**: Dim_Customer.FirstDepositDate defaults to '19000101' for non-depositors; TP_FTDDate will reflect that sentinel value (cast to date).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (FiatDwhDB or DWH_dbo) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_Dim_Account) |
| Tier 3 | Description inferred from column name and surrounding context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only — no description available |

### 4.1 Currency Balance Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 — dbo.FiatCurrencyBalances) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |

### 4.2 DWH Customer Enrichment (Primary Account Only)

*Columns 4–19 are populated only for rows where `GCID_Unique_Count = 1`. NULL for secondary accounts.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | ClubID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Renamed from PlayerLevelID. (Tier 1 — Customer.CustomerStatic) |
| 6 | Club | varchar(50) | YES | Player level display name resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 7 | ClubCategory | varchar(50) | YES | Grouped player level bucket. NoClub=PlayerLevelID 1; LowClub=3 or 5; HighClub=2, 6, or 7; Internal=4; Error=unmapped values. (Tier 2 — SP_eMoney_Dim_Account) |
| 8 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 9 | Regulation | varchar(50) | YES | Regulation display name resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 10 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 11 | Country | varchar(50) | YES | Country display name resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 12 | Region | varchar(50) | YES | Geographic region from DWH_dbo.Dim_Country.Region, resolved via CountryID. (Tier 2 — SP_eMoney_Dim_Account) |
| 13 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 14 | PlayerStatus | varchar(50) | YES | Player status display name resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 15 | IsValidETM | int | YES | eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 16 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 17 | IsTestAccount | int | YES | 1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 18 | IsCancelledAccount | int | YES | 1 when GCID=0 (cancelled accounts are recorded with a zero GCID in FiatDwhDB). (Tier 2 — SP_eMoney_Dim_Account) |
| 19 | GCID_Unique_Count | int | YES | Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.3 TP Trading Platform Dates

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | TP_RegDate | date | YES | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST to DATE (time component discarded); renamed RegisteredReal→TP_RegDate. (Tier 1 — Customer.CustomerStatic) |
| 21 | TP_FTDDate | date | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. DWH note: CAST to DATE; renamed FirstDepositDate→TP_FTDDate. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |

### 4.4 Registration-Time Snapshot (Customer State at eMoney Account Creation)

*Sourced from DWH_dbo.Fact_SnapshotCustomer at the date range matching AccountCreateDateID.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 22 | RegClubID | int | YES | PlayerLevelID from Fact_SnapshotCustomer at the date of eMoney account creation. Represents the customer's club at eTM onboarding. (Tier 2 — SP_eMoney_Dim_Account) |
| 23 | RegClub | varchar(50) | YES | Club display name for RegClubID, resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 24 | RegClubCategory | varchar(50) | YES | Club category bucket at account creation. Same mapping as ClubCategory (NoClub/LowClub/HighClub/Internal) applied to RegClubID. (Tier 2 — SP_eMoney_Dim_Account) |
| 25 | RegRegulationID | int | YES | RegulationID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 26 | RegRegulation | varchar(50) | YES | Regulation display name for RegRegulationID, resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 27 | RegCountryID | int | YES | CountryID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 28 | RegCountry | varchar(50) | YES | Country display name for RegCountryID, resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 29 | RegRegion | varchar(50) | YES | Geographic region for RegCountryID, resolved from DWH_dbo.Dim_Country.Region. (Tier 2 — SP_eMoney_Dim_Account) |
| 30 | RegPlayerStatusID | int | YES | PlayerStatusID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 31 | RegPlayerStatus | varchar(50) | YES | Player status display name for RegPlayerStatusID, resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 32 | RegAccountProgramID | int | YES | Account program type at eMoney account creation: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). Captured from eMoney_Account_Mappings baseline (original FiatAccount.AccountProgramId). (Tier 1 — dbo.FiatAccount) |
| 33 | RegAccountProgram | varchar(50) | YES | Account program display name for RegAccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 34 | RegAccountSubProgramID | int | YES | Specific sub-program variant at eMoney account creation: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. Captured from eMoney_Account_Mappings baseline. (Tier 1 — dbo.FiatAccount) |
| 35 | RegAccountSubProgram | varchar(50) | YES | Sub-program display name for RegAccountSubProgramID, resolved from eMoney_dbo.SubPrograms. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.5 Change Detection Flags

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | HasCustomerInfoChanged | int | YES | 1 if ANY of the following changed since account creation: ClubID, RegulationID, CountryID, PlayerStatusID, AccountProgramID, AccountSubProgramID. Composite of all six individual change flags. (Tier 2 — SP_eMoney_Dim_Account) |
| 37 | HasClubChanged | int | YES | 1 if ClubID (current) ≠ RegClubID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 38 | HasRegulationChanged | int | YES | 1 if RegulationID (current) ≠ RegRegulationID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 39 | HasCountryChanged | int | YES | 1 if CountryID (current) ≠ RegCountryID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 40 | HasPlayerStatusChanged | int | YES | 1 if PlayerStatusID (current) ≠ RegPlayerStatusID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 41 | HasAccountProgramChanged | int | YES | 1 if AccountProgramID (current) ≠ RegAccountProgramID (at account creation). Tracks card-to-IBAN upgrades. (Tier 2 — SP_eMoney_Dim_Account) |
| 42 | HasAccountSubProgramChanged | int | YES | 1 if AccountSubProgramID (current) ≠ RegAccountSubProgramID (at account creation). Tracks sub-program tier/region changes. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.6 Currency Balance Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | CurrencyBalanceISOCode | int | YES | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. Indexed for currency-based queries. Renamed from FiatCurrencyBalances.CurrencyISON. (Tier 1 — dbo.FiatCurrencyBalances) |
| 44 | CurrencyBalanceISODesc | varchar(50) | YES | Currency display name resolved from eMoney_Currency_Instrument_Mapping_Static via CurrencyBalanceISOCode (where SellCurrencyID=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 45 | CurrencyBalanceCreateTime | datetime | YES | UTC timestamp when this currency balance was created in the data warehouse. Renamed from FiatCurrencyBalances.Created. (Tier 1 — dbo.FiatCurrencyBalances) |
| 46 | CurrencyBalanceCreateDate | date | YES | Date portion of CurrencyBalanceCreateTime. DWH-derived: CAST(CurrencyBalanceCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 47 | CurrencyBalanceCreateDateID | int | YES | YYYYMMDD integer date key for CurrencyBalanceCreateDate. DWH-derived: CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 48 | CurrencyBalanceStatusID | int | YES | Current currency balance operational status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. Latest status from FiatCurrencyBalancesStatuses (RNDesc=1 by EventTimestamp). (Tier 2 — SP_eMoney_Dim_Account) |
| 49 | CurrencyBalanceStatus | varchar(50) | YES | Currency balance status display name for CurrencyBalanceStatusID, resolved from eMoney_Dictionary_CurrencyBalanceStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 50 | CurrencyBalanceStatusTime | datetime | YES | EventTimestamp of the most recent status change for this currency balance (from FiatCurrencyBalancesStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 51 | ProviderDesc | varchar(50) | YES | Provider name for this account (e.g., Tribe), sourced from AccountsProviderHoldersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 52 | ProviderCurrencyBalanceID | int | YES | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.7 Bank Account Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | BankAccountID | int | YES | Auto-incrementing surrogate primary key. (Tier 1 — dbo.FiatBankAccount) |
| 54 | BankAccountIsExternal | int | YES | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 — dbo.FiatBankAccount) |
| 55 | BankAccountName | nvarchar(100) | YES | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. Renamed from FiatBankAccount.FullName. (Tier 1 — dbo.FiatBankAccount) |
| 56 | BankAccountNumber | int | YES | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 — dbo.FiatBankAccount) |
| 57 | BankAccountSortCode | int | YES | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 — dbo.FiatBankAccount) |
| 58 | BankAccountIBAN | varchar(200) | YES | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 — dbo.FiatBankAccount) |
| 59 | BankAccountBIC | varchar(200) | YES | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 — dbo.FiatBankAccount) |

### 4.8 Fiat Account Create & Status

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 60 | AccountCreateTime | datetime | YES | UTC timestamp when this account record was created in the data warehouse. Renamed from FiatAccount.Created. (Tier 1 — dbo.FiatAccount) |
| 61 | AccountCreateDate | date | YES | Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 62 | AccountCreateDateID | int | YES | YYYYMMDD integer date key for AccountCreateDate. DWH-derived: CONVERT(VARCHAR(8), AccountCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 63 | AccountStatusID | int | YES | Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). (Tier 1 — dbo.FiatAccountStatuses) |
| 64 | AccountStatus | varchar(50) | YES | Account status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 65 | AccountStatusTime | datetime | YES | Created timestamp of the most recent account status change event (from FiatAccountStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |

### 4.9 Account Program & Sub-Program (Current)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.AccountProgramId) — reflects most recent program upgrade/downgrade. (Tier 1 — dbo.FiatAccount) |
| 67 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 68 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 — dbo.FiatAccount) |
| 69 | AccountSubProgram | varchar(50) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_Dim_Account) |
| 70 | AccountPropertiesTime | datetime | YES | Created timestamp of the most recent FiatAccountsProperties record for this account (the source of AccountProgramID/AccountSubProgramID). NULL if no properties record exists. (Tier 2 — SP_eMoney_Dim_Account) |
| 71 | AccountPropertiesDate | date | YES | Date portion of AccountPropertiesTime. DWH-derived: CAST(AccountPropertiesTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 72 | CountAccountProgramChanges | int | YES | Number of distinct program types this account has had. Set to 0 when ≤1 (i.e., never changed). N≥2 means the account has changed program N times. (Tier 2 — SP_eMoney_Dim_Account) |
| 73 | CountAccountSubProgramChanges | int | YES | Number of distinct sub-programs this account has had. Set to 0 when ≤1 (never changed). N≥2 means the account has changed sub-program N times. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.10 Provider & Seniority

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | ProviderHolderID | int | YES | Provider-side holder identifier from AccountsProviderHoldersMapping via eMoney_Account_Mappings. Identifies the customer's account in the Tribe payment provider system. (Tier 2 — SP_eMoney_Dim_Account) |
| 75 | Seniority_TP_RegDate | int | YES | Months since TP (trading platform) registration date (DATEDIFF MONTH between RegisteredReal and @Date=yesterday). NULL when TP_RegDate is NULL. (Tier 2 — SP_eMoney_Dim_Account) |
| 76 | Seniority_TP_FTDDate | int | YES | Months since first trading platform deposit date (DATEDIFF MONTH between FirstDepositDate and @Date=yesterday). NULL when TP_FTDDate is NULL or is the sentinel '19000101'. (Tier 2 — SP_eMoney_Dim_Account) |
| 77 | Seniority_eTM_RegDate | int | YES | Months since eToro Money account creation date (DATEDIFF MONTH between AccountCreateTime and @Date=yesterday). Measures eTM-specific tenure. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.11 Card Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | HasCard | int | YES | 1 if this account has an associated card (CardID IS NOT NULL), 0 otherwise. (Tier 2 — SP_eMoney_Dim_Account) |
| 79 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 — dbo.FiatCards) |
| 80 | CardCreateTime | datetime | YES | UTC timestamp when this card record was created in the data warehouse. Renamed from FiatCards.Created. (Tier 1 — dbo.FiatCards) |
| 81 | CardCreateDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 82 | CardCreateDateID | int | YES | YYYYMMDD integer date key for CardCreateDate. DWH-derived: CONVERT(VARCHAR(8), CardCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 83 | CardStatusID | int | YES | Current card lifecycle status: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. Latest status from FiatCardStatuses (RNDesc=1 by EventTimestamp). (Tier 1 — dbo.FiatCardStatuses) |
| 84 | CardStatus | varchar(50) | YES | Card status display name for CardStatusID, resolved from eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 85 | CardStatusExpirationTime | datetime | YES | Card expiration date at the time of this status event. (Tier 1 — dbo.FiatCardStatuses) |
| 86 | CardStatusTime | datetime | YES | When the status change occurred in the source system. (Tier 1 — dbo.FiatCardStatuses) |
| 87 | ProviderCardID | int | YES | Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.12 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 88 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_Dim_Account) |
| 89 | Entity | varchar(250) | YES | eToro Money entity name resolved from eMoney_EntityByCurrencyISO_MappingStatic via CurrencyBalanceISOCode. Identifies the regulatory/legal entity serving this balance. ISNULL → 'N/A' when no mapping exists. Values observed: Malta, UK, AUS. (Tier 2 — SP_eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column Group | Production Source | Source Column(s) | Transform |
|-----------------|-------------------|-----------------|-----------|
| CurrencyBalanceID | FiatDwhDB.dbo.FiatCurrencyBalances | Id | Passthrough |
| AccountID, GCID | FiatDwhDB.dbo.FiatAccount | Id, Gcid | Passthrough |
| AccountCreateTime | FiatDwhDB.dbo.FiatAccount | Created | Rename |
| CID, ClubID, RegulationID, CountryID, PlayerStatusID, IsValidCustomer, TP_RegDate, TP

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_AML_Terror_Monitor_Dashboard] AS
BEGIN
SET NOCOUNT ON;

-- EXEC BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard

/********** Step 01 **********/
/********** General Population **********/
IF OBJECT_ID('tempdb..#pop') IS NOT NULL DROP TABLE #pop
CREATE TABLE #pop  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT dc.RealCID AS CID
	  ,dr.Name AS Regulation
	  ,dc1.Name AS KYC_Country
	  ,dc2.Name CitizenshipCountry
	  ,dc3.Name POBCountry
	  ,dc4.Name CountryByIP_Residency
	  ,dps.Name AS PlayerStatus	 
	  ,dpl.Name AS Club
	  ,dc.HasWallet
	  ,dc.RegisteredReal
	  ,dc.FirstDepositDate
	  ,dc.FirstDepositAmount
	  ,dss.Name AS ScreeningStatus
	  ,bdrc.RiskScoreName
	  ,bdasec.AMLEntity
	  ,bdasec.AMLSubEntity	
	  ,bdasec.AMLSubEntity_2
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID AND dps.PlayerStatusID IN (1,5) -- Normal, Warning
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Country dc1 ON dc1.DWHCountryID = dc.CountryID 
LEFT JOIN DWH_dbo.Dim_Country dc2 ON dc2.DWHCountryID = dc.CitizenshipCountryID  
LEFT JOIN DWH_dbo.Dim_Country dc3 ON dc3.DWHCountryID = dc.POBCountryID   
LEFT JOIN DWH_dbo.Dim_Country dc4 ON dc4.DWHCountryID = dc.CountryIDByIP  
LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss ON dc.ScreeningStatusID = dss.ScreeningStatusID
LEFT JOIN [BI_DB_dbo].[External_RiskClassification_dbo_V_RiskClassificationDataLake] bdrc ON dc.RealCID = bdrc.CID
LEFT JOIN BI_DB_dbo.BI_DB_AML_SubEntity_Categorization bdasec ON bdasec.CID = dc.RealCID
WHERE dc.IsValidCustomer =1 
AND dc.IsDepositor =1 
AND dc.VerificationLevelID = 3 
AND 
(
 dc.CountryID IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209)
 OR dc.CitizenshipCountryID IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209)
 OR dc.POBCountryID IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209) 
 OR dc.CountryIDByIP IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209) 
)

/********** Step 02 **********/
/********** Equity **********/
IF OBJECT_ID('tempdb..#equity') IS NOT NULL DROP TABLE #equity
CREATE TABLE #equity  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT vl.CID
	  ,ISNULL(vl.Liabilities,0)+ISNULL(vl.ActualNWA,0) AS Equity
FROM DWH_dbo.V_Liabilities vl
JOIN #pop pp ON vl.CID = pp.CID
WHERE vl.DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)

/********** Step 03 **********/
/********** Total Deposits **********/
IF OBJECT_ID('tempdb..#deposits') IS NOT NULL DROP TABLE #deposits
CREATE TABLE #deposits  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT pp.CID, SUM(fca.Amount) AS Total_Deposits
FROM DWH_dbo.Fact_CustomerAction fca
JOIN #pop pp ON pp.CID = fca.RealCID
WHERE fca.ActionTypeID = 7 --Deposits
GROUP BY pp.CID

/********** Step 04 **********/
/********** Total CO **********/ 
IF OBJECT_ID('tempdb..#CO') IS NOT NULL DROP TABLE #CO
CREATE TABLE #CO  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT pp.CID, SUM(fca.Amount) AS Total_CO
FROM DWH_dbo.Fact_CustomerAction fca
JOIN #pop pp ON pp.CID = fca.RealCID
WHERE fca.ActionTypeID = 8 --CO
GROUP BY pp.CID

/********** Step 05 **********/
/********** Has eMoney/Iban **********/ 
IF OBJECT_ID('tempdb..#eMoney') IS NOT NULL DROP TABLE #eMoney
CREATE TABLE #eMoney  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT mda.CID
FROM eMoney_dbo.eMoney_Dim_Account mda
WHERE mda.IsValidETM =1
AND mda.IsTestAccount =0
AND ISNULL(mda.CurrencyBalanceStatusID,0) <> 4 -- Blocked

IF OBJECT_ID('tempdb..#eMoney2') IS NOT NULL DROP TABLE #eMoney2
CREATE TABLE #eMoney2  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT pp.CID
	  ,CASE WHEN mm.CID IS NULL THEN 0 ELSE 1 END AS Has_eMoney_Account	
FROM #pop pp
LEFT JOIN #eMoney mm ON pp.CID = mm.CID

/********** Step 06 **********/
/********** Final Table **********/
IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
CREATE TABLE #final  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT pp.CID
	  ,pp.Regulation
	  ,pp.KYC_Country
	  ,pp.CitizenshipCountry
	  ,pp.POBCountry
	  ,pp.CountryByIP_Residency
	  ,pp.PlayerStatus
	  ,pp.Club
	  ,pp.HasWallet
	  ,pp.RegisteredReal
	  ,pp.FirstDepositDate
	  ,pp.FirstDepositAmount
	  ,pp.ScreeningStatus 
	  ,pp.RiskScoreName
	  ,pp.AMLEntity
	  ,pp.AMLSubEntity	
	  ,pp.AMLSubEntity_2
	  ,ee.Equity
	  ,dd.Total_Deposits
	  ,cc.Total_CO
	  ,mm.Has_eMoney_Account
FROM #pop pp
LEFT JOIN #equity ee ON pp.CID = ee.CID
LEFT JOIN #deposits dd ON pp.CID = dd.CID
LEFT JOIN #CO cc ON pp.CID = cc.CID
LEFT JOIN #eMoney2 mm ON pp.CID = mm.CID

/********** Step 07 **********/
/********** Truncate and Insert into Table **********/
TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard
INSERT INTO BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard
	  (CID
	  ,Regulation
	  ,KYC_Country
	  ,CitizenshipCountry
	  ,POBCountry
	  ,CountryByIP_Residency
	  ,PlayerStatus
	  ,Club
	  ,HasWallet
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,FirstDepositAmount
	  ,ScreeningStatus
	  ,RiskScoreName
	  ,AMLEntity
	  ,AMLSubEntity	
	  ,AMLSubEntity_2
	  ,Equity
	  ,Total_Deposits
	  ,Total_CO
	  ,Has_eMoney_Account	 
	  ,UpdateDate)
SELECT CID
	  ,Regulation
	  ,KYC_Country
	  ,CitizenshipCountry
	  ,POBCountry
	  ,CountryByIP_Residency
	  ,PlayerStatus
	  ,Club
	  ,HasWallet
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,FirstDepositAmount
	  ,ScreeningStatus
	  ,RiskScoreName
	  ,AMLEntity
	  ,AMLSubEntity	
	  ,AMLSubEntity_2
	  ,Equity
	  ,Total_Deposits
	  ,Total_CO
	  ,Has_eMoney_Account	
	  ,GETDATE() AS UpdateDate
FROM #final  

/********** END **********/
 END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard` | synapse_sp | BI_DB_dbo | SP_AML_Terror_Monitor_Dashboard | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_PlayerLevel` | synapse | DWH_dbo | Dim_PlayerLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_ScreeningStatus` | synapse | DWH_dbo | Dim_ScreeningStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ScreeningStatus.md` |
| `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake` | unresolved | BI_DB_dbo | External_RiskClassification_dbo_V_RiskClassificationDataLake | `—` |
| `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization` | synapse | BI_DB_dbo | BI_DB_AML_SubEntity_Categorization | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AML_SubEntity_Categorization.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `eMoney_dbo.eMoney_Dim_Account` | synapse | eMoney_dbo | eMoney_Dim_Account | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |
