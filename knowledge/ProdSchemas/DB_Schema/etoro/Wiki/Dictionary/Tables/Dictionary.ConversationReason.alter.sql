-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ConversationReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConversationReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_conversationreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_conversationreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_conversationreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 reasons for customer service conversations - Sale, Risk, Support, and Account Management. Source: etoro.Dictionary.ConversationReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ConversationReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_conversationreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConversationReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_conversationreason ALTER COLUMN ConversationReasonID COMMENT 'Primary key identifying the conversation reason. Values 1-4. Referenced by History.Conversation.ConversationReasonID to classify why the interaction occurred. (Tier 1 - upstream wiki, etoro.Dictionary.ConversationReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_conversationreason ALTER COLUMN Name COMMENT 'Reason label (''Sale'', ''Risk'', ''Support'', ''Account Management''). Enforced unique via DCOR_NAME index. Used in BackOffice UI dropdowns and conversation reports. (Tier 1 - upstream wiki, etoro.Dictionary.ConversationReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
