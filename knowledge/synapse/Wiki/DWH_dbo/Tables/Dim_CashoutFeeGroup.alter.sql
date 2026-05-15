-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CashoutFeeGroup
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup SET TBLPROPERTIES (
    'comment' = 'Dim_CashoutFeeGroup is the DWH version of etoro.Dictionary.CashoutFeeGroup. It classifies customers into fee tiers for withdrawal processing. Each customer''s record carries a CashoutFeeGroupID that determines which withdrawal fee schedule applies when they request a cashout. The three groups: Default (1) -- standard withdrawal fees apply (most customers); Exempt (2) -- no withdrawal fees (high-tier eToro Club members, active Popular Investors, promotional campaigns); Discount (3) -- reduced withdrawal fees (mid-tier loyalty program members). Fee amounts per group are defined in Trade.CashoutRange (not in DWH). The fee group is dynamically calculated based on a customer''s PlayerLevel and GuruStatus (Popular Investor tier) via mapping tables, and auto-updated by Billing.ProcessCashoutFeeGroupUpdate when tiers change. Source: etoro.Dictionary.CashoutFeeGroup on etoroDB-REAL. Exported daily to Bronze/etoro/Dictionary/CashoutFeeGroup/ and staged into DWH_staging.etoro_Dictionary_CashoutFeeGroup. SP_Dictionaries...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CashoutFeeGroupID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN CashoutFeeGroupID COMMENT 'Primary key identifying the fee group. 1=Default (standard fees), 2=Exempt (no fees), 3=Discount (reduced fees). Stored on customer records; drives withdrawal fee calculation via Trade.CashoutRange. (Tier 1 - upstream wiki, Dictionary.CashoutFeeGroup)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN CashoutFeeGroupName COMMENT 'Human-readable fee group name: ''Default'', ''Exempt'', ''Discount''. Renamed from production `Name` column. Used in reporting to display fee group. (Tier 1 - upstream wiki, Dictionary.CashoutFeeGroup)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN CashoutFeeGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN CashoutFeeGroupName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN Default SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN Exempt SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup ALTER COLUMN Discount SET TAGS ('pii' = 'none');

