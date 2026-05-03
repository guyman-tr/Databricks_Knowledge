-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.IndexDividends
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.IndexDividends.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_indexdividends
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_indexdividends (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends SET TBLPROPERTIES (
    'comment' = 'Stores scheduled dividend events for index/stock instruments, tracking ex-date, payment date, tax rates, and lifecycle status for both CFD and REAL position types. Source: etoro.Trade.IndexDividends on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.IndexDividends.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_indexdividends SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'IndexDividends',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN DividendID COMMENT 'Primary key. Surrogate ID for the dividend event. NOT FOR REPLICATION. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. The instrument (stock/index) for which this dividend is declared. See Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN DividendDate COMMENT 'Legacy field. CHECK (DividendDate>=getutcdate()) when set - NOCHECK in place. May predate ExDate/PaymentDate. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN BuyPaymentInDollars COMMENT 'Legacy. Pre-calculated buy-side payment in USD. Populated by Trade.InsertDividend; newer flow uses GetRateInDollarsForDividends. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN SellPaymentInDollars COMMENT 'Legacy. Pre-calculated sell-side payment in USD. Same pattern as BuyPaymentInDollars. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN Status COMMENT 'Lifecycle: 0=Pending, 4=Correction Pending, 1=In Progress, 2=Completed. See Section 2.1. Default 0. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN Occurred COMMENT 'UTC timestamp when the dividend row was created. Audit field. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN ProcName COMMENT 'Stored procedure that created the row. Default from @@procid. Audit. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN UserName COMMENT 'SQL login of the user who created the row. Default suser_sname(). Audit. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN PositionType COMMENT 'FK to Dictionary.PositionType. 0=CFD, 1=REAL, 255=ILLEGAL. Dividends split by position ownership model. See Dictionary.PositionType. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN TaxCode COMMENT 'Tax code/label for withholding. Passed from InsertIndexDividend; may map to jurisdiction. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN EventType COMMENT 'Type of corporate action (e.g., dividend, special dividend). Passed from InsertIndexDividend. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN ExDate COMMENT 'Ex-dividend date. Holder must own position on this date to receive dividend. CHECK: PaymentDate >= ExDate. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN PaymentDate COMMENT 'Date when dividend is paid. Trade.GetCIDsForIndexDividends uses PaymentDate < today to advance Status 0 -> 1. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN DividendValueInCurrency COMMENT 'Dividend amount per share/unit in DividendCurrencyID. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN DividendCurrencyID COMMENT 'FK to Dictionary.Currency. Currency of DividendValueInCurrency (USD, EUR, GBX, NOK, etc.). See Dictionary.Currency. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN BuyTax COMMENT 'Tax rate for buy-side (long) positions. CHECK: 0 to 1. Fraction, e.g., 0.15 = 15%. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN SellTax COMMENT 'Tax rate for sell-side (short) positions. CHECK: 0 to 1. Same format as BuyTax. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN PositionsSnapshotStarted COMMENT 'When the position snapshot for this dividend started. Set by Trade.DividendsSetSnapshotIsReady flow. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN PositionsSnapshotCompleted COMMENT 'When the position snapshot completed. Part of dividend processing pipeline. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN PositionsSnapshotMarketClose COMMENT 'Market close timestamp used for snapshot. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). Current DB login for audit. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN SysStartTime COMMENT 'System-versioning start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN SysEndTime COMMENT 'System-versioning end. GENERATED ALWAYS AS ROW END. History in History.IndexDividends. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN HostName COMMENT 'Computed: host_name(). Server where row was created. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN NegativeDividendAllowed COMMENT '1 = negative (special) dividend allowed. Passed from InsertIndexDividend. NULL = default no. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN CorrectionDividendID COMMENT 'FK to self. DividendID of the dividend being corrected. When set, Status defaults to 4. Trade.ValidateCorrectionDividendId validates. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
ALTER TABLE main.trading.bronze_etoro_trade_indexdividends ALTER COLUMN RetakeDividendID COMMENT 'FK to self. Parent dividend when this row is part of a retake batch. Multiple rows can share same RetakeDividendID. (Tier 1 - upstream wiki, etoro.Trade.IndexDividends)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
