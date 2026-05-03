-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT538_ClosedAccounts
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts SET TBLPROPERTIES (
    'comment' = 'Closed accounts from Apex Clearing EXT538 extract with restriction reason codes, balances, and equity values. Source: Sodreconciliation.apex.EXT538_ClosedAccounts on the Sodreconciliation production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md).'
);

ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT538_ClosedAccounts',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT538 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN AccountName COMMENT 'Account holder name. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN RestrictReasonCode COMMENT 'Restriction reason code indicating why the account was closed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN OfficeCurrency COMMENT 'Currency code for the office/account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN MarketValue COMMENT 'Remaining market value of securities in the closed account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN CashBalance COMMENT 'Remaining cash balance in the closed account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts ALTER COLUMN TotalEquity COMMENT 'Total equity remaining (MarketValue + CashBalance). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT538_ClosedAccounts)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
