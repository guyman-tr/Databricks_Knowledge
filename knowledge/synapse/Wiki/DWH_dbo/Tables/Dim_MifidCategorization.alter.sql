-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_MifidCategorization
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_MifidCategorization` maps the MiFID II customer classification IDs used throughout the eToro platform to human-readable tier names. MiFID II (Markets in Financial Instruments Directive II) is the EU regulatory framework governing retail and professional financial clients. Customer classification determines leverage caps, margin requirements, negative balance protection eligibility, and disclosure obligations. The 6 rows define the complete classification space: | ID | Name | Meaning | |----|------|---------| | 0 | None | Not classified / not applicable (e.g., US customers not subject to MiFID) | | 1 | Retail | Standard retail client -- maximum investor protection, lowest leverage limits | | 2 | Professional | Institutional or experienced investor -- lower protection, higher leverage allowed | | 3 | Elective professional | Retail client who has applied for professional status (opted-up) | | 4 | Retail Pending | Retail classification in progress (e.g., registration not yet complete) | | 5 | Pend...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (MifidCategorizationID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN MifidCategorizationID COMMENT 'MiFID II client classification tier: 0=None (non-EU), 1=Retail (full protection, default), 2=Professional (reduced protection), 3=Elective Professional (opted-in retail), 4=Retail Pending (under review), 5=Pending (assessment incomplete). Referenced by BackOffice.Customer.MifidCategorizationID (FK, DEFAULT 1) and History.BackOfficeCustomer. Feeds into computed column TradingRiskStatusID. (Tier 1 - Dictionary.MifidCategorization)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN Name COMMENT 'Human-readable classification label. Used in compliance dashboards and regulatory reports. (Tier 1 - Dictionary.MifidCategorization)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
