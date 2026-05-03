-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT870_StockActivity
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT870_StockActivity.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_ext870_stockactivity
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_ext870_stockactivity (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity SET TBLPROPERTIES (
    'comment' = 'Stock/security movement activity from Apex Clearing EXT870 extract: transfers, deliveries, and certificate movements per account. Source: Sodreconciliation.apex.EXT870_StockActivity on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT870_StockActivity.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT870_StockActivity',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT870 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN CurrencyCode COMMENT 'ISO currency code for the transaction. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN AccountType COMMENT 'Account type code (cash, margin, short). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN EntryDate COMMENT 'Date the stock movement was entered in Apex''s system. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN Cusip COMMENT 'CUSIP identifier of the security being moved. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SequenceNumber COMMENT 'Sequence number for ordering movements within a batch. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN TradeDate COMMENT 'Trade date associated with the stock movement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN Tradenumber COMMENT 'Trade number linking the movement to a specific trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SettleDate COMMENT 'Settlement date for the stock movement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN TradeSettleBasis COMMENT 'Trade settlement basis code (regular way, when-issued, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN Trailer COMMENT 'Trailer text providing additional movement details. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN Quantity COMMENT 'Number of shares or units moved. Positive for receipts, negative for deliveries. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SecurityTypeCode COMMENT 'Security type classification code (equity, bond, option, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN EnteredDate COMMENT 'Date the entry was recorded. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SourceProgram COMMENT 'Apex source program that generated the movement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN EntryType COMMENT 'Entry type code classifying the stock movement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN TerminalID COMMENT 'Terminal or workstation identifier where the entry originated. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN UserID COMMENT 'User ID of the operator who entered the movement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN IssueDate COMMENT 'Issue date of the security or certificate. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN CertificateShortDesc COMMENT 'Short description of the certificate being moved. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SMAChangeAmount COMMENT 'Dollar amount impact on the Special Memorandum Account (SMA). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SMAChangePrice COMMENT 'Price used for SMA change calculation. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN ReInvestmentAmount COMMENT 'Reinvestment amount for dividend reinvestment or DRIP movements. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN DTCNumberExp COMMENT 'DTC (Depository Trust Company) number or expiration code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SequenceCusipNumber COMMENT 'Sequence CUSIP number for multi-leg movements. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN SequenceEntryDate COMMENT 'Entry date associated with the sequence CUSIP. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext870_stockactivity ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT870_StockActivity)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
