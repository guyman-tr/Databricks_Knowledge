-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotCustomer_FromDateID
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
-- Resolved via: Wiki property table
-- Classification: PII Masked
-- Secondary UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid  (PII unmasked)
-- Masked Columns: 
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN FromDateID COMMENT 'Start date of the customer snapshot range (YYYYMMDD integer). (Tier 2 - view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN ToDateID COMMENT 'End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 - view DDL)';
-- NOTE: Inherited Fact_SnapshotCustomer columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotCustomer.md and are applied via that table's alter.sql.

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
-- NOTE: Inherited column PII tags omitted (same reason as above).

-- === Secondary UC Target (PII unmasked) ===
-- Column comments are identical - meaning is the same regardless of masking.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the customer snapshot range (YYYYMMDD integer). (Tier 2 - view DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 - view DDL)';
-- NOTE: Inherited Fact_SnapshotCustomer columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotCustomer.md and are applied via that table's alter.sql.

-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
-- NOTE: Inherited column PII tags omitted (same reason as above).

-- == LAST EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Fix: Removed invalid 'All Fact_SnapshotCustomer columns' ALTER COLUMN lines (bulk wildcard not valid SQL).
-- Statements: 12/12 succeeded
-- ====================

-- ============================================================
-- Inherited from Fact_SnapshotCustomer (propagated 2026-04-12)
-- Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
-- 52 column(s) | source: knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.alter.sql
-- ============================================================

-- ---- Column Comments (inherited) ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GCID` COMMENT 'Global Customer ID - the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RealCID` COMMENT 'Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DemoCID` COMMENT '[UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer - legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CustomerChangeTypeID` COMMENT '[UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP - retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CurentValue` COMMENT '[UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PreviousValue` COMMENT '[UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CountryID` COMMENT 'Customer''s registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LabelID` COMMENT 'Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LanguageID` COMMENT 'Customer''s preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `VerificationLevelID` COMMENT 'KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocsOK` COMMENT '[UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusID` COMMENT 'Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Bankruptcy` COMMENT '[UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskStatusID` COMMENT 'Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskClassificationID` COMMENT 'Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CommunicationLanguageID` COMMENT 'Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PremiumAccount` COMMENT '[UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Evangelist` COMMENT '[UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GuruStatusID` COMMENT 'Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `UpdateDate` COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegulationID` COMMENT 'Customer''s assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID - end-of-day change. See section 2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountStatusID` COMMENT 'Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountManagerID` COMMENT 'Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerLevelID` COMMENT 'Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountTypeID` COMMENT 'Account type (e.g., 7=Employee Account, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DateRangeID` COMMENT 'SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See section 2.1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsDepositor` COMMENT '1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PendingClosureStatusID` COMMENT 'Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocumentStatusID` COMMENT 'KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `SuitabilityTestStatusID` COMMENT 'MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `MifidCategorizationID` COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsEmailVerified` COMMENT '1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsValidCustomer` COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See section 2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DesignatedRegulationID` COMMENT 'Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `EvMatchStatus` COMMENT 'eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegionID` COMMENT 'Customer''s geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusReasonID` COMMENT 'Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsCreditReportValidCB` COMMENT '1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See section 2.3. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AffiliateID` COMMENT 'Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Email` COMMENT 'Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName=''DelUserName*''. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `City` COMMENT 'Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Address` COMMENT 'Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Zip` COMMENT 'Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PhoneNumber` COMMENT 'Customer phone number. PII: not DDL-masked but GDPR-erased to ''DelPhoneNumber_XXXXXXX'' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsPhoneVerified` COMMENT '1 if the customer''s phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PhoneVerificationDateID` COMMENT 'Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID=''19000101'' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusSubReasonID` COMMENT 'Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `WeekendFeePrecentage` COMMENT 'Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DltStatusID` COMMENT 'DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DltID` COMMENT 'DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `EquiLendID` COMMENT 'EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `StocksLendingStatusID` COMMENT 'Status of the customer''s stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer)';

-- ---- Column PII Tags (inherited) ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DemoCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CustomerChangeTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CurentValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PreviousValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LabelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `VerificationLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocsOK` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Bankruptcy` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskClassificationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CommunicationLanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PremiumAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Evangelist` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GuruStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountManagerID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DateRangeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsDepositor` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PendingClosureStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocumentStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `SuitabilityTestStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `MifidCategorizationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsEmailVerified` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DesignatedRegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `EvMatchStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsCreditReportValidCB` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AffiliateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Email` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `City` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Address` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Zip` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PhoneNumber` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsPhoneVerified` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PhoneVerificationDateID` SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusSubReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `WeekendFeePrecentage` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DltStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DltID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `EquiLendID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `StocksLendingStatusID` SET TAGS ('pii' = 'none');

-- == PROPAGATION EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Statements: 104/104 succeeded
-- ====================

-- ============================================================
-- Inherited from Fact_SnapshotCustomer (propagated 2026-04-12)
-- Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid
-- 52 column(s) | source: knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.alter.sql
-- ============================================================

-- ---- Column Comments (inherited) ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GCID` COMMENT 'Global Customer ID - the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RealCID` COMMENT 'Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DemoCID` COMMENT '[UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer - legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CustomerChangeTypeID` COMMENT '[UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP - retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CurentValue` COMMENT '[UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PreviousValue` COMMENT '[UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CountryID` COMMENT 'Customer''s registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LabelID` COMMENT 'Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LanguageID` COMMENT 'Customer''s preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `VerificationLevelID` COMMENT 'KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocsOK` COMMENT '[UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusID` COMMENT 'Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Bankruptcy` COMMENT '[UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskStatusID` COMMENT 'Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskClassificationID` COMMENT 'Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CommunicationLanguageID` COMMENT 'Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PremiumAccount` COMMENT '[UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Evangelist` COMMENT '[UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GuruStatusID` COMMENT 'Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `UpdateDate` COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegulationID` COMMENT 'Customer''s assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID - end-of-day change. See section 2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountStatusID` COMMENT 'Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountManagerID` COMMENT 'Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerLevelID` COMMENT 'Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountTypeID` COMMENT 'Account type (e.g., 7=Employee Account, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DateRangeID` COMMENT 'SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See section 2.1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsDepositor` COMMENT '1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PendingClosureStatusID` COMMENT 'Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocumentStatusID` COMMENT 'KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `SuitabilityTestStatusID` COMMENT 'MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `MifidCategorizationID` COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsEmailVerified` COMMENT '1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsValidCustomer` COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See section 2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DesignatedRegulationID` COMMENT 'Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `EvMatchStatus` COMMENT 'eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegionID` COMMENT 'Customer''s geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusReasonID` COMMENT 'Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsCreditReportValidCB` COMMENT '1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See section 2.3. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AffiliateID` COMMENT 'Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Email` COMMENT 'Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName=''DelUserName*''. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `City` COMMENT 'Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Address` COMMENT 'Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Zip` COMMENT 'Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PhoneNumber` COMMENT 'Customer phone number. PII: not DDL-masked but GDPR-erased to ''DelPhoneNumber_XXXXXXX'' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsPhoneVerified` COMMENT '1 if the customer''s phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PhoneVerificationDateID` COMMENT 'Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID=''19000101'' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusSubReasonID` COMMENT 'Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `WeekendFeePrecentage` COMMENT 'Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DltStatusID` COMMENT 'DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DltID` COMMENT 'DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `EquiLendID` COMMENT 'EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `StocksLendingStatusID` COMMENT 'Status of the customer''s stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer)';

-- ---- Column PII Tags (inherited) ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DemoCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CustomerChangeTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CurentValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PreviousValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LabelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `VerificationLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocsOK` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Bankruptcy` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskClassificationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CommunicationLanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PremiumAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Evangelist` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GuruStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountManagerID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DateRangeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsDepositor` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PendingClosureStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocumentStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `SuitabilityTestStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `MifidCategorizationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsEmailVerified` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DesignatedRegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `EvMatchStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsCreditReportValidCB` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AffiliateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Email` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `City` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Address` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Zip` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PhoneNumber` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsPhoneVerified` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PhoneVerificationDateID` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusSubReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `WeekendFeePrecentage` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DltStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DltID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `EquiLendID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `StocksLendingStatusID` SET TAGS ('pii' = 'none');

-- == PROPAGATION EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Statements: 104/104 succeeded
-- ====================
