-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Rollover_Assurance
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance SET TBLPROPERTIES (
    'comment' = 'This table is a **rollover fee quality-assurance audit trail**. Each day, SP_Rev_Assurance calculates what overnight fees *should have been* charged for every eligible open position (based on instrument fee config and day-of-week multipliers) and compares this against the fees *actually* recorded in the credit history. Only rows where the discrepancy exceeds $1 are retained. **Coverage**: Commodities dominate (~70% of rows), followed by Crypto, FX, Stocks, and Indices. This reflects the relative overnight-fee volume by asset class. **Exclusions applied by SP**: - Positions that are long (IsBuy=1) and unleveraged (Leverage=1) on Stocks or ETFs - these have no overnight fee - HedgeServerID=121 (special hedge server excluded from rollover tracking) - PI/premium accounts (Dim_Customer.PlayerLevelID=4) Synapse: HASH (CID, InstrumentID), CLUSTERED COLUMNSTORE INDEX.'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (CID, InstrumentID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE INDEX',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Date COMMENT 'Reporting date (the cutoff date for which rollover fees are evaluated) (Tier 2 - SP parameter)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN PositionID COMMENT 'Unique position identifier (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN CID COMMENT 'Customer identifier (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentID COMMENT 'Instrument identifier (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentName COMMENT 'Instrument display name (e.g., XAU/USD, BTC) (Tier 1 - DWH_dbo.Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentType COMMENT 'Instrument class: Commodities, Crypto Currencies, Currencies, Stocks, Indices, ETF (Tier 1 - DWH_dbo.Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN OpenOccurred COMMENT 'Timestamp when the position was opened (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN CloseOccurred COMMENT 'Timestamp when the position was closed; GETDATE() for open positions at execution time (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Units COMMENT 'Position size in instrument units (AmountInUnitsDecimal) (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Leverage COMMENT 'Leverage multiplier applied to the position (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN IsBuy COMMENT 'Direction: 1 = long (buy), 0 = short (sell) (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN MirrorID COMMENT 'Copy-trading mirror ID; 0 = manual trade, >0 = copy position (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN HedgeServerID COMMENT 'Hedge server routing identifier; HedgeServerID=225 = NOP server (unhedged) (Tier 1 - DWH_dbo.Dim_Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN WeekendFeePrecentage COMMENT 'Customer''s weekend fee percentage; 0 = Islamic/swap-free account (no overnight fees) (Tier 4 - etoro_Customer_CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Calculated RO] COMMENT 'Model-calculated rollover fee: day_multiplier × Units × overnight_fee_rate from InstrumentToFeeConfig (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Actual RO] COMMENT 'Actual rollover fee charged, sourced from etoro_History_Credit CreditTypeID=14 (excludes dividend payments) (Tier 4 - Dealing_staging.etoro_History_Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Total Diff] COMMENT 'Discrepancy: [Calculated RO] - [Actual RO]; positive = model expected more than was charged (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Islamic] COMMENT 'Portion of [Total Diff] attributable to Islamic/swap-free accounts (WeekendFeePrecentage=0) (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Closed after cutoff] COMMENT 'Portion of [Total Diff] where a non-Islamic position closed within 90 minutes of the cutoff time (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Fee updated] COMMENT 'Portion of [Total Diff] for non-Islamic positions on Natural Gas (InstrumentID=22) or Crypto/ETF (InstrumentTypeID 5,6) - typically reflects fee config change lag (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Other] COMMENT 'Remaining unexplained discrepancy not covered by the other three categories (Tier 2 - computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 - GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN WeekendFeePrecentage SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Calculated RO] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Actual RO] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Total Diff] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Islamic] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Closed after cutoff] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Fee updated] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN [Other] SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
