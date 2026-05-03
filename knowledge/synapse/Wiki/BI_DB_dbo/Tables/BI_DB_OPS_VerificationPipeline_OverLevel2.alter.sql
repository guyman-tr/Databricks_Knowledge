-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2 > 880K-row operations verification pipeline table tracking customers above verification level 1 within a 5-month rolling window. Classifies each customer into one of 16 verification outcome categories based on EV status, document uploads, screening hits, phone/email verification, and risk alerts. Daily TRUNCATE+INSERT via SP_OPS_VerificationPipeline_Level2. Registrations from Nov 2025 to present. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Dim_Customer (primary) via `SP_OPS_VerificationPipeline_Level2` | | **Refresh** | Daily (TRUNCATE+INSERT, 5-month rolling window from first day of current month minus 5 months) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **UC Target** | `_Not_Migrated` | | **UC Format** | - | | **UC P'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN EvMatchStatusName COMMENT 'Human-readable label for the EV match status. Renamed from Name in production source. Values: None, PartiallyVerified, Verified, NotVerified. Passthrough from Dim_EvMatchStatus. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values in this table: 2 (intermediate) or 3 (fully verified). Passthrough from Dim_Customer. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Country COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN TotalHits COMMENT 'Total screening hits from the main screening provider. Higher values indicate more potential matches requiring review. NULL if no screening record. (Tier 2 - SP_OPS_VerificationPipeline_Level2, ScreeningService)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN PhoneVerifiedName COMMENT 'Human-readable verification state label. Note: ID=2 has value "ManualyVerified" - a production typo (single ''l'') preserved verbatim from etoro.Dictionary.PhoneVerified. Passthrough from Dim_PhoneVerified. (Tier 1 - Dictionary.PhoneVerified)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN IsEmailVerified COMMENT 'Raw email verification flag from Dim_Customer. 1=verified, 0=not verified. Passthrough from Dim_Customer. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN IsManual COMMENT '1 if screening case was manually resolved by a human agent (ProviderUsername != automated compliance bot); 0 if auto-resolved; NULL if no screening record. (Tier 2 - SP_OPS_VerificationPipeline_Level2, ScreeningService)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN DDCategoryVL2toVL3 COMMENT 'Time bucket for VL2 -> VL3 transition duration. Values: VL3<=3minutes, VL3<=5minutes, VL3<=10minutes, VL3<=20minutes, VL3<=1Hour, 1Hour<VL3<=24Hours, 1Day<VL3<=7Days, 7Days<VL3<=14Days, 14Days<VL3<=30Days, VL3>30Days, NotCompleted. Derived from History_BackOfficeCustomer VL change timestamps. (Tier 2 - SP_OPS_VerificationPipeline_Level2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN ScreeningStatus COMMENT 'Screening service result from Dim_ScreeningStatus. Key value: ''NoMatch'' = clear. NULL if no screening record. (Tier 2 - SP_OPS_VerificationPipeline_Level2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RegisteredReal COMMENT 'Account registration date (renamed from Registered). Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Category COMMENT 'Verification pipeline outcome classification. 16 distinct values diagnosing exactly why a customer is at their current VL state. See Section 2.1 for full breakdown. NULL for unclassified edge cases. (Tier 2 - SP_OPS_VerificationPipeline_Level2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RiskAlerts COMMENT '1 if customer has Relations or HighRiskLogin alerts in BI_DB_RiskAlertManagementTool; 0 otherwise. Stored as varchar despite being binary. (Tier 2 - SP_OPS_VerificationPipeline_Level2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 2 - SP_OPS_VerificationPipeline_Level2)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN EvMatchStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN TotalHits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN PhoneVerifiedName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN IsEmailVerified SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN IsManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN DDCategoryVL2toVL3 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN ScreeningStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Category SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN RiskAlerts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2 ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:10:57 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
