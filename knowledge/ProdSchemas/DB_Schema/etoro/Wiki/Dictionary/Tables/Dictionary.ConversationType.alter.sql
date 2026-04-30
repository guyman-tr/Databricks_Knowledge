-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ConversationType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConversationType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_conversationtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_conversationtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_conversationtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 channels for customer service conversations — Phone, Chat, and Email. Source: etoro.Dictionary.ConversationType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConversationType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_conversationtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConversationType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_conversationtype ALTER COLUMN ConversationTypeID COMMENT 'Primary key identifying the communication channel. Values: 1=Phone, 2=Chat, 3=Email. Referenced by History.Conversation.ConversationTypeID to record which channel was used for each interaction. (Tier 1 - upstream wiki, etoro.Dictionary.ConversationType)';
ALTER TABLE main.general.bronze_etoro_dictionary_conversationtype ALTER COLUMN Name COMMENT 'Channel name (''Phone'', ''Chat'', ''Email''). Enforced unique via DCOT_NAME index. Used in BackOffice UI dropdowns and conversation reports. (Tier 1 - upstream wiki, etoro.Dictionary.ConversationType)';

