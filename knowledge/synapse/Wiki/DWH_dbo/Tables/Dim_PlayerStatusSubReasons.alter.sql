-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PlayerStatusSubReasons
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons SET TBLPROPERTIES (
    'comment' = 'Dim_PlayerStatusSubReasons provides the second level of detail for account status changes, working beneath Dim_PlayerStatusReasons. While the Reason gives the broad category (e.g., "Chargeback"), the SubReason gives the specific detail (e.g., "ACH CHBK", "Credit Card CHBK", "PayPal CHBK"). This two-level classification gives compliance, risk, and operations teams the granularity needed for investigation tracking and reporting. The 83 sub-reasons (IDs 0-82) span: fraud types (Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party), verification failures (Failed Verification, POI/POA Required), chargeback sources (ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK -- 11 variants), screening results (Sanctions, PEP, WCH matches), AML triggers (Investigation, AML Trigger, SAR filed, Law enforcement request), regulatory (FATCA, CRS, W-8BEN, corporate LEI), and operational states (1st Warning, 2nd Warning, Vulnerable Client). This table is always used together with Dim_PlayerStatusReasons -- both IDs are stored on...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PlayerStatusSubReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN PlayerStatusSubReasonID COMMENT 'Primary key identifying the granular sub-reason (NOTE: DDL allows NULL -- unusual for a PK). Range 0-82. 0=None (real production row, not DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Provides second-level detail beneath PlayerStatusReasonID. (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN PlayerStatusSubReasonName COMMENT 'Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share same timestamp per reload (2026-03-11 as of last load). Also nullable in DWH DDL. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN PlayerStatusSubReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN PlayerStatusSubReasonName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:25:43 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
