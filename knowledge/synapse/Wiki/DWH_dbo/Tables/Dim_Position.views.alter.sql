-- =============================================================================
-- Databricks View Column Comment Propagation: Dim_Position
-- Generated: 2026-03-08 | dwh-semantic-doc pipeline
-- 
-- Propagates column descriptions from Dim_Position to downstream UC views.
-- Uses COMMENT ON COLUMN syntax (required for views; ALTER TABLE does not work).
--
-- Source: main.dwh.dim_position
-- Synapse: DWH_dbo.Dim_Position
--
-- Target views (9):
--   main.data_rooms.vw_dim_position                     (110/111 cols)
--   main.api_delta.v_dwh_dim_position                   (29/29 cols)
--   main.delta_api.v_dwh_dim_position                   (28/28 cols)
--   main.bi_db_stg.trading_positions_regular_vw         (4/52 cols)
--   main.bi_output_stg.v_semantic_copyfund_positions    (6/9 cols)
--   main.etoro_kpi.positions_for_compliance_v           (32/53 cols)
--   main.bi_output.positionsvolumeandattributes_lc4_source (2/15 cols)
--   main.bi_output.vg_positions_open_closed_iban_tp     (14/47 cols)
--   main.bi_output.vg_positionsvolumeandattributes_lc4_source (2/15 cols)
--
-- Total: 227 COMMENT ON COLUMN statements
-- =============================================================================

-- ---- main.data_rooms.vw_dim_position (110/111 columns matched) ----
COMMENT ON COLUMN main.data_rooms.vw_dim_position.PositionID IS 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CID IS 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CurrencyID IS 'Account currency for amounts/commissions. References Dim_Currency. In practice always 1 (USD) in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.ProviderID IS 'Legacy field, always 1. Originally identified the trading provider.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InstrumentID IS 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.HedgeID IS 'Reference to a specific hedge record in Trade.Hedge. Links position to the corresponding hedge order. NULL if no direct hedge record.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.HedgeServerID IS 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.Leverage IS 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 -> REAL settlement. Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.Amount IS 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.AmountInUnitsDecimal IS 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LotCountDecimal IS 'Position size in standard lots. Updated on partial close. Used in overnight fee and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.UnitMargin IS 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForexRate IS 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) x Units x ConversionRate.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.NetProfit IS 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.SpreadedPipBid IS 'Bid-side spread rate at open (instrument bid after spread mark-up). Used in PnL and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.SpreadedPipAsk IS 'Ask-side spread rate at open (instrument ask after spread mark-up). Used in PnL and hedge calculations.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsBuy IS 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseOnEndOfWeek IS 'Weekend close flag from Trade.PositionTreeInfo. Deprecated feature, typically 0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndOfWeekFee IS 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.Commission IS 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CommissionOnClose IS 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenOccurred IS 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseOccurred IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.ParentPositionID IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OrigParentPositionID IS 'Original parent PositionID at copy time. Preserved even after tree restructuring. Sentinel 1 = independent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.MirrorID IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsOpenOpen IS 'OPEN_OPEN mechanism: 1=created by reinvesting unrealised profit (OpenActionType=3).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenDateID IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.RegulationIDOnOpen IS 'Regulation at open. DWH-joined from BackOfficeCustomer. 0=None,1=CySEC,2=FCA,4=ASIC,5=BVI,9=FSA Seychelles,10=ASIC&GAML,11=FSRA. Refs Dim_Regulation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.PlatformTypeID IS '[UNVERIFIED] Platform type. Not populated — always NULL in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.PositionSegment IS '[UNVERIFIED] Position segment. Not populated — always NULL in this table.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.Volume IS 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.UpdateDate IS 'UTC timestamp of last DWH ETL update for this row.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenInd IS '[UNVERIFIED] Open indicator flag. Mostly NULL; values 0 and 1 observed rarely.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.SpreadedCommission IS 'Spread commission in pips (integer). Used in hedge calculation and spread-group reporting.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForexRate IS 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LastOpConversionRate IS 'Conversion rate from most recent overnight operation for non-USD instruments.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LimitRate IS 'Take-profit rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves favorably.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.StopRate IS 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.ClosePositionReasonID IS 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=HierarchicalClose,13=CopySL,17=ManualUnregister,19=Redeem,23=Alignment,24=Delist,26=Expiry.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.TreeID IS 'Copy-trade tree root. Independent: TreeID=PositionID. Copy-trade: TreeID=leader PositionID. All positions sharing a TreeID share SL/TP settings.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.FullCommission IS 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.FullCommissionOnClose IS 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsComputeForHedge IS 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitialAmountCents IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.RedeemStatus IS 'Crypto redemption status: 0=N/A,1=Pending,6=PositionClosed(redeem),20=Terminated,21=FailedToCancel. Refs Dim_RedeemStatus.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.RedeemID IS 'Crypto redemption transaction record reference. NULL when RedeemStatus=0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.ReopenForPositionID IS 'For reopened positions: references the original closed PositionID this position replaces.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsReOpen IS 'Reopen flag: 1=created by reopening a previously closed position (e.g., after corporate action). Default 0.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CommissionOnCloseOrig IS 'Original CommissionOnClose before reopen adjustment by SP_Dim_Position_ReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.FullCommissionOnCloseOrig IS 'Original FullCommissionOnClose before reopen adjustment.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OriginalPositionID IS 'For partial-close children: parent PositionID. When OriginalPositionID != PositionID, this is a partial-close child.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsPartialCloseParent IS 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsPartialCloseChild IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitialUnits IS 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsPartialCloseChildFromReOpen IS 'Flag: 1=partial close child of a reopened position. Set by SP_Dim_Position_ReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsDiscounted IS 'Discounted pricing from Trade.PositionTreeInfo: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsSettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.VolumeOnClose IS 'Close volume = rounded(Units * Price * ConversionRate) at close. Pro-rated for partial close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CommissionByUnits IS 'eToro markup prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Adjusts for partial closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.FullCommissionByUnits IS 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Adjusts for partial closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsCopyFundPosition IS 'Flag: 1=belongs to CopyFund (tree root CID has AccountTypeID=9 OR MirrorTypeID=4 in Dim_Mirror). NULL=not copy fund.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LastOpPriceRateID IS 'Price-rate record from most recent overnight operation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsAirDrop IS 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations). NULL=not airdrop.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForexPriceRateID IS 'Price-rate snapshot record at open. Enables exact rate lookup for audit/recalculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForexPriceRateID IS 'Price-rate snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForex_Ask IS 'Ask price from forex price snapshot at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForex_Bid IS 'Bid price from forex price snapshot at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForex_AskSpreaded IS 'Ask with spread at open from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForex_BidSpreaded IS 'Bid with spread at open from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitForex_USDConversionRate IS 'USD conversion rate at open from forex price snapshot. Used for PnL conversion to USD.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForex_Ask IS 'Ask price from forex price snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForex_Bid IS 'Bid price from forex price snapshot at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForex_AskSpreaded IS 'Ask with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForex_BidSpreaded IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndForex_USDConversionRate IS 'USD conversion rate at close from forex price snapshot.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitExecutionID IS 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndExecutionID IS 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitConversionRate IS 'Conversion rate from instrument currency to account currency at open. Used in PnL currency conversion.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitConversionRateID IS 'Conversion-rate snapshot record at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarketPriceRateID IS 'Market price-rate record at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.InitHedgeType IS 'Hedge model at open: CBH=Client-Based Hedging (~95%), HBC=Hedge Before Client (~5%). Determined from HBCExecutionLog.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.EndHedgeType IS 'Hedge model at close: CBH or HBC. NULL for open positions.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OrderID IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.ExitOrderID IS 'Exit order ID for stop/limit-triggered closes. NULL for market/direct closes.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.IsSettledOnOpen IS 'Settlement status at open time. May differ from IsSettled if converted after open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.StopRateOnOpen IS 'Stop-loss rate at open time. May differ from current StopRate if modified after open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LimitRateOnOpen IS 'Take-profit rate at open time. May differ from current LimitRate if modified after open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.LastOpPriceRate IS 'Instrument price from most recent overnight operation. Starting rate for next overnight PnL calculation.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.SettlementTypeID IS 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarketPriceRateID IS 'Market price-rate record at open execution time.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.etr_y IS 'Partition column: year (string). Added by Databricks gold-layer ETL for partition pruning.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.etr_ym IS 'Partition column: year-month (string). Added by Databricks gold-layer ETL for partition pruning.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.etr_ymd IS 'Partition column: year-month-day (string). Added by Databricks gold-layer ETL for partition pruning.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarket_Ask IS 'Market ask price at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarket_Bid IS 'Market bid price at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarket_AskSpreaded IS 'Market ask with spread at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarket_BidSpreaded IS 'Market bid with spread at open.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarketCoversionRateBidSpreaded IS 'Conversion rate (bid-spreaded) at open market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OpenMarketCoversionRateAskSpreaded IS 'Conversion rate (ask-spreaded) at open market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarket_AskSpreaded IS 'Market ask with spread at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarket_BidSpreaded IS 'Market bid with spread at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarket_Ask IS 'Market ask price at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarket_Bid IS 'Market bid price at close.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarketCoversionRateBidSpreaded IS 'Conversion rate (bid-spreaded) at close market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.CloseMarketCoversionRateAskSpreaded IS 'Conversion rate (ask-spreaded) at close market snapshot. Note: column name typo "Coversion".';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.RequestOpenOccurred IS 'UTC timestamp when open was requested. May differ from OpenOccurred if execution was delayed.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.RequestCloseOccurred IS 'UTC timestamp when close was requested. Used for close latency measurement.';
COMMENT ON COLUMN main.data_rooms.vw_dim_position.OrderType IS 'Order type at open. Refs Dictionary.OrderType. Common: NULL(66%),17(28%),0(4%),18/13(rare).';

-- ---- main.api_delta.v_dwh_dim_position (29/29 columns matched) ----
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.PositionID IS 'Unique position identifier. System-generated. HASH distribution key for this table.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.CID IS 'Customer ID — the account that owns this position. References the customer entity.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.InstrumentID IS 'Financial instrument being traded. References Dim_Instrument.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.IsBuy IS 'Trade direction: 1=Buy/Long, 0=Sell/Short.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.MirrorID IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.ParentPositionID IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.Amount IS 'Customer invested amount in USD. Updated proportionally on partial close.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.Leverage IS 'Leverage multiplier (e.g., 1=no leverage, 5=5x). Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.OrderID IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.NetProfit IS 'Closed PnL in USD. Zero while open.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.IsSettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.InitialUnits IS 'Original unit count at open, preserved before partial-close adjustments.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.AmountInUnitsDecimal IS 'Position size in units of the underlying instrument. Updated on partial close.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.OpenOccurred IS 'UTC timestamp when position was opened.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.InitForexRate IS 'Instrument exchange rate at open. Core PnL input.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.UnitMargin IS 'Margin requirement per unit at open, in account currency.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.StopRate IS 'Stop-loss rate. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.IsPartialCloseParent IS 'Flag: 1=has had partial-close children created.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.IsPartialCloseChild IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.InitialAmountCents IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.EndOfWeekFee IS 'Cumulative end-of-week holding fee in USD.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.EndForexRate IS 'Instrument exchange rate at close. NULL for open positions.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.EndForex_BidSpreaded IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.CloseOccurred IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.OriginalPositionID IS 'For partial-close children: parent PositionID.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.etr_y IS 'Partition column: year (string). For partition pruning.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.etr_ym IS 'Partition column: year-month (string). For partition pruning.';
COMMENT ON COLUMN main.api_delta.v_dwh_dim_position.etr_ymd IS 'Partition column: year-month-day (string). For partition pruning.';

-- ---- main.delta_api.v_dwh_dim_position (28/28 columns matched) ----
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.PositionID IS 'Unique position identifier. System-generated. HASH distribution key for this table.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.CID IS 'Customer ID — the account that owns this position. References the customer entity.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.InstrumentID IS 'Financial instrument being traded. References Dim_Instrument.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.IsBuy IS 'Trade direction: 1=Buy/Long, 0=Sell/Short.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.MirrorID IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.ParentPositionID IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.Amount IS 'Customer invested amount in USD. Updated proportionally on partial close.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.Leverage IS 'Leverage multiplier (e.g., 1=no leverage, 5=5x). Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.OrderID IS 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.NetProfit IS 'Closed PnL in USD. Zero while open.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.IsSettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.InitialUnits IS 'Original unit count at open, preserved before partial-close adjustments.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.AmountInUnitsDecimal IS 'Position size in units of the underlying instrument. Updated on partial close.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.OpenOccurred IS 'UTC timestamp when position was opened.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.InitForexRate IS 'Instrument exchange rate at open. Core PnL input.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.UnitMargin IS 'Margin requirement per unit at open, in account currency.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.StopRate IS 'Stop-loss rate. Price at which position auto-closes if market moves against.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.IsPartialCloseParent IS 'Flag: 1=has had partial-close children created.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.IsPartialCloseChild IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.InitialAmountCents IS 'Original amount in cents at open. NEVER updated. Divide by 100 for USD.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.EndOfWeekFee IS 'Cumulative end-of-week holding fee in USD.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.EndForexRate IS 'Instrument exchange rate at close. NULL for open positions.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.EndForex_BidSpreaded IS 'Bid with spread at close from forex price snapshot.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.CloseOccurred IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.etr_y IS 'Partition column: year (string). For partition pruning.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.etr_ym IS 'Partition column: year-month (string). For partition pruning.';
COMMENT ON COLUMN main.delta_api.v_dwh_dim_position.etr_ymd IS 'Partition column: year-month-day (string). For partition pruning.';

-- ---- main.bi_db_stg.trading_positions_regular_vw (4/52 columns matched) ----
COMMENT ON COLUMN main.bi_db_stg.trading_positions_regular_vw.leverage IS 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.bi_db_stg.trading_positions_regular_vw.cid IS 'Customer ID — the account that owns this position. References the customer entity.';
COMMENT ON COLUMN main.bi_db_stg.trading_positions_regular_vw.amount IS 'Customer invested amount in USD. Updated proportionally on partial close.';
COMMENT ON COLUMN main.bi_db_stg.trading_positions_regular_vw.commission IS 'eToro markup (additional spread on top of market spread) at open in USD.';

-- ---- main.bi_output_stg.v_semantic_copyfund_positions (6/9 columns matched) ----
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.PositionID IS 'Unique position identifier. System-generated. HASH distribution key for source table.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.CID IS 'Customer ID — the account that owns this position.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.MirrorID IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.OpenDateID IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_copyfund_positions.IsPartialCloseChild IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';

-- ---- main.etoro_kpi.positions_for_compliance_v (32/53 columns matched) ----
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.positionid IS 'Unique position identifier. System-generated. HASH distribution key for source table.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.cid IS 'Customer ID — the account that owns this position.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.instrumentid IS 'Financial instrument being traded. References Dim_Instrument.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.amount IS 'Customer invested amount in USD. Updated proportionally on partial close.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.hedgeserverid IS 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.leverage IS 'Leverage multiplier (e.g., 1=no leverage, 5=5x). Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.isbuy IS 'Trade direction: 1=Buy/Long, 0=Sell/Short.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.openoccurred IS 'UTC timestamp when position was opened.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.closeoccurred IS 'UTC timestamp when close was written. 1900-01-01 for open positions.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.parentpositionid IS 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.origparentpositionid IS 'Original parent PositionID at copy time. Preserved even after tree restructuring.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.mirrorid IS 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.isopenopen IS 'OPEN_OPEN mechanism: 1=created by reinvesting unrealised profit (OpenActionType=3).';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.opendateid IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.closedateid IS 'Close date as YYYYMMDD int. 0=still open. Key filter for open vs closed.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.volume IS 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.regulationidonopen IS 'Regulation at open. 0=None,1=CySEC,2=FCA,4=ASIC,5=BVI,9=FSA Seychelles,10=ASIC&GAML,11=FSRA.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.treeid IS 'Copy-trade tree root. Independent: TreeID=PositionID. Copy-trade: TreeID=leader PositionID.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.initialunits IS 'Original unit count at open, preserved before partial-close adjustments.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.isdiscounted IS 'Discounted pricing: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.issettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.issettledonopen IS 'Settlement status at open time. May differ from IsSettled if converted after open.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.volumeonclose IS 'Close volume = rounded(Units * Price * ConversionRate) at close. Pro-rated for partial close.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.isairdrop IS 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations). NULL=not airdrop.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.inithedgetype IS 'Hedge model at open: CBH=Client-Based Hedging (~95%), HBC=Hedge Before Client (~5%).';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.endhedgetype IS 'Hedge model at close: CBH or HBC. NULL for open positions.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.orderid IS 'Initial order that triggered this open. NULL for direct opens.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.closepositionreasonid IS 'Close reason. 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=HierarchicalClose,13=CopySL,17=ManualUnregister,19=Redeem.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.ispartialclosechild IS 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.ispartialcloseparent IS 'Flag: 1=has had partial-close children created.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.netprofit IS 'Closed PnL in USD. Zero while open.';
COMMENT ON COLUMN main.etoro_kpi.positions_for_compliance_v.pnlindollars IS 'Current unrealized PnL in dollars for open positions (end-of-day snapshot).';

-- ---- main.bi_output.positionsvolumeandattributes_lc4_source (2/15 columns matched) ----
COMMENT ON COLUMN main.bi_output.positionsvolumeandattributes_lc4_source.IsSettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD.';
COMMENT ON COLUMN main.bi_output.positionsvolumeandattributes_lc4_source.CID IS 'Customer ID — the account that owns this position.';

-- ---- main.bi_output.vg_positions_open_closed_iban_tp (14/47 columns matched) ----
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.PositionID IS 'Unique position identifier. System-generated. HASH distribution key for source table.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.CID IS 'Customer ID — the account that owns this position.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.InstrumentID IS 'Financial instrument being traded. References Dim_Instrument.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.OpenDateID IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.PlatformTypeID IS '[UNVERIFIED] Platform type. Not populated — always NULL in source table.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.Amount IS 'Customer invested amount in USD. Updated proportionally on partial close.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.Volume IS 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.NetProfit IS 'Closed PnL in USD. Zero while open.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.Commission IS 'eToro markup (additional spread on top of market spread) at open in USD.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.Leverage IS 'Leverage multiplier (e.g., 1=no leverage, 5=5x). Gross notional = Amount x Leverage.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.RegulationIDOnOpen IS 'Regulation at open. 0=None,1=CySEC,2=FCA,4=ASIC,5=BVI,9=FSA Seychelles,10=ASIC&GAML,11=FSRA.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.RealCID IS 'Real-account Customer ID. HASH distribution key. Always include in WHERE/JOIN for optimal performance.';
COMMENT ON COLUMN main.bi_output.vg_positions_open_closed_iban_tp.CampaignID IS 'Marketing campaign identifier. 0 if not campaign-related. References Dim_Campaign.CampaignID.';

-- ---- main.bi_output.vg_positionsvolumeandattributes_lc4_source (2/15 columns matched) ----
COMMENT ON COLUMN main.bi_output.vg_positionsvolumeandattributes_lc4_source.IsSettled IS 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD.';
COMMENT ON COLUMN main.bi_output.vg_positionsvolumeandattributes_lc4_source.CID IS 'Customer ID — the account that owns this position.';
