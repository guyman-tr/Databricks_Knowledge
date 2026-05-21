-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ActionType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_ActionType is the master lookup for all customer financial and platform action types recorded in Fact_CustomerAction. It defines 45 distinct action types across 29 business categories covering position trading (open/close), deposits, withdrawals, bonuses, chargebacks, mirror/copy-trade operations, engagement events, and administrative actions. This table originates from the legacy DWH SQL Server (migrated via DWH_Migration.Dim_ActionType) and is NOT sourced from the production etoro.Dictionary.ActionType - which is a separate, smaller table covering only session and registration events. The DWH version was created specifically to classify the rich set of financial customer actions tracked in the Fact_CustomerAction fact table. New action types are added infrequently (45 rows since initial 2013 migration; 2 new types added in 2024). The table is effectively stable - changes require a coordinated insert across the legacy origin and DWH. The `UpdateDate` and `InsertDate` columns carry production t...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ActionTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying a specific customer action type. Integer codes 0-45 (gap at 33) where 0=N/A sentinel. Used as FK in Fact_CustomerAction, Fact_FirstCustomerAction, Fact_History_Cost, and numerous BI_DB/EXW/eMoney reporting SPs. (Tier 3 - no upstream wiki, grounded in DDL + live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Name COMMENT 'Human-readable name of the action type. Values include ManualPositionOpen, CopyPositionClose, Deposit, Cashout, Bonus, Chargeback, LoggedIn, Customer Registration, etc. (45 distinct values). (Tier 3 - no upstream wiki, grounded in DDL + live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN UpdateDate COMMENT 'Timestamp of the last update to this action type row. Most rows show 2013-07-17 (original seed); row 0 shows 2014-02-24. (Tier 3 - no upstream wiki, grounded in DDL + live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN InsertDate COMMENT 'Timestamp when this action type row was first inserted. Same pattern as UpdateDate - bulk seeded 2013-07-17, sentinel added 2014-02-24. (Tier 3 - no upstream wiki, grounded in DDL + live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Category COMMENT 'Category grouping for the action type. 30 distinct values: PositionOpen, PositionClose, Deposit, Cashout, Bonus, Chargeback, UserEngagement, WallEngagement, DetachPosition, etc. Multiple ActionTypeIDs can share one Category. (Tier 3 - no upstream wiki, grounded in DDL + live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN CategoryID COMMENT 'Integer code grouping multiple action types into business categories (values 0 - 28). Used in SP_Validation_Cycle_Gap_DL_To_Synapse MINO filter: CategoryID IN (2,4,6,7,8,12,17,20,21,19) - note that 23 (Reverse cashout) is commented out in the current SP code.';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Category SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN CategoryID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:36:08 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
