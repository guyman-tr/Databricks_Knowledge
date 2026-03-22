-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ThreeDsResponseTypes
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_ThreeDsResponseTypes` is a 15-row reference table classifying the outcomes of 3D Secure (3DS) credit card authentication during deposit transactions. 3DS is the industry standard for strong customer authentication (Visa Secure, Mastercard Identity Check). When customers make credit card deposits, the platform runs a two-phase 3DS flow: an **Enrollment** phase checking if the card supports 3DS, and an **Authentication** phase where the cardholder verifies their identity. Source: `etoro.Dictionary.ThreeDsResponseTypes` on etoroDB-REAL. The Generic Pipeline exports this daily to the Bronze data lake, where it is staged into `DWH_staging.etoro_Dictionary_ThreeDsResponseTypes`. `SP_Dictionaries_DL_To_Synapse` loads from that staging table using a TRUNCATE + INSERT pattern. In DWH, this dimension supports deposit analytics — categorizing card declines by 3DS reason (fraud monitoring, PSP troubleshooting, risk reporting). The column name differs from source: `Name` in `Dictionary.ThreeDsResponseTypes...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED (ThreeDsResponseTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN ThreeDsResponseTypeID COMMENT 'Primary key for the 3DS authentication outcome. Clustered index key. 0=Unspecified, 1=Success, 2=Failed Signature, 3=Not Enrolled, 4=Enrollment Unavailable, 5=Bypassed Enrollment, 6=Enrollment Error, 7=Timeout, 8=Failed Authentication, 9=Authentication Error, 10=Authentication Unavailable, 11=Bypassed Authentication, 12=Missing Authentication, 13=Skipped 3ds, 14=Unexpected. Referenced via the XML-extracted `ThreeDsResponseType` column in Fact_BillingDeposit. (Tier 1 — upstream wiki, Dictionary.ThreeDsResponseTypes)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN ThreeDsResponseTypesName COMMENT 'Human-readable label for the 3DS outcome. Source column is `Name` in Dictionary.ThreeDsResponseTypes; renamed in DWH with plural suffix. Used in deposit reporting to display authentication outcomes. All 15 rows are populated despite nullable DDL. (Tier 1 — upstream wiki, Dictionary.ThreeDsResponseTypes)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN ThreeDsResponseTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN ThreeDsResponseTypesName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
