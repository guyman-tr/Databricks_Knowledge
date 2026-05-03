-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PlayerStatusReasons
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatusReasons.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_playerstatusreasons
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_playerstatusreasons (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatusreasons SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 44 reasons why a customer''s account status may be changed - from compliance actions (AML, KYC, chargebacks) to user-initiated closures and administrative decisions. Source: etoro.Dictionary.PlayerStatusReasons on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatusReasons.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_playerstatusreasons SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlayerStatusReasons',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatusreasons ALTER COLUMN PlayerStatusReasonID COMMENT 'Primary key identifying the status change reason. Range 0-43. Referenced by BackOffice.PlayerStatusToReason (FK), BackOffice.PlayerStatusReasonToSubReason (FK), and Customer.CustomerStatic (implicit). Used as parameter in BackOffice.UpdateRiskUserInfo and Billing.UpdateCustomerStatusReason. 0=None (default). (Tier 1 - upstream wiki, etoro.Dictionary.PlayerStatusReasons)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatusreasons ALTER COLUMN Name COMMENT 'Human-readable reason label. Nullable (unlike most Dictionary tables). Used in BackOffice reporting JOINs, customer history views, and monitoring procedures. Displayed in BackOffice UI when viewing customer status change history. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerStatusReasons)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
