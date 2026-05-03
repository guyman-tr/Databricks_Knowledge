-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEPListCIDMappings
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEPListCIDMappings.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_ceplistcidmappings
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_ceplistcidmappings (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings SET TBLPROPERTIES (
    'comment' = 'Trigger-based delete audit log for CEP.ListCIDMappings - records each customer''s removal from a CEP named list, capturing the period (ValidFrom to ValidTo) during which they were a member. Source: etoro.History.CEPListCIDMappings on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEPListCIDMappings.md).'
);

ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEPListCIDMappings',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings ALTER COLUMN CEPListCIDMappingsID COMMENT 'Surrogate PK. Auto-incremented, not for replication. No business meaning - used only for row identity. (Tier 1 - upstream wiki, etoro.History.CEPListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings ALTER COLUMN ValidFrom COMMENT 'UTC timestamp when the customer was added to the named list in CEP.ListCIDMappings. Copied from the live row at delete time via trigger. Represents the start of the membership window. (Tier 1 - upstream wiki, etoro.History.CEPListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings ALTER COLUMN ValidTo COMMENT 'UTC timestamp when the customer was removed from the named list. Set to GETUTCDATE() by the trigger at the moment of deletion. Represents the end of the membership window. (Tier 1 - upstream wiki, etoro.History.CEPListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings ALTER COLUMN NamedListID COMMENT 'ID of the CEP named list from which the customer was removed. FK to CEP.NamedLists. Known values: 1="Large AUM", 13="Dinamic Guru List". (Tier 1 - upstream wiki, etoro.History.CEPListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_ceplistcidmappings ALTER COLUMN CID COMMENT 'Customer ID removed from the named list. Implicit FK to Customer.CustomerStatic. (Tier 1 - upstream wiki, etoro.History.CEPListCIDMappings)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
