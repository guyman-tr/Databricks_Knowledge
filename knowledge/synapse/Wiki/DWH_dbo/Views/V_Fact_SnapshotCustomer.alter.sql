-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotCustomer
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer
-- Resolved via: Wiki property table
-- Classification: PII Only
-- =============================================================================

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range`, `Dim_Date` | | **Purpose** | Expands Fact_SnapshotCustomer SCD2 date ranges into individual daily rows via `Dim_Range` + `Dim_Date` bridge. Adds `DateKey` for easy daily-grain queries. |'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer SET TAGS (
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DateKey COMMENT 'Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 - view DDL)';
-- NOTE: Inherited Fact_SnapshotCustomer columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotCustomer.md and are applied via that table's alter.sql.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN GCID COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN RealCID COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DemoCID COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN CustomerChangeTypeID COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN CurentValue COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN PreviousValue COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN CountryID COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN LabelID COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN LanguageID COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN VerificationLevelID COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DocsOK COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN PlayerStatusID COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN Bankruptcy COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN RiskStatusID COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN RiskClassificationID COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN CommunicationLanguageID COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN PremiumAccount COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN Evangelist COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN GuruStatusID COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN UpdateDate COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN RegulationID COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN AccountStatusID COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN AccountManagerID COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN PlayerLevelID COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN AccountTypeID COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DateRangeID COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN IsDepositor COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN PendingClosureStatusID COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DocumentStatusID COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN SuitabilityTestStatusID COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DateKey SET TAGS ('pii' = 'none');
-- NOTE: Inherited column PII tags omitted (same reason as above).

-- == LAST EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Fix: Removed invalid 'All Fact_SnapshotCustomer columns' ALTER COLUMN lines (bulk wildcard not valid SQL).
-- Statements: 4/4 succeeded
-- ====================

-- ============================================================
-- Inherited from Fact_SnapshotCustomer (propagated 2026-04-12)
-- Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer
-- 43 column(s) | source: knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.alter.sql
-- ============================================================

-- ---- Column Comments (inherited) ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `GCID` COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RealCID` COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DemoCID` COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CustomerChangeTypeID` COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CurentValue` COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PreviousValue` COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CountryID` COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `LabelID` COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `LanguageID` COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `VerificationLevelID` COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DocsOK` COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerStatusID` COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Bankruptcy` COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RiskStatusID` COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RiskClassificationID` COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CommunicationLanguageID` COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PremiumAccount` COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Evangelist` COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `GuruStatusID` COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `UpdateDate` COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RegulationID` COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountStatusID` COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountManagerID` COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerLevelID` COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountTypeID` COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DateRangeID` COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsDepositor` COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PendingClosureStatusID` COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DocumentStatusID` COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `SuitabilityTestStatusID` COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `MifidCategorizationID` COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsEmailVerified` COMMENT '1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsValidCustomer` COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See section 2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DesignatedRegulationID` COMMENT 'Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `EvMatchStatus` COMMENT 'eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RegionID` COMMENT 'Customer''s geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerStatusReasonID` COMMENT 'Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsCreditReportValidCB` COMMENT 'Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. See section 2.3. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AffiliateID` COMMENT 'Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Email` COMMENT 'Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName=''DelUserName*''. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `City` COMMENT 'Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Address` COMMENT 'Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Zip` COMMENT 'Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';

-- ---- Column PII Tags (inherited) ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DemoCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CustomerChangeTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CurentValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PreviousValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `LabelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `LanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `VerificationLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DocsOK` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Bankruptcy` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RiskStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RiskClassificationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `CommunicationLanguageID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PremiumAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Evangelist` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `GuruStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountManagerID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AccountTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DateRangeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsDepositor` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PendingClosureStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DocumentStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `SuitabilityTestStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `MifidCategorizationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsEmailVerified` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `DesignatedRegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `EvMatchStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `RegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `PlayerStatusReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `IsCreditReportValidCB` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `AffiliateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Email` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `City` SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Address` SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN `Zip` SET TAGS ('pii' = 'none');

-- == PROPAGATION EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Statements: 86/86 succeeded
-- ====================
