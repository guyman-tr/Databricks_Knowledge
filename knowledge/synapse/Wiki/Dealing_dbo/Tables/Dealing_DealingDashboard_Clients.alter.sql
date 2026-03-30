-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_DealingDashboard_Clients
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients SET TBLPROPERTIES (
    'comment' = 'Dealing_DealingDashboard_Clients is the primary fact table powering the eToro Dealing Dashboard. It provides a comprehensive daily view of client trading activity aggregated at the grain of: **Date × HedgeServerID × InstrumentID × Regulation × Country × Region × Mifid × IsCopy × IsCFD × Leverage × IsFuture** This enables the dealing desk to slice and dice client activity across virtually any business dimension: by regulation, by instrument, by country, by copy trading status, by leverage level, etc. With ~1.83B rows since July 2020, this is one of the largest tables in Dealing_dbo. The CCI storage with two NCIs (DateID and Date+InstrumentID) supports efficient analytical queries. Key metric groups: - **Volume**: VolumeOnOpen, VolumeOnClose, VolumeBuy, VolumeSell, TotalVolume - **Position metrics**: NOP, LongOpenPositions, ShortOpenPositions, UnitsNOP, UnitsBuy, UnitsSell - **Position counts**: NumberOfPositions, NumberOfPositionsOpened, NumberOfPositionsClosed - **Revenue (Zero)**: RealizedZero, ChangeInUn...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED COLUMNSTORE + NCI on DateID + NCI on (Date, InstrumentID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Date COMMENT 'Reporting date. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN DateID COMMENT 'Date as YYYYMMDD integer. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN HedgeServerID COMMENT 'Hedge server routing the position. From Dim_Position. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentType COMMENT 'Asset class from Dim_Instrument. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable instrument name. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentName COMMENT 'Instrument ticker e.g. `AMD.RTH/USD`. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Symbol COMMENT 'Short ticker symbol e.g. `AMD`. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN SellCurrency COMMENT 'Quote/sell currency of the instrument. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Exchange COMMENT 'Stock exchange. From Dim_Instrument. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Regulation COMMENT 'Client''s regulatory jurisdiction. From Dim_Regulation via Fact_SnapshotCustomer. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Country COMMENT 'Client''s country. From Dim_Country via Fact_SnapshotCustomer. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Region COMMENT 'Client''s geographic region. From Fact_SnapshotCustomer. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Mifid COMMENT 'MiFID classification: ''Retail'' (IDs 1,4), ''Professional'' (IDs 2,3), or Dim_MifidCategorization.Name. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsCopy COMMENT 'Copy trading flag. `CASE WHEN MirrorID>0 THEN 1 ELSE 0 END`. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsCFD COMMENT 'CFD flag. `CASE WHEN IsSettled=1 THEN 0 ELSE 1 END`. 1=CFD, 0=Real. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Leverage COMMENT 'Position leverage level from Dim_Position. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeOnOpen COMMENT 'Trading volume from positions opened today. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeOnClose COMMENT 'Trading volume from positions closed today. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeBuy COMMENT 'Buy-direction volume (open buy + close sell). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeSell COMMENT 'Sell-direction volume (open sell + close buy). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TotalVolume COMMENT 'VolumeOnOpen + VolumeOnClose. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NOP COMMENT 'Net open position value from BI_DB_PositionPnL. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN LongOpenPositions COMMENT 'NOP for long positions (IsBuy=1). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN ShortOpenPositions COMMENT 'ABS(NOP) for short positions (IsBuy=0). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsNOP COMMENT 'Net units in open positions. Positive=long, negative=short. Only for positions still open at EOD. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsBuy COMMENT 'Units in buy-direction flow (open buy + close sell). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsSell COMMENT 'Units in sell-direction flow (open sell + close buy). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositions COMMENT 'Count of distinct positions (excludes partial close children). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositionsOpened COMMENT 'Positions opened today (excludes partial close children). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositionsClosed COMMENT 'Positions closed today. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN RealizedZero COMMENT 'Realized eToro revenue (Zero) from closed positions. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN ChangeInUnrealizedZero COMMENT 'Daily change in unrealized eToro revenue from open positions. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TotalZero COMMENT 'Total eToro daily revenue: Realized + ChangeInUnrealized. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommission COMMENT 'Total commission. `ISNULL(FullCommission, Commission)` from Dim_Position. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommissionOnOpen COMMENT 'Commission charged on position open. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommissionOnClose COMMENT 'Commission charged on position close. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VariableSpread COMMENT 'Spread revenue. `Units*(Ask-Bid)*USDRate`, varies by open/close timing. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee COMMENT 'Total overnight fee charged. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Dividend COMMENT 'Dividend adjustments on positions. From Fact_DividendTransaction. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee_Long COMMENT 'Overnight fee for long positions only. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee_Short COMMENT 'Overnight fee for short positions only. (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TicketFees COMMENT 'Ticket fees charged. From Fact_TicketFee. Added SR-263106 (2024-07). (Tier 2 - SP_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsFuture COMMENT 'Whether instrument is a future contract. From Dim_Instrument.IsFuture. Added SR-303782 (2025-03). (Tier 2 - SP_DealingDashboard_Clients)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Mifid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TotalVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN LongOpenPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN ShortOpenPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsNOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UnitsSell SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositionsOpened SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN NumberOfPositionsClosed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN RealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN ChangeInUnrealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TotalZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN VariableSpread SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN Dividend SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee_Long SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN OverNightFee_Short SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN TicketFees SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
