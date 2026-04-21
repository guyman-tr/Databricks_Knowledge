-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_AccountStatus
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_AccountStatus` is a lookup/reference table that defines the valid values for account lifecycle state in the eToro Money fiat platform. Each row maps an integer ID to a human-readable status name. The three states - **Active**, **Suspended**, and **Deleted** - represent the full lifecycle of a fiat currency balance account: **Active** for normal operation, **Suspended** for temporarily restricted accounts (e.g., during AML review or compliance holds), and **Deleted** for permanently closed accounts. This dictionary is sourced directly from `FiatDwhDB.Dictionary.AccountStatuses` via the Generic Pipeline Bronze export. It is referenced by `eMoney_Dim_Account.AccountStatusID` and `eMoneyClientBalance.AccountStatus` throughout the eMoney analytics layer. The table is effectively static - the last UpdateDate is 2023-06-12. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `AccountStatusID` COMMENT 'Lookup identifier. Primary key. 0=Active, 1=Suspended, 2=Deleted. (Tier 1 - Dictionary.AccountStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `AccountStatus` COMMENT 'Human-readable name for this value. 0=Active, 1=Suspended, 2=Deleted. (Tier 1 - Dictionary.AccountStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `AccountStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `AccountStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
