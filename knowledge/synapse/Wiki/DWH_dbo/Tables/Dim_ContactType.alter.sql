-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ContactType
-- Generated: 2026-05-14 15:08:06 UTC | phase1 stub overwrite
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype
-- =============================================================================

-- ---- Table Comment ----

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN ContactTypeID COMMENT 'Natural key identifying the contact type. 0 rows - values never loaded. Expected to match a production Dictionary.ContactType.ContactTypeID if ETL is ever implemented. (Tier 3b - SSDT DDL, DWH_dbo.Dim_ContactType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN Name COMMENT '[UNVERIFIED] Short label for the contact type category (e.g., "Email", "Phone", "Chat"). No data exists to confirm actual values. (Tier 4 - inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN DWHContactTypeID COMMENT 'DWH surrogate key - standard DWH pattern where DWH{X}ID mirrors the source PK. Expected to equal ContactTypeID if loaded by SP_Dictionaries pattern. 0 rows - never populated. (Tier 3b - SSDT DDL DWH design pattern)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - would record GETDATE() on each SP_Dictionaries refresh. Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp - would record GETDATE() when row first loaded. Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN StatusID COMMENT 'Active/inactive flag - standard SP_Dictionaries convention (1 = active). Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN ContactTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN DWHContactTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype ALTER COLUMN Unknown SET TAGS ('pii' = 'none');

