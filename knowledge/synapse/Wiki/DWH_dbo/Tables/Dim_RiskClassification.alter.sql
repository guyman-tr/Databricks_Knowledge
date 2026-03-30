-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_RiskClassification
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification SET TBLPROPERTIES (
    'comment' = 'Dim_RiskClassification defines the 6 overall risk classification levels for customer accounts. Each level has a numeric RiskScore enabling quantitative comparison: Low (0) < Medium Low (25) < Medium (50) < Medium High (75) < High (100) < Unacceptable (200). (Tier 1 - upstream wiki, Dictionary.RiskClassification) Risk classification drives trading restrictions, deposit limits, and compliance review requirements. Customers with higher classifications may face reduced leverage, enhanced due diligence, or blocked access. The RiskCalculation schema computes classifications based on regulatory context (e.g., RiskCalculation.SetRiskClassificationForCySec) and stores them on BackOffice.Customer in two columns: RiskClassificationID (ongoing) and OnboardingRiskClassificationID (initial at registration). Note: The DWH renames the production `Name` column to `RiskClassificationName`. No other DWH objects in the DWH_dbo schema reference this table directly - it is available for joins from fact tables that carry RiskCla...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (RiskClassificationID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskClassificationID COMMENT 'Primary key (nullable in DDL per REPLICATE pattern). 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low. Referenced by CustomerStatic.RiskClassificationID and OnboardingRiskClassificationID. (Tier 1 - upstream wiki, Dictionary.RiskClassification)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskClassificationName COMMENT 'Human-readable classification label. Renamed from production `Name` column by ETL. Values: High, Medium, Low, Unacceptable, Medium High, Medium Low. (Tier 1 concept, Tier 2 - SP_Dictionaries_DL_To_Synapse rename)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskScore COMMENT 'Numeric score for ordered risk comparison. Higher = higher risk. Range: 0 (Low) to 200 (Unacceptable). Use this column for severity ordering, NOT RiskClassificationID. (Tier 1 - upstream wiki, Dictionary.RiskClassification)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN UpdateDate COMMENT 'GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskClassificationName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN RiskScore SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:33 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 10/10 succeeded
-- ====================
