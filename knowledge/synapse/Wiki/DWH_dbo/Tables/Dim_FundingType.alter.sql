-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_FundingType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype SET TBLPROPERTIES (
    'comment' = '`Dim_FundingType` is a payment method dimension with 44 rows (FundingTypeID 0-44, with ID 41 absent). Each row represents a payment method or funding channel that eToro customers use for deposits and withdrawals. Methods span credit cards, bank transfers, e-wallets, crypto, regional payment systems (Yandex, Qiwi, AliPay, WeChat, Przelewy24), and eToro-internal channels (eToroCryptoWallet, eToroMoney). Three behavioral flags classify each method: - `IsNewStyle`: modern-era payment integration (True = post-legacy platform) - `IsSingleFunding`: one-time/single use (True = e.g., BankDraft, InternalPayment) - `IsCashoutActive`: cashout/withdrawal supported via this method (True = bidirectional) **FundingTypeID=0 (N/A)** is a DWH-injected synthetic null-sentinel row, inserted after the main staging load as a hardcoded VALUES insert. Fact tables use `ISNULL(FundingTypeID, 0)` to replace NULLs with this sentinel, enabling NULL-safe joins. **FundingTypeID=27 (eToroCryptoWallet)** has hardcoded business logic: `SP_F...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (FundingTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN FundingTypeID COMMENT 'Primary key identifying the payment method. (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN Name COMMENT 'Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsNewStyle COMMENT 'Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsSingleFunding COMMENT 'Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsCashoutActive COMMENT 'Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN DWHFundingTypeID COMMENT 'DWH copy of FundingTypeID. SET in ETL as `[FundingTypeID] as [DWHFundingTypeID]`. Currently identical to FundingTypeID for all rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all rows (both staging rows and N/A sentinel). Likely means active. No corresponding Dim_Status table found. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() (stored as @ddate variable). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN InsertDate COMMENT 'ETL load timestamp. Set to GETDATE() (same value as UpdateDate). Both columns set on each run. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsNewStyle SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsSingleFunding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN IsCashoutActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN DWHFundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
