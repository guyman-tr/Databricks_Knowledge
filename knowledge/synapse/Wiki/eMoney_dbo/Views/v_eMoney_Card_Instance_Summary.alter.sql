-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.v_eMoney_Card_Instance_Summary
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary SET TBLPROPERTIES (
    'comment' = 'eMoney_dbo.v_eMoney_Card_Instance_Summary > Analytics-facing view of `eMoney_Card_Instance_Summary` exposing all columns except the PII field `MaskedPAN`. One row per card instance (CID may have multiple rows). Same row count as base table: 130,301 rows covering 94,556 distinct CIDs. CardCreateDate range 2020-11-10 to 2026-04-11. Use this view for all standard card instance analytics to avoid inadvertent PAN exposure. | Property | Value | |----------|-------| | **Schema** | eMoney_dbo | | **Object Type** | View | | **Base Table** | `eMoney_dbo.eMoney_Card_Instance_Summary` | | **Production Source** | FiatDwhDB.dbo.FiatCardInstances + FiatCardStatuses (via base table SP) | | **Refresh** | Reflects base table data; no separate refresh schedule. Base table refreshed daily via TRUNCATE+INSERT (SP_eMoney_Card_Instance_Summary). | | **Synapse Distribution** | Inherits from base table: HASH(CID'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary SET TAGS (
    'source_schema' = 'eMoney_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN ProviderHolderID COMMENT 'The external provider''s (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. DWH note: renamed from `ProviderHolderId`; CAST to INT. (Tier 1 - dbo.AccountsProviderHoldersMapping)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN FMI_Date COMMENT 'Date of the account''s first settled money-in transaction (TxTypeID IN [5,7], TxStatusID=2, HolderAmount != 0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for accounts that have never funded. Earliest value: 2020-11-10 (UK launch). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN DWH_CardID COMMENT 'Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. DWH note: renamed from CardID in eMoney_Dim_Account (originally FiatCards.Id). (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN ProviderCardID COMMENT 'Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN CardCreateDate COMMENT 'Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN IsValidETM COMMENT 'eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. 1=129,106 rows (99.1%), 0=1,195 (0.9%). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN GCID_Unique_Count COMMENT 'Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. DWH note: always 1 in this table - SP JOIN filters on GCID_Unique_Count=1. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN DWH_CardInstanceId COMMENT 'Auto-incrementing surrogate PK of the card instance. Referenced by FiatCardStatuses.CardInstanceId. DWH note: renamed from Id in dbo.FiatCardInstances. (Tier 1 - dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceStatus COMMENT 'Current lifecycle status of THIS specific card instance. Resolved via JOIN on eMoney_Dictionary_CardStatus (newest FiatCardStatuses event by EventTimestamp DESC). 0=NotActivated (32.9%), 1=Activated (29.8%), 2=Blocked (11.2%), 7=Expired (21.8%), 4=Risk, 5=Stolen (3.4%), 6=Lost (0.8%), 3=Suspended, 8=Fraud, NULL=0.1%. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceCreatedDate COMMENT 'Date the card instance was first issued - CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=0) AS DATE). First NotActivated event = card creation/delivery. NULL for 1,120 instances with no status history. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceActivationDate COMMENT 'Date the cardholder first activated this card instance - CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=1) AS DATE). NULL for 59,932 rows (45.9%) where the card was never activated by the cardholder. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceExpirationDate COMMENT 'Expiration date of this card instance. NULL for instances where expiration is not yet set. DWH note: CAST from datetime2 to DATE from FiatCardInstances.CardExpirationDate. (Tier 1 - dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN StatusByHighestRNDasc COMMENT 'Status of the customer''s most recently created card instance per DWH_CardID (highest RNDasc rank, ordered DESC). Same for all instances of the same DWH_CardID. Use this to assess the customer''s current card state across the full issuance history. Values: Activated (42.0%), Expired (28.6%), NotActivated (23.9%), Stolen (3.4%), Lost (1.0%), Blocked (0.9%). (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN NextActivationDateTime COMMENT 'Activation timestamp of the next card instance for this CID. NULL when this is the most recent activated instance (no successor). Used to define the upper bound of TxAfterActivationCount window. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN TxAfterActivationCount COMMENT 'Count of valid settled card transactions (IsValidETM=1, IsTxSettled=1, TxTypeID IN [1,2,3,4]) made by this CID after this instance''s ActivationDateTime and before NextActivationDateTime (or all time if NULL). Range: 0 - 4,150, avg 20.7. 0 for unactivated instances. (Tier 2 - SP_eMoney_Card_Instance_Summary)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN UpdateDate COMMENT 'Timestamp when this record was written by the SP. Set to GETDATE() at TRUNCATE+INSERT time. Reflects the daily SP run, not a business event. (Tier 2 - SP_eMoney_Card_Instance_Summary)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN ProviderHolderID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN FMI_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN DWH_CardID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN ProviderCardID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN CardCreateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN IsValidETM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN GCID_Unique_Count SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN DWH_CardInstanceId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceCreatedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceActivationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN InstanceExpirationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN StatusByHighestRNDasc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN NextActivationDateTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN TxAfterActivationCount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:19:25 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 9
-- Statements: 36/36 succeeded
-- ====================
