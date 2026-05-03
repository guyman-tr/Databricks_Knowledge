-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Label
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Label.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_label
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_label (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_label SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 25 platform labels (white-label brands) - eToro, RetailFX, eToroUSA, and partner brands - with associated website URLs and cashier logo assets for multi-brand customer experience. Source: etoro.Dictionary.Label on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Label.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_label SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Label',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_label ALTER COLUMN LabelID COMMENT 'Primary key identifying the platform brand/label. 0/1/9=eToro (primary), 2=RetailFX, 10-26=white-label partners, 14=eToroUSA, 27=Partners, 29=eToroRussia, 30=Dealing, 31=eToroChina. Stored in customer records and referenced across billing, reporting, and registration procedures. (Tier 1 - upstream wiki, etoro.Dictionary.Label)';
ALTER TABLE main.general.bronze_etoro_dictionary_label ALTER COLUMN Name COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = "eToro"). (Tier 1 - upstream wiki, etoro.Dictionary.Label)';
ALTER TABLE main.general.bronze_etoro_dictionary_label ALTER COLUMN URL COMMENT 'Brand''s primary website URL. Used in customer-facing emails, notifications, and redirect links. NULL for internal/system labels (Partners, Dealing) that have no website. (Tier 1 - upstream wiki, etoro.Dictionary.Label)';
ALTER TABLE main.general.bronze_etoro_dictionary_label ALTER COLUMN CashierLogoURL COMMENT 'CDN URL for the brand''s logo displayed in the cashier/payment interface. Points to eToro''s CDN (etoro-cdn.etorostatic.com). NULL for internal labels. Determines the visual branding during deposit and withdrawal flows. (Tier 1 - upstream wiki, etoro.Dictionary.Label)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
