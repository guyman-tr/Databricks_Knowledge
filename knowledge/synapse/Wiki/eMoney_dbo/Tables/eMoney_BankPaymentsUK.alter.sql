-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_BankPaymentsUK
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk SET TBLPROPERTIES (
    'comment' = '`eMoney_BankPaymentsUK` is the GBP bank payment transaction log for eToro Money UK accounts. **Grain**: one row per Tribe transaction - one row per bank payment event (TransactionId is unique). As of 2026-04-11, the table holds 468,632 rows covering 102,877 distinct account holders (HolderId), spanning 2025-12-21 to 2026-04-11. **What the table captures**: GBP-denominated bank transfer activity on eToro Money UK accounts - specifically: - **BankPayIns-External** (309,224 rows, 66.0%): External bank-to-eTM transfers (customers funding their eTM wallet from a UK bank account). Amounts are positive. - **BankPayOuts-External** (158,802 rows, 33.9%): eTM-to-external bank transfers (customers withdrawing from their eTM wallet to a UK bank account). Amounts are negative. - **BankPayOuts-DebitAdj** (509 rows, 0.1%): Debit adjustment transactions - reversed or corrected outgoing payments (positive HolderAmount, offsetting prior MO events). - **BankPayOuts-BankingReturn** (97 rows, 0.02%): Returned bank payments - o...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk SET TAGS (
    'domain' = 'billing',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(TransactionId)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE INDEX (CCI) - columnar storage for analytical aggregations',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderId` COMMENT 'Tribe provider holder identifier for the account owner. Corresponds to ProviderHolderId in FiatDwhDB - the external payment provider''s ID for this account holder. Sourced from Tribe AccountsActivities reconciliation data. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `AccountId` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: source is FiatAccount.Id. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `ExternalBankAccountId` COMMENT 'Auto-incrementing surrogate primary key for the external bank account record. FK from FiatTransactions.ExternalBankAccountId -> dbo.FiatBankAccount.Id. The external UK bank account on the other side of the payment. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `BankAccountNumber` COMMENT 'External UK bank account numeric identifier (from the Tribe AccountsActivities record for the counterparty bank account). **PII - handle with care.** (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCode` COMMENT 'Tribe internal transaction type code. Observed values: 57=bank-in external, 56/58=bank-out external, 59=bank-in external (alt), 11=debit adjustment, 66=banking return, 68=bank-in external (rare). Input to BankActivityType CASE expression. Excluded codes: 6,14,15,24,25,64. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionDateTime` COMMENT 'Timestamp when the bank payment transaction occurred (from Tribe AccountsActivities). Used to compute Date and DateID. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionAmount` COMMENT 'Transaction amount in TransactionCurrency (GBP). Positive for MI, negative for MO. Equals HolderAmount for GBP accounts (no FX). (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCurrencyCode` COMMENT 'ISO 4217 numeric currency code for the transaction (always 826=GBP for all rows in this table). (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCurrencyAlpha` COMMENT 'Text ISO currency code for the transaction (always ''GBP'' for all rows in this table). (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderAmount` COMMENT 'Amount in the account holder''s currency (GBP). Positive for inbound transfers (BankPayIns); negative for outbound (BankPayOuts-External). BankPayOuts-DebitAdj and BankPayOuts-BankingReturn may be positive despite "Outs" prefix - these are credits from returned/corrected outgoing payments. Range for BankPayOuts-External: -100,000 to -0.01 GBP; BankPayIns-External: 0.01 to 1,000,000 GBP. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderCurrencyAlpha` COMMENT 'Holder''s account currency text code (always ''GBP''). SP filter restricts to HolderCurrencyAlpha=''GBP''. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionId` COMMENT 'Unique Tribe/FiatDwhDB transaction identifier (FiatTransactions.Id or equivalent Tribe TX ID). One row per TransactionId - the table grain and HASH distribution key. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `EpmMethodId` COMMENT 'Electronic payment method identifier from Tribe AccountsActivities. Value=4 observed for all sampled rows (likely the UK Faster Payments or SEPA credit transfer method). (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `BankActivityType` COMMENT 'Computed classification of the bank payment event. Derived from a CASE expression on TransactionCode. Four live values: ''BankPayIns-External'' (TC 57/59/68, 66.0%), ''BankPayOuts-External'' (TC 56/58, 33.9%), ''BankPayOuts-DebitAdj'' (TC 11, 0.1%), ''BankPayOuts-BankingReturn'' (TC 66, 0.02%). nvarchar(4000) is the DDL-declared width; actual values are short strings. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `Created` COMMENT 'Tribe batch creation timestamp for this transaction record (typically midnight of the processing day). Used as the DELETE key in the incremental load pattern - DELETE WHERE Created = @Date before re-inserting the day''s batch. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `Date` COMMENT 'Calendar date of the bank payment transaction (CAST(TransactionDateTime AS DATE)). Business date for filtering; range: 2025-12-21 to 2026-04-11. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `DateID` COMMENT 'YYYYMMDD integer of Date (e.g., 20260411). Numeric date key for date-based partitioning in queries. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `UpdateDate` COMMENT 'Timestamp when this record was written by the SP. Set to GETDATE() at INSERT time. Not a business event timestamp. (Tier 2 - SP_eMoney_Reconciliation_ETLs)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderId` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `AccountId` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `ExternalBankAccountId` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `BankAccountNumber` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCurrencyCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionCurrencyAlpha` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `HolderCurrencyAlpha` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `TransactionId` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `EpmMethodId` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `BankActivityType` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `Created` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `DateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
