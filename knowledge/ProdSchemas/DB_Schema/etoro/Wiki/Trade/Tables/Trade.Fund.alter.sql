-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.Fund
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_fund
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_fund (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_fund SET TBLPROPERTIES (
    'comment' = 'Master table for CopyFunds/SmartPortfolios defining each fund''s account, owner, visibility, minimum investment, rebalance interval, and strategy type. Source: etoro.Trade.Fund on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_fund SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'Fund',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN FundID COMMENT 'Primary key. Surrogate identifier for the fund. Referenced by Trade.FundInterval, Trade.FundIntervalAllocation, and fee/backtest procedures. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN FundName COMMENT 'Display name of the fund. Set from Customer.CustomerStatic.UserName when Job_GenerateFundAllocation creates a fund. Shown in fund details and API responses. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN FundAccountID COMMENT 'FK to Customer.CustomerStatic.CID. The customer account that holds the fund''s positions. Used to check "is CID a fund?" (Confluence DCS-627). Join key for GetFundMetaData, GetFundCidsBulk. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN FundOwnerID COMMENT 'FK to Customer.CustomerStatic.CID. The entity that owns/manages the fund. Job_GenerateFundAllocation looks up FundID by FundOwnerID; when null, creates new fund. Typically equals FundAccountID at creation. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN IsPublic COMMENT '1 = fund is publicly discoverable; 0 = private. Returned by GetFundMetaData. Controls visibility in fund listing and copy flows. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN MinCopyAmount COMMENT 'Minimum investment amount (in account currency) required to copy into this fund. Job_GenerateFundAllocation uses 5000 for new funds; sample data shows 100-5000. Enforced by application. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN RefreshIntervalMonths COMMENT 'Rebalance interval in months. Job_GenerateFundAllocation uses this to compute Trade.FundInterval.PlannedEnd: adds this many months to PlannedStart. Sample: 1=monthly, 2=bimonthly, 3=quarterly. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN CreateDate COMMENT 'When the fund row was created. Set by default. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN LastUpdateDate COMMENT 'Last modification timestamp. Updated by application or procedures when fund config changes. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN FundType COMMENT 'FK to Dictionary.FundType.FundTypeID. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for older funds. See Dictionary.FundType. (Tier 1 - upstream wiki, etoro.Trade.Fund)';
ALTER TABLE main.bi_db.bronze_etoro_trade_fund ALTER COLUMN HasCrypto COMMENT '1 = fund may hold crypto instruments; 0 = fund excludes crypto. Default 1. Returned by GetFundMetaData. Used for instrument filtering and risk rules. (Tier 1 - upstream wiki, etoro.Trade.Fund)';

