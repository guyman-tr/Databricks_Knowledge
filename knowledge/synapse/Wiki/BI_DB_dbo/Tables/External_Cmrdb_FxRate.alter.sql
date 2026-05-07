-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.External_Cmrdb_FxRate
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.External_Cmrdb_FxRate > Daily cross-currency exchange rate matrix sourced from the external CMR-DB system. One row per (DomesticCurrency, ForeignCurrency, ExchangeDate) combination - for any of ~30 supported foreign currencies, the rate is expressed in 4 domestic-currency views (USD, EUR, GBP, AUD) so a fact table denominated in any of those bases can convert directly without a triangular join. Loaded daily; `IsOld` flags superseded rows. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (External-prefixed naming convention - sourced from the CMR-DB system upstream) | | **Production Source** | CMR-DB FX rate service (external to eToro DWH) | | **Refresh** | Daily - new rows appended per ExchangeDate; `IsOld` flag marks any superseded rate | | **Grain** | One row per (DomesticCurrencyCode, ForeignCurrencyCode, ExchangeDate) | | | | | '
);

-- ---- Table Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN Id COMMENT 'Surrogate primary key - append-only sequence assigned on insert. Use to order/dedupe within a (domestic, foreign, date) tuple. (Tier 1 - DDL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN DomesticCurrencyCode COMMENT 'ISO-4217 code of the **destination** (reporting) currency: USD, EUR, GBP, or AUD. (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyCode COMMENT 'ISO-4217 code of the **source** (customer/local) currency. ~30 codes covered (AED, AUD, CAD, USD, EUR, GBP, ...). (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyName COMMENT 'Human-readable name of the foreign currency (e.g. `''Australian Dollar''`, `''Canadian Dollar''`). May equal the code itself if no display name was provided in CMR-DB. (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyName2 COMMENT 'Secondary / alternate display name for the foreign currency, populated from CMR-DB when an alternate localization exists. Often NULL. (Tier 2 - convention)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeRate COMMENT 'Conversion rate: 1 unit of ForeignCurrency = ExchangeRate units of DomesticCurrency, divided by ExchangeQuantity. Apply as `amount_in_foreign × ExchangeRate / ExchangeQuantity`. (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeQuantity COMMENT 'Denominator for the rate; typically 1 (rate is per-unit). For low-unit currencies CMR-DB may publish per-100 or per-1000 rates - divide by ExchangeQuantity to get the per-unit factor. (Tier 1 - DDL + convention)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeDate COMMENT 'The business date this rate applies to. One rate (post-`IsOld` filter) per (domestic, foreign, date) tuple. (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN IsOld COMMENT 'TRUE if a newer rate has superseded this row for the same (domestic, foreign, date) tuple. Filter `IsOld = FALSE` for reporting; keep TRUE rows for audit. (Tier 1 - DDL + convention)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN AddedDate COMMENT 'Timestamp when the rate was first inserted into CMR-DB. (Tier 1 - DDL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN AddedBy COMMENT 'User/system that inserted the row in CMR-DB. Often empty when system-driven. (Tier 1 - UC sample)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN UpdatedDate COMMENT 'Timestamp when the rate was last updated in CMR-DB. NULL when the row has never been edited post-insert. (Tier 1 - DDL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN UpdatedBy COMMENT 'User/system that last edited the row in CMR-DB. Often empty. (Tier 1 - DDL)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN CrossExchangeRate COMMENT 'Cross-currency rate computed indirectly through a base currency (e.g. EUR <-> AUD via USD). For direct domestic <-> foreign conversion, prefer `ExchangeRate`; use `CrossExchangeRate` only for triangulated/derived calculations. (Tier 2 - name-inferred + CMR-DB convention)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN Id SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN DomesticCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyName SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ForeignCurrencyName2 SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeQuantity SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN ExchangeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN IsOld SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN AddedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN AddedBy SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN UpdatedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN UpdatedBy SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_external_cmrdb_fxrate ALTER COLUMN CrossExchangeRate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 10:46:47 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 13
-- Statements: 30/30 succeeded
-- ====================
