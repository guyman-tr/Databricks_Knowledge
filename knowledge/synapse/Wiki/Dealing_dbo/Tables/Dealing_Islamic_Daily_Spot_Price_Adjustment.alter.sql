-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment SET TAGS (
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
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Date COMMENT 'Report date; Sunday input -> Friday''s date';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN DateID COMMENT 'YYYYMMDD of Date';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN PositionID COMMENT 'Position identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN RealCID COMMENT 'Client ID (Islamic account holder)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN GCID COMMENT 'Global customer ID';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN UserName COMMENT 'Client username';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN OpenDateID COMMENT 'Date position opened';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN OpenOccurred COMMENT 'Exact open timestamp';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN NewOpenOccurred COMMENT 'Open date adjusted for 22:00 UTC cutoff';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsTheDayBefore COMMENT '1 if position opened after 22:00 UTC';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN CloseDateID COMMENT 'Date position closed; 0 if open';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN CloseOccurred COMMENT 'Exact close timestamp';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type ID';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentType COMMENT 'Instrument type name';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentID COMMENT 'One of: 17, 22, 339, 340, 341, 343, 344';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentName COMMENT 'Instrument display name';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Exchange COMMENT 'Exchange name';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN ExchangeID COMMENT 'Always 0 - not used in this SP';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsBuy COMMENT '1=long, 0=short';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Leverage COMMENT 'Position leverage';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN AmountInUnitsDecimal COMMENT 'Position size in instrument units';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_Open COMMENT 'Effective days open (Count_Fri rule)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_To_Charge COMMENT '3 on Fri, 1 on Mon - Thu, 0 weekend';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Front COMMENT 'Front contract close price from Fivetran';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Next COMMENT 'Next contract close price from Fivetran';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_Between_Expiration COMMENT 'Days until front contract expires';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Final_Fee COMMENT 'Roll-cost fee in USD; positive or negative';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Fee_Type_ID COMMENT 'Always 2 - spot price adjustment';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN OpenDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN NewOpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsTheDayBefore SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN CloseDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN ExchangeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN AmountInUnitsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_Open SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_To_Charge SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Front SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Next SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Days_Between_Expiration SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Final_Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN Fee_Type_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:04:13 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 62/62 succeeded
-- ====================
