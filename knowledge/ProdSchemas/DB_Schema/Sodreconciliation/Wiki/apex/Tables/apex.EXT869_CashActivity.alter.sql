-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT869_CashActivity
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT869_CashActivity.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_ext869_cashactivity (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity SET TBLPROPERTIES (
    'comment' = 'Cash transaction activity from Apex Clearing EXT869 extract: debits, credits, dividends, interest, and fees per account. Source: Sodreconciliation.apex.EXT869_CashActivity on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT869_CashActivity.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT869_CashActivity',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT869 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN AccountType COMMENT 'Account type code (e.g., cash, margin, short). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Amount COMMENT 'Transaction amount. Positive for credits, negative for debits. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Description COMMENT 'Free-text description of the cash activity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN CurrencyCode COMMENT 'ISO currency code for the transaction (e.g., USD). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN BatchCode COMMENT 'Apex batch processing code identifying the transaction category. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Cusip COMMENT 'CUSIP of the related security (for dividends, interest on bonds, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN EntryDate COMMENT 'Date the transaction was entered in Apex''s system. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN SourceProgram COMMENT 'Apex source program that generated the transaction. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN UserID COMMENT 'User ID of the operator who entered or approved the transaction. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN ActivityIndicator COMMENT 'Code indicating the type of cash activity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN OfficeCode COMMENT 'Apex office/branch code associated with the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN ACATSControlNumber COMMENT 'ACATS (Automated Customer Account Transfer Service) control number for account transfer transactions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN CheckNumber COMMENT 'Check number for check-based disbursements. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN DivTaxTypeCode COMMENT 'Dividend tax classification code (qualified, ordinary, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN EffectiveDate COMMENT 'Effective date of the transaction for settlement purposes. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN EnteredBy COMMENT 'Operator code who entered the transaction. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN EntryTypeCode COMMENT 'Code classifying the type of cash entry. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Firm COMMENT 'Clearing firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN GLPostStatusCode COMMENT 'General Ledger posting status code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN HistoryEntryCode COMMENT 'Code indicating if the entry is a historical correction or adjustment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN InterestEffectiveDate COMMENT 'Effective date for interest calculation purposes. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN MoneyMarketCode COMMENT 'Money market fund code for sweep-related transactions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN OriginalQuantity COMMENT 'Original share quantity related to the cash activity (e.g., shares for a dividend). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN OverrideIndicator COMMENT 'Flag indicating if the transaction was manually overridden. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN PasMergeEntryCode COMMENT 'PAS (Portfolio Accounting System) merge entry code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN PayTypeCode COMMENT 'Payment type code (check, wire, ACH, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Price COMMENT 'Price per unit related to the transaction (e.g., dividend rate per share). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN RecTypeCode COMMENT 'Record type code within the batch. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN RegisteredRepCode COMMENT 'Registered representative code assigned to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN SequenceNumber COMMENT 'Sequence number for ordering transactions within a batch. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN TerminalID COMMENT 'Terminal or workstation identifier where the transaction originated. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN TradeDate COMMENT 'Trade date for the related transaction. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN Tradenumber COMMENT 'Trade number linking the cash activity to a specific trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN UserEntryDate COMMENT 'Date the user entered the transaction (may differ from system entry date). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN WithholdTaxIndicator COMMENT 'Flag indicating if tax withholding was applied. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN WithholdTaxTypeCode COMMENT 'Type of tax withholding applied (federal, state, foreign). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN CorrespondentOfficeID COMMENT 'Correspondent firm office identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ALTER COLUMN CorrespondentID COMMENT 'Correspondent firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)';

