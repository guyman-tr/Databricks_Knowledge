-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.WithdrawType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_withdrawtype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_withdrawtype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three classifications of withdrawal requests — Default (standard cashout), Transfer (internal account transfer), or ApprovedForClosure (final withdrawal during account closure) — controlling how the withdrawal is processed and routed. Source: etoro.Dictionary.WithdrawType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'WithdrawType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN WithdrawTypeID COMMENT 'Unique identifier for the withdrawal classification: 0=Default (standard cashout), 1=Transfer (internal), 2=ApprovedForClosure (closure disbursement). Stored on Billing.Withdraw and checked by 15+ procedures to determine processing path, approval requirements, and reporting categorization. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawType)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN WithdrawType COMMENT 'Short code name for the type: "Default", "Transfer", "ApprovedForClosure". Used as a programmatic identifier in application code and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawType)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN Description COMMENT 'Human-readable description of the type. Empty for Default (0), "Internal Transfer" for Transfer (1), "Approved for closure" for ApprovedForClosure (2). Used in BackOffice UI and reports. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawType)';

