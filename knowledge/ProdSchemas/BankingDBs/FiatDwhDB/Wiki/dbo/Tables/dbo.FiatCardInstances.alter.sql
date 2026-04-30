-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatCardInstances
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances SET TBLPROPERTIES (
    'comment' = 'Represents physical or virtual card instances issued under a card entity, tracking PAN, expiration, and virtual/physical status. Source: FiatDwhDB.dbo.FiatCardInstances on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md).'
);

ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatCardInstances',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN CardId COMMENT 'Implicit FK to dbo.FiatCards.Id. The logical card this instance belongs to. No explicit FK constraint in DDL. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN MaskedPAN COMMENT 'Masked card number showing only last digits. Dynamic data masking protects the full PAN. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN IsVirtual COMMENT 'Whether this is a virtual (digital wallet) card: 1=virtual, 0=physical plastic card. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN Created COMMENT 'UTC timestamp when this instance was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN CorrelationId COMMENT 'Links this instance creation to the triggering business operation for distributed tracing. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN Name COMMENT 'Cardholder name printed on the card. Masked for PII protection. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN CardExpirationDate COMMENT 'Expiration date of this card instance. NULL for instances where expiration is not yet set. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances ALTER COLUMN CardInstanceGuid COMMENT 'External-facing GUID for this card instance. Used in API interactions. Nullable for legacy instances created before this field was added. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardInstances)';

