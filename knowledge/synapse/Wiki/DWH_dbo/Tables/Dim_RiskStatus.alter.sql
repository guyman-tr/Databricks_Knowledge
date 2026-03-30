-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_RiskStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus SET TBLPROPERTIES (
    'comment' = 'Dim_RiskStatus defines specific risk flags or reasons attached to individual customer accounts. Unlike Dim_RiskClassification (overall customer risk level) or Dim_RiskManagementStatus (per-deposit check outcome), Dim_RiskStatus captures the granular *reason* for a customer risk flag - e.g., OverTheLimit (2), BinToRegCountryConflict (6), Affiliate Multiple Accounts (10), High Risk Account Country (17), FundingStolenReportedByProcessor, CreditCardBruteForce. (Tier 1 - upstream wiki, Dictionary.RiskStatus) RiskStatusID is stored on BackOffice.Customer and indicates the most recent primary risk reason. BackOffice procedures track risk status changes over time. History.RiskStatus logs all historical changes. Billing.FundingCustomerRisk links a RiskStatusID to funding/customer combinations at risk events. The DWH version has 90 rows (IDs 0-90, with gaps), with 74 active and 16 inactive. Inactive rows (IsActive=False) represent legacy or deprecated risk flags - e.g., CHBK CAL (15), CHBK Leumi (16), CHBK B&S (18),...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (RiskStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN RiskStatusID COMMENT 'Primary key identifying the risk flag reason. 0=None, 1=Normal, 2=OverTheLimit, 3=FTDOverDailyLimit, 4=TooManyCreditCards, 5=Too Many PayPal Accounts, 6=BinToRegCountryConflict, 7=DepositNameConflict, 8=LoginToRegCountryConflict, 10=Affiliate Multiple Accounts, 17=High Risk Account Country, and many more up to ID 90. Stored in BackOffice.Customer.RiskStatusID. (Tier 1 - upstream wiki, Dictionary.RiskStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN Name COMMENT 'Human-readable risk flag name. Mix of PascalCase codes and plain English (e.g., "Too Many PayPal Accounts", "Negative Paramaters Relations"). Used in risk reports, compliance alerts, and BackOffice dashboards. (Tier 1 - upstream wiki, Dictionary.RiskStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN IsActive COMMENT 'Whether this risk flag is currently in use. True=active (74 rows), False=deprecated/legacy (16 rows, mostly CHBK-related). Filter on IsActive=1 for current risk analysis. (Tier 1 - upstream wiki, Dictionary.RiskStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN DWHRiskStatusID COMMENT 'ETL-computed alias of RiskStatusID - always equals RiskStatusID. `[RiskStatusID] as [DWHRiskStatusID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field. Use RiskStatusID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN StatusID COMMENT 'Hardcoded 1 (Active) for all rows by ETL. Not present in production Dictionary.RiskStatus. Distinct from IsActive. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN UpdateDate COMMENT 'GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN InsertDate COMMENT 'GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate (TRUNCATE+INSERT pattern). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN DWHRiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:46 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 16/16 succeeded
-- ====================
