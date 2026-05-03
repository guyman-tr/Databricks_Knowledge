-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.TerminalIDToCorporateAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.TerminalIDToCorporateAction.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_terminalidtocorporateaction
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_terminalidtocorporateaction (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_terminalidtocorporateaction SET TBLPROPERTIES (
    'comment' = 'Maps external clearing/settlement system terminal IDs (from Apex or DTC) to internal corporate action type codes, enabling automated processing of dividends, splits, mergers, staking, and promotional distributions. Source: etoro.Trade.TerminalIDToCorporateAction on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.TerminalIDToCorporateAction.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_terminalidtocorporateaction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'TerminalIDToCorporateAction',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_terminalidtocorporateaction ALTER COLUMN TerminalID COMMENT 'The terminal/code from the external clearing or settlement system (Apex, DTC, etc.). Examples: "$+DIV" (dividend), "REREV" (reverse split), "STAKING" (crypto staking). Used as lookup key when processing incoming corporate action notifications. (Tier 1 - upstream wiki, etoro.Trade.TerminalIDToCorporateAction)';
ALTER TABLE main.trading.bronze_etoro_trade_terminalidtocorporateaction ALTER COLUMN Description COMMENT 'Human-readable label for the terminal ID. Examples: "Dividend", "Reverse split", "Staking". Purely descriptive; not used for processing logic. (Tier 1 - upstream wiki, etoro.Trade.TerminalIDToCorporateAction)';
ALTER TABLE main.trading.bronze_etoro_trade_terminalidtocorporateaction ALTER COLUMN CorporateActionTypeID COMMENT 'FK to Dictionary.CorporateAction or Trade.CorporateInstrumentActions. Internal corporate action type code. 1=Dividend/ADR, 2=Cash in Lieu, 4=Interest, 8=Merger, 10=Reverse split, 35=Staking, 36=Promotion, 42=Promo-Crypto. Routes incoming events to correct processing. (Tier 1 - upstream wiki, etoro.Trade.TerminalIDToCorporateAction)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
