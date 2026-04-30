-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PlayerLevel
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_playerlevel
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_playerlevel (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 7 customer loyalty tiers — Bronze through Diamond plus Internal — with tier-specific cashout wait times, equity thresholds, and downgrade protection rules. Source: etoro.Dictionary.PlayerLevel on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlayerLevel',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN PlayerLevelID COMMENT 'Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Note: IDs are not in Sort order — use Sort column for display ordering. ID 4 is special (internal/employee) and is excluded from customer-facing queries. FK from Customer.RegistrationRequest and Customer.CustomerStatic. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN Name COMMENT 'Tier display name. Unique constraint prevents duplicates. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN CashoutPendingHours COMMENT 'Maximum hours a cashout request waits before processing. 120=5 days (Bronze/Silver/Internal), 72=3 days (Gold), 24=1 day (Platinum+). Key loyalty benefit — higher tiers get faster withdrawals. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN FromSumLotCount COMMENT 'Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN ToSumLotCount COMMENT 'Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN FromSumDeposit COMMENT 'Legacy: minimum cumulative deposit amount (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN ToSumDeposit COMMENT 'Legacy: maximum cumulative deposit amount (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN Sort COMMENT 'Display order for tier hierarchy. 0=Internal, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Ascending order matches tier rank. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN IsWalletRedeemAllowed COMMENT 'Whether wallet/copy-fund redemption is permitted for this tier. Currently 1 (allowed) for all tiers. Default 1. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN RealizedEquityFrom COMMENT 'Minimum realized equity (USD) to qualify for this tier. Current primary qualification metric. NULL for Internal tier. Range: -100,000 (Bronze) to 250,000 (Diamond). (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN RealizedEquityTo COMMENT 'Maximum realized equity (USD) for this tier. NULL for Internal tier. Range: 5,000 (Bronze) to 100,000,000 (Diamond). (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN ThresholdPercentToCurrentLevel COMMENT 'Percentage threshold before downgrade risk begins. Currently 20 for all customer tiers (customer must fall to 80% of tier minimum). NULL for Internal. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerlevel ALTER COLUMN DaysInRiskBeforeDowngrade COMMENT 'Grace period in days before tier downgrade when equity drops below threshold. 0=immediate (Bronze/Internal), 180=6 months (Silver/Gold), 365=1 year (Platinum+/Diamond). Default 0. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerLevel)';

