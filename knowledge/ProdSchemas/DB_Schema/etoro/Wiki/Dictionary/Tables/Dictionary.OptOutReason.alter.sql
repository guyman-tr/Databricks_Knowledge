-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OptOutReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OptOutReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_optoutreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_optoutreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_optoutreason SET TBLPROPERTIES (
    'comment' = 'Defines the reasons why a customer has opted out of marketing communications, distinguishing between active opt-in, self-service opt-out, inactivity-based opt-out, and geographic restriction. Source: etoro.Dictionary.OptOutReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OptOutReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_optoutreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OptOutReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_optoutreason ALTER COLUMN OptOutReasonID COMMENT 'Unique identifier for the opt-out state: 0=Opt-In, 1=User Opt-Out, 2=Last Login Opt-Out, 3=Country of Origin Opt-Out. Referenced by Customer.CustomerStatic and 10+ customer procedures. (Tier 1 - upstream wiki, etoro.Dictionary.OptOutReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_optoutreason ALTER COLUMN OptOutReason COMMENT 'Human-readable reason label. Note: column name matches table name. Displayed in BackOffice customer details and used in marketing campaign segmentation queries. (Tier 1 - upstream wiki, etoro.Dictionary.OptOutReason)';

