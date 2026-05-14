-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CountryBin
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin SET TBLPROPERTIES (
    'comment' = '`Dim_CountryBin` is a 16.3-million-row BIN (Bank Identification Number) lookup table. During credit card deposit processing, the first 6 or 8 digits of the customer''s card number are matched against this table to determine the card-issuing country, bank, card type, and processing rules (whether 3D Secure verification is required, whether the card is prepaid, etc.). The table combines two production sources: `etoro.Dictionary.CountryBin6` (6-digit BINs, ~324K rows upstream) and `etoro.Dictionary.CountryBin8` (8-digit BINs), both pre-merged in the `DWH_staging.etoro_Dictionary_CountryBin` staging table before loading to DWH. The ETL is a full TRUNCATE+INSERT daily reload from staging. Several processing-level columns from the upstream source are dropped: `ChallengeIndicator3DS`, `SupportsAFT`, `IsCFT`, `DomesticMoneyTransfer`, `CrossBorderMoneyTransfer`. Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` (6-digit BIN details; 8-digit covered by CountryBin8.md). Synapse: REPLICA...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (BinCode ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CountryID COMMENT 'FK to DWH_dbo.Dim_Country. Card-issuing country. Same ID space as Dim_Country.CountryID (DWH internal ID, not ISO numeric). (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BinCode COMMENT 'Bank Identification Number. First 6 or 8 digits of the card number identifying the issuing bank and card product. Values < 10,000,000 are 6-digit BINs; >= 10,000,000 are 8-digit BINs. Clustered index key for fast lookups. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN IssuingBank COMMENT 'Human-readable name of the card-issuing bank (e.g., "CENTRAL SUPPLIES - TDFS"). NULL when the BIN has no enriched bank metadata. Informational only - not used in deposit authorization logic. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardTypeID COMMENT 'FK to DWH_dbo.Dim_CardType (if exists). Card network/type: 1=Visa, 2=Master Card, 13=Local Card. Used in deposit routing and reporting. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardSubType COMMENT 'Sub-classification of the card product within its type (e.g., "CREDIT", "DEBIT", "PREPAID"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardCategory COMMENT 'Card product category (e.g., "STANDARD", "GOLD", "PLATINUM", "BUSINESS"). NULL when not available. Passthrough from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BankWebSite COMMENT 'Issuing bank website URL. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BankInfo COMMENT 'Additional bank information text. Informational. NULL in most rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN ShouldCheck3ds COMMENT 'Whether 3D Secure verification is required for deposits from this BIN. 1=required (4.8M BINs, 29%), 0=not required (11.6M BINs, 71%). Drives deposit authorization flow. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN MinAmountFor3ds COMMENT 'Minimum deposit amount (in account currency units) that triggers 3DS verification for this BIN. 0 = all amounts require 3DS when ShouldCheck3ds=1. Only meaningful when ShouldCheck3ds=1. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN IsPrepaid COMMENT 'Whether this is a prepaid card. True=prepaid (may trigger fraud checks or processing restrictions). False=standard credit/debit card. (Tier 1 - Dictionary.CountryBin6 upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily full reload via SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BinCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN IssuingBank SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardSubType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BankWebSite SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN BankInfo SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN ShouldCheck3ds SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN MinAmountFor3ds SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN IsPrepaid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:16:37 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 26/26 succeeded
-- ====================
