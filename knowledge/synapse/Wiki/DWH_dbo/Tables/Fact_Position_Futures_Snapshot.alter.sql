-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Position_Futures_Snapshot
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN Date COMMENT 'Settlement date. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN DateID COMMENT 'Settlement date in YYYYMMDD format. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementCategory COMMENT '''OpenAtSettlement'' = position still open at settlement time. ''ClosedBeforeSettlement'' = position closed between prev and current settlement. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN CID COMMENT 'Customer ID (Real account). (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN PositionID COMMENT 'Unique position identifier. Distribution key. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN OriginalPositionID COMMENT 'Parent position ID for partial-close child positions. Equals PositionID for non-partial positions. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InstrumentID COMMENT 'Futures instrument traded. JOINs to Dim_Instrument. Only IsFuture=1 instruments included. (Tier 2 - Dim_Instrument_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN LotCountDecimal COMMENT 'Number of lots at settlement time. Adjusted for partial closes via changelog reconstruction. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementTime COMMENT 'Exact settlement time from Dim_Instrument_Snapshot. Varies by instrument. (Tier 2 - Dim_Instrument_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementPrice COMMENT 'Official settlement price from Fact_Settlement_Prices. Latest available within 14-day lookback. NULL if no settlement price found. (Tier 2 - Fact_Settlement_Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InvestedAmount COMMENT 'Cash invested in the position at settlement time. Mapped from Dim_Position.Amount, adjusted for changelog changes. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN OpenOccurred COMMENT 'When the position was originally opened. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN CloseOccurred COMMENT 'When the position was closed. ''1900-01-01'' for open positions. (Tier 2 - Dim_Position / SP sentinel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitForexRate COMMENT 'Opening price / forex rate at position open. Used in mark-to-market PnL calculation. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN EndForexRate COMMENT 'Closing price / forex rate at position close. NULL for open positions. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsPartialCloseParent COMMENT '1 = position has been partially closed (some lots removed). 0 = full position. Reconstructed from changelog. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsPartialCloseChild COMMENT '1 = this position is the closed-off portion created by a partial close event (not the remainder). Child positions are excluded from OpenAtSettlement rows in this table; they appear only in ClosedBeforeSettlement rows.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsBuy COMMENT 'Direction: 1 = long (buy), 0 = short (sell). (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN ProviderID COMMENT 'Liquidity provider for this futures instrument. From Dim_Instrument_Snapshot. (Tier 2 - Dim_Instrument_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN Multiplier COMMENT 'Contract size multiplier. From Dim_Instrument_Snapshot. Used in PnL: LotCount × Multiplier × Price. (Tier 2 - Dim_Instrument_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN ProviderMargin COMMENT 'Margin required by the liquidity provider: LotCountDecimal × ProviderMarginPerLot. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN eToroMargin COMMENT 'Margin required by eToro: LotCountDecimal × eToroMarginPerLot. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN PnL COMMENT 'Mark-to-market PnL. Open: `LotCount × Multiplier × (SettlementPrice - InitForexRate)`. Closed: Dim_Position.NetProfit. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialLotCountDecimalFull COMMENT 'Original lot count at position open (before any partial closes). (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialInvestedAmountFull COMMENT 'Original invested amount at position open (before any partial closes). (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialProviderMarginFull COMMENT 'Original provider margin at position open: InitialLotCount × ProviderMarginPerLot. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialeToroMarginFull COMMENT 'Original eToro margin at position open: InitialLotCount × eToroMarginPerLot. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialLotCountDecimalResidual COMMENT 'Residual lot count at settlement (after partial closes). Equals LotCountDecimal. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialInvestedAmountResidual COMMENT 'Pro-rated invested amount based on residual lot ratio: InitialInvestedAmount × (ResidualLots / FullLots). (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialProviderMarginResidual COMMENT 'Residual provider margin: ProviderMarginPerLot × ResidualLotCount. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialeToroMarginResidual COMMENT 'Residual eToro margin: eToroMarginPerLot × ResidualLotCount. (Tier 2 - SP_Fact_Position_Futures_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE(). (Tier 2 - SP_Fact_Position_Futures_Snapshot)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN OriginalPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN LotCountDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN SettlementPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN EndForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsPartialCloseParent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsPartialCloseChild SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN ProviderID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN Multiplier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN ProviderMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN eToroMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN PnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialLotCountDecimalFull SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialInvestedAmountFull SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialProviderMarginFull SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialeToroMarginFull SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialLotCountDecimalResidual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialInvestedAmountResidual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialProviderMarginResidual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN InitialeToroMarginResidual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_position_futures_snapshot ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

