-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Settlement_Prices
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN InstrumentID COMMENT 'Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. Identifies the futures/derivatives contract. Composite CI key -- always include in JOINs and WHERE filters for efficient Synapse queries. 200 distinct instruments in production (InstrumentIDs 200000+ range). (Tier 2 - SP_Fact_Settlement_Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementDateID COMMENT 'Settlement date as YYYYMMDD integer (e.g., 20260310). DWH-derived: computed in SP as CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,Date),0), 112)). Composite CI key -- use for date-range filters. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_Settlement_Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementDate COMMENT 'Settlement date as a DATE type. Source column `Date` from EndOfDay_EOD_SettlementPrices, renamed to SettlementDate in the SP. Use for display or date arithmetic. (Tier 2 - SP_Fact_Settlement_Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementPrice COMMENT 'Official end-of-day settlement price for the futures/derivatives instrument on this date, as published by the exchange or clearing house. Source column `Price` renamed in SP. Used by SP_Fact_Position_Futures_Snapshot for mark-to-market P&L valuation. High-precision decimal(38,18). (Tier 2 - SP_Fact_Settlement_Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN UpdateDate COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price date -- use SettlementDate for the business date. (Tier 2 - SP_Fact_Settlement_Prices)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN SettlementPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_settlement_prices ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

