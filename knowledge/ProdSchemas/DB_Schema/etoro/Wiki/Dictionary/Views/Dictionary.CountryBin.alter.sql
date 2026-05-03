-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CountryBin
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_countrybin
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_countrybin (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin SET TBLPROPERTIES (
    'comment' = 'Union view combining 6-digit and 8-digit BIN lookup tables into a single card identification reference for payment processing. Source: etoro.Dictionary.CountryBin on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_countrybin SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CountryBin',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN CountryID COMMENT 'Card issuing country identifier. FK to Dictionary.Country: 0=Not available, 1=Afghanistan, 74=Germany, 82=United Kingdom, etc. Used to match card origin to customer''s registered country for fraud detection. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN BinCode COMMENT 'Bank Identification Number - first 6 or 8 digits of the card number that identify the issuing bank and card product. From CountryBin6 (6-digit legacy) or CountryBin8 (8-digit modern). (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN IssuingBank COMMENT 'Name of the bank that issued the card. Used in BackOffice reporting and payment routing decisions. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN ProductType COMMENT 'Card product type classification (e.g., Classic, Gold, Platinum). Only populated for 8-digit BINs (CountryBin8); always NULL for 6-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN CardTypeID COMMENT 'FK to Dictionary.CardType: 1=Visa, 2=MasterCard, 3=Amex, 4=Discover, 5=Diners, 6=Maestro, 7=JCB, 8=UnionPay. Determines processing network. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN CardSubType COMMENT 'Sub-classification within the card type (e.g., debit, credit, corporate). (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN Category COMMENT 'Card category from 8-digit BIN data (e.g., consumer, commercial, government). Always NULL for 6-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN CardCategory COMMENT 'Card category label from the BIN provider, available in both 6-digit and 8-digit sources. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN BankWebSite COMMENT 'Bank''s website URL. Only populated for 6-digit BINs (CountryBin6); always NULL for 8-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN BankInfo COMMENT 'Additional bank identification information. Only populated for 6-digit BINs (CountryBin6); always NULL for 8-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN ShouldCheck3ds COMMENT 'Whether this BIN requires 3D Secure verification: 1=require 3DS check, 0=skip 3DS. Consumed by Billing.GetCCProcessingBundle for payment authentication decisioning. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN MinAmountFor3ds COMMENT 'Minimum transaction amount (USD) that triggers 3DS authentication for this BIN. NULL means use the default threshold. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN IsPrepaid COMMENT 'Whether this BIN corresponds to a prepaid card: 1=prepaid, 0=standard bank-issued. Prepaid cards have different risk profiles and may be restricted for certain deposit amounts. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN ChallengeIndicator3DS COMMENT '3DS v2 challenge preference indicator sent to the card network. Values like "01"=No preference, "02"=No challenge requested, "03"=Challenge requested, "04"=Challenge mandated. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN SupportsAFT COMMENT 'Whether this BIN supports Account Funding Transactions (AFT) - Visa''s protocol for pulling funds from a card to fund an account. Used in withdrawal-to-card routing. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN IsCFT COMMENT 'Whether this BIN supports Card Funding Transactions: 1=supports CFT, 0=does not. CFT is used for Visa Direct / Mastercard Send money movement. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN DomesticMoneyTransfer COMMENT 'Whether this BIN supports domestic money transfers. Only populated for 8-digit BINs (CountryBin8); always NULL for 6-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
ALTER TABLE main.general.bronze_etoro_dictionary_countrybin ALTER COLUMN CrossBorderMoneyTransfer COMMENT 'Whether this BIN supports cross-border money transfers. Only populated for 8-digit BINs (CountryBin8); always NULL for 6-digit BIN rows. (Tier 1 - upstream wiki, etoro.Dictionary.CountryBin)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
