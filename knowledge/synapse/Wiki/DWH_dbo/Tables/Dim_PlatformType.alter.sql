-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PlatformType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype SET TBLPROPERTIES (
    'comment' = '`Dim_PlatformType` defines the 13 access context types for the eToro trading platform - the combination of product mode (OpenBook/Trader/SocialAlerts/BackOffice/CRM) and access channel (Web Desktop, Web Mobile, Android, iOS, BackOffice) that identifies how a user was interacting with eToro when an action occurred. Each row specifies which capabilities are available for that access context via binary flags. This table was migrated from the legacy on-premises DWH SQL Server as a one-time data migration (`DWH_Migration.Dim_PlatformType` via NoDbObjectsScripts). All `InsertDate` and `UpdateDate` values are NULL, confirming no active ETL. There is no corresponding production source table in the etoro application database. **In modern ETL, `Dim_PlatformType` is effectively deprecated.** `SP_Fact_CustomerAction` hardcodes `PlatformTypeID = 0` (No Platform) for the majority of action types - the platform detection logic (which would map user agents to platform IDs 1-9) was commented out. The table remains for hist...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ProductID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN ProductID COMMENT 'Primary key. Numeric identifier for the platform access context. Range: 0-11 and 99. 0 and 99 are "No Platform" placeholders. Maps to PlatformTypeID in Fact_CustomerAction. In modern ETL, almost all Fact_CustomerAction rows have PlatformTypeID = 0. (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN Product COMMENT 'Trading product / UI mode. Values observed: ''No Platform'' (0,99), ''OpenBook'' (1,3,5,7 - social feed), ''Trader'' (2,4,6,8 - trading terminal), ''SocialAlerts'' (9 - alerts app), ''BackOffice'' (10 - admin), ''CRM'' (11 - CRM system). (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN Platform COMMENT 'Access channel. Values: empty (0,99), ''Web'' (1-4), ''Mobile'' (5-9), ''BackOffice'' (10-11). (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN SubPlatform COMMENT 'Specific access channel variant. Values: empty (0,99), ''DesktopWeb'' (1,2), ''MobileWeb'' (3,4), ''Android'' (5,6,9), ''iOS'' (7,8), ''BackOffice'' (10,11). (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanManualTrade COMMENT 'Whether this platform context allows manual position opening/closing. True only for Trader variants: IDs 2 (Web Desktop), 6 (Android), 8 (iOS). OpenBook, SocialAlerts, BackOffice, CRM cannot manually trade. (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanOpenMirror COMMENT 'Whether this platform context allows opening a copy-trade mirror (following another trader). True for OpenBook variants: IDs 1 (DesktopWeb), 3 (MobileWeb), 5 (Android InDev), 7 (iOS InDev). (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanCopyTrade COMMENT 'Whether this platform context allows copy-trading (following/mirroring). True for: Trader Web Desktop (2), Trader Android (6), Trader iOS (8), SocialAlerts Android (9). (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanDeposit COMMENT 'Whether this platform context allows making a deposit. True for Web variants (1=OpenBook DesktopWeb, 2=Trader DesktopWeb, 3=OpenBook MobileWeb, 4=Trader MobileWeb InDev). Mobile apps do not support in-app deposits via this dimension. (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanCashout COMMENT 'Whether this platform context allows cashout/withdrawal. True only for ID 1 (OpenBook Web Desktop). False for all mobile and all BackOffice contexts. (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN InDevelopment COMMENT 'Whether this platform context was marked as in-development (not yet live). True for IDs 4 (Trader MobileWeb), 5 (OpenBook Android), 7 (OpenBook iOS). These features were either cancelled or released under different IDs. (Tier 3 - live data sampling, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN InsertDate COMMENT 'Intended ETL load timestamp. All values are NULL - confirms one-time migration load with no tracking. Do not use for freshness analysis. (Tier 2 - DDL structure, DWH_Migration)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN UpdateDate COMMENT 'Intended ETL update timestamp. All values are NULL - confirms no ETL has run since migration. (Tier 2 - DDL structure, DWH_Migration)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN ProductID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN Product SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN Platform SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN SubPlatform SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanManualTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanOpenMirror SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanCopyTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanDeposit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN CanCashout SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN InDevelopment SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
