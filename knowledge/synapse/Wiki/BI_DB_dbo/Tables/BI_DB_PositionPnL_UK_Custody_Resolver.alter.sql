-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver > 20.5M-row de-anonymization resolver mapping real CID and PositionID to both the EU (SHA1) and UK (MD5) hashed PositionID variants used in the custody reconciliation tables. Single-day TRUNCATE+INSERT snapshot refreshed daily via `SP_BI_DB_PositionPnL_EU_Custody`. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` (via #posFCA: stocks/ETFs, settled, CySEC) | | **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Inessa Kontorovich 2025-03-08 addition) | | **Refresh** | Daily, TRUNCATE+INSERT (single-day snapshot) | | **Synapse Distribution** | HASH (PositionID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver` | | **UC Format** | delta'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN CID COMMENT 'Real customer identifier (NOT anonymized). From BI_DB_PositionPnL via #posFCA. Use for de-anonymization of EU/UK custody books. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID COMMENT 'Real position identifier (NOT hashed). Distribution key. From BI_DB_PositionPnL via #posFCA. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID_HashedEU COMMENT 'SHA1 hash of PositionID. 40-character uppercase hex string. Matches `EU_Custody.PositionID_Hashed`. (Tier 2 - SP_BI_DB_PositionPnL_EU_Custody)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID_HashedUK COMMENT 'MD5 hash of PositionID. 32-character uppercase hex string. Matches `UK_Custody.PositionID_Hashed`. (Tier 2 - SP_BI_DB_PositionPnL_EU_Custody)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN InstrumentID COMMENT 'Traded instrument. Only stocks/ETFs (InstrumentTypeID 5,6). FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN Occurred COMMENT 'Position open timestamp (OpenOccurred). Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN Date COMMENT 'Snapshot calendar date @dt. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN DateID COMMENT 'Snapshot date as YYYYMMDD. Passthrough from BI_DB_PositionPnL. (Tier 1 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN UpdateDate COMMENT 'Row load timestamp. GETDATE() at insert time. (Tier 3 - SP_BI_DB_PositionPnL_EU_Custody, GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID_HashedEU SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN PositionID_HashedUK SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:12:44 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 20/20 succeeded
-- ====================
