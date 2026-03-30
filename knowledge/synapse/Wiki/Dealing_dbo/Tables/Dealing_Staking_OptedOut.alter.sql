-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Staking_OptedOut
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout SET TBLPROPERTIES (
    'comment' = 'This is the **Staking PM''s primary monitoring table** - it answers: *"How many clients are eligible for staking? Of those, how many opted in vs out? And how much can eToro actually commit to on-chain staking?"* The table provides the breakdown by **regulatory jurisdiction** (FCA, CySEC, FSA Seychelles, etc.), which is critical because eligibility rules differ by regulation - not all regulations allow all crypto instruments, and some regulatory changes (e.g., FCA exclusion for certain coins in specific months) affect opt-in rates overnight. **Key business metric: Units_AvailableForStaking** - this is the amount eToro can actually stake on behalf of clients, subject to two constraints: 1. **LiquidityBuffer**: eToro must keep a fraction (0.60 - 1.00 per instrument, from Dealing_Staking_Parameters) available for client withdrawals 2. **Recon Buffer**: An additional 5% (10% for ETH) safety margin on opted-in units, computed as `LEAST(EligibleUnits * LiquidityBuffer, OptedInUnits * 0.95)` Synapse: ROUND_ROBIN, CLU...'
);

ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX on Date',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Date COMMENT 'Snapshot date. CLUSTERED INDEX key. Daily from May 2024. (Tier 3 - SP @Date)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN InstrumentID COMMENT 'Crypto instrument FK to DWH_dbo.Dim_Instrument. One row per instrument/regulation per day. (Tier 3 - BI_DB_dbo.BI_DB_PositionPnL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Currency COMMENT 'Crypto ticker. Includes EUR pairs (ETHEUR, ADAEUR, SOLEUR). (Tier 3 - Fivetran_google_sheets)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN LiquidityBuffer COMMENT 'Fraction of eligible units that must remain available for client withdrawals (from Dealing_Staking_Parameters). E.g., 0.60 = only 60% of eligible units can be committed to staking. (Tier 3 - Dealing_Staking_Parameters)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN USD_Rate COMMENT 'Exchange rate: how many USD per 1 unit of this crypto at snapshot time. Used to compute Value columns. (Tier 3 - external rate source)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Regulation COMMENT 'eToro regulatory jurisdiction name (e.g., "FCA", "CySEC", "FSA Seychelles", "ASIC"). Defines eligibility rules for this specific crypto. Derived from DWH_dbo.Dim_Customer. (Tier 1 - DWH_dbo)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleClients COMMENT 'Count of clients past the intro period with eligible positions in this instrument under this regulation. (Tier 3 - BI_DB_dbo.BI_DB_PositionPnL eligible population)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleUnits COMMENT 'Total crypto units held by all eligible clients (opted-in AND opted-out combined). (Tier 3 - BI_DB_dbo.BI_DB_PositionPnL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleValue COMMENT 'USD value of all eligible holdings (EligibleUnits × USD_Rate). (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInClients COMMENT 'Count of clients who actively opted INTO staking for this instrument. (Tier 3 - waiver/opt-in tables)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInUnits COMMENT 'Total units held by opted-in clients only. (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInValue COMMENT 'USD value of opted-in holdings. (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutClients COMMENT 'Count of clients who opted OUT (EligibleClients - OptedInClients). (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutUnits COMMENT 'Units held by opted-out clients. (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutValue COMMENT 'USD value of opted-out holdings. (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Units_AvailableForStaking COMMENT '**The amount eToro can commit on-chain**. Computed as: `LEAST(EligibleUnits × LiquidityBuffer, OptedInUnits × 0.95)` (ETH uses 0.90 instead of 0.95). The minimum of two safety caps: the liquidity buffer (ensuring enough for withdrawals) and the recon buffer (5-10% safety margin on opted-in units). (Tier 3 - computed from SP_Staking_DailyPool logic)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Value_AvailableForStaking COMMENT 'USD value of Units_AvailableForStaking. `LEAST(EligibleValue × LiquidityBuffer, OptedInValue × 0.95)`. (Tier 3 - computed)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN UpdateDate COMMENT 'ETL run timestamp from SP_Staking_DailyPool. (Tier 4 - ETL metadata)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN LiquidityBuffer SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN USD_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleClients SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN EligibleValue SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInClients SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedInValue SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutClients SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN OptedOutValue SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Units_AvailableForStaking SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN Value_AvailableForStaking SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:06:52 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 38/38 succeeded
-- ====================
