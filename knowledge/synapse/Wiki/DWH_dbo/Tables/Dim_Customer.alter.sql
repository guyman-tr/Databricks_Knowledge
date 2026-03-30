-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Customer
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
-- Resolved via: Wiki property table
-- Classification: PII Masked
-- Secondary UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer  (PII unmasked)
-- Masked Columns: Email,FirstName,LastName,FullName,City,Address,PhoneNumber,MobileNumber,ZipCode,TaxId,BirthDate,NationalID,ExternalId,FullAddress
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked SET TBLPROPERTIES (
    'comment' = '`Dim_Customer` is the DWH''s central customer master table - the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer. The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle. Two UC copies exist: - **Masked**: `main.dwh.gold_...dim_customer_masked` - PII columns contain masked values, accessible to general analytics - **Unmasked**: `main.pii_data.gold_...dim_customer` - full PII, restricted access ### Business Usage - **Regulatory Reporting**: Confluence "Business & Regulatory Undert'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DemoCID COMMENT 'Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN OriginalCID COMMENT 'Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ExternalID COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName_Lower COMMENT 'Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstName COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LastName COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN MiddleName COMMENT 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BirthDate COMMENT 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Email COMMENT 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Phone COMMENT 'Phone number from production Customer.CustomerStatic. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IP COMMENT 'Registration IP address. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Zip COMMENT 'Postal code. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN City COMMENT 'City in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Address COMMENT 'Street address in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Separate from Address for structured address storage. (Tier 1 - Customer.CustomerStatic)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AffiliateID COMMENT 'Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CampaignID COMMENT 'Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SubChannelID COMMENT 'Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LabelID COMMENT 'Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BannerID COMMENT 'Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FunnelID COMMENT 'Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FunnelFromID COMMENT 'Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DownloadID COMMENT 'Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ReferralID COMMENT 'Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SubSerialID COMMENT 'Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegisteredReal COMMENT 'Account registration date (renamed from Registered). Default=getdate(). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegisteredDemo COMMENT 'Demo account registration date. Source unclear - may be populated separately. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountExpirationDate COMMENT 'Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountStatusID COMMENT 'Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusID COMMENT 'Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusReasonID COMMENT 'Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusSubReasonID COMMENT 'Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PendingClosureStatusID COMMENT 'Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerLevelID COMMENT 'Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountTypeID COMMENT 'Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsDepositor COMMENT 'Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstDepositAmount COMMENT 'Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegulationID COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DesignatedRegulationID COMMENT 'Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegulationChangeDate COMMENT 'Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CountryID COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CountryIDByIP COMMENT 'Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CitizenshipCountryID COMMENT 'Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN POBCountryID COMMENT 'Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegionID COMMENT 'Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegionByIP_ID COMMENT 'Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DocsOK COMMENT 'Whether required documents are verified. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DocumentStatusID COMMENT 'Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsAddressProof COMMENT 'Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsAddressProofExpiryDate COMMENT 'Expiry date of address proof document. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsIDProof COMMENT 'Whether ID proof document is on file (1/0). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsIDProofExpiryDate COMMENT 'Expiry date of ID proof document. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SuitabilityTestStatusID COMMENT 'MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN MifidCategorizationID COMMENT 'MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ScreeningStatusID COMMENT 'Compliance screening status. Updated from ScreeningService. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WorldCheckID COMMENT 'Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WorldCheckResultsUpdated COMMENT 'When World-Check results were last updated. Preserved from previous row. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsEDD COMMENT 'Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Bankruptcy COMMENT 'Bankruptcy flag. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsValidCustomer COMMENT 'DWH-computed: 1 when not Popular Investor (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsCreditReportValidCB COMMENT 'DWH-computed: similar to IsValidCustomer but with additional AccountTypeID != 2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskStatusID COMMENT 'Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskClassificationID COMMENT 'Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EmployeeAccount COMMENT '1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LanguageID COMMENT 'Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CommunicationLanguageID COMMENT 'Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsEmailVerified COMMENT 'Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PrivacyPolicyID COMMENT 'Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsCopyBlocked COMMENT '1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GuruStatusID COMMENT 'eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfGurus COMMENT 'Number of Popular Investors this customer is copying. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfCopiers COMMENT 'Number of customers copying this customer''s trades. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfRAF COMMENT 'Number of successful Refer-A-Friend referrals. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SocialConnectID COMMENT 'Social media connection type. DEFAULT=0. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PremiumAccount COMMENT 'Whether this is a premium account. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Evangelist COMMENT 'Whether this customer is an evangelist/ambassador. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN HasAvatar COMMENT 'Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AvatarUploadDate COMMENT 'When the avatar was uploaded. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EvMatchStatus COMMENT 'Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountManagerID COMMENT 'Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UpdateDate COMMENT 'ETL load/update timestamp (GETDATE()). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SalesForceAccountID COMMENT 'Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN 2FA COMMENT 'Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerifiedID COMMENT 'Result code of phone number verification process. NULL if not yet attempted. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneNumber COMMENT 'Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsPhoneVerified COMMENT 'Whether phone is verified (VerificationStatusID IN (1,2) -> 1). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerificationDate COMMENT 'Date phone was verified. ''1900-01-01'' if not verified. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ApexID COMMENT 'APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyID COMMENT 'Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyStatusID COMMENT 'Tangany integration status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EquiLendID COMMENT 'EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN StocksLendingStatusID COMMENT 'Stocks lending consent status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltID COMMENT 'Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltStatusID COMMENT 'DLT integration status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN HasWallet COMMENT '1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDPlatformID COMMENT 'Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDTransactionID COMMENT 'Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDRecoveryDate COMMENT 'Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CashoutFeeGroupID COMMENT 'Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WeekendFeePrecentage COMMENT 'Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 - Customer.CustomerStatic)';
-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN OriginalCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ExternalID SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName_Lower SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LastName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN MiddleName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BirthDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Email SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Phone SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Zip SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN City SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Address SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BuildingNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SubChannelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BannerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FunnelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FunnelFromID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DownloadID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ReferralID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SubSerialID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegisteredDemo SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountExpirationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerStatusSubReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PendingClosureStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DesignatedRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegulationChangeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CitizenshipCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN POBCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RegionByIP_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DocsOK SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DocumentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsAddressProof SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsAddressProofExpiryDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsIDProof SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsIDProofExpiryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SuitabilityTestStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ScreeningStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WorldCheckID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WorldCheckResultsUpdated SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsEDD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Bankruptcy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EmployeeAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CommunicationLanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsEmailVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsCopyBlocked SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfGurus SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfCopiers SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN NumOfRAF SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SocialConnectID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PremiumAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Evangelist SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN HasAvatar SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AvatarUploadDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EvMatchStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SalesForceAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN 2FA SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerifiedID SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsPhoneVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerificationDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ApexID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EquiLendID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN StocksLendingStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN HasWallet SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDPlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDRecoveryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CashoutFeeGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WeekendFeePrecentage SET TAGS ('pii' = 'none');

-- === Secondary UC Target (PII unmasked) ===
-- Column comments are identical - meaning is the same regardless of masking.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer SET TBLPROPERTIES (
    'comment' = '`Dim_Customer` is the DWH''s central customer master table - the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer. The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle. Two UC copies exist: - **Masked**: `main.dwh.gold_...dim_customer_masked` - PII columns contain masked values, accessible to general analytics - **Unmasked**: `main.pii_data.gold_...dim_customer` - full PII, restricted access ### Business Usage - **Regulatory Reporting**: Confluence "Business & Regulatory Undert'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DemoCID COMMENT 'Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN OriginalCID COMMENT 'Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ExternalID COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName_Lower COMMENT 'Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstName COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LastName COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN MiddleName COMMENT 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BirthDate COMMENT 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Email COMMENT 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Phone COMMENT 'Phone number from production Customer.CustomerStatic. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IP COMMENT 'Registration IP address. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Zip COMMENT 'Postal code. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN City COMMENT 'City in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Address COMMENT 'Street address in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Separate from Address for structured address storage. (Tier 1 - Customer.CustomerStatic)';

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AffiliateID COMMENT 'Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CampaignID COMMENT 'Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SubChannelID COMMENT 'Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LabelID COMMENT 'Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BannerID COMMENT 'Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FunnelID COMMENT 'Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FunnelFromID COMMENT 'Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DownloadID COMMENT 'Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ReferralID COMMENT 'Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SubSerialID COMMENT 'Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegisteredReal COMMENT 'Account registration date (renamed from Registered). Default=getdate(). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegisteredDemo COMMENT 'Demo account registration date. Source unclear - may be populated separately. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountExpirationDate COMMENT 'Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountStatusID COMMENT 'Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusID COMMENT 'Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusReasonID COMMENT 'Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusSubReasonID COMMENT 'Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PendingClosureStatusID COMMENT 'Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerLevelID COMMENT 'Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountTypeID COMMENT 'Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsDepositor COMMENT 'Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstDepositAmount COMMENT 'Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegulationID COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DesignatedRegulationID COMMENT 'Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegulationChangeDate COMMENT 'Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CountryID COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CountryIDByIP COMMENT 'Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CitizenshipCountryID COMMENT 'Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN POBCountryID COMMENT 'Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegionID COMMENT 'Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegionByIP_ID COMMENT 'Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DocsOK COMMENT 'Whether required documents are verified. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DocumentStatusID COMMENT 'Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsAddressProof COMMENT 'Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsAddressProofExpiryDate COMMENT 'Expiry date of address proof document. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsIDProof COMMENT 'Whether ID proof document is on file (1/0). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsIDProofExpiryDate COMMENT 'Expiry date of ID proof document. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SuitabilityTestStatusID COMMENT 'MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN MifidCategorizationID COMMENT 'MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ScreeningStatusID COMMENT 'Compliance screening status. Updated from ScreeningService. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WorldCheckID COMMENT 'Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WorldCheckResultsUpdated COMMENT 'When World-Check results were last updated. Preserved from previous row. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsEDD COMMENT 'Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Bankruptcy COMMENT 'Bankruptcy flag. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsValidCustomer COMMENT 'DWH-computed: 1 when not Popular Investor (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsCreditReportValidCB COMMENT 'DWH-computed: similar to IsValidCustomer but with additional AccountTypeID != 2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskStatusID COMMENT 'Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskClassificationID COMMENT 'Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EmployeeAccount COMMENT '1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LanguageID COMMENT 'Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CommunicationLanguageID COMMENT 'Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsEmailVerified COMMENT 'Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PrivacyPolicyID COMMENT 'Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsCopyBlocked COMMENT '1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GuruStatusID COMMENT 'eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfGurus COMMENT 'Number of Popular Investors this customer is copying. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfCopiers COMMENT 'Number of customers copying this customer''s trades. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfRAF COMMENT 'Number of successful Refer-A-Friend referrals. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SocialConnectID COMMENT 'Social media connection type. DEFAULT=0. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PremiumAccount COMMENT 'Whether this is a premium account. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Evangelist COMMENT 'Whether this customer is an evangelist/ambassador. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN HasAvatar COMMENT 'Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AvatarUploadDate COMMENT 'When the avatar was uploaded. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EvMatchStatus COMMENT 'Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountManagerID COMMENT 'Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UpdateDate COMMENT 'ETL load/update timestamp (GETDATE()). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SalesForceAccountID COMMENT 'Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN 2FA COMMENT 'Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerifiedID COMMENT 'Result code of phone number verification process. NULL if not yet attempted. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneNumber COMMENT 'Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsPhoneVerified COMMENT 'Whether phone is verified (VerificationStatusID IN (1,2) -> 1). (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerificationDate COMMENT 'Date phone was verified. ''1900-01-01'' if not verified. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ApexID COMMENT 'APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyID COMMENT 'Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyStatusID COMMENT 'Tangany integration status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EquiLendID COMMENT 'EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN StocksLendingStatusID COMMENT 'Stocks lending consent status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltID COMMENT 'Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltStatusID COMMENT 'DLT integration status. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN HasWallet COMMENT '1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDPlatformID COMMENT 'Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDTransactionID COMMENT 'Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDRecoveryDate COMMENT 'Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CashoutFeeGroupID COMMENT 'Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WeekendFeePrecentage COMMENT 'Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 - Customer.CustomerStatic)';
-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN OriginalCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ExternalID SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName_Lower SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstName SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LastName SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN MiddleName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BirthDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Email SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Phone SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IP SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Zip SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN City SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Address SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BuildingNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SubChannelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BannerID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FunnelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FunnelFromID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DownloadID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ReferralID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SubSerialID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegisteredDemo SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountExpirationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerStatusSubReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PendingClosureStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DesignatedRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegulationChangeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CitizenshipCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN POBCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegionID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RegionByIP_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DocsOK SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DocumentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsAddressProof SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsAddressProofExpiryDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsIDProof SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsIDProofExpiryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SuitabilityTestStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ScreeningStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WorldCheckID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WorldCheckResultsUpdated SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsEDD SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Bankruptcy SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EmployeeAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CommunicationLanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsEmailVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsCopyBlocked SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfGurus SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfCopiers SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN NumOfRAF SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SocialConnectID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PremiumAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Evangelist SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN HasAvatar SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AvatarUploadDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EvMatchStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SalesForceAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN 2FA SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerifiedID SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsPhoneVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerificationDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ApexID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EquiLendID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN StocksLendingStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN HasWallet SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDPlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDRecoveryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CashoutFeeGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WeekendFeePrecentage SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:21:22 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 432/432 succeeded
-- ====================
