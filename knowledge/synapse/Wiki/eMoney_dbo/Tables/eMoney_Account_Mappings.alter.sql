-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Account_Mappings
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings SET TBLPROPERTIES (
    'comment' = '`eMoney_Account_Mappings` is the central cross-reference table for eToro Money account infrastructure. It denormalizes five separate entity tables - currency balances, bank accounts, fiat accounts, provider holder mappings, and card mappings - into a single row per currency balance. This eliminates repetitive multi-table joins in downstream analytics and reporting. **Grain**: One row per currency balance (CurrencyBalanceID). A customer (GCID) with two currency balances (e.g., EUR + GBP) will have two rows. The 2,034,012 rows correspond to all provisioned currency balances, predominantly IBAN accounts (iban=97%, card=3%). **Key linkage chain**: - `CurrencyBalanceID` -> `AccountID` -> `GCID` (customer identity) - `CurrencyBalanceID` -> `ProviderCurrencyBalanceID` (Tribe balance reference) - `AccountID` -> `ProviderHolderID` (Tribe holder reference) - `AccountID` -> `CardID` -> `ProviderCardID` (card reference, NULL for IBAN accounts) **Provider**: Tribe is the sole payment provider (ProviderDesc=''Tribe'' for 99.99%...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceID` COMMENT 'Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. DWH note: renamed from `Id` in dbo.FiatCurrencyBalances. (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceISON` COMMENT 'ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. See ISO Currency Info. Indexed for currency-based queries. DWH note: renamed from `CurrencyISON` and CAST to INT. Live values: 978=EUR(67%), 826=GBP(31%), 36=AUD(2%), 208=DKK(<1%). (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceCreateTime` COMMENT 'UTC timestamp when this currency balance was created in the data warehouse. DWH note: renamed from `Created`. (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderDesc` COMMENT 'Provider name for this currency balance, resolved from eMoney_Dictionary_Provider via CurrencyBalancesProvidersMapping. Currently ''Tribe'' (99.99%); NULL for 227 unmapped balances. (Tier 2 - SP_eMoney_Account_Mappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderCurrencyBalanceID` COMMENT 'The provider''s identifier for this currency balance. Used for provider API calls and reconciliation. DWH note: renamed from `CurrencyBalanceProviderId` and CAST to INT; called "AccountId" in Tribe''s system. (Tier 1 - dbo.CurrencyBalancesProvidersMapping)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountID` COMMENT 'Auto-incrementing surrogate primary key. DWH note: renamed from `Id` in dbo.FiatBankAccount; latest bank account per CurrencyBalanceId (ROW_NUMBER by EventTimestamp DESC). NULL for card accounts or unlinked balances (436 rows). (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountIsExternal` COMMENT 'Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. DWH note: renamed from `IsExternal`. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountName` COMMENT 'Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. DWH note: renamed from `FullName`; CAST to NVARCHAR(200); DDM not enforced in Synapse - treat as PII. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountNumber` COMMENT 'Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). DWH note: CAST from nvarchar to INT - UK account numbers only (sort code accounts). (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountSortCode` COMMENT 'UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. DWH note: renamed from `SortCode`; CAST to INT. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountIBAN` COMMENT 'International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). DWH note: renamed from `Iban`; CAST to NVARCHAR(200); 40,407 NULL rows. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountBIC` COMMENT 'Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. DWH note: renamed from `Bic`; CAST to NVARCHAR(200). (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: renamed from `Id` in dbo.FiatAccount. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. DWH note: renamed from `Gcid`. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountCreateTime` COMMENT 'UTC timestamp when this account record was created in the data warehouse. Indexed for time-range queries. DWH note: renamed from `Created`. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountProgramID` COMMENT 'Account program type: 0=Unknown, 1=card (default), 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: renamed from `AccountProgramId`. Live: iban=97%, card=3%. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountProgram` COMMENT 'Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. Values: ''card'', ''iban''. NULL if AccountProgramID=0 (Unknown). (Tier 2 - SP_eMoney_Account_Mappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountSubProgramID` COMMENT 'Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). See Sub-Program. FK to dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: renamed from `SubProgramId`. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountSubProgram` COMMENT 'Account sub-program display name for AccountSubProgramID, resolved from eMoney_Dictionary_AccountSubProgram (e.g., ''IBAN EU Green'', ''IBAN Standard UK'', ''Card Standard UK''). NULL if AccountSubProgramID is NULL. (Tier 2 - SP_eMoney_Account_Mappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderHolderID` COMMENT 'The external provider''s (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. DWH note: renamed from `ProviderHolderId`; CAST to INT. (Tier 1 - dbo.AccountsProviderHoldersMapping)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CardID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. DWH note: renamed from `Id` in dbo.FiatCards; latest card per AccountId (ROW_NUMBER by Created DESC). NULL for IBAN accounts (95.3% of rows). (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CardCreateTime` COMMENT 'UTC timestamp when this card record was created in the data warehouse. DWH note: renamed from `Created`. NULL for IBAN accounts. (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderCardID` COMMENT 'The provider''s identifier for this card in their system. Used for provider API calls. DWH note: renamed from `CardProviderId` in dbo.CardsProvidersMapping; CAST to INT. NULL for IBAN accounts. (Tier 1 - dbo.CardsProvidersMapping)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `UpdateDate` COMMENT 'ETL execution timestamp set to GETDATE() when SP_eMoney_Account_Mappings ran. Reflects data freshness, not entity creation time. (Tier 2 - SP_eMoney_Account_Mappings)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceISON` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CurrencyBalanceCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderDesc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderCurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountID` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountIsExternal` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountName` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountNumber` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountSortCode` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountIBAN` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `BankAccountBIC` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountSubProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderHolderID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `CardCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `ProviderCardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
