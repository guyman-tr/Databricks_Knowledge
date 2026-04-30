-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TradingInstrumentGroups
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradingInstrumentGroups.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_dictionary_tradinginstrumentgroups
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_dictionary_tradinginstrumentgroups (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups SET TBLPROPERTIES (
    'comment' = 'System-versioned configuration table defining named instrument groupings used for trading rules, risk limits, regulatory restrictions, and cross-border settings. Source: etoro.Dictionary.TradingInstrumentGroups on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradingInstrumentGroups.md).'
);

ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TradingInstrumentGroups',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN GroupID COMMENT 'Auto-incrementing group identifier. Business groups: 1=RealOnly, 2=CopyBlock, 3=CFDOnly, 4=US_Restricted, 33-52=MaxNOPLimit tiers, 59=SQFs, 99=Crypto Futures, 183=Crypto UCITS ETFs, 450=stockmargin, 480=Experimental_Crypto, 780=Crypto US ETFs, 801=Futures. Many QA automation groups also exist. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN GroupName COMMENT 'Unique group name used as technical identifier. Business groups use descriptive names; QA groups use "QaAutomation" prefix with timestamps. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN Description COMMENT 'Optional description providing business context. Some groups have descriptions (e.g., "Instruments Not allowed in US"), others are NULL. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). SQL Server login that last modified the row. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application-level identity from CONTEXT_INFO. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN SysStartTime COMMENT 'Temporal row start — GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_dictionary_tradinginstrumentgroups ALTER COLUMN SysEndTime COMMENT 'Temporal row end — GENERATED ALWAYS AS ROW END. Active rows: 9999-12-31. (Tier 1 - upstream wiki, etoro.Dictionary.TradingInstrumentGroups)';

