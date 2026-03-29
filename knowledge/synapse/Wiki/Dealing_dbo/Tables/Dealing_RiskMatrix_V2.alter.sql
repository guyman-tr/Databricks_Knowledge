-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_RiskMatrix_V2
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 SET TBLPROPERTIES (
    'comment' = 'NOP (Net Open Position) stress-test matrix for Real Stocks and ETFs, capturing how the hedge book exposure would shift under 26 price movement scenarios — from +1% to +900% and -1% to -100%. Each row represents a specific slice of the NOP book (by instrument × buy/sell × leverage × regulation × region) with a set of simulated NOP values at each price shock level. The table appears to have been a **one-time experimental snapshot** from June 2024 — no writer SP exists in the SSDT repository and no OpsDB scheduling entry exists. The HEAP storage (rather than CLUSTERED INDEX) is consistent with a temporary/ad-hoc write. Purpose: stress-testing the real stocks hedge book — understanding how LP hedge requirements change under extreme market scenarios.'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN PositionsTime COMMENT 'Snapshot timestamp (2024-06-02 08:01:49 for all rows)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN HedgeServerID COMMENT 'LP/hedge server identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentID COMMENT 'Instrument identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentName COMMENT 'Instrument name (denormalized)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentType COMMENT 'Asset class';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsBuy COMMENT '1=Long, 0=Short — client position direction';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Leverage COMMENT 'Leverage tier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Region COMMENT 'Geographic region';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Bid COMMENT 'Bid price at snapshot time';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Ask COMMENT 'Ask price at snapshot time';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN ConversionRate COMMENT 'FX rate to USD';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP COMMENT 'Current net open position in units';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP+1%` … `UnitsNOP+900% COMMENT 'Simulated NOP value if price increases by X% (15 tiers: 1,2,3,4,5,10,15,20,25,30,35,40,50,100,900)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP-1%` … `UnitsNOP-100% COMMENT 'Simulated NOP value if price decreases by X% (11 tiers: 1,2,3,4,5,10,15,20,25,50,100)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UpdateDate COMMENT 'ETL timestamp (2024-06-02 08:02:49)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN PositionsTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP+1%` … `UnitsNOP+900% SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP-1%` … `UnitsNOP-100% SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
