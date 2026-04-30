-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MessageType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MessageType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_messagetype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_messagetype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_messagetype SET TBLPROPERTIES (
    'comment' = 'Classifies the delivery channels and display formats for real-time messages and promotional notifications sent to users within the trading platform. Source: etoro.Dictionary.MessageType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MessageType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_messagetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MessageType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_messagetype ALTER COLUMN MessageTypeID COMMENT 'Unique identifier for the message delivery channel: 1=Dialog, 2=Bar, 3=Web, 4=Promotion (Cashier), 5=Promotion (Trade), 6=WEB (On Exit), 7=KICK (On Login), 8=KICK (On Chat), 9=WEB (Def Browser), 10=Trade Block. (Tier 1 - upstream wiki, etoro.Dictionary.MessageType)';
ALTER TABLE main.general.bronze_etoro_dictionary_messagetype ALTER COLUMN Name COMMENT 'Short label describing the delivery mechanism. Enforced unique by index DMGT_NAME. Displayed in BackOffice message configuration. (Tier 1 - upstream wiki, etoro.Dictionary.MessageType)';
ALTER TABLE main.general.bronze_etoro_dictionary_messagetype ALTER COLUMN IsHidden COMMENT 'Controls visibility in BackOffice message type selection: 0=visible (available for message configuration), 1=hidden (deprecated or system-only). Currently all types are visible (0). Filtered by Dictionary.GetMessageType view. (Tier 1 - upstream wiki, etoro.Dictionary.MessageType)';

