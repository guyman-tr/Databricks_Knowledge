-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.DocumentVendors
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_documentvendors
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_documentvendors (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_documentvendors SET TBLPROPERTIES (
    'comment' = 'Records which third-party KYC verification vendor processed each customer document. 902,884 rows covering 893,779 documents; 5 vendor values: Onfido (31.8%), Sumsub (5.2%), Au10tix (1.5%), IDnow (0.8%), and the legacy code "100" (60.8%). Source: etoro.BackOffice.DocumentVendors on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_documentvendors SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'DocumentVendors',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_documentvendors ALTER COLUMN DocumentID COMMENT 'The KYC document that was processed. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Leading key of NC PK. 893,779 distinct values. Deletions cascade from DeleteUserDocument. (Tier 1 - upstream wiki, etoro.BackOffice.DocumentVendors)';
ALTER TABLE main.billing.bronze_etoro_backoffice_documentvendors ALTER COLUMN Vendor COMMENT 'The verification vendor name or code. Part of NC PK. Free-text, no FK constraint. Known values: "100" (legacy), "Onfido", "Sumsub", "Au10tix", "IDnow". Max 1024 chars - generous allocation for potentially long vendor identifiers or JSON-encoded metadata. (Tier 1 - upstream wiki, etoro.BackOffice.DocumentVendors)';

