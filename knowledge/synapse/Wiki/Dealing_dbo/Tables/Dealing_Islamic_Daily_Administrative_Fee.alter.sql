-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee SET TAGS (
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
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Date COMMENT 'Report date';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN DateID COMMENT 'YYYYMMDD of Date';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN PositionID COMMENT 'Position identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN RealCID COMMENT 'Client ID (Islamic account holder)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN GCID COMMENT 'Global customer ID';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN UserName COMMENT 'Client username';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CountryID COMMENT 'Client country';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN OpenDateID COMMENT 'Date position opened';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN OpenOccurred COMMENT 'Exact open timestamp';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN NewOpenOccurred COMMENT 'Open date adjusted for 22:00 cutoff';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN IsTheDayBefore COMMENT '1 if position opened after 22:00 UTC';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CloseDateID COMMENT 'Date position closed; 0 if still open';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CloseOccurred COMMENT 'Exact close timestamp';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentTypeID COMMENT '1=FX, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentID COMMENT 'Instrument identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentGroup COMMENT 'Manual Islamic group ID';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Units_per_Contract COMMENT 'Contract size for Commodities';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN ExchangeID COMMENT 'Exchange ID (day-counting rule selector)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN IsBuy COMMENT '1=long, 0=short';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Leverage COMMENT 'Position leverage';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN USD_Price COMMENT 'EOD USD price: Bid×ConvertRate (IsBuy=1) or Ask×ConvertRate (IsBuy=0)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN AmountInUnitsDecimal COMMENT 'Position size in instrument units';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Admin_Fee_USD COMMENT 'Fee rate per unit-equivalent per day';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_Open COMMENT 'Effective days open using exchange-appropriate counting';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN GracePeriod COMMENT 'Days before fee starts accruing';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_Admin_Fee COMMENT 'Days_Open - GracePeriod (net chargeable days)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_To_Charge COMMENT 'Actual multiplier for today''s charge: 0/1/2/3';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Final_Fee COMMENT 'Computed fee in USD; always <= 0';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Fee_Type_ID COMMENT 'Always 1 - administrative fee';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN OpenDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN NewOpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN IsTheDayBefore SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CloseDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN InstrumentGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Units_per_Contract SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN ExchangeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN USD_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN AmountInUnitsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Admin_Fee_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_Open SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN GracePeriod SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_Admin_Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Days_To_Charge SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Final_Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN Fee_Type_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
