-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown SET TBLPROPERTIES (
    'comment' = 'This table captures every trading "click" - a position open or close event - aggregated daily at the customer × instrument × dimension level. Each row represents one unique combination of date, customer, instrument, direction, open/close type, and various segmentation flags. It answers: "How many positions were opened/closed today, by whom, on what instrument, with what volume and commission?" The data is entirely ETL-derived from DWH_dbo dimension and fact tables. Primary sources are `DWH_dbo.Dim_Position` (position lifecycle), `DWH_dbo.Dim_Instrument` (instrument metadata), `DWH_dbo.Fact_SnapshotCustomer` (customer attributes at the snapshot date), and `DWH_dbo.Dim_Customer` (static customer data). Ticket fees come from `DWH_dbo.Fact_CustomerAction` (ActionTypeID=35, IsFeeDividend=4). IBAN trade flags from `BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN` / `BI_DB_Positions_Closed_To_IBAN`. eMoney account flags from `eMoney_dbo.eMoney_Dim_Account`. Loaded daily by `SP_Clicks_OpenClose_Breakdown(@Date)` using ...'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown SET TAGS (
    'domain' = 'trading',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED COLUMNSTORE INDEX + NCI on Date',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 4 stars COMMENT '`(Tier 1 - ...)`';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 3 stars COMMENT '`(Tier 2 - ...)`';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 2 stars COMMENT '`(Tier 3 - ...)`';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Date COMMENT 'Report date. Set to `@Date` SP parameter (typically yesterday). One day''s worth of clicks per load. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN DateID COMMENT 'Date as YYYYMMDD integer. `CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)`. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN SellCurrency COMMENT 'Text abbreviation of the instrument''s sell-side (denomination) currency. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Club COMMENT 'Player tier name from Dim_PlayerLevel (e.g., Bronze, Silver, Gold, Platinum). Customer''s loyalty/tier level at the snapshot date. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN CID COMMENT 'Customer ID. References Customer.Customer. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsBuy COMMENT 'Trade direction. 1=Long (buy), 0=Short (sell). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HeldOnReportDate COMMENT 'Whether position was still open at end of report date. `CASE WHEN CloseDateID > @DateID OR CloseDateID = 0 THEN 1 ELSE 0 END`. Renamed from IsOpen (SR-325240). Always 0 for close clicks. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HedgeServerID COMMENT 'Liquidity provider server ID. Identifies which hedge server executed the position. Key servers: 2=JP Morgan legacy, 101=Goldman Sachs, 81=Real Stocks LP. HedgeServerID=35 allows invalid customer inclusion. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentDisplayName COMMENT 'User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than InstrumentName (e.g., ''Apple Inc.'' vs ''Apple''). (Tier 2 - SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentName COMMENT 'Internal instrument name from Trade.Instrument. Renamed from Dim_Instrument.Name. For forex: pair notation (e.g., EUR/USD). For stocks: company name. (Tier 3 - live data, etoro.Trade.GetInstrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentTypeID COMMENT 'Asset class: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentType COMMENT 'Text label for InstrumentTypeID. DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsCopy COMMENT 'Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. 1=position opened via CopyTrader, 0=direct trade. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsCFD COMMENT 'CFD vs Real asset flag. `CASE WHEN IsSettled = 1 THEN 0 ELSE 1 END`. 1=CFD (contract for difference), 0=Real stock/crypto ownership. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Symbol COMMENT 'Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. (Tier 3 - live data, etoro.Trade.GetInstrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Leverage COMMENT 'Position leverage multiplier. 1=unleveraged (real stocks), 2-30=leveraged (CFDs). From Dim_Position.Leverage. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Exchange COMMENT 'Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 - live data, etoro_Trade_InstrumentMetaData)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN CountryID COMMENT 'Customer''s registered country at snapshot date. FK to Dim_Country. From Fact_SnapshotCustomer via Dim_Country. (Tier 1 - Dictionary.Country upstream wiki)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Country COMMENT 'Country name from Dim_Country.Name. (Tier 1 - Dictionary.Country upstream wiki)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Region COMMENT 'Marketing region manual override. From Dim_Country.MarketingRegionManualName. Examples: Latam, UK, German, CEE, SEA. (Tier 3 - Ext_Dim_Country live data)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN RegulationID COMMENT 'Customer''s regulatory jurisdiction at snapshot date. FK to Dim_Regulation. 1=CySEC, 2=FCA, etc. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Regulation COMMENT 'Regulation name from Dim_Regulation.Name. Examples: CySEC, FCA, ASIC. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsIslamic COMMENT 'Islamic (swap-free) account flag. `CASE WHEN WeekendFeePrecentage = 0 THEN 1 ELSE 0 END`. Source: Dim_Customer.WeekendFeePrecentage. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Size of Tickets COMMENT 'Volume bucket label. 16 buckets from ''1$-10$'' to ''Over2000000$''. Open clicks bucketed on VolumeOpened, close clicks on VolumeClosed. ''0'' = zero volume. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN OpenOrClose COMMENT 'Row type: `''Open Click''` or `''Close Click''`. Literal string set by SP. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN OpenOrCloseID COMMENT 'Row type numeric: 1=Open Click, 0=Close Click. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Click COMMENT 'Trade event count. `SUM(NumberofPositionsOpened)` for opens (1 per non-partial-close position opened on @Date), `SUM(NumberofPositionsClosed)` for closes. Aggregated in GROUP BY. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Volume COMMENT 'USD trade volume. For opens: `SUM(CAST(VolumeOpened AS BIGINT))` where VolumeOpened = SUM(Dim_Position.Volume) over OriginalPositionID partition. For closes: `SUM(VolumeClosed)` where VolumeClosed = VolumeOnClose. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Units COMMENT 'Instrument units traded. For opens: `SUM(InitialUnits)` WHERE OpenDateID=@DateID. For closes: `SUM(AmountInUnitsDecimal)` WHERE CloseDateID=@DateID. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN FullCommission COMMENT 'Commission amount. Opens: `SUM(FullCommissionOnOpenInit)` - accumulated FullCommissionByUnits including partial close children. Closes: `SUM(FullCommissionOnClose)` for same-day opens, `SUM(FullCommissionOnClose - FullCommissionByUnits)` for older positions. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InitialAmountUSDOnOpen COMMENT 'Initial investment in USD for open clicks only. `SUM(InitialAmountCents/100) WHERE NumberofPositionsOpened=1`. Always 0 for close clicks. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to `GETDATE()` on each daily reload. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsPI COMMENT 'Popular Investor flag. `CASE WHEN GuruStatusID >= 2 THEN 1 ELSE 0 END`. Source: Fact_SnapshotCustomer.GuruStatusID. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsTicketFee COMMENT 'Has ticket fee flag. `CASE WHEN Fact_CustomerAction.Amount IS NOT NULL THEN 1 ELSE 0 END`. Ticket fee = ActionTypeID=35 AND IsFeeDividend=4. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN TicketFee COMMENT 'Ticket fee amount. `SUM(Amount)` from Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=4 AND DateID=@DateID. Joined on PositionID+OpenOrCloseID. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsAirDrop COMMENT 'AirDrop position flag. `CASE WHEN Dim_Position.IsAirDrop = 1 THEN 1 ELSE 0 END`. AirDrop opens are treated separately: zero ticket fees, IsFTDClick always 0. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsFuture COMMENT 'Futures instrument flag. Direct from Dim_Instrument.IsFuture. Added SR-308870 (2025-04-07). (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HaseMoneyAccount COMMENT 'Has eMoney account flag (note: intentional typo in column name). `CASE WHEN eMoney_Dim_Account.CID IS NOT NULL THEN 1 ELSE 0 END` WHERE GCID_Unique_Count=1 AND IsValidETM=1. Added SR-346605 (2025-12-07). (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsIBANClick COMMENT 'IBAN-originated trade flag. Opens: `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END`. Closes: same with BI_DB_Positions_Closed_To_IBAN. Added SR-346605 (2025-12-07). (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsFTDClick COMMENT 'First Trade after Deposit flag. `CASE WHEN dp.PositionID = dc.PositionID THEN 1 ELSE 0 END`. dc.PositionID = first non-airdrop position opened after customer''s first deposit date (ROW_NUMBER=1). Always 0 for close clicks and AirDrop opens. Added SR-346605. (Tier 2 - SP_Clicks_OpenClose_Breakdown)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsLowTouch COMMENT 'Low-touch instrument flag. From Dim_Instrument.OperationMode. Indicates instruments with simplified execution flow. Added SR-346605 (2025-12-07). (Tier 2 - SP_Clicks_OpenClose_Breakdown)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 4 stars SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 3 stars SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN 2 stars SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HeldOnReportDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsIslamic SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Size of Tickets SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN OpenOrClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN OpenOrCloseID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Click SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN FullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN InitialAmountUSDOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsPI SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsTicketFee SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN TicketFee SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN HaseMoneyAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsIBANClick SET TAGS ('pii' = 'direct');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsFTDClick SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN IsLowTouch SET TAGS ('pii' = 'none');
