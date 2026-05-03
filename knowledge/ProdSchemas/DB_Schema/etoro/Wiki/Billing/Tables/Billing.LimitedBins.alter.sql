-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.LimitedBins
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_limitedbins
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_limitedbins (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_limitedbins SET TBLPROPERTIES (
    'comment' = 'Single-column blocklist of credit/debit card BIN prefixes (first 6 digits) that are subject to deposit restrictions on the eToro platform. Source: etoro.Billing.LimitedBins on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_limitedbins SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'LimitedBins',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_limitedbins ALTER COLUMN Bin COMMENT 'Credit/debit card BIN (Bank Identification Number) - the first 6 digits of the card number identifying the issuing bank and card program. Serves as both the primary key and the sole data element. Cards whose BIN matches an entry here are treated as "limited" in the deposit flow and may face deposit restrictions. (Tier 1 - upstream wiki, etoro.Billing.LimitedBins)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
