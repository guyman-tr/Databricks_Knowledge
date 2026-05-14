-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Funnel
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel SET TBLPROPERTIES (
    'comment' = '`Dim_Funnel` is an acquisition channel dimension mapping 129 funnel IDs (range -9 to 130) to the registration surface or product entry point through which an eToro customer first arrived. Funnels represent web pages, mobile apps, partner sites, and internal tools. **FunnelID=-9 (AutomationTest)** and **FunnelID=0 (Unknown)** are special sentinel values. SP_Dim_Customer uses `ISNULL(FunnelID, 0)` coercing NULLs to 0 (Unknown). `PlatformID` classifies the broad channel: - 0 = Unspecified/internal (AutomationTest, Unknown, Sit&Play, Mobile generic, BackOffice, etc.) - 1 = Web (eToro Client, Web Trader, Web Registration, Open Book, Cashier, eToro Website, etc.) - 2 = iOS (iOS eToro Trader) - 3 = Android (Android eToro Trader, Android Trade Alerts) The dimension is actively consumed by `Dim_Customer` (registration funnel for each customer), `Fact_BillingDeposit` (funnel at deposit time), and `Fact_CustomerAction`. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN FunnelID COMMENT 'Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. (Tier 1 - Dictionary.Funnel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN Name COMMENT 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 - Dictionary.Funnel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN PlatformID COMMENT 'Platform category for this funnel. 0=Undefined, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. (Tier 1 - Dictionary.Funnel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN InsertDate COMMENT 'ETL load timestamp. Set to GETDATE() (same value as UpdateDate per run). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all rows. Likely means active. No Dim_Status table in DWH to decode. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN FunnelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel ALTER COLUMN StatusID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:22:15 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
