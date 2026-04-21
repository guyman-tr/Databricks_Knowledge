-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_EthFeeSent_Blockchain
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain SET TBLPROPERTIES (
    'comment' = 'EXW_EthFeeSent_Blockchain attributes each Ethereum blockchain gas fee transaction to a specific wallet user and transaction type. It joins Etherscan-sourced fee data (EXW_ETH_FeeData_Blockchain) with wallet transactions (EXW_FactTransactions) using the blockchain transaction hash (txhash = BlockchainTransactionId) to produce an analyst-friendly view of who paid ETH gas fees, for what purpose, and at what cost. Activity distribution (338,404 rows total): User Send Out=134,697 (39.8%), Coin Transfer=131,642 (38.9%), Wallet Creation=25,713 (7.6%), Conversion In=11,977 (3.5%), Conversion Out=9,351 (2.8%), Not Exist on Wallet=8,978 (2.7%), ManualUserMoneyOut=6,467 (1.9%), ConversionToFiat=5,464 (1.6%), Staking=2,140 (0.6%), Payment=1,832 (0.5%), AML Money Back=119, Other=24. The "Not Exist on Wallet" category (8,978 rows) represents Etherscan-logged transactions where no matching record was found in EXW_FactTransactions - likely due to timing gaps, orphaned blockchain transactions, or pre-wallet-system transact...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `txhash` COMMENT 'Ethereum blockchain transaction hash from Etherscan. Primary JOIN key to EXW_FactTransactions.BlockchainTransactionId. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `date_time` COMMENT 'Raw timestamp string as imported from Etherscan - stored as nvarchar, not cast to datetime. Use Date or TranDate for time-based filtering. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Date` COMMENT 'Blockchain confirmation date: CAST(date_time AS DATE). Represents when Etherscan recorded the transaction. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `TranDate` COMMENT 'Wallet transaction date from EXW_FactTransactions.TranDate. May differ from Date by up to 5 days due to SP lookback window. NULL for ''Not Exist on Wallet'' rows. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `TranDateID` COMMENT 'YYYYMMDD integer form of TranDate. NULL if TranDate is NULL. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `txn_fee_eth` COMMENT 'ETH gas fee amount as reported by Etherscan. CAST(CAST(source AS FLOAT) AS MONEY) to handle varchar imports. Multiply by historical_price_eth to get USD cost. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `historical_price_eth` COMMENT 'ETH/USD price at time of transaction from Etherscan. Etherscan-sourced; not from internal EXW_Wallet.EXW_Price table. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `GCID` COMMENT 'Wallet user''s GCID from EXW_FactTransactions. 0 for omnibus-sender transactions. Use GCIDUnion for user attribution. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `RealCID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Enriched by JOIN to EXW_DimUser on GCID. Source: EXW_DimUser.RealCID via GCIDUnion. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `BlockchainFees` COMMENT 'On-chain blockchain fee in native crypto units from EXW_FactTransactions. Distinct from txn_fee_eth (Etherscan-reported ETH amount). (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `contract_address` COMMENT 'Ethereum smart contract address if the transaction created a wallet. Non-NULL indicates a Wallet Creation transaction. NULL for regular transfers. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `GCIDUnion` COMMENT 'Resolved GCID for user attribution. CASE: GCID>0 -> GCID (real sender); GCID=0 -> receiver''s GCID via CustomerWalletsView.Address lookup (omnibus resolution). Use this for all user-level analysis. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `CountryID` COMMENT 'Country ID from DWH_dbo.Dim_Country, resolved at TranDate via date-range snapshot (Fact_SnapshotCustomer + Dim_Range). (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Country` COMMENT 'Country name from DWH_dbo.Dim_Country.Name, resolved at TranDate. Reflects user''s country at time of transaction (not current). (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `RegulationID` COMMENT 'Regulation ID from DWH_dbo.Dim_Regulation, resolved at TranDate. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Regulation` COMMENT 'Regulation entity name from DWH_dbo.Dim_Regulation.Name, resolved at TranDate. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Activity` COMMENT 'Transaction type classification. Values: ''User Send Out'', ''Coin Transfer'', ''Wallet Creation'', ''Conversion In -Customer Send To Omnibus'', ''Conversion Out -Omnibus send to Customer'', ''Not Exist on Wallet'', ''ManualUserMoneyOut'', ''ConversionToFiat'', ''Staking'', ''Payment'', ''AML Money Back'', ''Other''. NOT NULL. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `UpdateDate` COMMENT 'ETL load timestamp - GETDATE() at SP run time. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `method` COMMENT 'Ethereum transaction method from Etherscan (e.g., ''Create Wallet'' for wallet creation transactions). NULL for standard ETH transfers. Used in Activity CASE for Wallet Creation detection. (Tier 2 - SP_EXW_EthFeeSent_Blockchain)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `txhash` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `date_time` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `TranDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `TranDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `txn_fee_eth` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `historical_price_eth` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `BlockchainFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `contract_address` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `GCIDUnion` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `Activity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain ALTER COLUMN `method` SET TAGS ('pii' = 'none');
