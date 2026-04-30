-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.GetAccountRateSourceMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Views/Price.GetAccountRateSourceMapping.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_price_getaccountratesourcemapping
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_price_getaccountratesourcemapping (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_price_getaccountratesourcemapping SET TBLPROPERTIES (
    'comment' = 'Read-only view that maps each active liquidity account''s assigned rate source to the instruments it is eligible to price - the primary lookup used by the pricing engine to resolve which AccountRateSourceID feeds prices for a given instrument via which liquidity account. Source: etoro.Price.GetAccountRateSourceMapping on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Views/Price.GetAccountRateSourceMapping.md).'
);

ALTER TABLE main.dealing.bronze_etoro_price_getaccountratesourcemapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'GetAccountRateSourceMapping',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_price_getaccountratesourcemapping ALTER COLUMN AccountRateSourceID COMMENT 'Rate source identifier assigned to this liquidity account. Sourced from Trade.GetLiquidityAccounts.AccountRateSourceID (which reads Trade.LiquidityAccounts.AccountRateSourceID). FK to Price.AccountRateSource. Values: -1=US special, 0=Do not use!, 1-6=Simulation feeds, 9001-9006=FIX protocol, 20-24=broker feeds (Goldman, ZBFX...), 196-197=Bloomberg. See Price.AccountRateSource for full registry. (Tier 1 - upstream wiki, etoro.Price.GetAccountRateSourceMapping)';
ALTER TABLE main.dealing.bronze_etoro_price_getaccountratesourcemapping ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier from Price.LiquidityAccountToInstrument. Identifies the tradeable instrument (forex pair, stock, crypto, etc.) this account-source pair can price. FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Price.GetAccountRateSourceMapping)';
ALTER TABLE main.dealing.bronze_etoro_price_getaccountratesourcemapping ALTER COLUMN LiquidityAccountID COMMENT 'Active liquidity account identifier from Price.LiquidityAccountToInstrument (aliased as LATI). Must exist in Trade.GetLiquidityAccounts (IsActive=1). Links AccountRateSourceID to InstrumentID. FK to Trade.LiquidityAccounts. (Tier 1 - upstream wiki, etoro.Price.GetAccountRateSourceMapping)';

