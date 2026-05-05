-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN > 2.98M-row mapping table linking positions opened directly from IBAN bank account deposits with their corresponding DepositID. Used for tracing which opened positions were funded via IBAN deposits. Sourced from an external finance BI output table, deduplicated via `Dim_Position` and `Fact_BillingDeposit` CID matching. Refreshed daily via `SP_Positions_Opened_From_IBAN` (TRUNCATE+INSERT). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `External_bi_output_finance_bi_db_positions_opened_from_iban_parquet` (external table) -> deduplicated via `DWH_dbo.Dim_Position` + `DWH_dbo.Fact_BillingDeposit` | | **Writer SP** | `BI_DB_dbo.SP_Positions_Opened_From_IBAN` (Guy Manova 2025-03-19, updated 2025-07-21) | | **Refresh** | Daily, TRUNCATE+INSERT | | **Synapse Distribution** | HAS'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN PositionID COMMENT 'Trading position that was opened directly from an IBAN bank account deposit. Distribution key. Deduplicated via CID matching against Dim_Position and Fact_BillingDeposit. (Tier 2 - SP_Positions_Opened_From_IBAN)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN DepositID COMMENT 'Corresponding deposit record in the billing system (Fact_BillingDeposit). Links the opened position to its IBAN deposit funding transaction. (Tier 2 - SP_Positions_Opened_From_IBAN)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN UpdateDate COMMENT 'Row load timestamp. GETDATE() at insert time. (Tier 3 - SP_Positions_Opened_From_IBAN, GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:34:29 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 8/8 succeeded
-- ====================
