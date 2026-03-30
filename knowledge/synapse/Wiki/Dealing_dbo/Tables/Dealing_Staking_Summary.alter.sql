-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Staking_Summary
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary SET TBLPROPERTIES (
    'comment' = 'Instrument-level staking summary - one row per crypto instrument per staking month. The top-level aggregate of the staking pipeline, consolidating all client-level distributions (`Dealing_Staking_Results`) into a single management-view row per instrument. This is the go-to table for finance, management, and compliance reporting on staking: how many crypto units were distributed to clients, how many eToro retained, what the USD values were, and what yield eToro achieved from the staking program. **Scale and activity:** 158 rows total (9 instruments × ~18 months from September 2023 to February 2026). **One row per instrument per staking month.** Very small table - suitable for direct dashboard consumption. **Key metrics in this table:** - `RewardsToDistribute` - total pool for the month (from blockchain/Google Sheets config) - `ClientUnits` / `EtoroUnits` - split of rewards between clients and eToro - `MonthlyPool` - total USD value of all staked positions (pool denominator for yield) - `EtoroYield` / `Annualiz'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingMonthID COMMENT 'Staking month key (YYYYMM). ⚠️ 2025030 (March 2025) is malformed. Use StakingYear+StakingMonth. (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingMonth COMMENT 'Month name (January - December). (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingYear COMMENT 'Calendar year. (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN InstrumentID COMMENT 'Crypto instrument. (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN Currency COMMENT 'Crypto ticker (ADA/ATOM/DOT/ETH/NEAR/POL/SOL/SUI/TRX). (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingStartDate COMMENT 'Official start of the staking measurement period. (Tier 2 - passthrough from google_sheets)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingEndDate COMMENT 'Official end of the staking measurement period. (Tier 2 - passthrough from google_sheets)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN NetworkReportedRewards COMMENT 'Total rewards reported by the blockchain network. (Tier 2 - passthrough from google_sheets)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RewardsToDistribute COMMENT 'Actual rewards to distribute (may include bonus buffer from prior months). (Tier 2 - passthrough)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN USD_ConversionRate COMMENT 'Crypto/USD exchange rate at staking_end_date. BidSpreaded from Fact_CurrencyPriceWithSplit. (Tier 2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RewardsToDistribute_USD COMMENT 'USD value: RewardsToDistribute × USD_ConversionRate. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientUnits COMMENT 'Total crypto units distributed to all eligible clients. SUM(Client_Airdrop). (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroUnits COMMENT 'Total crypto units retained by eToro. SUM(Etoro_Amount). (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientUSD COMMENT 'USD value of client distributions: ClientUnits × USD_ConversionRate. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroUSD COMMENT 'USD value of eToro''s share: EtoroUnits × USD_ConversionRate. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientPercent COMMENT 'Fraction of total rewards going to clients: ClientUnits / RewardsToDistribute. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroPercent COMMENT 'Fraction retained by eToro: EtoroUnits / RewardsToDistribute. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UtilizedUnits COMMENT 'Crypto units from eligible + opted-in positions. Numerator for utilization metrics. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UnutilizedUnits COMMENT 'Crypto units from opted-out or ineligible positions (MonthlyPool - UtilizedUnits). (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UtilizedPercent COMMENT 'Pool utilization rate: UtilizedUnits / MonthlyPool. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UnutilizedPercent COMMENT 'Fraction of pool not utilized. Current column (use over PercentUnutilized). (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN IneligibleCustomerRewards COMMENT 'Rewards that would have gone to ineligible clients - retained by eToro. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RevShareCommission COMMENT 'eToro''s RevShare portion specifically. SUM of Etoro_Amount for RevShare model clients. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentUnutilized COMMENT 'Legacy duplicate of UnutilizedPercent. Retained for backward compatibility. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentIneligible COMMENT 'Fraction of rewards lost to ineligibility: IneligibleCustomerRewards / RewardsToDistribute. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentRevShare COMMENT 'Weighted average RevShare rate across all clients: RevShareCommission / ClientUnits. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroYield COMMENT 'eToro''s yield as fraction of total pool value: EtoroUSD / MonthlyPool_USD. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN AnnualizedYield COMMENT 'Annualized yield: EtoroYield × (365 / TotalStakingDays). Benchmark comparison metric. (Tier 2 - ETL-computed)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UpdateDate COMMENT 'Row insertion timestamp (GETDATE()). (Tier 2 - ETL metadata)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN MonthlyPool COMMENT 'Total USD value of ALL staked positions (eligible+ineligible). Pool denominator for yield calculations. (Tier 2 - ETL-computed from Dealing_Staking_Position)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN IntroDays COMMENT 'Grace period days for this instrument from Dealing_Staking_Parameters. (Tier 2 - passthrough)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingMonthID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingStartDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN StakingEndDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN NetworkReportedRewards SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RewardsToDistribute SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN USD_ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RewardsToDistribute_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN ClientPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UtilizedUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UnutilizedUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UtilizedPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UnutilizedPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN IneligibleCustomerRewards SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN RevShareCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentUnutilized SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentIneligible SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN PercentRevShare SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN EtoroYield SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN AnnualizedYield SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN MonthlyPool SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary ALTER COLUMN IntroDays SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:08:07 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 64/64 succeeded
-- ====================
