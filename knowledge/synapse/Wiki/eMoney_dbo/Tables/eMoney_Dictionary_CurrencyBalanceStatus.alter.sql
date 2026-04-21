-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_CurrencyBalanceStatus` is a lookup/reference table that defines the valid operational states for a specific currency balance within an eToro Money account. Each row maps an integer ID to a human-readable status name. Currency balance status controls what types of money movement are permitted for that balance - making it a key compliance and risk control mechanism. The 5 states span from full operational access (`Active`) through partial restrictions (`ReceiveOnly`, `SpendOnly`) to complete freezes (`Suspended`, `Blocked`). `ReceiveOnly` and `SpendOnly` are partial restriction states used during account wind-down or migration scenarios. `Blocked` typically indicates a compliance or legal hold. Status changes in FiatDwhDB are tracked in `dbo.FiatCurrencyBalancesStatuses` with source and reason. This dictionary is sourced from `FiatDwhDB.Dictionary.CurrencyBalanceStatuses` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load). Synapse: REPLICATE...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `CurrencyBalanceStatusID` COMMENT 'Lookup identifier. Primary key. 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. (Tier 1 - Dictionary.CurrencyBalanceStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `CurrencyBalanceStatus` COMMENT 'Human-readable name for this value. 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. (Tier 1 - Dictionary.CurrencyBalanceStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `CurrencyBalanceStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `CurrencyBalanceStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
