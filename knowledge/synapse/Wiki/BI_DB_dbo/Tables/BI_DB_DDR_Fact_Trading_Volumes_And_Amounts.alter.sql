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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InstrumentTypeID COMMENT 'Instrument asset class ID. Key values: 1=Currencies/Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETFs, 9=Options, 10=Crypto. Combine with IsSettled: ID=5+IsSettled=1 = real stocks; ID=10+IsSettled=0 = crypto CFD; ID=10+IsSettled=1 = real crypto. JOIN to DWH_dbo.Dim_InstrumentType for name. Source: Dim_Instrument via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSettled COMMENT 'Real-asset settlement flag. 1 = real/settled ownership (real crypto, real stocks/ETFs - actual transfer of ownership). 0 = CFD (Contract for Difference - synthetic price exposure, no ownership). Critical for volume reporting: regulators and management track CFD vs real volumes separately. Source: Dim_Position.IsSettled via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopy COMMENT 'Copy-trade flag. CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END. 1 = position created as part of copying another trader (MirrorID links to Dim_Mirror copy relationship). 0 = manual/self-directed trade. Does not distinguish CopyFund (Smart Portfolio) from regular copy - use IsCopyFund for that. Source: Dim_Position.MirrorID via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsBuy COMMENT 'Trade direction. 1=buy/long, 0=sell/short. Direct from function -> `Dim_Position.IsBuy`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsLeverage COMMENT 'Leverage flag. `CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END`. Note: named `IsLeverage` (not `IsLeveraged`). (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsFuture COMMENT 'Futures contract flag. Direct from function -> `Dim_Instrument.IsFuture`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopyFund COMMENT 'CopyFund / Smart Portfolio flag. 1 = position belongs to a managed Smart Portfolio product where a portfolio manager allocates across assets. Distinct from regular copy-trading: CopyFunds are discretionary managed products. Lookup via BI_DB_CopyFund_Positions table. Source: BI_DB_CopyFund_Positions via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsOpenedFromIBAN COMMENT 'Position opened from eMoney IBAN/wallet funds. 1 = opening capital came from the eMoney wallet rather than the main TP wallet. IMPORTANT: DDL is varchar(100) - compare as string 0/1, not integer. Lookup via BI_DB_Positions_Opened_From_IBAN. Source: Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsClosedToIBAN COMMENT 'Position closed to eMoney IBAN flag. `CASE WHEN BI_DB_Positions_Closed_To_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsRecurring COMMENT 'Recurring investment flag. 1 = position opened via the Recurring Investment auto-invest feature. Lookup via BI_DB_RecurringInvestment_Positions. Useful for segmenting auto-investing vs manual trading behaviour. Source: BI_DB_RecurringInvestment_Positions via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsAirDrop COMMENT 'AirDrop (free share) flag. Direct from function -> `Dim_Position.IsAirDrop`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeOpen COMMENT 'Aggregated notional volume from position opens on this date (BIGINT). SUM of CAST(Dim_Position.Volume AS BIGINT) for open legs. Partial-close children excluded (VolumeOpen=0 to avoid double-counting). Primary trading volume KPI for new positions opened. Source: Dim_Position.Volume via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeClose COMMENT 'Aggregated notional volume from position closes on this date (BIGINT). SUM of CAST(Dim_Position.VolumeOnClose AS BIGINT) for close legs. Source: Dim_Position.VolumeOnClose via Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountOpen COMMENT 'Aggregated invested amount from position opens. `SUM(ftv.InvestedAmountOpen)`. Source: `InitialAmountCents / 100.0` (0 for partial-close children). (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountClosed COMMENT 'Aggregated invested amount from position closes. `SUM(ftv.InvestedAmountClosed)`. Source: `CAST(Dim_Position.Amount AS FLOAT)` on close legs. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN TotalVolume COMMENT 'Combined notional volume open + close on this date (BIGINT). SUM of per-position (VolumeOpen+VolumeClose). A position opened AND closed on the same day contributes to both. Primary trading volume KPI used in eToro management reporting. Source: Function_Trading_Volume_PositionLevel. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN NetInvestedAmount COMMENT 'Net investment flow. `SUM(ftv.NetInvestedAmount)`. Per position: `InvestedAmountOpen - InvestedAmountClosed`. Positive = net new investment. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountOpenTransactions COMMENT 'Count of position opens (excl. partial-close children). `SUM(ftv.CountOpenTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountCloseTransactions COMMENT 'Count of position closes. `SUM(ftv.CountCloseTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountTotalTransactions COMMENT 'Total open + close count. `SUM(ftv.CountTotalTransactions)`. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSQF COMMENT 'Sustainable & Quality-Focused instrument flag. From `Function_Instrument_Snapshot_Enriched` in the source function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsMarginTrade COMMENT 'Margin trade flag. `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END` in function. (Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsC2P COMMENT 'Copy-to-Portfolio (C2P) flag. 1 = position was migrated from a copy relationship into the customer own portfolio after they stopped copying a trader. Allows keeping a position without the copy overhead. Lookup via V_C2P_Positions. Source: Function_Trading_Volume_PositionLevel. (Tier 1)';

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
-- Timestamp: 2026-04-16 08:41:44 UTC
-- TVF DDR enrichment deploy
-- Statements: 56/56 succeeded
-- ====================
