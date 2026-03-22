-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_AccountStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus SET TBLPROPERTIES (
    'comment' = 'Dim_AccountStatus is a two-row reference table defining whether an eToro trading account is Open (active) or Closed (deactivated). It is the DWH version of the production Dictionary.AccountStatus table. Every customer account in the platform references this dimension via the AccountStatusID field (stored in Dim_Customer and Customer.CustomerStatic). Source: etoro.Dictionary.AccountStatus on etoroDB-REAL. The production table is exported daily to the data lake at Bronze/etoro/Dictionary/AccountStatus/ and staged into DWH_staging.etoro_Dictionary_AccountStatus. SP_Dictionaries_DL_To_Synapse loads from that staging table. The ETL is a full TRUNCATE + INSERT pattern (Override strategy). StatusID is hardcoded to 1 (active row indicator per the DWH ETL convention). UpdateDate and InsertDate are both set to GETDATE() at load time. An ID=0 placeholder row (''N/A'') is inserted after the main load for fact table JOIN safety. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN AccountStatusID COMMENT 'Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted), 0=N/A (DWH placeholder for NULL-safe JOINs). Referenced by Dim_Customer.AccountStatusID. (Tier 1 - upstream wiki, Dictionary.AccountStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN AccountStatusName COMMENT 'Human-readable label for the account state: ''Open'', ''Closed'', or ''N/A''. Used in reporting to display account state. Sourced directly from Dictionary.AccountStatus.AccountStatusName. (Tier 1 - upstream wiki, Dictionary.AccountStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN StatusID COMMENT 'ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows (including the ID=0 placeholder). Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed -- use for ETL freshness monitoring only. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN InsertDate COMMENT 'ETL load timestamp for when the row was (re-)inserted. Set to GETDATE() on every reload by SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN AccountStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
