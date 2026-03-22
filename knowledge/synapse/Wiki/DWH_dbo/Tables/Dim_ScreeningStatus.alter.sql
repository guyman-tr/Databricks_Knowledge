-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ScreeningStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus SET TBLPROPERTIES (
    'comment' = 'Dim_ScreeningStatus defines the 8 possible outcomes of a customer identity screening check against AML (Anti-Money Laundering) and compliance databases - including sanctions lists, PEP (Politically Exposed Person) registries, and adverse media risk databases. (Tier 3 - live data inferred from values; no upstream wiki found) When a customer is onboarded or reviewed, their identity is screened by the ScreeningService (a dedicated compliance microservice, separate from the core etoro platform). The result is stored as a ScreeningStatusID on the customer record. Statuses range from clean (NoMatch=1, no risk identified) through various alert levels (PEP=3, RiskMatch=4, SanctionsMatch=7) to process states (PendingInvestigation=2, Technical=5, MultipleMatch=6). Notably, this table''s source is `ScreeningService.Dictionary.ScreeningStatus` from `ScreeningServiceDB` - not the standard etoro Dictionary database used by most Dim_ tables. The staging table is `DWH_staging.ScreeningService_Dictionary_ScreeningStatus` (n...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ScreeningStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN ScreeningStatusID COMMENT 'Primary key for screening outcome. Renamed from production `ID` column by ETL. 0=Unknown, 1=NoMatch, 2=PendingInvestigation, 3=PEP, 4=RiskMatch, 5=Technical, 6=MultipleMatch, 7=SanctionsMatch. (Tier 2 - SP code rename from ID; Tier 3 - live data values)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN Name COMMENT 'Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. (Tier 3 - live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN UpdateDate COMMENT 'GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN ScreeningStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
