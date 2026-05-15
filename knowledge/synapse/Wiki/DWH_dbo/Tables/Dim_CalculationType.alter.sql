-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CalculationType
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN CalculationTypeId COMMENT 'Primary key identifying the calculation method. 1=FixPerUnit, 2=PipsPerUnit, 3=FixPerTrade, 4=PercentOfTrade, 5=PercentOfMarketDataMarkup, 6=PercentOfFees, 7=Override, 8=FixPerLot. Renamed from `Id` in production Dictionary.CalculationType. (Tier 3 - name-inferred, live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN CalculationType COMMENT 'Human-readable name for the calculation method. 8 distinct values (FixPerUnit through FixPerLot). Self-descriptive code-style names used in HistoryCosts cost computation. (Tier 3 - name-inferred, live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN FixPerUnit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN PipsPerUnit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN PercentOfTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN PercentOfMarketDataMarkup SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN PercentOfFees SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN Override SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN FixPerLot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN CalculationTypeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN CalculationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_calculationtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

