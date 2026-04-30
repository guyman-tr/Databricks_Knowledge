-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT981_BuyPowerSummary
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md
-- Layer: bronze
-- UC Target: main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
-- =============================================================================

-- ---- UC Target: main.general.bronze_sodreconciliation_apex_ext981_buypowersummary (business_group=general) ----
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary SET TBLPROPERTIES (
    'comment' = 'Account buying power summary from Apex Clearing EXT981 extract: equity, margin, requirements, SMA, and available to withdraw per account. Source: Sodreconciliation.apex.EXT981_BuyPowerSummary on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md).'
);

ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT981_BuyPowerSummary',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT981 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OvernightBuyingPowerID COMMENT 'Apex internal identifier for the buying power calculation record. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN Firm COMMENT 'Clearing firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OfficeCode COMMENT 'Apex office/branch code associated with the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CorrespondentCode COMMENT 'Correspondent firm code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CurrencyCode COMMENT 'ISO currency code for all monetary values. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN TotalEquity COMMENT 'Total account equity (long market value - short market value + cash balances). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginEquity COMMENT 'Equity in the margin segment of the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginRequirement COMMENT 'Maintenance margin requirement for the margin segment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginExcessEquity COMMENT 'Excess equity above margin requirement (MarginEquity - MarginRequirement). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CashEquity COMMENT 'Equity in the cash segment of the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CashRequirement COMMENT 'Requirement for the cash segment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CashExcessEquity COMMENT 'Excess equity in the cash segment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginRequirementWithConcentration COMMENT 'Margin requirement including concentration surcharge for overweight positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginExcessEquityWithConcentration COMMENT 'Excess equity after applying concentration requirement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OvernightBuyingPowerCalculated COMMENT 'System-calculated overnight buying power. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OvernightBuyingPowerIssued COMMENT 'Overnight buying power issued to the account (may differ from calculated). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN DayTradeBuyingPowerIssued COMMENT 'Day trade buying power issued to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN RegTBuyingPowerCalculated COMMENT 'Reg T buying power calculated (based on 50% initial margin). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN RegTBuyingPowerIssued COMMENT 'Reg T buying power issued to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OvernightFactorCalculated COMMENT 'Calculated overnight leverage factor. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OvernightFactorIssued COMMENT 'Issued overnight leverage factor. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN DayTradeFactorCalculated COMMENT 'Calculated day trade leverage factor. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN DayTradeFactorIssued COMMENT 'Issued day trade leverage factor. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginEquityPercent COMMENT 'Margin equity as a percentage of total position value. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN PositionMarketValue COMMENT 'Total market value of all positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN LongEquityMarketValue COMMENT 'Market value of long equity positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN ShortEquityMarketValue COMMENT 'Market value of short equity positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN LongOptionMarketValue COMMENT 'Market value of long option positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN ShortOptionMarketValue COMMENT 'Market value of short option positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN TotalTradeBalance COMMENT 'Total trade-date cash balance across all sub-accounts. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN TotalSettleBalance COMMENT 'Total settle-date cash balance across all sub-accounts. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CashTradeBalance COMMENT 'Trade-date balance in the cash sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginTradeBalance COMMENT 'Trade-date balance in the margin sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN ShortTradeBalance COMMENT 'Trade-date balance in the short sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MoneyMarketTradeBalance COMMENT 'Trade-date balance in the money market sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN CashSettleBalance COMMENT 'Settle-date balance in the cash sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MarginSettleBalance COMMENT 'Settle-date balance in the margin sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN ShortSettleBalance COMMENT 'Settle-date balance in the short sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN MoneyMarketSettleBalance COMMENT 'Settle-date balance in the money market sub-account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN FreeCash COMMENT 'Free cash available without impacting margin requirements. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN SMA COMMENT 'Special Memorandum Account balance (Reg T excess). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN AvailableToWithdraw COMMENT 'Maximum cash amount available for withdrawal. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN FutureBalance COMMENT 'Projected future cash balance after pending activity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN FutureEquity COMMENT 'Projected future equity after pending activity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN FutureRequirement COMMENT 'Projected future margin requirement after pending activity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN OptionsRequirement COMMENT 'Margin requirement attributable to option positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN NonOptionsRequirement COMMENT 'Margin requirement attributable to non-option positions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN LastUpdate COMMENT 'Timestamp of the last update to this buying power record. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN NonOptionsRequirementNotConcentrated COMMENT 'Non-option requirement excluding concentration surcharges. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN TypeIUnavailableCashProceeds COMMENT 'Type I unavailable cash proceeds (free-riding restriction). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN TypeIIUnavailableCashProceeds COMMENT 'Type II unavailable cash proceeds (liquidation restriction). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN NetBalance COMMENT 'Net cash balance across all sub-accounts. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN SMACommitted COMMENT 'Portion of SMA committed to pending orders. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext981_buypowersummary ALTER COLUMN HighWaterMark COMMENT 'Highest equity value reached (used for day trade buying power calculation). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT981_BuyPowerSummary)';

