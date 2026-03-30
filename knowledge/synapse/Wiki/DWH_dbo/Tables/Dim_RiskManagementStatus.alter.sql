-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_RiskManagementStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus SET TBLPROPERTIES (
    'comment' = 'Dim_RiskManagementStatus defines the outcome status of deposit risk management checks. When a deposit is attempted, the payment risk engine evaluates it against multiple rules and assigns a RiskManagementStatusID to the deposit. Status 1 (Success) means the deposit passed all checks. All other statuses (IDs 2-69) identify a specific block or decline reason - card velocity, BIN blacklists, geographic restrictions, KYC level insufficiency, fraud signals (ML, Sift), or business rules. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus) This table is the central enumeration for all deposit risk decisions. Billing.Deposit stores RiskManagementStatusID per deposit, making this dimension essential for any deposit risk analytics in the DWH. The DWH has 70 rows (IDs 0-69). ID=0 (N/A) is a sentinel row with midnight timestamp, likely representing deposits where no risk check was performed. Production Dictionary.RiskManagementStatus has 69 rows (IDs 1-69). The DWH ETL adds DWHRiskManagementStatusID (= ID alias)...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (RiskManagementStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN RiskManagementStatusID COMMENT 'Primary key identifying the deposit risk check outcome. 0=N/A (sentinel), 1=Success, 2-69=specific block/decline reason. See Section 2.1 for key values. Referenced by Billing.Deposit.RiskManagementStatusID. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN Name COMMENT 'Internal code name for the risk outcome. Used in analytics and risk dashboards. Values include: Success, CardIsBlocked, BinInBlackList, MemberLimit, FundingTypeLimit, DeclinedHighRiskDeposit, DeclinedBlackListCountry, KYCLevel0-3, ML, ThreeDsVerificationFail, BusinessRuleRisk, and others. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN DWHRiskManagementStatusID COMMENT 'ETL-computed alias of RiskManagementStatusID - always equals RiskManagementStatusID. `[RiskManagementStatusID] as [DWHRiskManagementStatusID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field. Use RiskManagementStatusID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN StatusID COMMENT 'Hardcoded 1 (Active) for all rows by ETL. Not present in production Dictionary.RiskManagementStatus. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN UpdateDate COMMENT 'GETDATE() at SP_Dictionaries reload time for IDs 1-69. ID=0 has midnight (00:00:00) timestamp - sentinel row behavior. (Tier 2 - SP_Dictionaries_DL_To_Synapse; Tier 3 - live data for ID=0 anomaly)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN InsertDate COMMENT 'GETDATE() at SP_Dictionaries reload time for IDs 1-69. ID=0 has midnight (00:00:00). Same pattern as UpdateDate. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN RiskManagementStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN DWHRiskManagementStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:39 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
