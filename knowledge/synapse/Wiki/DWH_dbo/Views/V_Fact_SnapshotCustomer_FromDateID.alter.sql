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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN FromDateID COMMENT 'Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - via Dim_Range)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN ToDateID COMMENT 'End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - via Dim_Range)';
-- NOTE: Inherited Fact_SnapshotCustomer columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotCustomer.md and are applied via that table's alter.sql.

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN GCID COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN RealCID COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN DemoCID COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN CustomerChangeTypeID COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN CurentValue COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN PreviousValue COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN CountryID COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN LabelID COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN LanguageID COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN VerificationLevelID COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN DocsOK COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN PlayerStatusID COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN Bankruptcy COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN RiskStatusID COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN RiskClassificationID COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN CommunicationLanguageID COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN PremiumAccount COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN Evangelist COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN GuruStatusID COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN UpdateDate COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN RegulationID COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN AccountStatusID COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN AccountManagerID COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN PlayerLevelID COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN AccountTypeID COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN DateRangeID COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN IsDepositor COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN PendingClosureStatusID COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN DocumentStatusID COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN SuitabilityTestStatusID COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - via Dim_Range)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - via Dim_Range)';
-- NOTE: Inherited Fact_SnapshotCustomer columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotCustomer.md and are applied via that table's alter.sql.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN GCID COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN RealCID COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN DemoCID COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN CustomerChangeTypeID COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN CurentValue COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN PreviousValue COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN CountryID COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN LabelID COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN LanguageID COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN VerificationLevelID COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN DocsOK COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN PlayerStatusID COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN Bankruptcy COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN RiskStatusID COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN RiskClassificationID COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN CommunicationLanguageID COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN PremiumAccount COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN Evangelist COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN GuruStatusID COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN UpdateDate COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN RegulationID COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN AccountStatusID COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN AccountManagerID COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN PlayerLevelID COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN AccountTypeID COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN DateRangeID COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN IsDepositor COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN PendingClosureStatusID COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN DocumentStatusID COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN SuitabilityTestStatusID COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GCID` COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RealCID` COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DemoCID` COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CustomerChangeTypeID` COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CurentValue` COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PreviousValue` COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CountryID` COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LabelID` COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `LanguageID` COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `VerificationLevelID` COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocsOK` COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusID` COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Bankruptcy` COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskStatusID` COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RiskClassificationID` COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `CommunicationLanguageID` COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PremiumAccount` COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `Evangelist` COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `GuruStatusID` COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `UpdateDate` COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegulationID` COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountStatusID` COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountManagerID` COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerLevelID` COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `AccountTypeID` COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DateRangeID` COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsDepositor` COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PendingClosureStatusID` COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DocumentStatusID` COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `SuitabilityTestStatusID` COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `MifidCategorizationID` COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsEmailVerified` COMMENT '1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsValidCustomer` COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See section 2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `DesignatedRegulationID` COMMENT 'Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `EvMatchStatus` COMMENT 'eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `RegionID` COMMENT 'Customer''s geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `PlayerStatusReasonID` COMMENT 'Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN `IsCreditReportValidCB` COMMENT 'Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. See section 2.3. (Tier 2 - SP_Fact_SnapshotCustomer)';
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GCID` COMMENT 'Fact_SnapshotCustomer.GCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RealCID` COMMENT 'Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DemoCID` COMMENT 'Fact_SnapshotCustomer.DemoCID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CustomerChangeTypeID` COMMENT 'Fact_SnapshotCustomer.CustomerChangeTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CurentValue` COMMENT 'Fact_SnapshotCustomer.CurentValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PreviousValue` COMMENT 'Fact_SnapshotCustomer.PreviousValue';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CountryID` COMMENT 'Fact_SnapshotCustomer.CountryID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LabelID` COMMENT 'Fact_SnapshotCustomer.LabelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `LanguageID` COMMENT 'Fact_SnapshotCustomer.LanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `VerificationLevelID` COMMENT 'Fact_SnapshotCustomer.VerificationLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocsOK` COMMENT 'Fact_SnapshotCustomer.DocsOK';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusID` COMMENT 'Fact_SnapshotCustomer.PlayerStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Bankruptcy` COMMENT 'Fact_SnapshotCustomer.Bankruptcy';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskStatusID` COMMENT 'Fact_SnapshotCustomer.RiskStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RiskClassificationID` COMMENT 'Fact_SnapshotCustomer.RiskClassificationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `CommunicationLanguageID` COMMENT 'Fact_SnapshotCustomer.CommunicationLanguageID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PremiumAccount` COMMENT 'Fact_SnapshotCustomer.PremiumAccount';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `Evangelist` COMMENT 'Fact_SnapshotCustomer.Evangelist';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `GuruStatusID` COMMENT 'Fact_SnapshotCustomer.GuruStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `UpdateDate` COMMENT 'Fact_SnapshotCustomer.UpdateDate';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegulationID` COMMENT 'Fact_SnapshotCustomer.RegulationID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountStatusID` COMMENT 'Fact_SnapshotCustomer.AccountStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountManagerID` COMMENT 'Fact_SnapshotCustomer.AccountManagerID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerLevelID` COMMENT 'Fact_SnapshotCustomer.PlayerLevelID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `AccountTypeID` COMMENT 'Fact_SnapshotCustomer.AccountTypeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DateRangeID` COMMENT 'Fact_SnapshotCustomer.DateRangeID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsDepositor` COMMENT 'Fact_SnapshotCustomer.IsDepositor';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PendingClosureStatusID` COMMENT 'Fact_SnapshotCustomer.PendingClosureStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DocumentStatusID` COMMENT 'Fact_SnapshotCustomer.DocumentStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `SuitabilityTestStatusID` COMMENT 'Fact_SnapshotCustomer.SuitabilityTestStatusID';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `MifidCategorizationID` COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsEmailVerified` COMMENT '1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsValidCustomer` COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See section 2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `DesignatedRegulationID` COMMENT 'Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `EvMatchStatus` COMMENT 'eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `RegionID` COMMENT 'Customer''s geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `PlayerStatusReasonID` COMMENT 'Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN `IsCreditReportValidCB` COMMENT 'Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. See section 2.3. (Tier 2 - SP_Fact_SnapshotCustomer)';
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
