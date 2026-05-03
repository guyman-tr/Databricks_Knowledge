-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN > 3.16M-row mapping table linking positions closed directly to IBAN bank accounts with their corresponding WithdrawPaymentID. Used for tracing which closed positions triggered IBAN withdrawals. Sourced from an external finance BI output table, deduplicated via `Dim_Position` and `Fact_BillingWithdraw` CID matching. Refreshed daily via `SP_Positions_Closed_To_IBAN` (TRUNCATE+INSERT). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `External_bi_output_finance_bi_db_positions_closed_to_iban_parquet` (external table) -> deduplicated via `DWH_dbo.Dim_Position` + `DWH_dbo.Fact_BillingWithdraw` | | **Writer SP** | `BI_DB_dbo.SP_Positions_Closed_To_IBAN` (Guy Manova 2025-03-19, updated 2025-07-21) | | **Refresh** | Daily, TRUNCATE+INSERT | | **Synapse Distribution** | HASH (Position'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN PositionID COMMENT 'Trading position that was closed directly to an IBAN bank account. Distribution key. Deduplicated via CID matching against Dim_Position and Fact_BillingWithdraw. (Tier 2 - SP_Positions_Closed_To_IBAN)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN WithdrawPaymentID COMMENT 'Corresponding withdrawal payment record in the billing system (Fact_BillingWithdraw). Links the closed position to its IBAN withdrawal transaction. (Tier 2 - SP_Positions_Closed_To_IBAN)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN UpdateDate COMMENT 'Row load timestamp. GETDATE() at insert time. (Tier 3 - SP_Positions_Closed_To_IBAN, GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:12:50 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 8/8 succeeded
-- ====================
