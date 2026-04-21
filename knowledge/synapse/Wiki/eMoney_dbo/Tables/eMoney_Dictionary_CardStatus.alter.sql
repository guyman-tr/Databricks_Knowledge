-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_CardStatus
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_CardStatus` is a lookup/reference table that defines the valid lifecycle states for eToro Money physical and virtual payment cards. Each row maps an integer ID to a human-readable status name. Card status controls whether the card can be used for transactions and - when restricted - the reason for the restriction. The 9 states span the full card lifecycle: from issuance before activation (`NotActivated`), through normal operation (`Activated`), temporary restrictions (`Blocked`, `Suspended`, `Risk`), permanent terminal states due to loss/theft/fraud (`Stolen`, `Lost`, `Fraud`), and natural expiry (`Expired`). Terminal states (Stolen, Lost, Expired, Fraud) cannot be reactivated - a replacement card must be issued. This dictionary is sourced directly from `FiatDwhDB.Dictionary.CardStatuses` via the Generic Pipeline Bronze export. Status changes in FiatDwhDB are tracked in `dbo.FiatCardStatuses` with EventTimestamp. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load, no subseque...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus SET TAGS (
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
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `CardStatusID` COMMENT 'Lookup identifier. Primary key. 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. (Tier 1 - Dictionary.CardStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `CardStatus` COMMENT 'Human-readable name for this value. 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. (Tier 1 - Dictionary.CardStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `CardStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `CardStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
