-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Position
-- Generated: 2026-03-02 | Updated: 2026-03-08 | 14-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.dim_position
-- Resolved via: information_schema (validated 2026-03-08)
-- Synapse Source: DWH_dbo.Dim_Position
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.dim_position SET TBLPROPERTIES (
    'comment' = 'Central trading-position dimension storing every open and historically-closed position as an end-of-day snapshot. Each row is one trade held by a customer on a financial instrument. Source: Trade.PositionTbl + Trade.PositionTreeInfo. Refreshed daily at midnight. HASH(PositionID). Key patterns: CloseDateID=0 means open; filter ISNULL(IsPartialCloseChild,0)=0 to exclude partial-close children; InitialAmountCents/100 for USD amount.'
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.dim_position SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'source_server' = 'sql_dp_prod_we',
    'refresh' = 'daily',
    'distribution' = 'HASH(PositionID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '14-phase'
);

ALTER TABLE main.dwh.dim_position ALTER COLUMN PositionID COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CID COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CurrencyID COMMENT 'Account currency for amounts/commissions. References Dim_Currency. In practice always 1 (USD) in this table.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ProviderID COMMENT 'Legacy field, always 1. Originally identified the trading provider.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InstrumentID COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN HedgeID COMMENT 'Reference to a specific hedge record in Trade.Hedge. Links position to the corresponding hedge order. NULL if no direct hedge record.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN HedgeServerID COMMENT 'Hedge server routing/executing hedges for this position. References Trade.HedgeServer.HedgeServerID.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Leverage COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Amount COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN AmountInUnitsDecimal COMMENT 'Position size in units of the underlying instrument (shares, crypto units, forex lots). Updated on partial close. Used in PnL and hedge exposure.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LotCountDecimal COMMENT 'Position size in standard lots. Updated on partial close. Used in overnight fee and hedge calculations.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN UnitMargin COMMENT 'Margin requirement per unit at open, in account currency. Used for margin calcs, risk checks, regulatory reporting.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForexRate COMMENT 'Instrument exchange rate at open. Core PnL input: (CloseRate - InitForexRate) × Units × ConversionRate.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN NetProfit COMMENT 'Closed PnL in USD. Zero while open. Set at close: ROUND(@NetProfit / 100, 2).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN SpreadedPipBid COMMENT 'Bid-side spread rate at open (instrument bid after spread mark-up). Used in PnL and hedge calculations.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN SpreadedPipAsk COMMENT 'Ask-side spread rate at open (instrument ask after spread mark-up). Used in PnL and hedge calculations.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsBuy COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseOnEndOfWeek COMMENT 'Weekend close flag from Trade.PositionTreeInfo. Deprecated feature, typically 0.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndOfWeekFee COMMENT 'Cumulative end-of-week holding fee in USD. Updated weekly. Reduced on partial close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Commission COMMENT 'eToro markup (additional spread on top of market spread) at open in USD. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CommissionOnClose COMMENT 'eToro markup (additional spread) at close. May be adjusted by SP_Dim_Position_ReOpen for reopened positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenOccurred COMMENT 'UTC timestamp when position was opened. Maps to Occurred in production Trade.PositionTbl.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseOccurred COMMENT 'UTC timestamp when close was written. 1900-01-01 for open positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ParentPositionID COMMENT 'Copy-trade: direct parent PositionID. Sentinel 1 = independent/no parent.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OrigParentPositionID COMMENT 'Original parent PositionID at copy time. Preserved even after tree restructuring. Sentinel 1 = independent.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN MirrorID COMMENT 'Copy-trade relationship: 0=manually opened, >0=auto-opened via CopyTrader (references Trade.Mirror.MirrorID).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsOpenOpen COMMENT 'OPEN_OPEN mechanism: 1=created by reinvesting unrealised profit (OpenActionType=3).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenDateID COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseDateID COMMENT 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN RegulationIDOnOpen COMMENT 'Regulation at open. DWH-joined from BackOfficeCustomer. 0=None,1=CySEC,2=FCA,4=ASIC,5=BVI,9=FSA Seychelles,10=ASIC&GAML,11=FSRA. Refs Dim_Regulation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN PlatformTypeID COMMENT '[UNVERIFIED] Platform type. Not populated — always NULL in this table.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN PositionSegment COMMENT '[UNVERIFIED] Position segment. Not populated — always NULL in this table.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Volume COMMENT 'Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN UpdateDate COMMENT 'UTC timestamp of last DWH ETL update for this row.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenInd COMMENT '[UNVERIFIED] Open indicator flag. Mostly NULL; values 0 and 1 observed rarely.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN SpreadedCommission COMMENT 'Spread commission in pips (integer). Used in hedge calculation and spread-group reporting.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForexRate COMMENT 'Instrument exchange rate at close. NULL for open positions. Used in NetProfit calculation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LastOpConversionRate COMMENT 'Conversion rate from most recent overnight operation for non-USD instruments.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LimitRate COMMENT 'Take-profit rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves favorably.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN StopRate COMMENT 'Stop-loss rate from Trade.PositionTreeInfo. Price at which position auto-closes if market moves against.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ClosePositionReasonID COMMENT 'Close reason. Refs Dim_ClosePositionReason: 0=Customer,1=StopLoss,5=TakeProfit,7=Rollover,8=BackOffice,9=HierarchicalClose,13=CopySL,17=ManualUnregister,19=Redeem,23=Alignment,24=Delist,26=Expiry.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN TreeID COMMENT 'Copy-trade tree root. Independent: TreeID=PositionID. Copy-trade: TreeID=leader PositionID. All positions sharing a TreeID share SL/TP settings.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN FullCommission COMMENT 'Full spread at open = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN FullCommissionOnClose COMMENT 'Full spread at close = market spread + eToro markup. May be adjusted for reopened positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsComputeForHedge COMMENT 'Hedge participation: 1=included in hedge exposure (default), 0=excluded (PlayerLevelID=4 customers).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitialAmountCents COMMENT 'Original amount in cents at open. NEVER updated. Divide by 100 for USD: InitialAmountCents/100. Denominator for partial-close proportional calcs.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN RedeemStatus COMMENT 'Crypto redemption status — tracks position to crypto-in-wallet loop: 0=N/A,1=Pending,6=PositionClosed(redeem),20=Terminated,21=FailedToCancel. Refs Dim_RedeemStatus.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN RedeemID COMMENT 'Crypto redemption transaction record reference. NULL when RedeemStatus=0.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ReopenForPositionID COMMENT 'For reopened positions: references the original closed PositionID this position replaces.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsReOpen COMMENT 'Reopen flag: 1=created by reopening a previously closed position (e.g., after corporate action). Default 0.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CommissionOnCloseOrig COMMENT 'Original CommissionOnClose before reopen adjustment by SP_Dim_Position_ReOpen.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN FullCommissionOnCloseOrig COMMENT 'Original FullCommissionOnClose before reopen adjustment.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OriginalPositionID COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID ≠ PositionID → partial-close child.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsPartialCloseParent COMMENT 'Flag: 1=has had partial-close children created. Set by SP_Dim_Position_IsPartialCloseParent.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsPartialCloseChild COMMENT 'Flag: 1=created by partial close. ALWAYS filter ISNULL(IsPartialCloseChild,0)=0 when counting positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitialUnits COMMENT 'Original unit count at open, preserved before partial-close adjustments. AmountInUnitsDecimal changes; InitialUnits does not.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsPartialCloseChildFromReOpen COMMENT 'Flag: 1=partial close child of a reopened position. Set by SP_Dim_Position_ReOpen.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsDiscounted COMMENT 'Discounted pricing from Trade.PositionTreeInfo: 0=standard Bid/Ask, 1=BidDiscounted/AskDiscounted (VIP/partner).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsSettled COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN VolumeOnClose COMMENT 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CommissionByUnits COMMENT 'eToro markup prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Adjusts for partial closes.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN FullCommissionByUnits COMMENT 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Adjusts for partial closes.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsCopyFundPosition COMMENT 'Flag: 1=belongs to CopyFund (tree root CID has AccountTypeID=9 OR MirrorTypeID=4 in Dim_Mirror). NULL=not copy fund.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LastOpPriceRateID COMMENT 'Price-rate record from most recent overnight operation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsAirDrop COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForexPriceRateID COMMENT 'Price-rate snapshot record at open. Enables exact rate lookup for audit/recalculation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForexPriceRateID COMMENT 'Price-rate snapshot at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForex_Ask COMMENT 'Ask price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForex_Bid COMMENT 'Bid price from forex price snapshot at open. Joined from PriceLog via InitForexPriceRateID.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForex_AskSpreaded COMMENT 'Ask with spread at open from forex price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForex_BidSpreaded COMMENT 'Bid with spread at open from forex price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitForex_USDConversionRate COMMENT 'USD conversion rate at open from forex price snapshot. Used for PnL conversion to USD.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForex_Ask COMMENT 'Ask price from forex price snapshot at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForex_Bid COMMENT 'Bid price from forex price snapshot at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForex_AskSpreaded COMMENT 'Ask with spread at close from forex price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForex_BidSpreaded COMMENT 'Bid with spread at close from forex price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndForex_USDConversionRate COMMENT 'USD conversion rate at close from forex price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitExecutionID COMMENT 'Execution record ID from exchange/LP at open. Used for reconciliation and to determine InitHedgeType (HBC vs CBH).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndExecutionID COMMENT 'Execution record ID from exchange/LP at close. Used to determine EndHedgeType.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitConversionRate COMMENT 'Conversion rate from instrument currency to account currency at open. Used in PnL currency conversion.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitConversionRateID COMMENT 'Conversion-rate snapshot record at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarketPriceRateID COMMENT 'Market price-rate record at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN InitHedgeType COMMENT 'Hedge model at open: CBH=Client-Based Hedging (~95%), HBC=Hedge Before Client (~5%). Determined from HBCExecutionLog.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EndHedgeType COMMENT 'Hedge model at close: CBH or HBC. NULL for open positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OrderID COMMENT 'Initial order that triggered this open (for order-driven opens). NULL for direct opens.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ExitOrderID COMMENT 'Exit order ID for stop/limit-triggered closes. NULL for market/direct closes.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsSettledOnOpen COMMENT 'Settlement status at open time. May differ from IsSettled if converted after open. Use ISNULL(IsSettledOnOpen,IsSettled) for at-open segmentation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN StopRateOnOpen COMMENT 'Stop-loss rate at open time. May differ from current StopRate if modified after open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LimitRateOnOpen COMMENT 'Take-profit rate at open time. May differ from current LimitRate if modified after open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN LastOpPriceRate COMMENT 'Instrument price from most recent overnight operation. Starting rate for next overnight PnL calculation.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN SettlementTypeID COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarketPriceRateID COMMENT 'Market price-rate record at open execution time.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarket_Ask COMMENT 'Market ask price at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarket_Bid COMMENT 'Market bid price at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarket_AskSpreaded COMMENT 'Market ask with spread at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarket_BidSpreaded COMMENT 'Market bid with spread at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarketCoversionRateBidSpreaded COMMENT 'Conversion rate (bid-spreaded) at open market snapshot. Note: column name typo "Coversion".';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarketCoversionRateAskSpreaded COMMENT 'Conversion rate (ask-spreaded) at open market snapshot. Note: column name typo "Coversion".';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarket_AskSpreaded COMMENT 'Market ask with spread at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarket_BidSpreaded COMMENT 'Market bid with spread at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarket_Ask COMMENT 'Market ask price at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarket_Bid COMMENT 'Market bid price at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarketCoversionRateBidSpreaded COMMENT 'Conversion rate (bid-spreaded) at close market snapshot. Note: column name typo "Coversion".';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarketCoversionRateAskSpreaded COMMENT 'Conversion rate (ask-spreaded) at close market snapshot. Note: column name typo "Coversion".';

ALTER TABLE main.dwh.dim_position ALTER COLUMN RequestOpenOccurred COMMENT 'UTC timestamp when open was requested. May differ from OpenOccurred if execution was delayed.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN RequestCloseOccurred COMMENT 'UTC timestamp when close was requested. Used for close latency measurement.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OrderType COMMENT 'Order type at open. Refs Dictionary.OrderType. Common: NULL(66%),17(28%),0(4%),18/13(rare).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN PnLVersion COMMENT 'PnL formula version: 0=CFD_FORMULA, 1=REAL_FORMULA. NULL=legacy. Determines Trade.FnCalculatePnL code path.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN PnLInDollars COMMENT 'Current unrealized PnL in dollars for open positions (end-of-day snapshot). From Trade.OpenPositionEndOfDay.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarketSpread COMMENT 'Market spread (variable spread) at open = Ask - Bid. The market-side spread before eToro markup is added.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarketSpread COMMENT 'Market spread (variable spread) at close = Ask - Bid.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarkupOnOpen COMMENT 'eToro close-side markup pre-computed at open time. Locks in the close markup rate at entry.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarkup COMMENT 'eToro markup (additional spread) at open in USD. Same concept as Commission in spread terms.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseMarkup COMMENT 'eToro markup (additional spread) at close.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN DLTOpen COMMENT 'DLT broker flag at open: 1=opened on DLT platform (German crypto broker for trade execution), 0/NULL=not DLT.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN DLTClose COMMENT 'DLT broker flag at close: 1=closed on DLT platform (German crypto broker), 0/NULL=not DLT.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenMarkupByUnits COMMENT 'eToro open markup prorated by units: OpenMarkup * AmountInUnitsDecimal / InitialUnits. Adjusts for partial closes.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CommissionVersion COMMENT 'Commission calculation version. Different values represent different versions/models of how commission is computed.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN ExitOrderType COMMENT 'Exit order type for stop/limit-triggered closes. Values: NULL(89%),20(11%),19(rare). NULL for direct closes.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenPositionReasonID COMMENT 'Open mechanism/reason. Refs Dictionary.OpenPositionActionType. Common: 2020-2023(year codes),1(regular),0(default),-1(undefined),3(hierarchical).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenTotalTaxes COMMENT 'Total taxes at open (e.g., UK stamp duty). Default 0.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseTotalTaxes COMMENT 'Total taxes at close. NULL for open positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN OpenTotalFees COMMENT 'Total ticket fees at open — fixed $ or % of volume. More fees may be added later; full breakdown in History.Cost.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CloseTotalFees COMMENT 'Total ticket fees at close — fixed $ or % of volume. More fees may accrue; full breakdown in History.Cost. NULL for open positions.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EstimateCloseFeeForCFD COMMENT 'Estimated close fee for CFD positions. From Trade.OpenPositionEndOfDay.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EstimateCloseFeeOnOpenByUnits COMMENT 'Estimated close fee at open, per unit.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN EstimateCloseFeeOnOpen COMMENT 'Estimated close fee recorded at open.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Close_PnLInDollars COMMENT 'Same as PnLInDollars but based on closing price instead of last (current) price.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Close_CalculationRate COMMENT 'Instrument rate used to compute Close_PnLInDollars (closing-price-based PnL, vs last-price-based PnLInDollars).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Close_ConversionRate COMMENT 'Currency conversion rate for Close_PnLInDollars. Converts instrument currency to USD using closing price snapshot.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN Close_PriceType COMMENT 'Closing price source for Close_PnLInDollars: official close, unofficial close, dealer injection, or last internal price. Value mapping TBD.';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CurrentCalculationRate COMMENT 'Current calculation rate for open position PnL (end-of-day snapshot).';

ALTER TABLE main.dwh.dim_position ALTER COLUMN CurrentConversionRate COMMENT 'Current conversion rate for open position PnL (end-of-day snapshot).';
