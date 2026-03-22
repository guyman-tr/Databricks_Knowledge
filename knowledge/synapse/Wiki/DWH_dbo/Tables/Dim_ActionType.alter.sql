-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ActionType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_ActionType is the master lookup for all customer financial and platform action types recorded in Fact_CustomerAction. It defines 45 distinct action types across 29 business categories covering position trading (open/close), deposits, withdrawals, bonuses, chargebacks, mirror/copy-trade operations, engagement events, and administrative actions. This table originates from the legacy DWH SQL Server (migrated via DWH_Migration.Dim_ActionType) and is NOT sourced from the production etoro.Dictionary.ActionType — which is a separate, smaller table covering only session and registration events. The DWH version was created specifically to classify the rich set of financial customer actions tracked in the Fact_CustomerAction fact table. New action types are added infrequently (45 rows since initial 2013 migration; 2 new types added in 2024). The table is effectively stable — changes require a coordinated insert across the legacy origin and DWH. The `UpdateDate` and `InsertDate` columns carry production t...'
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 5 COMMENT 'Domain expert confirmed';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 1 COMMENT 'Upstream production wiki verbatim';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 2 COMMENT 'Synapse SP code or migration DDL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 3 COMMENT 'Live data sampling or DDL structure';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 4 COMMENT 'Inferred from column name only';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key. Integer identifier for the customer action type. Values 1-45 active; 0 = N/A placeholder. Referenced by Fact_CustomerAction.ActionTypeID. DWH note: smallint in DWH vs int in legacy DWH_Migration DDL (type narrowed during migration). (Tier 2 - DWH_Migration.Dim_ActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Name COMMENT 'Human-readable name of the action type. Key values: 1=ManualPositionOpen, 2=CopyPositionOpen, 3=CopyPlusPositionOpen, 4=ManualPositionClose, 5=CopyPositionClose, 6=CopyPlusPositionClose, 7=Deposit, 8=Cashout, 9=Bonus, 10=Cashout request, 11=Chargeback, 12=Refund, 13=Refund As ChargeBack, 14=LoggedIn, 15=Account balance to mirror, 16=Mirror balance to account, 17=Register new mirror, 18=Unregister mirror, 19=Detach position from mirror, 20=Detach Stock From Mirror, 21=Publish Post, 22=Publish Comment, 23=Publish Like, 24=Recived Post On Wall, 25=Recived Comment On Wall, 26=Recived Like On Wall, 27=DepositAttempt, 28=DetachedPositionClose, 29=Cashier Loggin, 30=Processed Cashout, 31=Open CRM Case, 32=Edit StopLoss, 34=Open Stock Order, 35=End Of The Week Fee, 36=Compensation, 37=Reverse cashout, 38=Affiliate Deposit, 39=PositionOpenTypeUnknown, 40=PositionCloseTypeUnknown, 41=Customer Registration, 42=Cashout Rollback, 43=Reverse Deposit, 44=InternalDeposit, 45=InternalWithdraw. (Tier 3 - live data, DWH_dbo.Dim';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN UpdateDate COMMENT 'Production UpdateDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was last updated in the source system. Most rows = 2013-07-17 (initial migration); newer rows reflect when they were added. (Tier 2 - DWH_Migration.Dim_ActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN InsertDate COMMENT 'Production InsertDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was first inserted in the source system. Equals UpdateDate for most rows. (Tier 2 - DWH_Migration.Dim_ActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Category COMMENT 'Business category text label for grouping action types. Values: N/A, Account balance to mirror, Bonus, Cashier Loggin, Cashout, Chargeback, Compensation, Deposit, DepositAttempt, DetachPosition, Edit StopLoss, End Of The Week Fee, LoggedIn, Mirror balance to account, Open CRM Case, Open Stock Order, PositionClose, PositionOpen, Processed Cashout, Refund, Refund As ChargeBack, Register new mirror, Reverse cashout, Unregister mirror, UserEngagement, WallEngagement, Customer Registration, Reverse Deposit, Withdraw. DWH note: Use CategoryID (integer) for filtering - more reliable than Category string (see Gotchas). (Tier 3 - live data, DWH_dbo.Dim_ActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN CategoryID COMMENT 'Business category integer code grouping multiple action types. Values: 0=N/A, 1=Account balance to mirror, 2=Bonus, 3=Cashier Loggin, 4=Cashout/Withdraw, 5=Cashout request, 6=Chargeback, 7=Compensation, 8=Deposit, 9=DepositAttempt, 10=DetachPosition, 11=Edit StopLoss, 12=End Of The Week Fee, 13=LoggedIn, 14=Mirror balance to account, 15=Open CRM Case, 16=Open Stock Order, 17=PositionClose, 18=PositionOpen, 19=Processed Cashout, 20=Refund, 21=Refund As ChargeBack, 22=Register new mirror, 23=Reverse cashout, 24=Unregister mirror, 25=UserEngagement, 26=WallEngagement, 27=Customer Registration, 28=Reverse Deposit. Used in SP_Validation_Cycle_Gap MINO filter: CategoryID IN (2,4,6,7,8,12,17,19,20,21,23). (Tier 3 - live data, DWH_dbo.Dim_ActionType)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 5 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 1 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 2 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 3 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Tier 4 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN Category SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype ALTER COLUMN CategoryID SET TAGS ('pii' = 'none');
