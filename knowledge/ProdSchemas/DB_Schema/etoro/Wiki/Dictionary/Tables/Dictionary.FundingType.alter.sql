-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FundingType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_fundingtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_fundingtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype SET TBLPROPERTIES (
    'comment' = 'System-versioned lookup table defining the 24 payment methods/providers available on the eToro platform, with per-method operational flags. Source: etoro.Dictionary.FundingType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FundingType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN FundingTypeID COMMENT 'Primary key identifying the payment method. See Funding Type. (Dictionary.FundingType) (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN Name COMMENT 'Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsNewStyle COMMENT 'Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsSingleFunding COMMENT 'Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsCashoutActive COMMENT 'Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsFundingTypeActive COMMENT 'Whether this payment method is globally active. 1=active (shown in UI), 0=disabled. NULL treated as inactive. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN DefaultCurrency COMMENT 'FK to Dictionary.Currency - if set, forces transactions through this method to use this currency. NULL=use user''s account currency. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN MaxDepositAmount COMMENT 'Maximum allowed single deposit amount. NULL=no limit. Used for risk management and fraud prevention. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsRefundable COMMENT 'Whether deposits via this method can be refunded to the same payment source. Important for chargeback prevention. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsCountryConflictActive COMMENT 'Whether country-based availability restrictions apply. 1=some countries are blocked for this method. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN PaymentGeneration COMMENT 'Integration generation version. 0=legacy, 1+=newer integrations with different API contracts and flow patterns. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN IsRedeemable COMMENT 'Whether funds deposited via this method can be redeemed in copy-trading (mirror) context. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN Trace COMMENT 'Auto-computed audit column capturing hostname, app name, SPID, and database context for every DML operation. Not stored - calculated on read. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN ValidFrom COMMENT 'System-versioning row start time. Automatically maintained. Records when this row version became current. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtype ALTER COLUMN ValidTo COMMENT 'System-versioning row end time. Automatically maintained. 9999-12-31 for current rows. (Tier 1 - upstream wiki, etoro.Dictionary.FundingType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
