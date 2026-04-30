-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TradingRiskStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradingRiskStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_tradingriskstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_tradingriskstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_tradingriskstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the trading risk level that determines leverage and trading feature access. Value is COMPUTED on BackOffice.Customer from regulatory context (Seychelles, ASIC, CySEC, FCA, MiFID). Source: etoro.Dictionary.TradingRiskStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradingRiskStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_tradingriskstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TradingRiskStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_tradingriskstatus ALTER COLUMN TradingRiskStatusID COMMENT 'Primary key identifying the trading risk level. 1=None, 2=Pending, 3=Low, 4=High. Referenced by BackOffice.Customer.TradingRiskStatusID (COMPUTED column). Used by Trade.GetTradingRiskStatus, Trade.GetUserInfo, Trade.GetUserData, Trade.GetOrderForOpenContextData, Trade.GetOrderForCloseContextData, Trade.GetCustomersDataWithRestirctions, Trade.PositionsGuaranteedSLWasNotAligned, UserApiDB Customer procs. (Tier 1 - upstream wiki, etoro.Dictionary.TradingRiskStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_tradingriskstatus ALTER COLUMN TradingRiskStatus COMMENT 'Human-readable label. Values: None, Pending, Low, High. Used for UI and reporting when resolving TradingRiskStatusID. (Tier 1 - upstream wiki, etoro.Dictionary.TradingRiskStatus)';

