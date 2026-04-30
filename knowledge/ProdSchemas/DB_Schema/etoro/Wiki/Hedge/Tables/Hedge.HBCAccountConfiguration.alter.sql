-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.HBCAccountConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration SET TBLPROPERTIES (
    'comment' = 'Tiered HBC (Hedge Bot Controller) execution parameter table storing per-account, per-instrument, per-size-threshold configurations that define order timing, retry, and size constraints for hedge orders routed through each liquidity account. Source: etoro.Hedge.HBCAccountConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'HBCAccountConfiguration',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN LiquidityAccountID COMMENT 'FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account these execution parameters apply to. Part of 3-column composite PK. 14 distinct accounts configured. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument(InstrumentID). The instrument these execution parameters apply to. Part of 3-column composite PK. 10,458 distinct instruments configured. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN ThresholdInEToroUnits COMMENT 'Order size tier boundary (in eToro units). Part of 3-column composite PK enabling tiered config. The HBC selects the row for orders at or below this threshold. 5 distinct values: 0, 5,271, 110,462, 1,137,139, 200,000,000. Most rows (97%) use 200,000,000. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxTimeMS COMMENT 'Maximum milliseconds to wait for an order to fill before timeout. Range: 0-25,000 in current data. Applied per-tier, per-instrument, per-account. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxRejectRetries COMMENT 'Maximum number of retry attempts when an order is rejected. Range: 0-10 in current data. Higher values = more persistent execution attempts. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MinOrderSizeInEToroUnits COMMENT 'Minimum order size in eToro units for this account/instrument/tier. Orders below this floor are not routed. NULL = no minimum applied. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxOrderSizeInEToroUnits COMMENT 'Maximum single-order execution size in eToro units. Orders exceeding this must be split. Controls individual order impact on the market. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN UseExecutionRateWithSpread COMMENT 'Whether the execution rate calculation includes the bid-ask spread. 1=include spread (12,723 rows), 0=exclude spread (20,982 rows). Affects pricing calculation for execution rate benchmarking. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MinOrderSizeUSDForHBC COMMENT 'Minimum order size in USD for HBC routing. DEFAULT 0 = no USD minimum. Provides a USD-denominated floor in addition to the eToro units floor. (Tier 1 - upstream wiki, etoro.Hedge.HBCAccountConfiguration)';

