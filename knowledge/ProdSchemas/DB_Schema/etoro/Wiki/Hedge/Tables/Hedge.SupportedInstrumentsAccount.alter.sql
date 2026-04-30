-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.SupportedInstrumentsAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.SupportedInstrumentsAccount.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount SET TBLPROPERTIES (
    'comment' = 'Per-account instrument allowlist for multi-account hedge servers, specifying which instruments each liquidity account is permitted to execute when a hedge server owns more than one account. Source: etoro.Hedge.SupportedInstrumentsAccount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.SupportedInstrumentsAccount.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'SupportedInstrumentsAccount',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN LiquidityAccountID COMMENT 'The liquidity account this allowlist entry applies to. Part of composite PK. Implicit reference to Trade.LiquidityAccounts (no FK constraint). 6 distinct account IDs configured: 8 (ZBFX P1), 11 (ZBFX P3), 345 (Talos Hidden), 439 (DLT), 2147 (OMS IM Pricing), 2148 (OMS IM Hedging). (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN InstrumentID COMMENT 'The instrument this account is permitted to execute. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). 5,239 distinct instruments configured. (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';
ALTER TABLE main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.SupportedInstrumentsAccount. (Tier 1 - upstream wiki, etoro.Hedge.SupportedInstrumentsAccount)';

