-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ClosePositionReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason SET TBLPROPERTIES (
    'comment' = '`Dim_ClosePositionReason` defines every possible trigger or reason that can cause a trading position to close on the eToro platform. Each of the 27 IDs represents a distinct closure scenario: whether a user manually closes (ID=0), a stop-loss fires (ID=1/3), a CopyTrading leader exits cascading to copiers (ID=9), or operations liquidates an account (ID=15). This classification is permanently written to position records and drives trading analytics, P&L attribution, and regulatory reporting. Data flows from `etoro.Dictionary.ClosePositionActionType` via the Generic Pipeline, through `DWH_staging.etoro_Dictionary_ClosePositionActionType`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL applies column renames: `ID` becomes `ClosePositionReasonID` and `ClosePositionActionName` becomes `Name`. `StatusID=1` is hardcoded, and `UpdateDate`/`InsertDate` are set to `GETDATE()`. See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md`. `SP_Dictionaries_DL_To_Synapse`...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ClosePositionReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN ClosePositionReasonID COMMENT 'Primary key. DWH rename of production `ID`. Values 0-26. 0=Customer (manual), 1=Stop Loss, 2=End of Week, 3=SL via trade server, 4=Return to Market, 5=Take Profit, 6=TP via trade server, 7=Contact Rollover, 8=BackOffice, 9=Hierarchical Close, 10=Hierarchical close by recovery, 11=Join Demo Challenge, 12=Close All, 13=Copy Stop Loss, 14=Mirror manual, 15=Manual Liquidation, 16=BSL, 17=Manual Unregister, 18=BackOffice Unregister, 19=Redeem, 20=Operational adjustment, 21=Orphaned, 22=Transferred Out, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. Stored permanently with every closed position. (Tier 1 - upstream wiki, Dictionary.ClosePositionActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN Name COMMENT 'DWH rename of production `ClosePositionActionName`. Human-readable closure trigger label. E.g., "Customer", "Stop Loss", "Hierarchical Close", "BSL". Used in account statements, trading reports, and position analytics. (Tier 1 - upstream wiki, Dictionary.ClosePositionActionType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN StatusID COMMENT 'Active record flag hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from production Dictionary.ClosePositionActionType. No filtering value - all rows are active. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() on each daily reload. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp set to GETDATE() on each daily reload (same value as UpdateDate due to TRUNCATE+INSERT). Not the date the action type was originally created. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN ClosePositionReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

