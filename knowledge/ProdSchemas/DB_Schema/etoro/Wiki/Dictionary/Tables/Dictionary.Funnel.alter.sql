-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Funnel
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Funnel.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_funnel
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_funnel (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_funnel SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 120+ customer acquisition and registration funnels — the specific marketing channel, campaign, or product entry point through which a customer registered on eToro. Source: etoro.Dictionary.Funnel on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Funnel.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_funnel SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Funnel',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_funnel ALTER COLUMN FunnelID COMMENT 'Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. (Tier 1 - upstream wiki, etoro.Dictionary.Funnel)';
ALTER TABLE main.general.bronze_etoro_dictionary_funnel ALTER COLUMN Name COMMENT 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Enforced unique via DFNL_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.Funnel)';
ALTER TABLE main.general.bronze_etoro_dictionary_funnel ALTER COLUMN PlatformID COMMENT 'Platform category for this funnel. 0=Unknown/Cross-platform, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. (Tier 1 - upstream wiki, etoro.Dictionary.Funnel)';

