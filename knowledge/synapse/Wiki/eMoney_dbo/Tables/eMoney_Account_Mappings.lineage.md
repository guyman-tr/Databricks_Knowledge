# Lineage: eMoney_dbo.eMoney_Account_Mappings

**Generated**: 2026-04-21 | **Writer SP**: SP_eMoney_Account_Mappings (Step 04: DELETE + INSERT)

## ETL Chain

```
FiatDwhDB mirrors in eMoney_dbo:
  FiatCurrencyBalances → CurrencyBalancesProvidersMapping → FiatBankAccount
  FiatAccount → AccountsProviderHoldersMapping
  FiatCards → CardsProvidersMapping
eMoney_dbo dictionaries:
  eMoney_Dictionary_Provider (provider name resolution)
  eMoney_Dictionary_AccountProgram (program name resolution)
  eMoney_Dictionary_AccountSubProgram (sub-program name resolution)
  |-- SP_eMoney_Account_Mappings (Steps 1-4):  ---|
  |     Step 1: #currency_balance (FiatCurrencyBalances + provider + bank mappings)
  |     Step 2: #fiat_account (FiatAccount + program names + provider holder ID)
  |     Step 3: #fiat_card (latest FiatCards per account + CardsProvidersMapping)
  |     Step 4: DELETE + INSERT into eMoney_Account_Mappings
  v
eMoney_dbo.eMoney_Account_Mappings (2,034,012 rows)
  |-- Generic Pipeline (Gold export) ---|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|----------------|-----------|------|
| 1 | CurrencyBalanceID | FiatCurrencyBalances | Id | Renamed passthrough | Tier 1 |
| 2 | CurrencyBalanceISON | FiatCurrencyBalances | CurrencyISON | Rename + CAST to INT (stored as nvarchar in source) | Tier 1 |
| 3 | CurrencyBalanceCreateTime | FiatCurrencyBalances | Created | Renamed passthrough | Tier 1 |
| 4 | ProviderDesc | eMoney_Dictionary_Provider | Provider | JOIN-denormalized from ProviderId via CurrencyBalancesProvidersMapping | Tier 2 |
| 5 | ProviderCurrencyBalanceID | CurrencyBalancesProvidersMapping | CurrencyBalanceProviderId | Renamed + CAST to INT | Tier 1 |
| 6 | BankAccountID | FiatBankAccount | Id | Renamed; latest bank account per CurrencyBalanceId (ROW_NUMBER by EventTimestamp DESC = 1) | Tier 1 |
| 7 | BankAccountIsExternal | FiatBankAccount | IsExternal | Renamed passthrough | Tier 1 |
| 8 | BankAccountName | FiatBankAccount | FullName | Renamed + CAST to NVARCHAR(200) (PII field) | Tier 1 |
| 9 | BankAccountNumber | FiatBankAccount | BankAccountNumber | CAST to INT (PII field) | Tier 1 |
| 10 | BankAccountSortCode | FiatBankAccount | SortCode | Renamed + CAST to INT | Tier 1 |
| 11 | BankAccountIBAN | FiatBankAccount | Iban | Renamed + CAST to NVARCHAR(200) (PII field) | Tier 1 |
| 12 | BankAccountBIC | FiatBankAccount | Bic | Renamed + CAST to NVARCHAR(200) | Tier 1 |
| 13 | AccountID | FiatAccount | Id | Renamed passthrough | Tier 1 |
| 14 | GCID | FiatAccount | Gcid | Renamed passthrough | Tier 1 |
| 15 | AccountCreateTime | FiatAccount | Created | Renamed passthrough | Tier 1 |
| 16 | AccountProgramID | FiatAccount | AccountProgramId | Renamed passthrough | Tier 1 |
| 17 | AccountProgram | eMoney_Dictionary_AccountProgram | AccountProgram | JOIN-denormalized program name from AccountProgramId | Tier 2 |
| 18 | AccountSubProgramID | FiatAccount | SubProgramId | Renamed passthrough | Tier 1 |
| 19 | AccountSubProgram | eMoney_Dictionary_AccountSubProgram | AccountSubProgram | JOIN-denormalized sub-program name from SubProgramId | Tier 2 |
| 20 | ProviderHolderID | AccountsProviderHoldersMapping | ProviderHolderId | Renamed + CAST to INT (source is nvarchar) | Tier 1 |
| 21 | CardID | FiatCards | Id | Renamed; latest card per AccountId (ROW_NUMBER by Created DESC = 1). NULL for IBAN accounts (no card). | Tier 1 |
| 22 | CardCreateTime | FiatCards | Created | Renamed passthrough | Tier 1 |
| 23 | ProviderCardID | CardsProvidersMapping | CardProviderId | Renamed + CAST to INT | Tier 1 |
| 24 | UpdateDate | ETL | N/A | GETDATE() at SP execution time | Tier 2 |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 20 | CurrencyBalanceID, CurrencyBalanceISON, CurrencyBalanceCreateTime, ProviderCurrencyBalanceID, BankAccountID, BankAccountIsExternal, BankAccountName, BankAccountNumber, BankAccountSortCode, BankAccountIBAN, BankAccountBIC, AccountID, GCID, AccountCreateTime, AccountProgramID, AccountSubProgramID, ProviderHolderID, CardID, CardCreateTime, ProviderCardID |
| Tier 2 | 4 | ProviderDesc, AccountProgram, AccountSubProgram, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
