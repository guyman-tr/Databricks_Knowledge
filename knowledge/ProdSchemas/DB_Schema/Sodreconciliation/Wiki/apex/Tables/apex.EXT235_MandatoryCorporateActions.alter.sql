-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT235_MandatoryCorporateActions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT235_MandatoryCorporateActions.md
-- Layer: bronze
-- UC Target: main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions
-- =============================================================================

-- ---- UC Target: main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions (business_group=trading) ----
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions SET TBLPROPERTIES (
    'comment' = 'Mandatory corporate actions from Apex Clearing EXT235 extract: splits, mergers, and spinoffs with stock/cash factors. Source: Sodreconciliation.apex.EXT235_MandatoryCorporateActions on the Sodreconciliation production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT235_MandatoryCorporateActions.md).'
);

ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT235_MandatoryCorporateActions',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT235 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN Firm COMMENT 'Clearing firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN Cusip COMMENT 'New CUSIP identifier (resulting security after corporate action). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CusipOld COMMENT 'Old CUSIP identifier (original security before corporate action). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN Symbol COMMENT 'New trading symbol (resulting security). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN SymbolOld COMMENT 'Old trading symbol (original security). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ShortDescription COMMENT 'Description of the new/resulting security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ShortDescriptionOld COMMENT 'Description of the old/original security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ISIN COMMENT 'International Securities Identification Number. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ExpirationDate COMMENT 'Expiration date for the corporate action processing window. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN ToMarket COMMENT 'Market/exchange of the resulting security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN FromMarket COMMENT 'Market/exchange of the original security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CountryCode COMMENT 'Country code for the resulting security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CountryCodeOld COMMENT 'Country code for the original security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN StockFactor COMMENT 'Number of new shares received per old share. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CashFactor COMMENT 'Cash amount received per old share. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN PayableDate COMMENT 'Date when the corporate action proceeds are payable. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN SettlementDate COMMENT 'Settlement date for the corporate action. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN LastChangeDate COMMENT 'Date the corporate action record was last updated at Apex. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CorporateAction COMMENT 'Type of corporate action (split, merger, spinoff, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN CorporateActionMessage COMMENT 'Detailed message describing the corporate action terms. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
ALTER TABLE main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions ALTER COLUMN RecordDate COMMENT 'Record date for determining entitled shareholders. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT235_MandatoryCorporateActions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
