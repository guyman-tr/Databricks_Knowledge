# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_PaymentSent_Results`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_PaymentSent_Results.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_PaymentSent_Results]
(
	[CID] [int] NULL,
	[Regulation] [nvarchar](1000) NULL,
	[Currency] [varchar](50) NULL,
	[Amount$Withdraw] [money] NOT NULL,
	[DaysInPaymentSentStatus] [int] NULL,
	[ModificationDate] [datetime] NULL,
	[WithdrawID] [bigint] NULL,
	[WithdrawProcessingID] [bigint] NULL,
	[FundingID] [bigint] NULL,
	[Provider] [nvarchar](1000) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[CID] ASC
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

### Upstream `DWH_dbo.Dim_Currency` — synapse
- **Resolved as**: `DWH_dbo.Dim_Currency`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md`

# DWH_dbo.Dim_Currency

> Despite its name, this is the universal instrument registry (15.7K rows) for all tradeable assets on the eToro platform: stocks (13K), ETFs (1.1K), crypto (686), commodities (533), indices (203), and forex (174).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Currency |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CurrencyID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Currency` is the **universal instrument registry** for the eToro DWH. Despite its misleading name (inherited from eToro's origins as a forex-only platform), it contains every tradeable asset on the platform: 13,044 stocks, 1,094 ETFs, 686 crypto assets, 533 commodities, 203 indices, and 174 forex pairs - 15,734 rows total as of 2026-03-11.

`CurrencyID` is the platform-wide instrument identifier. It is referenced by virtually every fact table in the DWH: trade positions, deposits, credit events, and cost history all use CurrencyID to identify the instrument involved. Joining to Dim_Currency decodes CurrencyID into instrument name, asset class (CurrencyTypeID), and trading properties.

The ETL is a full TRUNCATE+INSERT daily reload from `DWH_staging.etoro_Dictionary_Currency`. All 9 source columns are passthroughs; only UpdateDate is ETL-computed. The DWH has more rows than the upstream wiki documents (15.7K vs 10.7K upstream) because the wiki was written earlier and the platform has added more instruments since.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md` (quality 9+/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 Instrument Classification by Asset Class

**What**: CurrencyTypeID classifies every instrument into one of 6 asset classes, determining trading rules, leverage limits, and settlement options.

**Columns Involved**: `CurrencyTypeID`

**DWH distribution (live 2026-03-11)**:
```
CurrencyTypeID=5 (Stocks):     13,044 rows (83%)
CurrencyTypeID=6 (ETF):         1,094 rows (7%)
CurrencyTypeID=10 (Crypto):       686 rows (4%)
CurrencyTypeID=2 (Commodity):     533 rows (3%)
CurrencyTypeID=4 (Indices):       203 rows (1%)
CurrencyTypeID=1 (Forex):         174 rows (1%)
```

**Rules**:
- Stocks (5): Individual company shares. Can trade as REAL (1x) or CFD.
- ETF (6): Exchange-traded funds. Similar rules to stocks.
- Crypto (10): Bitcoin, Ethereum, etc. ESMA max 2x retail leverage. Can be REAL at 1x.
- Commodity (2): Gold, Oil, Silver, etc. Always CFD. ESMA max 10x retail.
- Forex (1): Currency pairs. Always CFD. ESMA max 30x (majors) / 20x (minors).
- Indices (4): S&P 500, NASDAQ, etc. Always CFD. ESMA max 20x retail.

### 2.2 Bitmask System (Legacy Forex)

**What**: The Mask column encodes forex instrument identity as power-of-2 bitmasks for legacy system compatibility.

**Columns Involved**: `Mask`

**Rules**:
- USD=1 (2^0), EUR=2 (2^1), GBP=4 (2^2), JPY=8 (2^3), AUD=16 (2^4), CHF=32 (2^5), CAD=64 (2^6), NZD=128 (2^7)
- Only meaningful for the original 8 major forex currencies. Stocks, crypto, commodities have NULL or 0.
- Hard ceiling of 31 instruments (INT bitmask limit) - now exceeded, so not used for newer assets.

### 2.3 EEA Stock Exchange Compliance (MiFID II)

**What**: Flags instruments listed on European Economic Area exchanges requiring KID documents under PRIIPs regulation.

**Columns Involved**: `EEAStockExchange`

**Rules**:
- EEAStockExchange=1 for ~216 instruments on EU/EEA exchanges (London, Frankfurt, Paris, etc.)
- These require KID (Key Information Document) availability for retail EU clients
- Affects instrument availability for EU-regulated users

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE with 15.7K rows is appropriate. The CLUSTERED INDEX on CurrencyID supports fast point lookups. At this row count, the table is small enough to broadcast to all nodes efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (15.7K rows). Z-ORDER BY CurrencyID optional.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode instrument ID in a fact | `JOIN DWH_dbo.Dim_Currency d ON f.CurrencyID = d.CurrencyID` |
| Filter stocks only | `WHERE CurrencyTypeID = 5` |
| Find a specific instrument by ticker | `WHERE Abbreviation = 'AAPL.US'` |
| List EEA instruments | `WHERE EEAStockExchange = 1` |
| Exclude CurrencyID=0 (placeholder) | `WHERE CurrencyID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| All DWH fact tables | ON f.CurrencyID = d.CurrencyID | Decode instrument for any trade/position/cost fact |
| DWH_dbo.Dim_Country | ON c.DefaultCurrencyID = d.CurrencyID | Default account currency per country [UNVERIFIED - DefaultCurrencyID dropped from Dim_Country] |

### 3.4 Gotchas

- **Naming is misleading**: This is NOT just currencies. 83% of rows are stocks. Always filter by CurrencyTypeID when intent is asset-class-specific.
- CurrencyID=0 is a placeholder ("NULL instrument"). Exclude with `WHERE CurrencyID > 0` for business analytics.
- Mask is NULL/0 for all non-forex instruments. Do not use Mask for asset identification outside legacy forex systems.
- DWH has 15.7K rows; upstream production wiki shows 10.7K - the platform has added ~5K instruments since the wiki was written. Row count grows over time.
- Name is `varchar(50)` - many stock names are verbose (e.g., "United States of America, US Dollar"). Use Abbreviation for tickers.

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
| 1 | CurrencyID | int | NO | Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. (Tier 1 - Dictionary.Currency upstream wiki) |
| 2 | CurrencyTypeID | int | NO | FK to Dim_CurrencyType (if exists). Asset class: 1=Forex (174), 2=Commodity (533), 4=Indices (203), 5=Stocks (13,044), 6=ETF (1,094), 10=Crypto (686). Determines trading rules, leverage limits, and settlement eligibility. (Tier 1 - Dictionary.Currency upstream wiki) |
| 3 | Name | varchar(50) | NO | Full instrument name. Verbose for forex ("United States of America, US Dollar"), company name for stocks, coin name for crypto. (Tier 1 - Dictionary.Currency upstream wiki) |
| 4 | Abbreviation | varchar(20) | NO | Ticker symbol. "USD", "EUR" for forex; "AAPL.US", "TSLA.US" for US stocks (format: TICKER.EXCHANGE); "BTC" for crypto. Unique across all instruments. Use this for human-readable instrument identification. (Tier 1 - Dictionary.Currency upstream wiki) |
| 5 | Mask | int | YES | Legacy power-of-2 bitmask for original 8 major forex currencies (USD=1, EUR=2, GBP=4, JPY=8, AUD=16, CHF=32, CAD=64, NZD=128). NULL or 0 for all stocks, crypto, commodities, indices. Only used in legacy forex calculations. (Tier 1 - Dictionary.Currency upstream wiki) |
| 6 | EEAStockExchange | bit | NO | Whether this instrument is listed on a European Economic Area exchange, requiring KID documents under MiFID II PRIIPs regulation. 1=EEA-listed (~216 instruments), 0=not EEA-listed. Affects instrument availability for retail EU users. (Tier 1 - Dictionary.Currency upstream wiki) |
| 7 | ISINCode | varchar(25) | YES | International Securities Identification Number (12-char: 2-char country + 9-char ticker + check digit). Available for stocks and ETFs. NULL for forex, commodities, crypto, and indices. Used for regulatory reporting and cross-system integration. (Tier 1 - Dictionary.Currency upstream wiki) |
| 8 | CurrencySymbol | nchar(5) | YES | Display symbol for the instrument (e.g., "$" for USD, "€" for EUR, "£" for GBP, "₿" for BTC). NULL for most stocks and commodities. nchar type supports Unicode symbols. (Tier 2 - SP passthrough; live data confirms) |
| 9 | InterestRateID | int | YES | FK to an interest rate configuration for this instrument. Used for overnight financing rates on leveraged positions. NULL for most instruments. (Tier 2 - SP passthrough; live data confirms for major forex) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CurrencyID | etoro.Dictionary.Currency | CurrencyID | passthrough |
| CurrencyTypeID | etoro.Dictionary.Currency | CurrencyTypeID | passthrough |
| Name | etoro.Dictionary.Currency | Name | passthrough |
| Abbreviation | etoro.Dictionary.Currency | Abbreviation | passthrough |
| Mask | etoro.Dictionary.Currency | Mask | passthrough |
| EEAStockExchange | etoro.Dictionary.Currency | EEAStockExchange | passthrough |
| ISINCode | etoro.Dictionary.Currency | ISINCode | passthrough |
| CurrencySymbol | etoro.Dictionary.Currency | CurrencySymbol | passthrough |
| InterestRateID | etoro.Dictionary.Currency | InterestRateID | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.Currency
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_Currency (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_Currency (15.7K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Currency | Master instrument registry. All 6 asset classes. Audit-triggered with History.AuditHistory in production. |
| Staging | DWH_staging.etoro_Dictionary_Currency | Raw staging. Same column structure. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. All 9 columns passthrough. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_Currency | Final DWH instrument dimension (15.7K rows) |

**Note**: The upstream production table has audit triggers (INSERT/UPDATE/DELETE -> History.AuditHistory). DWH does not replicate this audit trail.

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CurrencyTypeID | DWH_dbo.Dim_CurrencyType (if exists) | Asset class classification. Implicit FK. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| All DWH trading fact tables | CurrencyID | Virtually every trade, position, and cost fact references CurrencyID for instrument identification. |
| DWH_dbo.Dim_Country | MarketingRegionID via DefaultCurrencyID | Country default currency references CurrencyID in production (DefaultCurrencyID dropped from DWH Dim_Country). |

---

## 7. Sample Queries

### 7.1 Instruments by asset class
```sql
SELECT CurrencyTypeID, COUNT(*) AS InstrumentCount
FROM [DWH_dbo].[Dim_Currency]
WHERE CurrencyID > 0
GROUP BY CurrencyTypeID
ORDER BY InstrumentCount DESC;
```

### 7.2 Find an instrument by ticker
```sql
SELECT CurrencyID, Name, Abbreviation, CurrencyTypeID, ISINCode
FROM [DWH_dbo].[Dim_Currency]
WHERE Abbreviation = 'AAPL.US';
```

### 7.3 EEA-listed instruments
```sql
SELECT CurrencyID, Abbreviation, Name, ISINCode
FROM [DWH_dbo].[Dim_Currency]
WHERE EEAStockExchange = 1
ORDER BY Abbreviation;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md`.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (4 stars) | Phases: 9/14 (no Atlassian)*
*Tiers: 7 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Currency | Type: Table | Production Source: etoro.Dictionary.Currency*


### Upstream `DWH_dbo.Dim_CashoutStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_CashoutStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutStatus.md`

# DWH_dbo.Dim_CashoutStatus

> Partial dimension defining 4 active withdrawal (cashout) lifecycle states in the DWH - a truncated subset of the 17-state production dictionary, missing terminal, review, and reversal states not currently in the DWH staging pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.CashoutStatus` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CashoutStatus` is the DWH dimension for withdrawal request lifecycle states. In production, `Dictionary.CashoutStatus` defines 17 distinct states spanning the full cashout pipeline - from initial submission through compliance review, billing processing, provider settlement, and potential reversal. The DWH version contains only 5 rows: the 4 core workflow states (Pending, InProcess, Processed, Canceled) plus an ID=0 N/A placeholder.

The production `IsFinishedWithoutMoneyTransfer` (terminal vs. no-money states) and `IsFinalStatus` (terminal/non-terminal flag) columns are **not loaded into DWH**. DWH instead adds `DWHCashoutStatusID` (a redundant surrogate equal to `CashoutStatusID`) and `StatusID` (hardcoded to 1). This means analysts using `Dim_CashoutStatus` in DWH JOINs will fail to resolve statuses such as Rejected (7), Reversed (16), Under Review (15), or SentToProvider (10) - those IDs will return NULL.

Data flows from `etoro.Dictionary.CashoutStatus` via the Generic Pipeline (daily Override to Bronze `general.bronze_etoro_dictionary_cashoutstatus`), through `DWH_staging.etoro_Dictionary_CashoutStatus`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ID=0 N/A placeholder row is inserted separately after the main load using `@ddate` (midnight timestamp). See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md`.

---

## 2. Business Logic

### 2.1 DWH vs. Production State Coverage

**What**: The DWH dimension covers only 4 of 17 production cashout states, creating JOIN nulls for less common statuses.

**Columns Involved**: `CashoutStatusID`, `Name`

**Rules**:
- **Loaded (IDs 1-4)**: Pending, InProcess, Processed, Canceled - the main workflow states
- **ID=0 (N/A)**: DWH-only placeholder added by SP_Dictionaries; not in production
- **Missing (IDs 5-17)**: Partially Processed (5), Payment Sent (6), Rejected (7), RejectedByProvider (8), PendingByProvider (9), SentToProvider (10), SentToBilling (11), ReceivedByBilling (12), Failed (13), Pending Review (14), Under Review (15), Reversed (16), Partially Reversed (17)

**Diagram**:
```
DWH Coverage:
  [x] 0: N/A (placeholder)
  [x] 1: Pending
  [x] 2: InProcess
  [x] 3: Processed
  [x] 4: Canceled
  [ ] 5-17: Not in DWH (JOIN returns NULL)

Production Full Lifecycle (not in DWH):
  5: Partially Processed -> 6: Payment Sent
  7: Rejected (final, no money moved)
  8-12: Provider/Billing processing chain
  13: Failed -> 14: Pending Review -> 15: Under Review
  16: Reversed -> 17: Partially Reversed
```

### 2.2 DWH-Added Columns

**What**: SP_Dictionaries adds two columns not in the production source.

**Columns Involved**: `DWHCashoutStatusID`, `StatusID`

**Rules**:
- `DWHCashoutStatusID` = `CashoutStatusID` (identical value, redundant surrogate pattern used across SP_Dictionaries tables)
- `StatusID` = 1 hardcoded (active record flag; all loaded rows are active)
- `UpdateDate` and `InsertDate` = GETDATE() for rows from staging; @ddate (midnight) for ID=0 placeholder

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `CashoutStatusID`. With 5 rows, this is zero-cost to JOIN on any compute node.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Parquet at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`. 5 rows, daily Override. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode a CashoutStatusID to its name | `LEFT JOIN DWH_dbo.Dim_CashoutStatus ON CashoutStatusID` |
| Find in-progress withdrawals | `WHERE CashoutStatusID = 2` (InProcess only) |
| Find completed withdrawals | `WHERE CashoutStatusID = 3` (Processed only in DWH) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Cashout_State (planned) | ON CashoutStatusID | Decode status for each cashout event |
| DWH_dbo.Fact_BillingWithdraw (planned) | ON CashoutStatusID | Decode withdrawal status |

### 3.4 Gotchas

- **CRITICAL - Missing States**: DWH only has 5 of 17 production statuses. Use `LEFT JOIN`, never `INNER JOIN`. Fact rows with CashoutStatusID 5-17 will return NULL for Name. For full status resolution, check the upstream production wiki or hard-code status names.
- **IsFinalStatus and IsFinishedWithoutMoneyTransfer are DROPPED**: These analytically valuable flags (distinguishing terminal vs. intermediate states, and no-money-moved rejections) are not in DWH. Cannot be derived from DWH alone.
- **ID=0 is a DWH-only placeholder** - use `ISNULL(Name, 'Unknown')` for robustness when no status assigned.
- **DWHCashoutStatusID = CashoutStatusID** - these are always identical; DWHCashoutStatusID adds no value for analysts.
- **ETL freshness alert**: As of 2026-03-11, this table's UpdateDate is 7 days before the last session. Investigate SP_Dictionaries_DL_To_Synapse execution logs if data seems stale.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |
| ** | Tier 3 | `(Tier 3 - live data)` | Observed from MCP live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutStatusID | int | NO | Primary key. DWH values: 0=N/A (placeholder), 1=Pending, 2=InProcess, 3=Processed, 4=Canceled. Note: production has 17 states (IDs 5-17 missing from DWH). Stored in withdrawal request records and updated as requests progress. (Tier 1 - upstream wiki, Dictionary.CashoutStatus) |
| 2 | Name | varchar(50) | NO | Human-readable status label. Values: "N/A", "Pending", "InProcess", "Processed", "Canceled". UNIQUE at production level (not enforced in DWH DDL). Used in reports and monitoring. (Tier 1 - upstream wiki, Dictionary.CashoutStatus) |
| 3 | DWHCashoutStatusID | int | YES | DWH surrogate - always equal to CashoutStatusID. Set by SP_Dictionaries as `[CashoutStatusID] as [DWHCashoutStatusID]`. No analytical value; redundant pattern used for consistency across DWH dictionary tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Active record indicator, hardcoded to 1 for all rows (including ID=0 placeholder). Mirrors the StatusID=1 convention used across SP_Dictionaries-loaded tables. Not sourced from production Dictionary.CashoutStatus. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() for rows loaded from staging (IDs 1-4); @ddate (midnight, CAST(GETDATE() AS DATE)) for the ID=0 N/A placeholder. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL insert timestamp. GETDATE() for staging rows; @ddate (midnight) for the ID=0 placeholder. Same value as UpdateDate (full reload on each run). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutStatusID | etoro.Dictionary.CashoutStatus | CashoutStatusID | Passthrough |
| Name | etoro.Dictionary.CashoutStatus | Name | Passthrough |
| DWHCashoutStatusID | etoro.Dictionary.CashoutStatus | CashoutStatusID | Rename + same value |
| StatusID | (ETL-computed) | - | Hardcoded 1 |
| UpdateDate | (ETL-computed) | - | GETDATE() at load |
| InsertDate | (ETL-computed) | - | GETDATE() at load |

Dropped production columns not loaded into DWH: `IsFinishedWithoutMoneyTransfer`, `IsFinalStatus`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutStatus (17 rows in production)
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_dictionary_cashoutstatus)
  -> DWH_staging.etoro_Dictionary_CashoutStatus (4 rows - IDs 1-4 only)
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, then INSERT ID=0 placeholder)
  -> DWH_dbo.Dim_CashoutStatus (5 rows: 0-4)
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CashoutStatus | Production 17-state lifecycle table |
| Lake | Bronze/etoro/Dictionary/CashoutStatus/ | Daily Override, but staging has only IDs 1-4 |
| Staging | DWH_staging.etoro_Dictionary_CashoutStatus | 4 rows: Pending, InProcess, Processed, Canceled |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 397-413, 1663-1678) | TRUNCATE + INSERT from staging + INSERT ID=0 placeholder |
| Target | DWH_dbo.Dim_CashoutStatus | 5 rows: IDs 0-4 |

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Cashout_State (planned) | CashoutStatusID | Cashout pipeline event table - JOIN for status name |
| DWH_dbo.Fact_BillingWithdraw (planned) | CashoutStatusID | Withdrawal fact - JOIN for status name |
| Production: Billing cashout tables | CashoutStatusID | Tracks withdrawal status in production pipeline |

Note: No DWH_dbo SPs or Views currently JOIN this table (SSDT grep returned no matches).

---

## 7. Sample Queries

### 7.1 List all DWH cashout statuses
```sql
SELECT  CashoutStatusID,
        Name
FROM    [DWH_dbo].[Dim_CashoutStatus]
ORDER BY CashoutStatusID;
```

### 7.2 Decode status with NULL-safe JOIN (handles missing statuses)
```sql
SELECT  f.CashoutID,
        f.CID,
        ISNULL(s.Name, 'Status ' + CAST(f.CashoutStatusID AS varchar)) AS StatusName
FROM    [DWH_dbo].[Fact_Cashout_State] f
LEFT JOIN [DWH_dbo].[Dim_CashoutStatus] s
        ON f.CashoutStatusID = s.CashoutStatusID;
```

### 7.3 Count cashouts by available status labels
```sql
SELECT  ISNULL(s.Name, 'Unknown (' + CAST(f.CashoutStatusID AS varchar) + ')') AS Status,
        COUNT(*) AS CashoutCount
FROM    [DWH_dbo].[Fact_Cashout_State] f
LEFT JOIN [DWH_dbo].[Dim_CashoutStatus] s
        ON f.CashoutStatusID = s.CashoutStatusID
GROUP BY ISNULL(s.Name, 'Unknown (' + CAST(f.CashoutStatusID AS varchar) + ')')
ORDER BY CashoutCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (Dictionary.CashoutStatus, quality 8.6/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 8.7/10 (★★★★☆) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CashoutStatus | Type: Table | Production Source: etoro.Dictionary.CashoutStatus*


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


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_H_PaymentSent_Results`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_PaymentSent_Results.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_H_PaymentSent_Results] AS  
  
/********************************************************************************************  
Author:      Pavlina Masuora  
Date:        30-09-2020  
Description: Cashouts not Processed (Payment Sent)  
   
**************************  
** Change History  
**************************  
Date         Author       Description    
----------    ----------   ------------------------------------  
Adi Ferber   14.3.2024  	remove the hour condition 
   
*********************************************************************************************/  

PRINT 'its time'  
 
IF OBJECT_ID('tempdb..#LastUpdatedDate') IS NOT NULL 
DROP TABLE #LastUpdatedDate
CREATE TABLE #LastUpdatedDate  
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
Select 
w.WithdrawID,
a.LastUpdatedDate  
From [BI_DB_dbo].[External_etoro_History_vWithdrawToFundingAction]  w 
inner join  (  
select w.WithdrawID, MAX (w.ModificationDate) as LastUpdatedDate   
from [BI_DB_dbo].[External_etoro_History_vWithdrawToFundingAction] w group by WithdrawID) a   
on a.WithdrawID=w.WithdrawID and a.LastUpdatedDate=w.ModificationDate  
Where w.CashoutStatusID = 6  
and w.[ModificationDate]>=dateadd(week,-4,getdate())   
 
IF OBJECT_ID('tempdb..#cashouts') IS NOT NULL 
DROP TABLE #cashouts
CREATE TABLE #cashouts  
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
select  
 distinct fbd.[CID],  
 fbd.[WithdrawID],  
 wtf.ID as [WithdrawProcessingID],  
 CURR1.[Abbreviation] as Currency,  
 wtf.[Amount] as Amount$Withdraw,  
 wtf.[FundingID],  
 cs.Name as CashoutStatus_Funding,  
 depo.Name Provider,  
 dr.Name as Regulation  
FROM   BI_DB_dbo.External_etoro_Billing_Withdraw fbd  
join  [BI_DB_dbo].[External_etoro_Billing_vWithdrawToFunding] wtf on wtf.WithdrawID=fbd.WithdrawID  
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbd.CID  
left JOIN  DWH_dbo.Dim_Currency CURR1 ON CURR1.CurrencyID=wtf.[ProcessCurrencyID]  
left JOIN  DWH_dbo.Dim_CashoutStatus cs on cs.CashoutStatusID=wtf.[CashoutStatusID]  
left join  [BI_DB_dbo].[External_etoro_Billing_Funding_Datafactory] Funding on wtf.FundingID=Funding.FundingID  
left JOIN DWH_dbo.Dim_FundingType ft on ft.[FundingTypeID]=Funding.[FundingTypeID]  
left join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID  
left join  [BI_DB_dbo].[External_etoro_Billing_Depot] depo on depo.DepotID =wtf.DepotID  
WHERE   
fbd.[ModificationDate]>=dateadd(week,-4,getdate())   
and Funding.[FundingTypeID]=2 -- WIRES  
and wtf.[ProcessCurrencyID] in (  
1, --USD  
2, --EUR  
3, --GBP  
5,  --AUD  
7 -- CAD  
)

  
IF OBJECT_ID('tempdb..#final') IS NOT NULL 
DROP TABLE #final
CREATE TABLE #final  
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS  
SELECT   
 CID,  
 Regulation,   
 Currency,  
 Amount$Withdraw,  
 cast (getdate()-lu.LastUpdatedDate as int) as DaysInPaymentSentStatus,  
 lu.LastUpdatedDate as ModificationDate,  
 c.WithdrawID,  
 WithdrawProcessingID,  
 FundingID,  
 Provider  
FROM #cashouts c  
join #LastUpdatedDate lu on lu.WithdrawID=c.WithdrawID   
where CashoutStatus_Funding in ('Payment Sent')  
and   
(  
(Currency in ('USD','EUR')  AND getdate()-lu.LastUpdatedDate>=1 )  
OR  
(getdate()-lu.LastUpdatedDate>2 and Regulation in ('CySEC') AND Currency in ('AUD'))  
OR  
(getdate()-lu.LastUpdatedDate>1 and Regulation NOT in ('CySEC') AND Currency in ('AUD'))  
OR  
(Currency in ('GBP') AND getdate()-lu.LastUpdatedDate>=1)  
)  
  
Truncate table   [BI_DB_dbo].[BI_DB_PaymentSent_Results]   
  
INSERT INTO [BI_DB_dbo].[BI_DB_PaymentSent_Results]  
(  
[CID],  
[Regulation],   
[Currency],  
[Amount$Withdraw],  
[DaysInPaymentSentStatus],  
[ModificationDate],  
[WithdrawID],  
[WithdrawProcessingID],  
[FundingID],  
[Provider],  
[UpdateDate]  
)  
  
select  
[CID],  
[Regulation],   
[Currency],  
[Amount$Withdraw],  
[DaysInPaymentSentStatus],  
[ModificationDate],  
[WithdrawID],  
[WithdrawProcessingID],  
[FundingID],  
[Provider],  
getdate() as UpdateDate  
from #final  

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_H_PaymentSent_Results` | synapse_sp | BI_DB_dbo | SP_H_PaymentSent_Results | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_PaymentSent_Results.sql` |
| `BI_DB_dbo.External_etoro_History_vWithdrawToFundingAction` | unresolved | BI_DB_dbo | External_etoro_History_vWithdrawToFundingAction | `—` |
| `BI_DB_dbo.External_etoro_Billing_Withdraw` | unresolved | BI_DB_dbo | External_etoro_Billing_Withdraw | `—` |
| `BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding` | unresolved | BI_DB_dbo | External_etoro_Billing_vWithdrawToFunding | `—` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Currency` | synapse | DWH_dbo | Dim_Currency | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `DWH_dbo.Dim_CashoutStatus` | synapse | DWH_dbo | Dim_CashoutStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutStatus.md` |
| `BI_DB_dbo.External_etoro_Billing_Funding_Datafactory` | unresolved | BI_DB_dbo | External_etoro_Billing_Funding_Datafactory | `—` |
| `DWH_dbo.Dim_FundingType` | synapse | DWH_dbo | Dim_FundingType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `BI_DB_dbo.External_etoro_Billing_Depot` | unresolved | BI_DB_dbo | External_etoro_Billing_Depot | `—` |
