-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.ConversionFeeOverride
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_conversionfeeoverride
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_conversionfeeoverride (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride SET TBLPROPERTIES (
    'comment' = 'Configuration table storing tier-specific currency conversion fee overrides that supersede the standard Billing.ConversionFee rates for loyalty club members by payment method, account currency, and optionally country. Source: etoro.Billing.ConversionFeeOverride on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'ConversionFeeOverride',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN PlayerLevelID COMMENT 'eToro Club loyalty tier for which this override applies. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Value 0 means "all tiers" (global override). Implicit FK to Dictionary.PlayerLevel. See Player Level. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN FundingTypeID COMMENT 'Payment method for which this override applies. Active values in this table: 1=CreditCard, 2=WireTransfer, 33=eToroMoney, 35=Trustly, 43=GCCInstantBankTransfer. Implicit FK to Dictionary.FundingType. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN CurrencyID COMMENT 'Account denomination currency for which this override applies. References Dictionary.Currency (which is the universal instrument registry; in billing context, CurrencyID refers to actual ISO currencies like EUR=2, GBP=3, AUD=5, CHF=6, NOK=39, SEK=40, PLN=44, HUF=45, DKK=46, CZK=82, RON=521, AEDUSD=349). Value 0 means "any currency". Explicit FK to Dictionary.Currency. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN DepositFee COMMENT 'Flat minimum deposit conversion fee in minor currency units (e.g., cents). Used for flat-fee payment methods (CreditCard, WireTransfer). For eToroMoney rows this is 0, meaning no flat minimum - the percentage (DepositFeePercentage) is the operative charge. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN CashoutFee COMMENT 'Flat minimum cashout (withdrawal) conversion fee in minor currency units. Same model as DepositFee: used for flat-fee methods; 0 for percentage-based methods. Diamond tier rows show CashoutFee=0 (flat minimum waived as loyalty benefit). (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN ModifictionDate COMMENT 'UTC timestamp of the last INSERT or UPDATE on this row. Note: column name is intentionally misspelled in DDL ("Modification" -> "Modifiction"). DEFAULT is GETUTCDATE() so new rows auto-populate. The trigger archives the old value to History.ConversionFeeOverride on UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN CountryID COMMENT 'Optional country scope for this override. NULL=applies globally to all countries. Non-NULL values: 12=Australia (AUD/eToroMoney rows with higher rates), 218=United Kingdom (GBP/Trustly flat fee rows). Passed to Billing.ExchangeRatesByPlayerLevelGet as @CountryID for country-aware fee lookup. Implicit FK to Dictionary.Country. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN DepositFeePercentage COMMENT 'Percentage-based deposit conversion fee rate (e.g., 0.75 = 0.75%). Used for newer payment methods (eToroMoney=0.75% globally, Trustly). NULL for flat-fee methods (CreditCard, WireTransfer, GCCInstantBankTransfer). Added in PAYIL-8694 (Aug 2024) to support percentage-based fee model. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN CashoutFeePercentage COMMENT 'Percentage-based cashout conversion fee rate. Mirrors DepositFeePercentage for withdrawal direction. Same values as DepositFeePercentage for symmetric pricing; NULL for flat-fee payment methods. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfeeoverride ALTER COLUMN ConversionFeeID COMMENT 'Auto-incrementing surrogate identity column. NOT declared as PRIMARY KEY in DDL - uniqueness is enforced via IX_Conv_1 unique index on (PlayerLevelID, FundingTypeID, CurrencyID, CountryID). Used as a stable row reference. (Tier 1 - upstream wiki, etoro.Billing.ConversionFeeOverride)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
