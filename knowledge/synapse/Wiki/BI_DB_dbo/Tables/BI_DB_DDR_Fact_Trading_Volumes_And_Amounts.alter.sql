-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts > 793M-row daily trading volume and invested amount fact table tracking position open/close volumes, invested amounts, and transaction counts per customer, broken down by instrument type, settlement, copy-trade, leverage, and 8+ position flags. Sourced from `Function_Trading_Volume_PositionLevel` (which reads `Dim_Position`, `Dim_Instrument`, and multiple enrichment tables), aggregated by `SP_DDR_Fact_Trading_Volumes_And_Amounts` with daily DELETE/INSERT by DateID. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel` -> `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument` | | **Refresh** | Daily (DELETE/INSERT by DateID) | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD format. DELETE/INSERT partition key. Direct from `Function_Trading_Volume_PositionLevel.DateID` (open or close date). (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN Date COMMENT 'Calendar date. `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)`. Derived from DateID in SP. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN RealCID COMMENT 'Customer identifier. Renamed from `Function_Trading_Volume_PositionLevel.CID`. Distribution key. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InstrumentTypeID COMMENT 'Instrument asset class. From `Dim_Instrument.InstrumentTypeID` via function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopy COMMENT 'Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsBuy COMMENT 'Trade direction. 1=buy/long, 0=sell/short. Direct from function -> `Dim_Position.IsBuy`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsLeverage COMMENT 'Leverage flag. `CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END`. Note: named `IsLeverage` (not `IsLeveraged`). (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsFuture COMMENT 'Futures contract flag. Direct from function -> `Dim_Instrument.IsFuture`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopyFund COMMENT 'Smart Portfolio flag. `CASE WHEN BI_DB_CopyFund_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsOpenedFromIBAN COMMENT 'Position opened from eMoney IBAN flag. `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. **DDL is varchar(100), stores ''0''/''1'' as strings.** (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsClosedToIBAN COMMENT 'Position closed to eMoney IBAN flag. `CASE WHEN BI_DB_Positions_Closed_To_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsRecurring COMMENT 'Recurring investment flag. `CASE WHEN BI_DB_RecurringInvestment_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsAirDrop COMMENT 'AirDrop (free share) flag. Direct from function -> `Dim_Position.IsAirDrop`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeOpen COMMENT 'Aggregated notional volume from position opens. `SUM(ftv.VolumeOpen)`. Source: `ISNULL(CAST(Dim_Position.Volume AS BIGINT), 0)` on open legs. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeClose COMMENT 'Aggregated notional volume from position closes. `SUM(ftv.VolumeClose)`. Source: `ISNULL(CAST(Dim_Position.VolumeOnClose AS BIGINT), 0)` on close legs. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountOpen COMMENT 'Aggregated invested amount from position opens. `SUM(ftv.InvestedAmountOpen)`. Source: `InitialAmountCents / 100.0` (0 for partial-close children). (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountClosed COMMENT 'Aggregated invested amount from position closes. `SUM(ftv.InvestedAmountClosed)`. Source: `CAST(Dim_Position.Amount AS FLOAT)` on close legs. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN TotalVolume COMMENT 'Combined open + close volume. `SUM(ftv.TotalVolume)`. Per position: `ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN NetInvestedAmount COMMENT 'Net investment flow. `SUM(ftv.NetInvestedAmount)`. Per position: `InvestedAmountOpen - InvestedAmountClosed`. Positive = net new investment. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountOpenTransactions COMMENT 'Count of position opens (excl. partial-close children). `SUM(ftv.CountOpenTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountCloseTransactions COMMENT 'Count of position closes. `SUM(ftv.CountCloseTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountTotalTransactions COMMENT 'Total open + close count. `SUM(ftv.CountTotalTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSQF COMMENT 'Sustainable & Quality-Focused instrument flag. From `Function_Instrument_Snapshot_Enriched` in the source function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsMarginTrade COMMENT 'Margin trade flag. `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsC2P COMMENT 'Copy-to-Portfolio flag. `CASE WHEN V_C2P_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsOpenedFromIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsClosedToIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountClosed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN TotalVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN NetInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountOpenTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountCloseTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountTotalTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSQF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsMarginTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsC2P SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:04:57 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 56/56 succeeded
-- ====================
