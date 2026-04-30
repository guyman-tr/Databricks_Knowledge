-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationsProvidersMapping.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping SET TBLPROPERTIES (
    'comment' = 'Mapping table linking internal payment specification IDs to provider-side (Tribe) identifiers, including the provider''s address ID. Source: FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.PaymentSpecificationsProvidersMapping.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'PaymentSpecificationsProvidersMapping',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN PaymentSpecificationId COMMENT 'FK to dbo.PaymentSpecifications.Id. The internal specification being mapped. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN ProviderId COMMENT 'FK to Dictionary.Providers. Currently 1=Tribe. See Provider. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN PaymentSpecificationProviderId COMMENT 'The provider''s identifier for this payment specification in their system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN AddressId COMMENT 'Provider-side payment address/endpoint ID. Identifies the payment destination within Tribe''s system. NULL if not applicable. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping ALTER COLUMN Created COMMENT 'UTC timestamp when this mapping was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.PaymentSpecificationsProvidersMapping)';

