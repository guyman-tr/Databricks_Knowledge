-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.PCSToLiquidityAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.PCSToLiquidityAccount.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_price_pcstoliquidityaccount
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_price_pcstoliquidityaccount (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount SET TBLPROPERTIES (
    'comment' = 'Configuration table that maps Price Calculation Service (PCS) instance IDs to liquidity account IDs, defining which market data accounts are assigned to each PCS process instance for price routing and rate source configuration. Source: etoro.Price.PCSToLiquidityAccount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.PCSToLiquidityAccount.md).'
);

ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'PCSToLiquidityAccount',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN PCSID COMMENT 'Part 1 of composite PK. The Price Calculation Service instance identifier. Each PCS is a distinct process/worker that calculates prices for its assigned liquidity accounts. No FK constraint - PCSID values are managed externally (application config). Current range: 1-5. (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN LiquidityAccountID COMMENT 'Part 2 of composite PK. FK to Trade.LiquidityAccounts. The liquidity account assigned to this PCS instance. The account''s AccountRateSourceID (from Trade.LiquidityAccounts) identifies the market data feed. Used by GetRateSourceConfiguration to resolve the full PCS -> instrument -> rate source chain. (Trade.LiquidityAccounts) (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN DbLoginName COMMENT 'Computed: SQL Server login of last row modifier. Auto-set on DML. (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN AppLoginName COMMENT 'Computed: application identity from context_info(). Populated when calling service sets CONTEXT_INFO before DML. (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN SysStartTime COMMENT 'Temporal period start. Auto-managed by SQL Server system versioning. (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';
ALTER TABLE main.dealing.bronze_etoro_price_pcstoliquidityaccount ALTER COLUMN SysEndTime COMMENT 'Temporal period end. Historical row versions in History.PCSToLiquidityAccount. (Tier 1 - upstream wiki, etoro.Price.PCSToLiquidityAccount)';

