-- =============================================================================
-- Databricks Deep Lineage Column Comment Propagation: DWH_dbo.Dim_Position
-- Generated: 2026-03-16 | dwh-semantic-doc pipeline (deep lineage)
--
-- Source (UC): main.dwh.dim_position
-- Source (Synapse): DWH_dbo.Dim_Position
--
-- Target tables (60):
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level  (TABLE, 3 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings  (TABLE, 2 cols)
--   main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new  (TABLE, 3 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee  (TABLE, 10 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl  (TABLE, 26 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment  (TABLE, 10 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro  (TABLE, 2 cols)
--   main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro  (TABLE, 1 cols)
--   main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition  (TABLE, 7 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid  (TABLE, 3 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport  (TABLE, 8 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results  (TABLE, 2 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss  (TABLE, 11 cols)
--   main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk  (TABLE, 4 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution  (TABLE, 9 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata  (TABLE, 2 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon  (TABLE, 2 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity  (TABLE, 3 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop  (TABLE, 3 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends  (TABLE, 5 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks  (TABLE, 2 cols)
--   main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts  (TABLE, 3 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends  (TABLE, 1 cols)
--   main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report  (TABLE, 17 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster  (TABLE, 1 cols)
--   main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown  (TABLE, 8 cols)
--   main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction  (TABLE, 32 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions  (TABLE, 4 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk  (TABLE, 1 cols)
--   main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts  (TABLE, 5 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures  (TABLE, 6 cols)
--   main.compliance_stg.rnd_output_dwh_dim_position_lc  (TABLE, 135 cols)
--   main.dealing.rnd_output_dealing_bestexecution_dim_position  (TABLE, 32 cols)
--   main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason  (TABLE, 1 cols)
--   main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog  (TABLE, 5 cols)
-- Target views (3):
--   main.delta_api.v_dwh_dim_position  (VIEW, 25 cols)
--   main.api_delta.v_dwh_dim_position  (VIEW, 26 cols)
--   main.data_rooms.vw_dim_position  (VIEW, 106 cols)
-- =============================================================================

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level (TABLE, 3 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings (TABLE, 2 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata (TABLE, 1 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients (TABLE, 2 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new (TABLE, 3 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee (TABLE, 10 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `OpenDateID` COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `CloseDateID` COMMENT 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `OpenOccurred` COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl (TABLE, 26 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Commission` COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `InitForexRate` COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `SpreadedPipBid` COMMENT 'Bid-side spread rate at open (instrument bid after spread mark-up). Used in PnL and hedge calculations.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `SpreadedPipAsk` COMMENT 'Ask-side spread rate at open (instrument ask after spread mark-up). Used in PnL and hedge calculations.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `LimitRate` COMMENT 'Take-profit rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves favorably.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `StopRate` COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `EstimateCloseFeeForCFD` COMMENT 'Estimated close fee for CFD positions. From Trade.OpenPositionEndOfDay.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `EstimateCloseFeeOnOpenByUnits` COMMENT 'Estimated close fee at open, per unit.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `EstimateCloseFeeOnOpen` COMMENT 'Estimated close fee recorded at open.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Close_PnLInDollars` COMMENT 'Same as PnLInDollars but based on closing price instead of last (current) price.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Close_CalculationRate` COMMENT 'Instrument rate used to compute Close_PnLInDollars (closing-price-based PnL, vs last-price-based PnLInDollars).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Close_ConversionRate` COMMENT 'Currency conversion rate for Close_PnLInDollars. Converts instrument currency to USD using closing price snapshot.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `Close_PriceType` COMMENT 'Closing price source for Close_PnLInDollars. 2=63.5%,1=11.8%,0=6.6%,3=0.05%,NULL=18%. Sources: official close, unofficial close, dealer injection, last internal price. Value-to-source mapping TBD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `CurrentCalculationRate` COMMENT 'Current calculation rate for open position PnL (end-of-day snapshot).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN `CurrentConversionRate` COMMENT 'Current conversion rate for open position PnL (end-of-day snapshot).';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment (TABLE, 10 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `OpenDateID` COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `CloseDateID` COMMENT 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `OpenOccurred` COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary (TABLE, 1 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro (TABLE, 2 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro (TABLE, 1 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints (TABLE, 2 columns)
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition (TABLE, 7 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `IsComputeForHedge` COMMENT 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid (TABLE, 3 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport (TABLE, 8 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `VolumeOnClose` COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon (TABLE, 2 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss (TABLE, 11 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `NetProfit` COMMENT 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `InitForexRate` COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `EndForexRate` COMMENT 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `StopRate` COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN `LastOpConversionRate` COMMENT 'Conversion rate from most recent overnight operation for non-USD instruments.';

-- main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk (TABLE, 4 columns)
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg (TABLE, 8 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `VolumeOnClose` COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings (TABLE, 2 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution (TABLE, 9 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN `commission` COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon (TABLE, 2 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity (TABLE, 3 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop (TABLE, 3 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends (TABLE, 5 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `IsComputeForHedge` COMMENT 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks (TABLE, 2 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';

-- main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients (TABLE, 1 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts (TABLE, 3 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report (TABLE, 17 columns)
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `NetProfit` COMMENT 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `OpenOccurred` COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `StopRate` COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `VolumeOnClose` COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `OpenDateID` COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `CloseDateID` COMMENT 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `InitForexRate` COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `EndForexRate` COMMENT 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
ALTER TABLE main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report ALTER COLUMN `OriginalPositionID` COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates (TABLE, 1 columns)
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown (TABLE, 8 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `FullCommission` COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';

-- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction (TABLE, 32 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `PlatformTypeID` COMMENT '[UNVERIFIED] Platform type. Not populated — always NULL in this table.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `NetProfit` COMMENT 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `Commission` COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `FullCommission` COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `RedeemID` COMMENT 'Crypto redemption transaction record reference. NULL when RedeemStatus=0.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `RedeemStatus` COMMENT 'Crypto redemption status — tracks position to crypto-in-wallet loop: 0=N/A,1=Pending,6=PositionClosed(redeem),20=Terminated,21=FailedToCancel. Refs Dim_RedeemStatus.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `RegulationIDOnOpen` COMMENT 'Regulation at open. DWH-joined from BackOfficeCustomer. 0=None,1=CySEC,2=FCA,3=eToroUS,4=ASIC,5=BVI,6=FinCEN,7=FINRAONLY,8=MAS,9=FSA Seychelles,10=ASIC&GAML,11=FSRA,12=NYDFS+FINRA. Refs Dim_Regulation.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `ReopenForPositionID` COMMENT 'For reopened positions: references the original closed PositionID this position replaces.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsReOpen` COMMENT 'Reopen flag: 1=created by reopening a previously closed position (e.g., after corporate action). Default 0.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `CommissionOnCloseOrig` COMMENT 'Original CommissionOnClose before reopen adjustment by SP_Dim_Position_ReOpen.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `FullCommissionOnCloseOrig` COMMENT 'Original FullCommissionOnClose before reopen adjustment.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `OriginalPositionID` COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsPartialCloseParent` COMMENT 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsPartialCloseChild` COMMENT 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `InitialUnits` COMMENT 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsDiscounted` COMMENT 'Discounted pricing from Trade.PositionTreeInfo: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `CommissionByUnits` COMMENT 'eToro markup prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Adjusts for partial closes.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `FullCommissionByUnits` COMMENT 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Adjusts for partial closes.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `DLTOpen` COMMENT 'DLT broker flag at open: 1=opened on DLT platform (German crypto broker for trade execution), 0/NULL=not DLT.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `DLTClose` COMMENT 'DLT broker flag at close: 1=closed on DLT platform (German crypto broker), 0/NULL=not DLT.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `OpenMarkupByUnits` COMMENT 'eToro open markup prorated by units: OpenMarkup * AmountInUnitsDecimal / InitialUnits. Adjusts for partial closes.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions (TABLE, 4 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';

-- main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients (TABLE, 6 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `VolumeOnClose` COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `FullCommission` COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level (TABLE, 6 columns)
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `CommissionVersion` COMMENT 'Commission calculation version. Different values represent different versions/models of how commission is computed.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts (TABLE, 5 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `OpenDateID` COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding (TABLE, 1 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures (TABLE, 6 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN `OrderID` COMMENT 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';

-- main.delta_api.v_dwh_dim_position (VIEW, 25 columns)
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`PositionID` IS 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`CID` IS 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`InstrumentID` IS 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`IsBuy` IS 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`MirrorID` IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`ParentPositionID` IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`Amount` IS 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`Leverage` IS 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`OrderID` IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`NetProfit` IS 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`IsSettled` IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`InitialUnits` IS 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`AmountInUnitsDecimal` IS 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`CloseDateID` IS 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`OpenOccurred` IS 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`InitForexRate` IS 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`UnitMargin` IS 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`StopRate` IS 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`IsPartialCloseParent` IS 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`IsPartialCloseChild` IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`InitialAmountCents` IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`EndOfWeekFee` IS 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`EndForexRate` IS 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`EndForex_BidSpreaded` IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.`CloseOccurred` IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';

-- main.api_delta.v_dwh_dim_position (VIEW, 26 columns)
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`PositionID` IS 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`CID` IS 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`InstrumentID` IS 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`IsBuy` IS 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`MirrorID` IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`ParentPositionID` IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`Amount` IS 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`Leverage` IS 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`OrderID` IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`NetProfit` IS 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`IsSettled` IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`InitialUnits` IS 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`AmountInUnitsDecimal` IS 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`CloseDateID` IS 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`OpenOccurred` IS 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`InitForexRate` IS 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`UnitMargin` IS 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`StopRate` IS 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`IsPartialCloseParent` IS 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`IsPartialCloseChild` IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`InitialAmountCents` IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`EndOfWeekFee` IS 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`EndForexRate` IS 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`EndForex_BidSpreaded` IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`CloseOccurred` IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.`OriginalPositionID` IS 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';

-- main.compliance_stg.rnd_output_dwh_dim_position_lc (TABLE, 135 columns)
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CurrencyID` COMMENT 'Account currency for amounts/commissions. References Dim_Currency. In practice always 1 (USD) in this table.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ProviderID` COMMENT 'Legacy field, always 1. Originally identified the trading provider.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `HedgeID` COMMENT 'Reference to a specific hedge record in Trade.Hedge. Links position to the corresponding hedge order. NULL if no direct hedge record.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LotCountDecimal` COMMENT 'Position size in standard lots. Updated on partial close. Used in overnight fee and hedge calculations.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `UnitMargin` COMMENT 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForexRate` COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `NetProfit` COMMENT 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `SpreadedPipBid` COMMENT 'Bid-side spread rate at open (instrument bid after spread mark-up). Used in PnL and hedge calculations.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `SpreadedPipAsk` COMMENT 'Ask-side spread rate at open (instrument ask after spread mark-up). Used in PnL and hedge calculations.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseOnEndOfWeek` COMMENT 'Weekend close flag from Trade.PositionTreeInfo. Deprecated feature, typically 0.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndOfWeekFee` COMMENT 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Commission` COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenOccurred` COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ParentPositionID` COMMENT 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OrigParentPositionID` COMMENT 'Original parent PositionID at copy time. Preserved even after tree restructuring. Sentinel 1 = independent.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsOpenOpen` COMMENT 'OPEN_OPEN mechanism: 1=created by reinvesting unrealised profit (OpenActionType=3).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenDateID` COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseDateID` COMMENT 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `RegulationIDOnOpen` COMMENT 'Regulation at open. DWH-joined from BackOfficeCustomer. 0=None,1=CySEC,2=FCA,3=eToroUS,4=ASIC,5=BVI,6=FinCEN,7=FINRAONLY,8=MAS,9=FSA Seychelles,10=ASIC&GAML,11=FSRA,12=NYDFS+FINRA. Refs Dim_Regulation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PlatformTypeID` COMMENT '[UNVERIFIED] Platform type. Not populated — always NULL in this table.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PositionSegment` COMMENT '[UNVERIFIED] Position segment. Not populated — always NULL in this table.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Volume` COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenInd` COMMENT '[UNVERIFIED] Open indicator flag. Mostly NULL; values 0 and 1 observed rarely.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `SpreadedCommission` COMMENT 'Spread commission in pips (integer). Used in hedge calculation and spread-group reporting.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForexRate` COMMENT 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LastOpConversionRate` COMMENT 'Conversion rate from most recent overnight operation for non-USD instruments.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LimitRate` COMMENT 'Take-profit rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves favorably.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `StopRate` COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ClosePositionReasonID` COMMENT 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=Hierarchical,13=CopySL,14=ReturnToMarket,15=JoinDemoChallenge,17=ManualUnregister,19=Redeem,20=CloseAll,21=ManualLiquidation,23=Alignment,24=Delist,25=BSL,26=Expiry,27=OpAdjustment,28=Orphaned,29=TransferredOut.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `TreeID` COMMENT 'Copy-trade tree root. Independent: TreeID=PositionID. Copy-trade: TreeID=leader PositionID. All positions sharing a TreeID share SL/TP settings.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `FullCommission` COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsComputeForHedge` COMMENT 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitialAmountCents` COMMENT 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `RedeemStatus` COMMENT 'Crypto redemption status — tracks position to crypto-in-wallet loop: 0=N/A,1=Pending,6=PositionClosed(redeem),20=Terminated,21=FailedToCancel. Refs Dim_RedeemStatus.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `RedeemID` COMMENT 'Crypto redemption transaction record reference. NULL when RedeemStatus=0.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ReopenForPositionID` COMMENT 'For reopened positions: references the original closed PositionID this position replaces.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsReOpen` COMMENT 'Reopen flag: 1=created by reopening a previously closed position (e.g., after corporate action). Default 0.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CommissionOnCloseOrig` COMMENT 'Original CommissionOnClose before reopen adjustment by SP_Dim_Position_ReOpen.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `FullCommissionOnCloseOrig` COMMENT 'Original FullCommissionOnClose before reopen adjustment.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OriginalPositionID` COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsPartialCloseParent` COMMENT 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsPartialCloseChild` COMMENT 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitialUnits` COMMENT 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsPartialCloseChildFromReOpen` COMMENT 'Flag: 1=partial close child of a reopened position. Set by SP_Dim_Position_ReOpen.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsDiscounted` COMMENT 'Discounted pricing from Trade.PositionTreeInfo: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `VolumeOnClose` COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CommissionByUnits` COMMENT 'eToro markup prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Adjusts for partial closes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `FullCommissionByUnits` COMMENT 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Adjusts for partial closes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsCopyFundPosition` COMMENT 'Flag: 1=belongs to CopyFund (tree root CID has AccountTypeID=9 OR MirrorTypeID=4 in Dim_Mirror). NULL=not copy fund.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LastOpPriceRateID` COMMENT 'Price-rate record from most recent overnight operation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForexPriceRateID` COMMENT 'Price-rate snapshot record at open. Enables exact rate lookup for audit/recalculation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForexPriceRateID` COMMENT 'Price-rate snapshot at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForex_Ask` COMMENT 'Ask price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForex_Bid` COMMENT 'Bid price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForex_AskSpreaded` COMMENT 'Ask with spread at open from forex price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForex_BidSpreaded` COMMENT 'Bid with spread at open from forex price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitForex_USDConversionRate` COMMENT 'USD conversion rate at open from forex price snapshot. Used for PnL conversion to USD.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForex_Ask` COMMENT 'Ask price from forex price snapshot at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForex_Bid` COMMENT 'Bid price from forex price snapshot at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForex_AskSpreaded` COMMENT 'Ask with spread at close from forex price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForex_BidSpreaded` COMMENT 'Bid with spread at close from forex price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndForex_USDConversionRate` COMMENT 'USD conversion rate at close from forex price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitExecutionID` COMMENT 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndExecutionID` COMMENT 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitConversionRate` COMMENT 'Conversion rate from instrument currency to account currency at open. Used in PnL currency conversion.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitConversionRateID` COMMENT 'Conversion-rate snapshot record at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarketPriceRateID` COMMENT 'Market price-rate record at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `InitHedgeType` COMMENT 'Hedge model at open: CBH=Client-Based Hedging (~95%), HBC=Hedge Before Client (~5%). Determined from HBCExecutionLog.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EndHedgeType` COMMENT 'Hedge model at close: CBH or HBC. NULL for open positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OrderID` COMMENT 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ExitOrderID` COMMENT 'Exit order ID for stop/limit-triggered closes. NULL for market/direct closes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `IsSettledOnOpen` COMMENT 'Settlement status at open time. May differ from IsSettled if converted after open. Use ISNULL(IsSettledOnOpen,IsSettled) for at-open segmentation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `StopRateOnOpen` COMMENT 'Stop-loss rate at open time. May differ from current StopRate if modified after open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LimitRateOnOpen` COMMENT 'Take-profit rate at open time. May differ from current LimitRate if modified after open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `LastOpPriceRate` COMMENT 'Instrument price from most recent overnight operation. Starting rate for next overnight PnL calculation.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `SettlementTypeID` COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarketPriceRateID` COMMENT 'Market price-rate record at open execution time.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarket_Ask` COMMENT 'Market ask price at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarket_Bid` COMMENT 'Market bid price at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarket_AskSpreaded` COMMENT 'Market ask with spread at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarket_BidSpreaded` COMMENT 'Market bid with spread at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarketCoversionRateBidSpreaded` COMMENT 'Conversion rate (bid-spreaded) at open market snapshot. Note: column name typo "Coversion".';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarketCoversionRateAskSpreaded` COMMENT 'Conversion rate (ask-spreaded) at open market snapshot. Note: column name typo "Coversion".';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarket_AskSpreaded` COMMENT 'Market ask with spread at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarket_BidSpreaded` COMMENT 'Market bid with spread at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarket_Ask` COMMENT 'Market ask price at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarket_Bid` COMMENT 'Market bid price at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarketCoversionRateBidSpreaded` COMMENT 'Conversion rate (bid-spreaded) at close market snapshot. Note: column name typo "Coversion".';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarketCoversionRateAskSpreaded` COMMENT 'Conversion rate (ask-spreaded) at close market snapshot. Note: column name typo "Coversion".';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `RequestOpenOccurred` COMMENT 'UTC timestamp when open was requested. May differ from OpenOccurred if execution was delayed.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `RequestCloseOccurred` COMMENT 'UTC timestamp when close was requested. Used for close latency measurement.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OrderType` COMMENT 'Order type at open. Refs Dictionary.OrderType. Common: NULL(66%),17(28%),0(4%),18/13(rare).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PnLVersion` COMMENT 'PnL formula version: 0=CFD_FORMULA, 1=REAL_FORMULA. NULL=legacy. Determines Trade.FnCalculatePnL code path.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PnLInDollars` COMMENT 'Current unrealized PnL in dollars for open positions (end-of-day snapshot). From Trade.OpenPositionEndOfDay.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarketSpread` COMMENT 'Market spread (variable spread) at open = Ask - Bid. The market-side spread before eToro markup is added.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarketSpread` COMMENT 'Market spread (variable spread) at close = Ask - Bid.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarkupOnOpen` COMMENT 'eToro close-side markup pre-computed at open time. Locks in the close markup rate at entry.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarkup` COMMENT 'eToro markup (additional spread) at open in USD. Same concept as Commission in spread terms.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseMarkup` COMMENT 'eToro markup (additional spread) at close.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `DLTOpen` COMMENT 'DLT broker flag at open: 1=opened on DLT platform (German crypto broker for trade execution), 0/NULL=not DLT.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `DLTClose` COMMENT 'DLT broker flag at close: 1=closed on DLT platform (German crypto broker), 0/NULL=not DLT.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenMarkupByUnits` COMMENT 'eToro open markup prorated by units: OpenMarkup * AmountInUnitsDecimal / InitialUnits. Adjusts for partial closes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CommissionVersion` COMMENT 'Commission calculation version. Different values represent different versions/models of how commission is computed.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `ExitOrderType` COMMENT 'Exit order type for stop/limit-triggered closes. Values: 20=56%,NULL=44%,19=rare. NULL for customer/manual closes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenPositionReasonID` COMMENT 'Open mechanism/reason. Refs Dictionary.OpenPositionActionType. Values 0-18 per dictionary. 2000-series values (2020-2023) are ETL data quality artefacts, not year codes.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenTotalTaxes` COMMENT 'Total taxes at open (e.g., UK stamp duty). Default 0.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseTotalTaxes` COMMENT 'Total taxes at close. NULL for open positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `OpenTotalFees` COMMENT 'Total ticket fees at open — fixed $ or % of volume. More fees may be added later; full breakdown in History.Cost.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseTotalFees` COMMENT 'Total ticket fees at close — fixed $ or % of volume. More fees may accrue; full breakdown in History.Cost. NULL for open positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EstimateCloseFeeForCFD` COMMENT 'Estimated close fee for CFD positions. From Trade.OpenPositionEndOfDay.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EstimateCloseFeeOnOpenByUnits` COMMENT 'Estimated close fee at open, per unit.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `EstimateCloseFeeOnOpen` COMMENT 'Estimated close fee recorded at open.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Close_PnLInDollars` COMMENT 'Same as PnLInDollars but based on closing price instead of last (current) price.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Close_CalculationRate` COMMENT 'Instrument rate used to compute Close_PnLInDollars (closing-price-based PnL, vs last-price-based PnLInDollars).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Close_PriceType` COMMENT 'Closing price source for Close_PnLInDollars. 2=63.5%,1=11.8%,0=6.6%,3=0.05%,NULL=18%. Sources: official close, unofficial close, dealer injection, last internal price. Value-to-source mapping TBD.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CurrentCalculationRate` COMMENT 'Current calculation rate for open position PnL (end-of-day snapshot).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CurrentConversionRate` COMMENT 'Current conversion rate for open position PnL (end-of-day snapshot).';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `Close_ConversionRate` COMMENT 'Currency conversion rate for Close_PnLInDollars. Converts instrument currency to USD using closing price snapshot.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.compliance_stg.rnd_output_dwh_dim_position_lc ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';

-- main.dealing.rnd_output_dealing_bestexecution_dim_position (TABLE, 32 columns)
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `OrderType` COMMENT 'Order type at open. Refs Dictionary.OrderType. Common: NULL(66%),17(28%),0(4%),18/13(rare).';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `FullCommission` COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `Commission` COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `AmountInUnitsDecimal` COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `Amount` COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `isSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `InitForexRate` COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `EndForexRate` COMMENT 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `IsBuy` COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `InitExecutionID` COMMENT 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `EndExecutionID` COMMENT 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `ExitOrderID` COMMENT 'Exit order ID for stop/limit-triggered closes. NULL for market/direct closes.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `RequestCloseOccurred` COMMENT 'UTC timestamp when close was requested. Used for close latency measurement.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `RequestOpenOccurred` COMMENT 'UTC timestamp when open was requested. May differ from OpenOccurred if execution was delayed.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `HedgeServerID` COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `CloseOccurred` COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `OpenOccurred` COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `InitForexPriceRateId` COMMENT 'Price-rate snapshot record at open. Enables exact rate lookup for audit/recalculation.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `EndForexPriceRateId` COMMENT 'Price-rate snapshot at close.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `Openpositionreasonid` COMMENT 'Open mechanism/reason. Refs Dictionary.OpenPositionActionType. Values 0-18 per dictionary. 2000-series values (2020-2023) are ETL data quality artefacts, not year codes.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `Closepositionreasonid` COMMENT 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=Hierarchical,13=CopySL,14=ReturnToMarket,15=JoinDemoChallenge,17=ManualUnregister,19=Redeem,20=CloseAll,21=ManualLiquidation,23=Alignment,24=Delist,25=BSL,26=Expiry,27=OpAdjustment,28=Orphaned,29=TransferredOut.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `LastOpConversionRate` COMMENT 'Conversion rate from most recent overnight operation for non-USD instruments.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `OriginalPositionId` COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `EndExecutionID` COMMENT 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';
ALTER TABLE main.dealing.rnd_output_dealing_bestexecution_dim_position ALTER COLUMN `InitExecutionID` COMMENT 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';

-- main.data_rooms.vw_dim_position (VIEW, 106 columns)
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`PositionID` IS 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CID` IS 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CurrencyID` IS 'Account currency for amounts/commissions. References Dim_Currency. In practice always 1 (USD) in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`ProviderID` IS 'Legacy field, always 1. Originally identified the trading provider.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InstrumentID` IS 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`HedgeID` IS 'Reference to a specific hedge record in Trade.Hedge. Links position to the corresponding hedge order. NULL if no direct hedge record.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`HedgeServerID` IS 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`Leverage` IS 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`Amount` IS 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`AmountInUnitsDecimal` IS 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LotCountDecimal` IS 'Position size in standard lots. Updated on partial close. Used in overnight fee and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`UnitMargin` IS 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForexRate` IS 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`NetProfit` IS 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`SpreadedPipBid` IS 'Bid-side spread rate at open (instrument bid after spread mark-up). Used in PnL and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`SpreadedPipAsk` IS 'Ask-side spread rate at open (instrument ask after spread mark-up). Used in PnL and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsBuy` IS 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseOnEndOfWeek` IS 'Weekend close flag from Trade.PositionTreeInfo. Deprecated feature, typically 0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndOfWeekFee` IS 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`Commission` IS 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CommissionOnClose` IS 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenOccurred` IS 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseOccurred` IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`ParentPositionID` IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OrigParentPositionID` IS 'Original parent PositionID at copy time. Preserved even after tree restructuring. Sentinel 1 = independent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`MirrorID` IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsOpenOpen` IS 'OPEN_OPEN mechanism: 1=created by reinvesting unrealised profit (OpenActionType=3).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenDateID` IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseDateID` IS 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`RegulationIDOnOpen` IS 'Regulation at open. DWH-joined from BackOfficeCustomer. 0=None,1=CySEC,2=FCA,3=eToroUS,4=ASIC,5=BVI,6=FinCEN,7=FINRAONLY,8=MAS,9=FSA Seychelles,10=ASIC&GAML,11=FSRA,12=NYDFS+FINRA. Refs Dim_Regulation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`PlatformTypeID` IS '[UNVERIFIED] Platform type. Not populated — always NULL in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`PositionSegment` IS '[UNVERIFIED] Position segment. Not populated — always NULL in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`Volume` IS 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenInd` IS '[UNVERIFIED] Open indicator flag. Mostly NULL; values 0 and 1 observed rarely.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`SpreadedCommission` IS 'Spread commission in pips (integer). Used in hedge calculation and spread-group reporting.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForexRate` IS 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LastOpConversionRate` IS 'Conversion rate from most recent overnight operation for non-USD instruments.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LimitRate` IS 'Take-profit rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves favorably.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`StopRate` IS 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`ClosePositionReasonID` IS 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=Hierarchical,13=CopySL,14=ReturnToMarket,15=JoinDemoChallenge,17=ManualUnregister,19=Redeem,20=CloseAll,21=ManualLiquidation,23=Alignment,24=Delist,25=BSL,26=Expiry,27=OpAdjustment,28=Orphaned,29=TransferredOut.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`TreeID` IS 'Copy-trade tree root. Independent: TreeID=PositionID. Copy-trade: TreeID=leader PositionID. All positions sharing a TreeID share SL/TP settings.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`FullCommission` IS 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`FullCommissionOnClose` IS 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsComputeForHedge` IS 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitialAmountCents` IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`RedeemStatus` IS 'Crypto redemption status — tracks position to crypto-in-wallet loop: 0=N/A,1=Pending,6=PositionClosed(redeem),20=Terminated,21=FailedToCancel. Refs Dim_RedeemStatus.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`RedeemID` IS 'Crypto redemption transaction record reference. NULL when RedeemStatus=0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`ReopenForPositionID` IS 'For reopened positions: references the original closed PositionID this position replaces.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsReOpen` IS 'Reopen flag: 1=created by reopening a previously closed position (e.g., after corporate action). Default 0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CommissionOnCloseOrig` IS 'Original CommissionOnClose before reopen adjustment by SP_Dim_Position_ReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`FullCommissionOnCloseOrig` IS 'Original FullCommissionOnClose before reopen adjustment.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OriginalPositionID` IS 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsPartialCloseParent` IS 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsPartialCloseChild` IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitialUnits` IS 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsPartialCloseChildFromReOpen` IS 'Flag: 1=partial close child of a reopened position. Set by SP_Dim_Position_ReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsDiscounted` IS 'Discounted pricing from Trade.PositionTreeInfo: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsSettled` IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`VolumeOnClose` IS 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CommissionByUnits` IS 'eToro markup prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Adjusts for partial closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`FullCommissionByUnits` IS 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Adjusts for partial closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsCopyFundPosition` IS 'Flag: 1=belongs to CopyFund (tree root CID has AccountTypeID=9 OR MirrorTypeID=4 in Dim_Mirror). NULL=not copy fund.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LastOpPriceRateID` IS 'Price-rate record from most recent overnight operation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsAirDrop` IS 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForexPriceRateID` IS 'Price-rate snapshot record at open. Enables exact rate lookup for audit/recalculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForexPriceRateID` IS 'Price-rate snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForex_Ask` IS 'Ask price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForex_Bid` IS 'Bid price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForex_AskSpreaded` IS 'Ask with spread at open from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForex_BidSpreaded` IS 'Bid with spread at open from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitForex_USDConversionRate` IS 'USD conversion rate at open from forex price snapshot. Used for PnL conversion to USD.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForex_Ask` IS 'Ask price from forex price snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForex_Bid` IS 'Bid price from forex price snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForex_AskSpreaded` IS 'Ask with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForex_BidSpreaded` IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndForex_USDConversionRate` IS 'USD conversion rate at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitExecutionID` IS 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndExecutionID` IS 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitConversionRate` IS 'Conversion rate from instrument currency to account currency at open. Used in PnL currency conversion.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitConversionRateID` IS 'Conversion-rate snapshot record at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarketPriceRateID` IS 'Market price-rate record at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`InitHedgeType` IS 'Hedge model at open: CBH=Client-Based Hedging (~95%), HBC=Hedge Before Client (~5%). Determined from HBCExecutionLog.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`EndHedgeType` IS 'Hedge model at close: CBH or HBC. NULL for open positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OrderID` IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`ExitOrderID` IS 'Exit order ID for stop/limit-triggered closes. NULL for market/direct closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`IsSettledOnOpen` IS 'Settlement status at open time. May differ from IsSettled if converted after open. Use ISNULL(IsSettledOnOpen,IsSettled) for at-open segmentation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`StopRateOnOpen` IS 'Stop-loss rate at open time. May differ from current StopRate if modified after open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LimitRateOnOpen` IS 'Take-profit rate at open time. May differ from current LimitRate if modified after open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`LastOpPriceRate` IS 'Instrument price from most recent overnight operation. Starting rate for next overnight PnL calculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`SettlementTypeID` IS 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarketPriceRateID` IS 'Market price-rate record at open execution time.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarket_Ask` IS 'Market ask price at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarket_Bid` IS 'Market bid price at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarket_AskSpreaded` IS 'Market ask with spread at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarket_BidSpreaded` IS 'Market bid with spread at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarketCoversionRateBidSpreaded` IS 'Conversion rate (bid-spreaded) at open market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OpenMarketCoversionRateAskSpreaded` IS 'Conversion rate (ask-spreaded) at open market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarket_AskSpreaded` IS 'Market ask with spread at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarket_BidSpreaded` IS 'Market bid with spread at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarket_Ask` IS 'Market ask price at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarket_Bid` IS 'Market bid price at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarketCoversionRateBidSpreaded` IS 'Conversion rate (bid-spreaded) at close market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`CloseMarketCoversionRateAskSpreaded` IS 'Conversion rate (ask-spreaded) at close market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`RequestOpenOccurred` IS 'UTC timestamp when open was requested. May differ from OpenOccurred if execution was delayed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`RequestCloseOccurred` IS 'UTC timestamp when close was requested. Used for close latency measurement.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.`OrderType` IS 'Order type at open. Refs Dictionary.OrderType. Common: NULL(66%),17(28%),0(4%),18/13(rare).';

-- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason (TABLE, 1 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN `ClosePositionReasonID` COMMENT 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=Hierarchical,13=CopySL,14=ReturnToMarket,15=JoinDemoChallenge,17=ManualUnregister,19=Redeem,20=CloseAll,21=ManualLiquidation,23=Alignment,24=Delist,25=BSL,26=Expiry,27=OpAdjustment,28=Orphaned,29=TransferredOut.';

-- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog (TABLE, 5 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN `PositionID` COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN `CID` COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN `IsSettled` COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN `StopRate` COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN `LotCountDecimal` COMMENT 'Position size in standard lots. Updated on partial close. Used in overnight fee and hedge calculations.';
