-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.BSLPositionsInfo
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BSLPositionsInfo.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_bslpositionsinfo
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_bslpositionsinfo (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo SET TBLPROPERTIES (
    'comment' = 'Active BSL position tracking table recording which specific positions were evaluated for each customer in each BSL execution run, enabling per-position equity audit reconstruction. Source: etoro.History.BSLPositionsInfo on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BSLPositionsInfo.md).'
);

ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'BSLPositionsInfo',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo ALTER COLUMN CID COMMENT 'Customer ID whose account this position belongs to. Groups all positions evaluated for a customer in one BSL run. (Tier 1 - upstream wiki, etoro.History.BSLPositionsInfo)';
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo ALTER COLUMN ExecutionID COMMENT 'BSL execution run identifier. Links to History.BSLDataForAllUsers.ExecutionID and Trade.ManageBSL. Groups all positions across all customers for a single BSL cycle. bigint for high run volume. (Tier 1 - upstream wiki, etoro.History.BSLPositionsInfo)';
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo ALTER COLUMN PositionID COMMENT 'The specific open position included in the equity calculation. bigint to match trade position table key type. Implicit FK to Trade.PositionTbl/History.Position_Active. (Tier 1 - upstream wiki, etoro.History.BSLPositionsInfo)';
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo ALTER COLUMN PriceRateID COMMENT 'The price rate used for this position''s equity calculation. Resolves to a row in History.BSLCurrencyPriceSnapShots (same ExecutionID). Enables per-position equity reconstruction by joining with the price snapshot. (Tier 1 - upstream wiki, etoro.History.BSLPositionsInfo)';
ALTER TABLE main.general.bronze_etoro_history_bslpositionsinfo ALTER COLUMN Occurred COMMENT 'Server timestamp when this BSL position record was created. Default = getdate() (local server time). PK component and EndMonth partition key. (Tier 1 - upstream wiki, etoro.History.BSLPositionsInfo)';

