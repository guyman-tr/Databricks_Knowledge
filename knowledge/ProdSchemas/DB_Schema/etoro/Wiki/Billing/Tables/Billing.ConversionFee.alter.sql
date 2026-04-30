-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.ConversionFee
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_conversionfee
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_conversionfee (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee SET TBLPROPERTIES (
    'comment' = 'Temporal (system-versioned) base table of FX conversion fees per currency; each row defines the flat deposit and cashout fee in the local currency unit for a non-USD payment currency, with History.ConversionFee automatically maintained by SQL Server. Source: etoro.Billing.ConversionFee on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_conversionfee SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'ConversionFee',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CurrencyID COMMENT 'Primary key. The currency for which this fee applies. FK to Dictionary.Currency implicitly. CurrencyID=1 (USD) has no entry - USD is eToro''s base currency requiring no conversion. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN InstrumentID COMMENT 'The forex trading instrument for this currency pair (e.g., EUR/USD=1, GBP/USD=2, AUD/USD=7). References Trade.Instrument implicitly. Used by the exchange rate SP to retrieve current bid/ask rates for the conversion. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN DepositFee COMMENT 'Flat deposit conversion fee in the local currency''s smallest unit (cents, pence, subunits, etc.). Applied when a customer makes a deposit in this currency and eToro converts to USD. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CashoutFee COMMENT 'Flat cashout conversion fee in the local currency''s smallest unit. Applied when a customer withdraws in this currency and eToro converts from USD. CHF has asymmetric fees (DepositFee=140, CashoutFee=150). (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the last modification to this fee row. Defaults to GETUTCDATE() on insert. All rows = 2024-05-02 (bulk fee update). Distinct from temporal ValidFrom (which is system-managed). (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN Trace COMMENT 'Auto-captured session context at DML time: {"HostName":"...","AppName":"...","SUserName":"...","SPID":"...","DBName":"...","ObjectName":"..."}. Provides lightweight audit trail of who changed the fee. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ValidFrom COMMENT 'System-managed temporal column. UTC timestamp when this row version became current. Automatically set by SQL Server on INSERT/UPDATE. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ValidTo COMMENT 'System-managed temporal column. UTC timestamp when this row version was superseded. Current rows: 9999-12-31. Set to NOW when updated or deleted; historical row moved to History.ConversionFee. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN DepositFeePercentage COMMENT 'Percentage-based deposit fee (e.g., 1.50 = 1.5%). Currently NULL for all rows - reserved for future percentage-based fee model. Already queried by GetExchangeRatesForCustomerFunding_v4. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CashoutFeePercentage COMMENT 'Percentage-based cashout fee. Currently NULL for all rows - future use. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ConversionFeeID COMMENT 'Secondary identity column (NOT the PK). Auto-generated starting at 100,000. Provides a stable row identifier separate from the CurrencyID PK, used in override and audit references. (Tier 1 - upstream wiki, etoro.Billing.ConversionFee)';

