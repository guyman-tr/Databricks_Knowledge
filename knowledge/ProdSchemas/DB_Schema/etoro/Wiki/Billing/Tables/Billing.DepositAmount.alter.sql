-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.DepositAmount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_billing_depositamount
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_billing_depositamount (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount SET TBLPROPERTIES (
    'comment' = 'Per-country, per-customer-type configuration of deposit amount limits and suggested package amounts; defines MinAmount/MaxAmount and three suggested deposit "packages" shown to customers, split by First Time Deposit (FTD) vs. returning depositor status. Source: etoro.Billing.DepositAmount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'DepositAmount',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN CountryID COMMENT 'Country for which these deposit limits apply. Implicit FK to Dictionary.Country(CountryID). CountryID=0 is the global fallback used when no country-specific row exists (via ISNULL(@CountryID, 0) in GetDepositAmountsForUser). (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN MinAmount COMMENT 'Minimum deposit amount in USD. The smallest amount a customer in this country can deposit (or globally, $50 for the fallback). Enforced at the deposit validation layer. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN Package1Amount COMMENT 'First suggested deposit amount shown as a quick-select button. NULL if not applicable. Default value is $200.00 across most rows. Only displayed when IsPackageVisible=1. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN Package2Amount COMMENT 'Second suggested deposit amount. NULL if not applicable. Default value is $400.00. Only displayed when IsPackageVisible=1. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN Package3Amount COMMENT 'Third suggested deposit amount. NULL if not applicable. Default value is $1,000.00. Only displayed when IsPackageVisible=1. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN FTD COMMENT 'First Time Deposit flag. 1=this row applies to customers making their FIRST approved deposit (no prior PaymentStatusID=2 in Billing.Deposit). 0=this row applies to returning depositors. GetDepositAmountsForUser dynamically determines FTD status and selects the appropriate row. DEFAULT 0. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN Id COMMENT 'Surrogate PK. Auto-incremented row identifier. Not the natural business key - lookups are by (CountryID, FTD). (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN IsPackageVisible COMMENT 'Whether the Package1/2/3 suggested amounts should be displayed in the deposit UI. 1=show package buttons (8 rows, all FTD=true), 0=hide packages, customer enters amount manually (493 rows). DEFAULT 0. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN Trace COMMENT 'Non-persisted JSON audit string (HostName, AppName, SUserName, SPID, DBName, ObjectName). Computed at query time for diagnostic purposes. Same pattern as CurrencyPerFundingTypeOverrides. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN ValidFrom COMMENT 'System-time start: row became current at this timestamp. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN ValidTo COMMENT 'System-time end: row was superseded at this timestamp (9999-12-31 for current rows). GENERATED ALWAYS AS ROW END. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';
ALTER TABLE main.bi_db.bronze_etoro_billing_depositamount ALTER COLUMN MaxAmount COMMENT 'Maximum deposit amount in USD. NULL means no upper limit. When set (e.g., MaxAmount=50 for CountryID=1), enforces a cap on deposit size for that country/depositor type. (Tier 1 - upstream wiki, etoro.Billing.DepositAmount)';

