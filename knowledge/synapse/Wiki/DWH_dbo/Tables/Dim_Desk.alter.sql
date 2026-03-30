-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Desk
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk SET TBLPROPERTIES (
    'comment' = '`Dim_Desk` is a composite-key mapping table that assigns each (CountryID, LanguageID) combination to a customer-facing desk. A "desk" is a regional customer relationship management or support team responsible for handling customers from that country/language segment (e.g., Russian-speaking customers regardless of country get the "Russian" desk; customers from France get the "French" desk). The table contains 6,526 rows covering all supported (CountryID, LanguageID) combinations. There are 10 distinct desks (CFKey 1-10), identified by their CFDesk name: Arabic, China, English, French, German, Italian, Russian, South & Central America, Spanish, and Israel. English is by far the largest desk (3,465 rows - the default for most countries with LanguageID=0). The table was migrated from the legacy on-premises DWH SQL Server via a one-time DWH_Migration load. InsertDate and UpdateDate are NULL for all rows - no active ETL refreshes this table. It is actively used in the GCP/Tableau Revenue Churn reporting pipeline...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (LanguageID ASC, CountryID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN LanguageID COMMENT 'Part of composite natural key. Customer language identifier - matches LanguageID in Dim_Customer. LanguageID=0 is the default (country-only assignment). (Tier 3 - live data, DWH_dbo.Dim_Desk)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CountryID COMMENT 'Part of composite natural key. Customer country identifier - matches CountryID in Dim_Customer and Dim_Country. (Tier 3 - live data, DWH_dbo.Dim_Desk)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CFKey COMMENT 'Numeric identifier for the customer-facing desk. Values 1-10; see Section 2.1 for the complete value map. "CF" = Customer Facing. (Tier 3 - live data, DWH_dbo.Dim_Desk)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CFDesk COMMENT 'Human-readable name of the customer-facing desk. Values: Arabic, China, English, French, German, Italian, Russian, South & Central America, Spanish, Israel. Used directly in reports for desk segmentation. (Tier 3 - live data, DWH_dbo.Dim_Desk)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp - always NULL (static migration load, no active ETL). (Tier 3b - SSDT DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN UpdateDate COMMENT 'ETL update timestamp - always NULL (static migration load, no active ETL). (Tier 3b - SSDT DDL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN LanguageID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CFKey SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN CFDesk SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
