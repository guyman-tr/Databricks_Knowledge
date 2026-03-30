-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CreditType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype SET TBLPROPERTIES (
    'comment' = '`Dim_CreditType` is a 33-row reference dictionary classifying every type of account balance change in the eToro platform. It covers the full lifecycle of customer funds: deposits (ID=1), cashouts (ID=2), position open/close events (IDs 3-4), bonuses and compensation (IDs 5-7), reversals and chargebacks (IDs 8,11-12,16-17,32-33), trading-related fees (IDs 13-15), mirror/copy trading events (IDs 18-28), stock orders (IDs 29-30), data fixes (ID=31), and IB synchronization (ID=10). The source is `etoro.Dictionary.CreditType`. The staging table `DWH_staging.etoro_Dictionary_CreditType` passes through CreditTypeID and renames `Name` to `CreditTypeName`. The ETL is a full TRUNCATE-and-INSERT daily reload. `UpdateDate` is injected as GETDATE() by the SP. Important: `CreditTypeName` uses `char(50)` - values have trailing spaces. Use `RTRIM(CreditTypeName)` when displaying or comparing. Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md`. Synapse: REPLICATE, CLUSTERED INDEX (CreditTypeID...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CreditTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN CreditTypeID COMMENT 'Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB Sync, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18-28=Mirror/CopyTrading operations, 29-30=Stock Orders, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Tier 1 - Dictionary.CreditType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN CreditTypeName COMMENT 'Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces - always RTRIM when displaying. DWH note: renamed from Name in source. (Tier 1 - Dictionary.CreditType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN CreditTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN CreditTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
