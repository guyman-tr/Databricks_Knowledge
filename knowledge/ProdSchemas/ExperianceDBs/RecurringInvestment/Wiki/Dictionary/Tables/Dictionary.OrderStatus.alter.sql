-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.Dictionary.OrderStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.OrderStatus.md
-- Layer: bronze
-- UC Target: main.experience.bronze_recurringinvestment_dictionary_orderstatus
-- =============================================================================

-- ---- UC Target: main.experience.bronze_recurringinvestment_dictionary_orderstatus (business_group=experience) ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining trading order lifecycle states - from receipt through execution, cancellation, or expiry. Source: RecurringInvestment.Dictionary.OrderStatus on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.OrderStatus.md).'
);

ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrderStatus',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the order status. 1=Received, 2=Placed, 3=Filled, 4=Rejected, 5=PartiallyFilled, 6=PendingCancel, 7=Canceled, 8=Expired, 9=CanceledPartiallyFilled, 10=RejectedPartiallyFilled, 11=WaitingForMarket. See Order Status. (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.OrderStatus)';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus ALTER COLUMN OrderStatus COMMENT 'Human-readable label for the order lifecycle state. Aligns with Trading API enum values (per Confluence). (Tier 1 - upstream wiki, RecurringInvestment.Dictionary.OrderStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
