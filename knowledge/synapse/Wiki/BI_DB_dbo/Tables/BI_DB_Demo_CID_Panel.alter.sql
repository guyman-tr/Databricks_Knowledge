-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Demo_CID_Panel
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Demo_CID_Panel > 4.55M-row per-CID demo account trading panel tracking each user''s first demo trade date, first action product type, first instrument, and number of positions opened within 14 days of demo activation - spanning registrations from September 2007 to January 2025 (4.43M distinct CIDs), refreshed daily via SP_Demo_CID_Panel with incremental INSERT for new CIDs and UPDATE for changed position counts (author: Eti, 2025-01-27 rewrite). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_dbo.External_Marketing_Acquisition_Demo via SP_Demo_CID_Panel | | **Refresh** | Daily (SB_Daily, Priority 0) - DELETE recent 3 months + INSERT new CIDs (WHERE NOT EXISTS) + UPDATE position counts | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX([Reg_YearMonth] ASC) | | **'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. One row per CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN Reg_YearMonth COMMENT 'Registration year-month in YYYY-MM format. CONVERT(VARCHAR(7), Registered, 126). Range: 2007-09 to 2025-01. NULL for some CIDs with missing registration data. Clustered index column. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FDT_YearMonth COMMENT 'First Demo Trade year-month in YYYY-MM format. CONVERT(VARCHAR(7), FirstDemoTrade, 126). NULL if the user never traded demo. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstDemoTrade COMMENT 'Date of the user''s first demo account trade. From External_Marketing_Acquisition_Demo.FirstDemoTrade. NULL if the user registered but never opened a demo position. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstAction COMMENT 'Product type of the user''s first demo trade. Classified from InstrumentID/InstrumentTypeID/IsBuy/Leverage: ''Real Stocks/ETFs'', ''Fx/Comm/Ind'', ''CFD Stocks/ETFs'', ''Crypto'', ''Copy'', ''Other''. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstInstrument COMMENT 'InstrumentID of the user''s first demo trade. FK to DWH_dbo.Dim_Instrument.InstrumentID for instrument details. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN IsTradedDemo COMMENT 'Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Currently all rows are 1 (only traded users are present). (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN OpenPositions14days COMMENT 'Number of demo positions opened within 14 days of the first demo trade. From External_Marketing_Acquisition_Demo.Pos14Days. Updated daily if count changes. Higher = more engaged. (Tier 2 - SP_Demo_CID_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT or UPDATE time. (Tier 5 - Propagation)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN Reg_YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FDT_YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstDemoTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN FirstInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN IsTradedDemo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN OpenPositions14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:31:57 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 20/20 succeeded
-- ====================
