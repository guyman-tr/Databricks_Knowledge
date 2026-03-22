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
    'comment' = '`Dim_Customer` is the DWH''s central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer. The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle. Two UC copies exist: - **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics - **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access ### Business Usage - **Regulatory Reporting**: Confluence "Business & Regulatory Undert'
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DemoCID COMMENT 'Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN OriginalCID COMMENT 'Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ExternalID COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column COMMENT 'Description';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UserName_Lower COMMENT 'Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FirstName COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LastName COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN MiddleName COMMENT 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BirthDate COMMENT 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Email COMMENT 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Phone COMMENT 'Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IP COMMENT 'Registration IP address. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Zip COMMENT 'Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN City COMMENT 'City in Unicode. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Address COMMENT 'Street address in Unicode. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN OriginalCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ExternalID SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EmployeeAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CommunicationLanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsEmailVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsCopyBlocked SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN SalesForceAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN 2FA SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerifiedID SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN IsPhoneVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN PhoneVerificationDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN ApexID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN TanganyStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN EquiLendID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN StocksLendingStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN DltStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN HasWallet SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDPlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN FTDRecoveryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN CashoutFeeGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ALTER COLUMN WeekendFeePrecentage SET TAGS ('pii' = 'none');

-- === Secondary UC Target (PII unmasked) ===
-- Column comments are identical — meaning is the same regardless of masking.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer SET TBLPROPERTIES (
    'comment' = '`Dim_Customer` is the DWH''s central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer. The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle. Two UC copies exist: - **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics - **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access ### Business Usage - **Regulatory Reporting**: Confluence "Business & Regulatory Undert'
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DemoCID COMMENT 'Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN OriginalCID COMMENT 'Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ExternalID COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column COMMENT 'Description';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UserName_Lower COMMENT 'Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FirstName COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LastName COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN MiddleName COMMENT 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BirthDate COMMENT 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Email COMMENT 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Phone COMMENT 'Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IP COMMENT 'Registration IP address. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Zip COMMENT 'Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN City COMMENT 'City in Unicode. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Address COMMENT 'Street address in Unicode. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic)';

-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN OriginalCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ExternalID SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EmployeeAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CommunicationLanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsEmailVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsCopyBlocked SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN SalesForceAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN 2FA SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerifiedID SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN IsPhoneVerified SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN PhoneVerificationDate SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN ApexID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN TanganyStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN EquiLendID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN StocksLendingStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN DltStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN HasWallet SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDPlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN FTDRecoveryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN CashoutFeeGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer ALTER COLUMN WeekendFeePrecentage SET TAGS ('pii' = 'none');
