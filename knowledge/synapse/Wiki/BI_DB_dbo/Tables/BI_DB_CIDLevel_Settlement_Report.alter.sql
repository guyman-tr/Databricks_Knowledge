-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN InstrumentID COMMENT 'Instrument identifier from BI_DB_PositionPnL, resolved via Dim_Instrument. Filtered to InstrumentTypeID IN (5,6) = Real stocks and ETFs only. (Tier 2 - SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN InstrumentName COMMENT 'Instrument name from Dim_Instrument.Name. Format includes exchange suffix: "OLED/USD", "GRG/GBX", "TTE.PA/EUR". (Tier 2 - SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN SettlementDate COMMENT 'Settlement date as YYYYMMDD integer. Clustered index leading column. Equals the SP @dt parameter date. (Tier 2 - SP_Finance_Non_US_Settlement_Report, @dateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN EffectiveEODPrice COMMENT 'Effective end-of-day price per unit in USD. Computed: CAST(Total_Open_$ / Units AS DECIMAL(18,4)). This is a portfolio-derived price, not a market quote - it reflects the actual mark-to-market value divided by units held. (Tier 2 - SP_Finance_Non_US_Settlement_Report, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN CID COMMENT 'Customer ID from BI_DB_PositionPnL. Only settled, non-US, real-stock customers with IsCreditReportValidCB = 1. (Tier 2 - SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.CID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN Regulation COMMENT 'Regulation name from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. Non-US only (excludes eToro US, FinCEN, FINRA). Values: "CySEC", "FCA", "ASIC", "ASIC & GAML", "FSA", etc. Clustered index component. (Tier 2 - SP_Finance_Non_US_Settlement_Report, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN SettledInUnits COMMENT 'Total units of the instrument held by this CID on this date. SUM of BI_DB_PositionPnL.AmountInUnitsDecimal aggregated at CID × Instrument level. (Tier 2 - SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 - SP_Finance_Non_US_Settlement_Report, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN IsGermanBaFin COMMENT 'German BaFin regulatory flag. 1 if CID exists in V_GermanBaFin for this date. Added Nov 2020. (Tier 2 - SP_Finance_Non_US_Settlement_Report, V_GermanBaFin)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN SettlementDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN EffectiveEODPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN SettledInUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
