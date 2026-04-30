# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_PI_Positions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_PI_Positions.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_PI_Positions]
(
	[PositionID] [bigint] NULL,
	[CID] [int] NULL,
	[InstrumentID] [int] NOT NULL,
	[Leverage] [int] NOT NULL,
	[Amount] [money] NOT NULL,
	[IsBuy] [bit] NOT NULL,
	[OpenOccurred] [datetime] NOT NULL,
	[CloseOccurred] [datetime] NOT NULL,
	[ParentPositionID] [bigint] NULL,
	[OrigParentPositionID] [bigint] NULL,
	[MirrorID] [int] NULL,
	[OpenDateID] [int] NOT NULL,
	[CloseDateID] [int] NULL,
	[Volume] [int] NULL,
	[FullCommissionOnCloseOrig] [money] NULL,
	[IsSettled] [int] NULL,
	[FullCommissionByUnits] [decimal](38, 6) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[PositionID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 16 upstream wiki(s). Read EACH one in full.


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

### Upstream `DWH_dbo.Dim_GuruStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_GuruStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md`

# DWH_dbo.Dim_GuruStatus

> Popular Investor (Guru) status dimension - maps integer codes to eToro Popular Investor program tier labels, from "No" (not enrolled) through Cadet, Rising Star, Champion, Elite, and Elite Pro, plus Removed and Rejected states.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.GuruStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (GuruStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_GuruStatus` is a 9-row dictionary classifying eToro customers in the **Popular Investor (PI) program** (internally called "Guru"). The PI program allows experienced traders to earn income by being copied; status reflects their tier and program standing.

The status ladder (active tiers):
- 0 = No: Customer is not enrolled in the Popular Investor program
- 1 = Certified: Entry-level PI certification
- 2 = Cadet: First active tier of the PI program
- 3 = Rising Star: Second tier - growing following
- 4 = Champion: Third tier
- 5 = Elite: Fourth tier - top performers
- 6 = Elite Pro: Highest active tier - professional Popular Investors

Negative states:
- 7 = Removed: Previously enrolled, now removed from the program
- 8 = Rejected: Applied but rejected from the program

**GuruStatusID=0 (No)** serves as both the "not enrolled" value and the null-safe join sentinel: SP_Dim_Customer uses `ISNULL(GuruStatusID, 0)` to coerce NULLs to 0.

The data originates from `etoro.Dictionary.GuruStatus` via `DWH_staging.etoro_Dictionary_GuruStatus`. ETL: TRUNCATE + INSERT, `Name` renamed to `GuruStatusName`.

Consumers: `Dim_Customer` (each customer's current PI status), `Fact_SnapshotCustomer` (daily PI status snapshot), `Fact_CustomerAction_DL_To_Synapse` (PI status at action time).

---

## 2. Business Logic

### 2.1 Popular Investor Tier Ladder

**What**: Active PI statuses represent a progression from entry-level to elite.

**Columns Involved**: `GuruStatusID`, `GuruStatusName`

**Rules**:
```
Tier progression (active):
  No (0) -> Certified (1) -> Cadet (2) -> Rising Star (3)
         -> Champion (4) -> Elite (5) -> Elite Pro (6)

Negative states (off-ladder):
  Removed (7): was in program, exited
  Rejected (8): applied, not accepted
```

**For analysis**: GuruStatusID > 0 AND < 7 = currently active in PI program. GuruStatusID = 0 = regular customer.

### 2.2 Null-Sentinel Pattern

**What**: GuruStatusID=0 (No) absorbs NULL values from Dim_Customer.

**Columns Involved**: `GuruStatusID`

**Rules**:
- SP_Dim_Customer: `ISNULL(GuruStatusID, 0) AS GuruStatusID` (customers with no PI enrollment get ID 0)
- SP_Dim_Customer change detection: `OR ISNULL(dc.GuruStatusID, 0) <> ISNULL(a.GuruStatusID, 0)`
- Meaning: NULL and 0 are semantically equivalent (not in PI program)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (9 rows - appropriate). CLUSTERED INDEX on GuruStatusID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 9 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode GuruStatusID to name | `LEFT JOIN DWH_dbo.Dim_GuruStatus ON GuruStatusID` |
| Find active Popular Investors | `WHERE GuruStatusID BETWEEN 1 AND 6` |
| Exclude regular customers | `WHERE GuruStatusID > 0 AND GuruStatusID < 7` |
| Count customers by PI tier | `GROUP BY GuruStatusName ORDER BY GuruStatusID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GuruStatusID | Customer's current Popular Investor status |
| DWH_dbo.Fact_SnapshotCustomer | ON GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | ON GuruStatusID | PI status at time of action |

### 3.4 Gotchas

- **ID=0 is NOT null**: GuruStatusID=0 means "No" (not in PI program). It is the semantic null sentinel. Do not filter it out when showing all customers - it represents the majority.
- **Active PI filter**: To find active Popular Investors, use `GuruStatusID BETWEEN 1 AND 6`. IDs 7 (Removed) and 8 (Rejected) are ex-PI or rejected applicants and should be excluded from "active PI" counts.
- **Tiers imply rank**: GuruStatusID 1-6 form a meaningful rank ordering (lower = less established). Use ORDER BY GuruStatusID for tier comparisons.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| **** | Tier 1 | Upstream Dictionary wiki (DB_Schema), verbatim |
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GuruStatusID | int | NO | Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. (Tier 1 — Dictionary.GuruStatus) |
| 2 | GuruStatusName | varchar(50) | NO | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — Dictionary.GuruStatus) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GuruStatusID | etoro.Dictionary.GuruStatus | GuruStatusID | passthrough |
| GuruStatusName | etoro.Dictionary.GuruStatus | Name | rename: Name -> GuruStatusName |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.GuruStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_GuruStatus -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 718) -> DWH_dbo.Dim_GuruStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.GuruStatus | Guru/PI status dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/GuruStatus/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_GuruStatus | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Name -> GuruStatusName rename. UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_GuruStatus | 9-row REPLICATE/CLUSTERED PI status dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | GuruStatusID | Customer's current Popular Investor tier |
| DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | GuruStatusID | PI status at time of customer action |

---

## 7. Sample Queries

### 7.1 All Guru status values

```sql
SELECT GuruStatusID, GuruStatusName
FROM DWH_dbo.Dim_GuruStatus
ORDER BY GuruStatusID
```

### 7.2 Count active Popular Investors by tier

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
WHERE dc.GuruStatusID BETWEEN 1 AND 6
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

### 7.3 PI tier distribution across all customers

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount,
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS Pct
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.Dim_GuruStatus | Type: Table | Production Source: etoro.Dictionary.GuruStatus*


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


### Upstream `BI_DB_dbo.BI_DB_PI_GainDaily` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PI_GainDaily`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PI_GainDaily.md`

# BI_DB_dbo.BI_DB_PI_GainDaily

> ~6.9M-row PI-specific shadow cache of DWH_GainDaily storing multi-horizon compound portfolio returns (daily, weekly, monthly, quarterly, half-yearly, yearly, MTD, YTD, QTD) for every active Popular Investor and CopyFund account, covering Jan 2013 to Apr 2024. Maintained incrementally by SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 3.1-3.2) to avoid re-scanning the 6.25B-row DWH_GainDaily during dashboard computation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 3.1, 3.2) from DWH_GainDaily |
| **Refresh** | Daily — DELETE WHERE @yesterday=Date + INSERT. New PIs backfilled with full history on first appearance. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_GainDaily` is a filtered shadow cache of `DWH_GainDaily` containing only rows for **active Popular Investors (PIs)** and **CopyFund accounts**. It exists solely to avoid re-scanning the massive 6.25B-row `DWH_GainDaily` table during the daily PI Dashboard computation.

The table holds ~6.9M rows spanning Jan 2013 to Apr 2024, with ~3,400-4,400 distinct CIDs per year at peak. All 9 gain columns are **direct passthroughs** from `DWH_GainDaily` — no transformation is applied. The only difference from the source is the population filter: only customers who are currently PIs (GuruStatusID IN 2,3,4,5,6 AND IsValidCustomer=1) or CopyFund accounts (AccountTypeID=9) are included.

**ETL pattern**: The SP has two insertion paths:
1. **New PI backfill** (section 3.1): When a customer first enters the PI population, ALL their historical gain data from `DWH_GainDaily` is copied in. This uses a cursor-like WHILE loop iterating by CID.
2. **Daily incremental** (section 3.2): Each day, DELETE rows for @yesterday and INSERT yesterday's gains from `DWH_GainDaily` for the current PI population.

**Consumers** (all within the same SP):
- Section 3.3: YTD, QTD, MTD, monthly, daily gain extraction for the `#YTD` temp table
- Section 3.5: Positive months percentage calculation
- Section 3.7 (indirectly): Average yearly gain via `#AvgGain0` UNION with `BI_DB_PastYearsGain`

**Data stopped refreshing around 2024-04-14**, consistent with the parent dashboard table `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Only PI-eligible and CopyFund customers are cached.

**Columns Involved**: `CID`

**Rules**:
- Active Popular Investors: `Dim_Customer.GuruStatusID IN (2,3,4,5,6) AND Dim_Customer.IsValidCustomer = 1`
- CopyFund accounts: `Dim_Customer.AccountTypeID = 9`
- Population is determined from `#pop` temp table built in section 1 of the SP
- GuruStatusID values: 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro

### 2.2 New PI Backfill (Section 3.1)

**What**: When a customer first appears in the PI population, their full gain history is loaded.

**Columns Involved**: All columns

**Rules**:
- SP checks for PIs in `#pop` that have no existing rows in `BI_DB_PI_GainDaily`
- For each new PI, ALL historical rows from `DWH_GainDaily` where `Date < @yesterday` are inserted
- Uses a WHILE loop iterating CID by CID (descending order)
- This ensures that metrics like `Positive_Months_percent` and `Avg_Yearly_gain` have full history from day one

### 2.3 Daily Incremental Refresh (Section 3.2)

**What**: Yesterday's gain data is refreshed for the entire PI population.

**Columns Involved**: All columns

**Rules**:
- `DELETE FROM BI_DB_PI_GainDaily WHERE @yesterday = Date`
- `INSERT` from `DWH_GainDaily` joined to `#pop` on `CID = RealCID` where `@yesterday = Date`
- Idempotent: re-running the SP for the same date replaces the data cleanly

### 2.4 Gain Value Semantics

**What**: All gain values are compound portfolio returns expressed as decimal fractions.

**Columns Involved**: All Gain_* columns

**Rules**:
- Values are decimal fractions: 0.05 = 5% gain, -0.10 = 10% loss
- NULL means the interval is not available (insufficient trading history for that horizon)
- Zero-gain customers are excluded upstream by DWH_GainDaily's source filter (WHERE Gain <> 0)
- Trailing intervals: Gain_w=7 days, Gain_m=30 days, Gain_q=90 days, Gain_h=180 days, Gain_y=365 days
- To-date intervals: Gain_MTD=month-to-date, Gain_QTD=quarter-to-date, Gain_YTD=year-to-date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distributed — no co-located JOINs. CLUSTERED INDEX on (Date, CID) supports date-filtered queries and point lookups by date+CID combination. ~6.9M rows total; per-day slices are small (~3,400 rows), so single-date queries are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI's latest gains | `WHERE CID = @cid AND Date = (SELECT MAX(Date) FROM BI_DB_PI_GainDaily WHERE CID = @cid)` |
| All PI gains for a date | `WHERE Date = @date` (~3,400 rows) |
| PI's monthly gain history | `WHERE CID = @cid AND DAY(Date) = 1` (first-of-month snapshots) |
| Positive months for a PI | `WHERE CID = @cid AND DAY(Date) = 1 AND ISNULL(Gain_m, 0) > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile, country, regulation |
| BI_DB_dbo.DWH_GainDaily | CID + Date | Cross-reference with full customer gain table |
| BI_DB_dbo.BI_DB_PastYearsGain | CID | UNION for average yearly gain calculation |
| BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | CID + Date | Parent dashboard table |

### 3.4 Gotchas

- **Shadow cache, not primary data**: This table is a filtered copy of `DWH_GainDaily`. For non-PI customers, query `DWH_GainDaily` directly.
- **Data stops at 2024-04-14**: The table has not been refreshed since this date based on live data. The parent SP appears to have stopped running.
- **Gain values are decimals, not percentages**: 0.0216 = 2.16% gain. Multiply by 100 for display.
- **NULL gain columns**: NULL means the interval is not available (insufficient history), NOT 0% return. Use ISNULL only when you understand this distinction.
- **New PI backfill is per-CID cursor**: For large numbers of new PIs, the backfill can be slow (WHILE loop with individual INSERTs).
- **Population drift**: If a PI loses their status (e.g., demoted to GuruStatusID=1 or 7), their historical rows remain in the table but no new rows are added. The table does not purge demoted PIs.
- **ROUND_ROBIN distribution**: JOINs on CID with HASH(CID) tables (like DWH_GainDaily) will trigger data movement.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (DWH_GainDaily, Dim_Customer) |
| Tier 2 | SP-computed / ETL-derived |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Snapshot date for which gains were calculated. Passthrough from DWH_GainDaily. Used as DELETE+INSERT key. Part of clustered index (Date, CID). (Tier 2 — DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). (Tier 1 — Customer.CustomerStatic) |
| 3 | Gain_w | float | YES | Trailing 7-day (weekly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=7 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 4 | Gain_m | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. IntervalTypeID=106 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 5 | Gain_q | float | YES | Trailing 90-day (quarterly) compound portfolio return as a decimal. IntervalTypeID=108 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 6 | Gain_h | float | YES | Trailing 180-day (half-yearly) compound portfolio return as a decimal. IntervalTypeID=109 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 7 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 9 | Gain_MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to Date. IntervalTypeID=101 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 10 | Gain_YTD | float | YES | Year-to-date compound portfolio return as a decimal. From Jan 1 to Date. IntervalTypeID=103 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 11 | Gain_d | float | YES | Daily compound portfolio return as a decimal. Single-day gain for this Date. IntervalTypeID=1 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 12 | Gain_QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to Date. IntervalTypeID=102 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough (filtered to PI/CopyFund population) |
| Gain_w | BI_DB_dbo.DWH_GainDaily | Gain_w | Passthrough |
| Gain_m | BI_DB_dbo.DWH_GainDaily | Gain_m | Passthrough |
| Gain_q | BI_DB_dbo.DWH_GainDaily | Gain_q | Passthrough |
| Gain_h | BI_DB_dbo.DWH_GainDaily | Gain_h | Passthrough |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| Gain_MTD | BI_DB_dbo.DWH_GainDaily | Gain_MTD | Passthrough |
| Gain_YTD | BI_DB_dbo.DWH_GainDaily | Gain_YTD | Passthrough |
| Gain_d | BI_DB_dbo.DWH_GainDaily | Gain_d | Passthrough |
| Gain_QTD | BI_DB_dbo.DWH_GainDaily | Gain_QTD | Passthrough |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Compound gains by IntervalTypeID
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
  |-- SP_DWH_GainDaily (daily pivot)
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, all customers)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide sections 3.1 + 3.2
  |   Population filter: #pop (GuruStatusID IN 2-6 + AccountTypeID=9)
  |   Section 3.1: New PI backfill (WHILE loop, full history)
  |   Section 3.2: Daily DELETE WHERE Date=@yesterday + INSERT
  v
BI_DB_dbo.BI_DB_PI_GainDaily (~6.9M rows, PI/CopyFund only)
  |
  |-- Same SP sections 3.3, 3.5, 3.7 (consumer)
  |   → #GainDaily → #YTD (YTD/QTD/MTD/monthly/daily gains)
  |   → #positive_months → #positive_months_percent
  |   → #AvgGain0 (UNION with BI_DB_PastYearsGain) → #AvgGain
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide
  (PI Dashboard — final output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Sections 3.3, 3.5, 3.7 | Consumed to compute YTD/MTD/QTD gains, positive months percent, and average yearly gain for the PI Dashboard |

---

## 7. Sample Queries

### 7.1 PI gain snapshot for the latest date

```sql
SELECT CID, Gain_d, Gain_w, Gain_m, Gain_YTD, Gain_y
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE [Date] = (SELECT MAX([Date]) FROM [BI_DB_dbo].[BI_DB_PI_GainDaily])
ORDER BY Gain_YTD DESC;
```

### 7.2 Positive months percentage for a PI

```sql
SELECT CID,
       COUNT(CASE WHEN ISNULL(Gain_m, 0) > 0 THEN 1 END) AS Positive_Months,
       COUNT(*) AS Total_Months,
       COUNT(CASE WHEN ISNULL(Gain_m, 0) > 0 THEN 1 END) * 1.0 / COUNT(*) AS Positive_Pct
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE CID = 2990627
  AND DAY([Date]) = 1
GROUP BY CID;
```

### 7.3 YTD performance ranking across all PIs

```sql
SELECT TOP 20 CID, Gain_YTD, Gain_d, Gain_w, Gain_m
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE [Date] = '2024-04-14'
  AND Gain_YTD IS NOT NULL
ORDER BY Gain_YTD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 11 T2, 0 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_GainDaily | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 3.1-3.2 from DWH_GainDaily)*


### Upstream `BI_DB_dbo.DWH_GainDaily` — synapse
- **Resolved as**: `BI_DB_dbo.DWH_GainDaily`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\DWH_GainDaily.md`

# BI_DB_dbo.DWH_GainDaily

> 6.25B-row daily multi-horizon portfolio gain table storing compound returns (daily, weekly, monthly, quarterly, half-yearly, yearly, MTD, YTD, QTD) for every customer — pivoted from the TradeGain Ranking service's External_TradeGain_Ranking_Compound_Gain_Completed table, covering Jan 2013 to present. The largest table in BI_DB_dbo. Refreshed daily by SP_DWH_GainDaily via DELETE+INSERT by Date. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_GainDaily` from External_TradeGain_Ranking_Compound_Gain_Completed |
| **Refresh** | Daily — DELETE WHERE Date=@gain_dt + INSERT. Accumulating by date. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP (PK on Date, CID — NOT ENFORCED) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides **multi-horizon compound portfolio returns** for every eToro customer, calculated daily by the production TradeGain Ranking service. For each customer and date, it stores 9 different gain metrics covering intervals from 1 day to 1 year, plus to-date metrics (MTD, QTD, YTD).

The 6.25B rows cover daily snapshots from Jan 2013 to Apr 2026 — making this the **largest table in BI_DB_dbo**. The SP performs a simple pivot: the source (Compound_Gain_Completed) stores one row per (CID, IntervalTypeID, Gain), and the SP pivots 9 interval types into 9 columns per CID.

The TradeGain Ranking service runs externally (tracked by External_TradeGain_Ranking_Execution, ObjectID=4). The SP finds the latest completed execution for the given date and pivots its results.

Gain values represent percentage returns as decimals (e.g., 0.0216 = 2.16% gain, -0.2485 = 24.85% loss). NULL values indicate the interval is not available for that customer on that date (e.g., weekly gain may be NULL if the customer hasn't been active for a full week).

---

## 2. Business Logic

### 2.1 IntervalTypeID to Column Mapping

**What**: Pivots row-based interval gains into columnar format.
**Columns Involved**: All Gain_* columns
**Rules**:
- IntervalTypeID 1 → Gain_d (daily)
- IntervalTypeID 7 → Gain_w (weekly, trailing 7 days)
- IntervalTypeID 101 → Gain_MTD (month-to-date)
- IntervalTypeID 102 → Gain_QTD (quarter-to-date)
- IntervalTypeID 103 → Gain_YTD (year-to-date)
- IntervalTypeID 106 → Gain_m (monthly, trailing 30 days)
- IntervalTypeID 108 → Gain_q (quarterly, trailing 90 days)
- IntervalTypeID 109 → Gain_h (half-yearly, trailing 180 days)
- IntervalTypeID 110 → Gain_y (yearly, trailing 365 days)

### 2.2 Execution Selection

**What**: Only uses the latest completed execution for the given date.
**Columns Involved**: ExecutionID
**Rules**:
- Source: External_TradeGain_Ranking_Execution WHERE Completed=1 AND ObjectID=4 AND MaxDate <= @gain_dt_today
- Takes MAX(ExecutionID) from qualifying executions
- All gain rows for a CID on a date come from the same ExecutionID

### 2.3 Zero Gain Exclusion

**What**: Customers with Gain=0 for all intervals are excluded.
**Columns Involved**: All Gain_* columns
**Rules**:
- WHERE g.Gain <> 0 in source filter
- A customer with no non-zero gains on a date has no row in this table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution — co-located JOINs with other CID-distributed tables. HEAP with NOT ENFORCED PK. **6.25B rows — ALWAYS filter by Date or CID.**

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's latest gains | `WHERE CID = X AND Date = (SELECT MAX(Date) FROM DWH_GainDaily WHERE CID = X)` |
| Best performing customers today | `WHERE Date = @today ORDER BY Gain_d DESC` |
| Yearly return for all customers | `WHERE Date = @today AND Gain_y IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| BI_DB_dbo.BI_DB_MonthlyGain | CID + date alignment | Cross-reference monthly gain aggregation |

### 3.4 Gotchas

- **6.25B rows**: The LARGEST table in BI_DB_dbo. ALWAYS filter by Date. Queries without a Date filter will timeout.
- **NULL gain columns**: A NULL Gain_w doesn't mean 0% return — it means the weekly interval was not available (insufficient history). Use COALESCE only if you understand this distinction.
- **Gain values are decimals, not percentages**: 0.0216 = 2.16% gain. Multiply by 100 for display.
- **HASH(CID) distribution**: This table is uniquely HASH-distributed among BI_DB tables. JOINs on CID with this table are co-located if the other table is also HASH(CID).
- **ExecutionID**: Multiple execution IDs may exist for the same date (retries/corrections). The SP always takes the latest completed one.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 — SP_DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key. (Tier 2 — SP_DWH_GainDaily) |
| 3 | Gain_w | float | YES | Trailing 7-day (weekly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=7 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 4 | Gain_m | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. IntervalTypeID=106 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 5 | Gain_q | float | YES | Trailing 90-day (quarterly) compound portfolio return as a decimal. IntervalTypeID=108 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 6 | Gain_h | float | YES | Trailing 180-day (half-yearly) compound portfolio return as a decimal. IntervalTypeID=109 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 7 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. IntervalTypeID=110 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_DWH_GainDaily. (Tier 5 — ETL infrastructure) |
| 9 | Gain_MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to Date. IntervalTypeID=101 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 10 | Gain_YTD | float | YES | Year-to-date compound portfolio return as a decimal. From Jan 1 to Date. IntervalTypeID=103 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 11 | Gain_d | float | YES | Daily compound portfolio return as a decimal. Single-day gain for this Date. IntervalTypeID=1 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 12 | Gain_QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to Date. IntervalTypeID=102 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 13 | ExecutionID | int | YES | TradeGain Ranking service execution ID that produced these gains. Links to External_TradeGain_Ranking_Execution. Multiple executions may exist per date; SP uses the latest completed one (ObjectID=4). (Tier 2 — SP_DWH_GainDaily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | SP parameter | @gain_dt | passthrough |
| CID | TradeGain_Ranking_Compound_Gain_Completed | CID | passthrough |
| Gain_* (9 columns) | TradeGain_Ranking_Compound_Gain_Completed | Gain | pivot by IntervalTypeID |
| UpdateDate | — | — | GETDATE() |
| ExecutionID | TradeGain_Ranking_Compound_Gain_Completed | ExecutionID | passthrough (latest completed) |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Produces compound gains by IntervalTypeID
  |-- Tracked by External_TradeGain_Ranking_Execution (ObjectID=4)
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
BI_DB_dbo.External_TradeGain_Ranking_Execution
  |
  |-- SP_DWH_GainDaily @gain_dt (daily)
  |   Find latest completed ExecutionID
  |   Pivot 9 IntervalTypeIDs into 9 gain columns
  |   DELETE WHERE Date=@gain_dt + INSERT
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, accumulating daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| — | — | Likely consumed by reporting/Popular Investor leaderboards (no SSDT SP references found) |

---

## 7. Sample Queries

### 7.1 Top Performers This Week

```sql
SELECT TOP 20 CID, Gain_w, Gain_m, Gain_y
FROM BI_DB_dbo.DWH_GainDaily
WHERE Date = CAST(GETDATE()-1 AS DATE)
  AND Gain_w IS NOT NULL
ORDER BY Gain_w DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found. Context: TradeGain Ranking is a production service that calculates compound portfolio returns; data surfaces in Popular Investor leaderboards and performance dashboards.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.DWH_GainDaily | Type: Table | Production Source: SP_DWH_GainDaily (pivot from TradeGain Ranking Compound Gain)*


### Upstream `DWH_dbo.V_Dim_Date` — synapse
- **Resolved as**: `DWH_dbo.V_Dim_Date`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Dim_Date.md`

# DWH_dbo.V_Dim_Date

> Enriched date dimension view that adds ~20 dynamic temporal flags to the base Dim_Date table — IsCurrentDay, IsCurrentMonth, IsCurrentWeek, opening/closing dates, and benchmarks — all computed relative to yesterday's date.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Table** | DWH_dbo.Dim_Date |
| **Computed Columns** | ~20 dynamic CASE expressions + CalculatedWeekNumber |
| **Reference Date** | `DATEADD(DD, -1, GETDATE())` — all flags are relative to yesterday |

---

## 1. Business Meaning

`V_Dim_Date` is the primary date dimension view used by BI reports and dashboards. It wraps `Dim_Date` and adds dynamic temporal classification columns — answering questions like "Is this row's date the current day? Current month? Current quarter?" — all relative to yesterday (T-1), which is the DWH's reporting anchor date.

The view provides:
- **Period membership flags**: IsCurrentDay, IsCurrentMonth, IsCurrentQuarter, IsCurrentYear, IsCurrentWeek
- **Period boundary flags**: Opening/closing dates for previous/current year, quarter, month, and week
- **Benchmark flags**: Is8wBenchmark (same weekday within the last 8 weeks, for week-over-week comparison)
- **Week numbering**: CalculatedWeekNumber (week number since 2000-01-02), SSYearAndWeekNumber (SQL Server week format)

All computed flags return `'Yes'` or `'No'` strings. The `PartitionID` column from Dim_Date is excluded (commented out).

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateKey | int | Dim_Date.DateKey | PK. Date as YYYYMMDD integer. Clustered index key. REPLICATE distribution. (Tier 3 — DDL inference) |
| 2 | FullDate | date | Dim_Date.FullDate | Calendar date value. Reference date for all computed flags. (Tier 3 — DDL inference) |
| 3 | MonthNumberOfYear | tinyint | Dim_Date.MonthNumberOfYear | Month number (1–12). (Tier 3 — DDL inference) |
| 4 | MonthNumberOfQuarter | tinyint | Dim_Date.MonthNumberOfQuarter | Month position within the quarter (1–3). (Tier 3 — DDL inference) |
| 5 | ISOYearAndWeekNumber | char(7) | Dim_Date.ISOYearAndWeekNumber | ISO year + week (e.g., '2026W13'). (Tier 3 — DDL inference) |
| 6 | ISOWeekNumberOfYear | tinyint | Dim_Date.ISOWeekNumberOfYear | ISO week number (1–53). (Tier 3 — DDL inference) |
| 7 | SSWeekNumberOfYear | tinyint | Dim_Date.SSWeekNumberOfYear | SQL Server week number (DATEPART WEEK). (Tier 3 — DDL inference) |
| 8 | ISOWeekNumberOfQuarter_454_Pattern | tinyint | Dim_Date.ISOWeekNumberOfQuarter_454_Pattern | ISO week within quarter using 4-5-4 retail calendar pattern. (Tier 3 — DDL inference) |
| 9 | SSWeekNumberOfQuarter_454_Pattern | tinyint | Dim_Date.SSWeekNumberOfQuarter_454_Pattern | SQL Server week within quarter using 4-5-4 retail pattern. (Tier 3 — DDL inference) |
| 10 | SSWeekNumberOfMonth | tinyint | Dim_Date.SSWeekNumberOfMonth | Week number within the month (SQL Server). (Tier 3 — DDL inference) |
| 11 | DayNumberOfYear | smallint | Dim_Date.DayNumberOfYear | Day of year (1–366). (Tier 3 — DDL inference) |
| 12 | DaysSince1900 | int | Dim_Date.DaysSince1900 | Days elapsed since 1900-01-01. Useful for date arithmetic. (Tier 3 — DDL inference) |
| 13 | DayNumberOfFiscalYear | smallint | Dim_Date.DayNumberOfFiscalYear | Day of fiscal year (1–366). Fiscal year starts July 1. (Tier 3 — DDL inference) |
| 14 | DayNumberOfQuarter | smallint | Dim_Date.DayNumberOfQuarter | Day position within the quarter (1–92). (Tier 3 — DDL inference) |
| 15 | DayNumberOfMonth | tinyint | Dim_Date.DayNumberOfMonth | Day of month (1–31). (Tier 3 — DDL inference) |
| 16 | DayNumberOfWeek_Sun_Start | tinyint | Dim_Date.DayNumberOfWeek_Sun_Start | Day of week (1=Sunday, 7=Saturday). (Tier 3 — DDL inference) |
| 17 | MonthName | varchar(10) | Dim_Date.MonthName | Full month name (e.g., 'January'). (Tier 3 — DDL inference) |
| 18 | MonthNameAbbreviation | char(3) | Dim_Date.MonthNameAbbreviation | 3-letter month abbreviation (e.g., 'Jan'). (Tier 3 — DDL inference) |
| 19 | DayName | varchar(10) | Dim_Date.DayName | Full day name (e.g., 'Monday'). (Tier 3 — DDL inference) |
| 20 | DayNameAbbreviation | char(3) | Dim_Date.DayNameAbbreviation | 3-letter day abbreviation (e.g., 'Mon'). (Tier 3 — DDL inference) |
| 21 | CalendarYear | smallint | Dim_Date.CalendarYear | Calendar year (e.g., 2026). (Tier 3 — DDL inference) |
| 22 | CalendarYearMonth | char(7) | Dim_Date.CalendarYearMonth | Year-month string (e.g., '2026-03'). (Tier 3 — DDL inference) |
| 23 | CalendarYearQtr | char(7) | Dim_Date.CalendarYearQtr | Year-quarter string (e.g., '2026-Q1'). (Tier 3 — DDL inference) |
| 24 | CalendarSemester | tinyint | Dim_Date.CalendarSemester | Half-year (1 or 2). (Tier 3 — DDL inference) |
| 25 | CalendarQuarter | tinyint | Dim_Date.CalendarQuarter | Calendar quarter (1–4). (Tier 3 — DDL inference) |
| 26 | FiscalYear | smallint | Dim_Date.FiscalYear | Fiscal year. Starts July 1. (Tier 3 — DDL inference) |
| 27 | FiscalMonth | tinyint | Dim_Date.FiscalMonth | Fiscal month (1–12, starting from fiscal year start). (Tier 3 — DDL inference) |
| 28 | FiscalQuarter | tinyint | Dim_Date.FiscalQuarter | Fiscal quarter (1–4). (Tier 3 — DDL inference) |
| 29 | FiscalYearMonth | char(7) | Dim_Date.FiscalYearMonth | Fiscal year-month string. (Tier 3 — DDL inference) |
| 30 | FiscalYearQtr | char(8) | Dim_Date.FiscalYearQtr | Fiscal year-quarter string. (Tier 3 — DDL inference) |
| 31 | QuarterNumber | int | Dim_Date.QuarterNumber | Absolute quarter number (monotonically increasing across years). (Tier 3 — DDL inference) |
| 32 | YYYYMMDD | char(8) | Dim_Date.YYYYMMDD | Date formatted as 'YYYYMMDD' string. (Tier 3 — DDL inference) |
| 33 | MM/DD/YYYY | char(10) | Dim_Date.MM/DD/YYYY | Date formatted as 'MM/DD/YYYY'. US format. (Tier 3 — DDL inference) |
| 34 | YYYY/MM/DD | char(10) | Dim_Date.YYYY/MM/DD | Date formatted as 'YYYY/MM/DD'. (Tier 3 — DDL inference) |
| 35 | YYYY-MM-DD | char(10) | Dim_Date.YYYY-MM-DD | Date formatted as 'YYYY-MM-DD'. ISO 8601. (Tier 3 — DDL inference) |
| 36 | MonDDYYYY | char(11) | Dim_Date.MonDDYYYY | Date formatted as 'Mon DD YYYY' (e.g., 'Mar 28 2026'). (Tier 3 — DDL inference) |
| 37 | IsLastDayOfMonth | char(1) | Dim_Date.IsLastDayOfMonth | 'Y' if date is the last day of its month, 'N' otherwise. (Tier 3 — DDL inference) |
| 38 | IsWeekday | char(1) | Dim_Date.IsWeekday | 'Y' if Monday–Friday, 'N' otherwise. (Tier 3 — DDL inference) |
| 39 | IsWeekend | char(1) | Dim_Date.IsWeekend | 'Y' if Saturday–Sunday, 'N' otherwise. (Tier 3 — DDL inference) |
| 40 | IsWorkday | char(1) | Dim_Date.IsWorkday | 'Y' if working day (weekday and not holiday). DEFAULT 'N'. (Tier 3 — DDL inference) |
| 41 | IsFederalHoliday | char(1) | Dim_Date.IsFederalHoliday | 'Y' if federal holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 42 | IsBankHoliday | char(1) | Dim_Date.IsBankHoliday | 'Y' if bank holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 43 | IsCompanyHoliday | char(1) | Dim_Date.IsCompanyHoliday | 'Y' if company holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 44 | CalculatedWeekNumber | int | Computed | `DATEDIFF(dd, '2000-01-02', FullDate) / 7` — sequential week number since 2000-01-02 (Monday-aligned). (Tier 2 — view DDL) |
| 45 | IsCurrentDay | varchar | Computed | `'Yes'` when FullDate equals yesterday (T-1). (Tier 2 — view DDL) |
| 46 | IsCurrentMonth | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar month. (Tier 2 — view DDL) |
| 47 | IsCurrentQuarter | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar quarter. (Tier 2 — view DDL) |
| 48 | IsCurrentYear | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar year. (Tier 2 — view DDL) |
| 49 | IsPreviousYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of the year before yesterday's year. (Tier 2 — view DDL) |
| 50 | IsPreviousQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 51 | IsPreviousMonthClosingDate | varchar | Computed | `'Yes'` for the last day of the month before yesterday's month. (Tier 2 — view DDL) |
| 52 | IsPreviousYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of the year before yesterday's year. (Tier 2 — view DDL) |
| 53 | IsPreviousQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 54 | IsPreviousMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of the month before yesterday's month. (Tier 2 — view DDL) |
| 55 | SSYearAndWeekNumber | varchar | Computed | SQL Server-style year+week string, e.g. `2026W12`. Zero-padded week number. (Tier 2 — view DDL) |
| 56 | IsCurrentWeek | varchar | Computed | `'Yes'` when FullDate falls in yesterday's ISO-style week (Sunday to Saturday). (Tier 2 — view DDL) |
| 57 | IsPreviousWeekClosingDate | varchar | Computed | `'Yes'` for the last day of the week before yesterday's week. (Tier 2 — view DDL) |
| 58 | IsPreviousWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of the week before yesterday's week. (Tier 2 — view DDL) |
| 59 | IscURRENTWeekClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current week. Note: column name has mixed-case typo in source DDL. (Tier 2 — view DDL) |
| 60 | IsCurrentWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current week. (Tier 2 — view DDL) |
| 61 | Is8wBenchmark | varchar | Computed | `'Yes'` for same-weekday dates within the last 8 weeks before yesterday — used for week-over-week benchmarking. (Tier 2 — view DDL) |
| 62 | IsCurrentYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of yesterday's year. (Tier 2 — view DDL) |
| 63 | IsCurrentQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current quarter. (Tier 2 — view DDL) |
| 64 | IsCurrentMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current month. (Tier 2 — view DDL) |
| 65 | IsCurrentYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of yesterday's year. (Tier 2 — view DDL) |
| 66 | IsCurrentQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current quarter. (Tier 2 — view DDL) |
| 67 | IsCurrentMonthClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current month. (Tier 2 — view DDL) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Date | Base table (1:1) | Source | Inbound |

---

## 4. ETL & Data Pipeline

No ETL — this is a computed view. All temporal flags are recalculated dynamically at query time relative to `GETDATE()`.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| BI reports and dashboards | Primary date dimension interface — filters on IsCurrentDay, IsCurrentMonth, etc. |
| SP_Fact_Guru_Copiers | Uses V_Dim_Date / V_M2M_Date_DateRange for date range handling |
| SP_Fact_CustomerUnrealized_PnL | Date dimension access |

---

## 6. Business Logic & Patterns

### Key Design Decisions

- **T-1 anchor**: All "current" flags are relative to yesterday (`DATEADD(DD, -1, GETDATE())`), not today. This aligns with DWH convention: the DWH processes yesterday's data overnight, so "current" means "the most recently processed business day."
- **String flags**: All computed columns return `'Yes'`/`'No'` strings (not BIT). This is likely for Tableau/SSRS compatibility.
- **PartitionID excluded**: The base Dim_Date.PartitionID column is commented out in this view.
- **Column name typo**: `IscURRENTWeekClosingDate` has mixed casing — a known cosmetic issue in the DDL.

---

## 7. Query Advisory

### Recommended Patterns

```sql
-- Get yesterday's row with all temporal context
SELECT * FROM [DWH_dbo].[V_Dim_Date] WHERE IsCurrentDay = 'Yes';

-- Get all dates in the current month
SELECT DateKey, FullDate FROM [DWH_dbo].[V_Dim_Date] WHERE IsCurrentMonth = 'Yes';

-- Week-over-week benchmark dates
SELECT DateKey, FullDate, DayName FROM [DWH_dbo].[V_Dim_Date] WHERE Is8wBenchmark = 'Yes';
```

### Performance Notes

- View is computed at query time — every query re-evaluates all 20+ CASE expressions
- For large JOINs, consider filtering on `Dim_Date.DateKey` directly and computing temporal flags in your query

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH Dim_Date, Dim_Range and View V_M2M_Date_DateRange](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952666154) | Confluence documentation covering the date dimension family |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | References Dim_Date as part of the core DWH table catalog |
| [DWH Usage](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12788367785) | Service-level join patterns using Dim_Date with facts (e.g. Fact_SnapshotEquity, V_M2M_Date_DateRange, DateKey) |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900) | Daily snapshot / partition behavior for DWH reporting |

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 8/14 | Column expansion: 67 cols documented individually (43 static + 24 computed)*
*Tiers: 0 T1, 24 T2, 43 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Date | Type: View | Base Table: DWH_dbo.Dim_Date (no upstream wiki — static cols Tier 3 DDL inference)*


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


### Upstream `BI_DB_dbo.BI_DB_PastYearsGain` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PastYearsGain`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PastYearsGain.md`

# BI_DB_dbo.BI_DB_PastYearsGain

> ~20.2M-row historical yearly gain archive storing the trailing 365-day compound portfolio return (Gain_y) for every customer on Jan 1 of each year, covering 2007 through 2023. Used by the PI Dashboard SP to compute average yearly performance across all completed calendar years. Append-only, refreshed annually via SP_PI_Dashboard_COPYDATA_RuningSideBySide.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (section 3.4) from DWH_GainDaily |
| **Refresh** | Annual — INSERT fires only when @yesterday = Jan 1 (conditional within a daily SP). Append-only, no DELETE. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PastYearsGain` is a historical archive that captures each customer's trailing 365-day compound portfolio return (Gain_y from `DWH_GainDaily`) on Jan 1 of each year. The `Year1` column stores the completed calendar year the gain covers (e.g., a row with Date=2024-01-01 has Year1=2023, representing calendar year 2023 performance).

The table is consumed by SP_PI_Dashboard_COPYDATA_RuningSideBySide (section 3.7), where it is UNIONed with the current year's YTD gain to compute `AVG(Gain_y)` — the average yearly performance across all completed years for each Popular Investor (PI). This metric appears in the PI Dashboard as `Avg_Yearly_gain`.

**Population**: All customers present in `DWH_GainDaily` on Jan 1 of each year who had a non-zero yearly gain. The table holds ~20.2M rows across 17 distinct years (Year1 2007–2023).

**Append-only pattern**: The SP conditionally inserts rows only when `@yesterday` falls on Jan 1 (determined by joining `DWH_GainDaily.Date` against `V_Dim_Date WHERE DayNumberOfYear=1`). There is no DELETE — each year's snapshot accumulates permanently.

**Historical pattern shift**: Rows for Year1 2007–2020 have Date values on Dec 1 (legacy behavior); rows for Year1 2021–2023 use Jan 1 dates (current SP logic). The Year1 formula `YEAR(Date)-1` is correct for Jan 1 dates; the Dec 1 rows predate this formula and have `Year1 = YEAR(Date)`.

---

## 2. Business Logic

### 2.1 Annual Gain Snapshot

**What**: Captures the trailing 365-day compound return from DWH_GainDaily on Jan 1 of each year.

**Columns Involved**: `Date`, `CID`, `Gain_y`, `Year1`

**Rules**:
- SP joins `DWH_GainDaily` with `V_Dim_Date WHERE DayNumberOfYear = 1` and filters `Date = @yesterday`
- Only fires when @yesterday is Jan 1 of any year
- Gain_y values are decimal fractions: 0.0914 = 9.14% gain, -0.0179 = 1.79% loss
- Year1 = `YEAR(Date) - 1` — the completed calendar year the return covers
- Zero-gain customers (Gain=0 in DWH_GainDaily) are excluded upstream by the DWH_GainDaily source filter

### 2.2 Average Yearly Gain Calculation (Consumer)

**What**: SP section 3.7 unions this table with the current YTD gain to compute lifetime average.

**Columns Involved**: `Year1`, `CID`, `Gain_y`

**Rules**:
```
#AvgGain0 = 
  SELECT Y.year, CID, Y.Gain_YTD AS Gain_y FROM #YTD Y      -- current year (YTD)
  UNION ALL
  SELECT Year1, CID, Gain_y FROM BI_DB_PastYearsGain          -- past completed years

#AvgGain = SELECT CID, AVG(Gain_y) AS Avg_Yearly_gain FROM #AvgGain0 GROUP BY CID
```
- The AVG includes both completed past years and the current partial year (as YTD)
- This produces the `Avg_Yearly_gain` column in `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distributed — no co-located JOINs. CLUSTERED INDEX on Date supports date-range scans. For ~20.2M rows, queries without a Date or Year1 filter are manageable but should still be bounded.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's yearly returns across all years | `WHERE CID = @cid ORDER BY Year1` |
| Average yearly return for a customer | `SELECT CID, AVG(Gain_y) FROM BI_DB_PastYearsGain WHERE CID = @cid GROUP BY CID` |
| All customers with >50% annual return in a given year | `WHERE Year1 = 2023 AND Gain_y > 0.5` |
| Count of customers per year | `SELECT Year1, COUNT(*) FROM BI_DB_PastYearsGain GROUP BY Year1 ORDER BY Year1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile, country, regulation |
| BI_DB_dbo.DWH_GainDaily | CID + Date | Cross-reference daily gain data for the snapshot date |

### 3.4 Gotchas

- **Gain_y is a decimal, not a percentage**: 0.0914 = 9.14% gain. Multiply by 100 for display.
- **Year1 does not always equal YEAR(Date)-1**: Legacy rows (2007–2020) have Date on Dec 1 and Year1=YEAR(Date). Only rows from 2022+ follow the current formula `Year1 = YEAR(Date) - 1`.
- **Append-only, no idempotent reload**: There is no DELETE before INSERT. If the SP runs twice on Jan 1, duplicate rows may appear. In practice this is prevented by the daily SP execution schedule.
- **No row for Year1=2020 via Jan 1**: The transition from Dec 1 to Jan 1 pattern means 2020's gain appears on Date=2020-12-01 (legacy) and 2021's gain appears on Date=2022-01-01. No Date=2021-01-01 row exists.
- **Latest data is Year1=2023** (Date=2024-01-01). Year1=2024 would only appear after 2025-01-01 run.
- **Not migrated to Unity Catalog**: No UC target exists for this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (DWH_GainDaily, Dim_Customer) |
| Tier 2 | SP code / ETL-computed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Jan 1 snapshot date from which the trailing yearly gain was captured. Sourced from DWH_GainDaily.Date, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1. Historical rows (2007-2020) use Dec 1 instead. Part of logical PK (Date, CID). (Tier 2 — DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID). (Tier 1 — Customer.CustomerStatic) |
| 3 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 4 | Year1 | int | YES | The completed calendar year the gain covers. ETL-computed: YEAR(Date)-1 for Jan 1 rows. E.g., Date=2024-01-01 yields Year1=2023. Historical Dec 1 rows have Year1=YEAR(Date). (Tier 2 — DWH_GainDaily) |
| 5 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough (filtered to Jan 1 via V_Dim_Date) |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough |
| Year1 | BI_DB_dbo.DWH_GainDaily | Date | ETL-computed: YEAR(Date)-1 |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Compound gains by IntervalTypeID
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
  |-- SP_DWH_GainDaily (daily pivot)
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, daily accumulating)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide section 3.4
  |   JOIN V_Dim_Date WHERE DayNumberOfYear=1 (Jan 1 filter)
  |   AND Date = @yesterday (only fires on Jan 1)
  |   Year1 = YEAR(Date)-1
  |   INSERT (append-only, no DELETE)
  v
BI_DB_dbo.BI_DB_PastYearsGain (~20.2M rows, 17 years)
  |
  |-- SP section 3.7: UNION with current YTD
  |   AVG(Gain_y) per CID
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide.Avg_Yearly_gain
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Section 3.7 (#AvgGain0) | Consumed to compute average yearly gain for PI dashboard |

---

## 7. Sample Queries

### 7.1 Average yearly return per customer across all years

```sql
SELECT CID, AVG(Gain_y) AS Avg_Yearly_Gain, COUNT(*) AS Years_Tracked
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
GROUP BY CID
HAVING COUNT(*) >= 3
ORDER BY Avg_Yearly_Gain DESC;
```

### 7.2 Year-over-year gain distribution

```sql
SELECT Year1,
       COUNT(*) AS Customers,
       AVG(Gain_y) AS Avg_Gain,
       MIN(Gain_y) AS Min_Gain,
       MAX(Gain_y) AS Max_Gain
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
GROUP BY Year1
ORDER BY Year1;
```

### 7.3 Specific customer's yearly performance history

```sql
SELECT Year1, Gain_y,
       Gain_y * 100 AS Gain_Percent
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
WHERE CID = 15310291
ORDER BY Year1;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PastYearsGain | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (section 3.4 from DWH_GainDaily)*


### Upstream `BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_WeeklyPanel_FullData.md`

# BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData

> Weekly per-depositor customer panel — the broadest weekly CRM fact table in BI_DB_dbo. 174 columns covering customer classification, trading activity, revenue, PnL, end-of-week equity, copy trading, cash flow, and accumulated totals. One row per depositor per calendar week. ~5.87M distinct CIDs; date range 2021–present; refreshed daily via DELETE/INSERT on the current week's partition.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL via BI_DB_CID_DailyPanel_FullData (see Section 5) |
| **Refresh** | Daily — DELETE WHERE FirstDayOfWeek = @FirstDayOfWeek + INSERT (SP_CID_WeeklyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (FirstDayOfWeek ASC, CID ASC) |
| **Row Count** | ~5.87M distinct CIDs per weekly slice (April 2026); ~14 distinct weeks in 2026 as of April |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_WeeklyPanel_FullData` is the primary **weekly CRM analytics panel** for all eToro depositors — the weekly counterpart to `BI_DB_CID_DailyPanel_FullData` (183 cols, daily grain) and `BI_DB_CID_MonthlyPanel_FullData` (189 cols, monthly grain). For each customer who has ever made a deposit, it provides a per-week summary of their trading activity, financial metrics, acquisition attributes, and accumulated totals.

The table serves as the central input for:
- **Weekly CRM reporting**: Week-over-week Club tier distribution, regulation, activity, and lifecycle segmentation
- **Revenue analytics**: Weekly revenue totals by instrument type, with Islamic/ticket/conversion fee breakdown since 2025
- **PnL tracking**: Customer-side weekly P&L by instrument and leverage tier
- **Activity measurement**: Active, ActiveOpen, ActiveUser flags — any-day-in-week semantics (MAX aggregation)
- **Cash flow analysis**: Weekly deposits, cashouts, withdrawal-to-wallet, and their running totals
- **Copy trading**: Weekly copy open/close/fund flows

**Population boundary**: Only **depositors** are included — customers with any deposit history. Non-depositing registered customers are absent. ~5.87M distinct depositor rows per weekly slice as of April 2026.

**Grain**: One row per CID per calendar week. The week is identified by `FirstDayOfWeek` (Sunday of the target week) and `YearWeekNumber` (e.g., '2026-15'). `SSWeekNumberOfYear` is the SQL Server ISO-style week number for the year.

**Two-source JOIN pattern**: The SP aggregates rows from `BI_DB_CID_DailyPanel_FullData` for the week's date range into two temp tables:
- **`#dailysum`** — weekly SUM/MAX aggregates of flow metrics (trades, revenue, PnL, deposits, copy activity)
- **`#lastdayattributes`** — end-of-week (EOW) snapshot from the **last calendar day of the week** only, capturing classification state (Region, Country, EOW_Club, EOW_Regulation, Equity, EOW_LSD, etc.)

**Instrument taxonomy**: Columns are systematically repeated across 6 asset-class families — same as the DailyPanel:
- **Copy** — mirror-copy positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** provides sub-breakdowns for Real Stocks, CFD Stocks, Real Crypto, CFD Crypto across Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL, and EOW_Equity columns. Lev1 = leverage=1 AND IsBuy=1; LevCFD = leveraged or short.

**ACC_ prefix**: 20 accumulator columns (ACC_Revenue_*, ACC_PnL_*, ACC_TotalDeposits, ACC_CountDeposits, ACC_TotalCashouts, ACC_TotalCoFee, ACC_NetDeposits, ACC_WithdrawalToWallet). In the weekly panel, these are the **SUM of daily ACC_ values** across the week's days — see §2.6 for semantics.

**Column evolution**: The SP has been extended 5 times since 2021. Columns added 2025-01-06 (ActiveOpen_AirDrop/Mirror/Manual/IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, CashoutsAdjusted) and 2025-08-13 (Revenue_TicketFeeByPercent). Historical rows pre-dating these additions will show NULL.

---

## 2. Business Logic

### 2.1 EOW_Club — Weekly Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of week, inherited from `EOD_Club` in the DailyPanel's last day of the week.

**Columns Involved**: `EOW_Club`

**Rules**:
```
EOW_Club =
  WHEN EOW_Equity < 1,000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                          → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                       → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split at the $1,000 equity mark. Observed distribution (Week 15 / 2026-04-05): LowBronze 79.8%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOW_Regulation — Weekly Regulatory Jurisdiction

**What**: Customer's regulatory entity at end of week, inherited from `EOD_Regulation` on the week's last day.

**Columns Involved**: `EOW_Regulation`

**Observed values (Week 15 / 2026)**: CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, FinCEN 1.7%, FSRA 1.5%, ASIC 0.9%, plus MAS, FINRAONLY, NFA, BVI, NYDFS+FINRA, eToroUS (<1%).

### 2.3 Active / ActiveOpen / ActiveUser — Weekly Aggregation

**What**: Activity flags use MAX across the week's days — a customer is Active/ActiveOpen for the week if they were active on ANY day within the week.

**Columns Involved**: `Active`, `ActiveOpen`, `ActiveUser`, `Active_*`, `ActiveOpen_*`

**Rules**:
```
Active (week)      = MAX(Active across all days in week)       → 1 if had any position open/closed on any day
ActiveOpen (week)  = MAX(ActiveOpen across all days in week)   → 1 if opened any new position on any day
ActiveUser (week)  = MAX(ActiveUser across all days in week)   → 1 if logged in on any day
Active_Copy        = MAX(Active_Copy) → 1 if had open copy position on any day
Active_*           = MAX(Active_*) for all asset class flags
ActiveOpen_*       = MAX(ActiveOpen_*) for all asset class flags
```
**Note**: ActiveOpen flag semantics differ from the MonthlyPanel where `Active = closed ≥1 position`. In the Weekly panel, `Active = MAX(daily Active)` where daily Active means "any position open or closed on that day."

### 2.4 Weekly_Classification — Always Empty String

**What**: Customer segment label (e.g., 'Traders', 'Crypto'). Inherited from `Daily_Classification` in the DailyPanel — which is set by a separate SP (`SP_CID_DailyPanel_UpdateCluster`) that is non-operational post-Synapse migration.

**Columns Involved**: `Weekly_Classification`

**Observed values**: Always empty string `''` as of 2025–2026. Historical rows (pre-Synapse migration) may contain values like 'Traders', 'Crypto'. Do not use this column for current segmentation — use `EOW_Club` or `EOW_LSD` instead.

### 2.5 Revenue Taxonomy

**What**: Weekly revenue uses the same two-total structure as the DailyPanel (post-2025 update by Or Filizer).

**Columns Involved**: `Revenue_Total`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Rules** (weekly SUM of daily values):
```
Revenue_Total               = SUM(daily trading commissions + TicketFees + TicketFeeByPercent + 
                                   ConversionFees + IslamicFees) for the week
Transactional_Revenue_Total = Revenue_Total - Islamic fee components (week SUM)
Revenue_IslamicFees         = SUM(daily AdminFee + SpotAdjustFee) for the week — 0 for non-Islamic
Revenue_TicketFees          = SUM(flat per-trade stock ticket fees) for the week
Revenue_ConversionFees      = SUM(deposit/cashout currency conversion fees) for the week
Revenue_TicketFeeByPercent  = SUM(% ticket fees across all asset classes) for the week
```

### 2.6 ACC_ Column Weekly Semantics

**What**: ACC_ columns in the Weekly panel are computed as `SUM(daily_ACC_value)` across all days in the week — NOT a self-referencing running total as in the MonthlyPanel.

**Columns Involved**: `ACC_Revenue_*`, `ACC_PnL_*`, `ACC_TotalDeposits`, `ACC_CountDeposits`, `ACC_TotalCashouts`, `ACC_TotalCoFee`, `ACC_NetDeposits`, `ACC_WithdrawalToWallet`

**Rules**:
```
ACC_Revenue_Total (week) = SUM(daily ACC_Revenue_Total for Mon, Tue, ..., Sun)
                         ≠ weekly Revenue_Total
                         ≠ lifetime ACC_ as of week-end
```
Each daily ACC_Revenue_Total is itself a lifetime running total (prior day + today's revenue). Summing 7 daily lifetime totals produces a value larger than the weekly revenue and not directly comparable to the MonthlyPanel's ACC_ columns.

**Practical implication**: Do NOT compare ACC_ across the DailyPanel, WeeklyPanel, and MonthlyPanel as equivalent lifetime totals. For lifetime revenue as of a given week, look at the DailyPanel row for the last day of the week instead. `ACC_ChurnDays` and `ACC_Transactional_Revenue_Total` are absent from the Weekly panel entirely.

### 2.7 EOW vs Daily Snapshot Attributes

**What**: Demographic and classification attributes are point-in-time from the **last calendar day** of the week (`#lastdayattributes WHERE DateID = @dateID`), not averaged or MAX'd across the week.

**Columns Involved**: `Seniority`, `Seniority_Seg`, `Region`, `Country`, `Channel`, `SubChannel`, `AffiliateID`, `V2_Complete`, `V3_Complete`, `IsPro`, `IsOTD`, `Weekly_Classification`, `EOW_Club`, `EOW_Regulation`, `NewMarketingRegion`, `Equity`, `RealizedEquity`, `AUM`, `Credit`, `EOW_Equity_*`, `EOW_LSD`

**Note on IsReg_ThisD / IsFTD_ThisD**: These are also from the last day of the week (end-of-week snapshot) — they answer "was this customer's registration date or FTD date the last day of this week?" Use `IsReg_ThisW` / `IsFTD_ThisW` (MAX aggregates) for "did this happen during the week?"

---

## 3. Query Advisory

### 3.1 Grain and Filtering
- **One row per CID per calendar week**. Always filter `WHERE FirstDayOfWeek = 'YYYY-MM-DD'` (Sunday of target week) for a single-week slice. The leading CLUSTERED INDEX key is FirstDayOfWeek.
- **FirstDayOfWeek is DATE type**. Use `FirstDayOfWeek = '2026-04-05'` (Sunday) not `= 20260405`.
- **YearWeekNumber format** is `'YYYY-W'` (e.g., '2026-15'). Use FirstDayOfWeek for reliable filtering; YearWeekNumber string comparisons are valid but secondary.
- **Bracket-escape "/" column names**: `[Active_FX/Comm/Ind]`, `[ActiveOpen_FX/Comm/Ind]`, `[NewTrades_FX/Comm/Ind]`, `[AmountIn_NewTrades_FX/Comm/Ind]`, `[Revenue_FX/Comm/Ind]`, `[PnL_FX/Comm/Ind]`, `[ACC_Revenue_FX/Comm/Ind]`, `[ACC_PnL_FX/Comm/Ind]`, `[EOW_Equity_FX/Comm/Ind]`.

### 3.2 Revenue — Which Column to Use
- Use **`Revenue_Total`** for current total revenue analysis (includes all fee components).
- Use **`Transactional_Revenue_Total`** when excluding Islamic swap fees (pure trading activity).
- Revenue_Total in the Weekly panel uses the same composition as DailyPanel (post-2025): commissions + rollover + TicketFees + TicketFeeByPercent + ConversionFees + IslamicFees. **Note**: No `Revenue_Total_New` column exists here (unlike MonthlyPanel). The Weekly `Revenue_Total` already includes all 2025+ fee components.

### 3.3 ACC_ Column Caveats
- Do NOT use ACC_ columns as lifetime totals — they are SUM of daily running totals for the week. For true lifetime figures, join to the DailyPanel row for the week's last day.
- Week-over-week comparison of ACC_ values will show inflated deltas because each ACC_ value already contains the lifetime total repeated 7 times.

### 3.4 Lev1/LevCFD Sub-Tier Columns
- The plain `Active_Real_Stocks`, `Revenue_Real_Stocks`, etc. columns include **both Lev1 and LevCFD** combined.
- `Active_Real_Stocks_Lev1` and `Active_CFD_Stocks_LevCFD` are sub-breakdowns. NULL for pre-2023 rows when the Lev split was not yet tracked.

### 3.5 Weekly_Classification Is Empty
- Do not use `Weekly_Classification` for current segmentation. Use `EOW_Club` (7 tiers) or `EOW_LSD` (17 lifecycle values) instead.

### 3.6 Large Table Query Guidance
- With ~5.87M CIDs × multiple years of weekly data, **always filter on `FirstDayOfWeek`** before adding other predicates. FirstDayOfWeek is the leading CLUSTERED INDEX key.
- HASH(CID) distributed — joins to other HASH(CID) tables (DailyPanel, MonthlyPanel) are co-located.
- Avoid unfiltered aggregations across all weeks. Use a date-bounded WHERE clause.

---

## 4. Data Elements

> 174 columns. Grouped by functional area. EOW = end-of-week snapshot from last day of week. MAX = maximum across all week days. SUM = sum across all week days. NOT NULL columns: CID, Credit, UpdateDate.

### 4A. Identity & Week Grain

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | eToro customer ID (Real CID). Only depositors present. HASH distribution key. FK → DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | YearWeekNumber | varchar(7) | YES | ISO-style week identifier: 'YYYY-W' (e.g., '2026-15'). Grain label for the week. Use FirstDayOfWeek (DATE) for reliable filtering. (Tier 2 — SP: CAST(YEAR(@date), '-', SSWeekNumberOfYear)) |
| 3 | SSWeekNumberOfYear | tinyint | YES | SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear. (Tier 2 — DWH_dbo.Dim_Date) |
| 4 | CalendarYear | smallint | YES | Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear. (Tier 2 — DWH_dbo.Dim_Date) |
| 28 | FirstDayOfWeek | date | YES | Sunday date marking the start of the calendar week. Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for week slices. (Tier 2 — SP: DATEADD(dd, -(DATEPART(dw, @date)-1), @date)) |

### 4B. Registration & Acquisition

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 5 | Seniority | int | YES | Months since customer's first deposit (FTDdate), as of start of the last month of the week. EOW snapshot. 0 = FTD month. (Tier 2 — SP: DATEDIFF(MONTH, FTDdate, month-start-of-@date), via DailyPanel) |
| 6 | Seniority_Seg | varchar(11) | YES | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '12+month'. EOW snapshot. (Tier 2 — SP CASE on DATEDIFF(DAY, FTDdate, @date), via DailyPanel) |
| 22 | Reg_Month | int | YES | YYYYMM of customer registration. MAX across week (no change expected). (Tier 2 — Dim_Customer.RegisteredReal, via DailyPanel) |
| 23 | RegDate | date | YES | Customer registration date. MAX across week. (Tier 2 — Dim_Customer.RegisteredReal, via DailyPanel) |
| 7 | IsReg_ThisD | int | YES | 1 if customer's registration date is the last day of this week (EOW snapshot from @dateID). NOT a weekly flag — use IsReg_ThisW for "registered during this week". (Tier 2 — SP: RegDate = last day of week, via DailyPanel) |
| 8 | IsFTD_ThisD | int | YES | 1 if customer's first deposit date is the last day of this week (EOW snapshot). NOT a weekly flag — use IsFTD_ThisW for "FTD occurred during this week". (Tier 2 — SP: FTDdate = last day of week, via DailyPanel) |
| 24 | IsReg_ThisW | int | YES | 1 if customer registered on any day during this calendar week (MAX of daily IsReg_ThisD). (Tier 2 — SP: MAX(IsReg_ThisD)) |
| 25 | IsFTD_ThisW | int | YES | 1 if customer made their first deposit on any day during this calendar week (MAX of daily IsFTD_ThisD). (Tier 2 — SP: MAX(IsFTD_ThisD)) |
| 26 | FTDdate | date | YES | Customer's first-time deposit date. MAX across week (no change expected). (Tier 2 — BI_DB_CIDFirstDates, via DailyPanel) |
| 27 | FTDA | money | YES | First-time deposit amount (USD). MAX across week (no change expected). (Tier 2 — BI_DB_CIDFirstDates, via DailyPanel) |

### 4C. Customer Attributes & Classification (EOW Snapshot)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Region | nvarchar(500) | YES | Geographic region label at end of week (e.g., 'French', 'UK', 'Arabic GCC', 'Australia', 'North Europe'). EOW snapshot from Dim_Country.Region. (Tier 1 — DWH_dbo.Dim_Country wiki, via DailyPanel) |
| 10 | Country | varchar(500) | YES | Customer's country name at end of week (e.g., 'France', 'United Kingdom'). EOW snapshot from Dim_Country.Name. (Tier 1 — DWH_dbo.Dim_Country wiki, via DailyPanel) |
| 11 | Channel | nvarchar(500) | YES | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Media Performance', 'Mobile Acquisition'). EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.Channel, via DailyPanel) |
| 12 | SubChannel | nvarchar(500) | YES | Acquisition sub-channel detail. EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.SubChannel, via DailyPanel) |
| 13 | AffiliateID | int | YES | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic. EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.SerialID, via DailyPanel) |
| 14 | V2_Complete | int | YES | 1 if customer has completed verification level 2 as of end of week. EOW snapshot. (Tier 1 — DWH_dbo.Dim_Customer wiki, via DailyPanel) |
| 15 | V3_Complete | int | YES | 1 if customer has completed full KYC (verification level 3) as of end of week. EOW snapshot. (Tier 1 — DWH_dbo.Dim_Customer wiki, via DailyPanel) |
| 16 | IsPro | int | YES | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3). EOW snapshot. (Tier 2 — Fact_SnapshotCustomer.MifidCategorizationID, via DailyPanel) |
| 17 | IsOTD | int | YES | 1 if customer has made exactly one prior deposit (One Trade Done). EOW snapshot. (Tier 2 — Fact_CustomerAction AT=7 count, via DailyPanel) |
| 21 | NewMarketingRegion | varchar(50) | YES | Marketing team region classification (e.g., 'Arabic', 'French', 'UK', 'ROW'). EOW snapshot. More recent vintage than Region. (Tier 2 — Dim_Country.MarketingRegionManualName, via DailyPanel) |
| 18 | Weekly_Classification | varchar(50) | YES | Customer segment label. Always empty string in 2025–2026 — inherited from Daily_Classification which is non-operational post-Synapse migration. See §2.4. Do not use for current analysis. (Tier 4 — SP_CID_DailyPanel_UpdateCluster, non-operational) |
| 19 | EOW_Club | varchar(50) | YES | eToro Club loyalty tier at end of week: 'LowBronze' (equity < $1,000), 'HighBronze' (equity ≥ $1,000, Bronze tier), 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'. EOW snapshot. See §2.1. Observed: LowBronze 79.8%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki, via DailyPanel) |
| 20 | EOW_Regulation | varchar(50) | YES | Regulatory jurisdiction at end of week (e.g., 'CySEC', 'FCA', 'FinCEN+FINRA', 'ASIC & GAML', 'FSA Seychelles'). EOW snapshot. See §2.2. 15 distinct values. (Tier 2 — Dim_Regulation.Name via Fact_SnapshotCustomer, via DailyPanel) |
| 164 | EOW_LSD | nvarchar(50) | YES | Life Stage Description at end of week from BI_DB_CID_LifeStageDefinition. 17 possible values (e.g., 'Dump Churn' 37.2%, 'Holder' 19.4%, 'No Activity - Not Funded' 12.1%, 'Active Open Club' 5.3%, 'Active Open' 5.1%, 'New Funded' 0.2%). EOW snapshot. (Tier 2 — BI_DB_CID_LifeStageDefinition.LSD, via DailyPanel) |

### 4D. EOW Financials (End-of-Week Snapshot)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | Equity | decimal(23,4) | YES | Total EOW equity (USD): NWA + liabilities from DWH_dbo.V_Liabilities. Includes open position unrealised PnL. NULL for ~0.2% of rows (no V_Liabilities record). EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities, via DailyPanel) |
| 30 | RealizedEquity | money | YES | Realized equity component (cash + closed positions, excluding open unrealised). EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.RealizedEquity, via DailyPanel) |
| 31 | AUM | money | YES | Assets Under Management: value in copy-trading and portfolio products. EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.AUM, via DailyPanel) |
| 32 | Credit | money | NO | Credit/margin balance (bonus credits, loans). NOT NULL — CASE WHEN NULL THEN 0 applied in SP. EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.EOD_Balance, via DailyPanel) |
| 116 | EOW_Equity_Copy | money | YES | EOW equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 119 | EOW_Equity_Real_Stocks | money | YES | EOW equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 120 | EOW_Equity_CFD_Stocks | money | YES | EOW equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 117 | EOW_Equity_Real_Crypto | money | YES | EOW equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 121 | EOW_Equity_CFD_Crypto | money | YES | EOW equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 123 | EOW_Equity_FX/Comm/Ind | money | YES | EOW equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4). Column name requires bracket quoting. EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 124 | EOW_Equity_Real_Crypto_Lev1 | money | YES | EOW equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long). EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 125 | EOW_Equity_Real_Stocks_LevCFD | money | YES | EOW equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short). EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 126 | EOW_Equity_CFD_Crypto_Lev1 | money | YES | EOW equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1. EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 127 | EOW_Equity_CFD_Stocks_LevCFD | money | YES | EOW equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0. EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |

### 4E. Activity Flags (MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | ActiveUser | int | YES | 1 if customer logged in on any day during the week (MAX of daily ActiveUser). (Tier 2 — Fact_CustomerAction AT=14, via DailyPanel) |
| 34 | Active | int | YES | 1 if customer had any position open or closed on any day during the week (MAX of daily Active). (Tier 2 — Dim_Position date range, via DailyPanel) |
| 35 | ActiveOpen | int | YES | 1 if customer opened a new position (manual/mirror, excludes AirDrop) on any day during the week (MAX of daily ActiveOpen). (Tier 2 — SP composite flag, via DailyPanel) |
| 112 | EOW_IsFunded | int | YES | 1 if EOW_Equity ≥ $25 on the last day of the week (original funded threshold). MAX across week. (Tier 2 — SP: EOD_IsFunded ≥ $25 threshold, via DailyPanel) |
| 150 | IsFunded_New | int | YES | 1 if customer has EOW_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < next day (stricter funded definition). MAX across week. (Tier 2 — SP: #NewFundedAccounts, via DailyPanel) |
| 46 | Active_Copy | int | YES | 1 if customer had an open copy position on any day during the week. MAX. (Tier 2 — Dim_Position MirrorID>0, via DailyPanel) |
| 47 | Active_Real_Stocks | int | YES | 1 if customer had an open settled stock position on any day (IsSettled=1, InstrTypeID IN 5,6). MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 48 | Active_CFD_Stocks | int | YES | 1 if customer had an open CFD stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 49 | Active_Real_Crypto | int | YES | 1 if customer had an open settled crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 50 | Active_CFD_Crypto | int | YES | 1 if customer had an open CFD crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 51 | Active_FX/Comm/Ind | int | YES | 1 if customer had an open FX/Comm/Ind position on any day (InstrTypeID IN 1,2,4). Column name requires bracket quoting. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 151 | Active_FX | int | YES | 1 if customer had an open FX (Currencies, InstrTypeID=1) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 152 | Active_Comm | int | YES | 1 if customer had an open Commodities (InstrTypeID=2) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 153 | Active_Ind | int | YES | 1 if customer had an open Indices (InstrTypeID=4) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 128 | Active_Real_Stocks_Lev1 | tinyint | YES | 1 if customer had an open stock position with Leverage=1 AND IsBuy=1 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 129 | Active_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer had an open stock position with Leverage>1 OR IsBuy=0 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 130 | Active_Real_Crypto_Lev1 | tinyint | YES | 1 if customer had an open crypto position with Leverage=1 AND IsBuy=1 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 131 | Active_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer had an open crypto position with Leverage>1 OR IsBuy=0 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |

### 4F. ActiveOpen by Instrument (MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 52 | ActiveOpen_Copy | int | YES | 1 if customer opened a copy position (MirrorID>0) on any day. MAX. (Tier 2 — Dim_Position OpenDateID, via DailyPanel) |
| 53 | ActiveOpen_Real_Stocks | int | YES | 1 if customer opened a settled stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 54 | ActiveOpen_CFD_Stocks | int | YES | 1 if customer opened a CFD stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 55 | ActiveOpen_Real_Crypto | int | YES | 1 if customer opened a settled crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 56 | ActiveOpen_CFD_Crypto | int | YES | 1 if customer opened a CFD crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 57 | ActiveOpen_FX/Comm/Ind | int | YES | 1 if customer opened a FX/Comm/Ind position on any day. Column name requires bracket quoting. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 154 | ActiveOpen_FX | int | YES | 1 if customer opened a FX position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 155 | ActiveOpen_Comm | int | YES | 1 if customer opened a Commodities position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 156 | ActiveOpen_Ind | int | YES | 1 if customer opened an Indices position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 167 | ActiveOpen_Manual | int | YES | 1 if customer opened a non-AirDrop, non-copy position (MirrorID=0, IsAirDrop=0) on any day. MAX. (Tier 2 — Dim_Position OpenDateID, via DailyPanel) |
| 168 | ActiveOpen_Mirror | int | YES | 1 if customer started a new copy relationship or added mirror allocation on any day. MAX. (Tier 2 — Dim_Mirror + Fact_CustomerAction AT=15, via DailyPanel) |
| 165 | ActiveOpen_AirDrop | int | YES | 1 if customer received an AirDrop position (IsAirDrop=1) on any day. MAX. (Tier 2 — Dim_Position IsAirDrop=1, via DailyPanel) |
| 169 | ActiveOpen_IncludeCopy | int | YES | 1 if customer opened any position (manual + copy) excluding AirDrop on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 132 | ActiveOpen_Real_Stocks_Lev1 | tinyint | YES | 1 if customer opened a Lev1 stock position (Leverage=1, IsBuy=1) on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 133 | ActiveOpen_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer opened a leveraged/short stock position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 134 | ActiveOpen_Real_Crypto_Lev1 | tinyint | YES | 1 if customer opened a Lev1 crypto position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 135 | ActiveOpen_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer opened a leveraged/short crypto position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |

### 4G. Copy Trading (SUM/MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | IsOpen_Copy | int | YES | 1 if customer opened a new copy relationship on any day (MAX of daily flag). (Tier 2 — Fact_CustomerAction AT=17, via DailyPanel) |
| 37 | Count_Opened_Copy | int | YES | Total number of copy relationships opened during the week (SUM). (Tier 2 — Fact_CustomerAction AT=17 DISTINCT MirrorID, via DailyPanel) |
| 38 | Count_Closed_Copy | int | YES | Total number of copy relationships closed during the week (SUM). (Tier 2 — Fact_CustomerAction AT=18 DISTINCT MirrorID, via DailyPanel) |
| 39 | MoneyIn_Copy | decimal(38,2) | YES | Total funds allocated into copy positions during the week (SUM). (Tier 2 — Fact_CustomerAction AT=17,15, via DailyPanel) |
| 40 | MoneyOut_Copy | decimal(38,2) | YES | Total funds returned from closed copy positions during the week (SUM). (Tier 2 — Fact_CustomerAction AT=18,16, via DailyPanel) |
| 41 | IsOpen_CopyPortfolio | int | YES | 1 if customer opened a CopyPortfolio on any day (MAX). (Tier 2 — Fact_CustomerAction AT=17 portfolio mode, via DailyPanel) |
| 42 | Count_Opened_CopyPortfolio | int | YES | Total CopyPortfolio relationships opened during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |
| 43 | Count_Closed_CopyPortfolio | int | YES | Total CopyPortfolio relationships closed during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |
| 44 | MoneyIn_CopyPortfolio | decimal(38,2) | YES | Total funds into CopyPortfolio positions during the week (SUM).

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `BI_DB_dbo.BI_DB_CopyDailyData` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CopyDailyData`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CopyDailyData.md`

# BI_DB_dbo.BI_DB_CopyDailyData

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object | BI_DB_CopyDailyData |
| Type | Table |
| Rows | Append-mode historical table (one batch per @date; volume grows daily) |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX(CID ASC) |
| Production Source | DWH_dbo.Fact_SnapshotCustomer (PI + Portfolio population) |
| Writer SP | BI_DB_dbo.SP_CopyDailyData |
| Refresh Cadence | Daily DELETE(WHERE Date=@date) + INSERT — append-mode, preserves history |
| UC Target | _Not_Migrated |
| Batch | 74 |
| Documented | 2026-04-23 |

---

## 1. Business Meaning

Daily per-PI and per-Portfolio-account performance snapshot. Each row represents one **Popular Investor (PI) or Portfolio account** on a specific `Date`, capturing their identity, PI tier, equity composition, AUM, copier count, commission earned, mirror flow activity (MIMO), and risk metrics.

The table is **append-mode** — each daily load adds rows for `Date=@date` without touching prior history. It is the primary input for PI performance dashboards, tier-change analysis, and account manager reporting. Coverage includes:
- **PIs**: Active Popular Investors (GuruStatusID >= 2, IsValidCustomer=1)
- **Portfolio accounts**: Accounts with AccountTypeID=9

Population is derived from `DWH_dbo.Fact_SnapshotCustomer` joined to `DWH_dbo.Dim_Range` to find which customers were active on the reporting date.

**Known column typos in DDL**: `CurrenyEquity` (→ CurrentEquity/CurrencyEquity), `ProtfoilioType` (→ PortfolioType), `MifidCatigorization` (→ MifidCategorization), `DaysInCurrnetStatus` (→ DaysInCurrentStatus). These are legacy column names and cannot be renamed without pipeline changes.

---

## 2. Business Logic & Derivation Rules

### Population Filter
```
Fact_SnapshotCustomer JOIN Dim_Range
WHERE (GuruStatusID >= 2 AND IsValidCustomer = 1) OR AccountTypeID = 9
AND @date_int BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID
```
Uses `Dim_Range` date-range semantics (SCD-style validity windows) rather than a direct date column.

### Risk Score (`LastNightRiskScore`)
10-band volatility-to-score mapping from `DWH_dbo.V_Liabilities.StandardDeviation`:

| StandardDeviation Range | Score |
|------------------------|-------|
| < 0.0011 | 1 |
| < 0.0024 | 2 |
| < 0.0040 | 3 |
| < 0.0055 | 4 |
| < 0.0079 | 5 |
| < 0.0111 | 6 |
| < 0.0158 | 7 |
| < 0.0316 | 8 |
| < 0.0475 | 9 |
| >= 0.0475 | 10 |
| No match / NULL | 0 |

### Equity Decomposition (from `DWH_dbo.V_Liabilities`)

| Column | Formula |
|--------|---------|
| TotalEquity | Liabilities + ActualNWA |
| CurrenyEquity | TotalPositionsAmount + PositionPnL (typo: should be CurrentEquity) |
| PI_CopyAUM | AUM + CopyPositionPnL |
| PI_ManualStocks | TotalStockManualPosition + ManualStockPositionPnL |
| PI_ManualCrypto | TotalCryptoManualPosition + ManualCryptoPositionPnL |

**Manual trading estimate** (comment in SP): `ManualTrading ≈ TotalEquity − PI_CopyAUM − PI_ManualStocks − PI_ManualCrypto − Credit − InProcessCashouts`

### Commission Accumulation
**Accumulates from 2011-01-01** (hardcoded `@start_date = '20110101'`) to `@date`. Multi-condition logic per position:
- Position opened AND closed within window: `ISNULL(FullCommissionOnClose, CommissionOnClose)`
- Position opened within window but still open: `ISNULL(FullCommission, Commission)`
- Position closed within window but opened before: `ISNULL(FullCommissionOnClose - FullCommission, CommissionOnClose - Commission)`

### MIMO (Mirror In / Mirror Out) from `Fact_CustomerAction` — DateID = @date only
| Column | Action Types | Logic |
|--------|-------------|-------|
| MI | 15 (Mirror In), 17 (New Mirror) | SUM(-Amount) |
| MO | 16 (Mirror Out), 18 (UnMirror) | SUM(Amount) |
| netMI | 15, 16, 17, 18 | SUM(-Amount) net |
| NewMirror | 17 | COUNT of new copy-start events |
| UnMirror | 18 | COUNT of copy-stop events |

### DaysInCurrnetStatus (typo for DaysInCurrentStatus)
Finds the first date the PI entered their current GuruStatus tier by examining status-change transitions in `Fact_SnapshotCustomer`. Uses two branches:
1. **Status has changed before**: MIN(FromDateID) after the last status transition
2. **Status has never changed**: MIN(FromDateID) in Fact_SnapshotCustomer for the CID

### LastContactDate
Most recent `Phone_Call_Succeed__c` or `Completed_Contact_Email__c` action in `BI_DB_UsageTracking_SF`, where `CreatedByManagerID = ManagerID` (manager-matched contact). Sentinel: `ISNULL(CreatedDate, '1900-01-01')` — use `> '1900-01-01'` to filter for actual contacts.

### PI_Level_Previous
Yesterday's GuruStatusName from `Fact_SnapshotCustomer` at `@date - 1`. NULL if the PI had no prior snapshot record.

### PnL Section (Commented Out)
The `--,[PnL]` column is in the SP's INSERT column list but commented out. The `#PnL` calculation block is also commented. This column does NOT exist in the table.

---

## 3. Query Advisory

- **ROUND_ROBIN distributed** — filter on `Date` or `DateID` for efficiency; joins on `CID` will trigger data movement.
- **Append-mode table** — always filter by `Date` or `DateID`. Without a date filter, the query scans all history.
- **`commission` accumulates from 2011-01-01** — not a daily delta. Do not SUM across dates; each row already contains the cumulative figure for that PI.
- **`LastContactDate = '1900-01-01'`** means no contact recorded (sentinel, not a real date).
- **`LastNightRiskScore = 0`** means no V_Liabilities row or StandardDeviation was NULL.
- **`PI_Level_Previous` is NULL** for PIs without a prior day's record (e.g., new PIs).
- **`CurrenyEquity`** (typo) = `TotalPositionsAmount + PositionPnL` (current open position value including unrealized P&L). Do NOT confuse with `TotalEquity`.
- **`Language` is char(500)** — grossly over-provisioned; actual language names are short (< 30 chars). RTRIM() if needed.
- **`Country` and `Region` are varchar(500)** — similarly over-provisioned.
- **`CopyType`**: 'Portfolio' for AccountTypeID=9, 'PI' for all others.
- **Duplicate-run safety**: DELETE WHERE Date=@date before INSERT ensures idempotent loads.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| UserName | NULL | varchar(20) | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| ID | NOT NULL | uniqueidentifier | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| Language | NULL | char(500) | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. NOTE: char(500) is over-provisioned — RTRIM() before use. (Tier 1 — DWH_dbo.Dim_Language via Dictionary.Language) |
| Country | NULL | varchar(500) | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country) |
| Region | NULL | nvarchar(500) | Geographic region grouping for Country. Used in regional reporting aggregations. (Tier 2 — DWH_dbo.Dim_Country) |
| Manager | NULL | nvarchar(500) | Account manager display name: FirstName + ' ' + LastName from Dim_Manager. (Tier 2 — DWH_dbo.Dim_Manager) |
| Gender | NULL | char(1) | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| GuruStatusID | NULL | smallint | eToro Popular Investor/Guru program status — whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. Values: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. (Tier 1 — DWH_dbo.Dim_Customer via BackOffice.Customer) |
| PI_Level | NULL | varchar(50) | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — DWH_dbo.Dim_GuruStatus via Dictionary.GuruStatus) |
| MifidCatigorization | NULL | varchar(50) | Human-readable MiFID II classification label. Column name is a typo (should be MifidCategorization). MiFID II client tiers: 0=None (non-EU), 1=Retail, 2=Professional, 3=Elective Professional, 4=Retail Pending, 5=Pending. (Tier 1 — DWH_dbo.Dim_MifidCategorization via Dictionary.MifidCategorization) |
| Registered | NULL | datetime | Account registration date (renamed from Dim_Customer.RegisteredReal). Default=getdate() at registration. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| FirstDepositDate | NULL | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — DWH_dbo.Dim_Customer via SP_Dim_Customer) |
| Club | NULL | varchar(500) | Tier display name from Dim_PlayerLevel: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 — DWH_dbo.Dim_PlayerLevel via Dictionary.PlayerLevel) |
| CopyType | NOT NULL | varchar(9) | PI category: 'Portfolio' for AccountTypeID=9 (Copy Portfolio accounts), 'PI' for all other active Popular Investors. (Tier 2 — derived from Fact_SnapshotCustomer.AccountTypeID) |
| ProtfoilioType | NULL | varchar(50) | Portfolio fund type name from Dim_FundType. Column name is a typo (should be PortfolioType). NULL for PI accounts. (Tier 2 — DWH_dbo.Dim_FundType via Dim_Fund) |
| AffiliateAccount | NULL | int | Affiliate (partner) ID under which the customer was acquired (renamed from Dim_Customer.AffiliateID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| Acc_RiskIndex | NULL | int | Account-level risk classification index from BI_DB_User_Segment_Snapshot as of @date. (Tier 2 — BI_DB_dbo.BI_DB_User_Segment_Snapshot) |
| LastNightRiskScore | NOT NULL | int | Portfolio volatility score 1–10 mapped from V_Liabilities.StandardDeviation using 10-band thresholds. 0 = no V_Liabilities record or StandardDeviation is NULL. Higher score = higher portfolio volatility. (Tier 2 — DWH_dbo.V_Liabilities.StandardDeviation) |
| TotalEquity | NULL | decimal(23,4) | PI's total equity: Liabilities + ActualNWA from V_Liabilities. Represents total account value including liabilities. (Tier 2 — DWH_dbo.V_Liabilities) |
| CurrenyEquity | NULL | decimal(20,4) | Current open-position equity: TotalPositionsAmount + PositionPnL. Column name is a typo (should be CurrentEquity). Different from TotalEquity — excludes cash, includes unrealized P&L. (Tier 2 — DWH_dbo.V_Liabilities) |
| RealizedEquity | NULL | money | Realized equity from closed positions. Source: V_Liabilities.RealizedEquity. (Tier 2 — DWH_dbo.V_Liabilities) |
| TotalPositionsAmount | NULL | money | Total invested amount across all open positions (excluding P&L). Source: V_Liabilities.TotalPositionsAmount. (Tier 2 — DWH_dbo.V_Liabilities) |
| Credit | NULL | money | Credit balance (bonus funds) in the account. Source: V_Liabilities.Credit. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_CopyAUM | NULL | decimal(20,4) | Copy-trading AUM: V_Liabilities.AUM + V_Liabilities.CopyPositionPnL. Total value managed through copy relationships. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_ManualStocks | NULL | decimal(20,4) | PI's manually-managed stock portfolio: TotalStockManualPosition + ManualStockPositionPnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_ManualCrypto | NULL | decimal(20,4) | PI's manually-managed crypto portfolio: TotalCryptoManualPosition + ManualCryptoPositionPnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| InProcessCashouts | NULL | money | Pending withdrawal amounts not yet settled. Source: V_Liabilities.InProcessCashouts. (Tier 2 — DWH_dbo.V_Liabilities) |
| NumOfCopiers | NULL | int | Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| CopyAUM | NULL | money | Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| Date | NULL | date | Reporting date (the business day this snapshot covers = @date = GETDATE()-1). (Tier 2 — ETL parameter) |
| DateID | NULL | int | Integer date key: CONVERT(VARCHAR(8), @date, 112) — YYYYMMDD format. (Tier 2 — derived from Date) |
| DaysAsPI | NULL | int | Number of days since this customer first achieved PI status (GuruStatusID >= 2): DATEDIFF(DAY, MIN(FullDate), @date) from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| commission | NULL | money | Cumulative copy commissions earned by this PI since 2011-01-01 through @date. Multi-condition formula across open, closed, and straddling positions via Dim_Position+Dim_Mirror. NOTE: not a daily delta — each row is cumulative. (Tier 2 — DWH_dbo.Dim_Position via Dim_Mirror) |
| MI | NULL | decimal(38,2) | Money In for @date: SUM(-Amount) for mirror-in flows (ActionTypeID 15=Mirror In, 17=New Mirror) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| MO | NULL | decimal(38,2) | Money Out for @date: SUM(Amount) for mirror-out flows (ActionTypeID 16=Mirror Out, 18=UnMirror) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| netMI | NULL | decimal(38,2) | Net mirror flow for @date: SUM(-Amount) for all ActionTypeID IN (15,16,17,18) from Fact_CustomerAction. Positive = net inflow, negative = net outflow. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| NewMirror | NULL | int | Number of new copy-start events on @date (ActionTypeID=17) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| UnMirror | NULL | int | Number of copy-stop events on @date (ActionTypeID=18) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| DaysInCurrnetStatus | NULL | int | Days since the PI entered their current GuruStatus tier. Column name is a typo (should be DaysInCurrentStatus). Computed from Fact_SnapshotCustomer status-change transitions. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |
| CopyPnL | NULL | int | Copiers' unrealized P&L attributed to this PI: ISNULL(SUM(PnL+DetachedPosInvestment+Dit_PnL), 0) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| LastContactDate | NULL | datetime | Most recent successful manager contact (phone call or email) recorded in Salesforce for this PI, where contact was by the PI's own account manager. Sentinel: '1900-01-01' = no contact on record. (Tier 2 — BI_DB_dbo.BI_DB_UsageTracking_SF) |
| PI_Level_Previous | NULL | varchar(50) | PI tier name (GuruStatusName) as of @date - 1 day. Used to detect tier changes. NULL if no prior-day snapshot exists. (Tier 2 — DWH_dbo.Dim_GuruStatus via DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Usage |
|--------|-------|
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Population filter (PIs + Portfolio), DaysAsPI, DaysInCurrnetStatus |
| DWH_dbo.Dim_Customer | UserName, ID, Gender, Registered, FirstDepositDate, AffiliateAccount |
| DWH_dbo.Dim_Language | Language name lookup |
| DWH_dbo.Dim_Country | Country name, Region lookup |
| DWH_dbo.Dim_Manager | Manager composite name |
| DWH_dbo.Dim_GuruStatus | PI_Level (today), PI_Level_Previous (yesterday) |
| DWH_dbo.Dim_PlayerLevel | Club (tier name) |
| DWH_dbo.Dim_MifidCategorization | MifidCatigorization label |
| DWH_dbo.Dim_Fund + Dim_FundType | ProtfoilioType for Portfolio accounts |
| DWH_dbo.V_Liabilities | All equity, AUM, credit, position, and risk columns |
| DWH_dbo.Dim_Mirror + Dim_Position | commission accumulation |
| DWH_dbo.Fact_CustomerAction | MI, MO, netMI, NewMirror, UnMirror |
| general.etoroGeneral_History_GuruCopiers | NumOfCopiers, CopyAUM, CopyPnL |
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | Acc_RiskIndex |
| BI_DB_dbo.BI_DB_UsageTracking_SF | LastContactDate |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer JOIN Dim_Range → @date population (PIs + Portfolios)
  |
  +--> DWH_dbo.Dim_Customer, Dim_Language, Dim_Country, Dim_Manager, Dim_GuruStatus,
  |    Dim_PlayerLevel, Dim_MifidCategorization, Dim_Fund, Dim_FundType
  |    → #basicdata (identity + equity + copier aggregates)
  |
  +--> DWH_dbo.Fact_SnapshotCustomer (DaysAsPI)
  +--> DWH_dbo.Dim_Position + Dim_Mirror (commission since 2011-01-01)
  +--> DWH_dbo.Fact_CustomerAction (MIMO for @date)
  +--> DWH_dbo.Fact_SnapshotCustomer transitions (DaysInCurrnetStatus)
  +--> BI_DB_dbo.BI_DB_UsageTracking_SF (LastContactDate)
  |
  v
SP_CopyDailyData — DELETE(Date=@date) + INSERT (append-mode)
  |
  v
BI_DB_dbo.BI_DB_CopyDailyData (ROUND_ROBIN, CLUSTERED INDEX(CID))
  |
  v
UC Target: _Not_Migrated (not in Generic Pipeline)
```

---

## 6. Relationships & Cross-References

| Related Object | Relationship |
|----------------|-------------|
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | Source of Acc_RiskIndex; joined on RealCID and Date. |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Source of LastContactDate; filtered to PI's account manager and successful contact types. |
| DWH_dbo.Fact_SnapshotCustomer | Primary population source and basis for DaysAsPI, DaysInCurrnetStatus. |
| DWH_dbo.V_Liabilities | Source of all equity and financial position columns. |
| DWH_dbo.Fact_CustomerAction | Source of all MIMO columns (MI, MO, netMI, NewMirror, UnMirror). |
| general.etoroGeneral_History_GuruCopiers | Source of copier metrics (NumOfCopiers, CopyAUM, CopyPnL). |

---

## 7. Sample Queries

```sql
-- PI daily snapshot for a specific date (filter required)
SELECT CID, UserName, PI_Level, Country, Manager,
       TotalEquity, PI_CopyAUM, NumOfCopiers, CopyAUM,
       LastNightRiskScore, DaysAsPI, DaysInCurrnetStatus
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
ORDER BY CopyAUM DESC;

-- Detect tier changes (PI_Level changed vs prior day)
SELECT CID, UserName, Date, PI_Level, PI_Level_Previous
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND PI_Level <> PI_Level_Previous
  AND PI_Level_Previous IS NOT NULL;

-- MIMO daily activity for a specific date
SELECT CID, UserName, MI, MO, netMI, NewMirror, UnMirror
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND (NewMirror > 0 OR UnMirror > 0)
ORDER BY NewMirror DESC;

-- PIs with no recent manager contact (>30 days)
SELECT CID, UserName, Manager, LastContactDate,
       DATEDIFF(DAY, LastContactDate, GETDATE()) AS DaysSinceContact
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND LastContactDate > '1900-01-01'  -- exclude sentinel
  AND DATEDIFF(DAY, LastContactDate, GETDATE()) > 30
ORDER BY DaysSinceContact DESC;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this object. Contact the Data Platform team or check the DATA Confluence space for PI performance reporting documentation.


### Upstream `BI_DB_dbo.BI_DB_DailyCopyRevenue` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_DailyCopyRevenue`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCopyRevenue.md`

# BI_DB_dbo.BI_DB_DailyCopyRevenue

> 7.2M-row daily copy trading revenue table attributing platform spread commissions to Popular Investors (Gurus) by instrument type. Each row = one PI (ParentCID) on one date. Revenue broken down across 7 instrument categories (real stocks, CFD stocks, real/CFD crypto, FX, commodities, indices). Refreshed daily via DELETE+INSERT by SP_CID_DailyCopyRevenue. Not yet migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Writer SP** | SP_CID_DailyCopyRevenue |
| **Refresh** | DELETE WHERE DateID=@startDateINT + INSERT daily (@date parameter) |
| **Row Count** | 7,192,560 rows (2026-04-22 live count) |
| **Date Range** | 2020-01-01 to 2026-04-12 (2,294 distinct dates) |
| **Distinct PIs** | 58,592 unique ParentCIDs across all dates |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **SP Authors** | Dan Iliescu (2021-07-27) · Tal Cohen (2023-06-28 Synapse migration) · Guy M (2024-09-27 IsBuy alias) · Or Filizer (2025-10-26 crypto TicketFeeByPercent) |

**Tier legend**: T1 = verbatim upstream wiki · T2 = SP-derived/computed · T3 = dimension ID passthrough from Fact_SnapshotCustomer · T4 = N/A

---

## 1. Business Meaning

Daily revenue breakdown for copy trading, attributed to Popular Investors (Gurus). Each row represents a single **ParentCID** (the Popular Investor being copied) on a given **Date**, with revenue broken down by instrument type: real stocks, CFD stocks, real crypto, CFD crypto, FX, commodities, and indices.

Revenue is generated by the platform from copiers who follow a Popular Investor — when a copier's position (which mirrors the PI's trade) opens or closes, eToro earns a spread commission. The table rolls up all such commissions across all copiers of a given PI for the day, attributed to that PI.

Primary use cases: PI performance analysis, copy trading P&L attribution, revenue decomposition by instrument type, country/regulation segmentation of PI revenue.

---

## 2. Business Logic & Derivation Rules

### 2.1 Population — Copier Filter

Copiers contributing to revenue must be valid depositors at @date:
- `Fact_SnapshotCustomer.IsDepositor = 1`
- `Fact_SnapshotCustomer.IsValidCustomer = 1`

This filters to customers with real money at risk. The Popular Investor (ParentCID) themselves is NOT subject to this filter — any PI who has copy revenue on @date appears regardless of their own depositor status (the final JOIN uses `#CIDs0`, which includes all customers at @date without the validity filter).

### 2.2 Commission Attribution — 3-Case UNION Logic

The SP computes commission for positions active on @date using three cases to avoid double-counting:

| Case | Condition | Commission Used | Business Logic |
|------|-----------|-----------------|----------------|
| Same-day | `OpenDateID = @date AND CloseDateID = @date` | `FullCommissionOnClose` | Position fully completed today; full commission earned |
| Carryover-close | `OpenDateID < @date AND CloseDateID = @date` | `FullCommissionOnClose − FullCommissionByUnits` | Opened on prior day; only close-side commission attributed today |
| New open | `OpenDateID = @date AND CloseDateID > @date` | `FullCommissionByUnits` | Opened today, still open; only open-side commission attributed today |

Positions opened before @date and still open contribute **zero** commission to @date — the commission was already attributed to their open date. The commented-out 4th UNION ALL case in the SP confirms this was intentional.

### 2.3 Rollover Fees

Rollover fees are sourced from `Fact_CustomerAction` (ActionTypeID=35, IsFeeDividend=1, DateID=@startDateINT) via a 4th UNION ALL branch. Amount is negated (`-fca.Amount`) because Fact_CustomerAction stores the fee as a customer debit (negative). Each Revenue_* column includes its relevant rollover component.

### 2.4 TicketFeeByPercent — Crypto Revenue (Added 2025-10-26)

`BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@startDateINT, @endDateINT, 1)` is a table-valued function that computes percentage-based ticket fees for crypto positions. Applied only to InstrumentTypeID=10 positions. Adds to both Revenue_Real_Crypto and Revenue_CFD_Crypto, and is also included in Revenue_Copy total. Historical data before 2025-10-26 will have TicketFeeByPercent=0 for crypto rows.

### 2.5 Revenue_Copy Is the Total

`Revenue_Copy = Revenue_Real_Stocks + Revenue_CFD_Stocks + Revenue_Real_Crypto + Revenue_CFD_Crypto + Revenue_FX + Revenue_Comm + Revenue_Ind`

Confirmed in live data:
- ParentCID 10155159: Revenue_Copy=857.02 = Revenue_Real_Crypto(732.90) + Revenue_CFD_Crypto(124.12) ✓
- ParentCID 14123814: Revenue_Copy=265.79 = Revenue_Comm(265.02) + Revenue_Ind(0.77) ✓

### 2.6 Instrument Type Classification

| Column | InstrumentTypeID | Additional Filter |
|--------|-----------------|-------------------|
| Revenue_Real_Stocks | 5 or 6 | Leverage=1 AND IsBuy=1 |
| Revenue_CFD_Stocks | 5 or 6 | Leverage>1 OR IsBuy=0 |
| Revenue_Real_Crypto | 10 | IsSettled=1 |
| Revenue_CFD_Crypto | 10 | IsSettled=0 |
| Revenue_FX | 1 | — |
| Revenue_Comm | 2 | — |
| Revenue_Ind | 4 | — |

InstrumentTypeIDs 3, 7, 8, 9, 11+ are not broken out separately — their commissions would be included in Revenue_Copy via FullCommission_Copy but would not appear in any named instrument-type column. This could cause `SUM(Revenue_Real_Stocks + ... + Revenue_Ind)` to be less than `Revenue_Copy` for some rows if unusual instrument types are present.

### 2.7 GuruStatusID, CountryID, AccountTypeID — PI Attributes at @date

These three columns reflect the Popular Investor's own snapshot attributes at @date (from `#CIDs0` which reads Fact_SnapshotCustomer). They are raw integer IDs — not human-readable labels. Join to Dim_GuruStatus, Dim_Country, Dim_AccountType for decoded values. Values in live sample: GuruStatusID ∈ {0, 4, 5}; AccountTypeID ∈ {1, 9}.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: ROUND_ROBIN — each daily DELETE+INSERT evenly distributes rows. Not joined to a large distributed table in typical analyst queries, so ROUND_ROBIN avoids skew.

**Index**: HEAP — no clustered index. Optimized for fast bulk INSERT on daily refresh. Date-range and PI filters use full table scan at small scale; for large multi-year queries, filter by DateID (integer) rather than Date (date) for best performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI revenue on a specific date | `WHERE DateID = 20260412 ORDER BY Revenue_Copy DESC` |
| Monthly revenue by instrument type | `GROUP BY YEAR([Date]), MONTH([Date])` on Revenue_* columns |
| Revenue trend for a single PI | `WHERE ParentCID = @cid ORDER BY Date` |
| Crypto vs non-crypto revenue split | `Revenue_Real_Crypto + Revenue_CFD_Crypto` vs remaining columns |
| Revenue by country (with country name) | JOIN Dim_Country ON CountryID, GROUP BY dc.Name |
| Revenue by PI status tier | JOIN Dim_GuruStatus ON GuruStatusID, GROUP BY gs.Name |
| Weekend vs weekday revenue comparison | Use DATEPART(dw, [Date]) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON r.CountryID = dc.CountryID | Decode PI country name |
| DWH_dbo.Dim_GuruStatus | ON r.GuruStatusID = dgs.GuruStatusID | Decode PI status tier label |
| DWH_dbo.Dim_AccountType | ON r.AccountTypeID = dat.AccountTypeID | Decode PI account type (Retail/Professional) |

### 3.4 Gotchas

- **Revenue_Copy ≠ sum of instrument columns for unusual InstrumentTypeIDs**: InstrumentTypeIDs 3, 7, 8, 9, 11+ contribute to Revenue_Copy but not to any named column. Verify `SUM(Revenue_Copy) = SUM(Revenue_Real_Stocks + ...)` before assuming the decomposition is exhaustive.
- **TicketFeeByPercent is crypto-only and added 2025-10-26**: Historical crypto revenue comparisons crossing this date will show a step-change in Revenue_Real_Crypto and Revenue_CFD_Crypto that is not driven by trading volume.
- **Weekend rows exist but are sparse**: ~500–700 rows/day on weekends vs 500–3,100 on weekdays. Rollover fees and crypto positions drive weekend revenue.
- **GuruStatusID=0 is valid**: Rows with GuruStatusID=0 represent PIs not formally in the program (or default status) who still have copiers generating revenue. Do not filter these out.
- **CountryID and AccountTypeID reflect PI's state at @date**: These are snapshot values from Fact_SnapshotCustomer at the reporting date. They can change over time; do not assume stability.
- **DateID uses integer format YYYYMMDD**: Filter `WHERE DateID = 20260412` — not `WHERE Date = '2026-04-12'` — for optimal scan on DELETE+INSERT key.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 — SP code / ETL logic | (Tier 2 — SP_CID_DailyCopyRevenue) |
| **  | Tier 3 — Dimension ID passthrough from Fact_SnapshotCustomer | (Tier 3 — DWH_dbo.Fact_SnapshotCustomer) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (SP @date input parameter). (Tier 2 — SP_CID_DailyCopyRevenue) |
| 2 | DateID | int | YES | YYYYMMDD integer of Date — DELETE+INSERT key. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 — SP_CID_DailyCopyRevenue) |
| 3 | ParentCID | int | YES | Popular Investor (Guru) customer ID being copied. Groups all copier revenue by the PI they follow. One row per PI per day. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 4 | GuruStatusID | smallint | YES | Popular Investor status tier ID at @date — from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_GuruStatus for label. Sample values: 0, 4, 5. (Tier 3 — DWH_dbo.Fact_SnapshotCustomer) |
| 5 | CountryID | int | YES | PI's country of registration ID at @date — from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_Country for country name. (Tier 3 — DWH_dbo.Fact_SnapshotCustomer) |
| 6 | AccountTypeID | int | YES | PI's account type ID at @date — from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_AccountType for label (e.g., Retail=1, Professional). (Tier 3 — DWH_dbo.Fact_SnapshotCustomer) |
| 7 | Revenue_Copy | decimal(38,2) | YES | Total copy trading revenue for this PI on @date = sum of all instrument-type revenue columns. Includes commissions (3-case UNION) + rollover fees (ActionTypeID=35) + crypto TicketFeeByPercent. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 8 | Revenue_Real_Stocks | decimal(38,2) | YES | Revenue from real stock copy positions — InstrumentTypeID IN (5,6), Leverage=1, IsBuy=1. Commission + rollover fees. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 9 | Revenue_CFD_Stocks | decimal(38,2) | YES | Revenue from CFD stock copy positions — InstrumentTypeID IN (5,6), Leverage>1 OR IsBuy=0 (leveraged or short). Commission + rollover fees. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 10 | Revenue_Real_Crypto | decimal(38,2) | YES | Revenue from settled (real) crypto copy positions — InstrumentTypeID=10, IsSettled=1. Commission + rollover fees + TicketFeeByPercent (added 2025-10-26). (Tier 2 — SP_CID_DailyCopyRevenue) |
| 11 | Revenue_CFD_Crypto | decimal(38,2) | YES | Revenue from CFD crypto copy positions — InstrumentTypeID=10, IsSettled=0. Commission + rollover fees + TicketFeeByPercent (added 2025-10-26). (Tier 2 — SP_CID_DailyCopyRevenue) |
| 12 | Revenue_FX | decimal(38,2) | YES | Revenue from FX copy positions — InstrumentTypeID=1. Commission + rollover fees. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 13 | Revenue_Comm | decimal(38,2) | YES | Revenue from commodities copy positions — InstrumentTypeID=2. Commission + rollover fees. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 14 | Revenue_Ind | decimal(38,2) | YES | Revenue from indices copy positions — InstrumentTypeID=4. Commission + rollover fees. (Tier 2 — SP_CID_DailyCopyRevenue) |
| 15 | UpdateDate | datetime | YES | SP execution timestamp — GETDATE() at DELETE+INSERT time. (Tier 2 — SP_CID_DailyCopyRevenue) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column / Expression | Transform |
|---------------|-------------------|---------------------------|-----------|
| Date | SP @date parameter | @date | Direct parameter passthrough |
| DateID | SP @date parameter | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Date → YYYYMMDD integer |
| ParentCID | DWH_dbo.Dim_Mirror | ParentCID | Passthrough — PI being copied |
| GuruStatusID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID at @date | Snapshot at reporting date via #CIDs0 |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID at @date | Snapshot at reporting date via #CIDs0 |
| AccountTypeID | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID at @date | Snapshot at reporting date via #CIDs0 |
| Revenue_Copy | DWH_dbo.Dim_Position, Fact_CustomerAction, Function_Revenue_TicketFeeByPercent | SUM of all instrument revenues | 3-case UNION commission + rollover + TicketFeeByPercent |
| Revenue_Real_Stocks | DWH_dbo.Dim_Position, Fact_CustomerAction | InstrumentTypeID IN (5,6), Leverage=1, IsBuy=1 | Commission + rollover |
| Revenue_CFD_Stocks | DWH_dbo.Dim_Position, Fact_CustomerAction | InstrumentTypeID IN (5,6), Leverage>1 OR IsBuy=0 | Commission + rollover |
| Revenue_Real_Crypto | DWH_dbo.Dim_Position, Fact_CustomerAction, Function_Revenue_TicketFeeByPercent | InstrumentTypeID=10, IsSettled=1 | Commission + rollover + TicketFeeByPercent |
| Revenue_CFD_Crypto | DWH_dbo.Dim_Position, Fact_CustomerAction, Function_Revenue_TicketFeeByPercent | InstrumentTypeID=10, IsSettled=0 | Commission + rollover + TicketFeeByPercent |
| Revenue_FX | DWH_dbo.Dim_Position, Fact_CustomerAction | InstrumentTypeID=1 | Commission + rollover |
| Revenue_Comm | DWH_dbo.Dim_Position, Fact_CustomerAction | InstrumentTypeID=2 | Commission + rollover |
| Revenue_Ind | DWH_dbo.Dim_Position, Fact_CustomerAction | InstrumentTypeID=4 | Commission + rollover |
| UpdateDate | ETL | GETDATE() | Set at SP execution time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (IsDepositor=1, IsValidCustomer=1 at @date)
  → #CIDs0 (all customers at @date, no validity filter — used for PI attributes)
  → #CIDs  (valid depositor copiers only — used for copier-side position filter)

DWH_dbo.Dim_Mirror (open copy relationships at @date: OpenDateID<=@date, CloseDateID=0|>=@date)
  → #mirror (CID=copier, ParentCID=guru, MirrorID=link)

DWH_dbo.Dim_Position (copy positions: MirrorID!=0, active on @date)
  → #pos (CID, PositionID, InstrumentID, IsSettled, IsBuy, Leverage, OpenDateID, CloseDateID,
          FullCommissionByUnits, FullCommissionOnClose)

BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@startDateINT, @endDateINT, 1)
  → #tfbp (PositionID → TicketFeeByPercent for crypto, added 2025-10-26)

DWH_dbo.Dim_Instrument → join to get InstrumentTypeID classification
  → #All_Positions: join #CIDs (copier filter) + #pos + Dim_Instrument + #tfbp

DWH_dbo.Fact_CustomerAction (ActionTypeID=35, IsFeeDividend=1, DateID=@date → rollover fees)

#CopyTotalRevenue (3-case UNION ALL commission + rollover, GROUP BY ParentCID):
  Case 1: Open+Close on @date       → FullCommissionOnClose
  Case 2: Open < @date, Close=@date → FullCommissionOnClose - FullCommissionByUnits
  Case 3: Open=@date, still open    → FullCommissionByUnits
  Case 4: Rollover                  → -Fact_CustomerAction.Amount (ActionTypeID=35)

JOIN #CIDs0 ON ParentCID=c0.CID → adds GuruStatusID, CountryID, AccountTypeID
  |
  |-- SP_CID_DailyCopyRevenue @date
  |     DELETE FROM BI_DB_DailyCopyRevenue WHERE DateID=@startDateINT
  |     + INSERT
  v
BI_DB_dbo.BI_DB_DailyCopyRevenue
  (7.2M rows | 2020-01-01–2026-04-12 | 2,294 dates | 58,592 distinct PIs)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID, GuruStatusID, AccountTypeID | DWH_dbo.Fact_SnapshotCustomer | PI snapshot attributes at reporting date (via #CIDs0); copier validity filter (IsDepositor, IsValidCustomer via #CIDs) |
| ParentCID, MirrorID | DWH_dbo.Dim_Mirror | Copier→PI mapping; determines which PIs have copy revenue |
| FullCommissionByUnits, FullCommissionOnClose | DWH_dbo.Dim_Position | Primary commission source for all revenue columns |
| Amount (rollover) | DWH_dbo.Fact_CustomerAction | Rollover fee source (ActionTypeID=35, IsFeeDividend=1) |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | Instrument type classification for revenue breakdown |
| TicketFeeByPercent | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Crypto percentage-based ticket fees (added 2025-10-26) |

### 6.2 Referenced By (other objects read from this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Join target for human-readable country name |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Join target for PI status tier label |
| AccountTypeID | DWH_dbo.Dim_AccountType | Join target for account type label |

---

## 7. Sample Queries

### 7.1 Top copy trading Popular Investors by revenue on a given date

```sql
SELECT
    ParentCID,
    Revenue_Copy,
    Revenue_Real_Stocks,
    Revenue_CFD_Stocks,
    Revenue_Real_Crypto,
    Revenue_CFD_Crypto,
    Revenue_FX,
    Revenue_Comm,
    Revenue_Ind
FROM BI_DB_dbo.BI_DB_DailyCopyRevenue
WHERE DateID = 20260412
ORDER BY Revenue_Copy DESC;
```

### 7.2 Monthly total copy revenue by instrument type

```sql
SELECT
    YEAR([Date]) AS yr,
    MONTH([Date]) AS mo,
    SUM(Revenue_Copy)        AS total,
    SUM(Revenue_Real_Stocks) AS real_stocks,
    SUM(Revenue_CFD_Stocks)  AS cfd_stocks,
    SUM(Revenue_Real_Crypto) AS real_crypto,
    SUM(Revenue_CFD_Crypto)  AS cfd_crypto,
    SUM(Revenue_FX)          AS fx,
    SUM(Revenue_Comm)        AS comm,
    SUM(Revenue_Ind)         AS ind
FROM BI_DB_dbo.BI_DB_DailyCopyRevenue
WHERE [Date] >= '2026-01-01'
GROUP BY YEAR([Date]), MONTH([Date])
ORDER BY yr, mo;
```

### 7.3 PI revenue with country name

```sql
SELECT
    r.DateID,
    r.ParentCID,
    dc.Name        AS Country,
    r.Revenue_Copy
FROM BI_DB_dbo.BI_DB_DailyCopyRevenue r
JOIN DWH_dbo.Dim_Country dc ON dc.CountryID = r.CountryID
WHERE r.DateID = 20260412
ORDER BY r.Revenue_Copy DESC;
```

### 7.4 Revenue by PI status tier (with label)

```sql
SELECT
    dgs.Name          AS GuruStatus,
    SUM(r.Revenue_Copy) AS total_revenue,
    COUNT(DISTINCT r.ParentCID) AS pi_count
FROM BI_DB_dbo.BI_DB_DailyCopyRevenue r
JOIN DWH_dbo.Dim_GuruStatus dgs ON dgs.GuruStatusID = r.GuruStatusID
WHERE r.DateID = 20260412
GROUP BY dgs.Name
ORDER BY total_revenue DESC;
```

---

## 8. Atlassian Knowledge Sources

*(No Confluence pages or Jira tickets linked at time of documentation.)*

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 0 T1, 12 T2, 3 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyCopyRevenue | Type: Table | Production Source: DWH_dbo.Dim_Position, Fact_SnapshotCustomer, Dim_Mirror, Fact_CustomerAction via SP_CID_DailyCopyRevenue*


### Upstream `BI_DB_dbo.DWH_CIDsDailyRisk` — synapse
- **Resolved as**: `BI_DB_dbo.DWH_CIDsDailyRisk`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\DWH_CIDsDailyRisk.md`

# BI_DB_dbo.DWH_CIDsDailyRisk

> 4.7B-row daily portfolio risk table storing the average hourly portfolio standard deviation for every customer — calculated using a Markowitz-style weighted portfolio covariance model with 24 hourly iterations per day, covering Jan 2013 to present. Sources: Dim_Position (holdings), Dim_Instrument_Correlation (covariance matrix), V_Liabilities + History.Credit (equity). Refreshed daily by SP_DWH_CIDsDailyRisk via DELETE+INSERT by FullDate. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_CIDsDailyRisk` from Dim_Position + Dim_Instrument_Correlation + equity sources |
| **Refresh** | Daily — DELETE WHERE FullDate=@date + INSERT. Accumulating by date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (PK on FullDate, CID — NOT ENFORCED) + 2 NCIs |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table calculates the **daily portfolio risk** for every eToro customer using a **Markowitz-style portfolio standard deviation model**. For each day, the SP loops through all 24 hours, computing the portfolio standard deviation at each hour based on:

1. **Position weights**: Each open position's notional value (amount × forex rate × direction × conversion) relative to the customer's realized equity
2. **Instrument correlations**: The inter-instrument covariance matrix from Dim_Instrument_Correlation (weekly, using the most recent matrix with SampleSize > 100)
3. **Portfolio variance**: `sqrt(SUM(Weight_a × Weight_b × Covariance_ab))` across all instrument pairs

The 4.7B rows cover daily snapshots from Jan 2013 to Apr 2026. Each row stores the average of all hourly STD calculations (AvgSTD) and the number of hours with valid data (HoursInSample, avg ~20 hours per customer per day).

This is the **most compute-intensive SP in BI_DB** — the hourly WHILE loop with cross-join portfolio covariance calculations runs for approximately 45-90 minutes per day. It is a sibling to DWH_CIDs7DaysDeviation (which averages this table's output over a 7-day window) and ultimately feeds the copy-trading risk management system.

---

## 2. Business Logic

### 2.1 Hourly Portfolio Risk Calculation

**What**: Computes portfolio standard deviation every hour using weighted instrument covariance.
**Columns Involved**: AvgSTD, HoursInSample
**Rules**:
- WHILE loop iterates from hour 1 to hour 24 of the given date
- At each hour: build weighted portfolio (position value / equity) → cross-join with covariance → sqrt(SUM(w_a × w_b × cov_ab))
- Only customers with RealizedEquity > 0 are included
- Covariance matrix: most recent weekly entry from Dim_Instrument_Correlation with SampleSize > 100
- Negative variance (rare rounding artifacts) clamped to 0 before sqrt

### 2.2 Position Weighting

**What**: Calculates the portfolio weight of each instrument position.
**Columns Involved**: (intermediate calculation)
**Rules**:
- Weight = AmountInUnitsDecimal × InitForexRate × direction(+1/-1) × conversionRate / RealizedEquity
- Direction: IsBuy='true' → +1, else -1
- Conversion: SellCurrencyID=1 → 1, BuyCurrencyID=1 → 1/InitForexRate, else use PositionChangeLog or InitConversionRate
- Equity source: V_Liabilities (previous day) UNION History.Credit (intraday, most recent before each hour)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with NOT ENFORCED PK + 2 NCIs. **4.7B rows — second largest in BI_DB_dbo.** NCI on FullDate supports date-filtered queries. NCI on (CID, FullDate, AvgSTD) supports customer risk lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Risk for a customer on a date | `WHERE CID = X AND FullDate = @date` |
| High-risk customers today | `WHERE FullDate = @date AND AvgSTD > 0.04763` |
| Customer risk trend | `WHERE CID = X ORDER BY FullDate` |
| Low data quality (few hours) | `WHERE HoursInSample < 12` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| BI_DB_dbo.DWH_CIDs7DaysDeviation | CID + FullDate | 7-day rolling average |

### 3.4 Gotchas

- **4.7B rows**: ALWAYS filter by FullDate. Unfiltered scans will timeout.
- **HoursInSample < 24**: If a customer had no open positions for some hours, those hours have no data. Average is only over hours WITH data.
- **AvgSTD = 0**: Can mean only one instrument in portfolio (no covariance) or near-zero position weights.
- **Negative covariance clamped**: The sqrt formula clamps negative variance to 0, which can understate risk for perfectly negatively correlated portfolios.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | NO | Snapshot date. The target date for hourly risk calculation. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 2 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 3 | AvgSTD | float | YES | Average hourly portfolio standard deviation for this customer on this date. Calculated using Markowitz portfolio variance: sqrt(SUM(Weight_a × Weight_b × Covariance_ab)). Higher values = more volatile portfolio. Average across all 24 hourly iterations. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 4 | HoursInSample | int | YES | Number of hourly iterations (out of 24) where this customer had valid data (open positions + positive equity). Average ~20. Lower values may indicate data gaps or intermittent position activity. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_DWH_CIDsDailyRisk. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| FullDate | SP parameter | @date | passthrough |
| CID | Dim_Position | CID | passthrough (grouped by) |
| AvgSTD | Dim_Position + Dim_Instrument + Dim_Instrument_Correlation + V_Liabilities + History.Credit | Portfolio weights × covariance | Markowitz portfolio STD, averaged over 24 hourly iterations |
| HoursInSample | — | — | COUNT of hourly iterations with data |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open positions, amounts, forex rates)
DWH_dbo.Dim_Instrument (currency pair metadata)
DWH_dbo.Dim_Instrument_Correlation (weekly covariance matrix)
DWH_dbo.V_Liabilities (previous day equity)
etoro.History.Credit (intraday equity changes)
etoro.History.PositionChangeLog (intraday rate updates)
  |
  |-- SP_DWH_CIDsDailyRisk @date (daily, ~45-90 min runtime)
  |   WHILE loop: 24 hourly iterations
  |   Per hour: weighted portfolio → covariance cross-join → sqrt(variance)
  |   Final: AVG(hourly_std), COUNT(hours)
  |   DELETE WHERE FullDate=@date + INSERT
  v
BI_DB_dbo.DWH_CIDsDailyRisk (4.7B rows, accumulating daily)
  |
  |-- BI_DB_dbo.DWH_CIDs7DaysDeviation (downstream: 7-day rolling average)
  v
BI_DB_dbo.BI_DB_WeeklyCopyBlock (risk score bucketing for copy blocks)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.DWH_CIDs7DaysDeviation | Downstream (indirectly — both read Fact_CustomerUnrealized_PnL) | 7-day rolling deviation average |

---

## 7. Sample Queries

### 7.1 Riskiest Customers Yesterday

```sql
SELECT TOP 20 CID, AvgSTD, HoursInSample
FROM BI_DB_dbo.DWH_CIDsDailyRisk
WHERE FullDate = CAST(GETDATE()-1 AS DATE)
ORDER BY AvgSTD DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found. Context: core risk calculation SP owned by BI team, feeds copy-trading risk management.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.DWH_CIDsDailyRisk | Type: Table | Production Source: SP_DWH_CIDsDailyRisk (Markowitz portfolio risk from Dim_Position + covariance)*


### Upstream `BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide.md`

# BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide

> Daily PI Dashboard comparison table storing ~3,400 rows per day for every active Popular Investor and CopyFund account, capturing KPI snapshots across performance (YTD/MTD/QTD gains), risk (7-day and 12-month risk scores), trading style (classification, trader type, holding time), portfolio composition (top instruments/industries), and financials (AUM, equity, commission). Covers 2020-01-01 to 2024-04-14 with 1,501 daily snapshots. Refreshed daily via SP_PI_Dashboard_COPYDATA_RuningSideBySide (DELETE+INSERT by Date).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` from Dim_Customer, DWH_GainDaily, BI_DB_CopyDailyData, DWH_CIDsDailyRisk, Dim_Position, and 10+ other sources |
| **Refresh** | Daily — DELETE WHERE Date=@yesterday + INSERT |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide` is a daily KPI dashboard snapshot table for all active **Popular Investors (PIs)** and **CopyFund accounts** on the eToro platform. Each row represents one PI or CopyFund on a given date, consolidating metrics from 15+ upstream tables into a single denormalized row for dashboard consumption.

The table serves as the primary data source for PI-vs-PI comparison dashboards, enabling side-by-side analysis of:
- **Performance**: YTD, QTD, MTD, last-month, and last-day compound returns; average yearly gain across all completed calendar years
- **Risk**: 7-day average risk score (matching platform display), highest average monthly risk in the last 12 months, current-month average risk score
- **Trading Style**: Classification (Long Equity, Multi-Strategy, Crypto, etc.), TraderType (Day/Swing/Medium/Long term), average holding time, average weekly trades
- **Portfolio Composition**: Largest asset class, top 3 traded instruments (all-time and current open), top 3 invested industries
- **Financials**: AUM (copy trading assets), total equity, past year commission
- **Status**: PI tier (Cadet through Elite Pro), blocked status

**Population**: Active PIs (GuruStatusID IN 2,3,4,5,6 AND IsValidCustomer=1) plus CopyFund accounts (AccountTypeID=9). ~3,391 rows on the latest date (2024-04-14): 3,215 PIs + 176 CopyFunds.

**ETL Pattern**: The SP maintains three incremental shadow tables (`BI_DB_PI_Positions`, `BI_DB_PI_GainDaily`, `BI_DB_PI_WeeklyTrades`) that cache position, gain, and trade data for PIs to avoid re-scanning the large DWH tables. On each run, new PIs are backfilled and yesterday's data is appended. The final INSERT joins ~15 temp tables to produce the denormalized output.

**Side effect**: The SP also appends to `BI_DB_PastYearsGain` on Jan 1 of each year (section 3.4 of the SP), capturing the trailing yearly gain for each customer.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Determines which customers appear in the dashboard.

**Columns Involved**: `CID`, `PI/CP`

**Rules**:
- Active Popular Investors: `GuruStatusID IN (2,3,4,5,6) AND IsValidCustomer = 1`
- CopyFund accounts: `AccountTypeID = 9` (regardless of GuruStatus)
- Population is derived from `Dim_Customer` joined to `Dim_GuruStatus`, `Dim_Country`, and `Dim_PlayerStatus`
- `PI/CP`: 'PI' for regular Popular Investors, 'CopyFund' for AccountTypeID=9 accounts

### 2.2 Classification — Open Position Asset Allocation

**What**: Categorizes each PI's trading strategy based on the asset class distribution of their current open positions.

**Columns Involved**: `Classification`

**Rules**:
```
Classification =
  WHEN Equity_Percent >= 0.7 AND Equity_Buy_Percent >= 0.2 AND Equity_Short_Percent >= 0.2
    → 'Long/Short Equity'
  WHEN Equity_Percent >= 0.7 AND Equity_Buy_Percent > 0.8
    → 'Long Equity'
  WHEN Currencies_Percent >= 0.7 → 'Currencies'
  WHEN Commodities_Percent >= 0.7 → 'Commodities'
  WHEN Crypto_Percent >= 0.7 → 'Crypto'
  WHEN ETF_Percent >= 0.7 → 'ETF'
  WHEN Total_invest = 0 → '100% cash balance'
  ELSE 'Multi-Strategy'
```
- Only manual positions (MirrorID=0) are considered for classification
- "Equity" in this context means InstrumentTypeID IN (5=Stocks, 4=Indices)
- Observed distribution (2024-04-14): Long Equity 56.4%, Multi-Strategy 24.4%, ETF 7.1%, Crypto 7.1%, 100% cash 2.4%, Currencies 1.2%, Long/Short Equity 1.2%, Commodities 0.2%

### 2.3 TraderType — Holding Time Segmentation

**What**: Classifies each PI by average holding time of their manual positions (last 2 years).

**Columns Involved**: `TraderType`, `Avgerage_Holding_Time`

**Rules**:
```
TraderType =
  WHEN AvgerageHoldingTime < 3 days    → 'Day trader'
  WHEN AvgerageHoldingTime >= 3 AND < 22 days  → 'Swing trader'
  WHEN AvgerageHoldingTime >= 22 AND < 94 days → 'Medium term investor'
  WHEN AvgerageHoldingTime >= 94 days  → 'Long term investor'
  DEFAULT (no closed positions)        → 'Long term investor'
```
- Holding time calculated as `DATEDIFF(mi, OpenOccurred, CloseOccurred) / 60 / 24` (in days)
- Both manual positions (MirrorID=0) and copy relationships (Dim_Mirror) are included
- Only closed positions in the last 2 years are considered
- Observed distribution (2024-04-14): Long term 50.7%, Medium term 34.4%, Swing 12.6%, Day 2.3%

### 2.4 Risk Score — Platform-Matching 7-Day Average

**What**: Computes a 1-10 risk score matching the eToro platform's display.

**Columns Involved**: `Acc_RiskIndex`, `Highest_AVG_12Months_Risk`, `AvgRiskScore_CurrentMonth`

**Rules**:
- Sources from `DWH_CIDsDailyRisk.AvgSTD` (daily portfolio standard deviation)
- STD is mapped to a 1-10 score via `External_etoro_Internal_RiskScore` band thresholds:
  - STD < 0.0011 → 1, < 0.0024 → 2, ..., >= 0.0475 → 10, no match → 0
- `Acc_RiskIndex`: ROUND(AVG(RiskScore)) over the last 7 days (matches platform display)
- `Highest_AVG_12Months_Risk`: MAX of monthly-average risk scores over the last 12 months
- `AvgRiskScore_CurrentMonth`: AVG(RiskScore) for dates in the current calendar month up to @yesterday

### 2.5 Average Yearly Gain

**What**: Computes lifetime average annual performance by combining completed calendar years with current YTD.

**Columns Involved**: `Avg_Yearly_gain`

**Rules**:
```
#AvgGain0 =
  SELECT year, CID, Gain_YTD FROM #YTD (current year's YTD gain)
  UNION ALL
  SELECT Year1, CID, Gain_y FROM BI_DB_PastYearsGain (completed past years)

Avg_Yearly_gain = AVG(Gain_y) per CID
```
- Includes the current partial year as YTD, averaged equally with completed years
- Gain values are decimal fractions (0.10 = 10% return)

### 2.6 Past Year Commission — Rolling 365-Day Window

**What**: Calculates copy-trading commission earned in the trailing 365-day window.

**Columns Involved**: `Past_Year_Commission`

**Rules**:
- Sources from `BI_DB_PI_Dashboard` (2 days ago) and `BI_DB_DailyCopyRevenue` (yesterday)
- Formula: `Prior_365d_commission_from_PI_Dashboard + Yesterday_Revenue_Copy`
- Uses LEAD window function to compute the rolling difference, then adds yesterday's daily copy revenue
- Result: cumulative copy trading commission for the past 365 days

### 2.7 IsBlocked — Active PI with Blocked Operations

**What**: Identifies PIs who have active copiers but are blocked from certain operations.

**Columns Involved**: `IsBlocked`

**Rules**:
- 'Yes' if CID appears in `External_etoro_Customer_BlockedCustomerOperations` (OperationTypeID=2) AND has active copiers in `etoroGeneral_History_GuruCopiers`
- 'No' otherwise
- Checks against the most recent block occurrence per CID

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution key, no clustered index. ~3,400 rows per daily slice; ~5.1M total rows across 1,501 dates. Always filter by `Date` to avoid full table scans. Date-filtered queries are fast given the modest per-day row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI dashboard for a specific date | `WHERE [Date] = @date ORDER BY AUM DESC` |
| Compare PI performance across dates | `WHERE CID = @cid ORDER BY [Date]` |
| Find high-risk PIs | `WHERE [Date] = @date AND Acc_RiskIndex >= 7` |
| PI classification distribution | `WHERE [Date] = @date GROUP BY Classification` |
| Top PIs by AUM | `WHERE [Date] = @date ORDER BY AUM DESC` |
| Swing traders with high YTD | `WHERE [Date] = @date AND TraderType = 'Swing trader' ORDER BY YTD DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in dashboard |
| BI_DB_dbo.BI_DB_CopyDailyData | ON CID + DateID | Detailed PI equity decomposition (CopyAUM, manual stocks/crypto) |
| BI_DB_dbo.BI_DB_DailyCopyRevenue | ON CID = ParentCID + Date | Revenue breakdown by instrument type |

### 3.4 Gotchas

- **Table name has a typo**: "RuningSideBySide" (should be "RunningSideBySide"). This is the authoritative DDL name.
- **Column name typo**: `Avgerage_Holding_Time` (should be "Average"). Use the exact spelling in queries.
- **Gain values are decimals, not percentages**: 0.2249 = 22.49% gain. Multiply by 100 for display.
- **Classification only uses manual positions**: MirrorID=0. Copy positions are excluded from the asset allocation calculation.
- **TraderType defaults to 'Long term investor'**: If a PI has no closed positions in the last 2 years, ISNULL defaults to 'Long term investor' rather than NULL.
- **Past_Year_Commission = 0 for many PIs**: Commission calculation depends on `BI_DB_PI_Dashboard` having a prior-day row with a hardcoded date filter. New PIs or PIs without matching records show 0.
- **AUM and Total_Equity can be NULL**: If the PI has no row in `BI_DB_CopyDailyData` for @yesterday, these values are NULL.
- **Data stops at 2024-04-14**: The table has not been refreshed since this date based on live data.
- **IsBlocked is a varchar 'Yes'/'No'**: Not a bit flag. Use `WHERE IsBlocked = 'Yes'` for filtering.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (Dim_Customer, Dim_Country, Dim_GuruStatus) |
| Tier 2 | SP-computed / ETL-derived |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (SP @yesterday parameter). DELETE+INSERT key. One row per PI per date. (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 2 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 4 | Name | nvarchar(101) | YES | PI display name: FirstName + ' ' + LastName from Dim_Customer. (Tier 2 — Dim_Customer) |
| 5 | PI_level | varchar(50) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 6 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 7 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 8 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Passthrough from Dim_Country. (Tier 2 — Ext_Dim_Country_Region_Desk) |
| 9 | PI/CP | varchar(13) | NO | PI category: 'PI' for active Popular Investors (GuruStatusID IN 2-6), 'CopyFund' for AccountTypeID=9 (Copy Portfolio accounts). Derived from Dim_Customer.AccountTypeID. (Tier 2 — Dim_Customer) |
| 10 | Largest_Asset_Class | varchar(50) | YES | Asset class with the highest total invested amount across all manual positions (MirrorID=0) in the PI's trade history. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. Determined by ROW_NUMBER on SUM(Amount) per InstrumentType. (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 11 | Top_3_Traded_Instruments | nvarchar(max) | YES | Comma-separated symbols of the top 3 instruments by total invested amount across all manual positions (full trade history). E.g., 'AAPL,MSFT,GOOGL'. (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 12 | YTD | float | YES | Year-to-date compound portfolio return as a decimal. 0.2249 = 22.49% gain. From Jan 1 to @yesterday. Passthrough from DWH_GainDaily.Gain_YTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 13 | MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to @yesterday. Passthrough from DWH_GainDaily.Gain_MTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 14 | Last_Day_Performance | float | YES | Daily compound portfolio return as a decimal for @yesterday. Single-day gain. Passthrough from DWH_GainDaily.Gain_d via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 15 | Positive_Months_percent | numeric(29,15) | YES | Fraction of months with positive returns (Gain_m > 0) out of all months the PI has gain data. 0.78 = 78% of months were profitable. Computed from BI_DB_PI_GainDaily monthly gain snapshots. (Tier 2 — DWH_GainDaily) |
| 16 | Avg_weekly_trades | numeric(38,6) | YES | Average number of new trades per week over the last 52 weeks. Computed as AVG(NewTrades) from BI_DB_PI_WeeklyTrades WHERE FirstDayOfWeek >= @yesterday - 1 year. (Tier 2 — BI_DB_CID_WeeklyPanel_FullData) |
| 17 | Avgerage_Holding_Time | numeric(38,2) | YES | Average position holding time in days for closed manual positions and copy relationships in the last 2 years. Calculated as AVG(DATEDIFF(minutes, Open, Close) / 60 / 24). Note: column name has typo ('Avgerage'). (Tier 2 — BI_DB_PI_Positions / Dim_Mirror) |
| 18 | Acc_RiskIndex | int | YES | Portfolio risk score 1-10, matching the eToro platform display. Computed as ROUND(AVG(RiskScore)) over the last 7 days, where RiskScore is mapped from DWH_CIDsDailyRisk.AvgSTD via External_etoro_Internal_RiskScore band thresholds. Higher score = more volatile portfolio. 0 = no data. (Tier 2 — DWH_CIDsDailyRisk) |
| 19 | Highest_AVG_12Months_Risk | numeric(38,6) | YES | Maximum of monthly-average risk scores over the last 12 months. Each month's average is the mean daily RiskScore for that calendar month. Identifies the PI's peak risk period. (Tier 2 — DWH_CIDsDailyRisk) |
| 20 | AUM | money | YES | Copy-trading AUM (Assets Under Management): total value managed through copy relationships. Passthrough from BI_DB_CopyDailyData.CopyAUM at @yesterday. NULL if no CopyDailyData row exists. (Tier 2 — BI_DB_CopyDailyData) |
| 21 | Total_Equity | decimal(23,4) | YES | PI's total equity: Liabilities + ActualNWA from V_Liabilities. Represents total account value including liabilities. Passthrough from BI_DB_CopyDailyData.TotalEquity at @yesterday. NULL if no CopyDailyData row exists. (Tier 2 — BI_DB_CopyDailyData) |
| 22 | Past_Year_Commission | money | YES | Cumulative copy-trading commission earned in the trailing 365-day window. Rolling calculation: prior day's 365-day commission from BI_DB_PI_Dashboard plus yesterday's Revenue_Copy from BI_DB_DailyCopyRevenue. 0 for PIs without matching prior records. (Tier 2 — BI_DB_PI_Dashboard / BI_DB_DailyCopyRevenue) |
| 23 | QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to @yesterday. Passthrough from DWH_GainDaily.Gain_QTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 24 | Last_Month_Performance | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. Passthrough from DWH_GainDaily.Gain_m via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 25 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 26 | Top_3_Traded_Instruments_yesteday | nvarchar(max) | YES | Comma-separated symbols of the top 3 instruments by invested amount among currently open manual positions only. Differs from Top_3_Traded_Instruments which uses full history. Note: column name has typo ('yesteday'). (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 27 | Avg_Yearly_gain | numeric(38,6) | YES | Average annual compound return across all completed calendar years plus the current year's YTD. Computed as AVG(Gain_y) from BI_DB_PastYearsGain UNION current YTD. Gain values are decimal fractions (0.10 = 10%). (Tier 2 — BI_DB_PastYearsGain / DWH_GainDaily) |
| 28 | Classification | nvarchar(50) | YES | PI trading strategy classification based on open manual position asset allocation. Values: 'Long Equity' (stocks/indices >= 70%, buy > 80%), 'Long/Short Equity' (stocks/indices >= 70%, mixed buy/sell), 'Currencies' (FX >= 70%), 'Commodities' (>= 70%), 'Crypto' (>= 70%), 'ETF' (>= 70%), '100% cash balance' (no open positions), 'Multi-Strategy' (no single asset class >= 70%). See section 2.2. (Tier 2 — BI_DB_PI_Positions / Dim_Instrument) |
| 29 | TraderType | nvarchar(50) | YES | PI trading style based on average holding time of closed positions in the last 2 years. Values: 'Day trader' (< 3 days), 'Swing trader' (3-22 days), 'Medium term investor' (22-94 days), 'Long term investor' (>= 94 days or no closed positions). See section 2.3. (Tier 2 — BI_DB_PI_Positions / Dim_Mirror) |
| 30 | IsBlocked | varchar(20) | YES | Whether this PI has blocked operations while still having active copiers. 'Yes' if CID appears in External_etoro_Customer_BlockedCustomerOperations (OperationTypeID=2) with active copiers; 'No' otherwise. (Tier 2 — External_etoro_Customer_BlockedCustomerOperations) |
| 31 | Top3TradedIndustries | nvarchar(50) | YES | Comma-separated top 3 industries by invested amount among currently open manual positions. E.g., 'Technology,Consumer Goods,Healthcare'. Based on Dim_Instrument.Industry for open positions (CloseDateID=0). (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 32 | AvgRiskScore_CurrentMonth | int | YES | Average daily risk score for the current calendar month up to @yesterday. Computed as ROUND(AVG(RiskScore)) for dates >= first of current month. Same band-mapping logic as Acc_RiskIndex but scoped to the current month. (Tier 2 — DWH_CIDsDailyRisk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @yesterday | Passthrough |
| CID | Dim_Customer | RealCID | Passthrough |
| UserName | Dim_Customer | UserName | Passthrough (dim-lookup) |
| Name | Dim_Customer | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| PI_level | Dim_GuruStatus | GuruStatusName | Passthrough (dim-lookup via GuruStatusID) |
| Country | Dim_Country | Name | Passthrough (dim-lookup via CountryID) |
| Region | Dim_Country | Region | Passthrough (dim-lookup via CountryID) |
| Desk | Dim_Country | Desk | Passthrough (dim-lookup via CountryID) |
| PI/CP | Dim_Customer | AccountTypeID | CASE: 9='CopyFund', else='PI' |
| Largest_Asset_Class | Dim_Instrument | InstrumentType | Top 1 by SUM(Amount) from BI_DB_PI_Positions (manual only) |
| Top_3_Traded_Instruments | Dim_Instrument | Symbol | STRING_AGG top 3 by Amount (full history, manual) |
| Top_3_Traded_Instruments_yesteday | Dim_Instrument | Symbol | STRING_AGG top 3 by Amount (open positions only) |
| YTD / QTD / MTD / Last_Month / Last_Day | DWH_GainDaily | Gain_YTD / QTD / MTD / m / d | Passthrough via BI_DB_PI_GainDaily |
| Positive_Months_percent | BI_DB_PI_GainDaily | Gain_m | COUNT(positive months) / COUNT(total months) |
| Avg_weekly_trades | BI_DB_PI_WeeklyTrades | NewTrades | AVG over last year |
| Avgerage_Holding_Time | BI_DB_PI_Positions + Dim_Mirror | OpenOccurred, CloseOccurred | AVG holding time in days (last 2 years) |
| Acc_RiskIndex | DWH_CIDsDailyRisk | AvgSTD | 7-day AVG of band-mapped RiskScore |
| Highest_AVG_12Months_Risk | DWH_CIDsDailyRisk | AvgSTD | MAX(monthly AVG RiskScore) over 12 months |
| AvgRiskScore_CurrentMonth | DWH_CIDsDailyRisk | AvgSTD | Current month AVG of band-mapped RiskScore |
| AUM | BI_DB_CopyDailyData | CopyAUM | Passthrough at @yesterday |
| Total_Equity | BI_DB_CopyDailyData | TotalEquity | Passthrough at @yesterday |
| Past_Year_Commission | BI_DB_PI_Dashboard + BI_DB_DailyCopyRevenue | Past_Year_Commission + Revenue_Copy | Rolling 365-day commission |
| Avg_Yearly_gain | BI_DB_PastYearsGain + DWH_GainDaily | Gain_y + Gain_YTD | AVG across all years + current YTD |
| Classification | BI_DB_PI_Positions + Dim_Instrument | Amount, InstrumentTypeID, IsBuy | CASE on asset class percentages |
| TraderType | BI_DB_PI_Positions + Dim_Mirror | OpenOccurred, CloseOccurred | CASE on AVG holding time |
| IsBlocked | External_etoro_Customer_BlockedCustomerOperations | OperationTypeID, CID | 'Yes'/'No' based on block + active copiers |
| Top3TradedIndustries | Dim_Instrument | Industry | STRING_AGG top 3 by Amount (open positions) |
| UpdateDate | SP | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer + Dim_GuruStatus + Dim_Country + Dim_PlayerStatus
  → #pop (PI/CopyFund population: ~3,400 CIDs)

DWH_dbo.Dim_Position → BI_DB_dbo.BI_DB_PI_Positions (incremental shadow cache)
  → #BI_DB_PI_Positions (manual positions, MirrorID=0)
  → #instrumntstype (largest asset class per CID)
  → #Top3instrumnts (top 3 symbols, full history)
  → #Top3openinstrumnts (top 3 symbols, open only)
  → #Top3openinstrumnts_industries (top 3 industries, open only)
  → #openpositions → #Clssification (asset allocation classification)
  → #hold1 → #avghold (avg holding time + TraderType)

BI_DB_dbo.DWH_GainDaily → BI_DB_dbo.BI_DB_PI_GainDaily (incremental shadow cache)
  → #GainDaily → #YTD (YTD/QTD/MTD/monthly/daily gains)
  → #positive_months → #positive_months_percent

BI_DB_dbo.BI_DB_PastYearsGain + #YTD
  → #AvgGain0 → #AvgGain (average yearly gain)

BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData → BI_DB_dbo.BI_DB_PI_WeeklyTrades (incremental shadow)
  → #Avg_weekly_trades

BI_DB_dbo.BI_DB_CopyDailyData → #CopyDailyData (PI_Level, TotalEquity, CopyAUM)
BI_DB_dbo.BI_DB_PI_Dashboard + BI_DB_DailyCopyRevenue → #Past_Year_Commission

BI_DB_dbo.DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore
  → #RiskAll → #RiskScore (7-day avg)
  → #MaxAvgRisk12Months (peak monthly risk)
  → #AvgRiskCurrentMonth (current month avg)

External_etoro_Customer_BlockedCustomerOperations + etoroGeneral_History_GuruCopiers
  → #BCO → #BI_DB_Guru_CopiersCID (blocked PI detection)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide @yesterday
  |     DELETE WHERE Date=@yesterday + INSERT (15-way LEFT JOIN)
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide
  (~3,400 rows/day | 2020-01-01 to 2024-04-14 | 1,501 dates)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | Terminal dashboard table; no known downstream consumers in SSDT |

---

## 7. Sample Queries

### 7.1 PI Dashboard for a Specific Date

```sql
SELECT CID, UserName, Name, PI_level, Country,
       [PI/CP], Classification, TraderType,
       YTD, MTD, Avg_Yearly_gain,
       Acc_RiskIndex, AUM, Total_Equity, Past_Year_Commission
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] = '2024-04-14'
ORDER BY AUM DESC;
```

### 7.2 PI Risk Distribution on Latest Date

```sql
SELECT Acc_RiskIndex, COUNT(*) AS PI_Count,
       AVG(CAST(YTD AS FLOAT)) AS Avg_YTD
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] = '2024-04-14'
  AND [PI/CP] = 'PI'
GROUP BY Acc_RiskIndex
ORDER BY Acc_RiskIndex;
```

### 7.3 Classification Distribution Over Time

```sql
SELECT [Date], Classification, COUNT(*) AS PI_Count
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] >= '2024-01-01'
  AND [PI/CP] = 'PI'
GROUP BY [Date], Classification
ORDER BY [Date], PI_Count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 5 T1, 27 T2, 0 T3, 0 T4, 0 T5 | Elements: 32/32, Logic: 9/10, Relationships: 6/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (multi-source ETL from Dim_Customer, DWH_GainDaily, BI_DB_CopyDailyData, DWH_CIDsDailyRisk)*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_PI_Dashboard_COPYDATA_RuningSideBySide] @yesterday [DATE] AS    
    
  
/********************************************************************************************    
Author:      Dan     
Date:        2020-03-31    
Description: Create a PI dashboard for compariing KPI's    
     
**************************    
** Change History    
**************************    
Date         Author       Description       
----------    ----------   ------------------------------------    
05-04-2020	 Dan			 Added 2 columns Top_3_Traded_Instruments_yesteday & Avg_Yearly_gain  
31-05-2020	 Dan			 Added Classification according to open positions and changed the avg holding to last year  
27-7-2020	 Dan			 Fixed bug in top3 instrument in open position  
23-9-2020	 Dan			 Added [IsBlocked] column  
19-10-2020	 Dan			 Match Risk score to Platform  
2021-01-05	 Daniel			 change source table from [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Customer].[BlockedCustomerOperations] to [dbo].[BI_DB_Blocked_Customer_Operations]   
2021-03-16	 Dan			Changed GurustatusID and update the definition for classification and trader type  
2021-03-21	 Shir           Added Top 3 invested Industries for each PI based on invested amount open positions only  
2021-04-13	 Dan			change date coumn to be @yesterday  
2022-02-15	 Tom			Replacing Retentionpanl with daily panel
2022-03-17	 Dan			Changing Union to Union All , replacing dailypanel with weekly for avg trades calc and using daily copy rev to calc commission
2022-06-23	 Bar			Add column AvgRiskScore_CurrentMonth / change risk score calculation 
2022-10-04	 Bar			Fix Zero devision
2024-02-08	 Tom			Migration to synapse
*********************************************************************************************/    
    
BEGIN    
  --exec [SP_PI_Dashboard] '20200504'  
--Declare @yesterday AS DATE = cast(getdate()-20 as date)    
DECLARE @yesterdayINT INT =CONVERT(CHAR(8),@yesterday, 112)    
DECLARE @FirstDayOfWeek DATE =  DATEADD(dd, -(DATEPART(dw, @yesterday)-1), @yesterday)    

/***********************************************************************************    
        Table of Content    
        ------------------    
1.  Creating PI population form Dim_customer    
2.1 Cheking for new PIs and importing the position to PI_Position table    
2.2 Filling PI_Position with new postion from yesterday    
2.3 Updating columns: Amount, close dates and FullCommissionByUnits    
2.4 Calculating largest asset class for each PI based on invested amount history    
2.5 Calculating Top 3 invested Instrumnts for each PI based on invested amount history    
2.6 Calculating Top 3 invested Instrumnts for each PI based on invested amount open positions only   
2.7 Calculating Top 3 invested Industries for each PI based on invested amount open positions only  
2.8 CID Classification according to open positions  
  
3.1 Cheking gain for new PIs and importing the gain data to PI_Gain table    
3.2 Filling PI_GainDaily with new Gain data from yesterday    
3.3 Calculating YTD,QTD,MTD,last month,last day gain past years gain    
3.4 Update past years gain     
3.5 Calculating avg positive months    
3.6 Calculating average holding time in the last year and defining Traded type  
3.7 Calculating Avg yearly Gain until yesterday  
    
4.1 Cheking Trades for new PIsand importing new trades data to PI_WeeklyTrades table    
4.2 Calculating AvgTrades per week in the last year    
    
5.1 Calculating the last Total AUM and PI KPIs in the past year from Copy daily data    
5.2 5.2 Calculating Risk Score and highest Avg.monthly risk in the last 12 months  
  
6.1 Adding Blocked indication  

*************************************************************************************/    
--1. Creating PI population form Dim_customer    
    
IF OBJECT_ID('tempdb..#pop') IS NOT NULL DROP TABLE #pop
CREATE TABLE #pop
WITH (DISTRIBUTION = HASH(RealCID),CLUSTERED INDEX(RealCID)) 
AS
SELECT dc.RealCID    
,dc.UserName    
,dc.FirstName+' '+dc.LastName AS [Name]     
,dgs.GuruStatusName    
,dc1.Name AS Country    
,dc1.Region    
,dc1.Desk    
,CASE WHEN dc.AccountTypeID=9 THEN 'CopyFund'    
ELSE 'PI' END AS [PI/CP]    
,dc.FirstDepositDate    
,dc.IsValidCustomer    
,dc.GuruStatusID    
,dc.AccountTypeID        
FROM [DWH_dbo].[Dim_Customer] dc with (NOLOCK)    
LEFT JOIN [DWH_dbo].[Dim_GuruStatus] dgs with (NOLOCK) ON dc.GuruStatusID = dgs.GuruStatusID    
LEFT JOIN [DWH_dbo].[Dim_Country] dc1  with (NOLOCK) ON dc.CountryID = dc1.CountryID    
LEFT JOIN [DWH_dbo].[Dim_PlayerStatus] dps with (NOLOCK) ON dc.PlayerStatusID = dps.PlayerStatusID  
WHERE (dc.AccountTypeID=9 OR (dc.GuruStatusID IN (2,3,4,5,6) AND dc.IsValidCustomer=1))    
    
   
    
--2.1 Cheking for new PIs and importing the position to PI_Position table    
IF OBJECT_ID('tempdb..#newPI') IS NOT NULL DROP TABLE #newPI
CREATE TABLE #newPI
WITH (DISTRIBUTION = HASH(RealCID),HEAP) 
AS   
SELECT DISTINCT dc.RealCID,dc.UserName,dc.AccountTypeID,dc.GuruStatusID,dc.IsValidCustomer    
FROM #pop dc     
LEFT JOIN [BI_DB_dbo].[BI_DB_PI_Positions] pdp with (NOLOCK)  
ON dc.RealCID = pdp.CID    
WHERE pdp.CID IS null    
  
  
DECLARE @newpi INT = (SELECT COUNT(*) FROM #newPI)
DECLARE @cid INT
SET @cid = (select top 1 CAST(RealCID AS INT) from #newPI order by CAST(RealCID AS INT) DESC)
--adding all position for new PIs    
IF @newpi>0
BEGIN
WHILE @cid is not NULL
BEGIN
INSERT INTO [BI_DB_dbo].[BI_DB_PI_Positions]    
   (PositionID    
   ,CID    
   ,InstrumentID    
   ,Leverage    
   ,Amount    
   ,IsBuy    
   ,OpenOccurred    
   ,CloseOccurred    
   ,ParentPositionID    
   ,OrigParentPositionID    
   ,MirrorID    
   ,OpenDateID    
   ,CloseDateID    
   ,Volume    
   ,FullCommissionOnCloseOrig    
   ,IsSettled    
   ,FullCommissionByUnits,    
   UpdateDate)    
SELECT dp.PositionID    
   ,dp.CID    
   ,dp.InstrumentID    
   ,dp.Leverage    
   ,dp.Amount    
   ,dp.IsBuy    
   ,dp.OpenOccurred    
   ,dp.CloseOccurred    
   ,dp.ParentPositionID    
   ,dp.OrigParentPositionID    
   ,dp.MirrorID    
   ,dp.OpenDateID    
   ,dp.CloseDateID    
   ,dp.Volume    
   ,dp.FullCommissionOnCloseOrig    
   ,dp.IsSettled    
   ,dp.FullCommissionByUnits,    
   getdate()    
FROM [DWH_dbo].[Dim_Position] dp with (NOLOCK)     
WHERE  CID = @cid

set @cid = (select top 1 RealCID from #newPI where RealCID <@cid order by RealCID DESC)
END
END

    
--2.2 Filling PI_Position with new postion from yesterday    
DELETE FROM [BI_DB_dbo].[BI_DB_PI_Positions] WHERE @yesterdayINT=OpenDateID    
    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_Positions]      
   (PositionID    
   ,CID    
   ,InstrumentID    
   ,Leverage    
   ,Amount    
   ,IsBuy    
   ,OpenOccurred    
   ,CloseOccurred    
   ,ParentPositionID    
   ,OrigParentPositionID    
   ,MirrorID    
   ,OpenDateID    
   ,CloseDateID    
   ,Volume    
   ,FullCommissionOnCloseOrig    
   ,IsSettled    
   ,FullCommissionByUnits  
   ,UpdateDate)    
SELECT dp.PositionID    
   ,dp.CID    
   ,dp.InstrumentID    
   ,dp.Leverage    
   ,dp.Amount    
   ,dp.IsBuy    
   ,dp.OpenOccurred    
   ,dp.CloseOccurred    
   ,dp.ParentPositionID    
   ,dp.OrigParentPositionID    
   ,dp.MirrorID    
   ,dp.OpenDateID    
   ,dp.CloseDateID    
   ,dp.Volume    
   ,dp.FullCommissionOnCloseOrig    
   ,dp.IsSettled    
   ,dp.FullCommissionByUnits    
   , getdate()  
FROM [DWH_dbo].[Dim_Position] dp with (NOLOCK)    
JOIN #pop p ON dp.CID=p.RealCID     
WHERE @yesterdayINT=dp.OpenDateID    
    
--2.3 Updating columns: Amount, close dates and FullCommissionByUnits    
UPDATE [BI_DB_dbo].[BI_DB_PI_Positions]  
SET Amount=b.Amount,    
 FullCommissionOnCloseOrig=b.FullCommissionOnCloseOrig,    
 FullCommissionByUnits=b.FullCommissionByUnits,    
 CloseOccurred=b.CloseOccurred,    
 CloseDateID=b.CloseDateID    
FROM [BI_DB_dbo].[BI_DB_PI_Positions] a  with (NOLOCK)  
JOIN [DWH_dbo].[Dim_Position] b with (NOLOCK) ON a.PositionID = b.PositionID    
WHERE a.CloseDateID<>b.CloseDateID     
OR a.Amount<>b.Amount     
OR a.FullCommissionByUnits<>b.FullCommissionByUnits    
    
    
--2.4 Calculating largest asset class for each PI based on his trade history    
IF OBJECT_ID('tempdb..#BI_DB_PI_Positions') IS NOT NULL DROP TABLE #BI_DB_PI_Positions
CREATE TABLE #BI_DB_PI_Positions
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT dp.PositionID
	  ,dp.CID
	  ,dp.InstrumentID
	  ,dp.Leverage
	  ,dp.Amount
	  ,dp.IsBuy
	  ,dp.OpenOccurred
	  ,dp.CloseOccurred
	  ,dp.ParentPositionID
	  ,dp.OrigParentPositionID
	  ,dp.MirrorID
	  ,dp.OpenDateID
	  ,dp.CloseDateID
	  ,dp.Volume
	  ,dp.FullCommissionOnCloseOrig
	  ,dp.IsSettled
	  ,dp.FullCommissionByUnits
	  ,dp.UpdateDate 
FROM [BI_DB_dbo].[BI_DB_PI_Positions] dp with (NOLOCK)  
JOIN #pop p 
ON dp.CID=p.RealCID    
WHERE dp.MirrorID =0 


IF OBJECT_ID('tempdb..#instrumntstype0') IS NOT NULL DROP TABLE #instrumntstype0
CREATE TABLE #instrumntstype0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS  
SELECT dp.CID    
,di.InstrumentType    
,SUM(dp.Amount) AS Amount    
,COUNT(dp.PositionID) AS Position_count    
,ROW_NUMBER() OVER(PARTITION BY dp.CID ORDER BY SUM(dp.Amount) DESC,COUNT(dp.PositionID) DESC) AS rn      
FROM #BI_DB_PI_Positions   dp
LEFT JOIN DWH_dbo.Dim_Instrument di 
ON dp.InstrumentID = di.InstrumentID    
GROUP BY dp.CID,di.InstrumentType    
    
    
IF OBJECT_ID('tempdb..#instrumntstype') IS NOT NULL DROP TABLE #instrumntstype
CREATE TABLE #instrumntstype
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT *		       
FROM #instrumntstype0    
WHERE rn=1    
    
    
--2.5 Calculating Top 3 invested Instrumnts for each PI based on invested amount history    
IF OBJECT_ID('tempdb..#Top3instrumnts0') IS NOT NULL DROP TABLE #Top3instrumnts0   
CREATE TABLE #Top3instrumnts0   
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS 
SELECT dp.CID
, dp.InstrumentID
,di.Symbol
,COUNT(dp.PositionID) AS Position_count
,SUM(dp.Amount) AS Amount
,ROW_NUMBER() OVER(PARTITION BY dp.CID ORDER BY SUM(dp.Amount) DESC,COUNT(dp.PositionID) DESC) AS rn     
FROM #BI_DB_PI_Positions dp WITH (NOLOCK)
LEFT JOIN [DWH_dbo].[Dim_Instrument] di WITH (NOLOCK)
ON dp.InstrumentID = di.InstrumentID    
GROUP BY dp.CID,dp.InstrumentID,di.Symbol    
  
    
IF OBJECT_ID('tempdb..#Top3instrumnts1') IS NOT NULL DROP TABLE #Top3instrumnts1  
CREATE TABLE #Top3instrumnts1  
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID,rn)) 
AS
SELECT *	      
FROM #Top3instrumnts0    
WHERE rn <=3    
    
IF OBJECT_ID('tempdb..#Top3instrumnts') IS NOT NULL DROP TABLE #Top3instrumnts  
CREATE TABLE #Top3instrumnts  
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT CID
	,STRING_AGG(Symbol,',')[Top3TradedInstruments] 
FROM #Top3instrumnts1  
group by CID
  
  
--2.6 Calculating Top 3 invested Instrumnts for each PI based on invested amount open positions only    
IF OBJECT_ID('tempdb..#Top3openinstrumnts0') IS NOT NULL DROP TABLE #Top3openinstrumnts0
CREATE TABLE #Top3openinstrumnts0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID,rn)) 
AS
SELECT dp.CID
,dp.InstrumentID
,di.Symbol
,COUNT(dp.PositionID) AS Position_count
,SUM(dp.Amount) AS Amount
,ROW_NUMBER() OVER(PARTITION BY dp.CID ORDER BY SUM(dp.Amount) DESC,COUNT(dp.PositionID) DESC) AS rn    
FROM #BI_DB_PI_Positions     dp
LEFT JOIN [DWH_dbo].[Dim_Instrument] di 
ON dp.InstrumentID = di.InstrumentID    
WHERE dp.CloseDateID=0  
GROUP BY dp.CID,dp.InstrumentID,di.Symbol    
    
IF OBJECT_ID('tempdb..#Top3openinstrumnts1') IS NOT NULL DROP TABLE #Top3openinstrumnts1
CREATE TABLE #Top3openinstrumnts1
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID,rn)) 
AS
SELECT *     
FROM #Top3openinstrumnts0    
WHERE rn <=3    
    
IF OBJECT_ID('tempdb..#Top3openinstrumnts') IS NOT NULL DROP TABLE #Top3openinstrumnts
CREATE TABLE #Top3openinstrumnts
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT CID
	,STRING_AGG(Symbol,',')[Top3TradedInstruments] 
FROM #Top3openinstrumnts1  
group by CID
  
  
  
--2.7 Calculating Top 3 invested Industries for each PI based on invested amount open positions only    
IF OBJECT_ID('tempdb..#Top3openinstrumnts_industries0') IS NOT NULL DROP TABLE #Top3openinstrumnts_industries0
CREATE TABLE #Top3openinstrumnts_industries0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS   
SELECT dp.CID
, di.Industry
,COUNT(dp.PositionID) AS Position_count
,SUM(dp.Amount) AS Amount, ROW_NUMBER() OVER(PARTITION BY dp.CID ORDER BY SUM(dp.Amount) DESC
,COUNT(dp.PositionID) DESC) AS rn     
FROM #BI_DB_PI_Positions  dp
LEFT JOIN [DWH_dbo].[Dim_Instrument] di 
ON dp.InstrumentID = di.InstrumentID    
WHERE dp.CloseDateID=0  
GROUP BY dp.CID,di.Industry  

  
IF OBJECT_ID('tempdb..#Top3openinstrumnts_industries1') IS NOT NULL DROP TABLE #Top3openinstrumnts_industries1
CREATE TABLE #Top3openinstrumnts_industries1
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID,rn)) 
AS
SELECT CID, ISNULL(Industry, 'NULL') Industry, Position_count, Amount, rn    
FROM #Top3openinstrumnts_industries0    
WHERE rn <=3    
    
IF OBJECT_ID('tempdb..#Top3openinstrumnts_industries') IS NOT NULL DROP TABLE #Top3openinstrumnts_industries
CREATE TABLE #Top3openinstrumnts_industries
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS 
SELECT CID
	,STRING_AGG(Industry,',')[Top3TradedIndustries]  
FROM #Top3openinstrumnts_industries1  
group by CID

--------------------------------------------------------  
--------------------------------------------------------  
  
  
--2.8 CID Classification according to open positions  
IF OBJECT_ID('tempdb..#openpositions') IS NOT NULL DROP TABLE #openpositions
CREATE TABLE #openpositions
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT bdpp.CID,bdpp.PositionID, bdpp.IsBuy,di.InstrumentTypeID,di.InstrumentType,bdpp.Amount  
FROM #BI_DB_PI_Positions  bdpp
JOIN DWH_dbo.Dim_Instrument di with (NOLOCK) 
ON bdpp.InstrumentID = di.InstrumentID  
WHERE bdpp.CloseDateID=0  
  
  
IF OBJECT_ID('tempdb..#Amount_invested_by_AssetType0') IS NOT NULL DROP TABLE #Amount_invested_by_AssetType0
CREATE TABLE #Amount_invested_by_AssetType0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT   CID  
  ,SUM(CASE WHEN InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END) AS Total_Equity_Amount  
  ,SUM(CASE WHEN InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END)/NULLIF(SUM(Amount),0) AS Equity_Percent  
  ,SUM(CASE WHEN InstrumentTypeID =1 THEN Amount ELSE 0 END) AS Total_Currencies_Amount  
  ,SUM(CASE WHEN InstrumentTypeID =1 THEN Amount ELSE 0 END)/NULLIF(SUM(Amount),0) AS Currencies_Percent  
  ,SUM(CASE WHEN InstrumentTypeID =2 THEN Amount ELSE 0 END) AS Total_Commodities_Amount  
  ,SUM(CASE WHEN InstrumentTypeID =2 THEN Amount ELSE 0 END)/NULLIF(SUM(Amount),0) AS Commodities_Percent  
  ,SUM(CASE WHEN InstrumentTypeID =6 THEN Amount ELSE 0 END) AS Total_ETF_Amount  
  ,SUM(CASE WHEN InstrumentTypeID =6 THEN Amount ELSE 0 END)/NULLIF(SUM(Amount),0) AS ETF_Percent  
  ,SUM(CASE WHEN InstrumentTypeID =10 THEN Amount ELSE 0 END) AS Total_Crypto_Amount  
  ,SUM(CASE WHEN InstrumentTypeID =10 THEN Amount ELSE 0 END)/NULLIF(SUM(Amount),0) AS Crypto_Percent  
  ,SUM(Amount) AS Total_invest  
FROM #openpositions  
GROUP BY CID  
  
  
  
IF OBJECT_ID('tempdb..#Amount_Equity') IS NOT NULL DROP TABLE #Amount_Equity
CREATE TABLE #Amount_Equity
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS  
SELECT   CID  
  ,SUM(CASE WHEN IsBuy = 1 AND InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END) AS Total_Buy  
  ,SUM(CASE WHEN IsBuy = 0 AND InstrumentTypeID IN(5,4)THEN Amount ELSE 0 END) AS Total_Short  
  ,SUM(CASE WHEN InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END) AS Total_Equity_Amount  
  ,COALESCE(SUM(CASE WHEN IsBuy = 1 THEN Amount ELSE 0 END) /NULLIF(SUM(CASE WHEN InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END),0),0) AS Equity_Buy_Percent  
  ,COALESCE(SUM(CASE WHEN IsBuy = 0 THEN Amount ELSE 0 END) /NULLIF(SUM(CASE WHEN InstrumentTypeID IN(5,4) THEN Amount ELSE 0 END),0),0) AS Equity_Short_Percent  
FROM #openpositions  
WHERE InstrumentTypeID IN(5,4)  
GROUP BY CID  
  
IF OBJECT_ID('tempdb..#Amount_invested_by_AssetType') IS NOT NULL DROP TABLE #Amount_invested_by_AssetType
CREATE TABLE #Amount_invested_by_AssetType
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT a.CID  
   ,a.Total_Equity_Amount  
   ,a.Equity_Percent  
   ,ISNULL(b.Total_Buy,0) AS Total_Buy  
   ,ISNULL(b.Equity_Buy_Percent,0) AS Equity_Buy_Percent  
   ,ISNULL(b.Total_Short,0) AS Total_Short  
   ,ISNULL(b.Equity_Short_Percent,0) AS Equity_Short_Percent  
   ,a.Total_Currencies_Amount  
   ,a.Currencies_Percent  
   ,a.Total_Commodities_Amount  
   ,a.Commodities_Percent  
   ,a.Total_ETF_Amount  
   ,a.ETF_Percent  
   ,a.Total_Crypto_Amount  
   ,a.Crypto_Percent  
   ,a.Total_invest     
FROM #Amount_invested_by_AssetType0 a  
LEFT JOIN #Amount_Equity b ON a.CID = b.CID  
  
IF OBJECT_ID('tempdb..#Clssification') IS NOT NULL DROP TABLE #Clssification
CREATE TABLE #Clssification
WITH (DISTRIBUTION = HASH(RealCID),CLUSTERED INDEX(RealCID)) 
AS 
SELECT p.RealCID  
   ,CASE WHEN a.Equity_Percent>=0.7 AND a.Equity_Buy_Percent>=0.2 AND a.Equity_Short_Percent>=0.2 THEN 'Long/Short Equity'  
      WHEN a.Equity_Percent>=0.7 AND a.Equity_Buy_Percent>0.8  THEN 'Long Equity'  
      WHEN a.Currencies_Percent>=0.7 THEN 'Currencies'  
      WHEN a.Commodities_Percent>=0.7 THEN 'Commodities'  
      WHEN a.Crypto_Percent>=0.7 THEN 'Crypto'  
      WHEN a.ETF_Percent>=0.7 THEN 'ETF'  
      WHEN ISNULL(a.Total_invest,0)=0 THEN '100% cash balance'  
   ELSE 'Multi-Strategy' END AS [Classification]  
FROM #pop p  
LEFT JOIN #Amount_invested_by_AssetType a ON p.RealCID=a.CID  
  
  
--3.1 Cheking gain for new PIs and importing the gain data to PI_Gain table    
IF OBJECT_ID('tempdb..#newPI_Gain') IS NOT NULL DROP TABLE #newPI_Gain
CREATE TABLE #newPI_Gain
WITH (DISTRIBUTION = HASH(RealCID),CLUSTERED INDEX(RealCID)) 
AS   
SELECT DISTINCT dc.RealCID,dc.AccountTypeID,dc.GuruStatusID,dc.IsValidCustomer     
FROM #pop dc     
LEFT JOIN BI_DB_dbo.BI_DB_PI_GainDaily pg with (NOLOCK)    
ON dc.RealCID = pg.CID    
WHERE pg.CID IS null    



    
DECLARE @newpig INT = (SELECT COUNT(*) FROM #newPI_Gain)    
--adding all daily gain for new PIs    
IF @newpig>0    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_GainDaily]    
(    
    Date    
   ,CID    
   ,Gain_w    
   ,Gain_m    
   ,Gain_q    
   ,Gain_h    
   ,Gain_y    
   ,UpdateDate    
   ,Gain_MTD    
   ,Gain_YTD    
   ,Gain_d    
   ,Gain_QTD    
)    
SELECT a.Date   
   ,a.CID    
   ,a.Gain_w    
   ,a.Gain_m    
   ,a.Gain_q    
   ,a.Gain_h    
   ,a.Gain_y    
   ,getdate()    
   ,a.Gain_MTD    
   ,a.Gain_YTD    
   ,a.Gain_d    
   ,a.Gain_QTD     
FROM BI_DB_dbo.DWH_GainDaily a with (NOLOCK)    
JOIN #newPI_Gain np 
ON a.CID=np.RealCID    
WHERE a.Date  <  @yesterday


    
--3.2 Filling PI_GainDaily with new Gain data from yesterday      
    
DELETE FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]  WHERE @yesterday=Date    
    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_GainDaily]    
(    
       Date    
   ,CID    
   ,Gain_w    
   ,Gain_m    
   ,Gain_q    
   ,Gain_h    
   ,Gain_y    
   ,UpdateDate    
   ,Gain_MTD    
   ,Gain_YTD    
   ,Gain_d    
   ,Gain_QTD     
)    
SELECT a.Date    
   ,a.CID    
   ,a.Gain_w    
   ,a.Gain_m    
   ,a.Gain_q    
   ,a.Gain_h    
   ,a.Gain_y    
   ,getdate()    
   ,a.Gain_MTD    
   ,a.Gain_YTD    
   ,a.Gain_d    
   ,a.Gain_QTD     
FROM [BI_DB_dbo].[DWH_GainDaily] a with (NOLOCK)    
JOIN #pop p ON a.CID=p.RealCID     
WHERE @yesterday=a.Date       

--3.3 Calculating YTD,QTD,MTD,last month,last day gain past years gain     
--Gain YTD, MTD and Yesterday    
IF OBJECT_ID('tempdb..#GainDaily') IS NOT NULL DROP TABLE #GainDaily
CREATE TABLE #GainDaily
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS   
SELECT a.*    
INTO #GainDaily    
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily] a with (NOLOCK)    
JOIN #pop p ON a.CID=p.RealCID    
WHERE  Date=@yesterday    
OR DAY(Date)=1    
    
    
IF OBJECT_ID('tempdb..#YTD') IS NOT NULL DROP TABLE #YTD
CREATE TABLE #YTD
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP) 
AS   
SELECT CID    
,YEAR(Date) AS [year]     
,ISNULL(Gain_YTD,0) AS Gain_YTD    
,ISNULL(Gain_QTD,0) AS Gain_QTD    
,ISNULL(Gain_MTD,0) AS Gain_MTD    
,ISNULL(Gain_m,0) AS Gain_m    
,ISNULL(Gain_d,0) AS Gain_d    
FROM #GainDaily    
WHERE Date=@yesterday    
    
--3.4 Update past years gain     
    
IF OBJECT_ID('tempdb..#FullDate') IS NOT NULL DROP TABLE #FullDate
CREATE TABLE #FullDate
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP) 
AS    
select FullDate     
from DWH_dbo.V_Dim_Date    
where DayNumberOfYear = 1    
    
INSERT INTO [BI_DB_dbo].[BI_DB_PastYearsGain] (    
Date    
,CID    
,Gain_y    
,Year1    
,UpdateDate    
)    
SELECT Date    
,CID    
,Gain_y    
,(YEAR(Date)-1) AS Year1    
,GETDATE() AS UpdateDate    
FROM [BI_DB_dbo].[DWH_GainDaily] a with (NOLOCK)    
join #FullDate b    
ON a.Date = b.FullDate AND a.Date =@yesterday    
      
--3.5 Calculating avg positive months    
    
IF OBJECT_ID('tempdb..#positive_months') IS NOT NULL DROP TABLE #positive_months 
CREATE TABLE #positive_months
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS    
SELECT CID ,COUNT(*) AS Num_positive_Months     
FROM #GainDaily     
WHERE  DAY(Date)=1 AND ISNULL(Gain_m,0) >0    
GROUP BY CID    
    
    
IF OBJECT_ID('tempdb..#total_months0') IS NOT NULL DROP TABLE #total_months0
CREATE TABLE #total_months0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT DISTINCT CID ,year(Date) AS year1,MONTH(Date) AS Month1      
FROM #GainDaily    
GROUP BY CID , year(Date),MONTH(Date)    
    
IF OBJECT_ID('tempdb..#total_months') IS NOT NULL DROP TABLE #total_months
CREATE TABLE #total_months
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID))  
AS    
SELECT CID,COUNT(*) AS Total_months     
FROM #total_months0    
GROUP BY CID    
    
    
IF OBJECT_ID('tempdb..#positive_months_percent') IS NOT NULL DROP TABLE #positive_months_percent
CREATE TABLE #positive_months_percent
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS	
SELECT a.CID    
,ISNULL(a.Total_months,0) AS Total_months,b.Num_positive_Months    
,ISNULL(b.Num_positive_Months,0)*1.00/a.Total_months*1.00 AS PositiveMonths_percent    
FROM #total_months a    
LEFT JOIN #positive_months b ON a.CID = b.CID    


--3.6 Calculating average holding time in the last year  
/***STEP 1 CALCULATING DATE DIFFERENCE***/    
IF OBJECT_ID('tempdb..#hold1') IS NOT NULL DROP TABLE #hold1
CREATE TABLE #hold1
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS	  
SELECT dp.CID    
,DATEDIFF(mi ,dp.OpenOccurred, dp.CloseOccurred) * 1.00 / 60 / 24 AS 'HoldingTime'    
FROM #pop p    
INNER JOIN #BI_DB_PI_Positions dp with (NOLOCK) ON p.RealCID = dp.CID    
AND dp.MirrorID = 0    
WHERE dp.CloseDateID <> 0 AND dp.OpenDateID >=CONVERT(CHAR(8),DATEADD(YEAR,-2,@yesterday), 112)    
    
UNION ALL
    
SELECT dm.CID    
,DATEDIFF(mi ,dm.OpenOccurred, dm.CloseOccurred) * 1.00 / 60 / 24 AS 'HoldingTime'    
FROM #pop p    
INNER JOIN [DWH_dbo].[Dim_Mirror] dm with (NOLOCK) ON p.RealCID = dm.CID    
WHERE dm.CloseDateID <> 0 AND dm.OpenDateID >=CONVERT(CHAR(8),DATEADD(YEAR,-2,@yesterday), 112)  
    
  
/***STEP 2 CALCULATING AVERAGE***/    
IF OBJECT_ID('tempdb..#avghold') IS NOT NULL DROP TABLE #avghold
CREATE TABLE #avghold
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS	
SELECT hd1.CID    
 ,CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) AS 'AvgerageHoldingTime'    
 ,CASE WHEN CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) >=3 AND CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) <22 THEN 'Swing trader'  
    WHEN CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) >=22 AND CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) <94 THEN 'Medium term investor'  
    WHEN CAST(AVG(hd1.HoldingTime) AS NUMERIC(38,2)) >=94 THEN 'Long term investor'  
    ELSE 'Day trader' END AS TraderType  
FROM #hold1 hd1    
GROUP BY hd1.CID    
  
  
 --3.7 Calculating Avg yearly Gain until yesterday  
IF OBJECT_ID('tempdb..#AvgGain0') IS NOT NULL DROP TABLE #AvgGain0
CREATE TABLE #AvgGain0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS	 
SELECT Y.year,CID,Y.Gain_YTD AS Gain_y    
FROM #YTD Y  
  
UNION  all
  
SELECT Year1,CID ,Gain_y  
FROM [BI_DB_dbo].[BI_DB_PastYearsGain] with (NOLOCK)  
  
IF OBJECT_ID('tempdb..#AvgGain') IS NOT NULL DROP TABLE #AvgGain
CREATE TABLE #AvgGain
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS 
SELECT CID,AVG(Gain_y) AS Avg_Yearly_gain  
FROM #AvgGain0  
GROUP BY CID  
  
  
--4.1 Cheking Trades for new PIs and importing new trades data to PI_WeeklyTrades table    
    
IF OBJECT_ID('tempdb..#newPITrade') IS NOT NULL DROP TABLE #newPITrade
CREATE TABLE #newPITrade
WITH (DISTRIBUTION = HASH(RealCID),CLUSTERED INDEX(RealCID)) 
AS    
SELECT DISTINCT dc.RealCID,dc.AccountTypeID,dc.GuruStatusID,dc.IsValidCustomer    
FROM #pop dc     
LEFT JOIN [BI_DB_dbo].[BI_DB_PI_WeeklyTrades] pdp with(NOLOCK)    
ON dc.RealCID = pdp.CID    
WHERE pdp.CID IS null    
 


DECLARE @newpitrade INT = (SELECT COUNT(*) FROM #newPITrade)    
--adding all position for new PIs    
IF @newpitrade>0    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_WeeklyTrades]   (
FirstDayOfWeek
,CID
,Week1
,Year1
,NewTrades
,UpdateDate
)
SELECT FirstDayOfWeek
,bdcwpfd.CID
,SSWeekNumberOfYear
,CalendarYear
,bdcwpfd.NewTrades_Total
,GETDATE()
FROM BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData bdcwpfd with(NOLOCK)
JOIN #newPITrade p 
ON bdcwpfd.CID=p.RealCID     
WHERE @yesterday > bdcwpfd.FirstDayOfWeek    

--filling PI_WeeklyTrades with new trades from yesterday    
DELETE FROM [BI_DB_dbo].[BI_DB_PI_WeeklyTrades] WHERE @FirstDayOfWeek=FirstDayOfWeek    
    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_WeeklyTrades]    
(    
FirstDayOfWeek
,CID
,Week1
,Year1
,NewTrades
,UpdateDate
)
SELECT FirstDayOfWeek
,bdcwpfd.CID
,SSWeekNumberOfYear
,CalendarYear
,bdcwpfd.NewTrades_Total
,GETDATE() 
FROM BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData bdcwpfd with(NOLOCK)
JOIN #pop p 
ON bdcwpfd.CID=p.RealCID     
WHERE @FirstDayOfWeek =  bdcwpfd.FirstDayOfWeek    

    
    

--4.2 Calculating AvgTrades per week in the last year    
IF OBJECT_ID('tempdb..#Avg_weekly_trades') IS NOT NULL DROP TABLE #Avg_weekly_trades
CREATE TABLE #Avg_weekly_trades
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS	
SELECT CID,AVG(a.NewTrades) AS Avg_weekly_trades       
FROM [BI_DB_dbo].[BI_DB_PI_WeeklyTrades] a with (NOLOCK) 
WHERE FirstDayOfWeek >= DATEADD(YEAR,-1,@yesterday)
GROUP BY CID   

    
  
--5.1 Calculating the last Total AUM and PI KPIs in the past year from Copy daily data    
IF OBJECT_ID('tempdb..#CopyDailyData') IS NOT NULL DROP TABLE #CopyDailyData
CREATE TABLE #CopyDailyData
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT 
bdcdd.CID    
,bdcdd.PI_Level    
,bdcdd.CopyType    
,bdcdd.Acc_RiskIndex    
,bdcdd.NumOfCopiers    
,bdcdd.TotalEquity    
,bdcdd.CopyAUM    
FROM BI_DB_dbo.BI_DB_CopyDailyData bdcdd with(NOLOCK)    
JOIN #pop p ON p.RealCID=bdcdd.CID    
WHERE bdcdd.DateID = @yesterdayINT


IF OBJECT_ID('tempdb..#Past_Year_Commission0') IS NOT NULL DROP TABLE #Past_Year_Commission0
CREATE TABLE #Past_Year_Commission0
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT bdpd.Date,bdpd.CID,bdpd.Past_Year_Commission 
FROM  BI_DB_dbo.BI_DB_PI_Dashboard bdpd with(NOLOCK) 
WHERE bdpd.Date IN (DATEADD(DAY,-2,@yesterday),DATEADD(DAY,-365,@yesterday))


IF OBJECT_ID('tempdb..#Past_Year_Commission1') IS NOT NULL DROP TABLE #Past_Year_Commission1
CREATE TABLE #Past_Year_Commission1
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT Date
	  ,CID
	  ,Past_Year_Commission
,LEAD(Past_Year_Commission,1,0) OVER (PARTITION BY CID ORDER BY Date) AS Past_Year_Commission_Clac
FROM #Past_Year_Commission0

IF OBJECT_ID('tempdb..#DailyCopyRevenue') IS NOT NULL DROP TABLE #DailyCopyRevenue
CREATE TABLE #DailyCopyRevenue
WITH (DISTRIBUTION = HASH(ParentCID),CLUSTERED INDEX(ParentCID)) 
AS
SELECT bddcr.ParentCID,bddcr.Revenue_Copy 
FROM BI_DB_dbo.BI_DB_DailyCopyRevenue bddcr with(NOLOCK) 
JOIN #pop pop
ON bddcr.ParentCID = pop.RealCID
WHERE bddcr.DateID = @yesterdayINT


IF OBJECT_ID('tempdb..#Past_Year_Commission') IS NOT NULL DROP TABLE #Past_Year_Commission
CREATE TABLE #Past_Year_Commission
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT ptc1.Date
	  ,ptc1.CID
	  ,ptc1.Past_Year_Commission_Clac + dcr.Revenue_Copy AS Past_Year_Commission
FROM #Past_Year_Commission1 ptc1
JOIN #DailyCopyRevenue dcr
ON ptc1.CID = dcr.ParentCID
WHERE ptc1.Date = '2021-03-14'

IF OBJECT_ID('tempdb..#AUM_Copiers_Eqtuiy') IS NOT NULL DROP TABLE #AUM_Copiers_Eqtuiy
CREATE TABLE #AUM_Copiers_Eqtuiy   
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT cdd.CID
	  ,PI_Level
	  ,CopyType
	  ,Acc_RiskIndex
	  ,NumOfCopiers
	  ,TotalEquity
	  ,CopyAUM 
	  ,ISNULL(pyc.Past_Year_Commission,0) AS Past_Year_Commission 
FROM #CopyDailyData cdd
LEFT JOIN #Past_Year_Commission pyc
ON cdd.CID = pyc.CID




--5.2 Calculating Risk Score and highest Avg.monthly risk in the last 12 months 

IF OBJECT_ID('tempdb..#riskPL') IS NOT NULL DROP TABLE #riskPL
CREATE TABLE #riskPL
WITH (DISTRIBUTION = ROUND_ROBIN,HEAP) 
AS	
SELECT RiskScore,MinValue,MaxValue
FROM [BI_DB_dbo].[External_etoro_Internal_RiskScore]

IF OBJECT_ID('tempdb..#RiskAll') IS NOT NULL DROP TABLE #RiskAll
CREATE TABLE #RiskAll
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT  LEFT(CD.FullDate,7) ClanderMonth  
       ,DATEPART(year, FullDate)*100+DATEPART(month, FullDate) MonthID  
    ,CD.FullDate  
    ,CD.CID  
    , ri.RiskScore as RiskScore   
FROM [BI_DB_dbo].[DWH_CIDsDailyRisk] CD with (NOLOCK)  
JOIN #pop p 
ON CD.CID=p.RealCID  
LEFT JOIN #riskPL  ri WITH (NOLOCK) 
 ON ROUND(CD.AvgSTD,4,1) BETWEEN MinValue AND MaxValue
WHERE CD.FullDate>=DATEADD(MONTH,-11,@yesterday)  
  

--risk score like on the platform avg risk of last 7 days.  

IF OBJECT_ID('tempdb..#RiskScore') IS NOT NULL DROP TABLE #RiskScore
CREATE TABLE #RiskScore
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS  
SELECT CID
,ROUND(AVG(RiskScore*1.00),0)  Acc_RiskIndex  
FROM #RiskAll  
WHERE FullDate>=DATEADD(DAY,-6,@yesterday)  
GROUP BY CID  


  
--Calculating highest Avg.monthly risk in the last 12 months. 
  
IF OBJECT_ID('tempdb..#avgrisk') IS NOT NULL DROP TABLE #avgrisk
CREATE TABLE #avgrisk
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS  
SELECT CID  
,ClanderMonth  
,AVG(RiskScore) AvgRiskScore 
FROM #RiskAll  
GROUP BY  CID,ClanderMonth  

IF OBJECT_ID('tempdb..#MaxAvgRisk12Months') IS NOT NULL DROP TABLE #MaxAvgRisk12Months
CREATE TABLE #MaxAvgRisk12Months
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
SELECT CID  
,MAX(AvgRiskScore) MaxAvgRiskScore  
FROM #avgrisk  
GROUP BY CID  


  
--Calculating current month Avg monthly risk score 
IF OBJECT_ID('tempdb..#AvgRiskCurrentMonth') IS NOT NULL DROP TABLE #AvgRiskCurrentMonth
CREATE TABLE #AvgRiskCurrentMonth
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS 
SELECT CID
,CAST(ROUND(Avg(RiskScore*1.0),0,1) AS INT) AvgRiskScore_CurrentMonth
from #RiskAll
where  FullDate >= DATEADD(mm, DATEDIFF(mm,0,@yesterday), 0)
and FullDate<=@yesterday
GROUP BY CID 

--  6.1 Adding Blocked PIs  
IF OBJECT_ID('tempdb..#BCO') IS NOT NULL DROP TABLE #BCO
CREATE TABLE #BCO
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
Select CID,BlockReasonID,Occurred,OperationTypeID    
From [BI_DB_dbo].[External_etoro_Customer_BlockedCustomerOperations]
Where OperationTypeID = 2  
  

IF OBJECT_ID('tempdb..#BI_DB_Guru_Copiers') IS NOT NULL DROP TABLE #BI_DB_Guru_Copiers  
CREATE TABLE #BI_DB_Guru_Copiers  
WITH (DISTRIBUTION = HASH(ParentCID),CLUSTERED INDEX(ParentCID)) 
AS  
select DISTINCT g.ParentUserName  
,g.ParentCID  
from [general].[etoroGeneral_History_GuruCopiers] g With(NOLOCK)  
Where partition_date = CAST(DateAdd(Day,-1,@yesterday) As Date)  
 
  
IF OBJECT_ID('tempdb..#BI_DB_Guru_CopiersCID') IS NOT NULL DROP TABLE #BI_DB_Guru_CopiersCID 
CREATE TABLE #BI_DB_Guru_CopiersCID 
WITH (DISTRIBUTION = HASH(CID),CLUSTERED INDEX(CID)) 
AS
Select bco.CID, Max(Occurred) As MaxOccurred  
From #BCO bco With(NOLOCK)  
Join #BI_DB_Guru_Copiers guru  
on bco.CID = guru.ParentCID  
Group By bco.CID  
  

/*************************************Insert INTO BI_DB Table**************************************************/    
DELETE FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide] WHERE [Date]= @yesterday    
  
  
--Final    
INSERT INTO [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]    
           ([Date]    
           ,[CID]    
           ,[UserName]    
           ,[Name]    
           ,[PI_level]    
           ,[Country]    
           ,[Region]    
           ,[Desk]    
           ,[PI/CP]  
     ,[IsBlocked]  
     ,[Classification]  
     ,[TraderType]  
           ,[Largest_Asset_Class]    
     ,[Top3TradedIndustries]  
           ,[Top_3_Traded_Instruments]    
     ,[Top_3_Traded_Instruments_yesteday]  
     ,[Avg_Yearly_gain]  
           ,[YTD]    
           ,[QTD]    
           ,[MTD]    
           ,[Last_Month_Performance]    
           ,[Last_Day_Performance]    
           ,[Positive_Months_percent]    
           ,[Avg_weekly_trades]    
           ,[Avgerage_Holding_Time]    
           ,[Acc_RiskIndex]    
           ,[Highest_AVG_12Months_Risk]    
           ,[AUM]    
           ,[Total_Equity]    
           ,[Past_Year_Commission]    
           ,[UpdateDate]  
		   ,AvgRiskScore_CurrentMonth
     )    
       
SELECT  @yesterday AS [Date]     
       ,p.RealCID AS CID    
    ,p.UserName AS UserName    
    ,p.Name AS Name    
    ,p.GuruStatusName AS [PI_level]    
    ,p.Country AS Country    
    ,p.Region AS Region    
    ,p.Desk AS Desk    
    ,p.[PI/CP] AS [PI/CP]  
    ,CASE WHEN gb.CID IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsBlocked  
    ,c.[Classification]  
    ,ISNULL(a.TraderType, 'Long term investor')  
    ,i.InstrumentType AS Largest_Asset_Class    
    ,[Top3TradedIndustries]   
    ,t.Top3TradedInstruments AS Top_3_Traded_Instruments   
    ,t1.Top3TradedInstruments AS Top_3_Traded_Instruments_yesteday  
    ,ag.Avg_Yearly_gain  
    ,y.Gain_YTD AS YTD    
    ,y.Gain_QTD AS QTD    
    ,y.Gain_MTD AS MTD    
    ,y.Gain_m  AS Last_Month_Performance    
    ,y.Gain_d  AS Last_Day_Performance    
    ,pmp.PositiveMonths_percent AS Positive_Months_percent    
    ,at.Avg_weekly_trades AS Avg_weekly_trades    
    ,a.AvgerageHoldingTime AS Avgerage_Holding_Time    
    ,CAST(rs.Acc_RiskIndex AS INT) AS Acc_RiskIndex    
    ,mar.MaxAvgRiskScore AS Highest_AVG_12Months_Risk    
    ,ace.CopyAUM AS AUM    
    ,ace.TotalEquity AS Total_Equity    
    ,ace.Past_Year_Commission as Past_Year_Commission    
    ,GETDATE() AS UpdateDate
	,arcm.AvgRiskScore_CurrentMonth
FROM #pop p    
LEFT JOIN #instrumntstype i ON p.RealCID = i.CID    
LEFT JOIN #Top3instrumnts t ON p.RealCID = t.CID   
LEFT JOIN #Top3openinstrumnts_industries ind  ON p.RealCID = ind.CID  
LEFT JOIN #Top3openinstrumnts t1 ON p.RealCID = t1.CID   
LEFT JOIN #YTD y ON p.RealCID=y.CID    
LEFT JOIN #positive_months_percent pmp ON p.RealCID = pmp.CID    
LEFT JOIN #avghold a ON p.RealCID=a.CID    
LEFT JOIN #Avg_weekly_trades at ON p.RealCID=at.CID    
--LEFT JOIN #Avg_monthly_risk r ON p.RealCID=r.CID   
LEFT JOIN #AvgGain ag ON p.RealCID = ag.CID  
LEFT JOIN #AUM_Copiers_Eqtuiy ace ON p.RealCID = ace.CID    
LEFT JOIN #Clssification c ON p.RealCID=c.RealCID  
LEFT JOIN #BI_DB_Guru_CopiersCID gb ON p.RealCID=gb.CID    
LEFT JOIN #RiskScore rs ON p.RealCID=rs.CID  
LEFT JOIN #MaxAvgRisk12Months mar ON p.RealCID=mar.CID  
LEFT JOIN #AvgRiskCurrentMonth arcm ON  p.RealCID=arcm.CID
  
END    
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` | synapse_sp | BI_DB_dbo | SP_PI_Dashboard_COPYDATA_RuningSideBySide | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide.sql` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_GuruStatus` | synapse | DWH_dbo | Dim_GuruStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_PI_GainDaily` | synapse | BI_DB_dbo | BI_DB_PI_GainDaily | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PI_GainDaily.md` |
| `BI_DB_dbo.DWH_GainDaily` | synapse | BI_DB_dbo | DWH_GainDaily | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\DWH_GainDaily.md` |
| `DWH_dbo.V_Dim_Date` | synapse | DWH_dbo | V_Dim_Date | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Dim_Date.md` |
| `DWH_dbo.Dim_Mirror` | synapse | DWH_dbo | Dim_Mirror | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `BI_DB_dbo.BI_DB_PastYearsGain` | synapse | BI_DB_dbo | BI_DB_PastYearsGain | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PastYearsGain.md` |
| `BI_DB_dbo.BI_DB_PI_WeeklyTrades` | unresolved | BI_DB_dbo | BI_DB_PI_WeeklyTrades | `—` |
| `BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_WeeklyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_WeeklyPanel_FullData.md` |
| `BI_DB_dbo.BI_DB_CopyDailyData` | synapse | BI_DB_dbo | BI_DB_CopyDailyData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CopyDailyData.md` |
| `BI_DB_dbo.BI_DB_PI_Dashboard` | unresolved | BI_DB_dbo | BI_DB_PI_Dashboard | `—` |
| `BI_DB_dbo.BI_DB_DailyCopyRevenue` | synapse | BI_DB_dbo | BI_DB_DailyCopyRevenue | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCopyRevenue.md` |
| `BI_DB_dbo.External_etoro_Internal_RiskScore` | unresolved | BI_DB_dbo | External_etoro_Internal_RiskScore | `—` |
| `BI_DB_dbo.DWH_CIDsDailyRisk` | synapse | BI_DB_dbo | DWH_CIDsDailyRisk | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\DWH_CIDsDailyRisk.md` |
| `BI_DB_dbo.External_etoro_Customer_BlockedCustomerOperations` | unresolved | BI_DB_dbo | External_etoro_Customer_BlockedCustomerOperations | `—` |
| `general.etoroGeneral_History_GuruCopiers` | unresolved | general | etoroGeneral_History_GuruCopiers | `—` |
| `BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide` | synapse | BI_DB_dbo | BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide.md` |
