-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT1047_RevenueReports
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1047_RevenueReports.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports SET TBLPROPERTIES (
    'comment' = 'Revenue/PFOF reports from Apex Clearing EXT1047 extract: order routing venue, execution rates, and customer payment for order flow. Source: Sodreconciliation.apex.EXT1047_RevenueReports on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1047_RevenueReports.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT1047_RevenueReports',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT1047 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN BillingPeriod COMMENT 'Billing period for the revenue record. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN TradeMonth COMMENT 'Month in which the trade occurred. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN TradeDate COMMENT 'Date the trade was executed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN GatewayRouteRequested COMMENT 'Routing instruction or gateway requested for the order. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN InstrumentType COMMENT 'Type of instrument traded (equity, option, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Side COMMENT 'Trade side indicator (B=Buy, S=Sell). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN ExecutionRate COMMENT 'Execution rate or price for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN TerminalID COMMENT 'Terminal or workstation identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Client COMMENT 'Client identifier or name. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Venue COMMENT 'Market center/venue that executed the order. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN BillingKey COMMENT 'Billing key for revenue allocation. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Symbol COMMENT 'Trading symbol of the security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN Description COMMENT 'Description of the trade or security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN OrderID COMMENT 'Order identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN ClearingAccount COMMENT 'Clearing account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN PriceFiller COMMENT 'Price or filler field (may be execution price or placeholder). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN OrderID2 COMMENT 'Secondary order identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN TotalQuantity COMMENT 'Total quantity of shares traded. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports ALTER COLUMN CustomerPFOFPayback COMMENT 'Payment for order flow or rebate amount for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1047_RevenueReports)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
