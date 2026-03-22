-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Fund
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund SET TBLPROPERTIES (
    'comment' = '`Dim_Fund` is a dimension table of eToro Smart Portfolios (internally called Funds). Each row represents one managed investment fund, identified by a `FundID`, with its associated account (`FundAccountID`), owner (`FundOwnerID`), public visibility flag (`IsPublic`), minimum copy investment amount (`MinCopyAmount`), quarterly/annual refresh schedule (`RefreshIntervalMonths`), and fund category (`FundType`). As of 2026-03-11, the table contains **877 funds**, nearly all of which are public (876 of 877). The vast majority are categorized as FundType=3 (Market), with smaller counts of FundType=1 (TopTraders, 38 funds) and FundType=2 (Partners, 44 funds). `FundType` values are decoded by `DWH_dbo.Dim_FundType`: - 1 = TopTraders (curated expert trader portfolios) - 2 = Partners (partner/affiliate-managed portfolios) - 3 = Market (market/thematic portfolios - the dominant type) The data originates from `etoro.Trade.Fund` on the etoroDB-REAL production server via `DWH_staging.etoro_Trade_Fund`. The staging table i...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (FundID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundID COMMENT 'Primary key. Surrogate identifier for the fund. Referenced by Trade.FundInterval, Trade.FundIntervalAllocation, and fee/backtest procedures. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundName COMMENT 'Display name of the fund. Set from Customer.CustomerStatic.UserName when Job_GenerateFundAllocation creates a fund. Shown in fund details and API responses. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundAccountID COMMENT 'FK to Customer.CustomerStatic.CID. The customer account that holds the fund''s positions. Used to check ''is CID a fund?'' (Confluence DCS-627). Join key for GetFundMetaData, GetFundCidsBulk. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundOwnerID COMMENT 'FK to Customer.CustomerStatic.CID. The entity that owns/manages the fund. Job_GenerateFundAllocation looks up FundID by FundOwnerID; when null, creates new fund. Typically equals FundAccountID at creation. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN IsPublic COMMENT '1 = fund is publicly discoverable; 0 = private. Returned by GetFundMetaData. Controls visibility in fund listing and copy flows. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN MinCopyAmount COMMENT 'Minimum investment amount (in account currency) required to copy into this fund. Job_GenerateFundAllocation uses 5000 for new funds; sample data shows 100-5000. Enforced by application. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN RefreshIntervalMonths COMMENT 'Rebalance interval in months. Job_GenerateFundAllocation uses this to compute Trade.FundInterval.PlannedEnd: adds this many months to PlannedStart. Sample: 1=monthly, 2=bimonthly, 3=quarterly. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundType COMMENT 'FK to Dictionary.FundType.FundTypeID. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for older funds. See Dictionary.FundType. (Tier 1 — Trade.Fund)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT the source LastUpdateDate. (Tier 2 — SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundOwnerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN IsPublic SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN MinCopyAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN RefreshIntervalMonths SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN FundType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
