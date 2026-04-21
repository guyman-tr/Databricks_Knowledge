-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Aggregated_Tribe_Balance
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance SET TBLPROPERTIES (
    'comment' = '`eMoney_Aggregated_Tribe_Balance` is the daily balance and account-health aggregation table for all eToro Money accounts held at Tribe Payments. It provides CASS (Client Asset Segregation Scheme) monitoring metrics, funding activity signals, and dormancy indicators needed for regulatory reporting and operational oversight. **Grain**: One row per (BalanceDate × Entity × Program × AccountSubProgram × AccountStatus × ExistingUser × EpmMethodID × CurrencyIson × IsTest). A single balance date produces ~130 rows across all entity/program/status combinations. The table has 67,580 rows covering daily snapshots from 2024-01-31 to 2026-04-11. **Three entities** are tracked: - **eToro Money UK** (CurrencyIson=826, GBP) - 638,710 accounts across UK CARD GBP, UK IBANO, UK FTD, UK GBP FOR UAE programs - **eToro Money Malta** (CurrencyIson=978 EUR + 208 DKK) - 1,356,805 accounts across EU Card, EU IBANO, EU FTD, EU TEST variants, Banking Circle DKK programs - **eToro Money AUS** (CurrencyIson=36, AUD) - 39,762 accounts v...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(BalanceDateID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `BalanceDate` COMMENT 'The actual account balance date - one day before the ETL snapshot date. Represents the day for which balances are being reported. Use this (not Date) for financial and regulatory reporting. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `BalanceDateID` COMMENT 'Integer YYYYMMDD representation of BalanceDate. Distribution key. Enables partition-aware queries by balance date. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Date` COMMENT 'ETL processing/snapshot date - the day ETL_AccountSnapshot was populated, which is BalanceDate + 1. Use for ETL lineage tracing only. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `DateID` COMMENT 'Integer YYYYMMDD of Date (ETL processing date). Matches ETL_AccountSnapshot.DateID. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `WorkDate` COMMENT 'Tribe API processing timestamp from ETL_AccountSnapshot. Represents when Tribe generated the account snapshot. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Entity` COMMENT 'eToro Money legal entity derived from CurrencyISO mapping. Values: eToro Money UK (GBP), eToro Money Malta (EUR/DKK), eToro Money AUS (AUD). (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance via eMoney_EntityByCurrencyISO_MappingStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `ProgramId` COMMENT 'Tribe program identifier for the account type. 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test. See Program column for names. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Program` COMMENT 'Human-readable program name mapped from ProgramId via SP CASE statement. 39=UK CARD GBP, 175=UK IBANO, 177=EU IBANO, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, and 8 others. ''NA'' for unmapped ProgramIds. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountSubProgramID` COMMENT 'Sub-program identifier from eMoney_Dim_Account, matched via ProviderCurrencyBalanceID or ProviderHolderID. NULL when account is not matched to a known customer. FK to eMoney_Dictionary_AccountSubProgram. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountSubProgram` COMMENT 'Sub-program name from eMoney_Dim_Account. Examples: IBAN Black, IBAN Silver, Card Standard. NULL when account unmatched. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `EpmMethodID` COMMENT 'Electronic Payment Method ID from ETL_AccountSnapshot. Identifies the payment rail type for the account. NULL when not set by Tribe. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountStatus` COMMENT 'Current account status from ETL_AccountSnapshot.AccountStatusDescription. Values: Active, Suspended, Blocked. Maps to eMoney_Dictionary_AccountStatus values (0=Active, 1=Suspended, 2=Deleted). (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `ExistingUser` COMMENT 'Flag: 1 if the account''s HolderId or AccountId matches a known eToro customer in eMoney_Dim_Account (GCID_Unique_Count=1); 0 for unmatched/provisioned-but-unverified accounts. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalAccounts` COMMENT 'Count of distinct AccountIds in this (BalanceDate × grouping) combination after row deduplication (latest Created per AccountId per BalanceDate). (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalIBANS` COMMENT 'Count of distinct BankAccountIds (IBAN assignments) in this grouping. Zero for card-only programs. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `FundedAccounts` COMMENT 'Count of accounts with SettledBalance > 0 (positive balance) on BalanceDate. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `FundedAbove5` COMMENT 'Count of accounts with SettledBalance > 5 (meaningful funded threshold, e.g., excluding micro-balances and rounding artefacts). (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Active30` COMMENT 'Count of accounts with AccountDateTimeUpdated within 30 days before BalanceDate. Measures accounts with recent activity or status changes. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Active90` COMMENT 'Count of accounts with AccountDateTimeUpdated within 90 days before BalanceDate. 90-day activity window for dormancy/retention analysis. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `NeverActive` COMMENT 'Count of accounts where AccountDateUpdated = AccountDateCreated - accounts that have never had any activity or status change since creation. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `OverdrawnAccounts` COMMENT 'Count of accounts with SettledBalance < 0 on BalanceDate. Regulatory exception - should be zero in a healthy CASS-compliant state. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `NegativeBalances` COMMENT 'Sum of settled balances for overdrawn accounts (SettledBalance WHERE SettledBalance < 0). Represents the total negative exposure. Expected to be 0 or near-zero for regulatory compliance. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `CASSBalances` COMMENT 'Sum of settled balances for accounts with positive balance (SettledBalance WHERE SettledBalance >= 0). CASS = Client Asset Segregation Scheme - this is the client money that must be held in segregated bank accounts. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalBalances` COMMENT 'Net sum of all settled balances (CASSBalances + NegativeBalances). Equals the total Tribe-held balance for this entity/program/status combination. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `UpdateDate` COMMENT 'ETL run timestamp - GETDATE() at INSERT time. Indicates when this row was last computed and inserted. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `CurrencyIson` COMMENT 'ISO 4217 numeric currency code. 826=GBP (UK), 978=EUR (Malta), 36=AUD (Australia), 208=DKK (Denmark). Identifies the account currency within the entity. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `HolderCurrency` COMMENT 'Currency name from eMoney_EntityByCurrencyISO_MappingStatic.CurrencyName, matched via CurrencyISO = CurrencyIson. Examples: GBP, EUR, AUD, DKK. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance via eMoney_EntityByCurrencyISO_MappingStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `IsTest` COMMENT '1 if the account is flagged as a test account in eMoney_Dim_Account.IsTestAccount; 0 for production accounts; NULL when account is not matched to eMoney_Dim_Account. Always exclude IsTest=1 from business reporting. (Tier 2 - SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `BalanceDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `BalanceDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `DateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `WorkDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Entity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `ProgramId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Program` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountSubProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `EpmMethodID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `AccountStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `ExistingUser` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalAccounts` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalIBANS` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `FundedAccounts` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `FundedAbove5` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Active30` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `Active90` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `NeverActive` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `OverdrawnAccounts` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `NegativeBalances` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `CASSBalances` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `TotalBalances` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `CurrencyIson` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `HolderCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance ALTER COLUMN `IsTest` SET TAGS ('pii' = 'none');
