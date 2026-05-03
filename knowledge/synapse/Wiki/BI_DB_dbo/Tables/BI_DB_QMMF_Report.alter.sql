-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_QMMF_Report
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_QMMF_Report > ~1.19B-row daily compliance interaction table tracking QMMF (Qualifying Money Market Funds) customer responses from ComplianceStateDB. Populated by `SP_QMMF_Report` via DELETE+INSERT per date. Contains 898K distinct GCIDs from 2023-08-06 to present, capturing interaction clicks, answers (Yes/No), club tier, and interest opt-in status. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ComplianceStateDB.Compliance (external tables) via `SP_QMMF_Report` | | **Refresh** | Daily (DELETE+INSERT per LastInteractionDate) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **UC Target** | `_Not_Migrated` | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | | **Row Count** | ~1,191,268,551 (daily snapshots, 2023-08-06 to 2026-04-12) | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN GCID COMMENT 'Global Customer ID from ComplianceStateDB.Compliance.CustomerInteractions. Identifies the customer across compliance interaction flows. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN Count_Clicks COMMENT 'Number of interaction action counts for this GCID on this interaction. Sourced from CustomerInteractionActionCounts.Count. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN FirstInteractionDate COMMENT 'Date of the first interaction action for this customer-interaction pair. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN LastInteractionDate COMMENT 'Date of the most recent interaction action for this customer-interaction pair. Used as the partition key for DELETE+INSERT. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionActionId COMMENT 'Interaction action type: 1=Open, 14=Accept, 15=Decline. Filtered from ComplianceStateDB UserInteractionDetails. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionTypeId COMMENT 'Interaction type identifier. Always 7 in observed data. From ComplianceStateDB UserInteractionDetails. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionId COMMENT 'User interaction definition ID. Always 39 (QMMF flow) due to SP filter. From ComplianceStateDB UserInteractionDetails. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN CustomerInteractionId COMMENT 'Unique customer interaction instance ID. FK to ComplianceStateDB CustomerInteractionActionCounts. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN StateAdditionalData COMMENT 'Customer''s QMMF answer: ''Answer-Yes'', ''Answer-No'', or empty string. From ComplianceStateDB CustomerInteractions.StateAdditionalData. (Tier 2 - SP_QMMF_Report, ComplianceStateDB)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UpdateDate COMMENT 'SP execution date (@Date parameter). All rows for a given LastInteractionDate share the same UpdateDate. (Tier 5 - ETL metadata)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN Club COMMENT 'eToro Club tier at the time of LastInteractionDate: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Resolved via Dim_Customer -> Fact_SnapshotCustomer -> Dim_PlayerLevel.Name at the interaction date. (Tier 2 - SP_QMMF_Report, Dim_PlayerLevel)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN InterestOnBalance_Opt_In COMMENT 'Interest on balance consent flag. 1 if latest ConsentStatusID=1 in External_Interest_Trade_InterestConsent (partitioned by CID, ordered by ValidFrom DESC), else 0. (Tier 2 - SP_QMMF_Report, Interest.InterestConsent)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN Count_Clicks SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN FirstInteractionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN LastInteractionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionActionId SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionTypeId SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UserInteractionId SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN CustomerInteractionId SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN StateAdditionalData SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_qmmf_report ALTER COLUMN InterestOnBalance_Opt_In SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:13:11 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 26/26 succeeded
-- ====================
