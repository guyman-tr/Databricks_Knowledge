-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_CommoditiesIntraHour_Clients
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Date COMMENT 'Trading date';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Minute_Start COMMENT 'Start of 1-minute interval (e.g., `2026-03-10 09:00:00`)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Minute_End COMMENT 'End of 1-minute interval (Minute_Start + 1 min)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN InstrumentID COMMENT 'Commodity instrument ID';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN VolumeBuy COMMENT 'Volume of buy trades executed in this minute (open buys + close sells)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN VolumeSell COMMENT 'Volume of sell trades executed in this minute (open sells + close buys)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Buy_Units COMMENT 'Total units of long open positions at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Buy COMMENT 'USD value of long open positions at minute start (units × Bid price)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Sell_Units COMMENT 'Total units of short open positions at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Sell COMMENT 'USD value of short open positions at minute start (units × Ask price)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UnrealizedStart COMMENT 'Unrealized PnL of open positions at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UnrealizedEnd COMMENT 'Unrealized PnL of open positions at minute end';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Realized COMMENT 'Realized PnL of positions closed during this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Bid COMMENT 'Bid price at minute start (for dominant instrument direction)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Ask COMMENT 'Ask price at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Minute_Start SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Minute_End SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Buy_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Sell_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN OP_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UnrealizedStart SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UnrealizedEnd SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Realized SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
