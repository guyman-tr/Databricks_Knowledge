-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_Inventory_Snapshot_History
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history SET TBLPROPERTIES (
    'comment' = 'EXW_Inventory_Snapshot_History is the daily time-series audit trail for eToro Wallet''s blockchain address inventory. Each row captures the state of the address pool for one specific (date, crypto asset, wallet status) combination - allowing operations to track trends over time and detect replenishment shortfalls. **What is the address inventory?** Each eToro Wallet customer is assigned a dedicated blockchain wallet address per crypto asset (e.g., a BTC address, an ETH address). The wallet infrastructure maintains a pool of pre-generated addresses in `EXW_WalletInventory`. Before assignment they sit as "Available"; once assigned to a user or to an omnibus account they become "Allocated"; once the customer has deposited and been verified they graduate to "FundingVerified". **Business value**: The snapshot lets the operations team answer "are we running low on ETH addresses?" or "how many new BTC wallets did we allocate last week?" without querying the live inventory directly. The rolling 7-day and 30-day win...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(BlockchainCryptoId)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `WalletStatus` COMMENT 'Lifecycle state of wallets in this snapshot group. 5 distinct values: Verified (wallets verified for blockchain use), Pending (in provisioning), FundingVerified (funded and verified - holding customer crypto), VerifiedForAssign (verified, queued for assignment), Failed (provisioning failure). Part of the grouping key (GROUP BY with BlockchainCryptoName, BlockchainCryptoId). (Tier 2 - SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `BlockchainCryptoName` COMMENT 'Short display name for the crypto asset. 12 distinct values: BTC, ETH, XRP, EOS, LTC, BCH, XLM, TRX, ADA, DOGE, ETC, SOL. Part of the grouping key. (Tier 2 - SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `BlockchainCryptoId` COMMENT 'Wallet-system internal integer ID for the crypto asset. 12 distinct values: 1=BTC, 2=ETH, 4=XRP, 3=BCH, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL. HASH distribution key. Part of the grouping key. (Tier 2 - SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_Total` COMMENT 'Cumulative count of all wallets of this crypto/status that have been allocated (assigned to any GCID, omnibus or user) up to and including [Date for Report]. Formula: SUM(CASE WHEN Allocated < @EndDate THEN 1 ELSE 0). (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Funded_Free` COMMENT 'Count of FundingVerified wallets that are unoccupied and ready for promotion. Formula: SUM(CASE WHEN WalletStatus=''FundingVerified'' AND Occupied=0 AND IsPromotionReady=1 THEN 1 ELSE 0). Non-zero only for WalletStatus=''FundingVerified'' rows. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Funded_Occupied` COMMENT 'Count of FundingVerified wallets that are actively holding customer funds. Formula: SUM(CASE WHEN WalletStatus=''FundingVerified'' AND Occupied=1 AND IsPromotionReady=1 THEN 1 ELSE 0). Non-zero only for WalletStatus=''FundingVerified'' rows. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Available` COMMENT 'Count of wallets in the unallocated pool - not yet assigned to any customer or omnibus. Formula: SUM(CASE WHEN Allocated IS NULL OR Allocated > @d THEN 1 ELSE 0). High values indicate a healthy address reserve. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Date_for_Report` COMMENT 'The business date of this snapshot row. Corresponds to the @d parameter passed to SP_EXW_Inventory_Snapshot_History. Used as the DELETE key for idempotent reruns. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `UpdateDate` COMMENT 'Timestamp when this row was inserted by SP_EXW_Inventory_Snapshot_History. Set to GETDATE() at insert time. Reflects ETL execution time, not business date. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_AllocatedOmnibuses` COMMENT 'Count of wallets allocated to omnibus/system accounts (GCID <= 0). Subset of [Allocated Total] for system-held wallets. Formula: SUM(CASE WHEN Allocated < @EndDate AND GCID <= 0 THEN 1 ELSE 0). (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_AllocatedToUsers` COMMENT 'Count of wallets allocated to real customer accounts (GCID > 0). Subset of [Allocated Total] for customer-held wallets. Formula: SUM(CASE WHEN Allocated < @EndDate AND GCID > 0 THEN 1 ELSE 0). Should equal [Allocated Total] minus [Total AllocatedOmnibuses]. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_Created` COMMENT 'Cumulative count of all wallet addresses ever created for this crypto/status group up to @EndDate. Formula: COUNT(DISTINCT WalletID) WHERE Created < @EndDate. Includes both allocated and available wallets. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_Daily` COMMENT 'Count of wallets allocated on exactly [Date for Report] (Allocated = @d). Point-in-time daily allocation velocity - how many new assignments happened that day. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_Daily` COMMENT 'Count of wallets provisioned on exactly [Date for Report] (CreatedDateID = YYYYMMDD(@d)). Point-in-time daily creation velocity - how many new address records were generated that day. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_7_days` COMMENT 'Count of wallets allocated within the 7-day window ending on [Date for Report] (Allocated BETWEEN @d-6 AND @d). Rolling 7-day allocation velocity. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_30_days` COMMENT 'Count of wallets allocated within the 30-day window ending on [Date for Report] (Allocated BETWEEN @d-29 AND @d). Rolling 30-day allocation velocity. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_7_days` COMMENT 'Count of wallets created within the 7-day window ending on [Date for Report] (Created BETWEEN @d-6 AND @d). Rolling 7-day provisioning velocity. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_30_days` COMMENT 'Count of wallets created within the 30-day window ending on [Date for Report] (Created BETWEEN @d-29 AND @d). Rolling 30-day provisioning velocity. (Tier 2 - SP_EXW_Inventory_Snapshot_History)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `WalletStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `BlockchainCryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `BlockchainCryptoId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_Total` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Funded_Free` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Funded_Occupied` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Available` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Date_for_Report` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_AllocatedOmnibuses` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_AllocatedToUsers` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Total_Created` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_Daily` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_Daily` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_7_days` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Allocated_30_days` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_7_days` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history ALTER COLUMN `Created_30_days` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:34:59 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 12/38 succeeded
-- Error: [RequestId=c9a05319-6a78-4014-8c5e-6f505b0b0111 ErrorClass=RESOURCE_DOES_NOT_EXIST] Column `Created_30_days` does not exist.
-- ====================
