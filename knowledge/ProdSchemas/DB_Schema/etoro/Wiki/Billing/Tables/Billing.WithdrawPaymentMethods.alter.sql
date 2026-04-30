-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.WithdrawPaymentMethods
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawPaymentMethods.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_billing_withdrawpaymentmethods
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_billing_withdrawpaymentmethods (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_billing_withdrawpaymentmethods SET TBLPROPERTIES (
    'comment' = 'Country-to-payment-method eligibility matrix that defines which withdrawal payment methods are available in each country and the accepted currencies for each combination. Source: etoro.Billing.WithdrawPaymentMethods on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawPaymentMethods.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_billing_withdrawpaymentmethods SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'WithdrawPaymentMethods',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_billing_withdrawpaymentmethods ALTER COLUMN CountryID COMMENT 'Country of the customer''s registration. Implicit FK to Dictionary.Country (CountryID). The clustered index on this column enables fast lookups by country when the application checks withdrawal eligibility for a specific customer. Known values: 55=Czech Republic, 57=Denmark, 94=Hungary, 154=Norway, 164=Poland, 168=Romania, 196=Sweden, 197=Switzerland. (Tier 1 - upstream wiki, etoro.Billing.WithdrawPaymentMethods)';
ALTER TABLE main.bi_db.bronze_etoro_billing_withdrawpaymentmethods ALTER COLUMN FundingTypeID COMMENT 'Payment method identifier for the withdrawal channel. Implicit FK to Dictionary.FundingType (FundingTypeID). Only two values present: 3=PayPal, 8=MoneyBookers (Skrill). Not all countries have both methods - Romania has MoneyBookers only. (Tier 1 - upstream wiki, etoro.Billing.WithdrawPaymentMethods)';
ALTER TABLE main.bi_db.bronze_etoro_billing_withdrawpaymentmethods ALTER COLUMN Currencies COMMENT 'Comma-separated list of CurrencyIDs representing the currencies accepted for this country/payment-method combination. Pattern: local currency first, then USD(1), EUR(2), GBP(3), AUD(5). Parsed by application code to build the currency selection list during withdrawal. Example: "82,1,2,3,5" = CZK, USD, EUR, GBP, AUD for Czech Republic. (Tier 1 - upstream wiki, etoro.Billing.WithdrawPaymentMethods)';

