-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.BadBin
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_badbin
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_badbin (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_badbin SET TBLPROPERTIES (
    'comment' = 'BIN (Bank Identification Number) range blocklist used to check whether a card prefix corresponds to a blocked card range; queried by Billing.CheckBadBin and Billing.CheckInBadBins during card payment validation. Source: etoro.Billing.BadBin on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_badbin SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'BadBin',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BinFrom COMMENT 'Start of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinTo. Represents the first 6 or 8 digits of the card number. (Tier 1 - upstream wiki, etoro.Billing.BadBin)';
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BinTo COMMENT 'End of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinFrom. Any card whose BIN prefix falls in [BinFrom, BinTo] is considered blocked. (Tier 1 - upstream wiki, etoro.Billing.BadBin)';
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BlockReasonID COMMENT 'Optional block reason code. NULL = blocked without a specific coded reason (the overwhelming majority of rows). Non-NULL values reference a reason catalog (only BlockReasonID=1 observed in live data, applied to 2 rows at BIN 40380600-40380601). No FK constraint defined. (Tier 1 - upstream wiki, etoro.Billing.BadBin)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
