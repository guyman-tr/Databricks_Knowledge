-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Response
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Response.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_response
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_response (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_response SET TBLPROPERTIES (
    'comment' = 'Configuration table with ~3,970 payment gateway response code mappings - translating PSP-specific response codes to eToro payment statuses, with support for protocol-specific, gateway-specific, and terminal-specific routing. Source: etoro.Dictionary.Response on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Response.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_response SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Response',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseID COMMENT 'Primary key. Sequential identifier for each response mapping. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ProtocolID COMMENT 'FK -> Dictionary.Protocol. Identifies which payment protocol this response belongs to. Indexed. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN PaymentActionTypeID COMMENT 'FK -> Dictionary.PaymentActionType. The action type context (PreAuth=1, Purchase=2, Refund=3, etc.). Indexed. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN PaymentStatusID COMMENT 'FK -> Dictionary.PaymentStatus. The resulting eToro payment status (Approved=1, Declined=2, etc.). Indexed. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseCode COMMENT 'PSP-specific response code (e.g., "00", "51", "APPROVED", "DECLINED"). Format varies by protocol. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseName COMMENT 'Human-readable PSP response description (e.g., "Transaction Approved", "Insufficient Funds"). (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN Meaning COMMENT 'Extended explanation of the response code''s meaning and recommended action. May be NULL for self-explanatory codes. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN TerminalID COMMENT 'Optional terminal-specific override. When set, this response mapping only applies to transactions on this terminal. NULL = all terminals. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN GatewayID COMMENT 'FK -> Dictionary.Gateway. Optional gateway-specific override. When set, this mapping only applies to this gateway. NULL = all gateways. (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ShouldTerminate COMMENT 'When true, the billing engine should stop retrying - the response is final and won''t change (e.g., card stolen, fraud, account closed). (Tier 1 - upstream wiki, etoro.Dictionary.Response)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
