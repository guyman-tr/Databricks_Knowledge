-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.RecurringInvestment.UserDeposits
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.UserDeposits.md
-- Layer: bronze
-- UC Target: main.general.bronze_recurringinvestment_recurringinvestment_userdeposits
-- =============================================================================

-- ---- UC Target: main.general.bronze_recurringinvestment_recurringinvestment_userdeposits (business_group=general) ----
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits SET TBLPROPERTIES (
    'comment' = 'Stores deposit data per user per cycle, tracking the aggregated deposit amount and timing for recurring investment plan execution. Source: RecurringInvestment.RecurringInvestment.UserDeposits on the RecurringInvestment production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.UserDeposits.md).'
);

ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'RecurringInvestment',
    'source_table' = 'UserDeposits',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits ALTER COLUMN GCID COMMENT 'Global Customer ID uniquely identifying the eToro user. Part of the composite primary key. Each user has one deposit record per cycle. (Source: Confluence confirms GCID is "unique identifier of the user") (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.UserDeposits)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits ALTER COLUMN DepositID COMMENT 'Unique identifier of the deposit or deposit attempt for this cycle. Part of the composite primary key. Data comes from Money ServiceBus and maps to Billing DB [Recurring].[Payment]. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.UserDeposits)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits ALTER COLUMN DepositAmountUsd COMMENT 'The deposit amount in USD. May differ from DepositAmountCurrency when the user''s plan currency is not USD due to currency conversion. Zero indicates a failed/declined deposit attempt. Data comes from Money ServiceBus. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.UserDeposits)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits ALTER COLUMN DepositAmountCurrency COMMENT 'The deposit amount in the plan''s currency. The plan''s currency can be found in RecurringInvestment.Plans.CurrencyID. Equal to DepositAmountUsd for USD-denominated plans. Data comes from Money ServiceBus. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.UserDeposits)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_userdeposits ALTER COLUMN DepositDate COMMENT 'The date and time the deposit or deposit attempt was made. Data comes from Money ServiceBus. Used for temporal queries and deposit tracking. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.UserDeposits)';

