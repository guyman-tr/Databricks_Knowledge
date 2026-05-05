-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.v_eMoney_Card_Instance_Summary
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `CID` COMMENT 'eToro trading platform customer ID (RealCID from Dim_Customer). Used as the Synapse HASH distribution key on the base table. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `ProviderHolderID` COMMENT 'Provider-side holder identifier for this account (Tribe''s holder ID). Passthrough from eMoney_Dim_Account.ProviderHolderID. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `FMI_Date` COMMENT 'First Money In date. Date of the customer''s first settled incoming transaction (TxStatusID=2) of type TransferReceived (TxTypeID=5) or PaymentReceived (TxTypeID=7) with non-zero HolderAmount. NULL if no qualifying incoming transaction. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `DWH_CardID` COMMENT 'Auto-incrementing surrogate PK of the logical card in FiatCards. The most recent card associated with this account. Renamed from eMoney_Dim_Account.CardID (FiatDwhDB.dbo.FiatCards.Id). (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `ProviderCardID` COMMENT 'Provider-side card identifier (Tribe''s internal card ID). Passthrough from eMoney_Dim_Account.ProviderCardID. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `CardCreateDate` COMMENT 'Date portion of CardCreateTime. ETL-derived CAST. Passthrough from eMoney_Dim_Account.CardCreateDate. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `IsValidETM` COMMENT '1 if the customer qualifies as a valid eToro Money customer (IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0), else 0. Primary filter for production analytics. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `GCID_Unique_Count` COMMENT 'Row number within the customer partition (GCID) ordered by AccountCreateTime descending. 1 = the customer''s most recently created currency balance. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `DWH_CardInstanceId` COMMENT 'Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId. Renamed from FiatCardInstances.Id. (Tier 1 - FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceStatus` COMMENT 'Current status of this card instance. ETL-computed as the most recent CardStatus label (TOP 1 ordered by EventTimestamp DESC) from FiatCardStatuses, resolved via eMoney_Dictionary_CardStatus. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceCreatedDate` COMMENT 'Date the card instance was created (first status event, CardStatusId=0). ETL-computed as MIN(EventTimestamp WHERE CardStatusId=0) CAST to DATE. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceActivationDate` COMMENT 'Date the card instance was activated (first activation event, CardStatusId=1). ETL-computed as MIN(EventTimestamp WHERE CardStatusId=1) CAST to DATE. NULL if not yet activated. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceExpirationDate` COMMENT 'Expiration date of this card instance. NULL for instances where expiration is not yet set. Renamed from FiatCardInstances.CardExpirationDate; CAST to DATE. (Tier 1 - FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `StatusByHighestRNDasc` COMMENT 'Status label of the most recently issued card instance for the parent CardID (highest activation-order rank = RNDasc). Enables card-level current status reporting across all historical instances. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `NextActivationDateTime` COMMENT 'Activation datetime of the next card instance for the same DWH_CardID. NULL for the most recently issued instance. Used as the upper bound for TxAfterActivationCount. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `TxAfterActivationCount` COMMENT 'Count of settled qualifying card transactions (TxTypeID IN 1,2,3,4) within this instance''s active window. NULL when NextActivationDateTime IS NULL (current active instance). (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `UpdateDate` COMMENT 'ETL load timestamp from the base table''s last TRUNCATE + INSERT run. (Tier 2 - SP_eMoney_Card_Instance_Summary)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `ProviderHolderID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `FMI_Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `DWH_CardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `ProviderCardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `CardCreateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `IsValidETM` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `GCID_Unique_Count` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `DWH_CardInstanceId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceCreatedDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceActivationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `InstanceExpirationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `StatusByHighestRNDasc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `NextActivationDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `TxAfterActivationCount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:27:55 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 10
-- Statements: 36/36 succeeded
-- ====================
