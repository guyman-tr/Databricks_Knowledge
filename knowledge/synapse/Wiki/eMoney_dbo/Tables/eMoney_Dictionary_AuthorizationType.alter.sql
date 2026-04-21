-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_AuthorizationType
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_AuthorizationType` is a lookup/reference table that defines the valid values for card transaction authorization type in the eToro Money fiat platform. Each row maps an integer ID to a human-readable name. Authorization type classifies how a card transaction was authorized by the payment network - determining the authorization flow, hold behavior, and settlement rules for each transaction event. The 15 values cover the full lifecycle: standard purchases (Normal), pre-authorization flows (PreAuthorize -> Incremental -> FinalAuthorize), specialized merchant scenarios (Instalment, PreferredCustomer, Recurring, DelayedCharges, NoShow), network messages (AuthorizeAdvice), and reversal/return operations (Refund, Reversal, SysReversal). AccountFunding (14) covers card-load operations. This dictionary is sourced directly from `FiatDwhDB.Dictionary.AuthorizationTypes` via the Generic Pipeline Bronze export and materialized into Synapse DWH. All rows carry the same UpdateDate (2023-06-12 03:48:01) in...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype SET TAGS (
    'domain' = 'general',
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
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `AuthorizationTypeID` COMMENT 'Lookup identifier. Primary key. 0=Unknown, 1=Normal, 2=PreAuthorize, 3=FinalAuthorize, 4=Incremental, 5=Instalment, 6=PreferredCustomer, 7=Recurring, 8=DelayedCharges, 9=NoShow, 10=AuthorizeAdvice, 11=Refund, 12=Reversal, 13=SysReversal, 14=AccountFunding. (Tier 1 - Dictionary.AuthorizationTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `AuthorizationType` COMMENT 'Human-readable name for this value. 0=Unknown, 1=Normal, 2=PreAuthorize, 3=FinalAuthorize, 4=Incremental, 5=Instalment, 6=PreferredCustomer, 7=Recurring, 8=DelayedCharges, 9=NoShow, 10=AuthorizeAdvice, 11=Refund, 12=Reversal, 13=SysReversal, 14=AccountFunding. (Tier 1 - Dictionary.AuthorizationTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `AuthorizationTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `AuthorizationType` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
