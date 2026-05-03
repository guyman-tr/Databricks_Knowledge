-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_PositionPnL_UK_Custody
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_PositionPnL_UK_Custody > 20.5M-row anonymized daily snapshot of CySEC-regulated open stock/ETF custody positions - the "UK book" view with MD5-hashed PositionID. Structurally identical to `BI_DB_PositionPnL_EU_Custody` (SHA1 hash) - both represent the same underlying positions with different hash algorithms for EU-vs-UK reconciliation. Sourced from `BI_DB_PositionPnL` via `SP_BI_DB_PositionPnL_EU_Custody` (TRUNCATE+INSERT, single-day snapshot). Refreshed daily. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` -> `DWH_dbo.Dim_Position` / `Fact_CurrencyPriceWithSplit` (via SP_PositionPnL) | | **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Guy Manova 2023-12-21, Inessa Kontorovich 2025-03-08) | | **Refresh** | Daily, TRUNCATE+INSERT (single-day snapshot replac'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN CID COMMENT 'Anonymized customer identifier. Hardcoded to 999999999 for all rows - original CID from BI_DB_PositionPnL is stripped for privacy. (Tier 2 - SP_BI_DB_PositionPnL_EU_Custody)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN PositionID_Hashed COMMENT 'MD5 hash of the original PositionID from BI_DB_PositionPnL. 32-character uppercase hex string. Use UK_Custody_Resolver to map back to real PositionID. (Tier 2 - SP_BI_DB_PositionPnL_EU_Custody)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN InstrumentID COMMENT 'Traded instrument. Only stocks/ETFs (InstrumentTypeID 5,6) appear. FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN MirrorID COMMENT 'Copy-trading mirror link when applicable. 0 = non-mirror (direct) position. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Commission COMMENT 'Opening commission in dollars. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN InitForexRate COMMENT 'Open rate; split-adjusted in SP when position spans a split. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SpreadedPipBid COMMENT 'Bid with spread at open. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SpreadedPipAsk COMMENT 'Ask with spread at open. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN PositionPnL COMMENT 'Unrealized P&L in USD; from PnLInDollars (replaces legacy formula). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Price COMMENT 'Per-unit price-move expression x USD conversion factor from #Pre_UnrealizedPnL (bid/ask vs InitForexRate and instrument FX chain). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN HedgeServerID COMMENT 'Hedge server for the position. 16 distinct values. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Amount COMMENT 'Position amount in USD; rewound via Dim_PositionChangeLog when SL/partial-close edits after @dt. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN AmountInUnitsDecimal COMMENT 'Size in instrument units; split-adjusted and rewound from partial-close log when applicable. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN LimitRate COMMENT 'Take-profit rate. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN StopRate COMMENT 'Stop-loss rate; rewound to PreviousStopRate when edited after @dt. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsBuy COMMENT 'Long (1) vs short (0). Always 1 (True) in this table - real stock custody is BUY-only. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Occurred COMMENT 'Position open timestamp (OpenOccurred). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Date COMMENT 'Snapshot calendar date @dt. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN DateID COMMENT 'Snapshot date as YYYYMMDD; clustered index key. Single value per load (TRUNCATE+INSERT). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN UpdateDate COMMENT 'Row load timestamp at insert (GETDATE()). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. Always 1 in this table (pre-filtered). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN NOP COMMENT 'Net open position in USD from units x pair rate x direction x conversion. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN DailyPnL COMMENT 'Day-over-day change: PositionPnL minus prior day PositionPnL. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Leverage COMMENT 'Position leverage. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN RateBid COMMENT 'EOD bid from latest Fact_CurrencyPriceWithSplit row before @ReportDate, split-adjusted. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN RateAsk COMMENT 'EOD ask from same price row, split-adjusted. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN USD_CR COMMENT 'End-of-day conversion rate used with PnL context; from Dim_Position CurrentConversionRate. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SettlementTypeID COMMENT 'Modern settlement type from Dim_Position. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsCreditReportValidCB COMMENT '1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. Passthrough from Fact_SnapshotCustomer. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsValidCustomer COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, LabelID, CountryID. Passthrough from Fact_SnapshotCustomer. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN PositionID_Hashed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN InitForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SpreadedPipBid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SpreadedPipAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Price SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN AmountInUnitsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN LimitRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN StopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN DailyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN RateBid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN RateAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN USD_CR SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:12:37 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 62/62 succeeded
-- ====================
