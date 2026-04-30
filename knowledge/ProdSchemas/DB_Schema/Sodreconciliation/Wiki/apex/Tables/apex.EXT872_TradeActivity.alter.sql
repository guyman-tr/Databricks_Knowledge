-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT872_TradeActivity
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT872_TradeActivity.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity SET TBLPROPERTIES (
    'comment' = 'Trade execution details from Apex Clearing EXT872 extract: buys, sells, quantities, prices, commissions, and fees. TRIGGERS RECONCILIATION against eToro trades (Flow 2). Source: Sodreconciliation.apex.EXT872_TradeActivity on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT872_TradeActivity.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT872_TradeActivity',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT872 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Firm COMMENT 'Clearing firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CorrespondentID COMMENT 'Correspondent firm identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CorrespondentOfficeID COMMENT 'Correspondent firm office identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CorrespondentCode COMMENT 'Correspondent firm code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN OfficeCode COMMENT 'Apex office/branch code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN RegisteredRepCode COMMENT 'Registered representative code assigned to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN AccountType COMMENT 'Account type code. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN BuySellCode COMMENT 'Buy/sell direction indicator for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN TradeDate COMMENT 'Date the trade was executed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN TradeNumber COMMENT 'Apex''s unique trade number identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ExecutionTime COMMENT 'Time the trade was executed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Cusip COMMENT 'CUSIP identifier of the traded security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Symbol COMMENT 'Trading symbol of the security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Quantity COMMENT 'Number of shares/units traded. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Price COMMENT 'Execution price per share/unit. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN MarketCode COMMENT 'Market/exchange code where the trade was executed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CapacityCode COMMENT 'Trade capacity code (principal, agency, riskless principal). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CommissionGrossCalculated COMMENT 'Commission amount calculated by the system. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CommissionGrossEntered COMMENT 'Commission amount entered manually or by the order entry system. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN SettlementDate COMMENT 'Settlement date for the trade (T+1 for equities). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CurrencyCode COMMENT 'ISO currency code for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN PrincipalAmount COMMENT 'Gross trade value (Quantity * Price). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN NetAmount COMMENT 'Net settlement amount after commissions and fees. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN FeeSec COMMENT 'SEC transaction fee (Section 31 fee). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN FeeMisc COMMENT 'Miscellaneous fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Fee1 COMMENT 'Additional fee amount (exchange, regulatory, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Fee2 COMMENT 'Additional fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Fee3 COMMENT 'Additional fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Fee4 COMMENT 'Additional fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Fee5 COMMENT 'Additional fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN EntryDate COMMENT 'Date the trade was entered into Apex''s system. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ShortDescription COMMENT 'Short description of the traded security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN TrailerCode COMMENT 'Trailer code providing additional trade classification. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN TradeIntrest COMMENT 'Accrued interest amount for bond trades. Note: column name has typo ("Intrest"). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ExecutingBrokerBack COMMENT 'Back-office executing broker identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN SecurityTypeCode COMMENT 'Security type classification code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CommissionRRCategory COMMENT 'Commission category for registered representative payout calculation. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Reallowance COMMENT 'Reallowance amount (portion of underwriting concession). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CommissionEntered COMMENT 'Commission amount as entered. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ShortName COMMENT 'Short name of the account holder. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Factor COMMENT 'Factor for bond or MBS trades (face value multiplier). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CommissionNet COMMENT 'Net commission after any splits or concessions. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Trailer COMMENT 'Trailer text providing additional trade details. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ExecutingBrokerFront COMMENT 'Front-office executing broker identifier. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN FeeMF COMMENT 'Mutual fund fee amount. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ClearingSymbol COMMENT 'Clearing-level symbol (may differ from trading symbol). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Repo COMMENT 'Repo (repurchase agreement) related information. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Description1 COMMENT 'Primary security description. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN SecuritySubType COMMENT 'Security sub-type classification. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN InstructionsTradeLegendCode COMMENT 'Trade legend code for special instructions on confirmations. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN Country COMMENT 'Country associated with the security or trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ISIN COMMENT 'International Securities Identification Number. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN LanguageID COMMENT 'Language identifier for trade confirmation generation. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN InstructionsSpecial1 COMMENT 'Special instruction line 1 for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN InstructionsSpecial2 COMMENT 'Special instruction line 2 for the trade. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN OriginalTradeNumber COMMENT 'Original trade number for corrections or amendments. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN TradeLegendCode COMMENT 'Trade legend code for confirmation printing. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN OptionSymbolRoot COMMENT 'Root symbol for option trades. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN DisplaySymbol COMMENT 'Display symbol for the security (human-readable format). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN StrikePrice COMMENT 'Strike price for option trades. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN CallPut COMMENT 'Call or Put indicator for option trades. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN ExpirationDeliveryDate COMMENT 'Expiration or delivery date for option/futures trades. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN OptionContractDate COMMENT 'Option contract origination date. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ALTER COLUMN OrderId COMMENT 'Order ID linking back to the originating order in eToro''s system. Key field for reconciliation matching. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT872_TradeActivity)';

