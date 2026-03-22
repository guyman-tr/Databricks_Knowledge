-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PhoneVerified
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified SET TBLPROPERTIES (
    'comment' = 'Dim_PhoneVerified is a 6-row dictionary defining the phone number verification lifecycle states used in eToro''s KYC (Know Your Customer) process. Phone verification is a key identity check -- customers must prove ownership of their registered phone number to complete account verification and enable certain platform features. The states cover the full lifecycle: from not yet started (ID=0), through initiation (ID=3), to successful outcomes (IDs 1 and 2), to failed outcomes (ID=4) and abuse detection (ID=5). The data originates from `etoro.Dictionary.PhoneVerified` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PhoneVerified/` in the data lake, with UC Bronze table `general.bronze_etoro_dictionary_phoneverified`. Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_PhoneVerified`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale, consistent with th...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PhoneVerifiedID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN PhoneVerifiedID COMMENT 'Primary key identifying the phone verification state. 0=NotVerified (default), 1=AutomaticallyVerified, 2=ManualyVerified (BO agent -- note production typo), 3=Initiated (in-progress), 4=Rejected (failed), 5=AbuseFlag (fraud detected). Stored in Dim_Customer. Referenced by 20+ procedures across BackOffice, Customer, SalesForce, and dbo schemas. (Tier 1 - upstream wiki, Dictionary.PhoneVerified)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN PhoneVerifiedName COMMENT 'Human-readable verification state label. Note: ID=2 has value "ManualyVerified" -- a production typo (single ''l'') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards. (Tier 1 - upstream wiki, Dictionary.PhoneVerified)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN PhoneVerifiedID SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN PhoneVerifiedName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
