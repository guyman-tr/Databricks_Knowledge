-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dim_Account
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account SET TBLPROPERTIES (
    'comment' = '`eMoney_Dim_Account` is the central account dimension for eToro Money (eTM), the fiat banking product. Each row represents one **currency balance** - the fundamental money-holding unit in the fiat platform. A single customer (GCID) can have multiple currency balances (e.g., EUR and GBP), so this table is at currency-balance grain, not customer grain. The table consolidates three layers of data: 1. **FiatDwhDB identity** - currency balance, fiat account, bank account, card, and current status fields sourced from FiatDwhDB tables (FiatCurrencyBalances, FiatAccount, FiatBankAccount, FiatCards, FiatCardStatuses, FiatAccountStatuses, FiatAccountsProperties, FiatCurrencyBalancesStatuses) 2. **DWH customer enrichment** - club, regulation, country, and player status attributes from DWH_dbo.Dim_Customer and registration-time snapshots from Fact_SnapshotCustomer, joined via GCID 3. **DWH-computed fields** - IsValidETM composite flag, change-detection flags, seniority months, entity mapping The ETL SP (`SP_eMoney_Dim...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'CLUSTERED INDEX (CurrencyBalanceID ASC); NCI (CID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceID` COMMENT 'Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ClubID` COMMENT 'Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Renamed from PlayerLevelID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Club` COMMENT 'Player level display name resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ClubCategory` COMMENT 'Grouped player level bucket. NoClub=PlayerLevelID 1; LowClub=3 or 5; HighClub=2, 6, or 7; Internal=4; Error=unmapped values. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegulationID` COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Regulation` COMMENT 'Regulation display name resolved from DWH_dbo.Dim_Regulation. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountryID` COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Country` COMMENT 'Country display name resolved from DWH_dbo.Dim_Country. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Region` COMMENT 'Geographic region from DWH_dbo.Dim_Country.Region, resolved via CountryID. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `PlayerStatusID` COMMENT 'Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `PlayerStatus` COMMENT 'Player status display name resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsValidETM` COMMENT 'eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsValidCustomer` COMMENT 'DWH-computed: 1 when not Popular Investor (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsTestAccount` COMMENT '1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsCancelledAccount` COMMENT '1 when GCID=0 (cancelled accounts are recorded with a zero GCID in FiatDwhDB). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `GCID_Unique_Count` COMMENT 'Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `TP_RegDate` COMMENT 'Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST to DATE (time component discarded); renamed RegisteredReal -> TP_RegDate. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `TP_FTDDate` COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. DWH note: CAST to DATE; renamed FirstDepositDate -> TP_FTDDate. Passthrough from Dim_Customer. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClubID` COMMENT 'PlayerLevelID from Fact_SnapshotCustomer at the date of eMoney account creation. Represents the customer''s club at eTM onboarding. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClub` COMMENT 'Club display name for RegClubID, resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClubCategory` COMMENT 'Club category bucket at account creation. Same mapping as ClubCategory (NoClub/LowClub/HighClub/Internal) applied to RegClubID. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegulationID` COMMENT 'RegulationID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegulation` COMMENT 'Regulation display name for RegRegulationID, resolved from DWH_dbo.Dim_Regulation. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegCountryID` COMMENT 'CountryID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegCountry` COMMENT 'Country display name for RegCountryID, resolved from DWH_dbo.Dim_Country. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegion` COMMENT 'Geographic region for RegCountryID, resolved from DWH_dbo.Dim_Country.Region. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegPlayerStatusID` COMMENT 'PlayerStatusID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegPlayerStatus` COMMENT 'Player status display name for RegPlayerStatusID, resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountProgramID` COMMENT 'Account program type at eMoney account creation: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). Captured from eMoney_Account_Mappings baseline (original FiatAccount.AccountProgramId). (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountProgram` COMMENT 'Account program display name for RegAccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountSubProgramID` COMMENT 'Specific sub-program variant at eMoney account creation: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. Captured from eMoney_Account_Mappings baseline. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountSubProgram` COMMENT 'Sub-program display name for RegAccountSubProgramID, resolved from eMoney_dbo.SubPrograms. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCustomerInfoChanged` COMMENT '1 if ANY of the following changed since account creation: ClubID, RegulationID, CountryID, PlayerStatusID, AccountProgramID, AccountSubProgramID. Composite of all six individual change flags. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasClubChanged` COMMENT '1 if ClubID (current) != RegClubID (at account creation). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasRegulationChanged` COMMENT '1 if RegulationID (current) != RegRegulationID (at account creation). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCountryChanged` COMMENT '1 if CountryID (current) != RegCountryID (at account creation). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasPlayerStatusChanged` COMMENT '1 if PlayerStatusID (current) != RegPlayerStatusID (at account creation). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasAccountProgramChanged` COMMENT '1 if AccountProgramID (current) != RegAccountProgramID (at account creation). Tracks card-to-IBAN upgrades. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasAccountSubProgramChanged` COMMENT '1 if AccountSubProgramID (current) != RegAccountSubProgramID (at account creation). Tracks sub-program tier/region changes. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceISOCode` COMMENT 'ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. Indexed for currency-based queries. Renamed from FiatCurrencyBalances.CurrencyISON. (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceISODesc` COMMENT 'Currency display name resolved from eMoney_Currency_Instrument_Mapping_Static via CurrencyBalanceISOCode (where SellCurrencyID=1). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateTime` COMMENT 'UTC timestamp when this currency balance was created in the data warehouse. Renamed from FiatCurrencyBalances.Created. (Tier 1 - dbo.FiatCurrencyBalances)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateDate` COMMENT 'Date portion of CurrencyBalanceCreateTime. DWH-derived: CAST(CurrencyBalanceCreateTime AS DATE). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateDateID` COMMENT 'YYYYMMDD integer date key for CurrencyBalanceCreateDate. DWH-derived: CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatusID` COMMENT 'Current currency balance operational status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. Latest status from FiatCurrencyBalancesStatuses (RNDesc=1 by EventTimestamp). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatus` COMMENT 'Currency balance status display name for CurrencyBalanceStatusID, resolved from eMoney_Dictionary_CurrencyBalanceStatus. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatusTime` COMMENT 'EventTimestamp of the most recent status change for this currency balance (from FiatCurrencyBalancesStatuses, RNDesc=1). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderDesc` COMMENT 'Provider name for this account (e.g., Tribe), sourced from AccountsProviderHoldersMapping via eMoney_Account_Mappings. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderCurrencyBalanceID` COMMENT 'Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountID` COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountIsExternal` COMMENT 'Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountName` COMMENT 'Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. Renamed from FiatBankAccount.FullName. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountNumber` COMMENT 'Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountSortCode` COMMENT 'UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountIBAN` COMMENT 'International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountBIC` COMMENT 'Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 - dbo.FiatBankAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateTime` COMMENT 'UTC timestamp when this account record was created in the data warehouse. Renamed from FiatAccount.Created. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateDate` COMMENT 'Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateDateID` COMMENT 'YYYYMMDD integer date key for AccountCreateDate. DWH-derived: CONVERT(VARCHAR(8), AccountCreateTime, 112). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatusID` COMMENT 'Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). (Tier 1 - dbo.FiatAccountStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatus` COMMENT 'Account status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatusTime` COMMENT 'Created timestamp of the most recent account status change event (from FiatAccountStatuses, RNDesc=1). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountProgramID` COMMENT 'Account program type: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.AccountProgramId) - reflects most recent program upgrade/downgrade. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountProgram` COMMENT 'Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountSubProgramID` COMMENT 'Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountSubProgram` COMMENT 'Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountPropertiesTime` COMMENT 'Created timestamp of the most recent FiatAccountsProperties record for this account (the source of AccountProgramID/AccountSubProgramID). NULL if no properties record exists. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountPropertiesDate` COMMENT 'Date portion of AccountPropertiesTime. DWH-derived: CAST(AccountPropertiesTime AS DATE). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountAccountProgramChanges` COMMENT 'Number of distinct program types this account has had. Set to 0 when  <= 1 (i.e., never changed). N >= 2 means the account has changed program N times. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountAccountSubProgramChanges` COMMENT 'Number of distinct sub-programs this account has had. Set to 0 when  <= 1 (never changed). N >= 2 means the account has changed sub-program N times. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderHolderID` COMMENT 'Provider-side holder identifier from AccountsProviderHoldersMapping via eMoney_Account_Mappings. Identifies the customer''s account in the Tribe payment provider system. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_TP_RegDate` COMMENT 'Months since TP (trading platform) registration date (DATEDIFF MONTH between RegisteredReal and @Date=yesterday). NULL when TP_RegDate is NULL. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_TP_FTDDate` COMMENT 'Months since first trading platform deposit date (DATEDIFF MONTH between FirstDepositDate and @Date=yesterday). NULL when TP_FTDDate is NULL or is the sentinel ''19000101''. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_eTM_RegDate` COMMENT 'Months since eToro Money account creation date (DATEDIFF MONTH between AccountCreateTime and @Date=yesterday). Measures eTM-specific tenure. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCard` COMMENT '1 if this account has an associated card (CardID IS NOT NULL), 0 otherwise. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateTime` COMMENT 'UTC timestamp when this card record was created in the data warehouse. Renamed from FiatCards.Created. (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateDate` COMMENT 'Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateDateID` COMMENT 'YYYYMMDD integer date key for CardCreateDate. DWH-derived: CONVERT(VARCHAR(8), CardCreateTime, 112). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusID` COMMENT 'Current card lifecycle status: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. Latest status from FiatCardStatuses (RNDesc=1 by EventTimestamp). (Tier 1 - dbo.FiatCardStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatus` COMMENT 'Card status display name for CardStatusID, resolved from eMoney_Dictionary_CardStatus. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusExpirationTime` COMMENT 'Card expiration date at the time of this status event. (Tier 1 - dbo.FiatCardStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusTime` COMMENT 'When the status change occurred in the source system. (Tier 1 - dbo.FiatCardStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderCardID` COMMENT 'Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `UpdateDate` COMMENT 'GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Entity` COMMENT 'eToro Money entity name resolved from eMoney_EntityByCurrencyISO_MappingStatic via CurrencyBalanceISOCode. Identifies the regulatory/legal entity serving this balance. ISNULL -> ''N/A'' when no mapping exists. Values observed: Malta, UK, AUS. (Tier 2 - SP_eMoney_Dim_Account)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ClubID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ClubCategory` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Region` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `PlayerStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsValidETM` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsTestAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `IsCancelledAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `GCID_Unique_Count` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `TP_RegDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `TP_FTDDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClubID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClub` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegClubCategory` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegCountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegCountry` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegRegion` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegPlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegPlayerStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountSubProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `RegAccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCustomerInfoChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasClubChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasRegulationChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCountryChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasPlayerStatusChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasAccountProgramChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasAccountSubProgramChanged` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceISOCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceISODesc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceCreateDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CurrencyBalanceStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderDesc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderCurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountID` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountIsExternal` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountName` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountNumber` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountSortCode` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountIBAN` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `BankAccountBIC` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountCreateDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountSubProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountPropertiesTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `AccountPropertiesDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountAccountProgramChanges` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CountAccountSubProgramChanges` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderHolderID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_TP_RegDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_TP_FTDDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Seniority_eTM_RegDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `HasCard` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardCreateDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusExpirationTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `CardStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `ProviderCardID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account ALTER COLUMN `Entity` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:17:18 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 1
-- Statements: 180/180 succeeded
-- ====================
