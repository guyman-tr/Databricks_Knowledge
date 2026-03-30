-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PlayerStatusReasons
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons SET TBLPROPERTIES (
    'comment' = 'Dim_PlayerStatusReasons is the first level of a two-tier reason classification hierarchy for account status changes. When an account is blocked, suspended, restricted, or closed, the system records both the new status (Dim_PlayerStatus) and the broad reason category for the change. This table provides that top-level category. The 44 reason codes (IDs 0-43) span the full range of account status change triggers: compliance/AML investigations (IDs 6, 10, 11, 18), KYC failures (1, 2, 39), risk flags (4, 7, 14, 25, 34, 35), fraud/chargebacks (5, 23, 24, 30-32), user-initiated actions (3, 20, 21, 22), payment issues (13, 16, 17, 38), and administrative decisions (8, 9, 12, 19, 37, 40-43). ID=0 (None) is the default when no reason has been explicitly recorded. This table works as a hierarchy with Dim_PlayerStatusSubReasons -- Reason gives the broad category (e.g., "Chargeback"), and SubReason provides granular detail (e.g., "ACH CHBK", "Credit Card CHBK"). Dim_Customer and Fact_SnapshotCustomer store both PlayerS...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PlayerStatusReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN PlayerStatusReasonID COMMENT 'Primary key identifying the account status change reason. Range 0-43. 0=None (no reason -- real production row, not a DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Represents first-level classification in the Reason->SubReason hierarchy. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN Name COMMENT 'Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share the same timestamp per reload (2026-03-11 as of last load). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN PlayerStatusReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:25:40 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
