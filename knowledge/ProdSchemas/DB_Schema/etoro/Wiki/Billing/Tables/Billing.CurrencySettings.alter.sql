-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.CurrencySettings
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_billing_currencysettings
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_billing_currencysettings (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings SET TBLPROPERTIES (
    'comment' = 'Currency-to-instrument mapping table used by PIP calculation functions - defines which trading instrument provides the FX rate for each currency, and how to apply that rate (direct or reciprocal) with what decimal precision. Source: etoro.Billing.CurrencySettings on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'CurrencySettings',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN ID COMMENT 'Surrogate primary key. No business significance - internal row identifier. (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN CurrencyID COMMENT 'Currency being configured. Implicit FK to Dictionary.Currency. The lookup key used by PIP calculation functions: JOIN Billing.CurrencySettings ON CurrencyID = BD.CurrencyID. Covers 31 currencies including EUR (2), GBP (3), JPY (4), AUD (5), CHF (6), CAD (7), and others. (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN InstrumentID COMMENT 'Trading instrument that provides the exchange rate for this currency. Implicit FK to the Trade instrument table. For major currencies, typically the standard forex pair (e.g., EUR->InstrumentID=1 is EUR/USD). For some currencies, CurrencyID=InstrumentID (e.g., 79, 80, 81 where currency and instrument share the same ID - likely non-USD instruments referenced directly). (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN IsReciprocal COMMENT 'Rate direction flag: 0=direct quote (currency is base, e.g., EUR/USD), 1=reciprocal quote (USD is base, e.g., USD/JPY, must invert rate). Used by PIP formula to determine whether to apply rate directly or as 1/rate. 0 for 9 currencies (EUR, GBP, AUD, CAD, and some crypto), 1 for 22 currencies (most others including JPY, CHF, CNY). (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN Precision COMMENT 'Decimal places used for this currency in PIP calculations. Determines rounding precision in the PIP formula. Values: 0=JPY-class (no decimal), 2=most standard currencies, 4=major FX pairs (EUR, GBP, AUD, CAD), 5=crypto/exotic instruments. (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN ModificationDate COMMENT 'Timestamp of last configuration update. All 31 rows show 2024-05-06 - a bulk update/refresh event. Used for change tracking by the admin tool. (Tier 1 - upstream wiki, etoro.Billing.CurrencySettings)';

