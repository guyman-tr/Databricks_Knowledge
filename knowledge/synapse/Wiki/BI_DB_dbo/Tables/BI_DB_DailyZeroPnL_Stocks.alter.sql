-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks > Daily stock/ETF hedge-accounting snapshot tracking Zero PnL decomposition per instrument, hedge server, and regulatory jurisdiction. 197.6M rows covering 2019-01-01 to 2024-02-09 (frozen - table was deprecated 2024-02-15 when the live feed was redirected to Dealing_dbo.Dealing_DailyZeroPnL_Stocks). Originally populated by Dealing_dbo.SP_DailyZeroPnL_Stocks from DWH_dbo.Dim_Position, BI_DB_dbo.BI_DB_PositionPnL, and DWH_dbo.Fact_SnapshotCustomer. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Unknown (dormant - SP migrated to Dealing_dbo.Dealing_DailyZeroPnL_Stocks on 2024-02-15) | | **Refresh** | Frozen. Was daily via Dealing_dbo.SP_DailyZeroPnL_Stocks @dd. Last data: 2024-02-09. | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX on [Date] ASC '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Date COMMENT 'ETL reporting date parameter passed to SP_DailyZeroPnL_Stocks. Determines which open/closed positions are included in the day''s calculation. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Industry COMMENT 'Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentType COMMENT 'ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. Here only ''Stocks'' and ''ETF'' appear (InstrumentTypeID IN (5,6) filter in SP). (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Financial instrument being traded. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN StockIndex COMMENT 'Stock exchange / index grouping from BI_DB_IndexesMapping_Static (e.g., ''US'', ''GER30''). NULL when InstrumentID has no mapping. (Tier 3 - BI_DB_IndexesMapping_Static, no upstream wiki located)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN IsManual COMMENT '1 = direct (manual) trade (MirrorID=0), 0 = copy-trade position (MirrorID > 0). Computed from Dim_Position.MirrorID. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Leverage COMMENT 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN IsCFD COMMENT '1 = CFD (IsSettled=0), 0 = real asset (IsSettled=1). Inverted from Dim_Position.IsSettled. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: ISNULL wraps NULL to ''Unknown''. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN MifID COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN RealizedCommission COMMENT 'Daily sum of commissions on closed positions per group: SUM(FullCommissionOnClose - FullCommissionByUnits) for partially-closed; SUM(FullCommissionOnClose) for fully-closed same-day positions. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN RealizedZero COMMENT 'Daily realized Zero PnL: SUM of CalculatedZero for closed positions (NetProfit adjusted for prior unrealized PnL and commissions). (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN ChangeInUnrealizedZero COMMENT 'Daily change in unrealized Zero PnL: SUM of DailyPnL (from BI_DB_PositionPnL) for open positions, plus opening-day commission adjustments. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN TotalZero COMMENT 'Total Zero PnL for the day: SUM(CalculatedZero) across all indicators = RealizedZero + ChangeInUnrealizedZero. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN NOP COMMENT 'Net open position in USD from units × pair rate × USD conversion. From BI_DB_PositionPnL.NOP (always positive). (Tier 2 - SP_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN OpenPositions COMMENT 'Signed net open position: SUM(NOP * direction) where direction = IsBuy=1 -> +1, IsBuy=0 -> -1. Positive = net long, negative = net short. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN NOP_Units COMMENT 'Sum of instrument units in open positions for the group on the report date (AmountInUnitsDecimal). (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN VolumeOnOpen COMMENT 'Sum of USD-equivalent volume for positions opened on the report date: SUM(CASE WHEN OpenDateID=RepDate THEN Volume ELSE 0 END). (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN VolumeOnClose COMMENT 'Sum of USD-equivalent volume for positions closed on the report date: SUM(CASE WHEN CloseDateID=RepDate THEN VolumeOnClose ELSE 0 END). (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN OpenPositionValue COMMENT 'Sum of invested amount plus unrealized PnL for open positions: SUM(BI_DB_PositionPnL.Amount + BI_DB_PositionPnL.PositionPnL). (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. GETDATE() at SP_DailyZeroPnL_Stocks execution time. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentName COMMENT 'Computed: TDCUR_BUY.Abbreviation + ''/'' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Units COMMENT 'Total instrument units that opened or closed on the report date per group: SUM(OpenUnits + CloseUnits) from #Units temp table. (Tier 2 - SP_DailyZeroPnL_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Currency COMMENT 'Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 - Dictionary.Currency)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Industry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN StockIndex SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN IsManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN IsCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN MifID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN RealizedCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN RealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN ChangeInUnrealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN TotalZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN OpenPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN NOP_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN VolumeOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN VolumeOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN OpenPositionValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks ALTER COLUMN Currency SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:36:42 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 54/54 succeeded
-- ====================
