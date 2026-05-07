-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.V_BI_DB_BO_Generated_Compensations
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.V_BI_DB_BO_Generated_Compensations **Schema**: BI_DB_dbo | **UC Target**: `general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations` **Row count**: ~27.5M (2021-01-01 -> 2026-05-06) | **Refresh**: daily (Append generic pipeline) **Type**: VIEW | **Base table**: `BI_DB_dbo.BI_DB_BO_Generated_Compensations` ---'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN CID COMMENT 'Customer ID who received the compensation. Joins to `DWH_dbo.Dim_Customer.CID`. Distribution column on the base table.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Amount COMMENT 'Compensation amount in customer-account currency (typically USD). CAST from `History.Credit.Payment`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Type COMMENT 'Credit type label - always ''Compensation'' (CreditTypeID=6 filter applied at SP). LTRIM/RTRIM applied.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Time COMMENT 'Datetime of the compensation event. From `History.Credit.Occurred`. Primary event timestamp for analytics.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Description COMMENT 'Free-text compensation description entered by the back-office agent. May be empty.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Category COMMENT 'Compensation category label from the BO `CompensationReason` dictionary. NULL if `CompensationReasonID` not resolvable.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Reason COMMENT 'Secondary reason label from `DWH_dbo.Dim_MoveMoneyReason`. ~87% NULL - only set when `MoveMoneyReasonID` is non-null on the source row.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Manager COMMENT 'BO agent who issued the compensation - `CONCAT(FirstName, '''', LastName)` (no space - known SP bug). Use as opaque string.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Affiliate COMMENT 'Affiliate ID associated with the customer at compensation time. From `Dim_Customer.AffiliateID`. NULL for unaffiliated customers.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Player_level COMMENT 'Customer player-level name at compensation time (e.g., ''Bronze'', ''Silver'', ''Platinum''). Renamed from base `[Player Level]`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Country_Reg_Form COMMENT 'Country name from customer''s registration form (full name, NOT ISO code). Renamed from base `[Country (Reg Form)]`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction of the customer''s account (e.g., ''CySEC'', ''FCA'', ''ASIC'', ''FSA Seychelles'').';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN UpdateDate COMMENT 'Datetime when this row was inserted by the writer SP (`GETDATE()` at INSERT). ETL metadata, not the event time.';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Type SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Time SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Description SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Category SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Reason SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Affiliate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Player_level SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Country_Reg_Form SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:26:16 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 5
-- Statements: 28/28 succeeded
-- ====================
