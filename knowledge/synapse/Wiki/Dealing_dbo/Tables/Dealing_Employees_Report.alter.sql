-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Employees_Report
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report SET TBLPROPERTIES (
    'comment' = 'Daily position-level report of all open and closed positions belonging to employee accounts (AccountTypeID IN 7, 13). Contains both current open positions and positions closed on the reporting date, enriched with P&L, pricing, equity, and gain metrics. The largest table in this batch at ~231.4M rows. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Distribution** | HASH(CID) | | **Index** | Clustered (Date ASC) | | **Row Count** | ~231.4M | | **Date Range** | Historical -> present (last: 2026-03-10) | | **Grain** | One row per Date × PositionID (open + closed) | | **Refresh** | Daily, via SP_Employees_Report |'
);

ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Date COMMENT 'Report date';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PositionID COMMENT 'Position identifier';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CID COMMENT 'Employee customer ID (AccountTypeID IN 7,13; IsValidCustomer=0)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InstrumentID COMMENT 'Instrument identifier';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InstrumentType COMMENT 'Asset class (Stocks, Crypto, Currencies, Commodities, Indices, ETF)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Symbol COMMENT 'Instrument ticker symbol';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Amount COMMENT 'Invested amount in USD';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration_seconds COMMENT 'Position holding time in seconds (NULL for open)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration_minutes COMMENT 'Position holding time in minutes';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration COMMENT 'Position holding time in days';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Leverage COMMENT 'Leverage multiplier';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Direction COMMENT '''Buy'' or ''Sell''';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CopyTarde COMMENT '''Copy'' if IsMirrorPosition=1, else ''Manual'' (typo: ''Tarde'' should be ''Trade'')';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN ReaL_CFD COMMENT '''Real'' or ''CFD'' based on IsReal flag';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_daily_Volume COMMENT 'Total opens+closes volume for this CID on @Date';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_daily_clicks COMMENT 'Count of trades opened+closed for CID on @Date';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN NetProfit COMMENT 'Realized P&L (NULL for open positions)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PositionPnL COMMENT 'Current P&L: for open positions = BI_DB_PositionPnL; for closed = final NetProfit';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN DateID COMMENT 'Date integer key (YYYYMMDD)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN NOP COMMENT 'Net open position value';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN DailyPnL COMMENT 'Daily P&L: open=PositionPnL.DailyPnL; same-day close=NetProfit; prior-day close=NetProfit - previos_Position_PnL';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN BonusCredit COMMENT 'Employee bonus credit balance';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RealizedEquity COMMENT 'Realized equity value';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN MirrorID COMMENT 'Copy relationship ID (if IsMirrorPosition=1)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_Daily_Commission COMMENT 'Sum of commissions for this CID on @Date';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OpenOccurred COMMENT 'Position open timestamp';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CloseOccurred COMMENT 'Position close timestamp (NULL if open)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN StopRate COMMENT 'Stop-loss rate';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Exchange COMMENT 'Exchange name';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalPositionsAmount COMMENT 'Sum of all position amounts for CID';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalCash COMMENT 'Total cash balance';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Total copy positions amount';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalMirrorCash COMMENT 'Total copy cash';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Credit COMMENT 'Credit balance';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CopyPositionPnL COMMENT 'P&L from copy positions';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN All_Positions_PNL COMMENT 'Total P&L across all positions for CID';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CountryID COMMENT 'Employee country ID';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Country COMMENT 'Employee country name';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_MTD COMMENT 'Month-to-date gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_YTD COMMENT 'Year-to-date gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_d COMMENT 'Daily gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_QTD COMMENT 'Quarter-to-date gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_w COMMENT 'Week-to-date gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_m COMMENT 'Month gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_y COMMENT 'Year gain percentage';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Units COMMENT 'Position units';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Volume COMMENT 'Trade open click count';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN VolumeOnClose COMMENT 'Trade close click count';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OpenDateID COMMENT 'Open date integer key';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CloseDateID COMMENT 'Close date integer key';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN previos_Position_PnL COMMENT 'Prior day''s PositionPnL - used for DailyPnL calculation on prior-day closes (typo: ''previos'' not ''previous'')';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InitForexRate COMMENT 'Opening price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN EndForexRate COMMENT 'Closing price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Price COMMENT 'Current market price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Change_Price COMMENT 'Price change vs prior day';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RateBid COMMENT 'Current bid price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RateAsk COMMENT 'Current ask price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Price COMMENT 'Prior day''s market price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Change_Price COMMENT 'Prior day''s price change';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Amount COMMENT 'Prior day''s invested amount';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Units COMMENT 'Prior day''s position units';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_DailyPnL COMMENT 'Prior day''s DailyPnL';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PreviousBid COMMENT 'Prior day''s bid price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PreviousAsk COMMENT 'Prior day''s ask price';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN ConversionRate COMMENT 'USD conversion rate';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN IsChild COMMENT 'Child position flag (sub-position in a copy)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN IsParent COMMENT 'Parent position flag';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OriginalPositionID COMMENT 'Original position ID in copy chain';

-- ---- Column PII Tags ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration_seconds SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration_minutes SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Duration SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Direction SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CopyTarde SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN ReaL_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_daily_Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_daily_clicks SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN DailyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN BonusCredit SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Total_Daily_Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN StopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalCash SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalMirrorPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN TotalMirrorCash SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CopyPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN All_Positions_PNL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_MTD SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_YTD SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_d SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_QTD SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_w SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_m SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Gain_y SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN VolumeOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OpenDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN CloseDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN previos_Position_PnL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN InitForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN EndForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Price SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Change_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RateBid SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN RateAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Change_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN Previous_DailyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PreviousBid SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN PreviousAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN IsChild SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN IsParent SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN OriginalPositionID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:02:43 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 140/140 succeeded
-- ====================
