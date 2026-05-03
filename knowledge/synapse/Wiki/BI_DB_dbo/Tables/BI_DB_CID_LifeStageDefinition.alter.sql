-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CID_LifeStageDefinition
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CID_LifeStageDefinition > SCD Type 2 customer lifecycle stage table. Assigns every valid eToro customer one of 19 lifecycle segments (LSD - Life Stage Definition) and tracks transitions over time. Each customer has one current open row (ToDateID=99991231) representing their present stage, plus historical rows for past stages. 122M total rows, 46.3M distinct customers, data from 2022-01-01. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_SnapshotCustomer (population), Dim_Position, V_Liabilities, Fact_SnapshotEquity, BI_DB_CIDFirstDates, Fact_CustomerAction | | **Refresh** | Daily - SCD Type 2 UPDATE + INSERT (SP_CID_LifeStageDefinition, SB_Daily, Priority 0) | | | | | **Synapse Distribution** | HASH (RealCID) | | **Synapse Index** | CLUSTERED INDEX (RealCID ASC, DateID ASC) | | | | | *'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN Date COMMENT 'Report date string (YYYY-MM-DD format) when the LSD was assigned. Stored as varchar(10) - not a date type. Cast when comparing: CAST(Date AS DATE). (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN DateID COMMENT 'Date integer (YYYYMMDD) when the LSD stage transition occurred. Combined with ToDateID, defines the validity window. CLUSTERED INDEX key (with RealCID). (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN RealCID COMMENT 'Customer identifier. FK into DWH_dbo.Dim_Customer. HASH distribution key. One open row per RealCID at ToDateID=99991231. (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN FirstDepositDate COMMENT 'Customer''s first ever deposit date (from Dim_Customer.FirstDepositDate). NULL if never deposited. Used for "New" stage detection (deposit within last 14 days). Stored per-row for convenience - static attribute, same across all rows for a given RealCID. (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN PlayerLevelID COMMENT 'Customer''s Club tier at the time of the LSD transition (from Fact_SnapshotCustomer). Same non-sequential ID mapping as Dim_PlayerLevel: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. Used to determine "Club" vs. non-Club variants of Active Open / Holder stages. (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN LSD COMMENT 'Life Stage Definition - the customer''s lifecycle segment. 19 possible values: ''Lead'', ''New Funded'', ''New Depositor Only'', ''Win Back Deposit'', ''Win Back Active Open'', ''Active Open'', ''Active Open Club'', ''Active Open 30-90 days'', ''Active Open 30-90 days Club'', ''Holder'', ''Holder Club'', ''Active LogIn'', ''Churn 14-30 days'', ''Churn 31-60 days'', ''Churn over 60 days'', ''Dump Lead'', ''Dump Churn'', ''No Activity - Funded'', ''No Activity - Not Funded''. Assigned by priority CASE (WinBack > Lead > New > Dump > Churn > Active Open > Holder > Active LogIn > No Activity). (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN ToDate COMMENT 'Date when this LSD row ended (closed). ''9999-12-31'' = current/open row (customer still in this stage). DATEADD(DAY,-1,@date) when the stage changed. Query pattern: WHERE ToDateID=99991231 for current state. (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN ToDateID COMMENT 'Integer version of ToDate (YYYYMMDD). 99991231 = current/open row. Use this for point-in-time filtering: WHERE @yyyymmdd BETWEEN DateID AND ToDateID. (T2 - SP_CID_LifeStageDefinition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last written (GETDATE() on INSERT or UPDATE). Useful for diagnosing pipeline run timing. (T2 - SP_CID_LifeStageDefinition)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN LSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN ToDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:27:29 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 20/20 succeeded
-- ====================
