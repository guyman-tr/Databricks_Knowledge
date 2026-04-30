# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits]
(
	[RealCID] [int] NULL,
	[CompensationAmount] [money] NULL,
	[#ofDeposits] [int] NULL,
	[DepositAmount$] [money] NULL,
	[Compensation$/Deposits$] [decimal](18, 0) NULL,
	[PlayerStatus] [varchar](max) NULL,
	[PlayerStatusReason] [varchar](max) NULL,
	[PlayerStatusSubReason] [varchar](max) NULL,
	[LastDepositDate] [datetime] NULL,
	[#OfDeposits24hrs] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[DepositAmount$24hrs] [varchar](max) NULL
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

Found 4 upstream wiki(s). Read EACH one in full.


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


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_H_OPS_HighCompensationsVsDeposits`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_OPS_HighCompensationsVsDeposits.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_H_OPS_HighCompensationsVsDeposits] AS

begin

declare @dt date = dateadd(day, -31, convert(date, getdate()))
--check if running flag is zero if yes continue else break
---Update running flag
--select @dt

IF OBJECT_ID('tempdb..#dailydepositors') IS NOT NULL
DROP TABLE #dailydepositors
CREATE TABLE #dailydepositors
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
	SELECT 
	DISTINCT fbd.CID
FROM [BI_DB_dbo].[External_etoro_Billing_Deposit] fbd
WHERE 
	fbd.PaymentStatusID=2 --Approved#
	AND ModificationDate >=@dt


IF OBJECT_ID('tempdb..#repeatdeposits1') IS NOT NULL
DROP TABLE #repeatdeposits1
CREATE TABLE #repeatdeposits1
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
	SELECT 
	DISTINCT fbd.CID,
	 COUNT(fbd.DepositID) AS #OfDeposits24hrs,
	 SUM(fbd.Amount*fbd.ExchangeRate) AS DepositAmount$24hrs

FROM [BI_DB_dbo].[External_etoro_Billing_Deposit] fbd
JOIN [BI_DB_dbo].[External_etoro_Billing_Funding_Datafactory] Fund ON Fund.FundingID=fbd.FundingID
WHERE 
	fbd.PaymentStatusID=2 --Approved#
	AND Fund.FundingTypeID IN (
	29,--	ACH
	32,--	PWMB
	35,--	Trustly
	15,--Sofort
	11--Giropay
	)
	AND  fbd.ModificationDate >=dateadd(day,-1,getdate())
	GROUP BY fbd.CID


IF OBJECT_ID('tempdb..#repeatdeposits') IS NOT NULL
DROP TABLE #repeatdeposits
CREATE TABLE #repeatdeposits
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT * 
FROM #repeatdeposits1 
where
#OfDeposits24hrs>3

--IF OBJECT_ID('tempdb..#comps') IS NOT NULL
--DROP TABLE #comps
--CREATE TABLE #comps
--WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
--AS


--SELECT
--fca.CID AS RealCID,
--COUNT(fca.CID) AS #ofCompensations,
--SUM(fca.Payment) AS CompensationAmount

--FROM [BI_DB_dbo].[SP_Create_External_etoro_history_credit] fca
--JOIN #dailydepositors d ON d.CID=fca.CID
--WHERE
--fca.CreditTypeID=6 --Compensation
--AND fca.CompensationReasonID=7 --Deposit Adjustment
--and fca.Payment<0
--GROUP BY
--fca.CID
--HAVING COUNT(fca.CID)>3 and SUM(fca.Payment)<-2000

EXEC [BI_DB_dbo].[SP_Create_External_etoro_history_credit] @dt, 'Pavlina'

IF OBJECT_ID('tempdb..#comps') IS NOT NULL 
DROP TABLE #comps
CREATE TABLE #comps  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT 
	c.CID AS RealCID,
	COUNT(c.CID) AS #ofCompensations,
	SUM(c.Payment) AS CompensationAmount
	FROM  [BI_DB_dbo].[External_etoro_history_credit_Pavlina] c
    --LEFT JOIN [BI_DB_dbo].[External_etoro_BackOffice_CompensationReason] cr  ON cr.CompensationReasonID=c.CompensationReasonID
	JOIN #dailydepositors d ON d.CID=c.CID
    WHERE c.CreditTypeID=6--Compensation
	AND c.CompensationReasonID=7 --Deposit Adjustment
	and c.Payment<0
   -- AND  c.Occurred = @dt
	--AND  CAST(c.Occurred AS DATE) = @Date
	GROUP BY
	c.CID
	HAVING COUNT(c.CID)>3 and SUM(c.Payment)<-2000

	--select * from #comps
	
	
	

IF OBJECT_ID('tempdb..#deps') IS NOT NULL
DROP TABLE #deps
CREATE TABLE #deps
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

	SELECT 
	fbd.CID,
	COUNT(fbd.DepositID) AS #ofDeposits,
	SUM(fbd.Amount*fbd.ExchangeRate) AS DepositAmount$
FROM [BI_DB_dbo].[External_etoro_Billing_Deposit] fbd
JOIN #dailydepositors c ON c.CID=fbd.CID
WHERE 
	fbd.PaymentStatusID=2 --Approved#
GROUP BY 
	fbd.CID
HAVING 	SUM(fbd.Amount*fbd.ExchangeRate)>0


IF OBJECT_ID('tempdb..#lastdeposit') IS NOT NULL
DROP TABLE #lastdeposit
CREATE TABLE #lastdeposit
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

	SELECT 
	fbd.CID,
	MAX(ModificationDate) AS LastDepositDate

FROM[BI_DB_dbo].[External_etoro_Billing_Deposit] fbd
JOIN #dailydepositors c ON c.CID=fbd.CID
WHERE 
	fbd.PaymentStatusID=2 --Approved#
GROUP BY 
	fbd.CID

IF OBJECT_ID('tempdb..#FINAL') IS NOT NULL
DROP TABLE #FINAL
CREATE TABLE #FINAL
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
	d.CID AS RealCID,
	c.#ofCompensations,
	-c.CompensationAmount AS CompensationAmount,
	d.#ofDeposits,
	d.DepositAmount$,
	(-c.CompensationAmount/d.DepositAmount$) AS [Compensation$/Deposits$],
	dps.Name AS PlayerStatus,
	dpsr.Name AS PlayerStatusReason,
	dpssr.PlayerStatusSubReasonName AS PlayerStatusSubReason,
	bdcd.LastDepositDate,
	ISNULL(r.#OfDeposits24hrs,0) AS #OfDeposits24hrs,
	ISNULL(r.DepositAmount$24hrs,0) AS [DepositAmount$24hrs],
	CASE WHEN r.CID IS NULL THEN 'HighCompensationToDeposits Ratio' ELSE '>3DepositsLast24hrs' END AS [Category],
	GETDATE() AS UpdateDate

FROM #deps  d
LEFT JOIN  #comps c ON c.RealCID=d.CID
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=d.CID
LEFT JOIN DWH_dbo.Dim_PlayerStatus dps ON dps.PlayerStatusID=dc.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr ON dpsr.PlayerStatusReasonID=dc.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr ON dpssr.PlayerStatusSubReasonID=dc.PlayerStatusSubReasonID
LEFT JOIN #lastdeposit bdcd ON bdcd.CID=d.CID
LEFT JOIN #repeatdeposits r ON r.CID=d.CID
WHERE 
(
(-c.CompensationAmount/d.DepositAmount$)>0.5 OR r.#OfDeposits24hrs>3
)
AND dc.IsValidCustomer=1


Truncate TABLE [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits]

insert into [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits]
(
[RealCID],
[CompensationAmount],
[#ofDeposits],
[DepositAmount$],
[Compensation$/Deposits$],
[PlayerStatus],
[PlayerStatusReason],
[PlayerStatusSubReason],
[LastDepositDate],
[#OfDeposits24hrs],
[UpdateDate],
[DepositAmount$24hrs]
)

SELECT

[RealCID],
[CompensationAmount],
[#ofDeposits],
[DepositAmount$],
[Compensation$/Deposits$],
[PlayerStatus],
[PlayerStatusReason],
[PlayerStatusSubReason],
[LastDepositDate],
[#OfDeposits24hrs],
[UpdateDate],
[DepositAmount$24hrs]
FROM #FINAL


---update running flag to zero
END



GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_H_OPS_HighCompensationsVsDeposits` | synapse_sp | BI_DB_dbo | SP_H_OPS_HighCompensationsVsDeposits | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_H_OPS_HighCompensationsVsDeposits.sql` |
| `BI_DB_dbo.External_etoro_Billing_Deposit` | unresolved | BI_DB_dbo | External_etoro_Billing_Deposit | `—` |
| `BI_DB_dbo.External_etoro_Billing_Funding_Datafactory` | unresolved | BI_DB_dbo | External_etoro_Billing_Funding_Datafactory | `—` |
| `BI_DB_dbo.External_etoro_history_credit_Pavlina` | unresolved | BI_DB_dbo | External_etoro_history_credit_Pavlina | `—` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_PlayerStatusReasons` | synapse | DWH_dbo | Dim_PlayerStatusReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | synapse | DWH_dbo | Dim_PlayerStatusSubReasons | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
