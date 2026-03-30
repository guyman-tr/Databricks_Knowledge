-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Staking_Results
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results SET TBLPROPERTIES (
    'comment' = 'Client-level staking rewards table - one row per client (CID) per instrument per staking month. This is the central output of the staking pipeline: it records how much crypto each eligible client earns, how much eToro retains, and whether the airdrop was successfully delivered. Written by `SP_Staking` as part of the same monthly run that produces `Dealing_Staking_Position`. `Dealing_Staking_Results` is the aggregation of eligible positions from `Dealing_Staking_Position` into a single per-client reward allocation. **Scale and activity:** September 2023 to present (latest = Feb 2026). **20.4 million rows**. 9 instruments × ~1.5M eligible clients per month. **Key fields:** - `Client_Airdrop` - crypto units allocated to the client (based on pool share × RevShare) - `Etoro_Amount` - crypto units retained by eToro - `IsAirdropSuccess` - delivery status (NULL = not yet run, 1 = delivered, 0 = failed) - `ClubCategory` - client''s Club tier (Silver/Gold/Platinum/Diamond & Platinum Plus), relevant for reduced commissio'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results SET TAGS (
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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingMonthID COMMENT 'Staking month key (YYYYMM). ⚠️ Malformed 7-digit IDs for Oct-2024 (2024100) and Oct-2025 (2025100). Use StakingYear+StakingMonth. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingMonth COMMENT 'Month name (January - December). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingYear COMMENT 'Calendar year. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN InstrumentID COMMENT 'Crypto instrument. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Currency COMMENT 'Crypto ticker. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN CID COMMENT 'Client account ID. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN GCID COMMENT 'Group/household customer ID. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN IsEligible COMMENT '1 = meets all eligibility criteria. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN NonEligible_PrimaryReason COMMENT 'First failing eligibility check when IsEligible=0. NULL when eligible. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Raw_Staking_Amount COMMENT 'Client''s proportional share of the total staking pool (USD, weighted by eligible days). (Tier 2 - ETL-computed from Dealing_Staking_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN RevShare COMMENT 'Client''s reward fraction (0.45 - 0.90) from PlayerLevel bracket. (Tier 2 - passthrough from Dealing_Staking_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Client_Airdrop COMMENT 'Crypto units allocated to the client: pool_share × RewardsToDistribute × RevShare. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Etoro_Amount COMMENT 'Crypto units retained by eToro: pool_share × RewardsToDistribute × (1-RevShare). (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN OriginalCompensationType COMMENT '''Crypto'' or ''Cash''. Cash for clients in cash-equivalent countries (e.g., Hungary). (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN USD_Compensation COMMENT 'USD value of Client_Airdrop at staking_end_date exchange rate. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Etoro_Amount_USD COMMENT 'USD value of Etoro_Amount at staking_end_date exchange rate. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN AirdropID COMMENT 'Airdrop transaction identifier. NULL before distribution runs. (Tier 2 - passthrough from airdrop execution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN AirdropOccurred COMMENT 'Actual distribution date. NULL before distribution. (Tier 2 - passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN IsAirdropSuccess COMMENT '1 = delivered; 0 = failed; NULL = not yet run. (Tier 2 - ETL-computed from airdrop execution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN FailReasonID COMMENT 'Fail reason code when IsAirdropSuccess=0. NULL when successful or not run. (Tier 2 - ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ActualAirdropUnits COMMENT 'Actual units transferred. May differ from Client_Airdrop due to rounding. NULL before distribution. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ActualCompensationType COMMENT 'Final delivery method. May differ from OriginalCompensationType if override applied. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN UpdateDate COMMENT 'Row insertion timestamp (GETDATE()). (Tier 2 - ETL metadata)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ClubCategory COMMENT 'Client''s Club tier (Silver/Gold/Platinum/Diamond & Platinum Plus). Based on  <= 40 USD holdings threshold. (Tier 2 - join-enriched from Dealing_Staking_Club)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingMonthID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN StakingYear SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN IsEligible SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN NonEligible_PrimaryReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Raw_Staking_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN RevShare SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Client_Airdrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Etoro_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN OriginalCompensationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN USD_Compensation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN Etoro_Amount_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN AirdropID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN AirdropOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN IsAirdropSuccess SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN FailReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ActualAirdropUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ActualCompensationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results ALTER COLUMN ClubCategory SET TAGS ('pii' = 'none');
