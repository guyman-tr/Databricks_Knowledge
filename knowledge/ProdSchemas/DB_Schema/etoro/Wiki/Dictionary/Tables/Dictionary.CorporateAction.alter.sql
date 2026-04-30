-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CorporateAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CorporateAction.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_corporateaction
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_corporateaction (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction SET TBLPROPERTIES (
    'comment' = 'Lookup table defining all types of corporate actions that affect stock and instrument positions — dividends, splits, mergers, promotions, and platform-specific events. Links to compensation accounting and order-cancel rules. Source: etoro.Dictionary.CorporateAction on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CorporateAction.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CorporateAction',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction ALTER COLUMN CorporateActionTypeID COMMENT 'Primary key. Auto-generated. Referenced by Trade.CorporateInstrumentActions via FK. Used by GetCorporateActionType, GetCorporateInstrumentActions, PayCashDividendByPayDate, ExecuteCashPayment, PositionAirdrop. (Tier 1 - upstream wiki, etoro.Dictionary.CorporateAction)';
ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction ALTER COLUMN Description COMMENT 'Human-readable description. Values: Dividend, Cash in Lieu, Stock Split, Merger, Staking, Promotion, etc. (41 types). NULL allowed. (Tier 1 - upstream wiki, etoro.Dictionary.CorporateAction)';
ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction ALTER COLUMN CompensationReasonID COMMENT 'FK to Dictionary.CreditType. Determines how compensation is recorded. NOT NULL. (Tier 1 - upstream wiki, etoro.Dictionary.CorporateAction)';
ALTER TABLE main.general.bronze_etoro_dictionary_corporateaction ALTER COLUMN CancelOrders COMMENT 'Whether to cancel pending orders when this action is processed. 1 = cancel; 0/NULL = typically no cancellation. (Tier 1 - upstream wiki, etoro.Dictionary.CorporateAction)';

